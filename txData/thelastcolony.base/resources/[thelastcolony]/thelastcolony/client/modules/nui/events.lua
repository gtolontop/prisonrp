--[[
    NUI Events
    Sends events FROM Lua TO React UI
    Triggered by server or client events

    NOTE: Inventory events are handled in client/modules/inventory/main.lua
    to avoid duplicate handlers
]]

-- ============================================
-- INVENTORY EVENTS - REMOVED (handled in inventory/main.lua)
-- ============================================

-- Inventory events moved to client/modules/inventory/main.lua to prevent duplicates

-- ============================================
-- LOOT CONTAINER EVENTS
-- ============================================

-- Open loot container UI
RegisterNetEvent('loot:openContainer', function(container)
    SetNuiFocus(true, true)
    SendNUIMessage({
        type = 'openLootContainer',
        data = container
    })
end)

-- Close loot container
RegisterNetEvent('loot:closeContainer', function()
    SendNUIMessage({
        type = 'closeLootContainer'
    })
end)

-- Update container contents
RegisterNetEvent('loot:updateContainer', function(container)
    SendNUIMessage({
        type = 'updateLootContainer',
        data = container
    })
end)

-- ============================================
-- STORAGE EVENTS
-- ============================================

-- Open storage UI (personal or guild)
RegisterNetEvent('storage:open', function(storageType, container)
    SetNuiFocus(true, true)
    SendNUIMessage({
        type = 'openStorage',
        data = {
            type = storageType,
            container = container
        }
    })
end)

-- Close storage
RegisterNetEvent('storage:close', function()
    SetNuiFocus(false, false)
    SendNUIMessage({
        type = 'closeStorage'
    })
end)

-- ============================================
-- NOTIFICATION EVENTS
-- ============================================

-- Show notification
RegisterNetEvent('notify', function(notifType, message, duration)
    SendNUIMessage({
        type = 'showNotification',
        data = {
            type = notifType or 'info',
            message = message,
            duration = duration or 3000
        }
    })
end)

-- ============================================
-- HEALTH & STATUS EVENTS
-- ============================================

-- Update player health
RegisterNetEvent('player:updateHealth', function(healthData)
    SendNUIMessage({
        type = 'updateHealth',
        data = healthData
    })
end)

-- Update player weight
RegisterNetEvent('player:updateWeight', function(currentWeight, maxWeight)
    SendNUIMessage({
        type = 'updateWeight',
        data = {
            current_weight = currentWeight,
            max_weight = maxWeight,
            overweight = currentWeight > maxWeight
        }
    })
end)

-- ============================================
-- DEATH SCREEN EVENTS
-- ============================================

-- Show death screen
RegisterNetEvent('player:death', function(deathInfo)
    SetNuiFocus(true, true)
    SendNUIMessage({
        type = 'showDeathScreen',
        data = deathInfo
    })
end)

-- Hide death screen (respawn)
RegisterNetEvent('player:respawn', function()
    SetNuiFocus(false, false)
    SendNUIMessage({
        type = 'hideDeathScreen'
    })
end)

-- ============================================
-- EXTRACTION EVENTS
-- ============================================

-- Update extraction points
RegisterNetEvent('extraction:updatePoints', function(extractionPoints)
    SendNUIMessage({
        type = 'updateExtractionPoints',
        data = extractionPoints
    })
end)

-- ============================================
-- ACTION EVENTS (Progress bars)
-- ============================================

-- Start action (healing, looting, etc.)
RegisterNetEvent('player:startAction', function(action, duration, cancelable)
    SendNUIMessage({
        type = 'startAction',
        data = {
            action = action,
            duration = duration,
            cancelable = cancelable or true
        }
    })
end)

-- Cancel action
RegisterNetEvent('player:cancelAction', function()
    SendNUIMessage({
        type = 'cancelAction'
    })
end)

-- Update action progress
RegisterNetEvent('player:updateActionProgress', function(progress, timeRemaining)
    SendNUIMessage({
        type = 'updateActionProgress',
        data = {
            progress = progress,
            time_remaining = timeRemaining
        }
    })
end)

print('[NUI] Events registered successfully')
