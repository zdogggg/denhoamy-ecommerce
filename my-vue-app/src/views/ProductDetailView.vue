<template>
  <div class="product-detail-wrapper">
    <AppHeader />
    <AppNavbar activeIndex="2" />

    <div class="container main-content">
      <div v-if="loading" style="text-align: center; padding: 80px 0;">
        <el-icon class="is-loading" :size="40" color="#D8B257"><Loading /></el-icon>
        <p style="color: #999; margin-top: 10px;">Đang tải thông tin sản phẩm...</p>
      </div>

      <template v-else>
      <el-breadcrumb :separator-icon="ArrowRight" class="breadcrumb-custom">
        <el-breadcrumb-item :to="{ path: '/' }">Trang chủ</el-breadcrumb-item>
        <el-breadcrumb-item :to="{ path: '/category', query: { type: product.loai_den } }">{{ product.loai_den }}</el-breadcrumb-item>
        <el-breadcrumb-item>{{ product.ten_san_pham }}</el-breadcrumb-item>
      </el-breadcrumb>

      <div class="product-top-section">
        <el-row :gutter="40">
          <el-col :xs="24" :md="10" :lg="10">
            <div class="image-gallery">
              <el-image 
                :src="currentImage || product.image_url" 
                class="main-product-img" 
                fit="contain" 
                :preview-src-list="allImages"
                preview-teleported
              />
              <div class="thumbnail-strip" v-if="allImages.length > 1">
                <div 
                  v-for="(img, idx) in allImages" 
                  :key="idx" 
                  :class="['thumbnail-item', { active: (currentImage || product.image_url) === img }]"
                  @mousemove="currentImage = img"
                  @click="currentImage = img"
                >
                  <el-image :src="img" fit="cover" loading="lazy" />
                </div>
              </div>
            </div>
          </el-col>

          <el-col :xs="24" :md="14" :lg="14">
            <div class="product-summary">
              <h1 class="product-title">{{ product.ten_san_pham }}</h1>
              <div class="product-meta">
                <span>Mã SP: <strong>{{ product.ma_san_pham }}</strong></span>
                <el-divider direction="vertical" />
                <span>Tình trạng: <strong style="color: #67C23A;">{{ product.tinh_trang }}</strong></span>
              </div>
              
              <div class="product-price-box">
                <div class="old-price" v-if="hasProductDiscount"><span>{{ formatPrice(resolveListPrice(product, displayPrice)) }}đ</span></div>
                <div class="current-price">{{ formatPrice(displayPrice) }}đ</div>
                <el-tag v-if="isHotDeal" type="danger" size="small" effect="dark" style="margin-top: 8px;">Hot Deal</el-tag>
              </div>

              <div class="product-variants-section" v-if="uniqueSizes.length > 0 || uniqueLights.length > 0">
                <div class="variant-group" v-if="uniqueSizes.length > 0">
                  <div class="variant-label">Kích thước:</div>
                  <div class="variant-options">
                    <div 
                      v-for="size in uniqueSizes" 
                      :key="size" 
                      :class="['variant-btn', { active: selectedSize === size }]"
                      @click="selectedSize = size"
                    >
                      {{ size }}
                    </div>
                  </div>
                </div>
                
                <div class="variant-group" v-if="uniqueLights.length > 0">
                  <div class="variant-label">Ánh sáng:</div>
                  <div class="variant-options">
                    <div 
                      v-for="light in uniqueLights" 
                      :key="light" 
                      :class="['variant-btn', { active: selectedLight === light }]"
                      @click="selectedLight = light"
                    >
                      {{ light }}
                    </div>
                  </div>
                </div>
              </div>

              <div class="product-specs-short">
                <ul>
                  <li><strong>Chất liệu:</strong> {{ product.chat_lieu }}</li>
                  <li v-if="!uniqueSizes.length"><strong>Kích thước:</strong> {{ product.kich_thuoc || 'Liên hệ' }}</li>
                  <li v-if="!uniqueLights.length"><strong>Nguồn sáng:</strong> {{ product.bong_den }}</li>
                  <li><strong>Tồn kho:</strong> {{ displayStockLabel }}</li>
                  <li><strong>Bảo hành:</strong> 24 tháng chính hãng.</li>
                </ul>
              </div>

              <div class="purchase-actions">
                <div class="quantity-selector">
                  <span style="margin-right: 15px; font-weight: 500;">Số lượng:</span>
                  <el-input-number 
                    v-model="quantity" 
                    :min="displayStock > 0 ? 1 : 0" 
                    :max="displayStock > 0 ? displayStock : 0" 
                    :disabled="displayStock <= 0" 
                  />
                </div>
                
                 <div class="action-buttons">
                   <el-button 
                     class="btn-add-cart" 
                     size="large" 
                     :disabled="!canPurchase" 
                     @click="addToCart"
                   >
                     <template v-if="canPurchase">
                       <el-icon style="margin-right: 8px;"><ShoppingCart /></el-icon> {{ addCartButtonLabel }}
                     </template>
                     <template v-else>
                       {{ addCartButtonLabel }}
                     </template>
                   </el-button>
                   <el-button 
                     class="btn-buy-now" 
                     size="large" 
                     :disabled="!canPurchase" 
                     @click="buyNow"
                   >
                     <div class="buy-now-content">
                       <span class="buy-now-title">{{ canPurchase ? 'MUA NGAY' : (needsVariantSelection ? 'CHỌN PHÂN LOẠI' : 'TẠM HẾT HÀNG') }}</span>
                       <small class="buy-now-sub">{{ canPurchase ? 'Giao hàng tận nơi nhanh chóng' : (needsVariantSelection ? 'Vui lòng chọn kích thước và ánh sáng' : 'Vui lòng quay lại sau') }}</small>
                     </div>
                   </el-button>
                   <el-button 
                     :class="['btn-wishlist', { 'is-liked': isLiked }]" 
                     size="large" 
                     @click="handleToggleWishlist"
                   >
                     <el-icon :size="20">
                       <StarFilled v-if="isLiked" />
                       <Star v-else />
                     </el-icon>
                   </el-button>
                 </div>
               </div>
 
               <div class="hotline-box">
                 <el-icon :size="24"><Phone /></el-icon>
                 <div class="hotline-text">
                   <span>Cần tư vấn? Gọi ngay Hotline: </span>
                   <strong>0978.897.579 - 0225.653.3618</strong>
                 </div>
               </div>
            </div>
          </el-col>
        </el-row>
      </div>

      <div class="product-tabs-section">
        <el-tabs type="border-card" class="custom-tabs">
          <el-tab-pane label="THÔNG TIN SẢN PHẨM">
            <div class="tab-content" v-if="product.description">
              <div v-html="sanitizedDescription" style="line-height: 1.8;"></div>
            </div>
            <div class="tab-content" v-else>
              <h3>Đặc điểm nổi bật của {{ product.ten_san_pham }}</h3>
              <p>Mẫu {{ product.loai_den }} mang thiết kế phong cách {{ product.phong_cach }} sang trọng, là điểm nhấn tuyệt vời cho {{ product.khong_gian_lap_dat }}. Sự kết hợp giữa chất liệu {{ product.chat_lieu }} tạo nên vẻ đẹp lộng lẫy, quyền quý.</p>
              <p>Sản phẩm được gia công tỉ mỉ từng chi tiết, đảm bảo độ bền vượt thời gian. Hệ thống bóng {{ product.bong_den }} đi kèm không chỉ mang lại ánh sáng ấm áp mà còn tiết kiệm điện năng tối đa.</p>
            </div>
          </el-tab-pane>
          <el-tab-pane label="THÔNG SỐ KỸ THUẬT">
            <el-descriptions title="Chi tiết thông số kỹ thuật" :column="2" border>
              <el-descriptions-item label="Mã sản phẩm"><strong>{{ product.ma_san_pham }}</strong></el-descriptions-item>
              <el-descriptions-item label="Phong cách">{{ product.phong_cach }}</el-descriptions-item>
              <el-descriptions-item label="Không gian lắp đặt">{{ product.khong_gian_lap_dat }}</el-descriptions-item>
              <el-descriptions-item label="Chất liệu đèn">{{ product.chat_lieu }}</el-descriptions-item>
              <el-descriptions-item label="Loại bóng đèn">{{ product.bong_den }}</el-descriptions-item>
              <el-descriptions-item label="Điện áp">{{ product.dien_ap }}</el-descriptions-item>
              <el-descriptions-item label="Tuổi thọ bóng trung bình">{{ product.tuoi_tho }}H</el-descriptions-item>
              <el-descriptions-item label="Kích thước đèn">{{ product.kich_thuoc || 'Liên hệ' }}</el-descriptions-item>
              <el-descriptions-item label="Tình trạng">
                <el-tag type="success" size="small">{{ product.tinh_trang }}</el-tag>
              </el-descriptions-item>
              <el-descriptions-item label="Tồn kho">{{ product.stock }} sản phẩm</el-descriptions-item>
            </el-descriptions>
          </el-tab-pane>
          <el-tab-pane :label="`ĐÁNH GIÁ (${reviews.length})`">
            <div class="reviews-section">
              <!-- Form Gửi Đánh Giá (Chỉ hiện khi đã đăng nhập) -->
              <div v-if="authStore.isLoggedIn" class="review-form-box">
                <h4>Viết đánh giá của bạn</h4>
                <el-rate v-model="newReview.rating" :colors="['#f56c6c', '#e6a23c', '#ff9900']" show-text />
                <el-input 
                  v-model="newReview.comment" 
                  type="textarea" 
                  rows="3" 
                  placeholder="Nhập nội dung đánh giá của bạn về sản phẩm này..." 
                  style="margin-top: 15px;"
                />
                <el-button color="#D8B257" @click="submitReview" :loading="submittingReview" style="margin-top: 15px;">Gửi đánh giá</el-button>
              </div>
              <div v-else class="review-login-prompt">
                Vui lòng <router-link to="/login" style="color: #D8B257; font-weight: bold;">đăng nhập</router-link> để gửi đánh giá sản phẩm.
              </div>

              <el-divider v-if="reviews.length > 0" border-style="dashed" />

              <!-- Danh sách Đánh Giá -->
              <div v-if="reviews.length === 0" style="padding: 30px 0;">
                <el-empty description="Chưa có đánh giá nào cho sản phẩm này. Hãy là người đầu tiên đánh giá!" />
              </div>
              <div v-else class="review-list">
                <div v-for="review in reviews" :key="review.id" class="review-item">
                  <el-avatar :size="40">{{ review.user_name.charAt(0) }}</el-avatar>
                  <div class="review-content">
                    <div class="r-header">
                      <strong>{{ review.user_name }}</strong>
                      <span class="r-date">{{ new Date(review.created_at).toLocaleDateString('vi-VN') }}</span>
                    </div>
                    <el-rate :model-value="Number(review.rating)" disabled disabled-void-color="#dcdfe6" />
                    <p class="r-text">{{ review.comment }}</p>
                    
                    <!-- Phản hồi của Shop -->
                    <div v-if="review.reply" class="r-reply">
                      <strong>Phản hồi từ Đèn Hoa Mỹ:</strong>
                      <p>{{ review.reply }}</p>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </el-tab-pane>
        </el-tabs>
      </div>
      </template>
    </div>

    <!-- SẢN PHẨM TƯƠNG TỰ -->
    <section class="products-section container" style="margin-top: 40px; margin-bottom: 60px;" v-if="relatedProducts.length > 0">
      <div class="section-title">
        <span>SẢN PHẨM TƯƠNG TỰ</span>
      </div>
      
      <el-row :gutter="20">
        <el-col :xs="12" :sm="12" :md="6" :lg="6" v-for="item in relatedProducts" :key="item.id" style="margin-bottom: 20px;">
          <el-card 
            :body-style="{ padding: '0px', position: 'relative' }" 
            class="product-card" 
            shadow="hover"
            @click="goToProduct(item.id)"
            style="cursor: pointer;"
          >
            <!-- Badge "Gợi ý" -->
            <div style="position: absolute; top: 10px; left: 10px; background: #67c23a; color: white; padding: 4px 12px; border-radius: 4px; font-size: 11px; text-transform: uppercase; font-weight: bold; z-index: 10; box-shadow: 0 2px 5px rgba(0,0,0,0.2);">
              Liên quan
            </div>
            
            <el-image :src="item.image_url || item.image" class="product-img" fit="cover" loading="lazy" />
            <div class="product-info">
              <h4 class="product-name">{{ item.ten_san_pham || item.name }}</h4>
              <div v-if="checkIsNewArrival(item.created_at)" class="tag-new-arrival">
                Hàng mới về
              </div>
              <div class="price-box">
                <span class="old-price" v-if="priceDisplay(item).hasDiscount">{{ formatPrice(priceDisplay(item).listPrice) }}đ</span>
                <span class="new-price">{{ priceDisplay(item).saleLabel }}</span>
              </div>
            </div>
          </el-card>
        </el-col>
      </el-row>
    </section>

    <AppFooter />
  </div>
</template>

<script setup>
import { ref, onMounted, computed, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { Phone, ShoppingCart, Loading, ArrowRight, Star, StarFilled } from '@element-plus/icons-vue'
import { ElMessage } from 'element-plus'
import { toastSuccess, toastWarning } from '../utils/toast'
import AppHeader from '../components/AppHeader.vue'
import AppNavbar from '../components/AppNavbar.vue'
import AppFooter from '../components/AppFooter.vue'
import { useAuthStore } from '../stores/auth'
import { useCartStore } from '../stores/cart'
import { getProductById, getRelatedProducts, resolveSalePrice } from '../services/productService'
import { getReviews, addReview } from '../services/reviewService'
import { getWishlist, toggleWishlist } from '../services/wishlistService'
import { formatPrice, checkIsNewArrival, sanitizeRichHtml } from '../utils/format'
import { getProductPriceDisplay, resolveListPrice } from '../utils/productPrice'
import { useSEO } from '../utils/useSEO'
import { ensureAuthForPurchase } from '../utils/promptAuthForPurchase'

const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()
const cartStore = useCartStore()
const quantity = ref(1)
const loading = ref(true)

const product = ref({
  id: 1, ma_san_pham: 'DC04305', ten_san_pham: 'Đèn chùm DC04305',
  price: 15000000, old_price: 18500000, stock: 15,
  phong_cach: 'Tân cổ điển', khong_gian_lap_dat: 'phòng khách, phòng ngủ, phòng ăn,..',
  bong_den: 'Led (vàng, trung tính, trắng)', dien_ap: '220v',
  chat_lieu: 'Hợp kim + thủy tinh', tinh_trang: 'Mới 100%', tuoi_tho: '50000',
  kich_thuoc: '', loai_den: 'Đèn chùm',
  image_url: 'https://images.unsplash.com/photo-1540932239986-30128078f3c5?q=80&w=800'
})
const currentImage = ref('')
const allImages = ref([])

// Related Products Logic
const relatedProducts = ref([])
const goToProduct = (id) => {
  router.push('/product/' + id)
  // Buộc reload lại component với data mới khi navigate cùng route name
  setTimeout(() => {
    window.scrollTo(0, 0)
    fetchProduct()
  }, 100)
}

// Review logic
const reviews = ref([])
const submittingReview = ref(false)
const newReview = ref({ rating: 5, comment: '' })

// Variants Logic
const selectedSize = ref('')
const selectedLight = ref('')

const uniqueSizes = computed(() => {
  if (!product.value?.variants) return []
  return [...new Set(product.value.variants.map(v => v.kich_thuoc).filter(Boolean))]
})

const uniqueLights = computed(() => {
  if (!product.value?.variants) return []
  // Lấy toàn bộ ánh sáng có sẵn của sản phẩm
  return [...new Set(product.value.variants.map(v => v.anh_sang).filter(Boolean))]
})

const currentVariant = computed(() => {
  if (!product.value?.variants || product.value.variants.length === 0) return null
  // Tìm variant khớp chính xác cả 2 tiêu chí
  return product.value.variants.find(v => 
    (v.kich_thuoc || '') === selectedSize.value && 
    (v.anh_sang || '') === selectedLight.value
  )
})

const isHotDeal = computed(() => Number(product.value.is_hot_deal) === 1)

const displayPrice = computed(() => {
  const variantId = currentVariant.value?.id
    || product.value.variants?.find((v) => (v.kich_thuoc || '') === selectedSize.value)?.id
    || null
  return resolveSalePrice(product.value, variantId)
})

const hasProductDiscount = computed(() => {
  const salePrice = Number(displayPrice.value) || 0
  return resolveListPrice(product.value, salePrice) > 0
})
const priceDisplay = (item) => getProductPriceDisplay(item)
const hasProductVariants = computed(() => (product.value?.variants?.length ?? 0) > 0)

const needsVariantSelection = computed(() => hasProductVariants.value && !currentVariant.value)

const displayStock = computed(() => {
  if (needsVariantSelection.value) return 0
  if (currentVariant.value) return Number(currentVariant.value.stock) || 0
  return Number(product.value.stock) || 0
})

const displayStockLabel = computed(() => {
  if (needsVariantSelection.value) return 'Chọn phân loại'
  return `${displayStock.value} sản phẩm`
})

const canPurchase = computed(() => displayStock.value > 0 && !needsVariantSelection.value)

const addCartButtonLabel = computed(() => {
  if (canPurchase.value) return 'THÊM VÀO GIỎ'
  if (needsVariantSelection.value) return 'CHỌN PHÂN LOẠI'
  return 'HẾT HÀNG'
})

const sanitizedDescription = computed(() => {
  const raw = product.value?.description || ''
  if (!raw) return ''
  const withBreaks = raw.includes('<') ? raw : raw.replace(/\n/g, '<br/>')
  return sanitizeRichHtml(withBreaks)
})

watch(selectedSize, (size) => {
  if (!product.value?.variants?.length) return
  const match = product.value.variants.find((v) => (v.kich_thuoc || '') === size)
  if (match) {
    selectedLight.value = match.anh_sang || ''
  }
})

// Watcher tự động điều chỉnh số lượng mua dựa trên tồn kho thực tế
watch(displayStock, (newStock) => {
  if (newStock <= 0) {
    quantity.value = 0
  } else {
    if (quantity.value <= 0) {
      quantity.value = 1
    } else if (quantity.value > newStock) {
      quantity.value = newStock
    }
  }
}, { immediate: true })

const applyVariantFromQuery = () => {
  const variantId = route.query.variant
  if (!variantId || !product.value?.variants?.length) return false
  const match = product.value.variants.find((v) => String(v.id) === String(variantId))
  if (!match) return false
  selectedSize.value = match.kich_thuoc || ''
  selectedLight.value = match.anh_sang || ''
  return true
}

const fetchProduct = async () => {
  loading.value = true
  const [result, rvResult] = await Promise.all([
    getProductById(route.params.id),
    getReviews(route.params.id)
  ])
  
  if (result && result.success && result.data) {
    product.value = result.data
    const images = [product.value.image_url]
    if (product.value.gallery) {
      try {
        const gal = typeof product.value.gallery === 'string' ? JSON.parse(product.value.gallery) : product.value.gallery
        if (Array.isArray(gal)) {
          images.push(...gal)
        }
      } catch(e) {}
    }
    allImages.value = images
    currentImage.value = images[0]

    if (product.value.variants && product.value.variants.length > 0) {
      if (!applyVariantFromQuery()) {
        selectedSize.value = product.value.variants[0].kich_thuoc || ''
        selectedLight.value = product.value.variants[0].anh_sang || ''
      }
    } else {
      selectedSize.value = ''
      selectedLight.value = ''
    }
  }
  if (rvResult && rvResult.success) {
    reviews.value = rvResult.data
  }
  
  // Sản phẩm liên quan (cùng danh mục, server-side limit)
  if (product.value.loai_den) {
    const relatedResult = await getRelatedProducts(route.params.id, product.value.loai_den, 4)
    if (relatedResult?.success && Array.isArray(relatedResult.data)) {
      relatedProducts.value = relatedResult.data
    }
  }
  
  loading.value = false

  // Ghi lại lịch sử danh mục đã xem vào localStorage (cho tính năng cá nhân hóa trang chủ)
  if (product.value.loai_den) {
    try {
      const stored = JSON.parse(localStorage.getItem('viewed_categories') || '[]')
      const updated = [product.value.loai_den, ...stored.filter(c => c !== product.value.loai_den)].slice(0, 5)
      localStorage.setItem('viewed_categories', JSON.stringify(updated))
    } catch(e) {}
  }

  // Cập nhật Meta SEO động cho sản phẩm
  useSEO({
    title: `${product.value.ten_san_pham} - Đèn Hoa Mỹ`,
    description: `Mua ${product.value.ten_san_pham} giá ${formatPrice(displayPrice.value)}đ tại Đèn Hoa Mỹ. Chất liệu: ${product.value.chat_lieu || 'Cao cấp'}. Bảo hành chính hãng.`,
    keywords: `${product.value.ten_san_pham}, ${product.value.loai_den}, đèn trang trí, Đèn Hoa Mỹ`,
    image: product.value.image_url,
    url: window.location.href
  })
}

// Wishlist Logic
const isLiked = ref(false)
const checkWishlistStatus = async () => {
  if (authStore.isLoggedIn && authStore.user?.id) {
    const res = await getWishlist()
    if (res && res.success && res.data) {
      isLiked.value = res.data.some(item => String(item.id) === String(route.params.id))
    }
  }
}

const handleToggleWishlist = async () => {
  if (!authStore.isLoggedIn || !authStore.user?.id) {
    return ElMessage.warning('Vui lòng đăng nhập để lưu sản phẩm yêu thích!')
  }
  const res = await toggleWishlist(product.value.id)
  if (res && res.success) {
    isLiked.value = res.action === 'added'
    if (isLiked.value) {
      ElMessage.success('Đã thêm vào danh sách yêu thích!')
    } else {
      ElMessage.info('Đã bỏ yêu thích.')
    }
  } else {
    ElMessage.error('Có lỗi xảy ra!')
  }
}

onMounted(() => {
  fetchProduct()
  checkWishlistStatus()
})

watch(
  () => route.params.id,
  (newId, oldId) => {
    if (!newId || oldId === undefined) return
    if (String(newId) === String(oldId)) return
    quantity.value = 1
    newReview.value = { rating: 5, comment: '' }
    window.scrollTo({ top: 0, behavior: 'smooth' })
    fetchProduct()
    checkWishlistStatus()
  }
)

watch(
  () => route.query.variant,
  () => {
    if (product.value?.variants?.length) {
      applyVariantFromQuery()
    }
  }
)

const submitReview = async () => {
  if (!newReview.value.comment.trim()) {
    return ElMessage.warning('Vui lòng nhập nội dung đánh giá!')
  }
  
  submittingReview.value = true
  const payload = {
    product_id: product.value.id,
    user_name: authStore.user?.name || 'Khách hàng',
    rating: newReview.value.rating,
    comment: newReview.value.comment
  }
  
  const res = await addReview(payload)
  submittingReview.value = false
  
  if (res && res.success) {
    ElMessage.success('Gửi đánh giá thành công! Đánh giá đang chờ duyệt.')
    newReview.value.comment = ''
    newReview.value.rating = 5
  } else {
    ElMessage.error('Có lỗi xảy ra, vui lòng thử lại.')
  }
}

const addToCart = () => {
  if (!ensureAuthForPurchase(authStore, route.fullPath)) return false

  if (hasProductVariants.value && !currentVariant.value) {
    toastWarning('Vui lòng chọn đủ kích thước và ánh sáng trước khi thêm vào giỏ!')
    return false
  }

  if (displayStock.value <= 0) {
    toastWarning('Sản phẩm hoặc phân loại này hiện đã hết hàng!')
    return false
  }

  let variantName = ''
  if (currentVariant.value) {
    let parts = []
    if (currentVariant.value.kich_thuoc) parts.push(currentVariant.value.kich_thuoc)
    if (currentVariant.value.anh_sang) parts.push(currentVariant.value.anh_sang)
    if (parts.length > 0) variantName = ` - [${parts.join(' - ')}]`
  }

  const result = cartStore.addItem({
    id: currentVariant.value ? `${product.value.id}_${currentVariant.value.id}` : product.value.id,
    code: product.value.ma_san_pham,
    name: product.value.ten_san_pham + variantName,
    image: product.value.image_url,
    price: displayPrice.value,
    stock: displayStock.value,
    quantity: quantity.value
  })

  if (result.success) {
    toastSuccess(`Đã thêm ${quantity.value} sản phẩm vào giỏ hàng!`)
    return true
  }

  toastWarning(result.message)
  return false
}

const buyNow = () => {
  if (!addToCart()) return
  router.push('/checkout')
}
</script>

<style scoped>
/* --- 1. Cấu trúc nền và khung chứa --- */
.product-detail-wrapper { background-color: #f7f8fa; min-height: 100vh; }
.container { width: 1200px; margin: 0 auto; max-width: 100%; padding: 0 20px; box-sizing: border-box; }

/* Thanh điều hướng (Breadcrumb) */
.breadcrumb-custom { padding: 20px 0; font-size: 14px; margin-bottom: 20px; border-bottom: 1px solid #f0f0f0; }
:deep(.el-breadcrumb__inner) { color: #999 !important; font-weight: normal; transition: color 0.3s; }
:deep(.el-breadcrumb__inner.is-link:hover) { color: #D8B257 !important; cursor: pointer; }
:deep(.el-breadcrumb__item:last-child .el-breadcrumb__inner) { color: #333 !important; font-weight: 600; }

/* Phần thân trên (Thông tin chính + Ảnh) */
.product-top-section { background: #fff; padding: 30px; border-radius: 8px; box-shadow: 0 2px 12px 0 rgba(0,0,0,0.05); margin-bottom: 30px; }

/* --- 2. Thư viện ảnh (Gallery) --- */
.image-gallery { display: flex; flex-direction: column; gap: 15px; }
.main-product-img { width: 100%; aspect-ratio: 1 / 1; height: auto; border-radius: 8px; border: 1px solid #eee; cursor: zoom-in; background-color: #fcfcfc; }

/* Các ảnh nhỏ (Thumbnail) */
.thumbnail-strip { display: flex; gap: 10px; overflow-x: auto; padding: 5px 0; }
.thumbnail-item { flex: 0 0 80px; height: 80px; border: 2px solid transparent; border-radius: 6px; overflow: hidden; cursor: pointer; transition: all 0.3s ease; background-color: #fcfcfc; }
.thumbnail-item.active { border-color: #D8B257; /* Viền vàng khi đang chọn ảnh này */ }

/* --- 3. Chi tiết sản phẩm (Tiêu đề, Giá, Biến thể) --- */
.product-title { margin: 0 0 10px 0; font-size: 24px; color: #222; line-height: 1.4; }
.product-meta { font-size: 13px; color: #666; margin-bottom: 20px; }

/* Khung giá sản phẩm */
.product-price-box { background-color: #fcf9f2; padding: 15px 20px; border-left: 4px solid #D8B257; margin-bottom: 25px; }
.old-price { font-size: 14px; color: #999; margin-bottom: 5px; }
.old-price span { text-decoration: line-through; }
.current-price { font-size: 28px; font-weight: bold; color: #D8B257; }

/* Các nút chọn biến thể (Kích thước, Ánh sáng) */
.product-variants-section { margin-bottom: 25px; display: flex; flex-direction: column; gap: 15px; }
.variant-label { margin-bottom: 8px; font-weight: 500; font-size: 14px; color: #333; }
.variant-options { display: flex; flex-wrap: wrap; gap: 10px; }
.variant-btn { padding: 8px 15px; background: #fff; border: 1px solid #dcdfe6; border-radius: 4px; font-size: 13px; cursor: pointer; transition: all 0.2s; }
.variant-btn:hover { border-color: #D8B257; color: #D8B257; }
.variant-btn.active { border-color: #D8B257; background: #fcf9f2; color: #D8B257; font-weight: 600; }

/* Cấu hình giãn cách phần Thông số kỹ thuật thu gọn */
.product-specs-short { margin-bottom: 25px; color: #444; font-size: 14px; }
.product-specs-short ul { padding-left: 20px; margin: 0; display: flex; flex-direction: column; gap: 12px; }

/* --- 4. Các nút thao tác mua hàng --- */
.purchase-actions { margin-bottom: 30px; }
.quantity-selector { margin-bottom: 20px; display: flex; align-items: center; }
.action-buttons { display: flex; gap: 15px; }

/* Nút thêm vào giỏ hàng (Viền vàng) */
.btn-add-cart { flex: 1; border: 2px solid #D8B257; color: #D8B257; font-weight: bold; height: 50px; }
/* Nút mua ngay (Nền vàng) */
.btn-buy-now { flex: 1; background-color: #D8B257; border: 2px solid #D8B257; color: #fff; height: 50px; padding: 0; }
.btn-buy-now:hover, .btn-buy-now:focus { background-color: #c7a14e; border-color: #c7a14e; color: #fff; }
.buy-now-content { display: flex; flex-direction: column; align-items: center; justify-content: center; line-height: 1.2; width: 100%; }
.buy-now-title { font-size: 14px; font-weight: 700; }
.buy-now-sub { font-size: 10px; font-weight: 400; opacity: 0.9; }

/* Trạng thái hết hàng / Disabled */
.btn-add-cart.is-disabled,
.btn-add-cart.is-disabled:hover,
.btn-buy-now.is-disabled,
.btn-buy-now.is-disabled:hover {
  border-color: #d2d2d2 !important;
  color: #a0a0a0 !important;
  cursor: not-allowed !important;
  pointer-events: none !important;
}

.btn-add-cart.is-disabled, 
.btn-add-cart.is-disabled:hover {
  background-color: #f5f5f5 !important;
}

.btn-buy-now.is-disabled, 
.btn-buy-now.is-disabled:hover {
  background-color: #eaeaea !important;
}

/* Nút yêu thích (Wishlist) */
.btn-wishlist { width: 50px; height: 50px; padding: 0; color: #999; border: 1px solid #dcdfe6; transition: all 0.3s; display: inline-flex; align-items: center; justify-content: center; }
.btn-wishlist.is-liked { color: #f56c6c; border-color: #f56c6c; background-color: #fef0f0; }

/* Khung chứa hotline hỗ trợ */
.hotline-box { display: flex; align-items: center; gap: 15px; padding: 15px; border: 1px dashed #ccc; border-radius: 8px; background-color: #fafafa; }
.hotline-text strong { font-size: 18px; color: #d93025; }

/* STYLE CỦA PHẦN SẢN PHẨM TƯƠNG TỰ */
.section-title { text-align: center; margin-bottom: 40px; position: relative; }
.section-title::after { content: ''; position: absolute; bottom: -10px; left: 50%; transform: translateX(-50%); width: 50px; height: 3px; background: #D8B257; }
.section-title span { font-size: 24px; font-weight: bold; color: #222; text-transform: uppercase; letter-spacing: 1px; }

.product-card { border-radius: 10px; border: 1px solid #f0f0f0; transition: all 0.3s cubic-bezier(0.25, 0.8, 0.25, 1); overflow: hidden !important; overflow-x: hidden !important; }
.product-card:hover { transform: translateY(-8px); box-shadow: 0 15px 30px rgba(0,0,0,0.1); border-color: #D8B257; }
.product-img { width: 100%; height: 260px; contain: paint; }
.product-info { padding: 20px; text-align: center; }
.product-name { font-size: 15px; color: #333; margin: 0 0 12px; height: 40px; overflow: hidden; display: -webkit-box; -webkit-line-clamp: 2; line-clamp: 2; -webkit-box-orient: vertical; font-weight: 500; }

.product-info .price-box {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 12px;
  margin-top: 10px;
}
.product-info .old-price {
  font-size: 13px !important;
  color: #bbb !important;
  text-decoration: line-through !important;
  margin: 0 !important;
}
.product-info .new-price {
  font-size: 16px !important;
  color: #d93025 !important;
  font-weight: bold !important;
  margin: 0 !important;
}


/* --- 5. Phần Tabs (Mô tả, Thông số, Đánh giá) --- */
.product-tabs-section { background: #fff; border-radius: 8px; box-shadow: 0 2px 12px 0 rgba(0,0,0,0.05); }
:deep(.custom-tabs .el-tabs__item.is-active) { color: #D8B257; font-weight: bold; }

/* Giao diện list đánh giá (Reviews) */
.review-form-box { background-color: #fcf9f2; padding: 20px; border-radius: 8px; border: 1px solid #faeed0; }
.review-item { display: flex; gap: 15px; border-bottom: 1px solid #eee; padding-bottom: 20px; margin-bottom: 20px; }
.r-reply { background-color: #f9fbfd; padding: 12px 15px; border-radius: 4px; border-left: 3px solid #D8B257; margin-top: 10px; }
.r-reply strong { color: #D8B257; display: block; margin-bottom: 5px; }

@media (max-width: 768px) {
  .breadcrumb-custom { padding: 12px 0 !important; font-size: 13px !important; margin-bottom: 12px !important; }
  :deep(.breadcrumb-custom .el-breadcrumb__item:last-child) { display: none !important; }
  :deep(.breadcrumb-custom .el-breadcrumb__item:nth-last-child(2) .el-breadcrumb__separator) { display: none !important; }
  .product-top-section { padding: 15px; }
  .main-product-img { height: 280px; }
  .product-title { font-size: 20px; margin-top: 15px; }
  .current-price { font-size: 22px; }
  .product-price-box { padding: 10px 15px; }
  
  .purchase-actions { margin-bottom: 20px; }
  .action-buttons { flex-direction: column !important; gap: 10px !important; width: 100% !important; }
  .btn-add-cart, .btn-buy-now { width: 100% !important; flex: none !important; margin: 0 !important; height: 46px !important; }
  .btn-wishlist { width: 100% !important; flex: none !important; height: 46px !important; margin: 0 !important; }
  
  .hotline-box { flex-direction: row !important; align-items: center !important; gap: 12px !important; padding: 10px !important; }
  .hotline-text { display: flex; flex-direction: column; align-items: flex-start; }
  .hotline-text span { font-size: 12px; color: #555; }
  .hotline-text strong { font-size: 14.5px !important; display: block; margin-top: 2px !important; }
  
  :deep(.el-descriptions) { font-size: 12px; }
  :deep(.el-descriptions__cell) { padding: 8px !important; }
  
  .review-item { flex-direction: column; gap: 10px; }
  
  .product-img { height: 180px; }
  .product-name { font-size: 12.5px; height: 34px; line-height: 1.35; margin-bottom: 6px; }
  .price-box .new-price { font-size: 14.5px; }
  .product-info { padding: 10px; }
}
</style>