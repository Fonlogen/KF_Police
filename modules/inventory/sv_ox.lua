--[[
    KF_Police - Bridge inventario: ox_inventory (server)
    ----------------------------------------------------------------------------
    Contratto implementato anche da sv_esx.lua:
      Inventory.Count(src, item)                  -> number
      Inventory.AddItem(src, item, count, meta)   -> boolean
      Inventory.RemoveItem(src, item, count)      -> boolean
      Inventory.AddWeapon(src, weapon, ammo, components) -> boolean
      Inventory.RemoveWeapon(src, weapon)         -> boolean
      Inventory.CanCarry(src, item, count)        -> boolean
      Inventory.GetInventory(src)                 -> table (per la perquisizione)
]]

if Config.Inventory ~= 'ox_inventory' then
    return
end

Inventory = {}

local function ox()
    return exports.ox_inventory
end

local function available()
    return GetResourceState('ox_inventory') == 'started'
end

function Inventory.Count(src, item)
    if not available() then
        return 0
    end

    local ok, count = pcall(ox().GetItemCount, ox(), src, item)
    return ok and (tonumber(count) or 0) or 0
end

function Inventory.CanCarry(src, item, count)
    if not available() then
        return false
    end

    local ok, result = pcall(ox().CanCarryItem, ox(), src, item, count or 1)
    return ok and result == true
end

function Inventory.AddItem(src, item, count, metadata)
    if not available() then
        return false
    end

    local ok, result = pcall(ox().AddItem, ox(), src, item, count or 1, metadata)
    return ok and result ~= false
end

function Inventory.RemoveItem(src, item, count)
    if not available() then
        return false
    end

    local ok, result = pcall(ox().RemoveItem, ox(), src, item, count or 1)
    return ok and result ~= false
end

--- In ox_inventory le armi sono item con metadata (serial, components, ammo).
function Inventory.AddWeapon(src, weapon, ammo, components)
    if not available() then
        return false
    end

    local metadata = {
        ammo = ammo or 0,
        components = components or {},
        registered = false,
    }

    return Inventory.AddItem(src, string.lower(weapon), 1, metadata)
end

function Inventory.RemoveWeapon(src, weapon)
    return Inventory.RemoveItem(src, string.lower(weapon), 1)
end

--- Elenco piatto dell'inventario, per la perquisizione.
function Inventory.GetInventory(src)
    if not available() then
        return {}
    end

    local ok, items = pcall(ox().GetInventoryItems, ox(), src)
    if not ok or type(items) ~= 'table' then
        return {}
    end

    local list = {}
    for _, item in pairs(items) do
        if item and item.name then
            list[#list + 1] = {
                name = item.name,
                label = item.label or item.name,
                count = tonumber(item.count) or 1,
                weapon = item.weapon == true or (item.name):find('^weapon_') ~= nil,
            }
        end
    end

    table.sort(list, function(a, b)
        return a.label < b.label
    end)

    return list
end

--- Toglie tutte le armi (usato all'ingresso in cella).
function Inventory.StripWeapons(src)
    if not available() then
        return
    end

    for _, item in ipairs(Inventory.GetInventory(src)) do
        if item.weapon then
            Inventory.RemoveItem(src, item.name, item.count)
        end
    end
end
