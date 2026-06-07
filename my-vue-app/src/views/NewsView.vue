<template>
  <div class="news-page">
    <AppHeader />
    <AppNavbar activeIndex="news" />

    <div class="container section">
      <el-breadcrumb separator="/" class="breadcrumb-custom">
        <el-breadcrumb-item :to="{ path: '/' }">Trang chủ</el-breadcrumb-item>
        <el-breadcrumb-item>Tin tức - Bài viết</el-breadcrumb-item>
      </el-breadcrumb>

      <div class="title-head text-center">
        <h2>TẠP CHÍ ĐÈN NGHỆ THUẬT</h2>
        <p>Cập nhật những xu hướng, kiến thức và thông tin mới nhất về không gian ánh sáng</p>
      </div>

      <div v-if="loading" style="text-align: center; padding: 60px 0;">
        <el-icon class="is-loading" :size="40" color="#D8B257"><Loading /></el-icon>
        <p style="color: #999; margin-top: 15px;">Đang tải danh sách bài viết...</p>
      </div>

      <div v-else-if="newsList.length === 0" style="padding: 60px 0; text-align: center;">
        <el-empty description="Hiện tại chưa có bài viết nào." />
      </div>

      <el-row :gutter="30" v-else class="news-grid">
        <el-col :xs="24" :sm="12" :md="8" v-for="news in newsList" :key="news.id" style="margin-bottom: 30px;">
          <el-card class="news-card" shadow="hover" :body-style="{ padding: '0px' }" @click="goToDetail(news.slug)">
            <div class="news-img-box">
              <el-image 
                :src="news.thumbnail || 'https://images.unsplash.com/photo-1540932239986-30128078f3c5?q=80&w=600'" 
                class="news-img" 
                fit="cover" 
              />
            </div>
            <div class="news-content">
              <div class="news-meta">
                <span class="news-date"><el-icon><Calendar /></el-icon> {{ new Date(news.created_at).toLocaleDateString('vi-VN') }}</span>
                <span class="news-views"><el-icon><View /></el-icon> {{ news.view_count || 0 }}</span>
              </div>
              <h3 class="news-title">{{ news.title }}</h3>
              <p class="news-summary">{{ news.summary }}</p>
              <el-button type="info" link class="read-more">Xem chi tiết <el-icon><ArrowRight /></el-icon></el-button>
            </div>
          </el-card>
        </el-col>
      </el-row>
    </div>

    <AppFooter />
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { Loading, Calendar, View, ArrowRight } from '@element-plus/icons-vue'
import AppHeader from '../components/AppHeader.vue'
import AppNavbar from '../components/AppNavbar.vue'
import AppFooter from '../components/AppFooter.vue'
import { getNews } from '../services/newsService'

const router = useRouter()
const newsList = ref([])
const loading = ref(true)

onMounted(async () => {
  loading.value = true
  const res = await getNews(false) // Không phải admin -> Chỉ lấy bài is_published = 1
  loading.value = false
  if (res && res.success) {
    newsList.value = res.data
  }
})

const goToDetail = (slug) => {
  router.push(`/news/${slug}`)
}
</script>

<style scoped>
/* --- 1. Cấu trúc nền và khung chứa --- */
.news-page { background-color: #f9fbff; min-height: 100vh; }
.container { width: 1200px; margin: 0 auto; max-width: 100%; padding: 0 20px; box-sizing: border-box; }
.section { padding: 40px 0 80px; }
.breadcrumb-custom { font-size: 14px; margin-bottom: 30px; }

/* Tiêu đề tạp chí */
.title-head { margin-bottom: 50px; }
.title-head h2 { font-size: 32px; color: #D8B257; margin-bottom: 10px; letter-spacing: 1px; }

/* --- 2. Thẻ tin tức (News Card) --- */
.news-card { border-radius: 10px; overflow: hidden; cursor: pointer; transition: all 0.3s ease; border: none; }
.news-card:hover { transform: translateY(-5px); box-shadow: 0 15px 30px rgba(0,0,0,0.1) !important; }

/* Hình ảnh bài viết và hiệu ứng Zoom */
.news-img-box { height: 220px; overflow: hidden; }
.news-img { width: 100%; height: 100%; transition: transform 0.5s ease; }
.news-card:hover .news-img { transform: scale(1.05); }

/* --- 3. Nội dung bài viết trong Card --- */
.news-content { padding: 25px 20px; background: #fff; }
.news-meta { display: flex; gap: 15px; color: #999; font-size: 12px; margin-bottom: 12px; }

/* Tiêu đề tin tức (Giới hạn 2 dòng) */
.news-title { margin: 0 0 12px 0; font-size: 22px; color: #D8B257; line-height: 1.4; display: -webkit-box; -webkit-line-clamp: 2; line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; font-weight: 800; transition: color 0.3s; }
.news-card:hover .news-title { color: #b5954a; }

/* Tóm tắt tin tức (Giới hạn 3 dòng) */
.news-summary { color: #666; font-size: 14px; line-height: 1.6; margin: 0 0 20px 0; display: -webkit-box; -webkit-line-clamp: 3; line-clamp: 3; -webkit-box-orient: vertical; overflow: hidden; }

.read-more { font-weight: bold; font-size: 13px; color: #D8B257 !important; padding: 0; }

@media (max-width: 768px) {
  .section { padding: 25px 15px 50px; }
  .breadcrumb-custom { margin-bottom: 20px; }
  .title-head { margin-bottom: 30px; }
  .title-head h2 { font-size: 24px; }
  .title-head p { font-size: 13px; line-height: 1.4; }
  .news-img-box { height: 180px; }
  .news-content { padding: 15px; }
  .news-title { font-size: 18px; margin-bottom: 8px; }
  .news-summary { font-size: 13px; line-height: 1.5; margin-bottom: 15px; }
  .news-meta { margin-bottom: 8px; }
}
</style>
