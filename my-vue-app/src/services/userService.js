import api from './httpClient'
import { failNull, failMessage } from './serviceErrors'

export const getUsers = async () => {
  try {
    const response = await api.get('/users.php?scope=customers')
    return response.data
  } catch (error) {
    return error.response?.data ?? failNull()
  }
}

export const updateUser = async (id, role) => {
  try {
    const response = await api.put('/users.php', { id, role, target: 'customer' })
    return response.data
  } catch (error) {
    return error.response?.data ?? failNull()
  }
}

export const updateProfile = async (userData) => {
  try {
    const response = await api.put('/users.php', { ...userData, target: 'profile' })
    return response.data
  } catch (error) {
    return failMessage('Lỗi máy chủ')
  }
}

export const getAdmins = async () => {
  try {
    const response = await api.get('/users.php?scope=admins')
    return response.data
  } catch (error) {
    return error.response?.data ?? failNull()
  }
}

export const addAdmin = async (data) => {
  try {
    const response = await api.post('/users.php', data)
    return response.data
  } catch (error) {
    return error.response?.data ?? failNull()
  }
}

export const updateAdmin = async (data) => {
  try {
    const response = await api.put('/users.php', { ...data, target: 'admin' })
    return response.data
  } catch (error) {
    return error.response?.data ?? failNull()
  }
}

export const deleteAdmin = async (id) => {
  try {
    const response = await api.delete(`/users.php?id=${id}`)
    return response.data
  } catch (error) {
    return error.response?.data ?? failNull()
  }
}
