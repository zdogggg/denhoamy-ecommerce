import api from './httpClient'
import { failFalse } from './serviceErrors'

export const getCategories = async () => {
  try {
    const response = await api.get('/categories.php')
    return response.data
  } catch (error) {
    console.error('Lỗi tải danh mục:', error)
    return { success: false, data: [] }
  }
}

export const addCategory = async (data) => {
  try {
    const response = await api.post('/categories.php', data)
    return response.data
  } catch (error) {
    console.error('Lỗi tạo danh mục:', error)
    return failFalse()
  }
}

export const updateCategory = async (data) => {
  try {
    const response = await api.put('/categories.php', data)
    return response.data
  } catch (error) {
    console.error('Lỗi cập nhật danh mục:', error)
    return failFalse()
  }
}

export const deleteCategory = async (id) => {
  try {
    const response = await api.delete(`/categories.php?id=${id}`)
    return response.data
  } catch (error) {
    console.error('Lỗi xoá danh mục:', error)
    return failFalse()
  }
}
