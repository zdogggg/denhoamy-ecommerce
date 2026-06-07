<template>
  <div class="cart-wrapper">
    <AppHeader />
    <AppNavbar />

    <div class="container main-content">
      <el-breadcrumb :separator-icon="ArrowRight" class="breadcrumb-custom">
        <el-breadcrumb-item :to="{ path: '/' }">Trang chủ</el-breadcrumb-item>
        <el-breadcrumb-item>Giỏ hàng của bạn</el-breadcrumb-item>
      </el-breadcrumb>

      <div class="cart-header-title">
        <h2>GIỎ HÀNG ({{ cartStore.items.length }} sản phẩm)</h2>
      </div>

      <div v-if="cartStore.items.length > 0">
        <el-row :gutter="30">
          <el-col :xs="24" :lg="18">
            <!-- Desktop Layout -->
            <div class="cart-table-wrapper desktop-only">
              <el-table :data="cartStore.items" style="width: 100%">
                <el-table-column label="Sản phẩm" min-width="300">
                  <template #default="scope">
                    <div class="product-col">
                      <el-image :src="scope.row.image" class="cart-img" fit="cover" />
                      <div class="product-info">
                        <div class="product-name" @click="goToProduct(scope.row.id)">{{ scope.row.name }}</div>
                        <div class="product-code">Mã SP: {{ scope.row.code }}</div>
                      </div>
                    </div>
                  </template>
                </el-table-column>

                <el-table-column label="Đơn giá" width="120" align="center">
                  <template #default="scope">
                    <span class="unit-price">{{ formatPrice(scope.row.price) }}đ</span>
                  </template>
                </el-table-column>

                <el-table-column label="Số lượng" width="130" align="center">
                  <template #default="scope">
                    <el-input-number v-model="scope.row.quantity" :min="1" :max="quantityMax(scope.row)" size="small" @change="(val) => cartStore.updateQuantity(scope.$index, val)" style="width: 105px" />
                  </template>
                </el-table-column>

                <el-table-column label="Thành tiền" width="130" align="right">
                  <template #default="scope">
                    <span class="total-price">{{ formatPrice(scope.row.price * scope.row.quantity) }}đ</span>
                  </template>
                </el-table-column>

                <el-table-column label="" width="80" align="center">
                  <template #default="scope">
                    <el-button type="danger" link @click="removeItem(scope.$index)" :icon="Delete">Xóa</el-button>
                  </template>
                </el-table-column>
              </el-table>
            </div>

            <!-- Mobile Layout -->
            <div class="cart-mobile-wrapper mobile-only">
              <div v-for="(item, index) in cartStore.items" :key="item.id" class="cart-mobile-item">
                <el-image :src="item.image" class="cart-mobile-img" fit="cover" />
                <div class="cart-mobile-info">
                  <div class="cart-mobile-name" @click="goToProduct(item.id)">{{ item.name }}</div>
                  <div class="cart-mobile-code">Mã SP: {{ item.code }}</div>
                  <div class="cart-mobile-price">
                    <span>Đơn giá: {{ formatPrice(item.price) }}đ</span>
                  </div>
                  <div class="cart-mobile-actions">
                    <el-input-number 
                      v-model="item.quantity" 
                      :min="1" 
                      :max="quantityMax(item)" 
                      size="small" 
                      @change="(val) => cartStore.updateQuantity(index, val)" 
                      style="width: 105px" 
                    />
                    <el-button type="danger" link @click="removeItem(index)" :icon="Delete">Xóa</el-button>
                  </div>
                  <div class="cart-mobile-subtotal">
                    Thành tiền: <strong>{{ formatPrice(item.price * item.quantity) }}đ</strong>
                  </div>
                </div>
              </div>
            </div>
            
            <div class="cart-actions-left">
              <el-button :icon="Back" @click="$router.push('/category')">Tiếp tục mua hàng</el-button>
              <el-button type="danger" plain :icon="Delete" @click="handleClearCart">Xóa toàn bộ giỏ hàng</el-button>
            </div>
          </el-col>

          <el-col :xs="24" :lg="6">
            <div class="summary-box">
              <h3 class="summary-title">Tóm tắt đơn hàng</h3>
              
              <div class="summary-row">
                <span>Tạm tính:</span>
                <strong>{{ formatPrice(cartStore.cartTotal) }}đ</strong>
              </div>
              <div class="summary-row">
                <span>Phí vận chuyển:</span>
                <span>Miễn phí</span>
              </div>
              
              <el-divider />
              
              <div class="summary-row total-row">
                <span>TỔNG TIỀN:</span>
                <span class="final-price">{{ formatPrice(cartStore.cartTotal) }}đ</span>
              </div>
              <p class="vat-note">(Đã bao gồm VAT nếu có)</p>

              <el-button class="btn-checkout" size="large" @click="handleCheckout">
                TIẾN HÀNH THANH TOÁN
              </el-button>
            </div>
          </el-col>
        </el-row>
      </div>

      <div v-else class="empty-cart-box">
        <el-empty description="Giỏ hàng của bạn đang trống" :image-size="200">
          <el-button class="gold-btn" size="large" @click="$router.push('/category')">ĐI MUA SẮM NGAY</el-button>
        </el-empty>
      </div>
    </div>

    <AppFooter />
  </div>
</template>

<script setup>
import { onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { ArrowRight, Delete, Back } from '@element-plus/icons-vue'
import AppHeader from '../components/AppHeader.vue'
import AppNavbar from '../components/AppNavbar.vue'
import AppFooter from '../components/AppFooter.vue'
import { useCartStore } from '../stores/cart'
import { useAuthStore } from '../stores/auth'
import { ensureAuthForPurchase } from '../utils/promptAuthForPurchase'
import { formatPrice } from '../utils/format'
import { toastInfo } from '../utils/toast'

const router = useRouter()
const cartStore = useCartStore()
const authStore = useAuthStore()

onMounted(async () => {
  const { updated } = await cartStore.syncPricesFromServer()
  if (updated) toastInfo('Giá trong giỏ đã được cập nhật theo ưu đãi mới.')
})

const removeItem = (index) => {
  ElMessageBox.confirm('Bạn có chắc chắn muốn xóa sản phẩm này khỏi giỏ hàng?', 'Xác nhận', {
    confirmButtonText: 'Xóa',
    cancelButtonText: 'Hủy',
    type: 'warning',
  }).then(() => {
    cartStore.removeItem(index)
    ElMessage.success('Đã xóa sản phẩm khỏi giỏ hàng')
  }).catch(() => {})
}

const handleClearCart = () => {
  ElMessageBox.confirm('Xóa toàn bộ sản phẩm trong giỏ?', 'Cảnh báo', {
    confirmButtonText: 'Xóa hết',
    cancelButtonText: 'Hủy',
    type: 'error',
  }).then(() => {
    cartStore.clearCart()
    ElMessage.success('Giỏ hàng đã được làm trống')
  }).catch(() => {})
}

const goToProduct = (itemId) => {
  const productId = cartStore.getProductIdFromCartItem(itemId)
  const variantId = cartStore.getVariantIdFromCartItem(itemId)
  router.push({
    name: 'product-detail',
    params: { id: productId },
    query: variantId ? { variant: variantId } : {},
  })
}

const quantityMax = (item) => {
  if (item.stock !== null && item.stock !== undefined) return Math.max(1, item.stock)
  return 99
}

const handleCheckout = () => {
  if (!ensureAuthForPurchase(authStore, '/checkout')) return
  router.push('/checkout')
}
</script>

<style scoped>
/* --- 1. Cấu trúc nền và khung chứa --- */
.cart-wrapper { background-color: #f7f8fa; min-height: 100vh; }
.container { width: 1200px; margin: 0 auto; max-width: 100%; padding: 0 20px; box-sizing: border-box; }
.breadcrumb-custom { padding: 15px 0; font-size: 13px; margin-bottom: 10px; }

/* Tiêu đề trang giỏ hàng */
.cart-header-title { margin-bottom: 20px; }
.cart-header-title h2 { font-size: 22px; color: #222; margin: 0; font-weight: 600; }

/* --- 2. Bảng giỏ hàng (Cart Table) --- */
.cart-table-wrapper { background-color: #fff; padding: 20px; border-radius: 8px; box-shadow: 0 2px 12px 0 rgba(0,0,0,0.05); }

/* Hiển thị sản phẩm trong dòng của bảng */
.product-col { display: flex; align-items: center; gap: 15px; }
.cart-img,
.cart-mobile-img {
  width: 80px;
  height: 80px;
  border: 1px solid #eaeaea;
  flex-shrink: 0;
}
.cart-img { border-radius: 4px; }

.product-info { display: flex; flex-direction: column; gap: 5px; }
.product-name,
.cart-mobile-name {
  color: #333;
  cursor: pointer;
}
.product-name { font-weight: 500; font-size: 14px; transition: color 0.3s; line-height: 1.4; }
.product-name:hover { color: #D8B257; }
.product-code { font-size: 12px; color: #999; }

/* Đơn giá và Thành tiền */
.unit-price { color: #666; font-size: 14px; font-weight: 500; }
.total-price { color: #d93025; font-size: 15px; font-weight: bold; }

.cart-actions-left { display: flex; justify-content: space-between; margin-top: 20px; }

/* --- 3. Box Tóm tắt đơn hàng (Summary Box) --- */
.summary-box { background-color: #fff; padding: 25px; border-radius: 8px; box-shadow: 0 2px 12px 0 rgba(0,0,0,0.05); border-top: 4px solid #D8B257; }
.summary-title { margin: 0 0 20px 0; font-size: 18px; color: #333; }

.summary-row { display: flex; justify-content: space-between; align-items: center; margin-bottom: 15px; font-size: 14px; color: #555; }
.total-row { font-size: 16px; font-weight: bold; color: #111; margin-bottom: 5px; }

/* Tổng tiền cuối cùng (Màu đỏ nổi bật) */
.final-price { font-size: 24px; color: #d93025; }
.vat-note { font-size: 12px; color: #999; text-align: right; margin: 0 0 25px 0; }

/* Nút thanh toán */
.btn-checkout { width: 100%; background-color: #D8B257; color: #fff; font-weight: bold; border: none; border-radius: 4px; }
.btn-checkout:hover { background-color: #c49d45; }

/* Box hiển thị khi giỏ hàng trống */
.empty-cart-box { background-color: #fff; padding: 60px 0; border-radius: 8px; text-align: center; box-shadow: 0 2px 12px 0 rgba(0,0,0,0.05); margin-top: 20px; }
.gold-btn { background-color: #D8B257; color: #fff; border: none; font-weight: bold; padding: 0 30px; margin-top: 10px; }
.gold-btn:hover { background-color: #c49d45; color: #fff; }

.desktop-only { display: block; }
.mobile-only { display: none; }

@media (max-width: 768px) {
  .desktop-only { display: none !important; }
  .mobile-only { display: block !important; }
  
  .container { padding: 0 12px; }
  .cart-header-title h2 { font-size: 18px; text-align: center; }
  
  .cart-mobile-wrapper { display: flex; flex-direction: column; gap: 15px; margin-bottom: 20px; }
  .cart-mobile-item {
    background-color: #fff;
    padding: 12px;
    border-radius: 8px;
    box-shadow: 0 2px 8px rgba(0,0,0,0.04);
    display: flex;
    gap: 12px;
    border: 1px solid #eaeaea;
  }
  .cart-mobile-img {
    border-radius: 6px;
  }
  .cart-mobile-info {
    flex: 1;
    display: flex;
    flex-direction: column;
    gap: 5px;
  }
  .cart-mobile-name { font-size: 13.5px; font-weight: 600; line-height: 1.35; }
  .cart-mobile-code {
    font-size: 11px;
    color: #999;
  }
  .cart-mobile-price {
    font-size: 11.5px;
    color: #666;
  }
  .cart-mobile-actions {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-top: 5px;
    margin-bottom: 5px;
  }
  
  /* Make the number inputs tidy */
  :deep(.cart-mobile-actions .el-input-number--small) {
    width: 95px !important;
  }
  
  .cart-mobile-subtotal {
    font-size: 12px;
    color: #555;
    text-align: right;
    border-top: 1px dashed #f0f0f0;
    padding-top: 6px;
    margin-top: 5px;
  }
  .cart-mobile-subtotal strong {
    color: #d93025;
    font-size: 14.5px;
  }

  .cart-actions-left {
    flex-direction: column;
    gap: 10px;
    margin-top: 15px;
  }
  .cart-actions-left .el-button {
    width: 100%;
    margin-left: 0 !important;
    display: inline-flex !important;
    justify-content: center !important;
    align-items: center !important;
  }
  
  .summary-box {
    margin-top: 25px;
    padding: 15px;
  }
  .final-price {
    font-size: 20px;
  }
}
</style>