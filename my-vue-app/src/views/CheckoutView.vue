<template>
  <div class="checkout-wrapper">
    <AppHeader />
    <AppNavbar />

    <div class="container main-content">
      <el-breadcrumb :separator-icon="ArrowRight" class="breadcrumb-custom">
        <el-breadcrumb-item :to="{ path: '/' }">Trang chủ</el-breadcrumb-item>
        <el-breadcrumb-item :to="{ path: '/cart' }">Giỏ hàng</el-breadcrumb-item>
        <el-breadcrumb-item>Thanh toán</el-breadcrumb-item>
      </el-breadcrumb>

      <div class="checkout-header-title">
        <h2>THÔNG TIN THANH TOÁN</h2>
      </div>

      <el-row :gutter="30">
        <el-col :xs="24" :lg="14">
          <div class="checkout-section">
            <h3 class="section-title">1. Phương thức nhận hàng</h3>
            <div class="delivery-methods">
              <div 
                :class="['delivery-card', { active: checkoutForm.deliveryMethod === 'home' }]" 
                @click="checkoutForm.deliveryMethod = 'home'"
              >
                <el-icon :size="24"><Van /></el-icon>
                <span>Giao hàng tận nhà</span>
              </div>
              <div 
                :class="['delivery-card', { active: checkoutForm.deliveryMethod === 'store' }]" 
                @click="checkoutForm.deliveryMethod = 'store'"
              >
                <el-icon :size="24"><Box /></el-icon>
                <span>Nhận hàng tại cửa hàng</span>
              </div>
            </div>

            <el-collapse-transition>
              <div v-if="checkoutForm.deliveryMethod === 'home'" class="delivery-address-form">
                <el-form :model="checkoutForm" :rules="rules" ref="formRef" label-position="top">
                  <el-row :gutter="20">
                    <el-col :xs="24" :sm="12">
                      <el-form-item label="Họ và tên *" prop="name">
                        <el-input v-model="checkoutForm.name" placeholder="Nhập họ tên người nhận" size="large" />
                      </el-form-item>
                    </el-col>
                    <el-col :xs="24" :sm="12">
                      <el-form-item label="Số điện thoại *" prop="phone">
                        <el-input v-model="checkoutForm.phone" placeholder="VD: 0912345678" size="large" />
                      </el-form-item>
                    </el-col>
                  </el-row>
                  <el-form-item label="Địa chỉ Email" prop="email">
                    <el-input v-model="checkoutForm.email" placeholder="example@gmail.com" size="large" />
                  </el-form-item>
                  <el-form-item label="Địa chỉ giao hàng chi tiết *" prop="address">
                    <el-input v-model="checkoutForm.address" placeholder="Số nhà, tên đường, phường/xã, quận/huyện, tỉnh/thành phố" size="large" />
                  </el-form-item>
                  <el-form-item label="Ghi chú đơn hàng (Tùy chọn)">
                    <el-input v-model="checkoutForm.note" type="textarea" rows="3" placeholder="Ghi chú về thời gian giao hàng, chỉ dẫn địa điểm..." />
                  </el-form-item>
                </el-form>
              </div>

              <!-- Store pickup panel -->
              <div v-else class="store-pickup-panel">
                <div class="store-info-card">
                  <div class="store-header-info">
                    <el-radio v-model="selectedStore" label="store1" size="large">
                      <span class="store-title">Đèn Hoa Mỹ Shop</span>
                      <p class="store-address">905 Nguyễn Văn Linh, An Biên, Hải Phòng</p>
                    </el-radio>
                  </div>
                </div>

                <el-form :model="checkoutForm" :rules="rules" ref="formRef" label-position="top" style="margin-top: 20px;">
                  <el-row :gutter="20">
                    <el-col :xs="24" :sm="12">
                      <el-form-item label="Họ và tên người nhận *" prop="name">
                        <el-input v-model="checkoutForm.name" placeholder="Nhập họ tên người nhận" size="large" />
                      </el-form-item>
                    </el-col>
                    <el-col :xs="24" :sm="12">
                      <el-form-item label="Số điện thoại người nhận *" prop="phone">
                        <el-input v-model="checkoutForm.phone" placeholder="VD: 0912345678" size="large" />
                      </el-form-item>
                    </el-col>
                  </el-row>
                  <el-form-item label="Địa chỉ Email" prop="email">
                    <el-input v-model="checkoutForm.email" placeholder="example@gmail.com" size="large" />
                  </el-form-item>
                  <el-form-item label="Ghi chú nhận hàng (Tùy chọn)">
                    <el-input v-model="checkoutForm.note" type="textarea" rows="3" placeholder="Thời gian bạn dự kiến tới nhận..." />
                  </el-form-item>
                </el-form>
              </div>
            </el-collapse-transition>
          </div>

          <div class="checkout-section">
            <h3 class="section-title">2. Phương thức thanh toán</h3>
            <el-radio-group v-model="checkoutForm.paymentMethod" class="payment-methods">
              <el-radio v-if="checkoutForm.deliveryMethod === 'home'" value="cod" border class="payment-option">
                <div class="payment-content">
                  <el-icon :size="24" color="#D8B257"><Money /></el-icon>
                  <div>
                    <strong>Thanh toán khi nhận hàng (COD)</strong>
                    <p>Khách hàng thanh toán bằng tiền mặt khi shipper giao hàng tới.</p>
                  </div>
                </div>
              </el-radio>
              <el-radio v-if="checkoutForm.deliveryMethod === 'store'" value="pay_at_store" border class="payment-option">
                <div class="payment-content">
                  <el-icon :size="24" color="#D8B257"><Money /></el-icon>
                  <div>
                    <strong>Thanh toán tại cửa hàng</strong>
                    <p>Thanh toán tiền mặt hoặc chuyển khoản khi đến nhận. Vui lòng mang theo mã đơn hàng.</p>
                  </div>
                </div>
              </el-radio>
              <el-radio value="payos" border class="payment-option">
                <div class="payment-content">
                  <el-icon :size="24" color="#D8B257"><CreditCard /></el-icon>
                  <div>
                    <strong>Thanh toán trực tuyến (PayOS)</strong>
                    <p>Thanh toán nhanh chóng qua cổng PayOS — hỗ trợ QR Code, ví điện tử và thẻ ngân hàng.</p>
                  </div>
                </div>
              </el-radio>
            </el-radio-group>
          </div>
        </el-col>

        <el-col :xs="24" :lg="10">
          <div class="order-summary-box">
            <h3 class="section-title">Đơn hàng của bạn</h3>
            
            <div v-if="cartStore.items.length === 0" style="text-align: center; padding: 20px;">
              <el-empty description="Giỏ hàng trống" :image-size="60" />
            </div>

            <div class="checkout-items" v-else>
              <div v-for="item in cartStore.items" :key="item.id" class="checkout-item">
                <el-image :src="item.image" class="item-img" fit="cover" />
                <div class="item-info">
                  <div class="item-name">{{ item.name }}</div>
                  <div class="item-qty">Số lượng: {{ item.quantity }}</div>
                </div>
                <div class="item-price">{{ formatPrice(item.price * item.quantity) }}đ</div>
              </div>
            </div>

            <el-divider border-style="dashed" />

            <div class="coupon-section" style="margin-bottom: 20px;">
              <p style="margin: 0 0 10px 0; font-size: 14px; font-weight: bold;">Mã giảm giá</p>
              
              <div v-if="!appliedCoupon" style="display: flex; gap: 10px;">
                <el-button type="primary" @click="openCouponDialog" style="width: 100%; border-style: dashed; background-color: #fdfaf2; color: #C19A44; border-color: #D8B257;">
                   <el-icon style="margin-right: 5px;"><Ticket /></el-icon> Chọn hoặc nhập mã giảm giá
                </el-button>
              </div>

              <div v-else style="display: flex; gap: 10px; align-items: center; border: 1px solid #67C23A; padding: 10px; border-radius: 4px; background-color: #f0f9eb;">
                <el-icon style="color: #67C23A; font-size: 20px;"><CircleCheck /></el-icon> 
                <span style="flex: 1; font-size: 13px;">Đã áp dụng mã <strong>{{ appliedCoupon.code }}</strong> (Giảm -{{ formatPrice(appliedCoupon.discount_amount) }}đ)</span>
                <el-button type="danger" link @click="cancelCoupon">Hủy</el-button>
              </div>
            </div>

            <div class="summary-row">
              <span>Tạm tính:</span>
              <strong>{{ formatPrice(cartStore.cartTotal) }}đ</strong>
            </div>
            <div class="summary-row">
              <span>Phí vận chuyển:</span>
              <span>Miễn phí</span>
            </div>
            <div class="summary-row" v-if="appliedCoupon" style="color: #f56c6c;">
              <span>Mã giảm giá ({{ appliedCoupon.code }}):</span>
              <strong>- {{ formatPrice(appliedCoupon.discount_amount) }}đ</strong>
            </div>
            
            <el-divider border-style="dashed" />
            
            <div class="summary-row total-row">
              <span>TỔNG CỘNG:</span>
              <span class="final-price">{{ formatPrice(finalTotal) }}đ</span>
            </div>

            <el-button class="btn-place-order" size="large" @click="handlePlaceOrder" :disabled="cartStore.items.length === 0">
              ĐẶT HÀNG NGAY
            </el-button>
            <p class="terms-note">Bằng việc tiến hành đặt hàng, bạn đồng ý với Điều khoản và Chính sách của Đèn Hoa Mỹ.</p>
          </div>
        </el-col>
      </el-row>
    </div>

    <AppFooter />

    <!-- Coupon Dialog -->
    <el-dialog v-model="couponDialogVisible" title="Chọn mã giảm giá" width="450px" class="coupon-dialog" align-center>
      <div style="display: flex; gap: 10px; margin-bottom: 20px;">
         <el-input v-model="couponCodeInput" placeholder="Nhập mã giảm giá..." style="text-transform: uppercase;" @keyup.enter="handleApplyCoupon(couponCodeInput)" />
         <el-button type="primary" @click="handleApplyCoupon(couponCodeInput)" :loading="isApplyingCoupon">Áp dụng</el-button>
      </div>
      
      <div v-if="loadingCoupons" style="text-align: center; padding: 20px;">
         <el-icon class="is-loading" :size="24" color="#D8B257"><Loading /></el-icon>
      </div>
      <div v-else class="coupons-list">
         <p v-if="availableCoupons.length === 0" style="text-align: center; color: #999;">Hiện chưa có mã giảm giá nào phù hợp với đơn hàng của bạn.</p>
         <div v-for="coupon in availableCoupons" :key="coupon.id" class="coupon-card">
            <div class="coupon-icon-box">
              <el-icon :size="24"><Ticket /></el-icon>
            </div>
            <div class="coupon-content">
               <div class="coupon-title">Mã: <strong>{{ coupon.code }}</strong></div>
               <div class="coupon-desc">
                 <template v-if="Number(coupon.discount_percent) > 0">
                   <strong style="color: #d93025;">Giảm {{ coupon.discount_percent }}%</strong>
                   <span v-if="Number(coupon.max_discount_amount) > 0">
                     · Giảm tối đa {{ formatPrice(coupon.max_discount_amount) }}đ
                   </span>
                 </template>
                 <strong v-else style="color: #d93025;">Giảm {{ formatPrice(coupon.discount_amount) }}đ</strong>
               </div>
               <div class="coupon-meta">
                 Đơn tối thiểu {{ formatPrice(coupon.min_order_value || 0) }}đ
                 <template v-if="coupon.usage_limit > 0">
                   · Đã dùng {{ Math.round((coupon.used_count / coupon.usage_limit) * 100) }}%
                 </template>
               </div>
               <div class="coupon-expiry" v-if="coupon.end_date">HSD: {{ new Date(coupon.end_date).toLocaleDateString('vi-VN') }}</div>
            </div>
            <el-button 
              type="success" 
              size="small" 
              @click="handleApplyCoupon(coupon.code)" 
              :loading="isApplyingCoupon"
            >
              Chọn
            </el-button>
         </div>
      </div>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onBeforeUnmount, watch } from 'vue'
import { useRouter, onBeforeRouteLeave } from 'vue-router'
import { Money, CreditCard, CircleCheck, ArrowRight, Van, Box, Ticket, Loading } from '@element-plus/icons-vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import AppHeader from '../components/AppHeader.vue'
import AppNavbar from '../components/AppNavbar.vue'
import AppFooter from '../components/AppFooter.vue'
import { useCartStore } from '../stores/cart'
import { createOrder, getPendingPayosOrder, retryPayosPayment, cancelPendingOrder, getPaymentStatus } from '../services/orderService'
import { setPayosPendingOrderId, getPayosPendingOrderId, clearPayosPendingOrderId } from '../utils/payosPending'
import { toastInfo } from '../utils/toast'
import { applyCoupon, getPublicCoupons } from '../services/couponService'
import { formatPrice } from '../utils/format'
import { useAuthStore } from '../stores/auth'

const router = useRouter()
const cartStore = useCartStore()
const authStore = useAuthStore()
const formRef = ref(null)
const selectedStore = ref('store1')
const orderCompleted = ref(false) // Flag: đơn hàng đã hoàn tất, không cần xác nhận khi rời trang
const checkoutBlocked = ref(false)

const checkoutForm = ref({
  name: '',
  phone: '',
  email: '',
  address: '',
  note: '',
  paymentMethod: 'cod',
  deliveryMethod: 'home'
})

// Guard trình duyệt: hỏi khi user đóng tab / refresh trang
const handleBeforeUnload = (e) => {
  if (!orderCompleted.value && cartStore.items.length > 0) {
    e.preventDefault()
    e.returnValue = ''
  }
}

onMounted(async () => {
  await syncCartPrices()
  if (authStore.user) {
    checkoutForm.value.name = authStore.user.name || ''
    checkoutForm.value.phone = authStore.user.phone || ''
    checkoutForm.value.email = authStore.user.email || ''
    checkoutForm.value.address = authStore.user.address || ''
  }
  const canCheckout = await resolvePendingPayosOnMount()
  if (!canCheckout) {
    ElMessage.info('Bạn có đơn PayOS chưa thanh toán. Hãy xử lý đơn cũ trước khi đặt mới.')
  }
  window.addEventListener('beforeunload', handleBeforeUnload)
})

const showPendingPayosDialog = async (pendingId) => {
  try {
    await ElMessageBox.confirm(
      `Bạn có đơn PayOS #ORD-${pendingId} chưa thanh toán. Giỏ hàng vẫn được giữ — bạn có thể thanh toán lại cùng đơn này hoặc hủy để đặt đơn mới.`,
      'Đơn thanh toán đang chờ',
      {
        distinguishCancelAndClose: true,
        confirmButtonText: 'Thanh toán lại',
        cancelButtonText: 'Hủy đơn cũ',
        type: 'warning',
      }
    )

    const retry = await retryPayosPayment(pendingId)
    if (retry?.success && retry.checkoutUrl) {
      setPayosPendingOrderId(pendingId)
      orderCompleted.value = true
      window.location.href = retry.checkoutUrl
      return false
    }
    ElMessage.error(retry?.message || 'Không thể tạo lại link thanh toán')
    return false
  } catch (action) {
    if (action === 'cancel') {
      const cancelled = await cancelPendingOrder(pendingId)
      if (cancelled?.success) {
        clearPayosPendingOrderId()
        ElMessage.success('Đã hủy đơn cũ. Bạn có thể đặt hàng mới.')
        return true
      }
      ElMessage.error(cancelled?.message || 'Không thể hủy đơn')
      return false
    }
    return false
  }
}

const resolvePendingPayosOnMount = async () => {
  if (!authStore.user) return true

  let pendingId = null
  const apiResult = await getPendingPayosOrder()
  if (apiResult?.success && apiResult.data?.id) {
    pendingId = apiResult.data.id
  } else {
    const stored = getPayosPendingOrderId()
    if (stored) {
      const status = await getPaymentStatus(stored)
      if (status?.success && status.isPending && !status.isPaid) {
        pendingId = Number(stored)
      } else {
        clearPayosPendingOrderId()
      }
    }
  }

  if (!pendingId) return true

  const canContinue = await showPendingPayosDialog(pendingId)
  checkoutBlocked.value = !canContinue
  return canContinue
}

const validatePhone = (rule, value, callback) => {
  if (!/^(0[3|5|7|8|9])+([0-9]{8})\b/.test(value)) {
    callback(new Error('Số điện thoại không hợp lệ'))
  } else {
    callback()
  }
}

const validateEmail = (rule, value, callback) => {
  if (value && !/^[\w.-]+@[\w.-]+\.\w+$/.test(value)) {
    callback(new Error('Email không hợp lệ'))
  } else {
    callback()
  }
}

const validateAddress = (rule, value, callback) => {
  if (checkoutForm.value.deliveryMethod === 'home' && !value) {
    callback(new Error('Vui lòng nhập địa chỉ giao hàng'))
  } else {
    callback()
  }
}

const rules = {
  name: [{ required: true, message: 'Vui lòng nhập họ tên', trigger: 'blur' }],
  phone: [
    { required: true, message: 'Vui lòng nhập số điện thoại', trigger: 'blur' },
    { validator: validatePhone, trigger: 'blur' }
  ],
  email: [{ validator: validateEmail, trigger: 'blur' }],
  address: [{ validator: validateAddress, trigger: 'blur' }]
}




const couponCodeInput = ref('')
const appliedCoupon = ref(null)
const isApplyingCoupon = ref(false)
const couponDialogVisible = ref(false)
const availableCoupons = ref([])
const loadingCoupons = ref(false)

/** Payload giỏ — server tính tạm tính giống lúc tạo đơn */
const cartItemsForApi = () =>
  cartStore.items.map((item) => ({
    id: item.id,
    name: item.name,
    quantity: item.quantity,
    price: item.price,
  }))

const syncCartPrices = async () => {
  const { updated } = await cartStore.syncPricesFromServer()
  if (!updated) return

  toastInfo('Giá trong giỏ đã được cập nhật theo ưu đãi mới.')

  if (appliedCoupon.value) {
    const res = await applyCoupon(appliedCoupon.value.code, { items: cartItemsForApi() })
    if (res?.success) {
      appliedCoupon.value = res.data
    } else {
      appliedCoupon.value = null
      ElMessage.warning(res?.message || 'Mã giảm giá không còn áp dụng được, đã gỡ mã.')
    }
  }
}

const finalTotal = computed(() => {
  let rawTotal = cartStore.cartTotal
  if (appliedCoupon.value) {
    return Math.max(0, rawTotal - appliedCoupon.value.discount_amount)
  }
  return rawTotal
})

const openCouponDialog = async () => {
  couponDialogVisible.value = true
  couponCodeInput.value = ''
  loadingCoupons.value = true
  
  const res = await getPublicCoupons()
  loadingCoupons.value = false
  if (!res) {
    ElMessage.error('Không tải được danh sách mã giảm giá. Vui lòng thử lại.')
    return
  }
  if (!res.success) {
    ElMessage.error(res.message || 'Không tải được danh sách mã giảm giá.')
    return
  }
  const today = new Date().toISOString().split('T')[0]
  availableCoupons.value = (res.data || []).filter(c => {
    if (Number(c.is_active) !== 1) return false
    if (cartStore.cartTotal < Number(c.min_order_value)) return false
    if (c.usage_limit > 0 && c.used_count >= c.usage_limit) return false
    if (c.start_date && today < c.start_date) return false
    if (c.end_date && today > c.end_date) return false
    if (Number(c.discount_percent) > 0 && Number(c.max_discount_amount) <= 0) return false
    return true
  })
}

const handleApplyCoupon = async (code = null) => {
  const codeToApply = typeof code === 'string' ? code : couponCodeInput.value
  if (!codeToApply || !codeToApply.trim()) return ElMessage.warning('Vui lòng nhập mã giảm giá')
  
  isApplyingCoupon.value = true
  const res = await applyCoupon(codeToApply.trim(), { items: cartItemsForApi() })
  isApplyingCoupon.value = false
  if (res && res.success) {
    appliedCoupon.value = res.data
    couponDialogVisible.value = false
    ElMessage.success(res.message)
  } else {
    ElMessage.error(res?.message || 'Mã giảm giá không hợp lệ')
  }
}

const cancelCoupon = () => {
  appliedCoupon.value = null
  couponCodeInput.value = ''
  ElMessage.info('Đã hủy sử dụng mã giảm giá')
}

watch(
  () => cartStore.items.map((i) => `${i.id}:${i.quantity}:${i.price}`).join('|'),
  async () => {
    if (!appliedCoupon.value || orderCompleted.value || cartStore.items.length === 0) return
    const code = appliedCoupon.value.code
    const res = await applyCoupon(code, { items: cartItemsForApi() })
    if (res?.success) {
      appliedCoupon.value = res.data
    } else {
      appliedCoupon.value = null
      ElMessage.warning(res?.message || 'Mã giảm giá không còn áp dụng được, đã gỡ mã.')
    }
  }
)

watch(
  () => checkoutForm.value.deliveryMethod,
  (method) => {
    const payment = checkoutForm.value.paymentMethod
    if (method === 'store' && payment === 'cod') {
      checkoutForm.value.paymentMethod = 'pay_at_store'
    } else if (method === 'home' && payment === 'pay_at_store') {
      checkoutForm.value.paymentMethod = 'cod'
    }
  }
)

const handlePlaceOrder = async () => {
  formRef.value?.validate(async (valid) => {
    if (!valid) {
      ElMessage.error('Vui lòng điền đầy đủ thông tin!')
      return
    }

    if (cartStore.items.length === 0) {
      ElMessage.error('Giỏ hàng trống!')
      return
    }

    if (checkoutBlocked.value) {
      ElMessage.warning('Vui lòng xử lý đơn PayOS chưa thanh toán trước khi đặt đơn mới.')
      return
    }

    await syncCartPrices()

    if (appliedCoupon.value) {
      const couponCheck = await applyCoupon(appliedCoupon.value.code, { items: cartItemsForApi() })
      if (!couponCheck?.success) {
        appliedCoupon.value = null
        ElMessage.error(couponCheck?.message || 'Mã giảm giá không còn áp dụng được với đơn hàng hiện tại.')
        return
      }
      appliedCoupon.value = couponCheck.data
    }

    const orderData = {
      user_id: authStore.user?.id || null,
      name: checkoutForm.value.name,
      phone: checkoutForm.value.phone,
      email: checkoutForm.value.email,
      deliveryMethod: checkoutForm.value.deliveryMethod,
      address: checkoutForm.value.deliveryMethod === 'store' ? 'Nhận hàng tại cửa hàng: 905 Nguyễn Văn Linh, An Biên, Hải Phòng' : checkoutForm.value.address,
      note: checkoutForm.value.note,
      paymentMethod: checkoutForm.value.paymentMethod,
      total: finalTotal.value,
      couponCode: appliedCoupon.value?.code || null,
      discountAmount: appliedCoupon.value?.discount_amount || 0,
      items: cartItemsForApi()
    }

    const result = await createOrder(orderData)

    if (result?.httpStatus === 409 && result.pendingOrderId) {
      const canContinue = await showPendingPayosDialog(result.pendingOrderId)
      checkoutBlocked.value = !canContinue
      return
    }

    if (result && result.success) {
      orderCompleted.value = true // Đánh dấu đã đặt hàng thành công → không hỏi khi rời trang

      // PayOS: redirect thẳng sang cổng thanh toán (giữ giỏ đến khi xác nhận thanh toán)
      if (result.checkoutUrl) {
        appliedCoupon.value = null
        setPayosPendingOrderId(result.orderId)
        window.location.href = result.checkoutUrl
        return
      }
      const isStorePickup = checkoutForm.value.deliveryMethod === 'store'
      const isPayAtStore = checkoutForm.value.paymentMethod === 'pay_at_store'
      const followUpMessage = isStorePickup && isPayAtStore
        ? 'Vui lòng mang mã đơn và số điện thoại đăng ký đến cửa hàng để thanh toán và nhận hàng.'
        : isStorePickup
          ? 'Chúng tôi sẽ chuẩn bị hàng. Bạn có thể đến cửa hàng nhận sau khi được xác nhận.'
          : 'Chúng tôi sẽ sớm liên hệ với bạn để xác nhận giao hàng.'

      const htmlMessage = `
          <div style="text-align: center;">
            <p style="font-size: 15px;">Đơn hàng của bạn đã được ghi nhận thành công.</p>
            <p style="font-size: 20px; font-weight: bold; color: #67C23A; margin: 10px 0;">#ORD-${result.orderId}</p>
            <p style="font-size: 13px; color: #666;">${followUpMessage}</p>
          </div>
        `

      ElMessageBox.alert(
        htmlMessage,
        'Đặt hàng thành công!',
        {
          dangerouslyUseHTMLString: true,
          confirmButtonText: 'Quay về trang chủ',
          center: true,
          showClose: false,
          customStyle: { maxWidth: '450px' },
          callback: () => {
            appliedCoupon.value = null
            cartStore.clearCart()
            router.push('/')
          },
        }
      )
    } else {
      ElMessage.error(result?.message || 'Có lỗi xảy ra khi tạo đơn hàng!')
    }
  })
}

// ====== XÁC NHẬN TRƯỚC KHI RỜI TRANG CHECKOUT ======
// Guard Vue Router: hỏi khi user click link chuyển trang
onBeforeRouteLeave((to, from, next) => {
  // Bỏ qua nếu đã đặt hàng xong hoặc giỏ trống
  if (orderCompleted.value || cartStore.items.length === 0) {
    return next()
  }
  // Hỏi xác nhận
  ElMessageBox.confirm(
    'Bạn đang có sản phẩm trong giỏ hàng. Bạn có chắc muốn rời trang thanh toán?',
    'Xác nhận rời trang',
    {
      confirmButtonText: 'Rời trang',
      cancelButtonText: 'Ở lại',
      type: 'warning',
    }
  ).then(() => next())
   .catch(() => next(false))
})

onBeforeUnmount(() => {
  window.removeEventListener('beforeunload', handleBeforeUnload)
})
</script>

<style scoped>
/* --- 1. Cấu trúc nền và khung chứa --- */
.checkout-wrapper { background-color: #f7f8fa; min-height: 100vh; }
.container { width: 1200px; margin: 0 auto; max-width: 100%; padding: 0 20px; box-sizing: border-box; }
.breadcrumb-custom { padding: 15px 0; font-size: 13px; margin-bottom: 10px; }

/* Tiêu đề trang */
.checkout-header-title { margin-bottom: 25px; }
.checkout-header-title h2 { font-size: 22px; color: #222; margin: 0; font-weight: 600; }

/* Các khối nội dung (Section) */
.checkout-section { background-color: #fff; padding: 25px; border-radius: 8px; box-shadow: 0 2px 12px 0 rgba(0,0,0,0.05); margin-bottom: 20px; }
.section-title { margin: 0 0 20px 0; font-size: 18px; color: #333; border-bottom: 1px solid #eee; padding-bottom: 10px; }

/* Delivery Cards */
.delivery-methods { display: flex; gap: 15px; margin-bottom: 25px; }
.delivery-card { flex: 1; display: flex; align-items: center; justify-content: center; gap: 10px; padding: 15px; border: 1.5px solid #dcdfe6; border-radius: 8px; font-weight: bold; font-size: 15px; cursor: pointer; transition: all 0.3s; background:#fafafa; color: #555; }
.delivery-card .el-icon { color: #888; transition: color 0.3s; }
.delivery-card:hover { border-color: #D8B257; background: #fffdf9; }
.delivery-card.active { border-color: #D8B257; background: #fffdf9; color: #D8B257; }
.delivery-card.active .el-icon { color: #D8B257; }

/* In-store Pickup */
.store-pickup-panel { background: #f4f6fb; padding: 20px; border-radius: 8px; border: 1.5px solid #e4e7ed; }
.store-info-card { background: #fff; padding: 15px; border: 1px solid #dcdfe6; border-radius: 6px; box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05); }
.store-header-info { display: flex; align-items: flex-start; justify-content: flex-start; }
.store-title { font-weight: bold; font-size: 15px; color: #D8B257; margin-bottom: 4px; display: block; }
.store-address { font-size: 13px; color: #666; margin: 4px 0 0 0; }

/* --- 2. Phương thức thanh toán --- */
.payment-methods { width: 100%; display: flex; flex-direction: column; gap: 15px; }
.payment-option { height: auto !important; padding: 15px !important; width: 100%; border-color: #eaeaea; }
.payment-option.is-checked { border-color: #D8B257; background-color: #fcf9f2; }

/* Nội dung bên trong nút Radio thanh toán */
.payment-content { display: flex; align-items: center; gap: 15px; margin-left: 5px; }
.payment-content strong { font-size: 15px; color: #333; }
.payment-content p { margin: 5px 0 0 0; font-size: 13px; color: #777; white-space: normal; }

/* --- 3. Tóm tắt đơn hàng (Order Summary) --- */
.order-summary-box { background-color: #fff; padding: 25px; border-radius: 8px; box-shadow: 0 2px 12px 0 rgba(0,0,0,0.05); border-top: 4px solid #111; position: sticky; top: 20px; }

/* Danh sách sản phẩm trong box thanh toán */
.checkout-items { max-height: 350px; overflow-y: auto; padding-right: 10px; }
.checkout-item { display: flex; align-items: center; gap: 15px; margin-bottom: 15px; }
.item-img { width: 60px; height: 60px; border-radius: 4px; border: 1px solid #eee; flex-shrink: 0; }
.item-info { flex: 1; }
.item-name { font-size: 13px; font-weight: 500; color: #333; line-height: 1.4; display: -webkit-box; -webkit-line-clamp: 2; line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; }

/* Thành tiền và nút đặt hàng */
.summary-row { display: flex; justify-content: space-between; align-items: center; margin-bottom: 15px; font-size: 14px; color: #555; }
.final-price { font-size: 26px; color: #d93025; font-weight: bold; }
.btn-place-order { width: 100%; background-color: #111; color: #D8B257; font-weight: bold; border: none; border-radius: 4px; margin-top: 15px; }
.btn-place-order:hover { background-color: #222; }

.qr-img { width: 180px; height: 180px; border: 4px solid #fff; border-radius: 8px; box-shadow: 0 4px 12px rgba(0,0,0,0.1); cursor: pointer; transition: transform 0.3s; }
.qr-img:hover { transform: scale(1.05); }

/* --- 5. Coupon Dialog Styles --- */
.coupons-list {
  max-height: 400px;
  overflow-y: auto;
  padding-right: 5px;
}
.coupon-card {
  display: flex;
  align-items: center;
  background: #fff;
  border: 1px dashed #D8B257;
  border-radius: 8px;
  padding: 15px;
  margin-bottom: 12px;
  position: relative;
  overflow: hidden;
}
.coupon-card::before, .coupon-card::after {
  content: '';
  position: absolute;
  top: 50%;
  width: 14px;
  height: 14px;
  background-color: #fff;
  border-radius: 50%;
  border: 1px solid #eee;
  transform: translateY(-50%);
  z-index: 1;
}
.coupon-card::before { left: -8px; border-right-color: transparent; }
.coupon-card::after { right: -8px; border-left-color: transparent; }
.coupon-icon-box {
  width: 45px;
  height: 45px;
  background-color: #faf6eb;
  color: #D8B257;
  display: flex;
  justify-content: center;
  align-items: center;
  border-radius: 50%;
  margin-right: 15px;
  flex-shrink: 0;
}
.coupon-content { flex: 1; }
.coupon-title { font-size: 14px; color: #333; margin-bottom: 4px; }
.coupon-desc { font-size: 13px; color: #555; }
.coupon-meta { font-size: 12px; color: #666; margin-top: 4px; }
.coupon-expiry { font-size: 12px; color: #999; margin-top: 4px; }

@media (max-width: 768px) {
  .container {
    padding: 0 12px;
  }
  .checkout-header-title h2 {
    font-size: 18px;
    text-align: center;
  }
  .checkout-section {
    padding: 15px;
    margin-bottom: 15px;
  }
  .delivery-methods {
    flex-direction: column;
    gap: 12px;
  }
  .delivery-card {
    padding: 12px;
    font-size: 14px;
    width: 100%;
    box-sizing: border-box;
  }
  .order-summary-box {
    position: static !important;
    margin-top: 20px;
    padding: 15px;
  }
  .payment-option {
    padding: 10px !important;
    height: auto !important;
  }
  .payment-content strong {
    font-size: 14px;
  }
  .payment-content p {
    font-size: 12px;
    line-height: 1.35;
  }
  .terms-note {
    font-size: 11px;
    line-height: 1.4;
  }
  .coupon-section .el-button {
    font-size: 12px;
    padding: 12px 8px;
  }
}
</style>