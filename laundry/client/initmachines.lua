local washingMachines = {
    {x = 1120.27, y = -3230.05, z = 4.7, heading = 0.0},
    {x = 1122.27, y = -3230.05, z = 4.7, heading = 0.0}
}

local spawnedMachines = {}
local spawnedMoney = {}
local machineStates = {}
local dirtyClothesTimerThread = nil
local nearMachine = false
local currentMachineIndex = nil
local moneyAnimationThreads = {}

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

    local moneyObject = GetHashKey('ex_cash_pile_02')
    RequestModel(moneyObject)

    local attempts = 0
    while (not HasModelLoaded(closedWasher) or not HasModelLoaded(openWasher) or not HasModelLoaded(moneyObject)) and attempts < 50 do
        Wait(100)
        attempts = attempts + 1
    end
    
    if HasModelLoaded(closedWasher) and HasModelLoaded(openWasher) then
        print("Custom washing machine model loaded successfully")
        for i = 1, #washingMachines do
            local pos = washingMachines[i]
            local washingMachine = CreateObject(openWasher, pos.x, pos.y, pos.z, false, false, false)
            PlaceObjectOnGroundProperly(washingMachine)
            local moneyPile = CreateObject(moneyObject, pos.x, pos.y - 0.005, (pos.z + 0.45))
            Wait(100)
            local finalCoords = GetEntityCoords(washingMachine)
            local finalHeading = GetEntityHeading(washingMachine)
            washingMachines[i] = {x = finalCoords.x, y = finalCoords.y, z = finalCoords.z, heading = finalHeading}
            FreezeEntityPosition(washingMachine, true)
            SetEntityAsMissionEntity(washingMachine, true, true)
            SetEntityVisible(moneyPile, false, false)
            table.insert(spawnedMachines, washingMachine)
            table.insert(spawnedMoney, moneyPile)
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
        local newMachine = CreateObject(GetHashKey('washing_closed'), pos.x, pos.y, pos.z, false, false, false)
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
        local newMachine = CreateObject(GetHashKey('washing_open'), pos.x, pos.y, pos.z, false, false, false)
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

RegisterNetEvent('laundry:startMoneyAnimation')
AddEventHandler('laundry:startMoneyAnimation', function(machineIndex)
    if moneyAnimationThreads[machineIndex] then return end
    
    local moneyPile = spawnedMoney[machineIndex]
    if not DoesEntityExist(moneyPile) then return end
    
    SetEntityVisible(moneyPile, true, false)
    
    moneyAnimationThreads[machineIndex] = CreateThread(function()
        local time = 0
        while machineStates[machineIndex].inUse and DoesEntityExist(moneyPile) do
            local pitchAngle = math.cos(time * 0.015) * 10
            SetEntityRotation(moneyPile, 0, pitchAngle, 0, 2, true)
            time = time + 1
            Wait(5)
        end
        machineStates[machineIndex].inUse = false
        SetEntityVisible(moneyPile, false, false)
        SetEntityRotation(moneyPile, 0, 0, 0, 2, true)
        moneyAnimationThreads[machineIndex] = nil
    end)
end)


RegisterNetEvent('laundry:stopMoneyAnimation')
AddEventHandler('laundry:stopMoneyAnimation', function(machineIndex)
    if machineStates[machineIndex] then
        machineStates[machineIndex].inUse = false
        print("Stopping money animation for machine", machineIndex)
    end
end)

RegisterNetEvent('laundry:showMessage')
AddEventHandler('laundry:showMessage', function(message, machineIndex)
    TriggerEvent('chat:addMessage', {
        args = {message}
    })
    
    print("Message received:", message, "Machine Index:", machineIndex)
    
    local targetMachine = machineIndex or currentMachineIndex
    
    if targetMachine and machineStates[targetMachine] then
        if string.find(message, "Washing starting") then
            print("Starting washing animation for machine", targetMachine)
            machineStates[targetMachine].inUse = true
            StartMoneyAnimation(targetMachine)
        elseif string.find(message, "Washing finished") then
            machineStates[targetMachine].inUse = false
        end
    else
        print("No machine index or invalid machine state")
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        for i = 1, #spawnedMachines do
            if DoesEntityExist(spawnedMachines[i]) then
                DeleteEntity(spawnedMachines[i])
            end
        end

        for i = 1, #spawnedMoney do
            if DoesEntityExist(spawnedMoney[i]) then
                DeleteEntity(spawnedMoney[i])
            end
        end
        print("Cleaned up washing machines and money")
    end
end)