-- MySQL dump 10.18  Distrib 10.3.27-MariaDB, for debian-linux-gnueabihf (armv8l)
--
-- Host: localhost    Database: pi_health_check
-- ------------------------------------------------------
-- Server version	10.3.27-MariaDB-0+deb10u1-log

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Current Database: `pi_health_check`
--

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `pi_health_check` /*!40100 DEFAULT CHARACTER SET utf8mb4 */;

USE `pi_health_check`;

--
-- Table structure for table `check_def`
--

DROP TABLE IF EXISTS `check_def`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `check_def` (
  `check_def_id` int(2) unsigned NOT NULL AUTO_INCREMENT,
  `code` varchar(5) NOT NULL,
  `name` varchar(20) NOT NULL,
  `description` varchar(255) DEFAULT NULL,
  `comment` varchar(255) DEFAULT NULL,
  `active` enum('Y','N') NOT NULL DEFAULT 'N',
  PRIMARY KEY (`check_def_id`) USING BTREE,
  UNIQUE KEY `code` (`code`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `check_def`
--

LOCK TABLES `check_def` WRITE;
/*!40000 ALTER TABLE `check_def` DISABLE KEYS */;
INSERT INTO `check_def` VALUES (1,'TEST','Test Check','This is an example of a Raspberry Pi Healthcheck definition record.','This is a comment.','Y');
/*!40000 ALTER TABLE `check_def` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `check_log`
--

DROP TABLE IF EXISTS `check_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `check_log` (
  `check_log_id` int(2) unsigned NOT NULL AUTO_INCREMENT,
  `check_code` varchar(5) NOT NULL,
  `status_code` varchar(2) NOT NULL,
  `timestamp` datetime DEFAULT current_timestamp(),
  `comment` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`check_log_id`) USING BTREE,
  KEY `FK1_CHECK_DEF_CODE` (`check_code`) USING BTREE,
  KEY `FK2_STATUS_DEF_CODE` (`status_code`),
  CONSTRAINT `FK1_CHECK_DEF_CODE` FOREIGN KEY (`check_code`) REFERENCES `check_def` (`code`),
  CONSTRAINT `FK2_STATUS_DEF_CODE` FOREIGN KEY (`status_code`) REFERENCES `status_def` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `check_log`
--

LOCK TABLES `check_log` WRITE;
/*!40000 ALTER TABLE `check_log` DISABLE KEYS */;
/*!40000 ALTER TABLE `check_log` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `status_def`
--

DROP TABLE IF EXISTS `status_def`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `status_def` (
  `status_def_id` int(2) unsigned NOT NULL AUTO_INCREMENT,
  `code` varchar(2) NOT NULL,
  `description` varchar(20) DEFAULT NULL,
  `active` enum('Y','N') NOT NULL DEFAULT 'N',
  PRIMARY KEY (`status_def_id`) USING BTREE,
  UNIQUE KEY `code` (`code`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `status_def`
--

LOCK TABLES `status_def` WRITE;
/*!40000 ALTER TABLE `status_def` DISABLE KEYS */;
INSERT INTO `status_def` VALUES (1,'OK','OK','Y'),(2,'WN','Warning','Y'),(3,'CR','Critical','Y'),(4,'ER','Error','Y');
/*!40000 ALTER TABLE `status_def` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2021-01-05 22:14:45
