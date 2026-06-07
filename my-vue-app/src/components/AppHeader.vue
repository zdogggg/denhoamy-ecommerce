<template>
  <!-- Desktop Top Bar -->
  <div class="top-bar desktop-only">
    <div class="container top-bar-inner">
      <div class="top-left">
        <span>Hệ thống Showroom Hải Phòng &amp; Toàn Quốc</span>
      </div>
      <div class="top-right">
        <span class="contact-info"><el-icon><Phone /></el-icon> Hotline: {{ settingsStore.sys_hotline }}</span>
        <span class="contact-info"><el-icon><Message /></el-icon> {{ settingsStore.sys_email }}</span>
        <el-divider direction="vertical" />
        <template v-if="authStore.isLoggedIn">
          <span class="welcome-text">Xin chào, {{ authStore.user.name }}</span>
          <el-link :underline="false" class="auth-link" v-if="authStore.canAccessAdmin" @click="$router.push('/admin')">Quản trị</el-link>
          <el-link :underline="false" class="auth-link" v-else @click="$router.push('/profile')">Tài khoản của tôi</el-link>
          <el-link :underline="false" class="auth-link" @click="handleLogout">Đăng xuất</el-link>
        </template>
        <template v-else>
          <el-link :underline="false" class="auth-link" @click="$router.push('/login')">Đăng nhập</el-link>
          <el-link :underline="false" class="auth-link" @click="$router.push('/register')">Đăng ký</el-link>
        </template>
      </div>
    </div>
  </div>

  <!-- Desktop Header -->
  <header class="main-header desktop-only">
    <div class="container header-inner">
      <div class="logo" @click="$router.push('/')" style="cursor:pointer; display: flex; align-items: center;">
        <img v-if="settingsStore.sys_logo_url" :src="settingsStore.sys_logo_url" style="height: 50px; border-radius: 4px;" />
        <div v-else>
          <h1>{{ settingsStore.sys_shop_name }}</h1>
          <p>Thế Giới Đèn Nghệ Thuật</p>
        </div>
      </div>

      <div class="search-box">
        <el-input v-model="searchQuery" placeholder="Từ khóa tìm kiếm..." class="search-input" clearable @keyup.enter="handleSearch">
          <template #append><el-button :icon="Search" class="search-btn" @click="handleSearch" /></template>
        </el-input>
      </div>

      <div class="cart-box" @click="$router.push('/cart')">
        <el-badge :value="cartStore.itemCount" class="cart-badge">
          <el-icon :size="28" color="#D8B257"><ShoppingCart /></el-icon>
        </el-badge>
        <div class="cart-text">
          <span>Giỏ hàng</span>
          <strong>{{ cartStore.itemCount }} SP</strong>
        </div>
      </div>
    </div>
  </header>

  <!-- Mobile Header Bar -->
  <header class="mobile-header mobile-only">
    <div class="mobile-header-inner">
      <!-- Logo -->
      <div class="mobile-logo" @click="$router.push('/')">
        <img v-if="settingsStore.sys_logo_url" :src="settingsStore.sys_logo_url" alt="Logo" class="mobile-logo-img" />
        <span v-else class="mobile-logo-text">{{ settingsStore.sys_shop_name }}</span>
      </div>
      
      <!-- Search Input Container -->
      <div class="mobile-search-box">
        <input 
          v-model="searchQuery" 
          placeholder="Từ khóa tìm kiếm..." 
          class="mobile-search-input"
          @keyup.enter="handleSearch" 
        />
        <button class="mobile-search-btn" @click="handleSearch">
          <el-icon><Search /></el-icon>
        </button>
      </div>
      
      <!-- Cart Icon with Badge -->
      <div class="mobile-cart-btn" @click="$router.push('/cart')">
        <el-badge :value="cartStore.itemCount" class="mobile-cart-badge" :max="99">
          <el-icon :size="22" color="#D8B257"><ShoppingCart /></el-icon>
        </el-badge>
      </div>
      
      <!-- Hamburger Menu Button -->
      <div class="mobile-menu-btn" @click="isDrawerOpen = true">
        <div class="hamburger-lines">
          <span></span>
          <span></span>
          <span></span>
        </div>
        <span class="menu-btn-text">MENU</span>
      </div>
    </div>
  </header>

  <!-- Mobile Drawer Menu Overlay -->
  <transition name="slide-fade">
    <div class="mobile-drawer-overlay" v-if="isDrawerOpen" @click.self="isDrawerOpen = false">
      <div class="mobile-drawer-content">
        <!-- Close button / Header inside drawer -->
        <div class="drawer-header">
          <div class="drawer-logo" @click="navigateDrawer('/')">
            <img v-if="settingsStore.sys_logo_url" :src="settingsStore.sys_logo_url" alt="Logo" />
            <h2 v-else>{{ settingsStore.sys_shop_name }}</h2>
          </div>
          <button class="drawer-close-btn" @click="isDrawerOpen = false">&times;</button>
        </div>
        
        <!-- Drawer options list -->
        <div class="drawer-body">
          <div class="drawer-menu-item main-link" @click="navigateDrawer('/')">
            TRANG CHỦ
          </div>
          
          <div class="drawer-section-title">DANH MỤC SẢN PHẨM</div>
          <div class="drawer-submenu-list">
            <div v-for="cat in categoriesStore" :key="cat.id" class="drawer-cat-group">
              <div class="drawer-cat-header" @click="toggleCatCollapse(cat.name)">
                <span>{{ cat.name }}</span>
                <el-icon :class="{ 'is-active': activeCats.includes(cat.name) }">
                  <ArrowDown />
                </el-icon>
              </div>
              <div v-show="activeCats.includes(cat.name)" class="drawer-child-list">
                <div 
                  class="drawer-child-item" 
                  @click="navigateDrawer({ path: '/category', query: { type: cat.name } })"
                >
                  Xem tất cả {{ cat.name }}
                </div>
                <div 
                  v-for="child in cat.children" 
                  :key="child.id" 
                  class="drawer-child-item"
                  @click="navigateDrawer({ path: '/category', query: { type: cat.name, sub: child.name } })"
                >
                  - {{ child.name }}
                </div>
              </div>
            </div>
          </div>
          
          <div class="drawer-section-title">TIN TỨC &amp; QUẢN TRỊ</div>
          <div class="drawer-menu-item" @click="navigateDrawer('/news')">
            TIN TỨC - BÀI VIẾT
          </div>
          
          <div class="drawer-section-title">TÀI KHOẢN</div>
          <template v-if="authStore.isLoggedIn">
            <div class="drawer-user-info">
              Tài khoản: <strong style="color: #D8B257;">{{ authStore.user.name }}</strong>
            </div>
            <div class="drawer-menu-item" v-if="authStore.canAccessAdmin" @click="navigateDrawer('/admin')">
              Trang Quản trị
            </div>
            <div class="drawer-menu-item" v-else @click="navigateDrawer('/profile')">
              Tài khoản của tôi
            </div>
            <div class="drawer-menu-item logout-link" @click="handleLogoutDrawer">
              Đăng xuất
            </div>
          </template>
          <template v-else>
            <div class="drawer-menu-item" @click="navigateDrawer('/login')">
              Đăng nhập
            </div>
            <div class="drawer-menu-item" @click="navigateDrawer('/register')">
              Đăng ký
            </div>
          </template>
          
          <div class="drawer-section-title">LIÊN HỆ HOTLINE</div>
          <div class="drawer-hotline-item" @click="callHotline">
            <el-icon :size="18"><Phone /></el-icon>
            <span class="hotline-numbers">0978897579 - 02256533618</span>
          </div>
        </div>
      </div>
    </div>
  </transition>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { Phone, Message, Search, ShoppingCart, ArrowDown, ArrowUp } from '@element-plus/icons-vue'
import { useCartStore } from '../stores/cart'
import { useAuthStore } from '../stores/auth'
import { useSettingsStore } from '../stores/settings'
import { getCategories } from '../services/categoryService'

const router = useRouter()
const cartStore = useCartStore()
const authStore = useAuthStore()
const settingsStore = useSettingsStore()

const searchQuery = ref('')
const isDrawerOpen = ref(false)
const activeCats = ref([])
const categoriesStore = ref([])

onMounted(async () => {
  const res = await getCategories()
  if (res && res.success) {
    categoriesStore.value = res.data
  }
})

const toggleCatCollapse = (catName) => {
  const idx = activeCats.value.indexOf(catName)
  if (idx >= 0) {
    activeCats.value.splice(idx, 1)
  } else {
    activeCats.value.push(catName)
  }
}

const navigateDrawer = (target) => {
  isDrawerOpen.value = false
  if (typeof target === 'string') {
    router.push(target)
  } else {
    router.push(target)
  }
}

const callHotline = () => {
  window.open('tel:0978897579', '_self')
}

const handleSearch = () => {
  if (searchQuery.value.trim()) {
    isDrawerOpen.value = false
    router.push({ path: '/category', query: { search: searchQuery.value.trim() } })
  }
}

const handleLogout = () => {
  authStore.logout()
  router.push('/')
}

const handleLogoutDrawer = () => {
  isDrawerOpen.value = false
  handleLogout()
}
</script>

<style scoped>
/* --- 1. Thanh Top Bar (Phía trên cùng) --- */
.top-bar { 
  background-color: #111; 
  color: #ccc; 
  font-size: 12px; 
  height: 36px;
  position: relative;
  z-index: 1001; /* Tạo lớp xếp chồng đè trên banner quảng cáo */
}

/* Khung căn giữa nội dung 1200px */
.container { 
  width: 1200px; 
  margin: 0 auto; 
  max-width: 100%; 
  padding: 0 20px; 
  box-sizing: border-box; 
}

.top-bar .container {
  height: 100%;
}

.top-bar-inner { 
  display: flex; 
  justify-content: space-between; 
  align-items: center; 
  width: 100%; 
  height: 100%;
}

.contact-info { 
  display: flex; 
  align-items: center; 
  gap: 5px; 
  margin-right: 15px; 
}

.top-right { 
  display: flex; 
  align-items: center; 
}

/* Link đăng nhập/đăng ký (Màu vàng đồng) */
.auth-link { 
  color: #D8B257; 
  font-size: 12px; 
  margin: 0 8px; 
}
.auth-link:hover { color: #fff; }

.welcome-text { 
  color: #D8B257; 
  font-size: 12px; 
  margin-right: 10px; 
}

/* --- 2. Header chính (Logo, Tìm kiếm, Giỏ hàng) --- */
.main-header { 
  background-color: #000; 
  padding: 20px 0; 
  color: #D8B257;
  position: relative;
  z-index: 1001; /* Đảm bảo đè trên banner quảng cáo sườn */
}

.header-inner { 
  display: flex; 
  justify-content: space-between; 
  align-items: center; 
}

/* Định dạng Logo */
.logo h1 { 
  margin: 0; 
  font-size: 32px; 
  letter-spacing: 2px; 
  color: #D8B257; 
  font-family: 'Montserrat', sans-serif; 
}
.logo p { 
  margin: 5px 0 0; 
  font-size: 12px; 
  letter-spacing: 1px; 
  color: #fff; 
}

/* Khu vực tìm kiếm (Search Box) */
.search-box { 
  width: 500px; 
}

/* Tùy chỉnh input search của Element Plus */
:deep(.search-input .el-input__wrapper) { 
  border-radius: 20px 0 0 20px !important; 
  padding-left: 20px; 
  box-shadow: none !important; 
  height: 40px; 
}
:deep(.search-input .el-input__inner) { 
  height: 40px; 
  line-height: normal; 
  padding-top: 2px;
}
:deep(.search-input .el-input-group__append) { 
  background-color: #D8B257 !important; 
  border-top-right-radius: 20px !important; 
  border-bottom-right-radius: 20px !important; 
  border: none !important; 
  box-shadow: none !important; 
  padding: 0 !important; 
  overflow: hidden;
}
:deep(.search-btn) { 
  background: transparent !important; 
  border: none !important; 
  color: #111 !important; 
  font-size: 18px; 
  height: 40px; 
  width: 50px;
  margin: 0; 
  display: flex;
  align-items: center;
  justify-content: center;
}
:deep(.search-btn:hover) { color: #fff !important; }

/* Khu vực giỏ hàng */
.cart-box { 
  display: flex; 
  align-items: center; 
  gap: 15px; 
  cursor: pointer; 
}
.cart-text { 
  display: flex; 
  flex-direction: column; 
  color: #fff; 
  font-size: 13px; 
}
.cart-text strong { 
  color: #D8B257; 
  font-size: 15px; 
}

/* --- 3. Responsive Hide / Show display utilities --- */
.desktop-only {
  display: block;
}
.mobile-only {
  display: none;
}

/* --- 4. Mobile Header Bar styling --- */
.mobile-header {
  background-color: #000;
  padding: 10px 15px;
  height: 60px;
  box-sizing: border-box;
  width: 100%;
}
.mobile-header-inner {
  display: flex;
  align-items: center;
  justify-content: space-between;
  height: 100%;
  gap: 12px;
}
.mobile-logo {
  cursor: pointer;
  display: flex;
  align-items: center;
}
.mobile-logo-img {
  height: 38px;
  border-radius: 4px;
}
.mobile-logo-text {
  font-size: 16px;
  font-weight: bold;
  color: #D8B257;
  letter-spacing: 0.5px;
}
.mobile-search-box {
  display: flex;
  align-items: center;
  background-color: #fff;
  border-radius: 20px;
  padding: 2px 4px 2px 14px;
  height: 35px;
  flex: 1;
}
.mobile-search-input {
  border: none;
  outline: none;
  font-size: 13px;
  width: 100%;
  color: #333;
}
.mobile-search-btn {
  border: none;
  background-color: #D8B257;
  color: #111;
  width: 28px;
  height: 28px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  font-size: 14px;
}
.mobile-cart-btn {
  position: relative;
  display: flex;
  align-items: center;
  cursor: pointer;
}
.mobile-cart-badge :deep(.el-badge__content) {
  background-color: #d93025 !important;
  color: #fff !important;
  border: none !important;
  font-size: 10px;
  height: 16px;
  padding: 0 4px;
  line-height: 16px;
}
.mobile-menu-btn {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  padding: 2px;
}
.hamburger-lines {
  display: flex;
  flex-direction: column;
  gap: 4px;
  width: 22px;
}
.hamburger-lines span {
  display: block;
  height: 2px;
  width: 100%;
  background-color: #D8B257;
  border-radius: 1px;
}
.menu-btn-text {
  font-size: 9px;
  color: #D8B257;
  font-weight: 700;
  margin-top: 3px;
  letter-spacing: 0.5px;
}

/* --- 5. Mobile Drawer overlay slide styling --- */
.mobile-drawer-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background-color: rgba(0, 0, 0, 0.6);
  z-index: 10000;
  backdrop-filter: blur(4px);
}
.mobile-drawer-content {
  position: absolute;
  top: 0;
  right: 0;
  width: 80%;
  max-width: 320px;
  height: 100%;
  background-color: #fff;
  box-shadow: -5px 0 25px rgba(0,0,0,0.3);
  display: flex;
  flex-direction: column;
}
.drawer-header {
  background-color: #000;
  color: #fff;
  padding: 15px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  border-bottom: 2px solid #D8B257;
}
.drawer-logo {
  cursor: pointer;
}
.drawer-logo img {
  height: 34px;
  border-radius: 4px;
}
.drawer-logo h2 {
  margin: 0;
  font-size: 16px;
  color: #D8B257;
  font-weight: bold;
  letter-spacing: 1px;
}
.drawer-close-btn {
  background: none;
  border: none;
  color: #D8B257;
  font-size: 28px;
  cursor: pointer;
  line-height: 1;
}
.drawer-body {
  flex: 1;
  overflow-y: auto;
  padding-bottom: 40px;
}
.drawer-section-title {
  background-color: #f5f5f5;
  color: #666;
  font-weight: bold;
  font-size: 11px;
  padding: 10px 15px;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  border-top: 1px solid #eee;
  border-bottom: 1px solid #eee;
}
.drawer-menu-item {
  padding: 14px 20px;
  font-size: 13.5px;
  color: #333;
  font-weight: 500;
  cursor: pointer;
  border-bottom: 1px solid #f0f0f0;
}
.drawer-menu-item.main-link {
  font-weight: bold;
  border-bottom: none;
}
.drawer-cat-group {
  border-bottom: 1px solid #f0f0f0;
}
.drawer-cat-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 14px 20px;
  font-size: 13.5px;
  color: #333;
  font-weight: 500;
  cursor: pointer;
}
.drawer-cat-header .el-icon {
  transition: transform 0.2s ease;
  color: #999;
}
.drawer-cat-header .el-icon.is-active {
  transform: rotate(180deg);
  color: #D8B257;
}
.drawer-child-list {
  background-color: #fafafa;
  padding: 5px 0;
  border-top: 1px dashed #eee;
}
.drawer-child-item {
  padding: 10px 30px;
  font-size: 12.5px;
  color: #666;
  cursor: pointer;
}
.drawer-user-info {
  padding: 12px 20px;
  font-size: 13px;
  color: #555;
  border-bottom: 1px solid #f0f0f0;
}
.logout-link {
  color: #f56c6c !important;
}
.drawer-hotline-item {
  padding: 15px 20px;
  display: flex;
  align-items: center;
  gap: 10px;
  color: #D8B257;
  font-weight: bold;
  font-size: 14px;
  cursor: pointer;
}
.hotline-numbers {
  letter-spacing: 0.5px;
}

/* Animations slide-in-fade */
.slide-fade-enter-active, .slide-fade-leave-active {
  transition: all 0.3s ease;
}
.slide-fade-enter-from, .slide-fade-leave-to {
  opacity: 0;
}
.slide-fade-enter-active .mobile-drawer-content {
  transition: transform 0.3s ease;
}
.slide-fade-enter-from .mobile-drawer-content {
  transform: translateX(100%);
}
.slide-fade-leave-active .mobile-drawer-content {
  transition: transform 0.2s ease;
}
.slide-fade-leave-to .mobile-drawer-content {
  transform: translateX(100%);
}

/* Tablet / Responsive view hooks */
@media (max-width: 992px) {
  .container { padding: 0 15px; }
  .search-box { width: 350px; }
}

@media (max-width: 768px) {
  .desktop-only {
    display: none !important;
  }
  .mobile-only {
    display: block !important;
  }
}
</style>
