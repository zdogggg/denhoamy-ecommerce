import api from './httpClient'
import { failMessage } from './serviceErrors'

export const loginApi = async (username, password) => {
  try {
    const response = await api.post('/auth.php', { action: 'login', username, password })
    return response.data
  } catch (error) {
    return failMessage('Lỗi máy chủ')
  }
}

export const registerApi = async (name, phone, email, password) => {
  try {
    const response = await api.post('/auth.php', { action: 'register', name, phone, email, password })
    return response.data
  } catch (error) {
    return failMessage('Lỗi máy chủ')
  }
}

/** Yêu cầu gửi magic link reset mật khẩu (theo SĐT đã đăng ký) */
export const requestPasswordResetApi = async (phone) => {
  try {
    const response = await api.post('/forgot-password.php', { action: 'request', phone })
    return response.data
  } catch (error) {
    return failMessage('Lỗi máy chủ')
  }
}

/** Đặt lại mật khẩu bằng token từ email */
export const resetPasswordApi = async (token, password, confirmPassword) => {
  try {
    const response = await api.post('/forgot-password.php', {
      action: 'reset',
      token,
      password,
      confirmPassword
    })
    return response.data
  } catch (error) {
    return failMessage('Lỗi máy chủ')
  }
}

/** Admin/staff đổi mật khẩu tài khoản đang đăng nhập */
export const changeAdminPasswordApi = async (currentPassword, newPassword) => {
  try {
    const response = await api.post('/auth.php', {
      action: 'change_password',
      current_password: currentPassword,
      new_password: newPassword,
    })
    return response.data
  } catch (error) {
    return error.response?.data ?? failMessage('Lỗi máy chủ')
  }
}