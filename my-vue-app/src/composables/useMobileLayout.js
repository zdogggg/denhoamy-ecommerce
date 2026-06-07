import { ref, onMounted, onUnmounted } from 'vue'

/** true khi viewport <= maxWidth (mặc định 992px, khớp breakpoint tablet của site) */
export function useMobileLayout(maxWidth = 992) {
  const query = `(max-width: ${maxWidth}px)`
  const isMobile = ref(
    typeof window !== 'undefined'
      ? window.matchMedia(query).matches
      : false
  )
  let mq = null

  const update = () => {
    isMobile.value = mq ? mq.matches : window.innerWidth <= maxWidth
  }

  onMounted(() => {
    mq = window.matchMedia(query)
    update()
    mq.addEventListener('change', update)
  })

  onUnmounted(() => {
    mq?.removeEventListener('change', update)
  })

  return { isMobile }
}
