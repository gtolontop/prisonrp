--[[
    The Last Colony - Death Manager (Server)
    Handles death state persistence in database
]]

print('^2[Death Server]^0 Manager loaded')

local MySQL = MySQL or exports.oxmysql

-- ============================================
-- DATABASE FUNCTIONS
-- ============================================

--- Check if character is dead in database
--- @param charId number Character ID
--- @return boolean isDead
local function IsCharacterDead(charId)
    local result = MySQL.single.await('SELECT is_dead FROM characters WHERE charid = ?', {charId})
    return result and result.is_dead == 1
end

--- Mark character as dead in database
--- @param charId number Character ID
--- @param coords vector3 Death coordinates
local function MarkCharacterDead(charId, coords)
    MySQL.update('UPDATE characters SET is_dead = 1, death_coords = ?, death_time = NOW() WHERE charid = ?', {
        json.encode({x = coords.x, y = coords.y, z = coords.z}),
        charId
    })
    print(string.format('^3[Death Server]^0 Character %d marked as dead in database', charId))
end

--- Mark character as alive in database (after respawn)
--- @param charId number Character ID
local function MarkCharacterAlive(charId)
    MySQL.update('UPDATE characters SET is_dead = 0, death_coords = NULL, death_time = NULL WHERE charid = ?', {charId})
    print(string.format('^2[Death Server]^0 Character %d marked as alive in database', charId))
end

-- ============================================
-- EVENTS
-- ============================================

-- Listen for player death
RegisterNetEvent('tlc:serverPlayerDied', function()
    local playerId = source
    local playerPed = GetPlayerPed(playerId)
    local coords = GetEntityCoords(playerPed)

    -- Get character ID from ox_core
    local player = exports.ox_core:GetPlayer(playerId)
    if not player then
        print('^1[Death Server]^0 ERROR: Player not found for ID ' .. playerId)
        return
    end

    local charId = player.charId

    -- Mark as dead in database
    MarkCharacterDead(charId, coords)

    print(string.format('^3[Death Server]^0 Player %d (char %d) died at %.1f, %.1f, %.1f',
        playerId, charId, coords.x, coords.y, coords.z))
end)

-- Listen for player respawn
RegisterNetEvent('tlc:serverPlayerRespawned', function()
    local playerId = source

    -- Get character ID from ox_core
    local player = exports.ox_core:GetPlayer(playerId)
    if not player then
        print('^1[Death Server]^0 ERROR: Player not found for ID ' .. playerId)
        return
    end

    local charId = player.charId

    -- Mark as alive in database
    MarkCharacterAlive(charId)

    print(string.format('^2[Death Server]^0 Player %d (char %d) respawned', playerId, charId))
end)

-- Check death state on player loaded (ox_core event)
AddEventHandler('ox:playerLoaded', function(playerId, userId, charId)
    print(string.format('^2[Death Server]^0 Checking death state for player %d (char %d)', playerId, charId))

    -- Check if character was dead when they disconnected
    local isDead = IsCharacterDead(charId)

    if isDead then
        print(string.format('^3[Death Server]^0 Character %d was dead - triggering client respawn', charId))

        -- Wait a bit for client to fully load
        Wait(2000)

        -- Tell client to force respawn at hospital
        TriggerClientEvent('tlc:forceRespawnAfterReconnect', playerId)
    else
        print(string.format('^2[Death Server]^0 Character %d is alive - normal spawn', charId))
    end
end)

-- ============================================
-- EXPORTS
-- ============================================

exports('IsCharacterDead', IsCharacterDead)
exports('MarkCharacterDead', MarkCharacterDead)
exports('MarkCharacterAlive', MarkCharacterAlive)

print('^2[Death Server]^0 Manager initialized')
