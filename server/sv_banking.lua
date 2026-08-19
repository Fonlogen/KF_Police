local function isResourceStarted(name)
    return name and GetResourceState(name) == 'started'
end

local function getIdentifier(entity)
    if not entity then
        return nil
    end

    if type(entity) == 'string' then
        return entity
    end

    if entity.identifier then
        return entity.identifier
    end

    if entity.getIdentifier then
        return entity.getIdentifier()
    end

    return nil
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
    local exp = exports[exportCfg.resource]
    if not exp then
        return false
    end

    -- FiveM exports use colon-call (self = export table). Without it the first arg is eaten.
    local invoke
    if exportCfg.method == false then
        invoke = function()
            return exp[exportCfg.name](table.unpack(args, 1, argc))
        end
    else
        invoke = function()
            return exp[exportCfg.name](exp, table.unpack(args, 1, argc))
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
                error('missing client destination')
            end
            TriggerClientEvent(eventCfg.name, dest, table.unpack(args, 1, argc))
        else
            TriggerEvent(eventCfg.name, table.unpack(args, 1, argc))
        end
    end)
    return ok
end

function FindOnlineSourceByIdentifier(identifier)
    if not identifier then
        return nil
    end

    if ESX.GetPlayerFromIdentifier then
        local xPlayer = ESX.GetPlayerFromIdentifier(identifier)
        if xPlayer then
            return xPlayer.source
        end
    end

    local players = ESX.GetExtendedPlayers and ESX.GetExtendedPlayers() or {}
    if type(players) == 'table' then
        for _, xPlayer in pairs(players) do
            if xPlayer and getIdentifier(xPlayer) == identifier then
                return xPlayer.source
            end
        end
    end

    return nil
end

function RecordPoliceTransaction(officer, citizen, label, amount)
    local banking = Config.Banking or {}
    amount = tonumber(amount) or 0
    if not banking.Enabled or amount <= 0 or not citizen then
        return false
    end

    local ctx = {
        targetIdentifier = getIdentifier(citizen),
        targetSource = FindOnlineSourceByIdentifier(getIdentifier(citizen)),
        officerIdentifier = getIdentifier(officer),
        officerSource = officer and officer.source or nil,
        amount = amount,
        label = label or banking.FallbackLabel or 'Sanzione polizia',
        society = banking.Society or Config.BillingSociety or 'society_police',
        societyLabel = banking.SocietyLabel or 'LSPD',
        reason = banking.Reason or 'police_fine',
        accountType = banking.AccountType or 'bank',
    }

    if not ctx.targetIdentifier or not ctx.officerIdentifier then
        return false
    end

    for _, adapter in ipairs(banking.Adapters or {}) do
        if isResourceStarted(adapter.resource or adapter.name) then
            local recorded = false
            if adapter.export then
                recorded = callExport(adapter.export, ctx) or recorded
            end
            if not recorded and adapter.event then
                recorded = fireEvent(adapter.event, ctx) or recorded
            end
            if recorded then
                return true
            end
        end
    end

    return false
end
