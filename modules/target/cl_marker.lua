--[[
    KF_Police - Bridge interazioni: marker classici
    ----------------------------------------------------------------------------
    Fallback usato quando Config.Target = 'marker'. Stesso contratto di cl_ox.lua:
    disegna un marker, mostra un suggerimento a schermo e attiva l'azione con E.
]]

if Config.Target ~= 'marker' then
    return
end

Target = {}

local zones = {}
local activeZone = nil

function Target.Available()
    return true
end

function Target.AddZone(opts)
    if not opts or not opts.name or not opts.coords then
        return
    end

    zones[opts.name] = opts
end

function Target.RemoveZone(name)
    if name then
        zones[name] = nil
        if activeZone == name then
            activeZone = nil
            lib.hideTextUI()
        end
    end
end

function Target.RemoveAll()
    zones = {}
    activeZone = nil
    lib.hideTextUI()
end

local function allowed(opts)
    if not Framework.HasAllowedJob() then
        return false
    end

    if opts.permission then
        local jobName, grade = Framework.GetJob()
        if not HasPermission(jobName, grade, opts.permission) then
            return false
        end
    end

    if opts.canInteract then
        return opts.canInteract() ~= false
    end

    return true
end

CreateThread(function()
    local markerCfg = Config.Marker
    local drawDistance = markerCfg.drawDistance or 10.0

    while true do
        local sleep = 750
        local coords = GetEntityCoords(PlayerPedId())
        local nearest, nearestDistance = nil, drawDistance

        for name, opts in pairs(zones) do
            local distance = #(coords - opts.coords)
            if distance < drawDistance and allowed(opts) then
                sleep = 0
                DrawMarker(
                    markerCfg.type[opts.marker or 'cloakroom'] or 21,
                    opts.coords.x, opts.coords.y, opts.coords.z,
                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                    markerCfg.size.x, markerCfg.size.y, markerCfg.size.z,
                    markerCfg.color.r, markerCfg.color.g, markerCfg.color.b, markerCfg.color.a or 120,
                    false, true, 2, false, nil, nil, false
                )

                if distance < (opts.radius or Config.TargetRadius) and distance < nearestDistance then
                    nearest, nearestDistance = name, distance
                end
            end
        end

        if nearest ~= activeZone then
            activeZone = nearest
            if nearest then
                lib.showTextUI(('[E] %s'):format(zones[nearest].label or 'Interagisci'), {
                    position = 'left-center',
                })
            else
                lib.hideTextUI()
            end
        end

        if activeZone and IsControlJustReleased(0, 38) then
            local opts = zones[activeZone]
            if opts and opts.onSelect then
                opts.onSelect()
            end
        end

        Wait(sleep)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        lib.hideTextUI()
    end
end)
