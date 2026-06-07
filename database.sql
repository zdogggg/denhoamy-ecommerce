-- ====================================
-- DATABASE: denhoamy_db
-- ====================================
-- Chạy file này trong MySQL/phpMyAdmin để tạo database
SET NAMES utf8mb4;
SET CHARACTER SET utf8mb4;

CREATE DATABASE IF NOT EXISTS denhoamy_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE denhoamy_db;

-- ====================================
-- BẢNG DANH MỤC (CATEGORIES)
-- ====================================
CREATE TABLE IF NOT EXISTS categories (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    parent_id INT NULL,
    sort_order INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (parent_id) REFERENCES categories(id) ON DELETE CASCADE
);

-- ====================================
-- 1. BẢNG SẢN PHẨM
-- ====================================
CREATE TABLE IF NOT EXISTS products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    category_id INT NULL,
    ten_san_pham VARCHAR(255),
    ma_san_pham VARCHAR(100) UNIQUE,
    loai_den VARCHAR(100),
    phong_cach VARCHAR(100),
    khong_gian_lap_dat VARCHAR(255),
    bong_den VARCHAR(255),
    dien_ap VARCHAR(50),
    chat_lieu VARCHAR(255),
    tinh_trang VARCHAR(50),
    tuoi_tho VARCHAR(50),
    kich_thuoc VARCHAR(255),
    price DECIMAL(15,2) NOT NULL,
    cost_price DECIMAL(15,0) DEFAULT 0,
    old_price DECIMAL(15,2) DEFAULT 0,
    is_hot_deal TINYINT(1) NOT NULL DEFAULT 0,
    stock INT DEFAULT 15,
    description LONGTEXT,
    image_url LONGTEXT,
    gallery LONGTEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL
);

-- ====================================
-- BẢNG THÔNG SỐ SẢN PHẨM (SPECIFICATIONS)
-- ====================================
CREATE TABLE IF NOT EXISTS product_specs (
    product_id INT PRIMARY KEY,
    phong_cach VARCHAR(100),
    khong_gian_lap_dat VARCHAR(255),
    bong_den VARCHAR(255),
    dien_ap VARCHAR(50),
    chat_lieu VARCHAR(255),
    tinh_trang VARCHAR(50),
    tuoi_tho VARCHAR(50),
    kich_thuoc VARCHAR(255),
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
);

-- ====================================
-- BẢNG SẢN PHẨM - BIẾN THỂ (VARIANTS)
-- ====================================
CREATE TABLE IF NOT EXISTS product_variants (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    kich_thuoc VARCHAR(100),
    anh_sang VARCHAR(100),
    price DECIMAL(15,2) NOT NULL,
    cost_price DECIMAL(15,0) DEFAULT 0,
    stock INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
);

-- ====================================
-- 2. BẢNG QUẢN TRỊ VIÊN (ADMINS) - Tách biệt khỏi users
-- ====================================
CREATE TABLE IF NOT EXISTS admins (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(100) UNIQUE NOT NULL,
    role ENUM('admin', 'staff') DEFAULT 'staff' COMMENT 'admin = toàn quyền, staff = giới hạn theo permissions',
    password VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(255),
    avatar_url LONGTEXT NULL,
    permissions JSON NULL COMMENT 'Phân quyền chi tiết cho từng nhân viên (staff)',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tạo tài khoản admin mặc định (mật khẩu: 123456)
INSERT INTO admins (username, role, password, name, phone, email, permissions, is_active) VALUES 
('admin', 'admin', '$2y$10$FFkw65Abpyo1tek/HUFL8ut0doc7RG0yUPczl6Qr9oz8QRpw.cw.y', 'Trần Minh Hiếu', '0978897579', 'hieu.it@denhoamy.com', NULL, TRUE);
-- Lưu ý: mật khẩu trên là hash của '123456' bằng password_hash()

-- ====================================
-- 3. BẢNG KHÁCH HÀNG (USERS)
-- ====================================
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(255),
    address TEXT NULL COMMENT 'Địa chỉ giao hàng / liên hệ (profile khách)',
    is_locked BOOLEAN DEFAULT FALSE COMMENT 'TRUE = tài khoản bị khoá',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ====================================
-- BẢNG MÃ GIẢM GIÁ (COUPONS)
-- ====================================
CREATE TABLE IF NOT EXISTS coupons (
    id INT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(50) UNIQUE,
    discount_percent INT DEFAULT 0,
    discount_amount DECIMAL(15,0) DEFAULT 0,
    min_order_value DECIMAL(15,0) DEFAULT 0,
    usage_limit INT DEFAULT NULL,
    used_count INT DEFAULT 0,
    start_date DATE,
    end_date DATE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ====================================
-- 3. BẢNG ĐƠN HÀNG
-- ====================================
CREATE TABLE IF NOT EXISTS orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NULL,
    customer_name VARCHAR(255) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(255),
    address TEXT NOT NULL,
    delivery_method ENUM('home', 'store') NOT NULL DEFAULT 'home',
    note TEXT,
    payment_method VARCHAR(50) DEFAULT 'cod',
    total DECIMAL(15,0) DEFAULT 0,
    coupon_code VARCHAR(50) DEFAULT NULL,
    coupon_id INT NULL,
    discount_amount DECIMAL(15,0) DEFAULT 0,
    status ENUM('pending', 'approved', 'shipping', 'completed', 'cancelled') DEFAULT 'pending',
    processed_by INT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (coupon_id) REFERENCES coupons(id) ON DELETE SET NULL,
    FOREIGN KEY (processed_by) REFERENCES admins(id) ON DELETE SET NULL
);

-- ====================================
-- 4. BẢNG CHI TIẾT ĐƠN HÀNG
-- ====================================
CREATE TABLE IF NOT EXISTS order_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    product_id INT,
    variant_id INT NULL,
    product_name VARCHAR(255),
    quantity INT DEFAULT 1,
    price DECIMAL(15,0) DEFAULT 0,
    cost_price DECIMAL(15,0) DEFAULT 0,
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE SET NULL,
    FOREIGN KEY (variant_id) REFERENCES product_variants(id) ON DELETE SET NULL
);

-- ====================================
-- 5. INSERT DỮ LIỆU SẢN PHẨM
-- ====================================

-- ================== ĐÈN CHÙM ==================
INSERT INTO products (ten_san_pham, ma_san_pham, phong_cach, khong_gian_lap_dat, bong_den, dien_ap, chat_lieu, tinh_trang, tuoi_tho, kich_thuoc, loai_den, price, old_price, image_url) VALUES 
('Đèn chùm DC04305', 'DC04305', 'Tân cổ điển', 'phòng khách, phòng ngủ, phòng ăn,..', 'Led (vàng, trung tính, trắng)', '220v', 'Hợp kim + thủy tinh', 'Mới 100%', '50000', '', 'Đèn chùm', 15000000.00, 18500000.00, 'https://images.unsplash.com/photo-1540932239986-30128078f3c5?q=80&w=400'),
('Đèn chùm DC04304', 'DC04304', 'Mỹ', 'phòng khách, phòng ngủ, phòng ăn,..', 'Led (vàng, trung tính, trắng)', '220v', 'Hợp kim + chao vải', 'Mới 100%', '50000', '', 'Đèn chùm', 12500000.00, 15000000.00, 'https://images.unsplash.com/photo-1565814329452-e1efa11c5e89?q=80&w=400'),
('Đèn chùm DC04302', 'DC04302', 'Hiện đại', 'phòng khách, phòng ngủ, phòng ăn,..', 'Led (vàng, trung tính, trắng)', '220v', 'Hợp kim + thủy tinh', 'Mới 100%', '50000', '', 'Đèn chùm', 14200000.00, 16000000.00, 'https://images.unsplash.com/photo-1513506003901-1e6a229e2d15?q=80&w=400'),
('Đèn chùm DC04298', 'DC04298', 'Hiện đại', 'phòng khách, phòng ngủ, phòng ăn,..', 'Led (vàng, trung tính, trắng)', '220v', 'Hợp kim + chao vải', 'Mới 100%', '50000', '', 'Đèn chùm', 11000000.00, 13500000.00, 'https://images.unsplash.com/photo-1574180045827-681f8a1bef71?q=80&w=400'),
('Đèn chùm DC04303', 'DC04303', 'Hiện đại', 'phòng khách, phòng ngủ, phòng ăn,..', 'Led (vàng, trung tính, trắng)', '220v', 'Hợp kim + pha lê', 'Mới 100%', '50000', '', 'Đèn chùm', 18000000.00, 22000000.00, 'https://images.unsplash.com/photo-1524484485831-a92fa817b3f1?q=80&w=400'),
('Đèn chùm DC04299', 'DC04299', 'Hiện đại', 'phòng khách, phòng ngủ, phòng ăn,..', 'Led (vàng, trung tính, trắng)', '220v', 'Hợp kim + pha lê', 'Mới 100%', '50000', '', 'Đèn chùm', 17500000.00, 21000000.00, 'https://images.unsplash.com/photo-1517991104123-1d56a6e81ed9?q=80&w=400'),
('Đèn chùm DC04306', 'DC04306', 'Tân cổ điển', 'phòng khách, phòng ngủ, phòng ăn,..', 'Led (vàng, trung tính, trắng)', '220v', 'Hợp kim + thủy tinh + pha lê', 'Mới 100%', '50000', '', 'Đèn chùm', 19000000.00, 23000000.00, 'https://images.unsplash.com/photo-1540932239986-30128078f3c5?q=80&w=400'),
('Đèn chùm DC04297', 'DC04297', 'Mỹ', 'phòng khách, phòng ngủ, phòng ăn,..', 'Led (vàng, trung tính, trắng)', '220v', 'Đồng + chao vải', 'Mới 100%', '50000', '', 'Đèn chùm', 25000000.00, 28000000.00, 'https://images.unsplash.com/photo-1565814329452-e1efa11c5e89?q=80&w=400'),
('Đèn chùm DC04296', 'DC04296', 'Mỹ', 'phòng khách, phòng ngủ, phòng ăn,..', 'Led (vàng, trung tính, trắng)', '220v', 'Đồng + đá + da', 'Mới 100%', '50000', '', 'Đèn chùm', 27000000.00, 31000000.00, 'https://images.unsplash.com/photo-1513506003901-1e6a229e2d15?q=80&w=400'),
('Đèn chùm DC04307', 'DC04307', 'Tân cổ điển', 'phòng khách, phòng ngủ, phòng ăn,..', 'Led (vàng, trung tính, trắng)', '220v', 'Đồng + thủy tinh', 'Mới 100%', '50000', '', 'Đèn chùm', 22000000.00, 26000000.00, 'https://images.unsplash.com/photo-1574180045827-681f8a1bef71?q=80&w=400'),
('Đèn chùm DC04301', 'DC04301', 'Mỹ', 'phòng khách, phòng ngủ, phòng ăn,..', 'Led (vàng, trung tính, trắng)', '220v', 'Đồng + chao vải', 'Mới 100%', '50000', '', 'Đèn chùm', 24500000.00, 29000000.00, 'https://images.unsplash.com/photo-1524484485831-a92fa817b3f1?q=80&w=400'),
('Đèn chùm DC04292', 'DC04292', 'Hiện đại', 'phòng khách, phòng ngủ, phòng ăn,..', 'Led (vàng, trung tính, trắng)', '220v', 'Hợp kim', 'Mới 100%', '50000', '', 'Đèn chùm', 9500000.00, 11000000.00, 'https://images.unsplash.com/photo-1517991104123-1d56a6e81ed9?q=80&w=400'),
('Đèn chùm DC04275', 'DC04275', 'Trung Hoa', 'phòng khách, phòng ngủ, phòng ăn,..', 'Led (vàng, trung tính, trắng)', '220v', 'Hợp kim', 'Mới 100%', '50000', '', 'Đèn chùm', 10500000.00, 12500000.00, 'https://images.unsplash.com/photo-1540932239986-30128078f3c5?q=80&w=400'),
('Đèn chùm DC04281', 'DC04281', 'Cổ điển', 'phòng khách, phòng ngủ, phòng ăn,..', 'Led (vàng, trung tính, trắng)', '220v', 'Hợp kim + thủy tinh', 'Mới 100%', '50000', '', 'Đèn chùm', 13000000.00, 16000000.00, 'https://images.unsplash.com/photo-1565814329452-e1efa11c5e89?q=80&w=400'),
('Đèn chùm DC04276', 'DC04276', 'Đồng quê Pháp', 'phòng khách, phòng ngủ, phòng ăn,..', 'Led (vàng, trung tính, trắng)', '220v', 'Hợp kim + pha lê', 'Mới 100%', '50000', '', 'Đèn chùm', 16500000.00, 19500000.00, 'https://images.unsplash.com/photo-1513506003901-1e6a229e2d15?q=80&w=400');

-- ================== ĐÈN THẢ ==================
INSERT INTO products (ten_san_pham, ma_san_pham, phong_cach, khong_gian_lap_dat, bong_den, dien_ap, chat_lieu, tinh_trang, tuoi_tho, kich_thuoc, loai_den, price, old_price, image_url) VALUES 
('Đèn thả DT03308', 'DT03308', 'Nhật', 'phòng khách, phòng ngủ, phòng ăn,..', 'Led (vàng, trung tính, trắng)', '220v', 'Hợp kim + mây tre', 'Mới 100%', '50000', '', 'Đèn thả', 3200000.00, 4000000.00, 'https://images.unsplash.com/photo-1565814329452-e1efa11c5e89?q=80&w=400'),
('Đèn thả DT03301', 'DT03301', 'Zen', 'phòng khách, phòng ngủ, phòng ăn,..', 'Led (vàng, trung tính, trắng)', '220v', 'Hợp kim', 'Mới 100%', '50000', '', 'Đèn thả', 2800000.00, 3500000.00, 'https://images.unsplash.com/photo-1513506003901-1e6a229e2d15?q=80&w=400'),
('Đèn thả DT03294', 'DT03294', 'Hiện đại', 'phòng khách, phòng ngủ, phòng ăn,..', 'Led (vàng, trung tính, trắng)', '220v', 'Đồng + thủy tinh', 'Mới 100%', '50000', '', 'Đèn thả', 4500000.00, 5200000.00, 'https://images.unsplash.com/photo-1574180045827-681f8a1bef71?q=80&w=400'),
('Đèn thả DT03306', 'DT03306', 'Nhật', 'phòng khách, phòng ngủ, phòng ăn,..', 'Led (vàng, trung tính, trắng)', '220v', 'Hợp kim + chao vải', 'Mới 100%', '50000', '', 'Đèn thả', 3100000.00, 3800000.00, 'https://images.unsplash.com/photo-1524484485831-a92fa817b3f1?q=80&w=400'),
('Đèn thả DT03304', 'DT03304', 'Pháp', 'phòng khách, phòng ngủ, phòng ăn,..', 'Led (vàng, trung tính, trắng)', '220v', 'Hợp kim + pha lê', 'Mới 100%', '50000', '', 'Đèn thả', 5500000.00, 6800000.00, 'https://images.unsplash.com/photo-1517991104123-1d56a6e81ed9?q=80&w=400'),
('Đèn thả DT03295', 'DT03295', 'Hiện đại', 'phòng khách, phòng ngủ, phòng ăn,..', 'Led (vàng, trung tính, trắng)', '220v', 'Đồng + thủy tinh', 'Mới 100%', '50000', '', 'Đèn thả', 4800000.00, 5600000.00, 'https://images.unsplash.com/photo-1540932239986-30128078f3c5?q=80&w=400'),
('Đèn thả DT03305', 'DT03305', 'Nhật', 'phòng khách, phòng ngủ, phòng ăn,..', 'Led (vàng, trung tính, trắng)', '220v', 'Hợp kim + acrylic', 'Mới 100%', '50000', '', 'Đèn thả', 2900000.00, 3400000.00, 'https://images.unsplash.com/photo-1565814329452-e1efa11c5e89?q=80&w=400'),
('Đèn thả DT03297', 'DT03297', 'Hiện đại', 'phòng khách, phòng ngủ, phòng ăn,..', 'Led (vàng, trung tính, trắng)', '220v', 'Hợp kim + acrylic', 'Mới 100%', '50000', '', 'Đèn thả', 3300000.00, 4100000.00, 'https://images.unsplash.com/photo-1513506003901-1e6a229e2d15?q=80&w=400'),
('Đèn thả DT03299', 'DT03299', 'Hiện đại', 'phòng khách, phòng ngủ, phòng ăn,..', 'Led (vàng, trung tính, trắng)', '220v', 'Hợp kim + pha lê', 'Mới 100%', '50000', '', 'Đèn thả', 6200000.00, 7500000.00, 'https://images.unsplash.com/photo-1574180045827-681f8a1bef71?q=80&w=400'),
('Đèn thả DT03296', 'DT03296', 'Hiện đại', 'phòng khách, phòng ngủ, phòng ăn,..', 'Led (vàng, trung tính, trắng)', '220v', 'Hợp kim', 'Mới 100%', '50000', '', 'Đèn thả', 2600000.00, 3100000.00, 'https://images.unsplash.com/photo-1524484485831-a92fa817b3f1?q=80&w=400'),
('Đèn thả DT03303', 'DT03303', 'Zen', 'phòng khách, phòng ngủ, phòng ăn,..', 'Led (vàng, trung tính, trắng)', '220v', 'Hợp kim + rơm', 'Mới 100%', '50000', '', 'Đèn thả', 2100000.00, 2600000.00, 'https://images.unsplash.com/photo-1517991104123-1d56a6e81ed9?q=80&w=400'),
('Đèn thả DT03289', 'DT03289', 'Đồng quê Mỹ', 'nhà hàng, quán cafe, văn phòng, khách sạn,...', 'Led (vàng, trung tính, trắng)', '220v', 'Hợp kim + tre', 'Mới 100%', '50000', '', 'Đèn thả', 3800000.00, 4500000.00, 'https://images.unsplash.com/photo-1540932239986-30128078f3c5?q=80&w=400'),
('Đèn thả DT03288', 'DT03288', 'Retro', 'nhà hàng, quán cafe, văn phòng, khách sạn,...', 'Led (vàng, trung tính, trắng)', '220v', 'Hợp kim + thủy tinh', 'Mới 100%', '50000', '', 'Đèn thả', 2700000.00, 3300000.00, 'https://images.unsplash.com/photo-1565814329452-e1efa11c5e89?q=80&w=400'),
('Đèn thả DT03287', 'DT03287', 'Trung Hoa', 'nhà hàng, quán cafe, văn phòng, khách sạn,...', 'Led (vàng, trung tính, trắng)', '220v', 'Hợp kim + chao vải', 'Mới 100%', '50000', '', 'Đèn thả', 3400000.00, 4200000.00, 'https://images.unsplash.com/photo-1513506003901-1e6a229e2d15?q=80&w=400'),
('Đèn thả DT03279', 'DT03279', 'Tân cổ điển', 'phòng khách, phòng ngủ, phòng ăn,..', 'Led (vàng, trung tính, trắng)', '220v', 'Đồng', 'Mới 100%', '50000', '', 'Đèn thả', 6800000.00, 8000000.00, 'https://images.unsplash.com/photo-1574180045827-681f8a1bef71?q=80&w=400');

-- ================== ĐÈN ỐP TRẦN ==================
INSERT INTO products (ten_san_pham, ma_san_pham, phong_cach, khong_gian_lap_dat, bong_den, dien_ap, chat_lieu, tinh_trang, tuoi_tho, kich_thuoc, loai_den, price, old_price, image_url) VALUES 
('Đèn ốp trần DO01629', 'DO01629', 'Hiện đại', 'phòng khách, phòng ngủ, phòng ăn,..', 'Led (vàng, trung tính, trắng)', '220v', 'Hợp kim + acrylic + pha lê', 'Mới 100%', '50000', '', 'Đèn ốp trần', 4500000.00, 5500000.00, 'https://images.unsplash.com/photo-1524484485831-a92fa817b3f1?q=80&w=400'),
('Đèn ốp trần DO01627', 'DO01627', 'Hiện đại', 'phòng khách, phòng ngủ, phòng ăn,..', 'Led (vàng, trung tính, trắng)', '220v', 'Hợp kim + acrylic + gỗ', 'Mới 100%', '50000', '', 'Đèn ốp trần', 3800000.00, 4600000.00, 'https://images.unsplash.com/photo-1517991104123-1d56a6e81ed9?q=80&w=400'),
('Đèn ốp trần DO01624', 'DO01624', 'Tân cổ điển', 'phòng khách, phòng ngủ, phòng ăn,..', 'Led (vàng, trung tính, trắng)', '220v', 'Hợp kim + pha lê', 'Mới 100%', '50000', '', 'Đèn ốp trần', 5200000.00, 6200000.00, 'https://images.unsplash.com/photo-1540932239986-30128078f3c5?q=80&w=400'),
('Đèn ốp trần DO01621', 'DO01621', 'Trung Hoa', 'phòng khách, phòng ngủ, phòng ăn,..', 'Led (vàng, trung tính, trắng)', '220v', 'Hợp kim + acrylic', 'Mới 100%', '50000', '', 'Đèn ốp trần', 3500000.00, 4200000.00, 'https://images.unsplash.com/photo-1565814329452-e1efa11c5e89?q=80&w=400'),
('Đèn ốp trần DO01622', 'DO01622', 'Nhật', 'phòng khách, phòng ngủ, phòng ăn,..', 'Led (vàng, trung tính, trắng)', '220v', 'Hợp kim + chao vải', 'Mới 100%', '50000', '', 'Đèn ốp trần', 2900000.00, 3600000.00, 'https://images.unsplash.com/photo-1513506003901-1e6a229e2d15?q=80&w=400'),
('Đèn ốp trần DO01620', 'DO01620', 'Mỹ', 'phòng khách, phòng ngủ, phòng ăn,..', 'Led (vàng, trung tính, trắng)', '220v', 'Hợp kim + acrylic', 'Mới 100%', '50000', '', 'Đèn ốp trần', 4100000.00, 4900000.00, 'https://images.unsplash.com/photo-1574180045827-681f8a1bef71?q=80&w=400'),
('Đèn ốp trần DO01615', 'DO01615', 'Trung Cổ', 'phòng khách, phòng ngủ, phòng ăn,..', 'Led (vàng, trung tính, trắng)', '220v', 'Hợp kim + gỗ + chao vải', 'Mới 100%', '50000', '', 'Đèn ốp trần', 4600000.00, 5600000.00, 'https://images.unsplash.com/photo-1524484485831-a92fa817b3f1?q=80&w=400'),
('Đèn ốp trần DO01614', 'DO01614', 'Mỹ', 'phòng khách, phòng ngủ, phòng ăn,..', 'Led (vàng, trung tính, trắng)', '220v', 'Hợp kim + chao vải', 'Mới 100%', '50000', '', 'Đèn ốp trần', 3800000.00, 4500000.00, 'https://images.unsplash.com/photo-1517991104123-1d56a6e81ed9?q=80&w=400'),
('Đèn ốp trần DO01611', 'DO01611', 'Wabi-sabi', 'phòng khách, phòng ngủ, phòng ăn,..', 'Led (vàng, trung tính, trắng)', '220v', 'Hợp kim + thủy tinh', 'Mới 100%', '50000', '', 'Đèn ốp trần', 3200000.00, 3900000.00, 'https://images.unsplash.com/photo-1540932239986-30128078f3c5?q=80&w=400'),
('Đèn ốp trần DO01610', 'DO01610', 'Thổ Nhĩ Kỹ', 'phòng khách, phòng ngủ, phòng ăn,..', 'Led (vàng, trung tính, trắng)', '220v', 'Hợp kim', 'Mới 100%', '50000', '', 'Đèn ốp trần', 2700000.00, 3300000.00, 'https://images.unsplash.com/photo-1565814329452-e1efa11c5e89?q=80&w=400'),
('Đèn ốp trần DO01604', 'DO01604', 'Mỹ', 'phòng khách, phòng ngủ, phòng ăn,..', 'Led (vàng, trung tính, trắng)', '220v', 'Hợp kim', 'Mới 100%', '50000', '', 'Đèn ốp trần', 2500000.00, 3000000.00, 'https://images.unsplash.com/photo-1513506003901-1e6a229e2d15?q=80&w=400'),
('Đèn ốp trần DO01603', 'DO01603', 'Mỹ', 'nhà hàng, quán cafe, văn phòng, khách sạn,...', 'Led (vàng, trung tính, trắng)', '220v', 'Hợp kim + thủy tinh', 'Mới 100%', '50000', '', 'Đèn ốp trần', 3100000.00, 3800000.00, 'https://images.unsplash.com/photo-1574180045827-681f8a1bef71?q=80&w=400'),
('Đèn ốp trần DO01598', 'DO01598', 'Hiện đại', 'nhà hàng, quán cafe, văn phòng, khách sạn,...', 'Led (vàng, trung tính, trắng)', '220v', 'Hợp kim + pha lê', 'Mới 100%', '50000', '', 'Đèn ốp trần', 5800000.00, 6900000.00, 'https://images.unsplash.com/photo-1524484485831-a92fa817b3f1?q=80&w=400'),
('Đèn ốp trần DO01586', 'DO01586', 'Wabi-sabi', 'nhà hàng, quán cafe, văn phòng, khách sạn,...', 'Led (vàng, trung tính, trắng)', '220v', 'Hợp kim + chao vải', 'Mới 100%', '50000', '', 'Đèn ốp trần', 3400000.00, 4100000.00, 'https://images.unsplash.com/photo-1517991104123-1d56a6e81ed9?q=80&w=400'),
('Đèn ốp trần DO01585', 'DO01585', 'Hiện đại', 'phòng khách, phòng ngủ, phòng ăn,..', 'Led (vàng, trung tính, trắng)', '220v', 'Hợp kim + thủy tinh', 'Mới 100%', '50000', '', 'Đèn ốp trần', 2800000.00, 3500000.00, 'https://images.unsplash.com/photo-1540932239986-30128078f3c5?q=80&w=400');

-- ================== ĐÈN QUẠT ==================
INSERT INTO products (ten_san_pham, ma_san_pham, phong_cach, khong_gian_lap_dat, bong_den, dien_ap, chat_lieu, tinh_trang, tuoi_tho, kich_thuoc, loai_den, price, old_price, image_url) VALUES 
('Đèn quạt DQ00968', 'DQ00968', 'Trung Hoa', 'phòng khách, phòng ngủ, phòng ăn,..', 'Led (vàng, trung tính, trắng)', '220v', 'Hợp kim + acrylic', 'Mới 100%', '50000', '', 'Đèn quạt', 5200000.00, 6500000.00, 'https://images.unsplash.com/photo-1565814329452-e1efa11c5e89?q=80&w=400'),
('Đèn quạt DQ00966', 'DQ00966', 'Tân cổ điển', 'phòng khách, phòng ngủ, phòng ăn,..', 'Led (vàng, trung tính, trắng)', '220v', 'Hợp kim + pha lê', 'Mới 100%', '50000', '', 'Đèn quạt', 7800000.00, 9500000.00, 'https://images.unsplash.com/photo-1513506003901-1e6a229e2d15?q=80&w=400'),
('Đèn quạt DQ00967', 'DQ00967', 'Hiện đại', 'phòng khách, phòng ngủ, phòng ăn,..', 'Led (vàng, trung tính, trắng)', '220v', 'Hợp kim + pha lê', 'Mới 100%', '50000', '', 'Đèn quạt', 7500000.00, 9200000.00, 'https://images.unsplash.com/photo-1574180045827-681f8a1bef71?q=80&w=400'),
('Đèn quạt DQ00958', 'DQ00958', 'Hiện đại', 'phòng khách, phòng ngủ, phòng ăn,..', 'Led (vàng, trung tính, trắng)', '220v', 'Hợp kim + acrylic', 'Mới 100%', '50000', '', 'Đèn quạt', 4900000.00, 6000000.00, 'https://images.unsplash.com/photo-1524484485831-a92fa817b3f1?q=80&w=400'),
('Đèn quạt DQ00965', 'DQ00965', 'Nhật', 'phòng khách, phòng ngủ, phòng ăn,..', 'Led (vàng, trung tính, trắng)', '220v', 'Hợp kim + gỗ', 'Mới 100%', '50000', '', 'Đèn quạt', 5500000.00, 6800000.00, 'https://images.unsplash.com/photo-1517991104123-1d56a6e81ed9?q=80&w=400'),
('Đèn quạt DQ00962', 'DQ00962', 'Tân cổ điển', 'phòng khách, phòng ngủ, phòng ăn,..', 'Led (vàng, trung tính, trắng)', '220v', 'Hợp kim + thủy tinh', 'Mới 100%', '50000', '', 'Đèn quạt', 6200000.00, 7500000.00, 'https://images.unsplash.com/photo-1540932239986-30128078f3c5?q=80&w=400'),
('Đèn quạt DQ00964', 'DQ00964', 'Tân cổ điển', 'phòng khách, phòng ngủ, phòng ăn,..', 'Led (vàng, trung tính, trắng)', '220v', 'Hợp kim + thủy tinh', 'Mới 100%', '50000', '', 'Đèn quạt', 6400000.00, 7700000.00, 'https://images.unsplash.com/photo-1565814329452-e1efa11c5e89?q=80&w=400'),
('Đèn quạt DQ00961', 'DQ00961', 'Tân cổ điển', 'phòng khách, phòng ngủ, phòng ăn,..', 'Led (vàng, trung tính, trắng)', '220v', 'Hợp kim + thủy tinh + cánh ABS', 'Mới 100%', '50000', '', 'Đèn quạt', 5800000.00, 7000000.00, 'https://images.unsplash.com/photo-1513506003901-1e6a229e2d15?q=80&w=400'),
('Đèn quạt DQ00950', 'DQ00950', 'Trung Hoa', 'phòng khách, phòng ngủ, phòng ăn,..', 'Led (vàng, trung tính, trắng)', '220v', 'Hợp kim', 'Mới 100%', '50000', '', 'Đèn quạt', 4200000.00, 5000000.00, 'https://images.unsplash.com/photo-1574180045827-681f8a1bef71?q=80&w=400'),
('Đèn quạt DQ00951', 'DQ00951', 'Mỹ', 'phòng khách, phòng ngủ, phòng ăn,..', 'Led (vàng, trung tính, trắng)', '220v', 'Hợp kim + cánh gỗ', 'Mới 100%', '50000', '', 'Đèn quạt', 6100000.00, 7400000.00, 'https://images.unsplash.com/photo-1524484485831-a92fa817b3f1?q=80&w=400'),
('Đèn quạt DQ00953', 'DQ00953', 'Hiện đại', 'phòng khách, phòng ngủ, phòng ăn,..', 'Led (vàng, trung tính, trắng)', '220v', 'Hợp kim + pha lê', 'Mới 100%', '50000', '', 'Đèn quạt', 8500000.00, 10200000.00, 'https://images.unsplash.com/photo-1517991104123-1d56a6e81ed9?q=80&w=400'),
('Đèn quạt DQ00948', 'DQ00948', 'Mỹ Retro', 'nhà hàng, quán cafe, văn phòng, khách sạn,...', 'Led (vàng, trung tính, trắng)', '220v', 'Hợp kim', 'Mới 100%', '50000', '', 'Đèn quạt', 4700000.00, 5800000.00, 'https://images.unsplash.com/photo-1540932239986-30128078f3c5?q=80&w=400'),
('Đèn quạt DQ00942', 'DQ00942', 'Trung Hoa', 'nhà hàng, quán cafe, văn phòng, khách sạn,...', 'Led (vàng, trung tính, trắng)', '220v', 'Hợp kim + thủy tinh', 'Mới 100%', '50000', '', 'Đèn quạt', 5600000.00, 6800000.00, 'https://images.unsplash.com/photo-1565814329452-e1efa11c5e89?q=80&w=400'),
('Đèn quạt DQ00937', 'DQ00937', 'Tân cổ điển', 'nhà hàng, quán cafe, văn phòng, khách sạn,...', 'Led (vàng, trung tính, trắng)', '220v', 'Hợp kim + thủy tinh', 'Mới 100%', '50000', '', 'Đèn quạt', 6900000.00, 8200000.00, 'https://images.unsplash.com/photo-1513506003901-1e6a229e2d15?q=80&w=400'),
('Đèn quạt DQ00935', 'DQ00935', 'Hiện đại', 'phòng khách, phòng ngủ, phòng ăn,..', 'Led (vàng, trung tính, trắng)', '220v', 'Hợp kim + ABS', 'Mới 100%', '50000', '', 'Đèn quạt', 4500000.00, 5500000.00, 'https://images.unsplash.com/photo-1574180045827-681f8a1bef71?q=80&w=400');

-- ================== ĐÈN VÁCH ==================
INSERT INTO products (ten_san_pham, ma_san_pham, phong_cach, khong_gian_lap_dat, bong_den, dien_ap, chat_lieu, tinh_trang, tuoi_tho, kich_thuoc, loai_den, price, old_price, image_url) VALUES 
('Đèn vách DV02084', 'DV02084', 'Trung Hoa', 'phòng khách, phòng ngủ, phòng ăn,..', 'Led (vàng, trung tính, trắng)', '220v', 'Hợp kim + thủy tinh', 'Mới 100%', '50000', '', 'Đèn vách', 850000.00, 1100000.00, 'https://images.unsplash.com/photo-1524484485831-a92fa817b3f1?q=80&w=400'),
('Đèn vách DV02093', 'DV02093', 'Mỹ', 'phòng khách, phòng ngủ, phòng ăn,..', 'Led (vàng, trung tính, trắng)', '220v', 'Hợp kim + chao vải', 'Mới 100%', '50000', '', 'Đèn vách', 950000.00, 1250000.00, 'https://images.unsplash.com/photo-1517991104123-1d56a6e81ed9?q=80&w=400'),
('Đèn vách DV02091', 'DV02091', 'Mỹ', 'phòng khách, phòng ngủ, phòng ăn,..', 'Led (vàng, trung tính, trắng)', '220v', 'Hợp kim + chao vải', 'Mới 100%', '50000', '', 'Đèn vách', 920000.00, 1200000.00, 'https://images.unsplash.com/photo-1540932239986-30128078f3c5?q=80&w=400'),
('Đèn vách DV02081', 'DV02081', 'Hiện đại', 'phòng khách, phòng ngủ, phòng ăn,..', 'Led (vàng, trung tính, trắng)', '220v', 'Hợp kim + thủy tinh', 'Mới 100%', '50000', '', 'Đèn vách', 750000.00, 950000.00, 'https://images.unsplash.com/photo-1565814329452-e1efa11c5e89?q=80&w=400'),
('Đèn vách DV02090', 'DV02090', 'Hiện đại', 'phòng khách, phòng ngủ, phòng ăn,..', 'Led (vàng, trung tính, trắng)', '220v', 'Hợp kim + acrylic', 'Mới 100%', '50000', '', 'Đèn vách', 680000.00, 850000.00, 'https://images.unsplash.com/photo-1513506003901-1e6a229e2d15?q=80&w=400'),
('Đèn vách DV02082', 'DV02082', 'Trung Hoa', 'phòng khách, phòng ngủ, phòng ăn,..', 'Led (vàng, trung tính, trắng)', '220v', 'Hợp kim + giả đá cẩm thạch', 'Mới 100%', '50000', '', 'Đèn vách', 1200000.00, 1500000.00, 'https://images.unsplash.com/photo-1574180045827-681f8a1bef71?q=80&w=400'),
('Đèn vách DV02083', 'DV02083', 'Hiện đại', 'phòng khách, phòng ngủ, phòng ăn,..', 'Led (vàng, trung tính, trắng)', '220v', 'Hợp kim + acrylic', 'Mới 100%', '50000', '', 'Đèn vách', 720000.00, 900000.00, 'https://images.unsplash.com/photo-1524484485831-a92fa817b3f1?q=80&w=400'),
('Đèn vách DV02089', 'DV02089', 'Mỹ', 'phòng khách, phòng ngủ, phòng ăn,..', 'Led (vàng, trung tính, trắng)', '220v', 'Đồng + chao vải', 'Mới 100%', '50000', '', 'Đèn vách', 1600000.00, 2100000.00, 'https://images.unsplash.com/photo-1517991104123-1d56a6e81ed9?q=80&w=400'),
('Đèn vách DV02064', 'DV02064', 'Tân cổ điển', 'phòng khách, phòng ngủ, phòng ăn,..', 'Led (vàng, trung tính, trắng)', '220v', 'Đồng + chao vải', 'Mới 100%', '50000', '', 'Đèn vách', 1850000.00, 2400000.00, 'https://images.unsplash.com/photo-1540932239986-30128078f3c5?q=80&w=400'),
('Đèn vách DV02075', 'DV02075', 'Mỹ', 'phòng khách, phòng ngủ, phòng ăn,..', 'Led (vàng, trung tính, trắng)', '220v', 'Hợp kim + acrylic', 'Mới 100%', '50000', '', 'Đèn vách', 890000.00, 1150000.00, 'https://images.unsplash.com/photo-1565814329452-e1efa11c5e89?q=80&w=400'),
('Đèn vách DV02074', 'DV02074', 'Mỹ', 'phòng khách, phòng ngủ, phòng ăn,..', 'Led (vàng, trung tính, trắng)', '220v', 'Hợp kim + chao vải', 'Mới 100%', '50000', '', 'Đèn vách', 960000.00, 1250000.00, 'https://images.unsplash.com/photo-1513506003901-1e6a229e2d15?q=80&w=400'),
('Đèn vách DV02071', 'DV02071', 'Mỹ', 'nhà hàng, quán cafe, văn phòng, khách sạn,...', 'Led (vàng, trung tính, trắng)', '220v', 'Hợp kim + chao vải', 'Mới 100%', '50000', '', 'Đèn vách', 1050000.00, 1350000.00, 'https://images.unsplash.com/photo-1574180045827-681f8a1bef71?q=80&w=400'),
('Đèn vách DV02070', 'DV02070', 'Mỹ', 'nhà hàng, quán cafe, văn phòng, khách sạn,...', 'Led (vàng, trung tính, trắng)', '220v', 'Hợp kim', 'Mới 100%', '50000', '', 'Đèn vách', 820000.00, 1050000.00, 'https://images.unsplash.com/photo-1524484485831-a92fa817b3f1?q=80&w=400'),
('Đèn vách DV02056', 'DV02056', 'Hiện đại', 'nhà hàng, quán cafe, văn phòng, khách sạn,...', 'Led (vàng, trung tính, trắng)', '220v', 'Hợp kim + acrylic', 'Mới 100%', '50000', '', 'Đèn vách', 710000.00, 920000.00, 'https://images.unsplash.com/photo-1517991104123-1d56a6e81ed9?q=80&w=400'),
('Đèn vách DV02054', 'DV02054', 'Hiện đại', 'phòng khách, phòng ngủ, phòng ăn,..', 'Led (vàng, trung tính, trắng)', '220v', 'Hợp kim', 'Mới 100%', '50000', '', 'Đèn vách', 650000.00, 850000.00, 'https://images.unsplash.com/photo-1540932239986-30128078f3c5?q=80&w=400');

-- ====================================
-- BẢNG MỞ RỘNG
-- ====================================
CREATE TABLE IF NOT EXISTS settings (
    setting_key VARCHAR(50) PRIMARY KEY,
    setting_value MEDIUMTEXT
);

INSERT INTO settings (setting_key, setting_value) VALUES 
('shop_name', 'ĐÈN HOA MỸ'),
('logo_url', ''),
('banner_url', ''),
('hotline', '0912345678'),
('email', 'hieu.it@denhoamy.com'),
('address', 'Hải Phòng, Việt Nam');

CREATE TABLE IF NOT EXISTS reviews (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT,
    user_id INT NULL,
    user_name VARCHAR(255),
    rating INT DEFAULT 5,
    comment TEXT,
    is_approved BOOLEAN DEFAULT 0,
    reply TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS inventory_history (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT,
    variant_id INT NULL,
    admin_id INT NULL,
    type ENUM('in', 'out') DEFAULT 'in',
    quantity INT,
    cost DECIMAL(15,0) DEFAULT 0,
    note TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    FOREIGN KEY (variant_id) REFERENCES product_variants(id) ON DELETE SET NULL,
    FOREIGN KEY (admin_id) REFERENCES admins(id) ON DELETE SET NULL
);

-- ====================================
-- BẢNG THANH TOÁN (PAYMENTS)
-- ====================================
CREATE TABLE IF NOT EXISTS payments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    payment_code VARCHAR(255) NULL,
    amount DECIMAL(15,0) NOT NULL,
    method ENUM('cod', 'bank_transfer', 'momo', 'vnpay', 'payos', 'pay_at_store') DEFAULT 'cod',
    status ENUM('pending', 'completed', 'failed', 'refunded') DEFAULT 'pending',
    evidence_url LONGTEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE
);

-- ====================================
-- BẢNG TIN TỨC / BÀI VIẾT (NEWS)
-- ====================================
CREATE TABLE IF NOT EXISTS news (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    slug VARCHAR(255) UNIQUE NOT NULL,
    thumbnail LONGTEXT,
    summary TEXT,
    content LONGTEXT,
    author_id INT NULL,
    is_published BOOLEAN DEFAULT TRUE,
    view_count INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (author_id) REFERENCES admins(id) ON DELETE SET NULL
);

-- ====================================
-- BẢNG SẢN PHẨM YÊU THÍCH (WISHLISTS)
-- ====================================
CREATE TABLE IF NOT EXISTS wishlists (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    product_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_user_product (user_id, product_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
);

-- ====================================
-- BẢNG GIỎ HÀNG (CARTS)
-- ====================================
CREATE TABLE IF NOT EXISTS carts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NULL,
    session_id VARCHAR(255) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- ====================================
-- BẢNG CHI TIẾT GIỎ HÀNG (CART_ITEMS)
-- ====================================
CREATE TABLE IF NOT EXISTS cart_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    cart_id INT NOT NULL,
    product_id INT NOT NULL,
    variant_id INT NULL,
    quantity INT DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (cart_id) REFERENCES carts(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    FOREIGN KEY (variant_id) REFERENCES product_variants(id) ON DELETE SET NULL
);

-- ====================================
-- BẢNG QUẢN LÝ ẢNH SẢN PHẨM (PRODUCT_IMAGES)
-- ====================================
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
-- BẢNG KHO VOUCHER NGƯỜI DÙNG (USER_COUPONS)
-- ====================================
-- Lưu trữ các mã giảm giá mà khách hàng đã thu thập/sử dụng
-- Quan hệ: users (1) --- (N) user_coupons (N) --- (1) coupons
CREATE TABLE IF NOT EXISTS user_coupons (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL COMMENT 'Khách hàng sở hữu voucher',
    coupon_id INT NOT NULL COMMENT 'Mã giảm giá được lưu',
    status ENUM('unused', 'used', 'expired') DEFAULT 'unused' COMMENT 'unused = chưa dùng, used = đã dùng, expired = hết hạn',
    claimed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Thời điểm khách hàng lưu mã',
    used_at TIMESTAMP NULL COMMENT 'Thời điểm mã được sử dụng trong đơn hàng',
    order_id INT NULL COMMENT 'Đơn hàng đã áp dụng voucher này (nếu đã dùng)',
    UNIQUE KEY unique_user_coupon (user_id, coupon_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (coupon_id) REFERENCES coupons(id) ON DELETE CASCADE,
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE SET NULL
);

-- ====================================
-- BẢNG PHIÊN HỘI THOẠI CHATBOT (CHAT_SESSIONS)
-- ====================================
-- Lưu trữ các phiên trò chuyện giữa khách hàng và AI Chatbot
-- Quan hệ: users (1) --- (N) chat_sessions
CREATE TABLE IF NOT EXISTS chat_sessions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NULL COMMENT 'NULL nếu là khách vãng lai chưa đăng nhập',
    session_token VARCHAR(255) NOT NULL COMMENT 'Token định danh phiên chat trên trình duyệt',
    title VARCHAR(255) NULL COMMENT 'Tiêu đề phiên chat (lấy từ câu hỏi đầu tiên)',
    message_count INT DEFAULT 0 COMMENT 'Tổng số tin nhắn trong phiên',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_user_id (user_id),
    INDEX idx_session_token (session_token),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);

-- ====================================
-- BẢNG CHI TIẾT TIN NHẮN (CHAT_MESSAGES)
-- ====================================
-- Lưu trữ nội dung từng tin nhắn trong phiên trò chuyện
-- Quan hệ: chat_sessions (1) --- (N) chat_messages
CREATE TABLE IF NOT EXISTS chat_messages (
    id INT AUTO_INCREMENT PRIMARY KEY,
    session_id INT NOT NULL COMMENT 'Phiên chat chứa tin nhắn này',
    sender ENUM('user', 'bot') NOT NULL COMMENT 'user = khách hàng gửi, bot = AI trả lời',
    message TEXT NOT NULL COMMENT 'Nội dung tin nhắn',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_session_id (session_id),
    FOREIGN KEY (session_id) REFERENCES chat_sessions(id) ON DELETE CASCADE
);

-- ====================================
-- BẢNG TOKEN ĐẶT LẠI MẬT KHẨU (MAGIC LINK)
-- ====================================
CREATE TABLE IF NOT EXISTS password_reset_tokens (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    token_hash VARCHAR(64) NOT NULL,
    expires_at DATETIME NOT NULL,
    used_at DATETIME NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_token_hash (token_hash),
    INDEX idx_user_id (user_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- ====================================
-- MIGRATION: orders.updated_at (DB đã tồn tại — chạy thủ công một lần)
-- ====================================
-- ALTER TABLE orders ADD COLUMN updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP;
-- UPDATE orders SET updated_at = created_at WHERE updated_at IS NULL;