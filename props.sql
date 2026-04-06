
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

