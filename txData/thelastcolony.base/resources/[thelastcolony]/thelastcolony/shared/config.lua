-- ========================================
-- THE LAST COLONY - CONFIGURATION
-- ========================================

Config = {}

-- ========================================
-- INVENTORY SYSTEM
-- ========================================

Config.Inventory = {
    -- Base pockets (ONLY storage available without backpack/rig)
    Pockets = {
        Slots = 5,  -- 5 individual 1x1 slots
        SlotSize = {w = 1, h = 1}
    },

    -- Weight system
    Weight = {
        MaxBase = 100.0,  -- Max weight without penalties (kg)
        SlowdownStart = 80.0,  -- Start slowing down at 80% capacity
        SlowdownMax = 120.0,  -- Barely able to move at 120kg
        StaminaDrainMultiplier = 1.5  -- Stamina drains 1.5x faster when over limit
    },

    -- Drop items on ground
    DropDistance = 1.5,  -- Meters in front of player
    DropDespawnTime = 600,  -- 10 minutes (seconds)

    -- Search system (for corpses/containers)
    SearchTime = 0.5,  -- Seconds per item to reveal
    SearchRadius = 3.0,  -- Max distance to search

    -- Interaction
    InteractionRange = 3.0,  -- Max distance to loot/open

    -- Auto-organize categories priority
    OrganizeCategories = {
        "weapon",
        "magazine",
        "ammo",
        "medical",
        "armor",
        "backpack",
        "rig",
        "consumable",
        "material",
        "key",
        "misc"
    }
}

-- ========================================
-- EQUIPMENT SYSTEM
-- ========================================

Config.Equipment = {
    -- Slots available
    Slots = {
        "helmet",
        "armor",
        "rig",
        "backpack",
        "primary_weapon",
        "secondary_weapon",
        "melee_weapon",
        "pistol",
        "gasmask"
    },

    -- Durability
    DurabilityLossPerHit = 5,  -- Armor loses 5 durability per hit absorbed
    RepairCostMultiplier = 0.1,  -- Repair costs 10% of item value per durability point
    MaxDurabilityLossOnRepair = 2,  -- Max durability decreases by 2 each repair

    -- Rig armored compatibility
    ArmoredRigBlocksArmorSlot = true
}

-- ========================================
-- BODY HEALTH SYSTEM
-- ========================================

Config.BodyHealth = {
    Zones = {
        "head",
        "torso",
        "left_arm",
        "right_arm",
        "left_leg",
        "right_leg"
    },

    MaxHP = 100,  -- Per zone

    -- Damage multipliers by zone
    DamageMultipliers = {
        head = 2.5,
        torso = 1.0,
        left_arm = 0.7,
        right_arm = 0.7,
        left_leg = 0.8,
        right_leg = 0.8
    },

    -- Effects
    Effects = {
        Bleeding = {
            DamagePerTick = 2,  -- HP lost per tick
            TickInterval = 5000,  -- Milliseconds (5 seconds)
            MaxStacks = 3  -- Can bleed from multiple zones
        },
        Fracture = {
            AimShakeMultiplier = 3.0,  -- Arms
            SpeedReduction = 0.5,  -- Legs (50% speed)
            StaminaDrainMultiplier = 2.0
        },
        Pain = {
            ScreenEffects = true,
            VignetteIntensity = 0.5,
            BreathingSound = true
        }
    },

    -- Death
    HeadshotInstantKill = {
        ["sniper_m24"] = true,  -- Sniper rifles always instant kill headshot
        -- Other weapons based on damage
        MinDamage = 80  -- Weapons dealing 80+ damage instant kill on headshot
    }
}

-- ========================================
-- COMBAT SYSTEM
-- ========================================

Config.Combat = {
    -- Hit detection
    BoneGroups = {
        head = {31086, 39317, 65068},  -- Head bones
        torso = {24816, 24817, 24818, 11816},  -- Chest, spine
        left_arm = {61163, 18905, 36864, 60309},
        right_arm = {28252, 57005, 58866, 64729},
        left_leg = {65245, 45454, 43312, 14201},
        right_leg = {58271, 36864, 51826, 52301}
    },

    -- Weapon degradation
    WeaponDurabilityLossPerShot = 0.05,  -- 0.05% per shot
    WeaponJamChance = {
        [100] = 0,     -- 100% durability = 0% jam
        [50] = 0.05,   -- 50% durability = 5% jam
        [25] = 0.15,   -- 25% durability = 15% jam
        [10] = 0.40    -- 10% durability = 40% jam
    },

    -- Armor penetration calculation
    ArmorPenetrationFormula = function(bulletPenetration, armorValue)
        local effectiveArmor = armorValue * (1 - (bulletPenetration / 100))
        return math.max(0, effectiveArmor)
    end
}

-- ========================================
-- LOOT SYSTEM
-- ========================================

Config.Loot = {
    -- Containers
    ContainerRespawnDelay = 300,  -- Seconds (5 minutes)
    ContainerDespawnIfNearby = 100,  -- Don't respawn if player within 100m

    -- Corpses
    CorpseDespawnTime = 600,  -- 10 minutes
    EMSResponseTime = 30,  -- EMS arrive 30 seconds after death
    EMSDropAnimation = true,

    -- Multi-loot
    AllowSimultaneousLoot = true,  -- Multiple players can loot same container

    -- Loot tables (basic examples, will be expanded)
    LootTables = {
        medical = {
            {item = "bandage", weight = 40, min = 1, max = 3},
            {item = "medkit", weight = 25, min = 1, max = 1},
            {item = "painkiller", weight = 30, min = 1, max = 5},
            {item = "morphine", weight = 5, min = 1, max = 1}
        },
        weapons = {
            {item = "ak47", weight = 15, min = 1, max = 1},
            {item = "m4a1", weight = 10, min = 1, max = 1},
            {item = "pistol_glock", weight = 30, min = 1, max = 1},
            {item = "knife_combat", weight = 45, min = 1, max = 1}
        },
        ammo = {
            {item = "762x39_fmj", weight = 30, min = 20, max = 60},
            {item = "556x45_fmj", weight = 30, min = 20, max = 60},
            {item = "9mm_fmj", weight = 40, min = 20, max = 60}
        }
    }
}

-- ========================================
-- SESSIONS & COMBAT HISTORY
-- ========================================

Config.Sessions = {
    -- Movement tracking
    TrackMovementInterval = 5000,  -- Log position every 5 seconds (client-side buffer)
    SendMovementBatchInterval = 30000,  -- Send batch to server every 30 seconds

    -- Combat logs
    LogAllActions = true,
    LogTypes = {
        "movement",
        "kill",
        "death",
        "damage_dealt",
        "damage_received",
        "loot",
        "container_open",
        "mission_progress"
    },

    -- Cleanup
    DeleteLogsAfterDays = 30,  -- Delete combat logs older than 30 days
    ArchiveSessionsAfterDays = 90  -- Archive old sessions
}

-- ========================================
-- LEADERBOARDS
-- ========================================

Config.Leaderboards = {
    UpdateInterval = 300000,  -- Update every 5 minutes (milliseconds)

    Categories = {
        {id = "kills", name = "Total Kills", column = "total_kills"},
        {id = "extractions", name = "Successful Extractions", column = "total_extractions"},
        {id = "kd", name = "K/D Ratio", column = "kd_ratio"},
        {id = "survival", name = "Survival Rate", column = "survival_rate"},
        {id = "best_extraction", name = "Best Extraction Value", column = "best_extraction_value"},
        {id = "longest_survival", name = "Longest Survival Time", column = "longest_survival_time"},
        {id = "zombies", name = "Total Zombie Kills", column = "total_zombie_kills"},
        {id = "military_zombies", name = "Military Zombies", column = "total_military_zombie_kills"},
        {id = "bandits", name = "Bandits Killed", column = "total_bandit_kills"}
    },

    TopCount = 100  -- Show top 100 per category
}

-- ========================================
-- MARKETPLACE
-- ========================================

Config.Market = {
    -- Taxes
    TaxRate = 0.05,  -- 5% tax on all sales

    -- Listing
    MaxListingsPerPlayer = 10,
    ListingDuration = 86400,  -- 24 hours (seconds)

    -- NPC traders
    NPCBuyPriceMultiplier = 0.6,  -- NPCs buy at 60% of base price
    NPCSellPriceMultiplier = 1.3,  -- NPCs sell at 130% of base price

    -- NPC AI marketplace participation
    NPCMarketplaceEnabled = true,
    NPCBuyChance = 0.3,  -- 30% chance NPC will buy a listing
    NPCCheckInterval = 600000  -- NPCs check marketplace every 10 minutes
}

-- ========================================
-- STORAGE
-- ========================================

Config.Storage = {
    Personal = {
        BaseSlots = {w = 20, h = 15},  -- 300 slots
        UpgradeCost = 1000000,  -- 1 million per upgrade
        UpgradeSlots = {w = 5, h = 5},  -- +25 slots per upgrade
        MaxUpgrades = 4  -- Max 4 upgrades (400 total slots)
    },

    Guild = {
        BaseSlotsPerLevel = {
            [1] = {w = 20, h = 15},
            [2] = {w = 25, h = 15},
            [3] = {w = 25, h = 20},
            [4] = {w = 30, h = 20},
            [5] = {w = 30, h = 25}
        }
    }
}

-- ========================================
-- MISSIONS
-- ========================================

Config.Missions = {
    -- Daily reset
    DailyResetHour = 0,  -- Midnight UTC

    -- Rewards
    MoneyRewardMultiplier = 1.0,
    XPRewardMultiplier = 1.0,

    -- Cooldowns
    DefaultCooldownHours = 24
}

-- ========================================
-- WIPE SYSTEM
-- ========================================

Config.Wipe = {
    -- Wipe schedule (every 3-4 months)
    AutoWipeEnabled = false,  -- Manual wipes only

    -- What gets wiped
    WipeInventory = true,
    WipeEquipment = true,
    WipeStorage = true,
    WipeGuildStorage = true,
    WipeVehicles = true,
    WipeClothing = true,

    -- What DOESN'T get wiped
    KeepCosmetics = true,  -- Purchased cosmetics survive wipe
    KeepLeaderboardHistory = true,  -- Stats archived but not deleted
    KeepGuildMembership = true  -- Guilds stay intact
}

-- ========================================
-- ANTI-CHEAT
-- ========================================

Config.AntiCheat = {
    -- Distance checks
    MaxInteractionDistance = 5.0,  -- Anything beyond this is suspicious
    MaxTeleportDistance = 100.0,  -- Moving >100m instantly = flag

    -- Inventory checks
    ValidateAllInventoryActions = true,
    LogSuspiciousActions = true,

    -- Rate limiting
    MaxInventoryActionsPerSecond = 10,
    MaxLootActionsPerSecond = 5,

    -- Auto-ban thresholds
    AutoBanEnabled = false,  -- Require manual review
    FlagThreshold = 10,  -- 10 suspicious actions = flagged account

    -- Logging
    LogRetentionDays = 90
}

-- ========================================
-- UI SETTINGS
-- ========================================

Config.UI = {
    -- DevTools
    DevMode = true,  -- Enable dev sidebar in npm run dev

    -- Animations
    TransitionSpeed = 200,  -- Milliseconds

    -- Highlights (hover item shows compatible items)
    HighlightCompatibleItems = true,
    HighlightColor = {
        compatible = "rgba(34, 197, 94, 0.3)",  -- Green
        incompatible = "rgba(239, 68, 68, 0.3)"  -- Red
    },

    -- Grid
    GridCellSize = 50,  -- Pixels (will be responsive)
    GridGap = 2,

    -- Drag & drop
    SnapToGrid = true,
    ShowGhostWhileDragging = true,
    RotateKey = "R"
}

-- ========================================
-- SAFE ZONES
-- ========================================

Config.SafeZones = {
    -- Military bases (no PvP)
    {
        name = "Fort Zancudo",
        coords = vector3(-2047.26, 3132.13, 32.81),
        radius = 500.0,
        pvp = false,
        market = true,
        storage = true,
        clothing_vendor = true
    }
    -- Add more zones as needed
}

-- ========================================
-- EXTRACTION POINTS
-- ========================================

Config.Extractions = {
    -- On-foot extraction points
    Points = {
        {coords = vector3(-2000.0, 3100.0, 32.0), radius = 10.0, time = 30},
        -- Add more
    },

    -- Helicopter beacon extraction
    BeaconExtraction = {
        Enabled = true,
        BeaconCost = 5000,  -- Money
        HelicopterArrivalTime = 60,  -- Seconds
        ExtractionTime = 10  -- Time to board
    }
}

return Config
