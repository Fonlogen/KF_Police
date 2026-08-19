RegisterNetEvent('KF_Police:Client:RequestDataUpdate', function()
    if opened then
        RequestDataUpdate()
    end
end)

RegisterNUICallback('getClientData', function(_, cb)
    local data = RequestDataUpdate()
    cb(data or {})
end)

RegisterNUICallback('getEnabledPages', function(_, cb)
    UpdateNuiEnabledPages()
    cb(Config.EnabledPages or {})
end)

RegisterNUICallback('close', function(_, cb)
    CloseMDT()
    cb({ ok = true })
end)

RegisterNUICallback('createReport', function(data, cb)
    local coords = GetEntityCoords(PlayerPedId())
    local streetHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local street = GetStreetNameFromHashKey(streetHash)

    TriggerServerEvent('KF_Police:Server:CreateReport', {
        title = data and data.title or '',
        description = data and data.description or '',
        tags = data and data.tags or {},
        involved = data and data.involved or {},
        involved_vehicles = data and data.involved_vehicles or {},
        location = (street and street ~= '' and street) or Config.DefaultTown,
    })

    cb({ ok = true })
end)

RegisterNUICallback('deleteReport', function(data, cb)
    TriggerServerEvent('KF_Police:Server:DeleteReport', data and (data.id or data.reportId))
    cb({ ok = true })
end)

RegisterNUICallback('setWanted', function(data, cb)
    TriggerServerEvent('KF_Police:Server:SetWanted', data or {})
    cb({ ok = true })
end)

RegisterNUICallback('addCharge', function(data, cb)
    TriggerServerEvent('KF_Police:Server:AddCharge', data or {})
    cb({ ok = true })
end)

RegisterNUICallback('saveCitizenNote', function(data, cb)
    TriggerServerEvent('KF_Police:Server:SaveCitizenNote', data or {})
    cb({ ok = true })
end)

RegisterNUICallback('setVehicleFlag', function(data, cb)
    TriggerServerEvent('KF_Police:Server:SetVehicleFlag', data or {})
    cb({ ok = true })
end)

RegisterNUICallback('reloadData', function(_, cb)
    TriggerServerEvent('KF_Police:Server:ReloadData')
    cb({ ok = true })
end)
