-- MySQL dump 10.13  Distrib 8.0.43, for Win64 (x86_64)
--
-- Host: shuttle.proxy.rlwy.net    Database: inventory
-- ------------------------------------------------------
-- Server version	9.7.2

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;
SET @MYSQLDUMP_TEMP_LOG_BIN = @@SESSION.SQL_LOG_BIN;
SET @@SESSION.SQL_LOG_BIN= 0;

--
-- GTID state at the beginning of the backup 
--

SET @@GLOBAL.GTID_PURGED=/*!80000 '+'*/ '';

--
-- Table structure for table `dining_hall_consumption`
--

DROP TABLE IF EXISTS `dining_hall_consumption`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `dining_hall_consumption` (
  `issue_id` int NOT NULL AUTO_INCREMENT,
  `issueno` varchar(45) NOT NULL,
  `item_id` int NOT NULL,
  `po_item_id` int DEFAULT NULL,
  `department` varchar(45) DEFAULT NULL,
  `issued_to` varchar(100) NOT NULL,
  `qty_issued` decimal(10,2) NOT NULL,
  `issue_date` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `remarks` varchar(255) DEFAULT NULL,
  `indent_id` varchar(45) DEFAULT NULL,
  `unit_price` decimal(10,2) DEFAULT NULL,
  `total_value` decimal(12,2) DEFAULT NULL,
  `session` varchar(30) DEFAULT NULL,
  PRIMARY KEY (`issue_id`)
) ENGINE=InnoDB AUTO_INCREMENT=30188 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
SET @@SESSION.SQL_LOG_BIN = @MYSQLDUMP_TEMP_LOG_BIN;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-10-25 15:07:04
