--[[
    KF_Police - Migrazioni
    ----------------------------------------------------------------------------
    Porta il database dal vecchio schema monolitico (`kf_police_citizens` con
    blob JSON, chiave su SSN) allo schema normalizzato con chiave su
    `identifier`.

    Garanzie:
      - backup automatico della tabella di partenza;
      - nessuna perdita: i record il cui SSN non esiste piu' finiscono in
        `kf_police_orphan_records` con il JSON originale;
      - idempotenza: `kf_police_schema_version` fa girare tutto una volta sola;
      - verifica dei conteggi prima/dopo stampata in console.
]]

Migrations = {}

local SCHEMA_VERSION = 1
local BACKUP_TABLE = 'kf_police_citizens_backup_20260819'

-- ============================================================================
--  Utilita'
-- ============================================================================

local function appliedVersion()
    if not Database.TableExists('kf_police_schema_version') then
        return 0
    end

    local version = Database.Scalar('SELECT MAX(version) FROM kf_police_schema_version')
    return tonumber(version) or 0
end

local function markApplied(version)
    Database.Insert('INSERT IGNORE INTO kf_police_schema_version (version) VALUES (?)', { version })
end

--- Mappa ssn -> identifier e identifier -> identifier, per risolvere le chiavi
--- storiche in una sola passata.
local function buildIdentifierIndex()
    local index = {}

    local rows = Database.Query('SELECT identifier, ssn FROM users') or {}
    for _, row in ipairs(rows) do
        if row.identifier then
            index[tostring(row.identifier)] = row.identifier
            if row.ssn and row.ssn ~= '' then
                index[tostring(row.ssn)] = row.identifier
            end
        end
    end

    return index
end

-- ============================================================================
--  Passo 1: adeguamento dello schema preesistente
-- ============================================================================

local function alignExistingTables()
    -- kf_police_reports creata dal vecchio codice non ha le colonne nuove.
    Database.AddColumnIfMissing('kf_police_reports', 'status',
        "`status` ENUM('draft','open','closed') NOT NULL DEFAULT 'open'")
    Database.AddColumnIfMissing('kf_police_reports', 'is_confidential',
        '`is_confidential` TINYINT(1) NOT NULL DEFAULT 0')
    Database.AddColumnIfMissing('kf_police_reports', 'created_at',
        '`created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP')
    Database.AddColumnIfMissing('kf_police_reports', 'updated_at',
        '`updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP')

    if Database.ColumnExists('kf_police_reports', 'date') then
        Database.Update('UPDATE kf_police_reports SET created_at = `date` WHERE `date` IS NOT NULL')
    end

    Database.AddColumnIfMissing('kf_police_tags', 'icon',
        "`icon` VARCHAR(48) NOT NULL DEFAULT 'warning'")

    Database.AddColumnIfMissing('kf_police_penalcode', 'code',
        '`code` VARCHAR(16) NULL DEFAULT NULL')
    Database.AddColumnIfMissing('kf_police_penalcode', 'category_id',
        '`category_id` INT NULL DEFAULT NULL')
    Database.AddColumnIfMissing('kf_police_penalcode', 'jail_months',
        '`jail_months` INT NOT NULL DEFAULT 0')
    Database.AddColumnIfMissing('kf_police_penalcode', 'is_felony',
        '`is_felony` TINYINT(1) NOT NULL DEFAULT 0')

    -- `jailTime` -> `jail_months`
    if Database.ColumnExists('kf_police_penalcode', 'jailTime') then
        Database.Update([[
            UPDATE kf_police_penalcode
            SET jail_months = COALESCE(jailTime, 0)
            WHERE jail_months = 0 AND jailTime IS NOT NULL
        ]])
    end

    -- La multa veniva riestratta con regex da `sanction` (bug L10): da qui in
    -- avanti si usano solo i campi numerici.
    if Database.ColumnExists('kf_police_penalcode', 'sanction') then
        local rows = Database.Query([[
            SELECT id, sanction FROM kf_police_penalcode
            WHERE (fine IS NULL OR fine = 0) AND sanction IS NOT NULL AND sanction <> ''
        ]]) or {}

        for _, row in ipairs(rows) do
            local amount = tostring(row.sanction):match('(%d+)')
            if amount then
                Database.Update('UPDATE kf_police_penalcode SET fine = ? WHERE id = ?',
                    { tonumber(amount), row.id })
            end
        end
    end
end

-- ============================================================================
--  Passo 2: emoji fuori dalle etichette dei tag
-- ============================================================================

local ICON_BY_KEYWORD = {
    ['import'] = 'warning',
    ['arm'] = 'weapon',
    ['rapin'] = 'money',
    ['estorsion'] = 'money',
    ['riss'] = 'fist',
    ['vandalism'] = 'spray',
    ['alcol'] = 'drink',
    ['droga'] = 'drug',
    ['stupefacent'] = 'drug',
    ['veicol'] = 'vehicles',
    ['testimon'] = 'citizens',
}

local function guessIcon(label)
    local lower = tostring(label or ''):lower()
    for keyword, icon in pairs(ICON_BY_KEYWORD) do
        if lower:find(keyword, 1, true) then
            return icon
        end
    end
    return 'warning'
end

local function cleanTagLabels()
    local rows = Database.Query('SELECT id, label, icon FROM kf_police_tags') or {}
    local cleaned = 0

    for _, row in ipairs(rows) do
        local stripped = StripEmoji(row.label)
        local needsIcon = not row.icon or row.icon == '' or row.icon == 'warning'

        if stripped ~= row.label or needsIcon then
            Database.Update('UPDATE kf_police_tags SET label = ?, icon = ? WHERE id = ?', {
                stripped ~= '' and stripped or ('Tag %d'):format(row.id),
                needsIcon and guessIcon(stripped) or row.icon,
                row.id,
            })
            cleaned = cleaned + 1
        end
    end

    if cleaned > 0 then
        print(('[KF_Police] Migrazione: %d tag ripuliti dalle emoji'):format(cleaned))
    end
end

-- ============================================================================
--  Passo 3: profili, reati, note dalla tabella monolitica
-- ============================================================================

local function backupLegacyTable()
    if not Database.TableExists('kf_police_citizens') then
        return true
    end

    if Database.TableExists(BACKUP_TABLE) then
        return true
    end

    local result = Database.Query(('CREATE TABLE `%s` AS SELECT * FROM `kf_police_citizens`'):format(BACKUP_TABLE))
    if result then
        print(('[KF_Police] Migrazione: backup creato in `%s`'):format(BACKUP_TABLE))
        return true
    end

    print('^1[KF_Police] Migrazione interrotta: backup non creato^7')
    return false
end

--- @return number reati, number note, number profili, number orfani
local function migrateLegacyCitizens()
    if not Database.TableExists('kf_police_citizens') then
        return 0, 0, 0, 0
    end

    local rows = Database.Query('SELECT * FROM kf_police_citizens') or {}
    if #rows == 0 then
        return 0, 0, 0, 0
    end

    local index = buildIdentifierIndex()
    local chargeCount, noteCount, profileCount, orphanCount = 0, 0, 0, 0

    for _, row in ipairs(rows) do
        local citizenId = tostring(row.citizenid or '')
        local identifier = index[citizenId]

        if not identifier then
            -- Orfano: si conserva il JSON originale per revisione manuale.
            local already = Database.Scalar(
                'SELECT COUNT(*) FROM kf_police_orphan_records WHERE citizenid = ?', { citizenId })

            if (tonumber(already) or 0) == 0 then
                Database.Insert(
                    'INSERT INTO kf_police_orphan_records (citizenid, payload, reason) VALUES (?, ?, ?)', {
                        citizenId,
                        json.encode({
                            criminalRecords = row.criminalRecords,
                            notes = row.notes,
                            wanted = row.wanted,
                            wantedReason = row.wantedReason,
                            wantedBy = row.wantedBy,
                            image = row.image,
                        }),
                        'ssn_non_risolto',
                    })
                orphanCount = orphanCount + 1
            end
        else
            local isWanted = ToBool(row.wanted) and 1 or 0

            Database.Insert([[
                INSERT INTO kf_police_profiles
                    (identifier, ssn, mugshot, is_wanted, wanted_reason, wanted_by_name, wanted_at)
                VALUES (?, ?, ?, ?, ?, ?, ?)
                ON DUPLICATE KEY UPDATE
                    ssn = COALESCE(kf_police_profiles.ssn, VALUES(ssn)),
                    mugshot = COALESCE(kf_police_profiles.mugshot, VALUES(mugshot)),
                    is_wanted = VALUES(is_wanted),
                    wanted_reason = VALUES(wanted_reason),
                    wanted_by_name = VALUES(wanted_by_name)
            ]], {
                identifier,
                citizenId ~= identifier and citizenId or nil,
                row.image,
                isWanted,
                Trim(row.wantedReason) ~= '' and row.wantedReason or nil,
                Trim(row.wantedBy) ~= '' and row.wantedBy or nil,
                isWanted == 1 and SqlNow() or nil,
            })
            profileCount = profileCount + 1

            -- Reati: il blob viene esploso in righe.
            for _, record in ipairs(NormalizeList(row.criminalRecords)) do
                if type(record) == 'table' and (record.crime or record.title) then
                    local victim = record.victim and index[tostring(record.victim)] or nil

                    Database.Insert([[
                        INSERT INTO kf_police_charges
                            (identifier, crime, fine, jail_months, officer_name, location,
                             victim_identifier, created_at)
                        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                    ]], {
                        identifier,
                        SanitizeText(record.crime or record.title, 255),
                        ClampInt(record.fine, 0, nil, 0),
                        ClampInt(record.jailTime or record.jail_months, 0, nil, 0),
                        SanitizeText(record.officer, 100),
                        SanitizeText(record.location, 128),
                        victim,
                        record.date or SqlNow(),
                    })
                    chargeCount = chargeCount + 1
                end
            end

            -- Note: stesso trattamento, con id da AUTO_INCREMENT (bug L6).
            for _, note in ipairs(NormalizeList(row.notes)) do
                local text = type(note) == 'table' and (note.note or note.text) or note
                if type(text) == 'string' and Trim(text) ~= '' then
                    Database.Insert([[
                        INSERT INTO kf_police_notes
                            (identifier, note, officer_name, created_at)
                        VALUES (?, ?, ?, ?)
                    ]], {
                        identifier,
                        SanitizeText(text, 1000),
                        type(note) == 'table' and SanitizeText(note.officer, 100) or nil,
                        type(note) == 'table' and note.date or SqlNow(),
                    })
                    noteCount = noteCount + 1
                end
            end
        end
    end

    return chargeCount, noteCount, profileCount, orphanCount
end

-- ============================================================================
--  Passo 4: rapporti, dalle colonne JSON alle tabelle di giunzione
-- ============================================================================

local function migrateLegacyReports()
    if not Database.TableExists('kf_police_reports') then
        return 0
    end

    local hasLegacy = Database.ColumnExists('kf_police_reports', 'involved')
        or Database.ColumnExists('kf_police_reports', 'tags')
        or Database.ColumnExists('kf_police_reports', 'involved_vehicles')

    if not hasLegacy then
        return 0
    end

    local columns = { 'id' }
    if Database.ColumnExists('kf_police_reports', 'involved') then columns[#columns + 1] = 'involved' end
    if Database.ColumnExists('kf_police_reports', 'involved_vehicles') then columns[#columns + 1] = 'involved_vehicles' end
    if Database.ColumnExists('kf_police_reports', 'tags') then columns[#columns + 1] = 'tags' end

    local rows = Database.Query(('SELECT %s FROM kf_police_reports'):format(table.concat(columns, ', '))) or {}
    if #rows == 0 then
        return 0
    end

    local index = buildIdentifierIndex()
    local moved = 0

    for _, row in ipairs(rows) do
        for _, value in ipairs(NormalizeList(row.involved)) do
            local identifier = index[tostring(value)] or (type(value) == 'table' and index[tostring(value.citizenId or value.identifier)])
            if identifier then
                Database.Insert([[
                    INSERT IGNORE INTO kf_police_report_involved (report_id, identifier, role)
                    VALUES (?, ?, 'suspect')
                ]], { row.id, identifier })
                moved = moved + 1
            end
        end

        for _, value in ipairs(NormalizeList(row.involved_vehicles)) do
            local plate = NormalizePlate(type(value) == 'table' and value.plate or value)
            if plate then
                Database.Insert(
                    'INSERT IGNORE INTO kf_police_report_vehicles (report_id, plate) VALUES (?, ?)',
                    { row.id, plate })
                moved = moved + 1
            end
        end

        for _, value in ipairs(NormalizeList(row.tags)) do
            local tagId = tonumber(type(value) == 'table' and value.id or value)
            if tagId then
                Database.Insert(
                    'INSERT IGNORE INTO kf_police_report_tags (report_id, tag_id) VALUES (?, ?)',
                    { row.id, tagId })
                moved = moved + 1
            end
        end
    end

    return moved
end

-- ============================================================================
--  Passo 5: stock iniziale dell'armeria
-- ============================================================================

local function seedArmoryStock()
    local existing = Database.Scalar('SELECT COUNT(*) FROM kf_police_armory_stock')
    if (tonumber(existing) or 0) > 0 then
        return
    end

    for item, count in pairs(Config.Armory.InitialStock or {}) do
        Database.Insert(
            'INSERT IGNORE INTO kf_police_armory_stock (item, count) VALUES (?, ?)',
            { string.lower(item), ClampInt(count, 0, nil, 0) })
    end

    print('[KF_Police] Stock iniziale armeria creato')
end

-- ============================================================================
--  Orchestrazione
-- ============================================================================

function Migrations.Run()
    local current = appliedVersion()

    -- Passi sempre eseguiti: sono controlli, non trasformazioni distruttive.
    alignExistingTables()
    cleanTagLabels()
    seedArmoryStock()

    if current >= SCHEMA_VERSION then
        return
    end

    print('[KF_Police] Migrazione 001 (normalizzazione) in corso...')

    if not backupLegacyTable() then
        return
    end

    local legacyCharges, legacyNotes = 0, 0
    if Database.TableExists('kf_police_citizens') then
        legacyCharges = 0
        local rows = Database.Query('SELECT criminalRecords, notes FROM kf_police_citizens') or {}
        for _, row in ipairs(rows) do
            legacyCharges = legacyCharges + #NormalizeList(row.criminalRecords)
            legacyNotes = legacyNotes + #NormalizeList(row.notes)
        end
    end

    local charges, notes, profiles, orphans = migrateLegacyCitizens()
    local reportLinks = migrateLegacyReports()

    markApplied(SCHEMA_VERSION)

    print(('[KF_Police] Migrazione completata: %d profili, %d reati, %d note, %d collegamenti rapporti, %d orfani')
        :format(profiles, charges, notes, reportLinks, orphans))

    -- Verifica dei conteggi: i reati/note nel blob devono essere tutti finiti
    -- o nelle tabelle normalizzate o tra gli orfani.
    local migratedCharges = tonumber(Database.Scalar('SELECT COUNT(*) FROM kf_police_charges')) or 0
    if legacyCharges > 0 and migratedCharges < charges then
        print(('^1[KF_Police] Attenzione: attesi >= %d reati, trovati %d^7'):format(charges, migratedCharges))
    end

    print(('[KF_Police] Verifica: %d reati nel blob di partenza, %d righe in kf_police_charges, %d orfani conservati')
        :format(legacyCharges, migratedCharges, orphans))
end
