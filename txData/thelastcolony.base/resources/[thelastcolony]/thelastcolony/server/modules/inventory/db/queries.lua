--[[
    Inventory Database Queries
    All SQL operations for inventory system
]]

local MySQL = MySQL or exports.oxmysql

local Queries = {}

-- ============================================
-- DATABASE OPTIMIZATION (INDEXES)
-- ============================================

-- Create critical indexes for performance (run once on startup)
CreateThread(function()
    -- Index on charid + slot_type for inventory queries (HUGE perf gain with 700 players)
    MySQL.query([[
        CREATE INDEX IF NOT EXISTS idx_inventory_charid_slot
        ON inventory_items(charid, slot_type)
    ]])

    -- Index on item_instance_id for single item lookups
    MySQL.query([[
        CREATE INDEX IF NOT EXISTS idx_inventory_instance
        ON inventory_items(item_instance_id)
    ]])

    print('^2[Inventory DB]^0 Performance indexes created/verified')
end)

-- ============================================
-- INVENTORY LOADING
-- ============================================

-- Load player's complete inventory
function Queries.LoadPlayerInventory(charId)
    local result = MySQL.query.await([[
        SELECT
            item_instance_id,
            item_id,
            quantity,
            position_x,
            position_y,
            rotation,
            slot_type,
            slot_index,
            metadata,
            durability,
            weight
        FROM inventory_items
        WHERE charid = ?
        ORDER BY slot_type, position_y, position_x
    ]], { charId })

    return result or {}
end

-- Load player's equipment
function Queries.LoadPlayerEquipment(charId)
    local result = MySQL.query.await([[
        SELECT
            slot_name,
            item_instance_id
        FROM equipment
        WHERE charid = ?
    ]], { charId })

    return result or {}
end

-- DEPRECATED: Grid size is now determined by item definition in LoadPlayerInventory()
-- This function now always returns 0x0 (no base grid without equipment)
function Queries.GetInventoryGridSize(charId)
    return { width = 0, height = 0 }
end

-- ============================================
-- ITEM OPERATIONS
-- ============================================

-- Create new item instance
function Queries.CreateItem(charId, itemId, quantity, slotType, slotIndex, position, rotation, metadata)
    local result = MySQL.insert.await([[
        INSERT INTO inventory_items (
            charid,
            item_id,
            quantity,
            position_x,
            position_y,
            rotation,
            slot_type,
            slot_index,
            metadata,
            durability,
            weight
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        charId,
        itemId,
        quantity,
        position and position.x or nil,
        position and position.y or nil,
        rotation or 0,
        slotType,
        slotIndex,
        metadata and json.encode(metadata) or nil,
        metadata and metadata.durability or 100,
        0 -- Weight will be calculated
    })

    return result
end

-- Update item position
function Queries.MoveItem(itemInstanceId, slotType, slotIndex, position, rotation)
    MySQL.update.await([[
        UPDATE inventory_items
        SET
            slot_type = ?,
            slot_index = ?,
            position_x = ?,
            position_y = ?,
            rotation = ?
        WHERE item_instance_id = ?
    ]], {
        slotType,
        slotIndex,
        position and position.x or nil,
        position and position.y or nil,
        rotation or 0,
        itemInstanceId
    })

    return true
end

-- Update item rotation
function Queries.RotateItem(itemInstanceId, rotation)
    MySQL.update.await([[
        UPDATE inventory_items
        SET rotation = ?
        WHERE item_instance_id = ?
    ]], { rotation, itemInstanceId })

    return true
end

-- Update item quantity
function Queries.UpdateItemQuantity(itemInstanceId, quantity)
    if quantity <= 0 then
        return Queries.DeleteItem(itemInstanceId)
    end

    MySQL.update.await([[
        UPDATE inventory_items
        SET quantity = ?
        WHERE item_instance_id = ?
    ]], { quantity, itemInstanceId })

    return true
end

-- Update item metadata
function Queries.UpdateItemMetadata(itemInstanceId, metadata)
    MySQL.update.await([[
        UPDATE inventory_items
        SET metadata = ?
        WHERE item_instance_id = ?
    ]], { json.encode(metadata), itemInstanceId })

    return true
end

-- Delete item
function Queries.DeleteItem(itemInstanceId)
    MySQL.update.await([[
        DELETE FROM inventory_items
        WHERE item_instance_id = ?
    ]], { itemInstanceId })

    return true
end

-- ============================================
-- EQUIPMENT OPERATIONS
-- ============================================

-- Equip item to slot
function Queries.EquipItem(charId, slotName, itemInstanceId)
    -- First, unequip current item in slot (if any)
    MySQL.update.await([[
        UPDATE equipment
        SET item_instance_id = NULL
        WHERE charid = ? AND slot_name = ?
    ]], { charId, slotName })

    -- Then equip new item
    MySQL.update.await([[
        INSERT INTO equipment (charid, slot_name, item_instance_id)
        VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE item_instance_id = ?
    ]], { charId, slotName, itemInstanceId, itemInstanceId })

    return true
end

-- Unequip item from slot
function Queries.UnequipItem(charId, slotName, itemInstanceId, position, rotation)
    -- Remove from equipment slot
    MySQL.update.await([[
        UPDATE equipment
        SET item_instance_id = NULL
        WHERE charid = ? AND slot_name = ?
    ]], { charId, slotName })

    -- Move item to grid inventory
    MySQL.update.await([[
        UPDATE inventory_items
        SET slot_type = 'grid',
            slot_index = NULL,
            position_x = ?,
            position_y = ?,
            rotation = ?
        WHERE item_instance_id = ?
    ]], { position.x, position.y, rotation, itemInstanceId })

    return true
end

-- Get equipped item in slot
function Queries.GetEquippedItem(charId, slotName)
    local result = MySQL.single.await([[
        SELECT
            e.item_instance_id,
            i.item_id,
            i.metadata
        FROM equipment e
        JOIN inventory_items i ON e.item_instance_id = i.item_instance_id
        WHERE e.charid = ? AND e.slot_name = ?
    ]], { charId, slotName })

    return result
end

-- ============================================
-- WEIGHT CALCULATIONS
-- ============================================

-- Calculate total inventory weight
function Queries.CalculateTotalWeight(charId)
    local result = MySQL.single.await([[
        SELECT COALESCE(SUM(i.weight * i.quantity), 0) as total_weight
        FROM inventory_items i
        WHERE i.charid = ?
    ]], { charId })

    return result and result.total_weight or 0
end

-- ============================================
-- LOOT CONTAINERS
-- ============================================

-- Create loot container
function Queries.CreateLootContainer(containerType, coords, gridWidth, gridHeight, metadata, heading, rotation)
    -- Build position JSON (with random heading)
    local position = {
        x = coords.x,
        y = coords.y,
        z = coords.z,
        heading = heading or 0.0
    }

    -- Build rotation JSON (optional - for dropped items)
    local rotationJson = nil
    if rotation then
        rotationJson = json.encode({
            pitch = rotation.pitch or 0.0,
            roll = rotation.roll or 0.0,
            yaw = rotation.yaw or 0.0
        })
    end

    local result = MySQL.insert.await([[
        INSERT INTO loot_containers (
            container_type,
            position,
            rotation,
            grid_width,
            grid_height,
            current_items,
            respawn_delay_seconds
        ) VALUES (?, ?, ?, ?, ?, ?, ?)
    ]], {
        containerType,
        json.encode(position),
        rotationJson, -- NULL if not provided
        gridWidth,
        gridHeight,
        json.encode(metadata and {metadata} or {}), -- Wrap in array for consistency
        600 -- 10 minutes despawn
    })

    return result
end

-- Load loot container
function Queries.LoadLootContainer(containerId)
    local container = MySQL.single.await([[
        SELECT
            container_id,
            container_type,
            position,
            rotation,
            grid_width,
            grid_height,
            current_items,
            last_looted_at,
            last_looted_by
        FROM loot_containers
        WHERE container_id = ?
    ]], { containerId })

    if not container then
        return nil
    end

    -- Decode JSON position and rotation
    if container.position then
        container.position = json.decode(container.position)
    end
    if container.rotation then
        container.rotation = json.decode(container.rotation)
    end

    -- Decode current_items JSON
    if container.current_items then
        container.items = json.decode(container.current_items)
    else
        container.items = {}
    end

    return container
end

-- Delete loot container (after pickup or despawn)
function Queries.DeleteLootContainer(containerId)
    MySQL.update.await([[
        DELETE FROM loot_containers
        WHERE container_id = ?
    ]], { containerId })
end

-- Load all active loot containers (on server start)
function Queries.LoadAllLootContainers()
    local containers = MySQL.query.await([[
        SELECT
            container_id,
            container_type,
            position,
            rotation,
            grid_width,
            grid_height,
            current_items
        FROM loot_containers
        WHERE active = TRUE
    ]], {})

    if not containers then
        return {}
    end

    -- Decode JSON fields
    for _, container in ipairs(containers) do
        if container.position then
            container.position = json.decode(container.position)
        end
        if container.rotation then
            container.rotation = json.decode(container.rotation)
        end
        if container.current_items then
            container.items = json.decode(container.current_items)
        else
            container.items = {}
        end
    end

    return containers
end

-- ============================================
-- STORAGE (Personal & Guild)
-- ============================================

-- Load personal storage
function Queries.LoadPersonalStorage(charId)
    local result = MySQL.query.await([[
        SELECT
            item_instance_id,
            item_id,
            quantity,
            position_x,
            position_y,
            rotation,
            metadata
        FROM storage_personal
        WHERE charid = ?
        ORDER BY position_y, position_x
    ]], { charId })

    return result or {}
end

-- Load guild storage
function Queries.LoadGuildStorage(guildId)
    local result = MySQL.query.await([[
        SELECT
            item_instance_id,
            item_id,
            quantity,
            position_x,
            position_y,
            rotation,
            metadata
        FROM storage_guild
        WHERE guild_id = ?
        ORDER BY position_y, position_x
    ]], { guildId })

    return result or {}
end

return Queries
