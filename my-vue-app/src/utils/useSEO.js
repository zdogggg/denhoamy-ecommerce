/**
 * Composable: useSEO
 * Cập nhật động các Meta Tags SEO quan trọng cho mỗi trang.
 * - title, description, keywords
 * - Open Graph (og:title, og:description, og:image, og:url)
 * - Canonical URL
 * Giúp link chia sẻ trên Facebook, Zalo, Telegram hiển thị đẹp.
 */
export function useSEO({ title, description, keywords, image, url }) {
    // 1. Title
    if (title) {
        document.title = title
    }

    // 2. Cập nhật hoặc tạo meta tag
    const setMeta = (attr, key, content) => {
        if (!content) return
        let el = document.querySelector(`meta[${attr}="${key}"]`)
        if (!el) {
            el = document.createElement('meta')
            el.setAttribute(attr, key)
            document.head.appendChild(el)
        }
        el.setAttribute('content', content)
    }

    // Meta Description (SEO chính)
    setMeta('name', 'description', description)

    // Meta Keywords
    setMeta('name', 'keywords', keywords)

    // Open Graph Tags (Chia sẻ mạng xã hội)
    setMeta('property', 'og:title', title)
    setMeta('property', 'og:description', description)
    setMeta('property', 'og:image', image)
    setMeta('property', 'og:url', url || window.location.href)
    setMeta('property', 'og:type', 'website')

    // 3. Canonical URL (Tránh duplicate content)
    let canonical = document.querySelector('link[rel="canonical"]')
    if (!canonical) {
        canonical = document.createElement('link')
        canonical.setAttribute('rel', 'canonical')
        document.head.appendChild(canonical)
    }
    canonical.setAttribute('href', url || window.location.href)
}
