-- ====================================
-- BẢNG QUẢN LÝ ẢNH SẢN PHẨM (PRODUCT_IMAGES)
-- ====================================
USE denhoamy_db;

CREATE TABLE IF NOT EXISTS product_images (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    image_url LONGTEXT NOT NULL,
    is_main BOOLEAN DEFAULT FALSE,
    sort_order INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
);

-- ====================================
-- DI CHUYỂN DỮ LIỆU TỪ GALLERY SANG BẢNG MỚI
-- (Yêu cầu MySQL 8.0+)
-- ====================================
INSERT INTO product_images (product_id, image_url, is_main, sort_order)
SELECT p.id, jt.url, CASE WHEN jt.ord = 1 THEN 1 ELSE 0 END, jt.ord
FROM products p,
JSON_TABLE(p.gallery, '$[*]' COLUMNS (
    ord FOR ORDINALITY,
    url VARCHAR(255) PATH '$'
)) AS jt
WHERE p.gallery IS NOT NULL AND JSON_VALID(p.gallery) AND p.gallery != '[]';

-- Lưu ý: Sau khi kiểm tra dữ liệu ổn định, bạn có thể xóa cột gallery ở bảng products.
