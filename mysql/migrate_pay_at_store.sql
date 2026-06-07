-- Thêm phương thức thanh toán tại cửa hàng cho bảng payments
ALTER TABLE payments
  MODIFY method ENUM('cod', 'bank_transfer', 'momo', 'vnpay', 'payos', 'pay_at_store') DEFAULT 'cod';
