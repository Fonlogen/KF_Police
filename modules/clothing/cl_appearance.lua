--[[
    KF_Police - Bridge vestiario: fivem-appearance
    ----------------------------------------------------------------------------
    Contratto implementato anche da cl_skinchanger.lua:
      Clothing.Available()          -> boolean
      Clothing.Snapshot()           -> table|nil   (abbigliamento attuale)
      Clothing.Apply(components)    (chiavi skinchanger: torso_1, pants_1, ...)
      Clothing.Restore(snapshot)    -> boolean
      Clothing.SaveCivilian()       memorizza l'abito civile (anche su KVP)
      Clothing.RestoreCivilian()    -> boolean

    Le divise di cfg_duty.lua usano le chiavi skinchanger: qui vengono tradotte
    negli indici nativi dei componenti GTA che fivem-appearance si aspetta.
]]

if Config.Clothing ~= 'fivem-appearance' then
    return
end

Clothing = {}

local KVP_KEY = 'kf_police:civilian_outfit'

--- chiave skinchanger -> { componente nativo, 'component'|'prop' }
local COMPONENT_MAP = {
    mask_1     = { 1, 'component' }, mask_2     = { 1, 'component' },
    arms       = { 3, 'component' }, arms_2     = { 3, 'component' },
    pants_1    = { 4, 'component' }, pants_2    = { 4, 'component' },
    bags_1     = { 5, 'component' }, bags_2     = { 5, 'component' },
    shoes_1    = { 6, 'component' }, shoes_2    = { 6, 'component' },
    chain_1    = { 7, 'component' }, chain_2    = { 7, 'component' },
    tshirt_1   = { 8, 'component' }, tshirt_2   = { 8, 'component' },
    bproof_1   = { 9, 'component' }, bproof_2   = { 9, 'component' },
    decals_1   = { 10, 'component' }, decals_2  = { 10, 'component' },
    torso_1    = { 11, 'component' }, torso_2   = { 11, 'component' },
    helmet_1   = { 0, 'prop' },      helmet_2   = { 0, 'prop' },
    glasses_1  = { 1, 'prop' },      glasses_2  = { 1, 'prop' },
    ears_1     = { 2, 'prop' },      ears_2     = { 2, 'prop' },
    watches_1  = { 6, 'prop' },      watches_2  = { 6, 'prop' },
    bracelets_1 = { 7, 'prop' },     bracelets_2 = { 7, 'prop' },
}

function Clothing.Available()
    return GetResourceState('fivem-appearance') == 'started'
end

--- Traduce una divisa skinchanger in liste di componenti e prop nativi.
local function translate(components)
    local nativeComponents, nativeProps = {}, {}

    for key, value in pairs(components or {}) do
        local mapping = COMPONENT_MAP[key]
        if mapping then
            local id, kind = mapping[1], mapping[2]
            local isTexture = key:sub(-2) == '_2'
            local bucket = kind == 'prop' and nativeProps or nativeComponents

            bucket[id] = bucket[id] or { [kind == 'prop' and 'prop_id' or 'component_id'] = id, drawable = 0, texture = 0 }

            if isTexture then
                bucket[id].texture = tonumber(value) or 0
            else
                bucket[id].drawable = tonumber(value) or 0
            end
        end
    end

    local componentList, propList = {}, {}
    for _, entry in pairs(nativeComponents) do
        componentList[#componentList + 1] = entry
    end
    for _, entry in pairs(nativeProps) do
        propList[#propList + 1] = entry
    end

    return componentList, propList
end

function Clothing.Snapshot()
    if not Clothing.Available() then
        return nil
    end

    local ok, components = pcall(function()
        return exports['fivem-appearance']:getPedComponents(PlayerPedId())
    end)
    local okProps, props = pcall(function()
        return exports['fivem-appearance']:getPedProps(PlayerPedId())
    end)

    if not ok and not okProps then
        return nil
    end

    return {
        components = ok and components or {},
        props = okProps and props or {},
    }
end

function Clothing.Apply(components)
    if not Clothing.Available() or type(components) ~= 'table' then
        return false
    end

    local componentList, propList = translate(components)

    if #componentList > 0 then
        pcall(function()
            exports['fivem-appearance']:setPedComponents(PlayerPedId(), componentList)
        end)
    end

    if #propList > 0 then
        pcall(function()
            exports['fivem-appearance']:setPedProps(PlayerPedId(), propList)
        end)
    end

    return true
end

function Clothing.Restore(snapshot)
    if not Clothing.Available() or type(snapshot) ~= 'table' then
        return false
    end

    if snapshot.components and #snapshot.components > 0 then
        pcall(function()
            exports['fivem-appearance']:setPedComponents(PlayerPedId(), snapshot.components)
        end)
    end

    if snapshot.props and #snapshot.props > 0 then
        pcall(function()
            exports['fivem-appearance']:setPedProps(PlayerPedId(), snapshot.props)
        end)
    end

    return true
end

--- Salva l'abito civile in memoria e su KVP, cosi' sopravvive a un rientro.
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
