--[[
    The Last Colony - Keybinds Configuration
    Centralized keybind definitions for the entire gamemode

    ALL keybinds are defined here for easy management
]]

local Keybinds = {}

-- ============================================
-- INVENTORY & INTERACTION
-- ============================================

Keybinds.Inventory = {
    Open = {
        command = 'inventory',
        label = 'Toggle Inventory',
        mapper = 'keyboard',
        key = 'TAB',
        description = 'Open/close your inventory'
    }
}

Keybinds.Interaction = {
    Use = {
        command = 'interact',
        label = 'Interact',
        mapper = 'keyboard',
        key = 'E',
        description = 'Interact with objects, open doors, loot containers'
    },
    QuickUse = {
        command = 'quickuse',
        label = 'Quick Use Item',
        mapper = 'keyboard',
        key = 'V',
        description = 'Quick use medical item from pockets'
    }
}

-- ============================================
-- COMBAT
-- ============================================

Keybinds.Combat = {
    Reload = {
        command = 'reload',
        label = 'Reload Weapon',
        mapper = 'keyboard',
        key = 'R',
        description = 'Reload your weapon'
    },
    -- Melee = Native GTA V combat (R key / Left Click)
    ToggleFireMode = {
        command = 'togglefiremode',
        label = 'Toggle Fire Mode',
        mapper = 'keyboard',
        key = 'B',
        description = 'Switch between auto/semi-auto/burst'
    }
}

-- ============================================
-- MOVEMENT & STANCE
-- ============================================

Keybinds.Movement = {
    Sprint = {
        -- Default SHIFT, no need to register
        label = 'Sprint',
        key = 'LSHIFT',
        description = 'Sprint (hold)'
    },
    Crouch = {
        command = 'crouch',
        label = 'Crouch',
        mapper = 'keyboard',
        key = 'LCONTROL',
        description = 'Crouch/prone toggle'
    },
    Jump = {
        -- Default SPACE, no need to register
        label = 'Jump',
        key = 'SPACE',
        description = 'Jump / Climb'
    }
}

-- ============================================
-- VEHICLE
-- ============================================

Keybinds.Vehicle = {
    Enter = {
        command = 'entervehicle',
        label = 'Enter Vehicle',
        mapper = 'keyboard',
        key = 'F',
        description = 'Enter/exit vehicle'
    },
    Horn = {
        -- Default H or E (GTA native)
        label = 'Horn',
        key = 'H',
        description = 'Vehicle horn'
    },
    Lights = {
        command = 'togglelights',
        label = 'Toggle Lights',
        mapper = 'keyboard',
        key = 'L',
        description = 'Toggle vehicle lights'
    }
}

-- ============================================
-- COMMUNICATION
-- ============================================

Keybinds.Communication = {
    PushToTalk = {
        -- pma-voice default
        label = 'Push to Talk',
        key = 'N',
        description = 'Hold to talk (pma-voice)'
    },
    ChangeRange = {
        -- pma-voice default
        label = 'Change Voice Range',
        key = 'F11',
        description = 'Cycle voice range: whisper/normal/shout'
    },
    Chat = {
        -- Default T (chat resource)
        label = 'Open Chat',
        key = 'T',
        description = 'Open text chat'
    },
    Radio = {
        command = 'radio',
        label = 'Radio',
        mapper = 'keyboard',
        key = 'GRAVE', -- Touche ~ (à gauche du 1)
        description = 'Open radio menu'
    }
}

-- ============================================
-- UI & MENUS
-- ============================================

Keybinds.UI = {
    CloseUI = {
        -- Default ESC, handled by NUI
        label = 'Close UI',
        key = 'ESCAPE',
        description = 'Close any open UI'
    },
    Map = {
        -- Default M or P (pausemenu)
        label = 'Map',
        key = 'M',
        description = 'Open map'
    },
    ScoreboardSkills = {
        command = 'scoreboard',
        label = 'Scoreboard / Skills',
        mapper = 'keyboard',
        key = 'Z',
        description = 'Open scoreboard and skill tree'
    },
    ContextMenu = {
        -- Right-click in UI
        label = 'Context Menu',
        key = 'MOUSE_RIGHT',
        description = 'Right-click to open context menu'
    }
}

-- ============================================
-- EXTRACTION & OBJECTIVES
-- ============================================

Keybinds.Extraction = {
    CallHelicopter = {
        command = 'callheli',
        label = 'Call Extraction Helicopter',
        mapper = 'keyboard',
        key = 'G',
        description = 'Use beacon to call extraction helicopter'
    },
    RequestExtraction = {
        command = 'requestextraction',
        label = 'Request Extraction',
        mapper = 'keyboard',
        key = 'F',
        description = 'Request extraction at designated point'
    }
}

-- ============================================
-- EMOTES & GESTURES
-- ============================================

Keybinds.Emotes = {
    EmoteMenu = {
        command = 'emotes',
        label = 'Emote Menu',
        mapper = 'keyboard',
        key = 'F3',
        description = 'Open emote menu'
    },
    HandsUp = {
        command = 'handsup',
        label = 'Hands Up',
        mapper = 'keyboard',
        key = 'X',
        description = 'Put hands up / surrender'
    },
    Point = {
        command = 'point',
        label = 'Point',
        mapper = 'keyboard',
        key = 'B',
        description = 'Point at something'
    }
}

-- ============================================
-- ADMIN / DEBUG
-- ============================================

Keybinds.Admin = {
    Noclip = {
        command = 'noclip',
        label = 'Noclip (Admin)',
        mapper = 'keyboard',
        key = 'F2',
        description = 'Toggle noclip (admin only)'
    },
    AdminMenu = {
        command = 'adminmenu',
        label = 'Admin Menu',
        mapper = 'keyboard',
        key = 'F10',
        description = 'Open admin menu (admin only)'
    }
}

-- ============================================
-- UTILITY FUNCTIONS
-- ============================================

-- Get all keybinds as flat table for documentation
function Keybinds.GetAll()
    local allKeybinds = {}

    for category, binds in pairs(Keybinds) do
        if type(binds) == 'table' and category ~= 'GetAll' and category ~= 'Register' then
            for name, bind in pairs(binds) do
                table.insert(allKeybinds, {
                    category = category,
                    name = name,
                    command = bind.command,
                    label = bind.label,
                    key = bind.key,
                    description = bind.description
                })
            end
        end
    end

    return allKeybinds
end

-- Register all keybinds (client-side only)
function Keybinds.Register()
    local registered = 0

    for category, binds in pairs(Keybinds) do
        if type(binds) == 'table' and category ~= 'GetAll' and category ~= 'Register' then
            for name, bind in pairs(binds) do
                if bind.command and bind.mapper and bind.key then
                    RegisterKeyMapping(bind.command, bind.label, bind.mapper, bind.key)
                    registered = registered + 1
                end
            end
        end
    end

    print(string.format('^2[Keybinds]^0 Registered %d keybinds', registered))
    return registered
end

return Keybinds
