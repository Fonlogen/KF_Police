--[[
    KF_Police - Notifiche (client)
    ----------------------------------------------------------------------------
    Quando il tablet e' aperto la notifica finisce dentro al tablet (toast della
    NUI), altrimenti esce come notifica di gioco tramite ox_lib.
]]

local TYPE_MAP = {
    info = 'inform',
    inform = 'inform',
    success = 'success',
    error = 'error',
    warning = 'warning',
    warn = 'warning',
}

--- @param message string
--- @param nType 'info'|'success'|'error'|'warning'|nil
function Notify(message, nType)
    if not message or message == '' then
        return
    end

    nType = TYPE_MAP[nType or 'info'] or 'inform'

    if MdtIsOpen and MdtIsOpen() then
        SendNUIMessage({
            action = 'mdt:notify',
            data = { message = message, type = nType },
        })
        return
    end

    lib.notify({
        title = 'LSPD',
        description = message,
        type = nType,
        duration = Config.NotificationsDuration,
        position = 'top-right',
    })
end

--- Notifica con chiave di traduzione.
function NotifyLocale(key, nType, ...)
    Notify(Locale(key, ...), nType)
end

RegisterNetEvent('KF_Police:Client:Notify', function(message, nType)
    Notify(message, nType)
end)
