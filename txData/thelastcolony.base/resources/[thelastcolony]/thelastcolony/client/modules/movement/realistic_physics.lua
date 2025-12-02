-- =====================================================
-- REALISTIC PHYSICS MODULE
-- =====================================================
-- Removes GTA V's automatic upright assistance when falling/rolling
-- Provides true ragdoll physics without hand-holding

local isRagdolling = false
local ragdollStartTime = 0

-- =====================================================
-- DISABLE AUTO-UPRIGHT ASSISTANCE
-- =====================================================

CreateThread(function()
    while true do
        local ped = PlayerPedId()

        -- Disable the automatic assistance that forces player upright
        SetPedCanRagdoll(ped, true)
        SetPedCanRagdollFromPlayerImpact(ped, true)

        -- Disable auto-recovery when falling/rolling
        -- This is the main setting that removes the "hand-holding"
        SetPedConfigFlag(ped, 32, false) -- Disable auto-upright when on back
        SetPedConfigFlag(ped, 104, false) -- Disable auto-recovery from ragdoll
        SetPedConfigFlag(ped, 166, false) -- Disable quick get-up animations

        -- Allow realistic ragdoll physics
        SetPedRagdollOnCollision(ped, true)
        SetPedRagdollForceFall(ped)

        Wait(1000) -- Check every second
    end
end)

-- =====================================================
-- ENHANCED RAGDOLL SYSTEM
-- =====================================================

-- Make ragdoll more realistic when taking damage
AddEventHandler('gameEventTriggered', function(name, args)
    if name == 'CEventNetworkEntityDamage' then
        local victim = args[1]
        local attacker = args[2]
        local isDead = args[4]

        if victim == PlayerPedId() and not isDead then
            local ped = PlayerPedId()
            local health = GetEntityHealth(ped)
            local maxHealth = GetEntityMaxHealth(ped)
            local healthPercent = (health / maxHealth) * 100

            -- If health is low, make ragdoll more likely and longer
            if healthPercent < 30 then
                -- Severely injured = harder to get up
                SetPedToRagdoll(ped, 3000, 3000, 0, false, false, false)
            elseif healthPercent < 60 then
                -- Moderately injured = medium ragdoll
                SetPedToRagdoll(ped, 1500, 1500, 0, false, false, false)
            end
        end
    end
end)

-- =====================================================
-- REALISTIC FALL DAMAGE
-- =====================================================

CreateThread(function()
    while true do
        local ped = PlayerPedId()

        if IsPedRagdoll(ped) then
            if not isRagdolling then
                isRagdolling = true
                ragdollStartTime = GetGameTimer()
            end
        else
            if isRagdolling then
                isRagdolling = false

                -- Calculate ragdoll duration
                local ragdollDuration = GetGameTimer() - ragdollStartTime

                -- If ragdolled for more than 2 seconds (hard fall), apply stun
                if ragdollDuration > 2000 then
                    -- Slow movement for a bit after hard fall
                    SetPedMoveRateOverride(ped, 0.7) -- 70% normal speed

                    -- Remove slowdown after 3 seconds
                    SetTimeout(3000, function()
                        SetPedMoveRateOverride(ped, 1.0)
                    end)
                end
            end
        end

        Wait(100)
    end
end)

-- =====================================================
-- DISABLE AUTO-AIM CORRECTION DURING MOVEMENT
-- =====================================================

CreateThread(function()
    while true do
        local ped = PlayerPedId()

        -- Disable aim assistance that auto-corrects your aim
        SetPlayerLockonRangeOverride(PlayerId(), 0.0) -- No auto-lock range

        -- Disable the magnetism effect when aiming near targets
        SetPedCanBeTargetted(ped, true)
        SetPedCanBeTargettedByPlayer(ped, PlayerId(), false)

        Wait(500)
    end
end)

-- =====================================================
-- REMOVE CAMERA AUTO-STABILIZATION
-- =====================================================

CreateThread(function()
    while true do
        -- Disable camera shake reduction (more realistic camera movement)
        ShakeGameplayCam('DRUNK_SHAKE', 0.0) -- Remove any artificial stabilization

        -- Disable automatic camera centering behind player
        DisableControlAction(0, 0, true) -- Camera center (V key by default)

        Wait(0)
    end
end)

-- =====================================================
-- REALISTIC WEAPON RECOIL (No Auto-Compensation)
-- =====================================================

CreateThread(function()
    while true do
        local ped = PlayerPedId()

        if IsPedArmed(ped, 7) then -- If holding a weapon
            -- Disable weapon recoil auto-compensation
            SetPedWeaponMovementClipset(ped, 'move_ped_crouched')

            -- Make weapon sway more realistic
            SetWeaponAnimationOverride(ped, 'Ballistic')
        end

        Wait(500)
    end
end)

print('^2[Realistic Physics]^7 Module loaded - Auto-assistance disabled')