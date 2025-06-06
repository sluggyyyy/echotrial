local washingMachines = {
    {x = 1120.27, y = -3220.05, z = 4.5}
}

function IsNearWashingMachine()
    local playerCoords = GetEntityCoords(PlayerPedId())
    
    for i = 1, #washingMachines do
        local machine = washingMachines[i]
        
        local distance = GetDistanceBetweenCoords(playerCoords.x, playerCoords.y, playerCoords.z, machine.x, machine.y, machine.z, true)
        
        if distance < 2.0 then
            return true
        end
    end
    
    return false
end

CreateThread(function()
    Wait(1000)

    local model = GetHashKey('prop_washer_02')
    RequestModel(model)

    while not HasModelLoaded(model) do
        Wait(100)
    end

    local washingMachine = CreateObject(model, 1120.27, -3220.05, 4.5, false, false, false)

    FreezeEntityPosition(washingMachine, true)

    SetEntityAsMissionEntity(washingMachine, true, true)
end)

CreateThread(function()
    while true do
        Wait(0)
        
        if IsNearWashingMachine() then
            SetTextComponentFormat("STRING")
            AddTextComponentString("Press E to use washing machine")
            DisplayHelpTextFromStringLabel(0, 0, 1, -1)
            
            if IsControlJustReleased(0, 38) then
                TriggerServerEvent('laundryinventory:getInventory')
                
                Wait(100)
                
                TriggerServerEvent('laundry:processInteraction')
            end
        else
            Wait(1000)
        end
    end
end)

RegisterNetEvent('laundryinteraction:showMessage')
AddEventHandler('laundryinteraction:showMessage', function(message)
    TriggerEvent('chat:addMessage', {
        args = {message}
    })
end)