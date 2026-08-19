--[[
    KF_Police - Sanzioni e adapter di fatturazione
    ----------------------------------------------------------------------------
    Gli adapter sono descritti in config/cfg_banking.lua per nome di argomento e
    risolti qui a runtime: aggiungere un banking nuovo non richiede codice.
    Gli export vengono invocati passando `self` esplicitamente, che equivale al
    colon-call richiesto da FiveM (stessa causa del bug L1).
]]

local function isResourceStarted(name)
    return name ~= nil and GetResourceState(name) == 'started'
end

local function resolveArg(token, ctx)
    if token == 'targetSource' then return ctx.targetSource end
    if token == 'targetIdentifier' then return ctx.targetIdentifier end
    if token == 'officerSource' then return ctx.officerSource end
    if token == 'officerIdentifier' then return ctx.officerIdentifier end
    if token == 'amount' then return ctx.amount end
    if token == 'label' then return ctx.label end
    if token == 'society' then return ctx.society end
    if token == 'societyLabel' then return ctx.societyLabel end
    if token == 'reason' then return ctx.reason end
    if token == 'accountType' then return ctx.accountType end
    if token == 'withdraw' then return 'withdraw' end
    return token
end

local function buildArgs(spec, ctx)
    local args = {}
    for i = 1, #(spec or {}) do
        args[i] = resolveArg(spec[i], ctx)
    end
    return args, #(spec or {})
end

local function hasRequiredArgs(spec, ctx)
    for i = 1, #(spec or {}) do
        local token = spec[i]
        if type(token) == 'string' and token:match('^[a-zA-Z]') and resolveArg(token, ctx) == nil then
            return false
        end
    end
    return true
end

local function callExport(exportCfg, ctx)
    if not exportCfg or not exportCfg.resource or not exportCfg.name then
        return false
    end
    if not isResourceStarted(exportCfg.resource) then
        return false
    end
    if not hasRequiredArgs(exportCfg.args, ctx) then
        return false
    end

    local args, argc = buildArgs(exportCfg.args, ctx)
    local handle = exports[exportCfg.resource]
    if not handle then
        return false
    end

    local invoke
    if exportCfg.method == false then
        invoke = function()
            return handle[exportCfg.name](table.unpack(args, 1, argc))
        end
    else
        -- self esplicito: equivale a exports[resource]:name(...)
        invoke = function()
            return handle[exportCfg.name](handle, table.unpack(args, 1, argc))
        end
    end

    local ok, result = pcall(invoke)
    return ok and result ~= false
end

local function fireEvent(eventCfg, ctx)
    if not eventCfg or not eventCfg.name then
        return false
    end
    if eventCfg.requiresSource and not ctx.officerSource then
        return false
    end
    if not hasRequiredArgs(eventCfg.args, ctx) then
        return false
    end

    local args, argc = buildArgs(eventCfg.args, ctx)

    local ok = pcall(function()
        if eventCfg.type == 'client' then
            local dest = eventCfg.target == 'officer' and ctx.officerSource or ctx.targetSource
            if not dest then
                error('destinazione client mancante')
            end
            TriggerClientEvent(eventCfg.name, dest, table.unpack(args, 1, argc))
        else
            TriggerEvent(eventCfg.name, table.unpack(args, 1, argc))
        end
    end)

    return ok
end

--- Emette una sanzione tramite il primo adapter disponibile.
--- @param officer table|nil xPlayer che emette
--- @param targetIdentifier string
--- @param amount number
--- @param label string
--- @return boolean
function IssueFine(officer, targetIdentifier, amount, label)
    local banking = Config.Banking or {}
    amount = ClampInt(amount, 1, 10000000, 0)

    if not banking.Enabled or amount <= 0 or not targetIdentifier then
        return false
    end

    local target = Framework.GetPlayerFromIdentifier(targetIdentifier)

    local ctx = {
        targetIdentifier = targetIdentifier,
        targetSource = target and target.source or nil,
        officerIdentifier = officer and officer.identifier or nil,
        officerSource = officer and officer.source or nil,
        amount = amount,
        label = label or banking.FallbackLabel or 'Sanzione polizia',
        society = banking.Society or Config.Society,
        societyLabel = banking.SocietyLabel or 'LSPD',
        reason = banking.Reason or 'police_fine',
        accountType = banking.AccountType or 'bank',
    }

    for _, adapter in ipairs(banking.Adapters or {}) do
        if isResourceStarted(adapter.resource or adapter.name) then
            local recorded = false

            if adapter.export then
                recorded = callExport(adapter.export, ctx)
            end
            if not recorded and adapter.event then
                recorded = fireEvent(adapter.event, ctx)
            end

            if recorded then
                Logger.Debug('Sanzione emessa via %s', adapter.name)
                return true
            end
        end
    end

    Logger.Warn('Nessun adapter di fatturazione disponibile per la sanzione')
    return false
end

-- ============================================================================
--  Endpoint MDT
-- ============================================================================

RegisterMdtEndpoint('fines:issue', 'mdt.fine.issue', function(officer, payload)
    local identifier = SanitizeText(payload.identifier, 64)
    local amount = ClampInt(payload.amount, 1, 10000000, 0)
    local label = SanitizeText(payload.label, 120)

    if identifier == '' or amount <= 0 then
        return MdtError('fine_invalid_amount')
    end

    local exists = Database.Scalar('SELECT COUNT(*) FROM users WHERE identifier = ?', { identifier })
    if (tonumber(exists) or 0) == 0 then
        return MdtError('citizen_not_found')
    end

    if label == '' then
        label = Config.Banking.FallbackLabel or 'Sanzione polizia'
    end

    if not IssueFine(officer, identifier, amount, label) then
        return MdtError('fine_failed')
    end

    -- La sanzione resta anche nel fascicolo, come reato pecuniario.
    local info = OfficerInfo(officer)
    Database.Insert([[
        INSERT INTO kf_police_charges
            (identifier, crime, fine, jail_months, officer_id, officer_name, location)
        VALUES (?, ?, ?, 0, ?, ?, ?)
    ]], { identifier, label, amount, info.identifier, info.name, SanitizeText(payload.location, Config.Limits.location) })

    Logger.Audit(officer, 'fine.issue', identifier, { amount = amount, label = label })
    Invalidate('citizen', identifier)

    return MdtOk({ message = Locale('fine_issued', tostring(amount)) })
end)

--- Multe non pagate di un cittadino (sostituisce il pannello di esx_policejob).
RegisterMdtEndpoint('fines:list', 'mdt.view', function(_, payload)
    local identifier = SanitizeText(payload.identifier, 64)

    local where = 'c.voided_at IS NULL AND c.fine > 0'
    local params = {}

    if identifier ~= '' then
        where = where .. ' AND c.identifier = ?'
        params[#params + 1] = identifier
    end

    if payload.onlyUnpaid ~= false then
        where = where .. ' AND c.is_paid = 0'
    end

    local rows = Database.Query(([[
        SELECT c.id, c.identifier, c.crime, c.fine, c.is_paid, c.officer_name, c.created_at,
               CONCAT_WS(' ', u.firstname, u.lastname) AS citizen_name
        FROM kf_police_charges c
        LEFT JOIN users u ON u.identifier = c.identifier
        WHERE %s
        ORDER BY c.created_at DESC
        LIMIT 200
    ]]):format(where), params) or {}

    local list = {}
    local total = 0

    for _, row in ipairs(rows) do
        list[#list + 1] = {
            id = tonumber(row.id),
            identifier = row.identifier,
            citizenName = Trim(row.citizen_name),
            label = row.crime,
            amount = tonumber(row.fine) or 0,
            isPaid = tonumber(row.is_paid) == 1,
            officer = row.officer_name,
            date = tostring(row.created_at),
        }
        total = total + (tonumber(row.fine) or 0)
    end

    return MdtOk({ rows = list, total = #list, amount = total })
end)
