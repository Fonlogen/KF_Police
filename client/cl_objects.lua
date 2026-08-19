--[[
    KF_Police - Oggetti piazzabili (client)
    ----------------------------------------------------------------------------
    Coni, barriere, chiodi e nastro. Gli oggetti sono locali, tracciati in una
    lista e ripuliti allo stop della risorsa: nessun prop orfano sulla mappa.
]]

local placed = {}

local function cleanup()
    for _, entry in ipairs(placed) do
        if entry.object and DoesEntityExist(entry.object) then
            DeleteEntity(entry.object)
        end
    end

    placed = {}
end

local function loadModel(model)
    local hash = joaat(model)
    RequestModel(hash)

    local deadline = GetGameTimer() + 5000
    while not HasModelLoaded(hash) and GetGameTimer() < deadline do
        Wait(10)
    end

    return HasModelLoaded(hash) and hash or nil
end

local function placeObject(definition)
    local hash = loadModel(definition.model)
    if not hash then
        return NotifyLocale('invalid_data', 'error')
    end

    local ped = PlayerPedId()
    local coords = GetOffsetFromEntityInWorldCoords(ped, 0.0, 1.2, -0.98)
    local heading = GetEntityHeading(ped)

    local object = CreateObject(hash, coords.x, coords.y, coords.z, false, false, false)
    SetEntityHeading(object, heading)
    PlaceObjectOnGroundProperly(object)
    FreezeEntityPosition(object, true)

    if definition.spikes then
        SetEntityCollision(object, true, true)
    end

    placed[#placed + 1] = {
        object = object,
        model = definition.model,
        placedAt = GetGameTimer(),
    }

    SetModelAsNoLongerNeeded(hash)
    NotifyLocale('object_placed', 'success')
end

local function removeNearest()
    local coords = GetEntityCoords(PlayerPedId())
    local nearestIndex, nearestDistance = nil, 3.5

    for index, entry in ipairs(placed) do
        if entry.object and DoesEntityExist(entry.object) then
            local distance = #(coords - GetEntityCoords(entry.object))
            if distance < nearestDistance then
                nearestIndex, nearestDistance = index, distance
            end
        end
    end

    if not nearestIndex then
        return NotifyLocale('object_none', 'error')
    end

    DeleteEntity(placed[nearestIndex].object)
    table.remove(placed, nearestIndex)
    NotifyLocale('object_removed', 'success')
end

function OpenObjectsMenu()
    if not Framework.HasPoliceJob() then
        return NotifyLocale('not_allowed_job', 'error')
    end

    local jobName, grade = Framework.GetJob()
    if not HasPermission(jobName, grade, 'objects.place') then
        return NotifyLocale('no_permission', 'error')
    end

    local options = {}

    for _, definition in ipairs(Config.PlaceableObjects) do
        options[#options + 1] = {
            title = definition.label,
            icon = 'traffic-cone',
            onSelect = function()
                placeObject(definition)
            end,
        }
    end

    options[#options + 1] = {
        title = Locale('object_removed'),
        description = 'Rimuove l\'oggetto piu vicino',
        icon = 'trash',
        onSelect = removeNearest,
    }

    lib.registerContext({
        id = 'kf_police_objects',
        title = 'Oggetti di servizio',
        options = options,
    })

    lib.showContext('kf_police_objects')
end

RegisterCommand('poliziaoggetti', function()
    OpenObjectsMenu()
end, false)

--- Rimozione automatica: nessun oggetto resta sulla mappa per sempre.
CreateThread(function()
    local lifetime = Config.PlaceableLifetime or 0
    if lifetime <= 0 then
        return
    end

    while true do
        Wait(60000)

        local now = GetGameTimer()
        for index = #placed, 1, -1 do
            local entry = placed[index]
            if now - entry.placedAt > lifetime then
                if entry.object and DoesEntityExist(entry.object) then
                    DeleteEntity(entry.object)
                end
                table.remove(placed, index)
            end
        end
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        cleanup()
    end
end)
