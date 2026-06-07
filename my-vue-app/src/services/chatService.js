const apiBase = import.meta.env.VITE_API_URL || 'http://localhost:8080'

/**
 * Gửi tin nhắn tới chatbot (Groq + tools)
 * @param {string} message
 * @param {Array} history - tối đa 16 tin gần nhất (caller trim)
 * @param {{ route?: string, productId?: number|string, lastProductIds?: number[] }} context
 */
export async function sendChatMessage(message, history = [], context = {}) {
  const res = await fetch(`${apiBase}/chatbot_engine.php`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ message, history, context })
  })
  return res.json()
}

/** @typedef {{ label: string, query: string } | string} QuickSuggestion */

/** @type {QuickSuggestion[]} */
export const defaultQuickSuggestions = [
  'Đèn từ 1 đến 10 triệu',
  'Đèn trên 10 triệu',
  { label: 'Đèn chùm pha lê sang trọng', query: 'đèn chùm pha lê' },
  'Chính sách giao hàng & bảo hành'
]

export function quickSuggestionLabel(item) {
  return typeof item === 'string' ? item : item.label
}

export function quickSuggestionQuery(item) {
  return typeof item === 'string' ? item : item.query
}
