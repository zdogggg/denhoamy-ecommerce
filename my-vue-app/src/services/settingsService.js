import api from './httpClient'
import { failNull } from './serviceErrors'

export const getSettings = async () => {
  try {
    const response = await api.get('/settings.php')
    return response.data
  } catch (error) {
    return failNull()
  }
}

export const updateSettings = async (data) => {
  try {
    const response = await api.put('/settings.php', data)
    return response.data
  } catch (error) {
    return failNull()
  }
}
