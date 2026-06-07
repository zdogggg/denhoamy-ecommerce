<?php
/**
 * Smoke test khóa tồn kho khi đặt hàng (chạy trong container API):
 *   php /var/www/html/tests/order_stock_smoke.php
 */
require_once __DIR__ . '/../lib/order_status.php';
require_once __DIR__ . '/../lib/order_pricing.php';

$pdo = createCronPdo();
$passed = 0;
$failed = 0;

function assertStockTest(string $name, bool $cond, string $detail = ''): void
{
    global $passed, $failed;
    if ($cond) {
        $passed++;
        echo "[PASS] $name\n";
    } else {
        $failed++;
        echo "[FAIL] $name" . ($detail ? " — $detail" : '') . "\n";
    }
}

// Sản phẩm hết hàng → normalizeOrderItemsInTransaction phải ném lỗi
$zeroStmt = $pdo->query('
    SELECT id FROM products
    WHERE deleted_at IS NULL AND stock <= 0
    ORDER BY id ASC
    LIMIT 1
');
$zeroRow = $zeroStmt->fetch(PDO::FETCH_ASSOC);

if ($zeroRow) {
    $pdo->beginTransaction();
    $threw = false;
    try {
        normalizeOrderItemsInTransaction($pdo, [
            ['id' => (int) $zeroRow['id'], 'quantity' => 1, 'name' => 'Smoke zero stock'],
        ]);
    } catch (InvalidArgumentException $e) {
        $threw = true;
        assertStockTest('reject order when stock is zero', strpos($e->getMessage(), 'tồn kho') !== false, $e->getMessage());
    }
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }
    if (!$threw) {
        assertStockTest('reject order when stock is zero', false, 'expected InvalidArgumentException');
    }
} else {
    echo "[SKIP] No product with stock <= 0\n";
}

// Sản phẩm còn hàng → normalize thành công trong transaction
$okStmt = $pdo->query('
    SELECT id FROM products
    WHERE deleted_at IS NULL AND stock >= 1
    ORDER BY id ASC
    LIMIT 1
');
$okRow = $okStmt->fetch(PDO::FETCH_ASSOC);

if ($okRow) {
    $pdo->beginTransaction();
    try {
        $normalized = normalizeOrderItemsInTransaction($pdo, [
            ['id' => (int) $okRow['id'], 'quantity' => 1, 'name' => 'Smoke in stock'],
        ]);
        assertStockTest('normalize in-stock product', count($normalized) === 1 && (int) $normalized[0]['quantity'] === 1);
        assertStockTest('locked row has product_id', (int) $normalized[0]['product_id'] === (int) $okRow['id']);
    } catch (InvalidArgumentException $e) {
        assertStockTest('normalize in-stock product', false, $e->getMessage());
    }
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }
} else {
    echo "[SKIP] No product with stock >= 1\n";
}

$agg = aggregateOrderItemsForStockLock([
    ['id' => 5, 'quantity' => 2],
    ['id' => 5, 'quantity' => 3],
]);
assertStockTest(
    'aggregateOrderItemsForStockLock sums qty',
    count($agg) === 1 && ($agg['5:0']['quantity'] ?? 0) === 5
);

echo "\nSummary: $passed passed, $failed failed\n";
exit($failed > 0 ? 1 : 0);
