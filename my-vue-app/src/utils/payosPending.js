export const PAYOS_PENDING_ORDER_KEY = 'payos_pending_order_id'

export function setPayosPendingOrderId(orderId) {
  if (orderId == null) return
  sessionStorage.setItem(PAYOS_PENDING_ORDER_KEY, String(orderId))
}

export function getPayosPendingOrderId() {
  return sessionStorage.getItem(PAYOS_PENDING_ORDER_KEY)
}

export function clearPayosPendingOrderId() {
  sessionStorage.removeItem(PAYOS_PENDING_ORDER_KEY)
}
