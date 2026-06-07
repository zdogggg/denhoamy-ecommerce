<?php
// ====================================
// API MÃ GIẢM GIÁ (COUPONS) - coupons.php
// ====================================
require_once 'db.php';
require_once __DIR__ . '/lib/auth_middleware.php';
require_once __DIR__ . '/lib/admin_route_guard.php';
require_once __DIR__ . '/lib/coupon_apply.php';

$method = $_SERVER['REQUEST_METHOD'];

function normalizeCouponPayload(array $data): array
{
    $code = strtoupper(trim($data['code'] ?? ''));
    if ($code === '') {
        return ['ok' => false, 'message' => 'Thiếu mã giảm giá'];
    }

    $discountPercent = max(0, min(100, (int) ($data['discount_percent'] ?? 0)));
    $discountAmount = max(0, (float) ($data['discount_amount'] ?? 0));

    if ($discountPercent === 0 && $discountAmount <= 0) {
        return ['ok' => false, 'message' => 'Cần thiết lập giảm theo % hoặc số tiền'];
    }
    if ($discountPercent > 0 && $discountAmount > 0) {
        return ['ok' => false, 'message' => 'Chỉ được chọn giảm theo % hoặc giảm tiền, không dùng cả hai'];
    }

    $startDate = !empty($data['start_date']) ? $data['start_date'] : null;
    $endDate = !empty($data['end_date']) ? $data['end_date'] : null;
    if ($startDate && $endDate && $endDate < $startDate) {
        return ['ok' => false, 'message' => 'Ngày kết thúc phải sau ngày bắt đầu'];
    }

    // Kiểu Shopee: mã giảm % bắt buộc có trần "giảm tối đa" (tránh 100% không trần = free ship cả đơn)
    $maxDiscount = null;
    if ($discountPercent > 0) {
        if (empty($data['max_discount_amount']) || (float) $data['max_discount_amount'] <= 0) {
            return ['ok' => false, 'message' => 'Mã giảm theo % phải có giới hạn giảm tối đa (VD: 200.000đ)'];
        }
        $maxDiscount = (float) $data['max_discount_amount'];
    }

    return [
        'ok' => true,
        'data' => [
            'code' => $code,
            'discount_percent' => $discountPercent > 0 ? $discountPercent : 0,
            'discount_amount' => $discountAmount > 0 ? $discountAmount : 0,
            'max_discount_amount' => $maxDiscount,
            'min_order_value' => max(0, (float) ($data['min_order_value'] ?? 0)),
            'usage_limit' => !empty($data['usage_limit']) ? (int) $data['usage_limit'] : null,
            'start_date' => $startDate,
            'end_date' => $endDate,
        ],
    ];
}

// Lấy danh sách coupons
if ($method === 'GET') {
    $scope = strtolower(trim((string) ($_GET['scope'] ?? '')));

    // Public: checkout dialog — chỉ mã đang active, field tối thiểu
    if ($scope === 'public') {
        $stmt = $pdo->prepare('
            SELECT id, code, discount_percent, discount_amount, max_discount_amount, min_order_value,
                   usage_limit, used_count, start_date, end_date, is_active
            FROM coupons
            WHERE is_active = 1
            ORDER BY id DESC
        ');
        $stmt->execute();
        echo json_encode(['success' => true, 'data' => $stmt->fetchAll(PDO::FETCH_ASSOC)]);
        exit();
    }

    adminGuardRequire('coupons');
    $stmt = $pdo->prepare('SELECT id, code, discount_percent, discount_amount, max_discount_amount, min_order_value, usage_limit, used_count, start_date, end_date, is_active, created_at FROM coupons ORDER BY id DESC');
    $stmt->execute();
    echo json_encode(['success' => true, 'data' => $stmt->fetchAll(PDO::FETCH_ASSOC)]);
    exit();
}

// Xử lý Kiểm tra & Áp dụng coupon (User)
if ($method === 'POST') {
    $rawBody = file_get_contents('php://input');
    $data = is_string($rawBody) && $rawBody !== '' ? json_decode($rawBody, true) : null;
    if (!is_array($data)) {
        $data = [];
    }

    $action = strtolower(trim((string) ($data['action'] ?? '')));
    if ($action === 'apply') {
        if (!isset($data['code'])) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Thiếu mã giảm giá']);
            exit();
        }

        $valueResult = resolveCouponOrderValue($pdo, $data);
        if (!$valueResult['success']) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => $valueResult['message']]);
            exit();
        }

        $result = applyCouponByCode($pdo, (string) $data['code'], $valueResult['order_value']);

        if (!$result['success']) {
            echo json_encode(['success' => false, 'message' => $result['message']]);
            exit();
        }

        echo json_encode([
            'success' => true,
            'message' => 'Áp dụng mã thành công!',
            'data' => [
                'code' => $result['code'],
                'discount_amount' => $result['discount_amount'],
                'coupon_id' => $result['coupon_id'],
            ],
        ]);
        exit();
    }

    adminGuardRequire('coupons');
    $normalized = normalizeCouponPayload($data);
    if (!$normalized['ok']) {
        echo json_encode(['success' => false, 'message' => $normalized['message']]);
        exit();
    }
    $c = $normalized['data'];

    $stmt = $pdo->prepare('
        INSERT INTO coupons (code, discount_percent, discount_amount, max_discount_amount, min_order_value, usage_limit, start_date, end_date) 
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ');

    try {
        $stmt->execute([
            $c['code'],
            $c['discount_percent'],
            $c['discount_amount'],
            $c['max_discount_amount'],
            $c['min_order_value'],
            $c['usage_limit'],
            $c['start_date'],
            $c['end_date']
        ]);
        echo json_encode(['success' => true, 'message' => 'Tạo mã giảm giá thành công']);
    } catch (PDOException $e) {
        if ($e->getCode() == 23000) { // Duplicate entry
            echo json_encode(['success' => false, 'message' => 'Mã giảm giá đã tồn tại!']);
        } else {
            echo json_encode(['success' => false, 'message' => 'Lỗi DB: ' . $e->getMessage()]);
        }
    }
    exit();
}

// Cập nhật mã giảm giá (Admin)
if ($method === 'PUT') {
    adminGuardRequire('coupons');
    $data = json_decode(file_get_contents('php://input'), true);
    if (!isset($data['id'])) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Thiếu ID']);
        exit();
    }

    // Cho phép bật/tắt kích hoạt nhanh (chỉ gửi id và is_active)
    if (isset($data['is_active']) && count($data) <= 3 && !isset($data['code'])) {
        $stmt = $pdo->prepare('UPDATE coupons SET is_active = ? WHERE id = ?');
        $stmt->execute([(int) $data['is_active'], $data['id']]);
        echo json_encode(['success' => true, 'message' => 'Cập nhật trạng thái thành công']);
        exit();
    }

    $isActiveVal = isset($data['is_active']) ? (int) $data['is_active'] : 1;

    $normalized = normalizeCouponPayload($data);
    if (!$normalized['ok']) {
        echo json_encode(['success' => false, 'message' => $normalized['message']]);
        exit();
    }
    $c = $normalized['data'];

    $stmt = $pdo->prepare('
        UPDATE coupons SET 
            code = ?, discount_percent = ?, discount_amount = ?, max_discount_amount = ?, min_order_value = ?, 
            usage_limit = ?, start_date = ?, end_date = ?, is_active = ?
        WHERE id = ?
    ');

    try {
        $stmt->execute([
            $c['code'],
            $c['discount_percent'],
            $c['discount_amount'],
            $c['max_discount_amount'],
            $c['min_order_value'],
            $c['usage_limit'],
            $c['start_date'],
            $c['end_date'],
            $isActiveVal,
            $data['id']
        ]);
        echo json_encode(['success' => true, 'message' => 'Cập nhật thành công']);
    } catch (PDOException $e) {
        echo json_encode(['success' => false, 'message' => 'Lỗi DB: ' . $e->getMessage()]);
    }
    exit();
}

// Xoá mã giảm giá (Admin)
if ($method === 'DELETE') {
    adminGuardRequire('coupons');
    $id = $_GET['id'] ?? null;
    if (!$id) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Thiếu ID']);
        exit();
    }

    $stmt = $pdo->prepare('DELETE FROM coupons WHERE id = ?');
    $stmt->execute([$id]);

    echo json_encode(['success' => true, 'message' => 'Đã xóa mã giảm giá']);
    exit();
}

http_response_code(405);
echo json_encode(['success' => false, 'message' => 'Method not allowed']);
