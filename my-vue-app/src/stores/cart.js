import { defineStore } from 'pinia'
import { ref, computed, watch } from 'vue'
import { getProductById, resolveSalePrice } from '../services/productService'
import { getCart, syncCart, clearServerCart } from '../services/cartService'
import { useAuthStore } from './auth'

const mapServerCartItem = (item) => ({
  id: item.id,
  code: item.code || item.id,
  name: item.name,
  image: item.image,
  price: item.price,
  stock: item.stock ?? null,
  quantity: item.quantity,
})

export function getProductIdFromCartItem(itemId) {
  const id = String(itemId)
  return id.includes('_') ? id.split('_')[0] : id
}

export function getVariantIdFromCartItem(itemId) {
  const id = String(itemId)
  return id.includes('_') ? id.split('_')[1] : null
}

function loadCartItems() {
  const raw = localStorage.getItem('cart_items')
  if (!raw) return []
  try {
    const parsed = JSON.parse(raw)
    return Array.isArray(parsed) ? parsed : []
  } catch {
    localStorage.removeItem('cart_items')
    return []
  }
}

export const useCartStore = defineStore('cart', () => {
  const items = ref(loadCartItems())

  let skipServerSync = false
  let syncTimer = null

  const canSyncToServer = () => {
    const auth = useAuthStore()
    return !!(auth.isLoggedIn && auth.user?.role === 'customer' && auth.user?.token)
  }

  const itemsForSyncPayload = () =>
    items.value.map((item) => ({
      id: item.id,
      quantity: item.quantity,
    }))

  const scheduleSyncToServer = () => {
    if (skipServerSync || !canSyncToServer()) return
    if (syncTimer) clearTimeout(syncTimer)
    syncTimer = setTimeout(() => {
      syncToServer()
    }, 500)
  }

  const syncToServer = async () => {
    if (!canSyncToServer()) return { success: false }
    const res = await syncCart(itemsForSyncPayload())
    if (res?.success && Array.isArray(res.data)) {
      skipServerSync = true
      items.value = res.data.map(mapServerCartItem)
      skipServerSync = false
    }
    return res
  }

  const mergeLocalWithServer = (serverItems) => {
    const merged = new Map()

    for (const item of items.value) {
      merged.set(String(item.id), { ...item })
    }

    for (const raw of serverItems) {
      const serverItem = mapServerCartItem(raw)
      const key = String(serverItem.id)
      const existing = merged.get(key)

      if (existing) {
        let qty = existing.quantity + serverItem.quantity
        const stockCap = serverItem.stock ?? existing.stock
        if (stockCap !== null && stockCap !== undefined && qty > stockCap) {
          qty = stockCap
        }
        merged.set(key, {
          ...existing,
          name: serverItem.name || existing.name,
          image: serverItem.image || existing.image,
          price: serverItem.price ?? existing.price,
          stock: serverItem.stock ?? existing.stock,
          quantity: qty,
        })
      } else {
        merged.set(key, serverItem)
      }
    }

    skipServerSync = true
    items.value = Array.from(merged.values())
    skipServerSync = false
  }

  const loadFromServer = async () => {
    if (!canSyncToServer()) return false
    const res = await getCart()
    if (res?.success && Array.isArray(res.data)) {
      skipServerSync = true
      items.value = res.data.map(mapServerCartItem)
      skipServerSync = false
      return true
    }
    return false
  }

  const mergeAfterLogin = async () => {
    if (!canSyncToServer()) return
    const res = await getCart()
    if (res?.success) {
      mergeLocalWithServer(res.data || [])
      await syncToServer()
    }
  }

  const hydrateFromServer = async () => {
    if (!canSyncToServer()) return false
    const res = await getCart()
    if (!res?.success) return false

    const serverItems = res.data || []
    if (serverItems.length > 0 && items.value.length > 0) {
      mergeLocalWithServer(serverItems)
      await syncToServer()
    } else if (serverItems.length > 0) {
      skipServerSync = true
      items.value = serverItems.map(mapServerCartItem)
      skipServerSync = false
    } else if (items.value.length > 0) {
      await syncToServer()
    }
    return true
  }

  watch(items, (newVal) => {
    localStorage.setItem('cart_items', JSON.stringify(newVal))
    scheduleSyncToServer()
  }, { deep: true })

  const itemCount = computed(() => {
    return items.value.reduce((total, item) => total + item.quantity, 0)
  })

  const cartTotal = computed(() => {
    return items.value.reduce((total, item) => total + (item.price * item.quantity), 0)
  })

  const addItem = (product) => {
    const addQty = product.quantity || 1
    const stock = product.stock ?? null

    const existing = items.value.find(item => item.id === product.id)
    if (existing) {
      const newQty = existing.quantity + addQty
      if (stock !== null && newQty > stock) {
        if (existing.quantity >= stock) {
          return { success: false, message: `Sản phẩm này chỉ còn ${stock} sản phẩm trong kho` }
        }
        existing.quantity = stock
        return { success: true, message: `Đã thêm vào giỏ (tối đa ${stock} sản phẩm)` }
      }
      existing.quantity = newQty
      if (stock !== null) existing.stock = stock
    } else {
      if (stock !== null && stock <= 0) {
        return { success: false, message: 'Sản phẩm đã hết hàng' }
      }
      const finalQty = (stock !== null && addQty > stock) ? stock : addQty
      items.value.push({
        id: product.id,
        code: product.code || product.id,
        name: product.name,
        image: product.image,
        price: product.price,
        stock: stock,
        quantity: finalQty
      })
    }
    return { success: true, message: 'Đã thêm vào giỏ hàng!' }
  }

  const removeItem = (index) => {
    items.value.splice(index, 1)
  }

  const updateQuantity = (index, quantity) => {
    if (items.value[index]) {
      const item = items.value[index]
      if (item.stock !== null && item.stock !== undefined && quantity > item.stock) {
        item.quantity = item.stock
      } else {
        item.quantity = Math.max(1, quantity)
      }
    }
  }

  const clearCart = async () => {
    items.value = []
    if (canSyncToServer()) {
      await clearServerCart()
    }
  }

  const syncPricesFromServer = async () => {
    if (items.value.length === 0) return { updated: false, changeCount: 0 }

    const productIds = [...new Set(items.value.map((item) => getProductIdFromCartItem(item.id)))]
    const productMap = new Map()

    await Promise.all(productIds.map(async (productId) => {
      const res = await getProductById(productId)
      if (res?.success && res.data) productMap.set(String(productId), res.data)
    }))

    let changeCount = 0
    items.value.forEach((item) => {
      const productId = getProductIdFromCartItem(item.id)
      const product = productMap.get(String(productId))
      if (!product) return
      const variantId = getVariantIdFromCartItem(item.id)
      const newPrice = resolveSalePrice(product, variantId)
      if (Number(item.price) !== Number(newPrice)) {
        changeCount += 1
        item.price = newPrice
      }
    })

    return { updated: changeCount > 0, changeCount }
  }

  return {
    items,
    itemCount,
    cartTotal,
    addItem,
    removeItem,
    updateQuantity,
    clearCart,
    syncPricesFromServer,
    syncToServer,
    loadFromServer,
    mergeAfterLogin,
    hydrateFromServer,
    getProductIdFromCartItem,
    getVariantIdFromCartItem,
  }
})
