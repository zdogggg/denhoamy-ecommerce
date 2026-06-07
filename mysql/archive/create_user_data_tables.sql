-- ====================================
-- MIGRATION: KHO DỮ LIỆU NGƯỜI DÙNG
-- Ngày tạo: 2026-05-20
-- Mô tả: Thêm bảng Kho Voucher (user_coupons),
--         Phiên hội thoại Chatbot (chat_sessions),
--         Chi tiết tin nhắn (chat_messages)
-- ====================================
USE denhoamy_db;

-- ====================================
-- 1. BẢNG KHO VOUCHER NGƯỜI DÙNG (USER_COUPONS)
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
-- 2. BẢNG PHIÊN HỘI THOẠI CHATBOT (CHAT_SESSIONS)
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
-- 3. BẢNG CHI TIẾT TIN NHẮN (CHAT_MESSAGES)
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
