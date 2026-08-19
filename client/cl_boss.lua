--[[
    KF_Police - Menu societa' (client)
    ----------------------------------------------------------------------------
    Se esx_society e' avviato si usa quello (conti, assunzioni, salari sono
    servizi condivisi con gli altri lavori: duplicarli farebbe danno). In sua
    assenza resta un menu interno minimo con il roster.
]]

local function openSocietyMenu()
    if GetResourceState('esx_society') == 'started' then
        TriggerServerEvent('esx_society:openBossMenu', Config.Society, nil, {
            wash = false,
        })
        return
    end

    -- Riserva: roster interno, in sola lettura.
    local response = lib.callback.await('KF_Police:mdt', false, 'duty:roster', {})

    if not response or not response.ok then
        return NotifyLocale('boss_unavailable', 'error')
    end

    local options = {}

    for _, agent in ipairs(response.rows or {}) do
        options[#options + 1] = {
            title = ('%s %s'):format(agent.firstName, agent.lastName),
            description = ('%s | %s | %s'):format(
                agent.gradeLabel,
                agent.onDuty and 'in servizio' or 'fuori servizio',
                FormatDuration(agent.secondsThisMonth)
            ),
            icon = 'user-shield',
            disabled = true,
        }
    end

    if #options == 0 then
        options[1] = { title = 'Nessun agente', disabled = true }
    end

    lib.registerContext({
        id = 'kf_police_boss',
        title = Locale('boss_menu'),
        options = options,
    })

    lib.showContext('kf_police_boss')
end

CreateThread(function()
    while not Target do
        Wait(200)
    end

    for stationKey, station in pairs(Config.Stations) do
        for index, coords in ipairs(station.bossActions or {}) do
            Target.AddZone({
                name = ('kf_police_boss_%s_%d'):format(stationKey, index),
                coords = coords,
                radius = Config.TargetRadius,
                label = Locale('boss_menu'),
                faIcon = 'fa-solid fa-briefcase',
                marker = 'boss',
                permission = 'society.boss',
                onSelect = openSocietyMenu,
            })
        end
    end
end)
