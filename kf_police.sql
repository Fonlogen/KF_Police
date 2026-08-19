-- KF_Police MDT
-- Importa questo file nel database ESX prima di avviare la risorsa.

CREATE TABLE IF NOT EXISTS `kf_police_citizens` (
  `citizenid` VARCHAR(50) NOT NULL,
  `criminalRecords` LONGTEXT NULL DEFAULT '{}',
  `wanted` TINYINT(1) NOT NULL DEFAULT 0,
  `wantedReason` VARCHAR(255) NULL DEFAULT NULL,
  `wantedBy` VARCHAR(100) NULL DEFAULT NULL,
  `notes` LONGTEXT NULL DEFAULT '[]',
  `image` VARCHAR(512) NULL DEFAULT NULL,
  PRIMARY KEY (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `kf_police_reports` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `title` VARCHAR(255) NOT NULL,
  `description` LONGTEXT NULL,
  `officer` VARCHAR(100) NULL,
  `officer_id` VARCHAR(50) NULL,
  `date` DATETIME NULL,
  `location` VARCHAR(255) NULL DEFAULT 'Unknown',
  `tags` LONGTEXT NULL DEFAULT '[]',
  `involved` LONGTEXT NULL DEFAULT '[]',
  `involved_vehicles` LONGTEXT NULL DEFAULT '[]',
  PRIMARY KEY (`id`),
  KEY `officer_id` (`officer_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `kf_police_tags` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `label` VARCHAR(100) NOT NULL,
  `color` VARCHAR(16) NULL DEFAULT '#333333',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `kf_police_penalcode` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `title` VARCHAR(255) NOT NULL,
  `description` LONGTEXT NULL,
  `sanction` VARCHAR(255) NULL,
  `fine` INT NULL DEFAULT NULL,
  `jailTime` INT NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `kf_police_tags` (`id`, `label`, `color`) VALUES
  (1, '⚠️ Importante', '#900000'),
  (2, '🔫 Armi', '#000090'),
  (3, '💰 Rapina', '#009000'),
  (4, '💸 Estorsione', '#009090'),
  (5, '👊 Rissa', '#900090'),
  (6, '🎨 Vandalismo', '#909000'),
  (7, '🍺 Alcol', '#909090')
ON DUPLICATE KEY UPDATE
  `label` = VALUES(`label`),
  `color` = VALUES(`color`);

INSERT INTO `kf_police_penalcode` (`id`, `title`, `description`, `sanction`, `fine`, `jailTime`) VALUES
  (1, 'Omicidio', 'Omicidio di una persona.', 'Multa: $10000 | Detenzione: 500 mesi', 10000, 500),
  (2, 'Rapina', 'Rapina a mano armata o con minaccia.', 'Multa: $5000 | Detenzione: 300 mesi', 5000, 300),
  (3, 'Furto', 'Sottrazione di beni altrui.', 'Multa: $3000 | Detenzione: 200 mesi', 3000, 200),
  (4, 'Estorsione', 'Richiesta di denaro o beni con minaccia.', 'Multa: $2000 | Detenzione: 100 mesi', 2000, 100),
  (5, 'Rissa', 'Rissa o aggressione in luogo pubblico.', 'Multa: $1000 | Detenzione: 50 mesi', 1000, 50),
  (6, 'Vandalismo', 'Danneggiamento di beni pubblici o privati.', 'Multa: $500 | Detenzione: 25 mesi', 500, 25),
  (7, 'Guida in stato di ebbrezza', 'Guida sotto effetto di alcol o stupefacenti.', 'Multa: $2000 | Detenzione: 100 mesi', 2000, 100)
ON DUPLICATE KEY UPDATE
  `title` = VALUES(`title`),
  `description` = VALUES(`description`),
  `sanction` = VALUES(`sanction`),
  `fine` = VALUES(`fine`),
  `jailTime` = VALUES(`jailTime`);
