<?php
// ============================================================
// CRON JOB: Tự động hủy đơn hàng "Chờ xác nhận" quá 24 giờ
// ============================================================
// Chạy bằng cron: * * * * * php /var/www/html/cron_cancel_orders.php
// ============================================================

require_once __DIR__ . '/lib/order_status.php';

putenv('PAYOS_CLIENT_ID=' . (getenv('PAYOS_CLIENT_ID') ?: ''));
putenv('PAYOS_API_KEY=' . (getenv('PAYOS_API_KEY') ?: ''));
putenv('PAYOS_CHECKSUM_KEY=' . (getenv('PAYOS_CHECKSUM_KEY') ?: ''));
require_once __DIR__ . '/lib/payos_helper.php';

try {
    $pdo = createCronPdo();
} catch (PDOException $e) {
    error_log('[CRON] Lỗi kết nối database: ' . $e->getMessage());
    exit(1);
}

$HOURS_LIMIT = ORDER_PENDING_CANCEL_HOURS;

$stmt = $pdo->prepare('
    SELECT id, coupon_code, payment_method 
    FROM orders 
    WHERE status = "pending" 
    AND deleted_at IS NULL
    AND created_at < DATE_SUB(NOW(), INTERVAL ? HOUR)
');
$stmt->execute([$HOURS_LIMIT]);
$expiredOrders = $stmt->fetchAll();

if (empty($expiredOrders)) {
    exit(0);
}

$cancelledCount = 0;

foreach ($expiredOrders as $order) {
    $orderId = (int) $order['id'];
    $paymentMethod = $order['payment_method'] ?? 'cod';

    if ($paymentMethod === 'payos') {
        $cancelResult = cancelPaymentLink($orderId, "Đơn hàng #{$orderId} quá {$HOURS_LIMIT}h không thanh toán");
        if ($cancelResult['success']) {
            error_log("[CRON] PayOS: Đã hủy link thanh toán cho đơn #{$orderId}");
        } else {
            error_log("[CRON] PayOS: Không thể hủy link cho đơn #{$orderId}: " . $cancelResult['message']);
        }
    }

    $result = applyOrderStatus($pdo, $orderId, 'cancelled', 'system_cron');
    if ($result['success']) {
        $cancelledCount++;
        error_log("[CRON] Đã tự động hủy đơn hàng #{$orderId} (quá {$HOURS_LIMIT}h không xác nhận)");
    } else {
        error_log("[CRON] Lỗi khi hủy đơn #{$orderId}: " . $result['message']);
    }
}

$totalExpired = count($expiredOrders);
error_log("[CRON] Hoàn tất: Đã hủy {$cancelledCount}/{$totalExpired} đơn hàng hết hạn.");
exit(0);
