--[[
    Loot Props Manager (Client)
    Handles spawning and managing visual props for loot containers
]]

local Props = {}

-- Cache of spawned props {containerId = propHandle}
local spawnedProps = {}

-- Track last prop that had outline (for dynamic outline system)
local lastOutlinedProp = nil

-- Track last prop that had TextUI3D
local lastTextUIProp = nil

-- Track props that are in "flash red" mode {propHandle = endTime}
local flashingProps = {}

-- Track props that are fading in/out {propHandle = {progress, targetAlpha, color, isFadingOut}}
local fadingProps = {}

-- Fade config
local FADE_DURATION = 0.2 -- Duration in seconds (200ms for smooth fade)
local TARGET_ALPHA = 200 -- Target alpha for visible outline

--- Ease-in-out function (smooth acceleration/deceleration)
--- @param t number Progress from 0 to 1
--- @return number Eased value from 0 to 1
local function EaseInOutCubic(t)
    if t < 0.5 then
        return 4 * t * t * t
    else
        return 1 - math.pow(-2 * t + 2, 3) / 2
    end
end

-- ============================================
-- VISIBILITY CHECK (RAYCAST)
-- ============================================

--- Check if entity is visible (not behind a wall)
--- Uses simplified raycast (3 points like outline.lua)
--- @param entity number Entity handle
--- @return boolean isVisible
local function IsEntityVisible(entity)
    if not DoesEntityExist(entity) then
        return false
    end

    local playerPed = PlayerPedId()
    local camCoords = GetGameplayCamCoord()
    local entityCoords = GetEntityCoords(entity)
    local min, max = GetModelDimensions(GetEntityModel(entity))

    -- Test 3 points (center + 2 corners)
    local testPoints = {
        entityCoords,
        GetOffsetFromEntityInWorldCoords(entity, min.x, min.y, min.z),
        GetOffsetFromEntityInWorldCoords(entity, max.x, max.y, max.z),
    }

    for _, point in ipairs(testPoints) do
        local raycast = StartShapeTestRay(
            camCoords.x, camCoords.y, camCoords.z,
            point.x, point.y, point.z,
            -1, playerPed, 0
        )
        local _, hit, _, _, hitEntity = GetShapeTestResult(raycast)

        -- If any point is visible, entity is visible
        if (not hit) or (hitEntity == entity) then
            return true
        end
    end

    return false
end

-- ============================================
-- PROP SPAWNING
-- ============================================

--- Spawn a single prop for a container
--- @param containerData table Container data with coords, model, etc.
function Props.Spawn(containerData)
    if not containerData or not containerData.coords then
        print('^3[Loot]^0 ERROR: Invalid container data')
        return
    end

    -- Check if already spawned
    if spawnedProps[containerData.containerId] then
        print(string.format('^3[Loot]^0 Container %d already has a prop spawned', containerData.containerId))
        return
    end

    local propModel = containerData.model or `prop_cs_cardbox_01`
    local coords = containerData.coords

    -- Load model
    RequestModel(propModel)
    local timeout = 0
    while not HasModelLoaded(propModel) and timeout < 5000 do
        Wait(10)
        timeout = timeout + 10
    end

    if not HasModelLoaded(propModel) then
        print(string.format('^3[Loot]^0 ERROR: Failed to load model %s', propModel))
        propModel = `prop_cs_cardbox_01` -- Fallback
        RequestModel(propModel)
        while not HasModelLoaded(propModel) do
            Wait(10)
        end
    end

    local isDroppedItem = containerData.containerType == 'dropped_item'

    -- Create prop (network + mission for synced physics)
    local prop = CreateObject(propModel, coords.x, coords.y, coords.z, true, true, false)

    -- Important: Freeze BEFORE setting position/rotation to prevent physics interference
    FreezeEntityPosition(prop, true)

    -- Set exact position
    SetEntityCoords(prop, coords.x, coords.y, coords.z, false, false, false, false)

    -- Set rotation (use full rotation if available, otherwise just heading)
    if containerData.rotation then
        -- Full 3D rotation (pitch, roll, yaw)
        SetEntityRotation(prop, containerData.rotation.pitch, containerData.rotation.roll, containerData.rotation.yaw, 2, true)
        print(string.format('^2[Loot]^0 Prop %d spawned with full rotation: %.2f, %.2f, %.2f',
            prop, containerData.rotation.pitch, containerData.rotation.roll, containerData.rotation.yaw))
    else
        -- Legacy heading only
        local heading = coords.heading or 0.0
        SetEntityHeading(prop, heading)
        print(string.format('^2[Loot]^0 Prop %d spawned with heading: %.2f', prop, heading))
    end

    -- NOTE: Outline and TextUI3D are NOT added here - they're added dynamically
    -- in the main thread when player looks at the prop AND it's visible (no wall)
    -- See the outline/TextUI3D thread below

    -- Store container data on entity for dynamic TextUI3D
    Entity(prop).state.containerId = containerData.containerId
    Entity(prop).state.itemId = containerData.item_id
    Entity(prop).state.quantity = containerData.quantity
    Entity(prop).state.containerType = containerData.containerType

    -- Cache it
    spawnedProps[containerData.containerId] = prop

    print(string.format('^2[Loot]^0 Spawned prop for container %d (entity: %d, item: %s)',
        containerData.containerId, prop, containerData.item_id))

    return prop
end

--- Flash red outline on prop (pickup failed)
--- @param containerId number Container ID
function Props.FlashRed(containerId)
    local prop = spawnedProps[containerId]

    if not prop or not DoesEntityExist(prop) then
        return
    end

    -- Mark this prop as flashing (1 second duration)
    flashingProps[prop] = GetGameTimer() + 1000

    -- Force update the outline color to red immediately (using fade system)
    UpdateFadeColor(prop, {r = 255, g = 0, b = 0})

    print(string.format('^3[Loot]^0 Flashing red on prop %d (container %d)', prop, containerId))
end

--- Remove a prop for a container
--- @param containerId number Container ID
function Props.Remove(containerId)
    local prop = spawnedProps[containerId]

    if not prop then
        print(string.format('^3[Loot]^0 No prop found for container %d', containerId))
        return
    end

    if DoesEntityExist(prop) then
        -- Remove outline (in case it was active)
        exports.thelastcolony:RemoveOutline(prop)

        -- Clear from all trackers
        if lastOutlinedProp == prop then
            lastOutlinedProp = nil
        end
        if lastTextUIProp == prop then
            lastTextUIProp = nil
        end
        flashingProps[prop] = nil
        fadingProps[prop] = nil

        -- Remove 3D text UI
        local TextUI3D = exports.thelastcolony:GetTextUI3D()
        TextUI3D.Remove(prop)

        -- Delete prop
        DeleteEntity(prop)
    end

    spawnedProps[containerId] = nil

    print(string.format('^2[Loot]^0 Removed prop for container %d', containerId))
end

--- Spawn all containers
--- @param containers table Array of container data
function Props.SpawnAll(containers)
    local count = 0

    for _, containerData in ipairs(containers) do
        Props.Spawn(containerData)
        count = count + 1
    end

    print(string.format('^2[Loot]^0 Spawned %d props', count))
end

--- Remove all props
function Props.RemoveAll()
    local count = 0

    for containerId, prop in pairs(spawnedProps) do
        if DoesEntityExist(prop) then
            exports.thelastcolony:RemoveOutline(prop)
            DeleteEntity(prop)
        end
        count = count + 1
    end

    spawnedProps = {}
    lastOutlinedProp = nil -- Clear outlined prop tracker
    lastTextUIProp = nil -- Clear TextUI3D tracker
    flashingProps = {} -- Clear flashing props tracker
    fadingProps = {} -- Clear fading props tracker

    print(string.format('^2[Loot]^0 Removed %d props', count))
end

--- Get prop handle for container
--- @param containerId number Container ID
--- @return number|nil Prop handle
function Props.Get(containerId)
    return spawnedProps[containerId]
end

-- ============================================
-- OUTLINE SYSTEM (DYNAMIC - ONLY WHEN LOOKING)
-- ============================================

--- Start fading in an outline
--- @param entity number Entity handle
--- @param color table {r, g, b}
local function StartFadeIn(entity, color)
    if not fadingProps[entity] then
        -- Start from progress 0
        fadingProps[entity] = {
            progress = 0.0,
            startTime = GetGameTimer(),
            color = color,
            isFadingOut = false
        }
        -- Add outline with alpha 0 to start
        exports.thelastcolony:AddOutline(entity, {r = color.r, g = color.g, b = color.b, a = 0}, 1)
    else
        -- Already fading - reverse direction for fade in
        fadingProps[entity].startTime = GetGameTimer()
        fadingProps[entity].progress = fadingProps[entity].isFadingOut and (1.0 - fadingProps[entity].progress) or fadingProps[entity].progress
        fadingProps[entity].isFadingOut = false
        fadingProps[entity].color = color
    end
end

--- Start fading out an outline
--- @param entity number Entity handle
local function StartFadeOut(entity)
    if fadingProps[entity] then
        -- Reverse direction for fade out
        fadingProps[entity].startTime = GetGameTimer()
        fadingProps[entity].progress = fadingProps[entity].isFadingOut and fadingProps[entity].progress or (1.0 - fadingProps[entity].progress)
        fadingProps[entity].isFadingOut = true
    else
        -- Not currently fading - remove immediately
        exports.thelastcolony:RemoveOutline(entity)
    end
end

--- Update color for a fading outline (for flash red)
--- @param entity number Entity handle
--- @param color table {r, g, b}
local function UpdateFadeColor(entity, color)
    if fadingProps[entity] then
        fadingProps[entity].color = color
        -- Calculate current alpha based on progress
        local t = fadingProps[entity].isFadingOut and (1.0 - fadingProps[entity].progress) or fadingProps[entity].progress
        local easedT = EaseInOutCubic(t)
        local currentAlpha = math.floor(easedT * TARGET_ALPHA)
        -- Update immediately
        exports.thelastcolony:UpdateOutlineColor(entity, {
            r = color.r,
            g = color.g,
            b = color.b,
            a = currentAlpha
        })
    end
end

-- Thread to update fading outlines with easing (60 FPS)
CreateThread(function()
    while true do
        -- Check if there are any fading props
        if next(fadingProps) == nil then
            Wait(100) -- Sleep longer if nothing to fade
            goto continue
        end

        Wait(16) -- ~60 FPS

        local currentTime = GetGameTimer()

        for entity, fadeData in pairs(fadingProps) do
            if DoesEntityExist(entity) then
                -- Calculate progress (0.0 to 1.0) based on time elapsed
                local elapsed = (currentTime - fadeData.startTime) / 1000.0 -- Convert to seconds
                local progress = math.min(elapsed / FADE_DURATION, 1.0)

                fadeData.progress = progress

                -- Apply easing
                local easedProgress = EaseInOutCubic(progress)

                -- Calculate alpha based on direction
                local alpha
                if fadeData.isFadingOut then
                    -- Fade out: 1.0 → 0.0
                    alpha = math.floor((1.0 - easedProgress) * TARGET_ALPHA)
                else
                    -- Fade in: 0.0 → 1.0
                    alpha = math.floor(easedProgress * TARGET_ALPHA)
                end

                -- Update outline color with eased alpha
                exports.thelastcolony:UpdateOutlineColor(entity, {
                    r = fadeData.color.r,
                    g = fadeData.color.g,
                    b = fadeData.color.b,
                    a = alpha
                })

                -- If animation complete
                if progress >= 1.0 then
                    if fadeData.isFadingOut then
                        -- Fade out complete - remove outline
                        exports.thelastcolony:RemoveOutline(entity)
                        fadingProps[entity] = nil
                    end
                    -- If fade in complete, keep the outline (don't remove from fadingProps yet in case we need to fade out)
                end
            else
                -- Entity no longer exists
                fadingProps[entity] = nil
            end
        end

        ::continue::
    end
end)

-- Thread to add outline + TextUI3D when looking at a visible prop
CreateThread(function()
    local TextUI3D = exports.thelastcolony:GetTextUI3D()
    local Animations = require 'shared.animations'

    while true do
        Wait(100) -- Check every 100ms

        local currentTime = GetGameTimer()
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)

        -- Clean up expired flashing props
        for prop, endTime in pairs(flashingProps) do
            if currentTime >= endTime then
                flashingProps[prop] = nil
                -- Restore white outline if player is still looking at it
                if lastOutlinedProp == prop and DoesEntityExist(prop) then
                    UpdateFadeColor(prop, {r = 255, g = 255, b = 255})
                end
            end
        end

        -- Find closest visible loot prop within range
        local closestProp = nil
        local closestDistance = 3.5 -- Max distance

        for _, prop in pairs(spawnedProps) do
            if DoesEntityExist(prop) then
                local propCoords = GetEntityCoords(prop)
                local distance = #(playerCoords - propCoords)

                -- Check distance and visibility (not behind wall)
                if distance <= closestDistance and IsEntityVisible(prop) then
                    closestProp = prop
                    closestDistance = distance
                end
            end
        end

        -- Handle outline
        if closestProp then
            -- Add outline if not already outlined
            if lastOutlinedProp ~= closestProp then
                -- Fade out outline from previous prop
                if lastOutlinedProp and DoesEntityExist(lastOutlinedProp) then
                    if not flashingProps[lastOutlinedProp] then
                        StartFadeOut(lastOutlinedProp)
                    end
                end

                -- Fade in outline to current prop
                local color = flashingProps[closestProp]
                    and {r = 255, g = 0, b = 0}
                    or {r = 255, g = 255, b = 255}

                StartFadeIn(closestProp, color)
                lastOutlinedProp = closestProp
            else
                -- Already outlined - update color if flash status changed
                if flashingProps[closestProp] then
                    UpdateFadeColor(closestProp, {r = 255, g = 0, b = 0})
                end
            end
        else
            -- Not looking at anything - fade out outline
            if lastOutlinedProp and DoesEntityExist(lastOutlinedProp) then
                if not flashingProps[lastOutlinedProp] then
                    StartFadeOut(lastOutlinedProp)
                    lastOutlinedProp = nil
                end
            end
        end

        -- Handle TextUI3D (synchronized with outline)
        if closestProp then
            -- Add TextUI3D if not already added
            if lastTextUIProp ~= closestProp then
                -- Remove TextUI3D from previous prop
                if lastTextUIProp and DoesEntityExist(lastTextUIProp) then
                    TextUI3D.Remove(lastTextUIProp)
                end

                -- Add TextUI3D to current prop
                local containerType = Entity(closestProp).state.containerType
                local containerId = Entity(closestProp).state.containerId
                local isDroppedItem = containerType == 'dropped_item'
                local promptText = isDroppedItem and "Loot" or "Search"

                TextUI3D.Add(closestProp, {
                    text = promptText,
                    key = "F",
                    distance = 3.5,
                    onPress = function()
                        if isDroppedItem then
                            -- Direct pickup for dropped items
                            print(string.format('^2[Loot]^0 Picking up item from container %d', containerId))

                            Animations.PlayWithProgress(
                                playerPed,
                                'pickupItem',
                                'Picking up...',
                                false,
                                function()
                                    TriggerServerEvent('loot:pickupItem', containerId)
                                end,
                                function()
                                    print('^3[Loot]^0 Pickup canceled')
                                end
                            )
                        else
                            -- Open container UI
                            print(string.format('^2[Loot]^0 Opening container %d', containerId))
                            TriggerServerEvent('loot:openContainer', containerId)
                        end
                    end
                })

                lastTextUIProp = closestProp
            end
        else
            -- Not looking at anything - remove TextUI3D
            if lastTextUIProp and DoesEntityExist(lastTextUIProp) then
                TextUI3D.Remove(lastTextUIProp)
                lastTextUIProp = nil
            end
        end
    end
end)

-- ============================================
-- EVENTS
-- ============================================

-- Sync all containers from server
RegisterNetEvent('loot:syncContainers', function(containers)
    print(string.format('^2[Loot]^0 Received %d containers from server', #containers))

    -- Create a set of container IDs from the sync
    local syncedContainerIds = {}
    for _, containerData in ipairs(containers) do
        syncedContainerIds[containerData.containerId] = true
    end

    -- Remove props that are no longer in the server's list
    for containerId, prop in pairs(spawnedProps) do
        if not syncedContainerIds[containerId] then
            Props.Remove(containerId)
        end
    end

    -- Add new containers (SpawnAll will skip already spawned ones)
    Props.SpawnAll(containers)
end)

-- Add single container
RegisterNetEvent('loot:addContainer', function(containerData)
    Props.Spawn(containerData)
end)

-- Remove single container
RegisterNetEvent('loot:removeContainer', function(containerId)
    Props.Remove(containerId)
end)

-- Flash red on pickup failed (no space)
RegisterNetEvent('loot:pickupFailed', function(containerId, reason)
    print(string.format('^3[Loot]^0 Pickup failed for container %d: %s', containerId, reason))
    Props.FlashRed(containerId)
end)

-- ============================================
-- RESOURCE START - Request sync from server
-- ============================================

CreateThread(function()
    -- Wait a bit for server to load containers
    Wait(2000)

    -- Request all containers from server
    print('^2[Loot]^0 Requesting loot containers from server...')
    TriggerServerEvent('loot:requestSync')
end)

-- ============================================
-- CLEANUP
-- ============================================

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    print('^2[Loot]^0 Cleaning up all props...')
    Props.RemoveAll()
end)

print('^2[Loot]^0 Props manager loaded')

return Props
