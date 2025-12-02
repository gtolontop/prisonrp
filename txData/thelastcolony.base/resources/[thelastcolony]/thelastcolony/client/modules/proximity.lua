--[[
    Proximity System (Client-side)
    Centralized entity proximity tracking to avoid multiple distance check loops

    Instead of having 10 different systems each running their own distance check loops,
    we have ONE loop that checks distances and notifies interested systems.

    Usage:
    local Proximity = exports.thelastcolony:GetProximitySystem()

    Proximity.Register(entity, {
        maxDistance = 10.0,
        onNear = function(entity, distance)
            -- Called when entity enters range
        end,
        onFar = function(entity)
            -- Called when entity leaves range
        end,
        onUpdate = function(entity, distance, isNear)
            -- Called every tick with current state
        end
    })
]]

local Proximity = {}

-- Registered entities {entity = {maxDistance, callbacks, lastState}}
local registered = {}

-- Config
local CHECK_INTERVAL = 500 -- Check every 500ms (10 FPS)
local DEBUG_MODE = false -- Enable debug logs (set to false in production)

-- ============================================
-- CORE FUNCTIONS
-- ============================================

--- Register an entity for proximity tracking
--- @param entity number Entity handle
--- @param options table {maxDistance, checkFOV?, fovAngle?, onNear?, onFar?, onUpdate?}
--- @return boolean success
function Proximity.Register(entity, options)
    if not DoesEntityExist(entity) then
        print('^3[Proximity]^0 WARNING: Entity does not exist')
        return false
    end

    if not options.maxDistance then
        print('^3[Proximity]^0 ERROR: maxDistance is required')
        return false
    end

    -- Cache entity coords if static (props don't move)
    local entityCoords = GetEntityCoords(entity)
    local isStatic = IsEntityStatic(entity)

    registered[entity] = {
        maxDistance = options.maxDistance,
        checkFOV = options.checkFOV or false, -- Check if entity is in front of player
        fovAngle = options.fovAngle or 90.0, -- Angle in degrees (90 = front 180deg cone, 180 = all around)
        onNear = options.onNear,
        onFar = options.onFar,
        onUpdate = options.onUpdate,
        isStatic = isStatic, -- Cache this to avoid repeated GetEntityCoords
        cachedCoords = isStatic and entityCoords or nil, -- Only cache if static
        lastState = {
            isNear = false,
            isInFOV = false,
            distance = nil,
            angle = nil,
            lastCheck = 0
        }
    }

    print(string.format('^2[Proximity]^0 Registered entity %d (maxDistance: %.1fm, FOV: %s)',
        entity, options.maxDistance, tostring(options.checkFOV)))
    return true
end

--- Unregister an entity
--- @param entity number Entity handle
--- @return boolean success
function Proximity.Unregister(entity)
    if registered[entity] then
        -- Call onFar if was near
        if registered[entity].lastState.isNear and registered[entity].onFar then
            registered[entity].onFar(entity)
        end

        registered[entity] = nil
        print(string.format('^2[Proximity]^0 Unregistered entity %d', entity))
        return true
    end
    return false
end

--- Check if entity is registered
--- @param entity number Entity handle
--- @return boolean
function Proximity.IsRegistered(entity)
    return registered[entity] ~= nil
end

--- Get current state for entity
--- @param entity number Entity handle
--- @return table|nil {isNear, distance}
function Proximity.GetState(entity)
    if registered[entity] then
        return registered[entity].lastState
    end
    return nil
end

--- Update max distance for entity
--- @param entity number Entity handle
--- @param maxDistance number New max distance
--- @return boolean success
function Proximity.UpdateMaxDistance(entity, maxDistance)
    if registered[entity] then
        registered[entity].maxDistance = maxDistance
        return true
    end
    return false
end

--- Get all nearby entities (within their maxDistance)
--- @return table Array of {entity, distance}
function Proximity.GetAllNearby()
    local nearby = {}
    for entity, data in pairs(registered) do
        if data.lastState.isNear then
            table.insert(nearby, {
                entity = entity,
                distance = data.lastState.distance
            })
        end
    end
    return nearby
end

--- Remove all registrations (cleanup)
function Proximity.UnregisterAll()
    local count = 0
    for entity, data in pairs(registered) do
        -- Call onFar for all that were near
        if data.lastState.isNear and data.onFar then
            data.onFar(entity)
        end
        count = count + 1
    end

    registered = {}
    print(string.format('^2[Proximity]^0 Unregistered %d entities', count))
end

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

--- Calculate if entity is within player's FOV (field of view)
--- @param playerCoords vector3 Player position
--- @param playerHeading number Player heading (degrees, GTA format: 0=North)
--- @param entityCoords vector3 Entity position
--- @param fovAngle number Max angle from forward direction (degrees)
--- @return boolean isInFOV, number angle
local function IsInFOV(playerCoords, playerHeading, entityCoords, fovAngle)
    -- Vector from player to entity
    local dx = entityCoords.x - playerCoords.x
    local dy = entityCoords.y - playerCoords.y

    -- Angle to entity in math coordinates (0° = East, counter-clockwise)
    local angleToEntityMath = math.deg(math.atan2(dy, dx))

    -- Convert GTA heading to math angle
    -- GTA: 0° = North, clockwise
    -- Math: 0° = East, counter-clockwise
    -- Conversion: mathAngle = 90 - gtaHeading
    local playerAngleMath = 90.0 - playerHeading

    -- Normalize both angles to 0-360
    angleToEntityMath = angleToEntityMath % 360
    playerAngleMath = playerAngleMath % 360

    -- Calculate angle difference (shortest path)
    local angleDiff = math.abs(angleToEntityMath - playerAngleMath)
    if angleDiff > 180 then
        angleDiff = 360 - angleDiff
    end

    -- Check if within FOV cone
    local isInFOV = angleDiff <= fovAngle

    return isInFOV, angleDiff
end

-- ============================================
-- MAIN LOOP (ONE LOOP FOR ALL SYSTEMS)
-- ============================================

CreateThread(function()
    while true do
        Wait(CHECK_INTERVAL)

        local ped = PlayerPedId()
        local playerCoords = GetEntityCoords(ped)
        local playerHeading = GetEntityHeading(ped)

        -- Count registered entities
        local count = 0
        for _ in pairs(registered) do count = count + 1 end

        if DEBUG_MODE and count > 0 then
            print(string.format('^6[Proximity]^0 Checking %d registered entities (heading: %.0f°)', count, playerHeading))
        end

        for entity, data in pairs(registered) do
            -- Check if entity still exists
            if not DoesEntityExist(entity) then
                -- Entity deleted, unregister it
                Proximity.Unregister(entity)
            else
                -- Get entity coords (use cache if static to avoid native call)
                local entityCoords = data.cachedCoords or GetEntityCoords(entity)
                local distance = #(playerCoords - entityCoords)

                -- Check FOV if enabled
                local isInFOV = true
                local angle = 0
                if data.checkFOV then
                    isInFOV, angle = IsInFOV(playerCoords, playerHeading, entityCoords, data.fovAngle)
                end

                -- Entity is "near" if within distance AND within FOV (if FOV check enabled)
                local isNear = distance <= data.maxDistance and isInFOV
                local wasNear = data.lastState.isNear

                -- Debug log only for close entities (< 20m) to avoid spam
                if DEBUG_MODE and distance < 20.0 then
                    if data.checkFOV then
                        print(string.format('^5[Proximity]^0 Entity %d: dist=%.1fm, angle=%.0f°, inFOV=%s, isNear=%s, wasNear=%s',
                            entity, distance, angle, tostring(isInFOV), tostring(isNear), tostring(wasNear)))
                    else
                        print(string.format('^5[Proximity]^0 Entity %d: dist=%.1fm, isNear=%s, wasNear=%s (no FOV)',
                            entity, distance, tostring(isNear), tostring(wasNear)))
                    end
                end

                -- State changed (near -> far OR far -> near)
                if isNear and not wasNear then
                    -- Entered range
                    if DEBUG_MODE then
                        print(string.format('^2[Proximity]^0 Entity %d ENTERED range+FOV', entity))
                    end
                    if data.onNear then
                        data.onNear(entity, distance)
                    end
                elseif not isNear and wasNear then
                    -- Left range
                    if DEBUG_MODE then
                        print(string.format('^3[Proximity]^0 Entity %d LEFT range+FOV', entity))
                    end
                    if data.onFar then
                        data.onFar(entity)
                    end
                end

                -- Always call onUpdate if provided
                if data.onUpdate then
                    data.onUpdate(entity, distance, isNear)
                end

                -- Update state
                data.lastState.isNear = isNear
                data.lastState.isInFOV = isInFOV
                data.lastState.distance = distance
                data.lastState.angle = angle
                data.lastState.lastCheck = GetGameTimer()
            end
        end
    end
end)

-- ============================================
-- CLEANUP ON RESOURCE STOP
-- ============================================

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    print('^2[Proximity]^0 Cleaning up all registrations...')
    Proximity.UnregisterAll()
end)

-- ============================================
-- EXPORTS
-- ============================================

exports('GetProximitySystem', function()
    return Proximity
end)

exports('RegisterProximity', Proximity.Register)
exports('UnregisterProximity', Proximity.Unregister)
exports('IsRegisteredProximity', Proximity.IsRegistered)
exports('GetProximityState', Proximity.GetState)

print('^2[Proximity]^0 Centralized proximity system loaded')

return Proximity
