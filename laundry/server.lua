RegisterNetEvent('laundry:processInteraction')
AddEventHandler('laundry:processInteraction', function()
    local playerId = source

    local hasIngredients = exports['laundryinventory']:hasItem(playerId, 'laundryDetergent', 1) and exports['laundryinventory']:hasItem(playerId, 'fabricSoftener', 1) and exports['laundryinventory']:hasItem(playerId, 'greenPigment', 1)
    local hasDirtyMoney = exports['laundryinventory']:hasItem(playerId, 'cashStack', 1) or exports['laundryinventory']:hasItem(playerId, 'cashRoll', 1) or exports['laundryinventory']:hasItem(playerId, 'looseNotes', 1)

    if hasDirtyMoney and hasIngredients then

        local cashStackCount = exports['laundryinventory']:getAmount(playerId, 'cashStack')
        local cashRollCount = exports['laundryinventory']:getAmount(playerId, 'cashStack')
        local looseNotesCount = exports['laundryinventory']:getAmount(playerId, 'cashStack')

        local totalCount = cashStackCount + cashRollCount + looseNotesCount

        exports['laundryinventory']:removeItem(playerId, 'cashStack', cashStackCount)
        exports['laundryinventory']:removeItem(playerId, 'cashRoll', cashRollCount)
        exports['laundryinventory']:removeItem(playerId, 'looseNotes', looseNotesCount)

        exports['laundryinventory']:removeItem(playerId, 'laundryDetergent', 1)
        exports['laundryinventory']:removeItem(playerId, 'fabricSoftener', 1)
        exports['laundryinventory']:removeItem(playerId, 'greenPigment', 1)

        TriggerClientEvent('laundryinteraction:showMessage', playerId, 'Washing started. Please wait...')

        Wait(totalCount * 6000)

        payout = ((cashStackCount * 675) + (cashRollCount * 325) + (looseNotesCount * 80))

        exports['laundryinventory']:addItem(playerId, 'cleanCash', payout)

        TriggerClientEvent('laundryinteraction:showMessage', playerId, 'Washing finished. Total cash washed: ' .. payout .. '.')
    else
        TriggerClientEvent('laundryinteraction:showMessage', playerId, 'You are missing something...')
    end
end)

