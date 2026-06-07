<?php
// =====================================================
// PayOS pending order helpers
// =====================================================

/**
 * Latest unpaid PayOS pending order for a logged-in customer.
 */
function findPendingPayosOrderForUser(PDO $pdo, int $userId): ?array
{
    $stmt = $pdo->prepare('
        SELECT o.id, o.user_id, o.total, o.status, o.payment_method,
               o.customer_name, o.email, o.phone, o.created_at,
               p.status AS payment_status
        FROM orders o
        LEFT JOIN payments p ON p.order_id = o.id AND p.method = o.payment_method
        WHERE o.user_id = ? AND o.deleted_at IS NULL
          AND o.status = "pending" AND o.payment_method = "payos"
          AND (p.status IS NULL OR p.status != "completed")
        ORDER BY o.created_at DESC
        LIMIT 1
    ');
    $stmt->execute([$userId]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);

    return $row ?: null;
}

/**
 * Load order row and validate pending PayOS access for customer or admin.
 */
function assertPendingPayosOrderAccess(PDO $pdo, int $orderId, array $authUser): array
{
    $stmt = $pdo->prepare('
        SELECT o.id, o.user_id, o.total, o.status, o.payment_method,
               o.customer_name, o.email, o.phone, o.created_at,
               p.status AS payment_status
        FROM orders o
        LEFT JOIN payments p ON p.order_id = o.id AND p.method = o.payment_method
        WHERE o.id = ? AND o.deleted_at IS NULL
        LIMIT 1
    ');
    $stmt->execute([$orderId]);
    $order = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$order) {
        http_response_code(404);
        echo json_encode(['success' => false, 'message' => 'Không tìm thấy đơn hàng']);
        exit();
    }

    $isAdmin = in_array($authUser['role'], ['admin', 'staff'], true);
    if (!$isAdmin && (int) ($order['user_id'] ?? 0) !== (int) $authUser['id']) {
        http_response_code(403);
        echo json_encode(['success' => false, 'message' => 'Bạn không có quyền thao tác đơn hàng này.']);
        exit();
    }

    if ($order['status'] !== 'pending' || $order['payment_method'] !== 'payos') {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Đơn hàng không ở trạng thái chờ thanh toán PayOS.']);
        exit();
    }

    if (($order['payment_status'] ?? '') === 'completed') {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Đơn hàng đã được thanh toán.']);
        exit();
    }

    return $order;
}

/**
 * Build PayOS checkout URL for an existing pending order (retry payment).
 */
function createPayosCheckoutForOrder(PDO $pdo, int $orderId, array $orderRow): array
{
    require_once __DIR__ . '/payos_helper.php';

    $itemsStmt = $pdo->prepare('
        SELECT product_name, quantity, price
        FROM order_items
        WHERE order_id = ?
    ');
    $itemsStmt->execute([$orderId]);
    $orderItems = $itemsStmt->fetchAll(PDO::FETCH_ASSOC);

    $payosItems = [];
    foreach ($orderItems as $item) {
        $payosItems[] = [
            'name' => mb_substr($item['product_name'] ?? 'Sản phẩm', 0, 50),
            'quantity' => (int) ($item['quantity'] ?? 1),
            'price' => (int) ($item['price'] ?? 0),
        ];
    }

    cancelPaymentLink($orderId, 'Tạo lại link thanh toán PayOS');

    $frontendUrl = rtrim(getenv('FRONTEND_URL') ?: 'http://localhost:3000', '/');
    $returnUrl = $frontendUrl . '/payment/success?orderId=' . $orderId;
    $cancelUrl = $frontendUrl . '/payment/cancel?orderId=' . $orderId;
    $description = 'DEN HOA MY #' . $orderId;

    return createPaymentLink(
        $orderId,
        (int) $orderRow['total'],
        $description,
        $payosItems,
        $returnUrl,
        $cancelUrl,
        $orderRow['customer_name'] ?? null,
        $orderRow['email'] ?? null,
        $orderRow['phone'] ?? null
    );
}
