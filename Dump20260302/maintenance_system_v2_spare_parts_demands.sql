-- MySQL dump 10.13  Distrib 8.0.33, for Win64 (x86_64)
--
-- Host: localhost    Database: maintenance_system_v2
-- ------------------------------------------------------
-- Server version	8.0.33

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

--
-- Table structure for table `spare_parts_demands`
--

DROP TABLE IF EXISTS `spare_parts_demands`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `spare_parts_demands` (
  `id` int NOT NULL AUTO_INCREMENT,
  `demand_number` varchar(50) NOT NULL,
  `maintenance_report_id` int DEFAULT NULL,
  `requestor_id` int NOT NULL,
  `department_id` int DEFAULT NULL,
  `material_id` int NOT NULL,
  `quantity_requested` int NOT NULL,
  `priority` enum('low','medium','high','urgent') DEFAULT 'medium',
  `reason` text,
  `supervisor_id` int DEFAULT NULL,
  `supervisor_approval` enum('pending','approved','rejected') DEFAULT 'pending',
  `supervisor_approval_date` datetime DEFAULT NULL,
  `supervisor_notes` text,
  `stock_agent_id` int DEFAULT NULL,
  `stock_agent_approval` enum('pending','approved','rejected','partial') DEFAULT 'pending',
  `stock_agent_approval_date` datetime DEFAULT NULL,
  `quantity_allocated` int DEFAULT NULL,
  `stock_agent_notes` text,
  `quantity_returned` int DEFAULT '0',
  `return_date` datetime DEFAULT NULL,
  `return_notes` text,
  `demand_status` enum('pending','supervisor_review','approved_supervisor','stock_agent_review','approved_stock_agent','rejected','partial_allocated','fulfilled') DEFAULT 'pending',
  `fulfilled_date` datetime DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `demand_number` (`demand_number`),
  KEY `maintenance_report_id` (`maintenance_report_id`),
  KEY `idx_created_at` (`created_at`),
  KEY `idx_demands_status` (`demand_status`),
  KEY `idx_material_id` (`material_id`),
  KEY `requestor_id` (`requestor_id`),
  KEY `supervisor_id` (`supervisor_id`),
  KEY `stock_agent_id` (`stock_agent_id`),
  KEY `idx_department_demands` (`department_id`),
  CONSTRAINT `spare_parts_demands_ibfk_1` FOREIGN KEY (`maintenance_report_id`) REFERENCES `maintenance_reports` (`id`) ON DELETE SET NULL,
  CONSTRAINT `spare_parts_demands_ibfk_2` FOREIGN KEY (`requestor_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `spare_parts_demands_ibfk_3` FOREIGN KEY (`material_id`) REFERENCES `materials` (`id`) ON DELETE CASCADE,
  CONSTRAINT `spare_parts_demands_ibfk_4` FOREIGN KEY (`supervisor_id`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `spare_parts_demands_ibfk_5` FOREIGN KEY (`stock_agent_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `spare_parts_demands`
--

LOCK TABLES `spare_parts_demands` WRITE;
/*!40000 ALTER TABLE `spare_parts_demands` DISABLE KEYS */;
INSERT INTO `spare_parts_demands` VALUES (1,'DEM-20260302-63C11B',1,5,NULL,115,1,'medium','needed nowwwwww',2,'approved','2026-03-02 10:18:02','nothing ',4,'approved','2026-03-02 10:44:04',1,'',0,NULL,NULL,'approved_stock_agent','2026-03-02 10:44:04','2026-03-02 09:06:59','2026-03-02 09:44:04');
/*!40000 ALTER TABLE `spare_parts_demands` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-03-02 11:54:22
