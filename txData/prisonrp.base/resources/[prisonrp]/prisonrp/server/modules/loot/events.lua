--[[
    Loot Container Events
    Server events for looting system
]]

local LootManager = require 'server.modules.loot.manager'
local Validation = require 'server.modules.inventory.validation'

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

--- Get character ID from player ID (ox_core)
local function GetCharId(playerId)
    local player = Ox.GetPlayer(playerId)
    if not player then
        print(string.format('^3[Loot]^0 GetCharId: Ox.GetPlayer returned nil for source %s', playerId))
        return nil
    end
    return player.charId
end

-- ============================================
-- CONTAINER INTERACTION
-- ============================================

-- Open container (view contents, split UI)
RegisterNetEvent('loot:openContainer', function(containerId)
    local playerId = source

    -- Rate limit
    local canProceed = Validation.CheckRateLimit(playerId, 'openContainer', 500)
    if not canProceed then
        return
    end

    -- Validate
    if type(containerId) ~= 'string' and type(containerId) ~= 'number' then
        return
    end

    containerId = tonumber(containerId)

    -- Get container data
    local LootContainers = require 'server.modules.loot.containers'
    local containerData = LootContainers.Get(containerId)

    if not containerData then
        TriggerClientEvent('notify', playerId, 'error', 'Container not found')
        return
    end

    -- Check distance (anti-cheat)
    local ped = GetPlayerPed(playerId)
    local playerCoords = GetEntityCoords(ped)

    -- Container position can be in different formats depending on source
    local containerPos = containerData.position or containerData.coords
    if not containerPos then
        print(string.format('^3[Loot]^0 ERROR: Container %d has no position data', containerId))
        TriggerClientEvent('ox_lib:notify', playerId, {
            type = 'error',
            description = 'Container position error'
        })
        return
    end

    local distance = #(playerCoords - vector3(containerPos.x, containerPos.y, containerPos.z))

    if distance > 5.0 then
        print(string.format('^3[Loot]^0 Player %d tried to open container %d from %.2fm away (cheat?)',
            playerId, containerId, distance))
        TriggerClientEvent('ox_lib:notify', playerId, {
            type = 'error',
            description = 'Too far from container'
        })
        return
    end

    -- Get player inventory
    local InventoryManager = require 'server.modules.inventory.manager'
    local charId = GetCharId(playerId)
    if not charId then return end

    local playerInventory = InventoryManager.LoadPlayerInventory(charId)

    -- Get item definitions
    local Items = require 'shared.items'
    local itemDefinitions = {}
    for itemId, def in pairs(Items) do
        -- Convert size.w/h to size.width/height for client
        local convertedDef = {}
        for k, v in pairs(def) do
            convertedDef[k] = v
        end
        if def.size then
            convertedDef.size = {
                width = def.size.w or def.size.width,
                height = def.size.h or def.size.height
            }
        end
        itemDefinitions[itemId] = convertedDef
    end

    -- Send both inventories to client (FIXED event name)
    TriggerClientEvent('loot:open', playerId, {
        container_id = tostring(containerId),
        container_type = containerData.container_type,
        container_name = containerData.container_type or 'Loot Container',
        grid = {
            width = containerData.grid_width,
            height = containerData.grid_height,
            items = containerData.items or {}
        }
    }, playerInventory, itemDefinitions)

    print(string.format('^2[Loot]^0 Player %d opened container %d', playerId, containerId))
end)

-- Search container (start looting)
RegisterNetEvent('loot:searchContainer', function(containerId)
    local playerId = source

    -- Rate limit
    local canProceed = Validation.CheckRateLimit(playerId, 'searchContainer', 1000)
    if not canProceed then
        return
    end

    -- Validate
    if type(containerId) ~= 'string' and type(containerId) ~= 'number' then
        return
    end

    containerId = tonumber(containerId)

    -- Start search
    local success, error = LootManager.StartSearch(playerId, containerId)
    if not success then
        TriggerClientEvent('notify', playerId, 'error', error or 'Cannot search container')
        return
    end

    print(('[Loot] Player %d started searching container %d'):format(playerId, containerId))
end)

-- Cancel search
RegisterNetEvent('player:cancelAction', function()
    local playerId = source
    LootManager.CancelSearch(playerId)
end)

-- Close container
RegisterNetEvent('loot:closeContainer', function(containerId)
    local playerId = source

    if not containerId then
        return
    end

    containerId = tonumber(containerId)

    LootManager.CloseContainer(playerId, containerId)
end)

-- ============================================
-- ITEM TRANSFER
-- ============================================

-- Take item from container to player inventory
RegisterNetEvent('loot:takeItem', function(data)
    local playerId = source

    print(string.format('^2[Loot]^0 TakeItem request from player %d: container=%s, item=%s',
        playerId, tostring(data.container_id), tostring(data.item_id)))

    -- Rate limit
    local canProceed = Validation.CheckRateLimit(playerId, 'lootTakeItem', 200)
    if not canProceed then
        print('^3[Loot]^0 Rate limit exceeded for player ' .. playerId)
        return
    end

    -- Validate data
    if not data.container_id or not data.item_id then
        print('^3[Loot]^0 Invalid data: container_id or item_id missing')
        return
    end

    local containerId = tonumber(data.container_id)
    local itemInstanceId = data.item_id

    -- Execute transfer
    local success, error = LootManager.TakeItem(
        playerId,
        containerId,
        itemInstanceId,
        data.to_position,
        data.to_pocket
    )

    if not success then
        print(string.format('^3[Loot]^0 TakeItem failed: %s', error or 'Unknown error'))
        TriggerClientEvent('ox_lib:notify', playerId, {
            type = 'error',
            description = error or 'Cannot take item'
        })
        return
    end

    print(string.format('^2[Loot]^0 Player %d successfully took item from container %d', playerId, containerId))
end)

-- Transfer item from player to container (deposit/exchange)
RegisterNetEvent('loot:transferItem', function(data)
    local playerId = source

    -- Rate limit
    local canProceed = Validation.CheckRateLimit(playerId, 'lootTransferItem', 200)
    if not canProceed then
        return
    end

    -- Validate data
    if not data.container_id or not data.item_id or not data.to_position then
        print('^3[Loot]^0 Invalid data for transferItem')
        return
    end

    local containerId = tonumber(data.container_id)

    -- Get character ID
    local charId = GetCharId(playerId)
    if not charId then return end

    -- Execute transfer
    local success, error = LootManager.TransferItem(
        playerId,
        containerId,
        data.item_id,
        data.to_position
    )

    if not success then
        TriggerClientEvent('ox_lib:notify', playerId, {
            type = 'error',
            description = error or 'Cannot transfer item'
        })
        return
    end

    print(string.format('^2[Loot]^0 Player %d deposited item into container %d', playerId, containerId))
end)

-- Move item within loot container (reorganize)
RegisterNetEvent('loot:moveItemInContainer', function(data)
    local playerId = source

    -- Rate limit
    local canProceed = Validation.CheckRateLimit(playerId, 'moveItemInContainer', 200)
    if not canProceed then
        return
    end

    -- Validate data
    if not data.container_id or not data.item_id or not data.from_position or not data.to_position then
        print('^3[Loot]^0 Invalid data for moveItemInContainer')
        return
    end

    local containerId = tonumber(data.container_id)

    -- Get container
    local LootContainers = require 'server.modules.loot.containers'
    local containerData = LootContainers.Get(containerId)

    if not containerData then
        return
    end

    -- Find item in container
    local item = nil
    local itemIndex = nil
    for i, containerItem in ipairs(containerData.items) do
        if containerItem.id == data.item_id then
            item = containerItem
            itemIndex = i
            break
        end
    end

    if not item then
        print(string.format('^3[Loot]^0 Item %s not found in container %d', data.item_id, containerId))
        return
    end

    -- Get item size
    local Items = require 'shared.items'
    local itemDef = Items[item.item_id]
    if not itemDef then
        return
    end

    local itemWidth = itemDef.size.w or itemDef.size.width
    local itemHeight = itemDef.size.h or itemDef.size.height

    -- Check collision with other items
    for i, otherItem in ipairs(containerData.items) do
        if otherItem.id ~= item.id then
            local otherDef = Items[otherItem.item_id]
            if otherDef then
                local otherWidth = otherDef.size.w or otherDef.size.width
                local otherHeight = otherDef.size.h or otherDef.size.height

                -- Check AABB collision
                local x1 = data.to_position.x
                local y1 = data.to_position.y
                local x2 = x1 + itemWidth - 1
                local y2 = y1 + itemHeight - 1

                local ox1 = otherItem.position.x
                local oy1 = otherItem.position.y
                local ox2 = ox1 + otherWidth - 1
                local oy2 = oy1 + otherHeight - 1

                if not (x2 < ox1 or x1 > ox2 or y2 < oy1 or y1 > oy2) then
                    -- Collision detected
                    print(string.format('^3[Loot]^0 Collision detected when moving item in container'))
                    TriggerClientEvent('ox_lib:notify', playerId, {
                        type = 'error',
                        description = 'Cannot place item here (collision)'
                    })
                    return
                end
            end
        end
    end

    -- Check bounds
    if data.to_position.x + itemWidth > containerData.grid_width or
       data.to_position.y + itemHeight > containerData.grid_height then
        print(string.format('^3[Loot]^0 Item would be out of bounds'))
        TriggerClientEvent('ox_lib:notify', playerId, {
            type = 'error',
            description = 'Cannot place item here (out of bounds)'
        })
        return
    end

    -- Update item position
    item.position = data.to_position

    -- Update container in cache
    LootContainers.Update(containerId, containerData)

    -- Notify all players viewing this container
    LootContainers.NotifyUpdate(containerId, containerData)

    print(string.format('^2[Loot]^0 Player %d moved item in container %d from (%d,%d) to (%d,%d)',
        playerId, containerId, data.from_position.x, data.from_position.y, data.to_position.x, data.to_position.y))
end)

-- ============================================
-- QUICK PICKUP (for dropped items 1x1)
-- ============================================

-- Pick up item directly without opening UI
RegisterNetEvent('loot:pickupItem', function(containerId)
    local playerId = source

    -- Rate limit
    local canProceed = Validation.CheckRateLimit(playerId, 'pickupItem', 500)
    if not canProceed then
        return
    end

    -- Validate
    if type(containerId) ~= 'string' and type(containerId) ~= 'number' then
        return
    end

    containerId = tonumber(containerId)

    -- Get container data
    local LootContainers = require 'server.modules.loot.containers'
    local containerData = LootContainers.Get(containerId)

    if not containerData then
        TriggerClientEvent('ox_lib:notify', playerId, {
            type = 'error',
            description = 'Item not found'
        })
        return
    end

    -- Check distance (anti-cheat)
    local ped = GetPlayerPed(playerId)
    local playerCoords = GetEntityCoords(ped)
    local containerPos = containerData.position or containerData.coords

    if not containerPos then
        print(string.format('^3[Loot]^0 ERROR: Container %d has no position', containerId))
        return
    end

    local distance = #(playerCoords - vector3(containerPos.x, containerPos.y, containerPos.z))

    if distance > 5.0 then
        print(string.format('^3[Loot]^0 Player %d tried to pickup from %.2fm away', playerId, distance))
        TriggerClientEvent('ox_lib:notify', playerId, {
            type = 'error',
            description = 'Too far'
        })
        return
    end

    -- Check if container has items
    if not containerData.items or #containerData.items == 0 then
        TriggerClientEvent('ox_lib:notify', playerId, {
            type = 'error',
            description = 'Container is empty'
        })
        return
    end

    -- Get first item from container
    local item = containerData.items[1]

    -- Try to add item to player inventory
    local InventoryManager = require 'server.modules.inventory.manager'
    local charId = GetCharId(playerId)
    if not charId then return end

    local success, result = InventoryManager.GiveItem(charId, item.item_id, item.quantity, item.metadata)

    -- Check if item was fully given (refused = 0)
    if not success or (type(result) == 'table' and result.refused and result.refused > 0) then
        local errorMsg = type(result) == 'string' and result or 'Not enough space in inventory'
        if type(result) == 'table' and result.refused then
            errorMsg = string.format('Only %d/%d could fit', result.given or 0, item.quantity)
        end

        -- No space - flash text red on client
        TriggerClientEvent('loot:pickupFailed', playerId, containerId, errorMsg)
        TriggerClientEvent('ox_lib:notify', playerId, {
            type = 'error',
            description = errorMsg
        })
        return
    end

    -- Success - remove container
    LootContainers.Remove(containerId)

    -- Notify all clients to remove prop
    TriggerClientEvent('loot:removeContainer', -1, containerId)

    print(string.format('^2[Loot]^0 Player %d picked up item %s (x%d) from container %d',
        playerId, item.item_id, item.quantity, containerId))
end)

-- Take item from container and equip it directly (bypass inventory)
RegisterNetEvent('loot:takeAndEquipItem', function(data)
    local playerId = source

    if not data.container_id or not data.item_id or not data.slot then
        return
    end

    local charId = GetCharId(playerId)
    if not charId then return end

    local containerId = tonumber(data.container_id)

    -- Get container
    local LootContainers = require 'server.modules.loot.containers'
    local container = LootContainers.Get(containerId)

    if not container then
        print(('[Loot] Container %d not found'):format(containerId))
        return
    end

    -- Find the item in container
    local containerItem = nil
    local itemIndex = nil
    for i, item in ipairs(container.items or {}) do
        if item.id == data.item_id then
            containerItem = item
            itemIndex = i
            break
        end
    end

    if not containerItem then
        print(('[Loot] Item %s not found in container %d'):format(data.item_id, containerId))
        return
    end

    -- Get item definition
    local Items = require 'shared.items'
    local itemDef = Items[containerItem.item_id]
    if not itemDef then
        print(('[Loot] Item definition not found for %s'):format(containerItem.item_id))
        return
    end

    -- Check if slot is compatible (validation)
    local InventoryManager = require 'server.modules.inventory.manager'
    local InventoryQueries = require 'server.modules.inventory.db.queries'

    -- Unequip current item in slot if any
    local inventory = InventoryManager.LoadPlayerInventory(charId)
    if inventory then
        for _, equipSlot in ipairs(inventory.equipment) do
            if equipSlot.slot_name == data.slot and equipSlot.item then
                local unequipSuccess = InventoryManager.UnequipItem(charId, equipSlot.item.id)
                if not unequipSuccess then
                    TriggerClientEvent('ox_lib:notify', playerId, {
                        type = 'error',
                        description = 'Could not unequip current item'
                    })
                    return
                end
            end
        end
    end

    -- Create item instance directly in equipment slot (bypass inventory)
    local newItemInstanceId = InventoryQueries.CreateItem(
        charId,
        containerItem.item_id,
        containerItem.quantity or 1,
        'equipment', -- slot_type = equipment
        nil,         -- slot_index = nil
        nil,         -- position = nil
        0,           -- rotation = 0
        containerItem.metadata or {}
    )

    if not newItemInstanceId then
        print('[Loot] Failed to create item instance')
        return
    end

    -- Link item to equipment slot
    InventoryQueries.EquipItem(charId, data.slot, newItemInstanceId)

    -- Remove item from container
    table.remove(container.items, itemIndex)
    LootContainers.Update(containerId, container)

    -- Clear cache and update client
    InventoryManager.ClearCache(charId)
    InventoryManager.UpdateClient(charId, playerId)

    -- Update container UI
    TriggerClientEvent('loot:updateContainer', playerId, {
        container_id = tostring(containerId),
        grid = {
            width = container.grid_width,
            height = container.grid_height,
            items = container.items or {}
        }
    })

    -- Sync visuals
    TriggerClientEvent('equipment:syncVisuals', playerId, {
        slot = data.slot,
        item_id = containerItem.item_id,
        itemDef = itemDef
    })

    print(('[Loot] Player %d took and equipped %s to slot %s (bypass inventory)'):format(playerId, containerItem.item_id, data.slot))
end)

-- ============================================
-- SYNC CONTAINERS
-- ============================================

-- Client requests all containers (on resource start or reconnect)
RegisterNetEvent('loot:requestSync', function()
    local playerId = source

    local LootContainers = require 'server.modules.loot.containers'
    LootContainers.SyncToPlayer(playerId)

    print(('[Loot] Player %d requested container sync'):format(playerId))
end)

print('[Server] Loot events registered')
