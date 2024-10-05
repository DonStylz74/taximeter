local fare = 10
local extras = 0
local extraCost = 0.8
local isDriver = false
local fareDecor = "_ND_TAXI_FARE_"
local extrasDecor = "_ND_TAXI_EXTRAS_"
local meterStarted = false
local display = false
local focus = false
local canUseMeter = false


-- Check job when player spawns
AddEventHandler('playerSpawned', function()
    TriggerServerEvent('taxi:checkJob')
end)

-- Check job when player loads
AddEventHandler('esx:playerLoaded', function(playerData)
    if isJobAllowed(playerData.job.name) then
        canUseMeter = true
    else
        canUseMeter = false
    end
end)

-- Check job when job changes
RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
    if isJobAllowed(job.name) then
        canUseMeter = true
    else
        canUseMeter = false
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

function SetTaxi(vehicle)
    DecorSetFloat(vehicle, fareDecor, tonumber(string.format("%.2f", fare)))
    DecorSetFloat(vehicle, extrasDecor, tonumber(string.format("%.2f", extras)))
end

function GetTaxi(vehicle)
    if DecorExistOn(vehicle, fareDecor) == false and DecorExistOn(vehicle, extrasDecor) == false then
        return fare, extras
    end
    return DecorGetFloat(vehicle, fareDecor), DecorGetFloat(vehicle, extrasDecor)
end

function isTaxi(vehicle)
    local vehicleModel = GetEntityModel(vehicle)
    local vehicleName = GetDisplayNameFromVehicleModel(vehicleModel):lower()
    return IsVehicleAllowed(vehicleName)
end

CreateThread(function()
    DecorRegister(fareDecor, 1)
    DecorRegister(extrasDecor, 1)
    local wait = 500
    while true do
        Wait(wait)
        if focus then
            wait = 0
            DisableControlAction(0, 1, true)    -- Look Left/Right
            DisableControlAction(0, 2, true)    -- Look up/Down
        else
            wait = 500
        end
    end
end)

RegisterCommand("+taxi", function()
    if not canUseMeter then
        ESX.ShowNotification('You are not a taxi driver!')
        return
    end
    if not isDriver then return end
    if not focus then
        focus = true
        Wait(300)
        SetCursorLocation(0.85, 0.9)
    else
        focus = false
    end
    SetNuiFocus(focus, focus)
    SetNuiFocusKeepInput(focus)
end, false)
RegisterCommand("-taxi", function()end, false)
RegisterKeyMapping("+taxi", "Taxi meter", "keyboard", "f3")

CreateThread(function()
    while true do
        Wait(1000)
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped)

        if vehicle ~= 0 and isTaxi(vehicle) then
            local seat = GetPedInVehicleSeat(vehicle, -1)
            if not display then
                display = true
                SendNUIMessage({
                    type = "showUI",
                    display = display
                })
            end

            if seat == ped and isDriver then
                local rpm = GetVehicleCurrentRpm(vehicle)
                if meterStarted then
                    fare = fare + (rpm / 1.5)
                    SetTaxi(vehicle)
                end
            elseif seat == ped and not isDriver then
                isDriver = true
                SendNUIMessage({
                    type = "updateDriver",
                    driver = isDriver
                })
            elseif seat ~= ped and isDriver then
                isDriver = false
                SendNUIMessage({
                    type = "updateDriver",
                    driver = isDriver
                })
            end

            local fare, extras = GetTaxi(vehicle)
            SendNUIMessage({
                type = "updateFare",
                fare = fare,
                extras = extras,
                total = fare + extras
            })
        elseif display then
            display = false
            SendNUIMessage({
                type = "showUI",
                display = display
            })
        end
    end
end)

RegisterNUICallback("extrasAdd", function(data)
    extras = extras + extraCost
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped)
    SetTaxi(vehicle, fare, extras)
    SendNUIMessage({
        type = "updateFare",
        fare = fare,
        extras = extras,
        total = fare + extras
    })
end)

RegisterNUICallback("extrasRemove", function(data)
    if extras >= extraCost then
        extras = extras - extraCost
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped)
        SetTaxi(vehicle, fare, extras)
        SendNUIMessage({
            type = "updateFare",
            fare = fare,
            extras = extras,
            total = fare + extras
        })
    end
end)

RegisterNUICallback("startMeter", function(data)
    meterStarted = true
    SetTaxi(vehicle, fare, extras)
end)

RegisterNUICallback("stopMeter", function(data)
    meterStarted = false
    SetTaxi(vehicle, fare, extras)
end)

RegisterNUICallback("resetMeter", function(data)
    meterStarted = false
    fare = 10
    extras = 0
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped)
    SetTaxi(vehicle, fare, extras)
end)

RegisterNetEvent('taxi:allowMeter')
AddEventHandler('taxi:allowMeter', function(allowed)
    canUseMeter = allowed
end)

Citizen.CreateThread(function()
    while ESX == nil do
        Citizen.Wait(0)
    end

    -- Load the config file
    local configFile = LoadResourceFile(GetCurrentResourceName(), 'config.lua')
    assert(load(configFile))()

    -- Register the taximeter command
    RegisterCommand('taximeter', function(source, args, rawCommand)
        local xPlayer = ESX.GetPlayerFromId(source)
        local vehicle = GetVehiclePedIsIn(GetPlayerPed(source), false)
        local vehicleModel = GetEntityModel(vehicle)
        local vehicleName = GetDisplayNameFromVehicleModel(vehicleModel):lower()

        if IsVehicleAllowed(vehicleName) then
            -- Your taximeter logic here
            TriggerClientEvent('esx_taximeter:start', source)
        else
            TriggerClientEvent('esx:showNotification', source, 'This vehicle is not allowed to use a taximeter.')
        end
    end, false)
end)

function IsVehicleAllowed(vehicleName)
    for _, allowedVehicle in ipairs(Config.AllowedVehicles) do
        if vehicleName == allowedVehicle then
            return true
        end
    end
    return false
end
