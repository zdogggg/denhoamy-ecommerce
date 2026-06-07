<?php
// =====================================================
// JWT HELPER - jwt_helper.php
// =====================================================
// Tạo và xác thực JSON Web Token (JWT) bằng HMAC-SHA256.
// Không cần thư viện bên ngoài, sử dụng hàm PHP built-in.
//
// JWT gồm 3 phần: Header.Payload.Signature
//   - Header: {"alg":"HS256","typ":"JWT"}
//   - Payload: {"sub": user_id, "role": "admin", "iat": ..., "exp": ...}
//   - Signature: HMAC-SHA256(header.payload, secret)
//
// Sử dụng:
//   require_once 'jwt_helper.php';
//   $token = jwtEncode(['sub' => 1, 'role' => 'admin']);
//   $payload = jwtDecode($token); // null nếu không hợp lệ
// =====================================================

// Lấy secret key từ biến môi trường (bắt buộc phải đặt trong .env)
define('JWT_SECRET', getenv('JWT_SECRET') ?: 'denhoamy_default_secret_change_me_in_production');

// Thời gian hết hạn mặc định: 24 giờ (tính bằng giây)
define('JWT_EXPIRY', 86400);

// ====== BASE64URL ENCODE/DECODE ======
// JWT dùng Base64URL (thay + bằng -, / bằng _, bỏ padding =)

/**
 * Encode chuỗi sang Base64URL (chuẩn JWT)
 */
function base64UrlEncode($data)
{
    return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
}

/**
 * Decode chuỗi Base64URL về dạng gốc
 */
function base64UrlDecode($data)
{
    return base64_decode(strtr($data, '-_', '+/'));
}

// ====== TẠO JWT TOKEN ======

/**
 * Tạo JWT token từ payload
 * 
 * @param array $payload Dữ liệu cần mã hóa (sub, role, name, ...)
 * @param int $expiry Thời gian hết hạn (giây), mặc định JWT_EXPIRY
 * @return string JWT token (header.payload.signature)
 */
function jwtEncode($payload, $expiry = null)
{
    // Header: thuật toán HMAC-SHA256
    $header = [
        'alg' => 'HS256',
        'typ' => 'JWT'
    ];

    // Thêm timestamps vào payload
    $now = time();
    $payload['iat'] = $now;                          // Issued At: thời điểm tạo
    $payload['exp'] = $now + ($expiry ?? JWT_EXPIRY); // Expiration: thời điểm hết hạn

    // Encode header và payload
    $headerEncoded = base64UrlEncode(json_encode($header, JSON_UNESCAPED_UNICODE));
    $payloadEncoded = base64UrlEncode(json_encode($payload, JSON_UNESCAPED_UNICODE));

    // Tạo chữ ký số bằng HMAC-SHA256
    $signature = hash_hmac('sha256', "$headerEncoded.$payloadEncoded", JWT_SECRET, true);
    $signatureEncoded = base64UrlEncode($signature);

    // Ghép 3 phần: header.payload.signature
    return "$headerEncoded.$payloadEncoded.$signatureEncoded";
}

// ====== XÁC THỰC JWT TOKEN ======

/**
 * Giải mã và xác thực JWT token
 * 
 * @param string $token JWT token cần xác thực
 * @return array|null Payload nếu hợp lệ, null nếu không hợp lệ
 * 
 * Quy trình xác thực:
 *   1. Tách token thành 3 phần (header, payload, signature)
 *   2. Tính lại chữ ký từ header + payload + secret
 *   3. So sánh chữ ký (dùng hash_equals chống timing attack)
 *   4. Kiểm tra thời gian hết hạn (exp)
 */
function jwtDecode($token)
{
    // Kiểm tra format: phải có đúng 3 phần ngăn cách bởi dấu chấm
    $parts = explode('.', $token);
    if (count($parts) !== 3) {
        return null;
    }

    [$headerEncoded, $payloadEncoded, $signatureEncoded] = $parts;

    // Tính lại chữ ký để so sánh (verify signature)
    $expectedSignature = base64UrlEncode(
        hash_hmac('sha256', "$headerEncoded.$payloadEncoded", JWT_SECRET, true)
    );

    // So sánh chữ ký an toàn (chống timing attack)
    if (!hash_equals($expectedSignature, $signatureEncoded)) {
        return null; // Chữ ký không khớp → token bị giả mạo
    }

    // Decode payload
    $payload = json_decode(base64UrlDecode($payloadEncoded), true);
    if (!$payload) {
        return null; // Payload không phải JSON hợp lệ
    }

    // Kiểm tra hết hạn
    if (isset($payload['exp']) && time() > $payload['exp']) {
        return null; // Token đã hết hạn
    }

    return $payload;
}

/**
 * Tạo JWT token cho Admin/Staff
 * 
 * @param array $admin Dữ liệu admin từ database
 * @param string $role 'admin' hoặc 'staff'
 * @param array|null $permissions Quyền hạn (chỉ cho staff)
 * @return string JWT token
 */
function createAdminToken($admin, $role, $permissions = null)
{
    $payload = [
        'sub' => (int) $admin['id'],      // Subject: admin ID
        'role' => $role,                    // Role: admin | staff
        'name' => $admin['name'],           // Tên hiển thị
        'table' => 'admins'                 // Bảng nguồn (phân biệt admin vs user)
    ];

    if ($permissions !== null) {
        $payload['permissions'] = $permissions;
    }

    return jwtEncode($payload);
}

/**
 * Tạo JWT token cho Customer (khách hàng)
 * 
 * @param array $user Dữ liệu user từ database
 * @return string JWT token
 */
function createCustomerToken($user)
{
    return jwtEncode([
        'sub' => (int) $user['id'],        // Subject: user ID
        'role' => 'customer',               // Role: customer
        'name' => $user['name'],            // Tên hiển thị
        'table' => 'users'                  // Bảng nguồn
    ]);
}
