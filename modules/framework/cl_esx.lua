--[[
    KF_Police - Bridge framework ESX (client)
]]

if Config.Framework ~= 'esx' then
    return
end

Framework = {}

ESX = exports['es_extended']:getSharedObject()

function Framework.IsLoaded()
    return ESX.IsPlayerLoaded() == true
end

function Framework.GetPlayerData()
    return ESX.GetPlayerData() or {}
end

--- @return string|nil name, number grade, string gradeName, string gradeLabel, string jobLabel
function Framework.GetJob()
    local job = Framework.GetPlayerData().job
    if not job or not job.name then
        return nil, 0, 'recruit', '', ''
    end

    local grade = tonumber(job.grade) or 0

    return job.name,
        grade,
        ResolveGradeName(job.name, grade, job.grade_name),
        job.grade_label or '',
        job.label or job.name
end

function Framework.HasAllowedJob()
    local name = Framework.GetJob()
    return IsAllowedJob(name)
end

function Framework.HasPoliceJob()
    local name = Framework.GetJob()
    return IsPoliceJob(name)
end

function Framework.GetIdentifier()
    return Framework.GetPlayerData().identifier
end

function Framework.GetSsn()
    local data = Framework.GetPlayerData()
    return data.ssn or data.identifier
end

function Framework.Notify(message, nType)
    Notify(message, nType)
end

--- @return number playerIndex (-1 se nessuno), number distance
function Framework.GetClosestPlayer(maxDistance)
    local coords = GetEntityCoords(PlayerPedId())
    local player, distance = lib.getClosestPlayer(coords, maxDistance or 3.0, false)
    return player or -1, distance or 999.0
end

function Framework.GetSex()
    local data = Framework.GetPlayerData()
    local sex = data.sex or (data.identity and data.identity.sex)

    if sex == 'f' or sex == 'F' or sex == 'female' or sex == 1 then
        return 'female'
    end

    return 'male'
end

--- Vero se l'inventario contiene almeno `count` unita' dell'item.
function Framework.HasItem(itemName, count)
    count = count or 1

    if Config.Inventory == 'ox_inventory' and GetResourceState('ox_inventory') == 'started' then
        local total = exports.ox_inventory:Search('count', itemName)
        return (tonumber(total) or 0) >= count
    end

    for _, item in pairs(Framework.GetPlayerData().inventory or {}) do
        if item.name == itemName and (tonumber(item.count) or 0) >= count then
            return true
        end
    end

    return false
end
