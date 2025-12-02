fx_version 'cerulean'
game 'gta5'

name 'thelastcolony'
author 'The Last Colony Team'
description 'Custom extraction shooter inventory & core systems'
version '0.1.0'

lua54 'yes'

-- ox_lib is required for UI components and utilities
shared_script '@ox_lib/init.lua'

-- Shared files (loaded by both client and server)
shared_scripts {
    'shared/config.lua',
    'shared/items.lua',
    'shared/loot_containers.lua', -- World loot containers config
    'shared/respawn_points.lua', -- Hospital/respawn locations
    'shared/constants.lua',
    'shared/utils.lua',
    'shared/keybinds.lua',
    'shared/animations.lua'
}

-- Client-side scripts
client_scripts {
    'client/main.lua',
    -- Core client modules (order matters - proximity FIRST)
    'client/modules/proximity.lua', -- Centralized proximity/distance system (ONE LOOP FOR ALL)
    'client/modules/textui3d.lua', -- 3D Text UI system (uses proximity)
    'client/modules/outline.lua', -- Outline system (uses proximity)
    -- Weapons module (MUST LOAD FIRST to disable GTA weapons)
    'client/modules/weapons/disabler.lua', -- Disable GTA weapon wheel and native weapons
    -- Player modules
    'client/modules/player/death.lua', -- Immersive death/ragdoll system
    -- Loot module
    'client/modules/loot/props.lua', -- Loot props manager
    -- Inventory module
    'client/modules/inventory/main.lua',
    -- NUI module (callbacks and events)
    'client/modules/nui/callbacks.lua',
    'client/modules/nui/events.lua',
    -- Other modules (wildcards)
    'client/modules/hud/*.lua',
    'client/modules/combat/*.lua',
    'client/modules/market/*.lua',
    'client/modules/storage/*.lua',
    'client/modules/death/*.lua'
}

-- Server-side scripts
server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/dev_commands.lua', -- Dev commands
    -- Inventory module (order matters for dependencies)
    'server/modules/inventory/db/queries.lua',
    'server/modules/inventory/validation.lua',
    'server/modules/inventory/manager.lua',
    'server/modules/inventory/equipment.lua', -- ⭐ NEW: Equipment management
    'server/modules/inventory/events.lua',
    -- Loot module
    'server/modules/loot/containers.lua',
    'server/modules/loot/manager.lua',
    'server/modules/loot/events.lua',
    'server/modules/loot/test_spawner.lua',
    -- Commands
    'server/commands/givepermanentitems.lua', -- Give permanent items command
    -- Other modules (wildcards)
    'server/modules/combat/*.lua',
    'server/modules/market/*.lua',
    'server/modules/storage/*.lua',
    'server/modules/death/*.lua',
    'server/modules/logging/*.lua',
    'server/modules/npc/*.lua'
}

-- UI files
ui_page 'web/dist/index.html'

files {
    'web/dist/**/*',
    'web/dist/index.html',
    'web/dist/assets/**/*'
}

-- Dependencies
dependencies {
    'ox_core',  -- Framework
    'ox_lib',   -- UI components
    'oxmysql',  -- Database
    'pma-voice' -- Voice (already installed, no custom voice needed)
}