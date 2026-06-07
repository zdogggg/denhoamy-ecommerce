import api from './httpClient'
import { failNull, failFalse } from './serviceErrors'

export const createOrder = async (orderData) => {
  try {
    const response = await api.post('/orders.php', orderData)
    return response.data
  } catch (error) {
    console.error('Lỗi tạo đơn hàng', error)
    if (error.response?.status === 409 && error.response?.data) {
      return { ...error.response.data, httpStatus: 409 }
    }
    return error.response?.data || failFalse()
  }
}

export const getPendingPayosOrder = async () => {
  try {
    const response = await api.get('/orders.php', { params: { action: 'pending_payos' } })
    return response.data
  } catch (error) {
    console.error('Lỗi lấy đơn PayOS pending', error)
    return failNull()
  }
}

export const retryPayosPayment = async (orderId) => {
  try {
    const response = await api.post('/orders.php', { action: 'retry_payos', orderId })
    return response.data
  } catch (error) {
    console.error('Lỗi tạo lại link PayOS', error)
    return error.response?.data || failFalse()
  }
}

export const cancelPendingOrder = async (orderId) => {
  try {
    const response = await api.put('/orders.php', { action: 'cancel_pending', orderId })
    return response.data
  } catch (error) {
    console.error('Lỗi hủy đơn pending', error)
    return error.response?.data || failFalse()
  }
}

export const getPaymentStatus = async (orderId) => {
  try {
    const response = await api.get('/orders.php', {
      params: { action: 'payment_status', orderId }
    })
    return response.data
  } catch (error) {
    console.error('Lỗi kiểm tra trạng thái thanh toán', error)
    return failNull()
  }
}

export const getOrders = async () => {
  try {
    const response = await api.get('/orders.php')
    return response.data
  } catch (error) {
    return failNull()
  }
}

export const getCustomerOrders = async (phone) => {
  try {
    const response = await api.get(`/orders.php?phone=${encodeURIComponent(phone)}`)
    return response.data
  } catch (error) {
    return failNull()
  }
}

export const updateOrder = async (id, status, admin_id = null) => {
  try {
    const response = await api.put('/orders.php', { id, status, admin_id })
    return response.data
  } catch (error) {
    console.error('Lỗi cập nhật đơn hàng', error)
    if (error.response?.data) {
      return error.response.data
    }
    return failFalse()
  }
}

export const confirmOrderReceived = async (orderId) => {
  try {
    const response = await api.put('/orders.php', {
      action: 'confirm_received',
      orderId,
    })
    return response.data
  } catch (error) {
    console.error('Lỗi xác nhận đã nhận hàng', error)
    if (error.response?.data) {
      return error.response.data
    }
    return failFalse()
  }
}

export const deleteOrder = async (id) => {
  try {
    const response = await api.delete(`/orders.php?id=${id}`)
    return response.data
  } catch (error) {
    console.error('Lỗi xóa đơn hàng', error)
    return failFalse()
  }
}

// Alias backward-compatible cho code cũ
export const deleteOrderApi = deleteOrder
