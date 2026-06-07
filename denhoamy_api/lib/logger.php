<?php
// =====================================================
// ERROR LOGGING CHUẨN - logger.php
// =====================================================
// Ghi log có cấu trúc (structured logging) vào file.
// Mỗi dòng log bao gồm: timestamp, level, message, context
//
// Sử dụng:
//   require_once 'logger.php';
//   logInfo('Tạo đơn hàng thành công', ['order_id' => 123]);
//   logError('Lỗi thanh toán', ['error' => $e->getMessage()]);
// =====================================================

// Đường dẫn file log (trong container Docker)
define('LOG_DIR', dirname(__DIR__) . '/logs');
define('LOG_FILE', LOG_DIR . '/app.log');
define('ERROR_LOG_FILE', LOG_DIR . '/error.log');

// Tự động tạo thư mục logs nếu chưa có
if (!is_dir(LOG_DIR)) {
    mkdir(LOG_DIR, 0755, true);
}

// ====== CÁC CẤP ĐỘ LOG ======

/**
 * Ghi log mức INFO - Hoạt động bình thường
 * VD: Tạo đơn hàng, đăng nhập thành công, cập nhật sản phẩm
 */
function logInfo($message, $context = [])
{
    writeLog('INFO', $message, $context);
}

/**
 * Ghi log mức WARNING - Có vấn đề nhưng hệ thống vẫn chạy
 * VD: Rate limit gần đạt ngưỡng, dữ liệu thiếu trường optional
 */
function logWarning($message, $context = [])
{
    writeLog('WARNING', $message, $context);
}

/**
 * Ghi log mức ERROR - Lỗi cần sửa gấp
 * VD: Query database lỗi, kết nối API ngoài timeout
 */
function logError($message, $context = [])
{
    writeLog('ERROR', $message, $context, true);
}

/**
 * Ghi log mức DEBUG - Thông tin chi tiết khi phát triển
 * VD: Giá trị biến, SQL query đang chạy
 */
function logDebug($message, $context = [])
{
    // Chỉ ghi debug khi bật chế độ debug (qua biến môi trường)
    if (getenv('APP_DEBUG') === 'true') {
        writeLog('DEBUG', $message, $context);
    }
}

/**
 * Ghi log cho request API (access log)
 * Tự động ghi: method, URI, IP, user-agent, response time
 */
function logApiRequest($statusCode = 200, $extra = [])
{
    $duration = defined('APP_START_TIME')
        ? round((microtime(true) - APP_START_TIME) * 1000, 2) . 'ms'
        : '-';

    $context = array_merge([
        'method' => $_SERVER['REQUEST_METHOD'] ?? '-',
        'uri' => $_SERVER['REQUEST_URI'] ?? '-',
        'status' => $statusCode,
        'ip' => $_SERVER['REMOTE_ADDR'] ?? '-',
        'user_agent' => substr($_SERVER['HTTP_USER_AGENT'] ?? '-', 0, 100),
        'duration' => $duration
    ], $extra);

    writeLog('ACCESS', $context['method'] . ' ' . $context['uri'] . ' → ' . $statusCode, $context);
}

/**
 * Log exception (catch block)
 * Ghi đầy đủ: message, file, line, trace
 */
function logException($exception, $context = [])
{
    $context = array_merge([
        'exception' => get_class($exception),
        'file' => $exception->getFile() . ':' . $exception->getLine(),
        'trace' => array_slice(explode("\n", $exception->getTraceAsString()), 0, 5)
    ], $context);

    writeLog('ERROR', $exception->getMessage(), $context, true);
}

// ====== CORE: HÀM GHI LOG ======

/**
 * Ghi một dòng log vào file
 * Format: [2026-05-12 21:20:00] [INFO] Message | {"context": "data"}
 *
 * @param string $level    Cấp độ: INFO, WARNING, ERROR, DEBUG, ACCESS
 * @param string $message  Nội dung log
 * @param array  $context  Dữ liệu đi kèm (JSON)
 * @param bool   $isError  Ghi thêm vào error.log
 */
function writeLog($level, $message, $context = [], $isError = false)
{
    $timestamp = date('Y-m-d H:i:s');
    $contextJson = !empty($context) ? ' | ' . json_encode($context, JSON_UNESCAPED_UNICODE) : '';
    $logLine = "[$timestamp] [$level] $message$contextJson" . PHP_EOL;

    // Ghi vào app.log (tất cả log)
    file_put_contents(LOG_FILE, $logLine, FILE_APPEND | LOCK_EX);

    // Ghi thêm vào error.log nếu là lỗi
    if ($isError) {
        file_put_contents(ERROR_LOG_FILE, $logLine, FILE_APPEND | LOCK_EX);
    }

    // Tự động xoay log khi file quá lớn (> 5MB)
    rotateLogIfNeeded(LOG_FILE);
    rotateLogIfNeeded(ERROR_LOG_FILE);
}

/**
 * Xoay file log khi vượt quá kích thước (Log Rotation)
 * Đổi tên file cũ thành .bak, tạo file mới
 */
function rotateLogIfNeeded($file, $maxSize = 5 * 1024 * 1024)
{
    if (file_exists($file) && filesize($file) > $maxSize) {
        $backupFile = $file . '.' . date('Y-m-d_His') . '.bak';
        rename($file, $backupFile);

        // Giữ tối đa 5 file backup
        $dir = dirname($file);
        $baseName = basename($file);
        $backups = glob($dir . '/' . $baseName . '.*.bak');
        if (count($backups) > 5) {
            rsort($backups);
            foreach (array_slice($backups, 5) as $old) {
                unlink($old);
            }
        }
    }
}
