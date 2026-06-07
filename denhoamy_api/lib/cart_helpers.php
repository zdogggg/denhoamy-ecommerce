<?php
/**
 * Helpers giỏ hàng — map DB ↔ format frontend cart store.
 */

require_once __DIR__ . '/order_pricing.php';

/**
 * Lấy hoặc tạo cart cho user.
 */
function cartGetOrCreateId(PDO $pdo, int $userId): int
{
    $stmt = $pdo->prepare('SELECT id FROM carts WHERE user_id = ? LIMIT 1');
    $stmt->execute([$userId]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($row) {
        return (int) $row['id'];
    }

    $ins = $pdo->prepare('INSERT INTO carts (user_id) VALUES (?)');
    $ins->execute([$userId]);

    return (int) $pdo->lastInsertId();
}

/**
 * Composite id khớp cart store Vue (productId hoặc productId_variantId).
 */
function cartCompositeItemId(int $productId, ?int $variantId): string
{
    if ($variantId) {
        return $productId . '_' . $variantId;
    }

    return (string) $productId;
}

/**
 * Parse item từ request body / store.
 *
 * @return array{product_id: int, variant_id: ?int, quantity: int}
 */
function cartParseItemInput(array $item): array
{
    if (!empty($item['product_id'])) {
        $productId = (int) $item['product_id'];
        $variantId = !empty($item['variant_id']) ? (int) $item['variant_id'] : null;
    } else {
        $ids = parseOrderItemIds($item['id'] ?? 0);
        $productId = $ids['product_id'];
        $variantId = $ids['variant_id'];
    }

    return [
        'product_id' => $productId,
        'variant_id' => $variantId,
        'quantity' => max(1, (int) ($item['quantity'] ?? 1)),
    ];
}

/**
 * Giá bán hiển thị (mirror resolveSalePrice đơn giản).
 */
function cartResolveSalePrice(array $product, ?int $variantId): float
{
    if ($variantId && !empty($product['variants'])) {
        foreach ($product['variants'] as $v) {
            if ((int) $v['id'] === $variantId) {
                return (float) ($v['price'] ?? 0);
            }
        }
    }

    if (!empty($product['variants'])) {
        $min = null;
        foreach ($product['variants'] as $v) {
            $p = (float) ($v['price'] ?? 0);
            if ($p > 0 && ($min === null || $p < $min)) {
                $min = $p;
            }
        }
        if ($min !== null) {
            return $min;
        }
    }

    return (float) ($product['price'] ?? 0);
}

/**
 * Stock cho dòng giỏ.
 */
function cartResolveStock(array $product, ?int $variantId): ?int
{
    if ($variantId && !empty($product['variants'])) {
        foreach ($product['variants'] as $v) {
            if ((int) $v['id'] === $variantId) {
                return (int) ($v['stock'] ?? 0);
            }
        }
    }

    return isset($product['stock']) ? (int) $product['stock'] : null;
}

/**
 * @return array<int, array<string, mixed>>
 */
function cartFetchEnrichedItems(PDO $pdo, int $cartId): array
{
    $stmt = $pdo->prepare('
        SELECT ci.id AS cart_item_id, ci.product_id, ci.variant_id, ci.quantity
        FROM cart_items ci
        WHERE ci.cart_id = ?
        ORDER BY ci.id ASC
    ');
    $stmt->execute([$cartId]);
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

    if (empty($rows)) {
        return [];
    }

    $productIds = array_unique(array_column($rows, 'product_id'));
    $placeholders = implode(',', array_fill(0, count($productIds), '?'));

    $pStmt = $pdo->prepare("
        SELECT id, ma_san_pham, ten_san_pham, price, image_url, stock
        FROM products
        WHERE id IN ($placeholders) AND deleted_at IS NULL
    ");
    $pStmt->execute($productIds);
    $products = [];
    while ($p = $pStmt->fetch(PDO::FETCH_ASSOC)) {
        $products[(int) $p['id']] = $p;
    }

    $vStmt = $pdo->prepare("
        SELECT id, product_id, kich_thuoc, anh_sang, price, stock
        FROM product_variants
        WHERE product_id IN ($placeholders)
    ");
    $vStmt->execute($productIds);
    $variantsByProduct = [];
    while ($v = $vStmt->fetch(PDO::FETCH_ASSOC)) {
        $variantsByProduct[(int) $v['product_id']][] = $v;
    }

    $items = [];

    foreach ($rows as $row) {
        $productId = (int) $row['product_id'];
        $variantId = !empty($row['variant_id']) ? (int) $row['variant_id'] : null;

        if (!isset($products[$productId])) {
            continue;
        }

        $product = $products[$productId];
        $product['variants'] = $variantsByProduct[$productId] ?? [];

        $compositeId = cartCompositeItemId($productId, $variantId);
        $price = cartResolveSalePrice($product, $variantId);
        $stock = cartResolveStock($product, $variantId);

        $items[] = [
            'id' => $compositeId,
            'code' => $product['ma_san_pham'] ?? (string) $productId,
            'name' => $product['ten_san_pham'] ?? '',
            'image' => $product['image_url'] ?? '',
            'price' => $price,
            'stock' => $stock,
            'quantity' => (int) $row['quantity'],
            'cart_item_id' => (int) $row['cart_item_id'],
            'product_id' => $productId,
            'variant_id' => $variantId,
        ];
    }

    return $items;
}

/**
 * Thay toàn bộ cart_items từ danh sách client.
 *
 * @throws InvalidArgumentException
 */
function cartReplaceItems(PDO $pdo, int $cartId, array $items): void
{
    $pdo->prepare('DELETE FROM cart_items WHERE cart_id = ?')->execute([$cartId]);

    if (empty($items)) {
        return;
    }

    $ins = $pdo->prepare('
        INSERT INTO cart_items (cart_id, product_id, variant_id, quantity)
        VALUES (?, ?, ?, ?)
    ');

    $seen = [];

    foreach ($items as $item) {
        $parsed = cartParseItemInput($item);
        $productId = $parsed['product_id'];
        $variantId = $parsed['variant_id'];

        if ($productId <= 0) {
            continue;
        }

        $key = $productId . ':' . ($variantId ?? 0);
        if (isset($seen[$key])) {
            $seen[$key]['quantity'] += $parsed['quantity'];
            continue;
        }

        $resolved = resolveOrderItemPrice($pdo, $productId, $variantId);
        if (!$resolved['found']) {
            throw new InvalidArgumentException('Sản phẩm trong giỏ không tồn tại hoặc không hợp lệ');
        }

        $seen[$key] = [
            'product_id' => $productId,
            'variant_id' => $variantId,
            'quantity' => $parsed['quantity'],
        ];
    }

    foreach ($seen as $row) {
        $ins->execute([
            $cartId,
            $row['product_id'],
            $row['variant_id'],
            $row['quantity'],
        ]);
    }
}
