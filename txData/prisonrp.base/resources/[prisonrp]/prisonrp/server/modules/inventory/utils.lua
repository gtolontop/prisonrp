--[[
    Inventory Utilities
    Helper functions for inventory management (grid placement, validation, etc.)
]]

local Items = require 'shared.items'
local Utils = {}

-- ============================================
-- GRID PLACEMENT
-- ============================================

-- Find first available position in grid for an item
-- Returns: position {x, y}, rotation (0 or 1) or nil if no space
function Utils.FindAvailablePosition(inventory, itemDef)
    local gridWidth = inventory.backpack.width
    local gridHeight = inventory.backpack.height
    -- Normalize size field names (items use w/h, but some code uses width/height)
    local itemWidth = itemDef.size.width or itemDef.size.w
    local itemHeight = itemDef.size.height or itemDef.size.h

    -- Check if grid is empty (no backpack equipped)
    if gridWidth == 0 or gridHeight == 0 then
        return nil, nil
    end

    -- Check if item is too large for the grid
    if itemWidth > gridWidth or itemHeight > gridHeight then
        -- Check if rotating would help
        if itemHeight > gridWidth or itemWidth > gridHeight then
            return nil, nil -- Item too large even when rotated
        end
    end

    -- Create occupancy map
    local occupied = {}
    for y = 0, gridHeight - 1 do
        occupied[y] = {}
        for x = 0, gridWidth - 1 do
            occupied[y][x] = false
        end
    end

    -- Mark occupied cells
    for _, item in ipairs(inventory.backpack.items) do
        if item.position then
            local def = Items[item.item_id]
            if def and def.size then
                -- Normalize size field names
                local defWidth = def.size.width or def.size.w
                local defHeight = def.size.height or def.size.h

                -- Validate size values
                if defWidth and defHeight then
                    -- Get rotated size
                    local rotation = item.rotation or 0
                    local w = (rotation == 1 or rotation == 3) and defHeight or defWidth
                    local h = (rotation == 1 or rotation == 3) and defWidth or defHeight

                    -- Mark cells
                    for dy = 0, h - 1 do
                        for dx = 0, w - 1 do
                            local cx = item.position.x + dx
                            local cy = item.position.y + dy
                            if occupied[cy] and occupied[cy][cx] ~= nil then
                                occupied[cy][cx] = true
                            end
                        end
                    end
                end
            end
        end
    end

    -- Try to find available position (try rotation 0 first, then rotation 1)
    for rotation = 0, 1 do
        local w = (rotation == 1) and itemHeight or itemWidth
        local h = (rotation == 1) and itemWidth or itemHeight

        -- Scan grid
        for y = 0, gridHeight - h do
            for x = 0, gridWidth - w do
                -- Check if item fits at this position
                local fits = true
                for dy = 0, h - 1 do
                    for dx = 0, w - 1 do
                        if occupied[y + dy][x + dx] then
                            fits = false
                            break
                        end
                    end
                    if not fits then break end
                end

                if fits then
                    return { x = x, y = y }, rotation
                end
            end
        end
    end

    -- No space found
    return nil, nil
end

-- Check if position is occupied
function Utils.IsPositionOccupied(inventory, position, itemWidth, itemHeight, rotation, excludeItemId, gridType)
    -- Validate position parameter
    if type(position) ~= 'table' or not position.x or not position.y then
        print(string.format('^3[Utils] IsPositionOccupied: Invalid position parameter (type: %s)^0', type(position)))
        return false -- Assume not occupied if invalid position
    end

    local w = (rotation == 1 or rotation == 3) and itemHeight or itemWidth
    local h = (rotation == 1 or rotation == 3) and itemWidth or itemHeight

    -- Determine which grid to check
    local itemsToCheck = {}
    if gridType == 'rig' and inventory.rig and inventory.rig.items then
        itemsToCheck = inventory.rig.items
    elseif gridType == 'backpack_storage' and inventory.backpack_storage and inventory.backpack_storage.items then
        itemsToCheck = inventory.backpack_storage.items
    else
        -- Default: check backpack items
        itemsToCheck = inventory.backpack.items or {}
    end

    for _, item in ipairs(itemsToCheck) do
        if item.id ~= excludeItemId and item.position and type(item.position) == 'table' then
            local def = Items[item.item_id]
            if def and def.size then
                local itemRot = item.rotation or 0
                local itemW = (itemRot == 1 or itemRot == 3) and (def.size.h or def.size.height) or (def.size.w or def.size.width)
                local itemH = (itemRot == 1 or itemRot == 3) and (def.size.w or def.size.width) or (def.size.h or def.size.height)

                -- Validate dimensions exist
                if itemW and itemH then
                    -- Check overlap
                    local overlap = not (
                        position.x + w <= item.position.x or
                        position.x >= item.position.x + itemW or
                        position.y + h <= item.position.y or
                        position.y >= item.position.y + itemH
                    )

                    if overlap then
                        return true
                    end
                end
            end
        end
    end

    return false
end

-- ============================================
-- STACKING
-- ============================================

-- Try to stack item with existing items in inventory
-- Returns: success (bool), updated quantity remaining
function Utils.TryStackItem(charId, itemId, quantity, maxStack)
    if not maxStack or maxStack <= 1 then
        return false, quantity
    end

    local Queries = require 'server.modules.inventory.db.queries'

    -- Find existing stacks of this item
    local result = MySQL.query.await([[
        SELECT item_instance_id, quantity
        FROM inventory_items
        WHERE charid = ? AND item_id = ?
        ORDER BY quantity DESC
    ]], { charId, itemId })

    for _, stack in ipairs(result) do
        if stack.quantity < maxStack then
            local canAdd = maxStack - stack.quantity
            local toAdd = math.min(canAdd, quantity)

            -- Update stack
            Queries.UpdateItemQuantity(stack.item_instance_id, stack.quantity + toAdd)

            quantity = quantity - toAdd

            if quantity <= 0 then
                return true, 0
            end
        end
    end

    return false, quantity
end

return Utils
