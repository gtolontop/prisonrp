--[[
    Outline System (Client-side) - OPTIMIZED VERSION
    Reusable system for entity outlines/glow effects with distance/occlusion culling
    
    PERFORMANCE IMPROVEMENTS:
    - Reduced raycast frequency from 60 FPS to 10 FPS (100ms interval)
    - Reduced raycast points from 13 to 3 (center + 2 corners)
    - Result: ~96% less CPU usage (300 raycasts/sec vs 7800 for 10 items)
]]

local Outline = {}
local outlinedEntities = {}
local Proximity = require 'client.modules.proximity'

-- Config
local MAX_DISTANCE = 20.0
local CHECK_INTERVAL = 100 -- 10 FPS instead of 60 FPS

function Outline.Add(entity, color, shader)
    if not DoesEntityExist(entity) then
        return false
    end
    
    color = color or {r = 255, g = 255, b = 255, a = 255}
    shader = shader or 0
    
    outlinedEntities[entity] = {
        color = color,
        shader = shader,
        addedAt = GetGameTimer(),
        visible = false
    }
    
    print(string.format('^2[Outline]^0 Added outline to entity %d', entity))
    return true
end

function Outline.Remove(entity)
    if DoesEntityExist(entity) then
        SetEntityDrawOutline(entity, false)
    end
    outlinedEntities[entity] = nil
    return true
end

function Outline.UpdateColor(entity, color)
    if not outlinedEntities[entity] then
        return Outline.Add(entity, color)
    end
    
    outlinedEntities[entity].color = color
    if outlinedEntities[entity].visible then
        SetEntityDrawOutlineColor(color.r, color.g, color.b, color.a)
    end
    return true
end

function Outline.Has(entity)
    return outlinedEntities[entity] ~= nil
end

function Outline.RemoveAll()
    for entity, _ in pairs(outlinedEntities) do
        if DoesEntityExist(entity) then
            SetEntityDrawOutline(entity, false)
        end
    end
    outlinedEntities = {}
end

Outline.Colors = {
    White = {r = 255, g = 255, b = 255, a = 255},
    Green = {r = 34, g = 197, b = 94, a = 255},
    Red = {r = 239, g = 68, b = 68, a = 255},
    Yellow = {r = 234, g = 179, b = 8, a = 255},
    Blue = {r = 59, g = 130, b = 246, a = 255},
    Purple = {r = 168, g = 85, b = 247, a = 255},
    Orange = {r = 249, g = 115, b = 22, a = 255}
}

-- Optimized visibility check (3 points instead of 13)
local function IsEntityVisible(entity)
    if not DoesEntityExist(entity) then
        return false
    end
    
    local playerPed = PlayerPedId()
    local camCoords = GetGameplayCamCoord()
    local entityCoords = GetEntityCoords(entity)
    local min, max = GetModelDimensions(GetEntityModel(entity))
    
    -- Test only 3 points (77% fewer raycasts)
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
        
        if (not hit) or (hitEntity == entity) then
            return true
        end
    end
    
    return false
end

-- Optimized visibility thread (10 FPS instead of 60 FPS)
CreateThread(function()
    while true do
        Wait(CHECK_INTERVAL)
        
        if next(outlinedEntities) == nil then
            goto continue
        end
        
        local camCoords = GetGameplayCamCoord()
        
        for entity, data in pairs(outlinedEntities) do
            if DoesEntityExist(entity) then
                local entityCoords = GetEntityCoords(entity)
                local distance = #(camCoords - entityCoords)
                
                if distance <= MAX_DISTANCE and IsEntityVisible(entity) then
                    if not data.visible then
                        SetEntityDrawOutline(entity, true)
                        SetEntityDrawOutlineColor(data.color.r, data.color.g, data.color.b, data.color.a)
                        if data.shader ~= 0 then
                            SetEntityDrawOutlineShader(data.shader)
                        end
                        data.visible = true
                    end
                else
                    if data.visible then
                        SetEntityDrawOutline(entity, false)
                        data.visible = false
                    end
                end
            end
        end
        
        ::continue::
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    Outline.RemoveAll()
end)

exports('AddOutline', Outline.Add)
exports('RemoveOutline', Outline.Remove)
exports('UpdateOutlineColor', Outline.UpdateColor)
exports('HasOutline', Outline.Has)
exports('RemoveAllOutlines', Outline.RemoveAll)

print('^2[Outline]^0 OPTIMIZED version loaded (100ms, 3 points)')

return Outline
