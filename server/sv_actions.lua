--[[
    KF_Police - Azioni di campo (server)
    ----------------------------------------------------------------------------
    Ogni azione rivalida il bersaglio lato server: che esista, che sia un
    giocatore, e che sia davvero entro la distanza consentita. La distanza viene
    misurata con `GetEntityCoords` sul server, non dichiarata dal client.
]]

--- identifier -> true, per i cittadini ammanettati.
local restrained = {}

--- identifier dell'agente -> identifier del cittadino scortato.
local dragging = {}

function IsRestrained(identifier)
    return identifier ~= nil and restrained[identifier] == true
end

--- Verifica che `targetSrc` sia un giocatore valido vicino a `src`.
--- @return table|nil xTarget, string|nil errore
function ValidateTarget(src, targetSrc, maxDistance)
    targetSrc = tonumber(targetSrc)
    if not targetSrc or targetSrc == src then
        return nil, 'invalid_data'
    end

    local xTarget = Framework.GetPlayer(targetSrc)
    if not xTarget then
        return nil, 'no_nearby_player'
    end

    local officerPed = GetPlayerPed(src)
    local targetPed = GetPlayerPed(targetSrc)

    if not officerPed or officerPed == 0 or not targetPed or targetPed == 0 then
        return nil, 'no_nearby_player'
    end

    local distance = #(GetEntityCoords(officerPed) - GetEntityCoords(targetPed))
    if distance > (maxDistance or Config.Actions.MaxDistance) then
        return nil, 'too_far'
    end

    return xTarget, nil
end

-- ============================================================================
--  Manette
-- ============================================================================

lib.callback.register('KF_Police:actions:cuff', function(src, targetSrc)
    local officer = RequirePermission(src, 'field.cuff')
    if not officer then
        return { ok = false, message = Locale('no_permission') }
    end

    local xTarget, err = ValidateTarget(src, targetSrc)
    if not xTarget then
        return { ok = false, message = Locale(err) }
    end

    local wasRestrained = restrained[xTarget.identifier] == true

    if not wasRestrained then
        local item = Config.Actions.HandcuffItem
        if item and item ~= '' and Inventory.Count(src, item) < 1 then
            return { ok = false, message = Locale('cuff_no_item') }
        end

        restrained[xTarget.identifier] = true
    else
        restrained[xTarget.identifier] = nil

        -- Slegando si interrompe anche la scorta.
        for officerId, draggedId in pairs(dragging) do
            if draggedId == xTarget.identifier then
                dragging[officerId] = nil
            end
        end
    end

    TriggerClientEvent('KF_Police:Client:SetRestrained', xTarget.source, not wasRestrained,
        Config.Actions.HandcuffTimer)
    Framework.Notify(xTarget.source, Locale(wasRestrained and 'uncuffed' or 'cuffed'),
        wasRestrained and 'success' or 'error')

    Logger.Audit(officer, wasRestrained and 'field.uncuff' or 'field.cuff', xTarget.identifier)

    return {
        ok = true,
        restrained = not wasRestrained,
        message = Locale(wasRestrained and 'uncuff_target' or 'cuff_target'),
    }
end)

--- Scadenza automatica delle manette (timer configurabile).
RegisterNetEvent('KF_Police:Server:CuffExpired', function()
    local xPlayer = Framework.GetPlayer(source)
    if xPlayer then
        restrained[xPlayer.identifier] = nil
    end
end)

-- ============================================================================
--  Scorta
-- ============================================================================

lib.callback.register('KF_Police:actions:drag', function(src, targetSrc)
    local officer = RequirePermission(src, 'field.cuff')
    if not officer then
        return { ok = false, message = Locale('no_permission') }
    end

    local xTarget, err = ValidateTarget(src, targetSrc)
    if not xTarget then
        return { ok = false, message = Locale(err) }
    end

    if dragging[officer.identifier] == xTarget.identifier then
        dragging[officer.identifier] = nil
        TriggerClientEvent('KF_Police:Client:SetDragged', xTarget.source, false, src)
        return { ok = true, dragging = false, message = Locale('drag_stop') }
    end

    if not restrained[xTarget.identifier] then
        return { ok = false, message = Locale('drag_need_cuffs') }
    end

    dragging[officer.identifier] = xTarget.identifier
    TriggerClientEvent('KF_Police:Client:SetDragged', xTarget.source, true, src)
    Logger.Audit(officer, 'field.drag', xTarget.identifier)

    return { ok = true, dragging = true, message = Locale('drag_start') }
end)

-- ============================================================================
--  Metti / togli dal veicolo
-- ============================================================================

lib.callback.register('KF_Police:actions:vehicle', function(src, targetSrc, action, netId, seat)
    local officer = RequirePermission(src, 'field.cuff')
    if not officer then
        return { ok = false, message = Locale('no_permission') }
    end

    local xTarget, err = ValidateTarget(src, targetSrc, Config.Actions.MaxVehicleDistance)
    if not xTarget then
        return { ok = false, message = Locale(err) }
    end

    if action == 'in' then
        if not netId then
            return { ok = false, message = Locale('no_nearby_vehicle') }
        end

        TriggerClientEvent('KF_Police:Client:PutInVehicle', xTarget.source, netId, tonumber(seat) or -2)
        Logger.Audit(officer, 'field.vehicle.in', xTarget.identifier)

        return { ok = true, message = Locale('put_in_vehicle') }
    end

    TriggerClientEvent('KF_Police:Client:OutOfVehicle', xTarget.source)
    Logger.Audit(officer, 'field.vehicle.out', xTarget.identifier)

    return { ok = true, message = Locale('out_of_vehicle') }
end)

-- ============================================================================
--  Perquisizione
-- ============================================================================

lib.callback.register('KF_Police:actions:search', function(src, targetSrc)
    local officer = RequirePermission(src, 'field.search')
    if not officer then
        return { ok = false, message = Locale('no_permission') }
    end

    local xTarget, err = ValidateTarget(src, targetSrc)
    if not xTarget then
        return { ok = false, message = Locale(err) }
    end

    if Config.Actions.SearchRequiresRestraint and not restrained[xTarget.identifier] then
        local isDead = xTarget.get and xTarget.get('isDead')
        if not isDead then
            return { ok = false, message = Locale('search_need_restraint') }
        end
    end

    local items = Inventory.GetInventory(xTarget.source)

    Framework.Notify(xTarget.source, Locale('searched'), 'inform')
    Logger.Audit(officer, 'field.search', xTarget.identifier, { itemCount = #items })

    return {
        ok = true,
        message = Locale('search_done'),
        items = items,
        citizen = {
            identifier = xTarget.identifier,
            name = Framework.GetName(xTarget),
        },
    }
end)

--- Sequestro di un oggetto durante la perquisizione.
--- Sostituisce `esx_policejob:confiscatePlayerItem`, con la stessa verifica del
--- lavoro piu' quella di distanza e permesso che l'originale non faceva.
lib.callback.register('KF_Police:actions:seize', function(src, targetSrc, itemName, count, isWeapon)
    local officer = RequirePermission(src, 'field.search')
    if not officer then
        return { ok = false, message = Locale('no_permission') }
    end

    local xTarget, err = ValidateTarget(src, targetSrc)
    if not xTarget then
        return { ok = false, message = Locale(err) }
    end

    if type(itemName) ~= 'string' or itemName == '' then
        return { ok = false, message = Locale('invalid_data') }
    end

    count = ClampInt(count, 1, 500, 1)

    local removed
    if isWeapon then
        removed = Inventory.RemoveWeapon(xTarget.source, itemName)
    else
        if Inventory.Count(xTarget.source, itemName) < count then
            return { ok = false, message = Locale('armory_no_item') }
        end
        removed = Inventory.RemoveItem(xTarget.source, itemName, count)
    end

    if not removed then
        return { ok = false, message = Locale('armory_no_item') }
    end

    -- L'oggetto passa all'agente; se non ci sta, torna al proprietario.
    local delivered
    if isWeapon then
        delivered = Inventory.AddWeapon(src, itemName, 0)
    else
        delivered = Inventory.AddItem(src, itemName, count)
    end

    if not delivered then
        if isWeapon then
            Inventory.AddWeapon(xTarget.source, itemName, 0)
        else
            Inventory.AddItem(xTarget.source, itemName, count)
        end
        return { ok = false, message = Locale('armory_full') }
    end

    Logger.Audit(officer, 'field.seize', xTarget.identifier, { item = itemName, count = count })

    return { ok = true, message = ('%s sequestrato'):format(itemName) }
end)

-- ============================================================================
--  Carta d'identita': apre la scheda MDT invece di un menu di testo
-- ============================================================================

lib.callback.register('KF_Police:actions:identify', function(src, targetSrc)
    local officer = RequirePermission(src, 'field.identify')
    if not officer then
        return { ok = false, message = Locale('no_permission') }
    end

    local xTarget, err = ValidateTarget(src, targetSrc)
    if not xTarget then
        return { ok = false, message = Locale(err) }
    end

    Framework.Notify(xTarget.source, Locale('identity_shown'), 'inform')
    Logger.Audit(officer, 'field.identify', xTarget.identifier)

    return {
        ok = true,
        identifier = xTarget.identifier,
        name = Framework.GetName(xTarget),
    }
end)

-- ============================================================================
--  Licenze
-- ============================================================================

lib.callback.register('KF_Police:actions:licenses', function(src, targetSrc)
    local officer = RequirePermission(src, 'field.license')
    if not officer then
        return { ok = false, message = Locale('no_permission') }
    end

    local xTarget, err = ValidateTarget(src, targetSrc)
    if not xTarget then
        return { ok = false, message = Locale(err) }
    end

    if not Database.TableExists('user_licenses') then
        return { ok = false, message = Locale('license_none') }
    end

    local rows = Database.Query([[
        SELECT ul.id, ul.type, COALESCE(l.label, ul.type) AS label
        FROM user_licenses ul
        LEFT JOIN licenses l ON l.type = ul.type
        WHERE ul.owner = ?
    ]], { xTarget.identifier }) or {}

    local list = {}
    for _, row in ipairs(rows) do
        list[#list + 1] = { id = tonumber(row.id), type = row.type, label = row.label }
    end

    return {
        ok = true,
        identifier = xTarget.identifier,
        name = Framework.GetName(xTarget),
        licenses = list,
    }
end)

lib.callback.register('KF_Police:actions:revokeLicense', function(src, targetSrc, licenseType)
    local officer = RequirePermission(src, 'field.license')
    if not officer then
        return { ok = false, message = Locale('no_permission') }
    end

    local xTarget, err = ValidateTarget(src, targetSrc)
    if not xTarget then
        return { ok = false, message = Locale(err) }
    end

    if type(licenseType) ~= 'string' or licenseType == '' then
        return { ok = false, message = Locale('invalid_data') }
    end

    local removed = Database.Update('DELETE FROM user_licenses WHERE owner = ? AND type = ?',
        { xTarget.identifier, licenseType })

    if not removed or removed == 0 then
        return { ok = false, message = Locale('license_none') }
    end

    Logger.Audit(officer, 'field.license.revoke', xTarget.identifier, { license = licenseType })
    Framework.Notify(xTarget.source, Locale('license_revoked', licenseType), 'error')

    return { ok = true, message = Locale('license_revoked', licenseType) }
end)

-- ============================================================================
--  Lockpick e sequestro
-- ============================================================================

lib.callback.register('KF_Police:actions:lockpick', function(src)
    local officer = RequirePermission(src, 'field.lockpick')
    if not officer then
        return { ok = false, message = Locale('no_permission') }
    end

    local item = Config.Actions.LockpickItem
    if item and item ~= '' and Inventory.Count(src, item) < 1 then
        return { ok = false, message = Locale('lockpick_no_item') }
    end

    Logger.Audit(officer, 'field.lockpick')

    return { ok = true }
end)

lib.callback.register('KF_Police:actions:impound', function(src, plate, reason)
    local officer = RequirePermission(src, 'field.impound')
    if not officer then
        return { ok = false, message = Locale('no_permission') }
    end

    local normalized = NormalizePlate(plate)
    if not normalized then
        return { ok = false, message = Locale('invalid_data') }
    end

    -- Persistente su kf_police_vehicle_flags: sopravvive al restart (bug L3).
    if not SetVehicleFlags(officer, normalized, {
        impounded = true,
        reason = reason,
    }) then
        return { ok = false, message = Locale('vehicle_not_found') }
    end

    Logger.Audit(officer, 'field.impound', normalized, { reason = reason })

    return { ok = true, message = Locale('vehicle_impounded') }
end)

lib.callback.register('KF_Police:actions:markStolen', function(src, plate, stolen, reason)
    local officer = RequirePermission(src, 'mdt.vehicle.flag')
    if not officer then
        return { ok = false, message = Locale('no_permission') }
    end

    local normalized = NormalizePlate(plate)
    if not normalized then
        return { ok = false, message = Locale('invalid_data') }
    end

    if not SetVehicleFlags(officer, normalized, { stolen = ToBool(stolen), reason = reason }) then
        return { ok = false, message = Locale('vehicle_not_found') }
    end

    return { ok = true, message = Locale('vehicle_marked_stolen') }
end)

--- Controllo targa da bordo strada: ritorna la scheda del veicolo.
lib.callback.register('KF_Police:actions:plateCheck', function(src, plate)
    local officer = RequirePermission(src, 'mdt.vehicle.view')
    if not officer then
        return nil
    end

    local record = GetVehicleRecord(plate)
    if not record then
        return { ok = false, message = Locale('plate_unknown') }
    end

    Logger.Audit(officer, 'field.plate_check', record.plate)

    return { ok = true, vehicle = record }
end)

-- ============================================================================
--  Manda in cella dal campo
-- ============================================================================

lib.callback.register('KF_Police:actions:jail', function(src, targetSrc, months, reason)
    local officer = RequirePermission(src, 'jail.send')
    if not officer then
        return { ok = false, message = Locale('no_permission') }
    end

    local xTarget, err = ValidateTarget(src, targetSrc, Config.Actions.MaxVehicleDistance)
    if not xTarget then
        return { ok = false, message = Locale(err) }
    end

    local seconds = ClampInt(months, 1, 10000, 1) * (Config.Jail.SecondsPerMonth or 30)
    local ok, message = JailPlayer(officer, xTarget.identifier, seconds, reason)

    return { ok = ok, message = message }
end)

--- Mesi di detenzione accumulati dai reati non annullati, per proporre la pena.
lib.callback.register('KF_Police:actions:pendingSentence', function(src, targetSrc)
    local officer = RequirePermission(src, 'jail.send')
    if not officer then
        return nil
    end

    local xTarget = ValidateTarget(src, targetSrc, Config.Actions.MaxVehicleDistance)
    if not xTarget then
        return nil
    end

    local _, totals = GetCitizenCharges(xTarget.identifier)

    return {
        identifier = xTarget.identifier,
        name = Framework.GetName(xTarget),
        months = totals.totalMonths,
        fine = totals.unpaidFine,
    }
end)

-- ============================================================================
--  Pulizia
-- ============================================================================

AddEventHandler('playerDropped', function()
    local xPlayer = Framework.GetPlayer(source)
    if not xPlayer then
        return
    end

    restrained[xPlayer.identifier] = nil
    dragging[xPlayer.identifier] = nil

    for officerId, draggedId in pairs(dragging) do
        if draggedId == xPlayer.identifier then
            dragging[officerId] = nil
        end
    end
end)
