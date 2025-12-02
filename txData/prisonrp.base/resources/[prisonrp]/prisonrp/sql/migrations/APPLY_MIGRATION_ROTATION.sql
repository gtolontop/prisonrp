-- ============================================
-- APPLY MIGRATION: Add rotation column to loot_containers
-- Run this SQL file manually in your MySQL database
-- ============================================

-- Check if column already exists before adding
SET @dbname = DATABASE();
SET @tablename = 'loot_containers';
SET @columnname = 'rotation';
SET @preparedStatement = (SELECT IF(
  (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE
      (TABLE_SCHEMA = @dbname)
      AND (TABLE_NAME = @tablename)
      AND (COLUMN_NAME = @columnname)
  ) > 0,
  'SELECT ''Column rotation already exists in loot_containers'' AS Status;',
  'ALTER TABLE loot_containers ADD COLUMN rotation JSON NULL COMMENT ''{pitch, roll, yaw} - 3D rotation for dropped items'' AFTER position;'
));

PREPARE alterIfNotExists FROM @preparedStatement;
EXECUTE alterIfNotExists;
DEALLOCATE PREPARE alterIfNotExists;

-- Verify the column was added
DESCRIBE loot_containers;
