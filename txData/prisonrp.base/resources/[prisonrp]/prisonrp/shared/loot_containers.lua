--[[
    LOOT CONTAINERS - World Props Configuration
    These are NOT items in the inventory, but props placed in the world
    that players can interact with to loot
]]

LootContainers = {}

-- ============================================
-- MILITARY CRATES (Custom Props)
-- ============================================

LootContainers["military_crate_wall_green"] = {
    name = "Military Supply Crate",
    description = "Large military supply crate. Contains high-tier loot.",
    model = `crate_wall_green`,
    container_size = {width = 6, height = 6}, -- Big inventory
    loot_table = "military_high_tier", -- Phase 2
    respawn_time = 1800, -- 30 minutes
    rarity_weight = "rare",
    can_be_destroyed = false
}

LootContainers["military_crate_wall_tan"] = {
    name = "Military Supply Crate (Desert)",
    description = "Desert camo military crate.",
    model = `crate_wall_tan`,
    container_size = {width = 6, height = 6},
    loot_table = "military_high_tier",
    respawn_time = 1800,
    rarity_weight = "rare",
    can_be_destroyed = false
}

LootContainers["military_crate_wall_olive"] = {
    name = "Military Supply Crate (Forest)",
    description = "Forest camo military crate.",
    model = `crate_wall_olive`,
    container_size = {width = 6, height = 6},
    loot_table = "military_high_tier",
    respawn_time = 1800,
    rarity_weight = "rare",
    can_be_destroyed = false
}

LootContainers["ammo_crate_small"] = {
    name = "Ammo Crate",
    description = "Small military ammo crate.",
    model = `crate_mil_small`,
    container_size = {width = 4, height = 4},
    loot_table = "ammo_weapons",
    respawn_time = 900, -- 15 minutes
    rarity_weight = "uncommon",
    can_be_destroyed = false
}

LootContainers["insurgent_crate"] = {
    name = "Insurgent Supply Crate",
    description = "Makeshift crate used by insurgent forces.",
    model = `crate_ins_small`,
    container_size = {width = 3, height = 4},
    loot_table = "insurgent_loot",
    respawn_time = 600, -- 10 minutes
    rarity_weight = "common",
    can_be_destroyed = true -- Can be blown up
}

LootContainers["russian_crate"] = {
    name = "Russian Supply Crate",
    description = "Russian military supply crate.",
    model = `crate_rus_small`,
    container_size = {width = 4, height = 4},
    loot_table = "russian_faction",
    respawn_time = 900,
    rarity_weight = "uncommon",
    can_be_destroyed = false
}

LootContainers["chinese_crate"] = {
    name = "Chinese Supply Crate",
    description = "PLA supply crate.",
    model = `crate_pla_small`,
    container_size = {width = 4, height = 4},
    loot_table = "chinese_faction",
    respawn_time = 900,
    rarity_weight = "uncommon",
    can_be_destroyed = false
}

LootContainers["australian_crate"] = {
    name = "Australian Military Crate",
    description = "Australian army supply crate.",
    model = `crate_aus`,
    container_size = {width = 5, height = 5},
    loot_table = "military_mid_tier",
    respawn_time = 1200,
    rarity_weight = "uncommon",
    can_be_destroyed = false
}

-- ============================================
-- NATIVE GTA V PROPS (Fallback/Default)
-- ============================================

LootContainers["cardboard_box"] = {
    name = "Cardboard Box",
    description = "Random loot box.",
    model = `prop_cs_cardbox_01`,
    container_size = {width = 2, height = 2},
    loot_table = "civilian_low_tier",
    respawn_time = 300, -- 5 minutes
    rarity_weight = "common",
    can_be_destroyed = true
}

LootContainers["toolbox"] = {
    name = "Toolbox",
    description = "Contains tools and materials.",
    model = `prop_tool_box_01`,
    container_size = {width = 3, height = 2},
    loot_table = "crafting_materials",
    respawn_time = 600,
    rarity_weight = "common",
    can_be_destroyed = false
}

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

function GetLootContainer(containerType)
    return LootContainers[containerType]
end

function GetAllLootContainers()
    return LootContainers
end

return LootContainers
