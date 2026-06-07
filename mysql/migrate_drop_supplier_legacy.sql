-- =====================================================
-- VPS / DB đã tồn tại: gỡ supplier_id + FK suppliers (legacy)
-- An toàn chạy nhiều lần trên MySQL 8.0+
-- =====================================================
USE denhoamy_db;

SET @fk_exists := (
    SELECT COUNT(*)
    FROM information_schema.TABLE_CONSTRAINTS
    WHERE CONSTRAINT_SCHEMA = DATABASE()
      AND TABLE_NAME = 'products'
      AND CONSTRAINT_NAME = 'products_ibfk_2'
      AND CONSTRAINT_TYPE = 'FOREIGN KEY'
);
SET @sql_drop_fk := IF(
    @fk_exists > 0,
    'ALTER TABLE products DROP FOREIGN KEY products_ibfk_2',
    'SELECT 1'
);
PREPARE stmt FROM @sql_drop_fk;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @col_exists := (
    SELECT COUNT(*)
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'products'
      AND COLUMN_NAME = 'supplier_id'
);
SET @sql_drop_col := IF(
    @col_exists > 0,
    'ALTER TABLE products DROP COLUMN supplier_id',
    'SELECT 1'
);
PREPARE stmt FROM @sql_drop_col;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

DROP TABLE IF EXISTS suppliers;

-- Index tìm user theo SĐT (nếu chưa có)
SET @idx_exists := (
    SELECT COUNT(*)
    FROM information_schema.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'users'
      AND INDEX_NAME = 'idx_user_phone'
);
SET @sql_add_idx := IF(
    @idx_exists = 0,
    'ALTER TABLE users ADD INDEX idx_user_phone (phone)',
    'SELECT 1'
);
PREPARE stmt FROM @sql_add_idx;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SELECT 'migrate_drop_supplier_legacy: OK' AS result;
