--[[
    KF_Police - Bridge interazioni: ox_target
    ----------------------------------------------------------------------------
    Contratto implementato anche da cl_marker.lua:
      Target.AddZone(opts)   opts = { name, coords, radius, label, icon,
                                      permission, canInteract, onSelect }
      Target.RemoveZone(name)
      Target.Available()     -> boolean
]]

if Config.Target ~= 'ox_target' then
    return
end

Target = {}

local zones = {}

function Target.Available()
    return GetResourceState('ox_target') == 'started'
end

--- @param opts table
function Target.AddZone(opts)
    if not opts or not opts.name or not opts.coords then
        return
    end

    Target.RemoveZone(opts.name)

    zones[opts.name] = exports.ox_target:addSphereZone({
        coords = opts.coords,
        radius = opts.radius or Config.TargetRadius,
        debug = Config.Debug,
        options = {
            {
                name = opts.name,
                label = opts.label or 'Interagisci',
                icon = opts.faIcon or 'fa-solid fa-hand',
                distance = opts.radius or Config.TargetRadius,
                canInteract = function()
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
                end,
                onSelect = function()
                    if opts.onSelect then
                        opts.onSelect()
                    end
                end,
            },
        },
    })
end

function Target.RemoveZone(name)
    if not name or not zones[name] then
        return
    end

    pcall(exports.ox_target.removeZone, exports.ox_target, zones[name])
    zones[name] = nil
end

function Target.RemoveAll()
    for name in pairs(zones) do
        Target.RemoveZone(name)
    end
end

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        Target.RemoveAll()
    end
end)
