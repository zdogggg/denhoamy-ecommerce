-- ====================================
-- MIGRATION: Thêm các Foreign Key còn thiếu
-- Chạy file này trên database đã tồn tại
-- ====================================
USE denhoamy_db;

-- ====================================
-- 1. products.category_id → categories(id)
-- ====================================
ALTER TABLE products ADD COLUMN category_id INT NULL AFTER id;
ALTER TABLE products ADD CONSTRAINT fk_products_category 
    FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL;

-- Tự động gán category_id dựa trên loai_den hiện tại
UPDATE products p
    JOIN categories c ON LOWER(TRIM(c.name)) = LOWER(TRIM(p.loai_den))
SET p.category_id = c.id;

-- ====================================
-- 2. orders.user_id → users(id)
-- ====================================
ALTER TABLE orders ADD COLUMN user_id INT NULL AFTER id;
ALTER TABLE orders ADD CONSTRAINT fk_orders_user 
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL;

-- Tự động gán user_id dựa trên phone hiện tại
UPDATE orders o
    JOIN users u ON o.phone = u.phone
SET o.user_id = u.id;

-- ====================================
-- 3. orders.coupon_id → coupons(id)
-- ====================================
ALTER TABLE orders ADD COLUMN coupon_id INT NULL AFTER coupon_code;
ALTER TABLE orders ADD CONSTRAINT fk_orders_coupon 
    FOREIGN KEY (coupon_id) REFERENCES coupons(id) ON DELETE SET NULL;

-- Tự động gán coupon_id dựa trên coupon_code hiện tại
UPDATE orders o
    JOIN coupons c ON o.coupon_code = c.code
SET o.coupon_id = c.id;

-- ====================================
-- 4. reviews.user_id → users(id)
-- ====================================
ALTER TABLE reviews ADD COLUMN user_id INT NULL AFTER product_id;
ALTER TABLE reviews ADD CONSTRAINT fk_reviews_user 
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL;

-- ====================================
-- DONE! Kiểm tra lại sơ đồ ERD trên phpMyAdmin
-- ====================================
SELECT 'Migration completed! Refresh ERD on phpMyAdmin.' AS result;
