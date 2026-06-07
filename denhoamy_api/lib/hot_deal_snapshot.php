<?php
/**
 * Snapshot giá trước Hot Deal — capture một lần, restore khi gỡ Hot Deal.
 */

/**
 * @return array{product: array<string, mixed>|false, variants: list<array<string, mixed>>}
 */
function hotDealLoadProductWithVariants(PDO $pdo, int $productId): array
{
    $pStmt = $pdo->prepare('
        SELECT id, price, old_price, price_before_hot_deal, old_price_before_hot_deal
        FROM products
        WHERE id = ? AND deleted_at IS NULL
    ');
    $pStmt->execute([$productId]);
    $product = $pStmt->fetch(PDO::FETCH_ASSOC);

    if (!$product) {
        return ['product' => false, 'variants' => []];
    }

    $vStmt = $pdo->prepare('
        SELECT id, product_id, price, price_before_hot_deal
        FROM product_variants
        WHERE product_id = ?
    ');
    $vStmt->execute([$productId]);

    return ['product' => $product, 'variants' => $vStmt->fetchAll(PDO::FETCH_ASSOC)];
}

/**
 * @param array<string, mixed> $product
 * @param list<array<string, mixed>> $variants
 */
function hotDealSnapshotAlreadyCaptured(array $product, array $variants): bool
{
    if ($product['price_before_hot_deal'] !== null) {
        return true;
    }

    foreach ($variants as $variant) {
        if ($variant['price_before_hot_deal'] !== null) {
            return true;
        }
    }

    return false;
}

/** Ghi snapshot giá hiện tại nếu chưa có (idempotent). */
function hotDealCaptureSnapshot(PDO $pdo, int $productId): void
{
    $loaded = hotDealLoadProductWithVariants($pdo, $productId);
    $product = $loaded['product'];
    $variants = $loaded['variants'];

    if ($product === false || hotDealSnapshotAlreadyCaptured($product, $variants)) {
        return;
    }

    $pdo->prepare('
        UPDATE products
        SET price_before_hot_deal = price,
            old_price_before_hot_deal = old_price
        WHERE id = ?
    ')->execute([$productId]);

    if (!empty($variants)) {
        $vSnap = $pdo->prepare('
            UPDATE product_variants
            SET price_before_hot_deal = price
            WHERE id = ? AND product_id = ?
        ');
        foreach ($variants as $variant) {
            $vSnap->execute([(int) $variant['id'], $productId]);
        }
    }
}

/**
 * Khôi phục giá từ snapshot và xóa snapshot.
 *
 * @return bool true nếu đã restore, false nếu không có snapshot (chỉ gỡ cờ)
 */
function hotDealRestoreAndClear(PDO $pdo, int $productId): bool
{
    $loaded = hotDealLoadProductWithVariants($pdo, $productId);
    $product = $loaded['product'];
    $variants = $loaded['variants'];

    if ($product === false || $product['price_before_hot_deal'] === null) {
        return false;
    }

    $restorePrice = (float) $product['price_before_hot_deal'];
    $restoreOldPrice = $product['old_price_before_hot_deal'] !== null
        ? (float) $product['old_price_before_hot_deal']
        : 0.0;

    if (!empty($variants)) {
        $vRestore = $pdo->prepare('
            UPDATE product_variants
            SET price = price_before_hot_deal
            WHERE id = ? AND product_id = ? AND price_before_hot_deal IS NOT NULL
        ');
        $prices = [];
        foreach ($variants as $variant) {
            if ($variant['price_before_hot_deal'] === null) {
                $prices[] = (float) ($variant['price'] ?? 0);
                continue;
            }
            $vRestore->execute([(int) $variant['id'], $productId]);
            $prices[] = (float) $variant['price_before_hot_deal'];
        }
        $positive = array_filter($prices, static fn ($p) => $p > 0);
        if (!empty($positive)) {
            $restorePrice = (float) min($positive);
        }
    }

    $pdo->prepare('
        UPDATE products
        SET price = ?, old_price = ?,
            price_before_hot_deal = NULL,
            old_price_before_hot_deal = NULL
        WHERE id = ?
    ')->execute([$restorePrice, $restoreOldPrice, $productId]);

    $pdo->prepare('
        UPDATE product_variants
        SET price_before_hot_deal = NULL
        WHERE product_id = ?
    ')->execute([$productId]);

    return true;
}
