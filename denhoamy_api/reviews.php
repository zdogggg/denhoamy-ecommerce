<?php
require_once 'db.php';
require_once __DIR__ . '/lib/auth_middleware.php';
require_once __DIR__ . '/lib/validator.php';
require_once __DIR__ . '/lib/admin_route_guard.php';

$method = $_SERVER['REQUEST_METHOD'];

// Lấy danh sách đánh giá
if ($method === 'GET') {
    // Lọc theo product_id nếu cần
    $productId = isset($_GET['product_id']) ? $_GET['product_id'] : null;

    if ($productId) {
        $stmt = $pdo->prepare('SELECT id, product_id, user_name, rating, comment, reply, created_at FROM reviews WHERE product_id = ? AND is_approved = 1 ORDER BY created_at DESC');
        $stmt->execute([$productId]);
    } else {
        adminGuardRequire('reviews');
        $stmt = $pdo->prepare('
            SELECT r.*, p.ten_san_pham as product_name, p.image_url 
            FROM reviews r 
            LEFT JOIN products p ON r.product_id = p.id 
            ORDER BY r.created_at DESC
        ');
        $stmt->execute();
    }

    echo json_encode(['success' => true, 'data' => $stmt->fetchAll(PDO::FETCH_ASSOC)]);
    exit();
}

// Thêm đánh giá mới (người dùng)
if ($method === 'POST') {
    $data = json_decode(file_get_contents('php://input'), true);

    // === Input Validation ===
    $errors = validateReview($data);
    if (!empty($errors)) {
        respondValidationError($errors);
    }

    // === Sanitize ===
    $userName = sanitizeString($data['user_name'] ?? 'Khách Ẩn Danh');
    $comment = sanitizeString($data['comment']);
    $rating = max(1, min(5, sanitizeInt($data['rating'] ?? 5)));

    $stmt = $pdo->prepare('INSERT INTO reviews (product_id, user_name, rating, comment, is_approved) VALUES (?, ?, ?, ?, 0)');
    $stmt->execute([
        sanitizeInt($data['product_id']),
        $userName,
        $rating,
        $comment
    ]);

    echo json_encode(['success' => true, 'message' => 'Đánh giá thành công. Chờ Admin duyệt.']);
    exit();
}

// Cập nhật duyệt/trả lời
if ($method === 'PUT') {
    adminGuardAuto();
    $data = json_decode(file_get_contents('php://input'), true);
    if (!isset($data['id'])) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Thiếu ID']);
        exit();
    }

    if (isset($data['is_approved'])) {
        $stmt = $pdo->prepare('UPDATE reviews SET is_approved = ? WHERE id = ?');
        $stmt->execute([$data['is_approved'], $data['id']]);
    }
    if (isset($data['reply'])) {
        $stmt = $pdo->prepare('UPDATE reviews SET reply = ? WHERE id = ?');
        $stmt->execute([$data['reply'], $data['id']]);
    }

    echo json_encode(['success' => true, 'message' => 'Cập nhật thành công']);
    exit();
}

// Xoá
if ($method === 'DELETE') {
    // === Middleware: Yêu cầu quyền Admin ===
    adminGuardAuto();

    $id = isset($_GET['id']) ? $_GET['id'] : null;
    if (!$id) {
        $data = json_decode(file_get_contents('php://input'), true);
        $id = $data['id'] ?? null;
    }

    if ($id) {
        $stmt = $pdo->prepare('DELETE FROM reviews WHERE id = ?');
        $stmt->execute([$id]);
        echo json_encode(['success' => true, 'message' => 'Đã xoá đánh giá']);
    } else {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Thiếu ID']);
    }
    exit();
}

http_response_code(405);
echo json_encode(['success' => false, 'message' => 'Method not allowed']);
