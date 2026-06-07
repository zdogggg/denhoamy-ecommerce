<?php
// =====================================================
// MIDDLEWARE XÁC THỰC JWT - auth_middleware.php
// =====================================================
// Xác thực request bằng JWT token (HMAC-SHA256).
// Frontend gửi header: Authorization: Bearer <jwt_token>
// Middleware xác thực chữ ký + thời hạn → trả về thông tin user
// =====================================================

require_once __DIR__ . '/jwt_helper.php';

/**
 * Parse Authorization header và trả về thông tin user.
 * Chỉ chấp nhận JWT token: Bearer eyJhbG...
 * 
 * @return array|null ['id' => int, 'role' => string] hoặc null nếu không hợp lệ
 */
function parseAuthHeader()
{
    // Lấy Authorization header (tương thích nhiều server)
    $authHeader = '';
    if (isset($_SERVER['HTTP_AUTHORIZATION'])) {
        $authHeader = $_SERVER['HTTP_AUTHORIZATION'];
    } elseif (isset($_SERVER['REDIRECT_HTTP_AUTHORIZATION'])) {
        $authHeader = $_SERVER['REDIRECT_HTTP_AUTHORIZATION'];
    } elseif (function_exists('apache_request_headers')) {
        $headers = apache_request_headers();
        $authHeader = $headers['Authorization'] ?? $headers['authorization'] ?? '';
    }

    if (empty($authHeader)) {
        return null;
    }

    // Tách "Bearer <token>"
    if (!preg_match('/^Bearer\s+(.+)$/i', $authHeader, $matches)) {
        return null;
    }

    $token = trim($matches[1]);

    // ====== GIẢI MÃ JWT ======
    // JWT token luôn có đúng 2 dấu chấm (header.payload.signature)
    if (substr_count($token, '.') === 2) {
        $payload = jwtDecode($token);
        if ($payload !== null) {
            return [
                'id' => (int) ($payload['sub'] ?? 0),
                'role' => $payload['role'] ?? 'customer',
                'name' => $payload['name'] ?? '',
                'table' => $payload['table'] ?? 'users',
                'permissions' => $payload['permissions'] ?? null,
                'jwt' => true
            ];
        }
    }

    // Token không hợp lệ (không phải JWT hoặc đã hết hạn/bị sửa đổi)
    return null;
}

/**
 * Yêu cầu đăng nhập (bất kỳ role nào).
 * Nếu chưa đăng nhập → trả 401 Unauthorized + dừng script.
 * 
 * @return array Thông tin user: ['id', 'role', ...]
 */
function requireLogin()
{
    $user = parseAuthHeader();
    if (!$user) {
        http_response_code(401);
        echo json_encode([
            'success' => false,
            'message' => 'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.'
        ]);
        exit();
    }
    return $user;
}

/**
 * Yêu cầu quyền Admin hoặc Staff.
 * Nếu không đủ quyền → trả 403 Forbidden + dừng script.
 * 
 * @return array Thông tin user: ['id', 'role', ...]
 */
function requireAdmin()
{
    $user = requireLogin(); // Phải đăng nhập trước

    if (!in_array($user['role'], ['admin', 'staff'])) {
        http_response_code(403);
        echo json_encode([
            'success' => false,
            'message' => 'Bạn không có quyền truy cập chức năng này.'
        ]);
        exit();
    }
    return $user;
}

/**
 * Yêu cầu quyền Admin (chỉ admin, không chấp nhận staff).
 * Dùng cho các thao tác nhạy cảm: xóa user, thay đổi cài đặt...
 * 
 * @return array Thông tin user: ['id', 'role', ...]
 */
function requireSuperAdmin()
{
    $user = requireLogin();

    if ($user['role'] !== 'admin') {
        http_response_code(403);
        echo json_encode([
            'success' => false,
            'message' => 'Chỉ Admin mới có quyền thực hiện thao tác này.'
        ]);
        exit();
    }
    return $user;
}

/**
 * Quyền mặc định cho nhân viên (staff).
 */
function getDefaultStaffPermissions()
{
    return [
        'dashboard' => true,
        'categories' => true,
        'products' => true,
        'orders' => true,
        'reviews' => true,
        'customers' => false,
        'coupons' => true,
        'news' => true,
        'policy' => true,
        'accounts' => false,
        'settings' => false
    ];
}

/**
 * Chuẩn hóa permissions từ DB hoặc request (xử lý double-encoded).
 *
 * @param mixed $raw
 * @return array|null
 */
function normalizePermissions($raw)
{
    if ($raw === null || $raw === '') {
        return null;
    }

    if (is_array($raw)) {
        return $raw;
    }

    if (!is_string($raw)) {
        return null;
    }

    $decoded = json_decode($raw, true);
    if (!is_array($decoded)) {
        return null;
    }

    // Dữ liệu cũ bị json_encode hai lần → decode thêm một lần
    if (is_string($decoded)) {
        $inner = json_decode($decoded, true);
        return is_array($inner) ? $inner : null;
    }

    return $decoded;
}

/**
 * Kiểm tra quyền chi tiết (admin bypass, staff theo JWT permissions).
 */
function hasPermission(array $user, string $key)
{
    if (($user['role'] ?? '') === 'admin') {
        return true;
    }

    if (($user['role'] ?? '') !== 'staff') {
        return false;
    }

    $permissions = $user['permissions'] ?? [];
    if (!is_array($permissions)) {
        $permissions = normalizePermissions($permissions) ?? [];
    }

    return !empty($permissions[$key]);
}

/**
 * Yêu cầu quyền chi tiết — admin bypass, staff phải có permission key.
 *
 * @return array Thông tin user
 */
function requirePermission(string $key)
{
    $user = requireAdmin();

    if (!hasPermission($user, $key)) {
        http_response_code(403);
        echo json_encode([
            'success' => false,
            'message' => 'Bạn không có quyền truy cập chức năng này.'
        ]);
        exit();
    }

    return $user;
}

/**
 * Lấy thông tin user hiện tại (không bắt buộc đăng nhập).
 * Dùng cho các API cần biết user nhưng vẫn cho phép anonymous.
 * 
 * @return array|null Thông tin user hoặc null
 */
function getCurrentUser()
{
    return parseAuthHeader();
}
