import api from './httpClient'
import { failNull, failMessage } from './serviceErrors'

/** Danh sách đầy đủ — Admin (cần JWT) */
export const getCoupons = async () => {
  try {
    const response = await api.get('/coupons.php')
    return response.data
  } catch (error) {
    console.error('Lỗi khi lấy mã giảm giá:', error)
    return failNull()
  }
}

/** Checkout — không gửi JWT để tránh nhầm API admin (GET /coupons.php không scope → 401/403) */
const publicCouponConfig = { skipAuth: true }

/** Mã đang active cho checkout — public */
export const getPublicCoupons = async () => {
  try {
    const response = await api.get('/coupons.php?scope=public', publicCouponConfig)
    return response.data
  } catch (error) {
    console.error('Lỗi khi lấy mã khuyến mãi:', error)
    const msg = error.response?.data?.message
    return msg ? failMessage(msg) : failNull()
  }
}

/**
 * @param {string} code
 * @param {{ items?: object[], orderValue?: number }} options — gửi items để server tính tạm tính (khớp lúc đặt hàng)
 */
export const applyCoupon = async (code, options = {}) => {
  const payload = { action: 'apply', code }
  if (Array.isArray(options.items) && options.items.length > 0) {
    payload.items = options.items
  } else if (options.orderValue != null) {
    payload.order_value = options.orderValue
  }

  try {
    const response = await api.post('/coupons.php', payload, publicCouponConfig)
    return response.data
  } catch (error) {
    return error.response?.data || failMessage('Lỗi kiểm tra mã')
  }
}

export const addCoupon = async (couponData) => {
  try {
    const response = await api.post('/coupons.php', couponData)
    return response.data
  } catch (error) {
    return error.response?.data || failMessage('Lỗi tạo mã giảm giá')
  }
}

export const updateCoupon = async (couponData) => {
  try {
    const response = await api.put('/coupons.php', couponData)
    return response.data
  } catch (error) {
    return error.response?.data || failMessage('Lỗi cập nhật mã')
  }
}

export const deleteCoupon = async (id) => {
  try {
    const response = await api.delete(`/coupons.php?id=${id}`)
    return response.data
  } catch (error) {
    console.error('Lỗi khi xoá mã:', error)
    return failNull()
  }
}
