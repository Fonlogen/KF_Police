--[[
    KF_Police - Rapporti
    ----------------------------------------------------------------------------
    Coinvolti, veicoli e tag stanno nelle tabelle di giunzione: niente piu' liste
    JSON dentro la riga del rapporto. Il salvataggio e' una transazione, quindi
    un rapporto non resta mai a meta' (testata salvata e collegamenti persi).
]]

local ROLES = { suspect = true, victim = true, witness = true }
local STATUSES = { draft = true, open = true, closed = true }

-- ============================================================================
--  Lettura
-- ============================================================================

local function loadInvolved(reportId)
    local rows = Database.Query([[
        SELECT ri.identifier, ri.role, u.firstname, u.lastname, u.ssn
        FROM kf_police_report_involved ri
        LEFT JOIN users u ON u.identifier = ri.identifier
        WHERE ri.report_id = ?
    ]], { reportId }) or {}

    local list = {}
    for _, row in ipairs(rows) do
        list[#list + 1] = {
            identifier = row.identifier,
            role = row.role,
            firstName = row.firstname or 'Sconosciuto',
            lastName = row.lastname or '',
            ssn = row.ssn,
        }
    end

    return list
end

local function loadVehicles(reportId)
    local rows = Database.Query([[
        SELECT rv.plate, ov.vehicle, ov.owner,
               CONCAT_WS(' ', u.firstname, u.lastname) AS owner_name
        FROM kf_police_report_vehicles rv
        LEFT JOIN owned_vehicles ov ON ov.plate = rv.plate
        LEFT JOIN users u ON u.identifier = ov.owner
        WHERE rv.report_id = ?
    ]], { reportId }) or {}

    local list = {}
    for _, row in ipairs(rows) do
        list[#list + 1] = {
            plate = row.plate,
            model = row.vehicle and DecodeVehicleModel(row.vehicle) or nil,
            owner = row.owner,
            ownerName = Trim(row.owner_name) ~= '' and Trim(row.owner_name) or nil,
        }
    end

    return list
end

local function loadTags(reportId)
    local rows = Database.Query([[
        SELECT t.id, t.label, t.icon, t.color
        FROM kf_police_report_tags rt
        INNER JOIN kf_police_tags t ON t.id = rt.tag_id
        WHERE rt.report_id = ?
    ]], { reportId }) or {}

    local list = {}
    for _, row in ipairs(rows) do
        list[#list + 1] = {
            id = tonumber(row.id),
            label = row.label,
            icon = row.icon,
            color = row.color,
        }
    end

    return list
end

RegisterMdtEndpoint('reports:list', 'mdt.view', function(officer, payload)
    local page = ClampInt(payload.page, 1, 10000, 1)
    local pageSize = ClampInt(payload.pageSize, 1, Config.MaxPageSize, Config.PageSize)
    local offset = (page - 1) * pageSize

    local where = { '1 = 1' }
    local params = {}

    local query = SanitizeText(payload.query, Config.Limits.query)
    if query ~= '' then
        where[#where + 1] = '(r.title LIKE ? OR r.officer LIKE ? OR r.location LIKE ?)'
        local like = '%' .. query .. '%'
        params[#params + 1] = like
        params[#params + 1] = like
        params[#params + 1] = like
    end

    if payload.status and STATUSES[payload.status] then
        where[#where + 1] = 'r.status = ?'
        params[#params + 1] = payload.status
    end

    -- I rapporti riservati li vede solo chi puo' eliminarli (grado alto).
    local info = OfficerInfo(officer)
    if not HasPermission(info.job, info.grade, 'mdt.report.delete') then
        where[#where + 1] = '(r.is_confidential = 0 OR r.officer_id = ?)'
        params[#params + 1] = info.identifier
    end

    local whereClause = table.concat(where, ' AND ')

    local total = Database.Scalar(
        ('SELECT COUNT(*) FROM kf_police_reports r WHERE %s'):format(whereClause), params)

    local rows = Database.Query(([[
        SELECT
            r.id, r.title, r.officer, r.officer_id, r.location, r.status,
            r.is_confidential, r.created_at, r.updated_at,
            (SELECT COUNT(*) FROM kf_police_report_involved ri WHERE ri.report_id = r.id) AS involved_count
        FROM kf_police_reports r
        WHERE %s
        ORDER BY r.created_at DESC, r.id DESC
        LIMIT %d OFFSET %d
    ]]):format(whereClause, pageSize, offset), params) or {}

    local list = {}
    for _, row in ipairs(rows) do
        list[#list + 1] = {
            id = tonumber(row.id),
            title = row.title,
            officer = row.officer,
            officerId = row.officer_id,
            location = row.location,
            status = row.status,
            isConfidential = tonumber(row.is_confidential) == 1,
            date = tostring(row.created_at),
            updatedAt = tostring(row.updated_at),
            involvedCount = tonumber(row.involved_count) or 0,
            tags = loadTags(tonumber(row.id)),
        }
    end

    return MdtOk({
        rows = list,
        total = tonumber(total) or 0,
        page = page,
        pageSize = pageSize,
    })
end)

RegisterMdtEndpoint('reports:get', 'mdt.view', function(officer, payload)
    local id = tonumber(payload.id)
    if not id then
        return MdtError('invalid_data')
    end

    local report = Database.Single([[
        SELECT id, title, description, officer, officer_id, location, status,
               is_confidential, created_at, updated_at
        FROM kf_police_reports WHERE id = ?
    ]], { id })

    if not report then
        return MdtError('report_not_found')
    end

    local info = OfficerInfo(officer)
    if tonumber(report.is_confidential) == 1
        and report.officer_id ~= info.identifier
        and not HasPermission(info.job, info.grade, 'mdt.report.delete') then
        return MdtError('no_permission')
    end

    return MdtOk({
        report = {
            id = tonumber(report.id),
            title = report.title,
            description = report.description or '',
            officer = report.officer,
            officerId = report.officer_id,
            location = report.location,
            status = report.status,
            isConfidential = tonumber(report.is_confidential) == 1,
            date = tostring(report.created_at),
            updatedAt = tostring(report.updated_at),
            involved = loadInvolved(id),
            vehicles = loadVehicles(id),
            tags = loadTags(id),
        },
    })
end)

-- ============================================================================
--  Scrittura
-- ============================================================================

--- Costruisce le query dei collegamenti di un rapporto.
local function linkStatements(reportId, payload)
    local statements = {
        { 'DELETE FROM kf_police_report_involved WHERE report_id = ?', { reportId } },
        { 'DELETE FROM kf_police_report_vehicles WHERE report_id = ?', { reportId } },
        { 'DELETE FROM kf_police_report_tags WHERE report_id = ?', { reportId } },
    }

    local seenInvolved = {}
    for _, entry in ipairs(payload.involved or {}) do
        local identifier = SanitizeText(type(entry) == 'table' and entry.identifier or entry, 64)
        local role = type(entry) == 'table' and entry.role or 'suspect'

        if not ROLES[role] then
            role = 'suspect'
        end

        local key = identifier .. ':' .. role
        if identifier ~= '' and not seenInvolved[key] then
            seenInvolved[key] = true
            statements[#statements + 1] = {
                'INSERT IGNORE INTO kf_police_report_involved (report_id, identifier, role) VALUES (?, ?, ?)',
                { reportId, identifier, role },
            }
        end
    end

    local seenPlates = {}
    for _, entry in ipairs(payload.vehicles or {}) do
        local plate = NormalizePlate(type(entry) == 'table' and entry.plate or entry)
        if plate and #plate <= Config.Limits.plate and not seenPlates[plate] then
            seenPlates[plate] = true
            statements[#statements + 1] = {
                'INSERT IGNORE INTO kf_police_report_vehicles (report_id, plate) VALUES (?, ?)',
                { reportId, plate },
            }
        end
    end

    local seenTags = {}
    for _, entry in ipairs(payload.tags or {}) do
        local tagId = tonumber(type(entry) == 'table' and entry.id or entry)
        if tagId and not seenTags[tagId] then
            seenTags[tagId] = true
            statements[#statements + 1] = {
                'INSERT IGNORE INTO kf_police_report_tags (report_id, tag_id) VALUES (?, ?)',
                { reportId, tagId },
            }
        end
    end

    return statements
end

RegisterMdtEndpoint('reports:save', 'mdt.report.create', function(officer, payload)
    local title = SanitizeText(payload.title, Config.Limits.reportTitle)
    if title == '' then
        return MdtError('invalid_data')
    end

    local description = SanitizeText(payload.description, Config.Limits.reportBody)
    local location = SanitizeText(payload.location, Config.Limits.location)
    local status = STATUSES[payload.status] and payload.status or 'open'
    local confidential = ToBool(payload.isConfidential) and 1 or 0

    local info = OfficerInfo(officer)
    local id = tonumber(payload.id)

    if id then
        local existing = Database.Single(
            'SELECT id, officer_id FROM kf_police_reports WHERE id = ?', { id })

        if not existing then
            return MdtError('report_not_found')
        end

        -- Modificare un rapporto di altri richiede il permesso di modifica.
        if existing.officer_id ~= info.identifier
            and not HasPermission(info.job, info.grade, 'mdt.report.edit') then
            return MdtError('no_permission')
        end

        Database.Update([[
            UPDATE kf_police_reports
            SET title = ?, description = ?, location = ?, status = ?, is_confidential = ?
            WHERE id = ?
        ]], { title, description, location ~= '' and location or 'Sconosciuto', status, confidential, id })
    else
        id = Database.Insert([[
            INSERT INTO kf_police_reports
                (title, description, officer, officer_id, location, status, is_confidential)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        ]], {
            title,
            description,
            info.name,
            info.identifier,
            location ~= '' and location or 'Sconosciuto',
            status,
            confidential,
        })

        if not id then
            return MdtError('report_create_failed')
        end
    end

    if not Database.Transaction(linkStatements(id, payload)) then
        Logger.Warn('Collegamenti del rapporto %s non salvati', id)
    end

    Logger.Audit(officer, payload.id and 'report.update' or 'report.create', tostring(id), {
        title = title,
        status = status,
    })

    Invalidate('reports', id)
    PushCounters()

    for _, entry in ipairs(payload.involved or {}) do
        local identifier = SanitizeText(type(entry) == 'table' and entry.identifier or entry, 64)
        if identifier ~= '' then
            Invalidate('citizen', identifier)
        end
    end

    return MdtOk({
        id = id,
        message = payload.id and Locale('report_updated') or Locale('report_created'),
    })
end)

RegisterMdtEndpoint('reports:delete', 'mdt.report.delete', function(officer, payload)
    local id = tonumber(payload.id)
    if not id then
        return MdtError('invalid_data')
    end

    local report = Database.Single('SELECT id, title FROM kf_police_reports WHERE id = ?', { id })
    if not report then
        return MdtError('report_not_found')
    end

    local ok = Database.Transaction({
        { 'DELETE FROM kf_police_report_involved WHERE report_id = ?', { id } },
        { 'DELETE FROM kf_police_report_vehicles WHERE report_id = ?', { id } },
        { 'DELETE FROM kf_police_report_tags WHERE report_id = ?', { id } },
        { 'UPDATE kf_police_charges SET report_id = NULL WHERE report_id = ?', { id } },
        { 'DELETE FROM kf_police_reports WHERE id = ?', { id } },
    })

    if not ok then
        return MdtError('invalid_data')
    end

    Logger.Audit(officer, 'report.delete', tostring(id), { title = report.title })
    Invalidate('reports')
    PushCounters()

    return MdtOk({ message = Locale('report_deleted') })
end)

-- ============================================================================
--  Tag (icone FontAwesome, mai emoji)
-- ============================================================================

RegisterMdtEndpoint('tags:list', 'mdt.view', function()
    local rows = Database.Query('SELECT id, label, icon, color FROM kf_police_tags ORDER BY label') or {}

    local list = {}
    for _, row in ipairs(rows) do
        list[#list + 1] = {
            id = tonumber(row.id),
            label = row.label,
            icon = row.icon or 'warning',
            color = row.color or '#A8322A',
        }
    end

    return MdtOk({ rows = list })
end)

RegisterMdtEndpoint('tags:save', 'mdt.tag.edit', function(officer, payload)
    -- StripEmoji: l'etichetta di un tag non contiene mai caratteri Unicode
    -- decorativi, l'icona sta nella colonna `icon`.
    local label = StripEmoji(SanitizeText(payload.label, 100))
    local icon = SanitizeText(payload.icon, 48)
    local color = SanitizeText(payload.color, 16)

    if label == '' then
        return MdtError('invalid_data')
    end

    if not color:match('^#%x%x%x%x%x%x$') then
        color = '#A8322A'
    end

    if icon == '' then
        icon = 'warning'
    end

    local id = tonumber(payload.id)

    if id then
        Database.Update('UPDATE kf_police_tags SET label = ?, icon = ?, color = ? WHERE id = ?',
            { label, icon, color, id })
    else
        id = Database.Insert('INSERT INTO kf_police_tags (label, icon, color) VALUES (?, ?, ?)',
            { label, icon, color })
    end

    Logger.Audit(officer, 'tag.save', tostring(id), { label = label, icon = icon })

    return MdtOk({ id = id, message = Locale('tag_saved') })
end)

RegisterMdtEndpoint('tags:delete', 'mdt.tag.edit', function(officer, payload)
    local id = tonumber(payload.id)
    if not id then
        return MdtError('invalid_data')
    end

    Database.Transaction({
        { 'DELETE FROM kf_police_report_tags WHERE tag_id = ?', { id } },
        { 'DELETE FROM kf_police_tags WHERE id = ?', { id } },
    })

    Logger.Audit(officer, 'tag.delete', tostring(id))

    return MdtOk({})
end)
