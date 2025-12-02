--[[
    Dev Commands
    Quick commands for testing
]]

-- Give yourself a backpack (required to have inventory)
RegisterCommand('givebackpack', function(source)
    local playerId = source
    local player = Ox.GetPlayer(playerId)
    if not player then return end

    local charId = player.charId
    local InventoryManager = require 'server.modules.inventory.manager'

    -- Give military backpack (10x12 grid)
    local success, error = InventoryManager.GiveItem(charId, 'backpack_military', 1)

    if success then
        -- Equip it automatically
        TriggerEvent('inventory:equipItem', {
            item_id = 'backpack_military',
            slot = 'backpack'
        })

        TriggerClientEvent('ox_lib:notify', playerId, {
            type = 'success',
            description = 'Military backpack given and equipped!'
        })
    else
        TriggerClientEvent('ox_lib:notify', playerId, {
            type = 'error',
            description = error or 'Failed to give backpack'
        })
    end
end, false)

-- ========================================
-- EQUIPMENT TEST COMMANDS
-- ========================================

-- Give a specific item
RegisterCommand('giveitem', function(source, args)
    local playerId = source
    local itemId = args[1]

    if not itemId then
        TriggerClientEvent('ox_lib:notify', playerId, {
            type = 'error',
            description = 'Usage: /giveitem <item_id>'
        })
        return
    end

    local itemDef = Items[itemId]
    if not itemDef then
        TriggerClientEvent('ox_lib:notify', playerId, {
            type = 'error',
            description = 'Item not found: ' .. itemId
        })
        return
    end

    local player = Ox.GetPlayer(playerId)
    if not player then return end

    local InventoryManager = require 'server.modules.inventory.manager'
    local success, error = InventoryManager.GiveItem(player.charId, itemId, 1)

    if success then
        TriggerClientEvent('ox_lib:notify', playerId, {
            type = 'success',
            description = 'Given: ' .. itemDef.name
        })
    else
        TriggerClientEvent('ox_lib:notify', playerId, {
            type = 'error',
            description = error or 'Failed to give item'
        })
    end
end, false)

-- Give a kit of items
RegisterCommand('givekit', function(source, args)
    local playerId = source
    local kitName = args[1] or 'basic'

    local kits = {
        basic = {
            'helmet_tactical',
            'armor_vest_light',
            'rig_tactical',
            'backpack_military',
            'pistol_glock',
            'ak47',
        },
        heavy = {
            'helmet_tactical',
            'rig_military_armored', -- Rig with fillsBodyArmor
            'backpack_military',
            'pistol_glock',
            'ak47',
            'ak_mag_30',
            'ak_mag_30',
            'pistol_mag_15',
        },
        test = {
            'helmet_tactical',
            'gasmask',
            'armor_vest_light',
        }
    }

    local kit = kits[kitName]
    if not kit then
        TriggerClientEvent('ox_lib:notify', playerId, {
            type = 'error',
            description = 'Kit not found. Available: basic, heavy, test'
        })
        return
    end

    local player = Ox.GetPlayer(playerId)
    if not player then return end

    local InventoryManager = require 'server.modules.inventory.manager'
    local count = 0

    for _, itemId in ipairs(kit) do
        local success = InventoryManager.GiveItem(player.charId, itemId, 1)
        if success then
            count = count + 1
        end
    end

    TriggerClientEvent('ox_lib:notify', playerId, {
        type = 'success',
        description = string.format('Given %d items from kit: %s', count, kitName)
    })
end, false)

-- Test permanent items
RegisterCommand('fixpermanent', function(source)
    local playerId = source
    GivePermanentItems(playerId)

    TriggerClientEvent('ox_lib:notify', playerId, {
        type = 'success',
        description = 'Permanent items restored (card, compass, knife)'
    })
end, false)

print('^2[Dev]^0 Dev commands loaded: /givebackpack, /giveitem, /givekit, /fixpermanent')

-- ========================================
-- SPAWN LOOT FOR PERFORMANCE TESTING
-- ========================================

-- Spawn random items around player with gravity (for perf testing)
RegisterCommand('testperf', function(source, args)
    local playerId = source
    local count = tonumber(args[1]) or 50 -- Default 50 items

    -- Get player position
    local ped = GetPlayerPed(playerId)
    local playerCoords = GetEntityCoords(ped)

    -- List of test items to spawn (varied: weapons, ammo, meds, armor, etc.)
    local testItems = {
        'bandage', 'bandage', 'bandage',
        'medkit', 'medkit',
        'water_bottle', 'water_bottle',
        'canned_food', 'canned_food',
        '762x39_fmj', '762x39_fmj', '762x39_fmj',
        '556x45_fmj', '556x45_fmj',
        '9mm_fmj', '9mm_fmj', '9mm_fmj',
        'ak_mag_30', 'ak_mag_30',
        'stanag_30', 'stanag_30',
        'pistol_mag_15', 'pistol_mag_15',
        'helmet_tactical',
        'armor_vest_light',
        'rig_tactical',
        'pistol_glock',
        'ak47',
        'm4a1'
    }

    local Queries = require 'server.modules.inventory.db.queries'
    local LootContainers = require 'server.modules.loot.containers'
    local Items = require 'shared.items'
    local spawned = 0

    for i = 1, count do
        local itemId = testItems[math.random(1, #testItems)]
        local itemDef = Items[itemId]

        if itemDef then
            -- Random position around player (5-10m radius)
            local angle = math.random() * 2 * math.pi
            local distance = 5 + math.random() * 5

            local dropCoords = vector3(
                playerCoords.x + math.cos(angle) * distance,
                playerCoords.y + math.sin(angle) * distance,
                playerCoords.z + 1.0 -- 1m above ground for gravity drop
            )

            -- Random rotation for realism
            local rotation = {
                pitch = math.random(-45, 45),
                roll = math.random(-45, 45),
                yaw = math.random(0, 360)
            }

            -- Create loot container (dropped_item)
            local containerId = Queries.CreateLootContainer(
                'dropped_item',
                dropCoords,
                1, 1,
                {
                    item_id = itemId,
                    quantity = 1,
                    metadata = {},
                    spawned_by_dev = true
                },
                rotation.yaw,
                rotation
            )

            if containerId then
                LootContainers.Add(containerId, {
                    container_id = containerId,
                    container_type = 'dropped_item',
                    position = {
                        x = dropCoords.x,
                        y = dropCoords.y,
                        z = dropCoords.z,
                        heading = rotation.yaw
                    },
                    rotation = rotation,
                    grid_width = 1,
                    grid_height = 1,
                    items = {{
                        id = 'temp_' .. containerId,
                        item_id = itemId,
                        quantity = 1,
                        position = {x = 0, y = 0},
                        rotation = 0,
                        metadata = {}
                    }}
                })

                LootContainers.NotifyNew(containerId, {
                    container_id = containerId,
                    container_type = 'dropped_item',
                    model = itemDef.world_prop or `prop_cs_cardbox_01`,
                    coords = {
                        x = dropCoords.x,
                        y = dropCoords.y,
                        z = dropCoords.z,
                        heading = rotation.yaw
                    },
                    rotation = rotation,
                    items = {{
                        item_id = itemId,
                        quantity = 1
                    }}
                })

                spawned = spawned + 1
            end
        end

        if i % 10 == 0 then
            Wait(50)
        end
    end

    TriggerClientEvent('ox_lib:notify', playerId, {
        type = 'success',
        description = string.format('Spawned %d items around you!', spawned)
    })

    print(string.format('^2[Dev]^0 Player %d spawned %d test items', playerId, spawned))
end, false)

print('^2[Dev]^0 /testperf [count] command loaded for performance testing')
