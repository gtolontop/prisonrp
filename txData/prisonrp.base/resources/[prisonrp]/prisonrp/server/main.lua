--[[
    The Last Colony - Server Main
    Entry point for server-side logic
]]

local ox = lib -- ox_lib is already loaded via shared_script

print('^2[The Last Colony]^0 Server starting...')

-- ============================================
-- OX_CORE INTEGRATION
-- ============================================

-- Wait for ox_core to be ready
CreateThread(function()
    while GetResourceState('ox_core') ~= 'started' do
        Wait(100)
    end

    print('^2[The Last Colony]^0 ox_core detected and ready')

    -- Load all loot containers from database
    Wait(1000) -- Wait for DB to be ready
    local LootContainers = require 'server.modules.loot.containers'
    LootContainers.LoadAll()
end)

-- ============================================
-- PLAYER LOADED EVENT
-- ============================================

-- When a player loads a character, initialize their inventory
AddEventHandler('ox:playerLoaded', function(source, userId, charId)
    local player = Ox.GetPlayer(source)

    if not player then
        print(string.format('^3[Warning]^0 Player %s loaded but Ox.GetPlayer returned nil', source))
        return
    end

    print(string.format('^2[The Last Colony]^0 Player %s (CharID: %s) loaded', source, charId))

    -- Sync all loot containers to this player
    local LootContainers = require 'server.modules.loot.containers'
    LootContainers.SyncToPlayer(source)

    -- Give default items if new character
    -- TODO: Check if inventory is empty, give starter items
end)

-- ============================================
-- PLAYER LOGOUT EVENT
-- ============================================

AddEventHandler('ox:playerLogout', function(source, userId, charId)
    print(string.format('^2[The Last Colony]^0 Player %s (CharID: %s) logged out', source, charId))

    -- Clear any cached data
    -- Manager.ClearCache(charId) is called automatically in inventory events
end)

-- ============================================
-- ADMIN COMMANDS (Debug)
-- ============================================

-- Give item to player
RegisterCommand('giveitem', function(source, args, rawCommand)
    if source == 0 then
        print('^3[Warning]^0 This command can only be used in-game')
        return
    end

    local player = Ox.GetPlayer(source)
    if not player then
        return
    end

    -- TODO: Check admin permission
    -- if not player.hasPermission('group.admin.inventory') then
    --     return
    -- end

    local itemId = args[1]
    local quantity = tonumber(args[2]) or 1

    if not itemId then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'Usage: /giveitem <item_id> [quantity]'
        })
        return
    end

    local Manager = require 'server.modules.inventory.manager'
    local charId = player.charId

    local success, result = Manager.GiveItem(charId, itemId, quantity)

    if success then
        local given = result.given
        local refused = result.refused

        -- Build message
        local message = string.format('Given %dx %s', given, itemId)
        if refused > 0 then
            message = message .. string.format(', refused %dx (not enough space)', refused)
        end

        TriggerClientEvent('ox_lib:notify', source, {
            type = given == quantity and 'success' or 'warning',
            description = message
        })

        -- Update client inventory (without opening UI)
        Manager.UpdateClient(charId, source)

        print(string.format('[GiveItem] Given %d/%d items to charId %s', given, quantity, charId))
    else
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'Error: ' .. (result or 'Unknown error')
        })
    end
end, false)

-- Clear inventory (debug)
RegisterCommand('clearinv', function(source, args, rawCommand)
    if source == 0 then
        print('^3[Warning]^0 This command can only be used in-game')
        return
    end

    local player = Ox.GetPlayer(source)
    if not player then
        return
    end

    -- TODO: Implement clear inventory function
    TriggerClientEvent('ox_lib:notify', source, {
        type = 'info',
        description = 'Clear inventory not yet implemented'
    })
end, false)

-- ============================================
-- RESOURCE CLEANUP
-- ============================================

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    print('^2[The Last Colony]^0 Server stopping...')

    -- Save all player inventories before shutdown
    local players = Ox.GetPlayers()
    for _, player in pairs(players) do
        if player.charId then
            -- Inventory is auto-saved on every operation via database
            print(string.format('^2[The Last Colony]^0 Player %s data auto-saved', player.source))
        end
    end
end)

print('^2[The Last Colony]^0 Server main loaded successfully')
