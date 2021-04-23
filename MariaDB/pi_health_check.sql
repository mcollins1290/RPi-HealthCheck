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
  `check_def_id` tinyint(2) unsigned NOT NULL AUTO_INCREMENT,
  `code` varchar(5) NOT NULL,
  `name` varchar(30) NOT NULL,
  `description` varchar(255) DEFAULT NULL,
  `comment` varchar(255) DEFAULT NULL,
  `priority` tinyint(1) unsigned DEFAULT NULL,
  `active` enum('Y','N') NOT NULL DEFAULT 'N',
  PRIMARY KEY (`check_def_id`) USING BTREE,
  UNIQUE KEY `code` (`code`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `check_def`
--

LOCK TABLES `check_def` WRITE;
/*!40000 ALTER TABLE `check_def` DISABLE KEYS */;
INSERT INTO `check_def` VALUES (1,'SERV','RPi Service Checks','Logs from the RPi-ServCheck healthcheck process.',NULL,1,'Y'),(2,'TEMP','RPi CPU Temp Check','Logs from the RPi-TempCheck healthcheck process.',NULL,1,'Y'),(3,'VKILL','RPi VPN Killswitch Check','Logs from the External VPN Provider Killswitch healthcheck process.',NULL,1,'Y'),(4,'VUCHK','RPi VPN UP Check','Logs from the External VPN Provider UP healthcheck process.',NULL,2,'Y'),(5,'PHOLE','RPi PiHole Status Check','Logs from the PiHole Status Check.',NULL,2,'Y');
/*!40000 ALTER TABLE `check_def` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `check_log`
--

DROP TABLE IF EXISTS `check_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `check_log` (
  `check_log_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `check_code` varchar(5) NOT NULL,
  `status_code` varchar(2) NOT NULL,
  `context_code` varchar(2) NOT NULL,
  `timestamp` datetime DEFAULT current_timestamp(),
  `comment` text DEFAULT NULL,
  `hostname` varchar(255) NOT NULL,
  PRIMARY KEY (`check_log_id`) USING BTREE,
  KEY `FK1_CHECK_DEF_CODE` (`check_code`) USING BTREE,
  KEY `FK2_STATUS_DEF_CODE` (`status_code`),
  KEY `FK3_CONTEXT_DEF_CODE` (`context_code`),
  CONSTRAINT `FK1_CHECK_DEF_CODE` FOREIGN KEY (`check_code`) REFERENCES `check_def` (`code`),
  CONSTRAINT `FK2_STATUS_DEF_CODE` FOREIGN KEY (`status_code`) REFERENCES `status_def` (`code`),
  CONSTRAINT `FK3_CONTEXT_DEF_CODE` FOREIGN KEY (`context_code`) REFERENCES `context_def` (`code`)
) ENGINE=InnoDB AUTO_INCREMENT=10107 DEFAULT CHARSET=utf8mb4;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `context_def`
--

DROP TABLE IF EXISTS `context_def`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `context_def` (
  `context_def_id` tinyint(2) unsigned NOT NULL AUTO_INCREMENT,
  `code` varchar(2) NOT NULL,
  `description` varchar(20) DEFAULT NULL,
  `active` enum('Y','N') NOT NULL DEFAULT 'N',
  PRIMARY KEY (`context_def_id`) USING BTREE,
  UNIQUE KEY `code` (`code`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `context_def`
--

LOCK TABLES `context_def` WRITE;
/*!40000 ALTER TABLE `context_def` DISABLE KEYS */;
INSERT INTO `context_def` VALUES (1,'D','Daily','Y'),(2,'H','Hourly','Y'),(3,'M','Manually','Y'),(4,'R','Reboot','Y');
/*!40000 ALTER TABLE `context_def` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `gpio_def`
--

DROP TABLE IF EXISTS `gpio_def`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `gpio_def` (
  `gpio_def_id` tinyint(2) unsigned NOT NULL AUTO_INCREMENT,
  `status` varchar(1) NOT NULL,
  `pin` tinyint(2) unsigned NOT NULL DEFAULT 0,
  `brightness` tinyint(2) unsigned NOT NULL DEFAULT 100,
  `flash_freq` tinyint(2) unsigned NOT NULL DEFAULT 60,
  `enabled` enum('Y') DEFAULT NULL,
  `comment` varchar(255) DEFAULT NULL,
  `last_updated` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`gpio_def_id`),
  UNIQUE KEY `status` (`status`),
  UNIQUE KEY `pin` (`pin`),
  UNIQUE KEY `enabled` (`enabled`),
  CONSTRAINT `CHK_brightness` CHECK (`brightness` <= 100 and `brightness` >= 1)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `gpio_def`
--

LOCK TABLES `gpio_def` WRITE;
/*!40000 ALTER TABLE `gpio_def` DISABLE KEYS */;
INSERT INTO `gpio_def` VALUES (1,'O',27,1,255,NULL,'OK',NULL),(2,'W',22,10,1,NULL,'Warning',NULL),(3,'C',17,100,255,NULL,'Critical',NULL);
/*!40000 ALTER TABLE `gpio_def` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `status_def`
--

DROP TABLE IF EXISTS `status_def`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `status_def` (
  `status_def_id` tinyint(2) unsigned NOT NULL AUTO_INCREMENT,
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
INSERT INTO `status_def` VALUES (1,'0','OK','Y'),(2,'2','Warning','Y'),(3,'3','Critical','Y'),(4,'1','Error','Y');
/*!40000 ALTER TABLE `status_def` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping routines for database 'pi_health_check'
--
/*!50003 DROP FUNCTION IF EXISTS `GetCurrentStatus` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`%` FUNCTION `GetCurrentStatus`() RETURNS varchar(1) CHARSET utf8mb4
    READS SQL DATA
    COMMENT 'Function to check the latest grouped records of active check(s) results in the check_log table and return one of three statuses - Critical, Warning or OK.'
BEGIN
    DECLARE tmpval VARCHAR(1);
    
    -- Check for (C)ritical Status
    SET tmpval := (SELECT DISTINCT max(cl1.status_code)
						 FROM pi_health_check.check_log cl1,
									(SELECT cl2.check_code, max(cl2.timestamp) AS max_timestamp
									 FROM pi_health_check.check_log cl2
									 JOIN pi_health_check.check_def cd2 ON cd2.code = cl2.check_code
									 WHERE cd2.active = 'Y'
									 AND   cd2.priority = 1
									 GROUP BY cl2.check_code, cl2.hostname) latest_check_result
							WHERE cl1.check_code = latest_check_result.check_code
							AND cl1.timestamp = latest_check_result.max_timestamp);
    IF tmpval <> '0' THEN
		RETURN 'C'; -- Return 'C' for Critical
    END IF;
    
    -- Check for (W)arning Status
    SET tmpval := (SELECT DISTINCT max(cl1.status_code)
						 FROM pi_health_check.check_log cl1,
									(SELECT cl2.check_code, max(cl2.timestamp) AS max_timestamp
									 FROM pi_health_check.check_log cl2
									 JOIN pi_health_check.check_def cd2 ON cd2.code = cl2.check_code
									 WHERE cd2.active = 'Y'
									 AND   cd2.priority > 1
									 GROUP BY cl2.check_code, cl2.hostname) latest_check_result
							WHERE cl1.check_code = latest_check_result.check_code
							AND cl1.timestamp = latest_check_result.max_timestamp);
    IF tmpval <> '0' THEN
		RETURN 'W'; -- Return 'W' for Warning
    END IF;
    
    -- Check for (O)K Status
    SET tmpval := (SELECT DISTINCT max(cl1.status_code)
						 FROM pi_health_check.check_log cl1,
									(SELECT cl2.check_code, max(cl2.timestamp) AS max_timestamp
									 FROM pi_health_check.check_log cl2
									 JOIN pi_health_check.check_def cd2 ON cd2.code = cl2.check_code
									 WHERE cd2.active = 'Y'
									 GROUP BY cl2.check_code, cl2.hostname) latest_check_result
							WHERE cl1.check_code = latest_check_result.check_code
							AND cl1.timestamp = latest_check_result.max_timestamp);
    IF tmpval = '0' THEN
		RETURN 'O'; -- Return 'O' for OK
    END IF;
    
    -- Status can only be either Critical, Warning or OK. Anything else would indicate a Fault
    RETURN 'F'; -- Return 'F' for Fault    
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `prune_check_log` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`%` PROCEDURE `prune_check_log`(
	IN `offset_in` INT
)
BEGIN

	SET offset_in = IFNULL(offset_in, 30);
	DELETE FROM pi_health_check.check_log WHERE date(TIMESTAMP) < (CURDATE() - INTERVAL offset_in DAY);

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2021-04-16 13:41:19
