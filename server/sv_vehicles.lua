--[[
    KF_Police - Veicoli
    ----------------------------------------------------------------------------
    CORREZIONE BUG L3
    ----------------------------------------------------------------------------
    `SetVehicleFlag` mutava solo la tabella in RAM: rubato e sequestrato si
    perdevano al restart. Ora ogni flag e' una riga su
    `kf_police_vehicle_flags`, con chi e quando l'ha impostato.
]]

local SORTABLE = {
    plate = 'ov.plate',
    owner = 'owner_name',
    type = 'ov.type',
}

RegisterMdtEndpoint('vehicles:search', 'mdt.vehicle.view', function(_, payload)
    if not Database.TableExists('owned_vehicles') then
        return MdtOk({ rows = {}, total = 0, page = 1 })
    end

    local page = ClampInt(payload.page, 1, 10000, 1)
    local pageSize = ClampInt(payload.pageSize, 1, Config.MaxPageSize, Config.PageSize)
    local offset = (page - 1) * pageSize

    local where = { '1 = 1' }
    local params = {}

    local query = SanitizeText(payload.query, Config.Limits.query)
    if query ~= '' then
        where[#where + 1] = [[(
            ov.plate LIKE ? OR ov.vehicle LIKE ?
            OR CONCAT_WS(' ', u.firstname, u.lastname) LIKE ?
        )]]
        local like = '%' .. query .. '%'
        params[#params + 1] = like
        params[#params + 1] = like
        params[#params + 1] = like
    end

    if payload.filter == 'stolen' then
        where[#where + 1] = 'f.is_stolen = 1'
    elseif payload.filter == 'impounded' then
        where[#where + 1] = 'f.is_impounded = 1'
    elseif payload.filter == 'bolo' then
        where[#where + 1] = 'f.has_bolo = 1'
    end

    local whereClause = table.concat(where, ' AND ')
    local orderColumn = SORTABLE[payload.sortBy] or 'ov.plate'
    local orderDirection = payload.sortDir == 'desc' and 'DESC' or 'ASC'

    local joins = [[
        FROM owned_vehicles ov
        LEFT JOIN users u ON u.identifier = ov.owner
        LEFT JOIN kf_police_vehicle_flags f ON f.plate = ov.plate
    ]]

    local total = Database.Scalar(('SELECT COUNT(*) %s WHERE %s'):format(joins, whereClause), params)

    local rows = Database.Query(([[
        SELECT
            ov.plate, ov.vehicle, ov.type, ov.stored, ov.owner, ov.job,
            CONCAT_WS(' ', u.firstname, u.lastname) AS owner_name,
            COALESCE(f.is_stolen, 0) AS is_stolen,
            COALESCE(f.is_impounded, 0) AS is_impounded,
            COALESCE(f.has_bolo, 0) AS has_bolo
        %s
        WHERE %s
        ORDER BY %s %s
        LIMIT %d OFFSET %d
    ]]):format(joins, whereClause, orderColumn, orderDirection, pageSize, offset), params) or {}

    local list = {}
    for _, row in ipairs(rows) do
        list[#list + 1] = {
            plate = NormalizePlate(row.plate),
            model = DecodeVehicleModel(row.vehicle),
            type = row.type or 'car',
            stored = tonumber(row.stored) == 1,
            owner = row.owner,
            ownerName = Trim(row.owner_name) ~= '' and Trim(row.owner_name) or 'Sconosciuto',
            job = row.job,
            isStolen = tonumber(row.is_stolen) == 1,
            isImpounded = tonumber(row.is_impounded) == 1,
            hasBolo = tonumber(row.has_bolo) == 1,
        }
    end

    return MdtOk({
        rows = list,
        total = tonumber(total) or 0,
        page = page,
        pageSize = pageSize,
    })
end)

--- Scheda completa di un veicolo. Funziona anche per targhe non registrate:
--- in quel caso ritorna solo i flag, cosi' un controllo su strada da comunque
--- l'informazione utile (rubato / ricercato).
--- @return table|nil
function GetVehicleRecord(plate)
    plate = NormalizePlate(plate)
    if not plate then
        return nil
    end

    local owned = Database.TableExists('owned_vehicles') and Database.Single([[
        SELECT ov.plate, ov.vehicle, ov.type, ov.stored, ov.owner, ov.job, ov.mileage,
               CONCAT_WS(' ', u.firstname, u.lastname) AS owner_name, u.ssn AS owner_ssn,
               u.phone_number AS owner_phone
        FROM owned_vehicles ov
        LEFT JOIN users u ON u.identifier = ov.owner
        WHERE ov.plate = ?
    ]], { plate }) or nil

    local flags = Database.Single('SELECT * FROM kf_police_vehicle_flags WHERE plate = ?', { plate })

    if not owned and not flags then
        return nil
    end

    local reports = Database.Query([[
        SELECT r.id, r.title, r.officer, r.created_at, r.status
        FROM kf_police_report_vehicles rv
        INNER JOIN kf_police_reports r ON r.id = rv.report_id
        WHERE rv.plate = ?
        ORDER BY r.created_at DESC
        LIMIT 25
    ]], { plate }) or {}

    local reportList = {}
    for _, row in ipairs(reports) do
        reportList[#reportList + 1] = {
            id = tonumber(row.id),
            title = row.title,
            officer = row.officer,
            date = tostring(row.created_at),
            status = row.status,
        }
    end

    return {
        plate = plate,
        registered = owned ~= nil,
        model = owned and DecodeVehicleModel(owned.vehicle) or 'Sconosciuto',
        type = owned and owned.type or 'car',
        stored = owned and tonumber(owned.stored) == 1 or false,
        mileage = owned and tonumber(owned.mileage) or nil,
        job = owned and owned.job or nil,
        owner = owned and owned.owner or nil,
        ownerName = owned and Trim(owned.owner_name) ~= '' and Trim(owned.owner_name) or nil,
        ownerSsn = owned and owned.owner_ssn or nil,
        ownerPhone = owned and owned.owner_phone or nil,
        flags = {
            isStolen = flags and tonumber(flags.is_stolen) == 1 or false,
            isImpounded = flags and tonumber(flags.is_impounded) == 1 or false,
            impoundReason = flags and flags.impound_reason or nil,
            impoundBy = flags and flags.impound_by or nil,
            impoundAt = flags and flags.impound_at and tostring(flags.impound_at) or nil,
            hasBolo = flags and tonumber(flags.has_bolo) == 1 or false,
            boloReason = flags and flags.bolo_reason or nil,
            notes = flags and flags.notes or nil,
        },
        reports = reportList,
    }
end

RegisterMdtEndpoint('vehicles:get', 'mdt.vehicle.view', function(_, payload)
    local record = GetVehicleRecord(payload.plate)
    if not record then
        return MdtError('vehicle_not_found')
    end

    return MdtOk({ vehicle = record })
end)

--- Imposta i flag con persistenza. `nil` = non toccare quel flag.
--- @return boolean
function SetVehicleFlags(officer, plate, changes)
    plate = NormalizePlate(plate)
    if not plate or #plate > Config.Limits.plate then
        return false
    end

    Database.Insert('INSERT IGNORE INTO kf_police_vehicle_flags (plate) VALUES (?)', { plate })

    local sets, params = {}, {}
    local info = officer and OfficerInfo(officer) or nil
    local reason = SanitizeText(changes.reason, Config.Limits.reason)

    if changes.stolen ~= nil then
        sets[#sets + 1] = 'is_stolen = ?'
        params[#params + 1] = ToBool(changes.stolen) and 1 or 0
    end

    if changes.impounded ~= nil then
        local impounded = ToBool(changes.impounded)
        sets[#sets + 1] = 'is_impounded = ?'
        params[#params + 1] = impounded and 1 or 0

        sets[#sets + 1] = 'impound_reason = ?'
        params[#params + 1] = impounded and (reason ~= '' and reason or nil) or nil

        sets[#sets + 1] = 'impound_by = ?'
        params[#params + 1] = impounded and info and info.name or nil

        sets[#sets + 1] = impounded and 'impound_at = NOW()' or 'impound_at = NULL'
    end

    if changes.bolo ~= nil then
        local bolo = ToBool(changes.bolo)
        sets[#sets + 1] = 'has_bolo = ?'
        params[#params + 1] = bolo and 1 or 0

        sets[#sets + 1] = 'bolo_reason = ?'
        params[#params + 1] = bolo and (reason ~= '' and reason or nil) or nil
    end

    if changes.notes ~= nil then
        sets[#sets + 1] = 'notes = ?'
        params[#params + 1] = SanitizeText(changes.notes, 1000)
    end

    if #sets == 0 then
        return false
    end

    params[#params + 1] = plate

    local updated = Database.Update(
        ('UPDATE kf_police_vehicle_flags SET %s WHERE plate = ?'):format(table.concat(sets, ', ')),
        params)

    if updated == nil then
        return false
    end

    if officer then
        Logger.Audit(officer, 'vehicle.flag', plate, changes)
    end

    Invalidate('vehicles', plate)

    return true
end

RegisterMdtEndpoint('vehicles:setFlag', 'mdt.vehicle.flag', function(officer, payload)
    if not SetVehicleFlags(officer, payload.plate, payload) then
        return MdtError('vehicle_not_found')
    end

    return MdtOk({
        vehicle = GetVehicleRecord(payload.plate),
        message = Locale('vehicle_updated'),
    })
end)

--- Elenco dei sequestri, per il deposito.
RegisterMdtEndpoint('vehicles:impounded', 'mdt.vehicle.view', function()
    local rows = Database.Query([[
        SELECT f.plate, f.impound_reason, f.impound_by, f.impound_at,
               ov.vehicle, CONCAT_WS(' ', u.firstname, u.lastname) AS owner_name
        FROM kf_police_vehicle_flags f
        LEFT JOIN owned_vehicles ov ON ov.plate = f.plate
        LEFT JOIN users u ON u.identifier = ov.owner
        WHERE f.is_impounded = 1
        ORDER BY f.impound_at DESC
    ]]) or {}

    local list = {}
    for _, row in ipairs(rows) do
        list[#list + 1] = {
            plate = row.plate,
            model = row.vehicle and DecodeVehicleModel(row.vehicle) or 'Sconosciuto',
            ownerName = Trim(row.owner_name) ~= '' and Trim(row.owner_name) or 'Sconosciuto',
            reason = row.impound_reason,
            officer = row.impound_by,
            date = row.impound_at and tostring(row.impound_at) or nil,
        }
    end

    return MdtOk({ rows = list, total = #list })
end)
