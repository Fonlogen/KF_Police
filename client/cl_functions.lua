local function getClosestPlayer(maxDistance)
    local players = GetActivePlayers()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local closestPlayer, closestDistance = -1, maxDistance or 3.0

    for i = 1, #players do
        local target = players[i]
        if target ~= PlayerId() then
            local targetPed = GetPlayerPed(target)
            local distance = #(coords - GetEntityCoords(targetPed))
            if distance < closestDistance then
                closestPlayer = target
                closestDistance = distance
            end
        end
    end

    return closestPlayer, closestDistance
end

RegisterNUICallback('getNearbyCitizen', function(_, cb)
    local closestPlayer = getClosestPlayer(3.0)
    if closestPlayer == -1 then
        cb({ ok = false })
        return
    end

    cb({
        ok = true,
        serverId = GetPlayerServerId(closestPlayer),
    })
end)
