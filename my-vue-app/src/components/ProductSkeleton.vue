<template>
  <div class="skeleton-grid">
    <div v-for="n in count" :key="n" class="skeleton-card">
      <div class="skeleton-img shimmer"></div>
      <div class="skeleton-body">
        <div class="skeleton-line title shimmer"></div>
        <div class="skeleton-line short shimmer"></div>
        <div class="skeleton-line btn shimmer"></div>
      </div>
    </div>
  </div>
</template>

<script setup>
defineProps({
  count: { type: Number, default: 4 }
})
</script>

<style scoped>
/* --- Khung chứa grid skeleton --- */
.skeleton-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 20px;
}

/* --- Card skeleton giả lập product card --- */
.skeleton-card {
  background: #fff;
  border-radius: 10px;
  overflow: hidden;
  border: 1px solid #f0f0f0;
}

/* Ảnh giả lập */
.skeleton-img {
  width: 100%;
  height: 260px;
  background-color: #e9ecef;
}

/* Nội dung bên dưới ảnh */
.skeleton-body {
  padding: 20px;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 12px;
}

/* Các thanh text giả lập */
.skeleton-line {
  height: 14px;
  border-radius: 4px;
  background-color: #e9ecef;
}
.skeleton-line.title {
  width: 85%;
  height: 16px;
}
.skeleton-line.short {
  width: 50%;
}
.skeleton-line.btn {
  width: 100%;
  height: 40px;
  border-radius: 20px;
  margin-top: 6px;
}

/* --- Hiệu ứng shimmer (sáng chạy từ trái sang phải) --- */
.shimmer {
  background: linear-gradient(
    90deg,
    #e9ecef 25%,
    #f5f5f5 50%,
    #e9ecef 75%
  );
  background-size: 200% 100%;
  animation: shimmer 1.5s ease-in-out infinite;
}

@keyframes shimmer {
  0% { background-position: 200% 0; }
  100% { background-position: -200% 0; }
}

/* --- Responsive --- */
@media (max-width: 1200px) {
  .skeleton-grid { grid-template-columns: repeat(3, 1fr); }
}
@media (max-width: 768px) {
  .skeleton-grid { grid-template-columns: repeat(2, 1fr); }
}
@media (max-width: 480px) {
  .skeleton-grid { grid-template-columns: 1fr; }
}
</style>
