local moneyCounters = {
    {x = 1110.0, y = -3230.0, z = 4.7, heading = 0.0}
}

local spawnedCounters = {}
local counterStates = {}

function GetNearestMoneyCounter()
    local playerCoords = GetEntityCoords(PlayerPedId())
    
    for i = 1, #moneyCounters do
        local counter = moneyCounters[i]
        local distance = GetDistanceBetweenCoords(playerCoords.x, playerCoords.y, playerCoords.z, counter.x, counter.y, counter.z, true)
        
        if distance < 2.0 then
            return i
        end
    end
    return nil
end

function InitCounterStates()
    for i = 1, #moneyCounters do
        counterStates[i] = {
            inUse = false,
        }
    end
end

CreateThread(function()
    Wait(1000)
    
    InitCounterStates()

    local counterModel = GetHashKey('bkr_prop_money_counter')
    RequestModel(counterModel)

    local attempts = 0
    while not HasModelLoaded(counterModel) and attempts < 50 do
        Wait(100)
        attempts = attempts + 1
    end
    
    if HasModelLoaded(counterModel) then
        for i = 1, #moneyCounters do
            local pos = moneyCounters[i]
            local counter = CreateObject(counterModel, pos.x, pos.y, pos.z, false, false, false)
            PlaceObjectOnGroundProperly(counter)
            Wait(100)
            local finalCoords = GetEntityCoords(counter)
            SetEntityHeading(counter, pos.heading)
            FreezeEntityPosition(counter, true)
            SetEntityAsMissionEntity(counter, true, true)
            table.insert(spawnedCounters, counter)
        end
        print("Money counters spawned")
    else
        print("Failed to load money counter model")
    end
end)

CreateThread(function()
    while true do
        Wait(0)
        local currentCounterIndex = GetNearestMoneyCounter()

        if currentCounterIndex then
            local counter = counterStates[currentCounterIndex]
            if not counter.inUse then
                SetTextComponentFormat("STRING")
                AddTextComponentString("Press E to bundle your cash.")
                DisplayHelpTextFromStringLabel(0, 0, 1, -1)

                if IsControlJustReleased(0, 38) then
                    TriggerServerEvent('moneycounter:processCash', currentCounterIndex)
                end
            else
                SetTextComponentFormat("STRING")
                AddTextComponentString("Cannot stack cash right now...")
                DisplayHelpTextFromStringLabel(0, 0, 1, -1)
            end
        end
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        for i = 1, #spawnedCounters do
            if DoesEntityExist(spawnedCounters[i]) then
                DeleteEntity(spawnedCounters[i])
            end
        end
        print("Cleaned up money counters")
    end
end)

