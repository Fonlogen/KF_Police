--[[
    KF_Police - Servizio (client)
    ----------------------------------------------------------------------------
    Il punto di ingresso/uscita servizio e' lo spogliatoio della stazione, piu'
    la voce nel MDT. Nessuna dipendenza da esx_service.
]]

local function toggleDuty()
    local response = lib.callback.await('KF_Police:mdt', false, 'duty:toggle', {})

    if not response or not response.ok then
        return Notify(response and response.message or Locale('invalid_data'), 'error')
    end

    Notify(response.message, response.onDuty and 'success' or 'inform')

    if response.onDuty then
        -- Entrando in servizio si salva l'abito civile, per poterlo ripristinare.
        if Config.Cloakroom.RestoreCivilian and Clothing and Clothing.Available() then
            Clothing.SaveCivilian()
        end
    end
end

RegisterCommand('poliziaservizio', function()
    if not Framework.HasAllowedJob() then
        return NotifyLocale('not_allowed_job', 'error')
    end

    toggleDuty()
end, false)

--- Esposto agli altri file client (spogliatoio, MDT).
function ToggleDuty()
    toggleDuty()
end
