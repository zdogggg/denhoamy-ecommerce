<template>
  <div class="not-found-wrapper">
    <div class="not-found-content">
      <!-- Animated 404 Number -->
      <div class="error-code">
        <span class="digit">4</span>
        <span class="digit zero">
          <div class="lamp-icon">
            <svg width="80" height="80" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
              <path d="M12 2v3M12 5c-2.5 0-5 2-5 5 0 2 1 3.5 2.5 4.5V17h5v-2.5C16 13.5 17 12 17 10c0-3-2.5-5-5-5z" 
                    stroke="#D8B257" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
              <path d="M9.5 17v1.5c0 .83.67 1.5 1.5 1.5h2c.83 0 1.5-.67 1.5-1.5V17" 
                    stroke="#D8B257" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
              <path d="M12 5v-3M4.22 4.22l1.42 1.42M1 12h3M4.22 19.78l1.42-1.42M19.78 4.22l-1.42 1.42M23 12h-3M19.78 19.78l-1.42-1.42" 
                    stroke="#D8B257" stroke-width="1.2" stroke-linecap="round" opacity="0.5"/>
            </svg>
          </div>
        </span>
        <span class="digit">4</span>
      </div>

      <h1 class="error-title">Trang không tồn tại</h1>
      <p class="error-desc">
        Xin lỗi, trang bạn đang tìm kiếm không tồn tại hoặc đã được di chuyển.<br>
        Hãy quay về trang chủ để tiếp tục mua sắm nhé!
      </p>

      <div class="error-actions">
        <el-button class="btn-home" size="large" @click="$router.push('/')">
          <el-icon style="margin-right: 8px;"><HomeFilled /></el-icon>
          Quay về Trang chủ
        </el-button>
        <el-button class="btn-category" size="large" @click="$router.push('/category')">
          <el-icon style="margin-right: 8px;"><Search /></el-icon>
          Xem sản phẩm
        </el-button>
      </div>

      <div class="error-contact">
        <p>Cần hỗ trợ? Gọi ngay Hotline: <strong>0978.897.579 - 0225.653.3618</strong></p>
      </div>
    </div>
  </div>
</template>

<script setup>
import { HomeFilled, Search } from '@element-plus/icons-vue'
</script>

<style scoped>
/* --- Wrapper toàn trang --- */
.not-found-wrapper {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #1a1a2e 0%, #16213e 50%, #0f3460 100%);
  padding: 40px 20px;
}

.not-found-content {
  text-align: center;
  max-width: 600px;
}

/* --- Số 404 với animation --- */
.error-code {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 5px;
  margin-bottom: 30px;
}

.digit {
  font-size: 120px;
  font-weight: 900;
  color: #D8B257;
  text-shadow: 0 0 40px rgba(216, 178, 87, 0.3);
  animation: float 3s ease-in-out infinite;
  line-height: 1;
}

.digit:nth-child(1) { animation-delay: 0s; }
.digit:nth-child(3) { animation-delay: 0.4s; }

.digit.zero {
  position: relative;
  width: 100px;
  height: 120px;
  display: flex;
  align-items: center;
  justify-content: center;
  animation-delay: 0.2s;
}

.lamp-icon {
  animation: glow 2s ease-in-out infinite alternate;
}

@keyframes float {
  0%, 100% { transform: translateY(0); }
  50% { transform: translateY(-15px); }
}

@keyframes glow {
  from { filter: drop-shadow(0 0 10px rgba(216, 178, 87, 0.3)); }
  to { filter: drop-shadow(0 0 25px rgba(216, 178, 87, 0.8)); }
}

/* --- Tiêu đề và mô tả --- */
.error-title {
  font-size: 28px;
  font-weight: 700;
  color: #ffffff;
  margin: 0 0 15px 0;
  letter-spacing: 1px;
}

.error-desc {
  font-size: 15px;
  color: rgba(255, 255, 255, 0.6);
  line-height: 1.8;
  margin: 0 0 35px 0;
}

/* --- Nút bấm --- */
.error-actions {
  display: flex;
  gap: 15px;
  justify-content: center;
  margin-bottom: 40px;
}

.btn-home,
.btn-category {
  font-weight: bold;
  padding: 12px 30px !important;
  border-radius: 25px;
  transition: all 0.3s;
  display: inline-flex !important;
  align-items: center !important;
  justify-content: center !important;
}

.btn-home {
  background-color: #D8B257;
  border-color: #D8B257;
  color: #000;
}
.btn-home:hover {
  background-color: #c7a14e;
  border-color: #c7a14e;
  transform: translateY(-2px);
  box-shadow: 0 8px 25px rgba(216, 178, 87, 0.35);
}

.btn-category {
  background-color: transparent;
  border: 2px solid rgba(216, 178, 87, 0.5) !important;
  color: #D8B257;
}
.btn-category:hover {
  background-color: rgba(216, 178, 87, 0.1);
  border-color: #D8B257;
  transform: translateY(-2px);
}

/* --- Thông tin liên hệ --- */
.error-contact {
  padding-top: 25px;
  border-top: 1px solid rgba(255,255,255,0.1);
}
.error-contact p {
  color: rgba(255,255,255,0.4);
  font-size: 13px;
  margin: 0;
}
.error-contact strong {
  color: #D8B257;
  font-size: 15px;
}

/* --- Responsive --- */
@media (max-width: 480px) {
  .digit { font-size: 80px; }
  .digit.zero { width: 70px; height: 80px; }
  .lamp-icon svg { width: 55px; height: 55px; }
  .error-title { font-size: 22px; }
  .error-actions { flex-direction: column; align-items: center; gap: 12px; }
  .btn-home, .btn-category {
    width: 220px !important;
    padding: 12px 0 !important;
    margin: 0 !important;
    display: inline-flex !important;
    justify-content: center !important;
    align-items: center !important;
  }
}
</style>
