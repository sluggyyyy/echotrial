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

RegisterNetEvent('laundry:processDirtyClothes')
AddEventHandler('laundry:processDirtyClothes', function(machineIndex)
    local playerId = source
    local machine = machineIndex

    local hasDirtyClothes = exports['laundry']:hasItem(playerId, 'dirtyClothes', 1)

    if hasDirtyClothes then
        exports['laundry']:removeItem(playerId, 'dirtyClothes', 1)

        TriggerClientEvent('laundry:showmessage', playerId, 'Added dirty clothes')
        TriggerEventNearby('laundry:startMoneyAnimation', playerId, 50.0, machine)
    else
        TriggerClientEvent('laundry:showmessage', playerId, 'You have no dirty clothes!')
    end

    TriggerEventNearby('laundry:closeMachine', playerId, 50.0, machine)
end)

RegisterNetEvent('laundry:closeMachineRequest')
AddEventHandler('laundry:closeMachineRequest', function(machineIndex)
    local playerId = source
    TriggerEventNearby('laundry:closeMachine', playerId, 50.0, machineIndex)
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

        payout = ((cashStackCount * 700) + (cashRollCount * 350) + (looseNotesCount * 50))

        exports['laundry']:addItem(playerId, 'cleanCash', payout)

        TriggerEventNearby('laundry:stopMoneyAnimation', playerId, 50.0, machine)

        TriggerClientEvent('laundry:showMessage', playerId, 'Washing finished. Total cash washed: ' .. payout .. '.')
        TriggerEventNearby('laundry:openMachine', playerId, 50.0, machine)
    else
        TriggerClientEvent('laundry:showMessage', playerId, 'You are missing something...')
    end
end)