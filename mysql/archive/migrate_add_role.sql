-- ====================================
-- MIGRATION: Thêm cột role cho bảng admins
-- Chạy file này trên database đã tồn tại
-- ====================================
USE denhoamy_db;

-- 1. Thêm cột role vào bảng admins
ALTER TABLE admins ADD COLUMN role ENUM('admin', 'staff') DEFAULT 'staff' 
    COMMENT 'admin = toàn quyền, staff = giới hạn theo permissions'
    AFTER username;

-- 2. Cập nhật admin gốc (ID = 1) thành role admin  
UPDATE admins SET role = 'admin' WHERE id = 1;

-- 3. Nếu có bảng suppliers và cột supplier_id, xoá đi
-- (Bỏ bảng nhà cung cấp theo yêu cầu)
SET FOREIGN_KEY_CHECKS = 0;
ALTER TABLE products DROP FOREIGN KEY IF EXISTS fk_products_supplier;
ALTER TABLE products DROP COLUMN IF EXISTS supplier_id;
DROP TABLE IF EXISTS suppliers;
SET FOREIGN_KEY_CHECKS = 1;

-- DONE!
SELECT 'Migration completed! Role column added to admins table.' AS result;
