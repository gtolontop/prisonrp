--[[
    The Last Colony - Immersive Death System
    Handles realistic ragdoll physics on death instead of static animations

    STRATEGY: Instead of fighting GTA's death system, we intercept the death
    and keep the player barely alive (health = 1) to prevent the death animation,
    then manually apply ragdoll physics.
]]

local isDead = false
local deathTime = 0
local ragdollDuration = 15000 -- 15 seconds of ragdoll before freezing the corpse
local isInIncapacitatedState = false
local isRespawning = false -- Flag to prevent death detection during respawn
local hasSpawnedOnce = false -- Flag to prevent death detection on initial spawn

-- ============================================
-- INITIAL SPAWN PROTECTION
-- ============================================

-- Wait for player to spawn and stabilize before enabling death detection
CreateThread(function()
    Wait(5000) -- Wait 5 seconds after resource start

    local ped = PlayerPedId()
    local health = GetEntityHealth(ped)

    -- If health is low on spawn, restore it
    if health < 150 then
        SetEntityHealth(ped, 200)
        print('^2[Death]^0 Player health restored on spawn')
    end

    -- Enable death detection after spawn stabilization
    hasSpawnedOnce = true
    print('^2[Death]^0 Death detection enabled')
end)

-- Listen for ox_core character load event
AddEventHandler('ox:playerLoaded', function()
    print('^2[Death]^0 Character loading - applying spawn protection...')

    -- CRITICAL: Disable death detection during spawn
    hasSpawnedOnce = false
    isDead = false
    isInIncapacitatedState = false
    isRespawning = true -- Prevent death detection during spawn

    Wait(500) -- Wait for ped to fully spawn

    local ped = PlayerPedId()

    -- Force restore health multiple times to ensure it sticks
    for _ = 1, 3 do
        SetEntityHealth(ped, 200)
        Wait(100)
    end

    -- Clear any damage/ragdoll from spawn
    ClearPedBloodDamage(ped)
    ClearPedTasksImmediately(ped)

    Wait(1000) -- Additional safety delay

    -- Verify health is correct before enabling death detection
    local finalHealth = GetEntityHealth(ped)
    if finalHealth < 150 then
        SetEntityHealth(ped, 200)
        print('^3[Death]^0 WARNING: Health was low after spawn, corrected to 200')
    end

    -- NOW enable death detection
    hasSpawnedOnce = true
    isRespawning = false

    print('^2[Death]^0 Character loaded - death detection enabled (Health: ' .. GetEntityHealth(ped) .. ')')
end)

-- Listen for forced respawn after reconnect (server tells us we were dead)
RegisterNetEvent('tlc:forceRespawnAfterReconnect', function()
    print('^3[Death]^0 Server says we died before disconnect - forcing respawn')

    local ped = PlayerPedId()

    -- Mark as alive immediately
    hasSpawnedOnce = true
    isDead = false
    isInIncapacitatedState = false
    isRespawning = false

    -- Restore health
    SetEntityHealth(ped, 200)

    -- Find closest hospital and teleport there
    local currentCoords = GetEntityCoords(ped)
    local closestHospital = Config.GetClosestRespawnPoint(currentCoords, "hospital")

    if closestHospital then
        -- Fade out
        DoScreenFadeOut(500)
        Wait(500)

        -- Teleport to hospital
        SetEntityCoords(ped, closestHospital.coords.x, closestHospital.coords.y, closestHospital.coords.z, false, false, false, false)
        SetEntityHeading(ped, closestHospital.coords.w)

        Wait(500)

        -- Fade in
        DoScreenFadeIn(500)

        lib.notify({
            title = 'Respawned',
            description = 'You woke up at ' .. closestHospital.name,
            type = 'info',
            duration = 5000
        })

        print('^2[Death]^0 Forced respawn completed at ' .. closestHospital.name)

        -- Notify server that respawn is complete
        TriggerServerEvent('tlc:serverPlayerRespawned')
    else
        print('^1[Death]^0 ERROR: No hospital found for forced respawn!')
    end
end)

-- ============================================
-- DISABLE AUTO-RESPAWN (spawnmanager)
-- ============================================

-- Disable FiveM's default auto-respawn system (if spawnmanager exists)
CreateThread(function()
    Wait(1000)
    if GetResourceState('spawnmanager') == 'started' then
        exports.spawnmanager:setAutoSpawn(false)
        print('^3[Death]^0 Auto-respawn disabled (manual respawn only)')
    end
end)

-- ============================================
-- RAGDOLL FUNCTIONS
-- ============================================

--- Enable ragdoll on the player with realistic physics
--- @param duration number Duration in milliseconds (0 = infinite until manually disabled)
local function EnableRagdoll(duration)
    local ped = PlayerPedId()

    -- CRITICAL: Clear any death animations first
    ClearPedTasksImmediately(ped)
    ClearPedSecondaryTask(ped)

    -- Disable default death animations
    SetPedConfigFlag(ped, 166, false) -- Disable getting up animation
    SetPedConfigFlag(ped, 186, false) -- Disable death writhe animation
    SetPedConfigFlag(ped, 187, false) -- Disable death animation

    -- Force ragdoll to override death animation
    SetPedToRagdoll(ped, duration or 10000, duration or 10000, 0, false, false, false)

    -- Make the ragdoll persist
    SetPedCanRagdoll(ped, true)
end

--- Freeze the corpse in place (after ragdoll has settled)
local function FreezeCorpse()
    local ped = PlayerPedId()

    -- Stop any remaining ragdoll
    SetPedToRagdoll(ped, 0, 0, 0, false, false, false)

    -- Freeze the entity in its final position
    FreezeEntityPosition(ped, true)

    -- Disable all ped tasks
    ClearPedTasksImmediately(ped)
end

--- Unfreeze and disable ragdoll (on respawn)
local function DisableRagdoll()
    local ped = PlayerPedId()

    -- Unfreeze
    FreezeEntityPosition(ped, false)

    -- Re-enable normal ped behavior
    SetPedCanRagdoll(ped, true)
    SetPedConfigFlag(ped, 166, true) -- Re-enable getting up animation

    -- Clear any tasks
    ClearPedTasksImmediately(ped)
end

-- ============================================
-- INTERCEPT DEATH & PREVENT DEATH ANIMATION
-- ============================================

-- Main death detection and interception thread
CreateThread(function()
    while true do
        Wait(0) -- Must be 0 to intercept death in time

        -- Skip death detection if respawning or not spawned yet
        if not isRespawning and hasSpawnedOnce then
            local ped = PlayerPedId()
            local health = GetEntityHealth(ped)

            -- Intercept the moment health hits 0 (death trigger)
            if health <= 100 and not isDead then
                -- Player is about to die or just died
                isDead = true
                isInIncapacitatedState = true
                deathTime = GetGameTimer()

                -- CRITICAL: Keep player barely alive to prevent death animation
                SetEntityHealth(ped, 1)

                -- Apply instant ragdoll
                SetPedToRagdoll(ped, ragdollDuration, ragdollDuration, 0, false, false, false)

                -- Trigger death event
                TriggerEvent('tlc:onPlayerDeath')
                TriggerServerEvent('tlc:serverPlayerDied')

                print('^3[Death]^0 Player incapacitated - Ragdoll active')
            end

            -- If in incapacitated state, maintain health at 1
            if isDead and isInIncapacitatedState then
                if health > 1 or health == 0 then
                    SetEntityHealth(ped, 1) -- Keep barely alive
                end
            end
        else
            -- During respawn or initial spawn, allow health changes
            Wait(100)
        end
    end
end)

-- ============================================
-- RAGDOLL MAINTENANCE THREAD
-- ============================================

CreateThread(function()
    local corpseIsFrozen = false

    while true do
        Wait(100)

        -- NEVER run maintenance during respawn
        if isDead and isInIncapacitatedState and not isRespawning then
            local ped = PlayerPedId()
            local timeSinceDeath = GetGameTimer() - deathTime

            if timeSinceDeath >= ragdollDuration then
                if not corpseIsFrozen then
                    -- Freeze the corpse after ragdoll duration
                    FreezeEntityPosition(ped, true)
                    corpseIsFrozen = true
                    print('^3[Death]^0 Corpse frozen in final position')
                end
            else
                corpseIsFrozen = false
                -- Re-apply ragdoll if it stops (player movement attempts, etc.)
                if not IsPedRagdoll(ped) then
                    SetPedToRagdoll(ped, ragdollDuration - timeSinceDeath, ragdollDuration - timeSinceDeath, 0, false, false, false)
                end
            end
        else
            corpseIsFrozen = false
            Wait(500)
        end
    end
end)

-- ============================================
-- DEATH UI THREAD (Optional - disable health regen, etc.)
-- ============================================

CreateThread(function()
    while true do
        Wait(0)

        if isDead and not isRespawning then
            -- Disable controls while dead (prevent movement attempts)
            DisableAllControlActions(0)
            EnableControlAction(0, 1, true)   -- Look left/right (camera)
            EnableControlAction(0, 2, true)   -- Look up/down (camera)
            EnableControlAction(0, 245, true) -- Chat
            EnableControlAction(0, 200, true) -- Pause menu (ESC)
            EnableControlAction(0, 199, true) -- Pause menu alternative

            -- Optional: Display death screen text
            -- You can add a NUI death screen here if needed
        else
            Wait(500) -- Not dead, check less frequently
        end
    end
end)

-- ============================================
-- RESPAWN SYSTEM
-- ============================================

-- Manual respawn function (prevents re-death loop)
local function RespawnPlayer()
    local ped = PlayerPedId()

    print('^3[Death]^0 Starting respawn process...')

    -- CRITICAL: Reset death flags FIRST (before any other action)
    isDead = false
    isInIncapacitatedState = false
    deathTime = 0
    isRespawning = true

    -- Find closest hospital
    local currentCoords = GetEntityCoords(ped)
    local closestHospital = Config.GetClosestRespawnPoint(currentCoords, "hospital")

    if not closestHospital then
        print('^1[Death]^0 ERROR: No respawn point found!')
        isRespawning = false
        return
    end

    -- Fade out screen
    DoScreenFadeOut(500)
    Wait(500)

    -- Unfreeze and clear ragdoll BEFORE restoring health
    FreezeEntityPosition(ped, false)
    SetPedCanRagdoll(ped, true)
    ClearPedTasksImmediately(ped)
    ClearPedTasks(ped)

    -- Restore health BEFORE teleport (critical!)
    SetEntityHealth(ped, 200)
    ClearPedBloodDamage(ped)

    Wait(200)

    -- Teleport to hospital
    SetEntityCoords(ped, closestHospital.coords.x, closestHospital.coords.y, closestHospital.coords.z, false, false, false, false)
    SetEntityHeading(ped, closestHospital.coords.w)

    -- Ensure player is properly revived
    SetEntityInvincible(ped, false)
    SetPlayerControl(PlayerId(), true, 0)

    -- Double-check health is still 200
    Wait(300)
    if GetEntityHealth(ped) < 200 then
        SetEntityHealth(ped, 200)
        print('^2[Death]^0 Health corrected to 200')
    end

    -- Wait for teleport to complete
    Wait(500)

    -- Fade in screen
    DoScreenFadeIn(500)
    Wait(500)

    -- Clear respawning flag LAST
    isRespawning = false

    -- Notification
    lib.notify({
        title = 'Respawn',
        description = 'You woke up at ' .. closestHospital.name,
        type = 'info',
        duration = 5000
    })

    -- Trigger respawn event
    TriggerEvent('tlc:onPlayerRespawn')

    -- Notify server that player respawned (mark as alive in DB)
    TriggerServerEvent('tlc:serverPlayerRespawned')

    print('^2[Death]^0 Player respawned at ' .. closestHospital.name .. ' - Health: ' .. GetEntityHealth(ped))
end

-- Listen for respawn request (from death screen UI, admin command, etc.)
RegisterNetEvent('tlc:respawn', function()
    if isDead then
        RespawnPlayer()
    end
end)

-- Temp: Auto-respawn after 10 seconds (for testing)
CreateThread(function()
    while true do
        Wait(1000)

        if isDead then
            local timeSinceDeath = GetGameTimer() - deathTime
            if timeSinceDeath >= 10000 then -- 10 seconds
                RespawnPlayer()
                print('^2[Death]^0 Auto-respawn after 10s (temp for testing)')
            end
        end
    end
end)

-- ============================================
-- EXPORTS
-- ============================================

--- Check if the player is currently dead
--- @return boolean
exports('IsDead', function()
    return isDead
end)

--- Force respawn the player (admin command, etc.)
exports('ForceRespawn', function()
    if isDead then
        RespawnPlayer()
    end
end)

print('^2[Death]^0 Immersive death system loaded')
