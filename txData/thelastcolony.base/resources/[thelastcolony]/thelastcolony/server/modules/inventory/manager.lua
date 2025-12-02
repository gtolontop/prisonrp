--[[
    Inventory Manager
    Core business logic for inventory operations (load, give, remove, move items)
]]

local Items = require 'shared.items'
local Queries = require 'server.modules.inventory.db.queries'
local Validation = require 'server.modules.inventory.validation'
local Config = require 'shared.config'

local Manager = {}

-- Cache for loaded inventories (avoid spam DB queries)
local inventoryCache = {}

-- ============================================
-- INVENTORY LOADING
-- ============================================

--- Load player's full inventory (backpack, pockets, equipment, weight)
--- Returns: inventory table or nil
function Manager.LoadPlayerInventory(charId)
    -- Check cache first
    if inventoryCache[charId] then
        print('[Inventory] Using cached inventory for charId ' .. charId)
        return inventoryCache[charId]
    end

    print('[Inventory] Loading fresh inventory for charId ' .. charId)

    -- Load raw data from DB
    local items = Queries.LoadPlayerInventory(charId)
    local equipment = Queries.LoadPlayerEquipment(charId)
    local gridSize = Queries.GetInventoryGridSize(charId)

    print(string.format('[Inventory] Loaded %d items, %d equipment, grid %dx%d',
        #items, #equipment, gridSize.width, gridSize.height))

    -- Build inventory structure
    local inventory = {
        backpack = {
            width = gridSize.width,
            height = gridSize.height,
            items = {}
        },
        backpack_storage = nil, -- Will be set if backpack equipped (dynamic slots)
        case_storage = nil, -- Will be set if secure_case equipped (permanent 3x1 storage)
        rig = nil, -- Will be set if rig equipped (dynamic slots)
        pockets = {},
        equipment = {},
        current_weight = 0,
        max_weight = Config.Inventory.MaxWeight
    }

    -- Initialize pockets
    for i = 0, 4 do
        table.insert(inventory.pockets, {
            index = i,
            item = nil
        })
    end

    -- Initialize equipment slots
    -- Order matters for UI display
    local equipmentSlots = {
        'headgear',     -- Helmet/hat
        'headset',      -- Earphones/comms
        'face_cover',   -- Gas mask/balaclava
        'armor',        -- Body armor (can be blocked by armored rig)
        'primary',      -- Primary weapon
        'secondary',    -- Secondary weapon
        'holster',      -- Pistol
        'sheath',       -- Knife (default melee - always present, cannot be removed)
        'case'          -- Secure case (permanent, contains card + compass)
    }
    for _, slot in ipairs(equipmentSlots) do
        table.insert(inventory.equipment, {
            slot_name = slot,
            item = nil
        })
    end

    -- Special slots that add dynamic storage
    table.insert(inventory.equipment, {
        slot_name = 'rig',
        item = nil  -- When equipped, adds rig.slots to inventory
    })
    table.insert(inventory.equipment, {
        slot_name = 'backpack',
        item = nil  -- When equipped, adds backpack_storage to inventory
    })

    -- Populate items
    for _, item in ipairs(items) do
        local itemData = {
            id = tostring(item.item_instance_id),
            item_id = item.item_id,
            quantity = item.quantity,
            rotation = item.rotation or 0,
            slot_type = item.slot_type,
            slot_index = item.slot_index,
            metadata = item.metadata and json.decode(item.metadata) or nil
        }

        if item.slot_type == 'grid' then
            itemData.position = {
                x = item.position_x,
                y = item.position_y
            }
            table.insert(inventory.backpack.items, itemData)
        elseif item.slot_type == 'pocket' then
            local pocketIndex = item.slot_index + 1
            if inventory.pockets[pocketIndex] then
                inventory.pockets[pocketIndex].item = itemData
            end
        elseif item.slot_type == 'rig' then
            -- Rig items will be loaded when we detect equipped rig below
            -- Do nothing here - will be populated later when we find equipped rig
            -- If no rig equipped, these items are orphaned (shouldn't happen normally)
        elseif item.slot_type == 'backpack_storage' then
            -- Backpack storage items
            if not inventory.backpack_storage then
                inventory.backpack_storage = {items = {}}
            end
            itemData.position = {
                x = item.position_x,
                y = item.position_y
            }
            table.insert(inventory.backpack_storage.items, itemData)
        end
    end

    -- Populate equipment
    for _, equip in ipairs(equipment) do
        if equip.item_instance_id then
            -- Find item data
            local itemData = nil
            for _, item in ipairs(items) do
                if item.item_instance_id == equip.item_instance_id then
                    itemData = {
                        id = tostring(item.item_instance_id),
                        item_id = item.item_id,
                        quantity = item.quantity,
                        metadata = item.metadata and json.decode(item.metadata) or nil
                    }
                    break
                end
            end

            for i, slot in ipairs(inventory.equipment) do
                if slot.slot_name == equip.slot_name then
                    inventory.equipment[i].item = itemData
                    break
                end
            end
        end
    end

    -- Initialize dynamic slots based on equipped rig/backpack
    print('[Inventory] DEBUG - Checking equipment for dynamic slots...')
    for _, slot in ipairs(inventory.equipment) do
        print('  Equipment slot:', slot.slot_name, 'has item:', slot.item ~= nil)
        if slot.item then
            print('    Item ID:', slot.item.item_id)
            local itemDef = Items[slot.item.item_id]
            print('    Item def found:', itemDef ~= nil)
            if itemDef then
                print('    Has rig_slots:', itemDef.rig_slots ~= nil)
                print('    Has storage_slots:', itemDef.storage_slots ~= nil)
            end

            -- Initialize rig storage if rig equipped (NOW A GRID, like backpack)
            if slot.slot_name == 'rig' and itemDef and itemDef.storage_slots then
                print('[Inventory] DEBUG - Initializing rig storage grid for', slot.item.item_id)
                inventory.rig = {
                    item_id = slot.item.item_id,
                    width = itemDef.storage_slots.w,
                    height = itemDef.storage_slots.h,
                    items = {}
                }

                -- Populate rig grid with items from DB
                for _, item in ipairs(items) do
                    if item.slot_type == 'rig' then
                        table.insert(inventory.rig.items, {
                            id = tostring(item.item_instance_id),
                            item_id = item.item_id,
                            quantity = item.quantity,
                            rotation = item.rotation or 0,
                            position = {
                                x = item.position_x,
                                y = item.position_y
                            },
                            metadata = item.metadata and json.decode(item.metadata) or nil
                        })
                    end
                end
            end

            -- Initialize backpack storage if backpack equipped
            if slot.slot_name == 'backpack' and itemDef and itemDef.storage_slots then
                print('[Inventory] DEBUG - Initializing backpack storage for', slot.item.item_id)

                -- Update main backpack dimensions (this is what the client needs)
                inventory.backpack.width = itemDef.storage_slots.w
                inventory.backpack.height = itemDef.storage_slots.h

                -- Also create backpack_storage structure (for compatibility)
                inventory.backpack_storage = {
                    item_id = slot.item.item_id,
                    width = itemDef.storage_slots.w,
                    height = itemDef.storage_slots.h,
                    items = {}
                }

                -- Populate backpack storage with items from DB
                for _, item in ipairs(items) do
                    if item.slot_type == 'backpack_storage' then
                        local itemData = {
                            id = tostring(item.item_instance_id),
                            item_id = item.item_id,
                            quantity = item.quantity,
                            rotation = item.rotation or 0,
                            position = {
                                x = item.position_x,
                                y = item.position_y
                            },
                            metadata = item.metadata and json.decode(item.metadata) or nil
                        }
                        table.insert(inventory.backpack_storage.items, itemData)
                        -- Also add to main backpack.items (client expects items here)
                        table.insert(inventory.backpack.items, itemData)
                    end
                end
            end

            -- Initialize case storage if secure_case equipped
            if slot.slot_name == 'case' and itemDef and itemDef.storage_slots then
                print('[Inventory] DEBUG - Initializing case storage for', slot.item.item_id)

                inventory.case_storage = {
                    item_id = slot.item.item_id,
                    width = itemDef.storage_slots.width or 3,
                    height = itemDef.storage_slots.height or 1,
                    items = {}
                }

                -- Populate case storage with items from DB (card + compass)
                for _, item in ipairs(items) do
                    if item.slot_type == 'case_storage' then
                        local itemData = {
                            id = tostring(item.item_instance_id),
                            item_id = item.item_id,
                            quantity = item.quantity,
                            rotation = item.rotation or 0,
                            position = {
                                x = item.position_x or 0,
                                y = item.position_y or 0
                            },
                            slot_type = 'case_storage',
                            metadata = item.metadata and json.decode(item.metadata) or nil
                        }
                        table.insert(inventory.case_storage.items, itemData)
                    end
                end

                print(string.format('[Inventory] Case storage initialized with %d items', #inventory.case_storage.items))
            end
        end
    end

    -- Calculate weight
    inventory.current_weight = Queries.CalculateTotalWeight(charId)

    -- Cache it
    inventoryCache[charId] = inventory

    return inventory
end

--- Clear inventory cache for player
function Manager.ClearCache(charId)
    inventoryCache[charId] = nil
end

-- ============================================
-- ITEM OPERATIONS
-- ============================================

--- Give item to player (partial give if not enough space)
--- Returns: success (bool), result {given = X, refused = Y} or error message
function Manager.GiveItem(charId, itemId, quantity, metadata)
    local itemDef = Items[itemId]
    if not itemDef then
        return false, "Item does not exist"
    end

    -- Validate quantity
    local isValid, error = Validation.ValidateQuantity(quantity, itemDef)
    if not isValid then
        return false, error
    end

    -- ============================================
    -- DURABILITY SYSTEM - Copy metadata_template
    -- ============================================
    -- If no metadata provided, copy from item definition's metadata_template
    if not metadata and itemDef.metadata_template then
        -- Deep copy metadata_template to avoid reference sharing
        local function deepCopy(original)
            if type(original) ~= 'table' then
                return original
            end
            local copy = {}
            for key, value in pairs(original) do
                copy[key] = deepCopy(value)
            end
            return copy
        end

        metadata = deepCopy(itemDef.metadata_template)
        print(string.format('[Inventory] Copied metadata_template for %s: durability=%s, max_durability=%s',
            itemId, tostring(metadata.durability), tostring(metadata.max_durability)))
    end

    local Utils = require 'server.modules.inventory.utils'
    local originalQuantity = quantity
    local givenQuantity = 0

    -- Try to stack with existing items first (if stackable)
    if itemDef.max_stack and itemDef.max_stack > 1 then
        local stacked, remaining = Utils.TryStackItem(charId, itemId, quantity, itemDef.max_stack)

        local stackedAmount = quantity - remaining
        givenQuantity = givenQuantity + stackedAmount
        quantity = remaining

        if quantity <= 0 then
            -- All items were stacked successfully
            Manager.ClearCache(charId)
            return true, {given = givenQuantity, refused = 0}
        end

        -- Clear cache to reload updated inventory
        Manager.ClearCache(charId)
    end

    -- Normalize size field names
    local itemWidth = itemDef.size.width or itemDef.size.w
    local itemHeight = itemDef.size.height or itemDef.size.h
    local maxStack = itemDef.max_stack or 1

    -- Give items until no more quantity or no more space
    while quantity > 0 do
        -- Reload inventory for each iteration
        local inventory = Manager.LoadPlayerInventory(charId)

        local position = nil
        local slotType = nil
        local slotIndex = nil
        local rotation = 0
        local equipmentSlot = nil

        -- TRY EQUIPMENT SLOTS FIRST for weapons, backpacks, rigs, armor, etc.
        if itemDef.type == 'weapon' then
            -- Check primary weapon slot first, then secondary
            for _, slot in ipairs(inventory.equipment) do
                if (slot.slot_name == 'primary' or slot.slot_name == 'secondary') and not slot.item then
                    slotType = 'equipment'
                    equipmentSlot = slot.slot_name
                    break
                end
            end
        elseif itemDef.type == 'backpack' then
            -- Check backpack slot
            for _, slot in ipairs(inventory.equipment) do
                if slot.slot_name == 'backpack' and not slot.item then
                    slotType = 'equipment'
                    equipmentSlot = slot.slot_name
                    break
                end
            end
        elseif itemDef.type == 'rig' then
            -- Check rig slot
            for _, slot in ipairs(inventory.equipment) do
                if slot.slot_name == 'rig' and not slot.item then
                    slotType = 'equipment'
                    equipmentSlot = slot.slot_name
                    break
                end
            end
        elseif itemDef.type == 'armor' then
            -- Check armor slot
            for _, slot in ipairs(inventory.equipment) do
                if slot.slot_name == 'armor' and not slot.item then
                    slotType = 'equipment'
                    equipmentSlot = slot.slot_name
                    break
                end
            end
        elseif itemDef.type == 'helmet' then
            -- Check headgear slot
            for _, slot in ipairs(inventory.equipment) do
                if slot.slot_name == 'headgear' and not slot.item then
                    slotType = 'equipment'
                    equipmentSlot = slot.slot_name
                    break
                end
            end
        end

        -- Try pockets for 1x1 items if no equipment slot found
        if not slotType and itemWidth == 1 and itemHeight == 1 then
            for i, pocket in ipairs(inventory.pockets) do
                if not pocket.item then
                    slotType = 'pocket'
                    slotIndex = i - 1
                    break
                end
            end
        end

        -- If no pocket available, try grid
        if not slotType then
            local gridPos, gridRot = Utils.FindAvailablePosition(inventory, itemDef)
            if gridPos then
                slotType = 'grid'
                position = gridPos
                rotation = gridRot
            end
        end

        -- No space found
        if not slotType then
            break
        end

        -- Calculate how much to add in this stack
        local toAdd = math.min(quantity, maxStack)

        -- Create the item
        local instanceId
        if slotType == 'equipment' then
            -- Create item and immediately equip it
            instanceId = Queries.CreateItem(charId, itemId, toAdd, 'equipment', nil, nil, 0, metadata)
            if instanceId then
                Queries.EquipItem(charId, equipmentSlot, instanceId)
                print(string.format('[Inventory] Auto-equipped %s to slot %s during GiveItem', itemId, equipmentSlot))

                -- CRITICAL: Restore stored_items if this is a rig/backpack
                if metadata and metadata.stored_items and (itemDef.type == 'rig' or itemDef.type == 'backpack') then
                    local storedItems = metadata.stored_items
                    local slotType = (itemDef.type == 'rig') and 'rig' or 'backpack_storage'

                    print(string.format('[Inventory] Restoring %d stored items from %s metadata during GiveItem', #storedItems, itemDef.type))

                    -- Recreate each stored item
                    for _, storedItem in ipairs(storedItems) do
                        local newItemId = Queries.CreateItem(
                            charId,
                            storedItem.item_id,
                            storedItem.quantity,
                            slotType,
                            nil,
                            storedItem.position,
                            storedItem.rotation or 0,
                            storedItem.metadata
                        )

                        if newItemId then
                            print(string.format('[Inventory] ✅ Restored item %s (x%d) to %s storage',
                                storedItem.item_id, storedItem.quantity, itemDef.type))
                        else
                            print(string.format('[Inventory] ❌ Failed to restore item %s to %s storage',
                                storedItem.item_id, itemDef.type))
                        end
                    end

                    -- Clear stored_items from metadata (now restored to actual storage)
                    metadata.stored_items = nil
                    Queries.UpdateItemMetadata(instanceId, metadata)
                    print(string.format('[Inventory] Cleared stored_items from %s metadata', itemDef.type))
                end
            end
        else
            -- Create item in pocket or grid
            instanceId = Queries.CreateItem(charId, itemId, toAdd, slotType, slotIndex, position, rotation, metadata)
        end

        givenQuantity = givenQuantity + toAdd
        quantity = quantity - toAdd

        Manager.ClearCache(charId)
    end

    local refusedQuantity = originalQuantity - givenQuantity

    if givenQuantity > 0 then
        return true, {given = givenQuantity, refused = refusedQuantity}
    else
        return false, "Not enough space in inventory"
    end
end

-- Remove item from player
function Manager.RemoveItem(charId, itemInstanceId, quantity)
    quantity = quantity or nil

    if quantity then
        -- Reduce quantity
        Queries.UpdateItemQuantity(itemInstanceId, quantity)
    else
        -- Delete item completely
        Queries.DeleteItem(itemInstanceId)
    end

    Manager.ClearCache(charId)

    return true
end

-- ============================================
-- ITEM MOVEMENT
-- ============================================

--- Rotate item in place (0° → 90° → 180° → 270°)
--- Validates that rotation doesn't cause collision
--- Returns: success (boolean), error (string)
function Manager.RotateItem(charId, itemInstanceId, newRotation)
    -- Validate rotation value
    if newRotation < 0 or newRotation > 3 then
        return false, "Invalid rotation value (must be 0-3)"
    end

    -- Load inventory
    local inventory = Manager.LoadPlayerInventory(charId)
    if not inventory then
        return false, "Could not load inventory"
    end

    -- Find the item
    local item = nil
    local itemPosition = nil

    for _, gridItem in ipairs(inventory.backpack.items) do
        if gridItem.id == itemInstanceId then
            item = gridItem
            itemPosition = gridItem.position
            break
        end
    end

    -- Check rig if not found in backpack
    if not item and inventory.rig and inventory.rig.items then
        for _, rigItem in ipairs(inventory.rig.items) do
            if rigItem.id == itemInstanceId then
                item = rigItem
                itemPosition = rigItem.position
                break
            end
        end
    end

    if not item then
        return false, "Item not found in inventory"
    end

    if not itemPosition then
        return false, "Cannot rotate items in pockets or equipment slots"
    end

    -- Get item definition
    local itemDef = Items[item.item_id]
    if not itemDef then
        return false, "Item definition not found"
    end

    -- If item is 1x1, rotation doesn't matter
    if itemDef.size.width == 1 and itemDef.size.height == 1 then
        return true -- Success but no actual change
    end

    -- Check collision with NEW rotation
    local Utils = require 'server.modules.inventory.utils'
    local Validation = require 'server.modules.inventory.validation'

    -- Get rotated size
    local rotatedSize = Validation.GetRotatedSize(itemDef, newRotation)

    -- Check if rotated item fits in grid bounds
    local gridWidth = inventory.backpack.width
    local gridHeight = inventory.backpack.height

    if itemPosition.x + rotatedSize.width > gridWidth or
       itemPosition.y + rotatedSize.height > gridHeight then
        return false, "Item would exceed grid boundaries after rotation"
    end

    -- Check collision with other items (excluding itself)
    local isOccupied = Utils.IsPositionOccupied(
        inventory,
        itemPosition,
        rotatedSize.width,
        rotatedSize.height,
        newRotation,
        itemInstanceId -- Exclude self from collision check
    )

    if isOccupied then
        return false, "Rotation would cause collision with another item"
    end

    -- OK, update rotation in database
    Queries.RotateItem(itemInstanceId, newRotation)

    Manager.ClearCache(charId)

    print(string.format('[Inventory] CharId %s rotated item %s to rotation %d',
        charId, item.item_id, newRotation))

    return true
end

--- Move item to new position/slot
--- Move item from one location to another
--- data = { item_id (instance ID), from, to, rotation }
function Manager.MoveItem(charId, data)
    -- Extract parameters
    local itemInstanceId = data.item_id
    local from = data.from
    local to = data.to
    local rotation = data.rotation or 0

    -- Validate move structure
    local isValid, error = Validation.ValidateMoveItem(nil, data)
    if not isValid then
        return false, error
    end

    -- Load inventory to get item details
    local inventory = Manager.LoadPlayerInventory(charId)
    if not inventory then
        return false, "Could not load inventory"
    end

    -- Find the item being moved and track source slot name (for equipment unequipping)
    local item = nil
    local sourceEquipmentSlot = nil
    local itemFromContainer = false

    -- If from.type is 'container', load item from external container
    if from.type == 'container' then
        local LootContainers = require 'server.modules.loot.containers'
        local containerId = tonumber(from.container_id)

        if not containerId then
            return false, "Invalid container ID"
        end

        local container = LootContainers.Get(containerId)

        -- Try loading from DB if not in cache
        if not container and containerId < 10000 then
            local Queries = require 'server.modules.inventory.db.queries'
            container = Queries.LoadLootContainer(containerId)
            if container then
                LootContainers.Add(containerId, container)
            end
        end

        if not container then
            return false, "Container not found"
        end

        -- Find item in container
        for _, containerItem in ipairs(container.items or {}) do
            if tostring(containerItem.id) == tostring(itemInstanceId) or tostring(containerItem.item_instance_id) == tostring(itemInstanceId) then
                item = containerItem
                itemFromContainer = true
                break
            end
        end

        if not item then
            return false, "Item not found in container"
        end
    else
        -- Search in player's inventory
        for _, gridItem in ipairs(inventory.backpack.items) do
            if gridItem.id == itemInstanceId then
                item = gridItem
                break
            end
        end

        -- Check pockets
        if not item then
            for _, pocket in ipairs(inventory.pockets) do
                if pocket.item and pocket.item.id == itemInstanceId then
                    item = pocket.item
                    break
                end
            end
        end

        -- Check equipment (and remember which slot it came from)
        if not item then
            for _, equipSlot in ipairs(inventory.equipment) do
                if equipSlot.item and equipSlot.item.id == itemInstanceId then
                    item = equipSlot.item
                    sourceEquipmentSlot = equipSlot.slot_name
                    break
                end
            end
        end

        -- Check rig storage (items stored IN the rig grid)
        if not item and inventory.rig and inventory.rig.items then
            for _, rigItem in ipairs(inventory.rig.items) do
                if rigItem.id == itemInstanceId then
                    item = rigItem
                    break
                end
            end
        end

        -- Check backpack storage (items stored IN the backpack grid)
        if not item and inventory.backpack_storage and inventory.backpack_storage.items then
            for _, backpackItem in ipairs(inventory.backpack_storage.items) do
                if backpackItem.id == itemInstanceId then
                    item = backpackItem
                    break
                end
            end
        end

        if not item then
            return false, "Item not found in inventory"
        end
    end

    -- Get item definition
    local itemDef = Items[item.item_id]
    if not itemDef then
        return false, "Item definition not found"
    end

    -- NOTE: We allow backpacks inside backpacks and rigs inside rigs
    -- The weight system handles this realistically (backpack weight + contained items weight)
    -- The stored_items metadata system keeps items persistent inside containers

    -- VALIDATION: Equipment slots - verify item type matches slot
    if to.type == 'equipment' then
        local slotName = to.slot_name
        if not slotName then
            return false, "Invalid equipment slot"
        end

        -- Define valid item types for each equipment slot
        local validTypes = {
            headgear = {'helmet', 'hat'},
            headset = {'headset'},
            face_cover = {'mask', 'face_cover'},
            armor = {'armor', 'vest'},
            primary = {'weapon', 'rifle', 'smg', 'shotgun', 'sniper'},
            secondary = {'weapon', 'rifle', 'smg', 'shotgun', 'sniper'}, -- Can accept primary weapons too
            holster = {'pistol'},
            sheath = {'melee', 'knife'},
            rig = {'rig', 'chest_rig'},
            backpack = {'backpack'}
        }

        -- Check if slot accepts this item type
        local allowedTypes = validTypes[slotName]
        if allowedTypes then
            local itemType = itemDef.type
            local isValid = false
            for _, validType in ipairs(allowedTypes) do
                if itemType == validType then
                    isValid = true
                    break
                end
            end

            if not isValid then
                return false, string.format("This item cannot be equipped in %s slot (wrong type)", slotName)
            end
        end

        -- Check if slot is already occupied
        for _, equipSlot in ipairs(inventory.equipment) do
            if equipSlot.slot_name == slotName and equipSlot.item then
                return false, string.format("%s slot is already occupied", slotName)
            end
        end
    end

    -- VALIDATION: Pockets only accept 1x1 items
    if to.type == 'pocket' then
        local itemWidth = itemDef.size.width or itemDef.size.w or 1
        local itemHeight = itemDef.size.height or itemDef.size.h or 1
        if itemWidth ~= 1 or itemHeight ~= 1 then
            return false, "This item is too large for pockets (only 1x1 items)"
        end

        -- Check if pocket slot is already occupied
        local pocketIndex = to.slot_index or 0
        if inventory.pockets[pocketIndex + 1] and inventory.pockets[pocketIndex + 1].item then
            return false, "Pocket is already occupied"
        end
    end

    -- VALIDATION: Grid/Rig - check if item fits without collision
    if to.type == 'grid' or to.type == 'rig' or to.type == 'backpack_storage' then
        if not to.position or not to.position.x or not to.position.y then
            return false, "Invalid position for grid placement"
        end

        -- Get item dimensions (with rotation)
        local itemWidth = itemDef.size.width or itemDef.size.w or 1
        local itemHeight = itemDef.size.height or itemDef.size.h or 1

        -- Apply rotation (0 or 2 = normal, 1 or 3 = swapped)
        if rotation == 1 or rotation == 3 then
            itemWidth, itemHeight = itemHeight, itemWidth
        end

        -- Get grid size
        local gridWidth, gridHeight
        if to.type == 'grid' or to.type == 'backpack_storage' then
            gridWidth = inventory.backpack.grid_width or 10
            gridHeight = inventory.backpack.grid_height or 10
        elseif to.type == 'rig' and inventory.rig then
            gridWidth = inventory.rig.grid_width or 4
            gridHeight = inventory.rig.grid_height or 4
        else
            return false, "Invalid destination type"
        end

        -- Check if item fits in grid bounds
        if to.position.x + itemWidth > gridWidth or to.position.y + itemHeight > gridHeight then
            return false, "Item doesn't fit at this position (out of bounds)"
        end

        -- Check for collisions with other items (using Utils.IsPositionOccupied)
        local Utils = require 'server.modules.inventory.utils'
        local isOccupied = Utils.IsPositionOccupied(
            inventory,
            to.position, -- Pass position object, not separate x/y
            itemWidth,
            itemHeight,
            rotation, -- Pass rotation
            itemInstanceId, -- Exclude self from collision check
            to.type -- Pass grid type (grid, rig, backpack_storage)
        )

        if isOccupied then
            return false, "This space is already occupied by another item"
        end
    end

    -- Allow weapons, equipment, and all other items in backpack/grid
    -- (No restriction - everything can go in backpack except backpack itself)

    -- SPECIAL CASE: If moving FROM equipment TO anywhere else, we need to unequip first
    if sourceEquipmentSlot and to.type ~= 'equipment' then
        -- Clear the equipment slot reference in DB
        MySQL.update.await([[
            UPDATE equipment
            SET item_instance_id = NULL
            WHERE charid = ? AND slot_name = ?
        ]], { charId, sourceEquipmentSlot })

        print(string.format('[Inventory] Auto-unequipped %s from %s slot before moving to %s',
            itemDef.name, sourceEquipmentSlot, to.type))
    end

    -- SPECIAL CASE: If moving TO equipment slot AND item is rig/backpack with stored_items
    if to.type == 'equipment' and item.metadata and item.metadata.stored_items then
        local storedItems = item.metadata.stored_items
        local slotType = (itemDef.type == 'rig') and 'rig' or 'backpack_storage'

        print(string.format('[Inventory] Restoring %d stored items to %s during move', #storedItems, slotType))

        -- Recreate each stored item in inventory
        for _, storedItem in ipairs(storedItems) do
            -- Create item in database
            local newItemId = Queries.CreateItem(
                charId,
                storedItem.item_id,
                storedItem.quantity,
                slotType,
                nil, -- slot_index
                storedItem.position,
                storedItem.rotation or 0,
                storedItem.metadata
            )

            print(string.format('[Inventory] Restored item %s (id: %d) to %s at position (%d,%d)',
                storedItem.item_id, newItemId, slotType,
                storedItem.position and storedItem.position.x or 0,
                storedItem.position and storedItem.position.y or 0))
        end

        -- Clear stored_items from metadata
        item.metadata.stored_items = nil

        -- Update item metadata in DB to remove stored_items
        Queries.UpdateItemMetadata(itemInstanceId, item.metadata)

        print(string.format('[Inventory] Restored %d items from container metadata during move', #storedItems))
    end

    -- If item came from container, handle differently (create new item in player inventory + remove from container)
    if itemFromContainer then
        -- Check if moving to SAME container (just repositioning within container)
        if to.type == 'container' and tonumber(to.container_id) == tonumber(from.container_id) then
            -- Moving within same container - just update position
            local LootContainers = require 'server.modules.loot.containers'
            local container = LootContainers.Get(tonumber(from.container_id))

            if container then
                -- Find and update item position in container
                for i, containerItem in ipairs(container.items or {}) do
                    if tostring(containerItem.id) == tostring(itemInstanceId) or tostring(containerItem.item_instance_id) == tostring(itemInstanceId) then
                        container.items[i].position = to.position
                        container.items[i].rotation = rotation
                        break
                    end
                end

                -- Update container in database
                if tonumber(from.container_id) < 10000 then
                    local Queries = require 'server.modules.inventory.db.queries'
                    Queries.UpdateLootContainer(from.container_id, container.items)
                end

                -- Notify all clients
                LootContainers.NotifyUpdate(tonumber(from.container_id), container)

                print(string.format('[Inventory] Repositioned item %s within container %s', item.item_id, from.container_id))
            end
        else
            -- Moving from container to player inventory/equipment
            -- Create new item in player inventory
            local newItemId = Queries.CreateItem(
                charId,
                item.item_id,
                item.quantity,
                to.type,
                to.slot_index,
                to.position,
                rotation,
                item.metadata
            )

            -- Update equipment table if moving TO equipment
            if to.type == 'equipment' then
                Queries.EquipItem(charId, to.slot_name, newItemId)
                print(string.format('[Inventory] Equipped item %s to slot %s from container', item.item_id, to.slot_name))
            end

            -- Remove item from container
            local LootContainers = require 'server.modules.loot.containers'
            local container = LootContainers.Get(tonumber(from.container_id))

            if container then
                -- Find and remove item from container's items array
                for i, containerItem in ipairs(container.items or {}) do
                    if tostring(containerItem.id) == tostring(itemInstanceId) or tostring(containerItem.item_instance_id) == tostring(itemInstanceId) then
                        table.remove(container.items, i)
                        break
                    end
                end

                -- Update container in database (skip for test containers with ID > 10000)
                if tonumber(from.container_id) < 10000 then
                    local Queries = require 'server.modules.inventory.db.queries'
                    Queries.UpdateLootContainer(from.container_id, container.items)
                end

                -- Notify all clients that container was updated
                LootContainers.NotifyUpdate(tonumber(from.container_id), container)

                print(string.format('[Inventory] Removed item %s from container %s', item.item_id, from.container_id))
            end
        end
    else
        -- Check if moving TO container (player inventory -> external container)
        if to.type == 'container' then
            local LootContainers = require 'server.modules.loot.containers'
            local LootQueries = require 'server.modules.inventory.db.queries'
            local containerId = tonumber(to.container_id)

            if not containerId then
                return false, "Invalid destination container ID"
            end

            local container = LootContainers.Get(containerId)
            if not container then
                return false, "Destination container not found"
            end

            -- SPECIAL HANDLING: If moving rig/backpack, save contained items in metadata
            local metadata = item.metadata or {}
            if itemDef.type == 'rig' or itemDef.type == 'backpack' then
                local storedItems = {}

                -- Collect items from rig storage
                if itemDef.type == 'rig' and inventory.rig and inventory.rig.items then
                    for _, rigItem in ipairs(inventory.rig.items) do
                        table.insert(storedItems, {
                            id = rigItem.id,
                            item_id = rigItem.item_id,
                            quantity = rigItem.quantity,
                            position = rigItem.position,
                            rotation = rigItem.rotation,
                            metadata = rigItem.metadata
                        })
                        -- Delete the item from database (it's now stored in metadata)
                        Queries.DeleteItem(tonumber(rigItem.id))
                    end
                    print(string.format('[Inventory] Stored %d items from rig into metadata before moving to container', #storedItems))
                end

                -- Collect items from backpack storage
                if itemDef.type == 'backpack' and inventory.backpack_storage and inventory.backpack_storage.items then
                    for _, backpackItem in ipairs(inventory.backpack_storage.items) do
                        table.insert(storedItems, {
                            id = backpackItem.id,
                            item_id = backpackItem.item_id,
                            quantity = backpackItem.quantity,
                            position = backpackItem.position,
                            rotation = backpackItem.rotation,
                            metadata = backpackItem.metadata
                        })
                        -- Delete the item from database (it's now stored in metadata)
                        Queries.DeleteItem(tonumber(backpackItem.id))
                    end
                    print(string.format('[Inventory] Stored %d items from backpack into metadata before moving to container', #storedItems))
                end

                -- Save stored items in metadata
                if #storedItems > 0 then
                    metadata.stored_items = storedItems
                end
            end

            -- Remove item from player inventory
            Queries.DeleteItem(itemInstanceId)

            -- Add to container's items array
            table.insert(container.items, {
                id = itemInstanceId,
                item_instance_id = itemInstanceId,
                item_id = item.item_id,
                quantity = item.quantity,
                position = to.position or { x = 0, y = 0 },
                rotation = rotation or 0,
                slot_type = 'grid',
                metadata = metadata
            })

            -- Update container in database (skip for test containers)
            if containerId < 10000 then
                LootQueries.UpdateLootContainer(containerId, container.items)
            end

            -- Notify all clients that container was updated
            LootContainers.NotifyUpdate(containerId, container)

            print(string.format('[Inventory] Moved item %s to container %d', item.item_id, containerId))
        else
            -- Normal move within player inventory
            Queries.MoveItem(itemInstanceId, to.type, to.slot_index, to.position, rotation)

            -- Update equipment table if moving TO equipment
            if to.type == 'equipment' then
                Queries.EquipItem(charId, to.slot_name, itemInstanceId)
                print(string.format('[Inventory] Equipped item %d to slot %s via move', itemInstanceId, to.slot_name))
            end
        end
    end

    Manager.ClearCache(charId)

    return true
end

-- ============================================
-- CLIENT SYNC
-- ============================================

-- Convert item definition to client format (TypeScript expects different key names)
local function ConvertItemDefForClient(def)
    local converted = {}
    for k, v in pairs(def) do
        converted[k] = v
    end

    -- Convert size.w/h to size.width/height
    if def.size then
        converted.size = {
            width = def.size.w or def.size.width,
            height = def.size.h or def.size.height
        }
    end

    return converted
end

--- Send full inventory to client and open UI
function Manager.SyncToClient(charId, playerId)
    Manager.ClearCache(charId)
    local inventory = Manager.LoadPlayerInventory(charId)

    -- Convert item definitions to client format
    local itemDefs = {}
    for itemId, def in pairs(Items) do
        itemDefs[itemId] = ConvertItemDefForClient(def)
    end

    TriggerClientEvent('inventory:open', playerId, inventory, itemDefs)
end

--- Update inventory without opening UI (for background updates like /giveitem)
function Manager.UpdateClient(charId, playerId)
    Manager.ClearCache(charId)
    local inventory = Manager.LoadPlayerInventory(charId)

    -- Convert item definitions to client format
    local itemDefs = {}
    for itemId, def in pairs(Items) do
        itemDefs[itemId] = ConvertItemDefForClient(def)
    end

    TriggerClientEvent('inventory:update', playerId, inventory, itemDefs)
end

-- ============================================
-- CONTEXT MENU ACTIONS
-- ============================================

--- Unequip item from equipment slot
--- Priority: Pockets first → Rig slots → Backpack grid
--- Returns: success (boolean), error (string)
function Manager.UnequipItem(charId, itemInstanceId)
    -- Load inventory
    local inventory = Manager.LoadPlayerInventory(charId)
    if not inventory then
        return false, "Could not load inventory"
    end

    -- Find the equipped item
    local equipmentSlot = nil
    local equippedItem = nil

    for _, slot in ipairs(inventory.equipment) do
        if slot.item and slot.item.id == itemInstanceId then
            equipmentSlot = slot.slot_name
            equippedItem = slot.item
            break
        end
    end

    if not equipmentSlot or not equippedItem then
        return false, "Item not found in equipment"
    end

    -- Get item definition
    local itemDef = Items[equippedItem.item_id]
    if not itemDef then
        return false, "Item definition not found"
    end

    -- IMPORTANT: If unequipping rig or backpack, check if they contain items
    if equipmentSlot == 'rig' then
        if inventory.rig and inventory.rig.items then
            if #inventory.rig.items > 0 then
                return false, "Cannot unequip rig while it contains items. Empty the rig first."
            end
        end
    elseif equipmentSlot == 'backpack' then
        if inventory.backpack_storage and inventory.backpack_storage.items then
            if #inventory.backpack_storage.items > 0 then
                return false, "Cannot unequip backpack while it contains items. Empty the backpack first."
            end
        end
    end

    local Utils = require 'server.modules.inventory.utils'
    local itemWidth = itemDef.size.w or itemDef.size.width or 1
    local itemHeight = itemDef.size.h or itemDef.size.height or 1
    local targetSlotType = nil
    local targetSlotIndex = nil
    local targetPosition = nil
    local targetRotation = 0

    -- Priority 1: Try pockets first (only for 1x1 items)
    if itemWidth == 1 and itemHeight == 1 then
        for i, pocket in ipairs(inventory.pockets) do
            if not pocket.item then
                targetSlotType = 'pocket'
                targetSlotIndex = i - 1
                break
            end
        end
    end

    -- Priority 2: Try rig grid (if rig equipped and item fits)
    if not targetSlotType and inventory.rig then
        -- Use Utils.FindAvailablePosition but pass rig grid instead of backpack
        local rigInventory = {
            backpack = {
                grid_width = inventory.rig.width or 4,
                grid_height = inventory.rig.height or 4,
                items = inventory.rig.items or {}
            }
        }
        local position, rotation = Utils.FindAvailablePosition(rigInventory, itemDef)

        if position then
            targetSlotType = 'rig'
            targetPosition = position
            targetRotation = rotation or 0
        end
    end

    -- Priority 3: Try backpack grid as last resort
    if not targetSlotType then
        local position, rotation = Utils.FindAvailablePosition(inventory, itemDef)

        if position then
            targetSlotType = 'grid'
            targetPosition = position
            targetRotation = rotation or 0
        end
    end

    -- No space found anywhere
    if not targetSlotType then
        return false, "Not enough space in inventory (pockets, rig, or backpack)"
    end

    -- Move item from equipment to target location
    Queries.UnequipItem(charId, equipmentSlot, itemInstanceId, targetPosition, targetRotation)

    -- If moved to rig or pocket, update slot_type and slot_index
    if targetSlotType ~= 'grid' then
        Queries.MoveItem(itemInstanceId, targetSlotType, targetSlotIndex, nil, 0)
    end

    Manager.ClearCache(charId)

    print(string.format('[Inventory] CharId %s unequipped %s from %s to %s',
        charId, equippedItem.item_id, equipmentSlot, targetSlotType))

    return true, equipmentSlot
end

--- Equip item to equipment slot
--- Validates slot compatibility and unequips current item if slot occupied
--- Returns: success (boolean), error (string)
function Manager.EquipItem(charId, itemInstanceId, slotName)
    -- Load inventory
    local inventory = Manager.LoadPlayerInventory(charId)
    if not inventory then
        return false, "Could not load inventory"
    end

    -- Find the item to equip (can be in grid, pockets, or rig)
    local itemToEquip = nil
    local sourceSlotType = nil
    local sourceSlotIndex = nil
    local sourcePosition = nil

    -- Check grid
    for _, item in ipairs(inventory.backpack.items) do
        if item.id == itemInstanceId then
            itemToEquip = item
            sourceSlotType = 'grid'
            sourcePosition = item.position
            break
        end
    end

    -- Check pockets
    if not itemToEquip then
        for i, pocket in ipairs(inventory.pockets) do
            if pocket.item and pocket.item.id == itemInstanceId then
                itemToEquip = pocket.item
                sourceSlotType = 'pocket'
                sourceSlotIndex = i - 1
                break
            end
        end
    end

    -- Check rig
    if not itemToEquip and inventory.rig and inventory.rig.items then
        for _, item in ipairs(inventory.rig.items) do
            if item.id == itemInstanceId then
                itemToEquip = item
                sourceSlotType = 'rig'
                break
            end
        end
    end

    if not itemToEquip then
        return false, "Item not found in inventory"
    end

    -- Get item definition
    local itemDef = Items[itemToEquip.item_id]
    if not itemDef then
        return false, "Item definition not found"
    end

    -- Validate slot compatibility
    local validSlots = {
        head = {'helmet', 'gasmask'},
        armor = {'armor'},
        rig = {'rig'},
        backpack = {'backpack'},
        holster = {'pistol'},
        melee = {'melee'},
        primary = {'primary'},
        secondary = {'secondary'}
    }

    local allowedCategories = validSlots[slotName]
    if not allowedCategories then
        return false, "Invalid equipment slot"
    end

    -- Check if item category matches slot
    local isCompatible = false
    for _, category in ipairs(allowedCategories) do
        if itemDef.category == category then
            isCompatible = true
            break
        end
    end

    if not isCompatible then
        return false, string.format("Cannot equip %s in %s slot", itemDef.name or itemDef.type, slotName)
    end

    -- Special validation: Armored rig blocks armor slot
    if slotName == 'rig' and itemDef.has_armor then
        -- Check if armor is equipped
        for _, slot in ipairs(inventory.equipment) do
            if slot.slot_name == 'armor' and slot.item then
                return false, "Unequip armor before equipping armored rig"
            end
        end
    end

    if slotName == 'armor' then
        -- Check if armored rig is equipped
        for _, slot in ipairs(inventory.equipment) do
            if slot.slot_name == 'rig' and slot.item then
                local rigDef = Items[slot.item.item_id]
                if rigDef and rigDef.has_armor then
                    return false, "Armored rig already equipped (blocks armor slot)"
                end
            end
        end
    end

    -- Check if slot is occupied - if yes, unequip current item first
    for _, slot in ipairs(inventory.equipment) do
        if slot.slot_name == slotName and slot.item then
            print(string.format('[Inventory] Slot %s occupied, unequipping current item first', slotName))

            -- Unequip current item (this will find space in pockets/rig/grid)
            local success, error = Manager.UnequipItem(charId, slot.item.id)
            if not success then
                return false, "Could not unequip current item: " .. error
            end

            -- Reload inventory after unequip
            Manager.ClearCache(charId)
            inventory = Manager.LoadPlayerInventory(charId)
            break
        end
    end

    -- Now equip the new item
    Queries.EquipItem(charId, slotName, itemInstanceId)

    -- Remove item from source location (grid/pocket/rig)
    -- The item still exists in inventory_items, but we clear its grid position
    if sourceSlotType == 'grid' then
        -- Clear grid position (item stays in inventory_items but position = NULL)
        Queries.MoveItem(itemInstanceId, 'equipment', nil, nil, 0)
    elseif sourceSlotType == 'pocket' then
        -- Clear pocket slot
        Queries.MoveItem(itemInstanceId, 'equipment', nil, nil, 0)
    elseif sourceSlotType == 'rig' then
        -- Clear rig slot
        Queries.MoveItem(itemInstanceId, 'equipment', nil, nil, 0)
    end

    -- SPECIAL HANDLING: If equipping rig/backpack with stored_items, restore them to inventory
    if itemToEquip.metadata and itemToEquip.metadata.stored_items then
        local storedItems = itemToEquip.metadata.stored_items
        local slotType = (itemDef.type == 'rig') and 'rig' or 'backpack_storage'

        print(string.format('[Inventory] Restoring %d stored items to %s', #storedItems, slotType))

        -- Recreate each stored item in inventory
        for _, storedItem in ipairs(storedItems) do
            -- Create item in database
            local newItemId = Queries.CreateItem(
                charId,
                storedItem.item_id,
                storedItem.quantity,
                slotType,
                nil, -- slot_index
                storedItem.position,
                storedItem.rotation or 0,
                storedItem.metadata
            )

            print(string.format('[Inventory] Restored item %s (id: %d) to %s at position (%d,%d)',
                storedItem.item_id, newItemId, slotType,
                storedItem.position and storedItem.position.x or 0,
                storedItem.position and storedItem.position.y or 0))
        end

        -- Clear stored_items from metadata
        itemToEquip.metadata.stored_items = nil

        -- Update item metadata in DB to remove stored_items
        Queries.UpdateItemMetadata(itemInstanceId, itemToEquip.metadata)

        print(string.format('[Inventory] Restored %d items from container metadata', #storedItems))
    end

    Manager.ClearCache(charId)

    print(string.format('[Inventory] CharId %s equipped %s to slot %s',
        charId, itemToEquip.item_id, slotName))

    return true, itemDef
end

--- Unload magazine from weapon
--- Priority: Pockets first → Rig slots → Backpack grid
--- Returns: success (boolean), error (string)
function Manager.UnloadMagazine(charId, weaponInstanceId)
    -- Load inventory
    local inventory = Manager.LoadPlayerInventory(charId)
    if not inventory then
        return false, "Could not load inventory"
    end

    -- Find the weapon (can be in grid, equipment, or pocket)
    local weapon = nil

    -- Check grid
    for _, item in ipairs(inventory.backpack.items) do
        if item.id == weaponInstanceId then
            weapon = item
            break
        end
    end

    -- Check equipment
    if not weapon then
        for _, slot in ipairs(inventory.equipment) do
            if slot.item and slot.item.id == weaponInstanceId then
                weapon = slot.item
                break
            end
        end
    end

    -- Check pockets
    if not weapon then
        for _, pocket in ipairs(inventory.pockets) do
            if pocket.item and pocket.item.id == weaponInstanceId then
                weapon = pocket.item
                break
            end
        end
    end

    if not weapon then
        return false, "Weapon not found"
    end

    -- Check if weapon has loaded magazine
    if not weapon.metadata or not weapon.metadata.loaded_magazine then
        return false, "No magazine loaded"
    end

    local magazineId = weapon.metadata.loaded_magazine
    local magazineItemDef = Items[magazineId]

    if not magazineItemDef then
        return false, "Magazine definition not found"
    end

    local Utils = require 'server.modules.inventory.utils'
    local magWidth = magazineItemDef.size.w or magazineItemDef.size.width or 1
    local magHeight = magazineItemDef.size.h or magazineItemDef.size.height or 1
    local targetSlotType = nil
    local targetSlotIndex = nil
    local targetPosition = nil
    local targetRotation = 0

    -- Priority 1: Try pockets first (only for 1x1 magazines)
    if magWidth == 1 and magHeight == 1 then
        for i, pocket in ipairs(inventory.pockets) do
            if not pocket.item then
                targetSlotType = 'pocket'
                targetSlotIndex = i - 1
                break
            end
        end
    end

    -- Priority 2: Try rig grid (magazines often go in rig)
    if not targetSlotType and inventory.rig then
        -- Use Utils.FindAvailablePosition but pass rig grid instead of backpack
        local rigInventory = {
            backpack = {
                grid_width = inventory.rig.width or 4,
                grid_height = inventory.rig.height or 4,
                items = inventory.rig.items or {}
            }
        }
        local position, rotation = Utils.FindAvailablePosition(rigInventory, magazineItemDef)

        if position then
            targetSlotType = 'rig'
            targetPosition = position
            targetRotation = rotation or 0
        end
    end

    -- Priority 3: Try backpack grid as last resort
    if not targetSlotType then
        local position, rotation = Utils.FindAvailablePosition(inventory, magazineItemDef)

        if position then
            targetSlotType = 'grid'
            targetPosition = position
            targetRotation = rotation or 0
        end
    end

    -- No space found anywhere
    if not targetSlotType then
        return false, "Not enough space for magazine"
    end

    -- Create magazine item in target location
    Queries.CreateItem(charId, magazineId, 1, targetSlotType, targetSlotIndex, targetPosition, targetRotation, nil)

    -- Remove magazine from weapon metadata
    local updatedMetadata = weapon.metadata or {}
    updatedMetadata.loaded_magazine = nil
    Queries.UpdateItemMetadata(weaponInstanceId, updatedMetadata)
    Manager.ClearCache(charId)

    print(string.format('[Inventory] CharId %s unloaded magazine %s from weapon to %s',
        charId, magazineId, targetSlotType))

    return true
end

--- Split stack (context menu action)
--- Returns: success (boolean), error (string)
function Manager.SplitStack(charId, itemInstanceId, splitAmount)
    -- Load inventory
    local inventory = Manager.LoadPlayerInventory(charId)
    if not inventory then
        return false, "Could not load inventory"
    end

    -- Find the item
    local sourceItem = nil

    -- Check grid
    for _, item in ipairs(inventory.backpack.items) do
        if item.id == itemInstanceId then
            sourceItem = item
            break
        end
    end

    -- Check pockets
    if not sourceItem then
        for _, pocket in ipairs(inventory.pockets) do
            if pocket.item and pocket.item.id == itemInstanceId then
                sourceItem = pocket.item
                break
            end
        end
    end

    if not sourceItem then
        return false, "Item not found"
    end

    -- Validate split amount
    if splitAmount < 1 or splitAmount >= sourceItem.quantity then
        return false, "Invalid split amount"
    end

    -- Get item definition
    local itemDef = Items[sourceItem.item_id]
    if not itemDef or not itemDef.stackable then
        return false, "Item is not stackable"
    end

    -- Find space for new stack
    local Utils = require 'server.modules.inventory.utils'
    local position, rotation = Utils.FindAvailablePosition(inventory, itemDef)

    if not position then
        return false, "Not enough space for split stack"
    end

    -- Reduce quantity of source item
    Queries.UpdateItemQuantity(itemInstanceId, sourceItem.quantity - splitAmount)

    -- Create new stack
    Queries.CreateItem(charId, sourceItem.item_id, splitAmount, 'grid', nil, position, rotation or 0, sourceItem.metadata)
    Manager.ClearCache(charId)

    return true
end

--- Use item (medical, food, consumable)
--- Applies effects and consumes/reduces quantity
--- Returns: success (boolean), error OR effects table
function Manager.UseItem(charId, itemInstanceId, playerId)
    -- Load inventory
    local inventory = Manager.LoadPlayerInventory(charId)
    if not inventory then
        return false, "Could not load inventory"
    end

    -- Find the item
    local item = nil

    -- Check grid
    for _, gridItem in ipairs(inventory.backpack.items) do
        if gridItem.id == itemInstanceId then
            item = gridItem
            break
        end
    end

    -- Check pockets
    if not item then
        for _, pocket in ipairs(inventory.pockets) do
            if pocket.item and pocket.item.id == itemInstanceId then
                item = pocket.item
                break
            end
        end
    end

    if not item then
        return false, "Item not found in inventory"
    end

    -- Get item definition
    local itemDef = Items[item.item_id]
    if not itemDef then
        return false, "Item definition not found"
    end

    -- Check if item is usable
    if not itemDef.usable and itemDef.type ~= 'medical' and itemDef.type ~= 'consumable' then
        return false, "This item cannot be used"
    end

    -- Execute effects based on item type
    local effects = itemDef.effects or {}
    local appliedEffects = {}

    -- Medical items (heal, stop bleeding, fix fracture, remove pain)
    if itemDef.type == 'medical' then
        for _, effect in ipairs(effects) do
            if effect.type == 'heal' then
                -- Heal specific zone or all zones
                table.insert(appliedEffects, {
                    type = 'heal',
                    amount = effect.amount,
                    zone = effect.zone or 'all'
                })
            elseif effect.type == 'stop_bleeding' or effect.type == 'stop_bleeding_instant' then
                table.insert(appliedEffects, {
                    type = 'stop_bleeding',
                    zone = effect.zone or 'all',
                    instant = effect.type == 'stop_bleeding_instant'
                })
            elseif effect.type == 'fix_fracture' then
                table.insert(appliedEffects, {
                    type = 'fix_fracture',
                    zone = effect.zone or 'all'
                })
            elseif effect.type == 'remove_malus' or effect.type == 'reduce_pain' then
                table.insert(appliedEffects, {
                    type = 'pain_relief',
                    amount = effect.amount or 100,
                    duration = effect.duration or 30
                })
            end
        end
    end

    -- Consumables (food, water, energy)
    if itemDef.type == 'consumable' then
        for _, effect in ipairs(effects) do
            if effect.type == 'hunger' then
                table.insert(appliedEffects, {
                    type = 'hunger',
                    amount = effect.amount
                })
            elseif effect.type == 'hydration' then
                table.insert(appliedEffects, {
                    type = 'hydration',
                    amount = effect.amount
                })
            elseif effect.type == 'stamina' then
                table.insert(appliedEffects, {
                    type = 'stamina',
                    amount = effect.amount
                })
            elseif effect.type == 'stamina_regen_boost' then
                table.insert(appliedEffects, {
                    type = 'stamina_boost',
                    duration = effect.duration
                })
            end
        end
    end

    -- Trigger client event to apply effects (health, hunger, stamina, etc.)
    if #appliedEffects > 0 then
        TriggerClientEvent('player:applyItemEffects', playerId, {
            item_id = item.item_id,
            item_name = itemDef.name or itemDef.type,
            effects = appliedEffects,
            use_time = itemDef.use_time or 0
        })
    end

    -- ============================================
    -- DURABILITY SYSTEM
    -- ============================================
    -- Check if item has durability metadata
    local hasDurability = item.metadata and item.metadata.durability and item.metadata.max_durability

    if hasDurability then
        -- Item has durability - reduce it instead of deleting
        local durabilityReduction = 1 -- Default: -1 per use

        -- Special cases for different item types
        if itemDef.metadata_template and itemDef.metadata_template.heal_per_use then
            -- Health syringes: reduce by heal amount (e.g., -30 for basic syringe)
            durabilityReduction = itemDef.metadata_template.heal_per_use
        elseif itemDef.type == 'consumable' then
            -- Consumables (water bottles, juice bottles): -10 per sip
            durabilityReduction = 10
        end

        -- Calculate new durability
        local newDurability = item.metadata.durability - durabilityReduction

        if newDurability <= 0 then
            -- Durability depleted - delete item
            Queries.DeleteItem(itemInstanceId)
            print(string.format('[Inventory] Item %s depleted (durability 0)', item.item_id))
        else
            -- Update durability in metadata
            item.metadata.durability = newDurability
            Queries.UpdateItemMetadata(itemInstanceId, item.metadata)
            print(string.format('[Inventory] Item %s durability: %d/%d',
                item.item_id, newDurability, item.metadata.max_durability))
        end
    else
        -- ============================================
        -- NO DURABILITY - Use old logic
        -- ============================================
        -- Stackable items (canned drinks, bandages, etc.)
        if itemDef.stackable and item.quantity > 1 then
            -- Reduce quantity by 1
            Queries.UpdateItemQuantity(itemInstanceId, item.quantity - 1)
        else
            -- Delete item completely
            Queries.DeleteItem(itemInstanceId)
        end
    end

    Manager.ClearCache(charId)

    print(string.format('[Inventory] CharId %s used item %s (effects: %d)',
        charId, item.item_id, #appliedEffects))

    return true, appliedEffects
end

--- Drop item on ground (removes from inventory and creates world prop)
--- Returns: success (boolean), error (string)
function Manager.DropItem(charId, itemInstanceId, playerId)
    -- Load inventory to verify item exists
    local inventory = Manager.LoadPlayerInventory(charId)
    if not inventory then
        return false, "Could not load inventory"
    end

    -- Find the item being dropped
    local droppedItem = nil

    -- Check grid
    for _, item in ipairs(inventory.backpack.items) do
        if item.id == itemInstanceId then
            droppedItem = item
            break
        end
    end

    -- Check pockets
    if not droppedItem then
        for _, pocket in ipairs(inventory.pockets) do
            if pocket.item and pocket.item.id == itemInstanceId then
                droppedItem = pocket.item
                break
            end
        end
    end

    -- Check rig storage
    if not droppedItem and inventory.rig and inventory.rig.items then
        for _, item in ipairs(inventory.rig.items) do
            if item.id == itemInstanceId then
                droppedItem = item
                break
            end
        end
    end

    -- Check equipment (allow dropping equipped items - will auto-unequip)
    if not droppedItem then
        for _, slot in ipairs(inventory.equipment) do
            if slot.item and slot.item.id == itemInstanceId then
                droppedItem = slot.item
                -- Mark for unequip
                droppedItem._was_equipped = true
                droppedItem._equipment_slot = slot.slot_name
                break
            end
        end
    end

    if not droppedItem then
        return false, "Item not found in inventory"
    end

    -- Get item definition
    local itemDef = Items[droppedItem.item_id]
    if not itemDef then
        return false, "Item definition not found"
    end

    -- SPECIAL HANDLING: If dropping rig/backpack, save contained items in metadata
    if itemDef.type == 'rig' or itemDef.type == 'backpack' then
        local storedItems = {}

        -- Collect items from rig storage
        if itemDef.type == 'rig' and inventory.rig and inventory.rig.items then
            for _, item in ipairs(inventory.rig.items) do
                table.insert(storedItems, {
                    id = item.id,
                    item_id = item.item_id,
                    quantity = item.quantity,
                    position = item.position,
                    rotation = item.rotation,
                    metadata = item.metadata
                })
            end
            print(string.format('[Inventory] Stored %d items from rig storage into metadata', #storedItems))
        end

        -- Collect items from backpack storage
        if itemDef.type == 'backpack' and inventory.backpack_storage and inventory.backpack_storage.items then
            for _, item in ipairs(inventory.backpack_storage.items) do
                table.insert(storedItems, {
                    id = item.id,
                    item_id = item.item_id,
                    quantity = item.quantity,
                    position = item.position,
                    rotation = item.rotation,
                    metadata = item.metadata
                })
            end
            print(string.format('[Inventory] Stored %d items from backpack storage into metadata', #storedItems))
        end

        -- Save items in metadata
        if #storedItems > 0 then
            droppedItem.metadata = droppedItem.metadata or {}
            droppedItem.metadata.stored_items = storedItems

            -- Delete the contained items from inventory (they're now in metadata)
            for _, storedItem in ipairs(storedItems) do
                Queries.DeleteItem(storedItem.id)
            end
            print(string.format('[Inventory] Deleted %d contained items (now in container metadata)', #storedItems))
        end
    end

    -- If item was equipped, unequip it IMMEDIATELY (clear slot in DB)
    if droppedItem._was_equipped and droppedItem._equipment_slot then
        MySQL.update.await([[
            UPDATE equipment
            SET item_instance_id = NULL
            WHERE charid = ? AND slot_name = ?
        ]], { charId, droppedItem._equipment_slot })
        print(string.format('[Inventory] Immediately unequipped item from slot %s for drop', droppedItem._equipment_slot))
    end

    -- DELETE ITEM IMMEDIATELY to prevent visual bug when reopening inventory
    -- If animation fails (rare), the item is lost, but this prevents confusion
    Queries.DeleteItem(itemInstanceId)
    Manager.ClearCache(charId)
    print(string.format('[Inventory] Immediately deleted item %d from inventory for drop', itemInstanceId))

    -- Trigger client event to play drop animation and create visual prop
    -- Client will calculate the exact drop position and send it back to create the container
    TriggerClientEvent('inventory:clientDropItem', playerId, {
        item_id = droppedItem.item_id,
        item_name = itemDef.name or droppedItem.item_id,
        quantity = droppedItem.quantity,
        model = itemDef.world_prop or `prop_cs_cardbox_01`, -- Use world_prop or fallback
        weight = itemDef.weight or 1.0, -- Item weight in kg for throw physics
        metadata = droppedItem.metadata,
        charId = charId,
        itemInstanceId = itemInstanceId, -- Send instance ID (already deleted)
        was_equipped = droppedItem._was_equipped or false, -- Pass equipment status
        equipment_slot = droppedItem._equipment_slot -- Pass slot name if equipped
    })

    print(string.format('[Inventory] CharId %s initiating drop for item %s (x%d) - item already deleted',
        charId, droppedItem.item_id, droppedItem.quantity))

    return true
end

--- Create loot container after client calculated drop position
--- Called by client after animation completes
--- @param charId string Character ID
--- @param itemData table Item data (item_id, quantity, metadata, itemInstanceId)
--- @param dropCoords vector3 Drop position
--- @param rotation table|number Full rotation {pitch, roll, yaw} or heading only
--- @return number containerId
function Manager.CreateDroppedContainer(charId, itemData, dropCoords, rotation)
    -- Support both legacy heading and new rotation format
    local heading, rotationData
    if type(rotation) == 'table' then
        -- Full rotation provided
        rotationData = rotation
        heading = rotation.yaw or 0.0
    else
        -- Legacy heading only
        heading = rotation or 0.0
        rotationData = nil
    end

    -- Create loot container for dropped item (with full rotation)
    local containerId = Queries.CreateLootContainer(
        'dropped_item',
        dropCoords,
        1, -- 1x1 grid for single item
        1,
        {
            item_id = itemData.item_id,
            quantity = itemData.quantity,
            metadata = itemData.metadata,
            dropped_by_charid = charId,
            dropped_at = os.time()
        },
        heading, -- Pass heading for backward compatibility
        rotationData -- Pass full rotation (pitch, roll, yaw)
    )

    -- Item was already deleted in DropItem() function
    -- No need to delete again here
    if not itemData.itemInstanceId then
        print('^3[Inventory] WARNING: No itemInstanceId provided^0')
    end

    -- Add to loot containers cache (with heading in position and full rotation)
    local LootContainers = require 'server.modules.loot.containers'
    LootContainers.Add(containerId, {
        container_id = containerId,
        container_type = 'dropped_item',
        position = {
            x = dropCoords.x,
            y = dropCoords.y,
            z = dropCoords.z,
            heading = heading
        },
        rotation = rotationData, -- Store full rotation for spawn
        items = {{
            item_id = itemData.item_id,
            quantity = itemData.quantity,
            metadata = itemData.metadata
        }}
    })

    if rotationData then
        print(string.format('[Inventory] Created container %d at %s (rotation: %.1f/%.1f/%.1f)',
            containerId, dropCoords, rotationData.pitch, rotationData.roll, rotationData.yaw))
    else
        print(string.format('[Inventory] Created container %d at %s (heading: %.1f)', containerId, dropCoords, heading))
    end

    return containerId
end

return Manager
