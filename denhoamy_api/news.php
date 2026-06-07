<?php
// ====================================
// API QUẢN LÝ TIN TỨC - news.php
// ====================================
require_once 'db.php';
require_once __DIR__ . '/lib/auth_middleware.php';
require_once __DIR__ . '/lib/validator.php';
require_once __DIR__ . '/lib/admin_route_guard.php';

$method = $_SERVER['REQUEST_METHOD'];

// ====== GET: Lấy danh sách hoặc 1 bài viết ======
if ($method === 'GET') {
    if (isset($_GET['slug'])) {
        // Lấy 1 bài viết theo slug
        $stmt = $pdo->prepare('SELECT n.*, a.name as author_name FROM news n LEFT JOIN admins a ON n.author_id = a.id WHERE n.slug = ? AND n.deleted_at IS NULL');
        $stmt->execute([$_GET['slug']]);
        $post = $stmt->fetch(PDO::FETCH_ASSOC);

        if ($post) {
            $is_admin_preview = isset($_GET['admin']) && $_GET['admin'] == '1';
            if ($is_admin_preview) {
                adminGuardRequire('news');
            }
            if (!$is_admin_preview) {
                $upd = $pdo->prepare('UPDATE news SET view_count = view_count + 1 WHERE id = ?');
                $upd->execute([$post['id']]);
                $post['view_count']++;
            }
            echo json_encode(['success' => true, 'data' => $post]);
        } else {
            http_response_code(404);
            echo json_encode(['success' => false, 'message' => 'Không tìm thấy bài viết']);
        }
    } else {
        // Lấy danh sách
        $is_admin = isset($_GET['admin']) && $_GET['admin'] == '1';
        if ($is_admin) {
            adminGuardRequire('news');
        }
        $sql = 'SELECT n.id, n.title, n.slug, n.thumbnail, n.summary, n.is_published, n.view_count, n.created_at, a.name as author_name 
                FROM news n LEFT JOIN admins a ON n.author_id = a.id ';

        if (!$is_admin) {
            $sql .= 'WHERE n.is_published = 1 AND n.deleted_at IS NULL ';
        } else {
            $sql .= 'WHERE n.deleted_at IS NULL ';
        }
        $sql .= 'ORDER BY n.created_at DESC';

        $stmt = $pdo->query($sql);
        echo json_encode(['success' => true, 'data' => $stmt->fetchAll(PDO::FETCH_ASSOC)]);
    }
    exit();
}

// ====== POST: Thêm bài viết mới ======
if ($method === 'POST') {
    // === Middleware: Yêu cầu quyền Admin ===
    adminGuardAuto();

    $data = json_decode(file_get_contents('php://input'), true);

    // === Input Validation ===
    $errors = validateNews($data);
    if (!empty($errors)) {
        respondValidationError($errors);
    }

    // === Sanitize ===
    $title = sanitizeString($data['title'] ?? '');
    $slug = sanitizeString($data['slug'] ?? '');
    $thumbnail = sanitizeString($data['thumbnail'] ?? '');
    $summary = sanitizeString($data['summary'] ?? '');
    $content = $data['content'] ?? ''; // raw HTML content
    $author_id = sanitizeInt($data['author_id'] ?? 0) ?: null;
    $is_published = sanitizeInt($data['is_published'] ?? 1);

    try {
        $stmt = $pdo->prepare('INSERT INTO news (title, slug, thumbnail, summary, content, author_id, is_published) VALUES (?, ?, ?, ?, ?, ?, ?)');
        $stmt->execute([$title, $slug, $thumbnail, $summary, $content, $author_id, $is_published]);
        echo json_encode(['success' => true, 'message' => 'Tạo bài viết thành công']);
    } catch (PDOException $e) {
        http_response_code(500);
        if ($e->getCode() == 23000) {
            echo json_encode(['success' => false, 'message' => 'Lỗi: Đường dẫn (Slug) đã tồn tại.']);
        } else {
            echo json_encode(['success' => false, 'message' => 'Lỗi DB: ' . $e->getMessage()]);
        }
    }
    exit();
}

// ====== PUT: Cập nhật bài viết ======
if ($method === 'PUT') {
    // === Middleware: Yêu cầu quyền Admin ===
    adminGuardAuto();

    $data = json_decode(file_get_contents('php://input'), true);
    $id = $data['id'] ?? null;
    $title = $data['title'] ?? '';
    $slug = $data['slug'] ?? '';
    $thumbnail = $data['thumbnail'] ?? '';
    $summary = $data['summary'] ?? '';
    $content = $data['content'] ?? '';
    $is_published = $data['is_published'] ?? 1;

    if (!$id) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Thiếu ID bài viết']);
        exit();
    }

    // Chỉ bật/tắt hiển thị (danh sách admin không gửi content)
    if (!isset($data['title']) && !isset($data['slug']) && !isset($data['content'])) {
        try {
            $stmt = $pdo->prepare('UPDATE news SET is_published = ? WHERE id = ? AND deleted_at IS NULL');
            $stmt->execute([$is_published, $id]);
            echo json_encode(['success' => true, 'message' => 'Cập nhật trạng thái thành công']);
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => 'Lỗi DB: ' . $e->getMessage()]);
        }
        exit();
    }

    if (!$title || !$slug || !$content) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Thiếu dữ liệu bắt buộc']);
        exit();
    }

    try {
        $stmt = $pdo->prepare('UPDATE news SET title = ?, slug = ?, thumbnail = ?, summary = ?, content = ?, is_published = ? WHERE id = ?');
        $stmt->execute([$title, $slug, $thumbnail, $summary, $content, $is_published, $id]);
        echo json_encode(['success' => true, 'message' => 'Cập nhật bài viết thành công']);
    } catch (PDOException $e) {
        http_response_code(500);
        if ($e->getCode() == 23000) {
            echo json_encode(['success' => false, 'message' => 'Lỗi: Đường dẫn (Slug) đã tồn tại cho bài khác.']);
        } else {
            echo json_encode(['success' => false, 'message' => 'Lỗi DB: ' . $e->getMessage()]);
        }
    }
    exit();
}

// ====== DELETE: Xóa bài viết ======
if ($method === 'DELETE') {
    // === Middleware: Yêu cầu quyền Admin ===
    adminGuardAuto();

    $id = $_GET['id'] ?? null;
    if (!$id) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Thiếu ID']);
        exit();
    }
    // Soft Delete: đánh dấu xóa thay vì xóa thật
    $stmt = $pdo->prepare('UPDATE news SET deleted_at = NOW() WHERE id = ?');
    $stmt->execute([$id]);
    echo json_encode(['success' => true, 'message' => 'Đã xóa bài viết']);
    exit();
}

http_response_code(405);
echo json_encode(['success' => false, 'message' => 'Method not allowed']);
