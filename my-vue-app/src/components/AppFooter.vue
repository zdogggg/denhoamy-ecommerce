<template>
  <footer class="site-footer">
    <div class="container footer-inner">
      <div class="footer-grid">
        <div class="footer-col">
          <img v-if="settingsStore.sys_logo_url" :src="settingsStore.sys_logo_url" style="height: 50px; margin-bottom: 15px; border-radius: 4px; display: block;" />
          <h3 v-else class="footer-logo">{{ settingsStore.sys_shop_name }}</h3>
          <p class="footer-tagline">Thế Giới Đèn Nghệ Thuật</p>
          <p class="footer-desc">Chuyên cung cấp đèn trang trí cao cấp, nội thất và thiết bị vệ sinh cho mọi không gian.</p>
        </div>
        <div class="footer-col">
          <h4>Liên hệ</h4>
          <ul>
            <li><el-icon><Phone /></el-icon> {{ settingsStore.sys_hotline }}</li>
            <li><el-icon><Message /></el-icon> {{ settingsStore.sys_email }}</li>
            <li><el-icon><Location /></el-icon> {{ settingsStore.sys_address }}</li>
          </ul>
        </div>
        <div class="footer-col">
          <h4>Chính sách</h4>
          <ul>
            <li><router-link to="/policy?type=bao-hanh">Chính sách bảo hành</router-link></li>
            <li><router-link to="/policy?type=doi-tra">Chính sách đổi trả</router-link></li>
            <li><router-link to="/policy?type=van-chuyen">Chính sách vận chuyển</router-link></li>
            <li><router-link to="/policy?type=huong-dan">Hướng dẫn mua hàng</router-link></li>
          </ul>
        </div>
        <div class="footer-col">
          <h4>Kết nối</h4>
          <div class="social-links">
            <a href="https://facebook.com/denhoamy" target="_blank" class="social-link">Facebook</a>
            <a href="https://zalo.me/0978897579" target="_blank" class="social-link">Zalo</a>
            <a href="https://youtube.com" target="_blank" class="social-link">YouTube</a>
          </div>
        </div>
      </div>
      <div class="footer-bottom">
        <p>© 2026 Đèn Hoa Mỹ. All rights reserved.</p>
      </div>
    </div>
  </footer>
</template>

<script setup>
import { Phone, Message, Location } from '@element-plus/icons-vue'
import { useSettingsStore } from '../stores/settings'

const settingsStore = useSettingsStore()
</script>

<style scoped>
/* --- 1. Tổng thế Footer (Nền tối) --- */
.site-footer { background-color: #000; color: #ccc; padding: 50px 0 0; margin-top: 50px; }
.container { width: 1200px; margin: 0 auto; max-width: 100%; padding: 0 20px; box-sizing: border-box; }

/* --- 2. Bố cục lưới (Grid) 4 cột --- */
.footer-grid { display: grid; grid-template-columns: 1.5fr 1fr 1fr 1fr; gap: 40px; }

/* --- 3. Định dạng tiêu đề cột và logo --- */
.footer-logo { color: #D8B257; font-size: 24px; font-family: 'Montserrat', sans-serif; margin: 0 0 5px; letter-spacing: 2px; }
.footer-tagline { color: #D8B257; font-size: 12px; margin: 0 0 15px; letter-spacing: 1px; }
.footer-desc { font-size: 13px; line-height: 1.7; color: #999; }

.footer-col h4 { color: #D8B257; font-size: 16px; margin: 0 0 20px; position: relative; padding-bottom: 10px; font-weight: normal;}
.footer-col h4::after { content: ''; position: absolute; bottom: 0; left: 0; width: 40px; height: 2px; background-color: #D8B257; }

/* --- 4. Danh sách link và icon thông tin --- */
.footer-col ul { list-style: none; padding: 0; margin: 0; }
.footer-col ul li { margin-bottom: 12px; font-size: 13px; display: flex; align-items: center; gap: 8px; color: #999; font-weight: normal;}
.footer-col ul li a { color: #999; text-decoration: none; transition: color 0.3s; font-weight: normal;}
.footer-col ul li a:hover { color: #D8B257; }

/* Nút liên kết MXH */
.social-links { display: flex; flex-wrap: wrap; gap: 10px; }
.social-link { display: inline-block; padding: 8px 16px; border: 1px solid #333; border-radius: 4px; color: #ccc; font-size: 13px; font-weight: normal; text-decoration: none; transition: all 0.3s; }
.social-link:hover { border-color: #D8B257; background-color: transparent; color: #D8B257; }

/* Bản quyền (Copyright) --- */
.footer-bottom { margin-top: 40px; padding: 20px 0; border-top: 1px solid #222; text-align: center; font-size: 13px; color: #666; font-weight: normal;}

@media (max-width: 768px) {
  .footer-grid { grid-template-columns: 1fr; gap: 30px; }
}
</style>
