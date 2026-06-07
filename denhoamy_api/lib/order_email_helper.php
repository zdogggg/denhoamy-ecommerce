<?php
// =====================================================
// ORDER EMAIL HELPER - order_email_helper.php
// =====================================================
// Email xác nhận đơn hàng (COD ngay sau tạo đơn, PayOS sau webhook).
// =====================================================

require_once __DIR__ . '/resend_helper.php';
require_once __DIR__ . '/validator.php';

define('STORE_PICKUP_ADDRESS', '905 Nguyễn Văn Linh, An Biên, Hải Phòng');

/**
 * @return array|null ['order' => array, 'items' => array]
 */
function fetchOrderEmailData($pdo, $orderId)
{
    $stmt = $pdo->prepare('
        SELECT id, customer_name, phone, email, address, delivery_method, note,
               payment_method, total, coupon_code, discount_amount, status, created_at
        FROM orders
        WHERE id = ? AND deleted_at IS NULL
        LIMIT 1
    ');
    $stmt->execute([(int) $orderId]);
    $order = $stmt->fetch();

    if (!$order) {
        return null;
    }

    $itemStmt = $pdo->prepare('
        SELECT product_name, quantity, price
        FROM order_items
        WHERE order_id = ?
        ORDER BY id ASC
    ');
    $itemStmt->execute([(int) $orderId]);
    $items = $itemStmt->fetchAll();

    return ['order' => $order, 'items' => $items];
}

function formatDeliveryLabel($deliveryMethod)
{
    return ($deliveryMethod ?? 'home') === 'store'
        ? 'Nhận hàng tại cửa hàng'
        : 'Giao hàng tận nhà';
}

function formatOrderMoney($amount)
{
    return number_format((float) $amount, 0, ',', '.') . 'đ';
}

function formatPaymentMethodLabel($method)
{
    $labels = [
        'cod' => 'Thanh toán khi nhận hàng (COD)',
        'pay_at_store' => 'Thanh toán tại cửa hàng',
        'payos' => 'Thanh toán trực tuyến (PayOS)',
        'bank_transfer' => 'Chuyển khoản ngân hàng',
    ];

    return $labels[$method] ?? $method;
}

/**
 * @param array $order
 * @param array $items
 * @param string $emailType 'cod' | 'paid'
 */
function buildOrderConfirmationEmailHtml($order, $items, $emailType)
{
    $safeName = htmlspecialchars($order['customer_name'] ?: 'Quý khách', ENT_QUOTES, 'UTF-8');
    $orderId = (int) $order['id'];
    $deliveryMethod = $order['delivery_method'] ?? 'home';
    $deliveryLabel = formatDeliveryLabel($deliveryMethod);
    $safeDeliveryLabel = htmlspecialchars($deliveryLabel, ENT_QUOTES, 'UTF-8');
    $safeAddress = htmlspecialchars($order['address'] ?: '-', ENT_QUOTES, 'UTF-8');
    $safePhone = htmlspecialchars($order['phone'] ?: '-', ENT_QUOTES, 'UTF-8');
    $safeNote = htmlspecialchars(trim($order['note'] ?? ''), ENT_QUOTES, 'UTF-8');
    $paymentLabel = htmlspecialchars(formatPaymentMethodLabel($order['payment_method'] ?? 'cod'), ENT_QUOTES, 'UTF-8');
    $discount = (float) ($order['discount_amount'] ?? 0);
    $total = (float) $order['total'];
    $couponCode = trim($order['coupon_code'] ?? '');

    if ($emailType === 'paid') {
        $headline = 'Thanh toán thành công!';
        $intro = 'Cảm ơn bạn đã thanh toán. Đơn hàng của bạn đã được xác nhận và sẽ được xử lý sớm.';
    } else {
        $headline = 'Đặt hàng thành công!';
        $intro = 'Cảm ơn bạn đã đặt hàng tại Đèn Hoa Mỹ. Đơn hàng của bạn đã được ghi nhận. Bạn sẽ thanh toán khi nhận hàng.';
    }

    $itemsHtml = '';
    foreach ($items as $item) {
        $name = htmlspecialchars($item['product_name'] ?? 'Sản phẩm', ENT_QUOTES, 'UTF-8');
        $qty = (int) ($item['quantity'] ?? 1);
        $lineTotal = formatOrderMoney((float) ($item['price'] ?? 0) * $qty);
        $itemsHtml .= <<<ROW
        <tr>
          <td style="padding:10px 0;border-bottom:1px solid #eee;color:#333;font-size:14px;">{$name}</td>
          <td style="padding:10px 8px;border-bottom:1px solid #eee;color:#666;font-size:14px;text-align:center;">×{$qty}</td>
          <td style="padding:10px 0;border-bottom:1px solid #eee;color:#333;font-size:14px;text-align:right;">{$lineTotal}</td>
        </tr>
ROW;
    }

    if ($itemsHtml === '') {
        $itemsHtml = '<tr><td colspan="3" style="padding:10px 0;color:#999;font-size:14px;">Không có sản phẩm</td></tr>';
    }

    $noteBlock = $safeNote !== ''
        ? '<p style="margin:0 0 8px;color:#666;font-size:14px;"><strong>Ghi chú:</strong> ' . $safeNote . '</p>'
        : '';

    $discountBlock = $discount > 0
        ? '<tr><td colspan="2" style="padding:6px 0;color:#666;font-size:14px;">Giảm giá' . ($couponCode !== '' ? ' (' . htmlspecialchars($couponCode, ENT_QUOTES, 'UTF-8') . ')' : '') . '</td><td style="padding:6px 0;color:#67C23A;font-size:14px;text-align:right;">-' . formatOrderMoney($discount) . '</td></tr>'
        : '';

    $totalFormatted = formatOrderMoney($total);

    $paymentMethod = $order['payment_method'] ?? 'cod';
    $storeHint = '';
    if ($deliveryMethod === 'store') {
        $storeHint = '<p style="margin:8px 0 0;color:#666;font-size:13px;">Vui lòng mang theo mã đơn hàng khi đến nhận tại cửa hàng.</p>';
        if ($paymentMethod === 'pay_at_store') {
            $storeHint .= '<p style="margin:4px 0 0;color:#666;font-size:13px;">Thanh toán tiền mặt hoặc chuyển khoản khi đến quầy.</p>';
        }
    }

    return <<<HTML
<!DOCTYPE html>
<html lang="vi">
<head><meta charset="UTF-8"></head>
<body style="margin:0;padding:0;background:#f7f8fa;font-family:Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="max-width:560px;margin:40px auto;background:#fff;border-radius:12px;overflow:hidden;box-shadow:0 4px 24px rgba(0,0,0,0.08);">
    <tr>
      <td style="background:#111;padding:24px 32px;text-align:center;">
        <h1 style="margin:0;color:#D8B257;font-size:22px;">Đèn Hoa Mỹ</h1>
      </td>
    </tr>
    <tr>
      <td style="padding:32px;">
        <p style="margin:0 0 8px;color:#333;font-size:18px;font-weight:bold;">{$headline}</p>
        <p style="margin:0 0 20px;color:#666;font-size:14px;line-height:1.6;">Xin chào <strong>{$safeName}</strong>, {$intro}</p>
        <p style="margin:0 0 20px;color:#67C23A;font-size:20px;font-weight:bold;">Mã đơn hàng: #ORD-{$orderId}</p>

        <div style="background:#f9fbfd;border:1px solid #e8ecf0;border-radius:8px;padding:16px;margin-bottom:20px;">
          <p style="margin:0 0 12px;color:#111;font-size:14px;font-weight:bold;">Phương thức nhận hàng</p>
          <p style="margin:0 0 8px;color:#D8B257;font-size:15px;font-weight:bold;">{$safeDeliveryLabel}</p>
          <p style="margin:0 0 8px;color:#666;font-size:14px;"><strong>Địa chỉ:</strong> {$safeAddress}</p>
          <p style="margin:0 0 8px;color:#666;font-size:14px;"><strong>SĐT:</strong> {$safePhone}</p>
          <p style="margin:0 0 8px;color:#666;font-size:14px;"><strong>Thanh toán:</strong> {$paymentLabel}</p>
          {$noteBlock}
          {$storeHint}
        </div>

        <p style="margin:0 0 12px;color:#111;font-size:14px;font-weight:bold;">Chi tiết sản phẩm</p>
        <table width="100%" cellpadding="0" cellspacing="0" style="margin-bottom:16px;">
          <tr>
            <th style="padding:8px 0;border-bottom:2px solid #eee;color:#999;font-size:12px;text-align:left;">Sản phẩm</th>
            <th style="padding:8px 8px;border-bottom:2px solid #eee;color:#999;font-size:12px;text-align:center;">SL</th>
            <th style="padding:8px 0;border-bottom:2px solid #eee;color:#999;font-size:12px;text-align:right;">Thành tiền</th>
          </tr>
          {$itemsHtml}
          {$discountBlock}
          <tr>
            <td colspan="2" style="padding:12px 0 0;color:#111;font-size:15px;font-weight:bold;">Tổng cộng</td>
            <td style="padding:12px 0 0;color:#d93025;font-size:16px;font-weight:bold;text-align:right;">{$totalFormatted}</td>
          </tr>
        </table>

        <p style="margin:0;color:#999;font-size:12px;line-height:1.5;">
          Nếu có thắc mắc, vui lòng liên hệ shop qua hotline hoặc fanpage. Cảm ơn bạn đã tin tưởng Đèn Hoa Mỹ!
        </p>
      </td>
    </tr>
    <tr>
      <td style="padding:16px 32px;background:#f5f7fa;text-align:center;color:#999;font-size:11px;">
        © Đèn Hoa Mỹ — Email tự động, vui lòng không trả lời.
      </td>
    </tr>
  </table>
</body>
</html>
HTML;
}

/**
 * Gửi email xác nhận đơn hàng.
 *
 * @param string $emailType 'cod' | 'paid'
 * @return array ['success' => bool, 'message' => string, 'skipped' => bool]
 */
function sendOrderConfirmationEmail($pdo, $orderId, $emailType)
{
    if (!in_array($emailType, ['cod', 'paid'], true)) {
        return ['success' => false, 'message' => 'Loại email không hợp lệ.', 'skipped' => true];
    }

    $data = fetchOrderEmailData($pdo, $orderId);
    if (!$data) {
        return ['success' => false, 'message' => 'Không tìm thấy đơn hàng.', 'skipped' => true];
    }

    $order = $data['order'];
    $to = trim($order['email'] ?? '');

    if ($to === '' || !isValidEmail($to)) {
        return ['success' => false, 'message' => 'Khách hàng không có email hợp lệ.', 'skipped' => true];
    }

    $html = buildOrderConfirmationEmailHtml($order, $data['items'], $emailType);
    $orderNum = (int) $order['id'];

    if ($emailType === 'paid') {
        $subject = '[Đèn Hoa Mỹ] Thanh toán thành công — Đơn hàng #' . $orderNum;
    } else {
        $subject = '[Đèn Hoa Mỹ] Xác nhận đơn hàng #' . $orderNum;
    }

    $result = sendResendEmail($to, $subject, $html);
    $result['skipped'] = false;

    return $result;
}
