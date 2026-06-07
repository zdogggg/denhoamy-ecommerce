<?php
// ====================================
// API ĐƠN HÀNG - orders.php
// ====================================
require_once 'db.php';
require_once __DIR__ . '/lib/rate_limit.php';
require_once __DIR__ . '/lib/auth_middleware.php';
require_once __DIR__ . '/lib/validator.php';
require_once __DIR__ . '/lib/order_status.php';
require_once __DIR__ . '/lib/admin_route_guard.php';
require_once __DIR__ . '/lib/coupon_apply.php';
require_once __DIR__ . '/lib/order_pricing.php';
checkNormalRateLimit(); // Giới hạn 120 request/phút

$method = $_SERVER['REQUEST_METHOD'];

// ====== KIỂM TRA TRẠNG THÁI THANH TOÁN (Public - dùng sau redirect PayOS) ======
if ($method === 'GET' && ($_GET['action'] ?? '') === 'payment_status') {
    $orderId = (int) ($_GET['orderId'] ?? 0);

    if ($orderId <= 0) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Thiếu mã đơn hàng']);
        exit();
    }

    $stmt = $pdo->prepare('
        SELECT o.id, o.status, o.payment_method, o.total,
               p.status AS payment_status
        FROM orders o
        LEFT JOIN payments p ON p.order_id = o.id AND p.method = o.payment_method
        WHERE o.id = ? AND o.deleted_at IS NULL
        LIMIT 1
    ');
    $stmt->execute([$orderId]);
    $row = $stmt->fetch();

    if (!$row) {
        http_response_code(404);
        echo json_encode(['success' => false, 'message' => 'Không tìm thấy đơn hàng']);
        exit();
    }

    $isPaid = in_array($row['status'], ['approved', 'shipping', 'completed'], true)
        && ($row['payment_status'] === 'completed' || !in_array($row['payment_method'], ['payos'], true));

    // PayOS: chỉ coi là đã thanh toán khi payment record = completed
    if ($row['payment_method'] === 'payos') {
        $isPaid = $row['payment_status'] === 'completed'
            && in_array($row['status'], ['approved', 'shipping', 'completed'], true);
    }

    echo json_encode([
        'success' => true,
        'orderId' => (int) $row['id'],
        'orderStatus' => $row['status'],
        'paymentMethod' => $row['payment_method'],
        'paymentStatus' => $row['payment_status'] ?? 'pending',
        'isPaid' => $isPaid,
        'isPending' => $row['status'] === 'pending',
        'isCancelled' => $row['status'] === 'cancelled'
    ]);
    exit();
}

// ====== PAYOS: Đơn pending chưa thanh toán của khách ======
if ($method === 'GET' && ($_GET['action'] ?? '') === 'pending_payos') {
    require_once __DIR__ . '/lib/payos_order_helpers.php';

    $authUser = requireLogin();
    if ($authUser['role'] !== 'customer') {
        echo json_encode(['success' => true, 'data' => null]);
        exit();
    }

    $pending = findPendingPayosOrderForUser($pdo, (int) $authUser['id']);
    echo json_encode([
        'success' => true,
        'data' => $pending ? [
            'id' => (int) $pending['id'],
            'total' => (float) $pending['total'],
            'status' => $pending['status'],
            'paymentMethod' => $pending['payment_method'],
            'paymentStatus' => $pending['payment_status'] ?? 'pending',
            'createdAt' => $pending['created_at'],
        ] : null,
    ]);
    exit();
}

// ====== LẤY DANH SÁCH ĐƠN HÀNG (có Pagination, Filter, Search) ======
if ($method === 'GET') {
    $phone = trim($_GET['phone'] ?? '');

    // Không có phone → chỉ admin/staff (dashboard). Có phone → đăng nhập + khách chỉ xem SĐT của mình
    if ($phone === '') {
        adminGuardRequire('orders');
    } else {
        $authUser = requireLogin();
        if (!in_array($authUser['role'], ['admin', 'staff'], true)) {
            $phoneStmt = $pdo->prepare('SELECT phone FROM users WHERE id = ? LIMIT 1');
            $phoneStmt->execute([(int) $authUser['id']]);
            $ownerPhone = trim((string) ($phoneStmt->fetchColumn() ?: ''));
            if ($ownerPhone === '' || $phone !== $ownerPhone) {
                http_response_code(403);
                echo json_encode(['success' => false, 'message' => 'Bạn không có quyền xem đơn hàng này.']);
                exit();
            }
        } else {
            adminGuardOrdersPhoneAccess($authUser);
        }
    }

    $page = max(1, intval($_GET['page'] ?? 0));   // 0 = không phân trang (backward compatible)
    $limit = max(1, min(100, intval($_GET['limit'] ?? 20))); // Tối đa 100, mặc định 20
    $status = $_GET['status'] ?? '';                 // Filter: pending, approved, shipping...
    $search = $_GET['search'] ?? '';                 // Tìm theo tên, SĐT, email

    // === Xây dựng WHERE clause ===
    $where = ['o.deleted_at IS NULL'];
    $params = [];

    if ($phone) {
        $where[] = 'o.phone = ?';
        $params[] = $phone;
    }
    if ($status) {
        $where[] = 'o.status = ?';
        $params[] = $status;
    }
    if ($search) {
        $where[] = '(o.customer_name LIKE ? OR o.phone LIKE ? OR o.email LIKE ?)';
        $searchTerm = "%$search%";
        $params[] = $searchTerm;
        $params[] = $searchTerm;
        $params[] = $searchTerm;
    }

    $whereClause = implode(' AND ', $where);

    // === Pagination: Đếm tổng số đơn ===
    $pagination = null;
    if ($page > 0) {
        $countStmt = $pdo->prepare("SELECT COUNT(*) FROM orders o WHERE $whereClause");
        $countStmt->execute($params);
        $total = (int) $countStmt->fetchColumn();
        $totalPages = ceil($total / $limit);
        $offset = ($page - 1) * $limit;

        $pagination = [
            'total' => $total,
            'totalPages' => $totalPages,
            'currentPage' => $page,
            'limit' => $limit
        ];

        // === Query chính với LIMIT ===
        $sql = "SELECT o.id, o.user_id, o.customer_name, o.phone, o.email, o.address, o.delivery_method, o.note, 
                       o.payment_method, o.total, o.coupon_code, o.discount_amount, o.status, 
                       o.processed_by, o.created_at 
                FROM orders o 
                WHERE $whereClause 
                ORDER BY o.created_at DESC 
                LIMIT $limit OFFSET $offset";
    } else {
        // Backward compatible: không truyền page → lấy hết (cho admin dashboard)
        $sql = "SELECT o.id, o.user_id, o.customer_name, o.phone, o.email, o.address, o.delivery_method, o.note, 
                       o.payment_method, o.total, o.coupon_code, o.discount_amount, o.status, 
                       o.processed_by, o.created_at 
                FROM orders o 
                WHERE $whereClause 
                ORDER BY o.created_at DESC";
    }

    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    $orders = $stmt->fetchAll();

    // Lấy chi tiết sản phẩm trong mỗi đơn
    foreach ($orders as &$order) {
        $stmt2 = $pdo->prepare('
            SELECT oi.*, p.ten_san_pham, p.ma_san_pham, p.image_url,
                   pv.kich_thuoc AS variant_kich_thuoc,
                   pv.anh_sang AS variant_anh_sang
            FROM order_items oi 
            LEFT JOIN products p ON oi.product_id = p.id 
            LEFT JOIN product_variants pv ON oi.variant_id = pv.id
            WHERE oi.order_id = ?
        ');
        $stmt2->execute([$order['id']]);
        $order['items'] = $stmt2->fetchAll();
    }

    // === Response ===
    $response = ['success' => true, 'data' => $orders];
    if ($pagination) {
        $response['pagination'] = $pagination;
    }

    // Log API access
    logInfo('Orders GET', [
        'count' => count($orders),
        'page' => $page,
        'filters' => array_filter(['phone' => $phone, 'status' => $status, 'search' => $search])
    ]);

    echo json_encode($response);
    exit();
}


// ====== TẠO ĐƠN HÀNG MỚI ======
if ($method === 'POST') {
    $data = json_decode(file_get_contents('php://input'), true);
    $action = $data['action'] ?? '';

    // ====== PAYOS: Tạo lại link thanh toán cho đơn pending ======
    if ($action === 'retry_payos') {
        require_once __DIR__ . '/lib/payos_order_helpers.php';

        $authUser = requireLogin();
        $orderId = (int) ($data['orderId'] ?? 0);

        if ($orderId <= 0) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Thiếu mã đơn hàng']);
            exit();
        }

        $orderRow = assertPendingPayosOrderAccess($pdo, $orderId, $authUser);
        $payosResult = createPayosCheckoutForOrder($pdo, $orderId, $orderRow);

        if ($payosResult['success']) {
            echo json_encode([
                'success' => true,
                'message' => 'Đang chuyển sang thanh toán...',
                'orderId' => $orderId,
                'checkoutUrl' => $payosResult['checkoutUrl'],
                'qrCode' => $payosResult['qrCode'] ?? '',
            ]);
        } else {
            http_response_code(502);
            echo json_encode([
                'success' => false,
                'message' => $payosResult['message'] ?? 'Không thể tạo lại link thanh toán PayOS',
            ]);
        }
        exit();
    }

    // Chặn tạo đơn PayOS trùng khi còn đơn pending chưa thanh toán
    $paymentMethod = $data['paymentMethod'] ?? 'cod';
    $userIdForGuard = !empty($data['user_id']) ? (int) $data['user_id'] : 0;
    if ($paymentMethod === 'payos' && $userIdForGuard > 0) {
        require_once __DIR__ . '/lib/payos_order_helpers.php';
        $existingPending = findPendingPayosOrderForUser($pdo, $userIdForGuard);
        if ($existingPending) {
            http_response_code(409);
            echo json_encode([
                'success' => false,
                'message' => 'Bạn có đơn PayOS chưa thanh toán. Vui lòng thanh toán lại hoặc hủy đơn cũ.',
                'pendingOrderId' => (int) $existingPending['id'],
            ]);
            exit();
        }
    }

    // === Input Validation: Kiểm tra dữ liệu đầu vào ===
    $errors = validateOrder($data);
    if (!empty($errors)) {
        respondValidationError($errors);
    }

    // === Sanitize: Làm sạch dữ liệu ===
    $clean = sanitizeInput($data, [
        'name' => 'string',
        'phone' => 'phone',
        'email' => 'email',
        'address' => 'string',
        'note' => 'string',
        'paymentMethod' => 'string',
        'total' => 'float',
        'discountAmount' => 'float',
        'couponCode' => 'string'
    ]);

    $rawItems = $data['items'] ?? [];
    if (!is_array($rawItems) || empty($rawItems)) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Giỏ hàng trống']);
        exit();
    }

    $deliveryMethod = 'home';
    if (!empty($data['deliveryMethod']) && in_array($data['deliveryMethod'], ['home', 'store'], true)) {
        $deliveryMethod = $data['deliveryMethod'];
    }

    $pdo->beginTransaction();
    try {
        $items = normalizeOrderItemsInTransaction($pdo, $rawItems);
        $subtotal = calculateOrderSubtotal($items);

        $couponCode = null;
        $discountAmount = 0.0;
        if (!empty($clean['couponCode'])) {
            $couponResult = applyCouponByCode($pdo, $clean['couponCode'], $subtotal, true);
            if (!$couponResult['success']) {
                $pdo->rollBack();
                http_response_code(400);
                echo json_encode(['success' => false, 'message' => $couponResult['message']]);
                exit();
            }
            $couponCode = $couponResult['code'];
            $discountAmount = (float) $couponResult['discount_amount'];
        }

        $finalTotal = max(0, round($subtotal - $discountAmount));
        // Tạo đơn hàng (total/discount do server tính — không tin client)
        $stmt = $pdo->prepare('
            INSERT INTO orders (user_id, customer_name, phone, email, address, delivery_method, note, payment_method, total, coupon_code, discount_amount, status)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ');
        $userId = !empty($data['user_id']) ? $data['user_id'] : null;
        $stmt->execute([
            $userId,
            $clean['name'],
            $clean['phone'],
            $clean['email'],
            $clean['address'],
            $deliveryMethod,
            $clean['note'],
            $clean['paymentMethod'] ?: 'cod',
            $finalTotal,
            $couponCode,
            $discountAmount,
            'pending'
        ]);
        $orderId = $pdo->lastInsertId();

        if ($couponCode) {
            $stmtUpdateCoupon = $pdo->prepare('UPDATE coupons SET used_count = used_count + 1 WHERE code = ?');
            $stmtUpdateCoupon->execute([$couponCode]);
        }

        // Thêm chi tiết sản phẩm
        $stmtItem = $pdo->prepare('
            INSERT INTO order_items (order_id, product_id, variant_id, product_name, quantity, price, cost_price)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        ');
        foreach ($items as $item) {
            $productId = (int) $item['product_id'];
            $variantId = !empty($item['variant_id']) ? (int) $item['variant_id'] : null;
            $itemCost = (float) ($item['cost_price'] ?? 0);

            $stmtItem->execute([
                $orderId,
                $productId,
                $variantId,
                $item['name'] ?? '',
                $item['quantity'] ?? 1,
                $item['price'],
                $itemCost
            ]);

            // Trừ tồn kho (đã khóa và kiểm tra trong normalizeOrderItemsInTransaction)
            if ($variantId) {
                $pdo->prepare('UPDATE product_variants SET stock = stock - ? WHERE id = ?')
                    ->execute([$item['quantity'], $variantId]);
            } else {
                $pdo->prepare('UPDATE products SET stock = stock - ? WHERE id = ?')
                    ->execute([$item['quantity'], $productId]);
            }
        }

        // Tạo bản ghi thanh toán
        $stmtPayment = $pdo->prepare('
            INSERT INTO payments (order_id, amount, method, status)
            VALUES (?, ?, ?, ?)
        ');
        $paymentStatus = 'pending';
        // Nào thanh toán VNPay thành công thì trạng thái là completed, ở đây tạm set pending cho COD
        $stmtPayment->execute([
            $orderId,
            $finalTotal,
            $data['paymentMethod'] ?? 'cod',
            $paymentStatus
        ]);

        $pdo->commit();

        // Log tạo đơn thành công
        logInfo('Tạo đơn hàng thành công', [
            'order_id' => $orderId,
            'customer' => $clean['name'],
            'phone' => $clean['phone'],
            'total' => $finalTotal,
            'subtotal' => $subtotal,
            'discount_amount' => $discountAmount,
            'items_count' => count($items)
        ]);

        // COD / nhận tại cửa hàng: gửi email xác nhận đơn hàng (không chặn luồng nếu mail lỗi)
        if (in_array($clean['paymentMethod'] ?: 'cod', ['cod', 'pay_at_store'], true)) {
            require_once __DIR__ . '/lib/order_email_helper.php';
            try {
                $mailResult = sendOrderConfirmationEmail($pdo, $orderId, 'cod');
                if (!empty($mailResult['skipped'])) {
                    logWarning('Order confirmation email skipped', [
                        'order_id' => $orderId,
                        'reason' => $mailResult['message'] ?? 'unknown'
                    ]);
                } elseif ($mailResult['success']) {
                    logInfo('Order confirmation email sent', [
                        'order_id' => $orderId,
                        'resend_id' => $mailResult['id'] ?? null
                    ]);
                } else {
                    logWarning('Order confirmation email failed', [
                        'order_id' => $orderId,
                        'error' => $mailResult['message'] ?? 'unknown'
                    ]);
                }
            } catch (Exception $e) {
                logException($e, ['action' => 'order_confirmation_email', 'order_id' => $orderId]);
            }
        }

        // ====== PAYOS: Tạo link thanh toán trực tuyến ======
        if (($clean['paymentMethod'] ?? '') === 'payos') {
            require_once __DIR__ . '/lib/payos_helper.php';

            // Chuẩn bị danh sách items cho PayOS
            $payosItems = [];
            foreach ($items as $item) {
                $payosItems[] = [
                    'name' => mb_substr($item['name'] ?? 'Sản phẩm', 0, 50),
                    'quantity' => (int) ($item['quantity'] ?? 1),
                    'price' => (int) ($item['price'] ?? 0)
                ];
            }

            // URL trả về sau khi thanh toán (dùng FRONTEND_URL cố định, không phụ thuộc HTTP_ORIGIN)
            $frontendUrl = rtrim(getenv('FRONTEND_URL') ?: 'http://localhost:3000', '/');
            $returnUrl = $frontendUrl . '/payment/success?orderId=' . $orderId;
            $cancelUrl = $frontendUrl . '/payment/cancel?orderId=' . $orderId;

            // Description tối đa 25 ký tự
            $description = 'DEN HOA MY #' . $orderId;

            $payosResult = createPaymentLink(
                $orderId,                                    // orderCode = orderId
                (int) $finalTotal,                           // amount (VND)
                $description,                                // description
                $payosItems,                                 // items
                $returnUrl,                                  // returnUrl
                $cancelUrl,                                  // cancelUrl
                $clean['name'] ?? null,                      // buyerName
                $clean['email'] ?? null,                     // buyerEmail
                $clean['phone'] ?? null                      // buyerPhone
            );

            if ($payosResult['success']) {
                logInfo('PayOS: Tạo link thanh toán thành công', [
                    'order_id' => $orderId,
                    'checkoutUrl' => $payosResult['checkoutUrl']
                ]);

                echo json_encode([
                    'success' => true,
                    'message' => 'Đặt hàng thành công! Đang chuyển sang thanh toán...',
                    'orderId' => $orderId,
                    'checkoutUrl' => $payosResult['checkoutUrl'],
                    'qrCode' => $payosResult['qrCode'] ?? ''
                ]);
            } else {
                logError('PayOS: Lỗi tạo link thanh toán', [
                    'order_id' => $orderId,
                    'error' => $payosResult['message'] ?? 'Unknown'
                ]);

                // Vẫn trả đơn hàng thành công, nhưng báo lỗi PayOS
                echo json_encode([
                    'success' => true,
                    'message' => 'Đặt hàng thành công! Tuy nhiên chưa thể tạo link thanh toán. Vui lòng liên hệ shop.',
                    'orderId' => $orderId,
                    'payosError' => $payosResult['message'] ?? ''
                ]);
            }
        } else {
            // COD hoặc bank_transfer → trả bình thường
            echo json_encode([
                'success' => true,
                'message' => 'Đặt hàng thành công!',
                'orderId' => $orderId
            ]);
        }
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
        logException($e, ['action' => 'create_order', 'phone' => $clean['phone'] ?? '']);
        echo json_encode(['success' => false, 'message' => 'Lỗi tạo đơn hàng']);
    }
    exit();
}

// ====== CẬP NHẬT TRẠNG THÁI ĐƠN HÀNG ======
if ($method === 'PUT') {
    $data = json_decode(file_get_contents('php://input'), true);

    // Khách hủy đơn PayOS pending (hoàn stock)
    if (($data['action'] ?? '') === 'cancel_pending') {
        require_once __DIR__ . '/lib/payos_order_helpers.php';

        $authUser = requireLogin();
        $orderId = (int) ($data['orderId'] ?? $data['id'] ?? 0);

        if ($orderId <= 0) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Thiếu mã đơn hàng']);
            exit();
        }

        assertPendingPayosOrderAccess($pdo, $orderId, $authUser);

        require_once __DIR__ . '/lib/payos_helper.php';
        cancelPaymentLink($orderId, 'Khách hàng hủy đơn chờ thanh toán PayOS');

        $result = applyOrderStatus($pdo, $orderId, 'cancelled', 'customer');
        if (!$result['success']) {
            http_response_code(400);
            echo json_encode($result);
            exit();
        }

        echo json_encode([
            'success' => true,
            'message' => 'Đã hủy đơn hàng chờ thanh toán.',
            'orderId' => $orderId,
        ]);
        exit();
    }

    // Khách xác nhận đã nhận hàng (shipping → completed)
    if (($data['action'] ?? '') === 'confirm_received') {
        $authUser = requireLogin();
        $orderId = (int) ($data['orderId'] ?? $data['id'] ?? 0);

        if ($orderId <= 0) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Thiếu mã đơn hàng']);
            exit();
        }

        $orderStmt = $pdo->prepare('SELECT id, status, phone FROM orders WHERE id = ? AND deleted_at IS NULL');
        $orderStmt->execute([$orderId]);
        $orderRow = $orderStmt->fetch();

        if (!$orderRow) {
            http_response_code(404);
            echo json_encode(['success' => false, 'message' => 'Không tìm thấy đơn hàng']);
            exit();
        }

        if (!in_array($authUser['role'], ['admin', 'staff'], true)) {
            $phoneStmt = $pdo->prepare('SELECT phone FROM users WHERE id = ? LIMIT 1');
            $phoneStmt->execute([(int) $authUser['id']]);
            $ownerPhone = trim((string) ($phoneStmt->fetchColumn() ?: ''));
            if ($ownerPhone === '' || trim($orderRow['phone']) !== $ownerPhone) {
                http_response_code(403);
                echo json_encode(['success' => false, 'message' => 'Bạn không có quyền xác nhận đơn hàng này.']);
                exit();
            }
        }

        if ($orderRow['status'] !== 'shipping') {
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'message' => 'Chỉ có thể xác nhận đã nhận khi đơn đang giao hàng.',
            ]);
            exit();
        }

        $result = applyOrderStatus($pdo, $orderId, 'completed', 'customer');
        if (!$result['success']) {
            http_response_code(400);
        }
        echo json_encode($result);
        exit();
    }

    // Admin cập nhật trạng thái
    adminGuardAuto();

    $id = (int) ($data['id'] ?? 0);
    $status = $data['status'] ?? '';
    $adminId = $data['admin_id'] ?? null;

    if ($id <= 0 || $status === '') {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Thiếu thông tin']);
        exit();
    }

    $result = applyOrderStatus($pdo, $id, $status, $adminId);
    if (!$result['success']) {
        http_response_code(400);
    }
    echo json_encode($result);
    exit();
}

// ====== XÓA ĐƠN HÀNG (Admin) ======
if ($method === 'DELETE') {
    // === Middleware: Yêu cầu quyền Admin ===
    adminGuardAuto();

    $id = $_GET['id'] ?? null;
    if (!$id) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Thiếu ID đơn hàng']);
        exit();
    }

    $pdo->beginTransaction();
    try {
        // Lấy thông tin đơn hàng trước khi xóa
        $orderStmt = $pdo->prepare('SELECT status, coupon_code FROM orders WHERE id = ?');
        $orderStmt->execute([$id]);
        $order = $orderStmt->fetch();

        if ($order && $order['status'] !== 'cancelled') {
            // Hoàn trả tồn kho (nếu đơn chưa bị hủy trước đó)
            $itemsStmt = $pdo->prepare('SELECT product_id, variant_id, quantity FROM order_items WHERE order_id = ?');
            $itemsStmt->execute([$id]);
            $items = $itemsStmt->fetchAll();

            foreach ($items as $item) {
                if (!empty($item['variant_id'])) {
                    $pdo->prepare('UPDATE product_variants SET stock = stock + ? WHERE id = ?')
                        ->execute([$item['quantity'], $item['variant_id']]);
                } elseif (!empty($item['product_id'])) {
                    $pdo->prepare('UPDATE products SET stock = stock + ? WHERE id = ?')
                        ->execute([$item['quantity'], $item['product_id']]);
                }
            }

            // Hoàn trả lượt dùng mã giảm giá
            if (!empty($order['coupon_code'])) {
                $pdo->prepare('UPDATE coupons SET used_count = GREATEST(0, used_count - 1) WHERE code = ?')
                    ->execute([$order['coupon_code']]);
            }
        }

        // Soft Delete: đánh dấu xóa thay vì xóa thật
        $pdo->prepare('UPDATE orders SET deleted_at = NOW() WHERE id = ?')->execute([$id]);

        $pdo->commit();

        logInfo('Xóa đơn hàng (soft delete)', ['order_id' => $id]);
        echo json_encode(['success' => true, 'message' => 'Đã xóa đơn hàng']);
    } catch (Exception $e) {
        $pdo->rollBack();
        logException($e, ['action' => 'delete_order', 'order_id' => $id]);
        echo json_encode(['success' => false, 'message' => 'Lỗi xóa đơn hàng']);
    }
    exit();
}

http_response_code(405);
echo json_encode(['success' => false, 'message' => 'Method not allowed']);
