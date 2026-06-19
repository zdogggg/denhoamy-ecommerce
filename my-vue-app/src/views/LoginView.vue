<template>
  <div class="login-page">
    <div class="login-card">
      <div class="login-visual">
      </div>
      <div class="login-form-section">
        <div class="form-inner">
          <div class="form-header">
            <h2>Đăng nhập</h2>
            <p>Vui lòng nhập thông tin tài khoản của bạn</p>
          </div>
          <el-form :model="loginForm" :rules="rules" ref="formRef" label-position="top" @submit.prevent="handleLogin">
            <el-form-item label="Tên đăng nhập / Số điện thoại" prop="username">
              <el-input v-model="loginForm.username" placeholder="Nhập tên đăng nhập hoặc Số điện thoại của bạn..." />
            </el-form-item>
            <el-form-item label="Mật khẩu" prop="password">
              <el-input v-model="loginForm.password" type="password" show-password placeholder="Nhập mật khẩu" />
            </el-form-item>
            <div class="form-utils">
              <el-checkbox v-model="loginForm.remember">Ghi nhớ đăng nhập</el-checkbox>
              <div class="forgot-wrap">
                <el-link class="gold-link" :underline="false" @click="router.push('/forgot-password')">Quên mật khẩu?</el-link>
                <p class="forgot-hint">Dành cho tài khoản khách hàng. Nhân viên liên hệ quản trị viên.</p>
              </div>
            </div>

            <el-button class="gold-btn btn-submit" native-type="submit">ĐĂNG NHẬP</el-button>

            <div class="form-footer">
              <span>Chưa có tài khoản? </span>
              <el-link class="gold-link" :underline="false" @click="router.push('/register')">Đăng ký ngay</el-link>
            </div>
            <div class="form-footer-home">
              <el-link type="info" :underline="false" @click="router.push('/')">← Quay lại Trang chủ</el-link>
            </div>
          </el-form>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { toastSuccess, toastError } from '../utils/toast'
import { useAuthStore } from '../stores/auth'

const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()
const formRef = ref(null)

const loginForm = ref({ username: '', password: '', remember: localStorage.getItem('auth_remember') === '1' })

const rules = {
  username: [{ required: true, message: 'Vui lòng nhập Tên đăng nhập hoặc Số điện thoại', trigger: 'blur' }],
  password: [{ required: true, message: 'Vui lòng nhập mật khẩu', trigger: 'blur' }]
}

onMounted(() => {
  if (authStore.isLoggedIn) {
    const redirect = route.query.redirect
    if (typeof redirect === 'string' && redirect.startsWith('/')) {
      router.replace(redirect)
    } else if (authStore.canAccessAdmin) {
      router.replace('/admin')
    } else {
      router.replace('/')
    }
  }
})

const handleLogin = () => {
  formRef.value?.validate(async (valid) => {
    if (!valid) return
    const result = await authStore.login(
      loginForm.value.username,
      loginForm.value.password,
      loginForm.value.remember
    )
    if (result.success) {
      toastSuccess(`Chào ${result.user.name}!`)
      const redirect = route.query.redirect
      if (typeof redirect === 'string' && redirect.startsWith('/')) {
        router.push(redirect)
      } else if (result.user.role === 'admin' || result.user.role === 'staff') {
        router.push('/admin')
      } else {
        router.push('/')
      }
    } else {
      toastError(result.message)
    }
  })
}
</script>

<style scoped>
.login-page { height: 100vh; width: 100vw; display: flex; align-items: center; justify-content: center; background-color: #f5f7fa; }

.login-card { display: flex; width: 1000px; height: 600px; background: #fff; border-radius: 16px; box-shadow: 0 20px 40px rgba(0, 0, 0, 0.08); overflow: hidden; }

.login-visual {
  flex: 1.2;
  background: linear-gradient(to bottom, transparent 65%, #050403 95%),
              url('../assets/auth-bg.jpg') center top / cover no-repeat;
}

.login-form-section { flex: 1; display: flex; align-items: center; justify-content: center; padding: 40px; }
.form-inner { width: 100%; max-width: 360px; }

.form-header h2 { font-size: 24px; color: #333; margin-bottom: 8px; }
.form-header p { color: #999; margin-bottom: 32px; font-size: 14px; }

.form-utils { display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 24px; gap: 12px; }
.forgot-wrap { text-align: right; }
.forgot-hint { margin: 4px 0 0; font-size: 11px; color: #aaa; line-height: 1.3; max-width: 180px; }

.btn-submit { width: 100%; height: 48px; font-size: 16px; font-weight: 600; border-radius: 8px; margin-bottom: 15px; }

.form-footer { display: flex; justify-content: center; align-items: center; gap: 4px; font-size: 14px; margin-top: 8px; color: #666; }
.form-footer-home { display: flex; justify-content: center; margin-top: 20px; font-size: 13px; }

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
