---@param source number Player ID
---@param data table Notification data
function lib.notify(source, data)
    TriggerClientEvent('ox_lib:notify', source, data)
end

exports('notify', lib.notify)
