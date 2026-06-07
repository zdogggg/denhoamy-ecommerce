<?php
/**
 * Logic giá thống nhất với frontend productPrice.js / order_pricing.php
 */

function productPricingVariantPrices(array $variants): array
{
    $prices = [];
    foreach ($variants as $variant) {
        $price = (float) ($variant['price'] ?? 0);
        if ($price > 0) {
            $prices[] = $price;
        }
    }
    return $prices;
}

function productPricingResolveSalePrice(array $product, array $variants = [], ?int $variantId = null): float
{
    if ($variantId) {
        foreach ($variants as $variant) {
            if ((int) ($variant['id'] ?? 0) === $variantId) {
                return (float) ($variant['price'] ?? 0);
            }
        }
    }

    $variantPrices = productPricingVariantPrices($variants);
    if (!empty($variantPrices)) {
        return (float) min($variantPrices);
    }

    return (float) ($product['price'] ?? 0);
}

function productPricingResolveListPrice(array $product, float $salePrice): float
{
    $list = (float) ($product['old_price'] ?? 0);
    return ($list > $salePrice && $list > 0) ? $list : 0.0;
}

/**
 * @return array{sale_price: float, list_price: float, has_discount: bool, show_from: bool, is_hot_deal: bool}
 */
function productPricingDisplayMeta(array $product, array $variants = [], ?int $variantId = null): array
{
    $salePrice = productPricingResolveSalePrice($product, $variants, $variantId);
    $listPrice = productPricingResolveListPrice($product, $salePrice);
    $variantPrices = productPricingVariantPrices($variants);
    $showFrom = !$variantId && count($variantPrices) > 0;

    if ($showFrom && count($variantPrices) > 1) {
        $min = min($variantPrices);
        $max = max($variantPrices);
        $showFrom = ($min !== $max);
    }

    return [
        'sale_price' => $salePrice,
        'list_price' => $listPrice,
        'has_discount' => $listPrice > 0,
        'show_from' => $showFrom,
        'is_hot_deal' => (int) ($product['is_hot_deal'] ?? 0) === 1,
    ];
}

/** Gắn sale_price, list_price, price (compat), has_discount, show_from cho chat/API */
function productPricingEnrichRow(array &$row, array $variants = [], ?int $variantId = null): void
{
    $meta = productPricingDisplayMeta($row, $variants, $variantId);
    $row['sale_price'] = $meta['sale_price'];
    $row['list_price'] = $meta['list_price'];
    $row['has_discount'] = $meta['has_discount'];
    $row['show_from'] = $meta['show_from'];
    $row['is_hot_deal'] = $meta['is_hot_deal'];
    $row['price'] = $meta['sale_price'];
}

/**
 * @param int[] $productIds
 * @return array<int, list<array<string, mixed>>>
 */
function productPricingFetchVariantsByProductIds(PDO $pdo, array $productIds): array
{
    $productIds = array_values(array_filter(array_map('intval', $productIds)));
    if (empty($productIds)) {
        return [];
    }

    $placeholders = implode(',', array_fill(0, count($productIds), '?'));
    $stmt = $pdo->prepare("
        SELECT id, product_id, kich_thuoc, anh_sang, price, cost_price, stock
        FROM product_variants
        WHERE product_id IN ($placeholders)
    ");
    $stmt->execute($productIds);

    $byProduct = [];
    foreach ($stmt->fetchAll(PDO::FETCH_ASSOC) as $variant) {
        $pid = (int) $variant['product_id'];
        $byProduct[$pid][] = $variant;
    }

    return $byProduct;
}
