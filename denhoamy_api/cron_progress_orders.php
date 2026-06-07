<?php
// ============================================================
// CRON JOB: Tự động tiến trạng thái đơn hàng
// ============================================================
// approved → shipping sau ORDER_APPROVED_TO_SHIPPING_HOURS
// shipping → completed sau ORDER_SHIPPING_TO_COMPLETED_DAYS
// Chạy: php /var/www/html/cron_progress_orders.php
// ============================================================

require_once __DIR__ . '/lib/order_status.php';

try {
    $pdo = createCronPdo();
} catch (PDOException $e) {
    error_log('[CRON] progress_orders: Lỗi kết nối database: ' . $e->getMessage());
    exit(1);
}

$hours = ORDER_APPROVED_TO_SHIPPING_HOURS;
$days = ORDER_SHIPPING_TO_COMPLETED_DAYS;

$approvedStmt = $pdo->prepare("
    SELECT id FROM orders
    WHERE status = 'approved'
    AND deleted_at IS NULL
    AND updated_at < DATE_SUB(NOW(), INTERVAL ? HOUR)
");
$approvedStmt->execute([$hours]);
$toShip = $approvedStmt->fetchAll();

$shippingStmt = $pdo->prepare("
    SELECT id FROM orders
    WHERE status = 'shipping'
    AND deleted_at IS NULL
    AND updated_at < DATE_SUB(NOW(), INTERVAL ? DAY)
");
$shippingStmt->execute([$days]);
$toComplete = $shippingStmt->fetchAll();

if (empty($toShip) && empty($toComplete)) {
    exit(0);
}

$shipCount = 0;
$completeCount = 0;

foreach ($toShip as $row) {
    $result = applyOrderStatus($pdo, (int) $row['id'], 'shipping', 'system_cron');
    if ($result['success']) {
        $shipCount++;
        error_log("[CRON] progress_orders: Đơn #{$row['id']} → shipping (sau {$hours}h)");
    } else {
        error_log("[CRON] progress_orders: Lỗi đơn #{$row['id']}: " . $result['message']);
    }
}

foreach ($toComplete as $row) {
    $result = applyOrderStatus($pdo, (int) $row['id'], 'completed', 'system_cron');
    if ($result['success']) {
        $completeCount++;
        error_log("[CRON] progress_orders: Đơn #{$row['id']} → completed (sau {$days} ngày)");
    } else {
        error_log("[CRON] progress_orders: Lỗi đơn #{$row['id']}: " . $result['message']);
    }
}

error_log("[CRON] progress_orders: Hoàn tất — {$shipCount} đơn → shipping, {$completeCount} đơn → completed.");
exit(0);
