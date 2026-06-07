<?php
/**
 * Smoke test order status (chạy trong container API):
 *   php /var/www/html/tests/order_status_smoke.php
 */
require_once __DIR__ . '/../lib/order_status.php';

$pdo = createCronPdo();
$passed = 0;
$failed = 0;

function assertTest(string $name, bool $cond, string $detail = ''): void
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

assertTest('canTransition pending→approved', canTransition('pending', 'approved'));
assertTest('canTransition pending→completed blocked', !canTransition('pending', 'completed'));
assertTest('canTransition shipping→completed', canTransition('shipping', 'completed'));
assertTest('canTransition completed→cancelled blocked', !canTransition('completed', 'cancelled'));

// Tìm hoặc tạo đơn test
$stmt = $pdo->query("SELECT id FROM orders WHERE deleted_at IS NULL ORDER BY id DESC LIMIT 1");
$row = $stmt->fetch();
if (!$row) {
    echo "No orders in DB — skip applyOrderStatus tests\n";
    exit($failed > 0 ? 1 : 0);
}

$orderId = (int) $row['id'];
$orig = $pdo->prepare('SELECT status FROM orders WHERE id = ?');
$orig->execute([$orderId]);
$originalStatus = $orig->fetchColumn();

// Invalid jump should fail
$bad = applyOrderStatus($pdo, $orderId, 'completed', 'test');
assertTest(
    'applyOrderStatus rejects invalid jump',
    !$bad['success'] && ($bad['oldStatus'] ?? '') === $originalStatus,
    $bad['message'] ?? ''
);

// Restore status if still same
$check = $pdo->prepare('SELECT status FROM orders WHERE id = ?');
$check->execute([$orderId]);
assertTest('DB unchanged after invalid jump', $check->fetchColumn() === $originalStatus);

echo "\nSummary: $passed passed, $failed failed\n";
exit($failed > 0 ? 1 : 0);
