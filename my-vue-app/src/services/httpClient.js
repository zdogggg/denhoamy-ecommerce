import axios from 'axios'
import { getStoredAuthUser } from '../utils/authStorage'
import { triggerSessionExpired } from '../utils/sessionExpired'

const api = axios.create({
  // Docker production: dùng '/api' (Nginx proxy) | Docker dev proxy hoặc local: 'http://localhost:8080'
  baseURL: import.meta.env.VITE_API_URL || 'http://localhost:8080',
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json',
    Accept: 'application/json'
  }
})

let handlingUnauthorized = false

function handleUnauthorized() {
  if (handlingUnauthorized) return
  handlingUnauthorized = true
  try {
    triggerSessionExpired()
  } finally {
    handlingUnauthorized = false
  }
}

api.interceptors.request.use(
  (config) => {
    if (config.skipAuth) {
      return config
    }
    const user = getStoredAuthUser()
    if (user?.token) {
      config.headers.Authorization = `Bearer ${user.token}`
    }
    return config
  },
  (error) => Promise.reject(error)
)

api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response) {
      const status = error.response.status

      if (status === 401 && !error.config?.skipAuth) {
        handleUnauthorized()
      }

      if (status >= 500) {
        console.error('[API] Lỗi máy chủ:', error.response.data?.message || error.message)
      }
    } else if (error.code === 'ECONNABORTED') {
      console.error('[API] Request timeout - máy chủ phản hồi quá lâu')
    }

    return Promise.reject(error)
  }
)

export default api
