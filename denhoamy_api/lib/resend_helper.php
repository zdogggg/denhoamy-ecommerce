<?php
// =====================================================
// RESEND HELPER - resend_helper.php
// =====================================================
// Gửi email transactional qua Resend API (PHP thuần + cURL).
// Docs: https://resend.com/docs/api-reference/emails/send-email
// =====================================================

define('RESEND_API_KEY', getenv('RESEND_API_KEY') ?: '');
define('RESEND_FROM_EMAIL', getenv('RESEND_FROM_EMAIL') ?: '');
define('RESEND_FROM_NAME', getenv('RESEND_FROM_NAME') ?: 'Đèn Hoa Mỹ');
define('RESEND_API_URL', 'https://api.resend.com/emails');

/**
 * Gửi email qua Resend.
 *
 * @param string $to Email người nhận
 * @param string $subject Tiêu đề
 * @param string $html Nội dung HTML
 * @param string|null $replyTo Reply-to (optional)
 * @return array ['success' => bool, 'message' => string, 'id' => string|null]
 */
function sendResendEmail($to, $subject, $html, $replyTo = null)
{
    if (empty(RESEND_API_KEY)) {
        return ['success' => false, 'message' => 'Resend API key chưa được cấu hình.', 'id' => null];
    }

    if (empty(RESEND_FROM_EMAIL)) {
        return ['success' => false, 'message' => 'Resend FROM email chưa được cấu hình.', 'id' => null];
    }

    $to = trim($to);
    if ($to === '' || !filter_var($to, FILTER_VALIDATE_EMAIL)) {
        return ['success' => false, 'message' => 'Email người nhận không hợp lệ.', 'id' => null];
    }

    $fromName = RESEND_FROM_NAME;
    $from = $fromName !== ''
        ? $fromName . ' <' . RESEND_FROM_EMAIL . '>'
        : RESEND_FROM_EMAIL;

    $payload = [
        'from' => $from,
        'to' => [$to],
        'subject' => $subject,
        'html' => $html
    ];

    if ($replyTo && filter_var($replyTo, FILTER_VALIDATE_EMAIL)) {
        $payload['reply_to'] = $replyTo;
    }

    $ch = curl_init(RESEND_API_URL);
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_POST => true,
        CURLOPT_TIMEOUT => 30,
        CURLOPT_HTTPHEADER => [
            'Content-Type: application/json',
            'Authorization: Bearer ' . RESEND_API_KEY
        ],
        CURLOPT_POSTFIELDS => json_encode($payload)
    ]);

    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);

    if (curl_errno($ch)) {
        return [
            'success' => false,
            'message' => 'Lỗi kết nối Resend: ' . curl_error($ch),
            'id' => null
        ];
    }

    $result = json_decode($response, true);

    if ($httpCode >= 200 && $httpCode < 300 && !empty($result['id'])) {
        return [
            'success' => true,
            'message' => 'Email đã được gửi.',
            'id' => $result['id']
        ];
    }

    $errorMessage = $result['message'] ?? $result['error'] ?? 'Lỗi không xác định từ Resend';

    return [
        'success' => false,
        'message' => $errorMessage,
        'id' => null,
        'httpCode' => $httpCode
    ];
}
