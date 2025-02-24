-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Jan 03, 2024 at 11:33 AM
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
-- Database: `mellowde`
--

-- --------------------------------------------------------

--
-- Table structure for table `album`
--

CREATE TABLE `album` (
  `idAlbum` int(11) NOT NULL,
  `title` varchar(45) DEFAULT NULL,
  `coverURL` varchar(225) DEFAULT NULL,
  `IdArtist` int(11) DEFAULT NULL,
  `createdAt` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Dumping data for table `album`
--

INSERT INTO `album` (`idAlbum`, `title`, `coverURL`, `IdArtist`, `createdAt`) VALUES
(20, 'kurwanahuipisau', 'http://10.0.2.2/images/bg,f8f8f8-flat,750x,075,f-pad,750x1000,f8f8f8.jpg', 6, '2024-01-03 12:34:03');

-- --------------------------------------------------------

--
-- Table structure for table `artist`
--

CREATE TABLE `artist` (
  `idArtist` int(11) NOT NULL,
  `bio` longtext DEFAULT NULL,
  `rating` double DEFAULT NULL,
  `idUser` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Dumping data for table `artist`
--

INSERT INTO `artist` (`idArtist`, `bio`, `rating`, `idUser`) VALUES
(6, '', 0, 50),
(7, '', 0, 52);

-- --------------------------------------------------------

--
-- Table structure for table `comment`
--

CREATE TABLE `comment` (
  `idComment` int(11) NOT NULL,
  `text` varchar(45) DEFAULT NULL,
  `IdUser` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Dumping data for table `comment`
--

INSERT INTO `comment` (`idComment`, `text`, `IdUser`) VALUES
(2, 'dsdsdsdsd', 44);

-- --------------------------------------------------------

--
-- Table structure for table `favouritegenre`
--

CREATE TABLE `favouritegenre` (
  `idFavouriteGenre` int(11) NOT NULL,
  `IdUser` int(11) DEFAULT NULL,
  `IdGenre` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Dumping data for table `favouritegenre`
--

INSERT INTO `favouritegenre` (`idFavouriteGenre`, `IdUser`, `IdGenre`) VALUES
(16, 44, 1),
(17, 44, 3),
(18, 44, 4),
(19, 44, 5),
(20, 44, 6),
(31, 50, 1),
(32, 50, 3),
(33, 50, 4),
(34, 50, 5),
(35, 50, 6),
(36, 51, 3),
(37, 51, 6),
(38, 52, 3),
(39, 52, 6);

-- --------------------------------------------------------

--
-- Table structure for table `genre`
--

CREATE TABLE `genre` (
  `idGenre` int(11) NOT NULL,
  `name` varchar(45) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Dumping data for table `genre`
--

INSERT INTO `genre` (`idGenre`, `name`) VALUES
(1, 'Pop'),
(3, 'Rock'),
(4, 'Blues'),
(5, 'Jazz'),
(6, 'Punk');

-- --------------------------------------------------------

--
-- Table structure for table `playlist`
--

CREATE TABLE `playlist` (
  `playlistId` int(11) NOT NULL,
  `name` varchar(45) DEFAULT NULL,
  `description` varchar(225) DEFAULT NULL,
  `imageUrl` varchar(225) DEFAULT NULL,
  `userId` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Dumping data for table `playlist`
--

INSERT INTO `playlist` (`playlistId`, `name`, `description`, `imageUrl`, `userId`) VALUES
(34, 'dasdasdsad', 'qweawdawd', 'http://10.0.2.2/images/', 52);

-- --------------------------------------------------------

--
-- Table structure for table `playlistuser`
--

CREATE TABLE `playlistuser` (
  `idPlaylistUser` int(11) NOT NULL,
  `userRole` varchar(45) DEFAULT NULL,
  `playlistId` int(11) DEFAULT NULL,
  `userId` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Dumping data for table `playlistuser`
--

INSERT INTO `playlistuser` (`idPlaylistUser`, `userRole`, `playlistId`, `userId`) VALUES
(12, 'user', 34, 52);

-- --------------------------------------------------------

--
-- Table structure for table `queue`
--

CREATE TABLE `queue` (
  `idQueue` int(11) NOT NULL,
  `userId` int(11) DEFAULT NULL,
  `songId` int(11) DEFAULT NULL,
  `playlistId` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `song`
--

CREATE TABLE `song` (
  `idSong` int(11) NOT NULL,
  `title` varchar(45) DEFAULT NULL,
  `bio` text NOT NULL,
  `IdArtist` int(11) DEFAULT NULL,
  `coverURL` varchar(225) DEFAULT NULL,
  `songURL` varchar(225) NOT NULL,
  `IdGenre` int(11) DEFAULT NULL,
  `rating` double DEFAULT NULL,
  `IdAlbum` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Dumping data for table `song`
--

INSERT INTO `song` (`idSong`, `title`, `bio`, `IdArtist`, `coverURL`, `songURL`, `IdGenre`, `rating`, `IdAlbum`) VALUES
(15, 'cuteuwuuwusdasd', 'sadasdasd', 6, 'http://10.0.2.2/images/whats-an-egirl-jpg.jpg', 'http://10.0.2.2/songs/Rawrx3.mp3', 5, 0, 20),
(16, 'cuteuwusong3', 'uwusong3', 6, 'http://10.0.2.2/images/download.jpg', 'http://10.0.2.2/songs/Hyrule.mp3', 4, 0, 20),
(17, 'uwuboyxd', 'taip', 6, 'http://10.0.2.2/images/image.png', 'http://10.0.2.2/songs/Airiduko_rap_god.mp3', 5, 0, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `user`
--

CREATE TABLE `user` (
  `idUser` int(11) NOT NULL,
  `username` varchar(20) DEFAULT NULL,
  `name` varchar(20) DEFAULT NULL,
  `email` varchar(45) DEFAULT NULL,
  `imageURL` varchar(225) DEFAULT NULL,
  `userType` varchar(10) DEFAULT NULL,
  `password` varchar(225) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Dumping data for table `user`
--

INSERT INTO `user` (`idUser`, `username`, `name`, `email`, `imageURL`, `userType`, `password`) VALUES
(44, 'Rokenzis', 'Rokas', 'dstadaalius20@gmail.com', '', 'Listener', 'makarena12'),
(50, 'RokenzisArtist', 'Rokas', 'dstadaalius@gmail.com', '', 'Creator', 'makarena12'),
(51, 'shiver', 'Ignas', 'i73ignask@gmail.com', '', 'Listener', 'ignas999'),
(52, 'shover', 'Ignasuwu', 'unrealedlt500@gmail.com', '', 'Creator', 'ignas999');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `album`
--
ALTER TABLE `album`
  ADD PRIMARY KEY (`idAlbum`),
  ADD KEY `AlbumIdArtist_idx` (`IdArtist`);

--
-- Indexes for table `artist`
--
ALTER TABLE `artist`
  ADD PRIMARY KEY (`idArtist`),
  ADD KEY `idUser_idx` (`idUser`);

--
-- Indexes for table `comment`
--
ALTER TABLE `comment`
  ADD PRIMARY KEY (`idComment`),
  ADD KEY `CommentIdUser_idx` (`IdUser`);

--
-- Indexes for table `favouritegenre`
--
ALTER TABLE `favouritegenre`
  ADD PRIMARY KEY (`idFavouriteGenre`),
  ADD KEY `IdUser_idx` (`IdUser`),
  ADD KEY `IdGenre_idx` (`IdGenre`);

--
-- Indexes for table `genre`
--
ALTER TABLE `genre`
  ADD PRIMARY KEY (`idGenre`);

--
-- Indexes for table `playlist`
--
ALTER TABLE `playlist`
  ADD PRIMARY KEY (`playlistId`),
  ADD KEY `playlistUserId_idx` (`userId`);

--
-- Indexes for table `playlistuser`
--
ALTER TABLE `playlistuser`
  ADD PRIMARY KEY (`idPlaylistUser`),
  ADD KEY `playlistuserUserId_idx` (`userId`),
  ADD KEY `playlistuserPlaylistId_idx` (`playlistId`);

--
-- Indexes for table `queue`
--
ALTER TABLE `queue`
  ADD PRIMARY KEY (`idQueue`),
  ADD KEY `queueUserId_idx` (`userId`),
  ADD KEY `queueSongId_idx` (`songId`),
  ADD KEY `queuePlaylistId_idx` (`playlistId`);

--
-- Indexes for table `song`
--
ALTER TABLE `song`
  ADD PRIMARY KEY (`idSong`),
  ADD KEY `SongIdArtist_idx` (`IdArtist`),
  ADD KEY `SongIdGenre_idx` (`IdGenre`),
  ADD KEY `SongIdAlbum_idx` (`IdAlbum`);

--
-- Indexes for table `user`
--
ALTER TABLE `user`
  ADD PRIMARY KEY (`idUser`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `album`
--
ALTER TABLE `album`
  MODIFY `idAlbum` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=21;

--
-- AUTO_INCREMENT for table `artist`
--
ALTER TABLE `artist`
  MODIFY `idArtist` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `comment`
--
ALTER TABLE `comment`
  MODIFY `idComment` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `favouritegenre`
--
ALTER TABLE `favouritegenre`
  MODIFY `idFavouriteGenre` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=40;

--
-- AUTO_INCREMENT for table `genre`
--
ALTER TABLE `genre`
  MODIFY `idGenre` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `playlist`
--
ALTER TABLE `playlist`
  MODIFY `playlistId` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=35;

--
-- AUTO_INCREMENT for table `playlistuser`
--
ALTER TABLE `playlistuser`
  MODIFY `idPlaylistUser` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13;

--
-- AUTO_INCREMENT for table `queue`
--
ALTER TABLE `queue`
  MODIFY `idQueue` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `song`
--
ALTER TABLE `song`
  MODIFY `idSong` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=18;

--
-- AUTO_INCREMENT for table `user`
--
ALTER TABLE `user`
  MODIFY `idUser` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=53;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `album`
--
ALTER TABLE `album`
  ADD CONSTRAINT `AlbumIdArtist` FOREIGN KEY (`IdArtist`) REFERENCES `artist` (`idArtist`);

--
-- Constraints for table `comment`
--
ALTER TABLE `comment`
  ADD CONSTRAINT `CommentIdUser` FOREIGN KEY (`IdUser`) REFERENCES `user` (`idUser`);

--
-- Constraints for table `favouritegenre`
--
ALTER TABLE `favouritegenre`
  ADD CONSTRAINT `FKIdGenre` FOREIGN KEY (`IdGenre`) REFERENCES `genre` (`idGenre`),
  ADD CONSTRAINT `FKIdUser` FOREIGN KEY (`IdUser`) REFERENCES `user` (`idUser`);

--
-- Constraints for table `playlist`
--
ALTER TABLE `playlist`
  ADD CONSTRAINT `playlistUserId` FOREIGN KEY (`userId`) REFERENCES `user` (`idUser`);

--
-- Constraints for table `playlistuser`
--
ALTER TABLE `playlistuser`
  ADD CONSTRAINT `playlistuserPlaylistId` FOREIGN KEY (`playlistId`) REFERENCES `playlist` (`playlistId`),
  ADD CONSTRAINT `playlistuserUserId` FOREIGN KEY (`userId`) REFERENCES `user` (`idUser`);

--
-- Constraints for table `queue`
--
ALTER TABLE `queue`
  ADD CONSTRAINT `queuePlaylistId` FOREIGN KEY (`playlistId`) REFERENCES `playlist` (`playlistId`),
  ADD CONSTRAINT `queueSongId` FOREIGN KEY (`songId`) REFERENCES `song` (`idSong`),
  ADD CONSTRAINT `queueUserId` FOREIGN KEY (`userId`) REFERENCES `user` (`idUser`);

--
-- Constraints for table `song`
--
ALTER TABLE `song`
  ADD CONSTRAINT `SongIdAlbum` FOREIGN KEY (`IdAlbum`) REFERENCES `album` (`idAlbum`) ON DELETE SET NULL ON UPDATE SET NULL,
  ADD CONSTRAINT `SongIdArtist` FOREIGN KEY (`IdArtist`) REFERENCES `artist` (`idArtist`),
  ADD CONSTRAINT `SongIdGenre` FOREIGN KEY (`IdGenre`) REFERENCES `genre` (`idGenre`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
