<?php
/**
 * Test shipping → completed via applyOrderStatus (customer actor)
 */
require_once __DIR__ . '/../lib/order_status.php';

$pdo = createCronPdo();

$pdo->exec("UPDATE orders SET status='shipping', updated_at=NOW() WHERE id=13");
$result = applyOrderStatus($pdo, 13, 'completed', 'customer');

echo json_encode($result, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE) . "\n";
$st = $pdo->query("SELECT status FROM orders WHERE id=13")->fetchColumn();
echo "DB status: $st\n";
exit($result['success'] ? 0 : 1);
