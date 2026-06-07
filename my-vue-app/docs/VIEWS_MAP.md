# Bản đồ `src/views` — Đèn Hoa Mỹ

> **Cập nhật:** 06/06/2026 · 17 routes · 19 components admin/layout

| Route | File view | Chức năng chính |
|-------|-----------|-----------------| 
| `/` | `HomeView.vue` | Trang chủ: banner carousel, banner QC dọc (trái/phải), banner ngang, danh mục icon, hot deal, sản phẩm mới (slider), khám phá bộ sưu tập |
| `/category` | `CategoryView.vue` | Danh mục SP: lọc loại/phong cách, sắp xếp giá, tìm kiếm, phân trang, skeleton loading |
| `/product/:id` | `ProductDetailView.vue` | Chi tiết SP: gallery, biến thể, wishlist, đánh giá; **SP liên quan** qua `getRelatedProducts()` (API `exclude_id` + `limit`) |
| `/cart` | `CartView.vue` | Giỏ: localStorage; customer đăng nhập đồng bộ `cart.php` (Pinia `cartStore`) |
| `/checkout` | `CheckoutView.vue` | Thanh toán (**requiresAuth**): giao hàng (`home`) / nhận tại shop (`store`); PTTT COD, PayOS, `pay_at_store`; coupon; dialog đơn PayOS pending (retry/hủy); guard `beforeunload` |
| `/payment/success` | `PaymentResultView.vue` | PayOS return — poll `payment_status`, xóa giỏ khi `isPaid`, nút retry PayOS |
| `/payment/cancel` | `PaymentResultView.vue` | PayOS hủy/chưa thanh toán — poll status, retry hoặc quay checkout |
| `/login` | `LoginView.vue` | Đăng nhập (+ ghi nhớ, redirect query) |
| `/register` | `RegisterView.vue` | Đăng ký |
| `/forgot-password` | `ForgotPasswordView.vue` | Quên mật khẩu (Magic Link qua Resend) |
| `/reset-password` | `ResetPasswordView.vue` | Đặt lại mật khẩu (token URL) |
| `/profile` | `ProfileView.vue` | Tài khoản: lịch sử đơn, yêu thích, sửa profile, **xác nhận đã nhận hàng** — mobile (≤992px): layout 1 cột, tab ngang, thẻ đơn/SP |
| `/news` | `NewsView.vue` | Danh sách tin tức |
| `/news/:slug` | `NewsDetailView.vue` | Chi tiết bài viết (SEO slug, sanitize HTML) |
| `/policy` | `PolicyView.vue` | Chính sách CMS (`policy_*` từ settings): bảo hành, đổi trả, vận chuyển, hướng dẫn mua |
| `/admin` | `AdminView.vue` | Shell quản trị RBAC; **poll đơn 5s** + `ElNotification` khi có đơn `pending` mới |
| `*` | `NotFoundView.vue` | Trang 404 (animated lamp icon) |

## Admin sub-components (trong `AdminView.vue`)

| Component | Menu / quyền | Chức năng |
|-----------|----------------|-----------|
| `AdminDashboard.vue` | dashboard | Chart.js doanh thu, top SP, SP sắp hết hàng, lợi nhuận, xuất Excel |
| `AdminPendingOrders.vue` | orders | Widget đơn chờ duyệt (expand items) |
| `AdminProducts.vue` | products | CRUD + Import Excel, gallery, biến thể, giá nhập; giá cũ tùy chọn |
| `AdminCategories.vue` | categories | Cây phân cấp (cha/con), drag sort |
| `AdminOrders.vue` | orders | Filter/search, trạng thái 5 bước, cột giao hàng/PTTT, hoàn kho khi hủy |
| `AdminHotDeal.vue` | coupons | Hot Deal + sửa giá nhanh (snapshot giá) |
| `AdminCoupons.vue` | coupons | CRUD voucher, giới hạn lượt dùng, thời gian hiệu lực |
| `AdminReviews.vue` | reviews | Duyệt/từ chối, trả lời khách |
| `AdminNews.vue` | news | CRUD bài viết, WYSIWYG (Quill), sanitize HTML |
| `AdminPolicy.vue` | policy | CMS 4 tab chính sách → `settings` key `policy_*` |
| `AdminUsers.vue` | customers / accounts | Khách hàng + admin/staff, phân quyền 11 module |
| `AdminSettings.vue` | settings | Logo, banner (≤6), QC dọc/ngang, hotline, QR, nén ảnh client-side |

## Component layout chung

| Component | Dùng ở |
|-----------|--------|
| `AppHeader.vue` | Thanh điều hướng responsive (hamburger mobile) |
| `AppNavbar.vue` | Navbar danh mục, sticky glassmorphism |
| `AppFooter.vue` | Footer cửa hàng |
| `ChatWidget.vue` | AI chatbot (Groq) — ẩn auth/admin/checkout/404 |
| `ProductSkeleton.vue` | Shimmer loading (Home, Category) |
| `PriceInput.vue` | Input giá VNĐ; prop `nullable` cho giá cũ |
| `composables/useMobileLayout.js` | Breakpoint 992px — `ProfileView` |

## Utils (frontend)

| File | Chức năng |
|------|-----------|
| `utils/productPrice.js` | `resolveSalePrice`, `getProductPriceDisplay` — nhãn **「Từ Xđ」** |
| `utils/payosPending.js` | `sessionStorage` lưu `orderId` PayOS đang chờ |
| `utils/sessionExpired.js` | 401 từ `httpClient` → logout + redirect login |
| `utils/promptAuthForPurchase.js` | Modal bắt đăng nhập trước mua/wishlist |
| `utils/orderStatus.js` | Nhãn và luồng trạng thái đơn |
| `utils/format.js` | `formatPrice`, `sanitizeNewsHtml` |
| `utils/authStorage.js` | localStorage vs sessionStorage cho JWT |
| `utils/useSEO.js` | Meta title/OG động |
| `utils/toast.js` | Toast Element Plus wrapper |
| `utils/chatMarkdown.js` | Render markdown chatbot an toàn |

## Router guards (`router/index.js`)

| Meta | Hành vi |
|------|---------|
| `requiresAuth` | `/checkout`, `/profile` → redirect `/login?redirect=...` |
| `requiresAdmin` | `/admin` → cần `canAccessAdmin` (admin/staff) |

## Sửa giao diện nhanh

- **Auth**: từng `*View.vue` + `assets/auth-bg.jpg`
- **Thẻ SP**: `HomeView.vue`, `CategoryView.vue`, `ProductDetailView.vue`
- **Banner QC**: `HomeView.vue` + `AdminSettings.vue` + `stores/settings.js`
- **Checkout / PayOS**: `CheckoutView.vue`, `PaymentResultView.vue`, `services/orderService.js`
- **Admin**: `AdminView.vue` + `components/Admin*.vue`
- **Floating social**: `App.vue` (Phone, Zalo, Messenger — ẩn checkout/admin)
