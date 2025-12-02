--[[
    Inventory Server Events
    Handles all inventory operations with server-side validation
]]

local Validation = require 'server.modules.inventory.validation'
local Manager = require 'server.modules.inventory.manager'
local ox = require '@ox_core/lib/init'

-- Helper to get character ID from player using ox_core
local function GetCharId(playerId)
    local player = Ox.GetPlayer(playerId)
    if not player then
        print(string.format('^3[Warning]^0 GetCharId: Ox.GetPlayer returned nil for source %s', playerId))
        return nil
    end

    local charId = player.charId
    if not charId then
        print(string.format('^3[Warning]^0 GetCharId: Player %s has no charId', playerId))
        return nil
    end

    return charId
end

-- ============================================
-- INVENTORY OPERATIONS
-- ============================================

-- Move item from one location to another
RegisterNetEvent('inventory:moveItem', function(data)
    local playerId = source

    -- DEBUG: Log what we received
    print(string.format('[Inventory] moveItem received from player %d:', playerId))
    print(string.format('  item_id: %s', tostring(data.item_id)))
    print(string.format('  rotation: %s', tostring(data.rotation)))
    print(string.format('  from: %s', data.from and 'exists' or 'NIL'))
    print(string.format('  to: %s', data.to and 'exists' or 'NIL'))
    if data.from then
        print(string.format('  from.type: %s', tostring(data.from.type)))
        print(string.format('  from.container_id: %s', tostring(data.from.container_id)))
        print(string.format('  from.slot_index: %s', tostring(data.from.slot_index)))
    end
    if data.to then
        print(string.format('  to.type: %s', tostring(data.to.type)))
        print(string.format('  to.slot_index: %s', tostring(data.to.slot_index)))
    end

    -- Rate limit check
    local canProceed, rateLimitError = Validation.CheckRateLimit(playerId, 'moveItem', 100)
    if not canProceed then
        print(('[ANTI-CHEAT] Player %d: %s'):format(playerId, rateLimitError))
        return
    end

    -- Validate operation
    local isValid, error = Validation.ValidateMoveItem(playerId, data)
    if not isValid then
        print(('[Inventory] Player %d moveItem failed: %s'):format(playerId, error))
        TriggerClientEvent('notify', playerId, 'error', 'Invalid operation: ' .. error)
        -- IMPORTANT: Refresh client to restore item to original position
        local charId = GetCharId(playerId)
        if charId then
            Manager.UpdateClient(charId, playerId)
        end
        return
    end

    -- Get character ID
    local charId = GetCharId(playerId)
    if not charId then
        return
    end

    -- Execute move
    local success, error = Manager.MoveItem(charId, data)
    if not success then
        print(('[Inventory] Player %d moveItem failed: %s'):format(playerId, error))
        TriggerClientEvent('ox_lib:notify', playerId, {
            type = 'error',
            description = error or 'Cannot move item here'
        })
        -- IMPORTANT: Refresh client to restore item to original position
        Manager.UpdateClient(charId, playerId)
        return
    end

    -- Update client inventory (without reopening UI)
    Manager.UpdateClient(charId, playerId)

    print(('[Inventory] Player %d moved item %s'):format(playerId, data.item_id))
end)

-- Rotate item
RegisterNetEvent('inventory:rotateItem', function(data)
    local playerId = source

    -- Rate limit
    local canProceed = Validation.CheckRateLimit(playerId, 'rotateItem', 50)
    if not canProceed then
        return
    end

    -- Validate
    if not data.item_id or not data.new_rotation then
        return
    end

    if data.new_rotation < 0 or data.new_rotation > 3 then
        return
    end

    -- Get character ID
    local charId = GetCharId(playerId)
    if not charId then
        return
    end

    -- Execute rotation
    local success, error = Manager.RotateItem(charId, data.item_id, data.new_rotation)
    if not success then
        print(('[Inventory] Player %d rotateItem failed: %s'):format(playerId, error))
        TriggerClientEvent('ox_lib:notify', playerId, {
            type = 'error',
            description = error
        })
        return
    end

    -- Update client inventory
    Manager.UpdateClient(charId, playerId)

    print(('[Inventory] Player %d rotated item %s to %d'):format(playerId, data.item_id, data.new_rotation))
end)

-- Split stack
RegisterNetEvent('inventory:splitStack', function(data)
    local playerId = source

    local canProceed = Validation.CheckRateLimit(playerId, 'splitStack', 200)
    if not canProceed then
        return
    end

    if not data.item_id or not data.split_amount then
        return
    end

    -- Validate amount
    if type(data.split_amount) ~= 'number' or data.split_amount < 1 then
        return
    end

    -- Get character ID
    local charId = GetCharId(playerId)
    if not charId then
        return
    end

    -- Execute split
    local success, error = Manager.SplitStack(charId, data.item_id, data.split_amount)
    if not success then
        print(('[Inventory] Player %d splitStack failed: %s'):format(playerId, error))
        TriggerClientEvent('ox_lib:notify', playerId, {
            type = 'error',
            description = error
        })
        return
    end

    -- Update client inventory
    Manager.UpdateClient(charId, playerId)

    print(('[Inventory] Player %d split stack of %s (amount: %d)'):format(playerId, data.item_id, data.split_amount))
end)

-- Drop item on ground
RegisterNetEvent('inventory:dropItem', function(data)
    local playerId = source

    local canProceed = Validation.CheckRateLimit(playerId, 'dropItem', 500)
    if not canProceed then
        return
    end

    local isValid, error = Validation.ValidateDropItem(playerId, data)
    if not isValid then
        print(('[ANTI-CHEAT] Player %d dropItem validation failed: %s'):format(playerId, error))
        return
    end

    -- Get character ID
    local charId = GetCharId(playerId)
    if not charId then
        return
    end

    -- Execute drop (pass playerId for animation and coords)
    local success, error = Manager.DropItem(charId, data.item_id, playerId)
    if not success then
        print(('[Inventory] Player %d dropItem failed: %s'):format(playerId, error))
        TriggerClientEvent('ox_lib:notify', playerId, {
            type = 'error',
            description = error
        })
        return
    end

    -- Update client inventory
    Manager.UpdateClient(charId, playerId)

    print(('[Inventory] Player %d dropped item %s'):format(playerId, data.item_id))
end)

-- Use item
RegisterNetEvent('inventory:useItem', function(data)
    local playerId = source

    local canProceed = Validation.CheckRateLimit(playerId, 'useItem', 1000)
    if not canProceed then
        return
    end

    local isValid, error = Validation.ValidateUseItem(playerId, data)
    if not isValid then
        print(('[ANTI-CHEAT] Player %d useItem validation failed: %s'):format(playerId, error))
        return
    end

    -- Get character ID
    local charId = GetCharId(playerId)
    if not charId then
        return
    end

    -- Execute use
    local success, result = Manager.UseItem(charId, data.item_id, playerId)
    if not success then
        print(('[Inventory] Player %d useItem failed: %s'):format(playerId, result))
        TriggerClientEvent('ox_lib:notify', playerId, {
            type = 'error',
            description = result
        })
        return
    end

    -- Update client inventory (item consumed)
    Manager.UpdateClient(charId, playerId)

    -- Notify client (effects are already applied via player:applyItemEffects event)
    TriggerClientEvent('ox_lib:notify', playerId, {
        type = 'success',
        description = 'Item used successfully'
    })

    print(('[Inventory] Player %d used item %s (effects: %d)'):format(playerId, data.item_id, #result))
end)

-- Equip item
RegisterNetEvent('inventory:equipItem', function(data)
    local playerId = source

    local canProceed = Validation.CheckRateLimit(playerId, 'equipItem', 500)
    if not canProceed then
        return
    end

    local isValid, error = Validation.ValidateEquipItem(playerId, data)
    if not isValid then
        print(('[ANTI-CHEAT] Player %d equipItem validation failed: %s'):format(playerId, error))
        TriggerClientEvent('notify', playerId, 'error', error)
        return
    end

    -- Get character ID
    local charId = GetCharId(playerId)
    if not charId then
        return
    end

    -- Execute equip
    local success, result = Manager.EquipItem(charId, data.item_id, data.slot)
    if not success then
        print(('[Inventory] Player %d equipItem failed: %s'):format(playerId, result))
        TriggerClientEvent('ox_lib:notify', playerId, {
            type = 'error',
            description = result
        })
        return
    end

    -- Update client inventory
    Manager.UpdateClient(charId, playerId)

    -- Sync visuals to client (weapon models, armor stats)
    if result then -- result is itemDef if success
        TriggerClientEvent('equipment:syncVisuals', playerId, {
            slot = data.slot,
            item_id = data.item_id,
            itemDef = result
        })
    end

    print(('[Inventory] Player %d equipped item %s to slot %s'):format(playerId, data.item_id, data.slot))
end)

-- Unequip item
RegisterNetEvent('inventory:unequipItem', function(data)
    local playerId = source

    local canProceed = Validation.CheckRateLimit(playerId, 'unequipItem', 500)
    if not canProceed then
        return
    end

    if not data.item_id then
        TriggerClientEvent('ox_lib:notify', playerId, {
            type = 'error',
            description = 'Invalid item'
        })
        return
    end

    -- Get character ID
    local charId = GetCharId(playerId)
    if not charId then
        return
    end

    -- Execute unequip
    local success, result = Manager.UnequipItem(charId, data.item_id)
    if not success then
        print(('[Inventory] Player %d unequipItem failed: %s'):format(playerId, result))
        TriggerClientEvent('ox_lib:notify', playerId, {
            type = 'error',
            description = result
        })
        return
    end

    -- Update client inventory
    Manager.UpdateClient(charId, playerId)

    -- Clear equipment visuals (result is the equipment slot that was cleared)
    if result then
        TriggerClientEvent('equipment:clearVisuals', playerId, result)
    end

    print(('[Inventory] Player %d unequipped item %s from slot %s'):format(playerId, data.item_id, result or 'unknown'))
end)

-- Unload magazine from weapon
RegisterNetEvent('inventory:unloadMagazine', function(data)
    local playerId = source

    local canProceed = Validation.CheckRateLimit(playerId, 'unloadMagazine', 500)
    if not canProceed then
        return
    end

    if not data.item_id then
        return
    end

    -- Get character ID
    local charId = GetCharId(playerId)
    if not charId then
        return
    end

    -- Execute unload
    local success, error = Manager.UnloadMagazine(charId, data.item_id)
    if not success then
        print(('[Inventory] Player %d unloadMagazine failed: %s'):format(playerId, error))
        TriggerClientEvent('ox_lib:notify', playerId, {
            type = 'error',
            description = error
        })
        return
    end

    -- Update client inventory
    Manager.UpdateClient(charId, playerId)

    print(('[Inventory] Player %d unloaded magazine from weapon %s'):format(playerId, data.item_id))
end)

-- Discard item permanently
RegisterNetEvent('inventory:discardItem', function(data)
    local playerId = source

    local canProceed = Validation.CheckRateLimit(playerId, 'discardItem', 1000)
    if not canProceed then
        return
    end

    if not data.item_id or not data.confirm then
        return
    end

    -- TODO: Get item from inventory
    -- TODO: Check if item is valuable (warn player)
    -- TODO: Delete item permanently
    -- TODO: Update database

    print(('[Inventory] Player %d discarded item %s'):format(playerId, data.item_id))
end)

-- ============================================
-- INVENTORY SYNC
-- ============================================

-- Request to open inventory
RegisterNetEvent('inventory:requestOpen', function()
    local playerId = source

    -- Rate limit
    local canProceed = Validation.CheckRateLimit(playerId, 'openInventory', 500)
    if not canProceed then
        return
    end

    -- Get character ID
    local charId = GetCharId(playerId)
    if not charId then
        return
    end

    -- Load and send inventory
    Manager.SyncToClient(charId, playerId)

    print(('[Inventory] Player %d opened inventory'):format(playerId))
end)

-- Request full data sync
RegisterNetEvent('player:requestSync', function()
    local playerId = source

    local canProceed = Validation.CheckRateLimit(playerId, 'requestSync', 1000)
    if not canProceed then
        return
    end

    -- TODO: Load all player data from database
    -- TODO: Send to client

    print(('[Inventory] Player %d requested data sync'):format(playerId))
end)

-- Create container after drop animation (client sends final position + rotation)
RegisterNetEvent('inventory:createDroppedContainer', function(itemData, dropCoords, rotation)
    local playerId = source

    local canProceed = Validation.CheckRateLimit(playerId, 'createContainer', 500)
    if not canProceed then
        return
    end

    -- Get character ID
    local charId = GetCharId(playerId)
    if not charId then
        return
    end

    -- Validate coords
    if not dropCoords or type(dropCoords.x) ~= 'number' then
        print(('[ANTI-CHEAT] Player %d sent invalid drop coords'):format(playerId))
        return
    end

    -- Validate rotation (can be vector3 with pitch, roll, yaw OR just a number for heading)
    print(string.format('[Inventory] DEBUG: rotation type=%s, rotation=%s', type(rotation), json.encode(rotation)))

    local finalRotation
    if type(rotation) == 'table' and rotation.x then
        -- Full rotation (pitch, roll, yaw)
        finalRotation = {
            pitch = tonumber(rotation.x) or 0.0,
            roll = tonumber(rotation.y) or 0.0,
            yaw = tonumber(rotation.z) or 0.0
        }
        print(string.format('[Inventory] DEBUG: Full rotation parsed: pitch=%.2f, roll=%.2f, yaw=%.2f',
            finalRotation.pitch, finalRotation.roll, finalRotation.yaw))
    elseif type(rotation) == 'vector3' then
        -- Handle vector3 type
        finalRotation = {
            pitch = rotation.x or 0.0,
            roll = rotation.y or 0.0,
            yaw = rotation.z or 0.0
        }
        print(string.format('[Inventory] DEBUG: Vector3 rotation: pitch=%.2f, roll=%.2f, yaw=%.2f',
            finalRotation.pitch, finalRotation.roll, finalRotation.yaw))
    else
        -- Legacy heading only
        local heading = tonumber(rotation) or 0.0
        finalRotation = {
            pitch = 0.0,
            roll = 0.0,
            yaw = heading
        }
        print(string.format('[Inventory] DEBUG: Legacy heading: %.2f', heading))
    end

    -- Create container in DB and cache (with full rotation)
    local containerId = Manager.CreateDroppedContainer(charId, itemData, dropCoords, finalRotation)

    -- Notify client who dropped it
    TriggerClientEvent('inventory:containerCreated', playerId, containerId)

    -- Notify ALL clients to spawn the prop (via loot system)
    local LootContainers = require 'server.modules.loot.containers'
    LootContainers.NotifyNew(containerId, {
        container_id = containerId,
        container_type = 'dropped_item',
        model = itemData.model, -- Pass the correct model
        coords = {
            x = dropCoords.x,
            y = dropCoords.y,
            z = dropCoords.z,
            heading = finalRotation.yaw -- For DB compatibility
        },
        rotation = finalRotation, -- Full rotation for accurate spawning
        items = {{
            item_id = itemData.item_id,
            quantity = itemData.quantity,
            metadata = itemData.metadata
        }}
    })

    print(('[Inventory] Player %d created dropped container %d (rotation: %.2f, %.2f, %.2f)'):format(
        playerId, containerId, finalRotation.pitch, finalRotation.roll, finalRotation.yaw))
end)

print('[Server] Inventory events registered')
