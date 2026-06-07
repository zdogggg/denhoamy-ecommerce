<?php
/**
 * Chuẩn hóa giá đơn hàng từ DB — mirror logic frontend resolveSalePrice().
 */

function parseOrderItemIds($rawId): array
{
    if (is_string($rawId) && strpos($rawId, '_') !== false) {
        $parts = explode('_', $rawId, 2);
        return [
            'product_id' => (int) ($parts[0] ?? 0),
            'variant_id' => (int) ($parts[1] ?? 0) ?: null,
        ];
    }

    return [
        'product_id' => (int) $rawId,
        'variant_id' => null,
    ];
}

/**
 * @return array{found: bool, price: float, cost_price: float, name: string, stock: int, product_id: int, variant_id: ?int}
 */
function resolveOrderItemPrice(PDO $pdo, int $productId, ?int $variantId): array
{
    $empty = [
        'found' => false,
        'price' => 0.0,
        'cost_price' => 0.0,
        'name' => '',
        'stock' => 0,
        'product_id' => $productId,
        'variant_id' => $variantId,
    ];

    if ($productId <= 0) {
        return $empty;
    }

    $pStmt = $pdo->prepare('
        SELECT id, ten_san_pham, price, cost_price, stock
        FROM products
        WHERE id = ? AND deleted_at IS NULL
    ');
    $pStmt->execute([$productId]);
    $product = $pStmt->fetch(PDO::FETCH_ASSOC);

    if (!$product) {
        return $empty;
    }

    if ($variantId) {
        $vStmt = $pdo->prepare('
            SELECT id, price, cost_price, stock
            FROM product_variants
            WHERE id = ? AND product_id = ?
        ');
        $vStmt->execute([$variantId, $productId]);
        $variant = $vStmt->fetch(PDO::FETCH_ASSOC);

        if (!$variant) {
            return $empty;
        }

        return [
            'found' => true,
            'price' => (float) ($variant['price'] ?? 0),
            'cost_price' => (float) ($variant['cost_price'] ?? 0),
            'name' => (string) ($product['ten_san_pham'] ?? ''),
            'stock' => (int) ($variant['stock'] ?? 0),
            'product_id' => $productId,
            'variant_id' => $variantId,
        ];
    }

    $vStmt = $pdo->prepare('
        SELECT id, price, cost_price, stock
        FROM product_variants
        WHERE product_id = ?
    ');
    $vStmt->execute([$productId]);
    $variants = $vStmt->fetchAll(PDO::FETCH_ASSOC);

    if (!empty($variants)) {
        $minVariant = null;
        $minPrice = null;

        foreach ($variants as $variant) {
            $variantPrice = (float) ($variant['price'] ?? 0);
            if ($variantPrice <= 0) {
                continue;
            }
            if ($minPrice === null || $variantPrice < $minPrice) {
                $minPrice = $variantPrice;
                $minVariant = $variant;
            }
        }

        if ($minVariant !== null) {
            return [
                'found' => true,
                'price' => (float) $minPrice,
                'cost_price' => (float) ($minVariant['cost_price'] ?? 0),
                'name' => (string) ($product['ten_san_pham'] ?? ''),
                'stock' => (int) ($product['stock'] ?? 0),
                'product_id' => $productId,
                'variant_id' => null,
            ];
        }
    }

    return [
        'found' => true,
        'price' => (float) ($product['price'] ?? 0),
        'cost_price' => (float) ($product['cost_price'] ?? 0),
        'name' => (string) ($product['ten_san_pham'] ?? ''),
        'stock' => (int) ($product['stock'] ?? 0),
        'product_id' => $productId,
        'variant_id' => null,
    ];
}

/**
 * Gán giá bán / giá nhập authoritative từ DB; kiểm tra tồn kho cơ bản.
 *
 * @throws InvalidArgumentException
 * @return array<int, array<string, mixed>>
 */
function normalizeOrderItems(PDO $pdo, array $items): array
{
    if (empty($items)) {
        throw new InvalidArgumentException('Giỏ hàng trống');
    }

    $normalized = [];

    foreach ($items as $item) {
        $ids = parseOrderItemIds($item['id'] ?? 0);
        $resolved = resolveOrderItemPrice($pdo, $ids['product_id'], $ids['variant_id']);

        if (!$resolved['found']) {
            $label = trim((string) ($item['name'] ?? ''));
            throw new InvalidArgumentException(
                $label !== '' ? "Sản phẩm \"{$label}\" không tồn tại hoặc biến thể không hợp lệ"
                    : 'Sản phẩm không tồn tại hoặc biến thể không hợp lệ'
            );
        }

        $quantity = max(1, (int) ($item['quantity'] ?? 1));
        if ($resolved['stock'] < $quantity) {
            $label = trim((string) ($item['name'] ?? $resolved['name']));
            throw new InvalidArgumentException(
                $label !== '' ? "Sản phẩm \"{$label}\" không đủ tồn kho"
                    : 'Sản phẩm không đủ tồn kho'
            );
        }

        $normalized[] = [
            'id' => $item['id'] ?? $resolved['product_id'],
            'product_id' => $resolved['product_id'],
            'variant_id' => $ids['variant_id'],
            'name' => trim((string) ($item['name'] ?? '')) ?: $resolved['name'],
            'quantity' => $quantity,
            'price' => $resolved['price'],
            'cost_price' => $resolved['cost_price'],
        ];
    }

    return $normalized;
}

/**
 * Khóa dòng tồn kho (FOR UPDATE) — chỉ gọi trong transaction.
 *
 * @return int|null stock sau khi khóa, null nếu không tìm thấy sản phẩm/biến thể
 */
function lockOrderItemStock(PDO $pdo, int $productId, ?int $variantId): ?int
{
    if ($productId <= 0) {
        return null;
    }

    if ($variantId) {
        $stmt = $pdo->prepare('
            SELECT stock FROM product_variants
            WHERE id = ? AND product_id = ?
            FOR UPDATE
        ');
        $stmt->execute([$variantId, $productId]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);

        return $row ? (int) $row['stock'] : null;
    }

    $stmt = $pdo->prepare('
        SELECT stock FROM products
        WHERE id = ? AND deleted_at IS NULL
        FOR UPDATE
    ');
    $stmt->execute([$productId]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);

    return $row ? (int) $row['stock'] : null;
}

/**
 * Gom số lượng theo (product_id, variant_id) để khóa tồn kho một lần mỗi SKU.
 *
 * @return array<string, array{product_id: int, variant_id: ?int, quantity: int, label: string}>
 */
function aggregateOrderItemsForStockLock(array $items): array
{
    $aggregated = [];

    foreach ($items as $item) {
        $ids = parseOrderItemIds($item['id'] ?? 0);
        $productId = $ids['product_id'];
        $variantId = $ids['variant_id'];
        $key = $productId . ':' . ($variantId ?? 0);

        if (!isset($aggregated[$key])) {
            $aggregated[$key] = [
                'product_id' => $productId,
                'variant_id' => $variantId,
                'quantity' => 0,
                'label' => '',
            ];
        }

        $aggregated[$key]['quantity'] += max(1, (int) ($item['quantity'] ?? 1));
        $label = trim((string) ($item['name'] ?? ''));
        if ($label !== '') {
            $aggregated[$key]['label'] = $label;
        }
    }

    return $aggregated;
}

/**
 * Chuẩn hóa items trong transaction — khóa tồn kho pessimistic trước khi trừ kho.
 *
 * @throws InvalidArgumentException
 * @return array<int, array<string, mixed>>
 */
function normalizeOrderItemsInTransaction(PDO $pdo, array $items): array
{
    if (empty($items)) {
        throw new InvalidArgumentException('Giỏ hàng trống');
    }

    foreach (aggregateOrderItemsForStockLock($items) as $agg) {
        $lockedStock = lockOrderItemStock($pdo, $agg['product_id'], $agg['variant_id']);

        if ($lockedStock === null) {
            $label = $agg['label'];
            throw new InvalidArgumentException(
                $label !== '' ? "Sản phẩm \"{$label}\" không tồn tại hoặc biến thể không hợp lệ"
                    : 'Sản phẩm không tồn tại hoặc biến thể không hợp lệ'
            );
        }

        if ($lockedStock < $agg['quantity']) {
            $label = $agg['label'];
            throw new InvalidArgumentException(
                $label !== '' ? "Sản phẩm \"{$label}\" không đủ tồn kho"
                    : 'Sản phẩm không đủ tồn kho'
            );
        }
    }

    $normalized = [];

    foreach ($items as $item) {
        $ids = parseOrderItemIds($item['id'] ?? 0);
        $resolved = resolveOrderItemPrice($pdo, $ids['product_id'], $ids['variant_id']);

        if (!$resolved['found']) {
            $label = trim((string) ($item['name'] ?? ''));
            throw new InvalidArgumentException(
                $label !== '' ? "Sản phẩm \"{$label}\" không tồn tại hoặc biến thể không hợp lệ"
                    : 'Sản phẩm không tồn tại hoặc biến thể không hợp lệ'
            );
        }

        $quantity = max(1, (int) ($item['quantity'] ?? 1));

        $normalized[] = [
            'id' => $item['id'] ?? $resolved['product_id'],
            'product_id' => $resolved['product_id'],
            'variant_id' => $ids['variant_id'],
            'name' => trim((string) ($item['name'] ?? '')) ?: $resolved['name'],
            'quantity' => $quantity,
            'price' => $resolved['price'],
            'cost_price' => $resolved['cost_price'],
        ];
    }

    return $normalized;
}
