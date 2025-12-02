--[[
    The Last Colony - Respawn Points Configuration
    Define hospital/respawn locations here
]]

Config = Config or {}

Config.RespawnPoints = {
    -- Los Santos hospitals
    {
        name = "Pillbox Hill Medical Center",
        coords = vector4(298.5, -584.5, 43.3, 70.0),
        type = "hospital"
    },
    {
        name = "Mount Zonah Medical Center",
        coords = vector4(-247.76, 6331.23, 32.43, 223.0),
        type = "hospital"
    },
    {
        name = "Sandy Shores Medical Center",
        coords = vector4(1839.6, 3672.93, 34.28, 210.0),
        type = "hospital"
    },
    {
        name = "Paleto Bay Medical Center",
        coords = vector4(-254.88, 6324.5, 32.58, 315.0),
        type = "hospital"
    },

    -- Military bases (extraction points - for later)
    {
        name = "Fort Zancudo Base",
        coords = vector4(-2360.0, 3249.0, 32.8, 240.0),
        type = "military"
    },
}

-- Get the closest respawn point to a position
function Config.GetClosestRespawnPoint(coords, pointType)
    local closestPoint = nil
    local closestDistance = math.huge

    for _, point in ipairs(Config.RespawnPoints) do
        -- Filter by type if specified (hospital, military, etc.)
        if not pointType or point.type == pointType then
            local distance = #(coords - vector3(point.coords.x, point.coords.y, point.coords.z))

            if distance < closestDistance then
                closestDistance = distance
                closestPoint = point
            end
        end
    end

    return closestPoint
end

return Config
