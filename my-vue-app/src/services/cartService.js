import api from './httpClient'

/** Lấy giỏ hàng từ server (customer đã đăng nhập). */
export const getCart = async () => {
  try {
    const response = await api.get('/cart.php')
    return response.data
  } catch (error) {
    console.error('Lỗi khi lấy giỏ hàng:', error)
    return { success: false, message: error.response?.data?.message || 'Không thể tải giỏ hàng' }
  }
}

/**
 * Đồng bộ toàn bộ giỏ lên server.
 * @param {Array<{ id: string|number, quantity: number, product_id?: number, variant_id?: number }>} items
 */
export const syncCart = async (items) => {
  try {
    const response = await api.put('/cart.php', { items })
    return response.data
  } catch (error) {
    console.error('Lỗi khi đồng bộ giỏ hàng:', error)
    return { success: false, message: error.response?.data?.message || 'Không thể đồng bộ giỏ hàng' }
  }
}

/** Xóa toàn bộ giỏ trên server. */
export const clearServerCart = async () => {
  try {
    const response = await api.delete('/cart.php', { params: { clear: 1 } })
    return response.data
  } catch (error) {
    console.error('Lỗi khi xóa giỏ server:', error)
    return { success: false }
  }
}
