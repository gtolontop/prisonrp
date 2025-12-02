--[[
    Inventory Validation Module
    Server-side validation for all inventory operations
    NEVER trust client input - validate everything
]]

local Config = require 'shared.config'
local Items = require 'shared.items'

local Validation = {}

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Get distance between two coordinates
local function GetDistance(coords1, coords2)
    return #(coords1 - coords2)
end

-- Check if item exists in Items table
function Validation.ItemExists(itemId)
    return Items[itemId] ~= nil
end

-- Get item definition
function Validation.GetItemDef(itemId)
    return Items[itemId]
end

-- Get rotated size of item
function Validation.GetRotatedSize(itemDef, rotation)
    local size = itemDef.size
    -- Rotation 1 (90°) and 3 (270°) swap width and height
    if rotation == 1 or rotation == 3 then
        return { width = size.height, height = size.width }
    end
    return size
end

-- ============================================
-- POSITION VALIDATION
-- ============================================

-- Check if item fits in grid at position
function Validation.CanItemFitAt(position, itemDef, rotation, gridSize)
    local rotatedSize = Validation.GetRotatedSize(itemDef, rotation)

    -- Check bounds
    if position.x < 0 or position.y < 0 then
        return false, "Position out of bounds"
    end

    if position.x + rotatedSize.width > gridSize.width or
       position.y + rotatedSize.height > gridSize.height then
        return false, "Item exceeds grid boundaries"
    end

    return true
end

-- Get all cells occupied by item
function Validation.GetOccupiedCells(position, itemDef, rotation)
    local rotatedSize = Validation.GetRotatedSize(itemDef, rotation)
    local cells = {}

    for x = 0, rotatedSize.width - 1 do
        for y = 0, rotatedSize.height - 1 do
            table.insert(cells, {
                x = position.x + x,
                y = position.y + y
            })
        end
    end

    return cells
end

-- Check if two items collide
function Validation.DoItemsCollide(item1Pos, item1Def, item1Rot, item2Pos, item2Def, item2Rot)
    local cells1 = Validation.GetOccupiedCells(item1Pos, item1Def, item1Rot)
    local cells2 = Validation.GetOccupiedCells(item2Pos, item2Def, item2Rot)

    for _, cell1 in ipairs(cells1) do
        for _, cell2 in ipairs(cells2) do
            if cell1.x == cell2.x and cell1.y == cell2.y then
                return true
            end
        end
    end

    return false
end

-- ============================================
-- ITEM OPERATION VALIDATION
-- ============================================

-- Validate move item operation
function Validation.ValidateMoveItem(playerId, data)
    -- Required fields
    if not data.item_id or not data.from or not data.to then
        return false, "Missing required fields"
    end

    -- Validate rotation (rotation can be 0, which is falsy in Lua, so check for nil explicitly)
    -- For pocket/equipment slots, rotation is not required (default to 0)
    if data.rotation == nil then
        data.rotation = 0 -- Default rotation
    end

    if type(data.rotation) ~= 'number' or data.rotation < 0 or data.rotation > 3 then
        return false, "Invalid rotation"
    end

    -- NOTE: We don't validate item existence here because data.item_id is the INSTANCE ID (e.g., "1")
    -- not the item definition ID (e.g., "bandage"). The Manager will load the item from DB.

    -- Validate target position if grid
    if data.to.type == 'grid' and data.to.position then
        local gridSize = { width = 10, height = 10 } -- TODO: Get actual grid size

        -- Just validate position is within grid bounds
        if data.to.position.x < 0 or data.to.position.y < 0 or
           data.to.position.x >= gridSize.width or data.to.position.y >= gridSize.height then
            return false, "Position out of bounds"
        end

        -- Note: Collision detection is done in Manager.MoveItem after loading item from DB
    end

    -- Validate pocket slot
    if data.to.type == 'pocket' then
        if not data.to.slot_index or data.to.slot_index < 0 or data.to.slot_index > 4 then
            return false, "Invalid pocket slot"
        end

        -- Note: Size validation (1x1 for pockets) is done in Manager.MoveItem
    end

    -- TODO: Check distance from player for loot containers
    -- TODO: Check actual inventory for conflicts (done in Manager)

    return true
end

-- Validate drop item operation
function Validation.ValidateDropItem(playerId, data)
    if not data.item_id then
        return false, "Missing item_id"
    end

    -- NOTE: data.item_id is the INSTANCE ID (e.g., "1"), not the item definition ID
    -- The actual existence check is done in the Manager after loading from DB
    -- Here we just validate the structure

    return true
end

-- Validate use item operation
function Validation.ValidateUseItem(playerId, data)
    if not data.item_id then
        return false, "Missing item_id"
    end

    -- NOTE: data.item_id is the INSTANCE ID, not the item definition ID
    -- The Manager will load the item from DB and check if it's usable

    return true
end

-- Validate equip item operation
function Validation.ValidateEquipItem(playerId, data)
    if not data.item_id or not data.slot then
        return false, "Missing required fields"
    end

    -- Check if slot name is valid
    local validSlots = {
        head = true,
        armor = true,
        rig = true,
        backpack = true,
        holster = true,
        melee = true,
        primary = true,
        secondary = true
    }

    if not validSlots[data.slot] then
        return false, "Invalid equipment slot"
    end

    -- NOTE: data.item_id is the INSTANCE ID, not the item definition ID
    -- The Manager will load the item from DB and check category compatibility

    return true
end

-- ============================================
-- ANTI-CHEAT VALIDATION
-- ============================================

-- Validate container distance (anti-cheat)
function Validation.ValidateContainerDistance(playerId, containerId, maxDistance)
    maxDistance = maxDistance or 3.0

    local playerPed = GetPlayerPed(playerId)
    if not playerPed or playerPed == 0 then
        return false, "Invalid player"
    end

    local playerCoords = GetEntityCoords(playerPed)

    -- TODO: Get container coords from database/entity
    -- local containerCoords = GetContainerCoords(containerId)
    -- local distance = GetDistance(playerCoords, containerCoords)

    -- if distance > maxDistance then
    --     return false, "Container too far away"
    -- end

    return true
end

-- Validate quantity (anti-cheat)
function Validation.ValidateQuantity(quantity, itemDef)
    if type(quantity) ~= 'number' then
        return false, "Invalid quantity type"
    end

    if quantity < 1 then
        return false, "Quantity must be positive"
    end

    -- Cap at reasonable maximum to prevent spam
    if quantity > 10000 then
        return false, "Quantity too large (max 10000)"
    end

    if not itemDef.stackable and quantity > 1 then
        return false, "Item is not stackable"
    end

    -- NOTE: We don't check max_stack here because GiveItem will create multiple stacks
    -- Example: giving 1000 bandages (max_stack=5) will create 200 stacks

    return true
end

-- Rate limiting (anti-spam)
local actionTimestamps = {}

function Validation.CheckRateLimit(playerId, action, cooldown)
    cooldown = cooldown or 100 -- 100ms default

    local key = playerId .. "_" .. action
    local now = GetGameTimer()
    local lastAction = actionTimestamps[key] or 0

    if now - lastAction < cooldown then
        return false, "Action too fast (rate limit)"
    end

    actionTimestamps[key] = now
    return true
end

-- ============================================
-- EXPORT
-- ============================================

return Validation
