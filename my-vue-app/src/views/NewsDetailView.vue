<template>
  <div class="news-detail-page">
    <AppHeader />
    <AppNavbar activeIndex="news" />

    <div class="container section">
      <div v-if="loading" style="text-align: center; padding: 80px 0;">
        <el-icon class="is-loading" :size="40" color="#D8B257"><Loading /></el-icon>
        <p style="color: #999; margin-top: 15px;">Đang tải bài viết...</p>
      </div>

      <div v-else-if="!newsItem" style="padding: 100px 0; text-align: center;">
        <el-empty description="Không tìm thấy bài viết hoặc bài viết đã bị xóa!" />
        <el-button type="primary" style="margin-top:20px; background-color: #D8B257; border:none;" @click="$router.push('/news')">
          Quay lại danh sách Tin Tức
        </el-button>
      </div>

      <template v-else>
        <el-breadcrumb separator="/" class="breadcrumb-custom">
          <el-breadcrumb-item :to="{ path: '/' }">Trang chủ</el-breadcrumb-item>
          <el-breadcrumb-item :to="{ path: '/news' }">Tin tức - Bài viết</el-breadcrumb-item>
          <el-breadcrumb-item>{{ newsItem.title }}</el-breadcrumb-item>
        </el-breadcrumb>

        <div class="news-content-wrapper">
          <h1 class="news-title">{{ newsItem.title }}</h1>
          
          <div class="news-meta">
            <span><el-icon><Calendar /></el-icon> {{ new Date(newsItem.created_at).toLocaleDateString('vi-VN') }}</span>
            <el-divider direction="vertical" />
            <span><el-icon><User /></el-icon> Đăng bởi: {{ newsItem.author_name || 'Đèn Hoa Mỹ' }}</span>
            <el-divider direction="vertical" />
            <span><el-icon><View /></el-icon> {{ newsItem.view_count || 0 }} lượt xem</span>
          </div>

          <div class="news-summary-box">
            {{ newsItem.summary }}
          </div>

          <div class="news-body" v-html="displayContent"></div>

          <div class="news-footer">
            <div class="share-box">
              <strong>Chia sẻ bài viết:</strong>
              <el-tooltip content="Chia sẻ Facebook" placement="top">
                <el-button circle class="share-btn share-btn--facebook" @click="shareFacebook" aria-label="Chia sẻ Facebook">
                  <span class="share-btn-label">f</span>
                </el-button>
              </el-tooltip>
              <el-tooltip content="Chia sẻ Zalo" placement="top">
                <el-button circle class="share-btn share-btn--zalo" @click="shareZalo" aria-label="Chia sẻ Zalo">
                  <span class="share-btn-label">Z</span>
                </el-button>
              </el-tooltip>
              <el-tooltip content="Chia sẻ Telegram" placement="top">
                <el-button circle class="share-btn share-btn--telegram" @click="shareTelegram" aria-label="Chia sẻ Telegram">
                  <span class="share-btn-label">TG</span>
                </el-button>
              </el-tooltip>
              <el-tooltip content="Sao chép liên kết" placement="top">
                <el-button circle class="share-btn share-btn--copy" @click="copyShareLink" aria-label="Sao chép liên kết">
                  <el-icon><Link /></el-icon>
                </el-button>
              </el-tooltip>
            </div>
          </div>
        </div>
      </template>
    </div>

    <AppFooter />
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { Loading, Calendar, View, User, Link } from '@element-plus/icons-vue'
import AppHeader from '../components/AppHeader.vue'
import AppNavbar from '../components/AppNavbar.vue'
import AppFooter from '../components/AppFooter.vue'
import { getNewsDetail } from '../services/newsService'
import { sanitizeNewsHtml } from '../utils/format'
import { ElMessage } from 'element-plus'

const route = useRoute()
const router = useRouter()
const newsItem = ref(null)
const loading = ref(true)

const shareUrl = computed(() => {
  if (typeof window === 'undefined') return ''
  return window.location.href
})

const shareTitle = computed(() => newsItem.value?.title || 'Bài viết Đèn Hoa Mỹ')

const displayContent = computed(() => sanitizeNewsHtml(newsItem.value?.content || ''))

const openShareWindow = (url) => {
  window.open(url, '_blank', 'noopener,noreferrer,width=640,height=480')
}

const shareFacebook = () => {
  const u = encodeURIComponent(shareUrl.value)
  openShareWindow(`https://www.facebook.com/sharer/sharer.php?u=${u}`)
}

const shareZalo = () => {
  const u = encodeURIComponent(shareUrl.value)
  openShareWindow(`https://zalo.me/share?url=${u}`)
}

const shareTelegram = () => {
  const u = encodeURIComponent(shareUrl.value)
  const t = encodeURIComponent(shareTitle.value)
  openShareWindow(`https://t.me/share/url?url=${u}&text=${t}`)
}

const copyShareLink = async () => {
  try {
    await navigator.clipboard.writeText(shareUrl.value)
    ElMessage.success('Đã sao chép liên kết bài viết!')
  } catch {
    ElMessage.error('Không sao chép được liên kết. Vui lòng copy thủ công từ thanh địa chỉ.')
  }
}

onMounted(async () => {
  const slug = route.params.slug
  if (!slug) {
    router.push('/news')
    return
  }

  loading.value = true
  const res = await getNewsDetail(slug)
  loading.value = false
  if (res && res.success) {
    newsItem.value = res.data
  } else {
    ElMessage.error('Bài viết không tồn tại!')
  }
})
</script>

<style scoped>
/* --- 1. Cấu trúc nền và khung chứa --- */
.news-detail-page { background-color: #f7f8fa; min-height: 100vh; }
.container { width: 1000px; margin: 0 auto; max-width: 100%; padding: 0 20px; box-sizing: border-box; }
.section { padding: 40px 0 80px; }
.breadcrumb-custom { font-size: 14px; margin-bottom: 25px; }

/* Khối bao quanh nội dung bài viết */
.news-content-wrapper { background: #fff; padding: 50px 60px; border-radius: 12px; box-shadow: 0 5px 20px rgba(0,0,0,0.03); }

/* --- 2. Tiêu đề và Thông tin bài viết --- */
.news-title { margin: 0 0 20px 0; font-size: 32px; color: #111; line-height: 1.4; }
.news-meta { display: flex; align-items: center; gap: 10px; color: #888; font-size: 14px; margin-bottom: 30px; border-bottom: 1px solid #f0f0f0; padding-bottom: 20px; }

/* Box tóm tắt (Sapo) */
.news-summary-box { background-color: #fdfaf3; border-left: 4px solid #D8B257; padding: 20px 25px; font-size: 16px; color: #555; font-style: italic; margin-bottom: 40px; line-height: 1.6; border-radius: 0 8px 8px 0; }

/* --- 3. Thân bài viết (Xử lý các thẻ HTML từ Backend) --- */
.news-body { font-size: 16px; color: #333; line-height: 1.8; }
:deep(.news-body p:empty) { display: none; margin: 0; padding: 0; }
:deep(.news-body p:has(> br:only-child)) { display: none; margin: 0; padding: 0; }
:deep(.news-body > *:first-child) { margin-top: 0; }
:deep(.news-body img) { max-width: 100%; height: auto !important; border-radius: 8px; margin: 20px 0; display: block; }
:deep(.news-body img[src=""]) { display: none; }
:deep(.news-body h2) { font-size: 24px; color: #D8B257; margin-top: 40px; margin-bottom: 15px; }
:deep(.news-body h2:first-child) { margin-top: 0; }
:deep(.news-body h3) { font-size: 20px; color: #222; margin-top: 30px; margin-bottom: 15px; }
:deep(.news-body h3:first-child) { margin-top: 0; }

/* Chân bài viết và các nút chia sẻ */
.news-footer { margin-top: 50px; padding-top: 20px; border-top: 1px solid #eee; display: flex; justify-content: flex-end; }
.share-box { display: flex; align-items: center; flex-wrap: wrap; gap: 10px; color: #555; }
.share-btn { border: none; color: #fff; font-weight: 700; }
.share-btn-label { font-size: 13px; line-height: 1; }
.share-btn--facebook { background: #1877f2; }
.share-btn--facebook:hover { background: #166fe0; color: #fff; }
.share-btn--zalo { background: #0068ff; }
.share-btn--zalo:hover { background: #0056d6; color: #fff; }
.share-btn--telegram { background: #229ed9; }
.share-btn--telegram:hover { background: #1d8fc7; color: #fff; }
.share-btn--copy { background: #D8B257; color: #fff; }
.share-btn--copy:hover { background: #c9a347; color: #fff; }

/* Giao diện di động */
@media (max-width: 768px) {
  .section { padding: 25px 15px 50px; }
  .news-content-wrapper { padding: 20px 15px 20px 50px; border-radius: 8px; }
  .news-title { font-size: 20px; font-weight: 700; margin-bottom: 15px; }
  .news-summary-box { padding: 12px 15px; font-size: 14px; margin-bottom: 25px; }
  .news-body { font-size: 15px; }
  :deep(.news-body h2) { font-size: 20px; margin-top: 30px; }
  :deep(.news-body h3) { font-size: 18px; margin-top: 25px; }
  
  .news-meta {
    flex-wrap: wrap;
    gap: 8px 15px;
    font-size: 12.5px;
    margin-bottom: 20px;
    padding-bottom: 15px;
  }
  .news-meta :deep(.el-divider--vertical) {
    display: none !important;
  }

  /* Hide the long article title in breadcrumbs on mobile */
  .breadcrumb-custom :deep(.el-breadcrumb__item:last-child) {
    display: none !important;
  }
  /* Hide the trailing separator (slash) from the second-to-last item */
  .breadcrumb-custom :deep(.el-breadcrumb__item:nth-last-child(2) .el-breadcrumb__separator) {
    display: none !important;
  }
}
</style>
