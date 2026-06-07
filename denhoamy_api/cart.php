<?php
// ====================================
// API GIỎ HÀNG - cart.php
// ====================================
require_once 'db.php';
require_once __DIR__ . '/lib/auth_middleware.php';
require_once __DIR__ . '/lib/cart_helpers.php';

$method = $_SERVER['REQUEST_METHOD'];

/**
 * Chỉ khách hàng (bảng users) được đồng bộ giỏ server.
 */
function requireCustomerUser(): array
{
    $user = requireLogin();
    if (($user['role'] ?? '') !== 'customer') {
        http_response_code(403);
        echo json_encode([
            'success' => false,
            'message' => 'Giỏ hàng trên server chỉ dành cho tài khoản khách hàng.',
        ]);
        exit();
    }

    return $user;
}

// ====== GET: Lấy giỏ hàng ======
if ($method === 'GET') {
    $authUser = requireCustomerUser();
    $userId = (int) $authUser['id'];
    $cartId = cartGetOrCreateId($pdo, $userId);
    $items = cartFetchEnrichedItems($pdo, $cartId);

    echo json_encode(['success' => true, 'data' => $items]);
    exit();
}

// ====== PUT: Đồng bộ toàn bộ giỏ ======
if ($method === 'PUT') {
    $authUser = requireCustomerUser();
    $userId = (int) $authUser['id'];

    $data = json_decode(file_get_contents('php://input'), true);
    $items = $data['items'] ?? [];

    if (!is_array($items)) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Danh sách giỏ hàng không hợp lệ']);
        exit();
    }

    $pdo->beginTransaction();
    try {
        $cartId = cartGetOrCreateId($pdo, $userId);
        cartReplaceItems($pdo, $cartId, $items);
        $pdo->commit();

        $enriched = cartFetchEnrichedItems($pdo, $cartId);
        echo json_encode([
            'success' => true,
            'message' => 'Đã đồng bộ giỏ hàng',
            'data' => $enriched,
        ]);
    } catch (InvalidArgumentException $e) {
        if ($pdo->inTransaction()) {
            $pdo->rollBack();
        }
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => $e->getMessage()]);
    } catch (Exception $e) {
        if ($pdo->inTransaction()) {
            $pdo->rollBack();
        }
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Lỗi đồng bộ giỏ hàng']);
    }
    exit();
}

// ====== DELETE: Xóa item hoặc xóa hết ======
if ($method === 'DELETE') {
    $authUser = requireCustomerUser();
    $userId = (int) $authUser['id'];

    $cartId = cartGetOrCreateId($pdo, $userId);

    if (!empty($_GET['clear']) && $_GET['clear'] === '1') {
        $pdo->prepare('DELETE FROM cart_items WHERE cart_id = ?')->execute([$cartId]);
        echo json_encode(['success' => true, 'message' => 'Đã xóa toàn bộ giỏ hàng']);
        exit();
    }

    $itemId = isset($_GET['item_id']) ? (int) $_GET['item_id'] : 0;
    if ($itemId <= 0) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Thiếu item_id hoặc dùng ?clear=1']);
        exit();
    }

    $del = $pdo->prepare('DELETE FROM cart_items WHERE id = ? AND cart_id = ?');
    $del->execute([$itemId, $cartId]);

    if ($del->rowCount() === 0) {
        http_response_code(404);
        echo json_encode(['success' => false, 'message' => 'Không tìm thấy dòng giỏ hàng']);
        exit();
    }

    echo json_encode(['success' => true, 'message' => 'Đã xóa sản phẩm khỏi giỏ']);
    exit();
}

http_response_code(405);
echo json_encode(['success' => false, 'message' => 'Method not allowed']);
