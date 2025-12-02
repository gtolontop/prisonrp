--[[
    Animation System
    Centralized animation definitions for reusability
    Usage: local Animations = require 'shared.animations'
           Animations.Play(playerPed, 'dropItem')
]]

local Animations = {}

-- ============================================
-- ANIMATION DEFINITIONS
-- ============================================

Animations.List = {
    -- Inventory actions
    dropItem = {
        dict = 'mp_common',
        anim = 'givetake1_a',
        duration = 1000, -- ms (giving motion with right hand)
        flag = 48, -- Upper body only
        blendIn = 2.0,
        blendOut = 2.0,
        playbackRate = 1.0,
        lockX = false,
        lockY = false,
        lockZ = false
    },

    pickupItem = {
        dict = 'amb@world_human_gardener_plant@male@base',
        anim = 'base',
        duration = 1500,
        flag = 1
    },

    -- Medical items
    useBandage = {
        dict = 'amb@world_human_clipboard@male@idle_a',
        anim = 'idle_c',
        duration = 3000,
        flag = 49 -- Upper body only, cancelable
    },

    useMedkit = {
        dict = 'amb@world_human_clipboard@male@idle_a',
        anim = 'idle_c',
        duration = 5000,
        flag = 49
    },

    useInjector = {
        dict = 'mp_player_intdrink',
        anim = 'loop_bottle',
        duration = 2000,
        flag = 49
    },

    -- Consumables
    eatFood = {
        dict = 'mp_player_inteat@burger',
        anim = 'mp_player_int_eat_burger',
        duration = 3000,
        flag = 49
    },

    drinkWater = {
        dict = 'mp_player_intdrink',
        anim = 'loop_bottle',
        duration = 2000,
        flag = 49
    },

    -- Looting
    searchContainer = {
        dict = 'amb@prop_human_bum_bin@idle_b',
        anim = 'idle_d',
        duration = 4000,
        flag = 1 -- Repeat
    },

    searchBody = {
        dict = 'anim@gangops@facility@servers@bodysearch@',
        anim = 'player_search',
        duration = 5000,
        flag = 1
    },

    -- Weapons
    reloadWeapon = {
        dict = 'reaction@intimidation@1h',
        anim = 'outro',
        duration = 2000,
        flag = 48 -- Upper body
    },

    equipWeapon = {
        dict = 'reaction@intimidation@1h',
        anim = 'intro',
        duration = 800,
        flag = 48
    },

    -- Crafting
    craft = {
        dict = 'mini@repair',
        anim = 'fixing_a_ped',
        duration = 5000,
        flag = 1
    },

    -- Extraction
    callHelicopter = {
        dict = 'cellphone@',
        anim = 'cellphone_call_listen_base',
        duration = 3000,
        flag = 49
    },

    -- Interactions
    openDoor = {
        dict = 'anim@mp_player_intmenu@key_fob@',
        anim = 'fob_click',
        duration = 500,
        flag = 48
    },

    -- Emotes (bonus)
    surrender = {
        dict = 'random@arrests@busted',
        anim = 'idle_a',
        duration = -1, -- Loop until canceled
        flag = 49
    },

    sit = {
        dict = 'anim@heists@prison_heiststation@cop_reactions',
        anim = 'cop_b_idle',
        duration = -1,
        flag = 1
    },
}

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

--- Load animation dictionary (must be called before playing anim)
--- @param dict string Animation dictionary name
--- @return boolean success
function Animations.LoadDict(dict)
    if HasAnimDictLoaded(dict) then
        print(('[Animations] Dict "%s" already loaded'):format(dict))
        return true
    end

    print(('[Animations] Loading dict "%s"...'):format(dict))
    RequestAnimDict(dict)
    local timeout = 0
    while not HasAnimDictLoaded(dict) and timeout < 5000 do
        Wait(10)
        timeout = timeout + 10
    end

    local success = HasAnimDictLoaded(dict)
    if success then
        print(('[Animations] Dict "%s" loaded successfully'):format(dict))
    else
        print(('[Animations] ERROR: Failed to load dict "%s" after 5s'):format(dict))
    end

    return success
end

--- Play animation on ped
--- @param ped number Ped handle
--- @param animName string Animation name from Animations.List
--- @param options table|nil Optional overrides (duration, flag, etc.)
--- @return boolean success
function Animations.Play(ped, animName, options)
    local anim = Animations.List[animName]
    if not anim then
        print(('[Animations] ERROR: Animation "%s" not found'):format(animName))
        return false
    end

    -- Merge options
    local config = {}
    for k, v in pairs(anim) do
        config[k] = v
    end
    if options then
        for k, v in pairs(options) do
            config[k] = v
        end
    end

    -- Load dictionary
    if not Animations.LoadDict(config.dict) then
        print(('[Animations] ERROR: Failed to load dict "%s"'):format(config.dict))
        return false
    end

    print(('[Animations] Playing "%s" (dict: %s, anim: %s, duration: %d, flag: %d)'):format(
        animName, config.dict, config.anim, config.duration, config.flag))

    -- Play animation
    TaskPlayAnim(
        ped,
        config.dict,
        config.anim,
        config.blendIn or 1.0,
        config.blendOut or 1.0,
        config.duration or -1,
        config.flag or 0,
        config.playbackRate or 1.0,
        config.lockX or false,
        config.lockY or false,
        config.lockZ or false
    )

    print(('[Animations] Animation "%s" started successfully'):format(animName))
    return true
end

--- Stop animation on ped
--- @param ped number Ped handle
--- @param animName string Animation name from Animations.List
function Animations.Stop(ped, animName)
    local anim = Animations.List[animName]
    if not anim then
        return
    end

    StopAnimTask(ped, anim.dict, anim.anim, 1.0)
end

--- Stop all animations on ped
--- @param ped number Ped handle
function Animations.StopAll(ped)
    ClearPedTasks(ped)
end

--- Play animation with progress bar (client-side only)
--- @param ped number Ped handle
--- @param animName string Animation name
--- @param label string Progress bar label
--- @param canCancel boolean Can player cancel?
--- @param onComplete function Callback when complete
--- @param onCancel function Callback if canceled
function Animations.PlayWithProgress(ped, animName, label, canCancel, onComplete, onCancel)
    local anim = Animations.List[animName]
    if not anim then
        print(('[Animations] ERROR: Animation "%s" not found'):format(animName))
        return
    end

    -- Load animation dict
    if not Animations.LoadDict(anim.dict) then
        print(('[Animations] ERROR: Failed to load dict "%s"'):format(anim.dict))
        return
    end

    print(string.format('[Animations] Playing "%s" manually + progressBar (dict=%s, anim=%s, flag=%d)',
        animName, anim.dict, anim.anim, anim.flag or 1))

    -- Play animation MANUALLY with stronger flags to prevent cancellation
    TaskPlayAnim(
        ped,
        anim.dict,
        anim.anim,
        8.0,  -- Blend in speed (higher = faster start)
        -8.0, -- Blend out speed (negative = maintain until stopped)
        -1,   -- Duration (-1 = loop until stopped)
        49,   -- Flag 49 = upperbody only + not interruptible by movement
        0.0,  -- Playback rate
        false, false, false
    )

    -- Keep animation playing during progress bar
    CreateThread(function()
        local startTime = GetGameTimer()
        local duration = anim.duration
        while GetGameTimer() - startTime < duration do
            -- Force animation to continue if it stops
            if not IsEntityPlayingAnim(ped, anim.dict, anim.anim, 3) then
                TaskPlayAnim(ped, anim.dict, anim.anim, 8.0, -8.0, -1, 49, 0.0, false, false, false)
            end
            Wait(100)
        end
    end)

    -- Show progress bar WITHOUT animation parameter (we're playing it manually)
    local success = lib.progressBar({
        duration = anim.duration,
        label = label,
        useWhileDead = false,
        canCancel = canCancel,
        disable = {
            car = true,
            move = true,
            combat = true,
        },
    })

    -- Stop animation after progress bar
    StopAnimTask(ped, anim.dict, anim.anim, 1.0)

    print(string.format('[Animations] ProgressBar finished (success=%s)', tostring(success)))

    -- Callbacks
    if success and onComplete then
        onComplete()
    elseif not success and onCancel then
        onCancel()
    end
end

return Animations
