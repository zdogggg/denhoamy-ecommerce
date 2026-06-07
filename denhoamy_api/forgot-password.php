<?php
// ====================================
// API QUÊN MẬT KHẨU - forgot-password.php
// Khách hàng: nhập SĐT → nhận magic link qua email đăng ký (Resend)
// ====================================
require_once 'db.php';
require_once __DIR__ . '/lib/rate_limit.php';
require_once __DIR__ . '/lib/validator.php';
require_once __DIR__ . '/lib/password_reset_helper.php';

checkStrictRateLimit();

$method = $_SERVER['REQUEST_METHOD'];

if ($method !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
    exit();
}

$data = json_decode(file_get_contents('php://input'), true) ?: [];
$action = $data['action'] ?? 'request';

// ====== YÊU CẦU GỬI LINK RESET ======
if ($action === 'request') {
    $phone = sanitizePhone($data['phone'] ?? '');

    if (!isValidPhone($phone)) {
        echo json_encode(['success' => false, 'message' => 'Số điện thoại không hợp lệ.']);
        exit();
    }

    $genericMessage = passwordResetRequestMessage();

    $stmt = $pdo->prepare('
        SELECT id, name, email, phone
        FROM users
        WHERE (phone = ? OR username = ?) AND is_locked = 0
        LIMIT 1
    ');
    $stmt->execute([$phone, $phone]);
    $user = $stmt->fetch();

    if ($user && !empty($user['email']) && isValidEmail($user['email'])) {
        try {
            $rawToken = createPasswordResetToken($pdo, $user['id']);

            if ($rawToken) {
                $frontendUrl = rtrim(getenv('FRONTEND_URL') ?: 'http://localhost:3000', '/');
                $resetUrl = $frontendUrl . '/reset-password?token=' . urlencode($rawToken);

                $mailResult = sendPasswordResetEmail($user['email'], $user['name'], $resetUrl);

                if ($mailResult['success']) {
                    logInfo('Password reset email sent', [
                        'user_id' => $user['id'],
                        'resend_id' => $mailResult['id'] ?? null
                    ]);
                } else {
                    logWarning('Password reset email failed', [
                        'user_id' => $user['id'],
                        'error' => $mailResult['message'] ?? 'unknown'
                    ]);
                }
            }
        } catch (Exception $e) {
            logException($e, ['action' => 'password_reset_request', 'phone' => $phone]);
        }
    } elseif ($user && empty($user['email'])) {
        logWarning('Password reset: user has no email', ['user_id' => $user['id']]);
    }

    echo json_encode([
        'success' => true,
        'message' => $genericMessage
    ]);
    exit();
}

// ====== ĐẶT LẠI MẬT KHẨU BẰNG TOKEN ======
if ($action === 'reset') {
    $rawToken = trim($data['token'] ?? '');
    $password = $data['password'] ?? '';
    $confirmPassword = $data['confirmPassword'] ?? $data['confirm_password'] ?? '';

    if (empty($rawToken)) {
        echo json_encode(['success' => false, 'message' => 'Link không hợp lệ.']);
        exit();
    }

    if (!isValidPassword($password)) {
        echo json_encode(['success' => false, 'message' => 'Mật khẩu phải có ít nhất 6 ký tự.']);
        exit();
    }

    if ($password !== $confirmPassword) {
        echo json_encode(['success' => false, 'message' => 'Mật khẩu xác nhận không khớp.']);
        exit();
    }

    $tokenRow = validatePasswordResetToken($pdo, $rawToken);

    if ($tokenRow === false) {
        echo json_encode([
            'success' => false,
            'message' => 'Link đặt lại mật khẩu không hợp lệ hoặc đã hết hạn. Vui lòng yêu cầu link mới.'
        ]);
        exit();
    }

    try {
        $hashed = password_hash($password, PASSWORD_DEFAULT);
        $pdo->prepare('UPDATE users SET password = ? WHERE id = ?')
            ->execute([$hashed, $tokenRow['user_id']]);

        markTokenUsed($pdo, $rawToken);

        logInfo('Password reset completed', ['user_id' => $tokenRow['user_id']]);

        echo json_encode([
            'success' => true,
            'message' => 'Đặt lại mật khẩu thành công! Bạn có thể đăng nhập bằng số điện thoại và mật khẩu mới.'
        ]);
    } catch (Exception $e) {
        logException($e, ['action' => 'password_reset_confirm', 'user_id' => $tokenRow['user_id'] ?? null]);
        echo json_encode(['success' => false, 'message' => 'Có lỗi xảy ra. Vui lòng thử lại.']);
    }
    exit();
}

echo json_encode(['success' => false, 'message' => 'Action không hợp lệ']);
