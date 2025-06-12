

local playerInventories = {}

local activeWashing = {}

local function getPlayerIdentifier(source)
    local identifier = GetPlayerIdentifier(source, 0)
    
    return identifier or tostring(source)
end

local function getPlayerInventory(source)
    local playerId = getPlayerIdentifier(source)
    
    if not playerInventories[playerId] then
        playerInventories[playerId] = {
            laundryDetergent = 1,
            fabricSoftener = 1,
            cashStack = 10,
            cashRoll = 20,
            looseNotes = 40,
            greenPigment = 1,
            cleanCash = 0
        }
    end
    
    return playerInventories[playerId]
end

local function getAmount(source, item)
    local inventory = getPlayerInventory(source)
    
    if inventory[item] ~= nil then
        return inventory[item]
    end
    
    return 0
end

local function addItem(source, item, amount)
    local inventory = getPlayerInventory(source)
    
    if inventory[item] ~= nil then
        inventory[item] = inventory[item] + amount
        return true
    end
    
    return false
end

local function removeItem(source, item, amount)
    local inventory = getPlayerInventory(source)
    
    if inventory[item] ~= nil and inventory[item] >= amount then
        inventory[item] = inventory[item] - amount
        return true
    end
    
    return false
end

local function hasItem(source, item, amount)
    local inventory = getPlayerInventory(source)
    
    return inventory[item] ~= nil and inventory[item] >= amount
end

local function TriggerEventNearby(eventName, playerId, radius, ...)
    local playerCoords = GetEntityCoords(GetPlayerPed(playerId))
    
    local players = GetPlayers()
    
    for _, nearbyPlayer in ipairs(players) do
        local nearbyCoords = GetEntityCoords(GetPlayerPed(nearbyPlayer))
        
        local distance = #(playerCoords - nearbyCoords)
        
        if distance <= radius then
            TriggerClientEvent(eventName, nearbyPlayer, ...)
        end
    end
end

RegisterNetEvent('laundry:processCash')
AddEventHandler('laundry:processCash', function(machineIndex)
    local playerId = source
    local machine = machineIndex
    
    local hasIngredients = hasItem(playerId, 'laundryDetergent', 1) and 
                          hasItem(playerId, 'fabricSoftener', 1) and 
                          hasItem(playerId, 'greenPigment', 1)
    
    local hasDirtyMoney = hasItem(playerId, 'cashStack', 1) or 
                         hasItem(playerId, 'cashRoll', 1) or 
                         hasItem(playerId, 'looseNotes', 1)

    if hasDirtyMoney and hasIngredients then
        local cashStackCount = getAmount(playerId, 'cashStack')
        local cashRollCount = getAmount(playerId, 'cashRoll')
        local looseNotesCount = getAmount(playerId, 'looseNotes')

        local totalCount = cashStackCount + cashRollCount + looseNotesCount

        activeWashing[playerId] = {
            cashStack = cashStackCount,
            cashRoll = cashRollCount,
            looseNotes = looseNotesCount,
            machine = machine,
            failed = false
        }

        removeItem(playerId, 'cashStack', cashStackCount)
        removeItem(playerId, 'cashRoll', cashRollCount)
        removeItem(playerId, 'looseNotes', looseNotesCount)

        removeItem(playerId, 'laundryDetergent', 1)
        removeItem(playerId, 'fabricSoftener', 1)
        removeItem(playerId, 'greenPigment', 1)

        TriggerClientEvent('laundry:showMessage', playerId, 'Washing starting. Please wait...', machine)
        
        TriggerClientEvent('laundry:startFirstMinigame', playerId, totalCount * 6000)
    else
        TriggerClientEvent('laundry:showMessage', playerId, 'You are missing something...')
    end
end)

RegisterNetEvent('laundry:firstMinigameSuccess')
AddEventHandler('laundry:firstMinigameSuccess', function(washingDuration)
    local playerId = source
    
    if activeWashing[playerId] then
        local data = activeWashing[playerId]
        
        TriggerEventNearby('laundry:closeMachine', playerId, 50.0, data.machine)
        TriggerEventNearby('laundry:startMoneyAnimation', playerId, 50.0, data.machine)
        TriggerClientEvent('laundry:startWashingProcess', playerId, washingDuration)
        
        Wait(washingDuration)
        
        if activeWashing[playerId] and not activeWashing[playerId].failed then
            local cashStackCount = data.cashStack
            local cashRollCount = data.cashRoll
            local looseNotesCount = data.looseNotes
            
            payout = ((cashStackCount * 700) + (cashRollCount * 350) + (looseNotesCount * 50))

            addItem(playerId, 'cleanCash', payout)

            TriggerEventNearby('laundry:stopMoneyAnimation', playerId, 50.0, data.machine)
            TriggerClientEvent('laundry:showMessage', playerId, 'Washing finished. Total cash washed: ' .. payout .. '.', data.machine)
            TriggerEventNearby('laundry:openMachine', playerId, 50.0, data.machine)
            
            activeWashing[playerId] = nil
        else
            if activeWashing[playerId] then
                TriggerEventNearby('laundry:stopMoneyAnimation', playerId, 50.0, activeWashing[playerId].machine)
                TriggerEventNearby('laundry:openMachine', playerId, 50.0, activeWashing[playerId].machine)
                activeWashing[playerId] = nil
            end
        end
    end
end)

RegisterNetEvent('laundry:washingFailed')
AddEventHandler('laundry:washingFailed', function()
    local playerId = source
    
    if activeWashing[playerId] then
        local data = activeWashing[playerId]
        
        data.failed = true

        addItem(playerId, 'cashStack', data.cashStack)
        addItem(playerId, 'cashRoll', data.cashRoll)
        addItem(playerId, 'looseNotes', data.looseNotes)
        
        addItem(playerId, 'laundryDetergent', 1)
        addItem(playerId, 'fabricSoftener', 1)
        addItem(playerId, 'greenPigment', 1)
        
        TriggerEventNearby('laundry:stopMoneyAnimation', playerId, 50.0, data.machine)
        TriggerEventNearby('laundry:openMachine', playerId, 50.0, data.machine)
        
        activeWashing[playerId] = nil
    end
end)

RegisterNetEvent('laundry:cancelWashing')
AddEventHandler('laundry:cancelWashing', function()
    local playerId = source
    
    if activeWashing[playerId] then
        local data = activeWashing[playerId]
        
        data.failed = true

        addItem(playerId, 'cashStack', data.cashStack)
        addItem(playerId, 'cashRoll', data.cashRoll)
        addItem(playerId, 'looseNotes', data.looseNotes)
        
        addItem(playerId, 'laundryDetergent', 1)
        addItem(playerId, 'fabricSoftener', 1)
        addItem(playerId, 'greenPigment', 1)
        
        TriggerEventNearby('laundry:stopMoneyAnimation', playerId, 50.0, data.machine)
        TriggerEventNearby('laundry:openMachine', playerId, 50.0, data.machine)
        
        TriggerClientEvent('laundry:showMessage', playerId, 'Washing cancelled - you moved too far away!')
        
        activeWashing[playerId] = nil
    end
end)