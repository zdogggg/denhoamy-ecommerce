<?php
// ====================================
// API SẢN PHẨM - products.php
// ====================================
require_once 'db.php';
require_once __DIR__ . '/lib/auth_middleware.php';
require_once __DIR__ . '/lib/admin_route_guard.php';
require_once __DIR__ . '/lib/products_filters.php';
require_once __DIR__ . '/lib/hot_deal_snapshot.php';

/** Số sản phẩm Hot Deal tối đa (đồng bộ trang chủ + admin) */
const HOT_DEAL_MAX = 10;

$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'GET') {
    // Lấy danh sách sản phẩm Hot Deal
    if (isset($_GET['hot_deal'])) {
        $stmt = $pdo->query('
            SELECT p.id, p.ten_san_pham, p.ma_san_pham, p.loai_den, p.price, p.old_price, p.cost_price, p.is_hot_deal, p.image_url, p.stock, p.created_at
            FROM products p
            WHERE p.is_hot_deal = 1 AND p.deleted_at IS NULL
            ORDER BY p.id DESC
        ');
        $hotDeals = $stmt->fetchAll(PDO::FETCH_ASSOC);
        if (!empty($hotDeals)) {
            $productIds = array_column($hotDeals, 'id');
            $placeholders = implode(',', array_fill(0, count($productIds), '?'));
            $vStmt = $pdo->prepare("SELECT id, product_id, kich_thuoc, anh_sang, price, cost_price, stock FROM product_variants WHERE product_id IN ($placeholders)");
            $vStmt->execute($productIds);
            $allVariants = $vStmt->fetchAll(PDO::FETCH_ASSOC);

            $variantsByProduct = [];
            foreach ($allVariants as $v) {
                $variantsByProduct[$v['product_id']][] = $v;
            }

            foreach ($hotDeals as &$p) {
                $p['variants'] = $variantsByProduct[$p['id']] ?? [];
            }
        }
        echo json_encode(['success' => true, 'data' => $hotDeals]);
        exit();
    }

    // Lấy 1 sản phẩm theo ID
    if (isset($_GET['id'])) {
        $stmt = $pdo->prepare('
            SELECT p.*, s.phong_cach, s.khong_gian_lap_dat, s.bong_den, s.dien_ap, s.chat_lieu, s.tinh_trang, s.tuoi_tho, s.kich_thuoc 
            FROM products p 
            LEFT JOIN product_specs s ON p.id = s.product_id 
            WHERE p.id = ? AND p.deleted_at IS NULL
        ');
        $stmt->execute([$_GET['id']]);
        $product = $stmt->fetch(PDO::FETCH_ASSOC);

        if ($product) {
            // Lấy biến thể
            $vStmt = $pdo->prepare('SELECT id, product_id, kich_thuoc, anh_sang, price, cost_price, stock FROM product_variants WHERE product_id = ?');
            $vStmt->execute([$product['id']]);
            $product['variants'] = $vStmt->fetchAll(PDO::FETCH_ASSOC);

            // Lấy danh sách ảnh từ bảng product_images mới
            $imgStmt = $pdo->prepare('SELECT image_url FROM product_images WHERE product_id = ? ORDER BY sort_order ASC');
            $imgStmt->execute([$product['id']]);
            $images = $imgStmt->fetchAll(PDO::FETCH_COLUMN);

            // Ép vào trường gallery để tương thích ngược với Frontend
            $product['gallery'] = !empty($images) ? $images : [];

            echo json_encode(['success' => true, 'data' => $product]);
        } else {
            http_response_code(404);
            echo json_encode(['success' => false, 'message' => 'Không tìm thấy sản phẩm']);
        }
        exit();
    }

    // Giá trị lọc (chất liệu, phong cách, không gian) theo danh mục / tìm kiếm hiện tại
    if (!empty($_GET['facets'])) {
        [$where, $params] = products_build_base_where($pdo);
        $facetSql = '
            SELECT s.chat_lieu, s.phong_cach, s.khong_gian_lap_dat
            FROM products p
            LEFT JOIN product_specs s ON p.id = s.product_id
        ';
        if (!empty($where)) {
            $facetSql .= ' WHERE ' . implode(' AND ', $where);
        }
        $facetStmt = $pdo->prepare($facetSql);
        $facetStmt->execute($params);
        $facets = products_facets_from_rows($facetStmt->fetchAll(PDO::FETCH_ASSOC));
        echo json_encode(['success' => true, 'facets' => $facets]);
        exit();
    }

    // Lấy danh sách sản phẩm (có filter, search, sort, pagination)
    [$where, $params] = products_build_base_where($pdo);
    products_apply_spec_filters($where, $params);

    $fromJoin = '
        FROM products p
        LEFT JOIN product_specs s ON p.id = s.product_id
    ';
    $whereClause = !empty($where) ? ' WHERE ' . implode(' AND ', $where) : '';

    $sql = '
        SELECT p.*, s.phong_cach, s.khong_gian_lap_dat, s.bong_den, s.dien_ap, s.chat_lieu, s.tinh_trang, s.tuoi_tho, s.kich_thuoc
        ' . $fromJoin . $whereClause;

    // Sắp xếp
    $sort = $_GET['sort'] ?? 'new';
    switch ($sort) {
        case 'asc':
            $sql .= ' ORDER BY p.price ASC';
            break;
        case 'desc':
            $sql .= ' ORDER BY p.price DESC';
            break;
        case 'oldest':
            $sql .= ' ORDER BY p.id ASC';
            break;
        default:
            $sql .= ' ORDER BY p.id DESC';
            break;
    }

    // Phân trang
    $page = max(1, intval($_GET['page'] ?? 1));
    $limit = max(1, min(200, intval($_GET['limit'] ?? 200)));
    $offset = ($page - 1) * $limit;

    // Đếm tổng (cùng điều kiện lọc, kể cả spec)
    $countSql = 'SELECT COUNT(DISTINCT p.id) ' . $fromJoin . $whereClause;
    $countStmt = $pdo->prepare($countSql);
    $countStmt->execute($params);
    $total = $countStmt->fetchColumn();

    // Query dữ liệu
    $sql .= " LIMIT ? OFFSET ?";
    $stmt = $pdo->prepare($sql);
    $params[] = $limit;
    $params[] = $offset;
    $stmt->execute($params);
    $products = $stmt->fetchAll(PDO::FETCH_ASSOC);

    if (!empty($products)) {
        $productIds = array_column($products, 'id');
        $placeholders = implode(',', array_fill(0, count($productIds), '?'));
        $vStmt = $pdo->prepare("SELECT id, product_id, kich_thuoc, anh_sang, price, cost_price, stock FROM product_variants WHERE product_id IN ($placeholders)");
        $vStmt->execute($productIds);
        $allVariants = $vStmt->fetchAll(PDO::FETCH_ASSOC);

        $variantsByProduct = [];
        foreach ($allVariants as $v) {
            $variantsByProduct[$v['product_id']][] = $v;
        }

        // Lấy danh sách ảnh cho toàn bộ sản phẩm trong list
        $imgStmt = $pdo->prepare("SELECT product_id, image_url FROM product_images WHERE product_id IN ($placeholders) ORDER BY sort_order ASC");
        $imgStmt->execute($productIds);
        $allImages = $imgStmt->fetchAll(PDO::FETCH_ASSOC);

        $imagesByProduct = [];
        foreach ($allImages as $img) {
            $imagesByProduct[$img['product_id']][] = $img['image_url'];
        }

        foreach ($products as &$p) {
            $p['variants'] = $variantsByProduct[$p['id']] ?? [];
            $p['gallery'] = $imagesByProduct[$p['id']] ?? [];
        }
    }

    echo json_encode([
        'success' => true,
        'data' => $products,
        'total' => intval($total),
        'page' => $page,
        'limit' => $limit
    ]);
    exit();
}

// Thêm sản phẩm mới (Admin) hoặc Import hàng loạt
if ($method === 'POST') {
    adminGuardAuto();
    $isImport = isset($_GET['action']) && $_GET['action'] === 'import';

    if ($isImport) {
        $products = json_decode(file_get_contents('php://input'), true);
        if (!is_array($products)) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Dữ liệu không hợp lệ']);
            exit();
        }

        $uploadsDir = __DIR__ . '/uploads/products/';
        if (!is_dir($uploadsDir)) {
            mkdir($uploadsDir, 0777, true);
        }

        $baseUrl = "http://" . $_SERVER['HTTP_HOST'] . "/uploads/products/";

        // Quét toàn bộ cấu trúc thư mục con để tạo map tên file ảnh
        $imageMap = [];
        try {
            $iterator = new RecursiveIteratorIterator(
                new RecursiveDirectoryIterator($uploadsDir, RecursiveDirectoryIterator::SKIP_DOTS),
                RecursiveIteratorIterator::SELF_FIRST
            );
            foreach ($iterator as $file) {
                if ($file->isFile()) {
                    $filename = explode('?', $file->getFilename())[0];
                    if (preg_match("/\.(jpg|jpeg|png|gif|webp)$/i", $filename)) {
                        $relativePath = str_replace($uploadsDir, '', $file->getPathname());
                        $relativePath = str_replace('\\', '/', $relativePath); // Đổi backslash Windows thành gạch chéo

                        // Mã hóa từng phần đường dẫn tránh lỗi Tiếng Việt có dấu / khoảng trắng
                        $urlParts = explode('/', $relativePath);
                        $urlParts = array_map('rawurlencode', $urlParts);
                        $urlEncodedPath = implode('/', $urlParts);

                        // Map lưu dạng `db01958 (1).jpg` => `http://localhost:8000/uploads/products/DATA/HI%E1%BB...`
                        $imageMap[strtolower($filename)] = $baseUrl . $urlEncodedPath;
                    }
                }
            }
        } catch (Exception $ex) {
        }

        try {
            $pdo->beginTransaction();
            $stmt = $pdo->prepare('
                INSERT IGNORE INTO products (
                ma_san_pham, ten_san_pham, price, old_price, loai_den, image_url,
                stock, description, gallery
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            ');

            $stmtSpec = $pdo->prepare('
                INSERT IGNORE INTO product_specs (
                product_id, phong_cach, khong_gian_lap_dat, 
                bong_den, chat_lieu, kich_thuoc, tuoi_tho, dien_ap, tinh_trang
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            ');

            $importedCount = 0;
            foreach ($products as $data) {
                // Đọc dữ liệu cơ bản
                $maSP = trim($data['ma_san_pham'] ?? '');
                $tenSP = trim($data['ten_san_pham'] ?? '');

                if (empty($maSP) && empty($tenSP))
                    continue;

                $price = $data['price'] ?? 0;
                $oldPrice = $data['old_price'] ?? 0;
                $loaiDen = trim($data['loai_den'] ?? '');
                $stock = $data['stock'] ?? 15;
                $tinhTrang = $data['tinh_trang'] ?? 'Mới 100%';

                $phongCach = trim($data['phong_cach'] ?? '');
                $khongGian = trim($data['khong_gian_lap_dat'] ?? '');
                $bongDen = trim($data['bong_den'] ?? '');
                $chatLieu = trim($data['chat_lieu'] ?? '');
                $kichThuoc = trim($data['kich_thuoc'] ?? '');
                $tuoiTho = trim($data['tuoi_tho'] ?? '50000');
                $dienAp = trim($data['dien_ap'] ?? '220v');
                $desc = trim($data['description'] ?? '');

                $mainImage = '';
                $galleryImages = [];

                if (!empty($maSP)) {
                    // Tìm file ảnh chính
                    foreach ([$maSP . ' (1).jpg', $maSP . ' (1).png'] as $f) {
                        $key = strtolower($f);
                        if (isset($imageMap[$key])) {
                            $mainImage = $imageMap[$key];
                            break;
                        }
                    }

                    // Tìm thư viện ảnh con (2 -> 10)
                    for ($i = 2; $i <= 10; $i++) {
                        foreach ([$maSP . " ($i).jpg", $maSP . " ($i).png"] as $f) {
                            $key = strtolower($f);
                            if (isset($imageMap[$key])) {
                                $galleryImages[] = $imageMap[$key];
                                break;
                            }
                        }
                    }
                }

                $gallery = !empty($galleryImages) ? json_encode($galleryImages) : null;

                $stmt->execute([
                    $maSP,
                    $tenSP,
                    $price,
                    $oldPrice,
                    $loaiDen,
                    $mainImage,
                    $stock,
                    $desc,
                    $gallery
                ]);
                $productId = $pdo->lastInsertId();
                if ($productId) {
                    $stmtSpec->execute([
                        $productId,
                        $phongCach,
                        $khongGian,
                        $bongDen,
                        $chatLieu,
                        $kichThuoc,
                        $tuoiTho,
                        $dienAp,
                        $tinhTrang
                    ]);

                    // Thêm ảnh vào bảng product_images (Import)
                    if (!empty($galleryImages)) {
                        $imgStmt = $pdo->prepare('INSERT INTO product_images (product_id, image_url, is_main, sort_order) VALUES (?, ?, ?, ?)');
                        foreach ($galleryImages as $idx => $imgUrl) {
                            $imgStmt->execute([$productId, $imgUrl, ($idx === 0 ? 1 : 0), $idx + 1]);
                        }
                    }

                    $importedCount++;
                }

                // Tự động tạo danh mục nếu chưa tồn tại trong bảng categories
                if (!empty($loaiDen)) {
                    $stmtCatCheck = $pdo->prepare("SELECT id FROM categories WHERE name = ?");
                    $stmtCatCheck->execute([$loaiDen]);
                    if (!$stmtCatCheck->fetch()) {
                        // Cố gắng tự động đoán danh mục cha (VD: "Đèn chùm hiện đại" -> cha là "Đèn chùm")
                        $words = explode(' ', $loaiDen);
                        $parentId = null;
                        if (count($words) >= 3 && (mb_strtolower($words[0], 'UTF-8') == 'đèn')) {
                            $parentName = $words[0] . ' ' . $words[1]; // VD: Đèn chùm
                            // Ngoại lệ: Đèn ốp trần
                            if (mb_strtolower($words[1], 'UTF-8') == 'ốp' && count($words) >= 4) {
                                $parentName = $words[0] . ' ' . $words[1] . ' ' . $words[2];
                            }

                            $stmtParentCheck = $pdo->prepare("SELECT id FROM categories WHERE name = ?");
                            $stmtParentCheck->execute([$parentName]);
                            if ($parentRow = $stmtParentCheck->fetch(PDO::FETCH_ASSOC)) {
                                $parentId = $parentRow['id'];
                            } else {
                                $stmtParentInsert = $pdo->prepare("INSERT INTO categories (name) VALUES (?)");
                                $stmtParentInsert->execute([$parentName]);
                                $parentId = $pdo->lastInsertId();
                            }
                        }

                        $stmtCatInsert = $pdo->prepare("INSERT INTO categories (name, parent_id) VALUES (?, ?)");
                        $stmtCatInsert->execute([$loaiDen, $parentId]);
                    }
                }
            }

            $pdo->commit();

            echo json_encode([
                'success' => true,
                'message' => 'Nhập dữ liệu thành công!',
                'count' => $importedCount
            ]);
            exit();

        } catch (Exception $e) {
            if ($pdo->inTransaction()) {
                $pdo->rollBack();
            }
            error_log("IMPORT products.php Error: " . $e->getMessage());
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => 'Lỗi DB: ' . $e->getMessage()]);
            exit();
        }
    }

    // Logic THÊM 1 SẢN PHẨM MỚI TỪ FORM (Mặc định)
    $data = json_decode(file_get_contents('php://input'), true);

    $maSP = $data['ma_san_pham'] ?? '';
    $tenSP = $data['ten_san_pham'] ?? '';
    $price = $data['price'] ?? 0;
    $oldPrice = $data['old_price'] ?? 0;
    if ((float) $oldPrice > 0 && (float) $oldPrice <= (float) $price) {
        // Giá gạch phải cao hơn giá bán; trùng hoặc thấp hơn → coi như không khuyến mãi
        $oldPrice = 0;
    }
    $loaiDen = $data['loai_den'] ?? '';
    $image = $data['image_url'] ?? '';
    $stock = $data['stock'] ?? 15;
    $costPrice = $data['cost_price'] ?? 0;
    $tinhTrang = $data['tinh_trang'] ?? 'Mới 100%';
    $phongCach = $data['phong_cach'] ?? '';
    $khongGian = $data['khong_gian_lap_dat'] ?? '';
    $bongDen = $data['bong_den'] ?? '';
    $chatLieu = $data['chat_lieu'] ?? '';
    $kichThuoc = $data['kich_thuoc'] ?? '';
    $tuoiTho = $data['tuoi_tho'] ?? '50000';
    $dienAp = $data['dien_ap'] ?? '220v';
    $desc = $data['description'] ?? '';
    $gallery = isset($data['gallery']) ? json_encode($data['gallery']) : null;
    $variants = isset($data['variants']) && is_array($data['variants']) ? $data['variants'] : [];

    try {
        $pdo->beginTransaction();

        $stmt = $pdo->prepare('
            INSERT INTO products (
            ma_san_pham, ten_san_pham, price, old_price, loai_den, image_url,
            stock, cost_price, description, gallery
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ');
        $stmt->execute([
            $maSP,
            $tenSP,
            $price,
            $oldPrice,
            $loaiDen,
            $image,
            $stock,
            $costPrice,
            $desc,
            $gallery
        ]);

        $productId = $pdo->lastInsertId();

        // 1.5 Thêm ảnh vào bảng product_images (Single Post)
        if (isset($data['gallery']) && is_array($data['gallery'])) {
            $imgStmt = $pdo->prepare('INSERT INTO product_images (product_id, image_url, is_main, sort_order) VALUES (?, ?, ?, ?)');
            foreach ($data['gallery'] as $idx => $imgUrl) {
                $imgStmt->execute([$productId, $imgUrl, ($idx === 0 ? 1 : 0), $idx + 1]);
            }
        }

        // 2. Thêm vào product_specs
        $stmtSpec = $pdo->prepare('
            INSERT INTO product_specs (
            product_id, phong_cach, khong_gian_lap_dat, bong_den, chat_lieu, kich_thuoc, tuoi_tho, dien_ap, tinh_trang
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)');
        $stmtSpec->execute([
            $productId,
            $phongCach,
            $khongGian,
            $bongDen,
            $chatLieu,
            $kichThuoc,
            $tuoiTho,
            $dienAp,
            $tinhTrang
        ]);

        if (!empty($variants)) {
            $vStmt = $pdo->prepare('INSERT INTO product_variants (product_id, kich_thuoc, anh_sang, price, cost_price, stock) VALUES (?, ?, ?, ?, ?, ?)');
            foreach ($variants as $v) {
                $vStmt->execute([$productId, $v['kich_thuoc'] ?? '', $v['anh_sang'] ?? '', $v['price'] ?? 0, $v['cost_price'] ?? 0, $v['stock'] ?? 0]);
            }
        }

        $pdo->commit();

        echo json_encode([
            'success' => true,
            'message' => 'Thêm sản phẩm thành công!',
            'id' => $productId
        ]);
        exit();
    } catch (Exception $e) {
        if ($pdo->inTransaction()) {
            $pdo->rollBack();
        }
        error_log("POST products.php Error: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Lỗi DB: ' . $e->getMessage()]);
        exit();
    }
}

// Cập nhật sản phẩm (Admin)
if ($method === 'PUT') {
    adminGuardAuto();

    $data = json_decode(file_get_contents('php://input'), true);

    // Toggle Hot Deal (Bật/tắt trạng thái hot deal)
    if (isset($data['action']) && $data['action'] === 'toggle_hot_deal') {
        $id = $data['id'] ?? null;
        $isHotDeal = $data['is_hot_deal'] ?? 0;
        if (!$id) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Thiếu ID sản phẩm']);
            exit();
        }

        if ((int) $isHotDeal === 1) {
            $checkStmt = $pdo->prepare('SELECT is_hot_deal FROM products WHERE id = ? AND deleted_at IS NULL');
            $checkStmt->execute([$id]);
            $alreadyHot = (int) $checkStmt->fetchColumn();

            if ($alreadyHot !== 1) {
                $countStmt = $pdo->query('SELECT COUNT(*) FROM products WHERE is_hot_deal = 1 AND deleted_at IS NULL');
                $hotCount = (int) $countStmt->fetchColumn();
                if ($hotCount >= HOT_DEAL_MAX) {
                    http_response_code(400);
                    echo json_encode([
                        'success' => false,
                        'message' => 'Hot Deal chỉ tối đa ' . HOT_DEAL_MAX . ' sản phẩm. Vui lòng gỡ bớt trước khi thêm mới.',
                    ]);
                    exit();
                }
            }

            try {
                hotDealCaptureSnapshot($pdo, (int) $id);
                $stmt = $pdo->prepare('UPDATE products SET is_hot_deal = 1 WHERE id = ?');
                $stmt->execute([$id]);
                echo json_encode(['success' => true, 'message' => 'Đã thêm vào Hot Deal']);
            } catch (Exception $e) {
                http_response_code(500);
                echo json_encode(['success' => false, 'message' => 'Lỗi thêm Hot Deal: ' . $e->getMessage()]);
            }
            exit();
        }

        try {
            $pdo->beginTransaction();
            $restored = hotDealRestoreAndClear($pdo, (int) $id);
            $stmt = $pdo->prepare('UPDATE products SET is_hot_deal = 0 WHERE id = ?');
            $stmt->execute([$id]);
            $pdo->commit();
            $message = $restored
                ? 'Đã gỡ khỏi Hot Deal và khôi phục giá trước khuyến mãi'
                : 'Đã gỡ khỏi Hot Deal';
            echo json_encode(['success' => true, 'message' => $message, 'restored' => $restored]);
        } catch (Exception $e) {
            if ($pdo->inTransaction()) {
                $pdo->rollBack();
            }
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => 'Lỗi gỡ Hot Deal: ' . $e->getMessage()]);
        }
        exit();
    }

    // Sửa giá nhanh (Quick Update Price) - dùng trong Hot Deal
    if (isset($data['action']) && $data['action'] === 'quick_update_price') {
        $id = $data['id'] ?? null;
        $price = $data['price'] ?? null;
        $oldPrice = $data['old_price'] ?? 0;
        $variants = isset($data['variants']) && is_array($data['variants']) ? $data['variants'] : [];
        if (!$id || $price === null) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Thiếu thông tin']);
            exit();
        }

        hotDealCaptureSnapshot($pdo, (int) $id);

        if (!empty($variants)) {
            try {
                $pdo->beginTransaction();
                $vStmt = $pdo->prepare('UPDATE product_variants SET price = ? WHERE id = ? AND product_id = ?');
                $prices = [];
                foreach ($variants as $v) {
                    $variantId = $v['id'] ?? null;
                    $variantPrice = $v['price'] ?? null;
                    if (!$variantId || $variantPrice === null) continue;
                    $vStmt->execute([$variantPrice, $variantId, $id]);
                    $prices[] = floatval($variantPrice);
                }
                $basePrice = !empty($prices) ? min($prices) : floatval($price);
                $stmt = $pdo->prepare('UPDATE products SET price = ?, old_price = ? WHERE id = ?');
                $stmt->execute([$basePrice, $oldPrice, $id]);
                $pdo->commit();
            } catch (Exception $e) {
                if ($pdo->inTransaction()) $pdo->rollBack();
                http_response_code(500);
                echo json_encode(['success' => false, 'message' => 'Lỗi cập nhật biến thể: ' . $e->getMessage()]);
                exit();
            }
        } else {
            $stmt = $pdo->prepare('UPDATE products SET price = ?, old_price = ? WHERE id = ?');
            $stmt->execute([$price, $oldPrice, $id]);
        }
        echo json_encode(['success' => true, 'message' => 'Đã cập nhật giá sản phẩm']);
        exit();
    }

    if (!isset($data['id'])) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Thiếu ID']);
        exit();
    }

    $id = $data['id'];
    $maSP = $data['ma_san_pham'] ?? '';
    $tenSP = $data['ten_san_pham'] ?? '';
    $price = $data['price'] ?? 0;
    $oldPrice = $data['old_price'] ?? 0;
    if ((float) $oldPrice > 0 && (float) $oldPrice <= (float) $price) {
        $oldPrice = 0;
    }
    $loaiDen = $data['loai_den'] ?? '';
    $image = $data['image_url'] ?? '';
    $stock = $data['stock'] ?? 15;
    $costPrice = $data['cost_price'] ?? 0;
    $tinhTrang = $data['tinh_trang'] ?? 'Mới 100%';
    $phongCach = $data['phong_cach'] ?? '';
    $khongGian = $data['khong_gian_lap_dat'] ?? '';
    $bongDen = $data['bong_den'] ?? '';
    $chatLieu = $data['chat_lieu'] ?? '';
    $kichThuoc = $data['kich_thuoc'] ?? '';
    $tuoiTho = $data['tuoi_tho'] ?? '50000';
    $dienAp = $data['dien_ap'] ?? '220v';
    $desc = $data['description'] ?? '';
    $gallery = isset($data['gallery']) ? json_encode($data['gallery']) : null;
    $variants = isset($data['variants']) && is_array($data['variants']) ? $data['variants'] : [];

    try {
        $pdo->beginTransaction();
        $stmt = $pdo->prepare('
        UPDATE products 
        SET ma_san_pham=?, ten_san_pham=?, price=?, old_price=?, loai_den=?, image_url=?,
            stock=?, cost_price=?, description=?, gallery=?
        WHERE id=?
    ');
        $stmt->execute([
            $maSP,
            $tenSP,
            $price,
            $oldPrice,
            $loaiDen,
            $image,
            $stock,
            $costPrice,
            $desc,
            $gallery,
            $id
        ]);

        // 1.5 Cập nhật ảnh vào bảng product_images (PUT)
        $imgDelStmt = $pdo->prepare('DELETE FROM product_images WHERE product_id = ?');
        $imgDelStmt->execute([$id]);

        if (isset($data['gallery']) && is_array($data['gallery'])) {
            $imgInsStmt = $pdo->prepare('INSERT INTO product_images (product_id, image_url, is_main, sort_order) VALUES (?, ?, ?, ?)');
            foreach ($data['gallery'] as $idx => $imgUrl) {
                $imgInsStmt->execute([$id, $imgUrl, ($idx === 0 ? 1 : 0), $idx + 1]);
            }
        }

        // 2. Cập nhật product_specs
        $stmtSpecCheck = $pdo->prepare('SELECT product_id FROM product_specs WHERE product_id=?');
        $stmtSpecCheck->execute([$id]);
        if ($stmtSpecCheck->fetch()) {
            $stmtSpecUpdate = $pdo->prepare('
                UPDATE product_specs 
                SET phong_cach=?, khong_gian_lap_dat=?, bong_den=?, chat_lieu=?, kich_thuoc=?, tuoi_tho=?, dien_ap=?, tinh_trang=?
                WHERE product_id=?
            ');
            $stmtSpecUpdate->execute([$phongCach, $khongGian, $bongDen, $chatLieu, $kichThuoc, $tuoiTho, $dienAp, $tinhTrang, $id]);
        } else {
            $stmtSpecInsert = $pdo->prepare('
                INSERT INTO product_specs 
                (product_id, phong_cach, khong_gian_lap_dat, bong_den, chat_lieu, kich_thuoc, tuoi_tho, dien_ap, tinh_trang)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            ');
            $stmtSpecInsert->execute([$id, $phongCach, $khongGian, $bongDen, $chatLieu, $kichThuoc, $tuoiTho, $dienAp, $tinhTrang]);
        }

        $delStmt = $pdo->prepare('DELETE FROM product_variants WHERE product_id = ?');
        $delStmt->execute([$id]);

        if (!empty($variants)) {
            $vStmt = $pdo->prepare('INSERT INTO product_variants (product_id, kich_thuoc, anh_sang, price, cost_price, stock) VALUES (?, ?, ?, ?, ?, ?)');
            foreach ($variants as $v) {
                $vStmt->execute([$id, $v['kich_thuoc'] ?? '', $v['anh_sang'] ?? '', $v['price'] ?? 0, $v['cost_price'] ?? 0, $v['stock'] ?? 0]);
            }
        }

        $pdo->commit();

        echo json_encode([
            'success' => true,
            'message' => 'Đã cập nhật sản phẩm thành công!'
        ]);
        exit();
    } catch (Exception $e) {
        if ($pdo->inTransaction()) {
            $pdo->rollBack();
        }
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Lỗi Data: ' . $e->getMessage()]);
        exit();
    }
}

// Xóa sản phẩm (Admin)
if ($method === 'DELETE') {
    adminGuardAuto();

    $id = $_GET['id'] ?? null;
    $ids = $_GET['ids'] ?? null;
    $action = $_GET['action'] ?? null;

    if ($action === 'clear_all') {
        $pdo->exec('SET FOREIGN_KEY_CHECKS = 0');
        $pdo->exec('TRUNCATE table products');
        $pdo->exec('TRUNCATE table product_specs');
        $pdo->exec('TRUNCATE table product_variants');
        $pdo->exec('TRUNCATE table product_images');
        $pdo->exec('SET FOREIGN_KEY_CHECKS = 1');
        echo json_encode(['success' => true, 'message' => 'Đã xóa toàn bộ kho hàng']);
        exit();
    }

    if ($ids) {
        $idArray = explode(',', $ids);
        $placeholders = implode(',', array_fill(0, count($idArray), '?'));
        // Soft Delete: chỉ đánh dấu xóa, không xóa thật
        $stmt = $pdo->prepare("UPDATE products SET deleted_at = NOW() WHERE id IN ($placeholders)");
        $stmt->execute($idArray);
        echo json_encode(['success' => true, 'message' => 'Đã xóa ' . count($idArray) . ' sản phẩm']);
        exit();
    }

    if (!$id) {
        echo json_encode(['success' => false, 'message' => 'Thiếu ID']);
        exit();
    }

    // Soft Delete: đánh dấu xóa thay vì DELETE thật
    $stmt = $pdo->prepare('UPDATE products SET deleted_at = NOW() WHERE id = ?');
    $stmt->execute([$id]);
    echo json_encode(['success' => true, 'message' => 'Đã xóa sản phẩm']);
    exit();
}

http_response_code(405);
echo json_encode(['success' => false, 'message' => 'Method not allowed']);
