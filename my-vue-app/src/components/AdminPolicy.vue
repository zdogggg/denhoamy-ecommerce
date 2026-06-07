<template>
  <el-card shadow="never">
    <template #header>
      <div class="card-header">
        <span style="font-size: 16px; font-weight: bold;">Quản lý nội dung Chính sách</span>
        <el-button type="primary" :icon="Check" :loading="saving" @click="savePolicies">Lưu tất cả</el-button>
      </div>
    </template>

    <p class="policy-hint">
      Nội dung hiển thị tại trang <router-link to="/policy" target="_blank">/policy</router-link> (footer website).
    </p>

    <el-tabs v-model="activeTab">
      <el-tab-pane
        v-for="tab in policyTabs"
        :key="tab.key"
        :label="tab.label"
        :name="tab.key"
      />
    </el-tabs>

    <div v-loading="loading" class="policy-editor-section">
      <div ref="editorWrapper" class="policy-editor-wrap">
        <div
          :key="editorKey"
          ref="editorContainer"
          spellcheck="false"
          class="policy-editor-host"
        ></div>
      </div>
    </div>
  </el-card>
</template>

<script setup>
import { ref, watch, onMounted, onBeforeUnmount, nextTick } from 'vue'
import { Check } from '@element-plus/icons-vue'
import { ElMessage } from 'element-plus'
import { getSettings, updateSettings } from '../services/settingsService'
import { uploadImage } from '../services/uploadService'
import { sanitizeNewsHtml } from '../utils/format'
import { useSettingsStore } from '../stores/settings'

const settingsStore = useSettingsStore()

const policyTabs = [
  { key: 'bao-hanh', label: 'Bảo hành', settingKey: 'policy_bao_hanh' },
  { key: 'doi-tra', label: 'Đổi trả', settingKey: 'policy_doi_tra' },
  { key: 'van-chuyen', label: 'Vận chuyển', settingKey: 'policy_van_chuyen' },
  { key: 'huong-dan', label: 'Hướng dẫn mua hàng', settingKey: 'policy_huong_dan' }
]

const activeTab = ref('bao-hanh')
const loading = ref(false)
const saving = ref(false)
const editorWrapper = ref(null)
const editorContainer = ref(null)
const editorKey = ref(0)

const policyContents = ref({
  'bao-hanh': '',
  'doi-tra': '',
  'van-chuyen': '',
  'huong-dan': ''
})

let quillInstance = null
let pendingImageInsertIndex = 0

const syncEditorToState = () => {
  if (quillInstance) {
    policyContents.value[activeTab.value] = quillInstance.root.innerHTML
  }
}

const loadQuill = () => {
  return new Promise((resolve) => {
    if (window.Quill) {
      resolve(window.Quill)
      return
    }
    if (!document.querySelector('link[data-quill-css]')) {
      const link = document.createElement('link')
      link.rel = 'stylesheet'
      link.href = 'https://cdn.jsdelivr.net/npm/quill@2.0.2/dist/quill.snow.css'
      link.setAttribute('data-quill-css', '1')
      document.head.appendChild(link)
    }
    const script = document.createElement('script')
    script.src = 'https://cdn.jsdelivr.net/npm/quill@2.0.2/dist/quill.js'
    script.onload = () => resolve(window.Quill)
    document.head.appendChild(script)
  })
}

const disableEditorSpellcheck = (root) => {
  if (!root) return
  root.setAttribute('spellcheck', 'false')
  root.setAttribute('autocorrect', 'off')
  root.setAttribute('autocapitalize', 'off')
  root.setAttribute('data-gramm', 'false')
  root.setAttribute('data-gramm_editor', 'false')
}

const insertImageAtCursor = (url) => {
  if (!quillInstance) return
  const range = quillInstance.getSelection()
  const index = range ? range.index : pendingImageInsertIndex
  quillInstance.focus()
  quillInstance.insertEmbed(index, 'image', url, 'user')
  quillInstance.setSelection(index + 1, 0)
  policyContents.value[activeTab.value] = quillInstance.root.innerHTML
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
  if (!editorContainer.value || quillInstance) return

  editorWrapper.value?.querySelectorAll('.ql-toolbar').forEach((el) => el.remove())

  quillInstance = new Quill(editorContainer.value, {
    theme: 'snow',
    placeholder: 'Soạn nội dung chính sách...',
    modules: {
      toolbar: {
        container: [
          [{ header: [2, 3, false] }],
          ['bold', 'italic', 'underline', 'strike'],
          [{ list: 'ordered' }, { list: 'bullet' }],
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
                  ElMessage.success('Đã chèn ảnh!')
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

  quillInstance.root.innerHTML = policyContents.value[activeTab.value] || ''
  disableEditorSpellcheck(quillInstance.root)

  quillInstance.on('selection-change', (range) => {
    if (range) pendingImageInsertIndex = range.index
  })

  quillInstance.on('text-change', () => {
    policyContents.value[activeTab.value] = quillInstance.root.innerHTML
  })
}

watch(activeTab, async (newTab, oldTab) => {
  if (!oldTab || !quillInstance) return

  policyContents.value[oldTab] = quillInstance.root.innerHTML

  await nextTick()
  quillInstance.root.innerHTML = policyContents.value[newTab] || ''
  disableEditorSpellcheck(quillInstance.root)
})

const loadPolicies = async () => {
  loading.value = true
  try {
    const res = await getSettings()
    if (res?.success && res.data) {
      policyContents.value = {
        'bao-hanh': res.data.policy_bao_hanh || '',
        'doi-tra': res.data.policy_doi_tra || '',
        'van-chuyen': res.data.policy_van_chuyen || '',
        'huong-dan': res.data.policy_huong_dan || ''
      }
    }
  } finally {
    loading.value = false
  }
}

const savePolicies = async () => {
  syncEditorToState()

  const payload = {}
  for (const tab of policyTabs) {
    payload[tab.settingKey] = sanitizeNewsHtml(policyContents.value[tab.key] || '')
  }

  saving.value = true
  try {
    const res = await updateSettings(payload)
    if (res?.success) {
      ElMessage.success('Đã lưu nội dung chính sách!')
      await settingsStore.fetchSettings()
    } else {
      ElMessage.error(res?.message || 'Lỗi khi lưu chính sách')
    }
  } finally {
    saving.value = false
  }
}

onMounted(async () => {
  await loadPolicies()
  await initializeQuillEditor()
})

onBeforeUnmount(() => {
  destroyQuillEditor()
})
</script>

<style scoped>
.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.policy-hint {
  margin: 0 0 16px;
  font-size: 13px;
  color: #909399;
}

.policy-editor-section {
  margin-top: 8px;
}

.policy-editor-wrap {
  width: 100%;
}

.policy-editor-host {
  min-height: 420px;
  background-color: #fff;
}

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
  min-height: 360px;
}
</style>
