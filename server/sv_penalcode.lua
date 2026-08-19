--[[
    KF_Police - Codice penale
    ----------------------------------------------------------------------------
    Gli articoli sono raggruppati per categoria e contengono i campi numerici
    (`fine`, `jail_months`): niente piu' stringhe `sanction` da cui riestrarre
    la multa con una regex (bug L10).
    Le ex `fine_types` di esx_policejob sono articoli come tutti gli altri, con
    la loro categoria: una sola fonte per multe e reati.
]]

RegisterMdtEndpoint('penalcode:list', 'mdt.view', function()
    local categories = Database.Query([[
        SELECT id, label, icon, sort_order
        FROM kf_police_penalcode_categories
        ORDER BY sort_order, label
    ]]) or {}

    local articles = Database.Query([[
        SELECT id, code, category_id, title, description, fine, jail_months, is_felony
        FROM kf_police_penalcode
        ORDER BY category_id, code, title
    ]]) or {}

    local byCategory = {}
    local flat = {}

    for _, row in ipairs(articles) do
        local article = {
            id = tonumber(row.id),
            code = row.code,
            categoryId = tonumber(row.category_id),
            title = row.title,
            description = row.description or '',
            fine = tonumber(row.fine) or 0,
            jailMonths = tonumber(row.jail_months) or 0,
            isFelony = tonumber(row.is_felony) == 1,
        }

        flat[#flat + 1] = article

        local key = tostring(article.categoryId or 0)
        byCategory[key] = byCategory[key] or {}
        table.insert(byCategory[key], article)
    end

    local categoryList = {}
    for _, row in ipairs(categories) do
        local key = tostring(row.id)
        categoryList[#categoryList + 1] = {
            id = tonumber(row.id),
            label = row.label,
            icon = row.icon or 'penalcode',
            sortOrder = tonumber(row.sort_order) or 0,
            articles = byCategory[key] or {},
        }
    end

    -- Articoli senza categoria: raccolti in fondo, cosi' non scompaiono.
    if byCategory['0'] and #byCategory['0'] > 0 then
        categoryList[#categoryList + 1] = {
            id = 0,
            label = 'Senza categoria',
            icon = 'penalcode',
            sortOrder = 9999,
            articles = byCategory['0'],
        }
    end

    return MdtOk({ categories = categoryList, articles = flat })
end)

RegisterMdtEndpoint('penalcode:save', 'mdt.penalcode.edit', function(officer, payload)
    local title = SanitizeText(payload.title, Config.Limits.penalTitle)
    if title == '' then
        return MdtError('invalid_data')
    end

    local code = SanitizeText(payload.code, 16)
    local description = SanitizeText(payload.description, Config.Limits.penalDescription)
    local fine = ClampInt(payload.fine, 0, 10000000, 0)
    local months = ClampInt(payload.jailMonths, 0, 10000, 0)
    local felony = ToBool(payload.isFelony) and 1 or 0
    local categoryId = tonumber(payload.categoryId)

    if categoryId then
        local exists = Database.Scalar(
            'SELECT COUNT(*) FROM kf_police_penalcode_categories WHERE id = ?', { categoryId })
        if (tonumber(exists) or 0) == 0 then
            categoryId = nil
        end
    end

    local id = tonumber(payload.id)

    if id then
        local updated = Database.Update([[
            UPDATE kf_police_penalcode
            SET code = ?, category_id = ?, title = ?, description = ?,
                fine = ?, jail_months = ?, is_felony = ?
            WHERE id = ?
        ]], { code ~= '' and code or nil, categoryId, title, description, fine, months, felony, id })

        if updated == nil then
            return MdtError('invalid_data')
        end
    else
        id = Database.Insert([[
            INSERT INTO kf_police_penalcode
                (code, category_id, title, description, fine, jail_months, is_felony)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        ]], { code ~= '' and code or nil, categoryId, title, description, fine, months, felony })

        if not id then
            return MdtError('invalid_data')
        end
    end

    Logger.Audit(officer, 'penalcode.save', tostring(id), { title = title, fine = fine, jailMonths = months })
    Invalidate('penalcode')

    return MdtOk({ id = id, message = Locale('article_saved') })
end)

RegisterMdtEndpoint('penalcode:delete', 'mdt.penalcode.edit', function(officer, payload)
    local id = tonumber(payload.id)
    if not id then
        return MdtError('invalid_data')
    end

    local article = Database.Single('SELECT id, title FROM kf_police_penalcode WHERE id = ?', { id })
    if not article then
        return MdtError('article_not_found')
    end

    -- I reati gia' contestati conservano il testo, ma perdono il riferimento:
    -- lo storico non deve cambiare quando il codice penale viene riscritto.
    local ok = Database.Transaction({
        { 'UPDATE kf_police_charges SET penalcode_id = NULL WHERE penalcode_id = ?', { id } },
        { 'DELETE FROM kf_police_penalcode WHERE id = ?', { id } },
    })

    if not ok then
        return MdtError('invalid_data')
    end

    Logger.Audit(officer, 'penalcode.delete', tostring(id), { title = article.title })
    Invalidate('penalcode')

    return MdtOk({ message = Locale('article_deleted') })
end)

RegisterMdtEndpoint('penalcode:saveCategory', 'mdt.penalcode.edit', function(officer, payload)
    local label = SanitizeText(payload.label, 100)
    if label == '' then
        return MdtError('invalid_data')
    end

    local icon = SanitizeText(payload.icon, 48)
    if icon == '' then
        icon = 'penalcode'
    end

    local sortOrder = ClampInt(payload.sortOrder, 0, 9999, 0)
    local id = tonumber(payload.id)

    if id then
        Database.Update(
            'UPDATE kf_police_penalcode_categories SET label = ?, icon = ?, sort_order = ? WHERE id = ?',
            { label, icon, sortOrder, id })
    else
        id = Database.Insert(
            'INSERT INTO kf_police_penalcode_categories (label, icon, sort_order) VALUES (?, ?, ?)',
            { label, icon, sortOrder })
    end

    Logger.Audit(officer, 'penalcode.category.save', tostring(id), { label = label })
    Invalidate('penalcode')

    return MdtOk({ id = id })
end)
