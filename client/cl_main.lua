--[[
    KF_Police - Nucleo client
    ----------------------------------------------------------------------------
    Solo il minimo indispensabile: stato del servizio, registrazione delle zone
    della stazione e utilita' condivise dagli altri file client.
]]

--- Stato locale del servizio, sincronizzato dal server.
local onDuty = false

function IsPlayerOnDuty()
    return onDuty
end

RegisterNetEvent('KF_Police:Client:DutyChanged', function(state)
    onDuty = state == true
end)

--- Stazione piu' vicina, usata dai menu che devono sapere dove ci si trova.
--- @return table|nil stazione, string|nil chiave
function GetNearestStation()
    local coords = GetEntityCoords(PlayerPedId())
    local nearest, nearestKey, nearestDistance = nil, nil, 200.0

    for key, station in pairs(Config.Stations) do
        local reference = station.blip and station.blip.coords
            or (station.cloakrooms and station.cloakrooms[1])

        if reference then
            local distance = #(coords - reference)
            if distance < nearestDistance then
                nearest, nearestKey, nearestDistance = station, key, distance
            end
        end
    end

    return nearest, nearestKey
end

--- Nome della strada corrente, in forma leggibile.
function GetCurrentStreet()
    local coords = GetEntityCoords(PlayerPedId())
    local street = GetStreetNameFromHashKey(GetStreetNameAtCoord(coords.x, coords.y, coords.z))

    return (street and street ~= '') and street or 'Los Santos'
end

--- Veicolo piu' vicino al giocatore entro `maxDistance`.
--- @return number|nil entita', number distanza
function GetNearestVehicle(maxDistance)
    local ped = PlayerPedId()

    if IsPedInAnyVehicle(ped, false) then
        return GetVehiclePedIsIn(ped, false), 0.0
    end

    local coords = GetEntityCoords(ped)
    local vehicle = lib.getClosestVehicle(coords, maxDistance or Config.Actions.MaxVehicleDistance, false)

    if not vehicle or vehicle == 0 then
        return nil, 999.0
    end

    return vehicle, #(coords - GetEntityCoords(vehicle))
end

--- Barra di progresso uniforme per tutte le azioni di campo.
--- @return boolean completata
function PoliceProgress(labelKey, duration, options)
    options = options or {}

    return lib.progressBar({
        duration = duration,
        label = Locale(labelKey),
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = options.allowCar ~= true,
            move = options.allowMove ~= true,
            combat = true,
        },
        anim = options.anim,
    }) == true
end

-- ============================================================================
--  Blip delle stazioni
-- ============================================================================

CreateThread(function()
    for _, station in pairs(Config.Stations) do
        local blipCfg = station.blip
        if blipCfg and blipCfg.coords then
            local blip = AddBlipForCoord(blipCfg.coords.x, blipCfg.coords.y, blipCfg.coords.z)
            SetBlipSprite(blip, blipCfg.sprite or 60)
            SetBlipDisplay(blip, blipCfg.display or 4)
            SetBlipScale(blip, blipCfg.scale or 0.9)
            SetBlipColour(blip, blipCfg.colour or 29)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName(station.label or 'Polizia')
            EndTextCommandSetBlipName(blip)
        end
    end
end)

-- ============================================================================
--  Stato iniziale
-- ============================================================================

CreateThread(function()
    while not Framework.IsLoaded() do
        Wait(500)
    end

    -- Il server conosce lo stato reale del servizio: lo si chiede all'ingresso.
    local response = lib.callback.await('KF_Police:mdt', false, 'duty:state', {})
    if response and response.ok then
        onDuty = response.onDuty == true
    end
end)
