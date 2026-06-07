import api from './httpClient'
import { failMessage } from './serviceErrors'

export const uploadImage = async (file, type = 'product') => {
  try {
    const formData = new FormData()
    formData.append('file', file)
    const response = await api.post(`/upload.php?type=${type}`, formData, {
      headers: { 'Content-Type': 'multipart/form-data' },
      timeout: 30000
    })
    return response.data
  } catch (error) {
    if (error.response) {
      console.error('[uploadImage] HTTP Status:', error.response.status)
      console.error('[uploadImage] Server response:', JSON.stringify(error.response.data))
    } else {
      console.error('[uploadImage] Network/timeout error:', error.message)
    }
    return failMessage(error.response?.data?.message || 'Lỗi upload ảnh')
  }
}

export const uploadBase64Image = async (base64, type = 'product') => {
  try {
    const response = await api.post(`/upload.php?type=${type}`, { base64 }, {
      timeout: 30000
    })
    return response.data
  } catch (error) {
    console.error('Lỗi upload base64:', error)
    return failMessage('Lỗi upload ảnh')
  }
}

export const uploadMultipleBase64 = async (images, type = 'gallery') => {
  try {
    const response = await api.post(`/upload.php?type=${type}`, { images }, {
      timeout: 60000
    })
    return response.data
  } catch (error) {
    console.error('Lỗi upload nhiều ảnh:', error)
    return failMessage('Lỗi upload ảnh')
  }
}
