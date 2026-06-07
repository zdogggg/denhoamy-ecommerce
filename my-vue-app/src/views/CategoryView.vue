<template>
  <div class="category-wrapper">
    <AppHeader />
    <AppNavbar activeIndex="2" />

    <div class="container main-content">
      <el-breadcrumb :separator-icon="ArrowRight" class="breadcrumb-custom">
        <el-breadcrumb-item :to="{ path: '/' }">Trang chủ</el-breadcrumb-item>
        <!-- Hiện danh mục cha nếu đang ở danh mục con -->
        <el-breadcrumb-item v-if="route.query.type && route.query.sub" :to="{ path: '/category', query: { type: route.query.type } }">
          {{ route.query.type }}
        </el-breadcrumb-item>
        <!-- Hiện danh mục hiện tại -->
        <el-breadcrumb-item>{{ route.query.sub || route.query.type || 'Tất cả sản phẩm' }}</el-breadcrumb-item>
      </el-breadcrumb>

      <el-row :gutter="30">
        <el-col :xs="24" :sm="8" :md="6" :lg="6">
          <div class="sidebar-title">Danh mục sản phẩm</div>
          <el-menu :default-active="activeSidebar" class="vertical-menu" active-text-color="#D8B257" @select="handleSidebarSelect" :default-openeds="categoriesStore.map(c => c.name)">
            <el-menu-item index="all">TẤT CẢ SẢN PHẨM</el-menu-item>
            
            <template v-for="cat in categoriesStore" :key="cat.id">
              <el-sub-menu v-if="cat.children && cat.children.length > 0" :index="cat.name">
                <template #title><span style="text-transform: uppercase;">{{ cat.name }}</span></template>
                <el-menu-item 
                  v-for="child in cat.children" 
                  :key="child.id" 
                  :index="`${cat.name}_${child.name}`"
                >
                  {{ child.name }}
                </el-menu-item>
              </el-sub-menu>
              
              <el-menu-item v-else :index="cat.name" style="text-transform: uppercase;">
                {{ cat.name }}
              </el-menu-item>
            </template>
          </el-menu>
        </el-col>

        <el-col :xs="24" :sm="16" :md="18" :lg="18" class="fade-in-up">
          <div class="category-header">
            <h2 class="category-title">{{ currentCategory || 'TẤT CẢ SẢN PHẨM' }}
              <span v-if="!loading" style="font-size: 14px; color: #999; font-weight: normal; margin-left: 10px;">({{ totalProducts }} sản phẩm)</span>
            </h2>

            <!-- BỘ LỌC TIÊU CHÍ -->
            <div class="filter-bar-section">
              <div class="filter-row">
                <span class="filter-label">Chọn theo tiêu chí</span>
                <div class="filter-tags">
                  <div :class="['filter-tag', { active: showFilterPanel }]" @click="showFilterPanel = !showFilterPanel">
                    <el-icon size="14"><Filter /></el-icon> Bộ lọc
                  </div>
                  <div v-for="pr in priceRanges" :key="pr.label" :class="['filter-tag', { active: selectedPriceRange === pr.label }]" @click="togglePriceRange(pr.label)">
                    {{ pr.label }}
                  </div>
                </div>
              </div>

              <!-- Panel lọc chi tiết (mở/đóng) -->
              <transition name="el-zoom-in-top">
                <div class="filter-panel" v-if="showFilterPanel">
                  <div class="filter-group">
                    <div class="filter-group-label">Chất liệu</div>
                    <div class="filter-group-options">
                      <div v-for="mat in availableMaterials" :key="mat" :class="['option-chip', { active: selectedMaterials.includes(mat) }]" @click="toggleFilter(selectedMaterials, mat)">{{ mat }}</div>
                    </div>
                  </div>
                  <div class="filter-group">
                    <div class="filter-group-label">Phong cách</div>
                    <div class="filter-group-options">
                      <div v-for="st in availableStyles" :key="st" :class="['option-chip', { active: selectedStyles.includes(st) }]" @click="toggleFilter(selectedStyles, st)">{{ st }}</div>
                    </div>
                  </div>
                  <div class="filter-group">
                    <div class="filter-group-label">Không gian</div>
                    <div class="filter-group-options">
                      <div v-for="sp in availableSpaces" :key="sp" :class="['option-chip', { active: selectedSpaces.includes(sp) }]" @click="toggleFilter(selectedSpaces, sp)">{{ sp }}</div>
                    </div>
                  </div>

                </div>
              </transition>

              <!-- Active Filters Tags -->
              <div class="active-filters" v-if="hasActiveFilters">
                <el-tag v-if="selectedPriceRange" closable @close="selectedPriceRange = ''" type="warning" size="small">{{ selectedPriceRange }}</el-tag>
                <el-tag v-for="mat in selectedMaterials" :key="'mat-' + mat" closable @close="toggleFilter(selectedMaterials, mat)" type="warning" size="small">{{ mat }}</el-tag>
                <el-tag v-for="st in selectedStyles" :key="'st-' + st" closable @close="toggleFilter(selectedStyles, st)" type="warning" size="small">{{ st }}</el-tag>
                <el-tag v-for="sp in selectedSpaces" :key="'sp-' + sp" closable @close="toggleFilter(selectedSpaces, sp)" type="warning" size="small">{{ sp }}</el-tag>
                <el-button link type="danger" size="small" @click="clearAllFilters" style="margin-left: 5px;">Xóa tất cả</el-button>
              </div>
            </div>

            <!-- SẮP XẾP -->
            <div class="sort-bar">
              <div class="sort-options">
                <span class="sort-label">Sắp xếp theo</span>
                <div class="sort-tags">
                  <div :class="['sort-tag', { active: sortOption === 'new' }]" @click="sortOption = 'new'; currentPage = 1; fetchData()">☆ Mới nhất</div>
                  <div :class="['sort-tag', { active: sortOption === 'asc' }]" @click="sortOption = 'asc'; currentPage = 1; fetchData()">↑ Giá Thấp → Cao</div>
                  <div :class="['sort-tag', { active: sortOption === 'desc' }]" @click="sortOption = 'desc'; currentPage = 1; fetchData()">↓ Giá Cao → Thấp</div>
                </div>
              </div>
              <div class="view-mode">
                <el-button-group>
                  <el-button size="small" :type="viewMode === 'grid' ? 'warning' : 'default'" @click="viewMode = 'grid'">
                    <el-icon style="margin-right: 5px;"><Grid /></el-icon> Lưới
                  </el-button>
                  <el-button size="small" :type="viewMode === 'list' ? 'warning' : 'default'" @click="viewMode = 'list'">
                    <el-icon style="margin-right: 5px;"><List /></el-icon> Cột
                  </el-button>
                </el-button-group>
              </div>
            </div>
          </div>

          <ProductSkeleton v-if="loading" :count="6" />

          <div v-else-if="products.length === 0" style="padding: 40px 0;">
            <el-empty description="Không tìm thấy sản phẩm nào" />
          </div>

          <el-row :gutter="20" v-if="!loading && viewMode === 'grid' && products.length > 0">
            <el-col :xs="12" :sm="12" :md="8" :lg="8" v-for="item in products" :key="item.id" style="margin-bottom: 20px;">
              <el-card :body-style="{ padding: '0px' }" class="product-card" shadow="hover" @click="$router.push('/product/' + item.id)" style="cursor: pointer;">
                <div class="img-wrapper">
                  <el-image :src="item.image_url" class="product-img" fit="cover" loading="lazy" />
                  <span class="product-code">{{ item.ma_san_pham }}</span>
                </div>
                <div class="product-info">
                  <h4 class="product-name">{{ item.ten_san_pham }}</h4>
                  <div v-if="checkIsNewArrival(item.created_at)" class="tag-new-arrival">
                    Hàng mới về
                  </div>
                  <div class="price-row">
                    <span class="old-price" v-if="priceDisplay(item).hasDiscount">{{ formatPrice(priceDisplay(item).listPrice) }}đ</span>
                    <span class="price-text">{{ priceDisplay(item).saleLabel }}</span>
                  </div>
                </div>
              </el-card>
            </el-col>
          </el-row>

          <div class="list-view-wrapper" v-if="!loading && viewMode === 'list' && products.length > 0">
            <el-card v-for="item in products" :key="item.id" :body-style="{ padding: '0px' }" class="product-card-list" shadow="hover" @click="$router.push('/product/' + item.id)" style="cursor: pointer;">
              <div class="list-item-inner">
                <div class="img-wrapper-list">
                  <el-image :src="item.image_url" class="product-img-list" fit="cover" loading="lazy" />
                  <span class="product-code">{{ item.ma_san_pham }}</span>
                </div>
                <div class="product-info-list">
                  <h4 class="product-name-list">{{ item.ten_san_pham }}</h4>
                  <div v-if="checkIsNewArrival(item.created_at)" class="tag-new-arrival">
                    Hàng mới về
                  </div>
                  <p class="product-material">{{ item.chat_lieu }} | {{ item.phong_cach }}</p>
                  <div class="price-text-list">{{ priceDisplay(item).saleLabel }}</div>
                  <el-button class="gold-btn btn-view-detail">Xem chi tiết</el-button>
                </div>
              </div>
            </el-card>
          </div>
          
          <div class="pagination-wrapper" v-if="!loading && totalProducts > pageSize">
            <el-pagination 
              background 
              layout="total, prev, pager, next" 
              :total="totalProducts"
              :page-size="pageSize"
              v-model:current-page="currentPage"
              @current-change="onPageChange"
            />
          </div>
        </el-col>
      </el-row>
    </div>

    <AppFooter />
  </div>
</template>

<script setup>
import { ref, computed, watch, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { Loading, Filter, ArrowRight, Grid, List } from '@element-plus/icons-vue'
import AppHeader from '../components/AppHeader.vue'
import AppNavbar from '../components/AppNavbar.vue'
import AppFooter from '../components/AppFooter.vue'
import ProductSkeleton from '../components/ProductSkeleton.vue'
import { getProducts, getProductFilterFacets } from '../services/productService'
import { getCategories } from '../services/categoryService'
import { formatPrice, checkIsNewArrival } from '../utils/format'
import { getProductPriceDisplay } from '../utils/productPrice'
import { useSEO } from '../utils/useSEO'

const route = useRoute()
const router = useRouter()

const sortOption = ref('new')
const viewMode = ref('grid')
const currentPage = ref(1)
const pageSize = 12
const loading = ref(true)
const products = ref([])
const totalProducts = ref(0)
const activeSidebar = ref('all')
const categoriesStore = ref([])
const filterFacets = ref({ materials: [], styles: [], spaces: [] })

// FILTER LOGIC
const showFilterPanel = ref(false)
const selectedPriceRange = ref('')
const selectedMaterials = ref([])
const selectedStyles = ref([])
const selectedSpaces = ref([])

const priceRanges = [
  { label: 'Dưới 1 triệu', min: 0, max: 1000000 },
  { label: '1 - 10 triệu', min: 1000000, max: 10000000 },
  { label: 'Trên 10 triệu', min: 10000000, max: Infinity },
]

const togglePriceRange = (label) => {
  selectedPriceRange.value = selectedPriceRange.value === label ? '' : label
}

const toggleFilter = (list, value) => {
  const idx = list.indexOf(value)
  if (idx >= 0) list.splice(idx, 1)
  else list.push(value)
}

const hasActiveFilters = computed(() =>
  selectedPriceRange.value ||
  selectedMaterials.value.length > 0 ||
  selectedStyles.value.length > 0 ||
  selectedSpaces.value.length > 0
)

const clearAllFilters = () => {
  selectedPriceRange.value = ''
  selectedMaterials.value = []
  selectedStyles.value = []
  selectedSpaces.value = []
}

const availableMaterials = computed(() => filterFacets.value.materials || [])
const availableStyles = computed(() => filterFacets.value.styles || [])
const availableSpaces = computed(() => filterFacets.value.spaces || [])

const buildListParams = () => {
  const params = {
    sort: sortOption.value,
    page: currentPage.value,
    limit: pageSize,
  }
  if (currentCategory.value) params.type = currentCategory.value
  if (searchKeyword.value) params.search = searchKeyword.value

  if (selectedPriceRange.value) {
    const range = priceRanges.find((r) => r.label === selectedPriceRange.value)
    if (range) {
      params.price_min = range.min
      if (range.max !== Infinity) params.price_max = range.max
    }
  }
  if (selectedMaterials.value.length) params.material = selectedMaterials.value.join(',')
  if (selectedStyles.value.length) params.style = selectedStyles.value.join(',')
  if (selectedSpaces.value.length) params.space = selectedSpaces.value.join(',')

  return params
}

const buildFacetParams = () => {
  const params = {}
  if (currentCategory.value) params.type = currentCategory.value
  if (searchKeyword.value) params.search = searchKeyword.value
  return params
}

const applyClientFilters = (list) => {
  let result = [...list]
  if (selectedPriceRange.value) {
    const range = priceRanges.find((r) => r.label === selectedPriceRange.value)
    if (range) {
      result = result.filter((p) => Number(p.price) >= range.min && Number(p.price) < range.max)
    }
  }
  if (selectedMaterials.value.length) {
    result = result.filter((p) =>
      p.chat_lieu && selectedMaterials.value.some((mat) => p.chat_lieu.includes(mat))
    )
  }
  if (selectedStyles.value.length) {
    result = result.filter((p) =>
      p.phong_cach && selectedStyles.value.some((st) => p.phong_cach.includes(st))
    )
  }
  if (selectedSpaces.value.length) {
    result = result.filter((p) =>
      p.khong_gian_lap_dat && selectedSpaces.value.some((sp) => p.khong_gian_lap_dat.includes(sp))
    )
  }
  return result
}

const onPageChange = (page) => {
  currentPage.value = page
  fetchData()
  window.scrollTo({ top: 0, behavior: 'smooth' })
}

watch(
  [selectedPriceRange, selectedMaterials, selectedStyles, selectedSpaces],
  () => {
    currentPage.value = 1
    fetchData()
  },
  { deep: true }
)

const currentCategory = computed(() => route.query.sub || route.query.type || '')
const searchKeyword = computed(() => route.query.search || '')

// Fallback data nếu API chưa chạy
const fallbackProducts = [
  { id: 1, ma_san_pham: 'DC04305', ten_san_pham: 'Đèn chùm DC04305 - Tân cổ điển', price: 15000000, old_price: 18500000, loai_den: 'Đèn chùm', chat_lieu: 'Hợp kim + thủy tinh', phong_cach: 'Tân cổ điển', image_url: 'https://images.unsplash.com/photo-1540932239986-30128078f3c5?q=80&w=400' },
  { id: 2, ma_san_pham: 'DC04304', ten_san_pham: 'Đèn chùm DC04304 - Phong cách Mỹ', price: 12500000, old_price: 15000000, loai_den: 'Đèn chùm', chat_lieu: 'Hợp kim + chao vải', phong_cach: 'Mỹ', image_url: 'https://images.unsplash.com/photo-1565814329452-e1efa11c5e89?q=80&w=400' },
  { id: 3, ma_san_pham: 'DC04302', ten_san_pham: 'Đèn chùm DC04302 - Hiện đại', price: 14200000, old_price: 16000000, loai_den: 'Đèn chùm', chat_lieu: 'Hợp kim + thủy tinh', phong_cach: 'Hiện đại', image_url: 'https://images.unsplash.com/photo-1513506003901-1e6a229e2d15?q=80&w=400' },
  { id: 7, ma_san_pham: 'DT03308', ten_san_pham: 'Đèn thả DT03308 - Phong cách Nhật', price: 3200000, old_price: 4000000, loai_den: 'Đèn thả', chat_lieu: 'Hợp kim + mây tre', phong_cach: 'Nhật', image_url: 'https://images.unsplash.com/photo-1565814329452-e1efa11c5e89?q=80&w=400' },
  { id: 10, ma_san_pham: 'DO01629', ten_san_pham: 'Đèn ốp trần DO01629 - Pha lê hiện đại', price: 4500000, old_price: 5500000, loai_den: 'Đèn ốp trần', chat_lieu: 'Hợp kim + pha lê', phong_cach: 'Hiện đại', image_url: 'https://images.unsplash.com/photo-1524484485831-a92fa817b3f1?q=80&w=400' },
  { id: 12, ma_san_pham: 'DV02084', ten_san_pham: 'Đèn vách DV02084 - Trung Hoa', price: 850000, old_price: 1100000, loai_den: 'Đèn vách', chat_lieu: 'Hợp kim + thủy tinh', phong_cach: 'Trung Hoa', image_url: 'https://images.unsplash.com/photo-1524484485831-a92fa817b3f1?q=80&w=400' },
]

const fetchFilterFacets = async () => {
  const result = await getProductFilterFacets(buildFacetParams())
  if (result?.success && result.facets) {
    filterFacets.value = result.facets
  }
}

const fetchData = async () => {
  loading.value = true
  const result = await getProducts(buildListParams())
  if (result && result.success) {
    products.value = result.data
    totalProducts.value = result.total
  } else {
    // Fallback nếu API chưa chạy
    let filtered = [...fallbackProducts]
    if (currentCategory.value) filtered = filtered.filter((p) => p.loai_den === currentCategory.value)
    if (searchKeyword.value) {
      const kw = searchKeyword.value.toLowerCase()
      filtered = filtered.filter(
        (p) => p.ten_san_pham.toLowerCase().includes(kw) || p.ma_san_pham.toLowerCase().includes(kw)
      )
    }
    filtered = applyClientFilters(filtered)
    if (sortOption.value === 'asc') filtered.sort((a, b) => a.price - b.price)
    else if (sortOption.value === 'desc') filtered.sort((a, b) => b.price - a.price)
    totalProducts.value = filtered.length
    const start = (currentPage.value - 1) * pageSize
    products.value = filtered.slice(start, start + pageSize)
  }
  loading.value = false

  const catName = currentCategory.value || 'Tất cả sản phẩm'
  useSEO({
    title: `${catName} - Đèn Hoa Mỹ`,
    description: `Khám phá bộ sưu tập ${catName} cao cấp tại Đèn Hoa Mỹ. ${totalProducts.value} sản phẩm, giao hàng toàn quốc.`,
    keywords: `${catName}, đèn trang trí, đèn cao cấp, Đèn Hoa Mỹ`,
  })
}

const fetchCategories = async () => {
  const res = await getCategories()
  if (res && res.success) {
    categoriesStore.value = res.data
  }
}

onMounted(() => {
  fetchFilterFacets()
  fetchData()
  fetchCategories()
})

const priceDisplay = (item) => getProductPriceDisplay(item)

const handleSidebarSelect = (index) => {
  if (index === 'all') {
    router.push({ path: '/category' })
  } else if (index.includes('_')) {
    const [type, sub] = index.split('_')
    router.push({ path: '/category', query: { type, sub } })
  } else {
    router.push({ path: '/category', query: { type: index } })
  }
  currentPage.value = 1
}

// Khi đổi route query -> fetch lại
watch(() => route.query, () => {
  currentPage.value = 1
  if (route.query.sub) {
    activeSidebar.value = route.query.type + '_' + route.query.sub
  } else {
    activeSidebar.value = route.query.type || 'all'
  }
  fetchFilterFacets()
  fetchData()
}, { immediate: false })
</script>

<style scoped>
/* --- 1. Cấu trúc nền và khung chứa --- */
.category-wrapper { background-color: #f7f8fa; min-height: 100vh; }
.container { width: 1200px; margin: 0 auto; max-width: 100%; padding: 0 20px; box-sizing: border-box; }
.main-content { margin-top: 20px; }
.breadcrumb-custom { padding: 20px 0; font-size: 14px; margin-bottom: 20px; border-bottom: 1px solid #f0f0f0; }

/* Sidebar bên trái (Danh mục) */
.sidebar-title { font-weight: bold; font-size: 16px; padding: 15px 20px; background-color: #fcfcfc; border-bottom: 2px solid #D8B257; }
.vertical-menu { border-right: none !important; }
:deep(.vertical-menu .el-menu-item) { font-size: 13px; border-bottom: 1px dashed #eee; font-weight: bold; }

.category-title { margin: 0 0 15px 0; font-size: 24px; font-weight: normal; text-transform: uppercase; }

/* --- 2. BỘ LỌC (FILTER BAR) --- */
.filter-bar-section { background: #fff; border: 1px solid #eaeaea; border-radius: 6px; padding: 15px; margin-bottom: 12px; }
.filter-row { display: flex; align-items: center; gap: 12px; flex-wrap: wrap; }
.filter-label { font-size: 13px; font-weight: 600; color: #333; }

/* Các thẻ lọc (Price, Material,...) */
.filter-tags { display: flex; gap: 8px; flex-wrap: wrap; }
.filter-tag,
.sort-tag {
  padding: 6px 14px;
  border: 1px solid #dcdfe6;
  border-radius: 20px;
  font-size: 12.5px;
  cursor: pointer;
  transition: all 0.2s ease;
}
.filter-tag { display: inline-flex; align-items: center; gap: 5px; }
.filter-tag.active { border-color: #D8B257; background: #fcf9f2; color: #D8B257; font-weight: 600; }

/* Panel lọc chi tiết khi mở rộng */
.filter-panel { margin-top: 12px; padding-top: 12px; border-top: 1px dashed #eaeaea; display: flex; flex-direction: column; gap: 12px; }
.filter-group { display: flex; align-items: flex-start; gap: 12px; }
.filter-group-label { font-size: 12.5px; font-weight: 600; color: #333; min-width: 70px; padding-top: 5px; }
.filter-group-options { display: flex; flex-wrap: wrap; gap: 8px; flex: 1; }
.option-chip { padding: 5px 12px; border: 1px solid #e4e7ed; border-radius: 4px; font-size: 12px; cursor: pointer; transition: all 0.2s ease; }
.option-chip.active { border-color: #D8B257; background: #fcf9f2; color: #D8B257; font-weight: 600; }


.active-filters { display: flex; flex-wrap: wrap; gap: 10px; align-items: center; margin-top: 15px; padding-top: 10px; border-top: 1px dashed #eaeaea; }

/* --- 3. THANH SẮP XẾP (SORT BAR) --- */
.sort-bar { display: flex; justify-content: space-between; align-items: center; padding: 10px 15px; background-color: #fff; border: 1px solid #eaeaea; border-radius: 6px; margin-bottom: 20px; }
.sort-options { display: flex; align-items: center; gap: 15px; }
.sort-label { font-size: 14px; font-weight: 600; color: #333; }
.sort-tags { display: flex; gap: 8px; }
.sort-tag.active { border-color: #D8B257; background: #D8B257; color: #fff; font-weight: 600; }

/* --- 4. DANH SÁCH SẢN PHẨM (Grid & List) --- */
.product-card { border-radius: 6px; border: 1px solid #eaeaea; text-align: center; transition: all 0.3s; overflow: hidden !important; overflow-x: hidden !important; }
.product-card:hover { transform: translateY(-3px); box-shadow: 0 10px 20px rgba(0,0,0,0.08); }
.img-wrapper { position: relative; }
.product-img { width: 100%; height: 250px; contain: paint; }
.product-code { position: absolute; bottom: 5px; right: 5px; background: rgba(0,0,0,0.5); color: #fff; font-size: 11px; padding: 2px 6px; border-radius: 3px; }
.product-info { padding: 15px; }
.product-name { font-size: 14px; color: #333; margin: 0 0 10px; font-weight: normal; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.price-row { display: flex; justify-content: center; gap: 10px; align-items: baseline; }
.price-text { color: #d93025; font-weight: bold; font-size: 15px; }
.old-price { color: #999; text-decoration: line-through; font-size: 13px; }

/* Chế độ hiển thị dạng cột (List View) */
.list-view-wrapper { display: flex; flex-direction: column; gap: 20px; }
.list-item-inner { display: flex; width: 100%; height: 220px; }
.img-wrapper-list { width: 300px; height: 100%; position: relative; border-right: 1px solid #eaeaea; overflow: hidden; }
.product-info-list { padding: 30px; flex: 1; text-align: left; }
.price-text-list { color: #D8B257; font-weight: bold; font-size: 18px; margin-bottom: 20px; }

.pagination-wrapper { margin-top: 30px; display: flex; justify-content: center; }

@media (max-width: 768px) {
  .container { padding: 0 10px; }
  .sidebar-title { font-size: 14px; padding: 10px; text-align: center; }
  .vertical-menu { max-height: 180px; overflow-y: auto; margin-bottom: 20px; border: 1px solid #eaeaea !important; border-radius: 6px; }
  :deep(.vertical-menu .el-menu-item) { font-size: 12px !important; height: 38px !important; line-height: 38px !important; }
  :deep(.vertical-menu .el-sub-menu__title) { font-size: 12px !important; height: 38px !important; line-height: 38px !important; }

  .category-title { font-size: 18px; text-align: center; }
  .filter-bar-section { padding: 10px; }
  .filter-row { flex-direction: column; align-items: flex-start; gap: 8px; }
  .filter-tags { width: 100%; }
  .filter-tag { padding: 4px 10px; font-size: 11.5px; }
  
  .sort-bar { flex-direction: column; align-items: stretch; gap: 10px; padding: 10px; }
  .sort-options { flex-direction: column; align-items: flex-start; gap: 8px; width: 100%; }
  .sort-tags { width: 100%; display: flex; justify-content: space-between; }
  .sort-tag { flex: 1; text-align: center; padding: 5px 2px; font-size: 11px; }
  
  .view-mode { display: flex !important; justify-content: center !important; width: 100% !important; margin-top: 5px !important; }
  .view-mode :deep(.el-button-group) { display: flex; width: 100%; }
  .view-mode :deep(.el-button) { flex: 1; }

  /* Stack list view details on mobile viewports safely */
  .list-item-inner { flex-direction: column; height: auto; }
  .img-wrapper-list { width: 100%; height: 180px; border-right: none; border-bottom: 1px solid #eaeaea; }
  .product-info-list { padding: 15px; text-align: center; }
  .btn-view-detail { width: 100% !important; }

  .product-img { height: 180px; }
  .product-name { font-size: 12.5px; height: 34px; line-height: 1.35; margin-bottom: 6px; }
  .price-text { font-size: 13.5px; }
  .old-price { font-size: 11px; }
  .product-info { padding: 10px; }
}
</style>