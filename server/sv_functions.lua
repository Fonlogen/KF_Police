function UpdateMDTData()
    TriggerClientEvent('KF_Police:Client:RequestDataUpdate', -1)
end

RegisterNetEvent('KF_Police:Server:CreateReport')
AddEventHandler('KF_Police:Server:CreateReport', function(data)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local report = {
        id = #reports + 1,
        officer = xPlayer.getName(),
        officer_id = xPlayer.citizenid,
        title = data.title,
        description = data.description,
        location = 'Unknown',
        date = os.date('%Y-%m-%d %H:%M:%S'),
        tags = data.tags or {},
        involved = data.involved or {},
        involved_vehicles = data.involved_vehicles or {},
    }
    reports[report.id] = report

    MySQL.Async.execute('INSERT INTO kf_police_reports (title, description, officer, officer_id, date, location, tags, involved, involved_vehicles) VALUES (@title, @description, @officer, @officer_id, @date, @location, @tags, @involved, @involved_vehicles)', {
        ['@title'] = report.title,
        ['@description'] = report.description,
        ['@officer'] = report.officer,
        ['@officer_id'] = report.officer_id,
        ['@date'] = report.date,
        ['@location'] = report.location,
        ['@tags'] = json.encode(report.tags),
        ['@involved'] = json.encode(report.involved or {}),
        ['@involved_vehicles'] = json.encode(report.involved_vehicles or {}),
    }, function(rowsChanged)
        if rowsChanged > 0 then
            TriggerClientEvent('esx:showNotification', src, 'Report created successfully', 'success', Config.NotificationsDuration)
            UpdateMDTData()
        end
    end)
end)
