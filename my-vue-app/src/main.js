import { createApp } from 'vue'
import { createPinia } from 'pinia'
import App from './App.vue'
import router from './router'
import ElementPlus from 'element-plus'
import 'element-plus/dist/index.css'
import './style.css'
import { setSessionExpiredHandler } from './utils/sessionExpired'
import { useAuthStore } from './stores/auth'

const app = createApp(App)
const pinia = createPinia()
app.use(pinia)
app.use(ElementPlus)
app.use(router)

setSessionExpiredHandler(() => {
  useAuthStore().handleStorageAuthEvent('logout')
  const path = window.location.pathname || ''
  if (!path.startsWith('/login') && !path.startsWith('/register')) {
    const redirect = path + (window.location.search || '')
    router.push({ name: 'login', query: { redirect } })
  }
})

app.mount('#app')