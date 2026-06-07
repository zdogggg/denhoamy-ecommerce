<template>
  <div class="payment-result-wrapper">
    <AppHeader />
    <AppNavbar />

    <div class="container main-content">
      <!-- Đang xác minh thanh toán -->
      <div v-if="loading" class="result-card loading-card">
        <el-icon class="loading-icon is-loading" :size="48"><Loading /></el-icon>
        <h2>Đang xác minh thanh toán...</h2>
        <p class="result-desc">Vui lòng đợi trong giây lát, hệ thống đang kiểm tra trạng thái đơn hàng.</p>
      </div>

      <!-- Thanh toán thành công (đã verify qua API) -->
      <div v-else-if="isSuccess" class="result-card success-card">
        <div class="result-icon success-icon">
          <el-icon :size="64"><CircleCheck /></el-icon>
        </div>
        <h2>Thanh toán thành công!</h2>
        <p class="result-desc">Đơn hàng của bạn đã được xác nhận và thanh toán thành công.</p>
        <div class="order-code">
          <span>Mã đơn hàng:</span>
          <strong>#ORD-{{ orderId }}</strong>
        </div>
        <p class="result-note">Chúng tôi sẽ sớm liên hệ với bạn để xác nhận giao hàng.</p>
        <el-button type="primary" size="large" class="btn-home" @click="$router.push('/')">
          Quay về trang chủ
        </el-button>
      </div>

      <!-- Webhook chưa kịp xử lý -->
      <div v-else-if="isPendingConfirm" class="result-card pending-card">
        <div class="result-icon pending-icon">
          <el-icon class="is-loading" :size="64"><Loading /></el-icon>
        </div>
        <h2>Đang chờ xác nhận thanh toán</h2>
        <p class="result-desc">
          Thanh toán của bạn có thể đã được ghi nhận. Hệ thống đang chờ xác nhận từ ngân hàng.
        </p>
        <div class="order-code">
          <span>Mã đơn hàng:</span>
          <strong>#ORD-{{ orderId }}</strong>
        </div>
        <p class="result-note">Nếu đã thanh toán, vui lòng đợi thêm vài phút hoặc liên hệ shop để được hỗ trợ.</p>
        <div class="action-row">
          <el-button type="primary" size="large" class="btn-home" :loading="retrying" @click="retryCheck">
            Kiểm tra lại
          </el-button>
          <el-button size="large" @click="$router.push('/')">Quay về trang chủ</el-button>
        </div>
      </div>

      <!-- Thanh toán bị hủy / thất bại -->
      <div v-else class="result-card cancel-card">
        <div class="result-icon cancel-icon">
          <el-icon :size="64"><CircleClose /></el-icon>
        </div>
        <h2>Thanh toán chưa hoàn tất</h2>
        <p class="result-desc">Đơn hàng <strong>#ORD-{{ orderId }}</strong> chưa được thanh toán.</p>
        <p class="result-note">
          Giỏ hàng vẫn được giữ. Thanh toán lại sẽ dùng cùng đơn này, không tạo đơn mới.
        </p>
        <div class="action-row">
          <el-button
            type="primary"
            size="large"
            class="btn-home"
            :loading="retryingPayos"
            @click="retryPayosCheckout"
          >
            Thanh toán lại đơn này
          </el-button>
          <el-button size="large" @click="$router.push('/')">
            Quay về trang chủ
          </el-button>
          <el-button size="large" @click="$router.push('/cart')">
            Quay lại giỏ hàng
          </el-button>
        </div>
      </div>
    </div>

    <AppFooter />
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import { useRoute } from 'vue-router'
import { CircleCheck, CircleClose, Loading } from '@element-plus/icons-vue'
import { ElMessage } from 'element-plus'
import AppHeader from '../components/AppHeader.vue'
import AppNavbar from '../components/AppNavbar.vue'
import AppFooter from '../components/AppFooter.vue'
import { getPaymentStatus, retryPayosPayment } from '../services/orderService'
import { useCartStore } from '../stores/cart'
import { clearPayosPendingOrderId, setPayosPendingOrderId } from '../utils/payosPending'

const route = useRoute()
const cartStore = useCartStore()

const orderId = computed(() => route.query.orderId || '---')
const isSuccessRoute = computed(() => route.name === 'payment-success')

const loading = ref(true)
const retrying = ref(false)
const retryingPayos = ref(false)
const paymentData = ref(null)

const isSuccess = computed(() => isSuccessRoute.value && paymentData.value?.isPaid === true)
const isPendingConfirm = computed(() =>
  isSuccessRoute.value && !paymentData.value?.isPaid && paymentData.value?.isPending === true
)

const POLL_INTERVAL_MS = 2000
const MAX_POLL_ATTEMPTS = 5

const checkPaymentStatus = async () => {
  const id = route.query.orderId
  if (!id) {
    paymentData.value = { isPaid: false, isPending: false, isCancelled: true }
    return
  }

  const result = await getPaymentStatus(id)
  if (result?.success) {
    paymentData.value = result
    return
  }

  paymentData.value = { isPaid: false, isPending: false, isCancelled: false }
}

const pollUntilConfirmed = async () => {
  for (let attempt = 0; attempt < MAX_POLL_ATTEMPTS; attempt++) {
    await checkPaymentStatus()
    if (paymentData.value?.isPaid || !paymentData.value?.isPending) {
      break
    }
    if (attempt < MAX_POLL_ATTEMPTS - 1) {
      await new Promise((resolve) => setTimeout(resolve, POLL_INTERVAL_MS))
    }
  }
}

const retryCheck = async () => {
  retrying.value = true
  await pollUntilConfirmed()
  retrying.value = false
}

const retryPayosCheckout = async () => {
  const id = route.query.orderId
  if (!id) return

  retryingPayos.value = true
  const result = await retryPayosPayment(id)
  retryingPayos.value = false

  if (result?.success && result.checkoutUrl) {
    setPayosPendingOrderId(id)
    window.location.href = result.checkoutUrl
    return
  }
  ElMessage.error(result?.message || 'Không thể tạo lại link thanh toán')
}

watch(
  () => paymentData.value?.isPaid,
  async (isPaid) => {
    if (isPaid) {
      clearPayosPendingOrderId()
      await cartStore.clearCart()
    }
  }
)

onMounted(async () => {
  if (isSuccessRoute.value) {
    await pollUntilConfirmed()
  } else {
    await checkPaymentStatus()
    if (paymentData.value?.isPaid) {
      window.location.href = `/payment/success?orderId=${route.query.orderId}`
      return
    }
  }
  loading.value = false
})
</script>

<style scoped>
.payment-result-wrapper { background-color: #f7f8fa; min-height: 100vh; }
.container { width: 1200px; margin: 0 auto; max-width: 100%; padding: 0 20px; box-sizing: border-box; }
.main-content { padding: 60px 0; display: flex; justify-content: center; }

.result-card {
  background: #fff;
  border-radius: 16px;
  box-shadow: 0 4px 24px rgba(0,0,0,0.08);
  padding: 50px 40px;
  text-align: center;
  max-width: 500px;
  width: 100%;
}

.loading-card .loading-icon,
.pending-icon { color: #D8B257; margin-bottom: 20px; display: block; }

.result-icon { margin-bottom: 20px; }
.success-icon { color: #67C23A; }
.cancel-icon { color: #F56C6C; }

.result-card h2 {
  font-size: 24px;
  color: #222;
  margin: 0 0 10px 0;
}

.result-desc {
  font-size: 15px;
  color: #666;
  margin: 0 0 20px 0;
  line-height: 1.6;
}

.order-code {
  background: #f5f7fa;
  padding: 15px 25px;
  border-radius: 8px;
  margin: 20px 0;
  font-size: 16px;
}
.order-code span { color: #888; margin-right: 8px; }
.order-code strong { color: #67C23A; font-size: 22px; }

.pending-card .order-code strong { color: #D8B257; }

.result-note {
  font-size: 13px;
  color: #999;
  margin-bottom: 25px;
}

.action-row {
  display: flex;
  gap: 15px;
  justify-content: center;
  flex-wrap: wrap;
}

.btn-home {
  background-color: #111 !important;
  color: #D8B257 !important;
  font-weight: bold;
  border: none !important;
  padding: 12px 35px !important;
}
.btn-home:hover { background-color: #222 !important; }

.cancel-card .order-code strong { color: #F56C6C; }
</style>
