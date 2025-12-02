--[[
    Loot Container Test Spawner
    Creates test containers with rigs and weapons for testing
]]

local LootContainers = require 'server.modules.loot.containers'

-- Create a test loot box with a rig and weapons
RegisterCommand('spawnloot', function(source, args)
    local playerId = source
    local ped = GetPlayerPed(playerId)
    local coords = GetEntityCoords(ped)

    -- Place container 2m in front of player
    local heading = GetEntityHeading(ped)
    local forwardX = coords.x + (math.sin(math.rad(heading)) * 2.0)
    local forwardY = coords.y + (math.cos(math.rad(heading)) * 2.0)

    local spawnCoords = {
        x = forwardX,
        y = forwardY,
        z = coords.z,
        heading = (heading + 180.0) % 360.0
    }

    -- Random loot pool
    local Items = require 'shared.items'
    local lootPool = {
        -- Weapons (20-30% chance)
        {item_id = 'ak47', chance = 25, quantity = {1, 1}},
        {item_id = 'm4a1', chance = 20, quantity = {1, 1}},
        {item_id = 'pistol_glock', chance = 35, quantity = {1, 1}},
        {item_id = 'knife_combat', chance = 40, quantity = {1, 1}},

        -- Magazines & Ammo (30-60% chance)
        {item_id = 'ak_mag_30', chance = 40, quantity = {1, 3}},
        {item_id = 'm4_mag_30', chance = 35, quantity = {1, 3}},
        {item_id = 'glock_mag_17', chance = 45, quantity = {1, 3}},
        {item_id = '762x39_fmj', chance = 50, quantity = {30, 90}},
        {item_id = '556x45_fmj', chance = 45, quantity = {30, 90}},
        {item_id = '9mm_fmj', chance = 55, quantity = {30, 90}},

        -- Equipment: Rigs (25-40% chance)
        {item_id = 'rig_tactical', chance = 30, quantity = {1, 1}},
        {item_id = 'rig_chest', chance = 25, quantity = {1, 1}},
        {item_id = 'rig_belt', chance = 35, quantity = {1, 1}},

        -- Equipment: Backpacks (20-35% chance)
        {item_id = 'backpack_military', chance = 20, quantity = {1, 1}},
        {item_id = 'backpack_medium', chance = 30, quantity = {1, 1}},
        {item_id = 'backpack_small', chance = 35, quantity = {1, 1}},

        -- Equipment: Armor (15-30% chance)
        {item_id = 'armor_plate', chance = 25, quantity = {1, 1}},
        {item_id = 'armor_light', chance = 30, quantity = {1, 1}},

        -- Equipment: Helmets (20-35% chance)
        {item_id = 'helmet_tactical', chance = 25, quantity = {1, 1}},
        {item_id = 'helmet_ballistic', chance = 20, quantity = {1, 1}},
        {item_id = 'helmet_light', chance = 30, quantity = {1, 1}},

        -- Medical (50-80% chance)
        {item_id = 'bandage', chance = 70, quantity = {1, 5}},
        {item_id = 'medkit', chance = 30, quantity = {1, 1}},
        {item_id = 'painkiller', chance = 50, quantity = {1, 3}},
        {item_id = 'morphine', chance = 15, quantity = {1, 1}},
        {item_id = 'hemostatic_agent', chance = 20, quantity = {1, 1}},

        -- Consumables (40-70% chance)
        {item_id = 'water_bottle', chance = 60, quantity = {1, 2}},
        {item_id = 'canned_food', chance = 55, quantity = {1, 3}},
        {item_id = 'energy_drink', chance = 40, quantity = {1, 2}},
    }

    -- Generate random items
    local items = {}
    local gridWidth = 6
    local gridHeight = 4
    local occupiedSlots = {} -- Track occupied positions

    -- Helper: Check if position is free
    local function isPositionFree(x, y, width, height)
        for ix = x, x + width - 1 do
            for iy = y, y + height - 1 do
                if occupiedSlots[ix] and occupiedSlots[ix][iy] then
                    return false
                end
                if ix >= gridWidth or iy >= gridHeight then
                    return false
                end
            end
        end
        return true
    end

    -- Helper: Mark position as occupied
    local function occupyPosition(x, y, width, height)
        for ix = x, x + width - 1 do
            for iy = y, y + height - 1 do
                occupiedSlots[ix] = occupiedSlots[ix] or {}
                occupiedSlots[ix][iy] = true
            end
        end
    end

    -- Helper: Find random free position
    local function findRandomPosition(itemWidth, itemHeight)
        local attempts = 0
        while attempts < 50 do
            local x = math.random(0, gridWidth - itemWidth)
            local y = math.random(0, gridHeight - itemHeight)
            if isPositionFree(x, y, itemWidth, itemHeight) then
                return x, y
            end
            attempts = attempts + 1
        end
        return nil, nil -- No space found
    end

    -- Roll for items
    for _, lootData in ipairs(lootPool) do
        if math.random(100) <= lootData.chance then
            local itemDef = Items[lootData.item_id]
            if itemDef then
                -- Respect max_stack
                local maxStack = itemDef.max_stack or 1
                local requestedQty = math.random(lootData.quantity[1], lootData.quantity[2])
                local quantity = math.min(requestedQty, maxStack)

                local itemWidth = itemDef.size.w or itemDef.size.width
                local itemHeight = itemDef.size.h or itemDef.size.height

                -- Find position
                local x, y = findRandomPosition(itemWidth, itemHeight)
                if x and y then
                    occupyPosition(x, y, itemWidth, itemHeight)
                    table.insert(items, {
                        id = tostring(math.random(1000, 9999)),
                        item_id = lootData.item_id,
                        quantity = quantity,
                        position = {x = x, y = y},
                        rotation = 0,
                        slot_type = 'grid',
                        metadata = lootData.item_id == 'rig_tactical' and {items = {}} or nil
                    })
                end
            end
        end
    end

    -- Create container with random items
    local containerData = {
        containerId = math.random(10000, 99999),
        container_type = 'loot_box',
        position = spawnCoords,
        coords = spawnCoords,
        model = `prop_mil_crate_02`,
        item_id = 'military_crate',
        quantity = 1,
        grid_width = gridWidth,
        grid_height = gridHeight,
        items = items
    }

    -- Add to cache
    LootContainers.Add(containerData.containerId, containerData)

    -- Notify all clients to spawn the prop
    LootContainers.NotifyNew(containerData.containerId, containerData)

    -- Send notification to player
    TriggerClientEvent('ox_lib:notify', playerId, {
        type = 'success',
        description = string.format('Spawned loot container with %d items', #containerData.items)
    })

    print(string.format('^2[Loot Test]^0 Player %d spawned container %d with %d items',
        playerId, containerData.containerId, #containerData.items))
end, false)

print('^2[Loot Test]^0 Test spawner loaded - Use /spawnloot')
