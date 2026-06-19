<template>
  <div class="login-page">
    <div class="login-card">
      <div class="login-visual">
      </div>

      <div class="login-form-section">
        <div class="form-inner">
          <div class="form-header">
            <h2>Khôi phục mật khẩu</h2>
            <p>Nhập số điện thoại đã đăng ký. Chúng tôi sẽ gửi link đặt lại mật khẩu tới email của bạn.</p>
          </div>

          <el-form :model="resetForm" :rules="rules" ref="formRef" label-position="top" @submit.prevent="handleReset">
            <el-form-item label="Số điện thoại đã đăng ký" prop="phone">
              <el-input v-model="resetForm.phone" placeholder="Nhập số điện thoại..." />
            </el-form-item>

            <el-button class="gold-btn btn-submit" native-type="submit" :loading="submitting">
              GỬI LINK KHÔI PHỤC
            </el-button>

            <div class="form-footer">
              <el-link class="gold-link" :underline="false" @click="router.push('/login')">← Quay lại Đăng nhập</el-link>
            </div>
          </el-form>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessageBox } from 'element-plus'
import { toastError } from '../utils/toast'
import { requestPasswordResetApi } from '../services/authService'

const router = useRouter()
const formRef = ref(null)
const submitting = ref(false)
const resetForm = ref({ phone: '' })

const validatePhone = (rule, value, callback) => {
  if (!/^(0[3|5|7|8|9])+([0-9]{8})\b/.test(value)) {
    callback(new Error('Số điện thoại không hợp lệ'))
  } else {
    callback()
  }
}

const rules = {
  phone: [
    { required: true, message: 'Vui lòng nhập số điện thoại', trigger: 'blur' },
    { validator: validatePhone, trigger: 'blur' }
  ]
}

const handleReset = () => {
  formRef.value?.validate(async (valid) => {
    if (!valid) return
    submitting.value = true
    const res = await requestPasswordResetApi(resetForm.value.phone)
    submitting.value = false

    if (res && res.success) {
      ElMessageBox.alert(
        (res.message || '') + '\n\nKiểm tra email đã đăng ký (kể cả thư rác). Link hết hạn sau 30 phút.',
        'Yêu cầu đã được gửi',
        {
          type: 'success',
          confirmButtonText: 'Đã hiểu',
          callback: () => {
            router.push('/login')
          }
        }
      )
    } else {
      toastError(res?.message || 'Lỗi kết nối')
    }
  })
}
</script>

<style scoped>
.login-page { height: 100vh; width: 100vw; display: flex; align-items: center; justify-content: center; background-color: #f5f7fa; }
.login-card { display: flex; width: 1000px; height: 600px; background: #fff; border-radius: 16px; box-shadow: 0 20px 40px rgba(0,0,0,0.08); overflow: hidden; }

.login-visual {
  flex: 1.2;
  background: linear-gradient(to bottom, transparent 65%, #050403 95%),
              url('../assets/auth-bg.jpg') center top / cover no-repeat;
}

.login-form-section { flex: 1; display: flex; align-items: center; justify-content: center; padding: 40px; }
.form-inner { width: 100%; max-width: 360px; }

.form-header h2 { font-size: 24px; color: #333; margin-bottom: 8px; }
.form-header p { color: #999; margin-bottom: 32px; font-size: 14px; line-height: 1.5; }

.btn-submit { width: 100%; height: 48px; font-size: 16px; font-weight: 600; border-radius: 8px; margin-bottom: 20px; }
.form-footer { text-align: center; font-size: 14px; }

.gold-btn { background-color: #D8B257; color: #fff; border: none; }
.gold-btn:hover { background-color: #c49d45; color: #fff; }
.gold-link:hover { color: #D8B257; }

@media (max-width: 768px) {
  .login-card {
    width: 92%;
    height: auto;
    flex-direction: column;
  }
  .login-visual { display: none; }
  .login-form-section { padding: 30px 20px; }
  .form-inner { max-width: 100%; }
}
</style>
