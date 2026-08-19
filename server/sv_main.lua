ESX = exports['es_extended']:getSharedObject()

jobs = {}
citizens = {}
vehicles = {}
tags = {}
reports = {}
penalcode = {}
wantedList = {}
notes = {}

local initialized = false

local function notify(src, message, nType)
    TriggerClientEvent('esx:showNotification', src, message, nType or 'info', Config.NotificationsDuration)
end

function IsAllowedJob(jobName)
    return jobName and Config.AllowedJobs[jobName] == true
end

function GetOfficer(src)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then
        return nil
    end

    if not IsAllowedJob(xPlayer.job and xPlayer.job.name) then
        return nil
    end

    return xPlayer
end

function GetOfficerName(xPlayer)
    if not xPlayer then
        return 'Sconosciuto'
    end

    local firstName = xPlayer.get('firstName')
    local lastName = xPlayer.get('lastName')
    if firstName or lastName then
        return (('%s %s'):format(firstName or '', lastName or '')):gsub('^%s+', ''):gsub('%s+$', '')
    end

    return xPlayer.getName() or GetPlayerName(xPlayer.source) or 'Sconosciuto'
end

function GetCitizenId(user)
    return user.ssn or user.citizenid or user.citizenId or user.identifier
end

function FindCitizenById(citizenId)
    if not citizenId then
        return nil, nil
    end

    citizenId = tostring(citizenId)
    if citizens[citizenId] then
        return citizens[citizenId], citizenId
    end

    for id, citizen in pairs(citizens) do
        if tostring(id) == citizenId or tostring(citizen.citizenId) == citizenId or citizen.identifier == citizenId then
            return citizen, id
        end
    end

    return nil, nil
end

function FindCitizenIdByIdentifier(identifier)
    if not identifier then
        return nil
    end

    for id, citizen in pairs(citizens) do
        if citizen.identifier == identifier or tostring(citizen.citizenId) == tostring(identifier) then
            return id
        end
    end

    return nil
end

local function safeQuery(query, params)
    local ok, result = pcall(function()
        return MySQL.query.await(query, params or {})
    end)

    if not ok then
        print(('[KF_Police] Query failed: %s'):format(tostring(result)))
        return {}
    end

    return result or {}
end

local function tableExists(tableName)
    local result = safeQuery('SHOW TABLES LIKE ?', { tableName })
    return result[1] ~= nil
end

local function columnExists(tableName, columnName)
    local result = safeQuery(('SHOW COLUMNS FROM `%s` LIKE ?'):format(tableName), { columnName })
    return result[1] ~= nil
end

local function retrive_jobs()
    jobs = {}

    local job_grades_db = safeQuery('SELECT * FROM job_grades', {})
    for _, v in pairs(job_grades_db) do
        jobs[v.job_name] = jobs[v.job_name] or {}
        jobs[v.job_name][tonumber(v.grade) or v.grade] = {
            label = v.label,
            salary = v.salary,
            name = v.name,
            grade = tonumber(v.grade) or v.grade,
            job_name = v.job_name
        }
    end

    local db_jobs = safeQuery('SELECT * FROM jobs', {})
    for _, v in pairs(db_jobs) do
        jobs[v.name] = jobs[v.name] or {}
        jobs[v.name].label = v.label
        jobs[v.name].name = v.name
    end
end

local function getJobInfo(jobName, jobGrade)
    jobGrade = tonumber(jobGrade) or 0
    local job = jobs[jobName] or {}
    local grade = job[jobGrade] or {}

    return {
        job_name = jobName or 'unemployed',
        job_grade = jobGrade,
        job_grade_label = grade.label or 'Disoccupato',
        job_label = job.label or jobName or 'Disoccupato'
    }
end

local function getPhoneNumber(identifier)
    if not identifier or not tableExists('phone_phones') then
        return 'N/A'
    end

    local result = safeQuery('SELECT phone_number FROM phone_phones WHERE owner_id = ? LIMIT 1', { identifier })
    if result[1] and result[1].phone_number then
        return tostring(result[1].phone_number)
    end

    return 'N/A'
end

local function getCitizenLicenses(identifier)
    local licenses = {}
    if not identifier or not tableExists('user_licenses') then
        return licenses
    end

    local rows = {}
    if tableExists('licenses') then
        rows = safeQuery([[
            SELECT user_licenses.type, COALESCE(licenses.label, user_licenses.type) AS label
            FROM user_licenses
            LEFT JOIN licenses ON licenses.type = user_licenses.type
            WHERE user_licenses.owner = ?
        ]], { identifier })
    else
        rows = safeQuery('SELECT type FROM user_licenses WHERE owner = ?', { identifier })
    end

    for _, row in pairs(rows) do
        licenses[row.type] = {
            label = row.label or row.type,
            type = row.type,
            date = row.date or 'N/A',
            status = 'active'
        }
    end

    return licenses
end

local function getCitizenProperties(identifier)
    local properties = {}
    if not identifier then
        return properties
    end

    if tableExists('coin_system_items') then
        local rows = safeQuery('SELECT property_id, label, category, coords FROM coin_system_items WHERE owner = ?', { identifier })
        for _, row in pairs(rows) do
            properties[row.property_id] = {
                label = row.label or row.property_id,
                address = row.coords or 'N/A',
                city = row.category or Config.DefaultTown
            }
        end
    end

    return properties
end

local function decodeVehicleModel(vehicleJson)
    local props = DecodeJson(vehicleJson, {})
    return props.model or props.name or 'Sconosciuto'
end

local function ensureCitizenProfile(citizenId)
    if not citizenId then
        return
    end

    MySQL.insert.await(
        'INSERT IGNORE INTO kf_police_citizens (citizenid, criminalRecords, wanted, notes) VALUES (?, ?, ?, ?)',
        { tostring(citizenId), '{}', 0, '[]' }
    )
end

local function buildCitizenReports(citizenId)
    local citizenReports = {}
    if not citizenId then
        return citizenReports
    end

    citizenId = tostring(citizenId)
    for reportId, report in pairs(reports) do
        local involved = report.involved or {}
        for _, involvedId in pairs(involved) do
            if tostring(involvedId) == citizenId then
                citizenReports[tostring(reportId)] = {
                    date = report.date,
                    officer = report.officer,
                    title = report.title,
                    report = report.description
                }
                break
            end
        end
    end

    return citizenReports
end

function RefreshWantedList()
    wantedList = {}
    local index = 1

    for citizenId, citizen in pairs(citizens) do
        if citizen.wanted then
            wantedList[tostring(index)] = {
                id = index,
                citizen = citizenId,
                reason = citizen.wantedReason or 'Ricercato',
                wantedBy = citizen.wantedBy or 'LSPD'
            }
            index = index + 1
        end
    end
end

function AttachCitizenExtras()
    for citizenId, citizen in pairs(citizens) do
        citizen.reports = buildCitizenReports(citizenId)
        citizen.notes = notes[citizenId] or citizen.notes or {}
    end
end

function BuildMdtPayload()
    AttachCitizenExtras()
    RefreshWantedList()

    return {
        citizens = citizens,
        vehicles = vehicles,
        tags = tags,
        reports = reports,
        penalcode = penalcode,
        penalCode = penalcode,
        wantedList = wantedList,
    }
end

function ServerDataInit()
    citizens = {}
    vehicles = {}
    tags = {}
    reports = {}
    penalcode = {}
    notes = {}

    retrive_jobs()

    local usersQuery = 'SELECT identifier, firstname, lastname, job, job_grade, dateofbirth, sex'
    if tableExists('users') and columnExists('users', 'ssn') then
        usersQuery = usersQuery .. ', ssn'
    end
    if tableExists('users') and columnExists('users', 'phone_number') then
        usersQuery = usersQuery .. ', phone_number'
    end
    usersQuery = usersQuery .. ' FROM users'

    local server_players = safeQuery(usersQuery, {})
    local citizens_table = tableExists('kf_police_citizens') and safeQuery('SELECT * FROM kf_police_citizens', {}) or {}
    local reports_table = tableExists('kf_police_reports') and safeQuery('SELECT * FROM kf_police_reports', {}) or {}
    local tags_table = tableExists('kf_police_tags') and safeQuery('SELECT * FROM kf_police_tags', {}) or {}
    local penalcode_table = tableExists('kf_police_penalcode') and safeQuery('SELECT * FROM kf_police_penalcode', {}) or {}
    local vehicles_table = tableExists('owned_vehicles') and safeQuery('SELECT * FROM owned_vehicles', {}) or {}

    local extraByCitizen = {}
    for _, row in pairs(citizens_table) do
        extraByCitizen[tostring(row.citizenid)] = row
    end

    for _, user in pairs(server_players) do
        local citizenId = GetCitizenId(user)
        if citizenId then
            citizenId = tostring(citizenId)
            local extra = extraByCitizen[citizenId] or extraByCitizen[tostring(user.identifier)] or {}
            local criminalRecords = NormalizeList(DecodeJson(extra.criminalRecords, {}))
            local citizenNotes = NormalizeList(extra.notes)

            citizens[citizenId] = {
                citizenId = citizenId,
                firstname = user.firstname or 'Sconosciuto',
                lastname = user.lastname or '',
                job = getJobInfo(user.job, user.job_grade),
                phoneNumber = user.phone_number or getPhoneNumber(user.identifier),
                phone_number = user.phone_number or getPhoneNumber(user.identifier),
                criminalRecord = criminalRecords,
                criminalRecords = criminalRecords,
                licenses = getCitizenLicenses(user.identifier),
                properties = getCitizenProperties(user.identifier),
                wanted = extra.wanted == true or tonumber(extra.wanted) == 1,
                wantedReason = extra.wantedReason or extra.wanted_reason or '',
                wantedBy = extra.wantedBy or extra.wanted_by or '',
                town = user.town or Config.DefaultTown,
                image = extra.image or user.image or Config.DefaultImage,
                identifier = user.identifier,
                dateofbirth = user.dateofbirth,
                sex = user.sex,
                notes = citizenNotes,
                reports = {},
            }

            notes[citizenId] = citizenNotes
        end
    end

    for _, vehicle in pairs(vehicles_table) do
        if vehicle.plate then
            local plate = tostring(vehicle.plate):gsub('^%s+', ''):gsub('%s+$', '')
            vehicles[plate] = {
                plate = plate,
                owner = FindCitizenIdByIdentifier(vehicle.owner) or vehicle.owner,
                model = vehicle.model or decodeVehicleModel(vehicle.vehicle),
                label = vehicle.label or vehicle.model or decodeVehicleModel(vehicle.vehicle),
                buyDate = vehicle.stored ~= nil and (tonumber(vehicle.stored) == 1 and 'In garage' or 'Fuori') or 'N/A',
                pounded = vehicle.pound ~= nil and vehicle.pound ~= '' and vehicle.pound ~= 0,
                stolen = false,
                type = vehicle.type or 'car',
            }
        end
    end

    for _, report in pairs(reports_table) do
        local reportId = tostring(report.id)
        reports[reportId] = {
            id = tonumber(report.id) or report.id,
            title = report.title or 'Senza titolo',
            description = report.description or '',
            officer = report.officer or 'Sconosciuto',
            officerId = report.officer_id or report.officerId,
            officer_id = report.officer_id or report.officerId,
            date = report.date and tostring(report.date) or os.date('%Y-%m-%d %H:%M:%S'),
            location = report.location or 'Unknown',
            tags = NormalizeList(report.tags),
            involved = NormalizeList(report.involved),
            involved_vehicles = NormalizeList(report.involved_vehicles),
        }
    end

    for _, tag in pairs(tags_table) do
        tags[tostring(tag.id)] = {
            id = tonumber(tag.id) or tag.id,
            label = tag.label,
            color = tag.color or '#333333',
        }
    end

    for _, article in pairs(penalcode_table) do
        penalcode[tostring(article.id)] = {
            id = tonumber(article.id) or article.id,
            title = article.title,
            crime = article.title,
            description = article.description or '',
            sanction = article.sanction or '',
            fine = article.fine,
            jailTime = article.jailTime or article.jail_time,
        }
    end

    AttachCitizenExtras()
    RefreshWantedList()
    initialized = true
    print(('[KF_Police] MDT loaded: %s citizens, %s vehicles, %s reports'):format(
        TableCount(citizens),
        TableCount(vehicles),
        TableCount(reports)
    ))
end

lib.callback.register('KF_Police:Server:GetData', function(src)
    local xPlayer = GetOfficer(src)
    if not xPlayer then
        return {
            citizens = {},
            vehicles = {},
            tags = {},
            reports = {},
            penalcode = {},
            penalCode = {},
            wantedList = {},
        }
    end

    if not initialized then
        ServerDataInit()
    end

    return BuildMdtPayload()
end)

lib.callback.register('KF_Police:Server:GetPlayerProfile', function(src)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then
        return {}
    end

    local citizenId = xPlayer.getSSN and xPlayer.getSSN() or xPlayer.identifier
    local citizen = FindCitizenById(citizenId)

    return {
        firstName = xPlayer.get('firstName') or (citizen and citizen.firstname) or '',
        lastName = xPlayer.get('lastName') or (citizen and citizen.lastname) or '',
        grade = xPlayer.job and xPlayer.job.grade_label or '',
        job = xPlayer.job and xPlayer.job.name or '',
        job_label = xPlayer.job and xPlayer.job.label or '',
        citizenId = citizenId,
        image = (citizen and citizen.image) or Config.DefaultImage,
    }
end)

CreateThread(function()
    Wait(1000)
    if Config.AutoDatabaseCreation then
        EnsurePoliceDatabase()
    end
    ServerDataInit()

    if Config.OpenItem and Config.OpenItem ~= '' then
        pcall(function()
            ESX.RegisterUsableItem(Config.OpenItem, function(source)
                if not GetOfficer(source) then
                    return TriggerClientEvent('esx:showNotification', source, Locale('not_allowed_job'), 'error', Config.NotificationsDuration)
                end

                TriggerClientEvent('KF_Police:Client:OpenMDT', source)
            end)
        end)
    end
end)
