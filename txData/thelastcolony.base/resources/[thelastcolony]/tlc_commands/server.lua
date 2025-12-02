lib.addCommand('freeze', {
    help = 'Freeze the player',
    params = {
        {
            name = 'target',
            type = 'playerId',
            help = 'Target player\'s server id',
        },
    },
    restricted = 'group.admin'
}, function(source, args, raw)
    if not args.target then
        return TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            title = 'Missing Argument',
            description = 'Please specify a player ID. Usage: /freeze <id>'
        })
    end

    local entity = GetPlayerPed(args.target)

    if entity == 0 then
        return TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            title = 'Invalid Target',
            description = 'Player not found or not online.'
        })
    end

    TriggerClientEvent('tlc_commands:freeze', args.target, true, true)

    local targetName = GetPlayerName(args.target)
    TriggerClientEvent('ox_lib:notify', source, {
        type = 'success',
        title = 'Player Frozen',
        description = ('Froze %s (ID: %s)'):format(targetName, args.target)
    })
    TriggerClientEvent('ox_lib:notify', args.target, {
        type = 'info',
        title = 'Frozen',
        description = 'You have been frozen by an admin.'
    })
end)

lib.addCommand('thaw', {
    help = 'Unfreeze the player',
    params = {
        {
            name = 'target',
            type = 'playerId',
            help = 'Target player\'s server id',
        },
    },
    restricted = 'group.admin'
}, function(source, args, raw)
    if not args.target then
        return TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            title = 'Missing Argument',
            description = 'Please specify a player ID. Usage: /thaw <id>'
        })
    end

    local entity = GetPlayerPed(args.target)

    if entity == 0 then
        return TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            title = 'Invalid Target',
            description = 'Player not found or not online.'
        })
    end

    TriggerClientEvent('tlc_commands:freeze', args.target, false, true)

    local targetName = GetPlayerName(args.target)
    TriggerClientEvent('ox_lib:notify', source, {
        type = 'success',
        title = 'Player Unfrozen',
        description = ('Unfroze %s (ID: %s)'):format(targetName, args.target)
    })
    TriggerClientEvent('ox_lib:notify', args.target, {
        type = 'success',
        title = 'Unfrozen',
        description = 'You have been unfrozen.'
    })
end)

-- Override ox_core car command to fix addon vehicle support
lib.addCommand('car', {
    help = 'Spawn a vehicle with the given model (supports addon vehicles)',
    params = {
        {
            name = 'model',
            type = 'string',
            help = 'The vehicle model name (e.g., "adder", "venatusc")',
        },
    },
    restricted = 'group.admin'
}, function(source, args, raw)
    if not args.model or args.model == '' then
        return TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            title = 'Missing Argument',
            description = 'Please specify a vehicle model. Usage: /car <model>',
            duration = 5000
        })
    end

    local playerId = source
    local ped = GetPlayerPed(playerId)

    if not ped or ped == 0 then
        return TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            title = 'Error',
            description = 'Player not found.',
            duration = 3000
        })
    end

    -- Get player coords and heading
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    -- Send to client to handle model loading and spawning
    -- Client will delete old vehicle and spawn new one
    TriggerClientEvent('tlc_commands:client:spawnVehicle', playerId, args.model, coords, heading)
end)

-- Fix/Repair vehicle command
lib.addCommand({'fix', 'repair'}, {
    help = 'Repair a vehicle',
    params = {
        {
            name = 'target',
            type = 'string',
            help = 'Player ID or "me" for yourself',
            optional = true
        },
    },
    restricted = 'group.admin'
}, function(source, args, raw)
    local targetId = source

    -- If target argument is provided
    if args.target then
        if args.target == 'me' then
            targetId = source
        else
            targetId = tonumber(args.target)
            if not targetId then
                return TriggerClientEvent('ox_lib:notify', source, {
                    type = 'error',
                    title = 'Invalid Argument',
                    description = 'Invalid player ID. Usage: /fix [id] or /fix me'
                })
            end
        end
    end

    -- Verify target player exists
    local targetPed = GetPlayerPed(targetId)
    if targetPed == 0 then
        return TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            title = 'Player Not Found',
            description = ('Player ID %s is not online.'):format(targetId)
        })
    end

    -- Get target's vehicle
    local vehicle = GetVehiclePedIsIn(targetPed, false)

    if vehicle == 0 then
        local targetName = GetPlayerName(targetId)
        return TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            title = 'Not In Vehicle',
            description = targetId == source and 'You must be in a vehicle.' or ('%s is not in a vehicle.'):format(targetName)
        })
    end

    -- Convert to network ID before sending to client
    local vehicleNetId = NetworkGetNetworkIdFromEntity(vehicle)

    -- Repair the vehicle (client-side natives)
    TriggerClientEvent('tlc_commands:client:repairVehicle', targetId, vehicleNetId)

    -- Notify success
    if targetId == source then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'success',
            title = 'Vehicle Repaired',
            description = 'Your vehicle has been fully repaired.'
        })
    else
        local targetName = GetPlayerName(targetId)
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'success',
            title = 'Vehicle Repaired',
            description = ('Repaired %s\'s vehicle (ID: %s)'):format(targetName, targetId)
        })
        TriggerClientEvent('ox_lib:notify', targetId, {
            type = 'success',
            title = 'Vehicle Repaired',
            description = 'Your vehicle has been repaired by an admin.'
        })
    end
end)
