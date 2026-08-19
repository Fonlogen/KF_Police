function UpdateMDTData()
    TriggerClientEvent('KF_Police:Client:RequestDataUpdate', -1)
end

local function notify(src, message, nType)
    TriggerClientEvent('esx:showNotification', src, message, nType or 'info', Config.NotificationsDuration)
end

function EnsurePoliceDatabase()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `kf_police_citizens` (
            `citizenid` VARCHAR(50) NOT NULL,
            `criminalRecords` LONGTEXT NULL DEFAULT '{}',
            `wanted` TINYINT(1) NOT NULL DEFAULT 0,
            `wantedReason` VARCHAR(255) NULL DEFAULT NULL,
            `wantedBy` VARCHAR(100) NULL DEFAULT NULL,
            `notes` LONGTEXT NULL DEFAULT '[]',
            `image` VARCHAR(512) NULL DEFAULT NULL,
            PRIMARY KEY (`citizenid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    MySQL.query.await([[
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
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `kf_police_tags` (
            `id` INT NOT NULL AUTO_INCREMENT,
            `label` VARCHAR(100) NOT NULL,
            `color` VARCHAR(16) NULL DEFAULT '#333333',
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `kf_police_penalcode` (
            `id` INT NOT NULL AUTO_INCREMENT,
            `title` VARCHAR(255) NOT NULL,
            `description` LONGTEXT NULL,
            `sanction` VARCHAR(255) NULL,
            `fine` INT NULL DEFAULT NULL,
            `jailTime` INT NULL DEFAULT NULL,
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    local function addColumnIfMissing(tableName, columnName, definition)
        local exists = MySQL.scalar.await(
            'SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? AND COLUMN_NAME = ?',
            { tableName, columnName }
        )
        if not exists or tonumber(exists) == 0 then
            MySQL.query.await(('ALTER TABLE `%s` ADD COLUMN %s'):format(tableName, definition))
        end
    end

    addColumnIfMissing('kf_police_citizens', 'wantedReason', '`wantedReason` VARCHAR(255) NULL DEFAULT NULL')
    addColumnIfMissing('kf_police_citizens', 'wantedBy', '`wantedBy` VARCHAR(100) NULL DEFAULT NULL')
    addColumnIfMissing('kf_police_citizens', 'notes', '`notes` LONGTEXT NULL DEFAULT \'[]\'')
    addColumnIfMissing('kf_police_citizens', 'image', '`image` VARCHAR(512) NULL DEFAULT NULL')
    addColumnIfMissing('kf_police_penalcode', 'fine', '`fine` INT NULL DEFAULT NULL')
    addColumnIfMissing('kf_police_penalcode', 'jailTime', '`jailTime` INT NULL DEFAULT NULL')

    MySQL.query.await([[
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
            `color` = VALUES(`color`)
    ]])

    MySQL.query.await([[
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
            `jailTime` = VALUES(`jailTime`)
    ]])
end

local function parseFine(article)
    if article.fine and tonumber(article.fine) then
        return tonumber(article.fine)
    end

    if type(article.sanction) == 'string' then
        local amount = article.sanction:match('%$(%d+)')
        return tonumber(amount)
    end

    return nil
end

local function nextRecordId(records)
    local maxId = 0
    for key, record in pairs(records or {}) do
        local id = tonumber(record.id) or tonumber(key) or 0
        if id > maxId then
            maxId = id
        end
    end
    return maxId + 1
end

local function recordsToList(records)
    local list = {}
    if type(records) ~= 'table' then
        return list
    end

    for _, record in pairs(records) do
        if type(record) == 'table' then
            list[#list + 1] = record
        end
    end

    table.sort(list, function(a, b)
        return (tonumber(a.id) or 0) < (tonumber(b.id) or 0)
    end)

    return list
end

local function persistCitizen(citizen)
    if not citizen then
        return
    end

    local records = recordsToList(citizen.criminalRecord or citizen.criminalRecords or {})
    citizen.criminalRecord = records
    citizen.criminalRecords = records

    MySQL.insert.await(
        'INSERT INTO kf_police_citizens (citizenid, criminalRecords, wanted, wantedReason, wantedBy, notes, image) VALUES (?, ?, ?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE criminalRecords = VALUES(criminalRecords), wanted = VALUES(wanted), wantedReason = VALUES(wantedReason), wantedBy = VALUES(wantedBy), notes = VALUES(notes), image = VALUES(image)',
        {
            tostring(citizen.citizenId),
            EncodeJson(records),
            citizen.wanted and 1 or 0,
            citizen.wantedReason or '',
            citizen.wantedBy or '',
            EncodeJson(NormalizeList(citizen.notes or {})),
            citizen.image
        }
    )
end

RegisterNetEvent('KF_Police:Server:CreateReport', function(data)
    local src = source
    local xPlayer = GetOfficer(src)
    if not xPlayer or type(data) ~= 'table' then
        return notify(src, Locale('invalid_data'), 'error')
    end

    local title = data.title and tostring(data.title):gsub('^%s+', ''):gsub('%s+$', '') or ''
    if title == '' then
        return notify(src, Locale('invalid_data'), 'error')
    end

    local insertId = MySQL.insert.await(
        'INSERT INTO kf_police_reports (title, description, officer, officer_id, date, location, tags, involved, involved_vehicles) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
        {
            title,
            data.description or '',
            GetOfficerName(xPlayer),
            xPlayer.getSSN and xPlayer.getSSN() or xPlayer.identifier,
            os.date('%Y-%m-%d %H:%M:%S'),
            data.location or 'Unknown',
            EncodeJson(data.tags or {}),
            EncodeJson(data.involved or {}),
            EncodeJson(data.involved_vehicles or {}),
        }
    )

    if not insertId then
        return notify(src, Locale('report_create_failed'), 'error')
    end

    reports[tostring(insertId)] = {
        id = insertId,
        title = title,
        description = data.description or '',
        officer = GetOfficerName(xPlayer),
        officerId = xPlayer.getSSN and xPlayer.getSSN() or xPlayer.identifier,
        officer_id = xPlayer.getSSN and xPlayer.getSSN() or xPlayer.identifier,
        date = os.date('%Y-%m-%d %H:%M:%S'),
        location = data.location or 'Unknown',
        tags = NormalizeList(data.tags or {}),
        involved = NormalizeList(data.involved or {}),
        involved_vehicles = NormalizeList(data.involved_vehicles or {}),
    }

    notify(src, Locale('report_created'), 'success')
    UpdateMDTData()
end)

RegisterNetEvent('KF_Police:Server:DeleteReport', function(reportId)
    local src = source
    local xPlayer = GetOfficer(src)
    if not xPlayer or not reportId then
        return
    end

    reportId = tostring(reportId)
    if not reports[reportId] then
        return notify(src, Locale('report_not_found'), 'error')
    end

    MySQL.update.await('DELETE FROM kf_police_reports WHERE id = ?', { tonumber(reportId) or reportId })
    reports[reportId] = nil
    notify(src, Locale('report_deleted'), 'success')
    UpdateMDTData()
end)

RegisterNetEvent('KF_Police:Server:SetWanted', function(data)
    local src = source
    local xPlayer = GetOfficer(src)
    if not xPlayer or type(data) ~= 'table' then
        return notify(src, Locale('invalid_data'), 'error')
    end

    local citizen, citizenId = FindCitizenById(data.citizenId)
    if not citizen then
        return notify(src, Locale('citizen_not_found'), 'error')
    end

    citizen.wanted = data.wanted == true or data.wanted == 1 or data.wanted == '1'
    citizen.wantedReason = citizen.wanted and (data.reason or 'Ricercato') or ''
    citizen.wantedBy = citizen.wanted and GetOfficerName(xPlayer) or ''
    citizens[citizenId] = citizen
    persistCitizen(citizen)
    RefreshWantedList()
    notify(src, Locale('wanted_updated'), 'success')
    UpdateMDTData()
end)

RegisterNetEvent('KF_Police:Server:AddCharge', function(data)
    local src = source
    local xPlayer = GetOfficer(src)
    if not xPlayer or type(data) ~= 'table' then
        return notify(src, Locale('invalid_data'), 'error')
    end

    local citizen, citizenId = FindCitizenById(data.citizenId)
    if not citizen then
        return notify(src, Locale('citizen_not_found'), 'error')
    end

    local article = nil
    if data.penalId then
        article = penalcode[tostring(data.penalId)]
    end

    local crime = data.crime or (article and (article.title or article.crime))
    if not crime or crime == '' then
        return notify(src, Locale('charge_add_failed'), 'error')
    end

    local records = ToObjectMap(citizen.criminalRecord or citizen.criminalRecords or {}, 'id')
    local recordId = nextRecordId(records)
    local fine = tonumber(data.fine or (article and parseFine(article)) or 0) or 0
    records[tostring(recordId)] = {
        id = recordId,
        crime = crime,
        date = os.date('%Y-%m-%d %H:%M:%S'),
        location = data.location or Config.DefaultTown,
        officer = GetOfficerName(xPlayer),
        victim = data.victim or '',
        sanction = data.sanction or (article and article.sanction) or '',
        fine = fine,
        jailTime = data.jailTime or (article and (article.jailTime or article.jail_time)) or 0,
    }

    local recordList = recordsToList(records)
    citizen.criminalRecord = recordList
    citizen.criminalRecords = recordList
    citizens[citizenId] = citizen
    persistCitizen(citizen)

    RecordPoliceTransaction(xPlayer, citizen, crime, fine)

    notify(src, Locale('charge_added'), 'success')
    UpdateMDTData()
end)

RegisterNetEvent('KF_Police:Server:SaveCitizenNote', function(data)
    local src = source
    local xPlayer = GetOfficer(src)
    if not xPlayer or type(data) ~= 'table' then
        return notify(src, Locale('invalid_data'), 'error')
    end

    local citizen, citizenId = FindCitizenById(data.citizenId)
    if not citizen then
        return notify(src, Locale('citizen_not_found'), 'error')
    end

    local noteText = data.note and tostring(data.note):gsub('^%s+', ''):gsub('%s+$', '') or ''
    if noteText == '' then
        return notify(src, Locale('invalid_data'), 'error')
    end

    citizen.notes = citizen.notes or {}
    citizen.notes[#citizen.notes + 1] = {
        id = #citizen.notes + 1,
        note = noteText,
        officer = GetOfficerName(xPlayer),
        date = os.date('%Y-%m-%d %H:%M:%S'),
    }
    notes[citizenId] = citizen.notes
    citizens[citizenId] = citizen
    persistCitizen(citizen)
    notify(src, Locale('note_saved'), 'success')
    UpdateMDTData()
end)

RegisterNetEvent('KF_Police:Server:SetVehicleFlag', function(data)
    local src = source
    local xPlayer = GetOfficer(src)
    if not xPlayer or type(data) ~= 'table' or not data.plate then
        return notify(src, Locale('invalid_data'), 'error')
    end

    local plate = tostring(data.plate):gsub('^%s+', ''):gsub('%s+$', '')
    local vehicle = vehicles[plate]
    if not vehicle then
        return notify(src, Locale('vehicle_not_found'), 'error')
    end

    if data.stolen ~= nil then
        vehicle.stolen = data.stolen == true or data.stolen == 1
    end
    if data.pounded ~= nil then
        vehicle.pounded = data.pounded == true or data.pounded == 1
    end

    vehicles[plate] = vehicle
    notify(src, Locale('vehicle_updated'), 'success')
    UpdateMDTData()
end)

RegisterNetEvent('KF_Police:Server:ReloadData', function()
    local src = source
    if not GetOfficer(src) then
        return
    end

    ServerDataInit()
    UpdateMDTData()
end)
