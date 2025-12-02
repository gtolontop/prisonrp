-- ========================================
-- THE LAST COLONY - SHARED UTILITIES
-- ========================================

Utils = {}

-- ========================================
-- TABLE UTILITIES
-- ========================================

function Utils.TableContains(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

function Utils.TableCount(table)
    local count = 0
    for _ in pairs(table) do
        count = count + 1
    end
    return count
end

function Utils.DeepCopy(original)
    local copy
    if type(original) == 'table' then
        copy = {}
        for key, value in next, original, nil do
            copy[Utils.DeepCopy(key)] = Utils.DeepCopy(value)
        end
        setmetatable(copy, Utils.DeepCopy(getmetatable(original)))
    else
        copy = original
    end
    return copy
end

-- ========================================
-- MATH UTILITIES
-- ========================================

function Utils.Round(num, decimals)
    local mult = 10 ^ (decimals or 0)
    return math.floor(num * mult + 0.5) / mult
end

function Utils.Clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

function Utils.Distance(x1, y1, z1, x2, y2, z2)
    local dx = x2 - x1
    local dy = y2 - y1
    local dz = z2 - z1
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

-- ========================================
-- STRING UTILITIES
-- ========================================

function Utils.FormatMoney(amount)
    local formatted = tostring(amount)
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return "$" .. formatted
end

function Utils.FormatWeight(weight)
    return string.format("%.1f kg", weight)
end

function Utils.FormatTime(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60
    if hours > 0 then
        return string.format("%dh %dm %ds", hours, minutes, secs)
    elseif minutes > 0 then
        return string.format("%dm %ds", minutes, secs)
    else
        return string.format("%ds", secs)
    end
end

-- ========================================
-- GRID UTILITIES
-- ========================================

function Utils.CanItemFitAt(item, x, y, gridWidth, gridHeight, existingItems, rotation)
    rotation = rotation or 0
    local itemWidth = item.size.w
    local itemHeight = item.size.h

    -- Apply rotation (90° or 270° swaps width/height)
    if rotation == 1 or rotation == 3 then
        itemWidth, itemHeight = itemHeight, itemWidth
    end

    -- Check bounds
    if x + itemWidth > gridWidth or y + itemHeight > gridHeight then
        return false
    end

    -- Check collisions with existing items
    for _, existingItem in ipairs(existingItems) do
        if Utils.ItemsCollide(x, y, itemWidth, itemHeight, existingItem) then
            return false
        end
    end

    return true
end

function Utils.ItemsCollide(x1, y1, w1, h1, item2)
    local x2 = item2.x
    local y2 = item2.y
    local w2 = item2.width
    local h2 = item2.height

    return not (x1 + w1 <= x2 or x2 + w2 <= x1 or y1 + h1 <= y2 or y2 + h2 <= y1)
end

function Utils.FindFreeSlot(item, gridWidth, gridHeight, existingItems, rotation)
    rotation = rotation or 0
    local itemWidth = item.size.w
    local itemHeight = item.size.h

    if rotation == 1 or rotation == 3 then
        itemWidth, itemHeight = itemHeight, itemWidth
    end

    for y = 0, gridHeight - itemHeight do
        for x = 0, gridWidth - itemWidth do
            if Utils.CanItemFitAt(item, x, y, gridWidth, gridHeight, existingItems, rotation) then
                return {x = x, y = y, rotation = rotation}
            end
        end
    end

    return nil
end

-- ========================================
-- ITEM UTILITIES
-- ========================================

function Utils.GetItemWeight(itemId, quantity)
    local item = Items[itemId]
    if not item then return 0 end
    return (item.weight or 0) * quantity
end

function Utils.GetItemValue(itemId, quantity, metadata)
    local item = Items[itemId]
    if not item then return 0 end

    local basePrice = item.base_price or 0

    -- Adjust for durability if applicable
    if metadata and metadata.durability and item.durability then
        local durabilityPercent = metadata.durability / item.durability.max
        basePrice = basePrice * durabilityPercent
    end

    return basePrice * quantity
end

function Utils.IsItemStackable(itemId)
    local item = Items[itemId]
    return item and item.stackable == true
end

function Utils.GetMaxStack(itemId)
    local item = Items[itemId]
    if not item or not item.stackable then return 1 end
    return item.max_stack or 1
end

-- ========================================
-- INVENTORY VALIDATION
-- ========================================

function Utils.ValidateInventoryAction(playerId, action, data)
    -- Server-side validation
    -- Check distance, ownership, slot validity, etc.
    -- Returns: success (bool), errorMessage (string)

    -- Example checks:
    if not data then
        return false, "Invalid data"
    end

    -- Add more validation logic here
    return true, nil
end

-- ========================================
-- LOOT TABLE UTILITIES
-- ========================================

function Utils.GenerateLoot(lootTableName)
    local lootTable = Config.Loot.LootTables[lootTableName]
    if not lootTable then return {} end

    local generatedItems = {}
    local totalWeight = 0

    for _, entry in ipairs(lootTable) do
        totalWeight = totalWeight + entry.weight
    end

    -- Generate 1-3 random items from the table
    local numItems = math.random(1, 3)
    for i = 1, numItems do
        local roll = math.random() * totalWeight
        local currentWeight = 0

        for _, entry in ipairs(lootTable) do
            currentWeight = currentWeight + entry.weight
            if roll <= currentWeight then
                local quantity = math.random(entry.min, entry.max)
                table.insert(generatedItems, {
                    item_id = entry.item,
                    quantity = quantity,
                    metadata = {}
                })
                break
            end
        end
    end

    return generatedItems
end

-- ========================================
-- DAMAGE CALCULATION
-- ========================================

function Utils.CalculateDamage(weaponDamage, zone, armorValue, bulletPenetration)
    -- Base damage with zone multiplier
    local zoneMult = Config.BodyHealth.DamageMultipliers[zone] or 1.0
    local baseDamage = weaponDamage * zoneMult

    -- Apply armor reduction
    if armorValue and armorValue > 0 and bulletPenetration then
        local effectiveArmor = Config.Combat.ArmorPenetrationFormula(bulletPenetration, armorValue)
        local damageReduction = effectiveArmor / 100
        baseDamage = baseDamage * (1 - damageReduction)
    end

    return math.ceil(baseDamage)
end

return Utils
