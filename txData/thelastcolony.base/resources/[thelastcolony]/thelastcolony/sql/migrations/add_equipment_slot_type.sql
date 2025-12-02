-- ========================================
-- Migration: Add 'equipment' and 'backpack_storage' to slot_type ENUM
-- Date: 2025-10-23
-- Reason: Support equipping items directly from loot containers + backpack dynamic storage
-- ========================================

ALTER TABLE `inventory_items`
MODIFY COLUMN `slot_type` ENUM('grid', 'pocket', 'rig', 'equipment', 'backpack_storage') DEFAULT 'grid';
