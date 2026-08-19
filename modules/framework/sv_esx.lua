--[[
    KF_Police - Bridge framework ESX (server)
]]

if Config.Framework ~= 'esx' then
    return
end

Framework = {}

ESX = exports['es_extended']:getSharedObject()

function Framework.GetPlayer(src)
    if not src then
        return nil
    end

    return ESX.GetPlayerFromId(tonumber(src))
end

function Framework.GetPlayerFromIdentifier(identifier)
    if not identifier then
        return nil
    end

    if ESX.GetPlayerFromIdentifier then
        return ESX.GetPlayerFromIdentifier(identifier)
    end

    for _, xPlayer in pairs(Framework.GetOnlinePlayers()) do
        if xPlayer.identifier == identifier then
            return xPlayer
        end
    end

    return nil
end

function Framework.GetIdentifier(player)
    if not player then
        return nil
    end

    if type(player) == 'string' then
        return player
    end

    return player.identifier
end

function Framework.GetName(player)
    if not player then
        return 'Sconosciuto'
    end

    local firstName = player.get and player.get('firstName')
    local lastName = player.get and player.get('lastName')

    if firstName or lastName then
        return Trim(('%s %s'):format(firstName or '', lastName or ''))
    end

    if player.getName then
        return player.getName() or 'Sconosciuto'
    end

    return GetPlayerName(player.source) or 'Sconosciuto'
end

--- @return string|nil name, number grade, string gradeName, string gradeLabel
function Framework.GetJob(player)
    if not player or not player.job then
        return nil, 0, 'recruit', ''
    end

    local grade = tonumber(player.job.grade) or 0

    return player.job.name,
        grade,
        ResolveGradeName(player.job.name, grade, player.job.grade_name),
        player.job.grade_label or ''
end

function Framework.GetSsn(player)
    if not player then
        return nil
    end

    if player.getSSN then
        local ok, ssn = pcall(player.getSSN)
        if ok and ssn then
            return ssn
        end
    end

    return player.identifier
end

function Framework.GetSex(player)
    if not player then
        return 'male'
    end

    local sex = player.get and player.get('sex')
    if sex == 'f' or sex == 'F' or sex == 'female' then
        return 'female'
    end

    return 'male'
end

function Framework.Notify(src, message, nType)
    TriggerClientEvent('KF_Police:Client:Notify', src, message, nType or 'info')
end

function Framework.GetOnlinePlayers()
    if ESX.GetExtendedPlayers then
        return ESX.GetExtendedPlayers() or {}
    end

    local list = {}
    for _, playerId in ipairs(ESX.GetPlayers() or {}) do
        local xPlayer = ESX.GetPlayerFromId(playerId)
        if xPlayer then
            list[#list + 1] = xPlayer
        end
    end

    return list
end

function Framework.RegisterUsableItem(itemName, cb)
    if not itemName or itemName == '' then
        return
    end

    pcall(ESX.RegisterUsableItem, itemName, cb)
end

function Framework.AddAccountMoney(player, account, amount)
    if not player or not player.addAccountMoney then
        return false
    end

    local ok = pcall(player.addAccountMoney, account, amount)
    return ok
end

function Framework.RemoveAccountMoney(player, account, amount)
    if not player then
        return false
    end

    local balance = player.getAccount and player.getAccount(account)
    if not balance or (tonumber(balance.money) or 0) < amount then
        return false
    end

    local ok = pcall(player.removeAccountMoney, account, amount)
    return ok
end

--- Conto societa' via esx_addonaccount. Nil se la risorsa non c'e'.
function Framework.GetSocietyAccount(society)
    if GetResourceState('esx_addonaccount') ~= 'started' then
        return nil
    end

    local account = nil
    local ok = pcall(function()
        TriggerEvent('esx_addonaccount:getSharedAccount', society, function(result)
            account = result
        end)
    end)

    return ok and account or nil
end

--- Preleva dal conto societa'. Vero solo se il denaro c'era davvero.
function Framework.RemoveSocietyMoney(society, amount)
    amount = tonumber(amount) or 0
    if amount <= 0 then
        return true
    end

    local account = Framework.GetSocietyAccount(society)
    if not account then
        return false
    end

    if (tonumber(account.money) or 0) < amount then
        return false
    end

    local ok = pcall(account.removeMoney, amount)
    return ok
end

function Framework.AddSocietyMoney(society, amount)
    amount = tonumber(amount) or 0
    if amount <= 0 then
        return true
    end

    local account = Framework.GetSocietyAccount(society)
    if not account then
        return false
    end

    local ok = pcall(account.addMoney, amount)
    return ok
end
