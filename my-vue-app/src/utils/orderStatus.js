export const ORDER_STATUS_LABELS = {
  pending: 'Chờ xác nhận',
  approved: 'Đã xác nhận',
  shipping: 'Đang giao hàng',
  completed: 'Hoàn thành',
  cancelled: 'Đã hủy',
}

export const ORDER_STATUS_TAG_TYPES = {
  pending: 'warning',
  approved: 'primary',
  shipping: '',
  completed: 'success',
  cancelled: 'danger',
}

/** Bước tiếp theo trong luồng chuẩn (không gồm hủy). */
export function getNextStatus(current) {
  const flow = {
    pending: 'approved',
    approved: 'shipping',
    shipping: 'completed',
  }
  return flow[current] ?? null
}

export function getStatusLabel(code) {
  return ORDER_STATUS_LABELS[code] ?? code
}

export function getStatusTagType(code) {
  return ORDER_STATUS_TAG_TYPES[code] ?? 'info'
}

export function canCancelStatus(current) {
  return ['pending', 'approved', 'shipping'].includes(current)
}

/** Đơn đã hủy không in hóa đơn / phiếu giao */
export function canPrintOrderDocuments(status) {
  return status !== 'cancelled'
}

export function getNextStatusButtonLabel(current) {
  const next = getNextStatus(current)
  if (!next) return null
  return getStatusLabel(next)
}
