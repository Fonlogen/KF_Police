--[[
    KF_Police - Ricercati
    ----------------------------------------------------------------------------
    CORREZIONE BUG L7
    ----------------------------------------------------------------------------
    `RefreshWantedList` rigenerava gli id per indice di iterazione, quindi l'id
    di una voce cambiava tra due refresh e la UI apriva il fascicolo sbagliato.
    Qui l'elenco e' una query su `kf_police_profiles`: l'identificativo di una
    voce e' l'`identifier` del cittadino, che non cambia mai.
]]

RegisterMdtEndpoint('wanted:list', 'mdt.citizen.view', function(_, payload)
    local page = ClampInt(payload.page, 1, 10000, 1)
    local pageSize = ClampInt(payload.pageSize, 1, Config.MaxPageSize, Config.PageSize)
    local offset = (page - 1) * pageSize

    local query = SanitizeText(payload.query, Config.Limits.query)
    local where = { 'p.is_wanted = 1' }
    local params = {}

    if query ~= '' then
        where[#where + 1] = [[(
            u.firstname LIKE ? OR u.lastname LIKE ? OR u.ssn LIKE ? OR p.wanted_reason LIKE ?
        )]]
        local like = '%' .. query .. '%'
        params[#params + 1] = like
        params[#params + 1] = like
        params[#params + 1] = like
        params[#params + 1] = like
    end

    local whereClause = table.concat(where, ' AND ')

    local total = Database.Scalar(([[
        SELECT COUNT(*)
        FROM kf_police_profiles p
        INNER JOIN users u ON u.identifier = p.identifier
        WHERE %s
    ]]):format(whereClause), params)

    local rows = Database.Query(([[
        SELECT
            p.identifier, p.wanted_reason, p.wanted_by_name, p.wanted_at, p.mugshot,
            u.firstname, u.lastname, u.ssn, u.nationality, u.job, u.job_grade,
            (SELECT COUNT(*) FROM kf_police_charges c
                WHERE c.identifier = p.identifier AND c.voided_at IS NULL) AS charge_count
        FROM kf_police_profiles p
        INNER JOIN users u ON u.identifier = p.identifier
        WHERE %s
        ORDER BY p.wanted_at DESC, u.lastname ASC
        LIMIT %d OFFSET %d
    ]]):format(whereClause, pageSize, offset), params) or {}

    local list = {}
    for _, row in ipairs(rows) do
        list[#list + 1] = {
            identifier = row.identifier,
            firstName = row.firstname or 'Sconosciuto',
            lastName = row.lastname or '',
            ssn = row.ssn,
            nationality = row.nationality or 'Los Santos',
            job = GetJobLabel(row.job, row.job_grade),
            mugshot = row.mugshot,
            reason = row.wanted_reason or 'Ricercato',
            wantedBy = row.wanted_by_name,
            wantedAt = row.wanted_at and tostring(row.wanted_at) or nil,
            chargeCount = tonumber(row.charge_count) or 0,
        }
    end

    return MdtOk({
        rows = list,
        total = tonumber(total) or 0,
        page = page,
        pageSize = pageSize,
    })
end)

RegisterMdtEndpoint('wanted:set', 'mdt.wanted.set', function(officer, payload)
    local identifier = SanitizeText(payload.identifier, 64)
    if identifier == '' then
        return MdtError('invalid_data')
    end

    local user = Database.Single('SELECT identifier, ssn FROM users WHERE identifier = ?', { identifier })
    if not user then
        return MdtError('citizen_not_found')
    end

    EnsureProfile(identifier, user.ssn)

    local wanted = ToBool(payload.wanted)
    local reason = SanitizeText(payload.reason, Config.Limits.reason)
    local info = OfficerInfo(officer)

    if wanted then
        Database.Update([[
            UPDATE kf_police_profiles
            SET is_wanted = 1, wanted_reason = ?, wanted_by_id = ?, wanted_by_name = ?, wanted_at = NOW()
            WHERE identifier = ?
        ]], {
            reason ~= '' and reason or 'Ricercato',
            info.identifier,
            info.name,
            identifier,
        })
    else
        Database.Update([[
            UPDATE kf_police_profiles
            SET is_wanted = 0, wanted_reason = NULL, wanted_by_id = NULL,
                wanted_by_name = NULL, wanted_at = NULL
            WHERE identifier = ?
        ]], { identifier })
    end

    Logger.Audit(officer, wanted and 'wanted.set' or 'wanted.clear', identifier, { reason = reason })

    Invalidate('citizen', identifier)
    Invalidate('wanted')
    PushCounters()

    return MdtOk({ isWanted = wanted, message = Locale('wanted_updated') })
end)
