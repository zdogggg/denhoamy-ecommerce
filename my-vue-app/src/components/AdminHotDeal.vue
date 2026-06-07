<template>
  <el-card shadow="never">
    <template #header>
      <div class="card-header">
        <span style="font-size: 16px; font-weight: bold;">Quản lý Hot Deal (Hiển thị trên Trang chủ)</span>
        <el-tag type="warning" effect="plain">Tối đa {{ HOT_DEAL_MAX }} sản phẩm</el-tag>
      </div>
    </template>
    


    <!-- Danh sách sản phẩm đang là Hot Deal -->
    <el-alert
      v-if="!canAddMoreHotDeal"
      type="warning"
      :closable="false"
      show-icon
      style="margin-bottom: 15px;"
      title="Đã đủ 10 sản phẩm Hot Deal"
      description="Gỡ bớt sản phẩm khỏi danh sách bên dưới nếu muốn thêm mẫu khác. Trang chủ chỉ hiển thị tối đa 10 sản phẩm."
    />
    <h4 style="margin: 0 0 15px;">Sản phẩm đang là Hot Deal ({{ hotDealList.length }}/{{ HOT_DEAL_MAX }})</h4>
    <el-table :data="hotDealList" stripe style="width: 100%; margin-bottom: 30px;" v-loading="loading" size="small">
      <el-table-column label="Ảnh" width="70">
        <template #default="scope">
          <el-image :src="scope.row.image_url" style="width: 45px; height: 45px; border-radius: 4px;" fit="cover" />
        </template>
      </el-table-column>
      <el-table-column prop="ten_san_pham" label="Tên sản phẩm" show-overflow-tooltip />
      <el-table-column prop="ma_san_pham" label="Mã SP" width="120" />
      <el-table-column label="Giá gốc" width="130">
        <template #default="scope">
          <span v-if="hasDiscount(scope.row)" style="text-decoration: line-through; color: #999;">{{ formatPrice(scope.row.old_price) }}đ</span>
          <span v-else style="color: #ccc;">—</span>
        </template>
      </el-table-column>
      <el-table-column label="Giá bán" width="130">
        <template #default="scope">
          <strong style="color: #d93025;">{{ getDisplayPrice(scope.row) }}</strong>
        </template>
      </el-table-column>
      <el-table-column label="Biến thể" width="90" align="center">
        <template #default="scope">
          <el-tag v-if="hasVariants(scope.row)" type="warning" size="small" effect="plain">
            {{ scope.row.variants.length }}
          </el-tag>
          <span v-else style="color: #999;">—</span>
        </template>
      </el-table-column>
      <el-table-column label="Giảm" width="80" align="center">
        <template #default="scope">
          <el-tag v-if="hasDiscount(scope.row)" type="danger" size="small" effect="dark">
            -{{ getDiscountPercent(scope.row) }}%
          </el-tag>
          <el-tag v-else type="info" size="small" effect="plain">
            Ưu đãi
          </el-tag>
        </template>
      </el-table-column>
      <el-table-column label="Thao tác" width="170" align="center">
        <template #default="scope">
          <el-button size="small" @click="openEditDialog(scope.row)">Sửa giá</el-button>
          <el-button type="danger" size="small" plain @click="removeFromHotDeal(scope.row)">Gỡ bỏ</el-button>
        </template>
      </el-table-column>
    </el-table>

    <!-- Thêm sản phẩm vào Hot Deal -->
    <el-divider />
    <div style="display: flex; align-items: center; gap: 10px; margin-bottom: 15px;">
      <h4 style="margin: 0;">Thêm sản phẩm vào Hot Deal</h4>
      <el-tag type="info" effect="plain">Hiển thị {{ filteredAllProducts.length }} / Tổng {{ allProducts.length }} sản phẩm</el-tag>
    </div>
    <div style="display: flex; gap: 10px; margin-bottom: 15px;">
      <el-input v-model="searchQuery" placeholder="Tìm theo tên hoặc mã sản phẩm..." clearable :prefix-icon="Search" style="width: 350px;" />
      <el-select v-model="searchCategory" placeholder="Lọc theo danh mục" clearable style="width: 240px;">
        <el-option v-for="cat in categoryOptions" :key="cat" :label="cat" :value="cat" />
      </el-select>
    </div>
    
    <el-table :data="filteredAllProducts" stripe style="width: 100%" size="small" max-height="400">
      <el-table-column label="Ảnh" width="70">
        <template #default="scope">
          <el-image :src="scope.row.image_url" style="width: 45px; height: 45px; border-radius: 4px;" fit="cover" />
        </template>
      </el-table-column>
      <el-table-column prop="ten_san_pham" label="Tên sản phẩm" show-overflow-tooltip />
      <el-table-column prop="ma_san_pham" label="Mã SP" width="120" />
      <el-table-column label="Giá gốc" width="130">
        <template #default="scope">
          <span v-if="hasDiscount(scope.row)" style="text-decoration: line-through; color: #999;">{{ formatPrice(scope.row.old_price) }}đ</span>
          <span v-else style="color: #ccc;">—</span>
        </template>
      </el-table-column>
      <el-table-column label="Giá bán" width="130">
        <template #default="scope">
          <strong>{{ getDisplayPrice(scope.row) }}</strong>
        </template>
      </el-table-column>
      <el-table-column label="Thao tác" width="200" align="center">
        <template #default="scope">
          <el-button size="small" @click="openEditDialog(scope.row)">Sửa giá</el-button>
          <el-button
            type="warning"
            size="small"
            effect="dark"
            :disabled="!canAddMoreHotDeal"
            @click="addToHotDeal(scope.row)"
          >+ Hot Deal</el-button>
        </template>
      </el-table-column>
    </el-table>
  </el-card>

  <!-- DIALOG SỬA GIÁ NHANH -->
  <el-dialog v-model="editDialogVisible" title="Sửa giá sản phẩm nhanh" :width="editForm.has_variants ? '760px' : '450px'" destroy-on-close>
    <div style="display: flex; align-items: center; gap: 12px; margin-bottom: 20px; padding: 12px; background: #f9f9f9; border-radius: 8px;">
      <el-image :src="editForm.image_url" style="width: 50px; height: 50px; border-radius: 6px; flex-shrink: 0;" fit="cover" />
      <div>
        <div style="font-weight: bold; font-size: 14px;">{{ editForm.ten_san_pham }}</div>
        <div style="color: #999; font-size: 12px;">{{ editForm.ma_san_pham }}</div>
      </div>
    </div>

    <el-form label-width="100px" label-position="left">
      <el-alert
        type="info"
        :closable="false"
        style="margin-bottom: 14px;"
        title="Giá gốc sẽ tự động khôi phục sau khi gỡ Hot Deal."
      />
      <el-alert
        v-if="editForm.has_variants"
        type="info"
        :closable="false"
        style="margin-bottom: 14px;"
        title="Tùy chỉnh giá riêng cho từng biến thể sản phẩm tại đây."
      />
      <el-form-item label="Giá nhập (đ)">
        <el-input :model-value="formatPrice(editForm.cost_price) + 'đ'" disabled />
      </el-form-item>
      <el-form-item label="Giá gốc (đ)">
        <PriceInput v-model="editForm.old_price" style="width: 100%;" />
        <div v-if="editForm.has_variants" style="font-size: 12px; color: #999; margin-top: 4px;">
          Giá gạch trên web (áp dụng cho cả sản phẩm có biến thể)
        </div>
      </el-form-item>
      <template v-if="editForm.has_variants">
        <el-form-item label-width="0" style="margin-bottom: 10px;">
          <div style="display: flex; gap: 8px; flex-wrap: wrap;">
            <el-button size="small" @click="applyVariantMarkup(10)">+10%</el-button>
            <el-button size="small" @click="applyVariantMarkup(20)">+20%</el-button>
            <el-button size="small" @click="applyVariantMarkup(30)">+30%</el-button>
            <el-button size="small" @click="applyVariantMarkup(40)">+40%</el-button>
          </div>
        </el-form-item>
        <el-form-item label-width="0">
          <el-table :data="editForm.variants" border size="small" style="width: 100%;">
            <el-table-column label="Biến thể">
              <template #default="scope">
                {{ formatVariantLabel(scope.row) }}
              </template>
            </el-table-column>
            <el-table-column label="Giá nhập" width="150">
              <template #default="scope">
                {{ formatPrice(scope.row.cost_price || 0) }}đ
              </template>
            </el-table-column>
            <el-table-column label="Giá bán Hot Deal" width="190">
              <template #default="scope">
                <PriceInput v-model="scope.row.price" style="width: 100%;" />
              </template>
            </el-table-column>
          </el-table>
        </el-form-item>
      </template>
      <template v-else>
        <el-form-item label="Giá bán (đ)">
          <PriceInput v-model="editForm.price" style="width: 100%;" />
        </el-form-item>
        <el-form-item label-width="100px">
          <div style="display: flex; gap: 8px; flex-wrap: wrap;">
            <el-button size="small" @click="applySingleMarkup(10)">+10%</el-button>
            <el-button size="small" @click="applySingleMarkup(20)">+20%</el-button>
            <el-button size="small" @click="applySingleMarkup(30)">+30%</el-button>
            <el-button size="small" @click="applySingleMarkup(40)">+40%</el-button>
          </div>
        </el-form-item>
      </template>
      <el-form-item label="Tiết kiệm">
        <el-tag v-if="!editForm.has_variants && editForm.old_price > editForm.price && editForm.old_price > 0" type="danger" effect="dark" size="large">
          -{{ Math.round((1 - editForm.price / editForm.old_price) * 100) }}% · Giảm {{ formatPrice(editForm.old_price - editForm.price) }}đ
        </el-tag>
        <el-tag v-else-if="editForm.has_variants" type="info" size="large">{{ getVariantHotDealSummary(editForm.variants, editForm.old_price) }}</el-tag>
        <el-tag v-else type="info" size="large">Chưa có giảm giá</el-tag>
      </el-form-item>
    </el-form>

    <template #footer>
      <el-button @click="editDialogVisible = false">Hủy</el-button>
      <el-button type="primary" @click="saveQuickEdit" :loading="saving">Lưu giá</el-button>
      <el-button
        v-if="!editForm.is_hot_deal"
        type="warning"
        :disabled="!canAddMoreHotDeal"
        @click="saveAndAddHotDeal"
        :loading="saving"
      >Lưu & Thêm Hot Deal</el-button>
    </template>
  </el-dialog>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { Search } from '@element-plus/icons-vue'
import { ElMessage } from 'element-plus'
import { getProducts, getHotDealProducts, toggleHotDeal } from '../services/productService'
import { getCategories } from '../services/categoryService'
import { formatPrice } from '../utils/format'
import PriceInput from './PriceInput.vue'
import api from '../services/httpClient'

/** Đồng bộ với HOT_DEAL_MAX trong denhoamy_api/products.php và HomeView slice */
const HOT_DEAL_MAX = 10

const loading = ref(false)
const saving = ref(false)
const hotDealList = ref([])
const canAddMoreHotDeal = computed(() => hotDealList.value.length < HOT_DEAL_MAX)
const allProducts = ref([])
const categoryOrder = ref([])
const searchQuery = ref('')
const searchCategory = ref('')
const editDialogVisible = ref(false)
const editForm = ref({ id: null, ten_san_pham: '', ma_san_pham: '', image_url: '', price: 0, old_price: 0, cost_price: 0, is_hot_deal: 0, has_variants: false })

const hasDiscount = (product) => !hasVariants(product) && Number(product.old_price) > Number(product.price) && Number(product.old_price) > 0
const getDiscountPercent = (product) => Math.round((1 - Number(product.price) / Number(product.old_price)) * 100)
const hasVariants = (product) => Array.isArray(product?.variants) && product.variants.length > 0
const formatVariantLabel = (variant) => {
  const parts = []
  if (variant.kich_thuoc) parts.push(variant.kich_thuoc)
  if (variant.anh_sang) parts.push(variant.anh_sang)
  return parts.length ? parts.join(' - ') : `Biến thể #${variant.id}`
}
const getDisplayPrice = (product) => {
  if (!hasVariants(product)) return `${formatPrice(product.price)}đ`
  const variantPrices = product.variants.map(v => Number(v.price) || 0).filter(v => v > 0)
  if (!variantPrices.length) return `${formatPrice(product.price)}đ`
  const minPrice = Math.min(...variantPrices)
  const maxPrice = Math.max(...variantPrices)
  if (minPrice === maxPrice) return `${formatPrice(minPrice)}đ`
  return `${formatPrice(minPrice)}đ - ${formatPrice(maxPrice)}đ`
}
const getVariantSavingsSummary = (variants = []) => {
  if (!Array.isArray(variants) || variants.length === 0) return 'Chưa có dữ liệu biến thể'
  const discounted = variants.filter(v => Number(v.cost_price) > 0 && Number(v.price) > Number(v.cost_price))
  if (discounted.length === 0) return 'Chưa có lãi so với giá nhập'
  const margins = discounted.map(v => Math.round((Number(v.price) - Number(v.cost_price)) * 100 / Number(v.cost_price)))
  const minMargin = Math.min(...margins)
  const maxMargin = Math.max(...margins)
  if (minMargin === maxMargin) return `${discounted.length}/${variants.length} biến thể: +${minMargin}% so với giá nhập`
  return `${discounted.length}/${variants.length} biến thể: +${minMargin}% đến +${maxMargin}% so với giá nhập`
}
const getVariantHotDealSummary = (variants = [], oldPrice = 0) => {
  const list = Number(oldPrice) || 0
  const prices = (variants || []).map(v => Number(v.price) || 0).filter(p => p > 0)
  if (!prices.length) return 'Chưa có dữ liệu biến thể'

  const minSale = Math.min(...prices)
  const parts = []

  if (list > minSale && list > 0) {
    const pct = Math.round((1 - minSale / list) * 100)
    parts.push(`Giảm ${pct}% so với giá gốc (${formatPrice(list - minSale)}đ)`)
  }

  const marginSummary = getVariantSavingsSummary(variants)
  if (!marginSummary.startsWith('Chưa có')) {
    parts.push(marginSummary)
  }

  return parts.length ? parts.join(' · ') : 'Chưa có giảm giá'
}

const categoryOptions = computed(() => {
  const namesInProducts = [...new Set(allProducts.value.map(p => (p.loai_den || '').trim()).filter(Boolean))]
  const ordered = categoryOrder.value.filter(name => namesInProducts.includes(name))
  const missing = namesInProducts.filter(name => !ordered.includes(name))
  return [...ordered, ...missing]
})

const filteredAllProducts = computed(() => {
  const hotDealIds = new Set(hotDealList.value.map(p => p.id))
  let list = allProducts.value.filter(p => !hotDealIds.has(p.id))
  
  if (searchQuery.value.trim()) {
    const q = searchQuery.value.toLowerCase()
    list = list.filter(p => 
      (p.ten_san_pham || '').toLowerCase().includes(q) || 
      (p.ma_san_pham || '').toLowerCase().includes(q)
    )
  }

  if (searchCategory.value) {
    list = list.filter(p => (p.loai_den || '') === searchCategory.value)
  }
  return list
})

const fetchData = async () => {
  loading.value = true
  try {
    const [hotRes, allRes, catRes] = await Promise.all([getHotDealProducts(), getProducts(), getCategories()])
    if (hotRes && hotRes.success) hotDealList.value = hotRes.data
    if (allRes && allRes.success) allProducts.value = allRes.data
    if (catRes && catRes.success && Array.isArray(catRes.flat)) {
      const parentIds = new Set(
        catRes.flat
          .map(cat => cat.parent_id)
          .filter(id => id !== null && id !== undefined)
      )
      categoryOrder.value = catRes.flat
        .filter(cat => !parentIds.has(cat.id))
        .map(cat => (cat.name || '').trim())
        .filter(Boolean)
    }
  } catch (e) {
    console.error(e)
  } finally {
    loading.value = false
  }
}

const refreshAfterMutation = async () => {
  await fetchData()
}

const openEditDialog = (product) => {
  const matched = allProducts.value.find(p => Number(p.id) === Number(product.id))
  const sourceVariants = Array.isArray(product.variants) && product.variants.length
    ? product.variants
    : (matched?.variants || [])
  editForm.value = {
    id: product.id,
    ten_san_pham: product.ten_san_pham,
    ma_san_pham: product.ma_san_pham,
    image_url: product.image_url,
    price: Number(product.price) || 0,
    old_price: Number(product.old_price) || 0,
    cost_price: Number(product.cost_price ?? matched?.cost_price ?? 0) || 0,
    is_hot_deal: Number(product.is_hot_deal) || 0,
    has_variants: sourceVariants.length > 0,
    variants: sourceVariants.map(v => ({
      id: v.id,
      kich_thuoc: v.kich_thuoc || '',
      anh_sang: v.anh_sang || '',
      price: Number(v.price) || 0,
      cost_price: Number(v.cost_price) || 0
    }))
  }
  editDialogVisible.value = true
}

const quickUpdatePrice = async () => {
  if (!editForm.value.has_variants && editForm.value.price <= 0) {
    ElMessage.warning('Giá bán phải lớn hơn 0')
    return false
  }
  if (editForm.value.has_variants) {
    const hasInvalid = (editForm.value.variants || []).some(v => Number(v.price) <= 0)
    if (hasInvalid) {
      ElMessage.warning('Giá bán biến thể phải lớn hơn 0')
      return false
    }
  }
  saving.value = true
  try {
    const minVariantPrice = editForm.value.has_variants
      ? Math.min(...editForm.value.variants.map(v => Number(v.price) || 0))
      : Number(editForm.value.price)
    const res = await api.put('/products.php', {
      action: 'quick_update_price',
      id: editForm.value.id,
      price: minVariantPrice,
      old_price: editForm.value.old_price,
      variants: editForm.value.has_variants ? editForm.value.variants.map(v => ({ id: v.id, price: Number(v.price) || 0 })) : []
    })
    return Boolean(res.data && res.data.success)
  } catch (e) {
    console.error(e)
    return false
  } finally {
    saving.value = false
  }
}

const calculateByCost = (cost, percent) => Math.round((Number(cost) || 0) * (1 + Number(percent) / 100))

const applyVariantMarkup = (percent) => {
  if (!Array.isArray(editForm.value.variants) || editForm.value.variants.length === 0) return
  editForm.value.variants = editForm.value.variants.map(v => ({
    ...v,
    price: calculateByCost(v.cost_price, percent)
  }))
}

const applySingleMarkup = (percent) => {
  editForm.value.price = calculateByCost(editForm.value.cost_price, percent)
}

const saveQuickEdit = async () => {
  const ok = await quickUpdatePrice()
  if (ok) {
    await refreshAfterMutation()
    ElMessage.success('Đã cập nhật giá sản phẩm!')
    editDialogVisible.value = false
  } else {
    ElMessage.error('Lỗi cập nhật giá')
  }
}

const saveAndAddHotDeal = async () => {
  if (!canAddMoreHotDeal.value) {
    return ElMessage.warning(`Hot Deal chỉ tối đa ${HOT_DEAL_MAX} sản phẩm`)
  }
  const ok = await quickUpdatePrice()
  if (!ok) return ElMessage.error('Lỗi cập nhật giá')

  const res = await toggleHotDeal(editForm.value.id, 1)
  if (res && res.success) {
    await refreshAfterMutation()
    ElMessage.success(`Đã cập nhật giá & thêm vào Hot Deal!`)
    editDialogVisible.value = false
  } else {
    ElMessage.error(res?.message || 'Lỗi thêm vào Hot Deal')
  }
}

const addToHotDeal = async (product) => {
  if (!canAddMoreHotDeal.value) {
    return ElMessage.warning(`Hot Deal chỉ tối đa ${HOT_DEAL_MAX} sản phẩm`)
  }
  const res = await toggleHotDeal(product.id, 1)
  if (res && res.success) {
    await refreshAfterMutation()
    ElMessage.success(`Đã thêm "${product.ten_san_pham}" vào Hot Deal!`)
  } else {
    ElMessage.error(res?.message || 'Lỗi thêm vào Hot Deal')
  }
}

const removeFromHotDeal = async (product) => {
  const res = await toggleHotDeal(product.id, 0)
  if (res && res.success) {
    await refreshAfterMutation()
    ElMessage.success(res.message || `Đã gỡ "${product.ten_san_pham}" khỏi Hot Deal`)
  } else {
    ElMessage.error(res?.message || 'Lỗi gỡ Hot Deal')
  }
}

onMounted(fetchData)
</script>

<style scoped>
.card-header { display: flex; justify-content: space-between; align-items: center; }
</style>
