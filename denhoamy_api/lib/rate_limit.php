<?php
// ============================================================
// MIDDLEWARE CHỐNG SPAM REQUEST (Rate Limiting)
// ============================================================
// Giới hạn số lượng request từ 1 IP trong khoảng thời gian nhất định.
// Dùng file-based storage (không cần Redis/Memcached).
//
// Cách sử dụng: require_once 'rate_limit.php'; ở đầu mỗi API endpoint
// Cấu hình: truyền tham số $maxRequests và $windowSeconds qua hàm checkRateLimit()
// ============================================================

/**
 * Kiểm tra rate limit cho IP hiện tại
 * @param int $maxRequests Số request tối đa cho phép trong $windowSeconds giây
 * @param int $windowSeconds Khoảng thời gian tính (giây)
 * @return void Tự trả về HTTP 429 nếu vượt giới hạn
 */
function checkRateLimit($maxRequests = 60, $windowSeconds = 60) {
    $ip = $_SERVER['REMOTE_ADDR'] ?? '0.0.0.0';
    // Tạo key duy nhất cho mỗi IP (loại bỏ ký tự đặc biệt)
    $safeIp = preg_replace('/[^a-zA-Z0-9_\-\.]/', '_', $ip);
    
    // Lưu file rate limit vào thư mục tạm
    $rateLimitDir = sys_get_temp_dir() . '/rate_limit';
    if (!is_dir($rateLimitDir)) {
        @mkdir($rateLimitDir, 0777, true);
    }
    
    $filePath = $rateLimitDir . '/' . $safeIp . '.json';
    $now = time();
    
    // Đọc dữ liệu hiện tại
    $data = ['requests' => [], 'blocked_until' => 0];
    if (file_exists($filePath)) {
        $content = @file_get_contents($filePath);
        if ($content) {
            $data = json_decode($content, true) ?: $data;
        }
    }
    
    // Kiểm tra xem IP có đang bị block không
    if (!empty($data['blocked_until']) && $now < $data['blocked_until']) {
        $retryAfter = $data['blocked_until'] - $now;
        http_response_code(429);
        header("Retry-After: $retryAfter");
        echo json_encode([
            'success' => false,
            'message' => "Bạn đã gửi quá nhiều yêu cầu. Vui lòng thử lại sau {$retryAfter} giây."
        ]);
        exit();
    }
    
    // Lọc bỏ các request cũ (ngoài khung thời gian)
    $windowStart = $now - $windowSeconds;
    $data['requests'] = array_values(array_filter($data['requests'], function($timestamp) use ($windowStart) {
        return $timestamp >= $windowStart;
    }));
    
    // Kiểm tra số lượng request
    if (count($data['requests']) >= $maxRequests) {
        // Vượt giới hạn → Block IP trong 1 phút
        $blockDuration = 60; // 60 giây
        $data['blocked_until'] = $now + $blockDuration;
        @file_put_contents($filePath, json_encode($data), LOCK_EX);
        
        http_response_code(429);
        header("Retry-After: $blockDuration");
        echo json_encode([
            'success' => false,
            'message' => "Quá nhiều yêu cầu! Vui lòng thử lại sau {$blockDuration} giây."
        ]);
        exit();
    }
    
    // Ghi nhận request mới
    $data['requests'][] = $now;
    $data['blocked_until'] = 0;
    @file_put_contents($filePath, json_encode($data), LOCK_EX);
}

/**
 * Rate limit nghiêm ngặt cho các API nhạy cảm (Login, Forgot Password)
 * Chỉ cho phép 5 lần/phút
 */
function checkStrictRateLimit() {
    checkRateLimit(5, 60);
}

/**
 * Rate limit thường cho các API đọc dữ liệu (GET)
 * Cho phép 120 lần/phút
 */
function checkNormalRateLimit() {
    checkRateLimit(120, 60);
}

/**
 * Rate limit cho Chatbot AI (Groq) — tránh spam / tốn quota
 * 30 tin nhắn / phút / IP
 */
function checkChatbotRateLimit() {
    checkRateLimit(30, 60);
}

/**
 * Dọn dẹp các file rate limit quá cũ (chạy định kỳ)
 * Xóa các file không được cập nhật trong 1 giờ qua
 */
function cleanupRateLimitFiles() {
    $rateLimitDir = sys_get_temp_dir() . '/rate_limit';
    if (!is_dir($rateLimitDir)) return;
    
    $files = glob($rateLimitDir . '/*.json');
    $oneHourAgo = time() - 3600;
    
    foreach ($files as $file) {
        if (filemtime($file) < $oneHourAgo) {
            @unlink($file);
        }
    }
}
