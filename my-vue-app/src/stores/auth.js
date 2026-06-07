import { defineStore } from 'pinia'
import { ref, computed, watch } from 'vue'
import { loginApi, registerApi } from '../services/authService'
import { getAuthStorage, clearStoredAuth, broadcastAuthEvent } from '../utils/authStorage'

const REMEMBER_KEY = 'auth_remember'
const USER_KEY = 'auth_user'

function loadSavedUser() {
  const storage = getAuthStorage()
  const saved = storage.getItem(USER_KEY)
  if (!saved) return null
  try {
    return JSON.parse(saved)
  } catch {
    storage.removeItem(USER_KEY)
    return null
  }
}

export const useAuthStore = defineStore('auth', () => {
  const user = ref(loadSavedUser())

  const isLoggedIn = computed(() => !!user.value)
  const isAdmin = computed(() => user.value?.role === 'admin')
  const isStaff = computed(() => user.value?.role === 'staff')
  const canAccessAdmin = computed(() => isAdmin.value || isStaff.value)

  const hasPermission = (permKey) => {
    if (!user.value) return false
    if (user.value.role === 'admin') return true
    if (user.value.role === 'staff') {
      return user.value.permissions?.[permKey] === true
    }
    return false
  }

  watch(user, (newVal) => {
    const storage = getAuthStorage()
    if (newVal) {
      storage.setItem(USER_KEY, JSON.stringify(newVal))
    } else {
      clearStoredAuth()
    }
  }, { deep: true })

  const login = async (username, password, remember = false) => {
    const result = await loginApi(username, password)
    if (result.success) {
      const userData = { ...result.user }
      if (result.token) {
        userData.token = result.token
      }

      if (remember) {
        localStorage.setItem(REMEMBER_KEY, '1')
        sessionStorage.removeItem(USER_KEY)
      } else {
        localStorage.setItem(REMEMBER_KEY, '0')
        localStorage.removeItem(USER_KEY)
      }

      getAuthStorage().setItem(USER_KEY, JSON.stringify(userData))
      user.value = userData
      broadcastAuthEvent('login')

      if (userData.role === 'customer') {
        const { useCartStore } = await import('./cart')
        await useCartStore().mergeAfterLogin()
      }

      return { success: true, user: userData }
    }
    return { success: false, message: result.message || 'Đăng nhập thất bại' }
  }

  const register = async (name, phone, email, password) => {
    const result = await registerApi(name, phone, email, password)
    return result
  }

  const logout = ({ broadcast = true } = {}) => {
    user.value = null
    clearStoredAuth()
    if (broadcast) {
      broadcastAuthEvent('logout')
    }
  }

  const handleStorageAuthEvent = (type) => {
    if (type === 'logout') {
      logout({ broadcast: false })
    } else if (type === 'login') {
      user.value = loadSavedUser()
    }
  }

  return { user, isLoggedIn, isAdmin, isStaff, canAccessAdmin, hasPermission, login, register, logout, handleStorageAuthEvent }
})
