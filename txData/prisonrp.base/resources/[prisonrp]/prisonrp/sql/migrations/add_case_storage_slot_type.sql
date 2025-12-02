-- Migration: Add 'case_storage' to slot_type ENUM
-- This allows items to be stored in the secure case (permanent storage)

ALTER TABLE `inventory_items`
MODIFY COLUMN `slot_type` ENUM('grid', 'pocket', 'rig', 'equipment', 'backpack_storage', 'case_storage') DEFAULT 'grid';
