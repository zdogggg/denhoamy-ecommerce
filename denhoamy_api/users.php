<?php
// ====================================
// API QUẢN LÝ NGƯỜI DÙNG & ADMIN - users.php
// Hỗ trợ 2 bảng: admins & users
// ====================================
require_once 'db.php';
require_once __DIR__ . '/lib/auth_middleware.php';
require_once __DIR__ . '/lib/validator.php';

$method = $_SERVER['REQUEST_METHOD'];
$scope = $_GET['scope'] ?? 'customers'; // 'customers' hoặc 'admins'

/**
 * Encode permissions array thành JSON string cho DB (một lần).
 */
function encodePermissionsForDb($raw)
{
    $normalized = normalizePermissions($raw);
    if ($normalized === null) {
        $normalized = getDefaultStaffPermissions();
    }
    return json_encode($normalized, JSON_UNESCAPED_UNICODE);
}

// ====== GET: Lấy danh sách ======
if ($method === 'GET') {
    if ($scope === 'admins') {
        requirePermission('accounts');
        $stmt = $pdo->prepare('SELECT id, username, role, name, email, phone, avatar_url, permissions, is_active, created_at FROM admins ORDER BY created_at DESC');
        $stmt->execute();
        echo json_encode(['success' => true, 'data' => $stmt->fetchAll(PDO::FETCH_ASSOC)]);
    } else {
        requirePermission('customers');
        $stmt = $pdo->prepare('SELECT id, username, name, email, phone, address, is_locked, created_at FROM users ORDER BY created_at DESC');
        $stmt->execute();
        $customers = $stmt->fetchAll(PDO::FETCH_ASSOC);
        foreach ($customers as &$c) {
            $c['role'] = $c['is_locked'] ? 'locked' : 'customer';
        }
        echo json_encode(['success' => true, 'data' => $customers]);
    }
    exit();
}

// ====== POST: Thêm admin mới ======
if ($method === 'POST') {
    $authUser = requireAdmin();
    $data = json_decode(file_get_contents('php://input'), true);

    $errors = validateCreateAdmin($data);
    if (!empty($errors)) {
        respondValidationError($errors);
    }

    $role = $data['role'] ?? 'staff';
    if ($role === 'admin') {
        requireSuperAdmin();
    } else {
        if ($authUser['role'] === 'staff' && $role === 'admin') {
            http_response_code(403);
            echo json_encode(['success' => false, 'message' => 'Bạn không có quyền tạo tài khoản Admin.']);
            exit();
        }
        requirePermission('accounts');
    }

    $clean = sanitizeInput($data, [
        'username' => 'string',
        'name' => 'string',
        'phone' => 'phone',
        'email' => 'email'
    ]);
    $username = $clean['username'];
    $password = $data['password'] ?? '';
    $name = $clean['name'];
    $phone = $clean['phone'];
    $email = $clean['email'];

    $stmt = $pdo->prepare('SELECT id FROM admins WHERE username = ?');
    $stmt->execute([$username]);
    if ($stmt->fetch()) {
        echo json_encode(['success' => false, 'message' => 'Tên đăng nhập đã tồn tại!']);
        exit();
    }

    $hashedPassword = password_hash($password, PASSWORD_DEFAULT);
    $permissions = null;
    if ($role === 'staff') {
        $permissions = encodePermissionsForDb($data['permissions'] ?? null);
    }

    $stmt = $pdo->prepare('INSERT INTO admins (username, role, password, name, phone, email, permissions) VALUES (?, ?, ?, ?, ?, ?, ?)');
    $stmt->execute([$username, $role, $hashedPassword, $name, $phone, $email, $permissions]);

    echo json_encode(['success' => true, 'message' => ($role === 'admin' ? 'Tạo tài khoản Admin' : 'Tạo tài khoản Nhân viên') . ' thành công!']);
    exit();
}

// ====== PUT: Cập nhật trạng thái ======
if ($method === 'PUT') {
    $data = json_decode(file_get_contents('php://input'), true);

    if (!isset($data['id'])) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Thiếu ID']);
        exit();
    }

    $target = $data['target'] ?? 'customer';
    $targetId = (int) $data['id'];

    if ($target === 'profile') {
        $authUser = requireLogin();
        if ($authUser['role'] !== 'customer' || $targetId !== (int) $authUser['id']) {
            http_response_code(403);
            echo json_encode(['success' => false, 'message' => 'Bạn không có quyền cập nhật hồ sơ này.']);
            exit();
        }
        $stmt = $pdo->prepare('UPDATE users SET name = ?, email = ?, phone = ?, address = ? WHERE id = ?');
        $stmt->execute([$data['name'], $data['email'] ?? '', $data['phone'] ?? '', $data['address'] ?? '', $targetId]);
        echo json_encode(['success' => true, 'message' => 'Cập nhật thông tin thành công']);
        exit();
    }

    if ($target === 'admin') {
        $authUser = requireAdmin();

        $sensitiveFields = ['role', 'permissions', 'password'];
        $hasSensitive = false;
        foreach ($sensitiveFields as $field) {
            if ($field === 'password') {
                if (!empty($data['password'])) {
                    $hasSensitive = true;
                    break;
                }
            } elseif (isset($data[$field])) {
                $hasSensitive = true;
                break;
            }
        }

        if ($hasSensitive) {
            requireSuperAdmin();
        } else {
            requirePermission('accounts');
        }

        if (isset($data['is_active'])) {
            if ($targetId === 1 && (int) $data['is_active'] === 0) {
                http_response_code(403);
                echo json_encode(['success' => false, 'message' => 'Không thể vô hiệu hóa tài khoản Admin gốc!']);
                exit();
            }
            $stmt = $pdo->prepare('UPDATE admins SET is_active = ? WHERE id = ?');
            $stmt->execute([$data['is_active'], $targetId]);
        }
        if (isset($data['name'])) {
            $stmt = $pdo->prepare('UPDATE admins SET name = ?, phone = ?, email = ? WHERE id = ?');
            $stmt->execute([$data['name'], $data['phone'] ?? '', $data['email'] ?? '', $targetId]);
        }
        if (isset($data['permissions'])) {
            $permsJson = encodePermissionsForDb($data['permissions']);
            $stmt = $pdo->prepare('UPDATE admins SET permissions = ? WHERE id = ?');
            $stmt->execute([$permsJson, $targetId]);
        }
        if (isset($data['role'])) {
            $stmt = $pdo->prepare('UPDATE admins SET role = ? WHERE id = ?');
            $stmt->execute([$data['role'], $targetId]);
        }
        if (isset($data['password']) && !empty($data['password'])) {
            $hashedPassword = password_hash($data['password'], PASSWORD_DEFAULT);
            $stmt = $pdo->prepare('UPDATE admins SET password = ? WHERE id = ?');
            $stmt->execute([$hashedPassword, $targetId]);
        }
        echo json_encode(['success' => true, 'message' => 'Cập nhật Admin thành công']);
        exit();
    }

    // Cập nhật khách hàng: khoá/mở khoá
    requirePermission('customers');
    if (isset($data['role'])) {
        $isLocked = ($data['role'] === 'locked') ? 1 : 0;
        $stmt = $pdo->prepare('UPDATE users SET is_locked = ? WHERE id = ?');
        $stmt->execute([$isLocked, $targetId]);
    }
    echo json_encode(['success' => true, 'message' => 'Cập nhật trạng thái người dùng thành công']);
    exit();
}

// ====== DELETE: Xoá admin ======
if ($method === 'DELETE') {
    requireSuperAdmin();

    $id = $_GET['id'] ?? null;
    if (!$id) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Thiếu ID']);
        exit();
    }

    if ($id == 1) {
        echo json_encode(['success' => false, 'message' => 'Không thể xoá tài khoản Admin gốc!']);
        exit();
    }

    $stmt = $pdo->prepare('DELETE FROM admins WHERE id = ?');
    $stmt->execute([$id]);
    echo json_encode(['success' => true, 'message' => 'Đã xoá Admin']);
    exit();
}

http_response_code(405);
echo json_encode(['success' => false, 'message' => 'Method not allowed']);
