<?php
/**
 * RBAC map trung tâm cho API admin (phương án 2).
 * Gọi adminGuardRequire('key') hoặc adminGuardAuto() thay requireAdmin() tại từng nhánh admin.
 *
 * Trả về null từ resolve = không check (public). Ngược lại gọi requirePermission().
 */
require_once __DIR__ . '/auth_middleware.php';

/**
 * Map: tên file => [ METHOD => permission key | '*' => key ]
 * Chỉ khai báo method cần bảo vệ; GET không có trong map = public (vd. products.php).
 */
function getAdminRoutePermissionMap()
{
    return [
        'statistics.php' => ['*' => 'dashboard'],
        'settings.php' => ['PUT' => 'settings'],
        'inventory.php' => ['*' => 'products'],
        'products.php' => [
            'POST' => 'products',
            'PUT' => 'products',
            'DELETE' => 'products',
        ],
        'categories.php' => [
            'POST' => 'categories',
            'PUT' => 'categories',
            'DELETE' => 'categories',
        ],
        'orders.php' => [
            'POST' => 'orders',
            'PUT' => 'orders',
            'DELETE' => 'orders',
        ],
        'coupons.php' => [
            'GET' => 'coupons',
            'POST' => 'coupons',
            'PUT' => 'coupons',
            'DELETE' => 'coupons',
        ],
        'news.php' => [
            'POST' => 'news',
            'PUT' => 'news',
            'DELETE' => 'news',
        ],
        'reviews.php' => [
            'PUT' => 'reviews',
            'DELETE' => 'reviews',
        ],
    ];
}

/**
 * Logic đặc biệt theo query / ngữ cảnh (trả null = public).
 */
function resolveAdminRoutePermission($script, $method)
{
    $script = strtolower(basename($script));
    $method = strtoupper($method);

    if ($script === 'orders.php' && $method === 'GET') {
        if (($_GET['action'] ?? '') === 'payment_status') {
            return null;
        }
        if (trim($_GET['phone'] ?? '') === '') {
            return 'orders';
        }
        return null;
    }

    if ($script === 'reviews.php' && $method === 'GET') {
        if (!empty($_GET['product_id'])) {
            return null;
        }
        return 'reviews';
    }

    // Checkout: danh sách voucher công khai (POST apply xử lý trực tiếp trong coupons.php)
    if ($script === 'coupons.php' && $method === 'GET' && strtolower(trim((string) ($_GET['scope'] ?? ''))) === 'public') {
        return null;
    }

    if ($script === 'upload.php' && $method === 'POST') {
        return resolveUploadPermission();
    }

    $map = getAdminRoutePermissionMap();
    if (!isset($map[$script])) {
        return null;
    }

    $rules = $map[$script];
    if (isset($rules['*'])) {
        return $rules['*'];
    }

    return $rules[$method] ?? null;
}

/**
 * Upload type → permission (upload.php).
 */
function resolveUploadPermission()
{
    $type = $_POST['type'] ?? $_GET['type'] ?? 'product';
    $map = [
        'product' => 'products',
        'gallery' => 'products',
        'logo' => 'settings',
        'banner' => 'settings',
        'bank_qr' => 'settings',
        'news_content' => 'news',
        'avatar' => 'accounts',
    ];
    return $map[$type] ?? 'products';
}

/**
 * Tra cứu permission cho request hiện tại (không dừng script).
 */
function adminRoutePermissionKey()
{
    return resolveAdminRoutePermission(
        $_SERVER['SCRIPT_NAME'] ?? '',
        $_SERVER['REQUEST_METHOD'] ?? 'GET'
    );
}

/**
 * Bắt buộc một permission cụ thể (thay requireAdmin tại nhánh admin).
 *
 * @return array User đã xác thực
 */
function adminGuardRequire(string $permissionKey)
{
    return requirePermission($permissionKey);
}

/**
 * Tự resolve theo file + method (+ query). Không có map → không check.
 *
 * @return array|null User nếu đã check, null nếu public
 */
function adminGuardAuto()
{
    $key = adminRoutePermissionKey();
    if ($key === null) {
        return null;
    }
    return requirePermission($key);
}

/**
 * Staff/admin xem đơn theo SĐT — cần quyền orders (bổ sung cho nhánh requireLogin).
 */
function adminGuardOrdersPhoneAccess(array $authUser)
{
    if (!in_array($authUser['role'] ?? '', ['admin', 'staff'], true)) {
        return;
    }
    requirePermission('orders');
}
