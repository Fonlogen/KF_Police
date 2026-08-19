--[[
    KF_Police - Sequestro veicoli (client)
    ----------------------------------------------------------------------------
    Il flag `is_impounded` viene scritto su database prima che il veicolo venga
    rimosso dalla mappa, quindi il sequestro sopravvive al restart (bug L3).
]]

--- @param vehicle number entita' del veicolo
function ImpoundVehicle(vehicle)
    if not vehicle or not DoesEntityExist(vehicle) then
        return NotifyLocale('no_nearby_vehicle', 'error')
    end

    local plate = NormalizePlate(GetVehicleNumberPlateText(vehicle))
    if not plate then
        return NotifyLocale('vehicle_not_found', 'error')
    end

    local input = lib.inputDialog('Sequestro veicolo', {
        { type = 'input', label = 'Motivo', required = true, max = 200 },
    })

    if not input then
        return
    end

    if not PoliceProgress('progress_impound', Config.Impound.Duration or 8000, {
        anim = { dict = 'mini@repair', clip = 'fixing_a_ped' },
    }) then
        return
    end

    local response = lib.callback.await('KF_Police:actions:impound', false, plate, input[1])

    if not response or not response.ok then
        return Notify(response and response.message or Locale('invalid_data'), 'error')
    end

    -- Prima si svuota il veicolo, poi si elimina.
    for seat = -1, GetVehicleMaxNumberOfPassengers(vehicle) - 1 do
        local ped = GetPedInVehicleSeat(vehicle, seat)
        if ped and ped ~= 0 then
            TaskLeaveVehicle(ped, vehicle, 16)
        end
    end

    Wait(1200)

    if DoesEntityExist(vehicle) then
        SetEntityAsMissionEntity(vehicle, true, true)
        DeleteVehicle(vehicle)
    end

    Notify(response.message, 'success')
end

--- Deposito: elenco dei veicoli sequestrati e riconsegna.
local function openImpoundLot(station)
    local response = lib.callback.await('KF_Police:mdt', false, 'vehicles:impounded', {})

    if not response or not response.ok then
        return NotifyLocale('no_permission', 'error')
    end

    local options = {}

    for _, entry in ipairs(response.rows or {}) do
        options[#options + 1] = {
            title = ('%s - %s'):format(entry.plate, entry.model),
            description = ('%s | %s'):format(entry.ownerName or '?', entry.reason or ''),
            icon = 'car-burst',
            onSelect = function()
                local confirm = lib.alertDialog({
                    header = entry.plate,
                    content = 'Dissequestrare il veicolo?',
                    centered = true,
                    cancel = true,
                })

                if confirm ~= 'confirm' then
                    return
                end

                local result = lib.callback.await('KF_Police:mdt', false, 'vehicles:setFlag', {
                    plate = entry.plate,
                    impounded = false,
                })

                Notify(result and result.message or Locale('invalid_data'),
                    result and result.ok and 'success' or 'error')
            end,
        }
    end

    if #options == 0 then
        options[1] = { title = 'Nessun veicolo sequestrato', disabled = true }
    end

    lib.registerContext({
        id = 'kf_police_impound',
        title = 'Deposito sequestri',
        options = options,
    })

    lib.showContext('kf_police_impound')
end

CreateThread(function()
    while not Target do
        Wait(200)
    end

    for stationKey, station in pairs(Config.Stations) do
        local impound = station.impound
        if impound and impound.retrieve then
            Target.AddZone({
                name = ('kf_police_impound_%s'):format(stationKey),
                coords = impound.retrieve,
                radius = Config.TargetRadius + 0.8,
                label = 'Deposito sequestri',
                faIcon = 'fa-solid fa-car-burst',
                marker = 'garage',
                permission = 'field.impound',
                onSelect = function()
                    openImpoundLot(station)
                end,
            })
        end
    end
end)
