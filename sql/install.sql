-- ============================================================================
--  KF_Police - Schema completo
--  ---------------------------------------------------------------------------
--  Idempotente: puo' essere rieseguito su un database esistente senza danni.
--  Caricato automaticamente all'avvio da server/sv_database.lua.
--  La chiave di riferimento e' `identifier` (stabile), con `ssn` come colonna
--  indicizzata di comodo per le ricerche.
-- ============================================================================

CREATE TABLE IF NOT EXISTS `kf_police_schema_version` (
    `version` INT NOT NULL,
    `applied_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`version`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
--  Profili
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `kf_police_profiles` (
    `identifier` VARCHAR(64) NOT NULL,
    `ssn` VARCHAR(32) NULL DEFAULT NULL,
    `mugshot` VARCHAR(512) NULL DEFAULT NULL,
    `is_wanted` TINYINT(1) NOT NULL DEFAULT 0,
    `wanted_reason` VARCHAR(255) NULL DEFAULT NULL,
    `wanted_by_id` VARCHAR(64) NULL DEFAULT NULL,
    `wanted_by_name` VARCHAR(100) NULL DEFAULT NULL,
    `wanted_at` DATETIME NULL DEFAULT NULL,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`identifier`),
    KEY `idx_profiles_ssn` (`ssn`),
    KEY `idx_profiles_wanted` (`is_wanted`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
--  Codice penale
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `kf_police_penalcode_categories` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `label` VARCHAR(100) NOT NULL,
    `icon` VARCHAR(48) NOT NULL DEFAULT 'penalcode',
    `sort_order` INT NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `kf_police_penalcode` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `code` VARCHAR(16) NULL DEFAULT NULL,
    `category_id` INT NULL DEFAULT NULL,
    `title` VARCHAR(255) NOT NULL,
    `description` TEXT NULL,
    `fine` INT NOT NULL DEFAULT 0,
    `jail_months` INT NOT NULL DEFAULT 0,
    `is_felony` TINYINT(1) NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_penalcode_code` (`code`),
    KEY `idx_penalcode_category` (`category_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
--  Reati
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `kf_police_charges` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `identifier` VARCHAR(64) NOT NULL,
    `penalcode_id` INT NULL DEFAULT NULL,
    `crime` VARCHAR(255) NOT NULL,
    `fine` INT NOT NULL DEFAULT 0,
    `jail_months` INT NOT NULL DEFAULT 0,
    `is_paid` TINYINT(1) NOT NULL DEFAULT 0,
    `officer_id` VARCHAR(64) NULL DEFAULT NULL,
    `officer_name` VARCHAR(100) NULL DEFAULT NULL,
    `location` VARCHAR(128) NULL DEFAULT NULL,
    `victim_identifier` VARCHAR(64) NULL DEFAULT NULL,
    `report_id` INT NULL DEFAULT NULL,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `voided_at` DATETIME NULL DEFAULT NULL,
    `voided_by` VARCHAR(100) NULL DEFAULT NULL,
    `void_reason` VARCHAR(255) NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_charges_identifier` (`identifier`),
    KEY `idx_charges_report` (`report_id`),
    KEY `idx_charges_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
--  Note
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `kf_police_notes` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `identifier` VARCHAR(64) NOT NULL,
    `note` TEXT NOT NULL,
    `officer_id` VARCHAR(64) NULL DEFAULT NULL,
    `officer_name` VARCHAR(100) NULL DEFAULT NULL,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_notes_identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
--  Rapporti + tabelle di giunzione
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `kf_police_reports` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `title` VARCHAR(255) NOT NULL,
    `description` LONGTEXT NULL,
    `officer` VARCHAR(100) NULL DEFAULT NULL,
    `officer_id` VARCHAR(64) NULL DEFAULT NULL,
    `location` VARCHAR(128) NULL DEFAULT 'Sconosciuto',
    `status` ENUM('draft','open','closed') NOT NULL DEFAULT 'open',
    `is_confidential` TINYINT(1) NOT NULL DEFAULT 0,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_reports_officer` (`officer_id`),
    KEY `idx_reports_status` (`status`),
    KEY `idx_reports_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `kf_police_report_involved` (
    `report_id` INT NOT NULL,
    `identifier` VARCHAR(64) NOT NULL,
    `role` ENUM('suspect','victim','witness') NOT NULL DEFAULT 'suspect',
    PRIMARY KEY (`report_id`, `identifier`, `role`),
    KEY `idx_involved_identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `kf_police_report_vehicles` (
    `report_id` INT NOT NULL,
    `plate` VARCHAR(12) NOT NULL,
    PRIMARY KEY (`report_id`, `plate`),
    KEY `idx_report_vehicles_plate` (`plate`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `kf_police_tags` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `label` VARCHAR(100) NOT NULL,
    `icon` VARCHAR(48) NOT NULL DEFAULT 'warning',
    `color` VARCHAR(16) NOT NULL DEFAULT '#A8322A',
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `kf_police_report_tags` (
    `report_id` INT NOT NULL,
    `tag_id` INT NOT NULL,
    PRIMARY KEY (`report_id`, `tag_id`),
    KEY `idx_report_tags_tag` (`tag_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
--  Veicoli
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `kf_police_vehicle_flags` (
    `plate` VARCHAR(12) NOT NULL,
    `is_stolen` TINYINT(1) NOT NULL DEFAULT 0,
    `is_impounded` TINYINT(1) NOT NULL DEFAULT 0,
    `impound_reason` VARCHAR(255) NULL DEFAULT NULL,
    `impound_by` VARCHAR(100) NULL DEFAULT NULL,
    `impound_at` DATETIME NULL DEFAULT NULL,
    `has_bolo` TINYINT(1) NOT NULL DEFAULT 0,
    `bolo_reason` VARCHAR(255) NULL DEFAULT NULL,
    `notes` TEXT NULL,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`plate`),
    KEY `idx_vehicle_flags_stolen` (`is_stolen`),
    KEY `idx_vehicle_flags_impounded` (`is_impounded`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
--  Carcere
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `kf_police_jail` (
    `identifier` VARCHAR(64) NOT NULL,
    `seconds_remaining` INT NOT NULL DEFAULT 0,
    `total_seconds` INT NOT NULL DEFAULT 0,
    `reason` VARCHAR(255) NULL DEFAULT NULL,
    `officer_id` VARCHAR(64) NULL DEFAULT NULL,
    `officer_name` VARCHAR(100) NULL DEFAULT NULL,
    `cell` VARCHAR(16) NULL DEFAULT NULL,
    `jailed_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `released_at` DATETIME NULL DEFAULT NULL,
    PRIMARY KEY (`identifier`),
    KEY `idx_jail_released` (`released_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
--  Armeria e servizio
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `kf_police_armory_stock` (
    `item` VARCHAR(64) NOT NULL,
    `count` INT NOT NULL DEFAULT 0,
    PRIMARY KEY (`item`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `kf_police_duty_log` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `identifier` VARCHAR(64) NOT NULL,
    `officer_name` VARCHAR(100) NULL DEFAULT NULL,
    `action` ENUM('in','out') NOT NULL,
    `at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_duty_identifier` (`identifier`),
    KEY `idx_duty_at` (`at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
--  Tracciabilita'
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `kf_police_audit` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `actor_identifier` VARCHAR(64) NULL DEFAULT NULL,
    `actor_name` VARCHAR(100) NULL DEFAULT NULL,
    `action` VARCHAR(64) NOT NULL,
    `target` VARCHAR(128) NULL DEFAULT NULL,
    `payload` LONGTEXT NULL,
    `at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_audit_actor` (`actor_identifier`),
    KEY `idx_audit_action` (`action`),
    KEY `idx_audit_at` (`at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--- Righe di kf_police_citizens il cui SSN non corrisponde a nessun utente:
--- conservate per revisione manuale invece di essere perse.
CREATE TABLE IF NOT EXISTS `kf_police_orphan_records` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `citizenid` VARCHAR(64) NOT NULL,
    `payload` LONGTEXT NULL,
    `reason` VARCHAR(128) NULL DEFAULT NULL,
    `imported_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_orphan_citizenid` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

