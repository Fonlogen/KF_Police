--[[
    KF_Police - Anagrafica cittadini
    ----------------------------------------------------------------------------
    La ricerca e' SQL e paginata: nessun elenco completo viene mai inviato alla
    NUI. Le colonne ordinabili sono su lista bianca, quindi la NUI non puo'
    iniettare SQL passando un nome di colonna arbitrario.
]]

-- ============================================================================
--  Etichette dei lavori (cache leggera, ricaricabile)
-- ============================================================================

local jobLabels = {}
local gradeLabels = {}

function RefreshJobLabels()
    jobLabels, gradeLabels = {}, {}

    for _, row in ipairs(Database.Query('SELECT name, label FROM jobs') or {}) do
        jobLabels[row.name] = row.label or row.name
    end

    for _, row in ipairs(Database.Query('SELECT job_name, grade, label FROM job_grades') or {}) do
        gradeLabels[row.job_name] = gradeLabels[row.job_name] or {}
        gradeLabels[row.job_name][tonumber(row.grade) or 0] = row.label
    end
end

--- Etichetta leggibile del lavoro, es. "LSPD - Captain".
--- @return string
function GetJobLabel(jobName, grade)
    if not jobName or jobName == '' or jobName == 'unemployed' then
        return 'Disoccupato'
    end

    local job = jobLabels[jobName] or jobName
    local gradeLabel = gradeLabels[jobName] and gradeLabels[jobName][tonumber(grade) or 0]

    if gradeLabel and gradeLabel ~= '' then
        return ('%s - %s'):format(job, gradeLabel)
    end

    return job
end

Database.OnReady(function()
    RefreshJobLabels()
end)

-- ============================================================================
--  Ricerca
-- ============================================================================

--- Colonne ordinabili ammesse: la NUI puo' scegliere solo tra queste.
local SORTABLE = {
    firstname = 'u.firstname',
    lastname = 'u.lastname',
    nationality = 'u.nationality',
    job = 'u.job',
    ssn = 'u.ssn',
}

local function buildCitizenFilter(payload)
    local where = { '1 = 1' }
    local params = {}

    local query = SanitizeText(payload.query, Config.Limits.query)
    if query ~= '' then
        where[#where + 1] = [[(
            u.firstname LIKE ? OR u.lastname LIKE ?
            OR CONCAT(u.firstname, ' ', u.lastname) LIKE ?
            OR u.ssn LIKE ? OR u.phone_number LIKE ?
        )]]

        local like = '%' .. query .. '%'
        params[#params + 1] = like
        params[#params + 1] = like
        params[#params + 1] = like
        params[#params + 1] = like
        params[#params + 1] = like
    end

    if payload.filter == 'wanted' then
        where[#where + 1] = 'p.is_wanted = 1'
    elseif payload.filter == 'jailed' then
        where[#where + 1] = 'j.identifier IS NOT NULL'
    end

    return table.concat(where, ' AND '), params
end

local JOINS = [[
    FROM users u
    LEFT JOIN kf_police_profiles p ON p.identifier = u.identifier
    LEFT JOIN kf_police_jail j
        ON j.identifier = u.identifier AND j.released_at IS NULL AND j.seconds_remaining > 0
]]

RegisterMdtEndpoint('citizens:search', 'mdt.citizen.view', function(_, payload)
    local page = ClampInt(payload.page, 1, 10000, 1)
    local pageSize = ClampInt(payload.pageSize, 1, Config.MaxPageSize, Config.PageSize)
    local offset = (page - 1) * pageSize

    local orderColumn = SORTABLE[payload.sortBy] or 'u.lastname'
    local orderDirection = payload.sortDir == 'desc' and 'DESC' or 'ASC'

    local whereClause, params = buildCitizenFilter(payload)

    local total = Database.Scalar(('SELECT COUNT(*) %s WHERE %s'):format(JOINS, whereClause), params)
    if total == nil then
        return MdtError('invalid_data')
    end

    local rows = Database.Query(([[
        SELECT
            u.identifier, u.firstname, u.lastname, u.ssn, u.dateofbirth, u.sex,
            u.nationality, u.phone_number, u.job, u.job_grade,
            p.mugshot, COALESCE(p.is_wanted, 0) AS is_wanted, p.wanted_reason,
            (j.identifier IS NOT NULL) AS is_jailed,
            j.seconds_remaining
        %s
        WHERE %s
        ORDER BY %s %s, u.firstname ASC
        LIMIT %d OFFSET %d
    ]]):format(JOINS, whereClause, orderColumn, orderDirection, pageSize, offset), params) or {}

    local list = {}
    for _, row in ipairs(rows) do
        list[#list + 1] = {
            identifier = row.identifier,
            firstName = row.firstname or 'Sconosciuto',
            lastName = row.lastname or '',
            ssn = row.ssn,
            dateOfBirth = row.dateofbirth,
            sex = row.sex,
            nationality = row.nationality or 'Los Santos',
            phone = row.phone_number,
            job = GetJobLabel(row.job, row.job_grade),
            mugshot = row.mugshot,
            isWanted = ToBool(row.is_wanted) or tonumber(row.is_wanted) == 1,
            wantedReason = row.wanted_reason,
            isJailed = tonumber(row.is_jailed) == 1,
            jailSecondsRemaining = tonumber(row.seconds_remaining) or 0,
        }
    end

    return MdtOk({
        rows = list,
        total = tonumber(total) or 0,
        page = page,
        pageSize = pageSize,
        wantedCount = tonumber(Database.Scalar('SELECT COUNT(*) FROM kf_police_profiles WHERE is_wanted = 1')) or 0,
    })
end)

-- ============================================================================
--  Dossier completo
-- ============================================================================

local function getLicenses(identifier)
    if not Database.TableExists('user_licenses') then
        return {}
    end

    local rows
    if Database.TableExists('licenses') then
        rows = Database.Query([[
            SELECT ul.type, COALESCE(l.label, ul.type) AS label
            FROM user_licenses ul
            LEFT JOIN licenses l ON l.type = ul.type
            WHERE ul.owner = ?
        ]], { identifier })
    else
        rows = Database.Query('SELECT type, type AS label FROM user_licenses WHERE owner = ?', { identifier })
    end

    local list = {}
    for _, row in ipairs(rows or {}) do
        list[#list + 1] = { type = row.type, label = row.label or row.type }
    end

    return list
end

local function getProperties(identifier)
    local list = {}

    if Database.TableExists('coin_system_items') then
        local rows = Database.Query(
            'SELECT property_id, label, category, coords FROM coin_system_items WHERE owner = ?',
            { identifier }) or {}

        for _, row in ipairs(rows) do
            list[#list + 1] = {
                id = row.property_id,
                label = row.label or row.property_id,
                address = row.coords or 'N/A',
                city = row.category or 'Los Santos',
            }
        end
    end

    return list
end

--- Modello leggibile a partire dal blob `vehicle` di owned_vehicles.
function DecodeVehicleModel(vehicleJson)
    local props = DecodeJson(vehicleJson, {})
    return props.model or props.name or 'Sconosciuto'
end

local function getOwnedVehicles(identifier)
    if not Database.TableExists('owned_vehicles') then
        return {}
    end

    local rows = Database.Query([[
        SELECT
            ov.plate, ov.vehicle, ov.type, ov.stored, ov.pound,
            f.is_stolen, f.is_impounded, f.has_bolo
        FROM owned_vehicles ov
        LEFT JOIN kf_police_vehicle_flags f ON f.plate = ov.plate
        WHERE ov.owner = ?
    ]], { identifier }) or {}

    local list = {}
    for _, row in ipairs(rows) do
        list[#list + 1] = {
            plate = NormalizePlate(row.plate),
            model = DecodeVehicleModel(row.vehicle),
            type = row.type or 'car',
            stored = tonumber(row.stored) == 1,
            isStolen = tonumber(row.is_stolen) == 1,
            isImpounded = tonumber(row.is_impounded) == 1,
            hasBolo = tonumber(row.has_bolo) == 1,
        }
    end

    return list
end

--- Reati di un cittadino, i piu' recenti per primi.
function GetCitizenCharges(identifier)
    local rows = Database.Query([[
        SELECT
            c.id, c.penalcode_id, c.crime, c.fine, c.jail_months, c.is_paid,
            c.officer_name, c.location, c.victim_identifier, c.report_id,
            c.created_at, c.voided_at, c.voided_by, c.void_reason,
            pc.code AS penal_code,
            CONCAT_WS(' ', v.firstname, v.lastname) AS victim_name
        FROM kf_police_charges c
        LEFT JOIN kf_police_penalcode pc ON pc.id = c.penalcode_id
        LEFT JOIN users v ON v.identifier = c.victim_identifier
        WHERE c.identifier = ?
        ORDER BY c.created_at DESC, c.id DESC
    ]], { identifier }) or {}

    local list = {}
    local totalFine, totalMonths, unpaidFine = 0, 0, 0

    for _, row in ipairs(rows) do
        local voided = row.voided_at ~= nil

        list[#list + 1] = {
            id = tonumber(row.id),
            penalcodeId = tonumber(row.penalcode_id),
            code = row.penal_code,
            crime = row.crime,
            fine = tonumber(row.fine) or 0,
            jailMonths = tonumber(row.jail_months) or 0,
            isPaid = tonumber(row.is_paid) == 1,
            officer = row.officer_name,
            location = row.location,
            victim = Trim(row.victim_name) ~= '' and Trim(row.victim_name) or nil,
            victimIdentifier = row.victim_identifier,
            reportId = tonumber(row.report_id),
            date = tostring(row.created_at),
            voided = voided,
            voidedAt = row.voided_at and tostring(row.voided_at) or nil,
            voidedBy = row.voided_by,
            voidReason = row.void_reason,
        }

        if not voided then
            totalFine = totalFine + (tonumber(row.fine) or 0)
            totalMonths = totalMonths + (tonumber(row.jail_months) or 0)
            if tonumber(row.is_paid) ~= 1 then
                unpaidFine = unpaidFine + (tonumber(row.fine) or 0)
            end
        end
    end

    return list, {
        totalFine = totalFine,
        totalMonths = totalMonths,
        unpaidFine = unpaidFine,
        count = #list,
    }
end

--- Note di un cittadino.
function GetCitizenNotes(identifier)
    local rows = Database.Query([[
        SELECT id, note, officer_name, created_at, updated_at
        FROM kf_police_notes
        WHERE identifier = ?
        ORDER BY created_at DESC, id DESC
    ]], { identifier }) or {}

    local list = {}
    for _, row in ipairs(rows) do
        list[#list + 1] = {
            id = tonumber(row.id),
            note = row.note,
            officer = row.officer_name,
            date = tostring(row.created_at),
            updatedAt = tostring(row.updated_at),
        }
    end

    return list
end

--- Rapporti che coinvolgono il cittadino.
local function getLinkedReports(identifier)
    local rows = Database.Query([[
        SELECT r.id, r.title, r.officer, r.created_at, r.status, ri.role
        FROM kf_police_report_involved ri
        INNER JOIN kf_police_reports r ON r.id = ri.report_id
        WHERE ri.identifier = ?
        ORDER BY r.created_at DESC
        LIMIT 50
    ]], { identifier }) or {}

    local list = {}
    for _, row in ipairs(rows) do
        list[#list + 1] = {
            id = tonumber(row.id),
            title = row.title,
            officer = row.officer,
            date = tostring(row.created_at),
            status = row.status,
            role = row.role,
        }
    end

    return list
end

--- Profilo, creandolo se manca. Restituisce sempre una tabella.
function EnsureProfile(identifier, ssn)
    local profile = Database.Single(
        'SELECT * FROM kf_police_profiles WHERE identifier = ?', { identifier })

    if profile then
        return profile
    end

    Database.Insert(
        'INSERT IGNORE INTO kf_police_profiles (identifier, ssn) VALUES (?, ?)',
        { identifier, ssn })

    return Database.Single('SELECT * FROM kf_police_profiles WHERE identifier = ?', { identifier })
        or { identifier = identifier, ssn = ssn, is_wanted = 0 }
end

RegisterMdtEndpoint('citizens:get', 'mdt.citizen.view', function(_, payload)
    local identifier = SanitizeText(payload.identifier, 64)
    if identifier == '' then
        return MdtError('invalid_data')
    end

    local user = Database.Single([[
        SELECT identifier, firstname, lastname, ssn, dateofbirth, sex, height,
               nationality, phone_number, job, job_grade
        FROM users WHERE identifier = ?
    ]], { identifier })

    if not user then
        return MdtError('citizen_not_found')
    end

    local profile = EnsureProfile(identifier, user.ssn)
    local charges, totals = GetCitizenCharges(identifier)
    local jail = GetJailStatus and GetJailStatus(identifier) or nil

    return MdtOk({
        citizen = {
            identifier = user.identifier,
            firstName = user.firstname or 'Sconosciuto',
            lastName = user.lastname or '',
            ssn = user.ssn,
            dateOfBirth = user.dateofbirth,
            sex = user.sex,
            height = tonumber(user.height),
            nationality = user.nationality or 'Los Santos',
            phone = user.phone_number,
            job = GetJobLabel(user.job, user.job_grade),
            jobName = user.job,
            jobGrade = tonumber(user.job_grade) or 0,
            mugshot = profile.mugshot,
            isWanted = tonumber(profile.is_wanted) == 1,
            wantedReason = profile.wanted_reason,
            wantedBy = profile.wanted_by_name,
            wantedAt = profile.wanted_at and tostring(profile.wanted_at) or nil,
        },
        charges = charges,
        totals = totals,
        notes = GetCitizenNotes(identifier),
        vehicles = getOwnedVehicles(identifier),
        licenses = getLicenses(identifier),
        properties = getProperties(identifier),
        reports = getLinkedReports(identifier),
        jail = jail,
    })
end)

--- Foto segnaletica: URL o percorso locale, mai un host esterno per difetto.
RegisterMdtEndpoint('citizens:setMugshot', 'mdt.note.create', function(officer, payload)
    local identifier = SanitizeText(payload.identifier, 64)
    local mugshot = SanitizeText(payload.mugshot, 512)

    if identifier == '' then
        return MdtError('invalid_data')
    end

    EnsureProfile(identifier)

    Database.Update('UPDATE kf_police_profiles SET mugshot = ? WHERE identifier = ?', {
        mugshot ~= '' and mugshot or nil,
        identifier,
    })

    Logger.Audit(officer, 'citizen.mugshot', identifier, { mugshot = mugshot })
    Invalidate('citizen', identifier)

    return MdtOk({ mugshot = mugshot })
end)
