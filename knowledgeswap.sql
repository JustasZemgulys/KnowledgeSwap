-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: May 12, 2025 at 08:24 AM
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
(41, 'TEST', '2025-04-04 03:24:42', NULL, 22, 26, 'test', NULL, 0, 1),
(44, 'TEST', '2025-04-04 03:26:15', NULL, 22, 26, 'resource', NULL, 1, 1),
(45, 'TEST', '2025-04-05 02:12:35', NULL, 21, 27, 'test', NULL, 0, 2),
(46, 'qwe', '2025-04-05 02:12:41', NULL, 21, 27, 'test', 45, 0, 0),
(47, '123', '2025-04-13 02:14:50', NULL, 21, 3, 'group', NULL, 0, 1),
(48, 'asd', '2025-04-13 02:15:57', NULL, 21, 3, 'group', NULL, 0, 0),
(49, 'qwert', '2025-04-13 02:16:56', NULL, 21, -3, 'group', NULL, 0, 0),
(50, '1', '2025-04-13 22:42:37', NULL, 21, 19, 'group', NULL, 0, 0),
(51, '2', '2025-04-13 22:46:00', NULL, 21, 19, 'group', NULL, 0, 0),
(52, 'a', '2025-04-13 22:46:05', NULL, 21, -19, 'group', NULL, 0, 0),
(53, 'b', '2025-04-13 22:46:07', NULL, 21, -19, 'group', NULL, 0, 0),
(54, 'aa', '2025-04-13 22:46:10', NULL, 21, -19, 'group', 52, 1, 0),
(55, 'bb', '2025-04-13 22:47:51', NULL, 21, -19, 'group', 53, 1, 0),
(56, 'bbb', '2025-04-13 22:47:54', NULL, 21, -19, 'group', 55, 0, 0),
(57, '1', '2025-04-13 23:32:43', NULL, 21, 20, 'group', NULL, 0, 0),
(58, '11', '2025-04-13 23:32:45', NULL, 21, 20, 'group', 57, 0, 0),
(59, '11', '2025-04-13 23:32:47', NULL, 21, 20, 'group', NULL, 0, 0),
(60, 'a', '2025-04-13 23:32:52', NULL, 21, -20, 'group', NULL, 0, 0),
(61, 'bb', '2025-04-13 23:32:55', NULL, 21, -20, 'group', NULL, 0, 0),
(62, 'aa', '2025-04-13 23:32:58', NULL, 21, -20, 'group', 60, 0, 0),
(63, 'asd', '2025-04-17 21:46:32', NULL, 21, 38, 'resource', NULL, 0, 0),
(67, 'asd', '2025-05-01 00:42:31', NULL, 21, 10, 'forum_item', NULL, 0, 0);

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
(26, 'SHARE TEST22', 'SHARE TEST desc', 1, 126, 21, NULL, '2025-05-11 03:37:37'),
(27, 'asd\'s answers', '', 0, 126, 21, 24, '2025-05-11 03:55:32'),
(28, 'asd\'s answers', '', 0, 127, 21, 24, '2025-05-12 04:53:58'),
(29, 'clone\'s answers', '', 0, 126, 22, 24, '2025-05-12 04:55:52'),
(30, 'clone\'s answers', '', 0, 126, 22, 24, '2025-05-12 05:06:05'),
(31, 'asd\'s answers', '', 0, 126, 21, 24, '2025-05-12 05:11:03'),
(32, 'asd\'s answers', '', 0, 127, 21, 24, '2025-05-12 05:17:11'),
(33, 'asd\'s answers', '', 0, 126, 21, 24, '2025-05-12 05:18:16'),
(34, 'asd\'s answers', '', 0, 127, 21, 24, '2025-05-12 05:19:32'),
(35, 'asd\'s answers', '', 0, 127, 21, 24, '2025-05-12 05:21:47'),
(36, 'asd\'s answers', '', 0, 126, 21, 24, '2025-05-12 05:28:02'),
(37, 'asd\'s answers', '', 0, 126, 21, 24, '2025-05-12 05:46:23'),
(38, 'asd\'s answers', '', 0, 126, 21, 24, '2025-05-12 05:47:39'),
(39, 'clone\'s answers', '', 0, 126, 22, 24, '2025-05-12 06:02:54'),
(40, 'tt', '', -1, NULL, 21, NULL, '2025-05-12 06:55:49');

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
(12, 34, 197, '123'),
(13, 35, 197, '123');

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
(24, '2025-05-11 02:39:51', 'TEST12345', 'TEST desc', 1, 'knowledgeswap/group_icons/68200c87bfc8c.jpg', 0),
(27, '2025-05-12 05:55:35', '2', '', 1, NULL, -1),
(28, '2025-05-12 06:01:32', 'private group', '', 0, NULL, 0);

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
(36, 21, 24, 'admin'),
(37, 22, 24, 'member'),
(38, 23, 24, 'banned'),
(41, 21, 27, 'admin'),
(42, 21, 28, 'admin');

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
(7, 50, 24);

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
(5, 126, 24);

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
(189, 'aaaaaaaaaaaaaaaaaaaaaaaaaa', '7459856-287459856-28\n7459856-28\n7459856-287459856-28\n7459856-28\n7459856-287459856-28\n7459856-28\n7459856-287459856-28\n7459856-28\n7459856-287459856-28\n7459856-28\n7459856-287459856-28\n7459856-28\n7459856-287459856-28\n7459856-28\n7459856-287459856-28\n7459856-28', '2025-05-10 04:56:32', 1, 0, '\naaaaaaaaaaaaaaaaaaaaaaaaaaasdasds\nasaaaaaaaaaaaaaaaaaaaaaaaaaaasdasds\nasaaaaaaaaaaaaaaaaaaaaaaaaaaasdasds\nasaaaaaaaaaaaaaaaaaaaaaaaaaaasdasds\nasaaaaaaaaaaaaaaaaaaaaaaaaaaasdasds\nasaaaaaaaaaaaaaaaaaaaaaaaaaaasdasds\nasaaaaaaaaaaaaaaaaaaaaaaaaaaasdasds\nasaa', 21, 124),
(192, 'What is the correct case for \"der Bekannte\" when used as a subject in a sentence?', 'This question examines the correct subject case for the noun \"der Bekannte\" as discussed in the section on adjectives used as nouns in the resource text.\n\nOptions:\n• A) Nominative\n• B) Accusative\n• C) Dative\n', '2025-05-10 05:00:10', 1, 1, 'A) Nominative\n\nContext:\nNominativ\nAkkusativ\n• der Bekannte\nden Bekannten\nein Bekannter\neinen Bekannten\n• die Bekannte\ndie Bekannte\neine Bekannte\neine Bekannte\n• die Bekannten\ndie Bekannten\n- Bekannte\n- Bekannte\nDativ\ndem Bekannten\neinem Bekannten\nder Beka', 21, 126),
(193, 'What is the correct form of the German adjective \"bekannt\" as a nominative noun?', 'This question examines the correct form of the German adjective \"bekannt\" used as a noun in the nominative case. The answer can be found in the provided resource text under the heading \"Adjektiv als Nomen: bekannt → die/der Bekannte\".', '2025-05-10 05:00:10', 2, 1, 'Correct answer: die Bekannte\n\nContext:\nNominativ\nAkkusativ\n• der Bekannte\nden Bekannten\nein Bekannter\neinen Bekannten\n• die Bekannte\ndie Bekannte\neine Bekannte\neine Bekannte\n• die Bekannten\ndie Bekannten\n- Bekannte\n- Bekannte\nDativ\ndem Bekannten\neinem Bek', 21, 126),
(194, 'Is the sentence \"Sind das die Bekannte, von der man nur Gutes sagen kann?\" grammatically correct?', 'This question examines the grammaticality of a sentence that uses a relative clause with a preposition in the resource text.', '2025-05-10 05:00:10', 3, 1, 'Yes, the sentence \"Sind das die Bekannte, von der man nur Gutes sagen kann?\" is grammatically correct.\n\nContext:\nThe sentence is an example of a relative clause with a preposition in the resource text under the section \"Relativsatz mit Präpositionen\" (Rel', 21, 126),
(195, 'What is the correct form of the German indefinite article when referring to a person?', 'This question examines the correct form of the German indefinite article (Artikel) when referring to a person. The answer will be taken directly from the section discussing the indefinite article in the resource text.', '2025-05-10 05:00:10', 4, 1, 'The correct form of the German indefinite article when referring to a person is \"der\" for males and \"die\" for females.\n\nContext:\n\"Nominativ • der Bekannte, den Bekannten, ein Bekannter, einen Bekannten • die Bekannte, die Bekannte, eine Bekannte, eine Bek', 21, 126),
(196, 'Question about Relativsatz with Präpositionen', 'This question examines the structure and usage of a Relativsatz with Präpositionen, as demonstrated in the resource text.\n\nOptions:\n• A) Which colleague is the one from whom everyone speaks well?\n• B) Which famous person is the one whom everyone can only ', '2025-05-10 05:00:10', 5, 1, 'A) Which colleague is the one from whom everyone speaks well?\n\nContext:\nIs that the colleague, from whom of whom everyone only speaks good things?', 21, 126),
(197, '1', '', '2025-05-11 03:25:11', 1, 0, '1', 21, 127),
(198, '1', '', '2025-05-12 07:01:22', 1, 0, '1', 21, 128),
(199, '1', '', '2025-05-12 07:04:56', 1, 0, '1', 22, 129);

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
(38, 'test111', 'test', 'knowledgeswap/resources/68015f92e0368.jpg', '2025-04-17 20:38:38', 1, 'knowledgeswap/icons/68015f92e0493.jpg', 21, -1),
(40, 'qwe', '', 'knowledgeswap/resources/680d58424c59a_asd.PNG', '2025-04-27 00:03:46', 1, NULL, 21, 0),
(41, 'qwe2', '', 'knowledgeswap/resources/680d58424c59a_asd.PNG', '2025-04-27 00:03:46', 1, NULL, 21, 0),
(42, 'qwe23', '', 'knowledgeswap/resources/680d58424c59a_asd.PNG', '2025-04-27 00:03:46', 1, NULL, 21, 0),
(43, 'qwe234', '', 'knowledgeswap/resources/680d58424c59a_asd.PNG', '2025-04-27 00:03:46', 1, NULL, 21, 0),
(44, 'PHP', '', 'knowledgeswap/resources/68141ed0e3785_php.PNG', '2025-05-02 03:24:32', 1, NULL, 21, 0),
(45, 'grammar', '', 'knowledgeswap/resources/681438fabd658_1.PNG', '2025-05-02 05:16:10', 1, NULL, 21, 0),
(48, '123', '', 'knowledgeswap/resources/681fe672a9673_30mb.pdf', '2025-05-11 01:51:14', 1, NULL, 21, 0),
(50, 'IT long', '', 'knowledgeswap/resources/681feb76efc19_IT book.pdf', '2025-05-11 02:12:39', 1, NULL, 21, -1);

-- --------------------------------------------------------

--
-- Table structure for table `test`
--

CREATE TABLE `test` (
  `id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `description` varchar(255) NOT NULL,
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
(124, 'aaaaaaaaaaaaa aaaaaaaaaaaaa', '7459856-287459856-28\n7459856-28\n7459856-287459856-28\n7459856-28\n7459856-287459856-28\n7459856-28\n7459856-287459856-28\n7459856-28', '2025-05-10 04:56:32', 1, 0, 21, NULL, -1),
(126, 'Test: grammar', 'Generated test based on resource: grammar', '2025-05-10 05:00:10', 0, 1, 21, 45, 1),
(127, '1', '', '2025-05-11 03:25:11', 1, 0, 21, 50, -1),
(128, 'private test1', '', '2025-05-12 07:01:22', 0, 0, 21, NULL, 0),
(129, 'test', '', '2025-05-12 07:04:56', 1, 0, 22, NULL, 0);

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
(21, 'asd', 'justaszemgulys1@gmail.com', 'asd', '2025-03-07', -3, -3, -3, -3, '2025-03-07', 0, 'https://pbs.twimg.com/media/GnpSAd3aAAAkAy3?format=jpg&name=900x900'),
(22, 'clone', 'clone@gmail.com', 'clone', '2025-03-07', 0, 0, 0, 0, '2025-03-07', 0, 'https://pbs.twimg.com/media/GmRYoJDa4AAYc72?format=jpg&name=large'),
(23, 'zxc', 'fake@gmail.com', 'zxc', '2025-03-07', 0, 0, 0, 0, '2025-03-07', 0, 'https://pbs.twimg.com/media/GobAiw9WAAAEDGj?format=jpg&name=medium');

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
(67, 1, 21, 3, 'group', '2025-04-12 21:44:31'),
(68, 1, 22, 9, 'group', '2025-04-12 22:47:42'),
(69, 1, 21, 47, 'comment', '2025-04-12 23:14:52'),
(70, 1, 22, 11, 'group', '2025-04-13 00:57:51'),
(71, 1, 21, 19, 'group', '2025-04-13 19:42:27'),
(72, 1, 21, 26, 'resource', '2025-04-14 21:53:43'),
(73, 1, 23, 26, 'resource', '2025-04-14 21:55:04'),
(74, -1, 21, 30, 'test', '2025-04-15 21:38:45'),
(75, -1, 21, 38, 'resource', '2025-04-17 18:46:26'),
(77, -1, 21, 64, 'comment', '2025-04-22 23:54:46'),
(78, 1, 21, 6, 'forum_item', '2025-04-30 22:21:35'),
(79, -1, 21, 50, 'resource', '2025-05-12 03:11:13'),
(80, -1, 21, 127, 'test', '2025-05-12 03:50:19'),
(81, -1, 21, 124, 'test', '2025-05-12 03:50:20'),
(82, 1, 21, 126, 'test', '2025-05-12 03:50:42'),
(83, -1, 21, 27, 'group', '2025-05-12 03:55:38'),
(84, -1, 21, 40, 'forum_item', '2025-05-12 03:55:51'),
(85, 1, 21, 26, 'forum_item', '2025-05-12 03:55:55'),
(86, 1, 21, 52, 'resource', '2025-05-12 05:25:53');

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
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=72;

--
-- AUTO_INCREMENT for table `forum_item`
--
ALTER TABLE `forum_item`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=41;

--
-- AUTO_INCREMENT for table `forum_item_answer`
--
ALTER TABLE `forum_item_answer`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=14;

--
-- AUTO_INCREMENT for table `group`
--
ALTER TABLE `group`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=29;

--
-- AUTO_INCREMENT for table `group_member`
--
ALTER TABLE `group_member`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=43;

--
-- AUTO_INCREMENT for table `group_resource`
--
ALTER TABLE `group_resource`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `group_test`
--
ALTER TABLE `group_test`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `question`
--
ALTER TABLE `question`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=200;

--
-- AUTO_INCREMENT for table `resource`
--
ALTER TABLE `resource`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=53;

--
-- AUTO_INCREMENT for table `test`
--
ALTER TABLE `test`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=130;

--
-- AUTO_INCREMENT for table `test_assignment`
--
ALTER TABLE `test_assignment`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `test_assignment_user`
--
ALTER TABLE `test_assignment_user`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=83;

--
-- AUTO_INCREMENT for table `test_resource`
--
ALTER TABLE `test_resource`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `user`
--
ALTER TABLE `user`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=25;

--
-- AUTO_INCREMENT for table `vote`
--
ALTER TABLE `vote`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=87;

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
