--[[
    KF_Police - Blip dei colleghi (client)
    ----------------------------------------------------------------------------
    L'elenco arriva dal server (solo stesso lavoro, e solo in servizio se
    configurato): il client non deduce nulla dai giocatori intorno.
]]

--- serverId -> blip
local blips = {}

local function clearBlips()
    for serverId, blip in pairs(blips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
        blips[serverId] = nil
    end
end

local function upsertBlip(entry)
    local player = GetPlayerFromServerId(entry.serverId)
    if player == -1 then
        return false
    end

    local ped = GetPlayerPed(player)
    if not ped or ped == 0 or not DoesEntityExist(ped) then
        return false
    end

    local blip = blips[entry.serverId]

    if not blip or not DoesBlipExist(blip) then
        blip = AddBlipForEntity(ped)
        blips[entry.serverId] = blip
    end

    SetBlipSprite(blip, Config.ColleagueBlips.sprite or 1)
    SetBlipColour(blip, Config.ColleagueBlips.colour or 38)
    SetBlipScale(blip, Config.ColleagueBlips.scale or 0.75)
    SetBlipAsShortRange(blip, false)
    ShowHeadingIndicatorOnBlip(blip, true)

    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(('%s (%s)'):format(entry.name, entry.gradeLabel or ''))
    EndTextCommandSetBlipName(blip)

    return true
end

CreateThread(function()
    if not Config.ColleagueBlips.Enabled then
        return
    end

    while true do
        local interval = Config.ColleagueBlips.Refresh or 5000

        if Framework.IsLoaded() and Framework.HasAllowedJob() then
            local colleagues = lib.callback.await('KF_Police:duty:colleagues', false) or {}
            local seen = {}

            for _, entry in ipairs(colleagues) do
                if upsertBlip(entry) then
                    seen[entry.serverId] = true
                end
            end

            -- Via i blip di chi non e' piu' nell'elenco.
            for serverId, blip in pairs(blips) do
                if not seen[serverId] then
                    if DoesBlipExist(blip) then
                        RemoveBlip(blip)
                    end
                    blips[serverId] = nil
                end
            end
        else
            clearBlips()
            interval = 10000
        end

        Wait(interval)
    end
end)

-- ============================================================================
--  Allerte: blip temporaneo sul luogo della segnalazione
-- ============================================================================

RegisterNetEvent('KF_Police:Client:Alert', function(data)
    if type(data) ~= 'table' then
        return
    end

    Notify(data.message, 'warning')

    if data.blip == false or type(data.coords) ~= 'table' then
        return
    end

    local blip = AddBlipForCoord(data.coords.x + 0.0, data.coords.y + 0.0, data.coords.z + 0.0)
    SetBlipSprite(blip, 161)
    SetBlipColour(blip, 1)
    SetBlipScale(blip, 1.1)
    SetBlipAsShortRange(blip, false)
    SetBlipFlashes(blip, true)

    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(data.message)
    EndTextCommandSetBlipName(blip)

    -- L'allerta scade: nessun blip resta sulla mappa a vita.
    SetTimeout(120000, function()
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        clearBlips()
    end
end)
