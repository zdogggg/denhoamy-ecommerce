<template>
  <div class="home-wrapper">
    <AppHeader />
    <AppNavbar activeIndex="1" />

    <div class="hero-wrapper-outer">
      <!-- Banner Quảng Cáo Trái -->
      <a 
        v-if="settingsStore.sys_ads_left_url" 
        :href="settingsStore.sys_ads_left_link" 
        class="side-adskyscraper left-ad"
        :style="sideAdBannerStyle"
        target="_blank"
        rel="noopener noreferrer"
      >
        <img :src="settingsStore.sys_ads_left_url" alt="Banner Quảng Cáo Trái" />
      </a>

      <!-- Banner Quảng Cáo Phải -->
      <a 
        v-if="settingsStore.sys_ads_right_url" 
        :href="settingsStore.sys_ads_right_link" 
        class="side-adskyscraper right-ad"
        :style="sideAdBannerStyle"
        target="_blank"
        rel="noopener noreferrer"
      >
        <img :src="settingsStore.sys_ads_right_url" alt="Banner Quảng Cáo Phải" />
      </a>

      <section class="hero-section container">
      <!-- Full Width Carousel (24/24) -->
      <div class="main-banner-wrapper">
        <el-carousel
          :height="carouselHeight"
          class="main-carousel"
          :indicator-position="carouselIndicatorPosition"
        >
          <el-carousel-item v-for="(banner, index) in settingsStore.banner_list" :key="index">
            <img
              :src="banner"
              class="carousel-banner-img"
              :alt="`Banner ${index + 1}`"
              loading="eager"
              decoding="async"
            />
          </el-carousel-item>
        </el-carousel>
      </div>

      <!-- Horizontal Service Bar -->
      <div class="service-bar">
        <div class="service-item">
          <el-icon class="service-icon"><Star /></el-icon>
          <div class="service-info">
            <h5>MẪU MỚI ĐA DẠNG</h5>
            <p>Luôn đi đầu xu hướng</p>
          </div>
        </div>
        <div class="service-item">
          <el-icon class="service-icon"><Van /></el-icon>
          <div class="service-info">
            <h5>SHIP COD TOÀN QUỐC</h5>
            <p>Nhanh chóng & Tiết kiệm</p>
          </div>
        </div>
        <div class="service-item">
          <el-icon class="service-icon"><CreditCard /></el-icon>
          <div class="service-info">
            <h5>THANH TOÁN AN TOÀN</h5>
            <p>Đa dạng phương thức</p>
          </div>
        </div>
        <div class="service-item">
          <el-icon class="service-icon"><Service /></el-icon>
          <div class="service-info">
            <h5>TƯ VẤN 24/7</h5>
            <p>Hỗ trợ tận tâm</p>
          </div>
        </div>
      </div>
    </section>
    </div>

    <!-- SECTION: DANH MỤC SẢN PHẨM -->
    <section class="categories-grid-section container fade-in-up" style="margin-top: 50px; margin-bottom: 20px;">
      <div class="section-title">
        <span>DANH MỤC SẢN PHẨM</span>
      </div>
      <div class="category-grid">
        <div 
          v-for="(cat, index) in homeCategories" 
          :key="index" 
          class="category-card" 
          @click="$router.push({ path: '/category', query: { type: cat.name } })"
        >
          <div class="cat-icon-wrap" v-html="cat.icon"></div>
          <p class="cat-name">{{ cat.name }}</p>
        </div>
      </div>
    </section>

    <!-- Banner ngang (trước Hot Deal) -->
    <section
      v-if="settingsStore.sys_ads_bottom_url"
      class="bottom-ad-section container fade-in-up"
    >
      <a
        :href="settingsStore.sys_ads_bottom_link || '#'"
        class="bottom-ad-banner"
        :target="settingsStore.sys_ads_bottom_link ? '_blank' : undefined"
        :rel="settingsStore.sys_ads_bottom_link ? 'noopener noreferrer' : undefined"
        @click="!settingsStore.sys_ads_bottom_link && $event.preventDefault()"
      >
        <img :src="settingsStore.sys_ads_bottom_url" alt="Banner quảng cáo" />
      </a>
    </section>

    <!-- SECTION: HOT DEAL -->
    <section class="products-section container fade-in-up" v-if="hotDealProducts.length > 0" style="margin-top: 50px; margin-bottom: 50px;">
      <div class="section-title">
        <span>HOT DEAL</span>
      </div>
      <div class="featured-slider-container">
        <button
          class="slider-arrow left"
          @click="slideHotDealLeft"
          v-show="hotDealSliderCanScroll"
          title="Xem thêm sang trái"
        >
          <el-icon><ArrowLeft /></el-icon>
        </button>

        <div class="slider-viewport" ref="hotDealSliderRef" @scroll="handleHotDealScroll">
          <div class="slider-track">
            <div
              v-for="item in hotDealProducts"
              :key="item.id"
              class="slider-item hot-deal-slider-item"
              @click="$router.push('/product/' + item.id)"
            >
              <div class="hot-deal-card">
                <div class="discount-badge">
                  <span class="pct" v-if="priceDisplay(item).hasDiscount">-{{ getDiscountPercent(item) }}%</span>
                  <span class="pct" v-else>HOT</span>
                  <span class="label">{{ priceDisplay(item).hasDiscount ? 'Xả kho' : 'Ưu đãi' }}</span>
                </div>
                <div class="delivery-badge" title="Giao hàng nhanh">
                  <el-icon><Van /></el-icon>
                </div>

                <div class="deal-img-wrapper">
                  <el-image :src="item.image_url || item.image" class="deal-img" fit="cover" loading="lazy" />
                </div>

                <div class="deal-info">
                  <h4 class="deal-name">{{ item.ten_san_pham || item.name }}</h4>
                  <div class="arrival-badge-slot">
                    <div v-if="checkIsNewArrival(item.created_at)" class="tag-new-arrival">
                      Hàng mới về
                    </div>
                  </div>

                  <div class="stars-box">
                    <el-icon v-for="i in 5" :key="i" class="star-on"><StarFilled /></el-icon>
                  </div>

                  <div class="deal-price-box">
                    <span class="old-price" v-if="priceDisplay(item).hasDiscount">{{ formatPrice(priceDisplay(item).listPrice) }}đ</span>
                    <span class="new-price">{{ priceDisplay(item).saleLabel }}</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <button
          class="slider-arrow right"
          @click="slideHotDealRight"
          v-show="hotDealSliderCanScroll"
          title="Xem thêm sang phải"
        >
          <el-icon><ArrowRight /></el-icon>
        </button>
      </div>
    </section>

    <section class="products-section container fade-in-up">
      <div class="section-title">
        <span>SẢN PHẨM MỚI VỀ</span>
      </div>
      
      <ProductSkeleton v-if="loading" :count="4" />

      <!-- Khung Slider sản phẩm nổi bật -->
      <div v-else class="featured-slider-container">
        <!-- Nút Trái -->
        <button 
          class="slider-arrow left" 
          @click="slideLeft" 
          v-show="sliderCanScroll"
          title="Xem thêm sang trái"
        >
          <el-icon><ArrowLeft /></el-icon>
        </button>

        <div class="slider-viewport" ref="sliderRef" @scroll="handleScroll">
          <div class="slider-track">
            <div 
              v-for="item in featuredProducts" 
              :key="item.id" 
              class="slider-item"
            >
              <el-card 
                :body-style="{ padding: '0px' }" 
                class="product-card" 
                shadow="hover"
                @click="$router.push('/product/' + item.id)"
                style="cursor: pointer;"
              >
                <el-image :src="item.image_url || item.image" class="product-img" fit="cover" loading="lazy" />
                <div class="product-info">
                  <h4 class="product-name">{{ item.ten_san_pham || item.name }}</h4>
                  <div class="arrival-badge-slot">
                    <div v-if="checkIsNewArrival(item.created_at)" class="tag-new-arrival">
                      Hàng mới về
                    </div>
                  </div>
                  <div class="price-box">
                    <span class="old-price" v-if="priceDisplay(item).hasDiscount">{{ formatPrice(priceDisplay(item).listPrice) }}đ</span>
                    <span class="new-price">{{ priceDisplay(item).saleLabel }}</span>
                  </div>
                  <el-button type="primary" class="add-to-cart-btn" @click.stop="addToCart(item)">
                    Thêm vào giỏ
                  </el-button>
                </div>
              </el-card>
            </div>
          </div>
        </div>

        <!-- Nút Phải -->
        <button 
          class="slider-arrow right" 
          @click="slideRight" 
          v-show="sliderCanScroll"
          title="Xem thêm sang phải"
        >
          <el-icon><ArrowRight /></el-icon>
        </button>
      </div>
    </section>

    <!-- SECTION BỔ SUNG: KHÁM PHÁ BỘ SƯU TẬP -->
    <section class="products-section container fade-in-up" style="margin-top: 40px; margin-bottom: 60px; animation-delay: 0.1s;">
      <div class="section-title" style="margin-bottom: 40px;">
        <span>KHÁM PHÁ BỘ SƯU TẬP</span>
      </div>

      <ProductSkeleton v-if="loadingRecommended" :count="8" />

      <el-row :gutter="20" v-else>
        <el-col :xs="24" :sm="12" :md="8" :lg="6" v-for="item in recommendedProducts" :key="item.id" style="margin-bottom: 20px;">
          <el-card
            :body-style="{ padding: '0px' }"
            class="product-card"
            shadow="hover"
            @click="$router.push('/product/' + item.id)"
            style="cursor: pointer;"
          >
            <el-image :src="item.image_url || item.image" class="product-img" fit="cover" loading="lazy" />
            <div class="product-info">
              <h4 class="product-name">{{ item.ten_san_pham || item.name }}</h4>
              <div class="arrival-badge-slot">
                <div v-if="checkIsNewArrival(item.created_at)" class="tag-new-arrival">
                  Hàng mới về
                </div>
              </div>
              <div class="price-box">
                <span class="old-price" v-if="priceDisplay(item).hasDiscount">{{ formatPrice(priceDisplay(item).listPrice) }}đ</span>
                <span class="new-price">{{ priceDisplay(item).saleLabel }}</span>
              </div>
              <el-button type="primary" class="add-to-cart-btn" @click.stop="addToCart(item)">
                Thêm vào giỏ
              </el-button>
            </div>
          </el-card>
        </el-col>
      </el-row>
    </section>

    <AppFooter />
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted, nextTick } from 'vue'
import { useRoute } from 'vue-router'
import { Loading, Star, Van, CreditCard, Service, StarFilled, ArrowLeft, ArrowRight } from '@element-plus/icons-vue'
import { toastSuccess, toastWarning } from '../utils/toast'
import AppHeader from '../components/AppHeader.vue'
import AppNavbar from '../components/AppNavbar.vue'
import AppFooter from '../components/AppFooter.vue'
import ProductSkeleton from '../components/ProductSkeleton.vue'
import { useCartStore } from '../stores/cart'
import { useAuthStore } from '../stores/auth'
import { ensureAuthForPurchase } from '../utils/promptAuthForPurchase'
import { useSettingsStore } from '../stores/settings'
import { getProducts, getHotDealProducts } from '../services/productService'
import { formatPrice, checkIsNewArrival } from '../utils/format'
import { getProductPriceDisplay, getDiscountPercent as calcDiscountPercent } from '../utils/productPrice'
import { useSEO } from '../utils/useSEO'

const route = useRoute()
const cartStore = useCartStore()
const authStore = useAuthStore()
const settingsStore = useSettingsStore()
const loading = ref(true)
const featuredProducts = ref([])


const sliderRef = ref(null)
const sliderCanScroll = ref(false)
const hotDealSliderRef = ref(null)
const hotDealSliderCanScroll = ref(false)
const windowWidth = ref(typeof window !== 'undefined' ? window.innerWidth : 1200)

/** Desktop ~1.9:1; mobile ~1.85:1 — banner dọc/ngang đồng chiều cao */
const BANNER_ASPECT_DESKTOP = 1.9
const BANNER_ASPECT_MOBILE = 1.85
const carouselHeight = computed(() => {
  const w = windowWidth.value
  const isMobile = w <= 768
  const horizontalPad = isMobile ? 0 : 40
  const contentWidth = isMobile ? w : Math.min(w, 1200) - horizontalPad
  const aspect = isMobile ? BANNER_ASPECT_MOBILE : BANNER_ASPECT_DESKTOP
  const height = Math.round(contentWidth / aspect)
  const minH = isMobile ? 200 : 160
  const maxH = isMobile ? 440 : 620
  const clamped = Math.max(minH, Math.min(height, maxH))
  return `${clamped}px`
})

const sideAdBannerStyle = computed(() => {
  if (windowWidth.value <= 1820) return {}
  return { height: carouselHeight.value }
})

const carouselIndicatorPosition = computed(() =>
  windowWidth.value <= 768 ? 'inside' : 'outside'
)

const handleWindowResize = () => {
  windowWidth.value = window.innerWidth
  handleScroll()
  handleHotDealScroll()
}

const getSliderStep = (el) => {
  if (!el) return 305
  const cardWidth = el.querySelector('.slider-item')?.offsetWidth || 285
  return cardWidth + 20
}

const slideSlider = (el, direction) => {
  if (!el) return
  const step = getSliderStep(el)
  if (direction === 'left') {
    if (el.scrollLeft <= 15) {
      el.scrollTo({ left: el.scrollWidth - el.clientWidth, behavior: 'smooth' })
    } else {
      el.scrollBy({ left: -step, behavior: 'smooth' })
    }
  } else if (el.scrollLeft + el.clientWidth >= el.scrollWidth - 15) {
    el.scrollTo({ left: 0, behavior: 'smooth' })
  } else {
    el.scrollBy({ left: step, behavior: 'smooth' })
  }
}

const updateSliderCanScroll = (el, canScrollRef) => {
  if (!el) return
  const { scrollWidth, clientWidth } = el
  canScrollRef.value = scrollWidth > clientWidth + 15
}

const slideLeft = () => slideSlider(sliderRef.value, 'left')
const slideRight = () => slideSlider(sliderRef.value, 'right')
const slideHotDealLeft = () => slideSlider(hotDealSliderRef.value, 'left')
const slideHotDealRight = () => slideSlider(hotDealSliderRef.value, 'right')

const handleScroll = () => updateSliderCanScroll(sliderRef.value, sliderCanScroll)
const handleHotDealScroll = () => updateSliderCanScroll(hotDealSliderRef.value, hotDealSliderCanScroll)

const hotDealProducts = ref([])
const loadingRecommended = ref(true)
const recommendedProducts = ref([])
const priceDisplay = (item) => getProductPriceDisplay(item)
const getDiscountPercent = (item) => calcDiscountPercent(item)

const homeCategories = ref([
  { 
    name: 'Đèn chùm', 
    icon: `<svg width="42" height="42" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M12 2v4M8 6h8M6 6h12v1M9 7l-1 6M15 7l1 6M5 14h14M12 14v6M10 20h4M4 14l1 6M20 14l-1 6" stroke="#D8B257" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/></svg>`
  },
  { 
    name: 'Đèn thả', 
    icon: `<svg width="42" height="42" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M12 2v6M7 16h10L19 9H5l2 7zM12 16v4M10 20h4" stroke="#D8B257" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/></svg>`
  },
  { 
    name: 'Đèn bàn', 
    icon: `<svg width="42" height="42" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M9 21h6M12 21V11M8 11h8l-2-6H10l-2 6zM15 5h-1M11 5h-1" stroke="#D8B257" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/></svg>`
  },
  { 
    name: 'Đèn ốp trần', 
    icon: `<svg width="42" height="42" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M4 3h16M2 7h20v2H2V7zM6 10c0 4.418 2.686 8 6 8s6-3.582 6-8v-1H6v1z" stroke="#D8B257" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/></svg>`
  },
  { 
    name: 'Đèn quạt', 
    icon: `<svg width="42" height="42" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><circle cx="12" cy="12" r="3" stroke="#D8B257" stroke-width="1.5"/><path d="M12 2v7M12 15v7M2 12h7M15 12h7M5 8l4 4M15 12l4 4" stroke="#D8B257" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/></svg>`
  }
])

const fetchProducts = async () => {
  loading.value = true
  loadingRecommended.value = true
  
  // Gọi API lấy TẤT CẢ sản phẩm + Hot Deal do Admin chọn
  const [result, hotResult] = await Promise.all([getProducts(), getHotDealProducts()])
  
  if (result && result.success && Array.isArray(result.data)) {
    const allProducts = result.data
    
    // 1. Sản phẩm nổi bật (Sắp xếp theo thời gian mới nhất - Newest First để làm nổi bật Hàng Mới Về)
    const sortedNewest = [...allProducts].sort((a, b) => {
      const dateA = a.created_at ? new Date(a.created_at) : new Date(0)
      const dateB = b.created_at ? new Date(b.created_at) : new Date(0)
      return dateB - dateA
    })
    featuredProducts.value = sortedNewest.slice(0, 12)
    
    // 2. Khám phá bộ sưu tập: random thuần 8 sản phẩm mỗi lần tải trang
    recommendedProducts.value = [...allProducts].sort(() => 0.5 - Math.random()).slice(0, 8)

    // 3. Hot Deals - đồng bộ theo danh sách Admin chọn (single source of truth)
    if (hotResult && hotResult.success) {
      hotDealProducts.value = Array.isArray(hotResult.data) ? hotResult.data.slice(0, 10) : [] // max 10 = HOT_DEAL_MAX (products.php)
    } else {
      // Fallback: lấy sản phẩm có old_price > price
      const discountItems = allProducts.filter(p => Number(p.old_price) > Number(p.price))
      if (discountItems.length >= 2) {
        hotDealProducts.value = discountItems.slice(0, 5)
      } else {
        hotDealProducts.value = [...allProducts].sort(() => 0.5 - Math.random()).slice(0, 5)
      }
    }
  }
  
  loading.value = false
  loadingRecommended.value = false
  
  nextTick(() => {
    handleScroll()
    handleHotDealScroll()
  })
}

onMounted(() => {
  useSEO({
    title: 'Đèn Hoa Mỹ - Hệ thống đèn trang trí cao cấp Hải Phòng',
    description: 'Đèn Hoa Mỹ - Chuyên cung cấp đèn chùm, đèn thả, đèn ốp trần, đèn vách cao cấp. Showroom tại Hải Phòng và giao hàng toàn quốc.',
    keywords: 'đèn trang trí, đèn chùm, đèn thả, đèn ốp trần, đèn Hải Phòng, Đèn Hoa Mỹ',
    image: settingsStore.sys_logo_url
  })
  fetchProducts()
  window.addEventListener('resize', handleWindowResize)
})

onUnmounted(() => {
  window.removeEventListener('resize', handleWindowResize)
})

const addToCart = (item) => {
  if (!ensureAuthForPurchase(authStore, route.fullPath)) return

  const result = cartStore.addItem({
    id: item.id, 
    code: item.ma_san_pham,
    name: item.ten_san_pham || item.name,
    image: item.image_url || item.image,
    price: priceDisplay(item).salePrice,
    stock: item.stock != null ? Number(item.stock) : null
  })
  if (result.success) {
    toastSuccess(result.message)
  } else {
    toastWarning(result.message)
  }
}
</script>

<style scoped>
/* --- 1. Cấu trúc nền và khung chứa --- */
.home-wrapper { background-color: #f7f8fa; min-height: 100vh; }
.container { width: 1200px; margin: 0 auto; max-width: 100%; padding: 0 20px; box-sizing: border-box; }

/* --- 2. Khu vực Hero (Slider & Banner Phụ) --- */
.hero-section { margin-top: 20px; }
.main-banner-wrapper { width: 100%; }
.main-carousel { border-radius: 8px; overflow: hidden; box-shadow: 0 5px 20px rgba(0,0,0,0.05); }
:deep(.main-carousel .el-carousel__item) {
  height: 100%;
}
.carousel-banner-img {
  width: 100%;
  height: 100%;
  display: block;
  object-fit: cover;
  object-position: center;
}

/* Thanh dịch vụ nằm ngang (Service Bar) */
.service-bar { 
  display: flex; 
  justify-content: space-between; 
  background: #fff; 
  padding: 25px; 
  border-radius: 12px; 
  margin-top: 25px; 
  box-shadow: 0 5px 15px rgba(0,0,0,0.03);
  border: 1px solid #f0f0f0;
}
.service-item { display: flex; align-items: center; gap: 15px; }
.service-icon { font-size: 30px; color: #D8B257; filter: drop-shadow(0 2px 5px rgba(216, 178, 87, 0.2)); }
.service-info h5 { margin: 0 0 3px; font-size: 13px; color: #333; font-weight: bold; }
.service-info p { margin: 0; font-size: 12px; color: #888; }

/* Carousel indicators */
:deep(.el-carousel__indicators--outside) { margin-top: 10px; }
:deep(.el-carousel__button) { width: 10px; height: 3px; border-radius: 2px; }
:deep(.is-active .el-carousel__button) { background-color: #D8B257; width: 30px; }

/* --- 3. Phần danh mục sản phẩm --- */
.category-grid {
  display: flex;
  justify-content: center;
  flex-wrap: wrap;
  gap: 20px;
  margin-bottom: 45px;
}

.category-card {
  width: 170px;
  background: #fff;
  border: 1px solid #e4e7ed;
  border-radius: 12px;
  padding: 20px 10px;
  text-align: center;
  cursor: pointer;
  transition: all 0.3s cubic-bezier(0.25, 1, 0.5, 1);
  box-shadow: 0 1px 3px rgba(0,0,0,0.02);
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
}
.category-card:hover {
  transform: translateY(-5px);
  box-shadow: 0 12px 25px rgba(0,0,0,0.08);
  border-color: #D8B257;
}
.cat-icon-wrap {
  width: 60px;
  height: 60px;
  margin-bottom: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  background-color: #faf6eb;
  border-radius: 50%;
  transition: all 0.3s ease;
}
.category-card:hover .cat-icon-wrap {
  background-color: #f7ebd2;
}
.cat-name {
  font-size: 14px;
  color: #333;
  font-weight: bold;
  margin: 0;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  width: 100%;
  text-align: center;
}

/* --- 4. Phần Hot Deal (slider 1 dòng) --- */
.hot-deal-slider-item {
  cursor: pointer;
}

.hot-deal-card {
  background: #ffffff;
  border-radius: 12px;
  overflow: hidden;
  border: 1px solid #f0f0f0;
  transition: all 0.3s cubic-bezier(0.25, 0.8, 0.25, 1);
  position: relative;
  cursor: pointer;
  box-shadow: 0 1px 3px rgba(0,0,0,0.02);
}
.hot-deal-card:hover {
  transform: translateY(-5px);
  box-shadow: 0 12px 25px rgba(0,0,0,0.08);
  border-color: #D8B257;
}

.discount-badge {
  position: absolute;
  top: 10px;
  left: 10px;
  background-color: rgba(216, 178, 87, 0.95);
  color: #fff;
  border-radius: 4px;
  padding: 3px 6px;
  display: flex;
  flex-direction: column;
  align-items: center;
  z-index: 10;
  box-shadow: 0 2px 5px rgba(0,0,0,0.1);
}
.discount-badge .pct {
  font-size: 14px;
  font-weight: bold;
  color: #000;
}
.discount-badge .label {
  font-size: 10px;
  text-transform: uppercase;
  color: #000;
  font-weight: bold;
}
.delivery-badge {
  position: absolute;
  top: 10px;
  right: 10px;
  background-color: #fff;
  color: #D8B257;
  border-radius: 50%;
  width: 32px;
  height: 32px;
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 10;
  font-size: 16px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
}

.deal-img-wrapper {
  width: 100%;
  height: 220px;
  overflow: hidden;
}
.deal-img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.deal-info {
  padding: 15px;
  text-align: left;
}
.arrival-badge-slot {
  min-height: 24px;
  display: flex;
  align-items: center;
  justify-content: center;
  margin: 4px 0 6px;
}
.deal-name {
  font-size: 14px;
  color: #333;
  font-weight: 600;
  margin: 0 0 8px;
  height: 38px;
  overflow: hidden;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  line-clamp: 2;
  -webkit-box-orient: vertical;
}

.stars-box {
  display: flex;
  gap: 2px;
  margin-bottom: 10px;
}
.star-on {
  color: #F7BA2A;
  font-size: 14px;
}

.deal-price-box {
  display: flex;
  flex-direction: column;
}
.deal-price-box .old-price {
  font-size: 13px;
  color: #aaa;
  text-decoration: line-through;
  margin-bottom: 2px;
}
.deal-price-box .new-price {
  font-size: 18px;
  color: #d93025;
  font-weight: bold;
}

/* --- Banner ngang (trước Hot Deal) --- */
.bottom-ad-section {
  margin-top: 50px;
  margin-bottom: 10px;
}
.bottom-ad-banner {
  display: block;
  width: 100%;
  aspect-ratio: 1920 / 459;
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 5px 20px rgba(0, 0, 0, 0.06);
  border: 1px solid #f0f0f0;
  transition: transform 0.35s cubic-bezier(0.25, 0.8, 0.25, 1), box-shadow 0.35s;
}
.bottom-ad-banner img {
  width: 100%;
  height: 100%;
  display: block;
  object-fit: cover;
  object-position: center;
}
.bottom-ad-banner:hover {
  transform: translateY(-3px);
  box-shadow: 0 12px 28px rgba(216, 178, 87, 0.18);
  border-color: #D8B257;
}
/* --- 5. Phần sản phẩm nổi bật --- */
.products-section { margin-top: 60px; }
.section-title { text-align: center; margin-bottom: 40px; position: relative; }
.section-title::after { content: ''; position: absolute; bottom: -10px; left: 50%; transform: translateX(-50%); width: 50px; height: 3px; background: #D8B257; }
.section-title span { font-size: 24px; font-weight: bold; color: #222; text-transform: uppercase; letter-spacing: 1px; }

/* Card sản phẩm */
.product-card { border-radius: 10px; overflow: hidden !important; overflow-x: hidden !important; border: 1px solid #f0f0f0; transition: all 0.3s cubic-bezier(0.25, 0.8, 0.25, 1); }
.product-card:hover { transform: translateY(-8px); box-shadow: 0 15px 30px rgba(0,0,0,0.1); border-color: #D8B257; }
.product-img { width: 100%; height: 260px; contain: paint; }

.product-info { padding: 20px; text-align: center; }
.product-name { font-size: 15px; color: #333; margin: 0 0 12px; height: 40px; overflow: hidden; display: -webkit-box; -webkit-line-clamp: 2; line-clamp: 2; -webkit-box-orient: vertical; font-weight: 500; }

.price-box { margin-bottom: 18px; }
.old-price { text-decoration: line-through; color: #bbb; font-size: 13px; margin-right: 10px; }
.new-price { color: #d93025; font-weight: bold; font-size: 19px; }

.add-to-cart-btn { width: 100%; height: 40px; background-color: #000; border-color: #000; color: #D8B257; font-weight: bold; border-radius: 20px; transition: all 0.3s; }
.add-to-cart-btn:hover { background-color: #D8B257; border-color: #D8B257; color: #000; transform: scale(1.02); }

@media (max-width: 992px) {
  .service-bar { flex-wrap: wrap; gap: 20px; justify-content: center; }
}

/* --- Mobile 768px --- */
@media (max-width: 768px) {
  .container { padding: 0 12px; }
  /* Banner sát header, full width; bỏ khoảng trắng thừa */
  .hero-section {
    margin-top: 0;
  }
  .hero-section.container {
    padding-left: 0;
    padding-right: 0;
  }
  .hero-section .main-carousel {
    border-radius: 0;
    box-shadow: none;
  }
  .hero-section .main-banner-wrapper {
    margin-bottom: 0;
  }
  :deep(.main-carousel .el-carousel__indicators--inside) {
    bottom: 10px;
  }
  :deep(.main-carousel .el-carousel__indicators--outside) {
    margin-top: 0;
  }
  .hero-section .service-bar {
    margin-left: 12px;
    margin-right: 12px;
    margin-top: 10px;
  }
  .section-title span { font-size: 18px; }
  .service-bar { padding: 15px; gap: 15px; }
  .service-item { flex: 1 1 45%; min-width: 140px; }
  .service-info h5 { font-size: 12px; }
  .service-info p { font-size: 11px; }
  .category-grid { gap: 10px; }
  .category-card { width: 110px; padding: 12px 6px; }
  .cat-icon-wrap { width: 44px; height: 44px; }
  .cat-name { font-size: 12px; }
  .hot-deal-slider-item .deal-img-wrapper { height: 160px; }
  .deal-name { font-size: 13px; height: 34px; }
  .deal-price-box .new-price { font-size: 15px; }
  .product-img { height: 180px; }
  .product-name { font-size: 13px; height: 36px; }
  .new-price { font-size: 16px; }
  .add-to-cart-btn { height: 36px; font-size: 13px; }
  .slider-item { width: 240px !important; }
  .arrival-badge-slot {
    min-height: 22px;
    margin: 4px 0;
  }
}

/* --- Điện thoại nhỏ 480px --- */
@media (max-width: 480px) {
  .service-bar { flex-direction: column; align-items: flex-start; }
  .service-item { flex: 1 1 100%; }
  .category-card { width: 90px; padding: 10px 4px; }
  .cat-icon-wrap { width: 38px; height: 38px; }
  .cat-name { font-size: 11px; }
  .section-title span { font-size: 16px; }
}

/* ==========================================================================
   CAROUSEL/SLIDER STYLE CHO SẢN PHẨM NỔI BẬT (LUXURY STYLE)
   ========================================================================== */
.featured-slider-container {
  position: relative;
  width: 100%;
}

.slider-viewport {
  overflow-x: auto;
  scroll-behavior: smooth;
  width: 100%;
  scroll-snap-type: x proximity;
  scroll-padding-inline: 6px;
  overscroll-behavior-x: contain;
  scrollbar-width: none !important; /* Hộp cuộn ẩn hoàn toàn trên Firefox */
  -ms-overflow-style: none !important; /* Hộp cuộn ẩn hoàn toàn trên IE/Edge */
  padding: 12px 0 25px 0 !important;
}

.slider-viewport::-webkit-scrollbar {
  display: none !important; /* Hộp cuộn ẩn hoàn toàn trên Chrome/Safari */
}

.slider-track {
  display: flex !important;
  gap: 20px !important;
  width: max-content !important; /* Đảm bảo con track không wrap xuống dòng */
}

.slider-item {
  width: 285px !important; /* Chiều rộng thẻ sản phẩm chuẩn */
  flex-shrink: 0 !important;
  scroll-snap-align: start;
}

/* Nút dạng tròn Floating kính mờ Luxury */
.slider-arrow {
  position: absolute !important;
  top: 50% !important;
  transform: translateY(-50%) !important;
  width: 46px !important;
  height: 46px !important;
  border-radius: 50% !important;
  background: rgba(255, 255, 255, 0.95) !important;
  border: 1px solid rgba(0, 0, 0, 0.08) !important;
  box-shadow: 0 6px 16px rgba(0, 0, 0, 0.08) !important;
  display: flex !important;
  align-items: center !important;
  justify-content: center !important;
  cursor: pointer !important;
  z-index: 50 !important;
  transition: all 0.4s cubic-bezier(0.25, 0.8, 0.25, 1) !important;
  color: #333 !important;
}

.slider-arrow:hover {
  background: #C5A059 !important;
  color: #fff !important;
  border-color: #C5A059 !important;
  box-shadow: 0 8px 24px rgba(197, 160, 89, 0.3) !important;
  transform: translateY(-50%) scale(1.1) !important;
}

.slider-arrow.left {
  left: -23px !important; /* Nhô nhẹ ra ngoài lề */
}

.slider-arrow.right {
  right: -23px !important; /* Nhô nhẹ ra ngoài lề */
}

/* Biến mất mượt mà khi ẩn */
.slider-arrow-enter-active,
.slider-arrow-leave-active {
  transition: opacity 0.3s ease;
}
.slider-arrow-enter-from,
.slider-arrow-leave-to {
  opacity: 0;
}

/* Responsive tối ưu các lớp thiết bị */
@media (max-width: 600px) {
  .slider-item {
    width: 210px !important;
  }
  .slider-arrow {
    display: none !important;
  }
  .slider-viewport {
    scroll-snap-type: x mandatory;
    padding: 8px 0 18px 0 !important;
  }
}

@media (max-width: 560px) {
  .hot-deal-slider-item .deal-img-wrapper { height: 150px; }
}

@media (max-width: 390px) {
  .container {
    padding: 0 10px;
  }
  .service-bar {
    padding: 12px;
    gap: 12px;
  }
  .service-icon {
    font-size: 24px;
  }
  .service-info h5 {
    font-size: 11px;
  }
  .service-info p {
    font-size: 10px;
  }
  .slider-item {
    width: 186px !important;
  }
  .deal-img-wrapper {
    height: 150px;
  }
  .product-img {
    height: 168px;
  }
  .add-to-cart-btn {
    height: 34px;
    font-size: 12px;
  }
}

/* ==========================================================================
   SKYSCRAPER AD BANNERS (LEFT & RIGHT) - LUXURY STYLE
   ========================================================================== */
.hero-wrapper-outer {
  position: relative;
  width: 100%;
}

.side-adskyscraper {
  --side-ad-width: 260px;
  position: absolute;
  top: 20px;
  width: var(--side-ad-width);
  height: 620px; /* fallback; desktop bind theo carouselHeight */
  border-radius: 8px;
  overflow: hidden;
  box-shadow: 0 8px 30px rgba(0, 0, 0, 0.08);
  transition: transform 0.4s cubic-bezier(0.25, 0.8, 0.25, 1), box-shadow 0.4s cubic-bezier(0.25, 0.8, 0.25, 1);
  z-index: 10; /* Khôi phục z-index 10 */
  background-color: #fff;
  border: 1px solid rgba(0, 0, 0, 0.05);
}

.side-adskyscraper img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  display: block;
}

.side-adskyscraper:hover {
  transform: translateY(-5px);
  box-shadow: 0 16px 36px rgba(216, 178, 87, 0.2);
  border-color: #D8B257;
}

/* Định vị sát lề lưới 1200px (1200px / 2 = 600px + 15px gap = 615px) */
.side-adskyscraper.left-ad {
  right: calc(50% + 615px);
}

.side-adskyscraper.right-ad {
  left: calc(50% + 615px);
}

/* Ẩn khi màn hẹp — cần ~1820px+ để banner 260px không đè khung 1200px */
@media (max-width: 1820px) {
  .side-adskyscraper {
    display: none;
  }
}
</style>