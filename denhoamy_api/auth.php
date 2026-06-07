<?php
// ====================================
// API ĐĂNG NHẬP / ĐĂNG KÝ - auth.php
// Hỗ trợ 2 bảng: admins (quản trị) & users (khách hàng)
// ====================================
require_once 'db.php';
require_once __DIR__ . '/lib/rate_limit.php';
require_once __DIR__ . '/lib/validator.php';
require_once __DIR__ . '/lib/jwt_helper.php';
require_once __DIR__ . '/lib/auth_middleware.php';
checkStrictRateLimit(); // Giới hạn 5 request/phút - chống brute force đăng nhập

$data = json_decode(file_get_contents('php://input'), true);
$action = $data['action'] ?? '';

// ====== ĐĂNG NHẬP ======
if ($action === 'login') {
    // === Input Validation ===
    $errors = validateLogin($data);
    if (!empty($errors)) {
        respondValidationError($errors);
    }

    $username = sanitizeString($data['username'] ?? '');
    $password = $data['password'] ?? ''; // Không sanitize password (cần giữ nguyên)

    // === 1. Kiểm tra trong bảng ADMINS trước ===
    $stmt = $pdo->prepare('SELECT id, username, password, role, name, phone, email, avatar_url, permissions, is_active FROM admins WHERE username = ?');
    $stmt->execute([$username]);
    $admin = $stmt->fetch();

    if ($admin && password_verify($password, $admin['password'])) {
        if (!$admin['is_active']) {
            echo json_encode(['success' => false, 'message' => 'Tài khoản đã bị vô hiệu hoá!']);
            exit();
        }

        // Xác định role: admin (toàn quyền) hoặc staff (giới hạn)
        // Tương thích ngược: nếu cột 'role' chưa tồn tại trong DB, mặc định là 'admin'
        $adminRole = array_key_exists('role', $admin) && $admin['role'] ? $admin['role'] : 'admin';
        $permissions = null;
        if ($adminRole === 'staff') {
            $permissions = normalizePermissions($admin['permissions'] ?? null);
            if ($permissions === null) {
                $permissions = getDefaultStaffPermissions();
            }
        }

        // Tạo JWT token cho admin/staff
        $token = createAdminToken($admin, $adminRole, $permissions);

        echo json_encode([
            'success' => true,
            'token' => $token,
            'user' => [
                'id' => $admin['id'],
                'username' => $admin['username'],
                'name' => $admin['name'],
                'phone' => $admin['phone'],
                'email' => $admin['email'],
                'avatar' => $admin['avatar_url'],
                'role' => $adminRole,
                'permissions' => $permissions
            ]
        ]);
        exit();
    }

    // === 2. Nếu không phải admin, kiểm tra bảng USERS (khách hàng) ===
    $stmt = $pdo->prepare('SELECT id, username, password, name, phone, email, address, is_locked FROM users WHERE username = ?');
    $stmt->execute([$username]);
    $user = $stmt->fetch();

    if ($user && password_verify($password, $user['password'])) {
        // Kiểm tra tài khoản bị khoá
        if ($user['is_locked']) {
            echo json_encode(['success' => false, 'message' => 'Tài khoản của bạn đã bị khoá do vi phạm!']);
            exit();
        }

        // Tạo JWT token cho customer
        $token = createCustomerToken($user);

        echo json_encode([
            'success' => true,
            'token' => $token,
            'user' => [
                'id' => $user['id'],
                'username' => $user['username'],
                'name' => $user['name'],
                'phone' => $user['phone'],
                'email' => $user['email'],
                'address' => $user['address'] ?? '',
                'role' => 'customer'
            ]
        ]);
        exit();
    }

    // === 3. Không tìm thấy ở cả 2 bảng ===
    echo json_encode(['success' => false, 'message' => 'Tài khoản hoặc mật khẩu không đúng!']);
    exit();
}

// ====== ĐĂNG KÝ (chỉ dành cho khách hàng) ======
if ($action === 'register') {
    // === Input Validation ===
    $errors = validateRegistration($data);
    if (!empty($errors)) {
        respondValidationError($errors);
    }

    // === Sanitize ===
    $clean = sanitizeInput($data, [
        'name' => 'string',
        'phone' => 'phone',
        'email' => 'email'
    ]);
    $name = $clean['name'];
    $phone = $clean['phone'];
    $email = $clean['email'];
    $password = $data['password'] ?? ''; // Không sanitize password

    // Kiểm tra SĐT đã tồn tại
    $stmt = $pdo->prepare('SELECT id FROM users WHERE phone = ?');
    $stmt->execute([$phone]);
    if ($stmt->fetch()) {
        echo json_encode(['success' => false, 'message' => 'Số điện thoại đã được đăng ký!']);
        exit();
    }

    // Tạo tài khoản khách hàng mới
    $hashedPassword = password_hash($password, PASSWORD_DEFAULT);
    $stmt = $pdo->prepare('INSERT INTO users (username, password, name, phone, email) VALUES (?, ?, ?, ?, ?)');
    $stmt->execute([$phone, $hashedPassword, $name, $phone, $email]);

    echo json_encode([
        'success' => true,
        'message' => 'Đăng ký thành công!'
    ]);
    exit();
}

// ====== ĐỔI MẬT KHẨU (admin / staff đang đăng nhập) ======
if ($action === 'change_password') {
    $authUser = requireAdmin();
    $currentPassword = $data['current_password'] ?? '';
    $newPassword = $data['new_password'] ?? '';

    if ($currentPassword === '' || $newPassword === '') {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Vui lòng nhập đầy đủ mật khẩu']);
        exit();
    }

    if (strlen($newPassword) < 6) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Mật khẩu mới phải có ít nhất 6 ký tự']);
        exit();
    }

    $stmt = $pdo->prepare('SELECT id, password FROM admins WHERE id = ?');
    $stmt->execute([(int) $authUser['id']]);
    $admin = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$admin || !password_verify($currentPassword, $admin['password'])) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Mật khẩu hiện tại không đúng']);
        exit();
    }

    $hashedPassword = password_hash($newPassword, PASSWORD_DEFAULT);
    $stmt = $pdo->prepare('UPDATE admins SET password = ? WHERE id = ?');
    $stmt->execute([$hashedPassword, (int) $authUser['id']]);

    echo json_encode(['success' => true, 'message' => 'Đổi mật khẩu thành công']);
    exit();
}

echo json_encode(['success' => false, 'message' => 'Action không hợp lệ']);
