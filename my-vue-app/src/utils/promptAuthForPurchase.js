import { ElMessageBox } from 'element-plus'
import router from '../router'

/**
 * Kiểm tra đăng nhập trước khi thêm giỏ / mua hàng.
 * Nếu chưa login, hiện dialog với nút Đăng ký / Đăng nhập.
 * @returns {boolean} true nếu đã đăng nhập, false nếu bị chặn
 */
export function ensureAuthForPurchase(authStore, redirectPath) {
  if (authStore.isLoggedIn) return true

  const redirect = redirectPath || router.currentRoute.value.fullPath

  ElMessageBox.confirm(
    'Bạn cần đăng ký tài khoản để mua hàng. Vui lòng đăng ký hoặc đăng nhập để tiếp tục.',
    'Cần tài khoản để mua hàng',
    {
      confirmButtonText: 'Đăng ký',
      cancelButtonText: 'Đăng nhập',
      distinguishCancelAndClose: true,
      type: 'warning',
      center: true,
    }
  )
    .then(() => {
      router.push({ name: 'register', query: { redirect } })
    })
    .catch((action) => {
      if (action === 'cancel') {
        router.push({ name: 'login', query: { redirect } })
      }
    })

  return false
}
