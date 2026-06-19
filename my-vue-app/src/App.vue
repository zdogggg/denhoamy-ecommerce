<template>
  <router-view />

  <template v-if="showFloating">
    <div class="floating-social">
      <a href="tel:0978897579" class="social-btn phone-btn">
        <el-icon><PhoneFilled /></el-icon>
      </a>
      <a href="https://zalo.me/0978897579" target="_blank" class="social-btn zalo-btn">
        <img src="https://upload.wikimedia.org/wikipedia/commons/9/91/Icon_of_Zalo.svg" alt="Zalo" />
      </a>
      <a href="https://m.me/denhoamy" target="_blank" class="social-btn mess-btn">
        <img src="https://upload.wikimedia.org/wikipedia/commons/b/be/Facebook_Messenger_logo_2020.svg" alt="Messenger" />
      </a>
    </div>

    <ChatWidget v-if="showFloating" />
  </template>
</template>

<script setup>
import { ref, onMounted, onUnmounted, computed } from 'vue' // Đã thêm computed
import { useRoute } from 'vue-router' // Đã thêm useRoute để bắt đường dẫn
import { PhoneFilled } from '@element-plus/icons-vue'
import { useSettingsStore } from './stores/settings'
import { useCartStore } from './stores/cart'
import { useAuthStore } from './stores/auth'
import { AUTH_BROADCAST_KEY } from './utils/authStorage'
import { toastInfo } from './utils/toast'
import ChatWidget from './components/ChatWidget.vue'

const route = useRoute()
const settingsStore = useSettingsStore()
const cartStore = useCartStore()
const authStore = useAuthStore()

onMounted(async () => {
  settingsStore.fetchSettings()

  if (authStore.user?.role === 'customer') {
    await cartStore.hydrateFromServer()
  }

  if (cartStore.items.length > 0) {
    const { updated } = await cartStore.syncPricesFromServer()
    if (updated && route.path !== '/reset-password') {
      toastInfo('Giá trong giỏ đã được cập nhật theo ưu đãi mới.')
    }
  }

  window.addEventListener('storage', handleStorageAuth)
})

onUnmounted(() => {
  window.removeEventListener('storage', handleStorageAuth)
})

const handleStorageAuth = (event) => {
  if (event.key !== AUTH_BROADCAST_KEY || !event.newValue) return
  try {
    const { type } = JSON.parse(event.newValue)
    authStore.handleStorageAuthEvent(type)
  } catch {
    // ignore malformed broadcast payload
  }
}

// --- LOGIC ẨN/HIỆN THEO TRANG ---
const hiddenRoutes = ['/login', '/register', '/forgot-password', '/reset-password', '/checkout']

const showFloating = computed(() => {
  if (route.name === 'not-found') return false
  if (route.path.startsWith('/admin')) return false
  return !hiddenRoutes.includes(route.path)
})

// Logics for Chatbot has been moved to components/ChatWidget.vue
</script>

<style>
/* --- 1. CSS Reset & Cấu hình cơ bản --- */
body { 
  margin: 0; 
}

/* --- 2. Cấu hình cụm nút mạng xã hội (Floating Buttons) --- */
.floating-social { 
  position: fixed; 
  bottom: 40px; 
  left: 30px; 
  display: flex; 
  flex-direction: column; 
  gap: 15px; 
  z-index: 9999; 
}

/* Định dạng chung cho các nút tròn (Phone, Zalo, Messenger) */
.social-btn { 
  width: 50px; 
  height: 50px; 
  border-radius: 50%; 
  display: flex; 
  justify-content: center; 
  align-items: center; 
  box-shadow: 0 4px 12px rgba(0,0,0,0.15); 
  transition: transform 0.3s; 
  text-decoration: none; 
  color: white; 
  font-size: 24px; 
}

/* Hiệu ứng phóng to khi di chuột vào nút */
.social-btn:hover { 
  transform: scale(1.15) translateY(-5px); 
}

/* --- 3. Màu sắc riêng cho từng nút --- */
.phone-btn { 
  background-color: #ff9800; /* Màu cam cho hotline */
}

.zalo-btn { 
  background-color: #fff; 
  padding: 0; 
  overflow: hidden; 
}
.zalo-btn img { 
  width: 100%; 
  height: 100%; 
  object-fit: cover; 
}

.mess-btn { 
  background-color: #fff; 
  padding: 0; 
  overflow: hidden; 
}
.mess-btn img { 
  width: 105%; 
  height: 105%; 
}

/* --- 4. Mobile Responsive --- */
@media (max-width: 768px) {
  .floating-social {
    left: 16px;
    bottom: 100px;
    gap: 10px;
  }
  .social-btn {
    width: 42px;
    height: 42px;
    font-size: 18px;
  }
}

</style>