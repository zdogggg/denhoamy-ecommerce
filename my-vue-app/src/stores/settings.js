import { defineStore } from 'pinia'
import { getSettings } from '../services/settingsService'

export const useSettingsStore = defineStore('settings', {
  state: () => ({
    sys_shop_name: 'ĐÈN HOA MỸ',
    sys_logo_url: '',
    banner_list: [
      'https://images.unsplash.com/photo-1565814329452-e1efa11c5e89?q=80&w=800',
      'https://images.unsplash.com/photo-1540932239986-30128078f3c5?q=80&w=800',
      'https://images.unsplash.com/photo-1513506003901-1e6a229e2d15?q=80&w=800'
    ],
    sys_hotline: '0978.897.579 - 0225.653.3618',
    sys_email: 'denhoamy@gmail.com',
    sys_address: 'Hải Phòng, Việt Nam',
    sys_banner_right: 'https://images.unsplash.com/photo-1540932239986-30128078f3c5?q=80&w=400',
    sys_ads_left_url: '/uploads/banners/skyscraper_left.png',
    sys_ads_left_link: '/category?type=Đèn thả',
    sys_ads_right_url: '/uploads/banners/skyscraper_right.png',
    sys_ads_right_link: '/',
    sys_ads_bottom_url: '',
    sys_ads_bottom_link: '',
    sys_raw_data: null
  }),
  actions: {
    async fetchSettings() {
      const res = await getSettings()
      if (res && res.success && res.data) {
        this.sys_raw_data = res.data
        if (res.data.shop_name) this.sys_shop_name = res.data.shop_name
        if (res.data.logo_url) this.sys_logo_url = res.data.logo_url
        if (res.data.banner_urls) {
          try {
            const arr = JSON.parse(res.data.banner_urls)
            if (arr.length > 0) this.banner_list = arr
          } catch (e) { }
        } else if (res.data.banner_url) {
          this.banner_list = [res.data.banner_url]
        }
        if (res.data.hotline) this.sys_hotline = res.data.hotline
        if (res.data.email) this.sys_email = res.data.email
        if (res.data.address) this.sys_address = res.data.address
        if (res.data.banner_right) this.sys_banner_right = res.data.banner_right

        // Cấu hình ads left / right
        if (res.data.ads_left_url) this.sys_ads_left_url = res.data.ads_left_url
        if (res.data.ads_left_link) this.sys_ads_left_link = res.data.ads_left_link
        if (res.data.ads_right_url) this.sys_ads_right_url = res.data.ads_right_url
        if (res.data.ads_right_link) this.sys_ads_right_link = res.data.ads_right_link
        if (res.data.ads_bottom_url) this.sys_ads_bottom_url = res.data.ads_bottom_url
        if (res.data.ads_bottom_link) this.sys_ads_bottom_link = res.data.ads_bottom_link
      }
    }
  }
})
