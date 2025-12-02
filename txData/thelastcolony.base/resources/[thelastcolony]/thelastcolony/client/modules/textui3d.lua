--[[
    3D Text UI System (Client-side)
    Reusable system for displaying floating 3D prompts above entities/coords

    Features:
    - Raycast-based detection (look at entity to see prompt)
    - No ox_target dependency
    - Customizable text, key, distance
    - Auto cleanup
    - Multiple simultaneous prompts support

    Usage:
    local TextUI3D = exports.thelastcolony:GetTextUI3D()

    TextUI3D.Add(entity, {
        text = "Loot",
        key = "F",
        distance = 3.0,
        onPress = function()
            print("F pressed!")
        end
    })
]]

local TextUI3D = {}

-- Active prompts {entity = {text, key, distance, onPress, coords}}
local activePrompts = {}

-- Current prompt being looked at
local currentPrompt = nil
local currentEntity = nil

-- Config
local DEFAULT_DISTANCE = 3.0
local RAYCAST_DISTANCE = 5.0
local RAYCAST_RADIUS = 0.3 -- Sphere radius for swept sphere raycast (larger = easier to target)
local CHECK_INTERVAL = 100 -- Check raycast every 100ms (10 FPS)

-- ============================================
-- CORE FUNCTIONS
-- ============================================

--- Add a 3D text prompt to an entity
--- @param entity number Entity handle
--- @param options table {text, key, distance?, onPress}
--- @return boolean success
function TextUI3D.Add(entity, options)
    if not DoesEntityExist(entity) then
        print('^3[TextUI3D]^0 ERROR: Entity does not exist')
        return false
    end

    if not options.text or not options.key then
        print('^3[TextUI3D]^0 ERROR: text and key are required')
        return false
    end

    local distance = options.distance or DEFAULT_DISTANCE

    activePrompts[entity] = {
        text = options.text,
        key = options.key,
        distance = distance,
        onPress = options.onPress or function() end,
        coords = nil -- Will be updated in draw thread
    }

    -- NOTE: TextUI3D does NOT use Proximity system (uses its own raycast system)
    -- Only Outline uses Proximity for FOV-based culling

    print(string.format('^2[TextUI3D]^0 Added prompt to entity %d: [%s] %s',
        entity, options.key, options.text))

    return true
end

--- Add a 3D text prompt at specific coordinates (no entity)
--- @param coords vector3 World coordinates
--- @param options table {text, key, distance?, onPress}
--- @return string promptId Unique ID for this prompt
function TextUI3D.AddAtCoords(coords, options)
    if not coords or not options.text or not options.key then
        print('^3[TextUI3D]^0 ERROR: coords, text and key are required')
        return nil
    end

    -- Use coords as key (convert to string)
    local promptId = string.format("coord_%.2f_%.2f_%.2f", coords.x, coords.y, coords.z)

    activePrompts[promptId] = {
        text = options.text,
        key = options.key,
        distance = options.distance or DEFAULT_DISTANCE,
        onPress = options.onPress or function() end,
        coords = coords,
        isCoordBased = true
    }

    print(string.format('^2[TextUI3D]^0 Added prompt at coords: [%s] %s',
        options.key, options.text))

    return promptId
end

--- Remove a 3D text prompt
--- @param entityOrId number|string Entity handle or prompt ID
--- @return boolean success
function TextUI3D.Remove(entityOrId)
    if activePrompts[entityOrId] then
        activePrompts[entityOrId] = nil

        -- Clear current if it was this one
        if currentEntity == entityOrId then
            currentEntity = nil
            currentPrompt = nil
        end

        print(string.format('^2[TextUI3D]^0 Removed prompt: %s', tostring(entityOrId)))
        return true
    end

    return false
end

--- Remove all prompts (cleanup)
function TextUI3D.RemoveAll()
    local count = 0
    for _ in pairs(activePrompts) do
        count = count + 1
    end

    activePrompts = {}
    currentEntity = nil
    currentPrompt = nil

    print(string.format('^2[TextUI3D]^0 Removed %d prompts', count))
end

--- Check if entity has a prompt
--- @param entity number Entity handle
--- @return boolean
function TextUI3D.Has(entity)
    return activePrompts[entity] ~= nil
end

--- Get current prompt being looked at
--- @return table|nil {entity, text, key, distance, onPress}
function TextUI3D.GetCurrent()
    if currentEntity and currentPrompt then
        return {
            entity = currentEntity,
            text = currentPrompt.text,
            key = currentPrompt.key,
            distance = currentPrompt.distance,
            onPress = currentPrompt.onPress
        }
    end
    return nil
end

-- ============================================
-- RAYCAST SYSTEM
-- ============================================

--- Perform raycast from camera to world
--- @return number|nil entity Entity hit by raycast
--- @return vector3|nil coords Hit coordinates
--- @return vector3 camCoords Camera start position
--- @return vector3 endCoords Raycast end position
local function PerformCameraRaycast()
    local ped = PlayerPedId()
    local camCoords = GetGameplayCamCoord()
    local camRot = GetGameplayCamRot(2)

    -- Convert rotation to direction vector
    local rotX = math.rad(camRot.x)
    local rotZ = math.rad(camRot.z)
    local dirX = -math.sin(rotZ) * math.abs(math.cos(rotX))
    local dirY = math.cos(rotZ) * math.abs(math.cos(rotX))
    local dirZ = math.sin(rotX)

    -- End position (raycast distance ahead)
    local endCoords = vector3(
        camCoords.x + dirX * RAYCAST_DISTANCE,
        camCoords.y + dirY * RAYCAST_DISTANCE,
        camCoords.z + dirZ * RAYCAST_DISTANCE
    )

    -- Perform swept sphere raycast (larger hit detection radius)
    -- Using swept sphere instead of ray for easier targeting
    -- Flag 10 = objects + vehicles, we'll filter vehicles in code
    local rayHandle = StartShapeTestSweptSphere(
        camCoords.x, camCoords.y, camCoords.z,
        endCoords.x, endCoords.y, endCoords.z,
        RAYCAST_RADIUS, -- Sphere radius (0.3m = 30cm diameter for easier targeting)
        16, -- 16 = objects/props only (no vehicles, no peds, no world)
        ped,
        0
    )

    local retval, hit, hitCoords, surfaceNormal, hitEntity = GetShapeTestResult(rayHandle)

    if hit and hitEntity then
        -- Double-check entity type (should be object/prop)
        local entityType = GetEntityType(hitEntity)
        if entityType == 3 then -- 3 = Object/Prop
            return hitEntity, hitCoords, camCoords, endCoords
        end
    end

    return nil, nil, camCoords, endCoords
end

--- Check if player is looking at a prompt
local function UpdateCurrentPrompt()
    local ped = PlayerPedId()
    local pedCoords = GetEntityCoords(ped)

    -- Find the CLOSEST prompt within range (priority by distance)
    local closestEntity = nil
    local closestPrompt = nil
    local closestDistance = 999999.0

    -- Check all active entity-based prompts
    for promptEntity, prompt in pairs(activePrompts) do
        if not prompt.isCoordBased and DoesEntityExist(promptEntity) then
            local entityCoords = GetEntityCoords(promptEntity)
            local distance = #(pedCoords - entityCoords)

            -- Check if within max distance and closer than current closest
            if distance <= prompt.distance and distance < closestDistance then
                closestEntity = promptEntity
                closestPrompt = prompt
                closestDistance = distance
            end
        end
    end

    -- If we found a close prompt, use it (ignoring raycast - distance priority)
    if closestEntity and closestPrompt then
        currentEntity = closestEntity
        currentPrompt = closestPrompt
        currentPrompt.coords = GetEntityCoords(closestEntity)
        return
    end

    -- Check coord-based prompts (fallback)
    local hitEntity, hitCoords = PerformCameraRaycast()
    if hitCoords then
        for promptId, prompt in pairs(activePrompts) do
            if prompt.isCoordBased then
                local distance = #(pedCoords - prompt.coords)
                local hitDistance = #(hitCoords - prompt.coords)

                -- Check if we're looking at this coord and within distance
                if hitDistance < 1.0 and distance <= prompt.distance then
                    currentEntity = promptId
                    currentPrompt = prompt
                    return
                end
            end
        end
    end

    -- No valid prompt found - clear current prompt
    currentEntity = nil
    currentPrompt = nil
end

-- ============================================
-- DRAWING SYSTEM
-- ============================================

--- Draw 3D text at world coordinates (native DrawText)
--- @param coords vector3 World coordinates
--- @param text string Text to draw
local function Draw3DText(coords, text)
    -- Try different Z offsets to make sure text is visible
    local onScreen, screenX, screenY = World3dToScreen2d(coords.x, coords.y, coords.z + 1.0)

    if not onScreen then
        return
    end

    -- Set text properties (larger scale for visibility)
    SetTextScale(0.5, 0.5)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 255) -- Full white
    SetTextDropshadow(10, 0, 0, 0, 255) -- Strong shadow
    SetTextEdge(2, 0, 0, 0, 200) -- Strong edge
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    DrawText(screenX, screenY)
end

--- Draw the current prompt
local function DrawCurrentPrompt()
    if not currentPrompt or not currentPrompt.coords then
        return
    end

    -- Format: [KEY] Text
    local displayText = string.format("[%s] %s", currentPrompt.key, currentPrompt.text)

    Draw3DText(currentPrompt.coords, displayText)
end

-- ============================================
-- THREADS
-- ============================================

-- Raycast detection thread (check every 100ms)
CreateThread(function()
    while true do
        Wait(CHECK_INTERVAL)

        -- Only check if we have active prompts
        if next(activePrompts) ~= nil then
            UpdateCurrentPrompt()
        else
            currentEntity = nil
            currentPrompt = nil
        end
    end
end)

-- Drawing thread (every frame)
CreateThread(function()
    while true do
        Wait(0)

        -- Draw TextUI if prompt active
        if currentPrompt then
            DrawCurrentPrompt()
        end
    end
end)

-- Key press handler
CreateThread(function()
    while true do
        Wait(0)

        if currentPrompt then
            -- Map common keys (extend as needed)
            local keyMap = {
                E = 38,
                F = 23,
                G = 47,
                H = 74,
                X = 73,
                SPACE = 22,
                ENTER = 18
            }

            local keyCode = keyMap[currentPrompt.key]

            if keyCode then
                -- IMPORTANT: Disable GTA's "Enter Vehicle" control when F key prompt is active
                -- This prevents entering vehicles when trying to loot nearby
                if keyCode == 23 then -- F key
                    DisableControlAction(0, 23, true) -- INPUT_ENTER (F key)
                end

                -- Use IsDisabledControlJustPressed for disabled controls (F key)
                -- Use IsControlJustPressed for others
                local pressed = false
                if keyCode == 23 then
                    pressed = IsDisabledControlJustPressed(0, keyCode)
                else
                    pressed = IsControlJustPressed(0, keyCode)
                end

                if pressed then
                    -- Call the onPress callback
                    currentPrompt.onPress()
                end
            end
        else
            Wait(200) -- Sleep if no prompt active
        end
    end
end)

-- ============================================
-- CLEANUP
-- ============================================

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    print('^2[TextUI3D]^0 Cleaning up all prompts...')
    TextUI3D.RemoveAll()
end)

-- ============================================
-- EXPORTS
-- ============================================

exports('GetTextUI3D', function()
    return TextUI3D
end)

exports('AddTextUI3D', TextUI3D.Add)
exports('AddTextUI3DAtCoords', TextUI3D.AddAtCoords)
exports('RemoveTextUI3D', TextUI3D.Remove)
exports('RemoveAllTextUI3D', TextUI3D.RemoveAll)
exports('HasTextUI3D', TextUI3D.Has)
exports('GetCurrentTextUI3D', TextUI3D.GetCurrent)

print('^2[TextUI3D]^0 3D Text UI System loaded')

return TextUI3D
