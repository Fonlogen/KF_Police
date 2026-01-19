ESX = exports['es_extended']:getSharedObject()

jobs = {}
all_vehicles = {}
citizens = {}
vehicles = {}
tags = {}
reports = {}
penalcode = {}

lib.callback.register('KF_Police:Server:GetData', function(src)
    TriggerClientEvent('KF_Police:Client:SetData', src, 'citizens', citizens)
    Wait(500)
    TriggerClientEvent('KF_Police:Client:SetData', src, 'vehicles', vehicles)
    Wait(500)
    TriggerClientEvent('KF_Police:Client:SetData', src, 'tags', tags)
    Wait(500)
    TriggerClientEvent('KF_Police:Client:SetData', src, 'reports', reports)
    Wait(500)
    TriggerClientEvent('KF_Police:Client:SetData', src, 'penalcode', penalcode)
end)

--- INTERNAL FUNCTIONS

local function retrive_jobs()
    local job_grades_db = MySQL.Sync.fetchAll('SELECT * FROM job_grades', {})

    for k, v in pairs(job_grades_db) do
        if not jobs[v.job_name] then
            jobs[v.job_name] = {}
        end
        jobs[v.job_name][v.grade] = {
            label = v.label,
            salary = v.salary,
            name = v.name,
            grade = v.grade,
            job_name = v.job_name
        }
    end

    local db_jobs = MySQL.Sync.fetchAll('SELECT * FROM jobs', {})

    for k, v in pairs(db_jobs) do
        if not jobs[v.name] then
            jobs[v.name] = {}
        end
        jobs[v.name].label = v.label
        jobs[v.name].name = v.name
    end
end

function FindCitizenIdByIdentifier(identifier)
    for k, v in pairs(citizens) do
        if v.identifier == identifier then
            return v.citizenId
        end
    end
    return nil
end

function ServerDataInit()
    retrive_jobs()

    local server_players    = MySQL.Sync.fetchAll('SELECT * FROM users', {})
    local licenses_table    = MySQL.Sync.fetchAll('SELECT * FROM user_licenses', {})
    local properties_table  = MySQL.Sync.fetchAll('SELECT * FROM 0r_motels', {})
    local vehicles_table    = MySQL.Sync.fetchAll('SELECT * FROM owned_vehicles', {})

    -- KF Police Tables
    local citizens_table    = MySQL.Sync.fetchAll('SELECT * FROM kf_police_citizens', {})
    local reports_table     = MySQL.Sync.fetchAll('SELECT * FROM kf_police_reports', {})
    local tags_table        = MySQL.Sync.fetchAll('SELECT * FROM kf_police_tags', {})
    local penalcode_table   = MySQL.Sync.fetchAll('SELECT * FROM kf_police_penalcode', {})

    for k, v in pairs(server_players) do
        if not v.citizenid then
            goto skipUser
        end

        citizens[v.citizenid] = {
            citizenId = v.citizenid,
            firstname = v.firstname,
            lastname = v.lastname,
            job = {
                job_name = v.job,
                job_grade = v.job_grade,
                job_grade_label = jobs[v.job][v.job_grade].label,
                job_label = jobs[v.job].label
            },
            phone_number = v.phoneNumber or 'N/A',
            criminalRecords = {},
            licenses = {},
            properties = {},
            wanted = false,
            town = v.town,
            image = v.image or nil,
            identifier = v.identifier,
        }

        for x, y in pairs(citizens_table) do
            if y.citizenid == v.citizenid then
                citizens[v.citizenid].criminalRecords = json.decode(y.criminalRecords)
                citizens[v.citizenid].wanted = y.wanted
            end
        end

        ::skipUser::
    end

    -- Vehicles
    for k, v in pairs(vehicles_table) do
        vehicles[v.plate] = {
            plate = v.plate,
            owner = FindCitizenIdByIdentifier(v.owner),
            model = v.model,
            buyDate = 'N/A',
        }
    end

    -- reports
    for k, v in pairs(reports_table) do
        -- To String prevents javascript to think as "array" instead of "object"
        reports[tostring(v.id)] = {
            id = v.id,
            title = v.title,
            description = v.description,
            officer = v.officer,
            officerId = v.officerId,
            date = v.date,
            location = v.location,
            tags = json.decode(v.tags),
            involved = json.decode(v.involved),
            involved_vehicles = json.decode(v.involved_vehicles),
        }
    end

    -- tags
    for k, v in pairs(tags_table) do
        tags[tostring(v.id)] = {
            id = v.id,
            label = v.label,
            color = v.color,
        }
    end

    -- penalcode
    for k, v in pairs(penalcode_table) do
        penalcode[tostring(v.id)] = {
            id = v.id,
            title = v.title,
            description = v.description,
            sanction = v.sanction,
        }
    end

end

ServerDataInit()