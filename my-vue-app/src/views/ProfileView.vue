<template>
  <div class="profile-page">
    <AppHeader />
    <AppNavbar activeIndex="" />

    <div class="profile-container">
      <div class="profile-layout">
        <aside class="profile-sidebar">
          <el-card shadow="never" class="profile-sidebar-card">
            <div class="profile-user-block" :class="{ 'is-compact': isMobile }">
              <el-avatar :size="isMobile ? 56 : 80" class="profile-avatar">
                {{ authStore.user?.name?.charAt(0) || 'U' }}
              </el-avatar>
              <div class="profile-user-text">
                <h3 class="profile-name">{{ authStore.user?.name }}</h3>
                <p class="profile-phone">{{ authStore.user?.phone }}</p>
                <el-tag size="small" type="success">Khách hàng thành viên</el-tag>
              </div>
            </div>

            <el-menu
              v-if="!isMobile"
              :default-active="activeTab"
              class="profile-menu-desktop"
              style="border-right: none;"
              @select="handleMenuSelect"
            >
              <el-menu-item index="1"><el-icon><List /></el-icon> Lịch sử Đơn hàng</el-menu-item>
              <el-menu-item index="4"><el-icon><Star /></el-icon> Sản phẩm Yêu thích</el-menu-item>
              <el-menu-item index="3"><el-icon><User /></el-icon> Thông tin của tôi</el-menu-item>
              <el-menu-item index="2" @click="handleLogout"><el-icon><SwitchButton /></el-icon> Đăng xuất</el-menu-item>
            </el-menu>

            <div v-else class="profile-menu-mobile">
              <button
                v-for="tab in profileTabs"
                :key="tab.id"
                type="button"
                class="profile-tab-btn"
                :class="{ active: activeTab === tab.id }"
                @click="tab.id === '2' ? handleLogout() : (activeTab = tab.id)"
              >
                <el-icon><component :is="tab.icon" /></el-icon>
                <span>{{ tab.label }}</span>
              </button>
            </div>
          </el-card>
        </aside>

        <main class="profile-main">
          <el-card v-if="activeTab === '1'" shadow="never" class="profile-content-card">
            <template #header>
              <h3 class="profile-card-title">Lịch sử Đơn hàng của bạn</h3>
            </template>

            <template v-if="!isMobile">
              <el-table :data="orders" stripe style="width: 100%" v-loading="loading">
                <el-table-column prop="id" label="Mã Đơn" width="100">
                  <template #default="scope">DH{{ scope.row.id }}</template>
                </el-table-column>
                <el-table-column prop="created_at" label="Ngày Đặt" width="160" />
                <el-table-column label="Sản Phẩm" min-width="250">
                  <template #default="scope">
                    <div v-for="item in scope.row.items" :key="item.id" class="order-product-line">
                      - {{ item.product_name }} <strong class="gold-text">(x{{ item.quantity }})</strong>
                    </div>
                  </template>
                </el-table-column>
                <el-table-column label="Tổng tiền" width="130">
                  <template #default="scope">
                    <span class="gold-text order-total">{{ formatPrice(scope.row.total) }}đ</span>
                  </template>
                </el-table-column>
                <el-table-column label="Trạng thái" width="160">
                  <template #default="scope">
                    <el-tag :type="getStatusTagType(scope.row.status)" effect="dark">
                      {{ getStatusLabel(scope.row.status) }}
                    </el-tag>
                  </template>
                </el-table-column>
              </el-table>
            </template>

            <div v-else class="orders-mobile" v-loading="loading">
              <div v-for="order in orders" :key="order.id" class="order-mobile-card">
                <div class="order-mobile-head">
                  <strong>DH{{ order.id }}</strong>
                  <el-tag :type="getStatusTagType(order.status)" size="small" effect="dark">
                    {{ getStatusLabel(order.status) }}
                  </el-tag>
                </div>
                <div class="order-mobile-date">{{ order.created_at }}</div>
                <div class="order-mobile-products">
                  <div v-for="item in order.items" :key="item.id" class="order-product-line">
                    {{ item.product_name }} <strong class="gold-text">x{{ item.quantity }}</strong>
                  </div>
                </div>
                <div class="order-mobile-foot">
                  <span>Tổng tiền</span>
                  <strong class="gold-text">{{ formatPrice(order.total) }}đ</strong>
                </div>
              </div>
            </div>

            <el-empty
              v-if="!loading && orders.length === 0"
              description="Bạn chưa có đơn hàng nào"
              class="profile-empty"
            />
          </el-card>

          <el-card v-if="activeTab === '3'" shadow="never" class="profile-content-card">
            <template #header>
              <div class="profile-form-header" :class="{ 'is-mobile': isMobile }">
                <h3 class="profile-card-title">Thông tin cá nhân</h3>
                <el-button type="primary" @click="handleUpdateProfile" :loading="updating">Lưu thay đổi</el-button>
              </div>
            </template>
            <el-form :model="profileForm" label-position="top">
              <div class="profile-form-grid">
                <el-form-item label="Họ và tên">
                  <el-input v-model="profileForm.name" placeholder="Nhập họ tên của bạn" />
                </el-form-item>
                <el-form-item label="Số điện thoại">
                  <el-input v-model="profileForm.phone" disabled placeholder="Số điện thoại không thể thay đổi" />
                </el-form-item>
              </div>
              <el-form-item label="Email">
                <el-input v-model="profileForm.email" placeholder="Nhập địa chỉ email" />
              </el-form-item>
              <el-form-item label="Địa chỉ nhận hàng mặc định">
                <el-input
                  v-model="profileForm.address"
                  type="textarea"
                  :rows="3"
                  placeholder="Số nhà, tên đường, phường/xã, quận/huyện, tỉnh/thành phố..."
                />
              </el-form-item>
            </el-form>
          </el-card>

          <el-card v-if="activeTab === '4'" shadow="never" class="profile-content-card">
            <template #header>
              <h3 class="profile-card-title">Sản phẩm bạn đã yêu thích</h3>
            </template>

            <template v-if="!isMobile">
              <el-table :data="wishlists" stripe style="width: 100%" v-loading="loadingWishlist">
                <el-table-column label="Hình ảnh" width="100">
                  <template #default="scope">
                    <el-image :src="scope.row.image_url" class="wishlist-thumb" />
                  </template>
                </el-table-column>
                <el-table-column prop="ten_san_pham" label="Tên sản phẩm" />
                <el-table-column label="Giá bán" width="150">
                  <template #default="scope">
                    <span class="gold-text">{{ formatPrice(scope.row.price) }}đ</span>
                  </template>
                </el-table-column>
                <el-table-column label="Thao tác" width="150">
                  <template #default="scope">
                    <el-button size="small" type="primary" @click="router.push('/product/' + scope.row.id)">
                      Xem ngay
                    </el-button>
                    <el-button
                      size="small"
                      type="danger"
                      :icon="Delete"
                      circle
                      @click="handleRemoveWishlist(scope.row.id)"
                    />
                  </template>
                </el-table-column>
              </el-table>
            </template>

            <div v-else class="wishlist-mobile" v-loading="loadingWishlist">
              <div v-for="item in wishlists" :key="item.id" class="wishlist-mobile-card">
                <el-image :src="item.image_url" class="wishlist-mobile-img" fit="cover" />
                <div class="wishlist-mobile-info">
                  <div class="wishlist-mobile-name">{{ item.ten_san_pham }}</div>
                  <div class="gold-text wishlist-mobile-price">{{ formatPrice(item.price) }}đ</div>
                  <div class="wishlist-mobile-actions">
                    <el-button size="small" type="primary" @click="router.push('/product/' + item.id)">
                      Xem ngay
                    </el-button>
                    <el-button size="small" type="danger" :icon="Delete" circle @click="handleRemoveWishlist(item.id)" />
                  </div>
                </div>
              </div>
              <el-empty
                v-if="!loadingWishlist && wishlists.length === 0"
                description="Chưa có sản phẩm yêu thích"
                class="profile-empty"
              />
            </div>
          </el-card>
        </main>
      </div>
    </div>

    <AppFooter />
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import AppHeader from '../components/AppHeader.vue'
import AppNavbar from '../components/AppNavbar.vue'
import AppFooter from '../components/AppFooter.vue'
import { List, SwitchButton, User, Star, Delete } from '@element-plus/icons-vue'
import { ElMessage } from 'element-plus'
import { useAuthStore } from '../stores/auth'
import { getCustomerOrders } from '../services/orderService'
import { getStatusLabel, getStatusTagType } from '../utils/orderStatus'
import { updateProfile } from '../services/userService'
import { getWishlist, toggleWishlist } from '../services/wishlistService'
import { useMobileLayout } from '../composables/useMobileLayout'

const router = useRouter()
const authStore = useAuthStore()
const { isMobile } = useMobileLayout(992)
const activeTab = ref('1')
const orders = ref([])
const loading = ref(false)
const updating = ref(false)

const profileTabs = [
  { id: '1', label: 'Đơn hàng', icon: List },
  { id: '4', label: 'Yêu thích', icon: Star },
  { id: '3', label: 'Thông tin', icon: User },
  { id: '2', label: 'Đăng xuất', icon: SwitchButton },
]

const profileForm = ref({
  id: authStore.user?.id,
  name: authStore.user?.name || '',
  phone: authStore.user?.phone || '',
  email: authStore.user?.email || '',
  address: authStore.user?.address || ''
})

const formatPrice = (val) => val ? val.toString().replace(/\B(?=(\d{3})+(?!\d))/g, '.') : '0'

const fetchOrders = async () => {
  loading.value = true
  const res = await getCustomerOrders(authStore.user.phone)
  loading.value = false
  if (res && res.success) {
    orders.value = res.data
  }
}

onMounted(async () => {
  if (!authStore.isLoggedIn) {
    router.push('/login')
    return
  }
  await fetchOrders()
  fetchWishlists()
})

const wishlists = ref([])
const loadingWishlist = ref(false)

const fetchWishlists = async () => {
  loadingWishlist.value = true
  const res = await getWishlist()
  loadingWishlist.value = false
  if (res && res.success) {
    wishlists.value = res.data
  }
}

const handleRemoveWishlist = async (productId) => {
  const res = await toggleWishlist(productId)
  if (res && res.success) {
    ElMessage.success('Đã xóa khỏi danh sách yêu thích')
    fetchWishlists()
  }
}

const handleMenuSelect = (index) => {
  if (index === '2') return
  activeTab.value = index
}

const handleUpdateProfile = async () => {
  if (!profileForm.value.name) {
    ElMessage.warning('Vui lòng nhập họ tên')
    return
  }
  updating.value = true
  const res = await updateProfile(profileForm.value)
  updating.value = false
  if (res && res.success) {
    ElMessage.success('Đã cập nhật thông tin thành công!')
    authStore.user = { ...authStore.user, ...profileForm.value }
    localStorage.setItem('user', JSON.stringify(authStore.user))
  } else {
    ElMessage.error(res?.message || 'Lỗi khi cập nhật')
  }
}

const handleLogout = () => {
  authStore.logout()
  router.push('/')
}
</script>

<style scoped>
.profile-page {
  background-color: #f7f8fa;
  min-height: 100vh;
  overflow-x: hidden;
  width: 100%;
}

.profile-container {
  width: 100%;
  max-width: 1200px;
  margin: 30px auto 50px;
  padding: 0 20px;
  box-sizing: border-box;
}

.profile-layout {
  display: grid;
  grid-template-columns: minmax(0, 280px) minmax(0, 1fr);
  gap: 20px;
  align-items: start;
  width: 100%;
}

.profile-sidebar,
.profile-main {
  min-width: 0;
  width: 100%;
}

.profile-user-block {
  text-align: center;
  padding: 20px 0;
}

.profile-user-block.is-compact {
  display: flex;
  align-items: center;
  gap: 12px;
  text-align: left;
  padding: 4px 0 12px;
}

.profile-avatar {
  background: #d8b257;
  flex-shrink: 0;
}

.profile-name {
  margin: 15px 0 5px;
  font-size: 18px;
  word-break: break-word;
}

.profile-user-block.is-compact .profile-name {
  margin: 0 0 4px;
  font-size: 16px;
  line-height: 1.3;
}

.profile-phone {
  color: #999;
  margin: 0;
  font-size: 14px;
}

.profile-user-block.is-compact .profile-phone {
  font-size: 13px;
  margin-bottom: 6px;
}

.profile-user-text {
  min-width: 0;
}

.profile-card-title {
  margin: 0;
  font-size: 18px;
}

.profile-form-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 12px;
}

.profile-form-header.is-mobile {
  flex-direction: column;
  align-items: stretch;
}

.profile-form-header.is-mobile .el-button {
  width: 100%;
}

.profile-form-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 0 20px;
}

.gold-text {
  color: #d8b257;
  font-weight: bold;
}

.order-product-line {
  font-size: 13px;
  margin-bottom: 5px;
  line-height: 1.4;
}

.wishlist-thumb {
  width: 60px;
  height: 60px;
  object-fit: cover;
  border-radius: 4px;
}

.profile-empty {
  padding: 40px 0;
}

.profile-menu-mobile {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 6px;
  border-top: 1px solid #eee;
  padding-top: 12px;
}

.profile-tab-btn {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 4px;
  padding: 8px 4px;
  border: 1px solid #eaeaea;
  border-radius: 8px;
  background: #fff;
  color: #555;
  font-size: 10px;
  line-height: 1.2;
  cursor: pointer;
  min-width: 0;
}

.profile-tab-btn .el-icon {
  font-size: 18px;
}

.profile-tab-btn.active {
  border-color: #d8b257;
  background: #fdf8ee;
  color: #9a7b2a;
  font-weight: 600;
}

.orders-mobile {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.order-mobile-card {
  background: #fafafa;
  border: 1px solid #eee;
  border-radius: 8px;
  padding: 12px;
}

.order-mobile-head {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 8px;
  margin-bottom: 6px;
}

.order-mobile-date {
  font-size: 12px;
  color: #888;
  margin-bottom: 8px;
}

.order-mobile-foot {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding-top: 8px;
  border-top: 1px dashed #e0e0e0;
  font-size: 14px;
}

.wishlist-mobile {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.wishlist-mobile-card {
  display: flex;
  gap: 12px;
  padding: 12px;
  background: #fafafa;
  border: 1px solid #eee;
  border-radius: 8px;
}

.wishlist-mobile-img {
  width: 72px;
  height: 72px;
  border-radius: 6px;
  flex-shrink: 0;
}

.wishlist-mobile-info {
  flex: 1;
  min-width: 0;
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.wishlist-mobile-name {
  font-size: 14px;
  font-weight: 600;
  line-height: 1.35;
  word-break: break-word;
}

.wishlist-mobile-actions {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  margin-top: auto;
}

:deep(.profile-content-card),
:deep(.profile-sidebar-card) {
  width: 100%;
  max-width: 100%;
  box-sizing: border-box;
}

:deep(.profile-content-card .el-card__body),
:deep(.profile-sidebar-card .el-card__body) {
  overflow-x: hidden;
}

@media (max-width: 992px) {
  .profile-container {
    margin-top: 16px;
    margin-bottom: 32px;
    padding: 0 12px;
  }

  .profile-layout {
    grid-template-columns: minmax(0, 1fr);
    gap: 12px;
  }

  :deep(.profile-content-card .el-card__header),
  :deep(.profile-sidebar-card .el-card__body) {
    padding: 12px 14px;
  }

  :deep(.profile-content-card .el-card__body) {
    padding: 12px 14px;
  }

  .profile-card-title {
    font-size: 16px;
  }

  .profile-form-grid {
    grid-template-columns: 1fr;
    gap: 0;
  }
}
</style>
