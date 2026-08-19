--[[
    KF_Police - Manette (client)
    ----------------------------------------------------------------------------
    Lo stato autorevole e' sul server (sv_actions.lua): questo file si limita a
    rappresentarlo (animazione, controlli disabilitati) e a segnalare la scadenza
    del timer.
]]

local restrained = false
local restrainedUntil = nil

local ANIM_DICT = 'mp_arresting'
local ANIM_NAME = 'idle'

function IsLocalPlayerRestrained()
    return restrained
end

local function loadAnim(dict)
    RequestAnimDict(dict)

    local deadline = GetGameTimer() + 3000
    while not HasAnimDictLoaded(dict) and GetGameTimer() < deadline do
        Wait(10)
    end
end

local function applyRestraint(state)
    local ped = PlayerPedId()

    if state then
        loadAnim(ANIM_DICT)
        TaskPlayAnim(ped, ANIM_DICT, ANIM_NAME, 8.0, -8.0, -1, 49, 0, false, false, false)
        SetEnableHandcuffs(ped, true)
        SetPedCanPlayGestureAnims(ped, false)
        DisablePlayerFiring(PlayerId(), true)
    else
        ClearPedSecondaryTask(ped)
        StopAnimTask(ped, ANIM_DICT, ANIM_NAME, 1.0)
        SetEnableHandcuffs(ped, false)
        SetPedCanPlayGestureAnims(ped, true)
        DisablePlayerFiring(PlayerId(), false)
    end
end

RegisterNetEvent('KF_Police:Client:SetRestrained', function(state, timer)
    restrained = state == true
    restrainedUntil = (restrained and timer and timer > 0) and (GetGameTimer() + timer) or nil

    applyRestraint(restrained)
end)

--- Il ped ammanettato non puo' correre, salire su veicoli da solo, ne' sparare.
CreateThread(function()
    while true do
        if restrained then
            local ped = PlayerPedId()

            DisableControlAction(0, 21, true)  -- sprint
            DisableControlAction(0, 24, true)  -- attacco
            DisableControlAction(0, 25, true)  -- mira
            DisableControlAction(0, 47, true)  -- arma
            DisableControlAction(0, 58, true)  -- arma
            DisableControlAction(0, 263, true) -- melee
            DisableControlAction(0, 264, true)
            DisableControlAction(0, 257, true)
            DisableControlAction(0, 140, true)
            DisableControlAction(0, 141, true)
            DisableControlAction(0, 142, true)
            DisableControlAction(0, 143, true)
            DisableControlAction(0, 75, true)  -- esci dal veicolo

            if not IsEntityPlayingAnim(ped, ANIM_DICT, ANIM_NAME, 3) then
                applyRestraint(true)
            end

            if restrainedUntil and GetGameTimer() >= restrainedUntil then
                restrained = false
                restrainedUntil = nil
                applyRestraint(false)
                TriggerServerEvent('KF_Police:Server:CuffExpired')
                NotifyLocale('uncuffed', 'success')
            end

            Wait(0)
        else
            Wait(500)
        end
    end
end)

--- Metti / togli dal veicolo, comandati dall'agente e validati dal server.
RegisterNetEvent('KF_Police:Client:PutInVehicle', function(netId, seat)
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then
        return
    end

    local ped = PlayerPedId()
    local targetSeat = tonumber(seat) or -2

    -- Cerca il primo posto passeggero libero.
    if targetSeat == -2 then
        local maxSeats = GetVehicleMaxNumberOfPassengers(vehicle)
        for index = 0, maxSeats - 1 do
            if IsVehicleSeatFree(vehicle, index) then
                targetSeat = index
                break
            end
        end
    end

    if targetSeat == -2 then
        return NotifyLocale('vehicle_no_seat', 'error')
    end

    SetPedIntoVehicle(ped, vehicle, targetSeat)
end)

RegisterNetEvent('KF_Police:Client:OutOfVehicle', function()
    local ped = PlayerPedId()

    if IsPedInAnyVehicle(ped, false) then
        local vehicle = GetVehiclePedIsIn(ped, false)
        TaskLeaveVehicle(ped, vehicle, 16)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() and restrained then
        applyRestraint(false)
    end
end)
