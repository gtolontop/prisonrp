-- Add is_dead column to characters table to track death state
-- This prevents false death detection on reconnect

ALTER TABLE `characters`
ADD COLUMN `is_dead` BOOLEAN DEFAULT FALSE AFTER `dateofbirth`,
ADD COLUMN `death_coords` JSON NULL AFTER `is_dead`,
ADD COLUMN `death_time` TIMESTAMP NULL AFTER `death_coords`;

-- Add index for quick death checks
ALTER TABLE `characters` ADD INDEX `idx_is_dead` (`is_dead`);
