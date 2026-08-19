--[[
    KF_Police - Note sul fascicolo
    ----------------------------------------------------------------------------
    CORREZIONE BUG L6
    ----------------------------------------------------------------------------
    Gli id delle note erano calcolati come `#citizen.notes + 1`: dopo una
    cancellazione due note finivano con lo stesso id. Ora l'id arriva da
    AUTO_INCREMENT e non si ripete mai.
]]

RegisterMdtEndpoint('notes:add', 'mdt.note.create', function(officer, payload)
    local identifier = SanitizeText(payload.identifier, 64)
    local note = SanitizeText(payload.note, Config.Limits.note)

    if identifier == '' or note == '' then
        return MdtError('invalid_data')
    end

    local exists = Database.Scalar('SELECT COUNT(*) FROM users WHERE identifier = ?', { identifier })
    if (tonumber(exists) or 0) == 0 then
        return MdtError('citizen_not_found')
    end

    local info = OfficerInfo(officer)

    local id = Database.Insert([[
        INSERT INTO kf_police_notes (identifier, note, officer_id, officer_name)
        VALUES (?, ?, ?, ?)
    ]], { identifier, note, info.identifier, info.name })

    if not id then
        return MdtError('invalid_data')
    end

    Logger.Audit(officer, 'note.add', identifier, { noteId = id })
    Invalidate('citizen', identifier)

    return MdtOk({ id = id, notes = GetCitizenNotes(identifier), message = Locale('note_saved') })
end)

RegisterMdtEndpoint('notes:update', 'mdt.note.create', function(officer, payload)
    local id = tonumber(payload.id)
    local note = SanitizeText(payload.note, Config.Limits.note)

    if not id or note == '' then
        return MdtError('invalid_data')
    end

    local existing = Database.Single(
        'SELECT id, identifier, officer_id FROM kf_police_notes WHERE id = ?', { id })

    if not existing then
        return MdtError('note_not_found')
    end

    local info = OfficerInfo(officer)

    -- Una nota si modifica se e' propria, oppure con il permesso di eliminarle.
    local isOwner = existing.officer_id == info.identifier
    if not isOwner and not HasPermission(info.job, info.grade, 'mdt.note.delete') then
        return MdtError('no_permission')
    end

    Database.Update('UPDATE kf_police_notes SET note = ? WHERE id = ?', { note, id })
    Logger.Audit(officer, 'note.update', existing.identifier, { noteId = id })
    Invalidate('citizen', existing.identifier)

    return MdtOk({ notes = GetCitizenNotes(existing.identifier), message = Locale('note_saved') })
end)

RegisterMdtEndpoint('notes:delete', 'mdt.note.delete', function(officer, payload)
    local id = tonumber(payload.id)
    if not id then
        return MdtError('invalid_data')
    end

    local existing = Database.Single(
        'SELECT id, identifier, note FROM kf_police_notes WHERE id = ?', { id })

    if not existing then
        return MdtError('note_not_found')
    end

    Database.Update('DELETE FROM kf_police_notes WHERE id = ?', { id })
    Logger.Audit(officer, 'note.delete', existing.identifier, { noteId = id, note = existing.note })
    Invalidate('citizen', existing.identifier)

    return MdtOk({ notes = GetCitizenNotes(existing.identifier), message = Locale('note_deleted') })
end)
