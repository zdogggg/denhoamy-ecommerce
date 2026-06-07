<template>
  <nav class="nav-menu" :class="{ 'is-scrolled': isScrolled }">
    <div class="container nav-container">
      <el-menu
        :default-active="activeIndex"
        mode="horizontal"
        background-color="#D8B257"
        text-color="#111"
        active-text-color="#fff"
        class="custom-menu"
      >
        <el-menu-item index="1" @click="$router.push('/')">TRANG CHỦ</el-menu-item>
        
        <template v-for="(cat, idx) in categoriesStore" :key="cat.id">
          <el-sub-menu v-if="cat.children && cat.children.length > 0" :index="(idx+2).toString()" popper-class="custom-dropdown">
            <template #title>
              <span @click.stop="goCategory(cat.name)" style="width: 100%; display: inline-block; text-transform: uppercase;">{{ cat.name }}</span>
            </template>
            <el-menu-item 
              v-for="(child, childIdx) in cat.children" 
              :key="child.id" 
              :index="`${idx+2}-${childIdx+1}`" 
              @click="goCategory(cat.name, child.name)"
            >
              {{ child.name }}
            </el-menu-item>
          </el-sub-menu>
          
          <el-menu-item v-else :index="(idx+2).toString()" @click="goCategory(cat.name)" style="text-transform: uppercase;">
            {{ cat.name }}
          </el-menu-item>
        </template>
        
        <el-menu-item index="news" @click="$router.push('/news')">
          TIN TỨC - BÀI VIẾT
        </el-menu-item>
      </el-menu>

      <!-- Scrolled Action Buttons -->
      <div v-if="isScrolled" class="scrolled-actions fade-in-actions">
        <!-- Cart Action Button -->
        <button
          type="button"
          class="scrolled-action-btn cart-action"
          @click="$router.push('/cart')"
          aria-label="Mở giỏ hàng"
        >
          <div class="scrolled-cart-icon-wrapper">
            <el-icon :size="22"><ShoppingCart /></el-icon>
            <span v-if="cartStore.itemCount > 0" class="custom-cart-badge-absolute">
              {{ cartStore.itemCount }}
            </span>
          </div>
          <span class="action-text">Giỏ hàng</span>
        </button>

        <!-- Account Action Dropdown -->
        <div class="scrolled-action-btn account-action">
          <el-dropdown trigger="click" @command="handleUserCommand">
            <span class="user-dropdown-trigger">
              <el-icon :size="22"><User /></el-icon>
              <span class="action-text user-name-label">
                {{ authStore.isLoggedIn ? authStore.user.name : 'Tài khoản' }}
              </span>
              <el-icon class="arrow-down-icon"><ArrowDown /></el-icon>
            </span>
            <template #dropdown>
              <el-dropdown-menu class="scrolled-user-dropdown">
                <template v-if="authStore.isLoggedIn">
                  <div class="dropdown-welcome">Xin chào, <strong>{{ authStore.user.name }}</strong></div>
                  <el-dropdown-item v-if="authStore.canAccessAdmin" command="admin">Quản trị</el-dropdown-item>
                  <el-dropdown-item v-else command="profile">Tài khoản của tôi</el-dropdown-item>
                  <el-dropdown-item divided command="logout" style="color: #f56c6c;">Đăng xuất</el-dropdown-item>
                </template>
                <template v-else>
                  <el-dropdown-item command="login">Đăng nhập</el-dropdown-item>
                  <el-dropdown-item command="register">Đăng ký</el-dropdown-item>
                </template>
              </el-dropdown-menu>
            </template>
          </el-dropdown>
        </div>
      </div>
    </div>
  </nav>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import { ShoppingCart, User, ArrowDown } from '@element-plus/icons-vue'
import { useCartStore } from '../stores/cart'
import { useAuthStore } from '../stores/auth'
import { getCategories } from '../services/categoryService'

defineProps({
  activeIndex: { type: String, default: '1' }
})

const router = useRouter()
const cartStore = useCartStore()
const authStore = useAuthStore()
const categoriesStore = ref([])

const goCategory = (category, subCategory) => {
  const query = {}
  if (category) query.type = category
  if (subCategory) query.sub = subCategory
  router.push({ path: '/category', query })
}

// Logic thay đổi trạng thái khi cuộn chuột
const isScrolled = ref(false)
const handleScroll = () => {
  const scrolled = window.scrollY > 150
  isScrolled.value = scrolled
  if (scrolled) {
    document.body.classList.add('is-scrolled')
  } else {
    document.body.classList.remove('is-scrolled')
  }
}

onMounted(async () => {
  const res = await getCategories()
  if (res && res.success) {
    categoriesStore.value = res.data
  }
  window.addEventListener('scroll', handleScroll)
  handleScroll() // Cập nhật trạng thái ngay lập tức khi load xong
})

onUnmounted(() => {
  window.removeEventListener('scroll', handleScroll)
})

const handleUserCommand = (command) => {
  if (command === 'admin') {
    router.push('/admin')
  } else if (command === 'profile') {
    router.push('/profile')
  } else if (command === 'logout') {
    authStore.logout()
    router.push('/')
  } else if (command === 'login') {
    router.push('/login')
  } else if (command === 'register') {
    router.push('/register')
  }
}
</script>

<style>
/* --- 1. CSS Global (Ép màu cho Popper của Element Plus) --- */
/* Khi Navbar ở trên cùng */
.custom-dropdown.el-menu--popup { 
  background-color: #C19A44 !important; 
  padding: 0 !important; 
  border-radius: 4px; 
}
.custom-dropdown .el-menu-item { 
  color: #ffffff !important; 
  font-weight: bold !important; 
  font-family: 'Montserrat', sans-serif !important;
  font-size: 13px !important; 
  text-transform: uppercase; 
}

@media (max-width: 768px) {
  .custom-dropdown {
    display: none !important;
  }
}
</style>

<style scoped>
/* --- 2. Cấu trúc Thanh Menu --- */
.container { 
  width: 1200px; 
  margin: 0 auto; 
  max-width: 100%; 
  padding: 0 20px; 
  box-sizing: border-box; 
}

.nav-container {
  display: flex !important;
  align-items: center !important;
  justify-content: space-between !important;
  height: 100%;
}

/* Nền của thanh Menu gốc (Màu vàng đồng đặc) */
.nav-menu { 
  background-color: #D8B257; 
  border-bottom: 2px solid #b5954a; 
  position: sticky;
  top: 0;
  z-index: 1002; /* Nổi bật hẳn trên cả banner và phần header chính */
  transition: all 0.3s ease; /* Hiệu ứng chuyển đổi mượt mà */
}

/* Nền khi cuộn xuống (Màu đen bóng đêm - Glassmorphism sang trọng) */
.nav-menu.is-scrolled { 
  background-color: rgba(0, 0, 0, 0.85) !important; /* Đổi sang màu đen mờ cho sang */
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  border-bottom: 1px solid rgba(216, 178, 87, 0.3); 
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.4);
  padding: 0; 
}

/* Cập nhật màu chữ khi Navbar chuyển sang đen */
.nav-menu.is-scrolled :deep(.el-menu-item),
.nav-menu.is-scrolled :deep(.el-sub-menu__title) {
  color: #D8B257 !important; /* Chữ vàng đồng nổi trên nền đen */
}

/* Hover khi ở trạng thái cuộn */
.nav-menu.is-scrolled :deep(.el-menu-item:hover),
.nav-menu.is-scrolled :deep(.el-sub-menu:hover .el-sub-menu__title) {
  background-color: rgba(255, 255, 255, 0.1) !important;
  color: #fff !important;
}

.custom-menu { 
  border-bottom: none !important; 
  font-weight: bold; 
  background-color: transparent !important; /* Để lớp nền của nav-menu quyết định */
  flex: 1;
}

/* Kích thước và font chữ cho các mục menu đồng bộ với danh mục sản phẩm bên dưới */
:deep(.el-menu-item), :deep(.el-sub-menu__title) { 
  font-family: 'Montserrat', sans-serif !important;
  font-weight: bold !important;
  font-size: 13.5px !important; 
  letter-spacing: 0.5px;
}

/* Hiệu ứng khi di chuột vào mục menu */
:deep(.el-menu--horizontal > .el-menu-item:hover), 
:deep(.el-menu--horizontal > .el-sub-menu:hover .el-sub-menu__title) { 
  background-color: #b5954a !important; 
  color: #fff !important; 
}

/* --- 3. Scrolled Action Buttons (Luxury styling) --- */
.scrolled-actions {
  display: flex;
  align-items: center;
  gap: 15px;
  margin-left: 20px;
  flex-shrink: 0; /* Không cho phép bị co bóp */
}

.scrolled-action-btn {
  display: flex;
  align-items: center;
  gap: 10px; /* Khoảng cách rộng mở rộng rãi */
  color: #D8B257;
  cursor: pointer;
  padding: 8px 18px; /* Tăng padding để nút to và sang hơn */
  border-radius: 25px; /* Bo góc hoàn hảo tương ứng */
  background-color: rgba(255, 255, 255, 0.05);
  border: 1px solid rgba(216, 178, 87, 0.25);
  transition: all 0.3s cubic-bezier(0.25, 0.8, 0.25, 1);
  font-family: 'Montserrat', sans-serif !important;
  font-weight: bold;
  white-space: nowrap; /* Tuyệt đối không tự ngắt dòng */
  appearance: none;
  outline: none;
}

.scrolled-action-btn:hover {
  background-color: #D8B257;
  color: #111;
  border-color: #D8B257;
  box-shadow: 0 0 15px rgba(216, 178, 87, 0.4);
}

.scrolled-action-btn:focus-visible {
  box-shadow: 0 0 0 3px rgba(216, 178, 87, 0.55);
}

.scrolled-action-btn:hover :deep(.el-icon) {
  color: #111 !important;
}

/* Khung bọc Icon Giỏ hàng để định vị badge tùy chỉnh */
.scrolled-cart-icon-wrapper {
  position: relative;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  margin-right: 12px; /* Khoảng cách bên phải rộng rãi làm bước đệm cho Badge đỏ */
}

/* Badge số giỏ hàng tự thiết kế để kiểm soát tuyệt đối vị trí */
.custom-cart-badge-absolute {
  position: absolute;
  top: -8px;
  right: -12px;
  background-color: #d93025;
  color: #fff;
  font-size: 11px;
  font-weight: bold;
  height: 18px;
  min-width: 18px;
  padding: 0 5px;
  border-radius: 9px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  box-sizing: border-box;
  box-shadow: 0 2px 5px rgba(0,0,0,0.3);
  font-family: Arial, sans-serif !important;
  line-height: 1;
}

/* Khi hover vào nút giỏ hàng, chữ màu của badge vẫn giữ nguyên */
.scrolled-action-btn:hover .custom-cart-badge-absolute {
  color: #fff !important;
}

.user-dropdown-trigger {
  display: flex;
  align-items: center;
  gap: 8px;
  color: inherit;
  cursor: pointer;
}

.arrow-down-icon {
  font-size: 12px;
  margin-top: 1px;
  transition: transform 0.3s;
}

.scrolled-action-btn:hover .arrow-down-icon {
  transform: rotate(180deg);
}

.action-text {
  font-size: 13.5px;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  font-family: 'Montserrat', sans-serif !important;
  font-weight: bold;
  white-space: nowrap !important;
}

.user-name-label {
  max-width: 120px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

/* Dropdown menu customize when scrolled */
:deep(.scrolled-user-dropdown) {
  border-radius: 8px;
  border: 1px solid rgba(216, 178, 87, 0.2) !important;
  box-shadow: 0 10px 25px rgba(0,0,0,0.15) !important;
}

.dropdown-welcome {
  padding: 10px 16px;
  font-size: 12px;
  color: #666;
  border-bottom: 1px solid #eee;
  margin-bottom: 5px;
  font-family: 'Montserrat', sans-serif;
}

/* Hiệu ứng mượt mà khi xuất hiện actions */
@keyframes fadeInActions {
  from {
    opacity: 0;
    transform: translateX(15px);
  }
  to {
    opacity: 1;
    transform: translateX(0);
  }
}

.fade-in-actions {
  animation: fadeInActions 0.4s cubic-bezier(0.25, 1, 0.5, 1) forwards;
}

/* --- 4. Responsive cho Mobile --- */
@media (max-width: 768px) {
  .nav-menu {
    display: none !important;
  }
}
</style>
