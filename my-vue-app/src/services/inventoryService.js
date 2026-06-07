import api from './httpClient'
import { failNull } from './serviceErrors'

export const addInventory = async (data) => {
  try {
    const response = await api.post('/inventory.php', data)
    return response.data
  } catch (error) {
    return failNull()
  }
}
