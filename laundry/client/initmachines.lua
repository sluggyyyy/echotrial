local washingMachines = {
    {x = 1120.27, y = -3220.05, z = 6.5}
}

local machineInUse = false
local dirtyClothesInside = nil
local dirtyClothesTimerThread = nil
local nearMachine = false
local lastNearState = false

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
        nearMachine = IsNearWashingMachine()
        
        if nearMachine then
            if not machineInUse then
                SetTextComponentFormat("STRING")
                AddTextComponentString("Press E to add ingredients and start washing.")
                DisplayHelpTextFromStringLabel(0, 0, 1, -1)

                if IsControlJustReleased(0, 38) and not dirtyClothesTimerThread then
                    TriggerServerEvent('laundry:getInventory')
                    TriggerServerEvent('laundry:processCash')

                    dirtyClothesTimerThread = CreateThread(function()
                        local startTime = GetGameTimer()
                        local duration = 10000
                        local showingDirtyClothesPrompt = true
                        while (GetGameTimer() - startTime) < duration and showingDirtyClothesPrompt do
                            Wait(0)
                            if nearMachine then
                                SetTextComponentFormat("STRING")
                                AddTextComponentString("Press E to add dirty clothes")
                                DisplayHelpTextFromStringLabel(0, 0, 1, -1)

                                if IsControlJustReleased(0, 38) then
                                    TriggerServerEvent('laundry:processDirtyClothes')
                                    showingDirtyClothesPrompt = false
                                end
                            end
                        end
                        dirtyClothesTimerThread = nil
                    end)
                end
            else
                SetTextComponentFormat("STRING")
                AddTextComponentString("Washing machine is busy...")
                DisplayHelpTextFromStringLabel(0, 0, 1, -1)
            end
        end
    end
end)

RegisterNetEvent('laundry:showMessage')
AddEventHandler('laundry:showMessage', function(message)
    TriggerEvent('chat:addMessage', {
        args = {message}
    })
    
    if string.find(message, "Washing starting") then
        machineInUse = true
    elseif string.find(message, "Washing finished") then
        machineInUse = false
    end
end)