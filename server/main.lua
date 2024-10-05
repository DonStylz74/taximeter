ESX = nil

ESX = exports["es_extended"]:getSharedObject()

RegisterServerEvent('taxi:checkJob')
AddEventHandler('taxi:checkJob', function()
    local source = source
    print("Source: " .. tostring(source))  -- Debug print

    if ESX == nil then
        print("ESX is not initialized")
        return
    end

    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer == nil then
        print("xPlayer is nil for source: " .. tostring(source))
        return
    end

    if isJobAllowed(xPlayer.job.name) then
        TriggerClientEvent('taxi:allowMeter', source, true)
    else
        TriggerClientEvent('taxi:allowMeter', source, false)
    end
end)

function isJobAllowed(jobName)
    for _, allowedJob in ipairs(Config.AllowedJobs) do
        if jobName == allowedJob then
            return true
        end
    end
    return false
end
