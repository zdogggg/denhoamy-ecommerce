/**
 * Utility: Toast Notification thống nhất
 * Bọc (wrap) ElMessage để đảm bảo:
 * - Tất cả thông báo trong app dùng chung style
 * - Dễ thay thế thư viện UI sau này (chỉ sửa 1 file)
 * - Tự động grouping, duration, icon nhất quán
 */
import { ElMessage } from 'element-plus'

const DEFAULT_DURATION = 3000

/**
 * Hiện thông báo thành công (Thêm giỏ hàng, đặt hàng, đăng nhập...)
 */
export const toastSuccess = (msg) => {
    ElMessage({
        message: msg,
        type: 'success',
        duration: DEFAULT_DURATION,
        grouping: true,
        showClose: true
    })
}

/**
 * Hiện thông báo lỗi (API thất bại, validate sai...)
 */
export const toastError = (msg) => {
    ElMessage({
        message: msg,
        type: 'error',
        duration: DEFAULT_DURATION + 1000,
        grouping: true,
        showClose: true
    })
}

/**
 * Hiện thông báo cảnh báo (Hết hàng, vượt tồn kho...)
 */
export const toastWarning = (msg) => {
    ElMessage({
        message: msg,
        type: 'warning',
        duration: DEFAULT_DURATION,
        grouping: true,
        showClose: true
    })
}

/**
 * Hiện thông báo thông tin (Bỏ yêu thích, hủy coupon...)
 */
export const toastInfo = (msg) => {
    ElMessage({
        message: msg,
        type: 'info',
        duration: DEFAULT_DURATION,
        grouping: true,
        showClose: true
    })
}
