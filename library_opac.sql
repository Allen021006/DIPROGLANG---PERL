-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Mar 26, 2026 at 02:02 PM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `library_opac`
--

-- --------------------------------------------------------

--
-- Table structure for table `books`
--

CREATE TABLE `books` (
  `id` int(11) NOT NULL,
  `title` varchar(255) NOT NULL,
  `author` varchar(255) NOT NULL,
  `dewey` varchar(20) NOT NULL DEFAULT '000',
  `year` int(11) DEFAULT NULL,
  `status` enum('available','borrowed') DEFAULT 'available'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `books`
--

INSERT INTO `books` (`id`, `title`, `author`, `dewey`, `year`, `status`) VALUES
(1, 'Introduction to Algorithms', 'Thomas H. Cormen', '005.1', 2009, 'borrowed'),
(2, 'Meditations', 'Marcus Aurelius', '188', 2006, 'available'),
(3, 'The Purpose Driven Life', 'Rick Warren', '248.4', 2002, 'available'),
(4, 'Freakonomics', 'Steven D. Levitt', '330', 2005, 'available'),
(5, 'English Grammar in Use', 'Raymond Murphy', '425', 2019, 'borrowed'),
(6, 'A Brief History of Time', 'Stephen Hawking', '523.1', 1988, 'available'),
(7, 'The Innovators', 'Walter Isaacson', '620', 2014, 'available'),
(8, 'The Story of Art', 'E.H. Gombrich', '709', 1995, 'available'),
(9, 'To Kill a Mockingbird', 'Harper Lee', '813', 1960, 'available'),
(10, 'A Brief History of Humankind', 'Yuval Noah Harari', '909', 2011, 'borrowed'),
(11, 'Clean Architecture', 'Robert C. Martin', '005.1', 2017, 'available');

-- --------------------------------------------------------

--
-- Table structure for table `borrow_records`
--

CREATE TABLE `borrow_records` (
  `borrow_id` int(11) NOT NULL,
  `book_id` int(11) NOT NULL,
  `patron_name` varchar(255) NOT NULL DEFAULT 'Walk-in Patron',
  `borrow_date` date NOT NULL,
  `due_date` date NOT NULL,
  `return_date` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `borrow_records`
--

INSERT INTO `borrow_records` (`borrow_id`, `book_id`, `patron_name`, `borrow_date`, `due_date`, `return_date`) VALUES
(1, 1, 'Allen Panganiban', '2026-03-19', '2026-03-17', NULL),
(2, 5, 'Tyrone Aquino', '2026-03-19', '2026-03-27', NULL),
(3, 10, 'Shannon Priniel', '2026-03-19', '2026-03-24', NULL),
(4, 9, 'Benedict Sangalang', '2026-03-24', '2026-04-01', '2026-03-24');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `books`
--
ALTER TABLE `books`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `borrow_records`
--
ALTER TABLE `borrow_records`
  ADD PRIMARY KEY (`borrow_id`),
  ADD KEY `book_id` (`book_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `books`
--
ALTER TABLE `books`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- AUTO_INCREMENT for table `borrow_records`
--
ALTER TABLE `borrow_records`
  MODIFY `borrow_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `borrow_records`
--
ALTER TABLE `borrow_records`
  ADD CONSTRAINT `borrow_records_ibfk_1` FOREIGN KEY (`book_id`) REFERENCES `books` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
