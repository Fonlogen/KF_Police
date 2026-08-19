--[[
    KF_Police - Armeria (client)
    ----------------------------------------------------------------------------
    Il catalogo mostra solo cio' che il grado puo' prendere e le scorte reali:
    il server rivalida comunque grado e stock prima di consegnare.
]]

local function refreshArmory()
    return lib.callback.await('KF_Police:armory:catalog', false)
end

local function takeItem(entry)
    local response = lib.callback.await('KF_Police:armory:take', false, entry.item, entry.isWeapon)

    Notify(response and response.message or Locale('invalid_data'),
        response and response.ok and 'success' or 'error')
end

local function storeItem(entry)
    local response = lib.callback.await('KF_Police:armory:store', false, entry.item, entry.isWeapon)

    Notify(response and response.message or Locale('invalid_data'),
        response and response.ok and 'success' or 'error')
end

local function buyItem(entry)
    local input = lib.inputDialog(Locale('armory_buy'), {
        {
            type = 'number',
            label = entry.label,
            description = ('$%d / unita'):format(entry.price or 0),
            min = 1,
            max = 50,
            default = 1,
            required = true,
        },
    })

    if not input or not input[1] then
        return
    end

    local response = lib.callback.await('KF_Police:armory:buy', false, entry.item, input[1])

    Notify(response and response.message or Locale('invalid_data'),
        response and response.ok and 'success' or 'error')
end

local openArmory

--- Menu di dettaglio: prendi / deposita / rifornisci.
local function openEntry(entry, canBuy)
    local options = {
        {
            title = Locale('armory_take'),
            description = ('Scorte: %d'):format(entry.stock or 0),
            icon = 'hand',
            disabled = (entry.stock or 0) <= 0,
            onSelect = function()
                takeItem(entry)
                openArmory()
            end,
        },
        {
            title = Locale('armory_store'),
            icon = 'box',
            onSelect = function()
                storeItem(entry)
                openArmory()
            end,
        },
    }

    if canBuy then
        options[#options + 1] = {
            title = Locale('armory_buy'),
            description = ('$%d / unita'):format(entry.price or 0),
            icon = 'cart-shopping',
            onSelect = function()
                buyItem(entry)
                openArmory()
            end,
        }
    end

    lib.registerContext({
        id = 'kf_police_armory_entry',
        title = entry.label,
        menu = 'kf_police_armory',
        options = options,
    })

    lib.showContext('kf_police_armory_entry')
end

openArmory = function()
    local catalog = refreshArmory()
    if not catalog then
        return NotifyLocale('no_permission', 'error')
    end

    local options = {}

    for _, entry in ipairs(catalog.weapons or {}) do
        options[#options + 1] = {
            title = entry.label,
            description = ('Scorte: %d'):format(entry.stock or 0),
            icon = 'gun',
            onSelect = function()
                openEntry(entry, catalog.canBuy)
            end,
        }
    end

    for _, entry in ipairs(catalog.items or {}) do
        options[#options + 1] = {
            title = entry.label,
            description = ('Scorte: %d'):format(entry.stock or 0),
            icon = 'box',
            onSelect = function()
                openEntry(entry, catalog.canBuy)
            end,
        }
    end

    if #options == 0 then
        return NotifyLocale('armory_out_of_stock', 'error')
    end

    lib.registerContext({
        id = 'kf_police_armory',
        title = Locale('armory'),
        options = options,
    })

    lib.showContext('kf_police_armory')
end

CreateThread(function()
    while not Target do
        Wait(200)
    end

    for stationKey, station in pairs(Config.Stations) do
        for index, coords in ipairs(station.armories or {}) do
            Target.AddZone({
                name = ('kf_police_armory_%s_%d'):format(stationKey, index),
                coords = coords,
                radius = Config.TargetRadius,
                label = Locale('armory'),
                faIcon = 'fa-solid fa-gun',
                marker = 'armory',
                permission = 'armory.use',
                canInteract = function()
                    return not Config.Duty.Enabled or IsPlayerOnDuty()
                end,
                onSelect = openArmory,
            })
        end
    end
end)
