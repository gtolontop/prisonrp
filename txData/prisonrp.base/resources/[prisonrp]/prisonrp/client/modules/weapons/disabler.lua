--[[
    Weapon System Disabler
    Completely disables GTA V native weapon system to force custom inventory weapons only
]]

print('^2[Weapons]^0 Disabler loaded')

-- ============================================
-- DISABLE WEAPON WHEEL COMPLETELY
-- ============================================

-- Disable weapon wheel on spawn
AddEventHandler('playerSpawned', function()
    local ped = PlayerPedId()
    SetPedConfigFlag(ped, 35, false) -- PED_FLAG_DISABLE_WEAPON_WHEEL
    print('^2[Weapons]^0 Weapon wheel disabled on spawn')
end)

-- Disable weapon wheel on resource start
CreateThread(function()
    Wait(1000)
    local ped = PlayerPedId()
    SetPedConfigFlag(ped, 35, false)
    print('^2[Weapons]^0 Weapon wheel disabled on resource start')
end)

-- ============================================
-- DISABLE WEAPON WHEEL & SCROLL SELECTION
-- ============================================

CreateThread(function()
    while true do
        -- Disable weapon wheel and scroll selection ONLY (allow shooting/aiming)
        DisableControlAction(0, 37, true)  -- Select weapon (TAB/weapon wheel)
        DisableControlAction(0, 157, true) -- Select next weapon (scroll down)
        DisableControlAction(0, 158, true) -- Select previous weapon (scroll up)
        DisableControlAction(0, 166, true) -- Radio wheel (hold Q on foot)

        Wait(0) -- Every frame
    end
end)

-- ============================================
-- BLOCK NATIVE WEAPON GIVE EVENTS
-- ============================================

-- Block any attempt to give weapons via natives (anti-cheat measure)
local blockedWeaponHashes = {
    -- Melee
    `weapon_unarmed`,
    `weapon_knife`,
    `weapon_nightstick`,
    `weapon_hammer`,
    `weapon_bat`,
    `weapon_golfclub`,
    `weapon_crowbar`,
    `weapon_bottle`,
    `weapon_dagger`,
    `weapon_hatchet`,
    `weapon_knuckle`,
    `weapon_machete`,
    `weapon_flashlight`,
    `weapon_switchblade`,
    `weapon_poolcue`,
    `weapon_wrench`,
    `weapon_battleaxe`,

    -- Handguns
    `weapon_pistol`,
    `weapon_pistol_mk2`,
    `weapon_combatpistol`,
    `weapon_appistol`,
    `weapon_pistol50`,
    `weapon_snspistol`,
    `weapon_heavypistol`,
    `weapon_vintagepistol`,
    `weapon_marksmanpistol`,
    `weapon_revolver`,
    `weapon_revolver_mk2`,
    `weapon_doubleaction`,
    `weapon_flaregun`,

    -- Submachine Guns
    `weapon_microsmg`,
    `weapon_smg`,
    `weapon_smg_mk2`,
    `weapon_assaultsmg`,
    `weapon_combatpdw`,
    `weapon_machinepistol`,
    `weapon_minismg`,

    -- Shotguns
    `weapon_pumpshotgun`,
    `weapon_pumpshotgun_mk2`,
    `weapon_sawnoffshotgun`,
    `weapon_assaultshotgun`,
    `weapon_bullpupshotgun`,
    `weapon_musket`,
    `weapon_heavyshotgun`,
    `weapon_dbshotgun`,
    `weapon_autoshotgun`,

    -- Assault Rifles
    `weapon_assaultrifle`,
    `weapon_assaultrifle_mk2`,
    `weapon_carbinerifle`,
    `weapon_carbinerifle_mk2`,
    `weapon_advancedrifle`,
    `weapon_specialcarbine`,
    `weapon_specialcarbine_mk2`,
    `weapon_bullpuprifle`,
    `weapon_bullpuprifle_mk2`,
    `weapon_compactrifle`,

    -- LMGs
    `weapon_mg`,
    `weapon_combatmg`,
    `weapon_combatmg_mk2`,
    `weapon_gusenberg`,

    -- Sniper Rifles
    `weapon_sniperrifle`,
    `weapon_heavysniper`,
    `weapon_heavysniper_mk2`,
    `weapon_marksmanrifle`,
    `weapon_marksmanrifle_mk2`,

    -- Heavy Weapons
    `weapon_rpg`,
    `weapon_grenadelauncher`,
    `weapon_grenadelauncher_smoke`,
    `weapon_minigun`,
    `weapon_firework`,
    `weapon_railgun`,
    `weapon_hominglauncher`,
    `weapon_compactlauncher`,
    `weapon_rayminigun`,

    -- Throwables
    `weapon_grenade`,
    `weapon_bzgas`,
    `weapon_molotov`,
    `weapon_stickybomb`,
    `weapon_proxmine`,
    `weapon_snowball`,
    `weapon_pipebomb`,
    `weapon_ball`,
    `weapon_smokegrenade`,
    `weapon_flare`,

    -- Misc
    `weapon_petrolcan`,
    `weapon_fireextinguisher`,
    `weapon_parachute`,
}

-- Monitor and remove any weapon that appears
CreateThread(function()
    while true do
        local ped = PlayerPedId()

        if not IsEntityDead(ped) then
            for _, weaponHash in ipairs(blockedWeaponHashes) do
                -- IMPORTANT: Skip weapon_unarmed to allow melee combat
                if weaponHash ~= `weapon_unarmed` then
                    if HasPedGotWeapon(ped, weaponHash, false) then
                        -- Found a weapon that shouldn't be here - remove it
                        RemoveWeaponFromPed(ped, weaponHash)
                        print(string.format('^3[Weapons]^0 Removed unauthorized weapon: %s', weaponHash))
                    end
                end
            end
        end

        Wait(500) -- Check every 500ms
    end
end)

-- ============================================
-- ANTI-CHEAT: BLOCK WEAPON GIVE EXPLOITS
-- ============================================

-- Listen for any weapon pickups (in case cheater tries to spawn weapon pickups)
AddEventHandler('gameEventTriggered', function(eventName, data)
    if eventName == 'CEventNetworkEntityDamage' then
        -- Block damage events from unauthorized weapons (future: verify weapon is from inventory)
        -- This is a placeholder for anti-cheat integration
    end
end)

-- ============================================
-- ENSURE UNARMED WEAPON IS ALWAYS AVAILABLE
-- ============================================

-- Give player unarmed weapon on spawn to enable melee combat
CreateThread(function()
    Wait(2000) -- Wait for player to fully spawn

    while true do
        local ped = PlayerPedId()

        if not IsEntityDead(ped) then
            -- Ensure player has unarmed weapon (for melee)
            if not HasPedGotWeapon(ped, `weapon_unarmed`, false) then
                GiveWeaponToPed(ped, `weapon_unarmed`, 0, false, true)
                print('^2[Weapons]^0 Gave player unarmed weapon for melee combat')
            end
        end

        Wait(5000) -- Check every 5 seconds
    end
end)

print('^2[Weapons]^0 Disabler initialized - All GTA weapons blocked (except unarmed)')
