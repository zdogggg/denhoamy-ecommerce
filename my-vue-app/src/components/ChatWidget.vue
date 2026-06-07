<template>
  <div class="chatbot-wrapper" :class="{ 'is-open': isChatOpen }">
    <transition name="el-zoom-in-bottom">
      <div v-show="isChatOpen" class="chat-window">

        <!-- ===================== VIEW: WELCOME ===================== -->
        <div v-if="currentView === 'welcome'" class="welcome-view">
          <!-- Header gradient -->
          <div class="welcome-header">
            <button class="wh-close-btn" @click="toggleChat">—</button>
            <div class="wh-title">Xin chào</div>
            <div class="wh-subtitle">Tôi có thể hỗ trợ gì cho bạn hôm nay?</div>
          </div>

          <!-- Store card -->
          <div class="welcome-body">
            <div class="store-card">
              <div class="store-card-left">
                <div class="store-avatar-wrap">
                  <el-avatar :size="48" src="https://api.dicebear.com/7.x/bottts/svg?seed=Felix" class="store-avatar" />
                  <span class="online-badge"></span>
                </div>
                <div class="store-info">
                  <div class="store-name">Đèn Hoa Mỹ</div>
                  <div class="store-greeting">Chào mừng Quý khách! Tôi có thể tư vấn đèn trang trí cho bạn.</div>
                </div>
              </div>
            </div>

            <!-- CTA button -->
            <button class="cta-btn" @click="goToChat()">
              Gửi tin nhắn &nbsp;➤
            </button>
            <button v-if="isOnProductPage" class="cta-btn cta-btn-secondary" @click="askAboutCurrentProduct">
              Hỏi về mẫu này
            </button>

            <!-- Quick suggestions -->
            <div class="quick-label">Câu hỏi thường gặp</div>
            <div class="quick-list">
              <button
                v-for="(q, i) in quickSuggestions"
                :key="i"
                class="quick-item"
                @click="goToChat(quickSuggestionQuery(q))"
              >
                <span>{{ quickSuggestionLabel(q) }}</span>
                <span class="quick-arrow">→</span>
              </button>
            </div>
          </div>

          <!-- Bottom nav -->
          <div class="welcome-footer">
            <div class="wnav-row">
              <button class="wnav-item" :class="{ active: currentView === 'welcome' }" @click="goHome">
                <span class="wnav-icon"><el-icon><HomeFilled /></el-icon></span>
                <span>Trang chủ</span>
              </button>
              <button class="wnav-item" :class="{ active: currentView === 'chat' }" @click="goToChat()">
                <span class="wnav-icon"><el-icon><ChatLineRound /></el-icon></span>
                <span>Nhắn tin</span>
              </button>
              <button class="wnav-item" :class="{ active: currentView === 'contact' }" @click="currentView = 'contact'">
                <span class="wnav-icon"><el-icon><QuestionFilled /></el-icon></span>
                <span>Trợ giúp</span>
              </button>
              <button class="wnav-item" @click="goToOrders">
                <span class="wnav-icon"><el-icon><Goods /></el-icon></span>
                <span>Đơn hàng</span>
              </button>
            </div>
            <div class="wnav-powered">Tích hợp Trí tuệ nhân tạo • Powered by <strong>Groq AI</strong></div>
          </div>
        </div>

        <!-- ===================== VIEW: CONTACT (TRỢ GIÚP) ===================== -->
        <div v-else-if="currentView === 'contact'" class="contact-view">
          <div class="contact-header">
            <button class="wh-close-btn" @click="toggleChat">—</button>
            <div class="contact-header-title">Trợ giúp &amp; Liên hệ</div>
            <div class="contact-header-sub">Chúng tôi luôn sẵn sàng hỗ trợ Quý khách</div>
          </div>
          <div class="contact-body">
            <a href="tel:0978897579" class="contact-card">
              <div class="contact-icon phone"><el-icon><PhoneFilled /></el-icon></div>
              <div class="contact-info">
                <div class="contact-label">Gọi điện trực tiếp (Hotline / Bàn)</div>
                <div class="contact-value">0978 897 579 | 02256 533 618</div>
                <div class="contact-sub">Thứ 2 – Thứ 7, 8:00 – 17:30</div>
              </div>
              <span class="contact-arrow">→</span>
            </a>
            <a href="https://m.me/DenHoaMy" target="_blank" rel="noopener" class="contact-card">
              <div class="contact-icon messenger"><el-icon><ChatRound /></el-icon></div>
              <div class="contact-info">
                <div class="contact-label">Messenger Facebook</div>
                <div class="contact-value">Nhắn tin ngay</div>
                <div class="contact-sub">Phản hồi trong vòng 5 phút</div>
              </div>
              <span class="contact-arrow">→</span>
            </a>
            <div class="contact-note">
              📍 <strong>Địa chỉ:</strong> 905 Nguyễn Văn Linh, An Biên, Hải Phòng
            </div>
          </div>
          <div class="welcome-footer">
            <div class="wnav-row">
              <button class="wnav-item" @click="goHome">
                <span class="wnav-icon"><el-icon><HomeFilled /></el-icon></span><span>Trang chủ</span>
              </button>
              <button class="wnav-item" @click="goToChat()">
                <span class="wnav-icon"><el-icon><ChatLineRound /></el-icon></span><span>Nhắn tin</span>
              </button>
              <button class="wnav-item active">
                <span class="wnav-icon"><el-icon><QuestionFilled /></el-icon></span><span>Trợ giúp</span>
              </button>
              <button class="wnav-item" @click="goToOrders">
                <span class="wnav-icon"><el-icon><Goods /></el-icon></span><span>Đơn hàng</span>
              </button>
            </div>
            <div class="wnav-powered">Tích hợp Trí tuệ nhân tạo • Powered by <strong>Groq AI</strong></div>
          </div>
        </div>

        <!-- ===================== VIEW: CHAT ===================== -->
        <div v-else class="chat-view">
          <div class="chat-header">
            <button class="back-btn" @click="currentView = 'welcome'">←</button>
            <div class="bot-info">
              <el-avatar :size="34" src="https://api.dicebear.com/7.x/bottts/svg?seed=Felix" class="bot-avatar" />
              <div class="bot-text">
                <strong>AI Tư Vấn Đèn</strong>
                <span><span class="online-dot"></span> Đang trực tuyến</span>
              </div>
            </div>
            <el-button
              v-if="hasChatHistory()"
              :icon="RefreshLeft"
              circle
              text
              class="reset-chat-btn"
              title="Cuộc trò chuyện mới"
              @click="confirmResetChat"
            />
            <el-button :icon="Close" circle text class="close-chat-btn" @click="toggleChat" />
          </div>

          <div class="chat-body" ref="chatBodyRef" @click="handleChatBodyClick">
            <div
              v-for="(msg, index) in chatMessages"
              :key="msg.key ?? `chat-msg-${index}`"
              :class="['message-wrapper', msg.sender === 'user' ? 'is-user' : 'is-bot']"
            >
              <div v-if="msg.sender === 'bot'" class="bot-message-block">
                <div class="message-bubble" v-html="renderMarkdown(msg.text, msg)"></div>
                <button
                  v-if="msg.retryable"
                  type="button"
                  class="retry-btn"
                  @click="retryLastMessage"
                >
                  Thử lại
                </button>
                <div v-if="msg.engine === 'rule_based'" class="engine-badge">
                  Trả lời tự động từ kho hàng
                </div>
                <div v-if="msg.products?.length" class="product-cards">
                  <div
                    v-for="(p, pIdx) in msg.products"
                    :key="p.id ?? p.ma_san_pham ?? pIdx"
                    class="product-card"
                    role="button"
                    tabindex="0"
                    @click.stop="goToProduct(p.id)"
                    @keyup.enter.stop="goToProduct(p.id)"
                  >
                    <img
                      v-if="p.image_url"
                      :src="productImageUrl(p.image_url)"
                      :alt="p.ten_san_pham"
                      class="product-card-img"
                    />
                    <div class="product-card-body">
                      <div class="product-card-name">
                        {{ p.ten_san_pham }}
                        <span v-if="p.is_hot_deal" class="product-hot-tag">Hot Deal</span>
                      </div>
                      <div class="product-card-meta">
                        {{ p.ma_san_pham }}
                        <span
                          v-if="p.stock != null"
                          :class="p.stock > 0 ? 'stock-ok' : 'stock-out'"
                        >
                          · {{ p.stock > 0 ? `Còn ${p.stock} sp` : 'Hết hàng' }}
                        </span>
                      </div>
                      <div class="product-card-prices">
                        <span v-if="chatListPrice(p) > 0" class="product-old-price">{{ formatPrice(chatListPrice(p)) }}</span>
                        <span class="product-sale-price">
                          <template v-if="p.show_from">Từ </template>{{ formatPrice(chatSalePrice(p)) }}
                        </span>
                      </div>
                      <span class="product-card-cta">Xem sản phẩm →</span>
                    </div>
                  </div>
                </div>
              </div>
              <div class="message-bubble" v-else>{{ msg.text }}</div>
            </div>
            <div v-if="isBotTyping" class="message-wrapper is-bot">
              <div class="message-bubble typing-indicator">
                <span></span><span></span><span></span>
              </div>
            </div>
            <div v-if="showFollowUpChips" class="follow-up-chips">
              <button type="button" class="follow-up-chip" @click="sendMessage('So sánh các mẫu trên')">
                So sánh các mẫu trên
              </button>
              <button type="button" class="follow-up-chip" @click="sendMessage('Xem thêm cùng loại')">
                Xem thêm cùng loại
              </button>
            </div>
          </div>

          <div class="chat-footer">
            <el-input
              v-model="userInput"
              placeholder="Nhập câu hỏi cho AI..."
              maxlength="500"
              show-word-limit
              @keyup.enter="sendMessage()"
              class="chat-input"
              :disabled="isBotTyping"
            >
              <template #append>
                <el-button :icon="Position" class="send-btn" @click="sendMessage()" :disabled="isBotTyping" />
              </template>
            </el-input>
          </div>
        </div>

      </div>
    </transition>

    <!-- Teaser bubble (hiện khi chat đóng) -->
    <transition name="teaser">
      <div v-if="!isChatOpen && showTeaser" class="chat-teaser" @click="toggleChat">
        <div class="teaser-avatar">
          <el-avatar :size="34" src="https://api.dicebear.com/7.x/bottts/svg?seed=Felix" />
          <span class="teaser-dot"></span>
        </div>
        <div class="teaser-body">
          <div class="teaser-name">Đèn Hoa Mỹ</div>
          <div class="teaser-msg">Xin chào! Tôi có thể giúp gì cho Quý khách?</div>
        </div>
        <button class="teaser-close" @click.stop="showTeaser = false">&times;</button>
      </div>
    </transition>

    <!-- Toggle button (desktop: full / mobile open: mini FAB) -->
    <el-button class="chat-toggle-btn" :class="{ 'is-mini-fab': isChatOpen }" circle @click="toggleChat">
      <el-icon :size="28"><ChatDotRound v-if="!isChatOpen" /><Close v-else /></el-icon>
    </el-button>
  </div>
</template>

<script setup>
import { ref, nextTick, computed, onMounted, onBeforeUnmount, watch } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { ElMessageBox } from 'element-plus'
import { ChatDotRound, Close, Position, HomeFilled, ChatLineRound, QuestionFilled, Goods, PhoneFilled, ChatRound, RefreshLeft } from '@element-plus/icons-vue'
import { useAuthStore } from '../stores/auth'
import { sendChatMessage, defaultQuickSuggestions, quickSuggestionLabel, quickSuggestionQuery } from '../services/chatService'
import { renderSafeMarkdown, formatChatPrice, resolveProductImage, extractProductIdsFromText } from '../utils/chatMarkdown'

const MAX_MESSAGE_LENGTH = 500
const SESSION_SAVE_DEBOUNCE_MS = 300

const apiBase = import.meta.env.VITE_API_URL || 'http://localhost:8080'
const renderMarkdown = (text, msg) =>
  renderSafeMarkdown(text, { hasProductCards: !!(msg?.products?.length) })
const formatPrice = formatChatPrice
const productImageUrl = (url) => resolveProductImage(url, apiBase)

const chatSalePrice = (p) => Number(p?.sale_price ?? p?.price) || 0
const chatListPrice = (p) => Number(p?.list_price) || 0

const router = useRouter()
const route = useRoute()
const authStore = useAuthStore()

const isChatOpen  = ref(false)
const isBotTyping = ref(false)
const userInput   = ref('')
const chatBodyRef = ref(null)
const currentView = ref('welcome') // 'welcome' | 'chat' | 'contact'
const lastFailedUserText = ref('')

// Teaser bubble: hiện cho đến khi khách tự đóng hoặc mở chat
const showTeaser  = ref(true)

const createWelcomeMessage = () => ({
  key: 'welcome-bot',
  sender: 'bot',
  text: 'Chào Quý khách! Tôi là AI trợ lý của **Đèn Hoa Mỹ**. Quý khách đang tìm mẫu đèn nào ạ?'
})

const chatMessages = ref([createWelcomeMessage()])

const lastSuggestedProductIds = ref([])

const CHAT_SESSION_KEY = 'denhoamy_chat_session'

let chatMsgSeq = 0
let sessionSaveTimer = null
const nextMessageKey = () => `m${++chatMsgSeq}-${Date.now()}`

const hasChatHistory = () => chatMessages.value.some((m) => m.sender === 'user')

const isOnProductPage = computed(() => route.name === 'product-detail' && !!route.params.id)

const showFollowUpChips = computed(() =>
  currentView.value === 'chat' &&
  !isBotTyping.value &&
  lastSuggestedProductIds.value.length >= 2 &&
  hasChatHistory()
)

const sanitizeStoredProduct = (p) => {
  if (!p || typeof p !== 'object') return null
  const id = Number(p.id)
  if (!id || Number.isNaN(id)) return null
  return {
    id,
    ten_san_pham: String(p.ten_san_pham ?? ''),
    ma_san_pham: String(p.ma_san_pham ?? ''),
    price: Number(p.price ?? p.sale_price) || 0,
    sale_price: Number(p.sale_price ?? p.price) || 0,
    list_price: Number(p.list_price) || 0,
    has_discount: !!p.has_discount,
    show_from: !!p.show_from,
    is_hot_deal: !!p.is_hot_deal,
    image_url: String(p.image_url ?? ''),
    stock: p.stock != null ? Number(p.stock) : null,
  }
}

const sanitizeStoredMessages = (messages) => {
  if (!Array.isArray(messages)) return []
  return messages
    .filter(
      (m) =>
        m &&
        typeof m === 'object' &&
        typeof m.text === 'string' &&
        (m.sender === 'user' || m.sender === 'bot')
    )
    .map((m, index) => {
      const out = {
        key: typeof m.key === 'string' ? m.key : `restored-${index}`,
        sender: m.sender,
        text: m.text,
      }
      if (m.engine === 'groq' || m.engine === 'rule_based') {
        out.engine = m.engine
      }
      if (m.retryable) out.retryable = true
      if (m.sender === 'bot' && Array.isArray(m.products)) {
        const products = m.products.map(sanitizeStoredProduct).filter(Boolean).slice(0, 5)
        if (products.length > 0) out.products = products
      }
      return out
    })
}

const saveChatSessionNow = () => {
  try {
    sessionStorage.setItem(
      CHAT_SESSION_KEY,
      JSON.stringify({
        messages: chatMessages.value,
        lastSuggestedProductIds: lastSuggestedProductIds.value,
        currentView: currentView.value,
        isChatOpen: isChatOpen.value,
      })
    )
  } catch {
    /* quota / private mode */
  }
}

const scheduleSaveChatSession = () => {
  if (sessionSaveTimer) clearTimeout(sessionSaveTimer)
  sessionSaveTimer = setTimeout(() => {
    sessionSaveTimer = null
    saveChatSessionNow()
  }, SESSION_SAVE_DEBOUNCE_MS)
}

const loadChatSession = () => {
  try {
    const raw = sessionStorage.getItem(CHAT_SESSION_KEY)
    if (!raw) return
    const data = JSON.parse(raw)
    const stored = sanitizeStoredMessages(data.messages)
    if (stored.length > 0) {
      chatMessages.value = stored
    }
    if (Array.isArray(data.lastSuggestedProductIds)) {
      lastSuggestedProductIds.value = data.lastSuggestedProductIds
        .map((id) => Number(id))
        .filter((id) => id > 0)
        .slice(0, 5)
    }
    if (data.currentView === 'chat' || data.currentView === 'contact') {
      currentView.value = data.currentView
    } else if (hasChatHistory()) {
      currentView.value = 'chat'
    }
    if (typeof data.isChatOpen === 'boolean') {
      isChatOpen.value = data.isChatOpen
    }
  } catch {
    sessionStorage.removeItem(CHAT_SESSION_KEY)
  }
}

const isNearBottom = (threshold = 80) => {
  const el = chatBodyRef.value
  if (!el) return true
  return el.scrollHeight - el.scrollTop - el.clientHeight <= threshold
}

const scrollToBottom = async () => {
  await nextTick()
  if (chatBodyRef.value) chatBodyRef.value.scrollTop = chatBodyRef.value.scrollHeight
}

const scrollToBottomIfNear = async (force = false) => {
  if (force || isNearBottom()) {
    await scrollToBottom()
  }
}

const mergeSuggestedProductIds = (products, replyText) => {
  const fromProducts = products.map((p) => Number(p.id)).filter((id) => id > 0)
  const fromText = extractProductIdsFromText(replyText)
  lastSuggestedProductIds.value = [...new Set([...fromProducts, ...fromText])].slice(0, 5)
}

onMounted(() => {
  loadChatSession()
  chatMsgSeq = chatMessages.value.length
  setTimeout(() => {
    showTeaser.value = false
  }, 8000)
  if (isChatOpen.value && currentView.value === 'chat') {
    nextTick(scrollToBottom)
  }
})

onBeforeUnmount(() => {
  if (sessionSaveTimer) {
    clearTimeout(sessionSaveTimer)
    sessionSaveTimer = null
  }
  saveChatSessionNow()
})

watch(
  [chatMessages, lastSuggestedProductIds, currentView, isChatOpen],
  () => scheduleSaveChatSession(),
  { deep: true }
)

const quickSuggestions = computed(() => defaultQuickSuggestions)

const toggleChat = () => {
  const willOpen = !isChatOpen.value
  isChatOpen.value = willOpen
  if (willOpen) {
    currentView.value = hasChatHistory() ? 'chat' : 'welcome'
    nextTick(() => scrollToBottomIfNear(true))
  }
}

const closeChat = () => {
  isChatOpen.value = false
}

const resetChatSession = () => {
  chatMessages.value = [createWelcomeMessage()]
  lastSuggestedProductIds.value = []
  lastFailedUserText.value = ''
  userInput.value = ''
  isBotTyping.value = false
  currentView.value = 'chat'
  isChatOpen.value = true
  chatMsgSeq = 1
  sessionStorage.removeItem(CHAT_SESSION_KEY)
  saveChatSessionNow()
  nextTick(() => scrollToBottomIfNear(true))
}

const confirmResetChat = async () => {
  try {
    await ElMessageBox.confirm(
      'Bắt đầu cuộc trò chuyện mới? Lịch sử hiện tại sẽ bị xóa.',
      'Cuộc trò chuyện mới',
      { confirmButtonText: 'Bắt đầu lại', cancelButtonText: 'Hủy', type: 'warning' }
    )
    resetChatSession()
  } catch {
    /* cancelled */
  }
}

/** Mở trang SP — giữ chat mở và lịch sử */
const goToProduct = (productId) => {
  const id = Number(productId)
  if (!id || Number.isNaN(id)) return
  currentView.value = 'chat'
  const next = { name: 'product-detail', params: { id: String(id) } }
  if (route.name === 'product-detail' && String(route.params.id) === String(id)) return
  router.push(next).catch(() => {})
}

/** Link nội bộ trong markdown bubble → Vue Router */
const handleChatBodyClick = (e) => {
  if (e.target.closest?.('.product-card') || e.target.closest?.('.retry-btn') || e.target.closest?.('.follow-up-chip')) return
  const anchor = e.target.closest?.('a[href]')
  if (!anchor || !chatBodyRef.value?.contains(anchor)) return
  const href = anchor.getAttribute('href') || ''
  const productMatch = href.match(/\/product\/(\d+)/i)
  if (productMatch) {
    e.preventDefault()
    e.stopPropagation()
    goToProduct(productMatch[1])
    return
  }
  if (href.startsWith('/') && !href.startsWith('//')) {
    e.preventDefault()
    e.stopPropagation()
    router.push(href).catch(() => {})
  }
}

const goHome = () => {
  router.push('/').finally(() => closeChat())
}

const goToOrders = () => {
  if (authStore.isLoggedIn) {
    router.push('/profile').finally(() => closeChat())
  } else {
    currentView.value = 'chat'
    nextTick(() => {
      chatMessages.value.push({
        key: nextMessageKey(),
        sender: 'bot',
        text: 'Quý khách cần **đăng nhập** để xem đơn hàng. [Đăng nhập tại đây](/login)'
      })
      scrollToBottomIfNear(true)
    })
  }
}

const goToChat = (suggestion = null) => {
  currentView.value = 'chat'
  if (suggestion) {
    nextTick(() => sendMessage(suggestion))
  } else {
    nextTick(() => scrollToBottomIfNear(true))
  }
}

const askAboutCurrentProduct = () => {
  goToChat(`Cho tôi biết thêm về sản phẩm này (ID ${route.params.id})`)
}

const buildChatContext = () => {
  const ctx = { route: route.path }
  if (route.name === 'product-detail' && route.params.id) {
    ctx.productId = route.params.id
  }
  if (lastSuggestedProductIds.value.length > 0) {
    ctx.lastProductIds = lastSuggestedProductIds.value.slice(0, 5)
  }
  return ctx
}

const trimHistoryForApi = () => {
  return chatMessages.value
    .slice(-16)
    .map((m) => ({ sender: m.sender, text: m.text }))
}

const retryLastMessage = () => {
  if (!lastFailedUserText.value || isBotTyping.value) return
  sendMessage(lastFailedUserText.value, { isRetry: true })
}

const sendMessage = async (presetText = null, options = {}) => {
  const { isRetry = false } = options
  const text = (presetText && typeof presetText === 'string') ? presetText : null
  const userText = (text ?? userInput.value).trim()
  if (!userText || isBotTyping.value) return
  if (userText.length > MAX_MESSAGE_LENGTH) return

  if (!isRetry) {
    chatMessages.value.push({ key: nextMessageKey(), sender: 'user', text: userText })
    userInput.value = ''
    lastFailedUserText.value = userText
    scrollToBottomIfNear(true)
  }

  isBotTyping.value = true
  scrollToBottomIfNear(true)

  try {
    const data = await sendChatMessage(userText, trimHistoryForApi(), buildChatContext())
    isBotTyping.value = false

    if (data.success) {
      lastFailedUserText.value = ''
      const products = Array.isArray(data.products) ? data.products.slice(0, 5) : []
      mergeSuggestedProductIds(products, data.reply || '')
      chatMessages.value.push({
        key: nextMessageKey(),
        sender: 'bot',
        text: data.reply,
        products,
        engine: data.engine === 'rule_based' ? 'rule_based' : 'groq',
      })
    } else {
      const errText = data.message || 'Không thể kết nối AI'
      chatMessages.value.push({
        key: nextMessageKey(),
        sender: 'bot',
        text: errText.includes('quá nhiều')
          ? '**' + errText + '**'
          : 'Xin lỗi Quý khách, ' + errText + '. Quý khách vui lòng gọi **0978.897.579**.',
        retryable: true,
      })
    }
    scrollToBottomIfNear()
  } catch {
    isBotTyping.value = false
    chatMessages.value.push({
      key: nextMessageKey(),
      sender: 'bot',
      text: 'Xin lỗi Quý khách, lỗi kết nối. Vui lòng thử lại hoặc gọi hotline **0978.897.579**.',
      retryable: true,
    })
    scrollToBottomIfNear()
  }
}
</script>

<style scoped>
/* ===================== WRAPPER ===================== */
.chatbot-wrapper {
  position: fixed;
  bottom: 40px;
  right: 30px;
  z-index: 9999;
  display: flex;
  flex-direction: column;
  align-items: flex-end;
}

/* Toggle button */
.chat-toggle-btn {
  width: 60px !important;
  height: 60px !important;
  background: linear-gradient(135deg, #D8B257, #b5954a) !important;
  color: #111 !important;
  border: none !important;
  box-shadow: 0 4px 20px rgba(216, 178, 87, 0.45) !important;
  transition: transform 0.3s cubic-bezier(0.175, 0.885, 0.32, 1.275) !important;
}
.chat-toggle-btn:hover { transform: scale(1.1); }

/* ===================== CHAT WINDOW BASE ===================== */
.chat-window {
  width: 440px;
  height: 680px;
  border-radius: 20px;
  box-shadow: 0 20px 60px rgba(0,0,0,0.25);
  margin-bottom: 16px;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  background: #f5f5f5;
}

/* ===================== WELCOME VIEW ===================== */
.welcome-view {
  display: flex;
  flex-direction: column;
  height: 100%;
}

/* Header */
.welcome-header {
  background: linear-gradient(145deg, #1a1107, #3a2a08, #D8B257);
  padding: 28px 22px 24px;
  position: relative;
  flex-shrink: 0;
}
.wh-close-btn {
  position: absolute;
  top: 14px;
  right: 16px;
  background: rgba(255,255,255,0.15);
  border: none;
  color: #fff;
  width: 28px;
  height: 28px;
  border-radius: 50%;
  cursor: pointer;
  font-size: 14px;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: background 0.2s;
}
.wh-close-btn:hover { background: rgba(255,255,255,0.3); }
.wh-title {
  color: #fff;
  font-size: 24px;
  font-weight: 700;
  margin-bottom: 6px;
}
.wh-subtitle {
  color: rgba(255,255,255,0.8);
  font-size: 14px;
}

/* Body */
.welcome-body {
  flex: 1;
  overflow-y: auto;
  padding: 16px 16px 12px;
  margin-top: 0;
}

/* Store card */
.store-card {
  background: #fff;
  border-radius: 14px;
  padding: 16px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  box-shadow: 0 4px 16px rgba(0,0,0,0.08);
  margin-bottom: 14px;
}
.store-card-left { display: flex; align-items: center; gap: 12px; flex: 1; min-width: 0; }
.store-avatar-wrap { position: relative; flex-shrink: 0; }
.store-avatar { background-color: #D8B257; }
.online-badge {
  position: absolute;
  bottom: 2px; right: 2px;
  width: 11px; height: 11px;
  background: #22c55e;
  border-radius: 50%;
  border: 2px solid #fff;
  box-shadow: 0 0 6px #22c55e;
}
.store-info { min-width: 0; flex: 1; }
.store-name { font-weight: 700; font-size: 14px; color: #111; margin-bottom: 4px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.store-greeting { font-size: 13px; color: #555; line-height: 1.5; }
.notif-badge {
  background: #ef4444;
  color: #fff;
  width: 22px; height: 22px;
  border-radius: 50%;
  display: flex; align-items: center; justify-content: center;
  font-size: 11px; font-weight: 700;
  flex-shrink: 0;
  margin-top: 2px;
}

/* CTA button */
.cta-btn {
  width: 100%;
  background: linear-gradient(135deg, #D8B257, #b5954a);
  color: #fff;
  border: none;
  border-radius: 12px;
  padding: 14px;
  font-size: 15px;
  font-weight: 600;
  cursor: pointer;
  margin-bottom: 20px;
  letter-spacing: 0.3px;
  box-shadow: 0 4px 14px rgba(216,178,87,0.4);
  transition: transform 0.2s, box-shadow 0.2s;
}
.cta-btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 6px 20px rgba(216,178,87,0.5);
}
.cta-btn-secondary {
  margin-top: 10px;
  background: #fff;
  color: #333;
  border: 1px solid #D8B257;
  box-shadow: none;
}
.cta-btn-secondary:hover {
  background: #fffbf0;
  box-shadow: 0 4px 12px rgba(216,178,87,0.25);
}

/* Quick suggestions */
.quick-label {
  font-size: 12px;
  font-weight: 600;
  color: #999;
  text-transform: uppercase;
  letter-spacing: 0.6px;
  margin-bottom: 8px;
}
.quick-list { display: flex; flex-direction: column; gap: 8px; }
.quick-item {
  background: #fff;
  border: 1px solid #eee;
  border-radius: 12px;
  padding: 14px 16px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  cursor: pointer;
  font-size: 14px;
  color: #333;
  text-align: left;
  box-shadow: 0 2px 6px rgba(0,0,0,0.04);
  transition: border-color 0.2s, transform 0.15s;
}
.quick-item:hover {
  border-color: #D8B257;
  transform: translateX(4px);
}
.quick-arrow {
  color: #D8B257;
  font-size: 16px;
  font-weight: 700;
  flex-shrink: 0;
}

/* Footer nav */
.welcome-footer {
  background: #fff;
  border-top: 1px solid #eee;
  flex-shrink: 0;
  display: flex;
  flex-direction: column;
}
.wnav-row {
  display: flex;
  flex-direction: row;
  justify-content: space-around;
  align-items: center;
  padding: 8px 4px 4px;
}
.wnav-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 2px;
  background: none;
  border: none;
  cursor: pointer;
  padding: 4px 8px;
  border-radius: 8px;
  font-size: 11px;
  color: #888;
  transition: color 0.2s;
  flex: 1;
}
.wnav-item:hover, .wnav-item.active { color: #D8B257; }
.wnav-icon { font-size: 20px; }
.wnav-powered {
  text-align: center;
  font-size: 10px;
  color: #bbb;
  padding: 2px 0 8px;
}
.wnav-powered strong { color: #D8B257; }

/* ===================== CHAT VIEW ===================== */
.chat-view {
  display: flex;
  flex-direction: column;
  height: 100%;
  background: rgba(255,255,255,0.85);
  backdrop-filter: blur(12px);
}

.chat-header {
  background: rgba(17, 17, 17, 0.95);
  padding: 12px 16px;
  display: flex;
  align-items: center;
  gap: 10px;
  border-bottom: 1px solid rgba(255,255,255,0.08);
  flex-shrink: 0;
}
.back-btn {
  background: rgba(255,255,255,0.1);
  border: none;
  color: #fff;
  width: 32px; height: 32px;
  border-radius: 50%;
  cursor: pointer;
  font-size: 16px;
  display: flex; align-items: center; justify-content: center;
  transition: background 0.2s;
  flex-shrink: 0;
}
.back-btn:hover { background: rgba(255,255,255,0.2); }
.bot-info { display: flex; align-items: center; gap: 10px; flex: 1; }
.bot-avatar { background-color: #D8B257; }
.bot-text { display: flex; flex-direction: column; }
.bot-text strong { color: #D8B257; font-size: 14px; font-weight: 600; }
.bot-text span { color: rgba(255,255,255,0.6); font-size: 11px; display: flex; align-items: center; gap: 5px; margin-top: 2px; }
.online-dot { width: 7px; height: 7px; background: #22c55e; border-radius: 50%; box-shadow: 0 0 6px #22c55e; display: inline-block; }
.close-chat-btn { color: #aaa !important; }
.close-chat-btn:hover { color: #fff !important; background: transparent !important; transform: rotate(90deg); }
.reset-chat-btn { color: #aaa !important; margin-left: auto; }
.reset-chat-btn:hover { color: #D8B257 !important; background: transparent !important; }

.chat-body {
  flex: 1;
  padding: 18px;
  overflow-y: auto;
  display: flex;
  flex-direction: column;
  gap: 14px;
  background: transparent;
}
.chat-body::-webkit-scrollbar { width: 4px; }
.chat-body::-webkit-scrollbar-thumb { background: rgba(0,0,0,0.15); border-radius: 4px; }

.message-wrapper { display: flex; width: 100%; }
.message-wrapper.is-bot { justify-content: flex-start; }
.message-wrapper.is-user { justify-content: flex-end; }

.message-bubble {
  max-width: 85%;
  padding: 11px 15px;
  border-radius: 16px;
  font-size: 14px;
  line-height: 1.55;
  word-wrap: break-word;
  box-shadow: 0 2px 8px rgba(0,0,0,0.06);
}
.is-bot .message-bubble { background: #fff; color: #333; border-bottom-left-radius: 4px; }
.is-user .message-bubble {
  background: linear-gradient(135deg, #D8B257, #b5954a);
  color: #fff;
  border-bottom-right-radius: 4px;
  font-weight: 500;
}

.chat-footer {
  padding: 14px;
  background: rgba(255,255,255,0.7);
  border-top: 1px solid rgba(0,0,0,0.05);
  flex-shrink: 0;
}
:deep(.chat-input .el-input__wrapper) { border-radius: 20px 0 0 20px; box-shadow: 0 0 0 1px rgba(0,0,0,0.1) inset; background: #fff; }
:deep(.chat-input .el-input__wrapper.is-focus) { box-shadow: 0 0 0 1px #D8B257 inset; }
:deep(.chat-input .el-input-group__append) { background: #D8B257; border-radius: 0 20px 20px 0; border: none; box-shadow: none; padding: 0 18px; }
:deep(.send-btn) { color: #fff !important; font-size: 18px; }
:deep(.send-btn:hover) { transform: scale(1.1); }

/* Typing */
.typing-indicator { display: flex; gap: 5px; padding: 13px 16px !important; align-items: center; }
.typing-indicator span { width: 6px; height: 6px; background: #bbb; border-radius: 50%; animation: typing 1.4s infinite ease-in-out both; }
.typing-indicator span:nth-child(1) { animation-delay: -0.32s; }
.typing-indicator span:nth-child(2) { animation-delay: -0.16s; }
@keyframes typing { 0%,80%,100% { transform: scale(0); } 40% { transform: scale(1); opacity: 1; } }

/* Markdown table */
:deep(.message-bubble table) { border-radius: 8px; overflow: hidden; border-collapse: collapse; width: 100%; margin: 8px 0; }
:deep(.message-bubble th), :deep(.message-bubble td) { border: 1px solid #eee; padding: 7px 10px; text-align: left; font-size: 13px; }
:deep(.message-bubble th) { background: #f5f7fa; color: #333; font-weight: 600; }
:deep(.message-bubble p) { margin: 0 0 6px; }
:deep(.message-bubble p:last-child) { margin-bottom: 0; }
:deep(.message-bubble ul), :deep(.message-bubble ol) { padding-left: 18px; margin: 4px 0; }
:deep(.message-bubble li) { margin-bottom: 3px; }
:deep(.message-bubble a) { color: #b5954a; font-weight: 600; }

.bot-message-block { max-width: 92%; display: flex; flex-direction: column; gap: 8px; }

.product-cards { display: flex; flex-direction: column; gap: 8px; }
.product-card {
  display: flex;
  gap: 10px;
  background: #fff;
  border: 1px solid #eee;
  border-radius: 12px;
  padding: 10px;
  text-decoration: none;
  color: inherit;
  cursor: pointer;
  transition: border-color 0.2s, box-shadow 0.2s;
}
.product-card:hover {
  border-color: #D8B257;
  box-shadow: 0 4px 12px rgba(216, 178, 87, 0.25);
}
.product-card-img {
  width: 56px;
  height: 56px;
  object-fit: cover;
  border-radius: 8px;
  flex-shrink: 0;
}
.product-card-body { flex: 1; min-width: 0; }
.product-card-name {
  font-size: 13px;
  font-weight: 600;
  color: #111;
  line-height: 1.35;
  display: -webkit-box;
  line-clamp: 2;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
.product-card-meta { font-size: 12px; color: #666; margin-top: 4px; }
.product-card-prices {
  display: flex;
  flex-wrap: wrap;
  align-items: baseline;
  gap: 6px;
  margin-top: 6px;
}
.product-old-price {
  font-size: 12px;
  color: #999;
  text-decoration: line-through;
}
.product-sale-price {
  font-size: 14px;
  font-weight: 700;
  color: #d93025;
}
.product-hot-tag {
  display: inline-block;
  margin-left: 6px;
  padding: 1px 6px;
  font-size: 10px;
  font-weight: 700;
  color: #fff;
  background: #d93025;
  border-radius: 3px;
  vertical-align: middle;
}
.product-card-cta { font-size: 12px; color: #D8B257; font-weight: 600; margin-top: 6px; display: inline-block; }
.stock-ok { color: #67C23A; font-weight: 500; }
.stock-out { color: #F56C6C; font-weight: 500; }

.engine-badge {
  font-size: 11px;
  color: #888;
  background: #f5f5f5;
  border-radius: 8px;
  padding: 4px 10px;
  display: inline-block;
  align-self: flex-start;
}

.retry-btn {
  align-self: flex-start;
  margin-top: 4px;
  padding: 6px 14px;
  font-size: 12px;
  font-weight: 600;
  color: #b5954a;
  background: #fff;
  border: 1px solid #D8B257;
  border-radius: 16px;
  cursor: pointer;
  transition: background 0.2s;
}
.retry-btn:hover { background: #fffbf0; }

.follow-up-chips {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  margin-top: 4px;
}
.follow-up-chip {
  padding: 8px 14px;
  font-size: 12px;
  color: #333;
  background: #fff;
  border: 1px solid #e8e8e8;
  border-radius: 20px;
  cursor: pointer;
  transition: border-color 0.2s, background 0.2s;
}
.follow-up-chip:hover {
  border-color: #D8B257;
  background: #fffbf0;
}

/* ===================== CONTACT VIEW ===================== */
.contact-view {
  display: flex;
  flex-direction: column;
  height: 100%;
  background: #f5f5f5;
}
.contact-header {
  background: linear-gradient(145deg, #1a1107, #3a2a08, #D8B257);
  padding: 28px 22px 24px;
  flex-shrink: 0;
  position: relative;
}
.contact-header-title { color: #fff; font-size: 20px; font-weight: 700; margin-bottom: 6px; }
.contact-header-sub   { color: rgba(255,255,255,0.75); font-size: 13px; }

.contact-body {
  flex: 1;
  overflow-y: auto;
  padding: 16px;
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.contact-card {
  display: flex;
  align-items: center;
  gap: 14px;
  background: #fff;
  border-radius: 14px;
  padding: 16px;
  text-decoration: none;
  color: inherit;
  box-shadow: 0 2px 10px rgba(0,0,0,0.06);
  transition: transform 0.15s, box-shadow 0.15s;
  border: 1px solid transparent;
}
.contact-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 6px 18px rgba(0,0,0,0.1);
  border-color: #D8B257;
}

.contact-icon {
  width: 48px; height: 48px;
  border-radius: 14px;
  display: flex; align-items: center; justify-content: center;
  font-size: 22px;
  flex-shrink: 0;
}
.contact-icon.phone    { background: #fff3cd; }
.contact-icon.messenger{ background: #e8f4ff; }

.contact-info { flex: 1; min-width: 0; }
.contact-label { font-size: 11px; color: #999; text-transform: uppercase; letter-spacing: 0.5px; margin-bottom: 3px; }
.contact-value { font-size: 15px; font-weight: 700; color: #111; margin-bottom: 2px; }
.contact-sub   { font-size: 12px; color: #888; }

.contact-arrow { color: #D8B257; font-size: 20px; font-weight: 700; flex-shrink: 0; }

.contact-note {
  background: #fff;
  border-radius: 12px;
  padding: 14px 16px;
  font-size: 13px;
  color: #555;
  box-shadow: 0 2px 8px rgba(0,0,0,0.04);
}

/* ===================== TEASER BUBBLE ===================== */
.chat-teaser {
  display: flex;
  align-items: center;
  gap: 10px;
  background: #fff;
  border-radius: 16px;
  padding: 12px 14px;
  margin-bottom: 10px;
  box-shadow: 0 8px 30px rgba(0,0,0,0.15);
  cursor: pointer;
  max-width: 260px;
  border: 1px solid rgba(216,178,87,0.3);
  transition: box-shadow 0.2s, transform 0.2s;
  position: relative;
}
.chat-teaser:hover {
  transform: translateY(-2px);
  box-shadow: 0 12px 36px rgba(0,0,0,0.18);
}

.teaser-avatar {
  position: relative;
  flex-shrink: 0;
}
.teaser-dot {
  position: absolute;
  bottom: 0; right: 0;
  width: 10px; height: 10px;
  background: #22c55e;
  border-radius: 50%;
  border: 2px solid #fff;
  box-shadow: 0 0 5px #22c55e;
}

.teaser-body { flex: 1; min-width: 0; }
.teaser-name {
  font-size: 13px;
  font-weight: 700;
  color: #111;
  margin-bottom: 3px;
}
.teaser-msg {
  font-size: 13px;
  color: #555;
  line-height: 1.4;
  white-space: normal;
}

.teaser-close {
  background: none;
  border: none;
  font-size: 18px;
  color: #aaa;
  cursor: pointer;
  padding: 2px 4px;
  line-height: 1;
  flex-shrink: 0;
  transition: color 0.15s;
}
.teaser-close:hover { color: #333; }

/* Transition animation (slide up + fade) */
.teaser-enter-from { opacity: 0; transform: translateY(12px); }
.teaser-enter-active { transition: all 0.35s cubic-bezier(0.175, 0.885, 0.32, 1.275); }
.teaser-leave-active { transition: all 0.2s ease; }
.teaser-leave-to { opacity: 0; transform: translateY(8px); }

/* Responsive for mobile */
@media (max-width: 768px) {
  .chatbot-wrapper {
    bottom: 20px;
    right: 20px;
  }
  .chatbot-wrapper.is-open {
    bottom: 0 !important;
    right: 0 !important;
    left: 0 !important;
    top: 0 !important;
    width: 100% !important;
    height: 100% !important;
    height: 100dvh !important;
    margin: 0 !important;
  }
  .chatbot-wrapper.is-open .chat-window {
    width: 100% !important;
    height: 100% !important;
    border-radius: 0 !important;
    margin-bottom: 0 !important;
  }
  .chatbot-wrapper.is-open .chat-toggle-btn {
    display: flex !important;
    width: 44px !important;
    height: 44px !important;
    position: fixed !important;
    bottom: 20px !important;
    right: 20px !important;
    z-index: 10001 !important;
    box-shadow: 0 4px 16px rgba(0,0,0,0.2) !important;
  }
  .chatbot-wrapper.is-open .chat-toggle-btn.is-mini-fab :deep(.el-icon) {
    font-size: 22px !important;
  }
  .chat-teaser {
    max-width: 230px !important;
    padding: 8px 12px !important;
    right: 0;
  }
  .teaser-msg {
    font-size: 11.5px !important;
  }
  .teaser-avatar {
    display: none; /* Hide avatar on mobile teaser to save space */
  }
}
</style>
