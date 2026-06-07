<template>
  <div>
    <el-alert
      v-if="dashboardError"
      title="Không thể tải đầy đủ dữ liệu thống kê"
      type="warning"
      :description="dashboardError"
      show-icon
      :closable="false"
      style="margin-bottom: 16px;"
    />

    <el-card shadow="never" class="filter-card">
      <div class="filter-row">
        <div class="filter-item">
          <span class="filter-label">Mốc thời gian</span>
          <el-select v-model="selectedPreset" placeholder="Chọn mốc" style="width: 180px;" @change="onFilterChanged">
            <el-option v-for="preset in presetOptions" :key="preset.value" :label="preset.label" :value="preset.value" />
          </el-select>
        </div>
        <div class="filter-item">
          <span class="filter-label">Năm thống kê</span>
          <el-select v-model="selectedYear" placeholder="Chọn năm" style="width: 140px;" :disabled="selectedPreset !== 'custom_year'" @change="onFilterChanged">
            <el-option v-for="year in yearOptions" :key="year" :label="`Năm ${year}`" :value="year" />
          </el-select>
        </div>
        <div class="filter-item">
          <span class="filter-label">Ngưỡng tồn kho thấp</span>
          <el-input-number
            v-model="selectedLowStockThreshold"
            :min="1"
            :max="1000"
            :step="1"
            controls-position="right"
            @change="onFilterChanged"
          />
        </div>
        <div class="filter-item">
          <span class="filter-label">Ngưỡng bán chạy</span>
          <el-input-number
            v-model="selectedMinTopSold"
            :min="1"
            :max="10000"
            :step="1"
            controls-position="right"
            @change="onFilterChanged"
          />
          <el-tooltip content="Chỉ hiện sản phẩm bán từ X chiếc trở lên trong kỳ (sau đó lấy top 5)" placement="top">
            <el-icon style="color: #909399; cursor: help;"><QuestionFilled /></el-icon>
          </el-tooltip>
        </div>
        <el-text type="info" size="small">Dữ liệu tự động cập nhật sau khi thay đổi bộ lọc</el-text>
      </div>
    </el-card>

    <el-tabs v-model="activeDashboardTab" class="dashboard-tabs">
      <el-tab-pane label="Tổng quan" name="overview">
        <div class="kpi-grid">
          <div class="kpi-item" v-for="stat in overviewStats" :key="stat.key || stat.title">
            <el-card shadow="always" :class="['stat-card', stat.color]"><el-statistic :title="stat.title" :value="stat.value" /></el-card>
          </div>
        </div>
        <el-row :gutter="20">
          <el-col :span="16">
            <el-card shadow="never">
              <template #header>
                <div class="card-header">
                  <span>{{ overviewChartTitle }}</span>
                  <el-button type="success" size="small" @click="exportDashboardExcel" :icon="Download" :loading="isExportingExcel">Xuất Tình Hình Kinh Doanh</el-button>
                </div>
              </template>
              <div style="height: 300px">
                <el-skeleton :loading="isDashboardLoading" animated :rows="8">
                  <template #default>
                    <Bar v-if="hasOverviewBarData" :data="barChartData" :options="overviewBarChartOptions" />
                    <el-empty v-else description="Chưa có đơn hàng trong kỳ này" />
                  </template>
                </el-skeleton>
              </div>
            </el-card>
          </el-col>
          <el-col :span="8">
            <el-card shadow="never" header="Tỉ lệ danh mục bán chạy (Theo số lượng)">
              <div style="height: 300px; display: flex; justify-content: center; padding: 10px 0;">
                <el-skeleton :loading="isDashboardLoading" animated :rows="8" style="width: 100%;">
                  <template #default>
                    <Doughnut v-if="hasCategoryData" :data="doughnutChartData" :options="doughnutChartOptions" />
                    <el-empty v-else description="Chưa có dữ liệu danh mục" />
                  </template>
                </el-skeleton>
              </div>
              <div v-if="hasCategoryData" class="category-legend-list">
                <div v-for="item in categoryLegendItems" :key="item.category" class="category-legend-item">
                  <span class="dot" :style="{ backgroundColor: item.color }"></span>
                  <span class="label">{{ item.category }}</span>
                  <span class="value">{{ item.sold_count }} ({{ item.sold_pct }}%)</span>
                </div>
                <el-alert
                  v-if="hasSingleCategoryDominance"
                  title="Danh mục hiện tại đang tập trung gần như toàn bộ vào một nhóm. Cần thêm dữ liệu để đánh giá phân bổ chính xác hơn."
                  type="info"
                  :closable="false"
                  show-icon
                  class="single-category-note"
                />
              </div>
            </el-card>
          </el-col>
        </el-row>
        <el-row :gutter="20" style="margin-top: 25px;">
          <el-col :span="12">
            <el-card shadow="never">
              <template #header>
                <span class="top-products-title">Top 5 sản phẩm bán chạy nhất</span>
              </template>
              <el-table :data="topProducts" stripe style="width: 100%" class="top-products-table">
                <template #empty>
                  <el-empty :image-size="80">
                    <template #description>
                      <p class="top-products-empty-text">{{ topProductsEmptyText }}</p>
                    </template>
                  </el-empty>
                </template>
                <el-table-column label="Ảnh" width="70">
                  <template #default="scope">
                    <el-image style="width: 40px; height: 40px; border-radius: 4px" :src="scope.row.image" fit="cover" :preview-src-list="[scope.row.image]" preview-teleported />
                  </template>
                </el-table-column>
                <el-table-column prop="name" label="Tên đèn" show-overflow-tooltip />
                <el-table-column prop="price" label="Giá TB/SP" width="120">
                  <template #default="scope">
                    {{ Number(scope.row.price).toLocaleString('vi-VN') }} đ
                  </template>
                </el-table-column>
                <el-table-column prop="sold_count" label="Đã bán" width="80" align="center">
                  <template #default="scope">
                    <el-tag type="success" effect="dark">{{ scope.row.sold_count }}</el-tag>
                  </template>
                </el-table-column>
                <el-table-column prop="revenue" label="Doanh thu" width="130">
                  <template #default="scope">
                    {{ formatMoneyVND(scope.row.revenue) }}
                  </template>
                </el-table-column>
              </el-table>
            </el-card>
          </el-col>
          <el-col :span="12">
            <el-card shadow="never">
              <template #header>
                <div class="low-stock-title-wrapper">
                  <span style="font-weight: bold;">Sản phẩm sắp hết hàng (Cần nhập thêm)</span>
                  <el-input
                    v-model="stockSearchQuery"
                    placeholder="Tìm kiếm mã/tên..."
                    size="small"
                    clearable
                    style="width: 180px;"
                    :prefix-icon="Search"
                  />
                </div>
              </template>
              <el-table :data="pagedLowStockProducts" stripe style="width: 100%" height="320">
                <template #empty>
                  <el-empty description="Không có sản phẩm sắp hết hàng" :image-size="80" />
                </template>
                 <el-table-column label="Ảnh" width="70">
                  <template #default="scope">
                    <el-image style="width: 40px; height: 40px; border-radius: 4px" :src="scope.row.image" fit="cover" :preview-src-list="[scope.row.image]" preview-teleported />
                  </template>
                </el-table-column>
                <el-table-column prop="name" label="Tên đèn" show-overflow-tooltip />
                <el-table-column prop="ma_san_pham" label="Mã SP" width="100" />
                <el-table-column prop="real_stock" label="Tồn kho" width="90" align="center">
                  <template #default="scope">
                    <el-tag type="danger" effect="dark">{{ scope.row.real_stock ?? scope.row.stock }}</el-tag>
                  </template>
                </el-table-column>
                <el-table-column prop="severity" label="Mức độ" width="100" align="center">
                  <template #default="scope">
                    <el-tag :type="getSeverityTagType(scope.row.severity)" effect="dark">{{ getSeverityLabel(scope.row.severity) }}</el-tag>
                  </template>
                </el-table-column>
                <el-table-column label="Thao tác" width="120" align="center">
                  <template #default="scope">
                    <el-button link type="primary" @click="emit('open-products', scope.row.id)">Nhập thêm</el-button>
                  </template>
                </el-table-column>
              </el-table>
              <div class="low-stock-pagination-wrapper">
                <el-pagination
                  v-model:current-page="lowStockCurrentPage"
                  v-model:page-size="lowStockPageSize"
                  :total="filteredLowStockProducts.length"
                  layout="prev, pager, next"
                  small
                  background
                />
              </div>
            </el-card>
          </el-col>
        </el-row>
      </el-tab-pane>

      <el-tab-pane label="Tài chính" name="finance">
        <div class="finance-hero-header">
          <div>
            <h3 class="finance-title">Phân tích tài chính</h3>
            <p class="finance-subtitle">Đồ thị và chỉ số tài chính theo kỳ lọc để theo dõi hiệu quả kinh doanh.</p>
          </div>
        </div>
        <div class="kpi-grid finance-grid">
          <div class="kpi-item" v-for="stat in financeStats" :key="stat.key || stat.title">
            <el-card shadow="always" :class="['stat-card', stat.color]"><el-statistic :title="stat.title" :value="stat.value" /></el-card>
          </div>
        </div>
        <el-row :gutter="20">
          <el-col :span="24">
            <el-card shadow="never" class="finance-chart-card">
              <template #header>
                <div class="card-header">
                  <div class="finance-chart-heading">
                    <span class="finance-chart-title">{{ financeChartTitle }}</span>
                    <span class="finance-chart-meta">Biểu đồ doanh thu chính của kỳ đang chọn</span>
                  </div>
                </div>
              </template>
              <div style="height: 340px">
                <el-skeleton :loading="isDashboardLoading" animated :rows="8">
                  <template #default>
                    <Bar v-if="hasFinanceBarData" :data="financeBarChartData" :options="financeBarChartOptions" />
                    <el-empty v-else description="Chưa có dữ liệu tài chính trong kỳ này" />
                  </template>
                </el-skeleton>
              </div>
            </el-card>
          </el-col>
        </el-row>
        <el-row :gutter="20" style="margin-top: 20px;">
          <el-col :span="8" v-for="card in financeCompareCards" :key="card.key">
            <el-card shadow="never" class="finance-compare-card">
              <div class="compare-title">{{ card.title }}</div>
              <div class="compare-values">
                <div class="compare-current">{{ formatMoneyVND(card.current) }}</div>
                <div class="compare-previous">Kỳ trước: {{ formatMoneyVND(card.previous) }}</div>
              </div>
              <div class="compare-delta-chip" :class="getDeltaClass(card.delta)">
                {{ formatDelta(card.delta) }}
              </div>
            </el-card>
          </el-col>
        </el-row>
      </el-tab-pane>
    </el-tabs>
  </div>
</template>

<script setup>
import { ref, onMounted, computed, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { getDashboardStats } from '../services/statisticsService'
import { Bar, Doughnut } from 'vue-chartjs'
import { Download, Search, QuestionFilled } from '@element-plus/icons-vue'
import { ElMessage } from 'element-plus'
import { Chart as ChartJS, Title, Tooltip, Legend, BarElement, CategoryScale, LinearScale, ArcElement } from 'chart.js'

ChartJS.register(Title, Tooltip, Legend, BarElement, CategoryScale, LinearScale, ArcElement)

const props = defineProps({
  stats: { type: Array, required: true }
})

const emit = defineEmits(['stats-loaded', 'open-products'])
const route = useRoute()
const router = useRouter()
const FILTER_STORAGE_KEY = 'admin_dashboard_filters_v2'
const QUERY_PRESET_KEY = 'dp_preset'
const QUERY_YEAR_KEY = 'dp_year'
const QUERY_STOCK_KEY = 'dp_stock'
const QUERY_TOP_SOLD_KEY = 'dp_top_sold'
const QUERY_TAB_KEY = 'dp_tab'

const chartPalette = ['#409EFF', '#67C23A', '#E6A23C', '#F56C6C', '#909399', '#14A44D', '#A855F7']
const dashboardError = ref('')
const isDashboardLoading = ref(true)
const barChartData = ref({ labels: [], datasets: [] })
const financeBarChartData = ref({ labels: [], datasets: [] })
const doughnutChartData = ref({ labels: [], datasets: [] })
const categoryLegendItems = ref([])
const barChartOptions = {
  responsive: true,
  maintainAspectRatio: false,
  plugins: {
    legend: { display: true, position: 'top' },
    tooltip: {
      callbacks: {
        label: (context) => `${context.dataset.label}: ${formatMoneyVND(context.parsed.y)}`
      }
    }
  }
}
const overviewBarChartOptions = {
  responsive: true,
  maintainAspectRatio: false,
  plugins: {
    legend: { display: true, position: 'top' },
    tooltip: {
      callbacks: {
        label: (context) => `${context.dataset.label}: ${Number(context.parsed.y || 0)} đơn`
      }
    }
  }
}
const doughnutChartOptions = {
  responsive: true,
  maintainAspectRatio: false,
  plugins: {
    legend: { display: false },
    tooltip: {
      callbacks: {
        label: (context) => {
          const total = context.dataset.data.reduce((sum, value) => sum + Number(value || 0), 0)
          const current = Number(context.parsed || 0)
          const percent = total > 0 ? ((current / total) * 100).toFixed(2) : '0.00'
          return `${context.label}: ${current} (${percent}%)`
        }
      }
    }
  }
}
const financeBarChartOptions = {
  responsive: true,
  maintainAspectRatio: false,
  plugins: {
    legend: { display: true, position: 'top' },
    tooltip: {
      callbacks: {
        label: (context) => `${context.dataset.label}: ${formatMoneyVND(context.parsed.y)}`
      }
    }
  }
}
const topProducts = ref([])
const lowStockProducts = ref([])
const isExportingExcel = ref(false)
const activeDashboardTab = ref('overview')
const financeCompare = ref({
  revenue_current: 0,
  revenue_previous: 0,
  revenue_change_pct: 0,
  profit_current: 0,
  profit_previous: 0,
  profit_change_pct: 0,
  aov_current: 0,
  aov_previous: 0,
  aov_change_pct: 0
})

// Tìm kiếm & Phân trang cho Danh sách tồn kho thấp
const stockSearchQuery = ref('')
const lowStockCurrentPage = ref(1)
const lowStockPageSize = ref(5)
const selectedPreset = ref('custom_year')
const selectedYear = ref(new Date().getFullYear())
const selectedLowStockThreshold = ref(5)
const selectedMinTopSold = ref(2)
const activeMinTopSold = ref(2)
const yearOptions = Array.from({ length: 6 }, (_, index) => new Date().getFullYear() - index)
const presetOptions = [
  { label: '7 ngày gần nhất', value: '7d' },
  { label: '30 ngày gần nhất', value: '30d' },
  { label: 'Năm hiện tại', value: 'current_year' },
  { label: 'Năm tùy chọn', value: 'custom_year' }
]
const isRouteSyncing = ref(false)
const overviewStatKeys = ['total_product_types', 'in_stock', 'total_orders', 'orders_today', 'pending_orders', 'cancel_rate']
const financeStatKeys = ['total_revenue', 'total_profit', 'avg_order_value']

const filteredLowStockProducts = computed(() => {
  if (!stockSearchQuery.value.trim()) {
    return lowStockProducts.value
  }
  const query = stockSearchQuery.value.toLowerCase().trim()
  return lowStockProducts.value.filter(p => 
    (p.name && p.name.toLowerCase().includes(query)) ||
    (p.ma_san_pham && p.ma_san_pham.toLowerCase().includes(query))
  )
})

const pagedLowStockProducts = computed(() => {
  const start = (lowStockCurrentPage.value - 1) * lowStockPageSize.value
  const end = start + lowStockPageSize.value
  return filteredLowStockProducts.value.slice(start, end)
})

watch(stockSearchQuery, () => {
  lowStockCurrentPage.value = 1
})

const formatMoneyVND = (value) => `${Number(value || 0).toLocaleString('vi-VN')} đ`
const hasOverviewBarData = computed(() => barChartData.value.datasets[0]?.data?.some((value) => Number(value || 0) > 0))
const hasFinanceBarData = computed(() => {
  const sets = financeBarChartData.value.datasets || []
  return sets.some((set) => (set.data || []).some((value) => Number(value || 0) > 0))
})
const hasCategoryData = computed(() => doughnutChartData.value.datasets[0]?.data?.some((value) => Number(value || 0) > 0))
const hasSingleCategoryDominance = computed(() => {
  const data = doughnutChartData.value.datasets[0]?.data || []
  const nonZeroCount = data.filter((item) => Number(item || 0) > 0).length
  return nonZeroCount === 1
})
const overviewStats = computed(() => props.stats.filter((item) => overviewStatKeys.includes(item.key)))
const financeStats = computed(() => props.stats.filter((item) => financeStatKeys.includes(item.key)))
const financeCompareCards = computed(() => [
  {
    key: 'revenue',
    title: 'Doanh thu kỳ này',
    current: financeCompare.value.revenue_current,
    previous: financeCompare.value.revenue_previous,
    delta: financeCompare.value.revenue_change_pct
  },
  {
    key: 'profit',
    title: 'Lợi nhuận kỳ này',
    current: financeCompare.value.profit_current,
    previous: financeCompare.value.profit_previous,
    delta: financeCompare.value.profit_change_pct
  },
  {
    key: 'aov',
    title: 'AOV kỳ này',
    current: financeCompare.value.aov_current,
    previous: financeCompare.value.aov_previous,
    delta: financeCompare.value.aov_change_pct
  }
])
const overviewChartTitle = computed(() => {
  if (selectedPreset.value === '7d') return 'Biểu đồ trạng thái đơn hàng 7 ngày gần nhất'
  if (selectedPreset.value === '30d') return 'Biểu đồ trạng thái đơn hàng 30 ngày gần nhất'
  if (selectedPreset.value === 'current_year') return `Biểu đồ trạng thái đơn hàng năm ${new Date().getFullYear()}`
  return `Biểu đồ trạng thái đơn hàng năm ${selectedYear.value}`
})

const topProductsEmptyText = computed(() =>
  `Chưa có sản phẩm nào bán từ ${activeMinTopSold.value} chiếc trở lên trong kỳ đã chọn. Hãy giảm ngưỡng bán chạy hoặc mở rộng mốc thời gian.`
)
const financeChartTitle = computed(() => {
  if (selectedPreset.value === '7d') return 'Biểu đồ Doanh thu vs Lợi nhuận (7 ngày gần nhất)'
  if (selectedPreset.value === '30d') return 'Biểu đồ Doanh thu vs Lợi nhuận (30 ngày gần nhất)'
  if (selectedPreset.value === 'current_year') return `Biểu đồ Doanh thu vs Lợi nhuận năm ${new Date().getFullYear()}`
  return `Biểu đồ Doanh thu vs Lợi nhuận năm ${selectedYear.value}`
})

const loadXLSX = async () => import('xlsx')
const scheduleXlsxPrefetch = () => {
  const prefetch = () => { loadXLSX().catch(() => {}) }
  if (typeof window !== 'undefined' && typeof window.requestIdleCallback === 'function') {
    window.requestIdleCallback(prefetch, { timeout: 2000 })
  } else {
    setTimeout(prefetch, 1200)
  }
}

const parsePositiveInt = (value, fallback) => {
  const parsed = Number(value)
  if (!Number.isFinite(parsed) || parsed <= 0) return fallback
  return Math.floor(parsed)
}

const parseFiltersFromQuery = (query) => {
  const preset = typeof query[QUERY_PRESET_KEY] === 'string' ? query[QUERY_PRESET_KEY] : ''
  const normalizedPreset = presetOptions.some((item) => item.value === preset) ? preset : null
  const year = parsePositiveInt(query[QUERY_YEAR_KEY], new Date().getFullYear())
  const lowStockThreshold = parsePositiveInt(query[QUERY_STOCK_KEY], 5)
  const minTopSold = parsePositiveInt(query[QUERY_TOP_SOLD_KEY], 2)
  return {
    preset: normalizedPreset,
    year,
    lowStockThreshold,
    minTopSold,
    tab: query[QUERY_TAB_KEY] === 'finance' ? 'finance' : 'overview',
    hasAny: Boolean(normalizedPreset || query[QUERY_YEAR_KEY] || query[QUERY_STOCK_KEY] || query[QUERY_TOP_SOLD_KEY])
  }
}

const restoreFiltersFromStorage = () => {
  try {
    const raw = localStorage.getItem(FILTER_STORAGE_KEY)
    if (!raw) return null
    const saved = JSON.parse(raw)
    if (!saved || typeof saved !== 'object') return null
    const preset = presetOptions.some((item) => item.value === saved.preset) ? saved.preset : 'custom_year'
    return {
      preset,
      year: parsePositiveInt(saved.year, new Date().getFullYear()),
      lowStockThreshold: parsePositiveInt(saved.lowStockThreshold, 5),
      minTopSold: parsePositiveInt(saved.minTopSold, 2),
      tab: saved.tab === 'finance' ? 'finance' : 'overview'
    }
  } catch (error) {
    console.warn('Không thể khôi phục filter dashboard:', error)
    return null
  }
}

const persistFiltersToStorage = () => {
  localStorage.setItem(
    FILTER_STORAGE_KEY,
    JSON.stringify({
      preset: selectedPreset.value,
      year: selectedYear.value,
      lowStockThreshold: selectedLowStockThreshold.value,
      minTopSold: selectedMinTopSold.value,
      tab: activeDashboardTab.value
    })
  )
}

const syncFiltersToRoute = () => {
  const nextQuery = {
    ...route.query,
    [QUERY_PRESET_KEY]: selectedPreset.value,
    [QUERY_YEAR_KEY]: String(selectedYear.value),
    [QUERY_STOCK_KEY]: String(selectedLowStockThreshold.value),
    [QUERY_TOP_SOLD_KEY]: String(selectedMinTopSold.value),
    [QUERY_TAB_KEY]: activeDashboardTab.value
  }
  isRouteSyncing.value = true
  router.replace({ query: nextQuery }).finally(() => {
    isRouteSyncing.value = false
  })
}

const fetchDashboardStatsData = async () => {
  isDashboardLoading.value = true
  dashboardError.value = ''
  const result = await getDashboardStats({
    preset: selectedPreset.value,
    year: selectedYear.value,
    lowStockThreshold: selectedLowStockThreshold.value,
    minTopSold: selectedMinTopSold.value,
    topLimit: 5
  })
  const safeData = result?.data || {}

  const revData = Array.isArray(safeData.revenue) ? safeData.revenue : []
  const orderStatusData = safeData.order_status || {}
  const monthlyFinanceData = Array.isArray(safeData.monthly_finance) ? safeData.monthly_finance : []
  const catData = Array.isArray(safeData.categories_share) && safeData.categories_share.length > 0
    ? safeData.categories_share
    : (Array.isArray(safeData.categories) ? safeData.categories : [])

  topProducts.value = Array.isArray(safeData.topProducts) ? safeData.topProducts : []
  activeMinTopSold.value = Number(safeData.top_sales?.min_sold) || selectedMinTopSold.value
  lowStockProducts.value = Array.isArray(safeData.lowStock) ? safeData.lowStock : []
  financeCompare.value = {
    ...financeCompare.value,
    ...(safeData.finance_compare || {})
  }

  emit('stats-loaded', {
    summary: safeData.summary || {},
    financials: safeData.financials || {}
  })

  barChartData.value = {
    labels: ['Chờ xác nhận', 'Đã xác nhận', 'Đang giao', 'Hoàn thành', 'Đã hủy'],
    datasets: [{
      label: 'Số đơn',
      backgroundColor: ['#E6A23C', '#409EFF', '#9B59B6', '#67C23A', '#F56C6C'],
      data: [
        Number(orderStatusData.pending || 0),
        Number(orderStatusData.approved || 0),
        Number(orderStatusData.shipping || 0),
        Number(orderStatusData.completed || 0),
        Number(orderStatusData.cancelled || 0)
      ]
    }]
  }
  financeBarChartData.value = {
    labels: monthlyFinanceData.map((d) => d.month),
    datasets: [
      { label: 'Doanh thu', backgroundColor: '#409EFF', data: monthlyFinanceData.map((d) => Number(d.revenue || 0)) },
      { label: 'Lợi nhuận', backgroundColor: '#67C23A', data: monthlyFinanceData.map((d) => Number(d.profit || 0)) }
    ]
  }

  const categoryValues = catData.map((c) => Number(c.sold_count || 0))
  doughnutChartData.value = {
    labels: catData.map((c) => c.category || 'Khác'),
    datasets: [{
      backgroundColor: catData.map((_, index) => chartPalette[index % chartPalette.length]),
      data: categoryValues
    }]
  }

  const totalCategorySold = categoryValues.reduce((sum, value) => sum + value, 0)
  categoryLegendItems.value = catData.map((item, index) => {
    const fallbackPct = totalCategorySold > 0 ? ((Number(item.sold_count || 0) / totalCategorySold) * 100) : 0
    return {
      category: item.category || 'Khác',
      sold_count: Number(item.sold_count || 0),
      sold_pct: Number(item.sold_pct ?? fallbackPct).toFixed(2),
      color: chartPalette[index % chartPalette.length]
    }
  })

  if (!result?.success) {
    dashboardError.value = result?.message || 'Đã có lỗi khi lấy dữ liệu, đang hiển thị dữ liệu mặc định.'
  }

  isDashboardLoading.value = false
}

const onFilterChanged = () => {
  lowStockCurrentPage.value = 1
  persistFiltersToStorage()
  syncFiltersToRoute()
  fetchDashboardStatsData()
}

watch(activeDashboardTab, () => {
  persistFiltersToStorage()
  syncFiltersToRoute()
})

const getSeverityTagType = (severity) => {
  if (severity === 'critical') return 'danger'
  if (severity === 'warning') return 'warning'
  return 'success'
}

const getSeverityLabel = (severity) => {
  if (severity === 'critical') return 'Rất thấp'
  if (severity === 'warning') return 'Sắp hết'
  return 'Ổn định'
}

const formatDelta = (value) => {
  const delta = Number(value || 0)
  const sign = delta > 0 ? '+' : ''
  return `${sign}${delta.toFixed(2)}% so với kỳ trước`
}
const getDeltaClass = (value) => (Number(value || 0) >= 0 ? 'positive' : 'negative')

const exportDashboardExcel = async () => {
  if (isExportingExcel.value) return
  isExportingExcel.value = true
  try {
    const XLSX = await loadXLSX()
    const wb = XLSX.utils.book_new()
    if (barChartData.value.labels.length > 0) {
      const revData = barChartData.value.labels.map((month, idx) => ({
        'Tháng': month,
        'Doanh thu (VNĐ)': barChartData.value.datasets[0].data[idx]
      }))
      const ws1 = XLSX.utils.json_to_sheet(revData)
      XLSX.utils.book_append_sheet(wb, ws1, 'ThongKeDoanhThu')
    }
    if (topProducts.value.length > 0) {
      const topData = topProducts.value.map(p => ({
        'Sản phẩm': p.name,
        'Đã bán': p.sold_count,
        'Giá bán': p.price,
        'Doanh thu': p.revenue
      }))
      const ws2 = XLSX.utils.json_to_sheet(topData)
      XLSX.utils.book_append_sheet(wb, ws2, 'TopBanChay')
    }
    XLSX.writeFile(wb, 'BaoCao_KinhDoanh.xlsx')
  } catch (error) {
    console.error('Lỗi xuất Excel dashboard:', error)
    ElMessage.error('Không thể tải module Excel. Vui lòng thử lại.')
  } finally {
    isExportingExcel.value = false
  }
}

onMounted(() => {
  const queryFilters = parseFiltersFromQuery(route.query)
  const storageFilters = restoreFiltersFromStorage()
  const resolvedFilters = queryFilters.hasAny
    ? {
        preset: queryFilters.preset || 'custom_year',
        year: queryFilters.year,
        lowStockThreshold: queryFilters.lowStockThreshold,
        minTopSold: queryFilters.minTopSold,
        tab: queryFilters.tab
      }
    : (storageFilters || {
        preset: 'custom_year',
        year: new Date().getFullYear(),
        lowStockThreshold: 5,
        minTopSold: 2,
        tab: 'overview'
      })

  selectedPreset.value = resolvedFilters.preset
  selectedYear.value = resolvedFilters.year
  selectedLowStockThreshold.value = resolvedFilters.lowStockThreshold
  selectedMinTopSold.value = resolvedFilters.minTopSold ?? 2
  activeDashboardTab.value = resolvedFilters.tab || 'overview'
  persistFiltersToStorage()
  syncFiltersToRoute()
  fetchDashboardStatsData()
  scheduleXlsxPrefetch()
})

watch(
  () => route.query,
  (query) => {
    if (isRouteSyncing.value) return
    const parsed = parseFiltersFromQuery(query)
    if (!parsed.hasAny) return
    const nextPreset = parsed.preset || 'custom_year'
    const changed = nextPreset !== selectedPreset.value
      || parsed.year !== selectedYear.value
      || parsed.lowStockThreshold !== selectedLowStockThreshold.value
      || parsed.minTopSold !== selectedMinTopSold.value
      || parsed.tab !== activeDashboardTab.value
    if (!changed) return
    selectedPreset.value = nextPreset
    selectedYear.value = parsed.year
    selectedLowStockThreshold.value = parsed.lowStockThreshold
    selectedMinTopSold.value = parsed.minTopSold
    activeDashboardTab.value = parsed.tab
    persistFiltersToStorage()
    fetchDashboardStatsData()
  }
)
</script>

<style scoped>
.card-header { display: flex; justify-content: space-between; align-items: center; }
.dashboard-tabs {
  margin-top: 8px;
}
.finance-hero-header {
  margin-bottom: 12px;
}
.finance-title {
  margin: 0;
  font-size: 18px;
  font-weight: 700;
  color: #303133;
}
.finance-subtitle {
  margin: 6px 0 0;
  font-size: 13px;
  color: #909399;
}
.kpi-grid {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 16px;
  margin-bottom: 25px;
}
.finance-grid {
  grid-template-columns: repeat(3, minmax(0, 1fr));
}
.kpi-item {
  min-width: 0;
}
.filter-card {
  margin-bottom: 16px;
}
.filter-row {
  display: flex;
  align-items: center;
  gap: 16px;
  flex-wrap: wrap;
}
.filter-item {
  display: flex;
  align-items: center;
  gap: 8px;
}
.filter-label {
  font-size: 13px;
  color: #606266;
}
.top-products-title {
  font-weight: bold;
}
.top-products-table :deep(.el-empty__description) {
  margin-top: 8px;
  padding: 0 12px;
}
.top-products-empty-text {
  margin: 0;
  line-height: 1.45;
  font-size: 14px;
  color: var(--el-text-color-secondary);
  max-width: 300px;
}
.low-stock-title-wrapper {
  display: flex;
  justify-content: space-between;
  align-items: center;
  width: 100%;
}
.low-stock-pagination-wrapper {
  margin-top: 15px;
  display: flex;
  justify-content: flex-end;
}
.category-legend-list {
  max-height: 120px;
  overflow: auto;
  border-top: 1px solid #f2f3f5;
  padding-top: 8px;
}
.category-legend-item {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 4px 0;
  font-size: 13px;
}
.category-legend-item .dot {
  width: 10px;
  height: 10px;
  border-radius: 50%;
  flex-shrink: 0;
}
.category-legend-item .label {
  flex: 1;
  color: #606266;
}
.category-legend-item .value {
  font-weight: 600;
  color: #303133;
}
.single-category-note {
  margin-top: 8px;
}
.finance-chart-card {
  border: 1px solid #ebeef5;
}
.finance-chart-heading {
  display: flex;
  flex-direction: column;
  gap: 4px;
}
.finance-chart-title {
  font-weight: 600;
  color: #303133;
}
.finance-chart-meta {
  font-size: 12px;
  color: #909399;
}
.finance-compare-card {
  border: 1px solid #ebeef5;
}
.compare-title {
  font-size: 13px;
  color: #909399;
  margin-bottom: 8px;
}
.compare-values {
  display: flex;
  flex-direction: column;
  gap: 4px;
}
.compare-current {
  font-size: 18px;
  font-weight: 700;
  color: #303133;
}
.compare-previous {
  font-size: 12px;
  color: #909399;
}
.compare-delta-chip {
  display: inline-flex;
  margin-top: 12px;
  padding: 4px 10px;
  border-radius: 999px;
  font-size: 12px;
  font-weight: 700;
}
.compare-delta-chip.positive {
  color: #1f8f4c;
  background: #e8f8ef;
}
.compare-delta-chip.negative {
  color: #d03050;
  background: #fdecec;
}
@media (max-width: 1200px) {
  .kpi-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
  .finance-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}
@media (max-width: 768px) {
  .kpi-grid {
    grid-template-columns: 1fr;
  }
  .finance-grid {
    grid-template-columns: 1fr;
  }
}
</style>
