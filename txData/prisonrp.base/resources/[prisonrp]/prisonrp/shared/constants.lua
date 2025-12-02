-- ========================================
-- THE LAST COLONY - CONSTANTS
-- ========================================

Constants = {}

-- ========================================
-- ITEM TYPES
-- ========================================

Constants.ItemTypes = {
    WEAPON = "weapon",
    MAGAZINE = "magazine",
    AMMO = "ammo",
    ARMOR = "armor",
    RIG = "rig",
    BACKPACK = "backpack",
    MEDICAL = "medical",
    CONSUMABLE = "consumable",
    MATERIAL = "material",
    KEY = "key",
    TOOL = "tool",
    MISC = "misc"
}

-- ========================================
-- WEAPON CATEGORIES
-- ========================================

Constants.WeaponCategories = {
    PRIMARY = "primary",
    SECONDARY = "secondary",
    PISTOL = "pistol",
    MELEE = "melee"
}

-- ========================================
-- ARMOR CATEGORIES
-- ========================================

Constants.ArmorCategories = {
    HELMET = "helmet",
    ARMOR = "armor",
    GASMASK = "gasmask"
}

-- ========================================
-- RARITIES
-- ========================================

Constants.Rarities = {
    STARTER = "starter",
    COMMON = "common",
    UNCOMMON = "uncommon",
    RARE = "rare",
    EPIC = "epic",
    LEGENDARY = "legendary",
    MYTHIC = "mythic"
}

Constants.RarityColors = {
    starter = "#6b7280",
    common = "#9ca3af",
    uncommon = "#10b981",
    rare = "#3b82f6",
    epic = "#a855f7",
    legendary = "#f59e0b",
    mythic = "#ef4444"
}

-- ========================================
-- BODY ZONES
-- ========================================

Constants.BodyZones = {
    HEAD = "head",
    TORSO = "torso",
    LEFT_ARM = "left_arm",
    RIGHT_ARM = "right_arm",
    LEFT_LEG = "left_leg",
    RIGHT_LEG = "right_leg"
}

-- ========================================
-- EFFECTS
-- ========================================

Constants.EffectTypes = {
    BLEEDING = "bleeding",
    FRACTURE = "fracture",
    PAIN = "pain",
    CONCUSSION = "concussion",
    DEAFNESS = "deafness"  -- From gunshots without ear protection
}

-- ========================================
-- SESSION STATUS
-- ========================================

Constants.SessionStatus = {
    ACTIVE = "active",
    EXTRACTED = "extracted",
    DIED = "died"
}

-- ========================================
-- EVENT TYPES (for combat logs)
-- ========================================

Constants.EventTypes = {
    MOVEMENT = "movement",
    KILL = "kill",
    DEATH = "death",
    DAMAGE_DEALT = "damage_dealt",
    DAMAGE_RECEIVED = "damage_received",
    LOOT = "loot",
    CONTAINER_OPEN = "container_open",
    MISSION_PROGRESS = "mission_progress"
}

-- ========================================
-- MISSION TYPES
-- ========================================

Constants.MissionTypes = {
    PVE = "pve",
    PVP = "pvp",
    COLLECTION = "collection",
    EXTRACTION = "extraction",
    EXPLORATION = "exploration"
}

Constants.MissionStatus = {
    ACTIVE = "active",
    COMPLETED = "completed",
    FAILED = "failed"
}

-- ========================================
-- SLOT TYPES
-- ========================================

Constants.SlotTypes = {
    GRID = "grid",       -- Main backpack grid
    POCKET = "pocket",   -- Pockets (5 slots, always accessible)
    RIG = "rig"          -- Rig slots (custom sizes)
}

-- ========================================
-- EQUIPMENT SLOTS
-- ========================================

Constants.EquipmentSlots = {
    HELMET = "helmet",
    ARMOR = "armor",
    RIG = "rig",
    BACKPACK = "backpack",
    PRIMARY_WEAPON = "primary_weapon",
    SECONDARY_WEAPON = "secondary_weapon",
    MELEE_WEAPON = "melee_weapon",
    PISTOL = "pistol",
    GASMASK = "gasmask"
}

-- ========================================
-- NUI EVENTS (Lua → React)
-- ========================================

Constants.NUIEvents = {
    -- Inventory
    OPEN_INVENTORY = "openInventory",
    CLOSE_INVENTORY = "closeInventory",
    UPDATE_INVENTORY = "updateInventory",
    UPDATE_EQUIPMENT = "updateEquipment",

    -- Loot
    OPEN_LOOT = "openLoot",
    CLOSE_LOOT = "closeLoot",
    UPDATE_LOOT_CONTAINER = "updateLootContainer",

    -- Storage
    OPEN_STORAGE = "openStorage",
    CLOSE_STORAGE = "closeStorage",
    UPDATE_STORAGE = "updateStorage",

    -- Market
    OPEN_MARKET = "openMarket",
    CLOSE_MARKET = "closeMarket",
    UPDATE_MARKETPLACE = "updateMarketplace",

    -- HUD
    UPDATE_HUD = "updateHUD",
    UPDATE_BODY_HEALTH = "updateBodyHealth",
    UPDATE_EFFECTS = "updateEffects",

    -- Death
    SHOW_DEATH_SCREEN = "showDeathScreen",
    SHOW_COMBAT_HISTORY = "showCombatHistory",

    -- DevTools
    SET_DEV_MODE = "setDevMode",
    LOAD_MOCK_DATA = "loadMockData"
}

-- ========================================
-- CALLBACK EVENTS (React → Lua)
-- ========================================

Constants.CallbackEvents = {
    -- Inventory
    MOVE_ITEM = "moveItem",
    ROTATE_ITEM = "rotateItem",
    DROP_ITEM = "dropItem",
    USE_ITEM = "useItem",
    SPLIT_STACK = "splitStack",

    -- Equipment
    EQUIP_ITEM = "equipItem",
    UNEQUIP_ITEM = "unequipItem",

    -- Loot
    TAKE_FROM_LOOT = "takeFromLoot",
    TAKE_ALL_LOOT = "takeAllLoot",
    SEARCH_CONTAINER = "searchContainer",

    -- Storage
    STORE_ITEM = "storeItem",
    RETRIEVE_ITEM = "retrieveItem",
    ORGANIZE_STORAGE = "organizeStorage",

    -- Market
    LIST_ITEM = "listItem",
    BUY_ITEM = "buyItem",
    CANCEL_LISTING = "cancelListing",
    SELL_TO_NPC = "sellToNPC",

    -- Crafting (future)
    CRAFT_ITEM = "craftItem",

    -- Ammo/Magazine management
    LOAD_AMMO_INTO_MAGAZINE = "loadAmmoIntoMagazine",
    UNLOAD_MAGAZINE = "unloadMagazine",
    LOAD_MAGAZINE_INTO_WEAPON = "loadMagazineIntoWeapon",

    -- Repair
    REPAIR_ITEM = "repairItem"
}

-- ========================================
-- KEYS
-- ========================================

Constants.Keys = {
    INVENTORY = "I",
    INTERACT = "F",
    RELOAD = "R",
    QUICK_USE = "V",
    DROP_ITEM = "X"
}

-- ========================================
-- COLORS (for UI)
-- ========================================

Constants.Colors = {
    Background = {
        Primary = "#0a0f1a",
        Secondary = "#121827",
        Tertiary = "#1a2234"
    },
    Text = {
        Primary = "#ffffff",
        Secondary = "#9ca3af",
        Disabled = "#4b5563"
    },
    Border = {
        Default = "#374151",
        Hover = "#4b5563",
        Active = "#6b7280"
    },
    Status = {
        Success = "#10b981",
        Warning = "#f59e0b",
        Error = "#ef4444",
        Info = "#3b82f6"
    }
}

return Constants
