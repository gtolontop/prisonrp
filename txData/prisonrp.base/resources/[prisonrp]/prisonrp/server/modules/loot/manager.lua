--[[
    Loot Container Manager
    Handles loot boxes, corpses, vehicles, etc.
]]

local Queries = require 'server.modules.inventory.db.queries'
local Items = require 'shared.items'
local Config = require 'shared.config'

local LootManager = {}

-- Get containers from the centralized cache
local LootContainers = require 'server.modules.loot.containers'

-- Players currently looting
local lootingPlayers = {}

-- ============================================
-- CONTAINER CREATION
-- ============================================

-- Create loot container at position
function LootManager.CreateContainer(containerType, coords, items, metadata)
    -- Determine grid size based on container type
    local gridSize = {
        loot_box = { width = 6, height = 4 },
        corpse = { width = 10, height = 12 }, -- Full player inventory
        vehicle = { width = 8, height = 6 },
        storage = { width = 10, height = 10 }
    }

    local size = gridSize[containerType] or { width = 6, height = 4 }

    -- Create in database
    local containerId = Queries.CreateLootContainer(
        containerType,
        coords,
        size.width,
        size.height,
        metadata
    )

    -- Add items to container
    if items then
        for _, item in ipairs(items) do
            Queries.CreateItem(
                nil, -- No charid for container items
                item.item_id,
                item.quantity,
                'grid',
                nil,
                item.position,
                item.rotation or 0,
                item.metadata
            )
        end
    end

    -- Cache container via centralized manager
    local containerData = {
        container_id = containerId,
        container_type = containerType,
        position = coords,
        coords = coords,
        grid_width = size.width,
        grid_height = size.height,
        searched = false,
        despawn_time = os.time() + (metadata and metadata.despawn_time or 600),
        items = items or {},
        metadata = metadata
    }

    LootContainers.Add(containerId, containerData)

    print(('[Loot] Created %s container at %s'):format(containerType, json.encode(coords)))

    return containerId
end

-- Create loot from player corpse
function LootManager.CreateCorpseContainer(coords, playerInventory, playerName)
    local metadata = {
        player_name = playerName,
        death_time = os.time(),
        despawn_time = 1800 -- 30 minutes
    }

    local containerId = LootManager.CreateContainer(
        'corpse',
        coords,
        playerInventory,
        metadata
    )

    return containerId
end

-- ============================================
-- CONTAINER INTERACTION
-- ============================================

-- Start searching container
function LootManager.StartSearch(playerId, containerId)
    -- Check if container exists
    local container = LootContainers.Get(containerId)
    if not container then
        -- Try loading from DB
        if containerId < 10000 then
            container = Queries.LoadLootContainer(containerId)
            if container then
                LootContainers.Add(containerId, container)
            end
        end
    end

    if not container then
        return false, "Container not found"
    end

    -- Check distance
    local playerPed = GetPlayerPed(playerId)
    local playerCoords = GetEntityCoords(playerPed)
    local distance = #(vector3(playerCoords.x, playerCoords.y, playerCoords.z) - vector3(container.coords.x, container.coords.y, container.coords.z))

    if distance > 3.0 then
        return false, "Container too far"
    end

    -- If already searched, open immediately
    if container.searched then
        LootManager.OpenContainer(playerId, containerId)
        return true
    end

    -- Calculate search time based on item count
    local itemCount = container.items and #container.items or 0
    local searchTime = Config.Loot.SearchTimePerItem * itemCount

    -- Start search progress
    lootingPlayers[playerId] = {
        containerId = containerId,
        startTime = GetGameTimer(),
        duration = searchTime
    }

    -- Notify client to show progress bar
    TriggerClientEvent('player:startAction', playerId, 'searching', searchTime / 1000, true)

    -- Set timer to finish search
    SetTimeout(searchTime, function()
        if lootingPlayers[playerId] and lootingPlayers[playerId].containerId == containerId then
            -- Mark as searched
            Queries.MarkContainerSearched(containerId)
            container.searched = true

            -- Open container
            LootManager.OpenContainer(playerId, containerId)

            -- Clear looting state
            lootingPlayers[playerId] = nil

            print(('[Loot] Player %d finished searching container %d'):format(playerId, containerId))
        end
    end)

    return true
end

-- Cancel search
function LootManager.CancelSearch(playerId)
    if lootingPlayers[playerId] then
        lootingPlayers[playerId] = nil
        TriggerClientEvent('player:cancelAction', playerId)
        return true
    end
    return false
end

-- Open container UI
function LootManager.OpenContainer(playerId, containerId)
    local container = LootContainers.Get(containerId)
    if not container and containerId < 10000 then
        container = Queries.LoadLootContainer(containerId)
        if container then
            LootContainers.Add(containerId, container)
        end
    end

    if not container then
        return false, "Container not found"
    end

    -- Send to client
    local containerData = {
        id = tostring(containerId),
        type = container.container_type or container.type,
        name = container.metadata and container.metadata.player_name or 'Loot Container',
        grid = {
            width = container.grid_width or container.grid.width,
            height = container.grid_height or container.grid.height,
            items = container.items or {}
        }
    }

    TriggerClientEvent('loot:openContainer', playerId, containerData)

    print(('[Loot] Player %d opened container %d'):format(playerId, containerId))

    return true
end

-- Close container
function LootManager.CloseContainer(playerId, containerId)
    TriggerClientEvent('loot:closeContainer', playerId)
    return true
end

-- ============================================
-- ITEM TRANSFER
-- ============================================

-- Take item from container
function LootManager.TakeItem(playerId, containerId, itemInstanceId, toPosition, toPocket)
    -- Get character ID
    local player = Ox.GetPlayer(playerId)
    if not player then
        return false, "Player not found"
    end
    local charId = player.charId

    -- Get container from centralized cache
    local container = LootContainers.Get(containerId)

    -- If not in cache and ID < 10000, try loading from DB
    if not container and containerId < 10000 then
        container = Queries.LoadLootContainer(containerId)
        if container then
            LootContainers.Add(containerId, container)
        end
    end

    if not container then
        -- Debug: show available container IDs
        local allContainers = LootContainers.GetAll()
        local availableIds = {}
        for id, _ in pairs(allContainers) do
            table.insert(availableIds, tostring(id))
        end
        print(string.format('^3[Loot]^0 Container %d not found. Available IDs: %s',
            containerId, table.concat(availableIds, ', ')))
        return false, "Container not found"
    end

    local playerPed = GetPlayerPed(playerId)
    local playerCoords = GetEntityCoords(playerPed)
    local containerPos = container.position or container.coords
    local distance = #(playerCoords - vector3(containerPos.x, containerPos.y, containerPos.z))

    if distance > 5.0 then
        return false, "Too far from container"
    end

    -- Load container items
    local containerItems = container.items or {}

    -- Find item in container
    local itemIndex = nil
    local itemData = nil
    for i, item in ipairs(containerItems) do
        if tostring(item.item_instance_id) == tostring(itemInstanceId) or tostring(item.id) == tostring(itemInstanceId) then
            itemIndex = i
            itemData = item
            break
        end
    end

    if not itemData then
        return false, "Item not found in container"
    end

    -- Give item to player
    local InventoryManager = require 'server.modules.inventory.manager'
    local success, result = InventoryManager.GiveItem(charId, itemData.item_id, itemData.quantity, itemData.metadata)

    if not success then
        return false, result or "Cannot add item to inventory"
    end

    -- Remove from container
    table.remove(containerItems, itemIndex)
    container.items = containerItems

    -- Update container in DB (skip for test containers with ID > 10000)
    if containerId < 10000 then
        Queries.UpdateLootContainer(containerId, containerItems)
    end

    -- Update cache and notify all clients
    LootContainers.NotifyUpdate(containerId, container)

    -- Sync player inventory
    InventoryManager.UpdateClient(charId, playerId)

    print(('[Loot] Player %d took item %s from container %d'):format(playerId, itemData.item_id, containerId))

    return true
end

-- Transfer item to container (player inventory -> container)
function LootManager.TransferItem(playerId, containerId, itemInstanceId, toPosition)
    -- Get character ID
    local player = Ox.GetPlayer(playerId)
    if not player then
        return false, "Player not found"
    end
    local charId = player.charId

    -- Get container from centralized cache
    local container = LootContainers.Get(containerId)
    if not container and containerId < 10000 then
        container = Queries.LoadLootContainer(containerId)
        if container then
            LootContainers.Add(containerId, container)
        end
    end

    if not container then
        return false, "Container not found"
    end

    -- Validate distance
    local playerPed = GetPlayerPed(playerId)
    local playerCoords = GetEntityCoords(playerPed)
    local containerPos = container.position or container.coords
    local distance = #(playerCoords - vector3(containerPos.x, containerPos.y, containerPos.z))

    if distance > 5.0 then
        return false, "Too far from container"
    end

    -- Get player inventory to find the item
    local InventoryManager = require 'server.modules.inventory.manager'
    local playerInventory = InventoryManager.LoadPlayerInventory(charId)

    -- Find item in player inventory (check backpack AND pockets)
    local itemData = nil
    local itemLocation = nil

    -- Check backpack
    for _, item in ipairs(playerInventory.backpack.items) do
        if tostring(item.item_instance_id) == tostring(itemInstanceId) or tostring(item.id) == tostring(itemInstanceId) then
            itemData = item
            itemLocation = 'backpack'
            break
        end
    end

    -- Check pockets if not found in backpack
    if not itemData then
        for i, pocket in ipairs(playerInventory.pockets) do
            if pocket and pocket.item then
                if tostring(pocket.item.item_instance_id) == tostring(itemInstanceId) or tostring(pocket.item.id) == tostring(itemInstanceId) then
                    itemData = pocket.item
                    itemLocation = 'pocket'
                    break
                end
            end
        end
    end

    if not itemData then
        print(string.format('^3[Loot]^0 TransferItem: Item %s not found in player %d inventory', itemInstanceId, playerId))
        return false, "Item not found in player inventory"
    end

    print(string.format('^2[Loot]^0 TransferItem: Found item %s in player %s', itemInstanceId, itemLocation))

    -- Remove from player inventory
    local success, error = InventoryManager.RemoveItem(charId, itemData.item_instance_id or itemData.id, itemData.quantity)
    if not success then
        return false, error or "Cannot remove item from inventory"
    end

    -- Add to container items
    local containerItems = container.items or {}
    table.insert(containerItems, {
        id = itemData.item_instance_id or itemData.id,
        item_instance_id = itemData.item_instance_id or itemData.id,
        item_id = itemData.item_id,
        quantity = itemData.quantity,
        position = toPosition or { x = 0, y = 0 },
        rotation = itemData.rotation or 0,
        slot_type = 'grid',
        metadata = itemData.metadata
    })
    container.items = containerItems

    -- Update container in DB (skip for test containers)
    if containerId < 10000 then
        Queries.UpdateLootContainer(containerId, containerItems)
    end

    -- Update cache and notify all clients
    LootContainers.NotifyUpdate(containerId, container)

    -- Sync player inventory
    InventoryManager.UpdateClient(charId, playerId)

    print(('[Loot] Player %d transferred item %s to container %d'):format(playerId, itemData.item_id, containerId))

    return true
end

-- ============================================
-- CLEANUP
-- ============================================

-- Remove expired containers
function LootManager.CleanupExpiredContainers()
    local now = os.time()
    local toRemove = {}
    local allContainers = LootContainers.GetAll()

    for containerId, container in pairs(allContainers) do
        if container.despawn_time and container.despawn_time < now then
            table.insert(toRemove, containerId)
        end
    end

    for _, containerId in ipairs(toRemove) do
        LootContainers.Remove(containerId)
        LootContainers.NotifyRemoved(containerId)
        print(('[Loot] Despawned container %d'):format(containerId))
    end

    -- Also clean database (DISABLED until loot_containers table is created)
    -- Queries.CleanupExpiredContainers()

    print(('[Loot] Cleaned up %d expired containers'):format(#toRemove))
end

-- ============================================
-- INITIALIZATION
-- ============================================

-- Start cleanup timer (every 5 minutes)
CreateThread(function()
    while true do
        Wait(300000) -- 5 minutes
        LootManager.CleanupExpiredContainers()
    end
end)

return LootManager
