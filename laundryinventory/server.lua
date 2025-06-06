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
            laundryDetergent = 0,
            fabricSoftener = 0, 
            cashStack = 0,
            cashRoll = 0,
            looseNotes = 0,
            greenPigment = 0, -- Special Item from house robberies that stops the money from getting bleached :)
            dirtyClothes = 0,
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

    local inventoryStr = json.encode(inventory)

    TriggerClientEvent('chat:addMessage', source, {
        args = {string.format('Inventory: %s', inventoryStr)}
    })
end, false)

RegisterNetEvent('laundryinventory:addItem')
AddEventHandler('laundryinventory:addItem', function(item, amount)
    local source = source
    addItem(source, item, amount)
end)

RegisterNetEvent('laundryinventory:removeItem')
AddEventHandler('laundryinventory:removeItem', function(item, amount)
    local source = source            
    return removeItem(source, item, amount)
end)

RegisterNetEvent('laundryinventory:hasItem')
AddEventHandler('laundryinventory:hasItem', function(item, amount)
    local source = source
    return hasItem(source, item, amount)
end)

RegisterNetEvent('laundryinventory:getInventory')
AddEventHandler('laundryinventory:getInventory', function()
    local source = source
    return getPlayerInventory(source)
end)

exports('getPlayerInventory', getPlayerInventory)
exports('addItem', addItem)
exports('removeItem', removeItem)
exports('hasItem', hasItem)
exports('getAmount', getAmount)