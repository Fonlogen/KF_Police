--[[
    KF_Police - Interfaccia NUI
    ----------------------------------------------------------------------------
    SCALA DINAMICA (sezione 3.2 del piano)
    ----------------------------------------------------------------------------
    Il tablet non ha piu' una dimensione assoluta in pixel. L'altezza e' una
    frazione dell'altezza schermo, la larghezza deriva dal rapporto di progetto
    (1280x910) e la NUI usa `rootFontSize` come font-size della radice. Cosi' a
    1920x1080, 2560x1440 e 3840x2160 il tablet occupa la stessa porzione di
    schermo e il testo ha la stessa dimensione apparente.
]]

local opened = false
local geometry = nil
local bootstrapped = false

function MdtIsOpen()
    return opened
end

--- Geometria del tablet in funzione della risoluzione reale.
--- @return table { width, height, rootFontSize }
function ComputeTabletGeometry()
    local cfg = Config.UI
    local sw, sh = GetActiveScreenResolution()

    local height = math.floor(sh * cfg.heightRatio)
    local width = math.floor(height * (cfg.baseWidth / cfg.baseHeight))

    if width < cfg.minWidth then
        width = cfg.minWidth
        height = math.floor(width * (cfg.baseHeight / cfg.baseWidth))
    elseif width > cfg.maxWidth then
        width = cfg.maxWidth
        height = math.floor(width * (cfg.baseHeight / cfg.baseWidth))
    end

    -- Non superare mai lo schermo disponibile.
    if width > sw then
        width = sw
        height = math.floor(width * (cfg.baseHeight / cfg.baseWidth))
    end
    if height > sh then
        height = sh
        width = math.floor(height * (cfg.baseWidth / cfg.baseHeight))
    end

    return {
        width = width,
        height = height,
        screenWidth = sw,
        screenHeight = sh,
        -- La NUI applica questo valore come font-size della radice.
        rootFontSize = 16.0 * (width / cfg.baseWidth) * (cfg.scale or 1.0),
    }
end

local function sendGeometry()
    geometry = ComputeTabletGeometry()

    SendNUIMessage({
        action = 'mdt:geometry',
        data = geometry,
    })
end

-- ============================================================================
--  Apertura e chiusura
-- ============================================================================

function CloseMDT()
    SetNuiFocus(false, false)

    if not opened then
        return
    end

    opened = false

    SendNUIMessage({
        action = 'mdt:visible',
        data = { visible = false },
    })

    if Config.Radio.DisconnectOnClose then
        LeavePoliceRadio()
    end
end

function OpenMDT()
    if not Framework.IsLoaded() then
        return
    end

    if not Framework.HasAllowedJob() then
        return NotifyLocale('not_allowed_job', 'error')
    end

    if opened then
        return CloseMDT()
    end

    opened = true
    SetNuiFocus(true, true)

    sendGeometry()

    SendNUIMessage({
        action = 'mdt:visible',
        data = { visible = true },
    })

    -- Il bootstrap arriva dal server: profilo, permessi, pagine, contatori.
    CreateThread(function()
        local response = lib.callback.await('KF_Police:mdt', false, 'bootstrap', {})

        if not response or not response.ok then
            NotifyLocale(response and response.error or 'mdt_not_ready', 'error')
            return CloseMDT()
        end

        bootstrapped = true

        SendNUIMessage({
            action = 'mdt:bootstrap',
            data = response,
        })

        PushRadioStateToNui()
    end)
end

RegisterCommand(Config.OpenCommand or 'openmdt', function()
    OpenMDT()
end, false)

--- CORREZIONE BUG L8: il tasto predefinito e' F5, non F6 (F6 collide con
--- `police:quickactions` di esx_policejob). Resta configurabile.
if Config.OpenKey and Config.OpenKey ~= '' then
    RegisterKeyMapping(Config.OpenCommand or 'openmdt', 'Apri MDT Polizia', 'keyboard', Config.OpenKey)
end

RegisterNetEvent('KF_Police:Client:OpenMDT', function()
    OpenMDT()
end)

-- ============================================================================
--  Ponte NUI -> server
--  Un solo canale: la NUI dichiara l'endpoint, il server rivalida e smista.
-- ============================================================================

--- Endpoint gestiti in locale sul client (non hanno senso lato server).
local localEndpoints = {}

--- @param name string
--- @param handler fun(payload: table): table
function RegisterLocalMdtEndpoint(name, handler)
    localEndpoints[name] = handler
end

RegisterNUICallback('mdt', function(data, cb)
    local endpoint = data and data.endpoint
    local payload = data and data.payload or {}

    if type(endpoint) ~= 'string' then
        return cb({ ok = false, error = 'invalid_data' })
    end

    local localHandler = localEndpoints[endpoint]
    if localHandler then
        local ok, result = pcall(localHandler, payload)
        return cb(ok and result or { ok = false, error = 'invalid_data' })
    end

    local response = lib.callback.await('KF_Police:mdt', false, endpoint, payload)
    cb(response or { ok = false, error = 'invalid_data' })
end)

RegisterNUICallback('mdt:close', function(_, cb)
    CloseMDT()
    cb({ ok = true })
end)

--- Posizione attuale, mostrata nella status bar e usata come luogo predefinito
--- nei rapporti.
RegisterLocalMdtEndpoint('client:context', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local street = GetStreetNameFromHashKey(GetStreetNameAtCoord(coords.x, coords.y, coords.z))

    return {
        ok = true,
        location = (street and street ~= '') and street or 'Los Santos',
        time = ('%02d:%02d'):format(GetClockHours(), GetClockMinutes()),
    }
end)

--- Cittadino piu' vicino, per compilare i coinvolti di un rapporto.
RegisterLocalMdtEndpoint('client:nearby', function()
    local player, distance = Framework.GetClosestPlayer(Config.Actions.MaxDistance * 2)

    if player == -1 or player == nil then
        return { ok = false, error = 'no_nearby_player' }
    end

    return {
        ok = true,
        serverId = GetPlayerServerId(player),
        distance = distance,
    }
end)

-- ============================================================================
--  Apertura diretta su una scheda
--  Usate dalle azioni di campo: la carta d'identita' e il controllo targa
--  aprono il fascicolo nel tablet invece di un menu di testo.
-- ============================================================================

--- @param identifier string
function OpenMdtOnCitizen(identifier)
    if not identifier or identifier == '' then
        return
    end

    local wasOpen = opened

    if not wasOpen then
        OpenMDT()
    end

    CreateThread(function()
        -- Se il tablet si e' appena aperto, aspetta il bootstrap.
        local deadline = GetGameTimer() + 5000
        while not bootstrapped and GetGameTimer() < deadline do
            Wait(50)
        end

        SendNUIMessage({
            action = 'mdt:open',
            data = { view = 'citizen', id = identifier },
        })
    end)
end

--- @param plate string
function OpenMdtOnVehicle(plate)
    if not plate or plate == '' then
        return
    end

    if not opened then
        OpenMDT()
    end

    CreateThread(function()
        local deadline = GetGameTimer() + 5000
        while not bootstrapped and GetGameTimer() < deadline do
            Wait(50)
        end

        SendNUIMessage({
            action = 'mdt:open',
            data = { view = 'vehicle', id = plate },
        })
    end)
end

-- ============================================================================
--  Push dal server
-- ============================================================================

RegisterNetEvent('KF_Police:Client:Invalidate', function(data)
    if not opened or not bootstrapped then
        return
    end

    SendNUIMessage({ action = 'mdt:invalidate', data = data })
end)

RegisterNetEvent('KF_Police:Client:Counters', function(counters)
    if not opened then
        return
    end

    SendNUIMessage({ action = 'mdt:counters', data = counters })
end)

RegisterNetEvent('KF_Police:Client:DutyChanged', function(onDuty)
    SendNUIMessage({ action = 'mdt:duty', data = { onDuty = onDuty } })
end)

-- ============================================================================
--  Stato di gioco inviato periodicamente alla status bar
-- ============================================================================

CreateThread(function()
    while true do
        if opened then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local street = GetStreetNameFromHashKey(GetStreetNameAtCoord(coords.x, coords.y, coords.z))

            SendNUIMessage({
                action = 'mdt:status',
                data = {
                    location = (street and street ~= '') and street or 'Los Santos',
                    time = ('%02d:%02d'):format(GetClockHours(), GetClockMinutes()),
                    inVehicle = IsPedInAnyVehicle(ped, false),
                },
            })

            Wait(5000)
        else
            Wait(1500)
        end
    end
end)

--- La risoluzione puo' cambiare mentre il gioco e' avviato (alt-tab, monitor).
CreateThread(function()
    local lastWidth, lastHeight = GetActiveScreenResolution()

    while true do
        Wait(4000)

        local width, height = GetActiveScreenResolution()
        if width ~= lastWidth or height ~= lastHeight then
            lastWidth, lastHeight = width, height
            if opened then
                sendGeometry()
            end
        end
    end
end)

RegisterNetEvent('esx:setJob', function(job)
    if opened and not IsAllowedJob(job and job.name) then
        return CloseMDT()
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        SetNuiFocus(false, false)
    end
end)
