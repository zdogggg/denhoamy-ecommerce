<?php
/**
 * PayOS E2E API test (chạy trong container API):
 *   docker cp scripts/payos_e2e_test.php denhoamy_api:/var/www/html/payos_e2e_test.php
 *   docker exec denhoamy_api php /var/www/html/payos_e2e_test.php
 */
require_once __DIR__ . '/db.php';
require_once __DIR__ . '/lib/jwt_helper.php';

$passed = 0;
$failed = 0;
$CUSTOMER_ID = 2;

function ok(string $m): void { global $passed; $passed++; echo "  OK  $m\n"; }
function bad(string $m, $d = ''): void {
    global $failed; $failed++;
    echo "  FAIL $m" . ($d ? ' — ' . (is_string($d) ? $d : json_encode($d, JSON_UNESCAPED_UNICODE)) : '') . "\n";
}

function httpJson(string $method, string $path, ?array $body, ?string $token): array {
    $headers = "Accept: application/json\r\n";
    if ($body !== null) $headers .= "Content-Type: application/json\r\n";
    if ($token) $headers .= "Authorization: Bearer $token\r\n";
    $ctx = stream_context_create(['http' => [
        'method' => $method, 'header' => $headers,
        'content' => $body !== null ? json_encode($body, JSON_UNESCAPED_UNICODE) : '',
        'ignore_errors' => true,
    ]]);
    $raw = @file_get_contents('http://127.0.0.1' . $path, false, $ctx);
    preg_match('/HTTP\/\d\.\d\s+(\d+)/', $http_response_header[0] ?? '', $m);
    return ['status' => (int)($m[1] ?? 0), 'data' => json_decode($raw ?: 'null', true)];
}

$u = $pdo->prepare('SELECT id, name FROM users WHERE id = ?');
$u->execute([$CUSTOMER_ID]);
$user = $u->fetch(PDO::FETCH_ASSOC);
$token = $user ? createCustomerToken($user) : null;
if (!$token) { bad('JWT'); exit(1); }
ok('JWT customer #' . $CUSTOMER_ID);

$pend = httpJson('GET', '/orders.php?action=pending_payos', null, $token);
$oldPending = (int)($pend['data']['data']['id'] ?? 0);
if ($oldPending > 0) {
    httpJson('PUT', '/orders.php', ['action' => 'cancel_pending', 'orderId' => $oldPending], $token);
    echo "  INFO cancelled leftover pending #$oldPending\n";
}

$product = $pdo->query('SELECT id, ten_san_pham, price, stock FROM products WHERE deleted_at IS NULL AND stock >= 2 AND id NOT IN (SELECT DISTINCT product_id FROM product_variants) ORDER BY id LIMIT 1')->fetch(PDO::FETCH_ASSOC);
if (!$product) {
    $product = $pdo->query('SELECT id, ten_san_pham, price, stock FROM products WHERE deleted_at IS NULL AND stock >= 2 ORDER BY id LIMIT 1')->fetch(PDO::FETCH_ASSOC);
}
if (!$product) { bad('no product'); exit(1); }

$pid = (int)$product['id'];
$stock0 = (int)$product['stock'];
echo "\nProduct #$pid stock=$stock0\n";

$payload = [
    'user_id' => $CUSTOMER_ID,
    'name' => 'E2E Test', 'phone' => '0866830716', 'email' => 'test@test.com',
    'address' => 'Test', 'deliveryMethod' => 'home', 'paymentMethod' => 'payos',
    'total' => 999999,
    'items' => [['id' => (string)$pid, 'name' => $product['ten_san_pham'], 'quantity' => 1, 'price' => (float)$product['price']]],
];

echo "\n[A] Create PayOS order\n";
$c1 = httpJson('POST', '/orders.php', $payload, $token);
$oid = (int)($c1['data']['orderId'] ?? 0);
if ($c1['status'] === 200 && ($c1['data']['success'] ?? false) && $oid > 0) {
    ok("created order #$oid");
} else { bad('create', $c1); exit(1); }

$stock1 = (int)$pdo->query("SELECT stock FROM products WHERE id=$pid")->fetchColumn();
if ($stock1 === $stock0 - 1) ok("stock deducted $stock0 → $stock1");
else bad("stock deduct expected " . ($stock0 - 1) . " got $stock1");

echo "\n[B] Duplicate → 409\n";
$c2 = httpJson('POST', '/orders.php', $payload, $token);
if ($c2['status'] === 409 && (int)($c2['data']['pendingOrderId'] ?? 0) === $oid) ok("409 pendingOrderId=$oid");
else bad('409', $c2);

echo "\n[C] pending_payos\n";
$p = httpJson('GET', '/orders.php?action=pending_payos', null, $token);
if ((int)($p['data']['data']['id'] ?? 0) === $oid) ok("pending_payos returns #$oid");
else bad('pending_payos', $p);

echo "\n[D] cancel_pending + stock restore\n";
$cancel = httpJson('PUT', '/orders.php', ['action' => 'cancel_pending', 'orderId' => $oid], $token);
if ($cancel['status'] === 200 && ($cancel['data']['success'] ?? false)) ok('cancelled');
else { bad('cancel', $cancel); exit(1); }

$stock2 = (int)$pdo->query("SELECT stock FROM products WHERE id=$pid")->fetchColumn();
if ($stock2 === $stock0) ok("stock restored $stock1 → $stock2");
else bad("stock restore expected $stock0 got $stock2");

$p2 = httpJson('GET', '/orders.php?action=pending_payos', null, $token);
if ($p2['data']['data'] === null) ok('pending_payos null after cancel');
else bad('pending should be null', $p2['data']);

echo "\n[E] Create again after cancel\n";
$c3 = httpJson('POST', '/orders.php', $payload, $token);
$oid2 = (int)($c3['data']['orderId'] ?? 0);
if ($c3['status'] === 200 && $oid2 > 0) ok("new order #$oid2");
else { bad('recreate', $c3); exit(1); }

if (!empty($c3['data']['checkoutUrl'])) {
    ok('PayOS checkoutUrl on create');
} else {
    echo "  WARN PayOS link: " . ($c3['data']['payosError'] ?? $c3['data']['message'] ?? 'none') . "\n";
}

echo "\n[F] retry_payos\n";
$retry = httpJson('POST', '/orders.php', ['action' => 'retry_payos', 'orderId' => $oid2], $token);
if ($retry['status'] === 200 && ($retry['data']['success'] ?? false) && !empty($retry['data']['checkoutUrl'])) {
    ok('retry_payos + checkoutUrl');
} else {
    echo "  WARN retry_payos: " . ($retry['data']['message'] ?? 'failed') . "\n";
}

echo "\n[G] Cleanup #$oid2\n";
httpJson('PUT', '/orders.php', ['action' => 'cancel_pending', 'orderId' => $oid2], $token);
ok('cleanup done');

echo "\n=== Results: $passed passed, $failed failed ===\n";
exit($failed > 0 ? 1 : 0);
