<template>
  <div class="login-page">
    <div class="login-card">
      <div class="login-visual">
      </div>

      <div class="login-form-section">
        <div class="form-inner">
          <div class="form-header">
            <h2>Đặt lại mật khẩu</h2>
            <p v-if="hasToken">Nhập mật khẩu mới cho tài khoản của bạn.</p>
            <p v-else class="error-text">Link không hợp lệ. Vui lòng yêu cầu link mới từ trang quên mật khẩu.</p>
          </div>

          <el-form v-if="hasToken" :model="form" :rules="rules" ref="formRef" label-position="top" @submit.prevent="handleSubmit">
            <el-form-item label="Mật khẩu mới" prop="password">
              <el-input v-model="form.password" type="password" show-password placeholder="Tối thiểu 6 ký tự" />
            </el-form-item>
            <el-form-item label="Xác nhận mật khẩu" prop="confirmPassword">
              <el-input v-model="form.confirmPassword" type="password" show-password placeholder="Nhập lại mật khẩu" />
            </el-form-item>

            <el-button class="gold-btn btn-submit" native-type="submit" :loading="submitting">
              ĐẶT LẠI MẬT KHẨU
            </el-button>

            <div class="form-footer">
              <el-link class="gold-link" :underline="false" @click="router.push('/login')">← Quay lại Đăng nhập</el-link>
            </div>
          </el-form>

          <div v-else class="form-footer">
            <el-button class="gold-btn btn-submit" @click="router.push('/forgot-password')">
              Yêu cầu link mới
            </el-button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { toastSuccess, toastError } from '../utils/toast'
import { resetPasswordApi } from '../services/authService'

const route = useRoute()
const router = useRouter()
const formRef = ref(null)
const submitting = ref(false)

const token = computed(() => (route.query.token || '').toString().trim())
const hasToken = computed(() => token.value.length === 64)

const form = ref({ password: '', confirmPassword: '' })

const validateConfirmPassword = (rule, value, callback) => {
  if (value !== form.value.password) {
    callback(new Error('Mật khẩu xác nhận không khớp!'))
  } else {
    callback()
  }
}

const rules = {
  password: [
    { required: true, message: 'Vui lòng nhập mật khẩu', trigger: 'blur' },
    { min: 6, message: 'Mật khẩu tối thiểu 6 ký tự', trigger: 'blur' }
  ],
  confirmPassword: [
    { required: true, message: 'Vui lòng xác nhận mật khẩu', trigger: 'blur' },
    { validator: validateConfirmPassword, trigger: 'blur' }
  ]
}

const handleSubmit = () => {
  formRef.value?.validate(async (valid) => {
    if (!valid || !hasToken.value) return
    submitting.value = true
    const res = await resetPasswordApi(token.value, form.value.password, form.value.confirmPassword)
    submitting.value = false

    if (res && res.success) {
      toastSuccess(res.message || 'Đặt lại mật khẩu thành công!')
      router.push('/login')
    } else {
      toastError(res?.message || 'Link không hợp lệ hoặc đã hết hạn.')
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
.error-text { color: #f56c6c !important; }

.btn-submit { width: 100%; height: 48px; font-size: 16px; font-weight: 600; border-radius: 8px; margin-bottom: 20px; }
.form-footer { text-align: center; font-size: 14px; }

.gold-btn { background-color: #D8B257; color: #fff; border: none; }
.gold-btn:hover { background-color: #c49d45; color: #fff; }
.gold-link:hover { color: #D8B257; }

@media (max-width: 768px) {
  .login-card { width: 92%; height: auto; flex-direction: column; }
  .login-visual { display: none; }
  .login-form-section { padding: 30px 20px; }
}
</style>
