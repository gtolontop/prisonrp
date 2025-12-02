-- Command to give permanent items to a player (for existing characters)
RegisterCommand('givepermanentitems', function(source, args, rawCommand)
    local playerId = source

    if playerId == 0 then
        -- Server console - need player ID
        playerId = tonumber(args[1])
        if not playerId then
            print('[ERROR] Usage: givepermanentitems <playerId>')
            return
        end
    end

    -- Get player data
    local player = Ox.GetPlayer(playerId)
    if not player then
        print('[ERROR] Player not found')
        return
    end

    local charId = player.charId
    if not charId then
        print('[ERROR] Character ID not found')
        return
    end

    print(string.format('[GivePermanentItems] Starting for player %d (charId: %d)', playerId, charId))

    -- Load necessary modules
    local Queries = require 'server.modules.inventory.db.queries'
    local Items = require 'shared.items'

    -- Check if player already has the case
    local hasCase = MySQL.scalar.await([[
        SELECT item_instance_id
        FROM equipment
        WHERE charid = ? AND slot_name = 'case' AND item_instance_id IS NOT NULL
    ]], { charId })

    if not hasCase then
        print('[GivePermanentItems] Creating secure case...')

        -- 1. Create secure_case item in inventory_items
        local caseItemId = Queries.CreateItem(
            charId,
            'secure_case',
            1,
            'equipment',
            nil, -- slot_index
            nil, -- position
            0,   -- rotation
            {}   -- metadata
        )

        -- 2. Link secure_case to equipment slot
        Queries.EquipItem(charId, 'case', caseItemId)

        print(string.format('[GivePermanentItems] ✅ Secure case created (ID: %d)', caseItemId))

        -- 3. Create card (minimap) inside the case
        local cardItemId = Queries.CreateItem(
            charId,
            'minimap',
            1,
            'case_storage',
            nil, -- slot_index
            { x = 0, y = 0 }, -- position in 3x1 grid
            0,   -- rotation
            {}   -- metadata
        )

        print(string.format('[GivePermanentItems] ✅ Card/Minimap created (ID: %d)', cardItemId))

        -- 4. Create compass inside the case
        local compassItemId = Queries.CreateItem(
            charId,
            'compass',
            1,
            'case_storage',
            nil, -- slot_index
            { x = 2, y = 0 }, -- position in 3x1 grid (at the end)
            0,   -- rotation
            {}   -- metadata
        )

        print(string.format('[GivePermanentItems] ✅ Compass created (ID: %d)', compassItemId))
    else
        print('[GivePermanentItems] Player already has a secure case')
    end

    -- Check if player already has the knife
    local hasKnife = MySQL.scalar.await([[
        SELECT item_instance_id
        FROM equipment
        WHERE charid = ? AND slot_name = 'sheath' AND item_instance_id IS NOT NULL
    ]], { charId })

    if not hasKnife then
        print('[GivePermanentItems] Creating knife...')

        -- 1. Create knife item in inventory_items
        local knifeItemId = Queries.CreateItem(
            charId,
            'knife',
            1,
            'equipment',
            nil, -- slot_index
            nil, -- position
            0,   -- rotation
            {}   -- metadata
        )

        -- 2. Link knife to equipment slot
        Queries.EquipItem(charId, 'sheath', knifeItemId)

        print(string.format('[GivePermanentItems] ✅ Knife created (ID: %d)', knifeItemId))
    else
        print('[GivePermanentItems] Player already has a knife')
    end

    -- Clear inventory cache and sync to client
    local Manager = require 'server.modules.inventory.manager'
    Manager.ClearCache(charId)
    Manager.UpdateClient(charId, playerId)

    print(string.format('[GivePermanentItems] ✅ Done! Player %d now has all permanent items', playerId))

    TriggerClientEvent('ox_lib:notify', playerId, {
        type = 'success',
        description = 'Permanent items added to your inventory'
    })
end, false)

print('[Commands] ✅ givepermanentitems command registered')
