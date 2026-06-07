<?php
// ====================================
// API YÊU THÍCH SẢN PHẨM - wishlist.php
// ====================================
require_once 'db.php';
require_once __DIR__ . '/lib/auth_middleware.php';

$method = $_SERVER['REQUEST_METHOD'];

/**
 * Chỉ khách hàng (bảng users) được dùng wishlist.
 */
function requireCustomerUser()
{
    $user = requireLogin();
    if (($user['role'] ?? '') !== 'customer') {
        http_response_code(403);
        echo json_encode([
            'success' => false,
            'message' => 'Chức năng yêu thích chỉ dành cho tài khoản khách hàng.'
        ]);
        exit();
    }
    return $user;
}

// ====== GET: Lấy danh sách sản phẩm yêu thích ======
if ($method === 'GET') {
    $authUser = requireCustomerUser();
    $userId = (int) $authUser['id'];

    $stmt = $pdo->prepare('
        SELECT p.*, w.created_at as liked_at 
        FROM wishlists w 
        JOIN products p ON w.product_id = p.id 
        WHERE w.user_id = ? 
        ORDER BY w.id DESC
    ');
    $stmt->execute([$userId]);
    $wishlists = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode(['success' => true, 'data' => $wishlists]);
    exit();
}

// ====== POST: Thêm / Bỏ yêu thích ======
if ($method === 'POST') {
    $authUser = requireCustomerUser();
    $userId = (int) $authUser['id'];

    $data = json_decode(file_get_contents('php://input'), true);
    $product_id = $data['product_id'] ?? null;

    if (!$product_id) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Thiếu mã sản phẩm']);
        exit();
    }

    $check = $pdo->prepare('SELECT id FROM wishlists WHERE user_id = ? AND product_id = ?');
    $check->execute([$userId, $product_id]);
    $exists = $check->fetch();

    if ($exists) {
        $del = $pdo->prepare('DELETE FROM wishlists WHERE id = ?');
        $del->execute([$exists['id']]);
        echo json_encode(['success' => true, 'action' => 'removed', 'message' => 'Đã bỏ yêu thích']);
    } else {
        $ins = $pdo->prepare('INSERT INTO wishlists (user_id, product_id) VALUES (?, ?)');
        $ins->execute([$userId, $product_id]);
        echo json_encode(['success' => true, 'action' => 'added', 'message' => 'Đã thêm vào mục yêu thích']);
    }
    exit();
}

http_response_code(405);
echo json_encode(['success' => false, 'message' => 'Method not allowed']);
