--[[
    KF_Police - Bridge vestiario: skinchanger / esx_skin
    ----------------------------------------------------------------------------
    Usato quando Config.Clothing = 'skinchanger'. Stesso contratto di
    cl_appearance.lua, ma qui le chiavi della divisa sono quelle native di
    skinchanger, quindi non serve tradurre nulla.
]]

if Config.Clothing ~= 'skinchanger' then
    return
end

Clothing = {}

local KVP_KEY = 'kf_police:civilian_outfit'

function Clothing.Available()
    return GetResourceState('skinchanger') == 'started'
end

--- skinchanger espone getSkin come callback: qui viene reso sincrono.
function Clothing.Snapshot()
    if not Clothing.Available() then
        return nil
    end

    local result = nil
    local done = false

    TriggerEvent('skinchanger:getSkin', function(skin)
        result = skin
        done = true
    end)

    local timeout = GetGameTimer() + 1000
    while not done and GetGameTimer() < timeout do
        Wait(0)
    end

    return result
end

function Clothing.Apply(components)
    if not Clothing.Available() or type(components) ~= 'table' then
        return false
    end

    TriggerEvent('skinchanger:loadClothes', nil, components)
    return true
end

function Clothing.Restore(snapshot)
    if not Clothing.Available() or type(snapshot) ~= 'table' then
        return false
    end

    TriggerEvent('skinchanger:loadSkin', snapshot)
    return true
end

function Clothing.SaveCivilian()
    local snapshot = Clothing.Snapshot()
    if not snapshot then
        return false
    end

    SetResourceKvp(KVP_KEY, json.encode(snapshot))
    return true
end

function Clothing.RestoreCivilian()
    local raw = GetResourceKvpString(KVP_KEY)
    if not raw then
        -- Senza copia locale si ricarica la skin salvata da esx_skin.
        if GetResourceState('esx_skin') == 'started' then
            TriggerEvent('esx_skin:loadDefaultSkin')
            return true
        end
        return false
    end

    local ok, snapshot = pcall(json.decode, raw)
    if not ok or type(snapshot) ~= 'table' then
        return false
    end

    return Clothing.Restore(snapshot)
end

function Clothing.HasCivilian()
    return GetResourceKvpString(KVP_KEY) ~= nil
end

function Clothing.ClearCivilian()
    DeleteResourceKvp(KVP_KEY)
end
