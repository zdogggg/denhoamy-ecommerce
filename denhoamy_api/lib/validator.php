<?php
// =====================================================
// INPUT VALIDATION TẬP TRUNG - validator.php
// =====================================================
// Cung cấp các hàm validate & sanitize dữ liệu đầu vào
// để chống XSS, SQL Injection, và đảm bảo dữ liệu hợp lệ.
//
// Sử dụng:
//   require_once 'validator.php';
//   $errors = validateOrder($data);
//   if (!empty($errors)) { ... trả về lỗi ... }
// =====================================================

// ====== SANITIZE: Làm sạch dữ liệu ======

/**
 * Làm sạch chuỗi: trim + strip HTML tags + chống XSS
 */
function sanitizeString($value)
{
    if ($value === null)
        return '';
    return htmlspecialchars(trim(strip_tags($value)), ENT_QUOTES, 'UTF-8');
}

/**
 * Làm sạch email
 */
function sanitizeEmail($value)
{
    if ($value === null)
        return '';
    return filter_var(trim($value), FILTER_SANITIZE_EMAIL);
}

/**
 * Làm sạch số nguyên
 */
function sanitizeInt($value)
{
    return intval($value);
}

/**
 * Làm sạch số thực (giá tiền...)
 */
function sanitizeFloat($value)
{
    return floatval($value);
}

/**
 * Làm sạch số điện thoại (chỉ giữ số và dấu +)
 */
function sanitizePhone($value)
{
    if ($value === null)
        return '';
    return preg_replace('/[^0-9+]/', '', trim($value));
}


// ====== VALIDATE: Kiểm tra dữ liệu ======

/**
 * Kiểm tra chuỗi bắt buộc
 */
function isRequired($value)
{
    return $value !== null && trim($value) !== '';
}

/**
 * Kiểm tra email hợp lệ
 */
function isValidEmail($value)
{
    if (empty($value))
        return true; // Email có thể không bắt buộc
    return filter_var($value, FILTER_VALIDATE_EMAIL) !== false;
}

/**
 * Kiểm tra SĐT Việt Nam (10 số, bắt đầu bằng 0)
 */
function isValidPhone($value)
{
    if (empty($value))
        return false;
    return preg_match('/^0[0-9]{9}$/', $value);
}

/**
 * Kiểm tra độ dài chuỗi
 */
function isLengthBetween($value, $min, $max)
{
    $len = mb_strlen($value, 'UTF-8');
    return $len >= $min && $len <= $max;
}

/**
 * Kiểm tra mật khẩu đủ mạnh (tối thiểu 6 ký tự)
 */
function isValidPassword($value)
{
    return mb_strlen($value, 'UTF-8') >= 6;
}

/**
 * Kiểm tra giá trị có phải số dương
 */
function isPositiveNumber($value)
{
    return is_numeric($value) && $value > 0;
}


// ====== VALIDATE CỤ THỂ CHO TỪNG MODULE ======

/**
 * Kiểm tra combo phương thức nhận hàng + thanh toán.
 * @return string|null Thông báo lỗi hoặc null nếu hợp lệ
 */
function validateOrderPaymentCombo($deliveryMethod, $paymentMethod)
{
    $delivery = in_array($deliveryMethod ?? '', ['home', 'store'], true) ? $deliveryMethod : 'home';
    $payment = $paymentMethod ?: 'cod';

    $allowed = [
        'home' => ['cod', 'payos'],
        'store' => ['pay_at_store', 'payos'],
    ];

    if (!in_array($payment, $allowed[$delivery], true)) {
        return $delivery === 'store'
            ? 'Phương thức thanh toán không hợp lệ cho đơn nhận tại cửa hàng'
            : 'Phương thức thanh toán không hợp lệ cho đơn giao tận nhà';
    }

    return null;
}

/**
 * Validate dữ liệu đơn hàng (Checkout)
 * @return array Mảng lỗi (rỗng = hợp lệ)
 */
function validateOrder($data)
{
    $errors = [];

    if (!isRequired($data['name'] ?? '')) {
        $errors[] = 'Họ tên không được để trống';
    }
    if (!isValidPhone($data['phone'] ?? '')) {
        $errors[] = 'Số điện thoại không hợp lệ (10 số, bắt đầu bằng 0)';
    }
    if (!isRequired($data['address'] ?? '')) {
        $errors[] = 'Địa chỉ giao hàng không được để trống';
    }
    if (!empty($data['email']) && !isValidEmail($data['email'])) {
        $errors[] = 'Email không đúng định dạng';
    }
    if (!empty($data['deliveryMethod']) && !in_array($data['deliveryMethod'], ['home', 'store'], true)) {
        $errors[] = 'Phương thức nhận hàng không hợp lệ';
    }
    $paymentComboError = validateOrderPaymentCombo(
        $data['deliveryMethod'] ?? 'home',
        $data['paymentMethod'] ?? 'cod'
    );
    if ($paymentComboError !== null) {
        $errors[] = $paymentComboError;
    }
    if (empty($data['items']) || !is_array($data['items']) || count($data['items']) === 0) {
        $errors[] = 'Giỏ hàng trống, không thể đặt hàng';
    }
    if (!isset($data['total']) || !is_numeric($data['total']) || (float) $data['total'] < 0) {
        $errors[] = 'Tổng tiền không hợp lệ';
    }

    return $errors;
}

/**
 * Validate dữ liệu đăng ký tài khoản
 * @return array Mảng lỗi
 */
function validateRegistration($data)
{
    $errors = [];

    if (!isRequired($data['name'] ?? '')) {
        $errors[] = 'Họ tên không được để trống';
    }
    if (!isValidPhone($data['phone'] ?? '')) {
        $errors[] = 'Số điện thoại không hợp lệ (10 số, bắt đầu bằng 0)';
    }
    if (!isRequired($data['password'] ?? '')) {
        $errors[] = 'Mật khẩu không được để trống';
    } elseif (!isValidPassword($data['password'])) {
        $errors[] = 'Mật khẩu phải có ít nhất 6 ký tự';
    }
    if (!empty($data['email']) && !isValidEmail($data['email'])) {
        $errors[] = 'Email không đúng định dạng';
    }

    return $errors;
}

/**
 * Validate dữ liệu đăng nhập
 * @return array Mảng lỗi
 */
function validateLogin($data)
{
    $errors = [];

    if (!isRequired($data['username'] ?? '')) {
        $errors[] = 'Tên đăng nhập không được để trống';
    }
    if (!isRequired($data['password'] ?? '')) {
        $errors[] = 'Mật khẩu không được để trống';
    }

    return $errors;
}

/**
 * Validate dữ liệu đánh giá sản phẩm
 * @return array Mảng lỗi
 */
function validateReview($data)
{
    $errors = [];

    if (!isset($data['product_id']) || !isPositiveNumber($data['product_id'])) {
        $errors[] = 'Thiếu ID sản phẩm';
    }
    if (!isRequired($data['comment'] ?? '')) {
        $errors[] = 'Nội dung đánh giá không được để trống';
    }
    if (isset($data['rating']) && ($data['rating'] < 1 || $data['rating'] > 5)) {
        $errors[] = 'Đánh giá phải từ 1 đến 5 sao';
    }

    return $errors;
}

/**
 * Validate dữ liệu tạo Admin/Staff
 * @return array Mảng lỗi
 */
function validateCreateAdmin($data)
{
    $errors = [];

    if (!isRequired($data['username'] ?? '')) {
        $errors[] = 'Tên đăng nhập không được để trống';
    } elseif (!isLengthBetween($data['username'], 3, 50)) {
        $errors[] = 'Tên đăng nhập phải từ 3-50 ký tự';
    }
    if (!isRequired($data['password'] ?? '')) {
        $errors[] = 'Mật khẩu không được để trống';
    } elseif (!isValidPassword($data['password'])) {
        $errors[] = 'Mật khẩu phải có ít nhất 6 ký tự';
    }
    if (!isRequired($data['name'] ?? '')) {
        $errors[] = 'Họ tên không được để trống';
    }

    return $errors;
}

/**
 * Validate dữ liệu bài viết
 * @return array Mảng lỗi
 */
function validateNews($data)
{
    $errors = [];

    if (!isRequired($data['title'] ?? '')) {
        $errors[] = 'Tiêu đề không được để trống';
    }
    if (!isRequired($data['slug'] ?? '')) {
        $errors[] = 'Đường dẫn (slug) không được để trống';
    }
    if (!isRequired($data['content'] ?? '')) {
        $errors[] = 'Nội dung bài viết không được để trống';
    }

    return $errors;
}

/**
 * Helper: Trả về lỗi validation dạng JSON + HTTP 422
 * @param array $errors Mảng lỗi
 */
function respondValidationError($errors)
{
    http_response_code(422);
    echo json_encode([
        'success' => false,
        'message' => $errors[0], // Lỗi đầu tiên (cho frontend hiện toast)
        'errors' => $errors       // Toàn bộ lỗi (cho debug)
    ]);
    exit();
}

/**
 * Helper: Sanitize toàn bộ dữ liệu đầu vào
 * Áp dụng sanitizeString cho tất cả các trường string
 * 
 * @param array $data Dữ liệu gốc
 * @param array $rules Quy tắc: ['field' => 'string|email|phone|int|float|raw']
 * @return array Dữ liệu đã làm sạch
 */
function sanitizeInput($data, $rules)
{
    $clean = [];
    foreach ($rules as $field => $type) {
        $value = $data[$field] ?? null;
        switch ($type) {
            case 'email':
                $clean[$field] = sanitizeEmail($value);
                break;
            case 'phone':
                $clean[$field] = sanitizePhone($value);
                break;
            case 'int':
                $clean[$field] = sanitizeInt($value);
                break;
            case 'float':
                $clean[$field] = sanitizeFloat($value);
                break;
            case 'raw':
                // Không sanitize (dùng cho HTML content như bài viết)
                $clean[$field] = $value;
                break;
            default: // 'string'
                $clean[$field] = sanitizeString($value);
                break;
        }
    }
    return $clean;
}
