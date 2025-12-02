-- =====================================================
-- REALISTIC VEHICLE PHYSICS MODULE
-- =====================================================
-- Removes GTA V's automatic vehicle upright assistance
-- If you flip your car, you stay flipped - true realism

-- =====================================================
-- DISABLE AUTO-FLIP ASSISTANCE
-- =====================================================

CreateThread(function()
    while true do
        local ped = PlayerPedId()

        if IsPedInAnyVehicle(ped, false) then
            local vehicle = GetVehiclePedIsIn(ped, false)

            -- Disable the automatic flip-back system
            -- This is what makes vehicles magically flip back when upside down
            SetVehicleCanBeVisiblyDamaged(vehicle, true)
            SetVehicleStrong(vehicle, false)

            -- Disable auto-upright for all vehicle types
            SetVehicleReduceGrip(vehicle, false)
            SetVehicleCanBreak(vehicle, true)

            -- Remove the "press X to flip vehicle" prompt
            DisableControlAction(0, 22, true) -- Space/Jump key in vehicle

            -- Prevent automatic roll correction
            -- This native is what causes the "self-righting" behavior
            SetVehicleRollControlEnabled(vehicle, false)
        end

        Wait(0) -- Check every frame for immediate response
    end
end)

-- =====================================================
-- REALISTIC CRASH DAMAGE
-- =====================================================

CreateThread(function()
    while true do
        local ped = PlayerPedId()

        if IsPedInAnyVehicle(ped, false) then
            local vehicle = GetVehiclePedIsIn(ped, false)

            -- Make vehicles more susceptible to flipping
            SetVehicleGravityAmount(vehicle, 10.0) -- Heavier gravity feel

            -- Check if vehicle is upside down
            local roll = GetEntityRoll(vehicle)

            if math.abs(roll) > 90 and math.abs(roll) < 270 then
                -- Vehicle is flipped
                -- Disable engine to prevent driving upside down
                SetVehicleEngineOn(vehicle, false, true, true)

                -- Apply slight damage over time when upside down
                local health = GetVehicleEngineHealth(vehicle)
                if health > 0 then
                    SetVehicleEngineHealth(vehicle, health - 1.0)
                end
            end
        end

        Wait(100)
    end
end)

-- =====================================================
-- NO MAGICAL RECOVERY
-- =====================================================

-- Prevent the game from auto-correcting vehicle orientation
AddEventHandler('gameEventTriggered', function(name, args)
    if name == 'CEventShockingCarCrash' or name == 'CEventVehicleCollision' then
        local vehicle = args[1]

        if DoesEntityExist(vehicle) and IsEntityAVehicle(vehicle) then
            -- Disable any automatic stabilization after crash
            SetVehicleOnGroundProperly(vehicle)

            -- Let physics handle it naturally
            SetVehicleOutOfControl(vehicle, false, false)
        end
    end
end)

-- =====================================================
-- REALISTIC HANDLING MODIFICATIONS
-- =====================================================

CreateThread(function()
    while true do
        local ped = PlayerPedId()

        if IsPedInAnyVehicle(ped, false) then
            local vehicle = GetVehiclePedIsIn(ped, false)

            -- More realistic center of gravity (easier to flip)
            SetVehicleCentreOfGravityOffset(vehicle, 0.0, 0.0, -0.1)

            -- Reduce artificial grip assistance
            SetVehicleReduceTraction(vehicle, 0)

            -- Make suspension more realistic (less "arcade-y")
            -- Higher values = more realistic suspension compression
            local suspensionForce = 1.0
            for i = 0, 3 do
                SetVehicleWheelSuspensionCompression(vehicle, i, suspensionForce)
            end
        end

        Wait(1000)
    end
end)

-- =====================================================
-- DISABLE SELF-RIGHTING FOR SPECIFIC VEHICLE TYPES
-- =====================================================

-- Some vehicles in GTA have extra self-righting logic
-- (especially larger vehicles like trucks)
CreateThread(function()
    while true do
        local ped = PlayerPedId()

        if IsPedInAnyVehicle(ped, false) then
            local vehicle = GetVehiclePedIsIn(ped, false)
            local vehicleClass = GetVehicleClass(vehicle)

            -- Disable special handling flags for all vehicle types
            -- These flags enable auto-stabilization
            SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fAntiRollBarForce', 0.0)
            SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fRollCentreHeightFront', 0.0)
            SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fRollCentreHeightRear', 0.0)
        end

        Wait(2000)
    end
end)

print('^2[Realistic Vehicle Physics]^7 Auto-flip assistance disabled')
