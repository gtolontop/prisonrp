-- ============================================
-- CLEANUP: Keep only 2 items, delete the rest
-- ============================================

-- Step 1: Check what you have
SELECT
    item_instance_id,
    item_id,
    quantity,
    slot_type,
    slot_index
FROM inventory_items
WHERE charid = 1
ORDER BY item_instance_id;

-- Step 2: Delete all items except the FIRST 2
DELETE FROM inventory_items
WHERE charid = 1
AND item_instance_id NOT IN (
    SELECT item_instance_id FROM (
        SELECT item_instance_id
        FROM inventory_items
        WHERE charid = 1
        ORDER BY item_instance_id
        LIMIT 2
    ) AS keep_items
);

-- Step 3: Reset pocket indexes to 0 and 1
UPDATE inventory_items
SET slot_index = 0
WHERE charid = 1
ORDER BY item_instance_id
LIMIT 1;

UPDATE inventory_items
SET slot_index = 1
WHERE charid = 1
AND slot_index != 0
ORDER BY item_instance_id
LIMIT 1;

-- Step 4: Verify result (should show only 2 items)
SELECT
    item_instance_id,
    item_id,
    quantity,
    slot_type,
    slot_index
FROM inventory_items
WHERE charid = 1
ORDER BY slot_index;
