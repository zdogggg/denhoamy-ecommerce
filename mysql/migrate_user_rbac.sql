-- ====================================
-- MIGRATION: RBAC quản lý người dùng (admins / users)
-- Chạy trên DB đã tồn tại trong phpMyAdmin hoặc CLI
-- Bỏ qua lỗi "Duplicate column name" nếu cột đã có sẵn
-- ====================================
USE denhoamy_db;

-- ------------------------------------
-- 1. Bảng admins — role, permissions, is_active
-- ------------------------------------
ALTER TABLE admins
    ADD COLUMN role ENUM('admin', 'staff') NOT NULL DEFAULT 'staff'
        COMMENT 'admin = toàn quyền, staff = theo permissions JSON'
        AFTER username;

ALTER TABLE admins
    ADD COLUMN permissions JSON NULL
        COMMENT 'Phân quyền staff: dashboard, products, customers, accounts, ...'
        AFTER email;

ALTER TABLE admins
    ADD COLUMN is_active BOOLEAN NOT NULL DEFAULT TRUE
        COMMENT 'FALSE = không đăng nhập được'
        AFTER permissions;

-- Admin gốc luôn full quyền
UPDATE admins SET role = 'admin', is_active = TRUE WHERE id = 1;

-- Staff cũ chưa có permissions → gán mặc định (khớp auth_middleware.php)
UPDATE admins
SET permissions = JSON_OBJECT(
    'dashboard', TRUE,
    'categories', TRUE,
    'products', TRUE,
    'orders', TRUE,
    'reviews', TRUE,
    'customers', FALSE,
    'coupons', TRUE,
    'news', TRUE,
    'policy', TRUE,
    'accounts', FALSE,
    'settings', FALSE
)
WHERE role = 'staff' AND (permissions IS NULL OR JSON_TYPE(permissions) = 'NULL');

-- Đổi key cũ finance → accounts (form UI cũ dùng nhầm key)
UPDATE admins
SET permissions = JSON_SET(
    JSON_REMOVE(permissions, '$.finance'),
    '$.accounts',
    COALESCE(
        JSON_EXTRACT(permissions, '$.accounts'),
        JSON_EXTRACT(permissions, '$.finance'),
        FALSE
    )
)
WHERE role = 'staff'
  AND permissions IS NOT NULL
  AND JSON_CONTAINS_PATH(permissions, 'one', '$.finance');

-- ------------------------------------
-- 2. Bảng users — is_locked, address
-- ------------------------------------
ALTER TABLE users
    ADD COLUMN is_locked BOOLEAN NOT NULL DEFAULT FALSE
        COMMENT 'TRUE = khách bị khóa, không đăng nhập'
        AFTER email;

ALTER TABLE users
    ADD COLUMN address TEXT NULL
        COMMENT 'Địa chỉ profile khách (users.php target=profile)'
        AFTER email;

-- ------------------------------------
-- 3. Kiểm tra nhanh sau migration
-- ------------------------------------
SELECT id, username, role, is_active,
       JSON_EXTRACT(permissions, '$.customers') AS perm_customers,
       JSON_EXTRACT(permissions, '$.accounts') AS perm_accounts
FROM admins
ORDER BY id;

SELECT COUNT(*) AS total_users, SUM(is_locked) AS locked_users FROM users;
