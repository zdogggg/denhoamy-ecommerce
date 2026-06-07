/**
 * Format giá tiền Việt Nam: 15000000 → "15.000.000"
 */
import DOMPurify from 'dompurify'

export const formatPrice = (value) => {
  if (value === null || value === undefined) return '0'
  return Math.round(Number(value)).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ".")
}

/**
 * Formatter cho input giá (Element Plus InputNumber).
 * Hiển thị số theo dạng 1.234.567
 */
export const formatPriceInput = (value) => {
  if (value === null || value === undefined || value === '') return ''
  const num = Number(value)
  if (!Number.isFinite(num)) return ''
  return formatPrice(num)
}

/**
 * Parser cho input giá:
 * - Chỉ nhận kiểu nhập số thường
 * - Tự bỏ ký tự không phải số để trả về số nguyên
 * - Ví dụ: 7500000 / 7.500.000 / 7,500,000 => 7_500_000
 */
export const parsePriceInput = (raw) => {
  if (raw === null || raw === undefined) return ''
  const text = String(raw).trim()
  if (!text) return ''

  const digitsOnly = text.replace(/\D/g, '')
  if (!digitsOnly) return ''
  const parsed = Number(digitsOnly)
  if (!Number.isFinite(parsed)) return ''

  return Math.round(parsed)
}

/**
 * Kiểm tra xem sản phẩm có được tạo dưới 10 ngày gần đây không
 */
const isEmptyNewsBlock = (el) => {
  if (!el || el.nodeType !== 1) return false
  const tag = el.tagName
  if (tag !== 'P' && tag !== 'DIV') return false

  const clone = el.cloneNode(true)
  clone.querySelectorAll('br').forEach((br) => br.remove())
  const text = (clone.textContent || '').replace(/\u00a0/g, ' ').trim()
  const hasMedia = clone.querySelector('img, video, iframe, embed, object')
  return !text && !hasMedia
}

/**
 * Loại bỏ đoạn trống / ảnh lỗi do Quill editor tạo ra khi soạn bài.
 */
export const sanitizeNewsHtml = (html) => {
  if (!html || typeof html !== 'string') return ''

  if (typeof DOMParser === 'undefined') {
    return html
      .replace(/<p>(\s|&nbsp;|<br\s*\/?>)*<\/p>/gi, '')
      .replace(/<div>(\s|&nbsp;|<br\s*\/?>)*<\/div>/gi, '')
      .trim()
  }

  const doc = new DOMParser().parseFromString(`<div id="news-root">${html}</div>`, 'text/html')
  const root = doc.getElementById('news-root')
  if (!root) return html.trim()

  root.querySelectorAll('img').forEach((img) => {
    const src = (img.getAttribute('src') || '').trim()
    if (!src) img.remove()
  })

  let changed = true
  while (changed) {
    changed = false
    root.querySelectorAll('p, div').forEach((el) => {
      if (el.id === 'news-root') return
      if (isEmptyNewsBlock(el)) {
        el.remove()
        changed = true
      }
    })
  }

  return root.innerHTML.trim()
}

/** Lọc HTML rich text (mô tả SP, chính sách) — chống XSS, giữ format cơ bản. */
export const sanitizeRichHtml = (html) => {
  if (!html || typeof html !== 'string') return ''
  return DOMPurify.sanitize(html, {
    ALLOWED_TAGS: ['p', 'br', 'strong', 'b', 'em', 'i', 'u', 'ul', 'ol', 'li', 'h1', 'h2', 'h3', 'h4', 'a', 'img', 'span', 'div'],
    ALLOWED_ATTR: ['href', 'src', 'alt', 'title', 'target', 'rel', 'class'],
    ALLOW_DATA_ATTR: false,
  })
}

export const checkIsNewArrival = (dateStr) => {
  if (!dateStr) return false
  const dateCreated = new Date(dateStr)
  if (isNaN(dateCreated.getTime())) return false
  const today = new Date()
  if (dateCreated > today) return false
  const diffTime = today - dateCreated
  const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24))
  return diffDays <= 10
}
