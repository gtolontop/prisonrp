-- ========================================
-- REFACTOR: inventory_items -> character_inventory
-- ========================================
-- This migration consolidates inventory data into character_inventory
-- for better organization and foreign key relationships

-- Step 1: Create new character_inventory table
CREATE TABLE IF NOT EXISTS `character_inventory` (
  `item_instance_id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `charid` INT UNSIGNED NOT NULL,
  `item_id` VARCHAR(50) NOT NULL,
  `quantity` INT UNSIGNED DEFAULT 1,
  `position_x` TINYINT UNSIGNED,  -- NULL if in special slot (pockets/rig)
  `position_y` TINYINT UNSIGNED,
  `rotation` TINYINT UNSIGNED DEFAULT 0,  -- 0=0°, 1=90°, 2=180°, 3=270°
  `slot_type` ENUM('grid', 'pocket', 'rig', 'equipment', 'backpack_storage') DEFAULT 'grid',
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

-- Step 2: Migrate data from inventory_items to character_inventory (if exists)
INSERT INTO `character_inventory` (
  `item_instance_id`,
  `charid`,
  `item_id`,
  `quantity`,
  `position_x`,
  `position_y`,
  `rotation`,
  `slot_type`,
  `slot_index`,
  `metadata`,
  `durability`,
  `weight`,
  `created_at`
)
SELECT
  `item_instance_id`,
  `charid`,
  `item_id`,
  `quantity`,
  `position_x`,
  `position_y`,
  `rotation`,
  `slot_type`,
  `slot_index`,
  `metadata`,
  `durability`,
  `weight`,
  `created_at`
FROM `inventory_items`
WHERE EXISTS (SELECT 1 FROM `inventory_items` LIMIT 1);

-- Step 3: Update equipment table to reference character_inventory
-- First, drop the foreign key constraint
ALTER TABLE `equipment` DROP FOREIGN KEY IF EXISTS `equipment_ibfk_2`;

-- Step 4: Drop the old inventory_items table
DROP TABLE IF EXISTS `inventory_items`;

-- Step 5: Re-add foreign key constraint for equipment table
ALTER TABLE `equipment`
  ADD CONSTRAINT `equipment_ibfk_2`
  FOREIGN KEY (`item_instance_id`)
  REFERENCES `character_inventory`(`item_instance_id`)
  ON DELETE SET NULL;

-- Done!
-- Now all inventory items are in character_inventory instead of inventory_items
