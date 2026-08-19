--[[
    KF_Police - Scorta (client)
    ----------------------------------------------------------------------------
    Il cittadino ammanettato viene agganciato all'agente. Lo stato arriva dal
    server, che verifica sia la distanza sia il fatto che sia ammanettato.
]]

local draggedBy = nil

local function attachTo(officerServerId)
    local officerPlayer = GetPlayerFromServerId(officerServerId)
    if officerPlayer == -1 then
        return false
    end

    local officerPed = GetPlayerPed(officerPlayer)
    if not officerPed or officerPed == 0 then
        return false
    end

    AttachEntityToEntity(
        PlayerPedId(), officerPed, 11816,
        0.54, 0.54, 0.0,
        0.0, 0.0, 0.0,
        false, false, false, false, 2, true
    )

    return true
end

local function detach()
    local ped = PlayerPedId()
    DetachEntity(ped, true, false)
end

RegisterNetEvent('KF_Police:Client:SetDragged', function(state, officerServerId)
    if state then
        draggedBy = officerServerId

        if not attachTo(officerServerId) then
            draggedBy = nil
        end
    else
        draggedBy = nil
        detach()
    end
end)

--- Se l'agente si allontana troppo o si disconnette, l'aggancio decade.
CreateThread(function()
    while true do
        if draggedBy then
            local officerPlayer = GetPlayerFromServerId(draggedBy)

            if officerPlayer == -1 or not DoesEntityExist(GetPlayerPed(officerPlayer)) then
                draggedBy = nil
                detach()
            elseif not IsEntityAttached(PlayerPedId()) then
                if not attachTo(draggedBy) then
                    draggedBy = nil
                end
            end

            Wait(500)
        else
            Wait(1000)
        end
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() and draggedBy then
        detach()
    end
end)
