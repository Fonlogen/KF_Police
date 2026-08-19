--[[
    KF_Police - Azioni su un veicolo (client)
    ----------------------------------------------------------------------------
    Il controllo targa apre la scheda veicolo nel MDT. Il sequestro passa da
    cl_impound.lua e persiste su kf_police_vehicle_flags (bug L3).
]]

local function plateOf(vehicle)
    return NormalizePlate(GetVehicleNumberPlateText(vehicle))
end

local function notifyResponse(response)
    if not response then
        return NotifyLocale('invalid_data', 'error')
    end

    if response.message and response.message ~= '' then
        Notify(response.message, response.ok and 'success' or 'error')
    end
end

local function actionPlate(vehicle)
    local plate = plateOf(vehicle)
    if not plate then
        return NotifyLocale('vehicle_not_found', 'error')
    end

    local response = lib.callback.await('KF_Police:actions:plateCheck', false, plate)

    if not response or not response.ok then
        return notifyResponse(response)
    end

    OpenMdtOnVehicle(plate)
end

local function actionLockpick(vehicle)
    local response = lib.callback.await('KF_Police:actions:lockpick', false)
    if not response or not response.ok then
        return notifyResponse(response)
    end

    if not PoliceProgress('progress_lockpick', 8000, {
        anim = { dict = 'veh@break_in@0h@p_m_one@', clip = 'low_force_entry_ds' },
    }) then
        return NotifyLocale('lockpick_failed', 'error')
    end

    SetVehicleDoorsLocked(vehicle, 1)
    SetVehicleDoorsLockedForAllPlayers(vehicle, false)
    NotifyLocale('lockpick_success', 'success')
end

local function actionStolen(vehicle)
    local plate = plateOf(vehicle)
    if not plate then
        return NotifyLocale('vehicle_not_found', 'error')
    end

    local input = lib.inputDialog('Segnala rubato', {
        { type = 'input', label = 'Motivo', max = 200 },
    })

    if not input then
        return
    end

    notifyResponse(lib.callback.await('KF_Police:actions:markStolen', false, plate, true, input[1]))
end

local function actionSearch(vehicle)
    if not PoliceProgress('progress_search', 4000) then
        return
    end

    -- La perquisizione del bagagliaio la gestisce l'inventario, se presente.
    if GetResourceState('ox_inventory') == 'started' then
        local plate = plateOf(vehicle)
        exports.ox_inventory:openInventory('trunk', {
            id = 'trunk' .. (plate or ''),
            entity = vehicle,
        })
        return
    end

    NotifyLocale('search_done', 'success')
end

local HANDLERS = {
    plate = actionPlate,
    lockpick = actionLockpick,
    impound = function(vehicle)
        ImpoundVehicle(vehicle)
    end,
    stolen = actionStolen,
    search = actionSearch,
}

function OpenVehicleActions()
    if not Framework.HasPoliceJob() then
        return NotifyLocale('not_allowed_job', 'error')
    end

    local vehicle, distance = GetNearestVehicle(Config.Actions.MaxVehicleDistance)
    if not vehicle or distance > Config.Actions.MaxVehicleDistance then
        return NotifyLocale('no_nearby_vehicle', 'error')
    end

    local jobName, grade = Framework.GetJob()
    local options = {}

    for _, action in ipairs(Config.VehicleActions) do
        if HasPermission(jobName, grade, action.permission) and HANDLERS[action.id] then
            options[#options + 1] = {
                title = action.label,
                icon = 'car',
                onSelect = function()
                    HANDLERS[action.id](vehicle)
                end,
            }
        end
    end

    if #options == 0 then
        return NotifyLocale('no_permission', 'error')
    end

    lib.registerContext({
        id = 'kf_police_vehicle',
        title = ('Veicolo %s'):format(plateOf(vehicle) or ''),
        options = options,
    })

    lib.showContext('kf_police_vehicle')
end

RegisterCommand('poliziaveicolo', function()
    OpenVehicleActions()
end, false)

RegisterKeyMapping('poliziaveicolo', 'Azioni polizia sul veicolo', 'keyboard', 'F8')
