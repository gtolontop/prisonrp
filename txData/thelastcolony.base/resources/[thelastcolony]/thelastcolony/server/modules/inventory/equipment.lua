-- ========================================
-- EQUIPMENT MANAGER
-- Handles equipping/unequipping items with validation
-- ========================================

-- Permanent items that cannot be removed
local PERMANENT_SLOTS = {
    ['sheath'] = true,
    ['case'] = true  -- Secure case (contains card + compass)
}

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

---@param playerId number
---@param slotName string
---@return table|nil
local function GetEquippedItem(playerId, slotName)
    -- À implémenter selon ton système de DB
    -- Retourne l'item équipé dans ce slot ou nil
    return nil
end

---@param playerId number
---@param item table
---@param slotName string
local function EquipItemDB(playerId, item, slotName)
    -- À implémenter selon ton système de DB
    -- Équipe l'item dans la base de données
end

---@param playerId number
---@param slotName string
local function UnequipItemDB(playerId, slotName)
    -- À implémenter selon ton système de DB
    -- Déséquipe l'item de la base de données
end

-- ========================================
-- VALIDATION FUNCTIONS
-- ========================================

---Valide qu'un item peut être équipé dans un slot
---@param itemDef table
---@param slotName string
---@return boolean, string|nil
local function ValidateEquipSlot(itemDef, slotName)
    if not itemDef.equipSlot then
        return false, "Item cannot be equipped"
    end

    -- Standard validation: equipSlot must match slotName
    if itemDef.equipSlot == slotName then
        return true
    end

    -- Special case: Rig with armor protection can be equipped in armor slot
    if slotName == 'armor' and itemDef.equipSlot == 'rig' and itemDef.fillsBodyArmor then
        return true
    end

    return false, string.format("Item can only be equipped in slot: %s", itemDef.equipSlot)
end

---Vérifie si un slot est bloqué
---@param playerId number
---@param slotName string
---@return boolean, string|nil
local function IsSlotBlocked(playerId, slotName)
    -- Permanent slots (sheath, card, compass)
    if PERMANENT_SLOTS[slotName] then
        return true, "This is a permanent slot"
    end

    -- Body armor slot (blocked if rig fills it)
    if slotName == 'armor' then
        local rigItem = GetEquippedItem(playerId, 'rig')
        if rigItem then
            local rigDef = Items[rigItem.item_id]
            if rigDef and rigDef.fillsBodyArmor then
                return true, "Body armor slot is filled by your chest rig"
            end
        end
    end

    return false
end

-- ========================================
-- EQUIP ITEM
-- ========================================

---Équipe un item dans un slot
---@param playerId number
---@param item table
---@param slotName string
---@return boolean success
---@return string|nil error
function EquipItem(playerId, item, slotName)
    -- 1. Get item definition
    local itemDef = Items[item.item_id]
    if not itemDef then
        return false, "Item definition not found"
    end

    -- 2. Validate equipSlot
    local valid, err = ValidateEquipSlot(itemDef, slotName)
    if not valid then
        print(string.format('[CHEAT DETECTED] Player %d tried to equip %s in slot %s',
            playerId, item.item_id, slotName))
        return false, err
    end

    -- 3. Check if slot is blocked
    local blocked, blockReason = IsSlotBlocked(playerId, slotName)
    if blocked then
        return false, blockReason
    end

    -- 4. Handle swap if slot occupied
    local currentItem = GetEquippedItem(playerId, slotName)
    if currentItem then
        -- Unequip current item
        UnequipItemDB(playerId, slotName)

        -- Try to place old item in inventory
        -- À implémenter selon ton système
        -- local placed = TryPlaceItemInInventory(playerId, currentItem)
        -- if not placed then
        --     DropItemOnGround(playerId, currentItem)
        -- end
    end

    -- 5. Equip new item
    EquipItemDB(playerId, item, slotName)

    -- 6. Special handling for rig with fillsBodyArmor
    if slotName == 'rig' and itemDef.fillsBodyArmor then
        -- Remove equipped armor if any
        local armorItem = GetEquippedItem(playerId, 'armor')
        if armorItem then
            UnequipItemDB(playerId, 'armor')
            -- Try to place in inventory or drop
            -- TryPlaceItemInInventory(playerId, armorItem)
            TriggerClientEvent('ox_lib:notify', playerId, {
                type = 'inform',
                description = 'Armor removed (rig has integrated protection)'
            })
        end
    end

    print(string.format('[Equipment] Player %d equipped %s in slot %s',
        playerId, item.item_id, slotName))

    return true
end

-- ========================================
-- UNEQUIP ITEM
-- ========================================

---Déséquipe un item d'un slot
---@param playerId number
---@param slotName string
---@return boolean success
---@return string|nil error
function UnequipItem(playerId, slotName)
    -- 1. Check if slot is permanent
    if PERMANENT_SLOTS[slotName] then
        return false, "Cannot remove permanent items"
    end

    -- 2. Get equipped item
    local item = GetEquippedItem(playerId, slotName)
    if not item then
        return false, "No item equipped in this slot"
    end

    -- 3. Unequip
    UnequipItemDB(playerId, slotName)

    -- 4. Try to place in inventory
    -- À implémenter selon ton système
    -- local placed = TryPlaceItemInInventory(playerId, item)
    -- if not placed then
    --     return false, "No space in inventory"
    -- end

    print(string.format('[Equipment] Player %d unequipped %s from slot %s',
        playerId, item.item_id, slotName))

    return true
end

-- ========================================
-- GIVE PERMANENT ITEMS
-- ========================================

---Donne les items permanents à un joueur (au spawn)
---@param playerId number
function GivePermanentItems(playerId)
    print(string.format('[Equipment] Giving permanent items to player %d', playerId))

    -- Give secure case (contains card + compass)
    local hasCase = GetEquippedItem(playerId, 'case')
    if not hasCase then
        -- 1. Create secure_case item
        local caseItem = {
            id = GenerateUUID(),
            item_id = 'secure_case',
            quantity = 1,
            slot_type = 'equipment',
            rotation = 0,
            metadata = {}
        }
        EquipItemDB(playerId, caseItem, 'case')
        print('[Equipment] ✅ Secure case given')

        -- 2. Add card (minimap) inside the case
        local cardItem = {
            id = GenerateUUID(),
            item_id = 'minimap',
            quantity = 1,
            slot_type = 'case_storage',
            position_x = 0,
            position_y = 0,
            rotation = 0,
            metadata = {}
        }
        -- À implémenter: AddItemToCaseStorage(playerId, cardItem)
        print('[Equipment] ✅ Card added to secure case')

        -- 3. Add compass inside the case
        local compassItem = {
            id = GenerateUUID(),
            item_id = 'compass',
            quantity = 1,
            slot_type = 'case_storage',
            position_x = 2,
            position_y = 0,
            rotation = 0,
            metadata = {}
        }
        -- À implémenter: AddItemToCaseStorage(playerId, compassItem)
        print('[Equipment] ✅ Compass added to secure case')
    end

    -- Give knife (permanent item)
    local hasKnife = GetEquippedItem(playerId, 'sheath')
    if not hasKnife then
        local knifeItem = {
            id = GenerateUUID(),
            item_id = 'knife', -- Using permanent knife item
            quantity = 1,
            slot_type = 'equipment',
            rotation = 0,
            metadata = {
                durability = 100,
                max_durability = 100
            }
        }
        EquipItemDB(playerId, knifeItem, 'sheath')
        print('[Equipment] ✅ Knife given')
    end
end

-- ========================================
-- EVENTS
-- ========================================

---Player requests to equip an item
RegisterNetEvent('inventory:equipItem', function(data)
    local playerId = source
    local itemId = data.item_id
    local slotName = data.to.slot_name

    -- Get item from source (grid, pocket, etc.)
    -- À implémenter selon ton système
    -- local item = GetItemFromSource(playerId, itemId, data.from)
    -- if not item then
    --     TriggerClientEvent('ox_lib:notify', playerId, {
    --         type = 'error',
    --         description = 'Item not found'
    --     })
    --     return
    -- end

    -- Equip
    -- local success, err = EquipItem(playerId, item, slotName)
    -- if not success then
    --     TriggerClientEvent('ox_lib:notify', playerId, {
    --         type = 'error',
    --         description = err
    --     })
    --     return
    -- end

    -- Remove item from source
    -- RemoveItemFromSource(playerId, itemId, data.from)

    -- Sync with client
    -- TriggerClientEvent('inventory:updateEquipment', playerId, GetPlayerEquipment(playerId))
end)

---Player requests to unequip an item
RegisterNetEvent('inventory:unequipItem', function(data)
    local playerId = source
    local slotName = data.slot_name

    local success, err = UnequipItem(playerId, slotName)
    if not success then
        TriggerClientEvent('ox_lib:notify', playerId, {
            type = 'error',
            description = err
        })
        return
    end

    -- Sync with client
    -- TriggerClientEvent('inventory:updateEquipment', playerId, GetPlayerEquipment(playerId))
end)

---Player spawned - give permanent items
RegisterNetEvent('player:spawned', function()
    local playerId = source
    GivePermanentItems(playerId)
end)

-- ========================================
-- EXPORTS
-- ========================================

exports('EquipItem', EquipItem)
exports('UnequipItem', UnequipItem)
exports('GivePermanentItems', GivePermanentItems)
exports('GetEquippedItem', GetEquippedItem)
exports('IsSlotBlocked', IsSlotBlocked)

print('[Equipment] Module loaded ✅')
