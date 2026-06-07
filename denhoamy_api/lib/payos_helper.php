<?php
// =====================================================
// PAYOS HELPER - payos_helper.php
// =====================================================
// Tích hợp PayOS thanh toán trực tuyến (PHP thuần, không cần Composer).
// Sử dụng cURL + HMAC-SHA256 để tạo link thanh toán và xác thực webhook.
//
// API Docs: https://payos.vn/docs
// API Endpoint: https://api-merchant.payos.vn/v2/payment-requests
//
// Sử dụng:
//   require_once 'payos_helper.php';
//   $result = createPaymentLink(123, 50000, 'Thanh toan don hang', [...], $returnUrl, $cancelUrl);
// =====================================================

/**
 * Đọc biến môi trường — Apache mod_php đôi khi không expose qua getenv().
 */
function payosEnv(string $name): string
{
    $value = getenv($name);
    if ($value !== false && $value !== '') {
        return trim($value);
    }
    if (!empty($_ENV[$name])) {
        return trim((string) $_ENV[$name]);
    }
    if (!empty($_SERVER[$name])) {
        return trim((string) $_SERVER[$name]);
    }
    return '';
}

// Lấy credentials từ biến môi trường
define('PAYOS_CLIENT_ID', payosEnv('PAYOS_CLIENT_ID'));
define('PAYOS_API_KEY', payosEnv('PAYOS_API_KEY'));
define('PAYOS_CHECKSUM_KEY', payosEnv('PAYOS_CHECKSUM_KEY'));

// API Base URL
define('PAYOS_API_URL', 'https://api-merchant.payos.vn/v2/payment-requests');

// ====== TẠO CHỮ KÝ (SIGNATURE) ======

/**
 * Tạo chữ ký HMAC-SHA256 cho PayOS request.
 * PayOS yêu cầu chuỗi ký theo format:
 *   amount=$amount&cancelUrl=$cancelUrl&description=$description&orderCode=$orderCode&returnUrl=$returnUrl
 * (Sắp xếp theo thứ tự alphabet của key)
 *
 * @param int $orderCode Mã đơn hàng (unique)
 * @param int $amount Số tiền (VND)
 * @param string $description Nội dung thanh toán
 * @param string $returnUrl URL trả về khi thanh toán thành công
 * @param string $cancelUrl URL trả về khi hủy thanh toán
 * @return string Chữ ký HMAC-SHA256
 */
function createPayOSSignature($orderCode, $amount, $description, $returnUrl, $cancelUrl)
{
    // Sắp xếp theo alphabet: amount, cancelUrl, description, orderCode, returnUrl
    $dataString = "amount={$amount}&cancelUrl={$cancelUrl}&description={$description}&orderCode={$orderCode}&returnUrl={$returnUrl}";

    return hash_hmac('sha256', $dataString, PAYOS_CHECKSUM_KEY);
}

// ====== TẠO LINK THANH TOÁN ======

/**
 * Gọi PayOS API để tạo link thanh toán.
 *
 * @param int $orderCode Mã đơn hàng (unique, dạng số)
 * @param int $amount Số tiền thanh toán (VND, số nguyên)
 * @param string $description Mô tả đơn hàng (tối đa 25 ký tự)
 * @param array $items Danh sách sản phẩm: [['name' => '...', 'quantity' => 1, 'price' => 50000], ...]
 * @param string $returnUrl URL redirect khi thanh toán thành công
 * @param string $cancelUrl URL redirect khi hủy thanh toán
 * @param string|null $buyerName Tên người mua (optional)
 * @param string|null $buyerEmail Email người mua (optional)
 * @param string|null $buyerPhone SĐT người mua (optional)
 * @return array ['success' => bool, 'checkoutUrl' => string, 'data' => array] hoặc ['success' => false, 'message' => string]
 */
function createPaymentLink($orderCode, $amount, $description, $items, $returnUrl, $cancelUrl, $buyerName = null, $buyerEmail = null, $buyerPhone = null)
{
    // Validate credentials
    if (empty(PAYOS_CLIENT_ID) || empty(PAYOS_API_KEY) || empty(PAYOS_CHECKSUM_KEY)) {
        return ['success' => false, 'message' => 'PayOS credentials chưa được cấu hình.'];
    }

    // Cắt description xuống max 25 ký tự (yêu cầu PayOS)
    $description = mb_substr($description, 0, 25);

    // Tạo chữ ký
    $signature = createPayOSSignature($orderCode, $amount, $description, $returnUrl, $cancelUrl);

    // Chuẩn bị payload
    $payload = [
        'orderCode' => (int) $orderCode,
        'amount' => (int) $amount,
        'description' => $description,
        'items' => $items,
        'returnUrl' => $returnUrl,
        'cancelUrl' => $cancelUrl,
        'signature' => $signature
    ];

    // Thêm thông tin người mua nếu có
    if ($buyerName)
        $payload['buyerName'] = $buyerName;
    if ($buyerEmail)
        $payload['buyerEmail'] = $buyerEmail;
    if ($buyerPhone)
        $payload['buyerPhone'] = $buyerPhone;

    // Gọi API PayOS
    $ch = curl_init(PAYOS_API_URL);
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_POST => true,
        CURLOPT_TIMEOUT => 30,
        CURLOPT_HTTPHEADER => [
            'Content-Type: application/json',
            'x-client-id: ' . PAYOS_CLIENT_ID,
            'x-api-key: ' . PAYOS_API_KEY
        ],
        CURLOPT_POSTFIELDS => json_encode($payload)
    ]);

    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);

    if (curl_errno($ch)) {
        $error = curl_error($ch);
        return ['success' => false, 'message' => 'Lỗi kết nối PayOS: ' . $error];
    }

    $result = json_decode($response, true);

    // PayOS trả về code = "00" khi thành công
    if (isset($result['code']) && $result['code'] === '00' && isset($result['data']['checkoutUrl'])) {
        return [
            'success' => true,
            'checkoutUrl' => $result['data']['checkoutUrl'],
            'qrCode' => $result['data']['qrCode'] ?? '',
            'paymentLinkId' => $result['data']['paymentLinkId'] ?? '',
            'data' => $result['data']
        ];
    }

    // Lỗi từ PayOS
    return [
        'success' => false,
        'message' => $result['desc'] ?? $result['message'] ?? 'Lỗi không xác định từ PayOS',
        'code' => $result['code'] ?? 'unknown',
        'httpCode' => $httpCode
    ];
}

// ====== XÁC THỰC WEBHOOK ======

/**
 * Xác thực chữ ký webhook từ PayOS.
 * PayOS gửi webhook khi thanh toán thành công/thất bại.
 *
 * Cấu trúc webhook payload:
 * {
 *   "code": "00",
 *   "desc": "success",
 *   "data": {
 *     "orderCode": 123,
 *     "amount": 50000,
 *     "description": "...",
 *     "accountNumber": "...",
 *     "reference": "...",
 *     "transactionDateTime": "...",
 *     "paymentLinkId": "...",
 *     "code": "00",
 *     "desc": "success",
 *     "counterAccountBankId": "...",
 *     "counterAccountBankName": "...",
 *     "counterAccountName": "...",
 *     "counterAccountNumber": "...",
 *     "virtualAccountName": "...",
 *     "virtualAccountNumber": "..."
 *   },
 *   "signature": "..."
 * }
 *
 * @param array $webhookBody Dữ liệu webhook đã decode JSON
 * @return array|false Trả về data nếu hợp lệ, false nếu không hợp lệ
 */
/**
 * Tạo chuỗi ký webhook theo chuẩn PayOS (sort key alphabet, HMAC-SHA256).
 * @see https://payos.vn/docs/tich-hop-webhook/kiem-tra-du-lieu-voi-signature/
 */
function buildPayOSWebhookDataString(array $data): string
{
    ksort($data);
    $parts = [];
    foreach ($data as $key => $value) {
        if (in_array($value, ['undefined', 'null'], true) || $value === null) {
            $value = '';
        } elseif (is_bool($value)) {
            $value = $value ? 'true' : 'false';
        } elseif (is_array($value)) {
            $valueSortedElementObj = array_map(function ($ele) {
                if (is_array($ele)) {
                    ksort($ele);
                }
                return $ele;
            }, $value);
            $value = json_encode($valueSortedElementObj, JSON_UNESCAPED_UNICODE);
        } elseif (is_int($value) || is_float($value)) {
            $value = (string) $value;
        }
        $parts[] = $key . '=' . $value;
    }
    return implode('&', $parts);
}

function verifyWebhookSignature($webhookBody)
{
    if (!isset($webhookBody['data']) || !isset($webhookBody['signature'])) {
        return false;
    }

    $data = $webhookBody['data'];
    if (!is_array($data)) {
        return false;
    }

    $checksumKey = payosEnv('PAYOS_CHECKSUM_KEY') ?: PAYOS_CHECKSUM_KEY;
    if ($checksumKey === '') {
        return false;
    }

    $receivedSignature = trim((string) $webhookBody['signature']);
    $dataString = buildPayOSWebhookDataString($data);
    $expectedSignature = hash_hmac('sha256', $dataString, $checksumKey);

    if (hash_equals($expectedSignature, $receivedSignature)) {
        return $data;
    }

    return false;
}

/**
 * Lấy thông tin thanh toán theo orderCode.
 *
 * @param int $orderCode Mã đơn hàng
 * @return array Thông tin thanh toán từ PayOS
 */
function getPaymentInfo($orderCode)
{
    $url = PAYOS_API_URL . '/' . $orderCode;

    $ch = curl_init($url);
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_TIMEOUT => 15,
        CURLOPT_HTTPHEADER => [
            'x-client-id: ' . PAYOS_CLIENT_ID,
            'x-api-key: ' . PAYOS_API_KEY
        ]
    ]);

    $response = curl_exec($ch);

    return json_decode($response, true) ?: [];
}

/**
 * Hủy link thanh toán PayOS.
 * Gọi khi đơn hàng bị hủy (cron hoặc admin) để vô hiệu link còn active.
 *
 * API: POST https://api-merchant.payos.vn/v2/payment-requests/{orderCode}/cancel
 *
 * @param int $orderCode Mã đơn hàng (= order ID)
 * @param string $reason Lý do hủy (optional)
 * @return array ['success' => bool, 'message' => string]
 */
function cancelPaymentLink($orderCode, $reason = 'Đơn hàng đã bị hủy do quá thời hạn thanh toán')
{
    if (empty(PAYOS_CLIENT_ID) || empty(PAYOS_API_KEY)) {
        return ['success' => false, 'message' => 'PayOS credentials chưa được cấu hình.'];
    }

    $url = PAYOS_API_URL . '/' . $orderCode . '/cancel';

    $ch = curl_init($url);
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_POST => true,
        CURLOPT_TIMEOUT => 15,
        CURLOPT_HTTPHEADER => [
            'Content-Type: application/json',
            'x-client-id: ' . PAYOS_CLIENT_ID,
            'x-api-key: ' . PAYOS_API_KEY
        ],
        CURLOPT_POSTFIELDS => json_encode(['cancellationReason' => $reason])
    ]);

    $response = curl_exec($ch);

    if (curl_errno($ch)) {
        return ['success' => false, 'message' => 'Lỗi kết nối PayOS: ' . curl_error($ch)];
    }

    $result = json_decode($response, true);

    if (isset($result['code']) && $result['code'] === '00') {
        return ['success' => true, 'message' => 'Đã hủy link thanh toán PayOS thành công'];
    }

    return [
        'success' => false,
        'message' => $result['desc'] ?? $result['message'] ?? 'Lỗi hủy link PayOS'
    ];
}
