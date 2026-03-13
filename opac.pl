#!/usr/bin/perl
# ============================================================
#   ___  ____   _    ____   _     ___ ____
#  / _ \|  _ \ / \  / ___| | |   |_ _| __ )
# | | | | |_) / _ \| |     | |    | ||  _ \
# | |_| |  __/ ___ \ |___  | |___ | || |_) |
#  \___/|_| /_/   \_\____| |_____|___|____/
#
#  OPAC LIB — Online Public Access Catalog System
#  Design & Implementation of Programming Languages
#  Final Project | 2nd Semester SY 2025-2026
#  Language Assigned: Perl 5
# ============================================================
#
#  PARADIGM HIGHLIGHTS DEMONSTRATED:
#   [1] Object-Oriented Programming  — Book, Patron, BorrowRecord classes
#   [2] Event-Driven Programming     — Menu dispatch table (code refs as events)
#   [3] Subprograms                  — Modular subs for every feature
#   [4] Parameter Passing            — By value, by reference, named params
#   [5] Abstract Data Types          — Perl hashes-as-objects with constructors
#   [6] Encapsulation                — Data hidden inside blessed hash refs
#   [7] Memory Management            — undef / $sth->finish() / $dbh->disconnect()
#   [8] Garbage Collection           — Perl ref-counting + explicit cleanup on EXIT
#   [9] Dewey Decimal Classification — Full DDC browser + category search
# ============================================================

use strict;
use warnings;
use DBI;
use POSIX      qw(strftime);
use Time::Local;
use Scalar::Util qw(looks_like_number);
use utf8;
use open ':std', ':encoding(UTF-8)';

# ============================================================
# SECTION 1 — CONSTANTS & CONFIGURATION
# (Abstract Data Type: configuration record)
# ============================================================
my %CONFIG = (
    dsn      => "DBI:ODBC:Driver={MySQL ODBC 9.6 Unicode Driver};Server=127.0.0.1;Port=3306;Database=library_opac",
    user     => "root",
    password => "",
    fee_per_day => 5,          # PHP 5.00 overdue fee per day
    app_name    => "OPAC LIB",
    version     => "1.0.0",
    school_year => "2025-2026",
);

# ============================================================
# SECTION 2 — DEWEY DECIMAL CLASSIFICATION TABLE
# (Abstract Data Type: nested hash — the DDC knowledge base)
# Full 10 main classes with representative subdivisions
# ============================================================
my %DDC = (
    "000" => {
        name  => "Computer Science, Information & General Works",
        emoji => "[GEN]",
        color => "\e[96m",
        subs  => {
            "001" => "Knowledge & Learning",
            "002" => "The Book",
            "003" => "Systems",
            "004" => "Computer Science",
            "005" => "Computer Programming",
            "006" => "Special Computer Methods",
            "010" => "Bibliography",
            "020" => "Library & Information Science",
            "030" => "General Encyclopedias",
            "050" => "General Serial Publications",
            "060" => "General Organizations & Museums",
            "070" => "News Media, Journalism, Publishing",
            "080" => "General Collections",
            "090" => "Manuscripts & Rare Books",
        },
    },
    "100" => {
        name  => "Philosophy & Psychology",
        emoji => "[PHI]",
        color => "\e[95m",
        subs  => {
            "100" => "Philosophy",
            "110" => "Metaphysics",
            "120" => "Epistemology",
            "130" => "Parapsychology & Occultism",
            "140" => "Philosophical Schools",
            "150" => "Psychology",
            "160" => "Logic",
            "170" => "Ethics",
            "180" => "Ancient Philosophy",
            "190" => "Modern Western Philosophy",
        },
    },
    "200" => {
        name  => "Religion",
        emoji => "[REL]",
        color => "\e[93m",
        subs  => {
            "200" => "Religion",
            "210" => "Philosophy of Religion",
            "220" => "The Bible",
            "230" => "Christianity",
            "240" => "Christian Practice",
            "250" => "Christian Pastoral",
            "260" => "Christian Organization",
            "270" => "Church History",
            "280" => "Christian Denominations",
            "290" => "Other Religions",
        },
    },
    "300" => {
        name  => "Social Sciences",
        emoji => "[SOC]",
        color => "\e[92m",
        subs  => {
            "300" => "Social Sciences",
            "310" => "Statistics",
            "320" => "Political Science",
            "330" => "Economics",
            "340" => "Law",
            "350" => "Public Administration",
            "360" => "Social Problems & Services",
            "370" => "Education",
            "380" => "Commerce, Communications, Transport",
            "390" => "Customs, Etiquette, Folklore",
        },
    },
    "400" => {
        name  => "Language",
        emoji => "[LNG]",
        color => "\e[94m",
        subs  => {
            "400" => "Language",
            "410" => "Linguistics",
            "420" => "English",
            "430" => "German",
            "440" => "French",
            "450" => "Italian",
            "460" => "Spanish & Portuguese",
            "470" => "Latin",
            "480" => "Greek",
            "490" => "Other Languages",
        },
    },
    "500" => {
        name  => "Natural Sciences & Mathematics",
        emoji => "[SCI]",
        color => "\e[91m",
        subs  => {
            "500" => "Natural Sciences",
            "510" => "Mathematics",
            "520" => "Astronomy",
            "530" => "Physics",
            "540" => "Chemistry",
            "550" => "Earth Sciences",
            "560" => "Paleontology",
            "570" => "Biology",
            "580" => "Plants",
            "590" => "Animals",
        },
    },
    "600" => {
        name  => "Technology & Applied Sciences",
        emoji => "[TEC]",
        color => "\e[33m",
        subs  => {
            "600" => "Technology",
            "610" => "Medicine & Health",
            "620" => "Engineering",
            "630" => "Agriculture",
            "640" => "Home Economics",
            "650" => "Management & Public Relations",
            "660" => "Chemical Engineering",
            "670" => "Manufacturing",
            "680" => "Various Products",
            "690" => "Construction",
        },
    },
    "700" => {
        name  => "The Arts & Recreation",
        emoji => "[ART]",
        color => "\e[35m",
        subs  => {
            "700" => "Arts",
            "710" => "Civic & Landscape Art",
            "720" => "Architecture",
            "730" => "Sculpture",
            "740" => "Drawing & Decorative Arts",
            "750" => "Painting",
            "760" => "Printmaking",
            "770" => "Photography",
            "780" => "Music",
            "790" => "Sports & Recreation",
        },
    },
    "800" => {
        name  => "Literature",
        emoji => "[LIT]",
        color => "\e[36m",
        subs  => {
            "800" => "Literature",
            "810" => "American Literature in English",
            "820" => "English Literature",
            "830" => "German Literature",
            "840" => "French Literature",
            "850" => "Italian Literature",
            "860" => "Spanish Literature",
            "870" => "Latin Literature",
            "880" => "Greek Literature",
            "890" => "Other Literatures",
        },
    },
    "900" => {
        name  => "History, Geography & Biography",
        emoji => "[HIS]",
        color => "\e[37m",
        subs  => {
            "900" => "History & Geography",
            "910" => "Geography & Travel",
            "920" => "Biography",
            "930" => "Ancient History",
            "940" => "European History",
            "950" => "Asian History",
            "960" => "African History",
            "970" => "North American History",
            "980" => "South American History",
            "990" => "Pacific & Antarctic History",
        },
    },
);

# ============================================================
# SECTION 3 — OOP: BLESSED HASH CONSTRUCTORS
# (Encapsulation + Abstract Data Types)
# Each "class" encapsulates its own data and behavior.
# ============================================================

# --- CLASS: Book ---
package Book;
sub new {
    # Parameter passing: named parameters via hash
    my ($class, %args) = @_;
    my $self = {
        id     => $args{id}     // undef,
        title  => $args{title}  // "",
        author => $args{author} // "",
        dewey  => $args{dewey}  // "000",
        year   => $args{year}   // 0,
        status => $args{status} // "available",
    };
    return bless $self, $class;   # Encapsulation via blessed reference
}
sub display {
    my ($self) = @_;
    my $status_color = $self->{status} eq 'available' ? "\e[92m" : "\e[91m";
    printf("  \e[33m[%4d]\e[0m %-35s | %-22s | \e[96mDDC: %-8s\e[0m | %4s | Status: %s%-9s\e[0m\n",
        $self->{id}, $self->{title}, $self->{author},
        $self->{dewey}, $self->{year},
        $status_color, uc($self->{status}));
}
# Destructor — called by Perl garbage collector when ref count hits 0
sub DESTROY {
    my ($self) = @_;
    # Explicit cleanup — demonstrating GC awareness
    # (In production: close file handles, free C-level resources here)
    $self->{title}  = undef;
    $self->{author} = undef;
}

# --- CLASS: BorrowRecord ---
package BorrowRecord;
sub new {
    my ($class, %args) = @_;
    my $self = {
        borrow_id   => $args{borrow_id}   // undef,
        book_id     => $args{book_id}      // undef,
        patron_name => $args{patron_name}  // "Unknown",
        borrow_date => $args{borrow_date}  // "",
        due_date    => $args{due_date}     // "",
        return_date => $args{return_date}  // undef,
    };
    return bless $self, $class;
}
sub is_overdue {
    # Parameter passing by reference (implicit via $self)
    my ($self) = @_;
    return 0 if defined $self->{return_date};
    my $today = POSIX::strftime("%Y-%m-%d", localtime);
    return ($today gt $self->{due_date}) ? 1 : 0;
}
sub DESTROY {
    my ($self) = @_;
    $self->{patron_name} = undef;
}

# ============================================================
# Back to main package
# ============================================================
package main;

# Declare $dbh as a package global accessible to all subprograms
# (must be declared here since subs are defined before $dbh is assigned)
our $dbh;

# ============================================================
# SECTION 4 — DATABASE BOOTSTRAP
# Creates tables if they don't exist (first-run setup)
# ============================================================
sub bootstrap_database {
    my ($dbh) = @_;  # Parameter: database handle passed by reference

    # Books table
    $dbh->do(qq{
        CREATE TABLE IF NOT EXISTS books (
            id     INT AUTO_INCREMENT PRIMARY KEY,
            title  VARCHAR(255) NOT NULL,
            author VARCHAR(255) NOT NULL,
            dewey  VARCHAR(20)  NOT NULL DEFAULT '000',
            year   INT,
            status ENUM('available','borrowed') DEFAULT 'available'
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    }) or warn "Table 'books' may already exist.\n";

    # Borrow records table
    $dbh->do(qq{
        CREATE TABLE IF NOT EXISTS borrow_records (
            borrow_id   INT AUTO_INCREMENT PRIMARY KEY,
            book_id     INT          NOT NULL,
            patron_name VARCHAR(255) NOT NULL DEFAULT 'Walk-in Patron',
            borrow_date DATE         NOT NULL,
            due_date    DATE         NOT NULL,
            return_date DATE         DEFAULT NULL,
            FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    }) or warn "Table 'borrow_records' may already exist.\n";
}

# ============================================================
# SECTION 5 — UI HELPER SUBPROGRAMS
# (Subprograms + parameter passing demonstrations)
# ============================================================

# Clears screen cross-platform
sub cls { system($^O eq 'MSWin32' ? 'cls' : 'clear'); }

# Prints a decorative banner — parameter: title string (by value)
sub banner {
    my ($title) = @_;
    my $width = 64;
    my $pad   = int(($width - length($title)) / 2);
    print "\e[90m" . ("=" x $width) . "\e[0m\n";
    print " " x $pad . "\e[1;33m$title\e[0m\n";
    print "\e[90m" . ("=" x $width) . "\e[0m\n";
}

# Prints a section divider
sub divider { print "\e[90m" . ("-" x 64) . "\e[0m\n"; }

# Prompts user and returns trimmed input — demonstrates parameter passing
sub prompt {
    my ($msg, $default) = @_;   # Two params: message + optional default
    print "\e[36m  >> $msg\e[0m";
    print " \e[90m[$default]\e[0m" if defined $default;
    print ": ";
    my $input = <STDIN>;
    chomp $input;
    return (length($input) > 0) ? $input : ($default // "");
}

# Pause and wait for Enter
sub pause {
    print "\n\e[90m  Press ENTER to continue...\e[0m";
    <STDIN>;
}

# Prints the splash screen
sub splash_screen {
    cls();
    print "\e[1;33m";
    print "\n";
    print "   ___  ____   _    ____   _     ___ ____  \n";
    print "  / _ \\|  _ \\ / \\  / ___| | |   |_ _| __ ) \n";
    print " | | | | |_) / _ \\| |     | |    | ||  _ \\ \n";
    print " | |_| |  __/ ___ \\ |___  | |___ | || |_) |\n";
    print "  \\___/|_| /_/   \\_\\____| |_____|___|____/ \n";
    print "\e[0m\n";
    print "\e[96m      OPAC LIB — Online Public Access Catalog System\e[0m\n";
    print "\e[90m      Design & Implementation of Programming Languages\e[0m\n";
    print "\e[90m      Final Project | 2nd Semester SY $CONFIG{school_year}\e[0m\n";
    print "\n";
    print "\e[93m      Language: Perl 5  |  Version: $CONFIG{version}\e[0m\n";
    print "\n";
    divider();
    print "\e[90m  Connecting to database...\e[0m\n";
}

# ============================================================
# SECTION 6 — DEWEY DECIMAL BROWSER (Creative Feature)
# Full interactive DDC tree navigator
# ============================================================
sub dewey_browser {
    while (1) {
        cls();
        banner("DEWEY DECIMAL CLASSIFICATION BROWSER");
        print "\n";
        printf("  \e[1m%-6s  %-8s  %-45s\e[0m\n", "CLASS", "CODE", "SUBJECT AREA");
        divider();

        my $idx = 1;
        my @keys = sort keys %DDC;
        for my $class (@keys) {
            my $info = $DDC{$class};
            printf("  \e[33m[%d]\e[0m  %s%-5s\e[0m  %s%s\e[0m\n",
                $idx, $info->{color}, $class,
                $info->{color}, $info->{name});
            $idx++;
        }

        print "\n";
        print "  \e[33m[0]\e[0m  Return to Main Menu\n\n";

        my $choice = prompt("Select a class to explore (0 to go back)");
        last if $choice eq '0' || $choice eq '';

        if ($choice =~ /^\d+$/ && $choice >= 1 && $choice <= 10) {
            my $class_key = $keys[$choice - 1];
            dewey_detail($class_key);
        } else {
            print "\n\e[91m  Invalid selection.\e[0m\n";
            pause();
        }
    }
}

# Shows subdivisions of a DDC class and lists books in it
sub dewey_detail {
    my ($class_key) = @_;   # Parameter: DDC class string (by value)
    my $info = $DDC{$class_key};

    cls();
    banner("DDC CLASS $class_key — " . uc($info->{name}));
    print "\n";
    print "  \e[1mSUBDIVISIONS:\e[0m\n";
    divider();

    for my $sub_key (sort keys %{ $info->{subs} }) {
        printf("  %s%-5s\e[0m  %s\n",
            $info->{color}, $sub_key, $info->{subs}{$sub_key});
    }

    print "\n";
    print "  \e[1mBOOKS IN THIS CLASS (DDC $class_key.xxx):\e[0m\n";
    divider();

    # Query books matching this DDC range
    my $sth = $dbh->prepare("SELECT * FROM books WHERE dewey LIKE ? ORDER BY dewey ASC");
    $sth->execute("$class_key%");

    my $count = 0;
    while (my @row = $sth->fetchrow_array()) {
        my $book = Book->new(
            id     => $row[0],
            title  => $row[1],
            author => $row[2],
            dewey  => $row[3],
            year   => $row[4],
            status => $row[5],
        );
        $book->display();
        $count++;
        # $book goes out of scope here — GC runs DESTROY automatically
    }
    $sth->finish();   # Explicit resource release (memory management)
    undef $sth;       # Dereference for GC

    print "  \e[90m(No books found in this class)\e[0m\n" if $count == 0;
    print "\n  \e[93mTotal: $count book(s) found.\e[0m\n";
    pause();
}

# ============================================================
# SECTION 7 — CORE OPAC SUBPROGRAMS
# ============================================================

# --- ADD BOOK ---
sub add_book {
    cls();
    banner("ADD NEW BOOK");
    print "\n";

    my $title  = prompt("Book Title");
    my $author = prompt("Author");

    # Show DDC quick guide inline
    print "\n  \e[90m  DDC Quick Reference:\e[0m\n";
    for my $c (sort keys %DDC) {
        printf("    \e[90m%s — %s\e[0m\n", $c, $DDC{$c}{name});
    }
    print "\n";

    my $dewey  = prompt("Dewey Decimal (e.g., 005.133)", "000");
    my $year   = prompt("Year Published", "2024");

    # Input validation — demonstrating defensive programming
    unless ($title && $author) {
        print "\n\e[91m  ERROR: Title and Author are required.\e[0m\n";
        pause();
        return;
    }
    unless ($year =~ /^\d{4}$/ && $year >= 1000 && $year <= 2099) {
        print "\n\e[91m  ERROR: Year must be a 4-digit number (1000-2099).\e[0m\n";
        pause();
        return;
    }

    # Create Book object (OOP — encapsulation)
    my $book = Book->new(
        title  => $title,
        author => $author,
        dewey  => $dewey,
        year   => $year,
        status => 'available',
    );

    # Persist to database
    my $sql = "INSERT INTO books (title, author, dewey, year, status) VALUES (?, ?, ?, ?, ?)";
    my $sth = $dbh->prepare($sql);
    $sth->execute($book->{title}, $book->{author}, $book->{dewey}, $book->{year}, $book->{status});
    $sth->finish();
    undef $sth;   # Release statement handle — memory management

    # Determine DDC class description
    my $ddc_class = substr($dewey, 0, 3);
    $ddc_class    = sprintf("%03d", int($ddc_class / 100) * 100) if looks_like_number($ddc_class);
    my $ddc_name  = $DDC{$ddc_class}{name} // "Unknown Category";

    print "\n\e[92m  OK  Book added successfully!\e[0m\n";
    print "  \e[90m  Filed under DDC $ddc_class: $ddc_name\e[0m\n";
    # $book goes out of scope — DESTROY is called by GC
    pause();
}

# --- VIEW ALL BOOKS ---
sub view_books {
    cls();
    banner("CATALOG — ALL BOOKS");
    print "\n";

    my $sth = $dbh->prepare("SELECT * FROM books ORDER BY dewey ASC, title ASC");
    $sth->execute();

    printf("  \e[1m%-6s  %-35s  %-22s  %-10s  %-4s  %-9s\e[0m\n",
        "ID", "TITLE", "AUTHOR", "DDC", "YEAR", "STATUS");
    divider();

    my $count = 0;
    while (my @row = $sth->fetchrow_array()) {
        my $book = Book->new(
            id => $row[0], title => $row[1], author => $row[2],
            dewey => $row[3], year => $row[4], status => $row[5],
        );
        $book->display();
        $count++;
    }
    $sth->finish();
    undef $sth;

    divider();
    print "  \e[93mTotal books in catalog: $count\e[0m\n";
    pause();
}

# --- SEARCH BOOKS ---
sub search_books {
    cls();
    banner("SEARCH CATALOG");
    print "\n";
    print "  \e[33m[1]\e[0m Search by Title\n";
    print "  \e[33m[2]\e[0m Search by Author\n";
    print "  \e[33m[3]\e[0m Search by DDC Number\n\n";

    my $mode    = prompt("Search type");
    my $keyword = prompt("Enter search term");

    my ($field, $like);
    if    ($mode eq '1') { $field = "title";  $like = "%$keyword%"; }
    elsif ($mode eq '2') { $field = "author"; $like = "%$keyword%"; }
    elsif ($mode eq '3') { $field = "dewey";  $like = "$keyword%";  }
    else { print "\e[91m  Invalid.\e[0m\n"; pause(); return; }

    cls();
    banner("SEARCH RESULTS: \"$keyword\"");
    print "\n";

    my $sth = $dbh->prepare("SELECT * FROM books WHERE $field LIKE ? ORDER BY dewey ASC");
    $sth->execute($like);

    my $count = 0;
    while (my @row = $sth->fetchrow_array()) {
        my $book = Book->new(
            id => $row[0], title => $row[1], author => $row[2],
            dewey => $row[3], year => $row[4], status => $row[5],
        );
        $book->display();
        $count++;
    }
    $sth->finish();
    undef $sth;

    print "  \e[90m(No results found)\e[0m\n" if $count == 0;
    print "\n  \e[93m$count result(s) found.\e[0m\n";
    pause();
}

# --- EDIT BOOK ---
sub edit_book {
    cls();
    banner("EDIT BOOK RECORD");
    print "\n";

    my $id = prompt("Enter Book ID to edit");
    unless ($id =~ /^\d+$/) {
        print "\e[91m  Invalid ID.\e[0m\n"; pause(); return;
    }

    # Fetch existing record
    my $sth = $dbh->prepare("SELECT * FROM books WHERE id = ?");
    $sth->execute($id);
    my @row = $sth->fetchrow_array();
    $sth->finish(); undef $sth;

    unless (@row) {
        print "\n\e[91m  ERROR: No book found with ID $id.\e[0m\n";
        pause(); return;
    }

    # Load into object (OOP)
    my $book = Book->new(
        id => $row[0], title => $row[1], author => $row[2],
        dewey => $row[3], year => $row[4], status => $row[5],
    );

    print "\n  \e[90m  Current record:\e[0m\n  ";
    $book->display();
    print "\n  \e[90m  Leave blank to keep existing value.\e[0m\n\n";

    # Prompt with defaults (demonstrating optional parameter passing)
    my $title  = prompt("New Title",  $book->{title});
    my $author = prompt("New Author", $book->{author});
    my $dewey  = prompt("New DDC",    $book->{dewey});
    my $year   = prompt("New Year",   $book->{year});

    my $sql = "UPDATE books SET title=?, author=?, dewey=?, year=? WHERE id=?";
    my $sth2 = $dbh->prepare($sql);
    $sth2->execute($title, $author, $dewey, $year, $id);
    $sth2->finish(); undef $sth2;

    print "\n\e[92m  OK  Book ID $id updated successfully!\e[0m\n";
    pause();
}

# --- DELETE BOOK ---
sub delete_book {
    cls();
    banner("DELETE BOOK RECORD");
    print "\n";

    my $id = prompt("Enter Book ID to DELETE");
    unless ($id =~ /^\d+$/) {
        print "\e[91m  Invalid ID.\e[0m\n"; pause(); return;
    }

    my $sth = $dbh->prepare("SELECT title, author, status FROM books WHERE id = ?");
    $sth->execute($id);
    my ($title, $author, $status) = $sth->fetchrow_array();
    $sth->finish(); undef $sth;

    unless ($title) {
        print "\n\e[91m  No book found with ID $id.\e[0m\n";
        pause(); return;
    }

    if ($status eq 'borrowed') {
        print "\n\e[91m  Cannot delete a book that is currently borrowed!\e[0m\n";
        pause(); return;
    }

    print "\n  \e[91mAbout to delete:\e[0m\n";
    print "  Title:  $title\n";
    print "  Author: $author\n\n";

    my $confirm = prompt("Type YES to confirm deletion");
    if (uc($confirm) eq 'YES') {
        $dbh->do("DELETE FROM books WHERE id=?", undef, $id);
        print "\n\e[92m  OK  Book deleted successfully.\e[0m\n";
    } else {
        print "\n\e[93m  Deletion cancelled.\e[0m\n";
    }
    pause();
}

# --- BORROW BOOK ---
sub borrow_book {
    cls();
    banner("BORROW A BOOK");
    print "\n";

    my $id = prompt("Enter Book ID to borrow");
    unless ($id =~ /^\d+$/) {
        print "\e[91m  Invalid ID.\e[0m\n"; pause(); return;
    }

    my $sth = $dbh->prepare("SELECT title, author, status FROM books WHERE id = ?");
    $sth->execute($id);
    my ($title, $author, $status) = $sth->fetchrow_array();
    $sth->finish(); undef $sth;

    unless ($title) {
        print "\n\e[91m  No book found with ID $id.\e[0m\n";
        pause(); return;
    }
    if ($status eq 'borrowed') {
        print "\n\e[91m  Sorry! \"$title\" is currently borrowed.\e[0m\n";
        pause(); return;
    }

    print "\n  \e[92m  Available: \"$title\" by $author\e[0m\n\n";

    my $patron      = prompt("Patron Name");
    my $borrow_date = strftime("%Y-%m-%d", localtime);

    print "  \e[90m  Borrow Date (today): $borrow_date\e[0m\n";
    my $due_date = prompt("Due Date (YYYY-MM-DD)");

    # Basic date format validation
    unless ($due_date =~ /^\d{4}-\d{2}-\d{2}$/) {
        print "\n\e[91m  Invalid date format. Use YYYY-MM-DD.\e[0m\n";
        pause(); return;
    }
    if ($due_date le $borrow_date) {
        print "\n\e[91m  Due date must be after today.\e[0m\n";
        pause(); return;
    }

    # Create BorrowRecord object (OOP)
    my $record = BorrowRecord->new(
        book_id     => $id,
        patron_name => $patron,
        borrow_date => $borrow_date,
        due_date    => $due_date,
    );

    # Update DB — transaction-like approach
    $dbh->do("UPDATE books SET status='borrowed' WHERE id=?", undef, $id);
    $dbh->do(
        "INSERT INTO borrow_records (book_id, patron_name, borrow_date, due_date) VALUES (?,?,?,?)",
        undef, $record->{book_id}, $record->{patron_name},
               $record->{borrow_date}, $record->{due_date}
    );

    print "\n\e[92m  OK  Book borrowed successfully!\e[0m\n";
    print "  \e[93m  Patron : $patron\e[0m\n";
    print "  \e[93m  Due    : $due_date\e[0m\n";
    print "  \e[91m  Fee if returned late: PHP $CONFIG{fee_per_day}.00/day\e[0m\n";
    # $record out of scope — DESTROY fires
    pause();
}

# --- RETURN BOOK ---
sub return_book {
    cls();
    banner("RETURN A BOOK");
    print "\n";

    my $id = prompt("Enter Book ID to return");
    unless ($id =~ /^\d+$/) {
        print "\e[91m  Invalid ID.\e[0m\n"; pause(); return;
    }

    my $sth = $dbh->prepare("SELECT title, status FROM books WHERE id = ?");
    $sth->execute($id);
    my ($title, $status) = $sth->fetchrow_array();
    $sth->finish(); undef $sth;

    unless ($title) {
        print "\n\e[91m  No book found with ID $id.\e[0m\n";
        pause(); return;
    }
    if ($status eq 'available') {
        print "\n\e[93m  \"$title\" is not currently borrowed.\e[0m\n";
        pause(); return;
    }

    # Get active borrow record
    my $sth2 = $dbh->prepare(
        "SELECT borrow_id, patron_name, borrow_date, due_date
         FROM borrow_records WHERE book_id=? AND return_date IS NULL
         ORDER BY borrow_id DESC LIMIT 1"
    );
    $sth2->execute($id);
    my ($borrow_id, $patron, $borrow_date, $due_date) = $sth2->fetchrow_array();
    $sth2->finish(); undef $sth2;

    my $return_date = strftime("%Y-%m-%d", localtime);

    # Create object to use method (OOP demo)
    my $record = BorrowRecord->new(
        borrow_id   => $borrow_id,
        book_id     => $id,
        patron_name => $patron,
        borrow_date => $borrow_date,
        due_date    => $due_date,
    );

    # Compute overdue fee — calling subprogram with value parameters
    my $days_late = compute_days_late($due_date, $return_date);
    my $fee       = $days_late * $CONFIG{fee_per_day};

    # Update DB
    $dbh->do("UPDATE books SET status='available' WHERE id=?", undef, $id);
    $dbh->do("UPDATE borrow_records SET return_date=? WHERE borrow_id=?",
             undef, $return_date, $borrow_id);

    print "\n\e[92m  OK  Return recorded successfully!\e[0m\n\n";
    divider();
    printf("  %-20s %s\n", "Book:",     $title);
    printf("  %-20s %s\n", "Patron:",   $patron);
    printf("  %-20s %s\n", "Borrowed:", $borrow_date);
    printf("  %-20s %s\n", "Due Date:", $due_date);
    printf("  %-20s %s\n", "Returned:", $return_date);
    divider();

    if ($days_late > 0) {
        print "  \e[91m  OVERDUE: $days_late day(s) late\e[0m\n";
        print "  \e[91m  FINE:    PHP $fee.00 (PHP $CONFIG{fee_per_day}.00/day x $days_late days)\e[0m\n";
    } else {
        print "  \e[92m  Returned on time! No overdue fee.\e[0m\n";
    }
    # $record GC'd here
    pause();
}

# --- VIEW BORROW RECORDS ---
sub view_borrow_records {
    cls();
    banner("BORROW RECORDS & OVERDUE REPORT");
    print "\n";

    my $sth = $dbh->prepare(qq{
        SELECT br.borrow_id, b.title, b.dewey, br.patron_name,
               br.borrow_date, br.due_date, br.return_date
        FROM borrow_records br
        JOIN books b ON br.book_id = b.id
        ORDER BY br.borrow_date DESC
    });
    $sth->execute();

    my $today         = strftime("%Y-%m-%d", localtime);
    my $count         = 0;
    my $overdue_count = 0;

    printf("  \e[1m%-4s  %-28s  %-18s  %-12s  %-12s  %-10s  %s\e[0m\n",
        "ID", "TITLE", "PATRON", "BORROWED", "DUE", "RETURNED", "STATUS");
    divider();

    while (my @r = $sth->fetchrow_array()) {
        my ($bid, $title, $dewey, $patron, $bdate, $ddate, $rdate) = @r;
        my $ret_str = $rdate // "---";
        my ($status_str, $status_color);

        if ($rdate) {
            $status_str   = "RETURNED";
            $status_color = "\e[92m";
        } elsif ($today gt $ddate) {
            $status_str   = "OVERDUE";
            $status_color = "\e[91m";
            $overdue_count++;
        } else {
            $status_str   = "ACTIVE";
            $status_color = "\e[93m";
        }

        printf("  %-4d  %-28s  %-18s  %-12s  %-12s  %-10s  %s%s\e[0m\n",
            $bid,
            substr($title,  0, 27),
            substr($patron, 0, 17),
            $bdate, $ddate, $ret_str,
            $status_color, $status_str);
        $count++;
    }
    $sth->finish(); undef $sth;

    divider();
    print "  \e[93mTotal records: $count\e[0m";
    print "   \e[91m| Overdue: $overdue_count\e[0m" if $overdue_count > 0;
    print "\n";
    pause();
}

# ============================================================
# SECTION 8 — UTILITY SUBPROGRAMS
# Demonstrating: parameter passing by value, return values
# ============================================================

# Computes number of days a return is overdue
# Parameters: due date string, return date string (passed by value)
# Returns: integer days late (0 if not overdue)
sub compute_days_late {
    my ($due, $returned) = @_;   # Two value parameters

    my ($y1, $m1, $d1) = split(/-/, $due);
    my ($y2, $m2, $d2) = split(/-/, $returned);

    # Allocate time values (memory allocated on stack)
    my $t1 = timelocal(0, 0, 0, $d1, $m1 - 1, $y1);
    my $t2 = timelocal(0, 0, 0, $d2, $m2 - 1, $y2);

    my $diff = int(($t2 - $t1) / 86400);

    # t1, t2, diff go out of scope here — Perl GC reclaims
    return $diff > 0 ? $diff : 0;
}

# ============================================================
# SECTION 9 — STATISTICS DASHBOARD
# ============================================================
sub statistics {
    cls();
    banner("LIBRARY STATISTICS DASHBOARD");
    print "\n";

    my ($total)     = $dbh->selectrow_array("SELECT COUNT(*) FROM books");
    my ($available) = $dbh->selectrow_array("SELECT COUNT(*) FROM books WHERE status='available'");
    my ($borrowed)  = $dbh->selectrow_array("SELECT COUNT(*) FROM books WHERE status='borrowed'");
    my ($records)   = $dbh->selectrow_array("SELECT COUNT(*) FROM borrow_records");
    my ($overdue)   = $dbh->selectrow_array(
        "SELECT COUNT(*) FROM borrow_records WHERE return_date IS NULL AND due_date < CURDATE()"
    );

    my $avail_pct  = $total > 0 ? int($available / $total * 100) : 0;
    my $borrow_pct = $total > 0 ? int($borrowed  / $total * 100) : 0;

    printf("  \e[1m%-30s %s\e[0m\n\n", "METRIC", "VALUE");
    printf("  %-30s \e[96m%d\e[0m\n",        "Total Books in Catalog:",    $total);
    printf("  %-30s \e[92m%d (%d%%)\e[0m\n", "Available:",                 $available, $avail_pct);
    printf("  %-30s \e[93m%d (%d%%)\e[0m\n", "Currently Borrowed:",        $borrowed,  $borrow_pct);
    printf("  %-30s \e[91m%d\e[0m\n",        "Overdue Books:",             $overdue);
    printf("  %-30s \e[37m%d\e[0m\n",        "Total Borrow Transactions:", $records);

    print "\n  \e[1mBOOKS BY DDC CLASS:\e[0m\n";
    divider();

    for my $class (sort keys %DDC) {
        my ($cnt) = $dbh->selectrow_array(
            "SELECT COUNT(*) FROM books WHERE dewey LIKE ?", undef, "$class%"
        );
        next if $cnt == 0;
        my $bar = "\e[96m" . ("#" x ($cnt > 40 ? 40 : $cnt)) . "\e[0m";
        printf("  %s%-3s\e[0m %-14s %s \e[93m%d\e[0m\n",
            $DDC{$class}{color}, $class,
            substr($DDC{$class}{name}, 0, 13) . "..",
            $bar, $cnt);
    }
    pause();
}

# ============================================================
# SECTION 10 — ABOUT / PARADIGM INFO SCREEN
# ============================================================
sub about_screen {
    cls();
    banner("ABOUT OPAC LIB & LANGUAGE PARADIGMS");
    print "\n";
    print "  \e[1;96mPROGRAMMING LANGUAGE: Perl 5\e[0m\n\n";

    my @features = (
        ["Object-Oriented",      "Book & BorrowRecord classes using blessed hash refs"],
        ["Event-Driven",         "Dispatch table maps menu choices to code references"],
        ["Subprograms",          "Modular subs: add_book, return_book, compute_days_late..."],
        ["Parameter Passing",    "By value (\$scalar), by reference (\\\$ref), named (%args)"],
        ["Abstract Data Types",  "Hashes-as-structs: %DDC, %CONFIG, Book->new()"],
        ["Encapsulation",        "Data hidden inside blessed hash refs, access via ->{}"],
        ["Memory Management",    "undef \$sth, \$sth->finish(), explicit cleanup on exit"],
        ["Garbage Collection",   "Perl ref-counting: DESTROY called when ref count = 0"],
        ["Dewey Decimal",        "Full DDC browser with 100+ subdivisions + book lookup"],
    );

    for my $f (@features) {
        printf("  \e[33m%-25s\e[0m %s\n", $f->[0] . ":", $f->[1]);
    }

    print "\n";
    divider();
    print "  \e[90m  Final Project | 6DIPROGLANG | 2nd Semester SY $CONFIG{school_year}\e[0m\n";
    pause();
}

# ============================================================
# SECTION 11 — EVENT-DRIVEN DISPATCH TABLE
# (Maps menu codes to code references — event-driven paradigm)
# ============================================================
my %MENU_EVENTS = (
    '1' => \&add_book,
    '2' => \&view_books,
    '3' => \&search_books,
    '4' => \&edit_book,
    '5' => \&delete_book,
    '6' => \&borrow_book,
    '7' => \&return_book,
    '8' => \&view_borrow_records,
    '9' => \&dewey_browser,
    's' => \&statistics,
    'a' => \&about_screen,
);

# ============================================================
# SECTION 12 — MAIN PROGRAM ENTRY POINT
# ============================================================

# Show splash and connect
splash_screen();

# Assign to the pre-declared global $dbh
$dbh = DBI->connect(
    $CONFIG{dsn}, $CONFIG{user}, $CONFIG{password},
    { RaiseError => 0, PrintError => 0, AutoCommit => 1 }
) or do {
    print "\e[91m  FATAL: Cannot connect to database!\e[0m\n";
    print "  \e[90m  Error: " . DBI->errstr . "\e[0m\n\n";
    print "  Make sure XAMPP MySQL is running.\n";
    exit(1);
};

print "\e[92m  Connected to library_opac database!\e[0m\n";
print "\e[90m  Running first-time setup check...\e[0m\n";

# Bootstrap DB (create tables if needed)
bootstrap_database($dbh);   # Passing $dbh by reference

print "\e[92m  System ready.\e[0m\n";
sleep(1);

# ============================================================
# MAIN MENU LOOP — Event-Driven with dispatch table
# ============================================================
while (1) {
    cls();
    banner("$CONFIG{app_name} MAIN MENU");
    print "\n";
    print "  \e[33m[1]\e[0m  Add Book to Catalog\n";
    print "  \e[33m[2]\e[0m  View All Books\n";
    print "  \e[33m[3]\e[0m  Search Catalog\n";
    print "  \e[33m[4]\e[0m  Edit Book Record\n";
    print "  \e[33m[5]\e[0m  Delete Book Record\n";
    divider();
    print "  \e[33m[6]\e[0m  Borrow a Book\n";
    print "  \e[33m[7]\e[0m  Return a Book\n";
    print "  \e[33m[8]\e[0m  View Borrow Records / Overdue Report\n";
    divider();
    print "  \e[33m[9]\e[0m  Browse Dewey Decimal Classification\n";
    print "  \e[33m[S]\e[0m  Statistics Dashboard\n";
    print "  \e[33m[A]\e[0m  About / Language Paradigms\n";
    divider();
    print "  \e[33m[0]\e[0m  Exit\n\n";

    my $choice = prompt("Enter choice");
    $choice = lc($choice);

    last if $choice eq '0';

    # Event dispatch — look up handler in dispatch table (event-driven paradigm)
    if (exists $MENU_EVENTS{$choice}) {
        $MENU_EVENTS{$choice}->();   # Invoke code reference (event handler)
    } else {
        print "\n\e[91m  Invalid choice. Please try again.\e[0m\n";
        sleep(1);
    }
}

# ============================================================
# CLEANUP — Demonstrating explicit memory management
# and garbage collection on program exit
# ============================================================
END {
    # Explicit resource release (memory management)
    if (defined $dbh) {
        $dbh->disconnect();   # Release DB connection
        undef $dbh;           # Dereference — Perl GC will free the memory
    }
    # Perl's ref-counting GC will clean up all remaining objects here
    cls();
    print "\e[1;33m\n  Thank you for using OPAC LIB!\e[0m\n";
    print "\e[90m  All resources released. Goodbye.\e[0m\n\n";
}

# ============================================================
# END OF PROGRAM
# ============================================================