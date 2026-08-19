--[[
    KF_Police - Garage di servizio (server)
    ----------------------------------------------------------------------------
    Nessuna dipendenza da esx_vehicleshop (su questo server e' in [disabled], per
    cui il garage di esx_policejob era di fatto rotto). Il veicolo di servizio e'
    creato lato server con `CreateVehicleServerSetter`, targato LSPD e non finisce
    in owned_vehicles: e' un mezzo di reparto, non un bene del personaggio.
]]

--- identifier -> { netId, plate, model }
local activeVehicles = {}

local plateCounter = 0

local function nextPlate()
    plateCounter = (plateCounter + 1) % 1000

    local plate = ('%s %03d'):format(Config.Garage.PlatePrefix or 'LSPD', plateCounter)

    -- Evita di riusare una targa gia' in strada.
    for _, entry in pairs(activeVehicles) do
        if entry.plate == plate then
            return nextPlate()
        end
    end

    return plate
end

--- Veicoli disponibili per il grado dell'agente in una categoria.
local function availableVehicles(gradeName, category)
    local byCategory = Config.AuthorizedVehicles[category or 'car'] or {}
    return byCategory[gradeName] or {}
end

lib.callback.register('KF_Police:garage:catalog', function(src, category)
    local officer = RequirePermission(src, 'garage.use')
    if not officer then
        return nil
    end

    local info = OfficerInfo(officer)
    local list = {}

    for _, entry in ipairs(availableVehicles(info.gradeName, category)) do
        list[#list + 1] = {
            model = entry.model,
            label = entry.label or entry.model,
            price = tonumber(entry.price) or 0,
        }
    end

    return {
        vehicles = list,
        hasActive = activeVehicles[info.identifier] ~= nil,
    }
end)

lib.callback.register('KF_Police:garage:spawn', function(src, data)
    local officer = RequirePermission(src, 'garage.use')
    if not officer then
        return { ok = false, message = Locale('no_permission') }
    end

    if Config.Duty.Enabled and not IsOnDuty(officer.identifier) then
        return { ok = false, message = Locale('duty_required') }
    end

    if type(data) ~= 'table' or type(data.model) ~= 'string' then
        return { ok = false, message = Locale('invalid_data') }
    end

    local info = OfficerInfo(officer)

    if Config.Garage.OneVehiclePerOfficer and activeVehicles[info.identifier] then
        return { ok = false, message = Locale('garage_already_out') }
    end

    -- Il modello deve essere fra quelli autorizzati per il grado.
    local allowed, entry = false, nil
    for _, candidate in ipairs(availableVehicles(info.gradeName, data.category)) do
        if candidate.model == data.model then
            allowed, entry = true, candidate
            break
        end
    end

    if not allowed then
        return { ok = false, message = Locale('no_permission') }
    end

    local price = tonumber(entry.price) or 0
    if price > 0 and not Framework.RemoveSocietyMoney(Config.Society, price) then
        return { ok = false, message = Locale('armory_no_money') }
    end

    local coords = data.coords
    if type(coords) ~= 'table' or not coords.x then
        return { ok = false, message = Locale('invalid_data') }
    end

    local plate = nextPlate()

    local vehicle = CreateVehicleServerSetter(
        joaat(data.model),
        data.category == 'helicopter' and 'heli' or 'automobile',
        coords.x + 0.0, coords.y + 0.0, coords.z + 0.0,
        tonumber(data.heading) or 0.0
    )

    if not vehicle or vehicle == 0 then
        return { ok = false, message = Locale('invalid_data') }
    end

    local deadline = GetGameTimer() + 5000
    while not DoesEntityExist(vehicle) and GetGameTimer() < deadline do
        Wait(10)
    end

    if not DoesEntityExist(vehicle) then
        return { ok = false, message = Locale('invalid_data') }
    end

    SetVehicleNumberPlateText(vehicle, plate)

    local netId = NetworkGetNetworkIdFromEntity(vehicle)

    activeVehicles[info.identifier] = {
        netId = netId,
        entity = vehicle,
        plate = plate,
        model = data.model,
    }

    Logger.Audit(officer, 'garage.spawn', data.model, { plate = plate })

    return {
        ok = true,
        netId = netId,
        plate = plate,
        props = entry.props or Config.Garage.DefaultProps,
    }
end)

local function despawn(identifier)
    local entry = activeVehicles[identifier]
    if not entry then
        return false
    end

    local entity = entry.entity
    if (not entity or not DoesEntityExist(entity)) and entry.netId then
        entity = NetworkGetEntityFromNetworkId(entry.netId)
    end

    if entity and DoesEntityExist(entity) then
        DeleteEntity(entity)
    end

    activeVehicles[identifier] = nil
    return true
end

lib.callback.register('KF_Police:garage:store', function(src, netId)
    local officer = RequirePermission(src, 'garage.use')
    if not officer then
        return { ok = false, message = Locale('no_permission') }
    end

    local info = OfficerInfo(officer)
    local entry = activeVehicles[info.identifier]

    if not entry then
        return { ok = false, message = Locale('garage_not_service_vehicle') }
    end

    -- Se il client indica un veicolo diverso da quello prelevato, si rifiuta.
    if netId and tonumber(netId) ~= entry.netId then
        return { ok = false, message = Locale('garage_not_service_vehicle') }
    end

    despawn(info.identifier)
    Logger.Audit(officer, 'garage.store', entry.model, { plate = entry.plate })

    return { ok = true, message = Locale('garage_stored') }
end)

RegisterNetEvent('KF_Police:Server:DespawnServiceVehicle', function()
    local xPlayer = Framework.GetPlayer(source)
    if xPlayer then
        despawn(xPlayer.identifier)
    end
end)

AddEventHandler('playerDropped', function()
    local xPlayer = Framework.GetPlayer(source)
    if xPlayer then
        despawn(xPlayer.identifier)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    for identifier in pairs(activeVehicles) do
        despawn(identifier)
    end
end)
