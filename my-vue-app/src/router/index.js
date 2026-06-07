import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '../stores/auth'

const routes = [
  { path: '/', name: 'home', component: () => import('../views/HomeView.vue'), meta: { title: 'Trang chủ - Đèn Hoa Mỹ' } },
  { path: '/category', name: 'category', component: () => import('../views/CategoryView.vue'), meta: { title: 'Danh mục sản phẩm - Đèn Hoa Mỹ' } },
  { path: '/product/:id', name: 'product-detail', component: () => import('../views/ProductDetailView.vue'), meta: { title: 'Chi tiết sản phẩm - Đèn Hoa Mỹ' } },
  { path: '/cart', name: 'cart', component: () => import('../views/CartView.vue'), meta: { title: 'Giỏ hàng - Đèn Hoa Mỹ' } },
  { path: '/checkout', name: 'checkout', component: () => import('../views/CheckoutView.vue'), meta: { title: 'Thanh toán - Đèn Hoa Mỹ', requiresAuth: true } },
  { path: '/login', name: 'login', component: () => import('../views/LoginView.vue'), meta: { title: 'Đăng nhập - Đèn Hoa Mỹ' } },
  { path: '/register', name: 'register', component: () => import('../views/RegisterView.vue'), meta: { title: 'Đăng ký - Đèn Hoa Mỹ' } },
  { path: '/forgot-password', name: 'forgot-password', component: () => import('../views/ForgotPasswordView.vue'), meta: { title: 'Quên mật khẩu - Đèn Hoa Mỹ' } },
  { path: '/reset-password', name: 'reset-password', component: () => import('../views/ResetPasswordView.vue'), meta: { title: 'Đặt lại mật khẩu - Đèn Hoa Mỹ' } },
  { path: '/profile', name: 'profile', component: () => import('../views/ProfileView.vue'), meta: { title: 'Tài khoản - Đèn Hoa Mỹ', requiresAuth: true } },
  { path: '/news', name: 'news', component: () => import('../views/NewsView.vue'), meta: { title: 'Tin tức - Đèn Hoa Mỹ' } },
  { path: '/news/:slug', name: 'news-detail', component: () => import('../views/NewsDetailView.vue'), meta: { title: 'Bài viết - Đèn Hoa Mỹ' } },
  { path: '/policy', name: 'policy', component: () => import('../views/PolicyView.vue'), meta: { title: 'Chính sách - Đèn Hoa Mỹ' } },
  { path: '/payment/success', name: 'payment-success', component: () => import('../views/PaymentResultView.vue'), meta: { title: 'Thanh toán thành công - Đèn Hoa Mỹ' } },
  { path: '/payment/cancel', name: 'payment-cancel', component: () => import('../views/PaymentResultView.vue'), meta: { title: 'Thanh toán chưa hoàn tất - Đèn Hoa Mỹ' } },
  {
    path: '/admin',
    name: 'admin',
    component: () => import('../views/AdminView.vue'),
    meta: { title: 'Quản trị - Đèn Hoa Mỹ', requiresAdmin: true }
  },
  {
    path: '/:pathMatch(.*)*',
    name: 'not-found',
    component: () => import('../views/NotFoundView.vue'),
    meta: { title: 'Không tìm thấy trang - Đèn Hoa Mỹ' }
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes,
  scrollBehavior() {
    return { top: 0 }
  }
})

router.beforeEach((to, from, next) => {
  const authStore = useAuthStore()

  if (to.meta.requiresAdmin) {
    if (!authStore.isLoggedIn || !authStore.canAccessAdmin) {
      next({ name: 'login', query: { redirect: to.fullPath } })
    } else {
      next()
    }
    return
  }

  if (to.meta.requiresAuth && !authStore.isLoggedIn) {
    next({ name: 'login', query: { redirect: to.fullPath } })
    return
  }

  next()
})

router.afterEach((to) => {
  document.title = to.meta.title || 'Đèn Hoa Mỹ - Đèn trang trí cao cấp'
})

export default router
