<template>
  <div class="policy-wrapper">
    <AppHeader />
    <AppNavbar />

    <div class="container main-content">
      <el-breadcrumb :separator-icon="ArrowRight" class="breadcrumb-custom">
        <el-breadcrumb-item :to="{ path: '/' }">Trang chủ</el-breadcrumb-item>
        <el-breadcrumb-item>{{ policyTitle }}</el-breadcrumb-item>
      </el-breadcrumb>

      <div class="policy-container">
        <div class="policy-sidebar">
          <h3>CHÍNH SÁCH</h3>
          <ul class="policy-menu">
            <li :class="{ active: type === 'bao-hanh' }" @click="changePolicy('bao-hanh')">Chính sách bảo hành</li>
            <li :class="{ active: type === 'doi-tra' }" @click="changePolicy('doi-tra')">Chính sách đổi trả</li>
            <li :class="{ active: type === 'van-chuyen' }" @click="changePolicy('van-chuyen')">Chính sách vận chuyển</li>
            <li :class="{ active: type === 'huong-dan' }" @click="changePolicy('huong-dan')">Hướng dẫn mua hàng</li>
          </ul>
        </div>

        <div class="policy-content">
          <h1 class="content-title">{{ policyTitle }}</h1>
          <div class="content-body" v-html="policyContent"></div>
          
          <div class="contact-box">
            <p>Mọi thắc mắc vui lòng liên hệ hotline:</p>
            <h2 class="hotline">{{ settingsStore.sys_hotline }}</h2>
          </div>
        </div>
      </div>
    </div>

    <AppFooter />
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ArrowRight } from '@element-plus/icons-vue'
import AppHeader from '../components/AppHeader.vue'
import AppNavbar from '../components/AppNavbar.vue'
import AppFooter from '../components/AppFooter.vue'
import { useSettingsStore } from '../stores/settings'
import { sanitizeRichHtml } from '../utils/format'

const route = useRoute()
const router = useRouter()
const settingsStore = useSettingsStore()

const type = ref(route.query.type || 'bao-hanh')
const apiPolicies = ref({ 'bao-hanh': '', 'doi-tra': '', 'van-chuyen': '', 'huong-dan': '' })

const policyData = computed(() => ({
  'bao-hanh': {
    title: 'Chính sách bảo hành',
    content: apiPolicies.value['bao-hanh'] || `
      <p>Chào mừng quý khách đến với chính sách bảo hành của Đèn Hoa Mỹ. Chúng tôi cam kết mang đến sự an tâm tuyệt đối cho khách hàng.</p>
      <h3>1. Thời hạn bảo hành</h3>
      <ul>
        <li>Đối với các dòng đèn chùm, đèn thả cao cấp: Bảo hành từ 24 - 36 tháng.</li>
        <li>Đối với đèn vách, đèn gương, đèn bàn: Bảo hành 12 tháng.</li>
        <li>Bóng đèn đi kèm (nếu có): Bảo hành 6 tháng.</li>
      </ul>
    `
  },
  'doi-tra': {
    title: 'Chính sách đổi trả',
    content: apiPolicies.value['doi-tra'] || `
      <h3>1. Quy định đổi hàng</h3>
      <p>Quý khách được đổi sang mẫu khác trong vòng 7 ngày kể từ ngày nhận hàng nếu sản phẩm chưa qua lắp đặt và còn nguyên hộp, nguyên kiện.</p>
    `
  },
  'van-chuyen': {
    title: 'Chính sách vận chuyển',
    content: apiPolicies.value['van-chuyen'] || `
      <h3>1. Phạm vi vận chuyển</h3>
      <p>Đèn Hoa Mỹ giao hàng toàn quốc thông qua các đơn vị vận chuyển uy tín hoặc chành xe đối với các đơn hàng cồng kềnh.</p>
    `
  },
  'huong-dan': {
    title: 'Hướng dẫn mua hàng',
    content: apiPolicies.value['huong-dan'] || `
      <h3>Các bước mua hàng đơn giản</h3>
      <p><strong>Bước 1:</strong> Lựa chọn sản phẩm ưng ý trên Website.</p>
      <p><strong>Bước 2:</strong> Bấm "Thêm vào giỏ hàng" hoặc "Mua ngay".</p>
    `
  }
}))

const policyTitle = computed(() => policyData.value[type.value]?.title || 'Chính sách')
const policyContent = computed(() => sanitizeRichHtml(policyData.value[type.value]?.content || ''))

const changePolicy = (newType) => {
  type.value = newType
  router.push({ path: '/policy', query: { type: newType } })
}

watch(() => route.query.type, (newType) => {
  if (newType) type.value = newType
})

onMounted(async () => {
  if (route.query.type) type.value = route.query.type
  
  // Fetch từ API
  await settingsStore.fetchSettings()
  apiPolicies.value = {
    'bao-hanh': settingsStore.sys_raw_data?.policy_bao_hanh || '',
    'doi-tra': settingsStore.sys_raw_data?.policy_doi_tra || '',
    'van-chuyen': settingsStore.sys_raw_data?.policy_van_chuyen || '',
    'huong-dan': settingsStore.sys_raw_data?.policy_huong_dan || ''
  }
})
</script>

<style scoped>
/* --- 1. Cấu trúc nền và khung chứa --- */
.policy-wrapper { background-color: #f7f8fa; min-height: 100vh; }
.container { width: 1200px; margin: 0 auto; max-width: 100%; padding: 0 20px; box-sizing: border-box; }
.breadcrumb-custom { padding: 20px 0; font-size: 14px; }

/* Bố cục chia 2 cột: Sidebar trái (300px) và Nội dung phải (1fr) */
.policy-container { display: grid; grid-template-columns: 300px 1fr; gap: 40px; margin-top: 20px; padding-bottom: 50px; }

/* --- 2. Thanh bên trái (Sidebar Menu) --- */
.policy-sidebar { background: #fff; border-radius: 8px; box-shadow: 0 2px 12px rgba(0,0,0,0.05); height: fit-content; overflow: hidden; }
.policy-sidebar h3 { background: #111; color: #D8B257; margin: 0; padding: 15px 20px; font-size: 16px; letter-spacing: 1px; }

.policy-menu { list-style: none; padding: 0; margin: 0; }
.policy-menu li { padding: 15px 20px; border-bottom: 1px solid #f0f0f0; cursor: pointer; transition: all 0.3s; font-size: 14px; color: #555; }
.policy-menu li:hover { color: #D8B257; padding-left: 25px; }

/* Trạng thái menu đang được chọn */
.policy-menu li.active { background-color: #fcf9f2; color: #D8B257; font-weight: bold; border-left: 4px solid #D8B257; }

/* --- 3. Nội dung chính sách bên phải --- */
.policy-content { background: #fff; padding: 40px; border-radius: 8px; box-shadow: 0 2px 12px rgba(0,0,0,0.05); }
.content-title { margin: 0 0 30px; font-size: 28px; color: #222; position: relative; padding-bottom: 15px; }
.content-title::after { content: ''; position: absolute; bottom: 0; left: 0; width: 60px; height: 3px; background: #D8B257; }

.content-body { line-height: 1.8; color: #444; font-size: 15px; }

/* Phần Box liên hệ Hotline */
.contact-box { margin-top: 50px; padding: 25px; background: #f9f9f9; border-left: 5px solid #D8B257; text-align: center; }
.hotline { margin: 10px 0 0; color: #D8B257; font-size: 32px; letter-spacing: 1px; }

/* Responsive cho máy tính bảng/di động */
@media (max-width: 992px) {
  .policy-container { grid-template-columns: 1fr; }
}
</style>
