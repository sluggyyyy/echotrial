
local moneyCounters = {
    {x = 1110.0, y = -3230.0, z = 4.7, heading = 0.0}
}

local spawnedCounters = {}
local counterStates = {}
local proximityUpdateThread = nil
local countingActive = false
local activeCounterIndex = nil

function GetNearestMoneyCounter()
    local playerCoords = GetEntityCoords(PlayerPedId())
    
    for i = 1, #moneyCounters do
        local counter = moneyCounters[i]
        
        local distance = GetDistanceBetweenCoords(
            playerCoords.x, playerCoords.y, playerCoords.z,
            counter.x, counter.y, counter.z,
            true
        )
        
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
            local finalHeading = GetEntityHeading(counter)
            
            moneyCounters[i] = {
                x = finalCoords.x, 
                y = finalCoords.y, 
                z = finalCoords.z, 
                heading = finalHeading
            }
            
            FreezeEntityPosition(counter, true)
            SetEntityAsMissionEntity(counter, true, true)
            
            table.insert(spawnedCounters, counter)
        end
    end
end)

CreateThread(function()
    while true do
        Wait(0)
        
        local nearestCounter = GetNearestMoneyCounter()
        
        if nearestCounter then
            local counter = counterStates[nearestCounter]
            
            if not counter.inUse then
                
                SetTextComponentFormat("STRING")
                AddTextComponentString("Press E to count money.")
                DisplayHelpTextFromStringLabel(0, 0, 1, -1)

                if IsControlJustReleased(0, 38) then
                    
                    TriggerServerEvent('moneycounter:startCounting', nearestCounter)
                end
            else
                SetTextComponentFormat("STRING")
                AddTextComponentString("Money counter is busy...")
                DisplayHelpTextFromStringLabel(0, 0, 1, -1)
            end
        end
    end
end)

RegisterNetEvent('moneycounter:startCountingAnimation')
AddEventHandler('moneycounter:startCountingAnimation', function(counterIndex)
    countingActive = true
    activeCounterIndex = counterIndex
    
    SendNUIMessage({
        type = 'playSound',
        sound = 'counting_loop'
    })
    
    if proximityUpdateThread then
        proximityUpdateThread = nil
    end
    
    proximityUpdateThread = CreateThread(function()
        while countingActive and activeCounterIndex == counterIndex do
            local playerCoords = GetEntityCoords(PlayerPedId())
            local counter = moneyCounters[counterIndex]
            
            local distance = GetDistanceBetweenCoords(
                playerCoords.x, playerCoords.y, playerCoords.z,
                counter.x, counter.y, counter.z, true
            )
            
            if distance > 10.0 then
                TriggerServerEvent('moneycounter:cancelCounting')
                break
            end
            
            Wait(500)
        end
        proximityUpdateThread = nil
    end)
end)

RegisterNetEvent('moneycounter:stopCountingAnimation')
AddEventHandler('moneycounter:stopCountingAnimation', function(counterIndex)
    countingActive = false
    activeCounterIndex = nil
    
    SendNUIMessage({
        type = 'stopSound',
        sound = 'counting_loop'
    })
    
    SendNUIMessage({
        type = 'playSound',
        sound = 'beep'
    })
    
    if counterStates[counterIndex] then
        counterStates[counterIndex].inUse = false
    end
end)

RegisterNetEvent('moneycounter:showMessage')
AddEventHandler('moneycounter:showMessage', function(message, counterIndex)
    TriggerEvent('chat:addMessage', {
        args = {message}
    })
    
    local targetCounter = counterIndex or GetNearestMoneyCounter()
    
    if targetCounter and counterStates[targetCounter] then
        if string.find(message, "Counting money") then
            counterStates[targetCounter].inUse = true
        elseif string.find(message, "Money counting complete") then
            counterStates[targetCounter].inUse = false
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
        
    end
end)