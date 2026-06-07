<?php
/**
 * Tính giảm giá voucher — dùng chung cho coupons.php (apply) và orders.php (đặt hàng).
 */

require_once __DIR__ . '/order_pricing.php';

function calculateOrderSubtotal(array $items): float
{
    $subtotal = 0.0;
    foreach ($items as $item) {
        $qty = max(1, (int) ($item['quantity'] ?? 1));
        $price = (float) ($item['price'] ?? 0);
        $subtotal += $price * $qty;
    }
    return round($subtotal, 0);
}

/**
 * Giá trị đơn để kiểm tra voucher — ưu tiên tính từ items (cùng logic đặt hàng).
 *
 * @param array<string, mixed> $data POST body: items[] và/hoặc order_value
 * @return array{success: bool, message?: string, order_value?: float}
 */
function resolveCouponOrderValue(PDO $pdo, array $data): array
{
    if (!empty($data['items']) && is_array($data['items'])) {
        try {
            $items = normalizeOrderItems($pdo, $data['items']);
            return ['success' => true, 'order_value' => calculateOrderSubtotal($items)];
        } catch (InvalidArgumentException $e) {
            return ['success' => false, 'message' => $e->getMessage()];
        }
    }

    if (!array_key_exists('order_value', $data)) {
        return ['success' => false, 'message' => 'Thiếu dữ liệu đơn hàng'];
    }

    return ['success' => true, 'order_value' => (float) $data['order_value']];
}

/**
 * @param array<string, mixed> $coupon Row từ bảng coupons
 */
function calculateDiscountFromCouponRow(array $coupon, float $orderValue): float
{
    $orderValue = max(0, round($orderValue, 0));
    $discountAmount = 0.0;

    $percent = (int) ($coupon['discount_percent'] ?? 0);
    $fixed = (float) ($coupon['discount_amount'] ?? 0);

    if ($percent > 0) {
        $discountAmount = $orderValue * ($percent / 100);
        $maxCap = (float) ($coupon['max_discount_amount'] ?? 0);
        if ($maxCap > 0 && $discountAmount > $maxCap) {
            $discountAmount = $maxCap;
        }
    } elseif ($fixed > 0) {
        $discountAmount = $fixed;
    }

    if ($discountAmount > $orderValue) {
        $discountAmount = $orderValue;
    }

    return round($discountAmount, 0);
}

/**
 * Kiểm tra & tính giảm cho mã (chưa tăng used_count — gọi khi tạo đơn).
 *
 * @return array{success: bool, message?: string, code?: string, discount_amount?: float, coupon_id?: int}
 */
function applyCouponByCode(PDO $pdo, string $code, float $orderValue, bool $forUpdate = false): array
{
    $code = strtoupper(trim($code));
    if ($code === '') {
        return ['success' => false, 'message' => 'Thiếu mã giảm giá'];
    }

    $today = date('Y-m-d');
    $lockSql = $forUpdate ? ' FOR UPDATE' : '';
    $stmt = $pdo->prepare('
        SELECT id, code, discount_percent, discount_amount, max_discount_amount, min_order_value,
               usage_limit, used_count, start_date, end_date
        FROM coupons
        WHERE code = ? AND is_active = 1' . $lockSql . '
    ');
    $stmt->execute([$code]);
    $coupon = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$coupon) {
        return ['success' => false, 'message' => 'Mã giảm giá không tồn tại hoặc đã bị khóa'];
    }

    if (($coupon['start_date'] && $today < $coupon['start_date']) || ($coupon['end_date'] && $today > $coupon['end_date'])) {
        return ['success' => false, 'message' => 'Mã giảm giá đã hết hạn hoặc chưa tới thời gian kích hoạt'];
    }

    if ($coupon['usage_limit'] && (int) $coupon['used_count'] >= (int) $coupon['usage_limit']) {
        return ['success' => false, 'message' => 'Mã giảm giá đã hết lượt sử dụng'];
    }

    $minOrder = (float) ($coupon['min_order_value'] ?? 0);
    if ($orderValue < $minOrder) {
        return [
            'success' => false,
            'message' => 'Đơn hàng chưa đạt giá trị tối thiểu: ' . number_format($minOrder, 0, ',', '.') . ' VNĐ',
        ];
    }

    $percent = (int) ($coupon['discount_percent'] ?? 0);
    if ($percent > 0) {
        $maxCap = (float) ($coupon['max_discount_amount'] ?? 0);
        if ($maxCap <= 0) {
            return [
                'success' => false,
                'message' => 'Mã giảm giá chưa được cấu hình đúng (thiếu giới hạn giảm tối đa). Vui lòng liên hệ cửa hàng.',
            ];
        }
    }

    $discountAmount = calculateDiscountFromCouponRow($coupon, $orderValue);

    return [
        'success' => true,
        'code' => $coupon['code'],
        'discount_amount' => $discountAmount,
        'coupon_id' => (int) $coupon['id'],
    ];
}
