RegisterNetEvent('laundry:processDirtyClothes')
AddEventHandler('laundry:processDirtyClothes', function(machineIndex)
    local playerId = source
    local machine = machineIndex

    local hasDirtyClothes = exports['laundry']:hasItem(playerId, 'dirtyClothes', 1)

    if hasDirtyClothes then
        exports['laundry']:removeItem(playerId, 'dirtyClothes', 1)

        TriggerClientEvent('laundry:showmessage', playerId, 'Added dirty clothes')
    else
        TriggerClientEvent('laundry:showmessage', playerId, 'You have no dirty clothes!')
    end

    TriggerClientEvent('laundry:closeMachine', playerId, machine)
end)

RegisterNetEvent('laundry:closeMachineRequest')
AddEventHandler('laundry:closeMachineRequest', function(machineIndex)
    local playerId = source
    TriggerClientEvent('laundry:closeMachine', playerId, machineIndex)
end)

RegisterNetEvent('laundry:processCash')
AddEventHandler('laundry:processCash', function(machineIndex)
    local playerId = source
    local machine = machineIndex

    local hasIngredients = exports['laundry']:hasItem(playerId, 'laundryDetergent', 1) and exports['laundry']:hasItem(playerId, 'fabricSoftener', 1) and exports['laundry']:hasItem(playerId, 'greenPigment', 1)
    local hasDirtyMoney = exports['laundry']:hasItem(playerId, 'cashStack', 1) or exports['laundry']:hasItem(playerId, 'cashRoll', 1) or exports['laundry']:hasItem(playerId, 'looseNotes', 1)

    if hasDirtyMoney and hasIngredients then

        TriggerClientEvent('laundry:startDirtyClothesPhase', playerId, machine)

        local cashStackCount = exports['laundry']:getAmount(playerId, 'cashStack')
        local cashRollCount = exports['laundry']:getAmount(playerId, 'cashRoll')
        local looseNotesCount = exports['laundry']:getAmount(playerId, 'looseNotes')

        local totalCount = cashStackCount + cashRollCount + looseNotesCount

        exports['laundry']:removeItem(playerId, 'cashStack', cashStackCount)
        exports['laundry']:removeItem(playerId, 'cashRoll', cashRollCount)
        exports['laundry']:removeItem(playerId, 'looseNotes', looseNotesCount)

        exports['laundry']:removeItem(playerId, 'laundryDetergent', 1)
        exports['laundry']:removeItem(playerId, 'fabricSoftener', 1)
        exports['laundry']:removeItem(playerId, 'greenPigment', 1)

        TriggerClientEvent('laundry:showMessage', playerId, 'Washing starting. Please wait...')
        
        Wait(totalCount * 6000)

        payout = ((cashStackCount * 675) + (cashRollCount * 325) + (looseNotesCount * 80))

        exports['laundry']:addItem(playerId, 'cleanCash', payout)

        TriggerClientEvent('laundry:showMessage', playerId, 'Washing finished. Total cash washed: ' .. payout .. '.')
        TriggerClientEvent('laundry:openMachine', playerId, machine)
    else
        TriggerClientEvent('laundry:showMessage', playerId, 'You are missing something...')
    end
end)