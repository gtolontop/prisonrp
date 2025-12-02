-- ============================================
-- MIGRATION: Move existing grid items to pockets
-- ============================================
-- Run this ONCE to migrate items from old 6x4 grid to pocket slots
-- Only for YOUR character (charId = 1)

-- IMPORTANT: This is a SIMPLE migration that moves YOUR first 5 items to pockets
-- If you have more than 5 items, the rest will be DELETED!

-- Step 1: Check what you currently have
SELECT
    item_instance_id,
    item_id,
    quantity,
    slot_type,
    position_x,
    position_y
FROM inventory_items
WHERE charid = 1 AND slot_type = 'grid'
ORDER BY item_instance_id
LIMIT 10;

-- Step 2: Move first 5 items to pockets (RUN THESE ONE BY ONE)
-- Pocket 0
UPDATE inventory_items
SET slot_type = 'pocket', slot_index = 0, position_x = NULL, position_y = NULL
WHERE charid = 1 AND slot_type = 'grid'
ORDER BY item_instance_id
LIMIT 1;

-- Pocket 1
UPDATE inventory_items
SET slot_type = 'pocket', slot_index = 1, position_x = NULL, position_y = NULL
WHERE charid = 1 AND slot_type = 'grid'
ORDER BY item_instance_id
LIMIT 1;

-- Pocket 2
UPDATE inventory_items
SET slot_type = 'pocket', slot_index = 2, position_x = NULL, position_y = NULL
WHERE charid = 1 AND slot_type = 'grid'
ORDER BY item_instance_id
LIMIT 1;

-- Pocket 3
UPDATE inventory_items
SET slot_type = 'pocket', slot_index = 3, position_x = NULL, position_y = NULL
WHERE charid = 1 AND slot_type = 'grid'
ORDER BY item_instance_id
LIMIT 1;

-- Pocket 4
UPDATE inventory_items
SET slot_type = 'pocket', slot_index = 4, position_x = NULL, position_y = NULL
WHERE charid = 1 AND slot_type = 'grid'
ORDER BY item_instance_id
LIMIT 1;

-- Step 3: DELETE remaining items that don't fit (CAREFUL!)
-- DELETE FROM inventory_items
-- WHERE charid = 1 AND slot_type = 'grid';

-- Step 4: Verify result
SELECT
    item_instance_id,
    item_id,
    quantity,
    slot_type,
    slot_index
FROM inventory_items
WHERE charid = 1
ORDER BY slot_type, slot_index;
