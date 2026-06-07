<template>
  <el-card shadow="never">
    <template #header><div class="card-header"><span style="font-size: 16px; font-weight: bold;">Quản lý đánh giá sản phẩm</span></div></template>
    <el-table :data="paginatedReviews" stripe style="width: 100%">
      <el-table-column label="Sản phẩm" width="220">
        <template #default="scope">
          <div style="display: flex; align-items: center; gap: 10px;">
            <el-image style="width: 40px; height: 40px; border-radius: 4px;" :src="scope.row.image_url" fit="cover" />
            <span style="font-size: 12px; line-height: 1.2">{{ scope.row.product_name }}</span>
          </div>
        </template>
      </el-table-column>
      <el-table-column prop="user_name" label="Khách hàng" width="130" />
      <el-table-column label="Đánh giá" width="150">
        <template #default="scope">
          <el-rate v-model="scope.row.rating" disabled text-color="#ff9900" />
        </template>
      </el-table-column>
      <el-table-column label="Nội dung" min-width="200">
        <template #default="scope">
          <div style="margin-bottom: 5px">{{ scope.row.comment }}</div>
          <div v-if="scope.row.reply" style="font-size: 12px; color: #67C23A; background: #f0f9eb; padding: 5px; border-radius: 4px;">
            <b>Admin trả lời:</b> {{ scope.row.reply }}
          </div>
        </template>
      </el-table-column>
      <el-table-column label="Trạng thái" width="110" align="center">
        <template #default="scope">
          <el-tag :type="scope.row.is_approved == 1 ? 'success' : 'warning'">
            {{ scope.row.is_approved == 1 ? 'Đã duyệt' : 'Chờ duyệt' }}
          </el-tag>
        </template>
      </el-table-column>
      <el-table-column label="Thao tác" width="180" align="center">
        <template #default="scope">
          <el-button v-if="scope.row.is_approved == 0" size="small" type="success" :icon="Check" @click="handleApproveReview(scope.row.id, 1)">Duyệt</el-button>
          <el-button v-if="scope.row.is_approved == 1" size="small" type="primary" :icon="ChatLineRound" @click="openReplyDialog(scope.row)">Trả lời</el-button>
          <el-button size="small" type="danger" :icon="Delete" @click="handleDeleteReview(scope.row.id)">Xoá</el-button>
        </template>
      </el-table-column>
    </el-table>
    
    <div style="display: flex; justify-content: flex-end; margin-top: 20px;">
      <el-pagination v-model:current-page="currentPage" v-model:page-size="pageSize" :page-sizes="[10, 20, 50]" :total="reviewsData.length" layout="total, sizes, prev, pager, next" />
    </div>
  </el-card>

  <!-- DIALOG TRẢ LỜI ĐÁNH GIÁ -->
  <el-dialog v-model="replyDialogVisible" title="Trả lời đánh giá khách hàng" width="500px">
    <el-input v-model="replyContent" type="textarea" :rows="4" placeholder="Nhập câu trả lời của bạn..." />
    <template #footer><el-button @click="replyDialogVisible = false">Hủy</el-button><el-button type="primary" @click="submitReply">Gửi trả lời</el-button></template>
  </el-dialog>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { Check, ChatLineRound, Delete } from '@element-plus/icons-vue'
import { getReviews, updateReview, deleteReview } from '../services/reviewService'
import { ElMessage, ElMessageBox } from 'element-plus'

const reviewsData = ref([])
const replyDialogVisible = ref(false)
const replyContent = ref('')
const currentReviewId = ref(null)

const currentPage = ref(1)
const pageSize = ref(10)

const paginatedReviews = computed(() => {
  const start = (currentPage.value - 1) * pageSize.value;
  return reviewsData.value.slice(start, start + pageSize.value);
})

const fetchReviewsData = async () => {
  const res = await getReviews()
  if (res && res.success) {
    reviewsData.value = res.data
  }
}

const handleApproveReview = async (id, status) => {
  const loading = ElMessage({ message: 'Đang xử lý...', type: 'info', duration: 0 })
  const res = await updateReview({ id, is_approved: status })
  loading.close()
  if (res && res.success) {
    ElMessage.success('Đã duyệt bình luận!')
    fetchReviewsData()
  }
}

const handleDeleteReview = (id) => {
  ElMessageBox.confirm('Xoá đánh giá này vĩnh viễn?', 'Cảnh báo', { type: 'warning' }).then(async () => {
    const res = await deleteReview(id)
    if (res && res.success) {
      ElMessage.success('Đã xoá bình luận!')
      fetchReviewsData()
    }
  }).catch(() => {})
}

const openReplyDialog = (row) => {
  currentReviewId.value = row.id
  replyContent.value = row.reply || ''
  replyDialogVisible.value = true
}

const submitReply = async () => {
  if (!replyContent.value.trim()) return ElMessage.warning('Vui lòng nhập nội dung trả lời')
  const loading = ElMessage({ message: 'Đang gửi...', type: 'info', duration: 0 })
  const res = await updateReview({ id: currentReviewId.value, reply: replyContent.value })
  loading.close()
  if (res && res.success) {
    ElMessage.success('Đã gửi câu trả lời!')
    replyDialogVisible.value = false
    fetchReviewsData()
  }
}

onMounted(() => {
  fetchReviewsData()
})
</script>

<style scoped>
.card-header { display: flex; justify-content: space-between; align-items: center; }
:deep(.el-button) { padding: 8px 10px !important; min-width: unset !important; height: 32px; flex-shrink: 0; }
</style>
