<?php
require_once 'db.php';
require_once __DIR__ . '/lib/auth_middleware.php';
require_once __DIR__ . '/lib/admin_route_guard.php';

$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'GET') {
    adminGuardAuto();
    $stmt = $pdo->query('
        SELECT i.*, p.ten_san_pham as product_name, p.ma_san_pham,
               pv.kich_thuoc, pv.anh_sang
        FROM inventory_history i 
        JOIN products p ON i.product_id = p.id 
        LEFT JOIN product_variants pv ON i.variant_id = pv.id
        ORDER BY i.created_at DESC
    ');
    echo json_encode(['success' => true, 'data' => $stmt->fetchAll(PDO::FETCH_ASSOC)]);
    exit();
}

if ($method === 'POST') {
    adminGuardAuto();
    $data = json_decode(file_get_contents('php://input'), true);
    if (!isset($data['product_id']) || !isset($data['quantity']) || !isset($data['cost'])) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Thiếu dữ liệu nhập kho']);
        exit();
    }

    $adminId = $data['admin_id'] ?? null;
    $variantId = isset($data['variant_id']) && $data['variant_id'] !== '' ? (int) $data['variant_id'] : null;
    $quantity = (int) $data['quantity'];
    $cost = $data['cost'];
    $note = $data['note'] ?? '';

    if ($quantity <= 0) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Số lượng nhập phải lớn hơn 0']);
        exit();
    }

    $pdo->beginTransaction();
    try {
        if ($variantId) {
            // Kiểm tra variant có thuộc product đang nhập hay không
            $variantCheck = $pdo->prepare('SELECT id FROM product_variants WHERE id = ? AND product_id = ?');
            $variantCheck->execute([$variantId, (int) $data['product_id']]);
            if (!$variantCheck->fetch(PDO::FETCH_ASSOC)) {
                throw new Exception('Biến thể không hợp lệ với sản phẩm đã chọn');
            }

            if ($adminId) {
                $stmt = $pdo->prepare('INSERT INTO inventory_history (product_id, variant_id, admin_id, type, quantity, cost, note) VALUES (?, ?, ?, "in", ?, ?, ?)');
                $stmt->execute([(int) $data['product_id'], $variantId, $adminId, $quantity, $cost, $note]);
            } else {
                $stmt = $pdo->prepare('INSERT INTO inventory_history (product_id, variant_id, type, quantity, cost, note) VALUES (?, ?, "in", ?, ?, ?)');
                $stmt->execute([(int) $data['product_id'], $variantId, $quantity, $cost, $note]);
            }

            // Cập nhật tồn + giá nhập theo biến thể
            $stmtUpdate = $pdo->prepare('UPDATE product_variants SET stock = stock + ?, cost_price = ? WHERE id = ?');
            $stmtUpdate->execute([$quantity, $cost, $variantId]);
        } else {
            if ($adminId) {
                $stmt = $pdo->prepare('INSERT INTO inventory_history (product_id, admin_id, type, quantity, cost, note) VALUES (?, ?, "in", ?, ?, ?)');
                $stmt->execute([(int) $data['product_id'], $adminId, $quantity, $cost, $note]);
            } else {
                $stmt = $pdo->prepare('INSERT INTO inventory_history (product_id, type, quantity, cost, note) VALUES (?, "in", ?, ?, ?)');
                $stmt->execute([(int) $data['product_id'], $quantity, $cost, $note]);
            }

            // Hành vi cũ cho sản phẩm không phân loại
            $stmtUpdate = $pdo->prepare('UPDATE products SET stock = stock + ?, cost_price = ? WHERE id = ?');
            $stmtUpdate->execute([$quantity, $cost, (int) $data['product_id']]);
        }

        $pdo->commit();
        echo json_encode(['success' => true, 'message' => 'Nhập kho thành công']);
    } catch (Exception $e) {
        $pdo->rollBack();
        echo json_encode(['success' => false, 'message' => 'Lỗi DB: ' . $e->getMessage()]);
    }
    exit();
}
http_response_code(405);
