-- ========================================
-- THE LAST COLONY - ITEMS DATABASE
-- ========================================
-- NOTE: This is a MINIMAL set of test items
-- You will add 200-300+ items later with real models
-- ========================================

Items = {}

-- ========================================
-- COMPATIBILITY SYSTEM
-- ========================================
-- Weapons → Magazines → Ammo chain

local Calibers = {
    ["7.62x39"] = {
        name = "7.62x39mm",
        weapons = {"ak47", "sks"},
        magazines = {"ak_mag_30", "ak_mag_40", "ak_mag_75"},
        ammo = {"762x39_fmj", "762x39_ap", "762x39_hp"}
    },
    ["5.56x45"] = {
        name = "5.56x45mm NATO",
        weapons = {"m4a1", "m16", "scar_l"},
        magazines = {"stanag_30", "stanag_60", "stanag_100"},
        ammo = {"556x45_fmj", "556x45_ap", "556x45_tracer"}
    },
    ["9mm"] = {
        name = "9x19mm Parabellum",
        weapons = {"pistol_glock", "pistol_m9", "mp5"},
        magazines = {"pistol_mag_15", "pistol_mag_20", "mp5_mag_30"},
        ammo = {"9mm_fmj", "9mm_hp", "9mm_ap"}
    },
    ["7.62x51"] = {
        name = "7.62x51mm NATO",
        weapons = {"sniper_m24", "dmr_mk17"},
        magazines = {"m24_mag_5", "mk17_mag_20"},
        ammo = {"762x51_fmj", "762x51_ap", "762x51_match"}
    },
    ["12gauge"] = {
        name = "12 Gauge",
        weapons = {"shotgun_m870", "shotgun_aa12"},
        magazines = {"m870_tube_7", "aa12_mag_20"},
        ammo = {"12g_buckshot", "12g_slug", "12g_frag"}
    }
}

-- ========================================
-- WEAPONS
-- ========================================

Items["ak47"] = {
    name = "AK-47",
    description = "Iconic assault rifle chambered in 7.62x39mm. Reliable and powerful.",
    type = "weapon",
    category = "primary",
    equipSlot = "primary", -- ⭐ NEW: Equipment slot
    size = {w = 4, h = 2},
    weight = 3.5,
    stackable = false,
    durability = {current = 100, max = 100},
    rarity = "common",
    base_price = 15000,
    icon = "items/weapons/ak47.png",
    model_3d = "items/weapons/ak47.glb",
    world_prop = `w_ar_assaultrifle`, -- Native GTA V prop for ground
    caliber = "7.62x39",
    compatible_magazines = Calibers["7.62x39"].magazines,
    attachment_slots = {
        scope = true,
        muzzle = true,
        grip = true,
        laser = false,
        stock = false
    },
    metadata_template = {
        loaded_magazine = nil,  -- {item_id: "ak_mag_30", loaded_ammo: [...]}
        attachments = {
            scope = nil,
            muzzle = nil,
            grip = nil
        },
        durability = 100,
        kills = 0
    }
}

Items["m4a1"] = {
    name = "M4A1 Carbine",
    description = "Modern tactical rifle chambered in 5.56x45mm. Highly customizable.",
    type = "weapon",
    category = "primary",
    equipSlot = "primary", -- ⭐ NEW: Equipment slot
    size = {w = 4, h = 2},
    weight = 3.0,
    stackable = false,
    durability = {current = 100, max = 100},
    rarity = "uncommon",
    base_price = 22000,
    icon = "items/weapons/m4a1.png",
    model_3d = "items/weapons/m4a1.glb",
    caliber = "5.56x45",
    compatible_magazines = Calibers["5.56x45"].magazines,
    attachment_slots = {
        scope = true,
        muzzle = true,
        grip = true,
        laser = true,
        stock = true
    },
    metadata_template = {
        loaded_magazine = nil,
        attachments = {
            scope = nil,
            muzzle = nil,
            grip = nil,
            laser = nil,
            stock = nil
        },
        durability = 100,
        kills = 0
    }
}

Items["pistol_glock"] = {
    name = "Glock 17",
    description = "Reliable 9mm sidearm. Standard issue for many forces.",
    type = "weapon",
    category = "pistol",
    equipSlot = "holster", -- ⭐ NEW: Equipment slot
    size = {w = 2, h = 2},
    weight = 0.8,
    stackable = false,
    durability = {current = 100, max = 100},
    rarity = "common",
    base_price = 2500,
    icon = "items/weapons/glock.png",
    model_3d = "items/weapons/glock.glb",
    caliber = "9mm",
    compatible_magazines = {"pistol_mag_15", "pistol_mag_20"},
    attachment_slots = {
        muzzle = true,
        laser = true
    },
    metadata_template = {
        loaded_magazine = nil,
        attachments = {
            muzzle = nil,
            laser = nil
        },
        durability = 100,
        kills = 0
    }
}

Items["sniper_m24"] = {
    name = "M24 Sniper Rifle",
    description = "Bolt-action precision rifle chambered in 7.62x51mm.",
    type = "weapon",
    category = "primary",
    equipSlot = "primary", -- ⭐ NEW: Equipment slot
    size = {w = 5, h = 2},
    weight = 5.5,
    stackable = false,
    durability = {current = 100, max = 100},
    rarity = "rare",
    base_price = 45000,
    icon = "items/weapons/m24.png",
    model_3d = "items/weapons/m24.glb",
    caliber = "7.62x51",
    compatible_magazines = Calibers["7.62x51"].magazines,
    attachment_slots = {
        scope = true,
        muzzle = true,
        grip = true
    },
    metadata_template = {
        loaded_magazine = nil,
        attachments = {
            scope = nil,
            muzzle = nil,
            grip = nil
        },
        durability = 100,
        kills = 0
    }
}

Items["knife_combat"] = {
    name = "Combat Knife",
    description = "Standard issue combat blade.",
    type = "weapon",
    category = "melee",
    equipSlot = "sheath", -- ⭐ NEW: Equipment slot (permanent)
    size = {w = 1, h = 2},
    weight = 0.5,
    stackable = false,
    rarity = "starter",
    base_price = 500,
    icon = "items/weapons/knife.png",
    model_3d = "items/weapons/knife.glb",
    metadata_template = {
        kills = 0
    }
}

-- ========================================
-- MAGAZINES
-- ========================================

Items["ak_mag_30"] = {
    name = "AK 30-Round Magazine",
    description = "Standard 30-round magazine for 7.62x39mm rifles.",
    type = "magazine",
    size = {w = 1, h = 2},
    weight = 0.3,
    stackable = false,
    rarity = "common",
    base_price = 150,
    icon = "items/magazines/ak_mag_30.png",
    model_3d = "items/magazines/ak_mag_30.glb",
    caliber = "7.62x39",
    capacity = 30,
    compatible_weapons = {"ak47", "sks"},
    compatible_ammo = Calibers["7.62x39"].ammo,
    metadata_template = {
        loaded_ammo = {},  -- FIFO queue: [{type: "762x39_fmj", count: 20}, {type: "762x39_ap", count: 10}]
        current_count = 0
    }
}

Items["ak_mag_75"] = {
    name = "AK 75-Round Drum Magazine",
    description = "High-capacity drum magazine for extended firefights.",
    type = "magazine",
    size = {w = 2, h = 2},
    weight = 0.8,
    stackable = false,
    rarity = "uncommon",
    base_price = 600,
    icon = "items/magazines/ak_drum_75.png",
    model_3d = "items/magazines/ak_drum_75.glb",
    caliber = "7.62x39",
    capacity = 75,
    compatible_weapons = {"ak47"},
    compatible_ammo = Calibers["7.62x39"].ammo,
    metadata_template = {
        loaded_ammo = {},
        current_count = 0
    }
}

Items["stanag_30"] = {
    name = "STANAG 30-Round Magazine",
    description = "NATO standard 30-round magazine for 5.56mm rifles.",
    type = "magazine",
    size = {w = 1, h = 2},
    weight = 0.25,
    stackable = false,
    rarity = "common",
    base_price = 180,
    icon = "items/magazines/stanag_30.png",
    model_3d = "items/magazines/stanag_30.glb",
    caliber = "5.56x45",
    capacity = 30,
    compatible_weapons = Calibers["5.56x45"].weapons,
    compatible_ammo = Calibers["5.56x45"].ammo,
    metadata_template = {
        loaded_ammo = {},
        current_count = 0
    }
}

Items["pistol_mag_15"] = {
    name = "9mm 15-Round Pistol Magazine",
    description = "Standard 15-round magazine for 9mm pistols.",
    type = "magazine",
    size = {w = 1, h = 1},
    weight = 0.15,
    stackable = false,
    rarity = "common",
    base_price = 80,
    icon = "items/magazines/pistol_mag_15.png",
    model_3d = "items/magazines/pistol_mag_15.glb",
    caliber = "9mm",
    capacity = 15,
    compatible_weapons = {"pistol_glock", "pistol_m9"},
    compatible_ammo = Calibers["9mm"].ammo,
    metadata_template = {
        loaded_ammo = {},
        current_count = 0
    }
}

Items["m24_mag_5"] = {
    name = "M24 5-Round Magazine",
    description = "Bolt-action magazine for M24 sniper rifle.",
    type = "magazine",
    size = {w = 1, h = 1},
    weight = 0.2,
    stackable = false,
    rarity = "uncommon",
    base_price = 300,
    icon = "items/magazines/m24_mag_5.png",
    model_3d = "items/magazines/m24_mag_5.glb",
    caliber = "7.62x51",
    capacity = 5,
    compatible_weapons = {"sniper_m24"},
    compatible_ammo = Calibers["7.62x51"].ammo,
    metadata_template = {
        loaded_ammo = {},
        current_count = 0
    }
}

-- ========================================
-- AMMUNITION
-- ========================================

Items["762x39_fmj"] = {
    name = "7.62x39mm FMJ",
    description = "Full Metal Jacket rounds. Standard military ammunition.",
    type = "ammo",
    size = {w = 1, h = 1},
    weight = 0.01,
    stackable = true,
    max_stack = 60,
    rarity = "common",
    base_price = 5,
    icon = "items/ammo/762x39_fmj.png",
    model_3d = "items/ammo/762x39_box.glb",
    world_prop = `v_ret_gc_ammo1`,
    caliber = "7.62x39",
    damage = 45,
    penetration = 30,
    compatible_magazines = Calibers["7.62x39"].magazines
}

Items["762x39_ap"] = {
    name = "7.62x39mm AP",
    description = "Armor Piercing rounds. Enhanced penetration against armor.",
    type = "ammo",
    size = {w = 1, h = 1},
    weight = 0.012,
    stackable = true,
    max_stack = 60,
    rarity = "rare",
    base_price = 25,
    icon = "items/ammo/762x39_ap.png",
    model_3d = "items/ammo/762x39_box.glb",
    world_prop = `v_ret_gc_ammo1`,
    caliber = "7.62x39",
    damage = 40,
    penetration = 70,
    compatible_magazines = Calibers["7.62x39"].magazines
}

Items["556x45_fmj"] = {
    name = "5.56x45mm FMJ",
    description = "NATO standard full metal jacket ammunition.",
    type = "ammo",
    size = {w = 1, h = 1},
    weight = 0.009,
    stackable = true,
    max_stack = 60,
    rarity = "common",
    base_price = 6,
    icon = "items/ammo/556x45_fmj.png",
    model_3d = "items/ammo/556x45_box.glb",
    world_prop = `v_ret_gc_ammo1`,
    caliber = "5.56x45",
    damage = 38,
    penetration = 35,
    compatible_magazines = Calibers["5.56x45"].magazines
}

Items["556x45_ap"] = {
    name = "5.56x45mm AP",
    description = "Armor piercing 5.56mm rounds.",
    type = "ammo",
    size = {w = 1, h = 1},
    weight = 0.01,
    stackable = true,
    max_stack = 60,
    rarity = "rare",
    base_price = 22,
    icon = "items/ammo/556x45_ap.png",
    model_3d = "items/ammo/556x45_box.glb",
    world_prop = `v_ret_gc_ammo1`,
    caliber = "5.56x45",
    damage = 35,
    penetration = 65,
    compatible_magazines = Calibers["5.56x45"].magazines
}

Items["9mm_fmj"] = {
    name = "9mm FMJ",
    description = "Standard 9mm full metal jacket pistol ammunition.",
    type = "ammo",
    size = {w = 1, h = 1},
    weight = 0.008,
    stackable = true,
    max_stack = 60,
    rarity = "common",
    base_price = 3,
    icon = "items/ammo/9mm_fmj.png",
    model_3d = "items/ammo/9mm_box.glb",
    world_prop = `v_ret_gc_ammo1`,
    caliber = "9mm",
    damage = 25,
    penetration = 15,
    compatible_magazines = {"pistol_mag_15", "pistol_mag_20", "mp5_mag_30"}
}

Items["762x51_match"] = {
    name = "7.62x51mm Match Grade",
    description = "High-precision sniper ammunition.",
    type = "ammo",
    size = {w = 1, h = 1},
    weight = 0.015,
    stackable = true,
    max_stack = 40,
    rarity = "epic",
    base_price = 50,
    icon = "items/ammo/762x51_match.png",
    model_3d = "items/ammo/762x51_box.glb",
    world_prop = `v_ret_gc_ammo1`,
    caliber = "7.62x51",
    damage = 85,
    penetration = 60,
    accuracy_bonus = 15,
    compatible_magazines = Calibers["7.62x51"].magazines
}

-- ========================================
-- ARMOR & HELMETS
-- ========================================

Items["helmet_tactical"] = {
    name = "Tactical Helmet",
    description = "Standard ballistic helmet. Provides head protection without blocking accessories.",
    type = "helmet",
    category = "helmet",
    equipSlot = "headgear", -- ⭐ NEW: Equipment slot
    size = {w = 2, h = 2},
    weight = 1.2,
    stackable = false,
    durability = {current = 100, max = 100},
    rarity = "uncommon",
    base_price = 5000,
    icon = "items/armor/helmet_tactical.png",
    model_3d = "items/armor/helmet_tactical.glb",
    armor_value = 50,
    blocks = {},
    allows = {"goggles", "gasmask"},
    protection_zones = {"head"},
    metadata_template = {
        durability = 100,
        max_durability = 100,
        hits_taken = 0
    }
}

Items["helmet_full_visor"] = {
    name = "Full Face Ballistic Helmet",
    description = "Heavy helmet with integrated face shield. Blocks gas masks and goggles.",
    type = "helmet",
    category = "helmet",
    equipSlot = "headgear", -- ⭐ NEW: Equipment slot
    size = {w = 2, h = 2},
    weight = 1.8,
    stackable = false,
    durability = {current = 100, max = 100},
    rarity = "rare",
    base_price = 12000,
    icon = "items/armor/helmet_full.png",
    model_3d = "items/armor/helmet_full.glb",
    armor_value = 80,
    blocks = {"gasmask", "goggles"},
    allows = {},
    protection_zones = {"head"},
    metadata_template = {
        durability = 100,
        max_durability = 100,
        hits_taken = 0
    }
}

Items["armor_vest_light"] = {
    name = "Light Ballistic Vest",
    description = "Basic protection for torso. Level II armor.",
    type = "armor",
    category = "armor",
    equipSlot = "armor", -- ⭐ NEW: Equipment slot
    size = {w = 3, h = 3},
    weight = 4.0,
    stackable = false,
    durability = {current = 100, max = 100},
    rarity = "common",
    base_price = 8000,
    icon = "items/armor/vest_light.png",
    model_3d = "items/armor/vest_light.glb",
    armor_value = 40,
    protection_zones = {"torso"},
    metadata_template = {
        durability = 100,
        max_durability = 100,
        hits_taken = 0
    }
}

Items["armor_vest_heavy"] = {
    name = "Heavy Ballistic Vest",
    description = "Advanced protection for torso. Level IV armor.",
    type = "armor",
    category = "armor",
    equipSlot = "armor", -- ⭐ NEW: Equipment slot
    size = {w = 3, h = 4},
    weight = 8.5,
    stackable = false,
    durability = {current = 100, max = 100},
    rarity = "epic",
    base_price = 25000,
    icon = "items/armor/vest_heavy.png",
    model_3d = "items/armor/vest_heavy.glb",
    armor_value = 90,
    protection_zones = {"torso"},
    metadata_template = {
        durability = 100,
        max_durability = 100,
        hits_taken = 0
    }
}

Items["gasmask"] = {
    name = "Gas Mask",
    description = "Protects against toxic gases and biological hazards.",
    type = "armor",
    category = "gasmask",
    equipSlot = "face_cover", -- ⭐ NEW: Equipment slot
    size = {w = 2, h = 2},
    weight = 0.8,
    stackable = false,
    rarity = "uncommon",
    base_price = 3000,
    icon = "items/armor/gasmask.png",
    model_3d = "items/armor/gasmask.glb",
    requires_free = {"facemask"},
    blocks = {"helmet_full_visor"},
    metadata_template = {
        filter_durability = 100
    }
}

-- ========================================
-- RIGS (Tactical Vests with Storage)
-- ========================================

Items["rig_tactical"] = {
    name = "Tactical Chest Rig",
    description = "Lightweight chest rig with magazine pouches. No armor.",
    type = "rig",
    equipSlot = "rig", -- ⭐ NEW: Equipment slot
    size = {w = 3, h = 2},
    weight = 1.5,
    stackable = false,
    rarity = "uncommon",
    base_price = 3000,
    icon = "items/rigs/rig_tactical.png",
    model_3d = "items/rigs/rig_tactical.glb",
    has_armor = false,  -- Can wear separate armor
    storage_slots = {w = 4, h = 2},  -- Grid storage like backpack (4x2 = 8 slots)
    metadata_template = {
        items = {}  -- Items in rig slots
    }
}

Items["rig_military_armored"] = {
    name = "Military Armored Rig",
    description = "Heavy tactical rig with integrated Level III armor. Blocks armor slot.",
    type = "rig",
    equipSlot = "rig", -- ⭐ NEW: Equipment slot
    fillsBodyArmor = true, -- ⭐ NEW: This rig blocks the body armor slot
    size = {w = 3, h = 3},
    weight = 6.0,
    stackable = false,
    rarity = "rare",
    base_price = 18000,
    icon = "items/rigs/rig_military.png",
    model_3d = "items/rigs/rig_military.glb",
    has_armor = true,  -- BLOCKS separate armor slot
    armor_value = 65,
    protection_zones = {"torso"},
    rig_slots = {
        -- 6 magazine pouches + 1 large utility (2x3)
        {type = "fixed", w = 1, h = 2, index = 0},
        {type = "fixed", w = 1, h = 2, index = 1},
        {type = "fixed", w = 1, h = 2, index = 2},
        {type = "fixed", w = 1, h = 2, index = 3},
        {type = "fixed", w = 1, h = 2, index = 4},
        {type = "fixed", w = 1, h = 2, index = 5},
        {type = "fixed", w = 2, h = 3, index = 6}
    },
    metadata_template = {
        items = {},
        durability = 100,
        max_durability = 100
    }
}

-- ========================================
-- BACKPACKS
-- ========================================

Items["backpack_small"] = {
    name = "Small Backpack",
    description = "Compact backpack. Can be rolled up when empty.",
    type = "backpack",
    equipSlot = "backpack", -- ⭐ NEW: Equipment slot
    size = {w = 3, h = 3},  -- When NOT equipped
    weight = 0.8,
    stackable = false,
    rarity = "common",
    base_price = 1500,
    icon = "items/backpacks/backpack_small.png",
    model_3d = "items/backpacks/backpack_small.glb",
    storage_slots = {w = 6, h = 4},  -- Adds 24 slots when equipped
    can_rollup = true,
    size_rolled = {w = 2, h = 2},  -- Size when rolled up
    metadata_template = {
        rolled_up = false,
        items = {}
    }
}

Items["backpack_military"] = {
    name = "Military Rucksack",
    description = "Large military-grade backpack. High capacity.",
    type = "backpack",
    equipSlot = "backpack", -- ⭐ NEW: Equipment slot
    size = {w = 4, h = 4},
    weight = 1.5,
    stackable = false,
    rarity = "uncommon",
    base_price = 4000,
    icon = "items/backpacks/backpack_military.png",
    model_3d = "items/backpacks/backpack_military.glb",
    storage_slots = {w = 8, h = 6},  -- Adds 48 slots
    can_rollup = true,
    size_rolled = {w = 3, h = 3},
    metadata_template = {
        rolled_up = false,
        items = {}
    }
}

-- ========================================
-- MEDICAL
-- ========================================

Items["bandage"] = {
    name = "Bandage",
    description = "Stops bleeding on a specific body zone.",
    type = "medical",
    size = {w = 1, h = 1},
    weight = 0.05,
    stackable = true,
    max_stack = 5,
    rarity = "common",
    base_price = 50,
    icon = "items/medical/bandage.png",
    model_3d = "items/medical/bandage.glb",
    world_prop = `prop_ld_health_pack`, -- Native GTA V health pack prop
    usable = true,
    use_time = 3.0,
    effects = {
        {type = "stop_bleeding", zone = "target"}
    }
}

Items["medkit"] = {
    name = "Medkit",
    description = "Restores HP to a body zone. Does not fix fractures. 3 uses.",
    type = "medical",
    size = {w = 2, h = 1},
    weight = 0.3,
    stackable = false,
    rarity = "uncommon",
    base_price = 500,
    icon = "items/medical/medkit.png",
    model_3d = "items/medical/medkit.glb",
    usable = true,
    use_time = 5.0,
    effects = {
        {type = "heal", amount = 50, zone = "target"}
    },
    metadata_template = {
        durability = 3,
        max_durability = 3
    }
}

Items["morphine"] = {
    name = "Morphine Syringe",
    description = "Temporarily removes pain effects (broken bones, aim shake).",
    type = "medical",
    size = {w = 1, h = 1},
    weight = 0.1,
    stackable = false,
    rarity = "rare",
    base_price = 800,
    icon = "items/medical/morphine.png",
    model_3d = "items/medical/morphine.glb",
    usable = true,
    use_time = 2.0,
    effects = {
        {type = "remove_malus", duration = 30}
    }
}

Items["medkit_advanced"] = {
    name = "Advanced Medkit",
    description = "Heals fractures and restores HP. Combat surgeon in a box.",
    type = "medical",
    size = {w = 2, h = 2},
    weight = 0.6,
    stackable = false,
    rarity = "epic",
    base_price = 2000,
    icon = "items/medical/medkit_advanced.png",
    model_3d = "items/medical/medkit_advanced.glb",
    usable = true,
    use_time = 8.0,
    effects = {
        {type = "heal", amount = 100, zone = "target"},
        {type = "fix_fracture", zone = "target"}
    }
}

Items["painkiller"] = {
    name = "Painkillers",
    description = "Pills that reduce pain effects for a short duration.",
    type = "medical",
    size = {w = 1, h = 1},
    weight = 0.05,
    stackable = true,
    max_stack = 10,
    rarity = "common",
    base_price = 150,
    icon = "items/medical/painkillers.png",
    model_3d = "items/medical/painkillers.glb",
    world_prop = `prop_cs_pills`,
    usable = true,
    use_time = 1.5,
    effects = {
        {type = "reduce_pain", amount = 30, duration = 60}
    }
}

Items["hemostatic_agent"] = {
    name = "Hemostatic Agent",
    description = "Liquid that stops severe bleeding instantly.",
    type = "medical",
    size = {w = 1, h = 1},
    weight = 0.1,
    stackable = false,
    rarity = "rare",
    base_price = 600,
    icon = "items/medical/hemostatic.png",
    model_3d = "items/medical/hemostatic.glb",
    usable = true,
    use_time = 2.5,
    effects = {
        {type = "stop_bleeding_instant", zone = "target"}
    }
}

-- Surgical Kits (multi-use medical items with durability)
Items["surgical_kit_basic"] = {
    name = "Basic Surgical Kit",
    description = "Basic surgical tools. 1 use.",
    type = "medical",
    size = {w = 2, h = 1},
    weight = 0.4,
    stackable = false,
    rarity = "uncommon",
    base_price = 800,
    icon = "items/medical/surgical_kit.png",
    model_3d = "items/medical/surgical_kit.glb",
    usable = true,
    use_time = 6.0,
    effects = {
        {type = "heal", amount = 60, zone = "target"},
        {type = "fix_fracture", zone = "target"}
    },
    metadata_template = {
        durability = 1,
        max_durability = 1
    }
}

Items["surgical_kit_advanced"] = {
    name = "Advanced Surgical Kit",
    description = "Advanced surgical tools. 2 uses.",
    type = "medical",
    size = {w = 2, h = 1},
    weight = 0.5,
    stackable = false,
    rarity = "rare",
    base_price = 1500,
    icon = "items/medical/surgical_kit.png",
    model_3d = "items/medical/surgical_kit.glb",
    usable = true,
    use_time = 6.0,
    effects = {
        {type = "heal", amount = 70, zone = "target"},
        {type = "fix_fracture", zone = "target"}
    },
    metadata_template = {
        durability = 2,
        max_durability = 2
    }
}

Items["surgical_kit_military"] = {
    name = "Military Surgical Kit",
    description = "Military-grade surgical tools. 4 uses.",
    type = "medical",
    size = {w = 2, h = 1},
    weight = 0.6,
    stackable = false,
    rarity = "epic",
    base_price = 3000,
    icon = "items/medical/surgical_kit.png",
    model_3d = "items/medical/surgical_kit.glb",
    usable = true,
    use_time = 5.0,
    effects = {
        {type = "heal", amount = 80, zone = "target"},
        {type = "fix_fracture", zone = "target"}
    },
    metadata_template = {
        durability = 4,
        max_durability = 4
    }
}

Items["surgical_kit_elite"] = {
    name = "Elite Surgical Kit",
    description = "Elite tactical surgical tools. 8 uses.",
    type = "medical",
    size = {w = 2, h = 2},
    weight = 0.8,
    stackable = false,
    rarity = "legendary",
    base_price = 6000,
    icon = "items/medical/surgical_kit.png",
    model_3d = "items/medical/surgical_kit.glb",
    usable = true,
    use_time = 5.0,
    effects = {
        {type = "heal", amount = 100, zone = "target"},
        {type = "fix_fracture", zone = "target"}
    },
    metadata_template = {
        durability = 8,
        max_durability = 8
    }
}

-- Health Syringes (instant heal with durability)
Items["health_syringe_basic"] = {
    name = "Basic Health Syringe",
    description = "Fast-acting healing syringe. 120 HP capacity.",
    type = "medical",
    size = {w = 1, h = 1},
    weight = 0.15,
    stackable = false,
    rarity = "uncommon",
    base_price = 400,
    icon = "items/medical/syringe.png",
    model_3d = "items/medical/syringe.glb",
    usable = true,
    use_time = 2.0,
    effects = {
        {type = "heal", amount = 30, zone = "target"}
    },
    metadata_template = {
        durability = 120,
        max_durability = 120,
        heal_per_use = 30
    }
}

Items["health_syringe_advanced"] = {
    name = "Advanced Health Syringe",
    description = "Advanced healing syringe. 400 HP capacity.",
    type = "medical",
    size = {w = 1, h = 1},
    weight = 0.2,
    stackable = false,
    rarity = "rare",
    base_price = 1200,
    icon = "items/medical/syringe.png",
    model_3d = "items/medical/syringe.glb",
    usable = true,
    use_time = 1.8,
    effects = {
        {type = "heal", amount = 40, zone = "target"}
    },
    metadata_template = {
        durability = 400,
        max_durability = 400,
        heal_per_use = 40
    }
}

Items["health_syringe_military"] = {
    name = "Military Health Syringe",
    description = "Military-grade healing syringe. 960 HP capacity.",
    type = "medical",
    size = {w = 1, h = 2},
    weight = 0.25,
    stackable = false,
    rarity = "epic",
    base_price = 2500,
    icon = "items/medical/syringe.png",
    model_3d = "items/medical/syringe.glb",
    usable = true,
    use_time = 1.5,
    effects = {
        {type = "heal", amount = 48, zone = "target"}
    },
    metadata_template = {
        durability = 960,
        max_durability = 960,
        heal_per_use = 48
    }
}

-- ========================================
-- FOOD & WATER
-- ========================================

Items["water_bottle"] = {
    name = "Water Bottle",
    description = "Clean drinking water. Restores hydration. Can drink progressively.",
    type = "consumable",
    size = {w = 1, h = 2},
    weight = 0.5,
    stackable = false,
    rarity = "common",
    base_price = 20,
    icon = "items/food/water.png",
    model_3d = "items/food/water.glb",
    usable = true,
    consumable = true,
    use_time = 2.0,
    effects = {
        {type = "hydration", amount = 10}
    },
    metadata_template = {
        durability = 100,
        max_durability = 100
    }
}

Items["canned_food"] = {
    name = "Canned Food",
    description = "Preserved food. Restores hunger.",
    type = "consumable",
    size = {w = 1, h = 1},
    weight = 0.4,
    stackable = true,
    max_stack = 5,
    rarity = "common",
    base_price = 30,
    icon = "items/food/canned.png",
    model_3d = "items/food/canned.glb",
    usable = true,
    consumable = true,
    use_time = 5.0,
    effects = {
        {type = "hunger", amount = 40}
    }
}

Items["energy_drink"] = {
    name = "Energy Drink",
    description = "Restores stamina and provides temporary boost.",
    type = "consumable",
    size = {w = 1, h = 1},
    weight = 0.3,
    stackable = true,
    max_stack = 5,
    rarity = "uncommon",
    base_price = 100,
    icon = "items/food/energy.png",
    model_3d = "items/food/energy.glb",
    usable = true,
    consumable = true,
    use_time = 1.5,
    effects = {
        {type = "stamina", amount = 100},
        {type = "stamina_regen_boost", duration = 120}
    }
}

Items["juice_bottle"] = {
    name = "Juice Bottle",
    description = "Fruit juice bottle. Can drink progressively.",
    type = "consumable",
    size = {w = 1, h = 2},
    weight = 0.5,
    stackable = false,
    rarity = "common",
    base_price = 40,
    icon = "items/food/juice.png",
    model_3d = "items/food/juice.glb",
    usable = true,
    consumable = true,
    use_time = 2.0,
    effects = {
        {type = "hydration", amount = 15},
        {type = "hunger", amount = 5}
    },
    metadata_template = {
        durability = 100,
        max_durability = 100
    }
}

Items["energy_drink_can"] = {
    name = "Energy Drink Can",
    description = "Canned energy drink. Instant consumption.",
    type = "consumable",
    size = {w = 1, h = 1},
    weight = 0.2,
    stackable = true,
    max_stack = 5,
    rarity = "common",
    base_price = 50,
    icon = "items/food/energy_can.png",
    model_3d = "items/food/energy_can.glb",
    usable = true,
    consumable = true,
    use_time = 1.0,
    effects = {
        {type = "hydration", amount = 25},
        {type = "stamina", amount = 50}
    }
}

Items["soda_can"] = {
    name = "Soda Can",
    description = "Canned soda. Instant consumption.",
    type = "consumable",
    size = {w = 1, h = 1},
    weight = 0.2,
    stackable = true,
    max_stack = 5,
    rarity = "common",
    base_price = 25,
    icon = "items/food/soda.png",
    model_3d = "items/food/soda.glb",
    usable = true,
    consumable = true,
    use_time = 1.0,
    effects = {
        {type = "hydration", amount = 25}
    }
}

Items["mre"] = {
    name = "MRE",
    description = "Meal Ready to Eat. Military ration.",
    type = "consumable",
    size = {w = 2, h = 1},
    weight = 0.6,
    stackable = true,
    max_stack = 3,
    rarity = "uncommon",
    base_price = 80,
    icon = "items/food/mre.png",
    model_3d = "items/food/mre.glb",
    usable = true,
    consumable = true,
    use_time = 8.0,
    effects = {
        {type = "hunger", amount = 60},
        {type = "hydration", amount = 20}
    }
}


-- ========================================
-- MATERIALS & CRAFTING
-- ========================================

Items["scrap_metal"] = {
    name = "Scrap Metal",
    description = "Salvaged metal parts. Used for crafting and repairs.",
    type = "material",
    size = {w = 1, h = 1},
    weight = 0.5,
    stackable = true,
    max_stack = 20,
    rarity = "common",
    base_price = 10,
    icon = "items/materials/scrap_metal.png",
    model_3d = "items/materials/scrap_metal.glb"
}

Items["gunpowder"] = {
    name = "Gunpowder",
    description = "Used for crafting ammunition.",
    type = "material",
    size = {w = 1, h = 1},
    weight = 0.3,
    stackable = true,
    max_stack = 50,
    rarity = "uncommon",
    base_price = 15,
    icon = "items/materials/gunpowder.png",
    model_3d = "items/materials/gunpowder.glb"
}

-- ========================================
-- KEYS & TECH
-- ========================================

Items["keycard_military"] = {
    name = "Military Keycard",
    description = "Grants access to restricted military zones.",
    type = "key",
    size = {w = 1, h = 1},
    weight = 0.01,
    stackable = false,
    rarity = "epic",
    base_price = 50000,
    icon = "items/keys/keycard_military.png",
    model_3d = "items/keys/keycard.glb",
    access_zones = {"military_bunker", "armory", "research_lab"}
}

-- ========================================
-- PERMANENT ITEMS (Cannot be dropped/sold)
-- ========================================

Items["compass"] = {
    name = "Compass",
    description = "Always equipped. Shows cardinal directions.",
    type = "tool",
    equipSlot = "compass", -- ⭐ NEW: Equipment slot (permanent)
    size = {w = 1, h = 1},
    weight = 0.1,
    stackable = false,
    rarity = "starter",
    base_price = 0,
    icon = "items/tools/compass.png",
    model_3d = "items/tools/compass.glb",
    permanent = true,
    cannot_drop = true,
    cannot_sell = true
}

Items["minimap"] = {
    name = "Mini-Map Device",
    description = "Always equipped. Displays tactical minimap.",
    type = "tool",
    equipSlot = "card", -- ⭐ NEW: Equipment slot (permanent, renommé en "card" pour carte)
    size = {w = 2, h = 1}, -- Card is 2x1
    weight = 0.1,
    stackable = false,
    rarity = "starter",
    base_price = 0,
    icon = "items/tools/minimap.png",
    model_3d = "items/tools/minimap.glb",
    permanent = true,
    cannot_drop = true,
    cannot_sell = true
}

Items["secure_case"] = {
    name = "Secure Case",
    description = "Permanent secure container (3x1). Cannot be removed. Contains your map and compass.",
    type = "container",
    equipSlot = "case", -- ⭐ Equipment slot (permanent)
    size = {w = 2, h = 2},
    weight = 0.5,
    stackable = false,
    rarity = "starter",
    base_price = 0,
    icon = "items/containers/secure_case.png",
    model_3d = "items/containers/secure_case.glb",
    permanent = true,
    cannot_drop = true,
    cannot_sell = true,
    storage_slots = {
        width = 3,
        height = 1
    }
}

Items["knife"] = {
    name = "Combat Knife",
    description = "Standard issue combat knife. Always equipped.",
    type = "melee",
    equipSlot = "sheath", -- ⭐ Equipment slot (permanent)
    size = {w = 1, h = 2},
    weight = 0.3,
    stackable = false,
    rarity = "starter",
    base_price = 0,
    icon = "items/weapons/knife.png",
    model_3d = "items/weapons/knife.glb",
    permanent = true,
    cannot_drop = true,
    cannot_sell = true,
    damage = 25,
    attack_speed = 1.5
}

-- ========================================
-- HELPER FUNCTIONS
-- ========================================

function GetItem(itemId)
    return Items[itemId]
end

function IsWeaponCompatibleWithMagazine(weaponId, magazineId)
    local weapon = Items[weaponId]
    local magazine = Items[magazineId]
    if not weapon or not magazine then return false end
    if weapon.type ~= "weapon" or magazine.type ~= "magazine" then return false end
    if weapon.caliber ~= magazine.caliber then return false end
    for _, compatMag in ipairs(weapon.compatible_magazines) do
        if compatMag == magazineId then return true end
    end
    return false
end

function IsMagazineCompatibleWithAmmo(magazineId, ammoId)
    local magazine = Items[magazineId]
    local ammo = Items[ammoId]
    if not magazine or not ammo then return false end
    if magazine.type ~= "magazine" or ammo.type ~= "ammo" then return false end
    if magazine.caliber ~= ammo.caliber then return false end
    for _, compatAmmo in ipairs(magazine.compatible_ammo) do
        if compatAmmo == ammoId then return true end
    end
    return false
end

function GetCompatibleItems(itemId)
    local item = Items[itemId]
    if not item then return {} end

    local compatible = {
        weapons = {},
        magazines = {},
        ammo = {}
    }

    if item.type == "weapon" then
        compatible.magazines = item.compatible_magazines or {}
    elseif item.type == "magazine" then
        compatible.weapons = item.compatible_weapons or {}
        compatible.ammo = item.compatible_ammo or {}
    elseif item.type == "ammo" then
        compatible.magazines = item.compatible_magazines or {}
    end

    return compatible
end

return Items
