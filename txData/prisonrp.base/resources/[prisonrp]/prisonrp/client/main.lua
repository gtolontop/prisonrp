--[[
    The Last Colony - Client Main
    Entry point for client-side logic
]]

local ox = lib -- ox_lib is already loaded
local Keybinds = require 'shared.keybinds'

print('^2[The Last Colony]^0 Client starting...')

-- ============================================
-- STATE VARIABLES
-- ============================================

local isInventoryOpen = false
local isInVehicle = false
local lastInventoryToggle = 0 -- Timestamp of last toggle (ms)

-- ============================================
-- KEYBINDS REGISTRATION
-- ============================================

-- Register all keybinds from centralized config
Keybinds.Register()

-- ============================================
-- KEYBIND HANDLERS
-- ============================================

-- Toggle inventory (TAB key - defined in shared/keybinds.lua)
RegisterCommand('inventory', function()
    -- Cooldown to prevent spam (200ms)
    local now = GetGameTimer()
    if now - lastInventoryToggle < 200 then
        return
    end
    lastInventoryToggle = now

    -- Don't allow opening inventory while dead
    if IsEntityDead(PlayerPedId()) then
        return
    end

    -- Don't allow opening inventory during progressbar
    if lib.progressActive() then
        lib.notify({
            type = 'error',
            description = 'Cannot open inventory during action'
        })
        return
    end

    -- Toggle inventory
    if isInventoryOpen then
        -- Close
        SetNuiFocus(false, false)
        SendNUIMessage({
            type = 'closeInventory'
        })
        isInventoryOpen = false
    else
        -- Request inventory data from server
        -- isInventoryOpen will be set to true when 'inventory:clientOpened' event fires
        TriggerServerEvent('inventory:requestOpen')
    end
end, false)

-- Alias command for opening inventory
RegisterCommand('openinv', function()
    ExecuteCommand('inventory')
end, false)

-- Listen for inventory actually opening
AddEventHandler('inventory:clientOpened', function()
    isInventoryOpen = true
end)

-- Listen for loot container opening (also counts as inventory open)
AddEventHandler('loot:clientOpened', function()
    isInventoryOpen = true
    print('^2[Loot]^0 Loot container opened')
end)

-- Listen for inventory closing (from drop, use item, etc.)
AddEventHandler('inventory:close', function()
    isInventoryOpen = false
    print('^2[Inventory]^0 Inventory state updated: closed')
end)

-- ============================================
-- VEHICLE CHECK THREAD (for future vehicle-specific logic)
-- ============================================

CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)

        if vehicle ~= 0 then
            isInVehicle = true
        else
            isInVehicle = false
        end

        Wait(500) -- Check every 500ms
    end
end)

-- ============================================
-- ENSURE PAUSE MENU (ESC) IS ALWAYS AVAILABLE
-- ============================================

CreateThread(function()
    while true do
        Wait(0) -- Every frame

        -- Only enable pause menu when UI is NOT open
        if not isInventoryOpen and not IsEntityDead(PlayerPedId()) then
            -- Force enable pause menu controls
            EnableControlAction(0, 200, true) -- Pause menu (ESC)
            EnableControlAction(0, 199, true) -- Pause menu alternative (P)
        end
    end
end)

-- ============================================
-- DEATH HANDLING
-- ============================================

CreateThread(function()
    while true do
        local ped = PlayerPedId()

        if IsEntityDead(ped) then
            -- Close inventory if opened while dying
            if isInventoryOpen then
                SetNuiFocus(false, false)
                SendNUIMessage({
                    type = 'closeInventory'
                })
                isInventoryOpen = false
            end
        end

        Wait(1000) -- Check every second
    end
end)

-- ============================================
-- PLAYER LOADED EVENT
-- ============================================

-- Listen for ox_core character load
AddEventHandler('ox:playerLoaded', function(player, isNew)
    print('^2[The Last Colony]^0 Character loaded (client-side)')

    if isNew then
        -- Show tutorial or welcome message
        lib.notify({
            title = 'Welcome to The Last Colony',
            description = 'Press I to open your inventory',
            type = 'info',
            duration = 10000
        })
    end
end)

-- ============================================
-- RESOURCE CLEANUP
-- ============================================

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    print('^2[The Last Colony]^0 Client stopping...')

    -- Close UI if open
    if isInventoryOpen then
        SetNuiFocus(false, false)
        SendNUIMessage({
            type = 'closeInventory'
        })
    end
end)

print('^2[The Last Colony]^0 Client main loaded successfully')
