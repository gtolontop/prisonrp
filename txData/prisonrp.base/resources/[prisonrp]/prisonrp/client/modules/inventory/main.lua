--[[
    Client Inventory Module
    Handles inventory UI opening/closing and communication with NUI
]]

local ox = lib

-- ============================================
-- STATE
-- ============================================

local currentInventoryData = nil
local currentItemDefinitions = nil

-- ============================================
-- EVENTS FROM SERVER
-- ============================================

-- Server sends inventory data to open UI
RegisterNetEvent('inventory:open', function(inventoryData, itemDefinitions)
    if not inventoryData then
        print('^3[Warning]^0 Received empty inventory data from server')
        return
    end

    currentInventoryData = inventoryData
    currentItemDefinitions = itemDefinitions

    -- ⭐ ABI_MOVEMENT INTEGRATION: Sync inventory weight
    if GetResourceState('abi_movement') == 'started' then
        TriggerEvent('abi_movement:updateInventoryWeight', inventoryData.current_weight or 0)
    end

    -- Debug: Log inventory structure
    print('[Inventory] DEBUG - Inventory structure:')
    print('  backpack:', inventoryData.backpack ~= nil)
    if inventoryData.backpack then
        print('    width:', inventoryData.backpack.width)
        print('    height:', inventoryData.backpack.height)
        print('    items:', inventoryData.backpack.items ~= nil, type(inventoryData.backpack.items))
        if inventoryData.backpack.items then
            print('    items count:', #inventoryData.backpack.items)
        end
    end
    print('  equipment:', inventoryData.equipment ~= nil, type(inventoryData.equipment))
    if inventoryData.equipment then
        print('    equipment count:', #inventoryData.equipment)
    end
    print('  pockets:', inventoryData.pockets ~= nil, type(inventoryData.pockets))
    if inventoryData.pockets then
        print('    pockets count:', #inventoryData.pockets)
    end

    -- Send data to NUI
    SendNUIMessage({
        type = 'openInventory',
        data = {
            inventory = inventoryData,
            itemDefinitions = itemDefinitions
        }
    })

    -- Set NUI focus (allow mouse cursor and keyboard input)
    SetNuiFocus(true, true)

    -- Notify client/main.lua that inventory is now open
    TriggerEvent('inventory:clientOpened')

    print('^2[Inventory]^0 Inventory UI opened')
end)

-- Server sends updated inventory (after item move, etc.)
RegisterNetEvent('inventory:update', function(inventoryData, itemDefinitions)
    if not inventoryData then
        print('^3[Warning]^0 Received empty inventory data in update')
        return
    end

    currentInventoryData = inventoryData
    if itemDefinitions then
        currentItemDefinitions = itemDefinitions
    end

    -- ⭐ ABI_MOVEMENT INTEGRATION: Sync inventory weight on update
    if GetResourceState('abi_movement') == 'started' then
        TriggerEvent('abi_movement:updateInventoryWeight', inventoryData.current_weight or 0)
    end

    print(string.format('^2[Inventory]^0 Inventory updated - backpack items=%d, pockets=%d',
        #inventoryData.backpack.items, #inventoryData.pockets))

    -- Send updated data to NUI (include itemDefinitions if provided)
    SendNUIMessage({
        type = 'updateInventory',
        data = {
            inventory = inventoryData,
            itemDefinitions = itemDefinitions or currentItemDefinitions
        }
    })
end)

-- Close inventory (from client)
RegisterNetEvent('inventory:close', function()
    SetNuiFocus(false, false)
    SendNUIMessage({
        type = 'closeInventory'
    })

    print('^2[Inventory]^0 Inventory closed')
end)

-- Force close inventory from server
RegisterNetEvent('inventory:forceClose', function()
    SetNuiFocus(false, false)
    SendNUIMessage({
        type = 'closeInventory'
    })

    print('^2[Inventory]^0 Inventory force closed by server')
end)

-- ============================================
-- LOOT SYSTEM
-- ============================================

-- Open loot container (dual-panel UI)
RegisterNetEvent('loot:open', function(containerData, inventoryData, itemDefinitions)
    if not containerData or not inventoryData then
        print('^3[Warning]^0 Received invalid loot data from server')
        return
    end

    currentInventoryData = inventoryData
    currentItemDefinitions = itemDefinitions

    print(string.format('^2[Loot]^0 Opening container %s with %d items',
        containerData.container_id, #containerData.grid.items))

    -- Send data to NUI (LootView expects this format)
    SendNUIMessage({
        type = 'openLoot',
        data = {
            container = {
                id = containerData.container_id,
                type = containerData.container_type,
                name = containerData.container_name or 'Loot Container',
                grid = containerData.grid
            },
            inventory = inventoryData,
            itemDefinitions = itemDefinitions
        }
    })

    -- Set NUI focus
    SetNuiFocus(true, true)

    -- Notify client/main.lua that loot is now open
    TriggerEvent('loot:clientOpened')

    print('^2[Loot]^0 Loot UI opened')
end)

-- Update loot container (when someone else takes an item)
RegisterNetEvent('loot:updateContainer', function(containerData)
    if not containerData then
        return
    end

    -- Send updated container data to NUI
    SendNUIMessage({
        type = 'updateLootContainer',
        data = {
            container = containerData
        }
    })
end)

-- ============================================
-- STORAGE SYSTEM
-- ============================================

-- Open storage
RegisterNetEvent('storage:open', function(storageData, inventoryData, itemDefinitions)
    if not storageData or not inventoryData then
        print('^3[Warning]^0 Received invalid storage data from server')
        return
    end

    currentInventoryData = inventoryData
    currentItemDefinitions = itemDefinitions

    -- Send data to NUI
    SendNUIMessage({
        type = 'openStorage',
        data = {
            storage = storageData,
            inventory = inventoryData,
            itemDefinitions = itemDefinitions
        }
    })

    -- Set NUI focus
    SetNuiFocus(true, true)

    print('^2[Storage]^0 Storage UI opened')
end)

-- ============================================
-- NOTIFICATIONS
-- ============================================

-- Server sends notification
RegisterNetEvent('notify', function(type, message)
    lib.notify({
        type = type,
        description = message
    })
end)

-- ============================================
-- DROP ITEM (Animation + Spawn Prop)
-- ============================================

RegisterNetEvent('inventory:clientDropItem', function(data)
    if not data or not data.item_id then
        print('^3[Inventory]^0 ERROR: Invalid drop data')
        return
    end

    local ped = PlayerPedId()
    local Animations = require 'shared.animations'

    print(string.format('^2[Inventory]^0 Dropping item %s (x%d)',
        data.item_id, data.quantity))

    -- Load item model
    local propModel = data.model or `prop_cs_cardbox_01`
    RequestModel(propModel)
    local timeout = 0
    while not HasModelLoaded(propModel) and timeout < 3000 do
        Wait(10)
        timeout = timeout + 10
    end

    if not HasModelLoaded(propModel) then
        print('^3[Inventory]^0 ERROR: Failed to load item model')
        return
    end

    -- Create prop in hand
    local prop = CreateObject(propModel, 0.0, 0.0, 0.0, true, true, false)

    -- Attach to right hand (bone index 57005 = BONETAG_R_PH_HAND)
    -- Offsets adjusted for holding props naturally (like holding a box)
    AttachEntityToEntity(
        prop, ped,
        GetPedBoneIndex(ped, 57005), -- Right hand bone (correct index)
        0.12, 0.05, 0.0,  -- Position offset: slightly forward and to the side
        0.0, 90.0, 0.0,   -- Rotation: rotated to face forward naturally
        true, true, false, true, 1, true
    )

    print(string.format('^2[Inventory]^0 Prop %d attached to hand', prop))

    -- Play drop animation with progress bar
    local itemName = data.item_name or data.item_id
    local anim = Animations.List['dropItem']
    if not anim then
        DeleteEntity(prop)
        return
    end

    -- Load animation dict
    if not Animations.LoadDict(anim.dict) then
        DeleteEntity(prop)
        return
    end

    -- Start animation
    lib.progressBar({
        duration = anim.duration,
        label = string.format('Dropping %s...', itemName),
        useWhileDead = false,
        canCancel = false,
        disable = {
            car = true,
            move = true,
            combat = true,
        },
        anim = {
            dict = anim.dict,
            clip = anim.anim,
            flag = anim.flag or 1,
        }
    })

    -- Animation complete, detach and drop prop
    DetachEntity(prop, true, true)

    -- Calculate throw velocity based on item weight
    local itemWeight = data.weight or 1.0 -- Default 1kg if not specified
    local playerHeading = GetEntityHeading(ped)
    local headingRad = math.rad(playerHeading)

    -- Calculate throw force (inverse relationship with weight)
    -- Light items (< 0.5kg) = gentle toss (1.5-2 m/s)
    -- Medium items (0.5-2kg) = normal drop (1-1.5 m/s)
    -- Heavy items (> 2kg) = weak drop (0.5-1 m/s)
    local baseForce = 1.2 -- Reduced from 3.0 to 1.2 (60% less force)
    local weightFactor = math.max(0.3, math.min(1.5, 1.0 / math.sqrt(itemWeight)))
    local throwForce = baseForce * weightFactor

    -- Forward velocity (in player's facing direction)
    local forwardX = -math.sin(headingRad) * throwForce
    local forwardY = math.cos(headingRad) * throwForce

    -- Downward velocity (affected by weight - heavier = falls faster)
    local downwardForce = -1.2 - (itemWeight * 0.2) -- Slightly faster downward

    -- Set prop to physics mode
    SetEntityDynamic(prop, true)
    SetEntityVelocity(prop, forwardX, forwardY, downwardForce)
    SetEntityCollision(prop, true, true)

    print(string.format('^2[Inventory]^0 Prop %d dropped from hand (weight: %.2fkg, force: %.2f m/s)',
        prop, itemWeight, throwForce))

    -- Wait for prop to fully settle (3 seconds for physics to stabilize)
    SetTimeout(3000, function()
        if DoesEntityExist(prop) then
            -- Freeze the prop so it stops moving completely
            FreezeEntityPosition(prop, true)

            -- Get final stable position and rotation
            local finalCoords = GetEntityCoords(prop)
            local finalRotation = GetEntityRotation(prop, 2) -- Get full rotation (pitch, roll, yaw)

            -- Convert vector3 to plain table for network transmission
            local rotationTable = {
                x = finalRotation.x,
                y = finalRotation.y,
                z = finalRotation.z
            }

            print(string.format('^2[Inventory]^0 Prop settled at %s, rotation: %.2f, %.2f, %.2f',
                finalCoords, rotationTable.x, rotationTable.y, rotationTable.z))

            -- Send to server to create persistent container with full rotation
            -- Include itemInstanceId so server can delete it after container creation
            TriggerServerEvent('inventory:createDroppedContainer', {
                item_id = data.item_id,
                item_name = data.item_name,
                quantity = data.quantity,
                model = data.model,
                metadata = data.metadata,
                itemInstanceId = data.itemInstanceId, -- Pass instance ID for safe deletion
                was_equipped = data.was_equipped or false, -- Pass equipment status
                equipment_slot = data.equipment_slot -- Pass slot name if equipped
            }, finalCoords, rotationTable) -- Send rotation as plain table

            -- Wait longer for server prop to fully spawn and stabilize before deleting client prop
            SetTimeout(1500, function()
                if DoesEntityExist(prop) then
                    -- Fade out client prop to avoid pop
                    SetEntityAlpha(prop, 0, false)

                    SetTimeout(100, function()
                        if DoesEntityExist(prop) then
                            DeleteEntity(prop)
                            print('^2[Inventory]^0 Client prop deleted, server prop active')
                        end
                    end)
                end
            end)
        end
    end)
end)

-- Receive container ID after server creates it
RegisterNetEvent('inventory:containerCreated', function(containerId)
    -- Server will notify all clients via loot system to spawn the prop
    print(string.format('^2[Inventory]^0 Container %d created by server', containerId))
end)

-- ============================================
-- UTILITY FUNCTIONS
-- ============================================

-- Get current inventory data (for debugging)
function GetCurrentInventory()
    return currentInventoryData
end

-- Export functions
exports('GetCurrentInventory', GetCurrentInventory)

print('^2[Inventory]^0 Client inventory module loaded')
