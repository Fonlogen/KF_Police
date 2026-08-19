--[[
    KF_Police - Spogliatoio (client)
    ----------------------------------------------------------------------------
    Divisa per grado e sesso da cfg_duty.lua, applicata tramite il bridge
    modules/clothing (fivem-appearance oppure skinchanger). L'abito civile viene
    salvato prima di indossare la divisa e ripristinato all'uscita, cosi' lo
    spogliatoio non distrugge il vestiario personale.
]]

local wearingUniform = false

local function uniformFor(gradeName)
    local uniform = Config.Uniforms[gradeName]
    if not uniform then
        return nil
    end

    return uniform[Framework.GetSex()] or uniform.male
end

local function applyUniform()
    local _, _, gradeName = Framework.GetJob()
    local components = uniformFor(gradeName)

    if not components then
        return NotifyLocale('uniform_missing', 'error')
    end

    if not Clothing or not Clothing.Available() then
        return NotifyLocale('uniform_missing', 'error')
    end

    if Config.Cloakroom.RestoreCivilian and not wearingUniform then
        Clothing.SaveCivilian()
    end

    Clothing.Apply(components)
    wearingUniform = true
    NotifyLocale('uniform_applied', 'success')
end

local function applyExtra(extraId)
    local extra = Config.Uniforms[extraId]
    if not extra then
        return
    end

    local components = extra[Framework.GetSex()] or extra.male
    if components and Clothing and Clothing.Available() then
        Clothing.Apply(components)
    end
end

local function restoreCivilian()
    if not Clothing or not Clothing.Available() then
        return
    end

    if Clothing.RestoreCivilian() then
        wearingUniform = false
        NotifyLocale('uniform_removed', 'success')
    end
end

local function openCloakroom()
    local jobName, grade = Framework.GetJob()

    local options = {
        {
            title = Locale('cloakroom_uniform'),
            icon = 'shirt',
            onSelect = applyUniform,
        },
        {
            title = Locale('cloakroom_civilian'),
            icon = 'user',
            onSelect = restoreCivilian,
        },
    }

    for _, extra in ipairs(Config.Cloakroom.Extras or {}) do
        options[#options + 1] = {
            title = extra.label,
            icon = 'vest',
            onSelect = function()
                applyExtra(extra.id)
            end,
        }
    end

    if HasPermission(jobName, grade, 'duty.toggle') then
        options[#options + 1] = {
            title = IsPlayerOnDuty() and Locale('duty_off') or Locale('duty_on'),
            icon = 'user-shield',
            onSelect = ToggleDuty,
        }
    end

    lib.registerContext({
        id = 'kf_police_cloakroom',
        title = Locale('cloakroom'),
        options = options,
    })

    lib.showContext('kf_police_cloakroom')
end

CreateThread(function()
    while not Target do
        Wait(200)
    end

    for stationKey, station in pairs(Config.Stations) do
        for index, coords in ipairs(station.cloakrooms or {}) do
            Target.AddZone({
                name = ('kf_police_cloakroom_%s_%d'):format(stationKey, index),
                coords = coords,
                radius = Config.TargetRadius,
                label = Locale('cloakroom'),
                faIcon = 'fa-solid fa-shirt',
                marker = 'cloakroom',
                permission = 'cloakroom.use',
                onSelect = openCloakroom,
            })
        end
    end
end)
