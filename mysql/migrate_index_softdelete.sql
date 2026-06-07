-- =====================================================
-- MIGRATION: Thêm Index cho cột tìm kiếm + Soft Delete
-- Chạy migration này trên MySQL / phpMyAdmin
-- Safe: dùng IF NOT EXISTS / kiểm tra trùng index
-- =====================================================

-- ====== PHẦN 1: INDEX CHO CỘT TÌM KIẾM THƯỜNG XUYÊN ======

-- 1.1. Bảng products (đã có index từ lần chạy trước, bỏ qua nếu duplicate)
ALTER TABLE products ADD INDEX idx_ten_san_pham (ten_san_pham);
ALTER TABLE products ADD INDEX idx_ma_san_pham (ma_san_pham);
ALTER TABLE products ADD INDEX idx_loai_den (loai_den);
ALTER TABLE products ADD INDEX idx_price (price);
ALTER TABLE products ADD INDEX idx_hot_deal (is_hot_deal);

-- 1.2. Bảng orders
ALTER TABLE orders ADD INDEX idx_order_status (status);
ALTER TABLE orders ADD INDEX idx_order_user (user_id);

-- 1.3. Bảng users
ALTER TABLE users ADD INDEX idx_user_phone (phone);

-- 1.4. Bảng categories
ALTER TABLE categories ADD INDEX idx_cat_parent (parent_id);

-- 1.5. Bảng reviews
ALTER TABLE reviews ADD INDEX idx_review_product (product_id);

-- ====== PHẦN 2: SOFT DELETE ======

-- 2.1. products
ALTER TABLE products ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP NULL DEFAULT NULL;

-- 2.2. orders
ALTER TABLE orders ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP NULL DEFAULT NULL;

-- 2.3. users
ALTER TABLE users ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP NULL DEFAULT NULL;

-- 2.4. news
ALTER TABLE news ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP NULL DEFAULT NULL;

-- 2.5. reviews
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP NULL DEFAULT NULL;

-- 2.6. categories
ALTER TABLE categories ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP NULL DEFAULT NULL;
