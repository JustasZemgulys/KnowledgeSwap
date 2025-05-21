-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: May 21, 2025 at 03:03 AM
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
-- Database: `knowledgeswap`
--

-- --------------------------------------------------------

--
-- Table structure for table `comment`
--

CREATE TABLE `comment` (
  `id` int(11) NOT NULL,
  `text` varchar(1000) DEFAULT NULL,
  `creation_date` datetime NOT NULL,
  `last_edit_date` datetime DEFAULT NULL,
  `fk_user` int(11) NOT NULL,
  `fk_item` int(11) NOT NULL,
  `fk_type` varchar(50) NOT NULL,
  `parent_id` int(11) DEFAULT NULL,
  `is_deleted` tinyint(1) DEFAULT 0,
  `score` int(11) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_lithuanian_ci;

--
-- Dumping data for table `comment`
--

INSERT INTO `comment` (`id`, `text`, `creation_date`, `last_edit_date`, `fk_user`, `fk_item`, `fk_type`, `parent_id`, `is_deleted`, `score`) VALUES
(6, 'Comment 1', '2025-05-21 03:41:49', NULL, 1, 15, 'resource', NULL, 0, 0),
(7, 'Comment 2', '2025-05-21 03:41:53', NULL, 1, 15, 'resource', NULL, 0, 0),
(8, 'Comment 1.1', '2025-05-21 03:42:01', NULL, 1, 15, 'resource', 6, 0, 0),
(9, 'Comment 1.1.1', '2025-05-21 03:42:11', NULL, 1, 15, 'resource', 8, 0, 0),
(10, 'Comment 1.2', '2025-05-21 03:42:22', NULL, 1, 15, 'resource', 6, 0, 0),
(11, 'Comment 1.2.1', '2025-05-21 03:42:31', NULL, 1, 15, 'resource', 10, 0, 0),
(12, 'Comment 1.2.2', '2025-05-21 03:42:41', NULL, 1, 15, 'resource', 10, 0, 0),
(13, 'Comment 1.1.1.1', '2025-05-21 03:42:57', NULL, 1, 15, 'resource', 9, 0, 0),
(14, 'Comment 1', '2025-05-21 03:52:09', NULL, 1, 1, 'forum_item', NULL, 0, 1),
(15, 'Comment 2', '2025-05-21 03:52:13', NULL, 1, 1, 'forum_item', NULL, 0, -1),
(16, 'Comment 3', '2025-05-21 03:52:17', NULL, 1, 1, 'forum_item', NULL, 0, 1),
(17, 'Comment 1.1', '2025-05-21 03:52:22', NULL, 1, 1, 'forum_item', 14, 0, 0),
(18, 'Comment 2.2', '2025-05-21 03:52:29', NULL, 1, 1, 'forum_item', 15, 0, 0),
(19, 'Comment 1.1.1', '2025-05-21 03:52:58', NULL, 1, 1, 'forum_item', 17, 0, 0),
(20, 'Comment 1.2', '2025-05-21 03:54:33', NULL, 1, 1, 'forum_item', 14, 0, 0),
(21, 'Comment 1.1.1.1', '2025-05-21 03:54:41', NULL, 1, 1, 'forum_item', 19, 0, 0),
(22, 'Comment 1', '2025-05-21 04:02:10', NULL, 3, 5, 'forum_item', NULL, 0, 0),
(23, 'Comment 1.1', '2025-05-21 04:02:24', NULL, 1, 5, 'forum_item', 22, 0, 0),
(24, 'Comment 1', '2025-05-21 04:03:01', NULL, 3, 3, 'forum_item', NULL, 0, 0),
(25, 'Comment 1.1', '2025-05-21 04:03:12', NULL, 1, 3, 'forum_item', 24, 0, 0);

-- --------------------------------------------------------

--
-- Table structure for table `forum_item`
--

CREATE TABLE `forum_item` (
  `id` int(11) NOT NULL,
  `title` varchar(255) NOT NULL,
  `description` text DEFAULT NULL,
  `score` int(11) NOT NULL DEFAULT 0,
  `fk_test` int(11) DEFAULT NULL,
  `fk_user` int(11) NOT NULL,
  `fk_group` int(11) DEFAULT NULL,
  `creation_date` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_lithuanian_ci;

--
-- Dumping data for table `forum_item`
--

INSERT INTO `forum_item` (`id`, `title`, `description`, `score`, `fk_test`, `fk_user`, `fk_group`, `creation_date`) VALUES
(1, 'Forum example', 'An example of a forum', 1, NULL, 1, NULL, '2025-05-21 03:39:15'),
(2, 'Shared test example', 'An example of a shared test', 1, 1, 1, NULL, '2025-05-21 03:51:30'),
(3, 'admin\'s answers', '', 0, 1, 1, 2, '2025-05-21 03:58:59'),
(4, 'example1\'s answers', '', 0, 1, 3, 2, '2025-05-21 04:00:47'),
(5, 'example1\'s answers', '', 0, 1, 3, 1, '2025-05-21 04:01:33');

-- --------------------------------------------------------

--
-- Table structure for table `forum_item_answer`
--

CREATE TABLE `forum_item_answer` (
  `id` int(11) NOT NULL,
  `fk_forum_item` int(11) NOT NULL,
  `fk_question` int(11) NOT NULL,
  `answer` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_lithuanian_ci;

--
-- Dumping data for table `forum_item_answer`
--

INSERT INTO `forum_item_answer` (`id`, `fk_forum_item`, `fk_question`, `answer`) VALUES
(1, 2, 1, 'User answer 1'),
(2, 2, 2, ''),
(3, 2, 3, 'User answer 2'),
(4, 3, 1, 'User answer 1'),
(5, 3, 2, 'User answer 2'),
(6, 3, 3, 'User answer 3'),
(7, 4, 1, 'User answer 1'),
(8, 4, 2, 'User answer 2'),
(9, 4, 3, 'User answer 3'),
(10, 5, 1, 'User answer 1'),
(11, 5, 2, 'User answer 2'),
(12, 5, 3, 'User answer 3');

-- --------------------------------------------------------

--
-- Table structure for table `group`
--

CREATE TABLE `group` (
  `id` int(11) NOT NULL,
  `creation_date` datetime NOT NULL,
  `name` varchar(255) NOT NULL,
  `description` varchar(255) NOT NULL,
  `visibility` tinyint(4) NOT NULL DEFAULT 1,
  `icon_path` varchar(255) DEFAULT NULL,
  `score` int(11) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_lithuanian_ci;

--
-- Dumping data for table `group`
--

INSERT INTO `group` (`id`, `creation_date`, `name`, `description`, `visibility`, `icon_path`, `score`) VALUES
(1, '2025-05-21 02:34:37', 'German grammar group', 'A group formed around german grammar', 1, NULL, 1),
(2, '2025-05-21 02:35:05', 'Programming group', 'A group formed around programming', 1, NULL, 1);

-- --------------------------------------------------------

--
-- Table structure for table `group_member`
--

CREATE TABLE `group_member` (
  `id` int(11) NOT NULL,
  `fk_user` int(11) NOT NULL,
  `fk_group` int(11) NOT NULL,
  `role` varchar(10) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_lithuanian_ci;

--
-- Dumping data for table `group_member`
--

INSERT INTO `group_member` (`id`, `fk_user`, `fk_group`, `role`) VALUES
(1, 1, 1, 'admin'),
(2, 1, 2, 'admin'),
(3, 3, 2, 'moderator'),
(4, 2, 2, 'banned'),
(6, 3, 1, 'moderator'),
(7, 2, 1, 'banned'),
(8, 4, 1, 'member'),
(9, 4, 2, 'member');

-- --------------------------------------------------------

--
-- Table structure for table `group_resource`
--

CREATE TABLE `group_resource` (
  `id` int(11) NOT NULL,
  `fk_resource` int(11) NOT NULL,
  `fk_group` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_lithuanian_ci;

--
-- Dumping data for table `group_resource`
--

INSERT INTO `group_resource` (`id`, `fk_resource`, `fk_group`) VALUES
(2, 2, 2),
(3, 13, 2),
(4, 12, 2),
(5, 14, 1),
(6, 1, 1);

-- --------------------------------------------------------

--
-- Table structure for table `group_test`
--

CREATE TABLE `group_test` (
  `id` int(11) NOT NULL,
  `fk_test` int(11) NOT NULL,
  `fk_group` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_lithuanian_ci;

--
-- Dumping data for table `group_test`
--

INSERT INTO `group_test` (`id`, `fk_test`, `fk_group`) VALUES
(1, 1, 2),
(2, 1, 1);

-- --------------------------------------------------------

--
-- Table structure for table `question`
--

CREATE TABLE `question` (
  `id` int(11) NOT NULL,
  `name` text NOT NULL,
  `description` text NOT NULL,
  `creation_date` datetime NOT NULL,
  `index` int(11) NOT NULL,
  `ai_made` tinyint(4) NOT NULL,
  `answer` text DEFAULT NULL,
  `fk_user` int(11) NOT NULL,
  `fk_test` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_lithuanian_ci;

--
-- Dumping data for table `question`
--

INSERT INTO `question` (`id`, `name`, `description`, `creation_date`, `index`, `ai_made`, `answer`, `fk_user`, `fk_test`) VALUES
(1, 'Question example 1', 'Question description 1', '2025-05-21 03:29:36', 1, 0, 'Question answer 1', 1, 1),
(2, 'Question example 2', 'Question description 2', '2025-05-21 03:29:36', 2, 0, 'Question answer 3', 1, 1),
(3, 'AI made question example', 'Question description 3', '2025-05-21 03:29:36', 3, 1, 'Question answer 3', 1, 1),
(4, 'What is the purpose of a URL in HTTP?', 'This question examines the role of a URL (Uniform Resource Locator) in HTTP (Hypertext Transfer Protocol). The answer will be taken directly from the section discussing URL in the given resource text.\n\nOptions:\n• A) To specify the protocol used for communication\n• B) To indicate the host computer where the information is located\n• C) To define the path to the file containing the information\n• D) To specify the port number of the server\n', '2025-05-21 03:33:10', 1, 1, 'C) To define the path to the file containing the information\n\nContext:\nThe URL defines four things: protocol, host computer, port, and path. The URL can optionally contain the port number of the server. If the port is included, it is inserted between the host and the path, and it is separated from the host by a colon. The path is the pathname of the file where the information is located. Note that the path can itself contain slashes that, in the UNIX operating system, separate the directories from the subdirectories and files.', 1, 2),
(5, 'What is the standard for specifying any kind of information on the Internet using HTTP?', 'This question examines the standard used for specifying any kind of information on the Internet using HTTP, as discussed in the resource text.\n\nOptions:\n• A) URL Protocol scheme\n• B) Host computer name\n• C) Port number\n• D) Path\n', '2025-05-21 03:33:10', 2, 1, 'A) URL Protocol scheme\n\nContext:\nThe uniform resource locator (URL) is a standard for specifying any kind of information on the Internet. The URL defines four things: protocol, host computer, port, and path. The URL Protocol specifies the client/server program used to retrieve the document. Many different protocols can retrieve a document; among them are FTP or HTTP. The most common today is HTTP.', 1, 2),
(6, 'What is the purpose of a Uniform Resource Locator (URL)?', 'This question examines the main purpose of a Uniform Resource Locator (URL) in the context of the World Wide Web (WWW) and HTTP. The answer will be taken directly from the resource text discussing URLs.\n\nOptions:\n• A) To store information about the client and server\n• B) To facilitate the access of documents distributed throughout the world\n• C) To specify any kind of information on the Internet\n', '2025-05-21 03:33:10', 3, 1, 'B) To facilitate the access of documents distributed throughout the world\n\nContext:\nThe URL defines four things: protocol, host computer, port, and path. The URL can optionally contain the port number of the server. If the port is included, it is inserted between the host and the path, and it is separated from the host by a colon. Path is the pathname of the file where the information is located. Note that the path can itself contain slashes that, in the UNIX operating system, separate the directories from the subdirectories and files. Cookies The World Wide Web was originally designed as a stateless entity. A client sends a request; a server responds. Their relationship is over. The original design of WWW, retrieving publicly available documents, exactly fits this purpose. Today the Web has other functions; some are listed here. I. Some websites need to allow access to registered clients only. 2. Websites are being used as electronic stores that allow users to browse through the store, select wanted items, put them in an electronic cart, and pay at the end with a credit card. Some websites are used as portals: the user selects the Web pages he wants to see. 4. Some websites are just advertising. Creation and Storage of Cookies The creation and storage of cookies depend on the implementation; however, the principle is the same. 1. When a server receives a request from a client, it stores information about the client in a file or a string. 3 The information may include the domain name of the client, the contents of the cookie (information the server has gathered about the client such as name, registration number, and so on), a timestamp, and other information depending on the implementation. 2. The server includes the cookie in the response that it sends to the client. 3. When the client receives the response, the browser stores the cookie in the cookie directory, which is sorted by the domain server name.', 1, 2),
(7, 'What is the primary component of a WWW browser architecture?', 'This question examines the structure of a WWW browser according to the resource content.', '2025-05-21 03:33:10', 4, 1, 'Correct answer: A variety of vendors offer commercial browsers that interpret and display a Web document, and all use nearly the same architecture. Each browser usually consists of three parts: a controller, client protocol, and interpreters.\n\nContext:\nEach browser usually consists of three parts: a controller, client protocol, and interpreters. The controller receives input from the keyboard or the mouse and uses the client programs to access the document. After the document has been accessed, the controller uses one of the interpreters to display the document on the screen. The client protocol can be one of the protocols described previously such as HTTP or HTTPS. The interpreter can be HTML, Java, or JavaScript, depending on the type of document.', 1, 2),
(8, 'What is the standard for specifying any kind of information on the Internet?', 'This question examines the standard used for specifying any kind of information on the Internet, as discussed in the context of URL in the provided resource text.', '2025-05-21 03:33:10', 5, 1, 'The uniform resource locator (URL) is the standard for specifying any kind of information on the Internet.\n\nContext:\nThe URL defines four things: protocol, host computer, port, and path. URL Protocol :// Host The protocol is the client/server program used to retrieve the document. Many different protocols can retrieve a document; among them are FTP or HTTP. The most common today is HTTP. The host is the computer on which the information is located, although the name of the computer can be an alias. Web pages are usually stored in computers, and computers are given alias names that usually begin with the characters \"www\". This is not mandatory, however, as the host can be any name given to the computer that hosts the Web page. The URL can optionally contain the port number of the server. If the port is included, it is inserted between the host and the path, and it is separated from the host by a colon. Path is the pathname of the file where the information is located. Note that the path can itself contain slashes that, in the UNIX operating system, separate the directories from the subdirectories and files.', 1, 2);

-- --------------------------------------------------------

--
-- Table structure for table `resource`
--

CREATE TABLE `resource` (
  `id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `description` varchar(255) NOT NULL,
  `resource_link` varchar(255) NOT NULL,
  `creation_date` datetime NOT NULL,
  `visibility` tinyint(1) NOT NULL DEFAULT 1,
  `resource_photo_link` varchar(255) DEFAULT NULL,
  `fk_user` int(11) NOT NULL,
  `score` int(11) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_lithuanian_ci;

--
-- Dumping data for table `resource`
--

INSERT INTO `resource` (`id`, `name`, `description`, `resource_link`, `creation_date`, `visibility`, `resource_photo_link`, `fk_user`, `score`) VALUES
(1, 'German Konjuktation', 'German grammar file. It talks about Konjuktation.', 'knowledgeswap/resources/682d1d3f797fb.png', '2025-05-20 23:40:08', 1, NULL, 1, 0),
(2, 'PHP file', 'PHP file', 'knowledgeswap/resources/682cf6e8d20cb_php.PNG', '2025-05-20 23:40:56', 1, NULL, 1, 0),
(10, 'WWW and HTML', 'A file about WWW and HTML', 'knowledgeswap/resources/682d1b25a5da0.pdf', '2025-05-21 01:34:00', 1, NULL, 1, 0),
(11, 'CSS', 'A file about CSS', 'knowledgeswap/resources/682d1b33f26e6_CSS.pdf', '2025-05-21 02:15:47', 1, NULL, 1, 0),
(12, 'C++', 'A file about C++', 'knowledgeswap/resources/682d1c90323a7_C++.pdf', '2025-05-21 02:21:36', 1, NULL, 1, 0),
(13, 'Python', 'A file about Python', 'knowledgeswap/resources/682d1cd914404_Python.pdf', '2025-05-21 02:22:49', 1, NULL, 1, 0),
(14, 'German Pronomen', 'A file about german Pronomen', 'knowledgeswap/resources/682d1d667c787_german grammar 2.PNG', '2025-05-21 02:25:10', 1, NULL, 1, 1),
(15, 'Resource example', 'Resource description example', 'knowledgeswap/resources/682d1e8d56a26_Test.PNG', '2025-05-21 02:30:05', 1, NULL, 1, -1);

-- --------------------------------------------------------

--
-- Table structure for table `test`
--

CREATE TABLE `test` (
  `id` int(11) NOT NULL,
  `name` text NOT NULL,
  `description` text NOT NULL,
  `creation_date` datetime NOT NULL,
  `visibility` tinyint(1) NOT NULL,
  `ai_made` tinyint(4) NOT NULL DEFAULT 0,
  `fk_user` int(11) NOT NULL,
  `fk_resource` int(11) DEFAULT NULL,
  `score` int(11) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_lithuanian_ci;

--
-- Dumping data for table `test`
--

INSERT INTO `test` (`id`, `name`, `description`, `creation_date`, `visibility`, `ai_made`, `fk_user`, `fk_resource`, `score`) VALUES
(1, 'Basic test example', 'A basic example of a test', '2025-05-21 03:29:36', 1, 0, 1, 15, 1),
(2, 'Test: WWW and HTML', 'Generated test based on resource: WWW and HTML', '2025-05-21 03:33:10', 0, 1, 1, 10, -1);

-- --------------------------------------------------------

--
-- Table structure for table `test_assignment`
--

CREATE TABLE `test_assignment` (
  `id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `description` text DEFAULT NULL,
  `fk_test` int(11) NOT NULL,
  `fk_resource` int(11) DEFAULT NULL,
  `open_date` datetime DEFAULT NULL,
  `due_date` datetime DEFAULT NULL,
  `fk_group` int(11) DEFAULT NULL,
  `fk_creator` int(11) NOT NULL,
  `creation_date` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_lithuanian_ci;

--
-- Dumping data for table `test_assignment`
--

INSERT INTO `test_assignment` (`id`, `name`, `description`, `fk_test`, `fk_resource`, `open_date`, `due_date`, `fk_group`, `fk_creator`, `creation_date`) VALUES
(1, 'Assignment example', 'An example of an assignment', 1, 15, '2025-04-21 03:36:00', '2025-06-21 03:36:00', 2, 1, '2025-05-21 03:36:52'),
(2, 'Assignment example', 'An example of an assignment', 1, 15, '2025-04-21 03:38:00', '2025-06-21 03:38:00', 1, 1, '2025-05-21 03:38:41');

-- --------------------------------------------------------

--
-- Table structure for table `test_assignment_user`
--

CREATE TABLE `test_assignment_user` (
  `id` int(11) NOT NULL,
  `fk_assignment` int(11) NOT NULL,
  `fk_user` int(11) NOT NULL,
  `assigned_date` datetime DEFAULT current_timestamp(),
  `completed` tinyint(1) DEFAULT 0,
  `completion_date` datetime DEFAULT NULL,
  `score` int(11) DEFAULT NULL,
  `comment` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_lithuanian_ci;

--
-- Dumping data for table `test_assignment_user`
--

INSERT INTO `test_assignment_user` (`id`, `fk_assignment`, `fk_user`, `assigned_date`, `completed`, `completion_date`, `score`, `comment`) VALUES
(4, 1, 1, '2025-05-21 03:58:41', 1, '2025-05-21 03:58:59', 10, 'Score comment example'),
(8, 1, 4, '2025-05-21 03:59:34', 0, NULL, NULL, NULL),
(9, 1, 3, '2025-05-21 03:59:34', 1, '2025-05-21 04:00:47', 10, 'Score comment example'),
(10, 2, 1, '2025-05-21 03:59:51', 0, NULL, NULL, NULL),
(11, 2, 3, '2025-05-21 03:59:51', 1, '2025-05-21 04:01:33', 10, 'Score comment example'),
(12, 2, 4, '2025-05-21 03:59:51', 0, NULL, NULL, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `test_resource`
--

CREATE TABLE `test_resource` (
  `id` int(11) NOT NULL,
  `fk_test` int(11) NOT NULL,
  `fk_resource` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_lithuanian_ci;

-- --------------------------------------------------------

--
-- Table structure for table `user`
--

CREATE TABLE `user` (
  `id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `email` varchar(255) NOT NULL,
  `password` varchar(255) NOT NULL,
  `last_visited` date NOT NULL DEFAULT current_timestamp(),
  `points` int(11) NOT NULL DEFAULT 100,
  `points_in_24h` int(11) NOT NULL DEFAULT 0,
  `points_in_week` int(11) NOT NULL DEFAULT 0,
  `points_in_month` int(11) NOT NULL DEFAULT 0,
  `creation_date` date NOT NULL DEFAULT current_timestamp(),
  `visibility` tinyint(1) NOT NULL DEFAULT 0,
  `imageURL` varchar(511) NOT NULL DEFAULT 'default'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_lithuanian_ci;

--
-- Dumping data for table `user`
--

INSERT INTO `user` (`id`, `name`, `email`, `password`, `last_visited`, `points`, `points_in_24h`, `points_in_week`, `points_in_month`, `creation_date`, `visibility`, `imageURL`) VALUES
(1, 'admin', 'justaszemgulys1@gmail.com', 'admin', '2025-05-21', 100, 0, 0, 0, '2025-05-21', 0, 'default'),
(2, 'example2', 'example2@gmail.com', 'example2', '2025-05-21', 100, 0, 0, 0, '2025-05-21', 0, 'default'),
(3, 'example1', 'example1@gmail.com', 'example1', '2025-05-21', 100, 0, 0, 0, '2025-05-21', 0, 'default'),
(4, 'example3', 'example3@gmail.com', 'example3', '2025-05-21', 100, 0, 0, 0, '2025-05-21', 0, 'default');

-- --------------------------------------------------------

--
-- Table structure for table `vote`
--

CREATE TABLE `vote` (
  `id` int(11) NOT NULL,
  `direction` int(11) NOT NULL,
  `fk_user` int(11) NOT NULL,
  `fk_item` int(11) NOT NULL,
  `fk_type` varchar(20) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_lithuanian_ci;

--
-- Dumping data for table `vote`
--

INSERT INTO `vote` (`id`, `direction`, `fk_user`, `fk_item`, `fk_type`, `created_at`) VALUES
(1, 1, 1, 16, 'comment', '2025-05-21 00:54:50'),
(2, -1, 1, 15, 'comment', '2025-05-21 00:54:51'),
(3, 1, 1, 14, 'comment', '2025-05-21 00:54:51'),
(4, 1, 1, 2, 'forum_item', '2025-05-21 00:54:56'),
(5, 1, 1, 1, 'forum_item', '2025-05-21 00:54:57'),
(6, -1, 1, 15, 'resource', '2025-05-21 00:55:03'),
(7, 1, 1, 14, 'resource', '2025-05-21 00:55:04'),
(8, -1, 1, 2, 'test', '2025-05-21 00:55:08'),
(9, 1, 1, 1, 'test', '2025-05-21 00:55:11'),
(10, 1, 1, 2, 'group', '2025-05-21 00:55:14'),
(11, 1, 1, 1, 'group', '2025-05-21 00:55:15');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `comment`
--
ALTER TABLE `comment`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_user` (`fk_user`);

--
-- Indexes for table `forum_item`
--
ALTER TABLE `forum_item`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_test` (`fk_test`),
  ADD KEY `fk_user` (`fk_user`);

--
-- Indexes for table `forum_item_answer`
--
ALTER TABLE `forum_item_answer`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_test` (`fk_forum_item`),
  ADD KEY `fk_question` (`fk_question`);

--
-- Indexes for table `group`
--
ALTER TABLE `group`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `group_member`
--
ALTER TABLE `group_member`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_user` (`fk_user`),
  ADD KEY `fk_group` (`fk_group`);

--
-- Indexes for table `group_resource`
--
ALTER TABLE `group_resource`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_group` (`fk_group`),
  ADD KEY `fk_resource` (`fk_resource`);

--
-- Indexes for table `group_test`
--
ALTER TABLE `group_test`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_group` (`fk_group`),
  ADD KEY `fk_test` (`fk_test`);

--
-- Indexes for table `question`
--
ALTER TABLE `question`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_user` (`fk_user`),
  ADD KEY `fk_test` (`fk_test`);

--
-- Indexes for table `resource`
--
ALTER TABLE `resource`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_user` (`fk_user`);

--
-- Indexes for table `test`
--
ALTER TABLE `test`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_user` (`fk_user`);

--
-- Indexes for table `test_assignment`
--
ALTER TABLE `test_assignment`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_test` (`fk_test`),
  ADD KEY `fk_resource` (`fk_resource`),
  ADD KEY `fk_group` (`fk_group`),
  ADD KEY `fk_creator` (`fk_creator`);

--
-- Indexes for table `test_assignment_user`
--
ALTER TABLE `test_assignment_user`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `fk_assignment` (`fk_assignment`,`fk_user`),
  ADD KEY `fk_user` (`fk_user`);

--
-- Indexes for table `test_resource`
--
ALTER TABLE `test_resource`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `fk_test` (`fk_test`,`fk_resource`),
  ADD KEY `fk_resource` (`fk_resource`);

--
-- Indexes for table `user`
--
ALTER TABLE `user`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `vote`
--
ALTER TABLE `vote`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_vote` (`fk_user`,`fk_item`,`fk_type`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `comment`
--
ALTER TABLE `comment`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=26;

--
-- AUTO_INCREMENT for table `forum_item`
--
ALTER TABLE `forum_item`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `forum_item_answer`
--
ALTER TABLE `forum_item_answer`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13;

--
-- AUTO_INCREMENT for table `group`
--
ALTER TABLE `group`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `group_member`
--
ALTER TABLE `group_member`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT for table `group_resource`
--
ALTER TABLE `group_resource`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `group_test`
--
ALTER TABLE `group_test`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `question`
--
ALTER TABLE `question`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `resource`
--
ALTER TABLE `resource`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=16;

--
-- AUTO_INCREMENT for table `test`
--
ALTER TABLE `test`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `test_assignment`
--
ALTER TABLE `test_assignment`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `test_assignment_user`
--
ALTER TABLE `test_assignment_user`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13;

--
-- AUTO_INCREMENT for table `test_resource`
--
ALTER TABLE `test_resource`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `user`
--
ALTER TABLE `user`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `vote`
--
ALTER TABLE `vote`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `comment`
--
ALTER TABLE `comment`
  ADD CONSTRAINT `comment_ibfk_1` FOREIGN KEY (`fk_user`) REFERENCES `user` (`id`);

--
-- Constraints for table `forum_item`
--
ALTER TABLE `forum_item`
  ADD CONSTRAINT `forum_item_ibfk_1` FOREIGN KEY (`fk_test`) REFERENCES `test` (`id`),
  ADD CONSTRAINT `forum_item_ibfk_2` FOREIGN KEY (`fk_user`) REFERENCES `user` (`id`);

--
-- Constraints for table `forum_item_answer`
--
ALTER TABLE `forum_item_answer`
  ADD CONSTRAINT `forum_item_answer_ibfk_1` FOREIGN KEY (`fk_forum_item`) REFERENCES `forum_item` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `forum_item_answer_ibfk_2` FOREIGN KEY (`fk_question`) REFERENCES `question` (`id`);

--
-- Constraints for table `group_member`
--
ALTER TABLE `group_member`
  ADD CONSTRAINT `group_member_ibfk_1` FOREIGN KEY (`fk_user`) REFERENCES `user` (`id`),
  ADD CONSTRAINT `group_member_ibfk_2` FOREIGN KEY (`fk_group`) REFERENCES `group` (`id`);

--
-- Constraints for table `group_resource`
--
ALTER TABLE `group_resource`
  ADD CONSTRAINT `group_resource_ibfk_1` FOREIGN KEY (`fk_group`) REFERENCES `group` (`id`),
  ADD CONSTRAINT `group_resource_ibfk_2` FOREIGN KEY (`fk_resource`) REFERENCES `resource` (`id`);

--
-- Constraints for table `group_test`
--
ALTER TABLE `group_test`
  ADD CONSTRAINT `group_test_ibfk_1` FOREIGN KEY (`fk_group`) REFERENCES `group` (`id`),
  ADD CONSTRAINT `group_test_ibfk_2` FOREIGN KEY (`fk_test`) REFERENCES `test` (`id`);

--
-- Constraints for table `question`
--
ALTER TABLE `question`
  ADD CONSTRAINT `question_ibfk_1` FOREIGN KEY (`fk_user`) REFERENCES `user` (`id`),
  ADD CONSTRAINT `question_ibfk_2` FOREIGN KEY (`fk_test`) REFERENCES `test` (`id`);

--
-- Constraints for table `resource`
--
ALTER TABLE `resource`
  ADD CONSTRAINT `resource_ibfk_1` FOREIGN KEY (`fk_user`) REFERENCES `user` (`id`);

--
-- Constraints for table `test`
--
ALTER TABLE `test`
  ADD CONSTRAINT `test_ibfk_1` FOREIGN KEY (`fk_user`) REFERENCES `user` (`id`);

--
-- Constraints for table `test_assignment`
--
ALTER TABLE `test_assignment`
  ADD CONSTRAINT `test_assignment_ibfk_1` FOREIGN KEY (`fk_test`) REFERENCES `test` (`id`),
  ADD CONSTRAINT `test_assignment_ibfk_2` FOREIGN KEY (`fk_resource`) REFERENCES `resource` (`id`),
  ADD CONSTRAINT `test_assignment_ibfk_3` FOREIGN KEY (`fk_group`) REFERENCES `group` (`id`),
  ADD CONSTRAINT `test_assignment_ibfk_4` FOREIGN KEY (`fk_creator`) REFERENCES `user` (`id`);

--
-- Constraints for table `test_assignment_user`
--
ALTER TABLE `test_assignment_user`
  ADD CONSTRAINT `test_assignment_user_ibfk_1` FOREIGN KEY (`fk_assignment`) REFERENCES `test_assignment` (`id`),
  ADD CONSTRAINT `test_assignment_user_ibfk_2` FOREIGN KEY (`fk_user`) REFERENCES `user` (`id`);

--
-- Constraints for table `test_resource`
--
ALTER TABLE `test_resource`
  ADD CONSTRAINT `test_resource_ibfk_1` FOREIGN KEY (`fk_test`) REFERENCES `test` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `test_resource_ibfk_2` FOREIGN KEY (`fk_resource`) REFERENCES `resource` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `vote`
--
ALTER TABLE `vote`
  ADD CONSTRAINT `vote_ibfk_1` FOREIGN KEY (`fk_user`) REFERENCES `user` (`id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
