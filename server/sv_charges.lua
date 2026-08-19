--[[
    KF_Police - Reati
    ----------------------------------------------------------------------------
    CORREZIONE BUG L2
    ----------------------------------------------------------------------------
    Prima ogni reato veniva aggiunto riscrivendo l'intero blob JSON
    `criminalRecords` del cittadino: due agenti che lavoravano sullo stesso
    fascicolo nello stesso momento si annullavano a vicenda. Qui ogni reato e'
    una riga con id da AUTO_INCREMENT, inserita in una transazione: due
    aggiunte contemporanee restano entrambe.

    CORREZIONE BUG L10
    ----------------------------------------------------------------------------
    La multa non viene piu' riestratta con una regex da una stringa formattata:
    si leggono i campi `fine` e `jail_months` dell'articolo.
]]

--- Articoli richiesti, letti in un colpo solo.
--- @param ids number[]
--- @return table<number, table>
local function fetchArticles(ids)
    if #ids == 0 then
        return {}
    end

    local placeholders = {}
    for i = 1, #ids do
        placeholders[i] = '?'
    end

    local rows = Database.Query(([[
        SELECT id, code, title, fine, jail_months, is_felony
        FROM kf_police_penalcode
        WHERE id IN (%s)
    ]]):format(table.concat(placeholders, ',')), ids) or {}

    local map = {}
    for _, row in ipairs(rows) do
        map[tonumber(row.id)] = row
    end

    return map
end

RegisterMdtEndpoint('charges:add', 'mdt.charge.add', function(officer, payload)
    local identifier = SanitizeText(payload.identifier, 64)
    if identifier == '' then
        return MdtError('invalid_data')
    end

    local exists = Database.Scalar('SELECT COUNT(*) FROM users WHERE identifier = ?', { identifier })
    if (tonumber(exists) or 0) == 0 then
        return MdtError('citizen_not_found')
    end

    -- Id degli articoli, deduplicati mantenendo le ripetizioni volute.
    local ids = {}
    for _, value in ipairs(payload.penalcodeIds or {}) do
        local id = tonumber(value)
        if id and id > 0 then
            ids[#ids + 1] = id
        end
    end

    -- Reato libero (senza articolo): ammesso solo con testo esplicito.
    local freeCrime = SanitizeText(payload.crime, 255)

    if #ids == 0 and freeCrime == '' then
        return MdtError('charge_add_failed')
    end

    local unique = {}
    for _, id in ipairs(ids) do
        unique[id] = true
    end

    local lookupIds = {}
    for id in pairs(unique) do
        lookupIds[#lookupIds + 1] = id
    end

    local articles = fetchArticles(lookupIds)

    local info = OfficerInfo(officer)
    local location = SanitizeText(payload.location, Config.Limits.location)
    local victim = SanitizeText(payload.victim, 64)
    local reportId = tonumber(payload.reportId)

    if victim ~= '' then
        local victimExists = Database.Scalar('SELECT COUNT(*) FROM users WHERE identifier = ?', { victim })
        if (tonumber(victimExists) or 0) == 0 then
            victim = ''
        end
    end

    local statements = {}
    local added = 0
    local totalFine, totalMonths = 0, 0

    local function queueCharge(penalId, crime, fine, months)
        statements[#statements + 1] = {
            [[
                INSERT INTO kf_police_charges
                    (identifier, penalcode_id, crime, fine, jail_months, officer_id,
                     officer_name, location, victim_identifier, report_id)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ]],
            {
                identifier,
                penalId,
                crime,
                fine,
                months,
                info.identifier,
                info.name,
                location ~= '' and location or nil,
                victim ~= '' and victim or nil,
                reportId,
            },
        }

        added = added + 1
        totalFine = totalFine + fine
        totalMonths = totalMonths + months
    end

    for _, id in ipairs(ids) do
        local article = articles[id]
        if article then
            queueCharge(
                id,
                article.title,
                ClampInt(article.fine, 0, nil, 0),
                ClampInt(article.jail_months, 0, nil, 0)
            )
        end
    end

    if freeCrime ~= '' then
        queueCharge(
            nil,
            freeCrime,
            ClampInt(payload.fine, 0, 1000000, 0),
            ClampInt(payload.jailMonths, 0, 10000, 0)
        )
    end

    if added == 0 then
        return MdtError('charge_add_failed')
    end

    if not Database.Transaction(statements) then
        return MdtError('charge_add_failed')
    end

    Logger.Audit(officer, 'charge.add', identifier, {
        penalcodeIds = ids,
        crime = freeCrime ~= '' and freeCrime or nil,
        count = added,
        fine = totalFine,
        jailMonths = totalMonths,
        reportId = reportId,
    })

    Invalidate('citizen', identifier)
    PushCounters()

    local charges, totals = GetCitizenCharges(identifier)

    return MdtOk({
        added = added,
        charges = charges,
        totals = totals,
        message = added == 1 and Locale('charge_added') or Locale('charges_added', added),
    })
end)

--- Annullamento tracciato: la riga resta, con chi e perche' l'ha annullata.
RegisterMdtEndpoint('charges:void', 'mdt.charge.void', function(officer, payload)
    local chargeId = tonumber(payload.chargeId)
    local reason = SanitizeText(payload.reason, Config.Limits.reason)

    if not chargeId then
        return MdtError('invalid_data')
    end

    local charge = Database.Single(
        'SELECT id, identifier, crime, voided_at FROM kf_police_charges WHERE id = ?', { chargeId })

    if not charge then
        return MdtError('charge_not_found')
    end

    if charge.voided_at then
        return MdtError('charge_already_voided')
    end

    local info = OfficerInfo(officer)

    local updated = Database.Update([[
        UPDATE kf_police_charges
        SET voided_at = NOW(), voided_by = ?, void_reason = ?
        WHERE id = ? AND voided_at IS NULL
    ]], { info.name, reason ~= '' and reason or nil, chargeId })

    if not updated or updated == 0 then
        return MdtError('charge_already_voided')
    end

    Logger.Audit(officer, 'charge.void', charge.identifier, {
        chargeId = chargeId,
        crime = charge.crime,
        reason = reason,
    })

    Invalidate('citizen', charge.identifier)

    local charges, totals = GetCitizenCharges(charge.identifier)

    return MdtOk({ charges = charges, totals = totals, message = Locale('charge_voided') })
end)

--- Segna una multa come pagata (usato dal pannello sanzioni).
RegisterMdtEndpoint('charges:markPaid', 'mdt.fine.issue', function(officer, payload)
    local chargeId = tonumber(payload.chargeId)
    if not chargeId then
        return MdtError('invalid_data')
    end

    local charge = Database.Single(
        'SELECT id, identifier, fine, is_paid FROM kf_police_charges WHERE id = ? AND voided_at IS NULL',
        { chargeId })

    if not charge then
        return MdtError('charge_not_found')
    end

    Database.Update('UPDATE kf_police_charges SET is_paid = 1 WHERE id = ?', { chargeId })
    Logger.Audit(officer, 'charge.paid', charge.identifier, { chargeId = chargeId, fine = charge.fine })
    Invalidate('citizen', charge.identifier)

    local charges, totals = GetCitizenCharges(charge.identifier)

    return MdtOk({ charges = charges, totals = totals })
end)
