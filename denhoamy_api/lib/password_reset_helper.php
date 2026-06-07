<?php
// =====================================================
// PASSWORD RESET HELPER - password_reset_helper.php
// =====================================================

require_once __DIR__ . '/resend_helper.php';

define('PASSWORD_RESET_TOKEN_TTL_MINUTES', 30);

/**
 * Vô hiệu hóa token reset chưa dùng của user.
 */
function invalidatePasswordResetTokens($pdo, $userId)
{
    $stmt = $pdo->prepare('
        UPDATE password_reset_tokens
        SET used_at = NOW()
        WHERE user_id = ? AND used_at IS NULL
    ');
    $stmt->execute([(int) $userId]);
}

/**
 * Tạo token reset mới. Trả về raw token (chỉ dùng 1 lần để gửi email).
 *
 * @return string|false
 */
function createPasswordResetToken($pdo, $userId)
{
    invalidatePasswordResetTokens($pdo, $userId);

    $rawToken = bin2hex(random_bytes(32));
    $tokenHash = hash('sha256', $rawToken);
    $expiresAt = date('Y-m-d H:i:s', time() + PASSWORD_RESET_TOKEN_TTL_MINUTES * 60);

    $stmt = $pdo->prepare('
        INSERT INTO password_reset_tokens (user_id, token_hash, expires_at)
        VALUES (?, ?, ?)
    ');
    $stmt->execute([(int) $userId, $tokenHash, $expiresAt]);

    return $rawToken;
}

/**
 * Xác thực token và trả về thông tin user.
 *
 * @return array|false
 */
function validatePasswordResetToken($pdo, $rawToken)
{
    if (empty($rawToken) || strlen($rawToken) !== 64) {
        return false;
    }

    $tokenHash = hash('sha256', $rawToken);

    $stmt = $pdo->prepare('
        SELECT t.id AS token_id, t.user_id, t.expires_at, t.used_at,
               u.id, u.name, u.email, u.phone, u.is_locked
        FROM password_reset_tokens t
        INNER JOIN users u ON u.id = t.user_id
        WHERE t.token_hash = ?
        LIMIT 1
    ');
    $stmt->execute([$tokenHash]);
    $row = $stmt->fetch();

    if (!$row) {
        return false;
    }

    if (!empty($row['used_at'])) {
        return false;
    }

    if (strtotime($row['expires_at']) < time()) {
        return false;
    }

    if (!empty($row['is_locked'])) {
        return false;
    }

    return $row;
}

/**
 * Đánh dấu token đã sử dụng.
 */
function markTokenUsed($pdo, $rawToken)
{
    $tokenHash = hash('sha256', $rawToken);
    $stmt = $pdo->prepare('
        UPDATE password_reset_tokens
        SET used_at = NOW()
        WHERE token_hash = ? AND used_at IS NULL
    ');
    $stmt->execute([$tokenHash]);
}

/**
 * HTML email đặt lại mật khẩu.
 */
function buildPasswordResetEmailHtml($name, $resetUrl)
{
    $safeName = htmlspecialchars($name ?: 'Quý khách', ENT_QUOTES, 'UTF-8');
    $safeUrl = htmlspecialchars($resetUrl, ENT_QUOTES, 'UTF-8');
    $ttl = PASSWORD_RESET_TOKEN_TTL_MINUTES;

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
        <p style="margin:0 0 16px;color:#333;font-size:16px;">Xin chào <strong>{$safeName}</strong>,</p>
        <p style="margin:0 0 24px;color:#666;font-size:14px;line-height:1.6;">
          Bạn vừa yêu cầu đặt lại mật khẩu. Nhấn nút bên dưới để tạo mật khẩu mới (link hết hạn sau {$ttl} phút).
        </p>
        <p style="text-align:center;margin:0 0 24px;">
          <a href="{$safeUrl}" style="display:inline-block;background:#111;color:#D8B257;text-decoration:none;padding:14px 32px;border-radius:8px;font-weight:bold;font-size:15px;">
            Đặt lại mật khẩu
          </a>
        </p>
        <p style="margin:0;color:#999;font-size:12px;line-height:1.5;">
          Nếu bạn không yêu cầu, hãy bỏ qua email này. Mật khẩu của bạn sẽ không thay đổi.
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
 * Gửi email magic link đặt lại mật khẩu.
 *
 * @return array Kết quả từ sendResendEmail
 */
function sendPasswordResetEmail($to, $name, $resetUrl)
{
    $subject = '[Đèn Hoa Mỹ] Đặt lại mật khẩu';
    $html = buildPasswordResetEmailHtml($name, $resetUrl);

    return sendResendEmail($to, $subject, $html);
}

/**
 * Message chung khi request reset (chống enumerate SĐT).
 */
function passwordResetRequestMessage()
{
    return 'Nếu số điện thoại hợp lệ, chúng tôi đã gửi link đặt lại mật khẩu tới email đăng ký của bạn. Vui lòng kiểm tra hộp thư (kể cả thư rác).';
}
