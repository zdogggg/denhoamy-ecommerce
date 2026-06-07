<template>
  <el-card shadow="never">
    <template #header><div class="card-header"><span>Danh mục đèn nghệ thuật</span><el-button type="success" :icon="Plus" @click="openAddCategoryForm">Thêm danh mục</el-button></div></template>
    <el-table :data="categories" stripe style="width: 100%" row-key="id" :tree-props="{ children: 'children', hasChildren: 'hasChildren' }">
      <el-table-column prop="name" label="Tên danh mục" />
      <el-table-column prop="count" label="Số lượng sản phẩm" width="200" align="center" />
      <el-table-column label="Thao tác" width="150" align="center">
        <template #default="scope">
          <el-button size="small" link type="primary" @click="handleEditCategory(scope.row)">Sửa</el-button>
          <el-button size="small" link type="danger" @click="handleDeleteCategory(scope.row.id)">Xóa</el-button>
        </template>
      </el-table-column>
    </el-table>
  </el-card>

  <el-dialog v-model="categoryDialogVisible" :title="isEditCategory ? 'Sửa danh mục' : 'Thêm danh mục mới'" width="450px">
    <el-form :model="tempCategoryForm" label-position="top">
      <el-form-item label="Tên danh mục">
        <el-input v-model="tempCategoryForm.name" placeholder="Ví dụ: Đèn thả trần..." />
      </el-form-item>
      <el-form-item label="Danh mục cha (Để trống nếu là danh mục lớn nhất)">
        <el-select v-model="tempCategoryForm.parent_id" placeholder="-- Không chọn (Danh mục gốc) --" clearable style="width: 100%">
          <el-option 
            v-for="cat in flatCategories" 
            :key="cat.id" 
            :label="cat.name" 
            :value="cat.id" 
            :disabled="isEditCategory && (cat.id === tempCategoryForm.id || cat.parent_id === tempCategoryForm.id)"
          />
        </el-select>
      </el-form-item>
    </el-form>
    <template #footer>
      <el-button @click="categoryDialogVisible = false">Hủy</el-button>
      <el-button type="primary" @click="saveCategoryData">Xác nhận</el-button>
    </template>
  </el-dialog>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { Plus } from '@element-plus/icons-vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { getCategories, addCategory, updateCategory, deleteCategory } from '../services/categoryService'

const emit = defineEmits(['categories-updated'])

const categories = ref([])
const flatCategories = ref([])
const categoryDialogVisible = ref(false)
const isEditCategory = ref(false)
const tempCategoryForm = ref({ id: '', name: '', count: 0, parent_id: null, children: [] })

const fetchCategoriesData = async () => {
  const res = await getCategories()
  if (res && res.success) {
    categories.value = res.data
    flatCategories.value = res.flat || []
    emit('categories-updated', flatCategories.value)
  }
}

const openAddCategoryForm = () => { isEditCategory.value = false; tempCategoryForm.value = { id: '', name: '', count: 0, parent_id: null, children: [] }; categoryDialogVisible.value = true }
const handleEditCategory = (row) => { isEditCategory.value = true; tempCategoryForm.value = { ...row }; categoryDialogVisible.value = true }

const saveCategoryData = async () => {
  if (!tempCategoryForm.value.name) return ElMessage.warning('Vui lòng nhập tên danh mục')
  
  if (isEditCategory.value) {
    const res = await updateCategory({ id: tempCategoryForm.value.id, name: tempCategoryForm.value.name, parent_id: tempCategoryForm.value.parent_id })
    if (res && res.success) {
      ElMessage.success('Cập nhật tên danh mục thành công!')
      fetchCategoriesData()
    } else {
      ElMessage.error(res?.message || 'Có lỗi xảy ra')
    }
  } else {
    const res = await addCategory({ name: tempCategoryForm.value.name, parent_id: tempCategoryForm.value.parent_id })
    if (res && res.success) {
       ElMessage.success('Đã thêm danh mục mới!')
       fetchCategoriesData()
    } else {
       ElMessage.error(res?.message || 'Có lỗi xảy ra')
    }
  }
  categoryDialogVisible.value = false
}

const handleDeleteCategory = async (id) => {
  ElMessageBox.confirm('Khi xóa danh mục này thì các mục con (nếu có) cũng sẽ bị xóa. Các sản phẩm thuộc danh mục này sẽ mang nhãn Chưa phân loại. Bạn chắc chứ?', 'Cảnh báo', { type: 'warning' }).then(async () => {
    const res = await deleteCategory(id)
    if (res && res.success) {
      ElMessage.success('Đã xóa danh mục khỏi hệ thống.')
      fetchCategoriesData()
    } else {
      ElMessage.error(res?.message || 'Xóa thất bại')
    }
  }).catch(() => {})
}

onMounted(() => {
  fetchCategoriesData()
})
</script>

<style scoped>
.card-header { display: flex; justify-content: space-between; align-items: center; }
.card-header :deep(.el-button) { padding: 10px 20px !important; font-size: 14px; }
</style>
