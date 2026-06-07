<?php
// ====================================
// API UPLOAD ẢNH - upload.php
// ====================================
require_once 'db.php';
require_once __DIR__ . '/lib/auth_middleware.php';
require_once __DIR__ . '/lib/admin_route_guard.php';

$method = $_SERVER['REQUEST_METHOD'];

if ($method !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
    exit();
}

// Xác định loại upload: product, logo, banner, avatar
$type = $_POST['type'] ?? $_GET['type'] ?? 'product';

adminGuardRequire(resolveUploadPermission());

// Thư mục lưu trữ tương ứng
$uploadDirs = [
    'product' => 'uploads/products/',
    'logo' => 'uploads/logo/',
    'banner' => 'uploads/banners/',
    'avatar' => 'uploads/avatars/',
    'gallery' => 'uploads/products/',
    'news_content' => 'uploads/news/',
    'bank_qr' => 'uploads/logo/',
];

$subDir = $uploadDirs[$type] ?? 'uploads/misc/';
$uploadDir = __DIR__ . '/' . $subDir;

// Tạo thư mục nếu chưa tồn tại
if (!is_dir($uploadDir)) {
    mkdir($uploadDir, 0777, true);
}

// Xác định base URL (sử dụng đường dẫn tương đối để tương thích mọi IP/Docker proxy)
$baseUrl = '/' . $subDir;

// ====== UPLOAD TỪ FILE (multipart/form-data) ======
if (!empty($_FILES['file'])) {
    $file = $_FILES['file'];

    // Check upload errors (e.g. file too big for PHP limits)
    if ($file['error'] !== UPLOAD_ERR_OK) {
        $errorMsg = 'Lỗi upload ảnh (code: ' . $file['error'] . ')';
        if ($file['error'] === UPLOAD_ERR_INI_SIZE) {
            $errorMsg = 'File quá lớn. Vượt quá giới hạn cấu hình của PHP (upload_max_filesize).';
        }
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => $errorMsg]);
        exit();
    }

    // Validate file — kiểm tra MIME thực sự từ nội dung file (nếu hỗ trợ finfo)
    $allowedTypes = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
    $realMime = null;
    if (class_exists('finfo')) {
        try {
            $finfo = new finfo(FILEINFO_MIME_TYPE);
            $realMime = $finfo->file($file['tmp_name']);
        } catch (Exception $e) {
            $realMime = $file['type'];
        }
    } else {
        $realMime = $file['type'];
    }

    if (!$realMime || !in_array($realMime, $allowedTypes)) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'File không phải ảnh hợp lệ (JPEG, PNG, GIF, WebP)']);
        exit();
    }

    // Max 10MB
    if ($file['size'] > 10 * 1024 * 1024) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'File quá lớn. Tối đa 10MB']);
        exit();
    }

    // Tạo tên file unique
    $ext = pathinfo($file['name'], PATHINFO_EXTENSION) ?: 'jpg';
    $filename = uniqid($type . '_', true) . '.' . $ext;
    $filepath = $uploadDir . $filename;

    if (move_uploaded_file($file['tmp_name'], $filepath)) {
        echo json_encode([
            'success' => true,
            'url' => $baseUrl . $filename,
            'filename' => $filename
        ]);
    } else {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Lỗi lưu file']);
    }
    exit();
}

// ====== UPLOAD MULTIPLE FILES ======
if (!empty($_FILES['files'])) {
    $files = $_FILES['files'];
    $urls = [];

    for ($i = 0; $i < count($files['name']); $i++) {
        if ($files['error'][$i] !== UPLOAD_ERR_OK) {
            continue;
        }

        $allowedTypes = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
        $realMime = null;
        if (class_exists('finfo')) {
            try {
                $finfo = new finfo(FILEINFO_MIME_TYPE);
                $realMime = $finfo->file($files['tmp_name'][$i]);
            } catch (Exception $e) {
                $realMime = $files['type'][$i];
            }
        } else {
            $realMime = $files['type'][$i];
        }

        if (!$realMime || !in_array($realMime, $allowedTypes))
            continue;
        if ($files['size'][$i] > 10 * 1024 * 1024)
            continue;

        $ext = pathinfo($files['name'][$i], PATHINFO_EXTENSION) ?: 'jpg';
        $filename = uniqid($type . '_', true) . '.' . $ext;
        $filepath = $uploadDir . $filename;

        if (move_uploaded_file($files['tmp_name'][$i], $filepath)) {
            $urls[] = $baseUrl . $filename;
        }
    }

    echo json_encode([
        'success' => true,
        'urls' => $urls,
        'count' => count($urls)
    ]);
    exit();
}


// ====== UPLOAD TỪ BASE64 (JSON body) ======
$data = json_decode(file_get_contents('php://input'), true);
if (!empty($data['base64'])) {
    // Hỗ trợ cả data URI và raw base64
    $base64 = $data['base64'];

    // Detect format từ data URI
    $ext = 'jpg';
    if (preg_match('/^data:image\/(png|jpe?g|gif|webp);base64,/', $base64, $matches)) {
        $ext = $matches[1] === 'jpeg' ? 'jpg' : $matches[1];
        $base64 = preg_replace('/^data:image\/\w+;base64,/', '', $base64);
    }

    $decoded = base64_decode($base64);
    if ($decoded === false) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Dữ liệu base64 không hợp lệ']);
        exit();
    }

    // Max 10MB
    if (strlen($decoded) > 10 * 1024 * 1024) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Ảnh quá lớn. Tối đa 10MB']);
        exit();
    }

    $filename = uniqid($type . '_', true) . '.' . $ext;
    $filepath = $uploadDir . $filename;

    if (file_put_contents($filepath, $decoded)) {
        echo json_encode([
            'success' => true,
            'url' => $baseUrl . $filename,
            'filename' => $filename
        ]);
    } else {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Lỗi lưu file']);
    }
    exit();
}

// ====== UPLOAD MULTIPLE BASE64 (JSON array) ======
if (!empty($data['images']) && is_array($data['images'])) {
    $urls = [];
    foreach ($data['images'] as $imgData) {
        $base64 = $imgData;
        $ext = 'jpg';
        if (preg_match('/^data:image\/(png|jpe?g|gif|webp);base64,/', $base64, $matches)) {
            $ext = $matches[1] === 'jpeg' ? 'jpg' : $matches[1];
            $base64 = preg_replace('/^data:image\/\w+;base64,/', '', $base64);
        }

        $decoded = base64_decode($base64);
        if ($decoded === false || strlen($decoded) > 10 * 1024 * 1024)
            continue;

        $filename = uniqid($type . '_', true) . '.' . $ext;
        $filepath = $uploadDir . $filename;

        if (file_put_contents($filepath, $decoded)) {
            $urls[] = $baseUrl . $filename;
        }
    }

    echo json_encode([
        'success' => true,
        'urls' => $urls,
        'count' => count($urls)
    ]);
    exit();
}

http_response_code(400);
echo json_encode(['success' => false, 'message' => 'Không tìm thấy file hoặc dữ liệu ảnh']);
