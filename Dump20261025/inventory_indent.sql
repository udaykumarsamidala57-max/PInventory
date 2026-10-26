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
-- Table structure for table `indent`
--

DROP TABLE IF EXISTS `indent`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `indent` (
  `indent_id` int NOT NULL AUTO_INCREMENT,
  `indent_no` varchar(50) NOT NULL,
  `indent_date` varchar(50) NOT NULL,
  `item_id` int DEFAULT NULL,
  `item_name` varchar(150) NOT NULL,
  `qty` decimal(10,2) NOT NULL,
  `UOM` varchar(45) DEFAULT NULL,
  `department` varchar(100) NOT NULL,
  `requested_by` varchar(255) NOT NULL,
  `purpose` varchar(255) DEFAULT NULL,
  `remarks` varchar(255) DEFAULT NULL,
  `Istatus` varchar(45) DEFAULT 'Pending',
  `IstausApprove` varchar(45) DEFAULT NULL,
  `Iapprovedate` varchar(45) DEFAULT NULL,
  `status` varchar(50) DEFAULT 'Pending',
  `Fapprovedate` varchar(45) DEFAULT NULL,
  `Fapprovedby` varchar(255) DEFAULT NULL,
  `Indentnext` varchar(45) DEFAULT NULL,
  `POStatus` varchar(50) DEFAULT NULL,
  `Issued_qty` decimal(10,2) DEFAULT NULL,
  `Issued_status` varchar(45) DEFAULT 'Pending',
  `PurchaseorIssue` varchar(45) DEFAULT NULL,
  `stock` decimal(10,2) DEFAULT NULL,
  `event_id` int DEFAULT NULL,
  PRIMARY KEY (`indent_id`),
  KEY `fk_indent_item` (`item_id`),
  KEY `idx_indent_event` (`event_id`),
  CONSTRAINT `fk_indent_item` FOREIGN KEY (`item_id`) REFERENCES `item_master` (`Item_id`)
) ENGINE=InnoDB AUTO_INCREMENT=7375 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
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

-- Dump completed on 2026-10-25 15:06:55
