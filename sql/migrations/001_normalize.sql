-- ============================================================================
--  KF_Police - Migrazione 001: normalizzazione
--  ---------------------------------------------------------------------------
--  Questo file e' la versione manuale/di riferimento della migrazione. In
--  esecuzione normale la migrazione viene eseguita da server/sv_migrations.lua,
--  che fa le stesse operazioni in modo portabile (controlli su
--  information_schema invece di IF NOT EXISTS) e in piu' esplode i blob JSON
--  di `kf_police_citizens` nelle tabelle normalizzate.
--
--  Ordine: prima sql/install.sql, poi questo file.
--  E' idempotente: rieseguirlo non duplica nulla.
-- ============================================================================

-- ---------------------------------------------------------------------------
--  1. Backup della tabella monolitica prima di toccarla
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `kf_police_citizens_backup_20260819`
    AS SELECT * FROM `kf_police_citizens`;

-- ---------------------------------------------------------------------------
--  2. Adeguamento delle tabelle preesistenti al nuovo schema
-- ---------------------------------------------------------------------------

-- kf_police_reports: colonne nuove previste da 5.1
ALTER TABLE `kf_police_reports`
    ADD COLUMN IF NOT EXISTS `status` ENUM('draft','open','closed') NOT NULL DEFAULT 'open',
    ADD COLUMN IF NOT EXISTS `is_confidential` TINYINT(1) NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ADD COLUMN IF NOT EXISTS `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP;

-- Il vecchio schema usava `date`: il contenuto passa a `created_at`.
UPDATE `kf_police_reports`
    SET `created_at` = `date`
    WHERE `date` IS NOT NULL;

-- kf_police_tags: icona FontAwesome al posto dell'emoji nell'etichetta
ALTER TABLE `kf_police_tags`
    ADD COLUMN IF NOT EXISTS `icon` VARCHAR(48) NOT NULL DEFAULT 'warning';

-- kf_police_penalcode: codice, categoria, mesi di detenzione, gravita'
ALTER TABLE `kf_police_penalcode`
    ADD COLUMN IF NOT EXISTS `code` VARCHAR(16) NULL DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS `category_id` INT NULL DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS `jail_months` INT NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS `is_felony` TINYINT(1) NOT NULL DEFAULT 0;

-- `jailTime` del vecchio schema diventa `jail_months`
UPDATE `kf_police_penalcode`
    SET `jail_months` = COALESCE(`jailTime`, 0)
    WHERE `jail_months` = 0 AND `jailTime` IS NOT NULL;

-- La colonna `sanction` era una stringa gia' formattata da cui il codice
-- riestraeva la multa con una regex (bug L10): i campi numerici la sostituiscono.
UPDATE `kf_police_penalcode`
    SET `fine` = CAST(REGEXP_SUBSTR(`sanction`, '[0-9]+') AS UNSIGNED)
    WHERE (`fine` IS NULL OR `fine` = 0)
      AND `sanction` IS NOT NULL
      AND `sanction` REGEXP '[0-9]';

-- ---------------------------------------------------------------------------
--  3. Profili: da kf_police_citizens (chiave SSN) a identifier
-- ---------------------------------------------------------------------------
INSERT INTO `kf_police_profiles`
    (`identifier`, `ssn`, `mugshot`, `is_wanted`, `wanted_reason`, `wanted_by_name`, `wanted_at`)
SELECT
    u.`identifier`,
    c.`citizenid`,
    c.`image`,
    c.`wanted`,
    NULLIF(c.`wantedReason`, ''),
    NULLIF(c.`wantedBy`, ''),
    CASE WHEN c.`wanted` = 1 THEN NOW() ELSE NULL END
FROM `kf_police_citizens` c
INNER JOIN `users` u
    ON u.`ssn` = c.`citizenid` OR u.`identifier` = c.`citizenid`
ON DUPLICATE KEY UPDATE
    `ssn` = COALESCE(`kf_police_profiles`.`ssn`, VALUES(`ssn`)),
    `mugshot` = COALESCE(`kf_police_profiles`.`mugshot`, VALUES(`mugshot`));

-- ---------------------------------------------------------------------------
--  4. Orfani: righe il cui SSN non esiste piu' in users.
--     Conservate, non cancellate.
-- ---------------------------------------------------------------------------
INSERT INTO `kf_police_orphan_records` (`citizenid`, `payload`, `reason`)
SELECT
    c.`citizenid`,
    JSON_OBJECT(
        'criminalRecords', c.`criminalRecords`,
        'notes', c.`notes`,
        'wanted', c.`wanted`,
        'wantedReason', c.`wantedReason`,
        'wantedBy', c.`wantedBy`,
        'image', c.`image`
    ),
    'ssn_non_risolto'
FROM `kf_police_citizens` c
LEFT JOIN `users` u
    ON u.`ssn` = c.`citizenid` OR u.`identifier` = c.`citizenid`
WHERE u.`identifier` IS NULL
  AND NOT EXISTS (
      SELECT 1 FROM `kf_police_orphan_records` o WHERE o.`citizenid` = c.`citizenid`
  );

-- ---------------------------------------------------------------------------
--  5. Reati e note: l'esplosione dei blob JSON in righe avviene in
--     server/sv_migrations.lua, che sa decodificare le due forme storiche
--     (mappa e lista) presenti in `criminalRecords` e `notes`.
-- ---------------------------------------------------------------------------

-- ---------------------------------------------------------------------------
--  6. Versione dello schema: la migrazione gira una sola volta
-- ---------------------------------------------------------------------------
INSERT IGNORE INTO `kf_police_schema_version` (`version`) VALUES (1);
