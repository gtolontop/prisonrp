--[[
    NUI Callbacks
    Registers all callbacks from React UI to Lua client
    ALL events are validated server-side for anti-cheat
]]

local ox = require '@ox_core/lib/init'
local Animations = require 'shared.animations'

-- ============================================
-- INVENTORY CALLBACKS
-- ============================================

-- Move item from one location to another
RegisterNUICallback('moveItem', function(data, cb)
    -- Validate data structure
    if not data.item_id or not data.from or not data.to then
        cb({ success = false, error = 'Invalid data' })
        return
    end

    -- Send to server for validation and execution
    TriggerServerEvent('inventory:moveItem', data)

    cb({ success = true })
end)

-- Rotate item (R key pressed)
RegisterNUICallback('rotateItem', function(data, cb)
    if not data.item_id or not data.new_rotation then
        cb({ success = false, error = 'Invalid data' })
        return
    end

    TriggerServerEvent('inventory:rotateItem', data)
    cb({ success = true })
end)

-- Split stack (Ctrl+Drag for stackable items)
RegisterNUICallback('splitStack', function(data, cb)
    if not data.item_id or not data.split_amount or not data.target_position then
        cb({ success = false, error = 'Invalid data' })
        return
    end

    TriggerServerEvent('inventory:splitStack', data)
    cb({ success = true })
end)

-- Drop item on ground
RegisterNUICallback('dropItem', function(data, cb)
    if not data.item_id then
        cb({ success = false, error = 'Invalid data' })
        return
    end

    -- Close inventory UI
    SetNuiFocus(false, false)
    TriggerEvent('inventory:close')

    -- Send to server (server will trigger animation + prop spawn)
    TriggerServerEvent('inventory:dropItem', data)

    cb({ success = true })
end)

-- Use item (consume, activate, etc.)
RegisterNUICallback('useItem', function(data, cb)
    if not data.item_id then
        cb({ success = false, error = 'Invalid data' })
        return
    end

    -- Return immediately to UI
    cb({ success = true })

    -- Close NUI first
    SetNuiFocus(false, false)

    -- TODO: Get item type from inventory to determine animation
    -- For now, use generic bandage animation
    CreateThread(function()
        local ped = PlayerPedId()
        Animations.PlayWithProgress(
            ped,
            'useBandage',
            'Using item...',
            true, -- Can cancel
            function() -- On complete
                TriggerServerEvent('inventory:useItem', data)
            end,
            function() -- On cancel
                -- Animation canceled, do nothing
            end
        )
    end)
end)

-- Equip item to equipment slot
RegisterNUICallback('equipItem', function(data, cb)
    if not data.item_id or not data.slot then
        cb({ success = false, error = 'Invalid data' })
        return
    end

    TriggerServerEvent('inventory:equipItem', data)
    cb({ success = true })
end)

-- Unequip item from equipment slot
RegisterNUICallback('unequipItem', function(data, cb)
    if not data.item_id then
        cb({ success = false, error = 'Invalid data' })
        return
    end

    TriggerServerEvent('inventory:unequipItem', data)
    cb({ success = true })
end)

-- Take item from container and equip it directly
RegisterNUICallback('takeAndEquipFromContainer', function(data, cb)
    if not data.container_id or not data.item_id or not data.slot then
        cb({ success = false, error = 'Invalid data' })
        return
    end

    TriggerServerEvent('loot:takeAndEquipItem', data)
    cb({ success = true })
end)

-- Discard item permanently (delete)
RegisterNUICallback('discardItem', function(data, cb)
    if not data.item_id or not data.confirm then
        cb({ success = false, error = 'Invalid data or confirmation required' })
        return
    end

    TriggerServerEvent('inventory:discardItem', data)
    cb({ success = true })
end)

-- Split stack (context menu action)
RegisterNUICallback('splitStackPrompt', function(data, cb)
    if not data.item_id then
        cb({ success = false, error = 'Invalid data' })
        return
    end

    -- TODO: Show input prompt for split amount
    -- For now, just split in half
    TriggerServerEvent('inventory:splitStack', {
        item_id = data.item_id,
        split_amount = math.floor(data.quantity / 2)
    })
    cb({ success = true })
end)

-- Unload magazine from weapon
RegisterNUICallback('unloadMagazine', function(data, cb)
    if not data.item_id then
        cb({ success = false, error = 'Invalid data' })
        return
    end

    TriggerServerEvent('inventory:unloadMagazine', data)
    cb({ success = true })
end)

-- ============================================
-- LOOT CONTAINER CALLBACKS
-- ============================================

-- Take item from loot container
RegisterNUICallback('takeItemFromContainer', function(data, cb)
    if not data.container_id or not data.item_id then
        cb({ success = false, error = 'Invalid data' })
        return
    end

    TriggerServerEvent('loot:takeItem', data)
    cb({ success = true })
end)

-- Transfer item to loot container (deposit/exchange)
RegisterNUICallback('transferItemToContainer', function(data, cb)
    if not data.container_id or not data.item_id then
        cb({ success = false, error = 'Invalid data' })
        return
    end

    TriggerServerEvent('loot:transferItem', data)
    cb({ success = true })
end)

-- Move item within loot container (reorganize)
RegisterNUICallback('moveItemInContainer', function(data, cb)
    if not data.container_id or not data.item_id or not data.from_position or not data.to_position then
        cb({ success = false, error = 'Invalid data' })
        return
    end

    TriggerServerEvent('loot:moveItemInContainer', data)
    cb({ success = true })
end)

-- Search container (takes time based on item count)
RegisterNUICallback('searchContainer', function(data, cb)
    if not data.container_id then
        cb({ success = false, error = 'Invalid data' })
        return
    end

    TriggerServerEvent('loot:searchContainer', data.container_id)
    cb({ success = true })
end)

-- Close loot container
RegisterNUICallback('closeContainer', function(data, cb)
    print('[NUI Callback] closeContainer called')

    -- Notify server FIRST
    if data and data.container_id then
        TriggerServerEvent('loot:closeContainer', data.container_id)
    end

    -- Close NUI focus immediately
    SetNuiFocus(false, false)

    -- Send both close messages to fully reset UI
    SendNUIMessage({
        type = 'closeLoot'
    })
    SendNUIMessage({
        type = 'closeInventory'
    })

    -- Trigger inventory:close event to reset isInventoryOpen flag in main.lua
    TriggerEvent('inventory:close')

    cb({ success = true })
end)

-- ============================================
-- STORAGE CALLBACKS
-- ============================================

-- Deposit item to storage
RegisterNUICallback('depositItem', function(data, cb)
    if not data.container_id or not data.item_id then
        cb({ success = false, error = 'Invalid data' })
        return
    end

    TriggerServerEvent('storage:depositItem', data)
    cb({ success = true })
end)

-- Withdraw item from storage
RegisterNUICallback('withdrawItem', function(data, cb)
    if not data.container_id or not data.item_id then
        cb({ success = false, error = 'Invalid data' })
        return
    end

    TriggerServerEvent('storage:withdrawItem', data)
    cb({ success = true })
end)

-- ============================================
-- ACTION CALLBACKS
-- ============================================

-- Cancel current action (healing, looting, etc.)
RegisterNUICallback('cancelAction', function(data, cb)
    TriggerServerEvent('player:cancelAction')
    cb({ success = true })
end)

-- Request extraction at extraction point
RegisterNUICallback('requestExtraction', function(data, cb)
    if not data.extraction_id then
        cb({ success = false, error = 'Invalid data' })
        return
    end

    TriggerServerEvent('extraction:request', data.extraction_id)
    cb({ success = true })
end)

-- Call helicopter extraction with beacon
RegisterNUICallback('callHelicopter', function(data, cb)
    if not data.beacon_item_id then
        cb({ success = false, error = 'Invalid data' })
        return
    end

    TriggerServerEvent('extraction:callHelicopter', data.beacon_item_id)
    cb({ success = true })
end)

-- ============================================
-- MARKET CALLBACKS (Future Phase 3)
-- ============================================

-- List item on marketplace
RegisterNUICallback('listItem', function(data, cb)
    if not data.item_id or not data.price or not data.duration_hours then
        cb({ success = false, error = 'Invalid data' })
        return
    end

    TriggerServerEvent('market:listItem', data)
    cb({ success = true })
end)

-- Buy item from marketplace
RegisterNUICallback('buyItem', function(data, cb)
    if not data.listing_id then
        cb({ success = false, error = 'Invalid data' })
        return
    end

    TriggerServerEvent('market:buyItem', data.listing_id)
    cb({ success = true })
end)

-- ============================================
-- UI CALLBACKS
-- ============================================

-- Close UI (ESC key or close button)
RegisterNUICallback('closeUI', function(data, cb)
    SetNuiFocus(false, false)

    -- Send close messages to fully reset UI state
    SendNUIMessage({
        type = 'closeInventory'
    })
    SendNUIMessage({
        type = 'closeLoot'
    })

    -- Trigger inventory:close event to reset isInventoryOpen flag
    TriggerEvent('inventory:close')

    cb({ success = true })
end)

-- Request full data sync
RegisterNUICallback('requestSync', function(data, cb)
    TriggerServerEvent('player:requestSync')
    cb({ success = true })
end)

print('[NUI] Callbacks registered successfully')
