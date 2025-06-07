local playerInventories = {}

-- Using FiveM license instead of SteamID to avoid last time's issue <3
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
            cashStack = 2,
            cashRoll = 0,
            looseNotes = 0,
            greenPigment = 1, -- Special Item from house robberies that stops the money from getting bleached :)
            dirtyClothes = 1,
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
    return nil
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
        if amount == -1 then
            inventory[item] = 0
        else
            inventory[item] = inventory[item] - amount
        end
        return true
    end
    return false
end

local function hasItem(source, item, amount)
    local inventory = getPlayerInventory(source)
    return inventory[item] ~= nil and inventory[item] >= amount
end

RegisterCommand('giveitem', function(source, args)
    if source == 0 then return end

    local item = args[1]
    local amount = tonumber(args[2]) or 1
    
    if not item then
        TriggerClientEvent('chat:addMessage', source, {
            args = {'^1[Error] Usage: /giveitem itemname amount'}
        })
        return
    end
    
    if addItem(source, item, amount) then
        print(string.format('Gave %d %s to player %d', amount, item, source))
        TriggerClientEvent('chat:addMessage', source, {
            args = {string.format('^2[Success] Added %d %s to inventory', amount, item)}
        })
    else
        print(string.format('Invalid Item: %s', item))
        TriggerClientEvent('chat:addMessage', source, {
            args = {string.format('^1[Error] Invalid item: %s', item)}
        })
    end
end, false)

RegisterCommand('checkinventory', function(source, args)
    if source == 0 then return end

    local inventory = getPlayerInventory(source)

    TriggerClientEvent('chat:addMessage', source, {
        args = {'=== INVENTORY ==='}
    })
    
    for item, amount in pairs(inventory) do
        TriggerClientEvent('chat:addMessage', source, {
            args = {string.format('%s: %d', item, amount)}
        })
    end
end, false)

RegisterNetEvent('laundry:addItem')
AddEventHandler('laundry:addItem', function(item, amount)
    local source = source
    addItem(source, item, amount)
end)

RegisterNetEvent('laundry:removeItem')
AddEventHandler('laundry:removeItem', function(item, amount)
    local source = source            
    removeItem(source, item, amount)
end)

RegisterNetEvent('laundry:hasItem')
AddEventHandler('laundry:hasItem', function(item, amount)
    local source = source
    hasItem(source, item, amount)
end)

RegisterNetEvent('laundry:getInventory')
AddEventHandler('laundry:getInventory', function()
    local source = source
    getPlayerInventory(source)
end)

exports('getPlayerInventory', getPlayerInventory)
exports('addItem', addItem)
exports('removeItem', removeItem)
exports('hasItem', hasItem)
exports('getAmount', getAmount)