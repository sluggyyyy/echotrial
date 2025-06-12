

local playerInventories = {}

local activeCounting = {}

local function getPlayerIdentifier(source)
    local identifier = GetPlayerIdentifier(source, 0)
    
    return identifier or tostring(source)
end

local function getPlayerInventory(source)
    local playerId = getPlayerIdentifier(source)
    
    if not playerInventories[playerId] then
        playerInventories[playerId] = {
            cashStack = 5,
            cashRoll = 1,
            looseNotes = 10
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

RegisterNetEvent('moneycounter:startCounting')
AddEventHandler('moneycounter:startCounting', function(counterIndex)
    local playerId = source
    
    local hasCashStack = hasItem(playerId, 'cashStack', 1)
    local hasCashRoll = hasItem(playerId, 'cashRoll', 1)
    local hasLooseNotes = hasItem(playerId, 'looseNotes', 1)
    
    local cashStackCount = getAmount(playerId, 'cashStack') or 0
    local cashRollCount = getAmount(playerId, 'cashRoll') or 0
    local looseNotesCount = getAmount(playerId, 'looseNotes') or 0
    
    local notesPerRoll = 7
    local rollsPerStack = 2
    
    if cashRollCount < rollsPerStack and looseNotesCount < notesPerRoll then
        TriggerClientEvent('chat:addMessage', playerId, {args = {"You don't have enough dirty money to process."}})
        return
    end

    
    local newRollsFromNotes = math.floor(looseNotesCount / notesPerRoll)
    local remainingNotes = looseNotesCount % notesPerRoll
    
    local totalRolls = cashRollCount + newRollsFromNotes
    
    local newStacksFromRolls = math.floor(totalRolls / rollsPerStack)
    local remainingRolls = totalRolls % rollsPerStack
    
    local totalStacks = cashStackCount + newStacksFromRolls
    
    local totalItems = cashStackCount + cashRollCount + looseNotesCount
    local processingTime = totalItems * 1000
    
    activeCounting[playerId] = {
        cashStack = cashStackCount,
        cashRoll = cashRollCount,
        looseNotes = looseNotesCount,
        counterIndex = counterIndex
    }
    
    removeItem(playerId, 'cashStack', cashStackCount)
    removeItem(playerId, 'cashRoll', cashRollCount)
    removeItem(playerId, 'looseNotes', looseNotesCount)
    
    TriggerClientEvent('chat:addMessage', playerId, {args = {"Processing " .. totalItems .. " items..."}})
    
    TriggerEventNearby('moneycounter:startCountingAnimation', playerId, 50.0, counterIndex, processingTime)
    
    Wait(processingTime - 1000)
    
    if activeCounting[playerId] then
        TriggerEventNearby('moneycounter:stopCountingAnimation', playerId, 50.0, counterIndex)
        Wait(1000)
        
        if activeCounting[playerId] then
            if totalStacks > 0 then
                addItem(playerId, 'cashStack', totalStacks)
            end
            if remainingRolls > 0 then
                addItem(playerId, 'cashRoll', remainingRolls)
            end
            if remainingNotes > 0 then
                addItem(playerId, 'looseNotes', remainingNotes)
            end
            
            local message = string.format("Money counting finished! Result: %d stacks, %d rolls, %d notes", totalStacks, remainingRolls, remainingNotes)
            TriggerClientEvent('chat:addMessage', playerId, {args = {message}})
            
            TriggerEventNearby('moneycounter:finishCounting', playerId, 50.0, counterIndex)
            
            activeCounting[playerId] = nil
        end
    end
end)

RegisterCommand('checkcash', function(source, args)
    if source == 0 then return end

    local inventory = getPlayerInventory(source)

    TriggerClientEvent('chat:addMessage', source, {
        args = {'=== CASH INVENTORY ==='}
    })
    
    for item, amount in pairs(inventory) do
        TriggerClientEvent('chat:addMessage', source, {
            args = {string.format('%s: %d', item, amount)}
        })
    end
end, false)

RegisterCommand('givecash', function(source, args)
    if source == 0 then return end

    local item = args[1]
    local amount = tonumber(args[2]) or 1
    
    if not item then
        TriggerClientEvent('chat:addMessage', source, {
            args = {'^1[Error] Usage: /givecash itemname amount'}
        })
        return
    end
    
    if addItem(source, item, amount) then
        TriggerClientEvent('chat:addMessage', source, {
            args = {string.format('^2[Success] Added %d %s to inventory', amount, item)}
        })
    else
        TriggerClientEvent('chat:addMessage', source, {
            args = {string.format('^1[Error] Invalid item: %s', item)}
        })
    end
end, false)

RegisterNetEvent('moneycounter:cancelCounting')
AddEventHandler('moneycounter:cancelCounting', function()
    local playerId = source
    
    if activeCounting[playerId] then
        local data = activeCounting[playerId]
        
        addItem(playerId, 'cashStack', data.cashStack)
        addItem(playerId, 'cashRoll', data.cashRoll)
        addItem(playerId, 'looseNotes', data.looseNotes)
        
        TriggerEventNearby('moneycounter:stopCountingAnimation', playerId, 50.0, data.counterIndex)
        
        TriggerClientEvent('chat:addMessage', playerId, {args = {'Money counting cancelled - you moved too far away!'}})
        
        activeCounting[playerId] = nil
    end
end)