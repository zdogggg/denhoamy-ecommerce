<template>
  <div class="login-page">
    <div class="login-card">
      <div class="login-visual">
      </div>

      <div class="login-form-section">
        <div class="form-inner">
          <div class="form-header">
            <h2>Đăng ký tài khoản</h2>
            <p>Vui lòng điền thông tin cá nhân</p>
          </div>

          <el-form :model="regForm" :rules="rules" ref="formRef" label-position="top" @submit.prevent="handleRegister">
            <el-form-item label="Họ và tên" prop="name">
              <el-input v-model="regForm.name" placeholder="VD: Trần Minh Hiếu" />
            </el-form-item>
            <el-form-item label="Số điện thoại" prop="phone">
              <el-input v-model="regForm.phone" placeholder="Nhập số điện thoại..." />
            </el-form-item>
            <el-form-item label="Email" prop="email">
              <el-input v-model="regForm.email" placeholder="example@gmail.com" />
            </el-form-item>
            <el-form-item label="Mật khẩu" prop="password">
              <el-input v-model="regForm.password" type="password" show-password placeholder="Tối thiểu 6 ký tự" />
            </el-form-item>
            <el-form-item label="Xác nhận mật khẩu" prop="confirmPassword">
              <el-input v-model="regForm.confirmPassword" type="password" show-password placeholder="Nhập lại mật khẩu" />
            </el-form-item>
            <el-form-item prop="agreeTerms" style="margin-bottom: 25px;">
              <el-checkbox v-model="regForm.agreeTerms">Tôi đồng ý với các điều khoản và chính sách bảo mật</el-checkbox>
            </el-form-item>

            <el-button class="gold-btn btn-submit" native-type="submit" :disabled="!regForm.agreeTerms">TẠO TÀI KHOẢN</el-button>

            <div class="form-footer">
              <span>Đã có tài khoản? </span>
              <el-link class="gold-link" :underline="false" @click="router.push('/login')">Đăng nhập ngay</el-link>
            </div>
          </el-form>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { toastSuccess, toastError } from '../utils/toast'
import { useAuthStore } from '../stores/auth'

const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()
const formRef = ref(null)
const regForm = ref({ name: '', phone: '', email: '', password: '', confirmPassword: '', agreeTerms: false })

const validatePhone = (rule, value, callback) => {
  if (!/^(0[3|5|7|8|9])+([0-9]{8})\b/.test(value)) {
    callback(new Error('Số điện thoại không hợp lệ'))
  } else {
    callback()
  }
}

const validateConfirmPassword = (rule, value, callback) => {
  if (value !== regForm.value.password) {
    callback(new Error('Mật khẩu xác nhận không khớp!'))
  } else {
    callback()
  }
}

const validateAgreeTerms = (rule, value, callback) => {
  if (!value) {
    callback(new Error('Bạn phải đồng ý với các điều khoản'))
  } else {
    callback()
  }
}

const validateEmail = (rule, value, callback) => {
  if (value && !/^[\w.-]+@[\w.-]+\.\w+$/.test(value)) {
    callback(new Error('Email không hợp lệ'))
  } else {
    callback()
  }
}

const rules = {
  name: [
    { required: true, message: 'Vui lòng nhập họ tên', trigger: 'blur' },
    { min: 2, message: 'Họ tên tối thiểu 2 ký tự', trigger: 'blur' }
  ],
  phone: [
    { required: true, message: 'Vui lòng nhập số điện thoại', trigger: 'blur' },
    { validator: validatePhone, trigger: 'blur' }
  ],
  email: [
    { required: true, message: 'Vui lòng nhập Email', trigger: 'blur' },
    { validator: validateEmail, trigger: 'blur' }
  ],
  password: [
    { required: true, message: 'Vui lòng nhập mật khẩu', trigger: 'blur' },
    { min: 6, message: 'Mật khẩu tối thiểu 6 ký tự', trigger: 'blur' }
  ],
  confirmPassword: [
    { required: true, message: 'Vui lòng xác nhận mật khẩu', trigger: 'blur' },
    { validator: validateConfirmPassword, trigger: 'blur' }
  ],
  agreeTerms: [
    { validator: validateAgreeTerms, trigger: 'change' }
  ]
}

const handleRegister = () => {
  formRef.value?.validate(async (valid) => {
    if (!valid) return
    const result = await authStore.register(regForm.value.name, regForm.value.phone, regForm.value.email, regForm.value.password)
    if (result.success) {
      toastSuccess('Đăng ký thành công! Chuyển tới đăng nhập...')
      router.push({
        name: 'login',
        query: route.query.redirect ? { redirect: route.query.redirect } : {},
      })
    } else {
      toastError(result.message || 'Đăng ký thất bại')
    }
  })
}
</script>

<style scoped>
.login-page { min-height: 100vh; width: 100vw; display: flex; align-items: center; justify-content: center; background-color: #f5f7fa; padding: 40px 0; }

.login-card { display: flex; width: 1000px; min-height: 700px; background: #fff; border-radius: 16px; box-shadow: 0 20px 40px rgba(0,0,0,0.08); overflow: hidden; }

.login-visual {
  flex: 1.2;
  background: linear-gradient(to bottom, transparent 65%, #050403 95%),
              url('../assets/auth-bg.jpg') center top / cover no-repeat;
}

.login-form-section { flex: 1; display: flex; align-items: center; justify-content: center; padding: 40px; }
.form-inner { width: 100%; max-width: 360px; }

.form-header h2 { font-size: 24px; color: #333; margin-bottom: 8px; }
.form-header p { color: #999; margin-bottom: 32px; font-size: 14px; }

.btn-submit { width: 100%; height: 48px; font-size: 16px; font-weight: 600; border-radius: 8px; margin-bottom: 15px; }

.form-footer { display: flex; justify-content: center; align-items: center; gap: 5px; font-size: 14px; color: #666; }

.gold-btn { background-color: #D8B257; color: #fff; border: none; }
.gold-btn:hover { background-color: #c49d45; color: #fff; }
.gold-link:hover { color: #D8B257; }

@media (max-width: 768px) {
  .login-card {
    width: 92%;
    min-height: unset;
    flex-direction: column;
  }
  .login-visual { display: none; }
  .login-form-section { padding: 30px 20px; }
  .form-inner { max-width: 100%; }
}
</style>
