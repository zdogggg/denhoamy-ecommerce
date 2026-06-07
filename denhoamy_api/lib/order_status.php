<?php
// =====================================================
// ORDER STATUS - State machine & shared transitions
// =====================================================

require_once __DIR__ . '/logger.php';

const ORDER_APPROVED_TO_SHIPPING_HOURS = 12;
const ORDER_SHIPPING_TO_COMPLETED_DAYS = 5;
const ORDER_PENDING_CANCEL_HOURS = 24;

/**
 * @return string[]
 */
function getAllowedTransitions(string $from): array
{
    $map = [
        'pending' => ['approved', 'cancelled'],
        'approved' => ['shipping', 'cancelled'],
        'shipping' => ['completed', 'cancelled'],
        'completed' => [],
        'cancelled' => [],
    ];

    return $map[$from] ?? [];
}

function canTransition(string $from, string $to): bool
{
    return in_array($to, getAllowedTransitions($from), true);
}

/**
 * Hoàn kho và lượt dùng coupon khi hủy đơn.
 */
function restoreOrderInventory(PDO $pdo, int $orderId, ?string $couponCode): void
{
    $itemsStmt = $pdo->prepare('SELECT product_id, variant_id, quantity FROM order_items WHERE order_id = ?');
    $itemsStmt->execute([$orderId]);
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

    if (!empty($couponCode)) {
        $pdo->prepare('UPDATE coupons SET used_count = GREATEST(0, used_count - 1) WHERE code = ?')
            ->execute([$couponCode]);
    }
}

/**
 * Áp dụng chuyển trạng thái đơn hàng (có validate + hoàn kho khi hủy).
 *
 * @param int|string|null $actor Admin ID, 'system_cron', 'customer', hoặc null
 * @return array{success: bool, message: string, oldStatus?: string, newStatus?: string}
 */
function applyOrderStatus(PDO $pdo, int $orderId, string $newStatus, $actor = null): array
{
    $validStatuses = ['pending', 'approved', 'shipping', 'completed', 'cancelled'];
    if (!in_array($newStatus, $validStatuses, true)) {
        return ['success' => false, 'message' => 'Trạng thái không hợp lệ'];
    }

    $stmt = $pdo->prepare('SELECT id, status, coupon_code FROM orders WHERE id = ? AND deleted_at IS NULL');
    $stmt->execute([$orderId]);
    $order = $stmt->fetch();

    if (!$order) {
        return ['success' => false, 'message' => 'Không tìm thấy đơn hàng'];
    }

    $oldStatus = $order['status'];

    if ($oldStatus === $newStatus) {
        return [
            'success' => true,
            'message' => 'Trạng thái không thay đổi',
            'oldStatus' => $oldStatus,
            'newStatus' => $newStatus,
        ];
    }

    if (!canTransition($oldStatus, $newStatus)) {
        return [
            'success' => false,
            'message' => "Không thể chuyển từ \"{$oldStatus}\" sang \"{$newStatus}\"",
            'oldStatus' => $oldStatus,
        ];
    }

    $pdo->beginTransaction();
    try {
        if ($newStatus === 'cancelled' && $oldStatus !== 'cancelled') {
            restoreOrderInventory($pdo, $orderId, $order['coupon_code'] ?? null);
        }

        $processedBy = null;
        if ($actor !== null && $actor !== '' && is_numeric($actor) && (int) $actor > 0) {
            $processedBy = (int) $actor;
        }

        if ($processedBy !== null) {
            $pdo->prepare('UPDATE orders SET status = ?, processed_by = ?, updated_at = NOW() WHERE id = ?')
                ->execute([$newStatus, $processedBy, $orderId]);
        } else {
            $pdo->prepare('UPDATE orders SET status = ?, updated_at = NOW() WHERE id = ?')
                ->execute([$newStatus, $orderId]);
        }

        $pdo->commit();

        $actorLabel = is_numeric($actor) && (int) $actor > 0
            ? 'admin:' . (int) $actor
            : (string) ($actor ?? 'system');

        logInfo('Order status updated', [
            'order_id' => $orderId,
            'from' => $oldStatus,
            'to' => $newStatus,
            'actor' => $actorLabel,
        ]);

        return [
            'success' => true,
            'message' => 'Đã cập nhật trạng thái đơn hàng',
            'oldStatus' => $oldStatus,
            'newStatus' => $newStatus,
        ];
    } catch (Exception $e) {
        $pdo->rollBack();
        logException($e, ['action' => 'apply_order_status', 'order_id' => $orderId, 'to' => $newStatus]);
        return ['success' => false, 'message' => 'Lỗi cập nhật trạng thái đơn hàng'];
    }
}

/**
 * PDO cho cron (không qua HTTP / db.php headers).
 */
function createCronPdo(): PDO
{
    $DB_HOST = getenv('DB_HOST') ?: 'localhost';
    $DB_NAME = getenv('DB_NAME') ?: 'denhoamy_db';
    $DB_USER = getenv('DB_USER') ?: 'root';
    $DB_PASS = getenv('DB_PASS') ?: '';

    return new PDO(
        "mysql:host=$DB_HOST;dbname=$DB_NAME;charset=utf8mb4",
        $DB_USER,
        $DB_PASS,
        [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES => false,
        ]
    );
}
