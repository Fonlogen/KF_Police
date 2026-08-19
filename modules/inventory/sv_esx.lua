--[[
    KF_Police - Bridge inventario: ESX classico (server)
    ----------------------------------------------------------------------------
    Usato quando Config.Inventory = 'esx'. Stesso contratto di sv_ox.lua.
]]

if Config.Inventory ~= 'esx' then
    return
end

Inventory = {}

local function player(src)
    return Framework.GetPlayer(src)
end

function Inventory.Count(src, item)
    local xPlayer = player(src)
    if not xPlayer then
        return 0
    end

    local entry = xPlayer.getInventoryItem(item)
    return entry and (tonumber(entry.count) or 0) or 0
end

function Inventory.CanCarry(src, item, count)
    local xPlayer = player(src)
    if not xPlayer then
        return false
    end

    return xPlayer.canCarryItem(item, count or 1) == true
end

function Inventory.AddItem(src, item, count)
    local xPlayer = player(src)
    if not xPlayer then
        return false
    end

    if not Inventory.CanCarry(src, item, count or 1) then
        return false
    end

    local ok = pcall(xPlayer.addInventoryItem, item, count or 1)
    return ok
end

function Inventory.RemoveItem(src, item, count)
    local xPlayer = player(src)
    if not xPlayer then
        return false
    end

    if Inventory.Count(src, item) < (count or 1) then
        return false
    end

    local ok = pcall(xPlayer.removeInventoryItem, item, count or 1)
    return ok
end

function Inventory.AddWeapon(src, weapon, ammo, components)
    local xPlayer = player(src)
    if not xPlayer then
        return false
    end

    local ok = pcall(xPlayer.addWeapon, weapon:upper(), ammo or 0)
    if not ok then
        return false
    end

    for _, component in ipairs(components or {}) do
        pcall(xPlayer.addWeaponComponent, weapon:upper(), component)
    end

    return true
end

function Inventory.RemoveWeapon(src, weapon)
    local xPlayer = player(src)
    if not xPlayer then
        return false
    end

    local ok = pcall(xPlayer.removeWeapon, weapon:upper())
    return ok
end

function Inventory.GetInventory(src)
    local xPlayer = player(src)
    if not xPlayer then
        return {}
    end

    local list = {}

    for _, item in pairs(xPlayer.getInventory() or {}) do
        if item and item.name and (tonumber(item.count) or 0) > 0 then
            list[#list + 1] = {
                name = item.name,
                label = item.label or item.name,
                count = tonumber(item.count) or 1,
                weapon = false,
            }
        end
    end

    for _, weapon in pairs(xPlayer.getLoadout() or {}) do
        list[#list + 1] = {
            name = weapon.name,
            label = weapon.label or weapon.name,
            count = 1,
            weapon = true,
        }
    end

    table.sort(list, function(a, b)
        return a.label < b.label
    end)

    return list
end

function Inventory.StripWeapons(src)
    local xPlayer = player(src)
    if not xPlayer then
        return
    end

    for _, weapon in pairs(xPlayer.getLoadout() or {}) do
        pcall(xPlayer.removeWeapon, weapon.name)
    end
end
