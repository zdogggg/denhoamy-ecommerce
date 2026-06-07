import api from './httpClient'
import { failFalse } from './serviceErrors'

export const getNews = async (isAdmin = false) => {
  try {
    const response = await api.get(`/news.php${isAdmin ? '?admin=1' : ''}`)
    return response.data
  } catch (error) {
    console.error('Lỗi lấy danh sách tin tức:', error)
    return failFalse()
  }
}

export const getNewsDetail = async (slug, isAdmin = false) => {
  try {
    const response = await api.get(`/news.php?slug=${encodeURIComponent(slug)}${isAdmin ? '&admin=1' : ''}`)
    return response.data
  } catch (error) {
    console.error('Lỗi lấy chi tiết tin tức:', error)
    return failFalse()
  }
}

export const addNews = async (newsData) => {
  try {
    const response = await api.post('/news.php', newsData)
    return response.data
  } catch (error) {
    console.error('Lỗi thêm tin tức:', error)
    return failFalse()
  }
}

export const updateNews = async (newsData) => {
  try {
    const response = await api.put('/news.php', newsData)
    return response.data
  } catch (error) {
    console.error('Lỗi cập nhật tin tức:', error)
    return failFalse()
  }
}

export const deleteNews = async (id) => {
  try {
    const response = await api.delete(`/news.php?id=${id}`)
    return response.data
  } catch (error) {
    console.error('Lỗi xóa tin tức:', error)
    return failFalse()
  }
}
