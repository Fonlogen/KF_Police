--[[
    KF_Police - Azioni su un cittadino (client)
    ----------------------------------------------------------------------------
    Menu contestuale ox_lib con le sole voci che il grado consente. La carta
    d'identita' apre la scheda MDT, non un menu di testo.
]]

local function serverIdOf(playerIndex)
    return GetPlayerServerId(playerIndex)
end

--- Cittadino piu' vicino, oppure nil con notifica.
--- @return number|nil serverId
local function requireNearbyCitizen()
    local player = Framework.GetClosestPlayer(Config.Actions.MaxDistance)

    if not player or player == -1 then
        NotifyLocale('no_nearby_player', 'error')
        return nil
    end

    return serverIdOf(player)
end

local function notifyResponse(response)
    if not response then
        return NotifyLocale('invalid_data', 'error')
    end

    if response.message and response.message ~= '' then
        Notify(response.message, response.ok and 'success' or 'error')
    end
end

-- ============================================================================
--  Azioni
-- ============================================================================

local function actionIdentify(targetId)
    local response = lib.callback.await('KF_Police:actions:identify', false, targetId)

    if not response or not response.ok then
        return notifyResponse(response)
    end

    -- Apre il tablet direttamente sul fascicolo del cittadino.
    OpenMdtOnCitizen(response.identifier)
end

local function actionCuff(targetId)
    if not PoliceProgress('progress_cuff', 2000, {
        anim = { dict = 'mp_arrest_paired', clip = 'cop_p2_back_left' },
    }) then
        return
    end

    notifyResponse(lib.callback.await('KF_Police:actions:cuff', false, targetId))
end

local function actionDrag(targetId)
    notifyResponse(lib.callback.await('KF_Police:actions:drag', false, targetId))
end

local function actionVehicle(targetId)
    local vehicle = GetNearestVehicle(Config.Actions.MaxVehicleDistance)

    local options = {
        {
            title = Locale('put_in_vehicle'),
            icon = 'car-side',
            disabled = vehicle == nil,
            onSelect = function()
                notifyResponse(lib.callback.await('KF_Police:actions:vehicle', false,
                    targetId, 'in', NetworkGetNetworkIdFromEntity(vehicle)))
            end,
        },
        {
            title = Locale('out_of_vehicle'),
            icon = 'person-walking',
            onSelect = function()
                notifyResponse(lib.callback.await('KF_Police:actions:vehicle', false, targetId, 'out'))
            end,
        },
    }

    lib.registerContext({
        id = 'kf_police_citizen_vehicle',
        title = Locale('put_in_vehicle'),
        menu = 'kf_police_citizen',
        options = options,
    })

    lib.showContext('kf_police_citizen_vehicle')
end

local function actionSearch(targetId)
    if not PoliceProgress('progress_search', 3000, {
        anim = { dict = 'missminuteman_1ig_2', clip = 'handsup_base', flag = 49 },
    }) then
        return
    end

    local response = lib.callback.await('KF_Police:actions:search', false, targetId)

    if not response or not response.ok then
        return notifyResponse(response)
    end

    local options = {}
    for _, item in ipairs(response.items or {}) do
        options[#options + 1] = {
            title = ('%s x%d'):format(item.label, item.count),
            description = 'Sequestra',
            icon = item.weapon and 'gun' or 'box',
            onSelect = function()
                notifyResponse(lib.callback.await('KF_Police:actions:seize', false,
                    targetId, item.name, item.count, item.weapon))
            end,
        }
    end

    if #options == 0 then
        options[1] = { title = 'Nessun oggetto', disabled = true }
    end

    lib.registerContext({
        id = 'kf_police_search_result',
        title = ('Perquisizione: %s'):format(response.citizen and response.citizen.name or ''),
        options = options,
    })

    lib.showContext('kf_police_search_result')
end

local function actionFine(targetId)
    local response = lib.callback.await('KF_Police:actions:identify', false, targetId)
    if not response or not response.ok then
        return notifyResponse(response)
    end

    local input = lib.inputDialog('Multa', {
        { type = 'input', label = 'Motivo', required = true, max = 120 },
        { type = 'number', label = 'Importo', required = true, min = 1, max = 100000 },
    })

    if not input then
        return
    end

    local result = lib.callback.await('KF_Police:mdt', false, 'fines:issue', {
        identifier = response.identifier,
        label = input[1],
        amount = input[2],
        location = GetCurrentStreet(),
    })

    notifyResponse(result)
end

local function actionLicenses(targetId)
    local response = lib.callback.await('KF_Police:actions:licenses', false, targetId)

    if not response or not response.ok then
        return notifyResponse(response)
    end

    local options = {}
    for _, license in ipairs(response.licenses or {}) do
        options[#options + 1] = {
            title = license.label,
            description = 'Revoca',
            icon = 'ban',
            onSelect = function()
                local confirm = lib.alertDialog({
                    header = license.label,
                    content = ('Revocare la licenza %s?'):format(license.label),
                    centered = true,
                    cancel = true,
                })

                if confirm == 'confirm' then
                    notifyResponse(lib.callback.await('KF_Police:actions:revokeLicense', false,
                        targetId, license.type))
                end
            end,
        }
    end

    if #options == 0 then
        options[1] = { title = Locale('license_none'), disabled = true }
    end

    lib.registerContext({
        id = 'kf_police_licenses',
        title = ('Licenze: %s'):format(response.name or ''),
        menu = 'kf_police_citizen',
        options = options,
    })

    lib.showContext('kf_police_licenses')
end

local function actionJail(targetId)
    local pending = lib.callback.await('KF_Police:actions:pendingSentence', false, targetId)

    local input = lib.inputDialog('Trasferimento in cella', {
        {
            type = 'number',
            label = 'Mesi di detenzione',
            description = pending and ('Reati pendenti: %d mesi'):format(pending.months or 0) or nil,
            default = pending and pending.months > 0 and pending.months or 5,
            min = 1,
            max = 10000,
            required = true,
        },
        { type = 'input', label = 'Motivo', max = 200 },
    })

    if not input then
        return
    end

    notifyResponse(lib.callback.await('KF_Police:actions:jail', false, targetId, input[1], input[2]))
end

local HANDLERS = {
    identity = actionIdentify,
    cuff = actionCuff,
    drag = actionDrag,
    vehicle = actionVehicle,
    search = actionSearch,
    fine = actionFine,
    licenses = actionLicenses,
    jail = actionJail,
}

-- ============================================================================
--  Menu
-- ============================================================================

function OpenCitizenActions()
    if not Framework.HasPoliceJob() then
        return NotifyLocale('not_allowed_job', 'error')
    end

    local targetId = requireNearbyCitizen()
    if not targetId then
        return
    end

    local jobName, grade = Framework.GetJob()
    local options = {}

    for _, action in ipairs(Config.CitizenActions) do
        if HasPermission(jobName, grade, action.permission) and HANDLERS[action.id] then
            options[#options + 1] = {
                title = action.label,
                icon = 'user',
                onSelect = function()
                    HANDLERS[action.id](targetId)
                end,
            }
        end
    end

    if #options == 0 then
        return NotifyLocale('no_permission', 'error')
    end

    lib.registerContext({
        id = 'kf_police_citizen',
        title = 'Azioni sul cittadino',
        options = options,
    })

    lib.showContext('kf_police_citizen')
end

RegisterCommand('poliziacittadino', function()
    OpenCitizenActions()
end, false)

RegisterKeyMapping('poliziacittadino', 'Azioni polizia sul cittadino', 'keyboard', 'F7')
