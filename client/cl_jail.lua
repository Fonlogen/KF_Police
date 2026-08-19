--[[
    KF_Police - Carcere (client)
    ----------------------------------------------------------------------------
    Il tempo residuo e' quello che dice il server: qui si mostra solo il
    contatore e si impedisce al detenuto di allontanarsi dall'area.
]]

local jailData = nil
local secondsRemaining = 0

function IsLocalPlayerJailed()
    return jailData ~= nil
end

local function showTimer()
    if not jailData then
        return
    end

    lib.showTextUI(('%s  %s'):format(
        Locale('jail_time_left', FormatDuration(secondsRemaining)),
        jailData.reason and ('| ' .. jailData.reason) or ''
    ), { position = 'top-center' })
end

RegisterNetEvent('KF_Police:Client:Jailed', function(data)
    jailData = data
    secondsRemaining = data.secondsRemaining or 0

    local ped = PlayerPedId()

    if data.cell and data.cell.coords then
        SetEntityCoords(ped, data.cell.coords.x, data.cell.coords.y, data.cell.coords.z, false, false, false, false)
    end

    if data.stripWeapons then
        RemoveAllPedWeapons(ped, true)
    end

    showTimer()
end)

RegisterNetEvent('KF_Police:Client:JailTick', function(remaining)
    secondsRemaining = remaining or 0

    if jailData then
        showTimer()
    end
end)

RegisterNetEvent('KF_Police:Client:Released', function(data)
    jailData = nil
    secondsRemaining = 0
    lib.hideTextUI()

    local coords = data and data.coords or Config.Jail.Release
    if coords then
        SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z, false, false, false, false)
    end
end)

--- Confinamento: uscire dall'area riporta in cella.
CreateThread(function()
    while true do
        if jailData then
            local bounds = jailData.bounds or Config.Jail.Bounds

            if bounds and bounds.center then
                local coords = GetEntityCoords(PlayerPedId())
                local distance = #(coords - bounds.center)

                if distance > (bounds.radius or 65.0) then
                    local cell = jailData.cell and jailData.cell.coords or bounds.center
                    SetEntityCoords(PlayerPedId(), cell.x, cell.y, cell.z, false, false, false, false)
                    NotifyLocale('jail_cannot_leave', 'error')
                end
            end

            Wait(2000)
        else
            Wait(3000)
        end
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        lib.hideTextUI()
    end
end)
