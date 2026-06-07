<template>
  <el-container class="admin-wrapper">
    <el-aside width="225px" class="sidebar">
      <div class="logo-container"><span>ĐÈN HOA MỸ</span></div>
      <el-menu 
        :default-active="activeMenu" 
        @select="(index) => activeMenu = index" 
        background-color="#1a222d" 
        text-color="#b0b5b9" 
        active-text-color="#D8B257"
        class="admin-menu"
      >
        <el-menu-item index="1" v-if="authStore.hasPermission('dashboard')"><el-icon><DataBoard /></el-icon> <span>Thống kê tổng quan</span></el-menu-item>
        
        <el-sub-menu index="2" v-if="authStore.hasPermission('products') || authStore.hasPermission('categories')">
          <template #title><el-icon><ShoppingBag /></el-icon> <span>Quản lý sản phẩm</span></template>
          <el-menu-item index="2-1" v-if="authStore.hasPermission('categories')">Danh mục đèn</el-menu-item>
          <el-menu-item index="2-2" v-if="authStore.hasPermission('products')">Danh sách sản phẩm</el-menu-item>
        </el-sub-menu>
        
        <el-sub-menu index="3" v-if="authStore.hasPermission('orders')">
          <template #title><el-icon><Tickets /></el-icon> <span>Quản lý đơn hàng</span></template>
          <el-menu-item index="3-1">Đơn chờ xác nhận</el-menu-item>
          <el-menu-item index="3-2">Danh sách đơn hàng</el-menu-item>
        </el-sub-menu>

        <el-menu-item index="6" v-if="authStore.hasPermission('reviews')"><el-icon><ChatDotRound /></el-icon> <span>Quản lý đánh giá</span></el-menu-item>
        <el-menu-item index="8" v-if="authStore.hasPermission('news')"><el-icon><Document /></el-icon> <span>Quản lý tin tức</span></el-menu-item>
        <el-menu-item index="9" v-if="authStore.hasPermission('policy')"><el-icon><Notebook /></el-icon> <span>Quản lý chính sách</span></el-menu-item>
        <el-menu-item index="4" v-if="authStore.hasPermission('customers') || authStore.hasPermission('accounts')"><el-icon><User /></el-icon> <span>Quản lý người dùng</span></el-menu-item>
        <el-menu-item index="7" v-if="authStore.hasPermission('coupons')"><el-icon><Ticket /></el-icon> <span>Quản lý khuyến mãi</span></el-menu-item>
        <el-menu-item index="5" v-if="authStore.hasPermission('settings')"><el-icon><Setting /></el-icon> <span>Cài đặt hệ thống</span></el-menu-item>
      </el-menu>
    </el-aside>

    <el-container>
      <el-header class="header">
        <div class="breadcrumb">Trang chủ / {{ getBreadcrumb() }}</div>
        <div class="user-info-section">
          <el-tooltip content="Chuyển đến Website Khách" placement="bottom">
            <div class="header-icon-btn" @click="$router.push('/')">
              <el-icon :size="20"><Monitor /></el-icon>
            </div>
          </el-tooltip>

          <el-badge v-if="canPollOrders" :value="pendingOrders.length" :hidden="pendingOrders.length === 0" type="warning" class="custom-badge">
            <div class="header-icon-btn" @click="goToPendingOrders"><el-icon :size="20"><List /></el-icon></div>
          </el-badge>

          <el-popover placement="bottom-end" :width="320" trigger="click" popper-style="padding: 0; overflow: hidden; border-radius: 8px;">
            <template #reference>
              <el-badge :value="unreadCount" :hidden="unreadCount === 0" :max="99" class="custom-badge">
                <div class="header-icon-btn"><el-icon :size="20"><Bell /></el-icon></div>
              </el-badge>
            </template>
            <div class="notification-panel">
              <div class="notif-header"><span>Thông Báo</span><span class="notif-count">{{ notifications.length }}</span></div>
              <div class="notif-body">
                <div v-for="notif in notifications" :key="notif.id" class="notif-item" @click="markAsRead(notif)">
                  <div class="notif-dot" v-if="!notif.read"></div>
                  <div class="notif-content">{{ notif.text }}</div>
                </div>
                <el-empty v-if="notifications.length === 0" description="Không có thông báo mới" :image-size="60" />
              </div>
            </div>
          </el-popover>

          <el-dropdown trigger="click" style="margin-left: 10px;">
            <div class="user-profile">
              <el-avatar :size="32" :src="profileForm.avatar" />
              <span class="user-name">{{ adminName }}</span>
              <el-icon class="dropdown-icon"><CaretBottom /></el-icon>
            </div>
            <template #dropdown>
              <el-dropdown-menu>
                <el-dropdown-item @click="profileDialogVisible = true"><el-icon><User /></el-icon>Trung tâm cá nhân</el-dropdown-item>
                <el-dropdown-item divided @click="handleLogout"><el-icon><SwitchButton /></el-icon>Đăng xuất hệ thống</el-dropdown-item>
              </el-dropdown-menu>
            </template>
          </el-dropdown>
        </div>
      </el-header>

      <el-main class="main-content">
        <AdminDashboard
          v-if="activeMenu === '1'"
          :stats="stats"
          @stats-loaded="handleDashboardStatsLoaded"
          @open-products="handleOpenProductsFromDashboard"
        />

        <AdminCategories v-else-if="activeMenu === '2-1'" @categories-updated="onCategoriesUpdated" />

        <AdminProducts v-else-if="activeMenu === '2-2'" :flat-categories="flatCategories" @stats-updated="onProductStatsUpdated" />

        <AdminPendingOrders v-else-if="activeMenu === '3-1'" :pending-orders="pendingOrders" @approved="onOrderApproved" @cancelled="onOrderCancelled" />

        <AdminOrders v-else-if="activeMenu === '3-2'" :all-orders="allOrders" :web-settings-form="webSettingsForm" @orders-changed="onOrdersChanged" />

        <AdminUsers v-else-if="activeMenu === '4' && canAccessUserManagement" />
        <el-empty v-else-if="activeMenu === '4'" description="Bạn không có quyền truy cập quản lý người dùng" />

        <AdminSettings v-else-if="activeMenu === '5'" @settings-loaded="onSettingsLoaded" />

        <AdminReviews v-else-if="activeMenu === '6'" />

        <div v-else-if="activeMenu === '7'">
          <AdminHotDeal />
          <div style="margin-top: 25px;"></div>
          <AdminCoupons />
        </div>
        
        <AdminNews v-else-if="activeMenu === '8'" />

        <AdminPolicy v-else-if="activeMenu === '9'" />

      </el-main>
    </el-container>
  </el-container>

  <el-dialog v-model="profileDialogVisible" title="Trung tâm cá nhân" width="700px" top="5vh">
    <el-tabs tab-position="left" style="height: 450px">
      <el-tab-pane label="Thông tin cơ bản">
        <el-row :gutter="40" style="padding: 20px">
          <el-col :span="8" style="text-align: center">
            <el-upload action="#" :auto-upload="false" :show-file-list="false" @change="handleAvatarChange">
              <el-avatar :size="120" :src="profileForm.avatar" style="cursor: pointer; border: 2px solid #409EFF" />
              <div style="margin-top: 10px; color: #909399; font-size: 12px">Click để đổi ảnh đại diện</div>
            </el-upload>
          </el-col>
          <el-col :span="16">
            <el-form :model="profileForm" label-position="top">
              <el-form-item label="Họ và tên"><el-input v-model="profileForm.name" /></el-form-item>
              <el-form-item label="Email hệ thống"><el-input v-model="profileForm.email" /></el-form-item>
              <el-form-item label="Số điện thoại"><el-input v-model="profileForm.phone" /></el-form-item>
              <el-form-item label="Địa chỉ liên hệ"><el-input v-model="profileForm.address" type="textarea" /></el-form-item>
            </el-form>
          </el-col>
        </el-row>
      </el-tab-pane>
      <el-tab-pane label="Đổi mật khẩu">
        <div style="padding: 20px">
          <el-form :model="passwordForm" label-position="top">
            <el-form-item label="Mật khẩu hiện tại"><el-input v-model="passwordForm.current" type="password" show-password /></el-form-item>
            <el-form-item label="Mật khẩu mới"><el-input v-model="passwordForm.newPassword" type="password" show-password /></el-form-item>
            <el-form-item label="Xác nhận mật khẩu mới"><el-input v-model="passwordForm.confirm" type="password" show-password /></el-form-item>
            <el-button type="primary" :loading="changingPassword" @click="handleChangePassword">CẬP NHẬT MẬT KHẨU</el-button>
          </el-form>
        </div>
      </el-tab-pane>
    </el-tabs>
    <template #footer><el-button @click="profileDialogVisible = false">Đóng</el-button><el-button type="primary" @click="saveProfile">Lưu thay đổi</el-button></template>
  </el-dialog>

</template>

<script setup>
import { ref, onMounted, onUnmounted, computed, defineAsyncComponent } from 'vue'
import { useRouter } from 'vue-router'
import { DataBoard, ShoppingBag, User, CaretBottom, SwitchButton, Plus, Bell, List, Tickets, Search, Delete, Setting, ChatDotRound, Download, Monitor, Ticket, Upload, UploadFilled, Document, Notebook } from '@element-plus/icons-vue'
import { useAuthStore } from '../stores/auth'
import { getOrders } from '../services/orderService'
import { getStatusLabel } from '../utils/orderStatus'
import { getCategories } from '../services/categoryService'
import { uploadImage } from '../services/uploadService'
import { getSettings } from '../services/settingsService'
import { changeAdminPasswordApi } from '../services/authService'

import { ElMessage, ElMessageBox, ElNotification } from 'element-plus'

const ORDERS_POLL_MS = 5000

const ADMIN_MENU_ENTRIES = [
  { index: '1', perm: 'dashboard' },
  { index: '2-1', perm: 'categories' },
  { index: '2-2', perm: 'products' },
  { index: '3-1', perm: 'orders' },
  { index: '6', perm: 'reviews' },
  { index: '8', perm: 'news' },
  { index: '9', perm: 'policy' },
  { index: '4', check: (store) => store.hasPermission('customers') || store.hasPermission('accounts') },
  { index: '7', perm: 'coupons' },
  { index: '5', perm: 'settings' },
]

function getDefaultAdminMenu(store) {
  for (const entry of ADMIN_MENU_ENTRIES) {
    if (entry.check ? entry.check(store) : store.hasPermission(entry.perm)) {
      return entry.index
    }
  }
  return '1'
}

const goToPendingOrders = () => {
  if (authStore.hasPermission('orders')) {
    activeMenu.value = '3-1'
  }
}

const DEFAULT_WEB_SETTINGS = {
  shop_name: 'ĐÈN HOA MỸ - THẾ GIỚI ĐÈN NGHỆ THUẬT',
  address: '905 Nguyễn Văn Linh, An Biên, Hải Phòng',
  hotline: '0978897579 - 02256533618',
  logo_url: '',
  banner_urls: '',
  email: '',
  banner_right: ''
}
const AdminDashboard = defineAsyncComponent(() => import('../components/AdminDashboard.vue'))
const AdminCategories = defineAsyncComponent(() => import('../components/AdminCategories.vue'))
const AdminPendingOrders = defineAsyncComponent(() => import('../components/AdminPendingOrders.vue'))
const AdminProducts = defineAsyncComponent(() => import('../components/AdminProducts.vue'))
const AdminOrders = defineAsyncComponent(() => import('../components/AdminOrders.vue'))
const AdminUsers = defineAsyncComponent(() => import('../components/AdminUsers.vue'))
const AdminReviews = defineAsyncComponent(() => import('../components/AdminReviews.vue'))
const AdminSettings = defineAsyncComponent(() => import('../components/AdminSettings.vue'))
const AdminCoupons = defineAsyncComponent(() => import('../components/AdminCoupons.vue'))
const AdminNews = defineAsyncComponent(() => import('../components/AdminNews.vue'))
const AdminPolicy = defineAsyncComponent(() => import('../components/AdminPolicy.vue'))
const AdminHotDeal = defineAsyncComponent(() => import('../components/AdminHotDeal.vue'))


const router = useRouter()
const authStore = useAuthStore()
const canPollOrders = computed(() => authStore.hasPermission('orders'))
const canAccessUserManagement = computed(() =>
  authStore.hasPermission('customers') || authStore.hasPermission('accounts')
)
const adminName = ref(authStore.user?.name || 'Admin')
const activeMenu = ref(getDefaultAdminMenu(authStore))
const profileDialogVisible = ref(false)
const changingPassword = ref(false)
const passwordForm = ref({ current: '', newPassword: '', confirm: '' })

const profileForm = ref({ name: adminName.value, email: 'hieu.it@denhoamy.com', phone: '0912345678', address: 'Hải Phòng, Việt Nam', avatar: 'https://cube.elemecdn.com/0/88/03b0d39583f48206768a7534e55bcpng.png' })

// QUẢN LÝ DANH MỤC (TỪ CSDL)
const flatCategories = ref([])

const fetchCategoriesData = async () => {
  const res = await getCategories()
  if (res && res.success) {
    flatCategories.value = res.flat || []
  }
}

// Category CRUD đã chuyển sang AdminCategories.vue
const onCategoriesUpdated = (newFlatCategories) => {
  flatCategories.value = newFlatCategories
}

// Products đã chuyển sang AdminProducts.vue
const stats = ref([
  { key: 'total_product_types', title: 'Tổng loại đèn', value: 0, color: 'blue-line' },
  { key: 'in_stock', title: 'Trong kho', value: 0, color: 'blue-line' },
  { key: 'total_orders', title: 'Tổng đơn hàng', value: 0, color: 'green-line' },
  { key: 'orders_today', title: 'Đơn hôm nay', value: 0, color: 'green-line' },
  { key: 'pending_orders', title: 'Đơn chờ xác nhận', value: 0, color: 'green-line' },
  { key: 'cancel_rate', title: 'Tỉ lệ huỷ đơn', value: '0%', color: 'orange-line', format: 'percent' },
  { key: 'avg_order_value', title: 'Giá trị đơn TB', value: 0, color: 'orange-line', format: 'currency' },
  { key: 'total_revenue', title: 'Doanh thu', value: 0, color: 'orange-line', format: 'currency' },
  { key: 'total_profit', title: 'Lợi nhuận', value: 0, color: 'blue-line', format: 'currency' }
])
const formatMoneyVND = (value) => `${Number(value || 0).toLocaleString('vi-VN')}đ`
const formatPercent = (value) => `${Number(value || 0).toFixed(2)}%`
const updateStatValue = (key, value) => {
  const target = stats.value.find((item) => item.key === key)
  if (!target) return
  if (target.format === 'currency') {
    target.value = formatMoneyVND(value)
    return
  }
  if (target.format === 'percent') {
    target.value = formatPercent(value)
    return
  }
  target.value = Number(value || 0)
}

const onProductStatsUpdated = ({ productCount, totalStock }) => {
  updateStatValue('total_product_types', productCount)
  updateStatValue('in_stock', totalStock)
}

// CÀI ĐẶT WEB — tải sớm để hóa đơn/phiếu giao có địa chỉ & hotline
const webSettingsForm = ref({ ...DEFAULT_WEB_SETTINGS })

const fetchWebSettings = async () => {
  const result = await getSettings()
  if (result?.success && result.data) {
    webSettingsForm.value = { ...DEFAULT_WEB_SETTINGS, ...result.data }
  }
}

const onSettingsLoaded = (settings) => {
  webSettingsForm.value = { ...DEFAULT_WEB_SETTINGS, ...settings }
}

// CẬP NHẬT LOGIC ĐỔI INDEX 3-1 & 3-2
const notifications = ref([])
const unreadCount = computed(() => notifications.value.filter(n => !n.read).length)
const markAsRead = (notif) => {
  notif.read = true
  goToPendingOrders()
}

const allOrdersList = ref([])
const lastPendingCount = ref(0)
let ordersPollInitialized = false

const pendingOrders = computed(() => allOrdersList.value.filter(order => order.status === 'pending').map(order => ({
  db_id: order.id,
  orderId: `#ORD-${order.id}`,
  customerName: order.customer_name,
  date: new Date(order.created_at.replace(' ', 'T') + 'Z').toLocaleString('vi-VN'),
  total: formatPrice(order.total),
  items: order.items || []
})))

const allOrders = computed(() => allOrdersList.value.map(order => ({
  db_id: order.id,
  orderId: `#ORD-${order.id}`,
  rawOrderId: `HD00${order.id}`,
  customerName: order.customer_name,
  phone: order.phone,
  email: order.email,
  address: order.address,
  note: order.note,
  deliveryMethod: order.delivery_method || 'home',
  paymentMethod: order.payment_method || 'cod',
  date: new Date(order.created_at.replace(' ', 'T') + 'Z').toLocaleString('vi-VN'),
  raw_status: order.status,
  status: getStatusLabel(order.status),
  items: order.items || [],
  discount_amount: order.discount_amount || 0,
  total_amount: order.total || 0,
})))


const syncPendingNotifications = (pendingCount, delta = 0) => {
  if (delta > 0) {
    notifications.value.unshift({
      id: Date.now(),
      text: `Có ${delta} đơn mới chờ xác nhận`,
      read: false,
    })
    return
  }
  notifications.value = pendingCount > 0
    ? [{ id: Date.now(), text: `Có ${pendingCount} đơn hàng đang chờ xác nhận`, read: false }]
    : []
}

const fetchOrders = async () => {
  if (!canPollOrders.value) return

  const result = await getOrders()
  if (!result?.success) return

  const pendingCount = (result.data || []).filter((o) => o.status === 'pending').length

  if (ordersPollInitialized && pendingCount > lastPendingCount.value) {
    const delta = pendingCount - lastPendingCount.value
    ElNotification({
      title: 'Đơn hàng mới',
      message: `Có ${delta} đơn mới chờ xác nhận (tổng ${pendingCount})`,
      type: 'warning',
      duration: 8000,
      position: 'top-right',
      onClick: () => {
        goToPendingOrders()
      },
    })
    syncPendingNotifications(pendingCount, delta)
  } else if (!ordersPollInitialized) {
    syncPendingNotifications(pendingCount)
  } else if (pendingCount !== lastPendingCount.value) {
    syncPendingNotifications(pendingCount)
  }

  allOrdersList.value = result.data
  lastPendingCount.value = pendingCount
  ordersPollInitialized = true
}


// approve/cancelOrder đã chuyển sang AdminPendingOrders.vue
const onOrdersChanged = async () => {
  await fetchOrders()
}

const onOrderApproved = async () => {
  await fetchOrders()
  activeMenu.value = '3-2'
}
const onOrderCancelled = async () => {
  await fetchOrders()
}


const handleDashboardStatsLoaded = ({ summary, financials }) => {
  updateStatValue('total_orders', summary?.total_orders || 0)
  updateStatValue('orders_today', summary?.orders_today || summary?.today_orders || 0)
  updateStatValue('pending_orders', summary?.pending_orders || 0)
  updateStatValue('cancel_rate', summary?.cancel_rate || 0)
  updateStatValue('avg_order_value', summary?.avg_order_value || 0)
  updateStatValue('total_revenue', financials?.total_revenue || 0)
  updateStatValue('total_profit', financials?.total_profit || 0)
}

const handleOpenProductsFromDashboard = () => {
  activeMenu.value = '2-2'
}


let ordersPollTimer = null

const stopOrdersPolling = () => {
  if (ordersPollTimer) {
    clearInterval(ordersPollTimer)
    ordersPollTimer = null
  }
}

const startOrdersPolling = () => {
  if (!canPollOrders.value) return
  stopOrdersPolling()
  ordersPollTimer = setInterval(() => {
    if (document.visibilityState === 'visible') {
      fetchOrders()
    }
  }, ORDERS_POLL_MS)
}

const onAdminVisibilityChange = () => {
  if (!canPollOrders.value) return
  if (document.visibilityState === 'visible') {
    fetchOrders()
    startOrdersPolling()
  } else {
    stopOrdersPolling()
  }
}

onMounted(() => {
  fetchOrders()
  fetchCategoriesData()
  fetchWebSettings()
  startOrdersPolling()
  document.addEventListener('visibilitychange', onAdminVisibilityChange)
})

onUnmounted(() => {
  stopOrdersPolling()
  document.removeEventListener('visibilitychange', onAdminVisibilityChange)
})


// CẬP NHẬT BREADCRUMB
const formatPrice = (value) => value.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ".")
const getBreadcrumb = () => ({ '1': 'Thống kê', '2-1': 'Danh mục', '2-2': 'Sản phẩm', '3-1': 'Đơn chờ duyệt', '3-2': 'Danh sách đơn', '4': 'Người dùng', '5': 'Cài đặt Website', '6': 'Đánh giá sản phẩm', '7': 'Danh sách Mã giảm giá', '8': 'Tin tức bài viết', '9': 'Quản lý chính sách' }[activeMenu.value] || 'Quản trị')
const handleLogout = () => { authStore.logout(); router.push('/login') }
const openProfileDialog = () => { profileDialogVisible.value = true }
const handleAvatarChange = async (file) => { const res = await uploadImage(file.raw, 'avatar'); if (res && res.success) { profileForm.value.avatar = res.url } }
const saveProfile = () => { adminName.value = profileForm.value.name; profileDialogVisible.value = false; ElMessage.success('Đã cập nhật!'); }

const handleChangePassword = async () => {
  const { current, newPassword, confirm } = passwordForm.value
  if (!current || !newPassword || !confirm) {
    ElMessage.warning('Vui lòng nhập đầy đủ thông tin mật khẩu')
    return
  }
  if (newPassword.length < 6) {
    ElMessage.warning('Mật khẩu mới phải có ít nhất 6 ký tự')
    return
  }
  if (newPassword !== confirm) {
    ElMessage.warning('Xác nhận mật khẩu không khớp')
    return
  }
  changingPassword.value = true
  const res = await changeAdminPasswordApi(current, newPassword)
  changingPassword.value = false
  if (res?.success) {
    passwordForm.value = { current: '', newPassword: '', confirm: '' }
    ElMessage.success(res.message || 'Đổi mật khẩu thành công')
  } else {
    ElMessage.error(res?.message || 'Không thể đổi mật khẩu')
  }
}

// ===================== IMPORT EXCEL =====================

</script>

<style scoped>


.admin-wrapper { height: 100vh; width: 100vw; display: flex; }
.sidebar { background-color: #1a222d; border-right: none; transition: width 0.3s; }
.logo-container { height: 60px; display: flex; align-items: center; justify-content: center; background-color: #1a222d; color: #fff; font-weight: bold; font-size: 16px; border-bottom: 1px solid rgba(255,255,255,0.05); }
.admin-menu { border-right: none !important; }
:deep(.el-menu-item), :deep(.el-sub-menu__title) { height: 50px; line-height: 50px; font-size: 15px; }
:deep(.el-sub-menu .el-sub-menu__icon-arrow) { right: 12px !important; margin-top: -6px; }
:deep(.el-menu-item .el-icon), :deep(.el-sub-menu__title .el-icon) { margin-right: 8px !important; width: 18px; text-align: center; }
:deep(.el-menu-item:hover), :deep(.el-sub-menu__title:hover) { background-color: #263445 !important; color: #D8B257 !important; }
:deep(.el-menu-item.is-active) { background-color: rgba(216, 178, 87, 0.1) !important; color: #D8B257 !important; border-right: 3px solid #D8B257; }
:deep(.el-menu--inline) { background-color: #111a25 !important; }
:deep(.el-menu--inline .el-menu-item) { padding-left: 50px !important; font-size: 14px; height: 45px; line-height: 45px; color: #909399; }
.header { background-color: #fff; display: flex; align-items: center; justify-content: space-between; height: 60px; border-bottom: 1px solid #e6e6e6; padding: 0 20px; }
.user-info-section { display: flex; align-items: center; gap: 18px; height: 100%; }
.custom-badge { display: flex; align-items: center; }
.header-icon-btn { width: 36px; height: 36px; display: flex; align-items: center; justify-content: center; border-radius: 50%; cursor: pointer; color: #606266; background-color: #f4f4f5; transition: all 0.3s ease; }
.header-icon-btn:hover { background-color: #e9e9eb; color: #409EFF; }
.notification-panel { display: flex; flex-direction: column; }
.notif-header { background-color: #409EFF; color: white; padding: 12px 16px; font-size: 16px; font-weight: 500; display: flex; justify-content: space-between; align-items: center; }
.notif-count { background-color: white; color: #333; font-size: 12px; font-weight: bold; padding: 2px 8px; border-radius: 4px; }
.notif-body { max-height: 300px; overflow-y: auto; }
.notif-item { display: flex; align-items: flex-start; padding: 12px 16px; border-bottom: 1px solid #f0f0f0; cursor: pointer; transition: background-color 0.2s; }
.notif-item:hover { background-color: #f9fafc; }
.notif-dot { width: 8px; height: 8px; background-color: #f56c6c; border-radius: 50%; margin-top: 6px; margin-right: 12px; flex-shrink: 0; }
.notif-content { font-size: 14px; color: #303133; line-height: 1.5; }
.user-profile { display: flex; align-items: center; gap: 10px; cursor: pointer; height: 36px; }
.user-name { font-weight: 500; color: #606266; font-size: 14px; line-height: 1; }
.blue-line { border-top-color: #409EFF; }
.green-line { border-top-color: #67C23A; }
.orange-line { border-top-color: #E6A23C; }
.admin-wrapper { height: 100vh; width: 100vw; }
.main-content { background-color: #f0f2f5; padding: 20px; }
:deep(.el-progress-bar__inner) { transition: width 1.5s cubic-bezier(0.4, 0, 0.2, 1); }
:deep(.el-tabs__content) { overflow: visible; }

@media print {
  .admin-wrapper { display: none !important; }
  .el-dialog__wrapper, .el-overlay { display: none !important; }
}
</style>