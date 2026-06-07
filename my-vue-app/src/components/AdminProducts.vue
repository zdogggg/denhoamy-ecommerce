<template>
  <el-card shadow="never">
    <template #header>
      <div class="card-header">
        <div style="display: flex; align-items: center; gap: 15px;">
          <span style="font-weight: bold; font-size: 16px;">Quản lý kho đèn</span>
          <el-tag type="info" effect="plain" style="font-weight: bold;">
            Tổng tồn kho: {{ totalStock }} bộ
          </el-tag>
        </div>
        <div style="display: flex; gap: 10px;">
          <el-button v-if="multipleSelection.length > 0" type="danger" plain @click="handleDeleteBatch" :icon="Delete">Xóa đã chọn ({{ multipleSelection.length }})</el-button>
          <el-button type="primary" :icon="Plus" @click="openAddForm">Thêm sản phẩm</el-button>
        </div>
      </div>
    </template>
    <div class="filter-bar">
      <el-input v-model="searchQuery" placeholder="Mã sản phẩm, tên..." style="width: 250px" clearable suffix-icon="Search" />
      <el-select v-model="searchCategory" placeholder="Chọn danh mục" clearable style="width: 200px">
        <el-option v-for="cat in selectableCategories" :key="cat.id" :label="cat.name" :value="cat.name" />
      </el-select>
      <el-button type="primary" :icon="Search">Tìm kiếm</el-button>
    </div>
    <el-table :data="filteredLampData" stripe style="width: 100%" @selection-change="handleSelectionChange">
      <el-table-column type="selection" width="55" />
      <el-table-column label="STT" type="index" width="60" align="center" />
      <el-table-column label="Ảnh" width="90"><template #default="scope"><el-image style="width: 45px; height: 45px; border-radius: 4px" :src="scope.row.image" fit="cover" :preview-src-list="[scope.row.image]" preview-teleported /></template></el-table-column>
      <el-table-column prop="id" label="Mã SP" width="100" />
      <el-table-column prop="name" label="Tên sản phẩm" />
      <el-table-column prop="category" label="Danh mục" width="160" />
      <el-table-column prop="price" label="Giá bán" width="130" />
      <el-table-column label="Tồn kho" width="100" align="center">
        <template #default="scope">
          <el-tag :type="scope.row.stock <= 5 ? 'danger' : (scope.row.stock <= 20 ? 'warning' : 'success')" effect="plain">
            {{ scope.row.stock }}
          </el-tag>
        </template>
      </el-table-column>
      <el-table-column label="Thao tác" width="220">
        <template #default="scope">
          <el-button size="small" link type="success" @click="openImportDialog(scope.row)">Nhập kho</el-button>
          <el-button size="small" link type="primary" @click="handleEdit(scope.row)">Sửa</el-button>
          <el-button size="small" link type="danger" @click="handleDelete(scope.row.id)">Xóa</el-button>
        </template>
      </el-table-column>
    </el-table>
  </el-card>

  <!-- DIALOG THÊM/SỬA SẢN PHẨM -->
  <el-dialog v-model="dialogVisible" :title="isEdit ? 'Sửa thông tin đèn' : 'Thêm đèn mới'" width="1100px" top="3vh">
     <el-form :model="tempForm" label-width="120px" label-position="left">
      <el-row :gutter="20">
        <!-- CỘT 1: THÔNG TIN CƠ BẢN -->
        <el-col :span="8">
          <p style="margin: 0 0 15px 0; font-weight: bold; color: #409EFF;">THÔNG TIN CƠ BẢN</p>
          <el-form-item label="Ảnh đèn" label-width="100px">
            <el-upload action="#" :auto-upload="false" :show-file-list="false" @change="handleProductImageChange">
              <img v-if="tempForm.image" :src="tempForm.image" class="product-preview-img" style="width: 100px; height: 100px; object-fit: cover; border-radius: 4px; border: 1px dashed #dcdfe6;" />
              <el-icon v-else class="product-uploader-icon" style="font-size: 28px; color: #8c939d; width: 100px; height: 100px; line-height: 100px; text-align: center; border: 1px dashed #dcdfe6; border-radius: 4px;"><Plus /></el-icon>
            </el-upload>
          </el-form-item>
          <el-form-item label="Nhiều ảnh phụ" label-width="100px">
            <el-upload action="#" list-type="picture-card" :auto-upload="false" :file-list="galleryFileList" @change="handleGalleryChange" @remove="handleGalleryRemove" multiple style="width: 100%;">
              <el-icon><Plus /></el-icon>
            </el-upload>
          </el-form-item>
          <el-form-item label="Tên đèn" label-width="100px"><el-input v-model="tempForm.name" /></el-form-item>
          <el-form-item label="Danh mục" label-width="100px">
            <el-select v-model="tempForm.category" style="width: 100%" clearable>
              <el-option v-for="cat in selectableCategories" :key="cat.id" :label="cat.name" :value="cat.name" />
            </el-select>
          </el-form-item>
          <el-form-item label="Mã SP" label-width="100px">
             <el-input v-model="tempForm.id" placeholder="Bỏ trống để tự sinh mã" />
          </el-form-item>
        </el-col>

        <!-- CỘT 2: GIÁ & TỒN KHO -->
        <el-col :span="8">
          <p style="margin: 0 0 15px 0; font-weight: bold; color: #67C23A;">BÁN HÀNG & KHO</p>
          <el-form-item label="Giá bán (VNĐ)" label-width="110px"><PriceInput v-model="tempForm.price" style="width: 100%" /></el-form-item>
          <el-form-item label="Giá cũ (Gạch)" label-width="110px">
            <PriceInput v-model="tempForm.old_price" nullable style="width: 100%" placeholder="Để trống nếu không gạch giá" />
          </el-form-item>
          <el-form-item label="Giá nhập" label-width="110px">
            <PriceInput v-model="tempForm.cost_price" style="width: 100%" />
          </el-form-item>
          <el-form-item label="Tồn kho" label-width="110px"><el-input-number v-model="tempForm.stock" :min="0" style="width: 100%" /></el-form-item>
          <el-form-item label="Tình trạng" label-width="110px"><el-input v-model="tempForm.tinh_trang" placeholder="Mới 100%" /></el-form-item>
        </el-col>

        <!-- CỘT 3: THÔNG SỐ -->
        <el-col :span="8">
          <div style="background: #f9fbfd; padding: 15px; border-radius: 4px; border: 1px dashed #e4e7ed;">
            <p style="margin: 0 0 15px 0; font-weight: bold; color: #D8B257;">THÔNG SỐ KỸ THUẬT</p>
            <el-form-item label="Phong cách" label-width="110px">
              <el-select v-model="tempForm.phong_cach_arr" multiple collapse-tags placeholder="Chọn phong cách" style="width: 100%">
                <el-option v-for="item in phongCachOptions" :key="item" :label="item" :value="item" />
              </el-select>
            </el-form-item>
            <el-form-item label="Không gian" label-width="110px">
              <el-select v-model="tempForm.khong_gian_arr" multiple collapse-tags placeholder="Chọn không gian" style="width: 100%">
                <el-option v-for="item in khongGianOptions" :key="item" :label="item" :value="item" />
              </el-select>
            </el-form-item>
            <el-form-item label="Bóng đèn" label-width="110px"><el-input v-model="tempForm.bong_den" placeholder="LED..." /></el-form-item>
            <el-form-item label="Chất liệu" label-width="110px">
              <el-select v-model="tempForm.chat_lieu_arr" multiple collapse-tags placeholder="Chọn chất liệu" style="width: 100%">
                <el-option v-for="item in chatLieuOptions" :key="item" :label="item" :value="item" />
              </el-select>
            </el-form-item>
            <el-form-item label="Kích thước" label-width="110px"><el-input v-model="tempForm.kich_thuoc" placeholder="D600..." /></el-form-item>
            <el-form-item label="Tuổi thọ" label-width="110px"><el-input v-model="tempForm.tuoi_tho" placeholder="50000" /></el-form-item>
            <el-form-item label="Điện áp" label-width="110px"><el-input v-model="tempForm.dien_ap" placeholder="220v" /></el-form-item>
          </div>
        </el-col>
      </el-row>

      <!-- MÔ TẢ SẢN PHẨM -->
      <div style="margin-top: 15px; padding-top: 15px; border-top: 1px dashed #e4e7ed;">
        <p style="margin: 0 0 10px 0; font-weight: bold; color: #409EFF;">MÔ TẢ CHI TIẾT SẢN PHẨM</p>
        <el-input v-model="tempForm.description" type="textarea" :rows="5" placeholder="Nhập nội dung quảng cáo, bài viết giới thiệu chi tiết về đặc điểm nổi bật của Mẫu đèn này..." />
      </div>

      <!-- BIẾN THỂ SẢN PHẨM (VARIANTS) -->
      <div style="margin-top: 15px; padding-top: 15px; border-top: 1px dashed #e4e7ed;">
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px;">
          <p style="margin: 0; font-weight: bold; color: #E6A23C;">PHÂN LOẠI HÀNG HÓA (BIẾN THỂ TÙY CHỌN)</p>
          <el-button type="warning" plain size="small" icon="Plus" @click="addVariantRow">Bấm Thêm Phân Loại</el-button>
        </div>
        
        <el-table v-if="tempForm.variants && tempForm.variants.length > 0" :data="tempForm.variants" border style="width: 100%; border-radius: 8px;">
          <el-table-column label="Kích thước" min-width="150">
            <template #default="scope"><el-input v-model="scope.row.kich_thuoc" placeholder="VD: D600" size="small" /></template>
          </el-table-column>
          <el-table-column label="Ánh sáng" min-width="150">
            <template #default="scope"><el-input v-model="scope.row.anh_sang" placeholder="VD: Vàng, 3 Màu" size="small" /></template>
          </el-table-column>
          <el-table-column width="180">
            <template #header>
              <div style="display: flex; align-items: center; justify-content: space-between;">
                <span>Giá bán riêng</span>
                <el-tooltip content="Áp dụng giá bán của dòng đầu cho tất cả">
                  <el-button size="small" link type="primary" icon="Download" @click="applyToAllPrice" />
                </el-tooltip>
              </div>
            </template>
            <template #default="scope"><PriceInput v-model="scope.row.price" size="small" style="width: 100%" /></template>
          </el-table-column>
          <el-table-column width="180">
            <template #header>
              <div style="display: flex; align-items: center; justify-content: space-between;">
                <span>Giá nhập riêng</span>
                <el-tooltip content="Áp dụng giá nhập của dòng đầu cho tất cả">
                  <el-button size="small" link type="warning" icon="Download" @click="applyToAllCost" />
                </el-tooltip>
              </div>
            </template>
            <template #default="scope"><PriceInput v-model="scope.row.cost_price" size="small" style="width: 100%" /></template>
          </el-table-column>
          <el-table-column width="130">
            <template #header>
              <div style="display: flex; align-items: center; justify-content: space-between;">
                <span>Tồn kho</span>
                <el-tooltip content="Áp dụng tồn kho của dòng đầu cho tất cả">
                  <el-button size="small" link type="primary" icon="Download" @click="applyToAllStock" />
                </el-tooltip>
              </div>
            </template>
            <template #default="scope"><el-input-number v-model="scope.row.stock" :min="0" size="small" style="width: 100%" /></template>
          </el-table-column>
          <el-table-column label="Xóa" width="60" align="center">
            <template #default="scope"><el-button size="small" type="danger" icon="Delete" circle plain @click="removeVariantRow(scope.$index)" /></template>
          </el-table-column>
        </el-table>
        <div v-else style="background: #fdf6ec; padding: 10px; border-radius: 4px; text-align: center; color: #E6A23C; font-size: 13px;">
          Sản phẩm hiện chưa cấu hình phân loại (Chỉ bán 1 mức giá mặc định phía trên).
        </div>
      </div>
    </el-form>
    <template #footer><el-button @click="dialogVisible = false">Hủy</el-button><el-button type="primary" @click="saveData">Lưu Sản Phẩm</el-button></template>
  </el-dialog>

  <!-- DIALOG NHẬP KHO -->
  <el-dialog v-model="importDialogVisible" title="Nhập Kho Sản Phẩm" width="450px">
    <el-form :model="importForm" label-position="top">
      <el-form-item label="Tên sản phẩm">
        <el-input v-model="importForm.name" disabled />
      </el-form-item>
      <el-form-item v-if="importForm.has_variants" label="Chọn phân loại">
        <el-select v-model="importForm.variant_id" placeholder="Chọn biến thể cần nhập kho" style="width: 100%">
          <el-option
            v-for="variant in importForm.variants"
            :key="variant.id"
            :label="formatVariantLabel(variant)"
            :value="variant.id"
          />
        </el-select>
      </el-form-item>
      <el-row :gutter="20">
        <el-col :span="12">
           <el-form-item label="Số lượng nhập">
            <el-input-number v-model="importForm.quantity" :min="1" style="width: 100%" />
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="Giá nhập (VNĐ)">
            <PriceInput v-model="importForm.cost" style="width: 100%" />
          </el-form-item>
        </el-col>
      </el-row>
      <el-form-item label="Ghi chú">
        <el-input type="textarea" v-model="importForm.note" placeholder="Nhập ghi chú hoặc mã lô hàng..." />
      </el-form-item>
    </el-form>
    <template #footer>
      <el-button @click="importDialogVisible = false">Hủy</el-button>
      <el-button type="primary" @click="submitImportStock">Xác nhận nhập kho</el-button>
    </template>
  </el-dialog>

</template>

<script setup>
import { ref, computed, watch, onMounted } from 'vue'
import { Plus, Search, Delete } from '@element-plus/icons-vue'
import { useAuthStore } from '../stores/auth'
import { getAdminProducts, addProduct, updateProduct, deleteProduct, deleteBatchProducts } from '../services/productService'
import { addInventory } from '../services/inventoryService'
import { getCategories } from '../services/categoryService'
import { uploadImage } from '../services/uploadService'
import { ElMessage, ElMessageBox } from 'element-plus'
import { formatPrice } from '../utils/format'
import PriceInput from './PriceInput.vue'

const authStore = useAuthStore()

const props = defineProps({
  flatCategories: { type: Array, default: () => [] }
})

const emit = defineEmits(['stats-updated'])

const phongCachOptions = ['Hiện Đại', 'Cổ Điển', 'Tân Cổ Điển']
const khongGianOptions = ['Phòng khách', 'Phòng ăn', 'Phòng ngủ']
const chatLieuOptions = ['Đồng', 'Pha Lê', 'Hợp Kim', 'Gốm', 'Acrylic', 'Gỗ', 'Thủy tinh', 'Chao vải', 'Tre', 'Đá cẩm thạch', 'Hợp kim mạ vàng', 'Nhựa ABS', 'Vải', 'Giấy']

const dialogVisible = ref(false)
const isEdit = ref(false)
const galleryFileList = ref([])
const searchQuery = ref('')
const searchCategory = ref('')
const lampData = ref([])
const tempForm = ref({ db_id: '', id: '', name: '', category: '', price: 0, image: '', variants: [] })

const totalStock = computed(() => lampData.value.reduce((sum, item) => sum + item.stock, 0))
const selectableCategories = computed(() => {
  const parentIds = new Set(
    (props.flatCategories || [])
      .map(cat => cat.parent_id)
      .filter(id => id !== null && id !== undefined)
  )
  return (props.flatCategories || []).filter(cat => !parentIds.has(cat.id))
})

const filteredLampData = computed(() => lampData.value.filter(item => {
  const matchSearch = item.name.toLowerCase().includes(searchQuery.value.toLowerCase()) || item.id.toLowerCase().includes(searchQuery.value.toLowerCase());
  const matchCat = searchCategory.value ? (item.category || '').toLowerCase() === searchCategory.value.toLowerCase() : true;
  return matchSearch && matchCat;
}))

// NHẬP KHO
const importDialogVisible = ref(false)
const importForm = ref({ product_id: '', variant_id: null, variants: [], has_variants: false, name: '', quantity: 1, cost: 0, note: '' })
const formatVariantLabel = (variant) => {
  const parts = []
  if (variant.kich_thuoc) parts.push(variant.kich_thuoc)
  if (variant.anh_sang) parts.push(variant.anh_sang)
  return parts.length ? parts.join(' - ') : `Biến thể #${variant.id}`
}
const openImportDialog = (row) => {
  const variants = Array.isArray(row.variants) ? row.variants : []
  const hasVariants = variants.length > 0
  importForm.value = {
    product_id: row.db_id,
    variant_id: hasVariants ? variants[0].id : null,
    variants,
    has_variants: hasVariants,
    name: row.name,
    quantity: 1,
    cost: hasVariants ? (Number(variants[0].cost_price) || 0) : (Number(row.cost_price) || 0),
    note: ''
  }
  importDialogVisible.value = true
}
const submitImportStock = async () => {
  if (importForm.value.quantity <= 0) return ElMessage.warning('Số lượng phải lớn hơn 0')
  if (importForm.value.has_variants && !importForm.value.variant_id) {
    return ElMessage.warning('Vui lòng chọn biến thể cần nhập kho')
  }
  const loading = ElMessage({ message: 'Đang xử lý nhập kho...', type: 'info', duration: 0 })
  const payload = {
    product_id: importForm.value.product_id,
    quantity: importForm.value.quantity,
    cost: importForm.value.cost,
    note: importForm.value.note,
    admin_id: authStore.user?.id
  }
  if (importForm.value.has_variants) payload.variant_id = importForm.value.variant_id
  const res = await addInventory(payload)
  loading.close()
  if (res && res.success) {
    ElMessage.success('Nhập kho thành công!')
    importDialogVisible.value = false
    fetchProductsData()
  } else {
    ElMessage.error(res?.message || 'Có lỗi xảy ra khi nhập kho')
  }
}

// FETCH SẢN PHẨM
const fetchProductsData = async () => {
  const result = await getAdminProducts()
  if (result && result.success) {
    lampData.value = result.data.map(item => ({
      db_id: item.id,
      id: item.ma_san_pham,
      name: item.ten_san_pham,
      category: item.loai_den,
      price: formatPrice(item.price),
      raw_price: item.price,
      cost_price: item.cost_price || 0,
      stock: item.variants && item.variants.length > 0 
        ? item.variants.reduce((sum, v) => sum + (Number(v.stock) || 0), 0) 
        : (item.stock || 0),
      old_price: item.old_price || 0,
      tinh_trang: item.tinh_trang || 'Mới 100%',
      image: item.image_url,
      phong_cach: item.phong_cach || '',
      khong_gian_lap_dat: item.khong_gian_lap_dat || '',
      bong_den: item.bong_den || '',
      chat_lieu: item.chat_lieu || '',
      kich_thuoc: item.kich_thuoc || '',
      tuoi_tho: item.tuoi_tho || '50000',
      dien_ap: item.dien_ap || '220v',
      description: item.description || '',
      gallery: item.gallery ? (typeof item.gallery === 'string' ? JSON.parse(item.gallery) : item.gallery) : [],
      variants: item.variants || []
    }))
    emit('stats-updated', { productCount: lampData.value.length, totalStock: totalStock.value })
  }
}

// THÊM / SỬA SẢN PHẨM
const handleProductImageChange = async (file) => {
  const loading = ElMessage({ message: 'Đang upload ảnh sản phẩm...', type: 'info', duration: 0 })
  const res = await uploadImage(file.raw, 'product')
  loading.close()
  if (res && res.success) {
    tempForm.value.image = res.url
    ElMessage.success('Upload ảnh thành công!')
  } else {
    ElMessage.error(res?.message || 'Lỗi upload ảnh')
  }
}

const openAddForm = () => { 
  isEdit.value = false; 
  tempForm.value = { 
    db_id: '', id: '', name: '', category: '', price: 0, old_price: 0, cost_price: 0, stock: 15, tinh_trang: 'Mới 100%', image: '', 
    phong_cach: '', phong_cach_arr: [], 
    khong_gian_lap_dat: '', khong_gian_arr: [], 
    bong_den: 'LED', 
    chat_lieu: '', chat_lieu_arr: [], 
    kich_thuoc: '', tuoi_tho: '50000', dien_ap: '220v', description: '', gallery: [], variants: [] 
  }; 
  galleryFileList.value = []; 
  dialogVisible.value = true 
}

const handleEdit = (row) => { 
  isEdit.value = true; 
  tempForm.value = { 
    ...row, 
    price: row.raw_price, 
    cost_price: row.cost_price || 0, 
    variants: [...(row.variants || [])],
    phong_cach_arr: row.phong_cach ? row.phong_cach.split(',').map(s => s.trim()) : [],
    khong_gian_arr: row.khong_gian_lap_dat ? row.khong_gian_lap_dat.split(',').map(s => s.trim()) : [],
    chat_lieu_arr: row.chat_lieu ? row.chat_lieu.split(',').map(s => s.trim()) : []
  }; 
  galleryFileList.value = (row.gallery || []).map((url, idx) => ({ name: `gal-${idx}`, url })); 
  dialogVisible.value = true 
}

const handleGalleryChange = async (file, fileList) => {
  if (file.raw) {
    const loading = ElMessage({ message: 'Đang upload ảnh gallery...', type: 'info', duration: 0 })
    const res = await uploadImage(file.raw, 'gallery')
    loading.close()
    if (res && res.success) {
      file.url = res.url
      galleryFileList.value = fileList
    } else {
      ElMessage.error('Lỗi upload ảnh gallery')
      galleryFileList.value = fileList.filter(f => f.uid !== file.uid)
    }
  } else {
    galleryFileList.value = fileList
  }
}
const handleGalleryRemove = (file, fileList) => { galleryFileList.value = fileList }

const saveData = async () => { 
  const loading = ElMessage({ message: 'Đang lưu...', type: 'info', duration: 0 })
  tempForm.value.gallery = galleryFileList.value.map(f => f.url)
  tempForm.value.phong_cach = (tempForm.value.phong_cach_arr || []).join(', ')
  tempForm.value.khong_gian_lap_dat = (tempForm.value.khong_gian_arr || []).join(', ')
  tempForm.value.chat_lieu = (tempForm.value.chat_lieu_arr || []).join(', ')

  // Có biến thể: đồng bộ giá bán SP chính từ giá thấp nhất của biến thể (không đụng giá cũ)
  if (tempForm.value.variants?.length > 0) {
    const variantPrices = tempForm.value.variants
      .map((v) => Number(v.price) || 0)
      .filter((p) => p > 0)
    if (variantPrices.length > 0 && !(Number(tempForm.value.price) > 0)) {
      tempForm.value.price = Math.min(...variantPrices)
    }
  }

  const oldPriceVal = Number(tempForm.value.old_price) || 0
  if (oldPriceVal > 0 && oldPriceVal === Number(tempForm.value.price)) {
    tempForm.value.old_price = 0
  }

  let result;
  if (isEdit.value) { 
    result = await updateProduct(tempForm.value)
  } else { 
    result = await addProduct(tempForm.value)
  }
  loading.close()
  if (result && result.success) {
    dialogVisible.value = false
    ElMessage.success('Lưu thành công!')
    fetchProductsData()
  } else {
    ElMessage.error('Có lỗi xảy ra khi lưu sản phẩm')
  }
}

// XÓA SẢN PHẨM
const multipleSelection = ref([])
const handleSelectionChange = (val) => { multipleSelection.value = val }

const handleDeleteBatch = () => {
  if (multipleSelection.value.length === 0) return
  const ids = multipleSelection.value.map(item => item.db_id)
  ElMessageBox.confirm(`Bạn có chắc muốn xóa ${ids.length} sản phẩm đã chọn?`, 'Cảnh báo', {
    confirmButtonText: 'Đồng ý', cancelButtonText: 'Hủy bỏ', type: 'danger'
  }).then(async () => {
    const loading = ElMessage({ message: 'Đang xóa loạt...', type: 'info', duration: 0 })
    const result = await deleteBatchProducts(ids)
    loading.close()
    if (result && result.success) {
      ElMessage.success(result.message || 'Đã xóa các sản phẩm.')
      fetchProductsData()
      multipleSelection.value = []
    } else {
      ElMessage.error('Lỗi khi xóa sản phẩm')
    }
  }).catch(() => {})
}

const handleDelete = (id) => { 
  const lamp = lampData.value.find(i => i.id === id)
  ElMessageBox.confirm(`Bạn chắc chắn muốn xóa sản phẩm \${lamp.name}?`, 'Xoá sản phẩm', {
    confirmButtonText: 'Đồng ý', cancelButtonText: 'Hủy bỏ', type: 'danger'
  }).then(async () => {
    const loading = ElMessage({ message: 'Đang xóa...', type: 'info', duration: 0 })
    const result = await deleteProduct(lamp.db_id)
    loading.close()
    if (result && result.success) {
      ElMessage.success('Đã xóa sản phẩm.') 
      fetchProductsData()
    } else {
      ElMessage.error('Lỗi khi xóa sản phẩm')
    }
  }).catch(() => {})
}

// BIẾN THỂ (VARIANTS)
const addVariantRow = () => { 
  if (!tempForm.value.variants) tempForm.value.variants = []
  tempForm.value.variants.push({ kich_thuoc: '', anh_sang: '', price: tempForm.value.price || 0, cost_price: tempForm.value.cost_price || 0, stock: tempForm.value.stock || 15 }) 
}
const removeVariantRow = (idx) => { tempForm.value.variants.splice(idx, 1) }

const applyToAllPrice = () => {
  if (tempForm.value.variants.length < 2) return
  const firstPrice = tempForm.value.variants[0].price
  tempForm.value.variants.forEach((v, idx) => { if (idx > 0) v.price = firstPrice })
  ElMessage.success('Đã áp dụng giá bán cho tất cả phân loại!')
}
const applyToAllCost = () => {
  if (tempForm.value.variants.length < 2) return
  const firstCost = tempForm.value.variants[0].cost_price
  tempForm.value.variants.forEach((v, idx) => { if (idx > 0) v.cost_price = firstCost })
  ElMessage.success('Đã áp dụng giá nhập cho tất cả phân loại!')
}
const applyToAllStock = () => {
  if (tempForm.value.variants.length < 2) return
  const firstStock = tempForm.value.variants[0].stock
  tempForm.value.variants.forEach((v, idx) => { if (idx > 0) v.stock = firstStock })
  ElMessage.success('Đã áp dụng tồn kho cho tất cả phân loại!')
}

watch(() => importForm.value.variant_id, (variantId) => {
  if (!importForm.value.has_variants || !variantId) return
  const selectedVariant = importForm.value.variants.find(v => Number(v.id) === Number(variantId))
  if (selectedVariant) importForm.value.cost = Number(selectedVariant.cost_price) || 0
})

watch(() => tempForm.value.variants, (newVariants) => {
  if (newVariants && newVariants.length > 0) {
    const total = newVariants.reduce((sum, v) => sum + (Number(v.stock) || 0), 0)
    tempForm.value.stock = total
  }
}, { deep: true })

onMounted(() => {
  fetchProductsData()
})
</script>

<style scoped>
.card-header { display: flex; justify-content: space-between; align-items: center; }
.filter-bar { display: flex; gap: 15px; margin-bottom: 20px; align-items: center; padding: 15px; background-color: #fafafa; border-radius: 4px; border: 1px solid #ebeef5; width: fit-content; }
:deep(.el-button) { padding: 8px 10px !important; min-width: unset !important; height: 32px; flex-shrink: 0; }
</style>
