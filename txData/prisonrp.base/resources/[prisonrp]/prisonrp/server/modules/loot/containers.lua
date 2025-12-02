--[[
    Loot Container Manager (Server)
    Handles loading, caching, and syncing loot containers
]]

local Queries = require 'server.modules.inventory.db.queries'
local Items = require 'shared.items'

local Containers = {}

-- Cache of all active containers {containerId = containerData}
local activeContainers = {}

-- ============================================
-- INITIALIZATION
-- ============================================

--- Load all containers from database on server start
function Containers.LoadAll()
    print('[Loot] Loading all loot containers from database...')

    local containers = Queries.LoadAllLootContainers()

    -- Cache them
    for _, container in ipairs(containers) do
        activeContainers[container.container_id] = container
    end

    print(string.format('[Loot] Loaded %d loot containers', #containers))

    return containers
end

--- Get all active containers
function Containers.GetAll()
    return activeContainers
end

--- Get container by ID
function Containers.Get(containerId)
    return activeContainers[containerId]
end

--- Add new container to cache
function Containers.Add(containerId, containerData)
    activeContainers[containerId] = containerData
    print(string.format('[Loot] Added container %d to cache', containerId))
end

--- Update container in cache
function Containers.Update(containerId, containerData)
    activeContainers[containerId] = containerData
    print(string.format('[Loot] Updated container %d in cache', containerId))
end

--- Remove container from cache AND database
function Containers.Remove(containerId)
    activeContainers[containerId] = nil

    -- Also remove from database to prevent duplication on restart
    local Queries = require 'server.modules.inventory.db.queries'
    Queries.DeleteLootContainer(containerId)

    print(string.format('[Loot] Removed container %d from cache and database', containerId))
end

-- ============================================
-- CLIENT SYNC
-- ============================================

--- Sync all containers to a player (when they join or request)
function Containers.SyncToPlayer(playerId)
    local containerList = {}

    for containerId, container in pairs(activeContainers) do
        -- Get first item info for prop model
        local firstItem = container.items and container.items[1]
        local itemDef = firstItem and Items[firstItem.item_id]

        table.insert(containerList, {
            containerId = containerId,
            containerType = container.container_type,
            coords = container.position,
            rotation = container.rotation, -- Include full rotation from DB
            item_id = firstItem and firstItem.item_id or 'unknown',
            item_name = itemDef and itemDef.name or 'Unknown',
            quantity = firstItem and firstItem.quantity or 0,
            model = itemDef and itemDef.world_prop or `prop_cs_cardbox_01`
        })
    end

    TriggerClientEvent('loot:syncContainers', playerId, containerList)

    print(string.format('[Loot] Synced %d containers to player %d', #containerList, playerId))
end

--- Sync all containers to all players
function Containers.SyncToAll()
    local containerList = {}

    for containerId, container in pairs(activeContainers) do
        -- Get first item info for prop model
        local firstItem = container.items and container.items[1]
        local itemDef = firstItem and Items[firstItem.item_id]

        table.insert(containerList, {
            containerId = containerId,
            containerType = container.container_type,
            coords = container.position,
            rotation = container.rotation, -- Include full rotation from DB
            item_id = firstItem and firstItem.item_id or 'unknown',
            item_name = itemDef and itemDef.name or 'Unknown',
            quantity = firstItem and firstItem.quantity or 0,
            model = itemDef and itemDef.world_prop or `prop_cs_cardbox_01`
        })
    end

    TriggerClientEvent('loot:syncContainers', -1, containerList)

    print(string.format('[Loot] Synced %d containers to all players', #containerList))
end

--- Notify all players about a new container
function Containers.NotifyNew(containerId, containerData)
    local firstItem = containerData.items and containerData.items[1]
    local itemDef = firstItem and Items[firstItem.item_id]

    -- Use coords from position field if available
    local coords = containerData.coords or containerData.position

    -- Use model from containerData (if provided), otherwise from itemDef, otherwise fallback
    local model = containerData.model or (itemDef and itemDef.world_prop) or `prop_cs_cardbox_01`

    TriggerClientEvent('loot:addContainer', -1, {
        containerId = containerId,
        containerType = containerData.container_type,
        coords = coords,
        rotation = containerData.rotation, -- Pass full rotation for accurate spawning
        item_id = firstItem and firstItem.item_id or 'unknown',
        item_name = itemDef and itemDef.name or 'Unknown',
        quantity = firstItem and firstItem.quantity or 0,
        model = model -- Use the correct model
    })

    if containerData.rotation then
        print(string.format('[Loot] Notified all clients about new container %d (model: %s, rot: %.2f/%.2f/%.2f)',
            containerId, model, containerData.rotation.pitch, containerData.rotation.roll, containerData.rotation.yaw))
    else
        print(string.format('[Loot] Notified all clients about new container %d (model: %s)', containerId, model))
    end
end

--- Notify all players about a removed container
function Containers.NotifyRemoved(containerId)
    TriggerClientEvent('loot:removeContainer', -1, containerId)
end

--- Notify all players about updated container (item taken/added)
function Containers.NotifyUpdate(containerId, containerData)
    -- Update cache
    activeContainers[containerId] = containerData

    -- Send update to all players
    TriggerClientEvent('loot:updateContainer', -1, {
        id = tostring(containerId),
        type = containerData.container_type,
        name = containerData.container_type or 'Loot Container',
        grid = {
            width = containerData.grid_width,
            height = containerData.grid_height,
            items = containerData.items or {}
        }
    })

    print(string.format('[Loot] Notified container %d update to all clients', containerId))
end

return Containers
