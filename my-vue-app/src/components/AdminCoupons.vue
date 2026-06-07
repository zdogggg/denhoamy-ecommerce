<template>
  <el-card shadow="never">
    <template #header>
      <div class="card-header">
        <span style="font-size: 16px; font-weight: bold;">Quản lý Mã Giảm Giá (Voucher)</span>
        <el-button type="primary" @click="openAddCouponDialog" :icon="Plus">Tạo Voucher Mới</el-button>
      </div>
    </template>
    
    <el-table :data="paginatedCoupons" stripe style="width: 100%" v-loading="loadingCoupons">
      <el-table-column prop="code" label="Mã Khuyến Mãi" width="220" align="center">
        <template #default="scope">
          <el-tag type="warning" size="large" effect="dark" style="font-weight:bold; letter-spacing: 1px">{{ scope.row.code }}</el-tag>
        </template>
      </el-table-column>
      
      <el-table-column label="Mức giảm" min-width="130" align="center">
        <template #default="scope">
          <div style="color:red; font-weight:bold">
            {{ scope.row.discount_percent > 0 ? scope.row.discount_percent + '%' : formatPrice(scope.row.discount_amount) + 'đ' }}
          </div>
          <div v-if="scope.row.discount_percent > 0 && scope.row.max_discount_amount > 0" style="font-size: 11px; color: #666; margin-top: 4px;">
            (Tối đa: {{ formatPrice(scope.row.max_discount_amount) }}đ)
          </div>
        </template>
      </el-table-column>
      
      <el-table-column label="Đơn tối thiểu" min-width="150" align="center">
        <template #default="scope">{{ formatPrice(scope.row.min_order_value) }} đ</template>
      </el-table-column>
      
      <el-table-column prop="used_count" label="Đã dùng" min-width="140" align="center">
        <template #default="scope">
          <el-progress 
            :percentage="scope.row.usage_limit ? Math.min((scope.row.used_count / scope.row.usage_limit) * 100, 100) : 0" 
            :format="() => `${scope.row.used_count}/${scope.row.usage_limit || '∞'}`" 
            :stroke-width="10" 
          />
        </template>
      </el-table-column>
      
      <el-table-column label="Thời hạn" min-width="200" align="center">
        <template #default="scope">
          <span>{{ scope.row.start_date ? new Date(scope.row.start_date).toLocaleDateString('vi-VN') : '...' }}</span>
          <span style="margin: 0 5px;">-</span>
          <span>{{ scope.row.end_date ? new Date(scope.row.end_date).toLocaleDateString('vi-VN') : '...' }}</span>
        </template>
      </el-table-column>
      
      <el-table-column label="Bật/Tắt" width="100" align="center">
        <template #default="scope">
          <el-switch 
            v-model="scope.row.is_active" 
            :active-value="1" 
            :inactive-value="0" 
            @change="(val) => toggleCouponStatus(scope.row, val)" 
          />
        </template>
      </el-table-column>
      
      <el-table-column label="Thao tác" width="160" align="center">
        <template #default="scope">
          <el-button size="small" type="primary" @click="editCoupon(scope.row)">Sửa</el-button>
          <el-button size="small" type="danger" :icon="Delete" @click="deleteCouponHandler(scope.row.id)">Xóa</el-button>
        </template>
      </el-table-column>
    </el-table>

    <div style="display: flex; justify-content: flex-end; margin-top: 20px;">
      <el-pagination v-model:current-page="currentPage" v-model:page-size="pageSize" :page-sizes="[10, 20, 50]" :total="couponsData.length" layout="total, sizes, prev, pager, next" />
    </div>
  </el-card>

  <!-- DIALOG THÊM/SỬA MÃ GIẢM GIÁ -->
  <el-dialog v-model="couponDialogVisible" title="Quản lý Mã Khuyến Mãi" width="550px" top="5vh">
    <el-form :model="tempCoupon" label-position="top">
      <el-form-item label="Mã Khuyến Mãi (CODE)">
        <el-input v-model="tempCoupon.code" placeholder="VD: TET2026, FREESHIP..." style="text-transform: uppercase;" />
      </el-form-item>
      
      <el-row :gutter="20">
        <el-col :span="12">
          <el-form-item label="Giảm theo %">
            <el-input-number
              v-model="tempCoupon.discount_percent"
              :min="0"
              :max="100"
              :disabled="tempCoupon.discount_amount > 0"
              style="width:100%"
            />
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="Hoặc Giảm bằng Tiền mặt">
            <PriceInput
              v-model="tempCoupon.discount_amount"
              placeholder="VD: 100.000"
              :disabled="tempCoupon.discount_percent > 0"
              style="width:100%"
            />
          </el-form-item>
        </el-col>
      </el-row>

      <el-form-item label="Giảm tối đa (VNĐ) — bắt buộc khi giảm theo %">
        <PriceInput
          v-model="tempCoupon.max_discount_amount"
          placeholder="VD: 200.000 (25% tối đa 200k)"
          :disabled="!(tempCoupon.discount_percent > 0)"
          style="width:100%"
        />
      </el-form-item>
      
      <el-form-item label="Giá trị đơn hàng tối thiểu để áp dụng (VNĐ)">
        <PriceInput v-model="tempCoupon.min_order_value" placeholder="VD: 500.000" style="width:100%" />
      </el-form-item>
      
      <el-row :gutter="20">
        <el-col :span="12">
          <el-form-item label="Ngày Bắt đầu">
            <el-date-picker v-model="tempCoupon.start_date" type="date" value-format="YYYY-MM-DD" placeholder="Chọn ngày" style="width:100%" />
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="Ngày Kết thúc">
            <el-date-picker v-model="tempCoupon.end_date" type="date" value-format="YYYY-MM-DD" placeholder="Chọn ngày" style="width:100%" />
          </el-form-item>
        </el-col>
      </el-row>
      
      <el-form-item label="Giới hạn số lượt dùng (Để trống = vô hạn lượt)">
        <el-input
          :model-value="usageLimitDisplay"
          placeholder="Để trống nếu không giới hạn"
          inputmode="numeric"
          style="width:100%"
          @update:model-value="onUsageLimitInput"
        />
      </el-form-item>
    </el-form>
    
    <template #footer>
      <el-button @click="couponDialogVisible = false">Hủy</el-button>
      <el-button type="primary" :icon="Check" @click="saveCouponBtn">Lưu mã giảm giá</el-button>
    </template>
  </el-dialog>
</template>

<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import { Plus, Delete, Check } from '@element-plus/icons-vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { getCoupons, addCoupon, updateCoupon, deleteCoupon } from '../services/couponService'
import { formatPrice } from '../utils/format'
import PriceInput from './PriceInput.vue'

const couponsData = ref([])
const loadingCoupons = ref(false)
const couponDialogVisible = ref(false)
const tempCoupon = ref({ 
  id: null, 
  code: '', 
  discount_percent: 0, 
  discount_amount: 0, 
  max_discount_amount: null,
  min_order_value: 0, 
  usage_limit: null, 
  start_date: '', 
  end_date: '' 
})

const currentPage = ref(1)
const pageSize = ref(10)

const paginatedCoupons = computed(() => {
  const start = (currentPage.value - 1) * pageSize.value;
  return couponsData.value.slice(start, start + pageSize.value);
})

const usageLimitDisplay = computed(() => {
  const n = tempCoupon.value.usage_limit
  if (n === null || n === undefined || n === '') return ''
  return String(n)
})

const onUsageLimitInput = (raw) => {
  const digits = String(raw ?? '').replace(/\D/g, '')
  tempCoupon.value.usage_limit = digits ? parseInt(digits, 10) : null
}

watch(
  () => tempCoupon.value.discount_percent,
  (pct) => {
    if (Number(pct) > 0) {
      tempCoupon.value.discount_amount = 0
    }
  }
)

watch(
  () => tempCoupon.value.discount_amount,
  (amt) => {
    if (Number(amt) > 0) {
      tempCoupon.value.discount_percent = 0
      tempCoupon.value.max_discount_amount = null
    }
  }
)

const buildCouponPayload = () => {
  const code = (tempCoupon.value.code || '').trim().toUpperCase()
  if (!code) {
    ElMessage.warning('Vui lòng nhập Mã giảm giá')
    return null
  }

  const discountPercent = Math.min(100, Math.max(0, Number(tempCoupon.value.discount_percent) || 0))
  const discountAmount = Math.max(0, Number(tempCoupon.value.discount_amount) || 0)

  if (discountPercent === 0 && discountAmount === 0) {
    ElMessage.warning('Vui lòng thiết lập mức giảm giá (% hoặc số tiền)')
    return null
  }
  if (discountPercent > 0 && discountAmount > 0) {
    ElMessage.warning('Chỉ chọn một loại giảm: % hoặc tiền mặt, không dùng cả hai')
    return null
  }

  const { start_date, end_date } = tempCoupon.value
  if (start_date && end_date && end_date < start_date) {
    ElMessage.warning('Ngày kết thúc phải sau hoặc bằng ngày bắt đầu')
    return null
  }

  if (discountPercent > 0) {
    const maxVal = Number(tempCoupon.value.max_discount_amount)
    if (!maxVal || maxVal <= 0) {
      ElMessage.warning('Mã giảm % cần có "Giới hạn giảm tối đa" (kiểu Shopee: 25% tối đa 200.000đ)')
      return null
    }
  }

  const maxDiscount =
    discountPercent > 0 ? Number(tempCoupon.value.max_discount_amount) : null

  return {
    ...tempCoupon.value,
    code,
    discount_percent: discountPercent > 0 ? discountPercent : 0,
    discount_amount: discountAmount > 0 ? discountAmount : 0,
    max_discount_amount: maxDiscount && maxDiscount > 0 ? maxDiscount : null,
    min_order_value: Math.max(0, Number(tempCoupon.value.min_order_value) || 0),
    usage_limit:
      tempCoupon.value.usage_limit && Number(tempCoupon.value.usage_limit) > 0
        ? Number(tempCoupon.value.usage_limit)
        : null,
    start_date: start_date || null,
    end_date: end_date || null
  }
}

const fetchCouponsData = async () => {
  loadingCoupons.value = true
  try {
    const res = await getCoupons()
    if (res && res.success) {
      couponsData.value = res.data
    }
  } catch (error) {
    console.error('Error fetching coupons:', error)
  } finally {
    loadingCoupons.value = false
  }
}

const openAddCouponDialog = () => {
  tempCoupon.value = { 
    id: null, 
    code: '', 
    discount_percent: 0, 
    discount_amount: 0, 
    max_discount_amount: null,
    min_order_value: 0, 
    usage_limit: null, 
    start_date: '', 
    end_date: '' 
  }
  couponDialogVisible.value = true
}

const editCoupon = (row) => {
  tempCoupon.value = {
    ...row,
    discount_percent: Number(row.discount_percent) || 0,
    discount_amount: Number(row.discount_amount) || 0,
    max_discount_amount: row.max_discount_amount ? Number(row.max_discount_amount) : null,
    min_order_value: Number(row.min_order_value) || 0,
    usage_limit: row.usage_limit ? Number(row.usage_limit) : null
  }
  couponDialogVisible.value = true
}

const toggleCouponStatus = async (row, val) => {
  const loading = ElMessage({ message: 'Đang cập nhật...', type: 'info', duration: 0 })
  try {
    const res = await updateCoupon({ id: row.id, is_active: val })
    if (res && res.success) {
      ElMessage.success('Sửa trạng thái mã thành công!')
    } else {
      ElMessage.error('Lỗi khi đổi trạng thái')
      row.is_active = val === 1 ? 0 : 1
    }
  } catch (error) {
    ElMessage.error('Lỗi kết nối server')
    row.is_active = val === 1 ? 0 : 1
  } finally {
    loading.close()
  }
}

const saveCouponBtn = async () => {
  const payload = buildCouponPayload()
  if (!payload) return

  const loading = ElMessage({ message: 'Đang lưu...', type: 'info', duration: 0 })
  try {
    let res
    if (payload.id) {
      res = await updateCoupon(payload)
    } else {
      res = await addCoupon(payload)
    }
    
    if (res && res.success) {
      ElMessage.success('Lưu mã giảm giá thành công!')
      couponDialogVisible.value = false
      fetchCouponsData()
    } else {
      ElMessage.error(res?.message || 'Có lỗi khi lưu')
    }
  } catch (error) {
    ElMessage.error('Lỗi kết nối server')
  } finally {
    loading.close()
  }
}

const deleteCouponHandler = (id) => {
  ElMessageBox.confirm('Hành động này sẽ xóa mã giảm giá. Bạn có chắc chắn?', 'Cảnh báo', { 
    type: 'warning' 
  }).then(async () => {
    try {
      const res = await deleteCoupon(id)
      if (res && res.success) {
        ElMessage.success('Đã xóa mã!')
        fetchCouponsData()
      }
    } catch (error) {
      ElMessage.error('Lỗi khi xóa mã')
    }
  }).catch(() => {})
}

onMounted(() => {
  fetchCouponsData()
})
</script>

<style scoped>
/* Tiêu đề card và nút thêm */
.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
:deep(.el-button) { padding: 8px 12px !important; min-width: unset !important; height: 32px; flex-shrink: 0; }
</style>
