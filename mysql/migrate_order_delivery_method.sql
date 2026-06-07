-- Thêm phương thức nhận hàng cho đơn hàng (email xác nhận)
ALTER TABLE orders
  ADD COLUMN delivery_method ENUM('home', 'store') NOT NULL DEFAULT 'home' AFTER address;
