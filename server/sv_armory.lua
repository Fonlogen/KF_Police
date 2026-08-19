--[[
    KF_Police - Armeria (server)
    ----------------------------------------------------------------------------
    Lo stock e' su `kf_police_armory_stock`, non su esx_datastore: sopravvive ai
    restart ed e' leggibile in SQL. Prelievo e deposito sono atomici (UPDATE
    condizionato), quindi due agenti che prendono l'ultima arma nello stesso
    istante non la duplicano.
]]

--- Armi autorizzate per il grado dell'agente.
local function authorizedWeapons(gradeName)
    return Config.AuthorizedWeapons[gradeName] or {}
end

--- @return table<string, number>
local function readStock()
    local rows = Database.Query('SELECT item, count FROM kf_police_armory_stock') or {}

    local stock = {}
    for _, row in ipairs(rows) do
        stock[row.item] = tonumber(row.count) or 0
    end

    return stock
end

--- Scala lo stock solo se disponibile. L'UPDATE condizionato rende
--- l'operazione atomica anche con richieste contemporanee.
--- @return boolean
local function consumeStock(item, count)
    item = string.lower(item)
    count = count or 1

    local updated = Database.Update(
        'UPDATE kf_police_armory_stock SET count = count - ? WHERE item = ? AND count >= ?',
        { count, item, count })

    return (tonumber(updated) or 0) > 0
end

local function returnStock(item, count)
    item = string.lower(item)

    Database.Insert([[
        INSERT INTO kf_police_armory_stock (item, count) VALUES (?, ?)
        ON DUPLICATE KEY UPDATE count = count + VALUES(count)
    ]], { item, count or 1 })
end

--- Catalogo visibile all'agente: armi del grado + oggetti comuni, con scorte.
lib.callback.register('KF_Police:armory:catalog', function(src)
    local officer = RequirePermission(src, 'armory.use')
    if not officer then
        return nil
    end

    local info = OfficerInfo(officer)
    local stock = readStock()

    local weapons = {}
    for _, entry in ipairs(authorizedWeapons(info.gradeName)) do
        local key = string.lower(entry.weapon)
        weapons[#weapons + 1] = {
            item = entry.weapon,
            label = entry.label or entry.weapon:gsub('^WEAPON_', ''):lower():gsub('^%l', string.upper),
            price = tonumber(entry.price) or 0,
            components = entry.components,
            stock = stock[key] or 0,
            isWeapon = true,
        }
    end

    local items = {}
    for _, entry in ipairs(Config.ArmoryItems or {}) do
        local key = string.lower(entry.item)
        items[#items + 1] = {
            item = entry.item,
            label = entry.label or entry.item,
            price = tonumber(entry.price) or 0,
            max = entry.max,
            stock = stock[key] or 0,
            isWeapon = false,
        }
    end

    return {
        weapons = weapons,
        items = items,
        canBuy = HasPermission(info.job, info.grade, Config.Armory.BuyPermission or 'armory.buy'),
    }
end)

--- Prelievo dall'armeria.
lib.callback.register('KF_Police:armory:take', function(src, itemName, isWeapon)
    local officer = RequirePermission(src, 'armory.use')
    if not officer then
        return { ok = false, message = Locale('no_permission') }
    end

    if type(itemName) ~= 'string' or itemName == '' then
        return { ok = false, message = Locale('invalid_data') }
    end

    local info = OfficerInfo(officer)

    -- L'arma deve essere fra quelle autorizzate per il grado.
    local entry
    if isWeapon then
        for _, candidate in ipairs(authorizedWeapons(info.gradeName)) do
            if candidate.weapon == itemName then
                entry = candidate
                break
            end
        end
    else
        for _, candidate in ipairs(Config.ArmoryItems or {}) do
            if candidate.item == itemName then
                entry = candidate
                break
            end
        end
    end

    if not entry then
        return { ok = false, message = Locale('no_permission') }
    end

    if not consumeStock(itemName, 1) then
        return { ok = false, message = Locale('armory_out_of_stock') }
    end

    local delivered
    if isWeapon then
        delivered = Inventory.AddWeapon(src, itemName, 250, entry.components)
    else
        if entry.max and Inventory.Count(src, itemName) >= entry.max then
            returnStock(itemName, 1)
            return { ok = false, message = Locale('armory_full') }
        end
        delivered = Inventory.AddItem(src, itemName, 1)
    end

    if not delivered then
        -- Consegna fallita: lo stock torna indietro, niente sparizioni.
        returnStock(itemName, 1)
        return { ok = false, message = Locale('armory_full') }
    end

    if Config.Armory.Audit then
        Logger.Audit(officer, 'armory.take', itemName)
    end

    return { ok = true, message = Locale('armory_taken', entry.label or itemName) }
end)

--- Deposito in armeria.
lib.callback.register('KF_Police:armory:store', function(src, itemName, isWeapon)
    local officer = RequirePermission(src, 'armory.use')
    if not officer then
        return { ok = false, message = Locale('no_permission') }
    end

    if type(itemName) ~= 'string' or itemName == '' then
        return { ok = false, message = Locale('invalid_data') }
    end

    local removed
    if isWeapon then
        removed = Inventory.RemoveWeapon(src, itemName)
    else
        removed = Inventory.RemoveItem(src, itemName, 1)
    end

    if not removed then
        return { ok = false, message = Locale('armory_no_item') }
    end

    returnStock(itemName, 1)

    if Config.Armory.Audit then
        Logger.Audit(officer, 'armory.store', itemName)
    end

    return { ok = true, message = Locale('armory_stored', itemName) }
end)

--- Rifornimento: crea stock addebitando societa' o agente.
lib.callback.register('KF_Police:armory:buy', function(src, itemName, count)
    local officer = RequirePermission(src, Config.Armory.BuyPermission or 'armory.buy')
    if not officer then
        return { ok = false, message = Locale('no_permission') }
    end

    if type(itemName) ~= 'string' or itemName == '' then
        return { ok = false, message = Locale('invalid_data') }
    end

    count = ClampInt(count, 1, 50, 1)

    local info = OfficerInfo(officer)
    local price = 0
    local label = itemName

    for _, candidate in ipairs(authorizedWeapons(info.gradeName)) do
        if candidate.weapon == itemName then
            price = tonumber(candidate.price) or 0
            label = candidate.label or itemName
            break
        end
    end

    if price == 0 then
        for _, candidate in ipairs(Config.ArmoryItems or {}) do
            if candidate.item == itemName then
                price = tonumber(candidate.price) or 0
                label = candidate.label or itemName
                break
            end
        end
    end

    local total = price * count

    if total > 0 then
        local paid
        if Config.Armory.BuyFrom == 'player' then
            paid = Framework.RemoveAccountMoney(officer, 'money', total)
        else
            paid = Framework.RemoveSocietyMoney(Config.Society, total)
        end

        if not paid then
            return { ok = false, message = Locale('armory_no_money') }
        end
    end

    returnStock(itemName, count)
    Logger.Audit(officer, 'armory.buy', itemName, { count = count, total = total })

    return { ok = true, message = Locale('armory_bought', label) }
end)
