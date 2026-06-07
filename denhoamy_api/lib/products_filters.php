<?php
/**
 * Helpers for product list filtering (category page).
 */

function products_parse_list_param(string $key): array
{
    if (!isset($_GET[$key]) || $_GET[$key] === '') {
        return [];
    }
    return array_values(array_filter(array_map('trim', explode(',', (string) $_GET[$key]))));
}

function products_build_category_where(PDO $pdo, array &$where, array &$params): void
{
    if (empty($_GET['type'])) {
        return;
    }

    $type = $_GET['type'];
    $stmtCat = $pdo->prepare('SELECT id FROM categories WHERE name = ?');
    $stmtCat->execute([$type]);
    $cat = $stmtCat->fetch(PDO::FETCH_ASSOC);

    $catNames = [$type];
    if ($cat) {
        $stmtSub = $pdo->prepare('SELECT name FROM categories WHERE parent_id = ?');
        $stmtSub->execute([$cat['id']]);
        while ($subCat = $stmtSub->fetch(PDO::FETCH_ASSOC)) {
            $catNames[] = $subCat['name'];
        }
    }

    $placeholders = implode(',', array_fill(0, count($catNames), '?'));
    $where[] = "p.loai_den IN ($placeholders)";
    foreach ($catNames as $name) {
        $params[] = $name;
    }
}

function products_build_base_where(PDO $pdo): array
{
    $where = ['p.deleted_at IS NULL'];
    $params = [];

    products_build_category_where($pdo, $where, $params);

    if (!empty($_GET['search'])) {
        $where[] = '(p.ten_san_pham LIKE ? OR p.ma_san_pham LIKE ?)';
        $searchTerm = '%' . $_GET['search'] . '%';
        $params[] = $searchTerm;
        $params[] = $searchTerm;
    }

    if (!empty($_GET['exclude_id'])) {
        $where[] = 'p.id != ?';
        $params[] = intval($_GET['exclude_id']);
    }

    return [$where, $params];
}

function products_apply_spec_filters(array &$where, array &$params): void
{
    if (isset($_GET['price_min']) && $_GET['price_min'] !== '') {
        $where[] = 'p.price >= ?';
        $params[] = floatval($_GET['price_min']);
    }
    if (isset($_GET['price_max']) && $_GET['price_max'] !== '') {
        $where[] = 'p.price < ?';
        $params[] = floatval($_GET['price_max']);
    }

    $specFilters = [
        'material' => 's.chat_lieu',
        'style' => 's.phong_cach',
        'space' => 's.khong_gian_lap_dat',
    ];

    foreach ($specFilters as $param => $column) {
        $values = products_parse_list_param($param);
        if (empty($values)) {
            continue;
        }
        $ors = [];
        foreach ($values as $value) {
            $ors[] = "$column LIKE ?";
            $params[] = '%' . $value . '%';
        }
        $where[] = '(' . implode(' OR ', $ors) . ')';
    }
}

function products_facets_from_rows(array $rows): array
{
    $materials = [];
    $styles = [];
    $spaces = [];

    foreach ($rows as $row) {
        foreach (explode(',', (string) ($row['chat_lieu'] ?? '')) as $part) {
            $t = trim($part);
            if ($t !== '' && $t !== '..') {
                $materials[$t] = true;
            }
        }
        foreach (explode(',', (string) ($row['phong_cach'] ?? '')) as $part) {
            $t = trim($part);
            if ($t !== '' && $t !== '..') {
                $styles[$t] = true;
            }
        }
        foreach (explode(',', (string) ($row['khong_gian_lap_dat'] ?? '')) as $part) {
            $t = trim($part);
            if ($t !== '' && $t !== '..') {
                $spaces[$t] = true;
            }
        }
    }

    $sortKeys = static function (array $map) {
        $keys = array_keys($map);
        sort($keys, SORT_NATURAL | SORT_FLAG_CASE);
        return $keys;
    };

    return [
        'materials' => $sortKeys($materials),
        'styles' => $sortKeys($styles),
        'spaces' => $sortKeys($spaces),
    ];
}
