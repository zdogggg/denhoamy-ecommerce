<?php
require_once 'db.php';
require_once __DIR__ . '/lib/auth_middleware.php';
require_once __DIR__ . '/lib/admin_route_guard.php';

$method = $_SERVER['REQUEST_METHOD'];

function buildTree(array &$elements, $parentId = null)
{
    $branch = array();
    foreach ($elements as $element) {
        if ($element['parent_id'] == $parentId) {
            $children = buildTree($elements, $element['id']);
            if ($children) {
                $element['children'] = $children;
            }
            $branch[] = $element;
        }
    }
    return $branch;
}

try {
    switch ($method) {
        case 'GET':
            // Lấy tất cả danh mục
            $stmt = $pdo->query("SELECT id, name, parent_id, sort_order, created_at FROM categories ORDER BY sort_order ASC, id ASC");
            $categories = $stmt->fetchAll(PDO::FETCH_ASSOC);

            // Xây dựng cây danh mục (dành cho Admin "Danh mục nghệ thuật" và Menu ngang)
            // Tính toán số lượng sản phẩm (count)
            // Tính toán số lượng sản phẩm (count)
            $stmtCount = $pdo->query("SELECT loai_den, COUNT(*) as c FROM products GROUP BY loai_den");
            $counts = [];
            while ($row = $stmtCount->fetch(PDO::FETCH_ASSOC)) {
                $counts[mb_strtolower(trim($row['loai_den']), 'UTF-8')] = (int) $row['c'];
            }

            foreach ($categories as &$cat) {
                $catName = mb_strtolower(trim($cat['name']), 'UTF-8');
                $cat['count'] = isset($counts[$catName]) ? $counts[$catName] : 0;
            }

            $tree = buildTree($categories);

            // Hàm tính tổng đệ quy cho các danh mục cha
            function sumCounts(&$nodes)
            {
                if (!is_array($nodes))
                    return 0;
                $total = 0;
                foreach ($nodes as &$n) {
                    if (!empty($n['children'])) {
                        $n['count'] += sumCounts($n['children']);
                    }
                    $total += $n['count'];
                }
                return $total;
            }
            sumCounts($tree);

            echo json_encode(['success' => true, 'data' => $tree, 'flat' => $categories]);
            break;

        case 'POST':
            adminGuardAuto();
            $data = json_decode(file_get_contents("php://input"));
            if (!empty($data->name)) {
                $parentId = !empty($data->parent_id) ? $data->parent_id : null;
                $sortOrder = isset($data->sort_order) ? $data->sort_order : 0;

                $stmt = $pdo->prepare("INSERT INTO categories (name, parent_id, sort_order) VALUES (:name, :parent_id, :sort_order)");
                $stmt->bindParam(':name', $data->name);
                $stmt->bindParam(':parent_id', $parentId);
                $stmt->bindParam(':sort_order', $sortOrder);

                if ($stmt->execute()) {
                    http_response_code(201);
                    echo json_encode(["success" => true, "message" => "Đã tạo danh mục", "id" => $pdo->lastInsertId()]);
                } else {
                    http_response_code(503);
                    echo json_encode(["success" => false, "message" => "Không thể tạo danh mục"]);
                }
            } else {
                http_response_code(400);
                echo json_encode(["success" => false, "message" => "Thiếu tên danh mục"]);
            }
            break;

        case 'PUT':
            adminGuardAuto();
            $data = json_decode(file_get_contents("php://input"));
            if (!empty($data->id) && !empty($data->name)) {
                $parentId = !empty($data->parent_id) ? $data->parent_id : null;
                $sortOrder = isset($data->sort_order) ? $data->sort_order : 0;

                $stmt = $pdo->prepare("UPDATE categories SET name = :name, parent_id = :parent_id, sort_order = :sort_order WHERE id = :id");
                $stmt->bindParam(':name', $data->name);
                $stmt->bindParam(':parent_id', $parentId);
                $stmt->bindParam(':sort_order', $sortOrder);
                $stmt->bindParam(':id', $data->id);

                if ($stmt->execute()) {
                    echo json_encode(["success" => true, "message" => "Cập nhật danh mục thành công"]);
                } else {
                    http_response_code(503);
                    echo json_encode(["success" => false, "message" => "Lỗi cập nhật danh mục"]);
                }
            } else {
                http_response_code(400);
                echo json_encode(["success" => false, "message" => "Thiếu ID hoặc tên danh mục"]);
            }
            break;

        case 'DELETE':
            adminGuardAuto();
            $id = $_GET['id'] ?? null;
            if ($id) {
                // Xoá danh mục

                // 1. Tìm tên danh mục để lấy products
                $stmtFind = $pdo->prepare("SELECT name FROM categories WHERE id = ?");
                $stmtFind->execute([$id]);
                $cat = $stmtFind->fetch(PDO::FETCH_ASSOC);
                if ($cat) {
                    $catName = $cat['name'];
                    // Chuyển label sản phẩm
                    $stmtUpdateProd = $pdo->prepare("UPDATE products SET loai_den = 'Chưa phân loại' WHERE loai_den = ?");
                    $stmtUpdateProd->execute([$catName]);
                }

                // 2. Xóa danh mục
                $stmt = $pdo->prepare("DELETE FROM categories WHERE id = :id");
                $stmt->bindParam(':id', $id);

                if ($stmt->execute()) {
                    echo json_encode(["success" => true, "message" => "Đã xóa danh mục"]);
                } else {
                    http_response_code(503);
                    echo json_encode(["success" => false, "message" => "Lỗi xóa danh mục"]);
                }
            } else {
                http_response_code(400);
                echo json_encode(["success" => false, "message" => "Không tìm thấy ID"]);
            }
            break;
    }
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Database error: ' . $e->getMessage()]);
}
?>