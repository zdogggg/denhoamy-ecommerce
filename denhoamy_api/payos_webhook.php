<?php
// =====================================================
// PAYOS WEBHOOK - payos_webhook.php
// =====================================================
// Nhận callback từ PayOS khi khách thanh toán thành công/thất bại.
// PayOS gọi POST tới endpoint này với payload chứa thông tin giao dịch.
//
// Khi thanh toán thành công:
//   1. Xác thực chữ ký webhook (chống giả mạo)
//   2. Tìm đơn hàng theo orderCode
//   3. So khớp số tiền với tổng đơn
//   4. Cập nhật orders.status → 'approved'
//   5. Cập nhật payments.status → 'completed'
//
// Setup: Cấu hình webhook URL trong PayOS Dashboard
//        VD: https://yourdomain.com/payos_webhook.php
// =====================================================

require_once 'db.php';
require_once __DIR__ . '/lib/payos_helper.php';

// Chỉ chấp nhận POST
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
    exit();
}

// Đọc body webhook
$rawBody = file_get_contents('php://input');
$webhookData = json_decode($rawBody, true);

// Guard: body rỗng hoặc không phải JSON hợp lệ
if (empty($webhookData) || !is_array($webhookData)) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Invalid webhook payload']);
    exit();
}

// Log webhook nhận được (để debug)
logInfo('PayOS Webhook received', [
    'code' => $webhookData['code'] ?? '-',
    'desc' => $webhookData['desc'] ?? '-',
    'orderCode' => $webhookData['data']['orderCode'] ?? '-'
]);

// ====== XÁC THỰC CHỮ KÝ ======
$verifiedData = verifyWebhookSignature($webhookData);

if ($verifiedData === false) {
    logWarning('PayOS Webhook: Chữ ký không hợp lệ (có thể bị giả mạo)', [
        'raw_body' => mb_substr($rawBody, 0, 500)
    ]);
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Invalid signature']);
    exit();
}

// ====== XỬ LÝ THANH TOÁN ======
$orderCode = (int) ($verifiedData['orderCode'] ?? 0);
$amount = (int) ($verifiedData['amount'] ?? 0);
$paymentCode = $verifiedData['code'] ?? '';
$paymentDesc = $verifiedData['desc'] ?? '';
$reference = $verifiedData['reference'] ?? '';
$transactionDateTime = $verifiedData['transactionDateTime'] ?? '';

// Tìm đơn hàng theo orderCode (= order ID)
$stmt = $pdo->prepare('SELECT id, status, total, payment_method FROM orders WHERE id = ?');
$stmt->execute([$orderCode]);
$order = $stmt->fetch();

if (!$order) {
    logWarning('PayOS Webhook: Không tìm thấy đơn hàng', ['orderCode' => $orderCode]);
    http_response_code(200);
    echo json_encode(['success' => false, 'message' => 'Order not found']);
    exit();
}

// So khớp số tiền webhook với tổng đơn hàng
$orderTotal = (int) round((float) $order['total']);
if ($amount > 0 && $orderTotal > 0 && $amount !== $orderTotal) {
    logWarning('PayOS Webhook: Số tiền không khớp', [
        'order_id' => $orderCode,
        'webhook_amount' => $amount,
        'order_total' => $orderTotal
    ]);
    http_response_code(200);
    echo json_encode(['success' => false, 'message' => 'Amount mismatch']);
    exit();
}

$dbUpdateFailed = false;

// Kiểm tra code = "00" nghĩa là thanh toán thành công
if ($paymentCode === '00') {
    // Chỉ cập nhật nếu đơn đang ở trạng thái pending
    if ($order['status'] === 'pending') {
        $pdo->beginTransaction();
        try {
            // Cập nhật trạng thái đơn hàng → approved (đã thanh toán)
            $pdo->prepare('UPDATE orders SET status = ? WHERE id = ?')
                ->execute(['approved', $orderCode]);

            // Cập nhật bảng payments → completed
            $pdo->prepare('UPDATE payments SET status = ?, payment_code = ? WHERE order_id = ? AND method = ?')
                ->execute(['completed', $reference, $orderCode, 'payos']);

            $pdo->commit();

            logInfo('PayOS: Thanh toán thành công - Đơn hàng tự động duyệt', [
                'order_id' => $orderCode,
                'amount' => $amount,
                'reference' => $reference,
                'transaction_time' => $transactionDateTime
            ]);

            require_once __DIR__ . '/lib/order_email_helper.php';
            try {
                $mailResult = sendOrderConfirmationEmail($pdo, $orderCode, 'paid');
                if (!empty($mailResult['skipped'])) {
                    logWarning('Order paid confirmation email skipped', [
                        'order_id' => $orderCode,
                        'reason' => $mailResult['message'] ?? 'unknown'
                    ]);
                } elseif ($mailResult['success']) {
                    logInfo('Order paid confirmation email sent', [
                        'order_id' => $orderCode,
                        'resend_id' => $mailResult['id'] ?? null
                    ]);
                } else {
                    logWarning('Order paid confirmation email failed', [
                        'order_id' => $orderCode,
                        'error' => $mailResult['message'] ?? 'unknown'
                    ]);
                }
            } catch (Exception $e) {
                logException($e, ['action' => 'order_paid_confirmation_email', 'order_id' => $orderCode]);
            }
        } catch (Exception $e) {
            $pdo->rollBack();
            $dbUpdateFailed = true;
            logException($e, ['action' => 'payos_webhook', 'order_id' => $orderCode]);
        }
    } else {
        logInfo('PayOS Webhook: Đơn hàng đã được xử lý trước đó', [
            'order_id' => $orderCode,
            'current_status' => $order['status']
        ]);
    }
} else {
    // Thanh toán thất bại
    logWarning('PayOS: Thanh toán thất bại', [
        'order_id' => $orderCode,
        'code' => $paymentCode,
        'desc' => $paymentDesc
    ]);

    if ($order['status'] === 'pending') {
        try {
            $pdo->prepare('UPDATE payments SET status = ? WHERE order_id = ? AND method = ?')
                ->execute(['failed', $orderCode, 'payos']);
        } catch (Exception $e) {
            logException($e, ['action' => 'payos_webhook_failed', 'order_id' => $orderCode]);
        }
    }
}

// DB lỗi → trả 503 để PayOS retry webhook
if ($dbUpdateFailed) {
    http_response_code(503);
    echo json_encode(['success' => false, 'message' => 'Database update failed, please retry']);
    exit();
}

http_response_code(200);
echo json_encode(['success' => true, 'message' => 'Webhook processed']);
