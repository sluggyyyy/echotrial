RegisterNetEvent('moneycounter:processCash')
AddEventHandler('moneycounter:processCash', function(counterIndex)
    local playerId = source
    
    local hasCashStack = exports['laundry']:hasItem(playerId, 'cashStack', 1)
    local hasCashRoll = exports['laundry']:hasItem(playerId, 'cashRoll', 1)
    local hasLooseNotes = exports['laundry']:hasItem(playerId, 'looseNotes', 1)
    
    local cashStackCount = exports['laundry']:getAmount(playerId, 'cashStack') or 0
    local cashRollCount = exports['laundry']:getAmount(playerId, 'cashRoll') or 0
    local looseNotesCount = exports['laundry']:getAmount(playerId, 'looseNotes') or 0
    
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
    
    exports['laundry']:removeItem(playerId, 'cashStack', cashStackCount)
    exports['laundry']:removeItem(playerId, 'cashRoll', cashRollCount)
    exports['laundry']:removeItem(playerId, 'looseNotes', looseNotesCount)
    
    TriggerClientEvent('chat:addMessage', playerId, {args = {"Processing " .. totalItems .. " items..."}})
    
    Wait(processingTime)
    
    if totalStacks > 0 then
        exports['laundry']:addItem(playerId, 'cashStack', totalStacks)
    end
    if remainingRolls > 0 then
        exports['laundry']:addItem(playerId, 'cashRoll', remainingRolls)
    end
    if remainingNotes > 0 then
        exports['laundry']:addItem(playerId, 'looseNotes', remainingNotes)
    end
    
    local message = string.format("Money counting finished! Result: %d stacks, %d rolls, %d notes", totalStacks, remainingRolls, remainingNotes)
    TriggerClientEvent('chat:addMessage', playerId, {args = {message}})
end)