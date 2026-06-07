<template>
  <el-card shadow="never">
    <template #header>
      <div class="card-header">
        <span style="font-size: 16px; font-weight: bold;">Quản lý Tin Tức - Bài Viết</span>
        <el-button type="primary" @click="openAddNewsDialog" :icon="Plus">Thêm Bài Mới</el-button>
      </div>
    </template>
    
    <el-table :data="paginatedNews" stripe style="width: 100%" v-loading="loading">
      <el-table-column label="Ảnh Bìa" width="100">
        <template #default="scope">
          <el-image :src="scope.row.thumbnail" style="width: 60px; height: 40px; border-radius: 4px; object-fit: cover;" />
        </template>
      </el-table-column>
      <el-table-column prop="title" label="Tiêu đề" show-overflow-tooltip min-width="250" />
      <el-table-column prop="view_count" label="Lượt xem" width="100" align="center">
        <template #default="scope"><el-tag type="info" size="small">{{ scope.row.view_count || 0 }}</el-tag></template>
      </el-table-column>
      <el-table-column label="Ngày tạo" width="120">
        <template #default="scope">{{ new Date(scope.row.created_at).toLocaleDateString('vi-VN') }}</template>
      </el-table-column>
      <el-table-column label="Hiển thị" width="100" align="center">
        <template #default="scope">
          <el-switch v-model="scope.row.is_published" :active-value="1" :inactive-value="0" @change="(val) => togglePublishStatus(scope.row, val)" />
        </template>
      </el-table-column>
      <el-table-column label="Thao tác" width="180" align="center">
        <template #default="scope">
          <el-button size="small" type="primary" @click="editNews(scope.row)">Sửa</el-button>
          <el-button size="small" type="danger" :icon="Delete" @click="deleteNewsHandler(scope.row.id)">Xóa</el-button>
        </template>
      </el-table-column>
    </el-table>

    <div style="display: flex; justify-content: flex-end; margin-top: 20px;">
      <el-pagination v-model:current-page="currentPage" v-model:page-size="pageSize" :page-sizes="[10, 20, 50]" :total="newsData.length" layout="total, sizes, prev, pager, next" />
    </div>
  </el-card>

  <!-- DIALOG THÊM/SỬA TIN TỨC -->
  <el-dialog
    v-model="newsDialogVisible"
    :title="tempNews.id ? 'Sửa bài viết' : 'Thêm bài viết mới'"
    width="900px"
    top="5vh"
    destroy-on-close
    @opened="initializeQuillEditor"
    @closed="handleDialogClose"
  >
    <el-form :model="tempNews" label-position="top">
      <el-row :gutter="20">
        <el-col :span="16">
          <el-form-item label="Tiêu đề bài viết">
            <el-input v-model="tempNews.title" placeholder="Nhập tiêu đề..." @blur="generateSlug" />
          </el-form-item>
          <el-form-item label="Đường dẫn (Slug)">
            <el-input v-model="tempNews.slug" placeholder="VD: huong-dan-chon-den-trang-tri" />
          </el-form-item>
        </el-col>
        <el-col :span="8">
          <el-form-item label="Ảnh bìa bài viết (Thumbnail)">
            <el-upload action="#" :auto-upload="false" :show-file-list="false" @change="handleThumbnailUpload" style="width: 100%;">
              <div v-if="tempNews.thumbnail" style="position: relative; width: 100%; height: 120px;">
                <img :src="tempNews.thumbnail" style="width: 100%; height: 100%; border-radius: 4px; object-fit: cover;" />
              </div>
              <div v-else class="product-uploader-content">
                <el-icon :size="24"><Plus /></el-icon>
                <span>Chọn ảnh bìa</span>
              </div>
            </el-upload>
          </el-form-item>
        </el-col>
      </el-row>
      
      <el-form-item label="Đoạn tóm tắt">
        <el-input v-model="tempNews.summary" type="textarea" :rows="2" placeholder="Tóm tắt ngắn gọn nội dung bài viết..." />
      </el-form-item>
      
      <el-form-item label="Nội dung bài viết">
        <div ref="editorWrapper" class="news-editor-wrap">
          <div
            :key="editorKey"
            ref="editorContainer"
            spellcheck="false"
            class="news-editor-host"
          ></div>
        </div>
      </el-form-item>
    </el-form>
    
    <template #footer>
      <el-button @click="newsDialogVisible = false">Hủy</el-button>
      <el-button type="primary" :icon="Check" :loading="saving" @click="saveNewsBtn">Lưu bài viết</el-button>
    </template>
  </el-dialog>
</template>

<script setup>
import { ref, computed, onMounted, nextTick } from 'vue'
import { Plus, Delete, Check } from '@element-plus/icons-vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { getNews, getNewsDetail, addNews, updateNews, deleteNews } from '../services/newsService'
import { uploadImage } from '../services/uploadService'
import { useAuthStore } from '../stores/auth'
import { sanitizeNewsHtml } from '../utils/format'

const authStore = useAuthStore()

const editorWrapper = ref(null)
const editorContainer = ref(null)
const editorKey = ref(0)
const newsData = ref([])
const loading = ref(false)
const newsDialogVisible = ref(false)
const saving = ref(false)

const currentPage = ref(1)
const pageSize = ref(10)

const paginatedNews = computed(() => {
  const start = (currentPage.value - 1) * pageSize.value
  return newsData.value.slice(start, start + pageSize.value)
})

const tempNews = ref({ id: null, title: '', slug: '', thumbnail: '', summary: '', content: '', is_published: 1, author_id: authStore.user?.id })

const fetchNewsData = async () => {
  loading.value = true
  try {
    const res = await getNews(true) // Get as admin
    if (res && res.success) {
      newsData.value = res.data
    }
  } catch (error) {
    console.error(error)
  } finally {
    loading.value = false
  }
}

let quillInstance = null
let pendingImageInsertIndex = 0

const getImageInsertIndex = () => {
  if (!quillInstance) return 0
  const range = quillInstance.getSelection()
  if (range) return range.index
  return pendingImageInsertIndex ?? 0
}

const insertImageAtCursor = (url) => {
  const index = getImageInsertIndex()
  quillInstance.focus()
  quillInstance.insertEmbed(index, 'image', url, 'user')
  quillInstance.setSelection(index + 1, 0)
  tempNews.value.content = quillInstance.root.innerHTML
}

const disableEditorSpellcheck = (root) => {
  if (!root) return
  root.setAttribute('spellcheck', 'false')
  root.setAttribute('autocorrect', 'off')
  root.setAttribute('autocapitalize', 'off')
  root.setAttribute('data-gramm', 'false')
  root.setAttribute('data-gramm_editor', 'false')
}

const loadQuill = () => {
  return new Promise((resolve) => {
    if (window.Quill) {
      resolve(window.Quill)
      return
    }
    const link = document.createElement('link')
    link.rel = 'stylesheet'
    link.href = 'https://cdn.jsdelivr.net/npm/quill@2.0.2/dist/quill.snow.css'
    document.head.appendChild(link)
    
    const script = document.createElement('script')
    script.src = 'https://cdn.jsdelivr.net/npm/quill@2.0.2/dist/quill.js'
    script.onload = () => {
      resolve(window.Quill)
    }
    document.head.appendChild(script)
  })
}

const destroyQuillEditor = () => {
  if (quillInstance) {
    quillInstance.off('text-change')
    quillInstance.off('selection-change')
    quillInstance = null
  }
  pendingImageInsertIndex = 0
  editorWrapper.value?.querySelectorAll('.ql-toolbar').forEach((el) => el.remove())
  editorKey.value += 1
}

const initializeQuillEditor = async () => {
  await nextTick()
  const Quill = await loadQuill()

  if (quillInstance) {
    quillInstance.root.innerHTML = tempNews.value.content || ''
    disableEditorSpellcheck(quillInstance.root)
    return
  }

  if (!editorContainer.value) return

  editorWrapper.value?.querySelectorAll('.ql-toolbar').forEach((el) => el.remove())

  quillInstance = new Quill(editorContainer.value, {
      theme: 'snow',
      placeholder: 'Viết nội dung bài viết thú vị của bạn tại đây...',
      modules: {
        toolbar: {
          container: [
            [{ 'header': [2, 3, false] }],
            ['bold', 'italic', 'underline', 'strike'],
            [{ 'list': 'ordered' }, { 'list': 'bullet' }],
            ['link', 'image', 'clean']
          ],
          handlers: {
            image: () => {
              const range = quillInstance.getSelection()
              if (range) pendingImageInsertIndex = range.index

              const input = document.createElement('input')
              input.type = 'file'
              input.accept = 'image/*'
              input.onchange = async () => {
                const file = input.files?.[0]
                if (!file) return
                const uploadLoading = ElMessage({ message: 'Đang tải ảnh lên...', type: 'info', duration: 0 })
                try {
                  const res = await uploadImage(file, 'gallery')
                  uploadLoading.close()
                  if (res?.success) {
                    insertImageAtCursor(res.url)
                    ElMessage.success('Đã chèn ảnh tại vị trí con trỏ!')
                  } else {
                    ElMessage.error(res?.message || 'Lỗi tải ảnh lên')
                  }
                } catch {
                  uploadLoading.close()
                  ElMessage.error('Lỗi kết nối máy chủ')
                }
              }
              input.click()
            }
          }
        }
      }
    })
    
    quillInstance.root.innerHTML = tempNews.value.content || ''
    disableEditorSpellcheck(quillInstance.root)

    quillInstance.on('selection-change', (range) => {
      if (range) pendingImageInsertIndex = range.index
    })

    quillInstance.on('text-change', () => {
      tempNews.value.content = quillInstance.root.innerHTML
    })
}

const openAddNewsDialog = () => {
  tempNews.value = { id: null, title: '', slug: '', thumbnail: '', summary: '', content: '', is_published: 1, author_id: authStore.user?.id }
  newsDialogVisible.value = true
}

const editNews = async (row) => {
  const detailRes = await getNewsDetail(row.slug, true)
  if (detailRes?.success) {
    tempNews.value = { ...detailRes.data }
  } else {
    tempNews.value = { ...row, content: row.content || '' }
    ElMessage.warning('Không tải được nội dung đầy đủ, vui lòng thử lại')
  }
  newsDialogVisible.value = true
  await nextTick()
  if (quillInstance) {
    quillInstance.root.innerHTML = tempNews.value.content || ''
    disableEditorSpellcheck(quillInstance.root)
  }
}

const handleDialogClose = () => {
  destroyQuillEditor()
}

const generateSlug = () => {
  if (!tempNews.value.id && tempNews.value.title && !tempNews.value.slug) {
    tempNews.value.slug = tempNews.value.title.toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '').replace(/[đĐ]/g, 'd').replace(/([^0-9a-z-\s])/g, '').replace(/(\s+)/g, '-').replace(/-+/g, '-').replace(/^-+|-+$/g, '')
  }
}

const handleThumbnailUpload = async (file) => {
  const uploadLoading = ElMessage({ message: 'Đang upload ảnh...', type: 'info', duration: 0 })
  const res = await uploadImage(file.raw, 'gallery')
  uploadLoading.close()
  if (res && res.success) {
    tempNews.value.thumbnail = res.url
  } else {
    ElMessage.error(res?.message || 'Lỗi upload ảnh')
  }
}

const togglePublishStatus = async (row, val) => {
  const statusLoading = ElMessage({ message: 'Đang cập nhật...', type: 'info', duration: 0 })
  try {
    const res = await updateNews({ id: row.id, is_published: val })
    if (res && res.success) {
      ElMessage.success('Đã cập nhật trạng thái')
    } else {
      row.is_published = val === 1 ? 0 : 1
      ElMessage.error('Lỗi cập nhật trạng thái')
    }
  } catch (error) {
    row.is_published = val === 1 ? 0 : 1
  } finally {
    statusLoading.close()
  }
}

const saveNewsBtn = async () => {
  if (quillInstance) {
    tempNews.value.content = quillInstance.root.innerHTML
  }
  tempNews.value.content = sanitizeNewsHtml(tempNews.value.content)

  if (!tempNews.value.title || !tempNews.value.slug || !tempNews.value.content) {
    return ElMessage.warning('Vui lòng nhập Tiêu đề, Slug và Nội dung chính')
  }

  saving.value = true
  try {
    let res
    if (tempNews.value.id) {
      res = await updateNews(tempNews.value)
    } else {
      res = await addNews(tempNews.value)
    }
    
    if (res && res.success) {
      ElMessage.success(tempNews.value.id ? 'Cập nhật thành công!' : 'Tạo mới thành công!')
      newsDialogVisible.value = false
      fetchNewsData()
    } else {
      ElMessage.error(res?.message || 'Lỗi lưu bài viết')
    }
  } catch (error) {
    ElMessage.error('Lỗi kết nối')
  } finally {
    saving.value = false
  }
}

const deleteNewsHandler = (id) => {
  ElMessageBox.confirm('Bài viết này sẽ bị xoá vĩnh viễn?', 'Cảnh báo', { type: 'warning' }).then(async () => {
    const res = await deleteNews(id)
    if (res && res.success) {
      ElMessage.success('Đã xoá bài viết')
      fetchNewsData()
    }
  }).catch(() => {})
}

onMounted(() => {
  fetchNewsData()
})
</script>

<style scoped>
.card-header { display: flex; justify-content: space-between; align-items: center; }

/* Custom wide & padded design for thumbnail uploader on dialog */
.product-uploader-content {
  width: 100%;
  min-width: 120px;
  height: 120px;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  gap: 8px;
  border: 1px dashed #ccc;
  border-radius: 4px;
  background: #fafafa;
  color: #8c939d;
  cursor: pointer;
  box-sizing: border-box;
  font-size: 13px;
  padding: 10px;
}
.product-uploader-content:hover {
  border-color: #D8B257;
  color: #D8B257;
}

.news-editor-wrap {
  width: 100%;
}

.news-editor-host {
  min-height: 300px;
  background-color: #fff;
}

/* Quill editor customization to fit Element Plus forms harmoniously */
:deep(.ql-toolbar.ql-snow) {
  border: 1px solid #dcdfe6;
  border-top-left-radius: 4px;
  border-top-right-radius: 4px;
  background-color: #fafafa;
  padding: 8px;
}
:deep(.ql-container.ql-snow) {
  border: 1px solid #dcdfe6;
  border-bottom-left-radius: 4px;
  border-bottom-right-radius: 4px;
  font-family: inherit;
  font-size: 14px;
}
:deep(.ql-editor) {
  min-height: 250px;
}
</style>
