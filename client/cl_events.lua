RegisterNetEvent('KF_Police:Client:RequestDataUpdate')
AddEventHandler('KF_Police:Client:RequestDataUpdate', function()
    if opened then
        RequestDataUpdate()
    end
end)