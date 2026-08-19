--[[
    KF_Police - Permessi per grado
    ----------------------------------------------------------------------------
    Fonte unica di verita' dei permessi. Lo stesso file gira su client e server:
    il client la usa per non mostrare voci inutili, il server per rifiutare.
    Il controllo autorevole e' SEMPRE quello del server (RequirePermission).

    Sintassi: '@N' eredita tutti i permessi del grado N dello stesso lavoro.
    I gradi corrispondono a `job_grades`:
      police -> recruit(0) officer(1) sergeant(2) lieutenant(3) boss(4)
]]

Config.Permissions = {
    police = {
        -- recruit
        [0] = {
            'mdt.view',
            'mdt.citizen.view',
            'mdt.vehicle.view',
            'mdt.report.create',
            'mdt.report.edit',
            'mdt.note.create',
            'mdt.jail.view',
            'duty.toggle',
            'cloakroom.use',
            'armory.use',
            'garage.use',
            'radio.use',
            'field.identify',
            'objects.place',
        },
        -- officer
        [1] = {
            '@0',
            'mdt.charge.add',
            'mdt.vehicle.flag',
            'field.cuff',
            'field.search',
            'field.lockpick',
            'jail.send',
        },
        -- sergeant
        [2] = {
            '@1',
            'mdt.wanted.set',
            'mdt.note.delete',
            'field.impound',
            'field.fine',
            'field.license',
            'mdt.fine.issue',
        },
        -- lieutenant
        [3] = {
            '@2',
            'mdt.charge.void',
            'mdt.report.delete',
            'jail.release',
            'mdt.roster.view',
        },
        -- boss (Captain)
        [4] = {
            '@3',
            'mdt.penalcode.edit',
            'mdt.tag.edit',
            'mdt.audit.view',
            'armory.buy',
            'society.boss',
        },
    },

    --- Il personale sanitario consulta il MDT ma non opera sui fascicoli.
    ambulance = {
        [0] = {
            'mdt.view',
            'mdt.citizen.view',
            'mdt.vehicle.view',
            'mdt.note.create',
            'radio.use',
            'duty.toggle',
        },
        [1] = { '@0' },
        [2] = { '@1', 'mdt.report.create' },
        [3] = { '@2' },
        [4] = { '@3', 'mdt.roster.view' },
    },
}

--- Permessi che implicano scrittura: usati dal rate limiter e dall'audit.
Config.WritePermissions = {
    ['mdt.report.create'] = true,
    ['mdt.report.edit'] = true,
    ['mdt.report.delete'] = true,
    ['mdt.note.create'] = true,
    ['mdt.note.delete'] = true,
    ['mdt.charge.add'] = true,
    ['mdt.charge.void'] = true,
    ['mdt.wanted.set'] = true,
    ['mdt.vehicle.flag'] = true,
    ['mdt.penalcode.edit'] = true,
    ['mdt.tag.edit'] = true,
    ['mdt.fine.issue'] = true,
    ['jail.send'] = true,
    ['jail.release'] = true,
    ['field.impound'] = true,
    ['field.fine'] = true,
    ['field.license'] = true,
    ['armory.buy'] = true,
}

local cache = {}

--- Risolve l'insieme dei permessi di un grado, seguendo le ereditarieta' '@N'.
--- @param jobName string
--- @param grade number
--- @return table<string, boolean>
function ResolvePermissions(jobName, grade)
    grade = tonumber(grade) or 0

    local jobTable = Config.Permissions[jobName]
    if not jobTable then
        return {}
    end

    local key = ('%s:%d'):format(jobName, grade)
    if cache[key] then
        return cache[key]
    end

    local resolved = {}
    local visiting = {}

    local function collect(g)
        if visiting[g] then
            return -- protezione contro ereditarieta' circolari
        end
        visiting[g] = true

        local list = jobTable[g]
        if not list then
            return
        end

        for i = 1, #list do
            local entry = list[i]
            local inherited = type(entry) == 'string' and entry:match('^@(%d+)$')
            if inherited then
                collect(tonumber(inherited))
            else
                resolved[entry] = true
            end
        end
    end

    collect(grade)
    cache[key] = resolved
    return resolved
end

--- @return boolean
function HasPermission(jobName, grade, permission)
    if not permission or permission == '' then
        return true
    end

    return ResolvePermissions(jobName, grade)[permission] == true
end

--- Elenco piatto dei permessi, pronto per la NUI.
--- @return string[]
function PermissionList(jobName, grade)
    local list = {}
    for permission in pairs(ResolvePermissions(jobName, grade)) do
        list[#list + 1] = permission
    end
    table.sort(list)
    return list
end
