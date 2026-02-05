-- --------------------------------------------------------
-- Host:                         127.0.0.1
-- Versión del servidor:         12.1.2-MariaDB - MariaDB Server
-- SO del servidor:              Win64
-- HeidiSQL Versión:             12.14.0.7165
-- --------------------------------------------------------

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET NAMES utf8 */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

-- Volcando estructura para tabla bloodline_test.m_props_created
CREATE TABLE IF NOT EXISTS `m_props_created` (
  `propid` int(11) NOT NULL AUTO_INCREMENT,
  `propname` varchar(255) NOT NULL,
  `x` float(12,6) NOT NULL DEFAULT 0.000000,
  `y` float(12,6) NOT NULL DEFAULT 0.000000,
  `z` float(12,6) NOT NULL DEFAULT 0.000000,
  `rotX` float(12,6) NOT NULL DEFAULT 0.000000,
  `rotY` float(12,6) NOT NULL DEFAULT 0.000000,
  `rotZ` float(12,6) NOT NULL DEFAULT 0.000000,
  `scale` float(12,6) NOT NULL DEFAULT 1.000000,
  `freeze` tinyint(1) NOT NULL DEFAULT 1,
  `colision` tinyint(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`propid`)
) ENGINE=InnoDB AUTO_INCREMENT=74 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- Volcando datos para la tabla bloodline_test.m_props_created: ~0 rows (aproximadamente)

/*!40103 SET TIME_ZONE=IFNULL(@OLD_TIME_ZONE, 'system') */;
/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IFNULL(@OLD_FOREIGN_KEY_CHECKS, 1) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40111 SET SQL_NOTES=IFNULL(@OLD_SQL_NOTES, 1) */;
