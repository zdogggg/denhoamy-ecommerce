<template>
  <el-card shadow="never">
    <template #header><div class="card-header"><span style="font-size: 16px; font-weight: bold;">Cấu hình Website</span></div></template>
    <el-form :model="settingsForm" label-position="top" style="max-width: 600px;">
      <el-form-item label="Tên cửa hàng">
        <el-input v-model="settingsForm.shop_name" placeholder="VD: ĐÈN HOA MỸ" />
      </el-form-item>
      
      <el-form-item label="Ảnh Logo">
        <el-upload action="#" :auto-upload="false" :show-file-list="false" @change="handleLogoUpload">
          <div class="logo-upload-container">
            <img v-if="settingsForm.logo_url" :src="settingsForm.logo_url" class="logo-preview" />
            <el-button type="primary" plain size="small">Chọn Ảnh Logo mới</el-button>
          </div>
        </el-upload>
      </el-form-item>
      
      <el-form-item label="Danh sách Ảnh Banner (Tối đa 6 ảnh)">
        <el-upload
          class="banner-uploader"
          action="#"
          list-type="picture-card"
          :auto-upload="false"
          :file-list="bannerFileList"
          :on-change="handleBannerChange"
          :on-remove="handleBannerRemove"
          :limit="6"
          accept="image/*"
        >
          <el-icon><Plus /></el-icon>
        </el-upload>
      </el-form-item>
      
      <el-form-item label="Hotline liên hệ">
        <el-input v-model="settingsForm.hotline" />
      </el-form-item>
      <el-form-item label="Email hỗ trợ">
        <el-input v-model="settingsForm.email" />
      </el-form-item>
      <el-form-item label="Địa chỉ cửa hàng">
        <el-input type="textarea" v-model="settingsForm.address" />
      </el-form-item>

      <div style="margin: 20px 0; border-top: 1px dashed #ccc; padding-top: 15px;">
        <h4 style="margin: 0 0 15px 0; color: #D8B257;">Cấu hình 2 Banner Quảng cáo sườn (Dọc ~260×620px)</h4>
        <el-row :gutter="20">
          <el-col :span="12" style="border-right: 1px dashed #eee;">
            <h5 style="margin: 0 0 10px 0; color: #606266;">Banner bên Trái</h5>
            <el-form-item label="Ảnh Banner">
              <el-upload action="#" :auto-upload="false" :show-file-list="false" @change="handleLeftAdUpload">
                <div class="logo-upload-container">
                  <img v-if="settingsForm.ads_left_url" :src="settingsForm.ads_left_url" class="ad-preview-vertical" />
                  <el-button type="primary" plain size="small">Chọn ảnh mới</el-button>
                </div>
              </el-upload>
            </el-form-item>
            <el-form-item label="Liên kết Banner">
              <el-input v-model="settingsForm.ads_left_link" placeholder="VD: /category?type=Đèn thả" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <h5 style="margin: 0 0 10px 0; color: #606266;">Banner bên Phải</h5>
            <el-form-item label="Ảnh Banner">
              <el-upload action="#" :auto-upload="false" :show-file-list="false" @change="handleRightAdUpload">
                <div class="logo-upload-container">
                  <img v-if="settingsForm.ads_right_url" :src="settingsForm.ads_right_url" class="ad-preview-vertical" />
                  <el-button type="primary" plain size="small">Chọn ảnh mới</el-button>
                </div>
              </el-upload>
            </el-form-item>
            <el-form-item label="Liên kết Banner">
              <el-input v-model="settingsForm.ads_right_link" placeholder="VD: /" />
            </el-form-item>
          </el-col>
        </el-row>
      </div>

      <div style="margin: 20px 0; border-top: 1px dashed #ccc; padding-top: 15px;">
        <h4 style="margin: 0 0 15px 0; color: #D8B257;">Banner ngang trước Hot Deal (1920×459px)</h4>
        <p style="margin: 0 0 12px 0; font-size: 13px; color: #909399;">
          Tỉ lệ 1920:459. Hiển thị ngay trên Hot Deal (sau danh mục). Retina: 3840×918. Để trống ảnh thì banner sẽ không hiện.
        </p>
        <el-form-item label="Ảnh Banner">
          <el-upload action="#" :auto-upload="false" :show-file-list="false" @change="handleBottomAdUpload">
            <div class="logo-upload-container">
              <img v-if="settingsForm.ads_bottom_url" :src="settingsForm.ads_bottom_url" class="ad-preview-horizontal" />
              <el-button type="primary" plain size="small">Chọn ảnh banner ngang</el-button>
            </div>
          </el-upload>
        </el-form-item>
        <el-form-item label="Liên kết Banner (tùy chọn)">
          <el-input v-model="settingsForm.ads_bottom_link" placeholder="VD: /category?type=Đèn chùm hoặc https://..." />
        </el-form-item>
      </div>

      <el-form-item style="margin-top: 30px;">
        <el-button type="primary" size="large" @click="saveWebSettings">Lưu Cài đặt</el-button>
      </el-form-item>
    </el-form>
  </el-card>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { Plus } from '@element-plus/icons-vue'
import { getSettings, updateSettings } from '../services/settingsService'
import { uploadImage } from '../services/uploadService'
import { useSettingsStore } from '../stores/settings'
import { ElMessage } from 'element-plus'

const settingsStore = useSettingsStore()

const emit = defineEmits(['settings-loaded'])

const settingsForm = ref({ shop_name: '', logo_url: '', banner_urls: '', hotline: '', email: '', address: '', ads_left_url: '', ads_left_link: '', ads_right_url: '', ads_right_link: '', ads_bottom_url: '', ads_bottom_link: '' })
const bannerFileList = ref([])

const loadWebSettings = async () => {
  const result = await getSettings()
  if (result && result.success) {
    settingsForm.value = { ...settingsForm.value, ...result.data }
    if (result.data.banner_urls) {
      try {
        const urls = JSON.parse(result.data.banner_urls)
        bannerFileList.value = urls.map((url, idx) => ({ name: `banner-${idx}`, url }))
      } catch (e) {}
    } else if (result.data.banner_url) {
      bannerFileList.value = [{ name: 'banner-0', url: result.data.banner_url }]
    }
    // Emit settings to parent (for AdminOrders print)
    emit('settings-loaded', settingsForm.value)
  }
}

// Nén ảnh bằng HTML5 Canvas nếu dung lượng ảnh > 500KB để tăng tốc độ upload và tránh giới hạn file size của server
const compressImage = (file, { maxWidth = 1920, maxHeight = 1080, quality = 0.82, mimeType = 'image/jpeg' } = {}) => {
  return new Promise((resolve) => {
    if (!file.type.startsWith('image/')) {
      return resolve(file)
    }
    if (file.size < 500 * 1024) {
      return resolve(file) // Giữ nguyên ảnh gốc nếu dưới 500KB
    }

    const reader = new FileReader()
    reader.readAsDataURL(file)
    reader.onload = (event) => {
      const img = new Image()
      img.src = event.target.result
      img.onload = () => {
        let width = img.width
        let height = img.height

        if (width > maxWidth) {
          height = Math.round((height * maxWidth) / width)
          width = maxWidth
        }
        if (height > maxHeight) {
          width = Math.round((width * maxHeight) / height)
          height = maxHeight
        }

        const canvas = document.createElement('canvas')
        canvas.width = width
        canvas.height = height

        const ctx = canvas.getContext('2d')
        if (!ctx) {
          return resolve(file)
        }
        ctx.drawImage(img, 0, 0, width, height)

        canvas.toBlob(
          (blob) => {
            if (!blob) {
              return resolve(file)
            }
            const compressedFile = new File([blob], file.name.substring(0, file.name.lastIndexOf('.')) + '.jpg', {
              type: mimeType,
              lastModified: Date.now()
            })
            resolve(compressedFile)
          },
          mimeType,
          quality
        )
      }
      img.onerror = () => resolve(file)
    }
    reader.onerror = () => resolve(file)
  })
}

const handleLogoUpload = async (file) => {
  const loading = ElMessage({ message: 'Đang xử lý & upload logo...', type: 'info', duration: 0 })
  const optimizedFile = await compressImage(file.raw, { maxWidth: 800, maxHeight: 800, quality: 0.85 })
  const res = await uploadImage(optimizedFile, 'logo')
  loading.close()
  if (res && res.success) {
    settingsForm.value.logo_url = res.url
    ElMessage.success('Upload logo thành công!')
  } else {
    ElMessage.error(res?.message || 'Lỗi upload logo')
  }
}

const handleLeftAdUpload = async (file) => {
  const loading = ElMessage({ message: 'Đang xử lý & upload banner dọc trái...', type: 'info', duration: 0 })
  const optimizedFile = await compressImage(file.raw, { maxWidth: 400, maxHeight: 1200, quality: 0.85 })
  const res = await uploadImage(optimizedFile, 'banner')
  loading.close()
  if (res && res.success) {
    settingsForm.value.ads_left_url = res.url
    ElMessage.success('Upload banner dọc trái thành công!')
  } else {
    ElMessage.error(res?.message || 'Lỗi upload banner dọc trái')
  }
}

const handleRightAdUpload = async (file) => {
  const loading = ElMessage({ message: 'Đang xử lý & upload banner dọc phải...', type: 'info', duration: 0 })
  const optimizedFile = await compressImage(file.raw, { maxWidth: 400, maxHeight: 1200, quality: 0.85 })
  const res = await uploadImage(optimizedFile, 'banner')
  loading.close()
  if (res && res.success) {
    settingsForm.value.ads_right_url = res.url
    ElMessage.success('Upload banner dọc phải thành công!')
  } else {
    ElMessage.error(res?.message || 'Lỗi upload banner dọc phải')
  }
}

const handleBottomAdUpload = async (file) => {
  const loading = ElMessage({ message: 'Đang xử lý & upload banner ngang...', type: 'info', duration: 0 })
  const optimizedFile = await compressImage(file.raw, { maxWidth: 1920, maxHeight: 459, quality: 0.85 })
  const res = await uploadImage(optimizedFile, 'banner')
  loading.close()
  if (res && res.success) {
    settingsForm.value.ads_bottom_url = res.url
    ElMessage.success('Upload banner ngang thành công!')
  } else {
    ElMessage.error(res?.message || 'Lỗi upload banner ngang')
  }
}

const handleBannerChange = async (file, fileList) => {
  const loading = ElMessage({ message: 'Đang xử lý & upload banner...', type: 'info', duration: 0 })
  const optimizedFile = await compressImage(file.raw, { maxWidth: 1920, maxHeight: 1080, quality: 0.82 })
  const res = await uploadImage(optimizedFile, 'banner')
  loading.close()
  if (res && res.success) {
    file.url = res.url
    bannerFileList.value = fileList
    ElMessage.success('Upload banner thành công!')
  } else {
    ElMessage.error(res?.message || 'Lỗi upload banner')
    bannerFileList.value = fileList.filter(f => f.uid !== file.uid)
  }
}

const handleBannerRemove = (file, fileList) => {
  bannerFileList.value = fileList
}

const saveWebSettings = async () => {
  const loading = ElMessage({ message: 'Đang lưu cấu hình...', type: 'info', duration: 0 })
  settingsForm.value.banner_urls = JSON.stringify(bannerFileList.value.map(f => f.url))
  const result = await updateSettings(settingsForm.value)
  loading.close()
  if (result && result.success) {
    ElMessage.success('Lưu cấu hình thành công!')
    await settingsStore.fetchSettings()
    emit('settings-loaded', settingsForm.value)
  } else {
    ElMessage.error('Lỗi khi lưu cấu hình')
  }
}

onMounted(() => {
  loadWebSettings()
})
</script>

<style scoped>
.card-header { display: flex; justify-content: space-between; align-items: center; }
.logo-upload-container { display: flex; flex-direction: column; align-items: flex-start; gap: 12px; }
.logo-preview { max-height: 80px; border: 1px dashed #dcdfe6; border-radius: 4px; padding: 10px; background: #fafafa; }

/* Custom styling for banner uploader to match banner aspect ratio (2.4:1) */
.banner-uploader :deep(.el-upload--picture-card) {
  width: 240px !important;
  height: 100px !important;
  line-height: 100px !important;
}

.banner-uploader :deep(.el-upload-list--picture-card .el-upload-list__item) {
  width: 240px !important;
  height: 100px !important;
}

.banner-uploader :deep(.el-upload-list--picture-card .el-upload-list__item-thumbnail) {
  object-fit: cover !important;
}

.ad-preview-vertical {
  width: 96px;
  height: 240px;
  border: 1px dashed #dcdfe6;
  border-radius: 4px;
  object-fit: cover;
  padding: 5px;
  background: #fafafa;
  margin-bottom: 8px;
}

.ad-preview-horizontal {
  width: 100%;
  max-width: 480px;
  aspect-ratio: 1920 / 459;
  height: auto;
  border: 1px dashed #dcdfe6;
  border-radius: 4px;
  object-fit: cover;
  padding: 5px;
  background: #fafafa;
  margin-bottom: 8px;
}
</style>
