<template>
  <el-card shadow="never">
    <template #header>
      <div class="card-header">
        <span style="font-size: 16px; font-weight: bold;">Danh sách đơn chờ xác nhận</span>
        <el-button
          v-if="pendingOrders.length > 0"
          type="success"
          size="small"
          :loading="bulkApproving"
          @click="approveAllOrders"
        >
          Xác nhận tất cả ({{ pendingOrders.length }})
        </el-button>
      </div>
    </template>
    <el-table v-if="pendingOrders.length > 0" :data="pendingOrders" stripe style="width: 100%">
      <el-table-column type="expand">
        <template #default="props">
          <div style="padding: 10px 50px">
            <h4 style="margin-bottom: 10px; color: #409EFF">Sản phẩm trong đơn:</h4>
            <el-table :data="props.row.items" border size="small">
              <el-table-column label="Ảnh" width="70">
                <template #default="itemScope">
                  <el-image :src="itemScope.row.image_url" style="width: 40px; height: 40px; border-radius: 4px;" fit="cover" />
                </template>
              </el-table-column>
              <el-table-column label="Tên sản phẩm" prop="product_name">
                <template #default="itemScope">
                  <div style="font-weight: bold;">{{ itemScope.row.product_name }}</div>
                  <div v-if="itemScope.row.kich_thuoc || itemScope.row.anh_sang" style="font-size: 12px; color: #909399;">
                    Phân loại: {{ itemScope.row.kich_thuoc }} {{ itemScope.row.anh_sang }}
                  </div>
                </template>
              </el-table-column>
              <el-table-column label="Số lượng" prop="quantity" width="100" align="center" />
              <el-table-column label="Đơn giá" width="150">
                <template #default="itemScope">{{ formatPrice(itemScope.row.price) }} đ</template>
              </el-table-column>
              <el-table-column label="Thành tiền" width="150">
                <template #default="itemScope">
                  <span style="font-weight: bold; color: #f56c6c;">{{ formatPrice(itemScope.row.price * itemScope.row.quantity) }} đ</span>
                </template>
              </el-table-column>
            </el-table>
          </div>
        </template>
      </el-table-column>
      <el-table-column prop="orderId" label="Mã Đơn" width="120" />
      <el-table-column prop="customerName" label="Khách hàng" />
      <el-table-column prop="date" label="Ngày đặt" width="150" />
      <el-table-column prop="total" label="Tổng tiền" width="150"><template #default="scope"><span style="color: #f56c6c; font-weight: bold;">{{ scope.row.total }} đ</span></template></el-table-column>
      <el-table-column prop="status" label="Trạng thái" width="150"><template #default><el-tag type="warning" effect="dark">Chờ xác nhận</el-tag></template></el-table-column>
      <el-table-column label="Thao tác" width="200">
        <template #default="scope">
          <el-button size="small" type="success" @click="approveOrder(scope.$index)">Xác nhận</el-button>
          <el-button size="small" type="danger" @click="cancelOrder(scope.$index)">Hủy</el-button>
        </template>
      </el-table-column>
    </el-table>
    <el-empty v-else description="Tuyệt vời! Đã duyệt hết đơn hàng." />
  </el-card>
</template>

<script setup>
import { ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { updateOrder } from '../services/orderService'
import { useAuthStore } from '../stores/auth'
import { formatPrice } from '../utils/format'

const authStore = useAuthStore()
const bulkApproving = ref(false)

const props = defineProps({
  pendingOrders: { type: Array, required: true }
})

const emit = defineEmits(['approved', 'cancelled'])

const approveOrder = async (index) => {
  const order = props.pendingOrders[index]
  const loading = ElMessage({ message: 'Đang xử lý...', type: 'info', duration: 0 })
  const result = await updateOrder(order.db_id, 'approved', authStore.user?.id)
  loading.close()
  
  if (result && result.success) {
    ElMessage.success(`Duyệt đơn ${order.orderId} thành công!`)
    emit('approved')
  } else {
    ElMessage.error(result?.message || 'Lỗi khi duyệt đơn')
  }
}

const approveAllOrders = async () => {
  ElMessageBox.confirm(
    `Xác nhận tất cả ${props.pendingOrders.length} đơn đang chờ?`,
    'Xác nhận hàng loạt',
    { confirmButtonText: 'Đồng ý', cancelButtonText: 'Hủy', type: 'info' }
  ).then(async () => {
    bulkApproving.value = true
    let ok = 0
    let fail = 0
    for (const order of props.pendingOrders) {
      const result = await updateOrder(order.db_id, 'approved', authStore.user?.id)
      if (result && result.success) ok++
      else fail++
    }
    bulkApproving.value = false
    if (fail === 0) {
      ElMessage.success(`Đã duyệt ${ok} đơn hàng`)
    } else {
      ElMessage.warning(`Thành công ${ok}, thất bại ${fail}`)
    }
    emit('approved')
  }).catch(() => {})
}

const cancelOrder = async (index) => {
  const order = props.pendingOrders[index]
  ElMessageBox.confirm(`Bạn muốn hủy đơn hàng ${order.orderId}?`, 'Xác nhận hủy', {
    confirmButtonText: 'Đồng ý',
    cancelButtonText: 'Hủy bỏ',
    type: 'warning'
  }).then(async () => {
    const loading = ElMessage({ message: 'Đang xử lý...', type: 'info', duration: 0 })
    const result = await updateOrder(order.db_id, 'cancelled', authStore.user?.id)
    loading.close()
    
    if (result && result.success) {
      ElMessage.success(`Đã hủy đơn ${order.orderId}`)
      emit('cancelled')
    } else {
      ElMessage.error(result?.message || 'Lỗi khi hủy đơn')
    }
  }).catch(() => {})
}
</script>

<style scoped>
.card-header { display: flex; justify-content: space-between; align-items: center; }
</style>
