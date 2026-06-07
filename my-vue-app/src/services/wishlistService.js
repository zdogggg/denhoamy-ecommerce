import api from './httpClient'
import { failFalse } from './serviceErrors'

/** JWT xác định user — không gửi user_id từ client */
export const getWishlist = async () => {
  try {
    const response = await api.get('/wishlist.php')
    return response.data
  } catch (error) {
    console.error('Lỗi lấy danh sách yêu thích:', error)
    return failFalse()
  }
}

export const toggleWishlist = async (productId) => {
  try {
    const response = await api.post('/wishlist.php', { product_id: productId })
    return response.data
  } catch (error) {
    console.error('Lỗi toggle yêu thích:', error)
    return failFalse()
  }
}
