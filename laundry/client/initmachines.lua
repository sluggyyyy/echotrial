local washingMachines = {
    {x = 1120.27, y = -3230.05, z = 4.7},
    {x = 1122.27, y = -3230.05, z = 4.7}
}

local spawnedMachines = {}
local machineStates = {}
local dirtyClothesTimerThread = nil
local nearMachine = false
local currentMachineIndex = nil

function GetNearestWashingMachine()
    local playerCoords = GetEntityCoords(PlayerPedId())
    
    for i = 1, #washingMachines do
        local machine = washingMachines[i]
        local distance = GetDistanceBetweenCoords(playerCoords.x, playerCoords.y, playerCoords.z, machine.x, machine.y, machine.z, true)
        
        if distance < 2.0 then
            return i
        end
    end
    return nil
end

function InitializeMachineStates()
    for i = 1, #washingMachines do
        machineStates[i] = {
            inUse = false,
            dirtyClothesInside = nil
        }
    end
end

CreateThread(function()
    Wait(1000)
    
    InitializeMachineStates()

    local closedWasher = GetHashKey('washing_closed')
    RequestModel(closedWasher)

    local openWasher = GetHashKey('washing_open')
    RequestModel(openWasher)

    local attempts = 0
    while not HasModelLoaded(closedWasher) and attempts < 50 do
        Wait(100)
        attempts = attempts + 1
    end
    
    if HasModelLoaded(closedWasher) then
        print("Custom washing machine model loaded successfully")
        for i = 1, #washingMachines do
            local pos = washingMachines[i]
            local washingMachine = CreateObject(openWasher, pos.x, pos.y, pos.z, false, false, false)
            PlaceObjectOnGroundProperly(washingMachine)
            Wait(100)
            local coords = GetEntityCoords(washingMachine)
            local heading = GetEntityHeading(washingMachine)
            washingMachines[i] = {x = coords.x, y = coords.y, z = coords.z, heading = heading}
            FreezeEntityPosition(washingMachine, true)
            SetEntityAsMissionEntity(washingMachine, true, true)
            table.insert(spawnedMachines, washingMachine)
        end
        print("Washing machines spawned at coordinates")
    else
        print("Failed to load custom washing machine model")
    end
end)

CreateThread(function()
    while true do
        Wait(0)
        currentMachineIndex = GetNearestWashingMachine()
        
        if currentMachineIndex then
            local machine = machineStates[currentMachineIndex]
            if not machine.inUse then
                SetTextComponentFormat("STRING")
                AddTextComponentString("Press E to add ingredients and start washing.")
                DisplayHelpTextFromStringLabel(0, 0, 1, -1)

                if IsControlJustReleased(0, 38) and not dirtyClothesTimerThread then
                    TriggerServerEvent('laundry:getInventory')
                    TriggerServerEvent('laundry:processCash', currentMachineIndex)
                end
            else
                SetTextComponentFormat("STRING")
                AddTextComponentString("Washing machine is busy...")
                DisplayHelpTextFromStringLabel(0, 0, 1, -1)
            end
        end
    end
end)

RegisterNetEvent('laundry:closeMachine')
AddEventHandler('laundry:closeMachine', function(machineIndex)
    if DoesEntityExist(spawnedMachines[machineIndex]) then
        local pos = washingMachines[machineIndex]
        DeleteEntity(spawnedMachines[machineIndex])
        local newMachine = CreateObject(GetHashKey('washing_closed'), 0, 0, 0, false, false, false)
        SetEntityCoordsNoOffset(newMachine, pos.x, pos.y, pos.z, false, false, false)
        SetEntityHeading(newMachine, pos.heading)
        FreezeEntityPosition(newMachine, true)
        SetEntityAsMissionEntity(newMachine, true, true)
        spawnedMachines[machineIndex] = newMachine
    end
end)

RegisterNetEvent('laundry:openMachine')
AddEventHandler('laundry:openMachine', function(machineIndex)
    if DoesEntityExist(spawnedMachines[machineIndex]) then
        local pos = washingMachines[machineIndex]
        DeleteEntity(spawnedMachines[machineIndex])
        local newMachine = CreateObject(GetHashKey('washing_open'), 0, 0, 0, false, false, false)
        SetEntityCoords(newMachine, pos.x, pos.y, pos.z, false, false, false, false)
        SetEntityHeading(newMachine, pos.heading)
        FreezeEntityPosition(newMachine, true)
        SetEntityAsMissionEntity(newMachine, true, true)
        spawnedMachines[machineIndex] = newMachine
    end
end)

RegisterNetEvent('laundry:startDirtyClothesPhase')
AddEventHandler('laundry:startDirtyClothesPhase', function(machineIndex)
    dirtyClothesTimerThread = CreateThread(function()
        local startTime = GetGameTimer()
        local duration = 10000
        local showingDirtyClothesPrompt = true
        while (GetGameTimer() - startTime) < duration and showingDirtyClothesPrompt do
            Wait(0)
            if GetNearestWashingMachine() == machineIndex then
                SetTextComponentFormat("STRING")
                AddTextComponentString("Press E to add dirty clothes")
                DisplayHelpTextFromStringLabel(0, 0, 1, -1)

                if IsControlJustReleased(0, 38) then
                    TriggerServerEvent('laundry:processDirtyClothes', machineIndex)
                    showingDirtyClothesPrompt = false
                end
            end
        end
        TriggerServerEvent('laundry:closeMachineRequest', machineIndex)
        dirtyClothesTimerThread = nil
    end)
end)

RegisterNetEvent('laundry:showMessage')
AddEventHandler('laundry:showMessage', function(message, machineIndex)
    TriggerEvent('chat:addMessage', {
        args = {message}
    })
    
    if machineIndex and machineStates[machineIndex] then
        if string.find(message, "Washing starting") then
            machineStates[machineIndex].inUse = true
        elseif string.find(message, "Washing finished") then
            machineStates[machineIndex].inUse = false
        end
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        for i = 1, #spawnedMachines do
            if DoesEntityExist(spawnedMachines[i]) then
                DeleteEntity(spawnedMachines[i])
            end
        end
        print("Cleaned up washing machines")
    end
end)