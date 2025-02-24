-- phpMyAdmin SQL Dump
-- version 5.2.0
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Dec 17, 2023 at 05:16 AM
-- Server version: 10.4.27-MariaDB
-- PHP Version: 8.2.0

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
-- Table structure for table `favouritegenre`
--

CREATE TABLE `favouritegenre` (
  `idFavouriteGenre` int(11) NOT NULL,
  `IdUser` int(11) DEFAULT NULL,
  `IdGenre` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `favouritegenre`
--
ALTER TABLE `favouritegenre`
  ADD PRIMARY KEY (`idFavouriteGenre`),
  ADD KEY `IdUser_idx` (`IdUser`),
  ADD KEY `IdGenre_idx` (`IdGenre`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `favouritegenre`
--
ALTER TABLE `favouritegenre`
  MODIFY `idFavouriteGenre` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `favouritegenre`
--
ALTER TABLE `favouritegenre`
  ADD CONSTRAINT `FKIdGenre` FOREIGN KEY (`IdGenre`) REFERENCES `genre` (`idGenre`),
  ADD CONSTRAINT `FKIdUser` FOREIGN KEY (`IdUser`) REFERENCES `user` (`idUser`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
