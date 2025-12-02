-- Migration: Add rotation column to loot_containers table
-- Date: 2025-01-24
-- Purpose: Store full 3D rotation (pitch, roll, yaw) for dropped items to preserve exact prop rotation on server restart

ALTER TABLE `loot_containers`
ADD COLUMN `rotation` JSON NULL COMMENT '{pitch, roll, yaw} - 3D rotation for dropped items' AFTER `position`;
