--[[
    KF_Police - Garage di servizio (client)
    ----------------------------------------------------------------------------
    Il veicolo viene creato dal server (`CreateVehicleServerSetter`): il client
    scelge solo modello e punto di spawn libero. Nessun riferimento a
    esx_vehicleshop.
]]

local activeVehicle = nil

--- Primo punto di spawn libero del garage.
--- @return table|nil
local function freeSpawnPoint(garage)
    for _, point in ipairs(garage.spawnPoints or {}) do
        local occupied = lib.getClosestVehicle(point.coords, 2.5, false)
        if not occupied or occupied == 0 then
            return point
        end
    end

    return nil
end

local function spawnVehicle(garage, entry)
    local point = freeSpawnPoint(garage)
    if not point then
        return NotifyLocale('garage_no_space', 'error')
    end

    local response = lib.callback.await('KF_Police:garage:spawn', false, {
        model = entry.model,
        category = garage.category or 'car',
        coords = { x = point.coords.x, y = point.coords.y, z = point.coords.z },
        heading = point.heading or 0.0,
    })

    if not response or not response.ok then
        return Notify(response and response.message or Locale('invalid_data'), 'error')
    end

    -- Attende che il veicolo esista anche in locale prima di configurarlo.
    local deadline = GetGameTimer() + 5000
    local vehicle = 0

    while GetGameTimer() < deadline do
        vehicle = NetworkGetEntityFromNetworkId(response.netId)
        if vehicle ~= 0 and DoesEntityExist(vehicle) then
            break
        end
        Wait(50)
    end

    if vehicle == 0 or not DoesEntityExist(vehicle) then
        return NotifyLocale('invalid_data', 'error')
    end

    SetVehicleNumberPlateText(vehicle, response.plate)
    SetVehicleHasBeenOwnedByPlayer(vehicle, true)
    SetEntityAsMissionEntity(vehicle, true, true)

    if Config.Garage.SpawnFullFuel then
        SetVehicleFuelLevel(vehicle, 100.0)
        SetVehicleEngineHealth(vehicle, 1000.0)
        SetVehicleBodyHealth(vehicle, 1000.0)
    end

    for modType, modValue in pairs(response.props or {}) do
        if modType == 'modLivery' then
            SetVehicleLivery(vehicle, modValue)
        end
    end

    activeVehicle = { netId = response.netId, plate = response.plate }

    SetPedIntoVehicle(PlayerPedId(), vehicle, -1)
    Notify(('%s - %s'):format(entry.label, response.plate), 'success')
end

local function openGarage(garage)
    local catalog = lib.callback.await('KF_Police:garage:catalog', false, garage.category or 'car')

    if not catalog then
        return NotifyLocale('no_permission', 'error')
    end

    if #(catalog.vehicles or {}) == 0 then
        return NotifyLocale('garage_no_vehicles', 'error')
    end

    local options = {}

    for _, entry in ipairs(catalog.vehicles) do
        options[#options + 1] = {
            title = entry.label,
            description = entry.price > 0 and ('$%d'):format(entry.price) or 'Di servizio',
            icon = (garage.category == 'helicopter') and 'helicopter' or 'car',
            onSelect = function()
                spawnVehicle(garage, entry)
            end,
        }
    end

    lib.registerContext({
        id = 'kf_police_garage',
        title = Locale('garage'),
        options = options,
    })

    lib.showContext('kf_police_garage')
end

--- Riconsegna: il veicolo su cui si e' seduti torna al reparto.
local function storeVehicle()
    local ped = PlayerPedId()
    local vehicle = IsPedInAnyVehicle(ped, false) and GetVehiclePedIsIn(ped, false) or nil

    if not vehicle then
        vehicle = GetNearestVehicle(5.0)
    end

    if not vehicle or vehicle == 0 then
        return NotifyLocale('no_nearby_vehicle', 'error')
    end

    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    local response = lib.callback.await('KF_Police:garage:store', false, netId)

    if not response or not response.ok then
        return Notify(response and response.message or Locale('invalid_data'), 'error')
    end

    activeVehicle = nil
    Notify(response.message, 'success')
end

RegisterNetEvent('KF_Police:Client:DespawnServiceVehicle', function()
    if not activeVehicle then
        return
    end

    TriggerServerEvent('KF_Police:Server:DespawnServiceVehicle')
    activeVehicle = nil
end)

CreateThread(function()
    while not Target do
        Wait(200)
    end

    for stationKey, station in pairs(Config.Stations) do
        for index, garage in ipairs(station.garages or {}) do
            Target.AddZone({
                name = ('kf_police_garage_%s_%d'):format(stationKey, index),
                coords = garage.spawner,
                radius = Config.TargetRadius + 0.5,
                label = Locale('garage_spawn'),
                faIcon = 'fa-solid fa-car',
                marker = 'garage',
                permission = 'garage.use',
                canInteract = function()
                    return not Config.Duty.Enabled or IsPlayerOnDuty()
                end,
                onSelect = function()
                    openGarage(garage)
                end,
            })
        end

        for index, point in ipairs(station.vehicleReturns or {}) do
            Target.AddZone({
                name = ('kf_police_return_%s_%d'):format(stationKey, index),
                coords = point.coords,
                radius = point.radius or 4.0,
                label = Locale('garage_store'),
                faIcon = 'fa-solid fa-square-parking',
                marker = 'garage',
                permission = 'garage.use',
                onSelect = storeVehicle,
            })
        end
    end
end)
