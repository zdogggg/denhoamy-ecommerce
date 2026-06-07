import { marked } from 'marked'
import DOMPurify from 'dompurify'

marked.setOptions({ breaks: true, gfm: true })

const ALLOWED_TAGS = [
  'p', 'br', 'strong', 'em', 'b', 'i', 'ul', 'ol', 'li',
  'table', 'thead', 'tbody', 'tr', 'th', 'td',
  'a', 'h1', 'h2', 'h3', 'h4', 'code', 'pre', 'blockquote', 'span'
]

const ALLOWED_ATTR = ['href', 'target', 'rel', 'class']

const PRODUCT_LINK_LABEL = 'Xem chi tiết →'

/** Markdown link thân thiện: [/product/85](/product/85) → [Xem chi tiết →](/product/85) */
function friendlyProductMarkdownLinks(text) {
  if (!text) return ''
  return text.replace(
    /\[(\/product\/\d+)\]\((\/product\/\d+)\)/gi,
    (_match, _label, href) => `[${PRODUCT_LINK_LABEL}](${href})`
  )
}

/** Biến đường dẫn /product/:id thành link markdown (nhãn thân thiện, không hiện URL) */
function linkifyProductPaths(text) {
  if (!text) return ''
  return text.replace(/(\/product\/\d+)/gi, (path, _m, offset, full) => {
    const before = full[offset - 1]
    const after = full[offset + path.length]
    if (before === '(' || before === ']') return path
    if (after === ')') return path
    return `[${PRODUCT_LINK_LABEL}](${path})`
  })
}

/** Bỏ block chỉ liệt kê link SP khi đã có thẻ sản phẩm bên dưới */
function stripRedundantProductLinkBlocks(text) {
  if (!text) return ''
  let out = text
  out = out.replace(
    /\n*Quý khách có thể xem chi tiết[^\n]*:\s*\n(?:(?:[-*•]\s*)?(?:\[(?:\/product\/\d+|Xem chi tiết →)\]\(\/product\/\d+\)|\/product\/\d+)\s*\n?)+/gi,
    '\n'
  )
  out = out.replace(
    /\n*(?:[-*•]\s*)?\[(?:\/product\/\d+|Xem chi tiết →)\]\(\/product\/\d+\)\s*(?:\n|$)/gi,
    '\n'
  )
  out = out.replace(/\n{3,}/g, '\n\n').trim()
  return out
}

function prepareChatBotText(text, { hasProductCards = false } = {}) {
  let out = text || ''
  if (hasProductCards) {
    out = stripRedundantProductLinkBlocks(out)
  }
  out = friendlyProductMarkdownLinks(out)
  out = linkifyProductPaths(out)
  return out
}

/**
 * Markdown an toàn cho bubble chat (chống XSS từ model)
 * @param {string} text
 * @param {{ hasProductCards?: boolean }} [options]
 */
export function renderSafeMarkdown(text, options = {}) {
  const raw = marked.parse(prepareChatBotText(text, options))
  return DOMPurify.sanitize(raw, {
    ALLOWED_TAGS,
    ALLOWED_ATTR,
    ADD_ATTR: ['target', 'rel']
  })
}

export function formatChatPrice(val) {
  const n = Number(val)
  if (Number.isNaN(n)) return 'Liên hệ'
  return n.toString().replace(/\B(?=(\d{3})+(?!\d))/g, '.') + ' đ'
}

/** Trích ID sản phẩm từ text bot (vd. /product/76) cho context follow-up */
export function extractProductIdsFromText(text, limit = 5) {
  const ids = []
  if (!text) return ids
  const re = /\/product\/(\d+)/gi
  let m
  while ((m = re.exec(text)) && ids.length < limit) {
    const id = Number(m[1])
    if (id > 0 && !ids.includes(id)) ids.push(id)
  }
  return ids
}

export function resolveProductImage(url, apiBase) {
  if (!url) return ''
  if (url.startsWith('http') || url.startsWith('//')) return url
  if (url.startsWith('/') || url.startsWith('uploads/')) {
    return url.startsWith('/') ? url : '/' + url
  }
  const base = (apiBase || '').replace(/\/$/, '')
  return base ? `${base}${url.startsWith('/') ? url : '/' + url}` : url
}
