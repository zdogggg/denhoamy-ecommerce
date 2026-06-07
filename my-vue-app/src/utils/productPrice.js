import { formatPrice } from './format'

/** Giá bán từng biến thể (chỉ giá > 0) */
export function getVariantSalePrices(product) {
  const variants = Array.isArray(product?.variants) ? product.variants : []
  return variants.map((v) => Number(v.price) || 0).filter((p) => p > 0)
}

export function hasVariants(product) {
  return getVariantSalePrices(product).length > 0
}

/**
 * Giá bán thực tế: biến thể đã chọn, hoặc min biến thể, hoặc giá sản phẩm.
 */
export function resolveSalePrice(product, variantId = null) {
  if (!product) return 0
  const variants = Array.isArray(product.variants) ? product.variants : []
  if (variantId) {
    const variant = variants.find((v) => String(v.id) === String(variantId))
    if (variant) return Number(variant.price) || 0
  }
  const variantPrices = getVariantSalePrices(product)
  if (variantPrices.length > 0) return Math.min(...variantPrices)
  return Number(product.price) || 0
}

/** Giá gốc (gạch) — chỉ khi old_price > giá bán thực tế */
export function resolveListPrice(product, salePrice = null) {
  const sale = salePrice ?? resolveSalePrice(product)
  const list = Number(product?.old_price) || 0
  return list > sale && list > 0 ? list : 0
}

export function hasSaleDiscount(product, salePrice = null) {
  return resolveListPrice(product, salePrice) > 0
}

export function getDiscountPercent(product, salePrice = null) {
  const list = resolveListPrice(product, salePrice)
  const sale = salePrice ?? resolveSalePrice(product)
  if (list <= 0 || sale <= 0) return 0
  return Math.round((1 - sale / list) * 100)
}

/**
 * Nhãn giá thống nhất cho thẻ sản phẩm (trang chủ, danh mục, liên quan).
 */
export function getProductPriceDisplay(product, variantId = null) {
  const salePrice = resolveSalePrice(product, variantId)
  const listPrice = resolveListPrice(product, salePrice)
  const variantPrices = getVariantSalePrices(product)
  let saleLabel = `${formatPrice(salePrice)}đ`

  if (!variantId && variantPrices.length > 0) {
    const min = Math.min(...variantPrices)
    const max = Math.max(...variantPrices)
    saleLabel = min === max ? `${formatPrice(min)}đ` : `Từ ${formatPrice(min)}đ`
  }

  return {
    salePrice,
    listPrice,
    saleLabel,
    hasDiscount: listPrice > 0
  }
}
