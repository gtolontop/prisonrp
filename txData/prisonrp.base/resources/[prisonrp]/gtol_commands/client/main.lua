lib.locale()

local _registerCommand = RegisterCommand

---@param commandName string
---@param callback fun(source, args, raw)
---@param restricted boolean?
function RegisterCommand(commandName, callback, restricted)
	_registerCommand(commandName, function(_, args, raw)
        CreateThread(function()
            if not restricted or lib.callback.await('ox_lib:checkPlayerAce', 100, ('command.%s'):format(commandName)) then
                lib.notify({ type = 'success', description = locale('success') })
                return callback(args, raw)
            end

            lib.notify({ type = 'error', description = locale('no_permission') })
        end)
	end)
end

local function freezePlayer(state, vehicle)
    local playerId, ped = cache.playerId, cache.ped
    vehicle = vehicle and cache.vehicle

    SetPlayerInvincible(playerId, state)
    FreezeEntityPosition(ped, state)
    SetEntityCollision(ped, not state, true)

    if vehicle then
        if not state then
            SetVehicleOnGroundProperly(vehicle)
        end

        FreezeEntityPosition(vehicle, state)
        SetEntityCollision(vehicle, not state, true)
    end
end

RegisterNetEvent('gtol_commands:freeze', freezePlayer)

local function teleport(vehicle, x, y, z)
    if vehicle then
        return SetPedCoordsKeepVehicle(cache.ped, x, y, z)
    end

    SetEntityCoords(cache.ped, x, y, z, false, false, false, false)
end

local lastCoords

RegisterCommand('goback', function()
    if lastCoords then
        local currentCoords = GetEntityCoords(cache.ped)
        teleport(cache.vehicle, lastCoords.x, lastCoords.y, lastCoords.z)
        lastCoords = currentCoords
    end
end, true)

RegisterCommand('tpm', function()
	local marker = GetFirstBlipInfoId(8)

    if marker ~= 0 then
        local coords = GetBlipInfoIdCoord(marker)

        DoScreenFadeOut(100)
        Wait(100)

        local vehicle = cache.seat == -1 and cache.vehicle
        lastCoords = GetEntityCoords(cache.ped)

        freezePlayer(true, vehicle)

        local z = GetHeightmapBottomZForPosition(coords.x, coords.y)
        local inc = Config.TeleportIncrement + 0.0

        while z < 800.0 do
            local found, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, z, true)
            local int = GetInteriorAtCoords(coords.x, coords.y, z)

            if found or int ~= 0 then
                if int ~= 0 then
                    local _, _, z = GetInteriorPosition(int)
                    groundZ = z
                end

                teleport(vehicle, coords.x, coords.y, groundZ)
                break
            end

            teleport(vehicle, coords.x, coords.y, z)
            Wait(0)

            z += inc
        end

        SetGameplayCamRelativeHeading(0)
        Wait(500)
        freezePlayer(false, vehicle)
        DoScreenFadeIn(750)
    end
end, true)

local function stringToCoords(input)
    local arr, num = {}, 0

    for n in string.gmatch(input:gsub('vec.-%d?%(', ''), '(-?[%d.%d]+)') do
        num += 1
        arr[num] = tonumber(n)
    end

    return table.unpack(arr)
end

RegisterCommand('setcoords', function(_, raw)
    local x, y, z, w = stringToCoords(raw)

    if x then
        DoScreenFadeOut(100)
        Wait(100)

        local vehicle = cache.seat == -1 and cache.vehicle
        lastCoords = GetEntityCoords(cache.ped)

        teleport(vehicle, x, y, z)

        if w then
            SetEntityHeading(cache.ped, w)
        end

        SetGameplayCamRelativeHeading(0)
        DoScreenFadeIn(750)
    end
end, true)

RegisterCommand('coords', function(args)
    local coords = GetEntityCoords(cache.ped)
    local str = args[1] and 'vec4(%.3f, %.3f, %.3f, %.3f)' or 'vec3(%.3f, %.3f, %.3f)'
    str = str:format(coords.x, coords.y, coords.z, args[1] and GetEntityHeading(cache.ped) or nil)

    print(str)
    lib.setClipboard(str)
end, false)

SetTimeout(1000, function()
    TriggerEvent('chat:addSuggestion', '/coords', 'Saves current coordinates to the clipboard.', {
        { name = 'heading', help = 'Save your current heading.' },
    })
end)

local noClip = false

-- https://github.com/Deltanic/fivem-freecam/
-- https://github.com/tabarra/txAdmin/tree/master/scripts/menu/vendor/freecam
RegisterCommand('noclip', function()
    noClip = not noClip
    SetFreecamActive(noClip)
end, true)

-- Vehicle repair event
RegisterNetEvent('gtol_commands:client:repairVehicle', function(vehicleNetId)
    local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)

    if not DoesEntityExist(vehicle) then return end

    SetVehicleFixed(vehicle)
    SetVehicleDeformationFixed(vehicle)
    SetVehicleUndriveable(vehicle, false)
    SetVehicleEngineOn(vehicle, true, true, true)
    SetVehicleDirtLevel(vehicle, 0.0)
end)

-- Vehicle spawn event with addon support
RegisterNetEvent('gtol_commands:client:spawnVehicle', function(modelName, coords, heading)
    local modelHash = GetHashKey(modelName)

    -- Request model (works for both base and addon vehicles)
    RequestModel(modelHash)

    local timeout = 0
    while not HasModelLoaded(modelHash) and timeout < 10000 do
        Wait(100)
        timeout = timeout + 100
    end

    -- Check if model loaded successfully
    if not HasModelLoaded(modelHash) then
        lib.notify({
            type = 'error',
            title = 'Invalid Model',
            description = ('Model "%s" not found. Check if the vehicle is installed correctly.'):format(modelName),
            duration = 5000
        })
        return
    end

    -- Verify it's actually a vehicle
    if not IsModelAVehicle(modelHash) then
        SetModelAsNoLongerNeeded(modelHash)
        lib.notify({
            type = 'error',
            title = 'Invalid Model',
            description = ('"%s" is not a vehicle model.'):format(modelName),
            duration = 5000
        })
        return
    end

    -- Delete current vehicle if player is in one
    local currentVehicle = GetVehiclePedIsIn(cache.ped, false)
    if currentVehicle ~= 0 then
        SetEntityAsMissionEntity(currentVehicle, true, true)
        DeleteVehicle(currentVehicle)
    end

    -- Create the new vehicle
    local vehicle = CreateVehicle(modelHash, coords.x, coords.y, coords.z, heading, true, false)

    if not DoesEntityExist(vehicle) then
        SetModelAsNoLongerNeeded(modelHash)
        lib.notify({
            type = 'error',
            title = 'Spawn Failed',
            description = 'Failed to spawn vehicle. Try again.',
            duration = 5000
        })
        return
    end

    -- Wait for vehicle to be ready
    local timeout = 0
    while not DoesEntityExist(vehicle) and timeout < 3000 do
        Wait(50)
        timeout = timeout + 50
    end

    -- Set vehicle as no longer needed for cleanup
    SetVehicleHasBeenOwnedByPlayer(vehicle, true)
    SetEntityAsNoLongerNeeded(vehicle)
    SetModelAsNoLongerNeeded(modelHash)

    -- Set vehicle on ground properly before warping player
    SetVehicleOnGroundProperly(vehicle)

    -- Put player in vehicle (driver seat)
    TaskWarpPedIntoVehicle(cache.ped, vehicle, -1)

    -- Ensure player is properly seated
    Wait(100)
    SetPedIntoVehicle(cache.ped, vehicle, -1)

    -- Turn on engine automatically
    SetVehicleEngineOn(vehicle, true, true, false)

    -- Set vehicle fully modded (optional)
    SetVehicleModKit(vehicle, 0)
    SetVehicleMod(vehicle, 11, GetNumVehicleMods(vehicle, 11) - 1, false) -- Engine
    SetVehicleMod(vehicle, 12, GetNumVehicleMods(vehicle, 12) - 1, false) -- Brakes
    SetVehicleMod(vehicle, 13, GetNumVehicleMods(vehicle, 13) - 1, false) -- Transmission
    SetVehicleMod(vehicle, 15, GetNumVehicleMods(vehicle, 15) - 1, false) -- Suspension
    ToggleVehicleMod(vehicle, 18, true) -- Turbo

    lib.notify({
        type = 'success',
        title = 'Vehicle Spawned',
        description = ('Spawned %s'):format(modelName),
        duration = 3000
    })
end)
