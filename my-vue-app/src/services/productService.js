import api from './httpClient'
import { failNull, failFalse, failMessage } from './serviceErrors'

export const getProducts = async (params = {}) => {
  try {
    const response = await api.get('/products.php', { params })
    return response.data
  } catch (error) {
    console.error('Lỗi khi kéo dữ liệu sản phẩm:', error)
    return failNull()
  }
}

/** Giá trị lọc (chất liệu, phong cách, không gian) theo danh mục / tìm kiếm */
export const getProductFilterFacets = async (params = {}) => {
  try {
    const response = await api.get('/products.php', { params: { ...params, facets: 1 } })
    return response.data
  } catch (error) {
    console.error('Lỗi khi lấy bộ lọc sản phẩm:', error)
    return failNull()
  }
}

export const getHotDealProducts = async () => {
  try {
    const response = await api.get('/products.php?hot_deal=1')
    return response.data
  } catch (error) {
    console.error('Lỗi khi lấy Hot Deal:', error)
    return failNull()
  }
}

export const toggleHotDeal = async (id, isHotDeal) => {
  try {
    const response = await api.put('/products.php', { action: 'toggle_hot_deal', id, is_hot_deal: isHotDeal })
    return response.data
  } catch (error) {
    return failFalse()
  }
}

export { resolveSalePrice } from '../utils/productPrice'

export const getProductById = async (id) => {
  try {
    const response = await api.get('/products.php', { params: { id } })
    return response.data
  } catch (error) {
    console.error('Lỗi khi kéo chi tiết sản phẩm:', error)
    return failNull()
  }
}

/** Sản phẩm cùng danh mục, loại trừ ID hiện tại */
export const getRelatedProducts = async (productId, categoryType, limit = 4) => {
  if (!categoryType) return failNull()
  try {
    const response = await api.get('/products.php', {
      params: {
        type: categoryType,
        exclude_id: productId,
        limit,
        page: 1,
        sort: 'new'
      }
    })
    return response.data
  } catch (error) {
    console.error('Lỗi khi lấy sản phẩm liên quan:', error)
    return failNull()
  }
}

export const getAdminProducts = async () => {
  try {
    const response = await api.get('/products.php', { params: { sort: 'oldest' } })
    return response.data
  } catch (error) {
    return failFalse()
  }
}

export const addProduct = async (productData) => {
  try {
    const payload = {
      ten_san_pham: productData.name,
      ma_san_pham: productData.id || ('SP' + Date.now()),
      loai_den: productData.category,
      price: productData.price,
      old_price: productData.old_price ?? 0,
      cost_price: productData.cost_price ?? 0,
      image_url: productData.image,
      phong_cach: productData.phong_cach,
      khong_gian_lap_dat: productData.khong_gian_lap_dat,
      bong_den: productData.bong_den,
      chat_lieu: productData.chat_lieu,
      kich_thuoc: productData.kich_thuoc,
      tuoi_tho: productData.tuoi_tho,
      dien_ap: productData.dien_ap,
      tinh_trang: productData.tinh_trang || 'Mới 100%',
      stock: productData.stock || 15,
      description: productData.description || '',
      gallery: productData.gallery || [],
      variants: productData.variants || []
    }
    const response = await api.post('/products.php', payload)
    return response.data
  } catch (error) {
    return failFalse()
  }
}

export const importProducts = async (productsArray) => {
  try {
    const response = await api.post('/products.php?action=import', productsArray)
    return response.data
  } catch (error) {
    console.error('Lỗi import products:', error)
    return failMessage('Lỗi máy chủ')
  }
}

export const updateProduct = async (productData) => {
  try {
    const payload = {
      id: productData.db_id,
      ten_san_pham: productData.name,
      ma_san_pham: productData.id,
      loai_den: productData.category,
      price: productData.price,
      old_price: productData.old_price ?? 0,
      cost_price: productData.cost_price ?? 0,
      image_url: productData.image,
      phong_cach: productData.phong_cach,
      khong_gian_lap_dat: productData.khong_gian_lap_dat,
      bong_den: productData.bong_den,
      chat_lieu: productData.chat_lieu,
      kich_thuoc: productData.kich_thuoc,
      tuoi_tho: productData.tuoi_tho,
      dien_ap: productData.dien_ap,
      tinh_trang: productData.tinh_trang || 'Mới 100%',
      stock: productData.stock || 0,
      description: productData.description || '',
      gallery: productData.gallery || [],
      variants: productData.variants || []
    }
    const response = await api.put('/products.php', payload)
    return response.data
  } catch (error) {
    return failFalse()
  }
}

export const deleteProduct = async (id) => {
  try {
    const response = await api.delete(`/products.php?id=${id}`)
    return response.data
  } catch (error) {
    return failFalse()
  }
}

export const deleteBatchProducts = async (ids) => {
  try {
    const response = await api.delete(`/products.php?ids=${ids.join(',')}`)
    return response.data
  } catch (error) {
    return failFalse()
  }
}

export const clearAllProducts = async () => {
  try {
    const response = await api.delete('/products.php?action=clear_all')
    return response.data
  } catch (error) {
    return failFalse()
  }
}
