import api from './httpClient'
import { failNull } from './serviceErrors'

export const getReviews = async (product_id = null) => {
  try {
    const url = product_id ? `/reviews.php?product_id=${product_id}` : '/reviews.php'
    const response = await api.get(url)
    return response.data
  } catch (error) {
    return failNull()
  }
}

export const addReview = async (data) => {
  try {
    const response = await api.post('/reviews.php', data)
    return response.data
  } catch (error) {
    return failNull()
  }
}

export const updateReview = async (data) => {
  try {
    const response = await api.put('/reviews.php', data)
    return response.data
  } catch (error) {
    return failNull()
  }
}

export const deleteReview = async (id) => {
  try {
    const response = await api.delete(`/reviews.php?id=${id}`)
    return response.data
  } catch (error) {
    return failNull()
  }
}
