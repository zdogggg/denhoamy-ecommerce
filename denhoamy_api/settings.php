<?php
// ====================================
// API CÀI ĐẶT WEBSITE - settings.php
// ====================================
require_once 'db.php';
require_once __DIR__ . '/lib/auth_middleware.php';
require_once __DIR__ . '/lib/admin_route_guard.php';

$method = $_SERVER['REQUEST_METHOD'];

// Lấy tất cả settings
if ($method === 'GET') {
    $stmt = $pdo->prepare('SELECT setting_key, setting_value FROM settings');
    $stmt->execute();
    $data = $stmt->fetchAll(PDO::FETCH_KEY_PAIR);
    
    echo json_encode([
        'success' => true,
        'data' => $data
    ]);
    exit();
}

// Cập nhật settings
if ($method === 'PUT') {
    $data = json_decode(file_get_contents('php://input'), true);

    if (!is_array($data)) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Dữ liệu không hợp lệ']);
        exit();
    }

    $policyKeys = ['policy_bao_hanh', 'policy_doi_tra', 'policy_van_chuyen', 'policy_huong_dan'];
    $keys = array_keys($data);
    $onlyPolicyKeys = count($keys) > 0 && count(array_diff($keys, $policyKeys)) === 0;

    if ($onlyPolicyKeys) {
        adminGuardRequire('policy');
    } else {
        adminGuardRequire('settings');
    }

    $stmt = $pdo->prepare('INSERT INTO settings (setting_key, setting_value) VALUES (?, ?) ON DUPLICATE KEY UPDATE setting_value = ?');
    foreach ($data as $key => $value) {
        $stmt->execute([$key, $value, $value]);
    }

    echo json_encode(['success' => true, 'message' => 'Cập nhật cấu hình thành công']);
    exit();
}

http_response_code(405);
echo json_encode(['success' => false, 'message' => 'Method not allowed']);
