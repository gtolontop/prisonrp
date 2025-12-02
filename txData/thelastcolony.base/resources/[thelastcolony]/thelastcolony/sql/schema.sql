-- ========================================
-- THE LAST COLONY - DATABASE SCHEMA
-- Custom Extraction Shooter Inventory System
-- Compatible with ox_core
-- ========================================

-- Note: ox_core already creates `users` and `characters` tables
-- We extend them with our custom tables

-- ========================================
-- INVENTORY SYSTEM
-- ========================================

-- Items in the main inventory (simplified - no separate inventory table)
CREATE TABLE IF NOT EXISTS `inventory_items` (
  `item_instance_id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `charid` INT UNSIGNED NOT NULL,
  `item_id` VARCHAR(50) NOT NULL,
  `quantity` INT UNSIGNED DEFAULT 1,
  `position_x` TINYINT UNSIGNED,  -- NULL if in special slot (pockets/rig)
  `position_y` TINYINT UNSIGNED,
  `rotation` TINYINT UNSIGNED DEFAULT 0,  -- 0=0°, 1=90°, 2=180°, 3=270°
  `slot_type` ENUM('grid', 'pocket', 'rig', 'equipment', 'backpack_storage', 'case_storage') DEFAULT 'grid',
  `slot_index` TINYINT UNSIGNED,  -- For pockets/rig (0-4 for pockets, etc.)
  `metadata` JSON,  -- Ammo, durability, attachments, etc.
  `durability` TINYINT UNSIGNED DEFAULT 100,
  `weight` FLOAT DEFAULT 0.0,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (`charid`) REFERENCES `characters`(`charId`) ON DELETE CASCADE,
  INDEX `idx_charid` (`charid`),
  INDEX `idx_item` (`item_id`),
  INDEX `idx_slot` (`slot_type`, `slot_index`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Equipment slots (simplified - references inventory_items)
CREATE TABLE IF NOT EXISTS `equipment` (
  `charid` INT UNSIGNED NOT NULL,
  `slot_name` VARCHAR(20) NOT NULL,
  `item_instance_id` INT UNSIGNED DEFAULT NULL,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`charid`, `slot_name`),
  FOREIGN KEY (`charid`) REFERENCES `characters`(`charId`) ON DELETE CASCADE,
  FOREIGN KEY (`item_instance_id`) REFERENCES `inventory_items`(`item_instance_id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ========================================
-- BODY HEALTH SYSTEM
-- ========================================

CREATE TABLE IF NOT EXISTS `body_health` (
  `character_id` INT UNSIGNED PRIMARY KEY,
  `head_hp` TINYINT UNSIGNED DEFAULT 100,
  `torso_hp` TINYINT UNSIGNED DEFAULT 100,
  `left_arm_hp` TINYINT UNSIGNED DEFAULT 100,
  `right_arm_hp` TINYINT UNSIGNED DEFAULT 100,
  `left_leg_hp` TINYINT UNSIGNED DEFAULT 100,
  `right_leg_hp` TINYINT UNSIGNED DEFAULT 100,
  `effects` JSON,  -- [{type: "bleeding", zone: "torso", started_at: 123456}, ...]
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (`character_id`) REFERENCES `characters`(`charid`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ========================================
-- CLOTHING (Cosmetics)
-- ========================================

CREATE TABLE IF NOT EXISTS `clothing` (
  `character_id` INT UNSIGNED PRIMARY KEY,
  `outfit` JSON,  -- GTA V clothing components
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (`character_id`) REFERENCES `characters`(`charid`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ========================================
-- STORAGE SYSTEMS
-- ========================================

-- Personal storage (in military base safe zone)
CREATE TABLE IF NOT EXISTS `storage_personal` (
  `character_id` INT UNSIGNED PRIMARY KEY,
  `grid_width` TINYINT UNSIGNED DEFAULT 20,
  `grid_height` TINYINT UNSIGNED DEFAULT 15,  -- 300 slots base
  `items` JSON,  -- [{item_id, quantity, x, y, rotation, metadata}, ...]
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (`character_id`) REFERENCES `characters`(`charid`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Guilds
CREATE TABLE IF NOT EXISTS `guilds` (
  `guild_id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(100) UNIQUE NOT NULL,
  `tag` VARCHAR(10) UNIQUE,
  `level` TINYINT UNSIGNED DEFAULT 1,
  `storage_width` TINYINT UNSIGNED DEFAULT 20,
  `storage_height` TINYINT UNSIGNED DEFAULT 15,
  `bank_money` BIGINT UNSIGNED DEFAULT 0,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX `idx_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Guild members
CREATE TABLE IF NOT EXISTS `guild_members` (
  `guild_id` INT UNSIGNED NOT NULL,
  `character_id` INT UNSIGNED NOT NULL,
  `rank` TINYINT UNSIGNED DEFAULT 0,  -- 0=member, 1=officer, 2=leader
  `joined_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`guild_id`, `character_id`),
  FOREIGN KEY (`guild_id`) REFERENCES `guilds`(`guild_id`) ON DELETE CASCADE,
  FOREIGN KEY (`character_id`) REFERENCES `characters`(`charid`) ON DELETE CASCADE,
  INDEX `idx_character` (`character_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Guild storage
CREATE TABLE IF NOT EXISTS `storage_guild` (
  `guild_id` INT UNSIGNED PRIMARY KEY,
  `items` JSON,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (`guild_id`) REFERENCES `guilds`(`guild_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ========================================
-- SESSIONS & COMBAT HISTORY
-- ========================================

-- Player sessions (from spawn to extraction/death)
CREATE TABLE IF NOT EXISTS `player_sessions` (
  `session_id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `character_id` INT UNSIGNED NOT NULL,
  `started_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `ended_at` TIMESTAMP NULL,
  `status` ENUM('active', 'extracted', 'died') DEFAULT 'active',
  `spawn_location` JSON,  -- {x, y, z}
  `extraction_location` JSON,
  -- Session stats
  `total_kills` INT UNSIGNED DEFAULT 0,
  `zombie_kills` INT UNSIGNED DEFAULT 0,
  `military_zombie_kills` INT UNSIGNED DEFAULT 0,
  `bandit_kills` INT UNSIGNED DEFAULT 0,
  `player_kills` INT UNSIGNED DEFAULT 0,
  `total_damage_dealt` INT UNSIGNED DEFAULT 0,
  `total_damage_received` INT UNSIGNED DEFAULT 0,
  `total_looted_value` BIGINT UNSIGNED DEFAULT 0,  -- Value of items looted (not bought)
  `total_distance_traveled` FLOAT DEFAULT 0.0,
  `containers_opened` INT UNSIGNED DEFAULT 0,
  `missions_completed` INT UNSIGNED DEFAULT 0,
  FOREIGN KEY (`character_id`) REFERENCES `characters`(`charid`) ON DELETE CASCADE,
  INDEX `idx_character` (`character_id`),
  INDEX `idx_status` (`status`),
  INDEX `idx_started` (`started_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Detailed combat logs (for replay/killcam)
CREATE TABLE IF NOT EXISTS `combat_logs` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `session_id` INT UNSIGNED NOT NULL,
  `character_id` INT UNSIGNED NOT NULL,
  `event_type` ENUM('movement', 'kill', 'death', 'damage_dealt', 'damage_received', 'loot', 'container_open', 'mission_progress') NOT NULL,
  `data` JSON,  -- Event-specific data
  `timestamp` TIMESTAMP(3) DEFAULT CURRENT_TIMESTAMP(3),  -- Millisecond precision
  FOREIGN KEY (`session_id`) REFERENCES `player_sessions`(`session_id`) ON DELETE CASCADE,
  FOREIGN KEY (`character_id`) REFERENCES `characters`(`charid`) ON DELETE CASCADE,
  INDEX `idx_session` (`session_id`),
  INDEX `idx_character_type` (`character_id`, `event_type`),
  INDEX `idx_timestamp` (`timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ========================================
-- LEADERBOARDS
-- ========================================

CREATE TABLE IF NOT EXISTS `leaderboard` (
  `character_id` INT UNSIGNED PRIMARY KEY,
  -- All-time stats
  `total_kills` INT UNSIGNED DEFAULT 0,
  `total_deaths` INT UNSIGNED DEFAULT 0,
  `total_extractions` INT UNSIGNED DEFAULT 0,
  `total_zombie_kills` INT UNSIGNED DEFAULT 0,
  `total_military_zombie_kills` INT UNSIGNED DEFAULT 0,
  `total_bandit_kills` INT UNSIGNED DEFAULT 0,
  `total_player_kills` INT UNSIGNED DEFAULT 0,
  `total_looted_value` BIGINT UNSIGNED DEFAULT 0,
  `total_distance_traveled` FLOAT DEFAULT 0.0,
  `total_playtime_seconds` INT UNSIGNED DEFAULT 0,
  -- Records
  `longest_survival_time` INT UNSIGNED DEFAULT 0,  -- Seconds
  `best_extraction_value` BIGINT UNSIGNED DEFAULT 0,  -- Highest single extraction loot value
  `most_kills_single_session` INT UNSIGNED DEFAULT 0,
  `most_military_zombies_single_session` INT UNSIGNED DEFAULT 0,
  `most_bandits_single_session` INT UNSIGNED DEFAULT 0,
  -- Ratings
  `kd_ratio` FLOAT DEFAULT 0.0,  -- Calculated: total_kills / total_deaths
  `survival_rate` FLOAT DEFAULT 0.0,  -- Calculated: extractions / (extractions + deaths)
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (`character_id`) REFERENCES `characters`(`charid`) ON DELETE CASCADE,
  INDEX `idx_total_kills` (`total_kills`),
  INDEX `idx_extractions` (`total_extractions`),
  INDEX `idx_best_extraction` (`best_extraction_value`),
  INDEX `idx_kd` (`kd_ratio`),
  INDEX `idx_survival_rate` (`survival_rate`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ========================================
-- MARKETPLACE
-- ========================================

CREATE TABLE IF NOT EXISTS `marketplace` (
  `listing_id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `seller_character_id` INT UNSIGNED,  -- NULL if NPC seller
  `seller_is_npc` BOOLEAN DEFAULT FALSE,
  `item_id` VARCHAR(50) NOT NULL,
  `quantity` INT UNSIGNED DEFAULT 1,
  `metadata` JSON,
  `price` INT UNSIGNED NOT NULL,
  `listed_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `expires_at` TIMESTAMP NULL,
  `sold` BOOLEAN DEFAULT FALSE,
  `sold_to` INT UNSIGNED,
  `sold_at` TIMESTAMP NULL,
  INDEX `idx_seller` (`seller_character_id`),
  INDEX `idx_item` (`item_id`),
  INDEX `idx_sold` (`sold`),
  INDEX `idx_expires` (`expires_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ========================================
-- SERVER ECONOMY
-- ========================================

CREATE TABLE IF NOT EXISTS `server_economy` (
  `id` TINYINT UNSIGNED PRIMARY KEY DEFAULT 1,  -- Always 1 row
  `total_taxes_collected` BIGINT UNSIGNED DEFAULT 0,
  `total_event_payouts` BIGINT UNSIGNED DEFAULT 0,
  `total_money_in_circulation` BIGINT UNSIGNED DEFAULT 0,
  `total_items_looted` BIGINT UNSIGNED DEFAULT 0,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Initialize with 1 row
INSERT INTO `server_economy` (`id`) VALUES (1) ON DUPLICATE KEY UPDATE `id`=1;

-- ========================================
-- LOOT CONTAINERS (World spawns)
-- ========================================

CREATE TABLE IF NOT EXISTS `loot_containers` (
  `container_id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `container_type` VARCHAR(50) NOT NULL,  -- "small_crate", "large_crate", "medical_box", etc.
  `position` JSON NOT NULL,  -- {x, y, z, heading}
  `rotation` JSON,  -- {pitch, roll, yaw} - 3D rotation for dropped items
  `loot_table` VARCHAR(50),  -- "medical", "weapons", "food", "military", etc.
  `grid_width` TINYINT UNSIGNED DEFAULT 6,
  `grid_height` TINYINT UNSIGNED DEFAULT 4,
  `current_items` JSON,  -- [{item_id, quantity, x, y, metadata}, ...]
  `last_looted_at` TIMESTAMP NULL,
  `last_looted_by` INT UNSIGNED,
  `respawn_delay_seconds` INT UNSIGNED DEFAULT 300,  -- 5 minutes
  `active` BOOLEAN DEFAULT TRUE,
  INDEX `idx_type` (`container_type`),
  INDEX `idx_last_looted` (`last_looted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ========================================
-- CORPSES (Temporary player death loot)
-- ========================================

CREATE TABLE IF NOT EXISTS `corpses` (
  `corpse_id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `character_id` INT UNSIGNED NOT NULL,
  `character_name` VARCHAR(100),
  `position` JSON NOT NULL,  -- {x, y, z, heading}
  `items` JSON,  -- All items from inventory/equipment (except cosmetic clothing)
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `despawn_at` TIMESTAMP,  -- Auto-despawn after X minutes
  `looted_by` JSON,  -- [character_id1, character_id2, ...] who looted this
  INDEX `idx_despawn` (`despawn_at`),
  INDEX `idx_character` (`character_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ========================================
-- MISSIONS SYSTEM
-- ========================================

-- Available missions
CREATE TABLE IF NOT EXISTS `missions` (
  `mission_id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `mission_type` ENUM('pve', 'pvp', 'collection', 'extraction', 'exploration') NOT NULL,
  `name` VARCHAR(100) NOT NULL,
  `description` TEXT,
  `objectives` JSON,  -- [{type: "kill", target: "zombie_military", count: 10}, ...]
  `rewards` JSON,  -- [{type: "money", amount: 5000}, {type: "item", item_id: "...", quantity: 1}, ...]
  `requirements` JSON,  -- {min_level: 5, required_items: [...]}
  `repeatable` BOOLEAN DEFAULT TRUE,
  `cooldown_hours` INT UNSIGNED DEFAULT 24,
  `active` BOOLEAN DEFAULT TRUE,
  INDEX `idx_type` (`mission_type`),
  INDEX `idx_active` (`active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Character mission progress
CREATE TABLE IF NOT EXISTS `mission_progress` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `character_id` INT UNSIGNED NOT NULL,
  `mission_id` INT UNSIGNED NOT NULL,
  `session_id` INT UNSIGNED,  -- Linked to current session
  `status` ENUM('active', 'completed', 'failed') DEFAULT 'active',
  `progress` JSON,  -- [{objective_index: 0, current: 5, required: 10}, ...]
  `started_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `completed_at` TIMESTAMP NULL,
  `last_completed_at` TIMESTAMP NULL,  -- For cooldown tracking
  FOREIGN KEY (`character_id`) REFERENCES `characters`(`charid`) ON DELETE CASCADE,
  FOREIGN KEY (`mission_id`) REFERENCES `missions`(`mission_id`) ON DELETE CASCADE,
  FOREIGN KEY (`session_id`) REFERENCES `player_sessions`(`session_id`) ON DELETE SET NULL,
  INDEX `idx_character` (`character_id`),
  INDEX `idx_status` (`status`),
  INDEX `idx_session` (`session_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ========================================
-- ANTI-CHEAT LOGS
-- ========================================

CREATE TABLE IF NOT EXISTS `anticheat_logs` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `character_id` INT UNSIGNED NOT NULL,
  `action` VARCHAR(100) NOT NULL,  -- "inventory_move", "item_spawn", "distance_teleport", etc.
  `details` JSON,
  `severity` TINYINT UNSIGNED DEFAULT 1,  -- 1=info, 5=warning, 10=ban
  `flagged` BOOLEAN DEFAULT FALSE,
  `timestamp` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (`character_id`) REFERENCES `characters`(`charid`) ON DELETE CASCADE,
  INDEX `idx_character` (`character_id`),
  INDEX `idx_severity` (`severity`),
  INDEX `idx_flagged` (`flagged`),
  INDEX `idx_timestamp` (`timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ========================================
-- NPC SYSTEM (AI players for marketplace/world)
-- ========================================

CREATE TABLE IF NOT EXISTS `npc_characters` (
  `npc_id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(100) NOT NULL,
  `personality` ENUM('aggressive', 'neutral', 'friendly', 'trader') DEFAULT 'neutral',
  `money` BIGINT UNSIGNED DEFAULT 10000,
  `inventory` JSON,  -- NPC inventory
  `equipment` JSON,  -- NPC equipped items
  `position` JSON,  -- Last known position
  `active` BOOLEAN DEFAULT TRUE,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX `idx_personality` (`personality`),
  INDEX `idx_active` (`active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ========================================
-- WIPE SYSTEM
-- ========================================

CREATE TABLE IF NOT EXISTS `wipe_history` (
  `wipe_id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `wiped_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `total_characters_wiped` INT UNSIGNED DEFAULT 0,
  `total_items_wiped` INT UNSIGNED DEFAULT 0,
  `reason` VARCHAR(255)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ========================================
-- VIEWS (For optimized queries)
-- ========================================

-- Top players by kills
CREATE OR REPLACE VIEW `leaderboard_kills` AS
SELECT
  c.charid,
  CONCAT(c.firstname, ' ', c.lastname) AS name,
  l.total_kills,
  l.kd_ratio,
  l.total_extractions
FROM leaderboard l
JOIN characters c ON l.character_id = c.charid
ORDER BY l.total_kills DESC
LIMIT 100;

-- Top extractors
CREATE OR REPLACE VIEW `leaderboard_extractors` AS
SELECT
  c.charid,
  CONCAT(c.firstname, ' ', c.lastname) AS name,
  l.total_extractions,
  l.best_extraction_value,
  l.survival_rate
FROM leaderboard l
JOIN characters c ON l.character_id = c.charid
ORDER BY l.total_extractions DESC
LIMIT 100;

-- Active sessions
CREATE OR REPLACE VIEW `active_sessions` AS
SELECT
  s.session_id,
  s.character_id,
  CONCAT(c.firstname, ' ', c.lastname) AS player_name,
  s.started_at,
  TIMESTAMPDIFF(SECOND, s.started_at, NOW()) AS duration_seconds,
  s.total_kills,
  s.total_looted_value
FROM player_sessions s
JOIN characters c ON s.character_id = c.charid
WHERE s.status = 'active'
ORDER BY s.started_at DESC;
