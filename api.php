<?php
// ============================================================
//  OPAC LIB — PHP API Backend
// ============================================================

// Catch ALL PHP errors and return them as JSON instead of HTML
set_error_handler(function($errno, $errstr, $errfile, $errline) {
    header('Content-Type: application/json');
    echo json_encode(['error' => "PHP Error [$errno]: $errstr on line $errline"]);
    exit();
});
set_exception_handler(function($e) {
    header('Content-Type: application/json');
    echo json_encode(['error' => 'Exception: ' . $e->getMessage()]);
    exit();
});

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200); exit();
}

// ============================================================
// DATABASE CONNECTION
// ============================================================
$db = new mysqli('127.0.0.1', 'root', '', 'library_opac');
if ($db->connect_error) {
    http_response_code(500);
    echo json_encode(['error' => 'DB connection failed: ' . $db->connect_error]);
    exit();
}
$db->set_charset('utf8mb4');

// ============================================================
// BOOTSTRAP — create tables if they don't exist
// ============================================================
$db->query("CREATE TABLE IF NOT EXISTS books (
    id     INT AUTO_INCREMENT PRIMARY KEY,
    title  VARCHAR(255) NOT NULL,
    author VARCHAR(255) NOT NULL,
    dewey  VARCHAR(20)  NOT NULL DEFAULT '000',
    year   INT,
    status ENUM('available','borrowed') DEFAULT 'available'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");

$db->query("CREATE TABLE IF NOT EXISTS borrow_records (
    borrow_id   INT AUTO_INCREMENT PRIMARY KEY,
    book_id     INT          NOT NULL,
    patron_name VARCHAR(255) NOT NULL DEFAULT 'Walk-in Patron',
    borrow_date DATE         NOT NULL,
    due_date    DATE         NOT NULL,
    return_date DATE         DEFAULT NULL,
    FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");

// ============================================================
// ROUTER
// ============================================================
$method = $_SERVER['REQUEST_METHOD'];
$action = $_GET['action'] ?? '';
$body   = json_decode(file_get_contents('php://input'), true) ?? [];

switch ($action) {

    // BOOKS
    case 'get_books':
        $allowed = ['title','author','year','id','dewey'];
        $sort    = $_GET['sort'] ?? 'dewey';
        $order   = in_array($sort, $allowed) ? $sort : 'dewey';
        $sql     = "SELECT * FROM books ORDER BY $order ASC";
        $res     = $db->query($sql);
        $books   = [];
        while ($row = $res->fetch_assoc()) 
        $books[] = $row;
        echo json_encode($books);
        break;

    case 'add_book':
        $title  = trim($body['title']  ?? '');
        $author = trim($body['author'] ?? '');
        $dewey  = trim($body['dewey']  ?? '000');
        $year   = intval($body['year'] ?? date('Y'));
        if (!$title || !$author) {
            respond(400, 'Title and author required');
            break;
        }
        if (!preg_match('/^\d{3}(\.\d{1,4})?$/', $dewey)) {
            respond(400, 'Invalid DDC format');
            break;
        }

        $stmt = $db->prepare("INSERT INTO books (title,author,dewey,year,status) VALUES (?,?,?,?,'available')");
        $stmt->bind_param('sssi', $title, $author, $dewey, $year);
        $stmt->execute();
        respond(200, 'Book added', ['id' => $db->insert_id]);
        break;

    case 'edit_book':
        $id     = intval($body['id']     ?? 0);
        $title  = trim($body['title']    ?? '');
        $author = trim($body['author']   ?? '');
        $dewey  = trim($body['dewey']    ?? '');
        $year   = intval($body['year']   ?? 0);
        if (!$id || !$title || !$author) {
            respond(400, 'Missing fields');
            break;
        }
        if (!preg_match('/^\d{3}(\.\d{1,4})?$/', $dewey)) {
            respond(400, 'Invalid DDC format');
            break;
        }
        $stmt = $db->prepare("UPDATE books SET title=?,author=?,dewey=?,year=? WHERE id=?");
        $stmt->bind_param('sssii', $title, $author, $dewey, $year, $id);
        $stmt->execute();
        respond(200, 'Book updated');
        break;

    case 'delete_book':
        $id = intval($body['id'] ?? 0);
        if (!$id) {
            respond(400, 'Missing ID');
            break;
        }
        $res = $db->query("SELECT status FROM books WHERE id=$id");
        $row = $res->fetch_assoc();
        if (!$row) {
            respond(404, 'Book not found');
            break;
        }
        if ($row['status'] === 'borrowed') {
            respond(400, 'Cannot delete a borrowed book');
            break;
        }
        $db->query("DELETE FROM books WHERE id=$id");
        respond(200, 'Book deleted');
        break;

    // CIRCULATION
    case 'borrow_book':
        $bookId   = intval($body['book_id']      ?? 0);
        $patron   = trim($body['patron_name']    ?? '');
        $dueDate  = trim($body['due_date']        ?? '');

        $borDate  = date('Y-m-d');
        if (!$bookId || !$patron || !$dueDate) {
            respond(400, 'Missing fields');
            break;
        }
        if ($dueDate <= $borDate) {
            respond(400, 'Due date must be after today');
            break;
        }

        $maxDate = date('Y-m-d', strtotime('+21 days'));
        if ($dueDate > $maxDate) {
            respond(400, 'Maximum borrow period is 21 days');
            break;
        }

        $res  = $db->query("SELECT title, status FROM books WHERE id=$bookId");
        $book = $res->fetch_assoc();
        if (!$book) {
            respond(404, 'Book not found');
            break;
        }
        if ($book['status'] !== 'available') {
            respond(400, 'Book is not available');
            break;
        }

        $db->query("UPDATE books SET status='borrowed' WHERE id=$bookId");
        $stmt = $db->prepare("INSERT INTO borrow_records (book_id,patron_name,borrow_date,due_date) VALUES (?,?,?,?)");
        $stmt->bind_param('isss', $bookId, $patron, $borDate, $dueDate);
        $stmt->execute();
        respond(200, 'Book borrowed successfully', ['borrow_id' => $db->insert_id]);
        break;

    case 'return_book':
        $bookId     = intval($body['book_id'] ?? 0);
        if (!$bookId) {
            respond(400, 'Missing book ID');
            break;
        }
        
        $returnDate = date('Y-m-d');
        $res = $db->query("SELECT borrow_id, due_date FROM borrow_records WHERE book_id=$bookId AND return_date IS NULL ORDER BY borrow_id DESC LIMIT 1");
        $rec = $res->fetch_assoc();
        if (!$rec) {
            respond(404, 'No active borrow record found');
            break;
        }
        
        $daysLate = max(0, intval((strtotime($returnDate) - strtotime($rec['due_date'])) / 86400));
        $fee      = $daysLate * 5;
        $db->query("UPDATE books SET status='available' WHERE id=$bookId");
        $stmt = $db->prepare("UPDATE borrow_records SET return_date=? WHERE borrow_id=?");
        $stmt->bind_param('si', $returnDate, $rec['borrow_id']);
        $stmt->execute();
        respond(200, 'Book returned', ['days_late' => $daysLate, 'fee' => $fee]);
        break;

    // --- RECORDS ---
    case 'get_records':
        $sql = "SELECT br.borrow_id, b.id as book_id, b.title as book_title, b.dewey,
                       br.patron_name, br.borrow_date, br.due_date, br.return_date
                FROM borrow_records br
                JOIN books b ON br.book_id = b.id
                ORDER BY br.borrow_date DESC";
        $res     = $db->query($sql);
        
        $records = [];
        $today   = date('Y-m-d');
        while ($row = $res->fetch_assoc()) {
            if ($row['return_date']) {
                $row['status']    = 'returned';
                $row['days_late'] = 0;
                $row['fee']       = 0;
            } elseif ($today > $row['due_date']) {
                $late             = intval((strtotime($today) - strtotime($row['due_date'])) / 86400);
                $row['status']    = 'overdue';
                $row['days_late'] = $late;
                $row['fee']       = $late * 5;
            } else {
                $row['status']    = 'active';
                $row['days_late'] = 0;
                $row['fee']       = 0;
            }
            $records[] = $row;
        }
        echo json_encode($records);
        break;

    // --- STATS ---
    case 'get_stats':
        $total     = $db->query("SELECT COUNT(*) FROM books")->fetch_row()[0];
        $available = $db->query("SELECT COUNT(*) FROM books WHERE status='available'")->fetch_row()[0];
        $borrowed  = $db->query("SELECT COUNT(*) FROM books WHERE status='borrowed'")->fetch_row()[0];
        $overdue   = $db->query("SELECT COUNT(*) FROM borrow_records WHERE return_date IS NULL AND due_date < CURDATE()")->fetch_row()[0];
        $txns      = $db->query("SELECT COUNT(*) FROM borrow_records")->fetch_row()[0];
        $ddc_counts = [];
        foreach (['0','1','2','3','4','5','6','7','8','9'] as $d) {
            $cnt = $db->query("SELECT COUNT(*) FROM books WHERE dewey LIKE '$d%'")->fetch_row()[0];
            $ddc_counts[$d.'00'] = intval($cnt);
        }
        echo json_encode(compact('total','available','borrowed','overdue','txns','ddc_counts'));
        break;

    default:
        respond(404, 'Unknown action: ' . $action);
}

$db->close();

function respond($code, $message, $data = []) {
    http_response_code($code);
    echo json_encode(array_merge(['message' => $message], $data));
}