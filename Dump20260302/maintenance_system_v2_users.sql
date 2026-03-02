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
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` varchar(50) DEFAULT NULL,
  `username` varchar(100) NOT NULL,
  `password` varchar(255) NOT NULL,
  `email` varchar(100) NOT NULL,
  `first_name` varchar(100) DEFAULT NULL,
  `last_name` varchar(100) DEFAULT NULL,
  `role` enum('admin','supervisor','technician','stock_agent') NOT NULL DEFAULT 'technician',
  `department` varchar(100) DEFAULT NULL,
  `zone` varchar(100) DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT '1',
  `status` varchar(50) DEFAULT 'active',
  `supervisor_id` int DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `username` (`username`),
  UNIQUE KEY `email` (`email`),
  UNIQUE KEY `user_id` (`user_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_supervisor_id` (`supervisor_id`),
  KEY `idx_status_users` (`status`),
  KEY `idx_role` (`role`),
  KEY `idx_active` (`is_active`),
  CONSTRAINT `users_ibfk_1` FOREIGN KEY (`supervisor_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES (1,'ADM001','admin','admin123','admin@company.com','Admin','User','admin',NULL,NULL,1,'active',NULL,'2026-02-27 11:48:49','2026-02-27 11:49:13'),(2,'SUP001','supervisor','sup123','supervisor1@company.com','Jean','Dupont','supervisor',NULL,NULL,1,'active',NULL,'2026-02-27 11:48:49','2026-03-02 08:35:27'),(3,'TECH001','technician','tech123','tech1@company.com','Pierre','Martin','technician',NULL,NULL,1,'active',NULL,'2026-02-27 11:48:49','2026-03-02 08:35:27'),(4,'STOCK001','stocking','stock123','stock@company.com','Marie','Garcia','stock_agent',NULL,NULL,1,'active',NULL,'2026-02-27 11:48:49','2026-03-02 08:35:27'),(5,NULL,'test','scrypt:32768:8:1$JXhLLY0AQtzX1cIR$1783c192d54ba4ef905ded126fa1f7a683d8dd6ec775db8b4ecfaa611d2dfbebd57f5bf972a1b7717c9a6c34363d0db240013d123289509885924b5115c33f84','test@test.test','test','test','technician','test','Zone A',1,'active',2,'2026-03-02 08:08:58','2026-03-02 09:06:04'),(6,NULL,'test1','scrypt:32768:8:1$0ZtRlepfshI5Bkgg$1ab105137b41c0c6dc56330f70cccda1c214528c6af83fd6d563e0baafcb9308ee0228e410ad7b63498f808a147642b46cb47ce1d6076a0e682b29ed5d67b464','test1@test.test','test1','test1','technician','test','Zone B',1,'active',NULL,'2026-03-02 08:09:29','2026-03-02 08:09:29'),(7,NULL,'test2','scrypt:32768:8:1$byQdCTahhSFlKoh1$28ac415cbac0b5c839af6bc856d99ab567250a70adf936a4f4dc685361c04029d920c93b8b9167c08fb37cb322880f3c839698fbdfe5323c22c3831334d7af57','test2@test.test','test2','test2','technician','test','Zone C',1,'active',NULL,'2026-03-02 08:09:54','2026-03-02 08:09:54');
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-03-02 11:54:21
