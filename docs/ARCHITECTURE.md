# System Architecture — Đèn Hoa Mỹ E-Commerce

> **Kiến trúc:** 3-Tier (Presentation → Application → Data)  
> **Triển khai:** Docker Compose (4 containers)  
> **Cập nhật:** 06/2026

---

## 1. Tổng Quan Kiến Trúc

### 1.1 Sơ đồ tổng thể

```
                                    ┌──────────────────────┐
                                    │      INTERNET        │
                                    └──────────┬───────────┘
                                               │
                               ┌───────────────▼───────────────┐
                               │         DOCKER HOST            │
                               │                               │
  ┌────────────────────────────┤                               ├─────────────────────┐
  │                            │                               │                     │
  │  ┌─────────────────┐      │  ┌──────────────────────┐     │  ┌────────────────┐  │
  │  │   FRONTEND       │      │  │      BACKEND          │     │  │   DATABASE      │  │
  │  │                 │      │  │                      │     │  │                │  │
  │  │  Vue 3 SPA      │  API │  │  PHP 8.2             │ SQL │  │  MySQL 8.0     │  │
  │  │  Nginx          │──────│──│  Apache              │─────│──│  denhoamy_db   │  │
  │  │  Port: 3000     │ JSON │  │  Port: 8080          │     │  │  Port: 3307    │  │
  │  │                 │      │  │                      │     │  │                │  │
  │  └─────────────────┘      │  └───────┬──────────────┘     │  └────────────────┘  │
  │                            │          │                    │                     │
  │  ┌─────────────────┐      │          │ HTTPS              │                     │
  │  │  phpMyAdmin      │      │  ┌───────▼──────────────┐     │                     │
  │  │  Port: 8081     │      │  │  3rd Party APIs       │     │                     │
  │  └─────────────────┘      │  │  ├── Groq (AI)        │     │                     │
  └────────────────────────────┤  │  ├── PayOS (Payment)  │     ├─────────────────────┘
                               │  │  └── Resend (Email)   │     │
                               │  └──────────────────────┘     │
                               │                               │
                               └───────────────────────────────┘
```

### 1.2 Docker Compose Services

| Service | Image | Port (Host) | Port (Container) | Vai trò |
|---|---|:---:|:---:|---|
| `db` | MySQL 8.0 | 3307 | 3306 | Relational Database |
| `api` | PHP 8.2 + Apache | 8080 | 80 | REST API Server |
| `frontend` | Nginx + Vue Build | 3000 | 80 | SPA Web Server |
| `phpmyadmin` | phpMyAdmin | 8081 | 80 | DB Admin UI |

```yaml
# Dependency Chain:
frontend ──depends_on──→ api ──depends_on──→ db (with healthcheck)
```

---

## 2. Frontend Architecture

### 2.1 Component Hierarchy

```
App.vue
├── AppHeader.vue                    ← Thanh điều hướng (responsive, mobile hamburger menu)
├── AppNavbar.vue                    ← Navigation bar danh mục (sticky glassmorphism)
├── AppFooter.vue                    ← Footer thông tin cửa hàng
├── ChatWidget.vue                   ← AI Chatbot widget (floating bubble)
│
├── <router-view>                    ← Vue Router
│   │
│   ├── CUSTOMER VIEWS (16 views)
│   │   ├── HomeView.vue             ← Trang chủ (Banner, Hot Deal, Showcase, Slider)
│   │   ├── CategoryView.vue         ← Danh mục + Filter/Sort/Search + Skeleton Loading
│   │   ├── ProductDetailView.vue    ← Chi tiết SP + Variants + Reviews + tag "Hàng mới về"
│   │   ├── CartView.vue             ← Giỏ hàng (Desktop table + Mobile card layout)
│   │   ├── CheckoutView.vue         ← Thanh toán: PTTT, giao hàng/nhận tại shop, coupon
│   │   ├── NewsView.vue             ← Danh sách tin tức
│   │   ├── NewsDetailView.vue       ← Chi tiết bài viết (responsive breadcrumb)
│   │   ├── LoginView.vue            ← Đăng nhập
│   │   ├── RegisterView.vue         ← Đăng ký
│   │   ├── ForgotPasswordView.vue   ← Quên mật khẩu
│   │   ├── ResetPasswordView.vue    ← Đặt lại mật khẩu (Magic Link)
│   │   ├── ProfileView.vue          ← Hồ sơ + đơn + wishlist (mobile: grid 1 cột, tab ngang)
│   │   ├── PaymentResultView.vue    ← Kết quả thanh toán PayOS
│   │   ├── PolicyView.vue           ← Chính sách cửa hàng
│   │   └── NotFoundView.vue         ← Custom 404 (animated lamp icon)
│   │
│   └── ADMIN VIEWS (AdminView.vue → layout sidebar + content)
│       ├── AdminDashboard.vue       ← Thống kê (Chart.js), Xuất Excel
│       │   └── AdminPendingOrders.vue ← Widget đơn chờ duyệt (expand items)
│       ├── AdminProducts.vue        ← CRUD SP, biến thể; giá cũ tùy chọn (API + form)
│       ├── AdminCategories.vue      ← Quản lý danh mục (cây phân cấp)
│       ├── AdminOrders.vue          ← Quản lý đơn hàng (filter, search, PTTT)
│       ├── AdminHotDeal.vue         ← Quản lý Hot Deal
│       ├── AdminCoupons.vue         ← Quản lý mã giảm giá
│       ├── AdminReviews.vue         ← Quản lý đánh giá
│       ├── AdminUsers.vue           ← Quản lý khách hàng + admin/staff
│       ├── AdminNews.vue            ← Quản lý tin tức (WYSIWYG editor)
│       ├── AdminPolicy.vue          ← CMS chính sách (bảo hành, đổi trả, vận chuyển, hướng dẫn)
│       └── AdminSettings.vue        ← Cài đặt website (logo, banner, ads, nén ảnh)
│
├── UI COMPONENTS
│   ├── ProductSkeleton.vue          ← Shimmer loading effect cho product grid
│   └── PriceInput.vue               ← Input giá tiền format VNĐ (1.234.567)
│
├── composables/
│   └── useMobileLayout.js           ← Breakpoint responsive (ProfileView)
│
└── utils/
    └── productPrice.js              ← Giá bán/gạch; nhãn 「Từ」 theo biến thể
```

### 2.2 State Management (Pinia)

```
┌──────────────────────────────────────────────────────┐
│                    PINIA STORES (3)                    │
├──────────────────────────────────────────────────────┤
│                                                      │
│  🔐 authStore                                        │
│  ├── user (id, name, role, token, permissions)       │
│  ├── isLoggedIn, isAdmin, isStaff, canAccessAdmin    │
│  ├── hasPermission(key)                              │
│  ├── login() / logout() / register()                 │
│  └── Persist: localStorage / sessionStorage          │
│                                                      │
│  🛒 cartStore                                        │
│  ├── items[] (id, name, price, quantity, variant)     │
│  ├── addToCart() / removeFromCart() / clearCart()     │
│  ├── Persist: localStorage (mọi khách)               │
│  ├── syncToServer() / hydrateFromServer() (customer) │
│  └── mergeAfterLogin() → cart.php (PUT/GET)          │
│                                                      │
│  ⚙️ settingsStore                                    │
│  ├── shop_name, hotline, email, address              │
│  ├── logo_url, banner_list[], bank_qr               │
│  ├── ads_left_url/link, ads_right_url/link          │
│  ├── ads_bottom_url/link                            │
│  └── fetchSettings() → Cache từ API                  │
│                                                      │
└──────────────────────────────────────────────────────┘
```

### 2.3 Utility Layer

```
utils/ (12 files)
├── format.js            ← formatPrice(), sanitizeNewsHtml(), checkIsNewArrival()
├── toast.js             ← toastSuccess(), toastWarning(), toastError()
├── useSEO.js            ← Dynamic meta tags (title, description, OG)
├── orderStatus.js       ← ORDER_STATUS_LABELS, getNextStatus(), canCancelStatus()
├── authStorage.js       ← getAuthStorage(), getStoredAuthUser(), clearStoredAuth()
├── chatMarkdown.js      ← renderSafeMarkdown(), formatChatPrice()
├── productPrice.js      ← resolveSalePrice, nhãn 「Từ」 theo biến thể
├── payosPending.js      ← sessionStorage pending PayOS orderId
├── sessionExpired.js    ← Handler 401 → logout + redirect login
├── promptAuthForPurchase.js ← Modal yêu cầu đăng nhập trước mua
└── (re-export từ services) productService.resolveSalePrice
```

### 2.4 API Service Layer

```
services/ (17 files)
├── httpClient.js        ← Axios instance + JWT interceptor + error handling
├── serviceErrors.js     ← Centralized error constants
├── authService.js       ← login(), register()
├── productService.js    ← getProducts(), getProductById(), getRelatedProducts(), ...
├── cartService.js       ← getCart(), syncCart(), clearServerCart()
├── orderService.js      ← createOrder(), getPendingPayosOrder(), retryPayosPayment(), cancelPendingOrder(), getPaymentStatus(), confirmOrderReceived(), ...
├── categoryService.js   ← getCategories(), createCategory(), ...
├── userService.js       ← getUsers(), updateUser(), toggleLock(), ...
├── couponService.js     ← getCoupons(), applyCoupon(), ...
├── reviewService.js     ← getReviews(), createReview(), replyReview(), ...
├── newsService.js       ← getNews(), getNewsBySlug(), ...
├── uploadService.js     ← uploadImage(), uploadMultiple(), ...
├── chatService.js       ← sendMessage()
├── statisticsService.js ← getStatistics(), getDashboardStats()
├── settingsService.js   ← getSettings(), updateSettings()
├── wishlistService.js   ← getWishlist(), toggleWishlist()
└── inventoryService.js  ← getHistory(), stockIn()
```

### 2.5 Route Protection (Navigation Guards)

```javascript
// router/index.js — beforeEach()

Khách (chưa login)──→ Trang public ✅
                    ─→ /admin/*    ✖ redirect /login
                    ─→ /profile    ✖ redirect /login

Customer ────────────→ Trang public ✅
                     ─→ /profile   ✅
                     ─→ /admin/*   ✖ redirect /

Admin/Staff ─────────→ Tất cả      ✅
                     ─→ /admin/*   ✅ (kiểm tra permissions)
```

---

## 3. Backend Architecture

### 3.1 Request Lifecycle

```
Client Request
      │
      ▼
┌─────────────────┐
│  Apache + CORS   │ ← db.php (PDO connection + CORS headers)
│  (db.php)        │
└────────┬────────┘
         │
┌────────▼────────┐
│  Rate Limiter    │ ← lib/rate_limit.php (IP-based, file-based)
│  (nếu có)        │
└────────┬────────┘
         │
┌────────▼────────┐
│  Auth Middleware  │ ← lib/auth_middleware.php
│  JWT Decode      │   requireLogin() / requireAdmin() / requireSuperAdmin()
└────────┬────────┘
         │
┌────────▼────────┐
│  Admin Guard     │ ← lib/admin_route_guard.php (RBAC permission check)
│  (nếu admin)     │   Map file/method → permission key
└────────┬────────┘
         │
┌────────▼────────┐
│  Input Validator  │ ← lib/validator.php
│  Sanitizer       │   validateOrder(), sanitizeInput(), sanitizeString()
└────────┬────────┘
         │
┌────────▼────────┐
│  Business Logic   │ ← products.php, orders.php, ...
│  Database Queries │   PDO Prepared Statements
└────────┬────────┘
         │
┌────────▼────────┐
│  JSON Response    │ ← {"success": true/false, "data": ..., "message": ...}
└─────────────────┘
```

### 3.2 File-based Routing

```
URL: POST /orders.php
           │
           ▼
denhoamy_api/orders.php     ← 1 file = 1 resource
    ├── GET    → Lấy danh sách
    ├── POST   → Tạo đơn hàng (transaction + lock tồn kho FOR UPDATE)
    ├── PUT    → Cập nhật trạng thái
    └── DELETE → Xóa (soft delete)
```

### 3.3 Middleware Stack

```php
// Mỗi endpoint PHP tự khai báo middleware cần dùng:

require_once 'db.php';                      // 1. Kết nối DB + CORS
require_once __DIR__ . '/lib/rate_limit.php';    // 2. Rate Limit (optional)
require_once __DIR__ . '/lib/auth_middleware.php'; // 3. JWT Auth
require_once __DIR__ . '/lib/validator.php';      // 4. Input Validation (optional)

checkNormalRateLimit();  // Apply rate limit
$user = requireAdmin();  // Xác thực + phân quyền
```

### 3.4 Middleware & Helper Library

```
lib/ (19 files)
├── auth_middleware.php       ← JWT decode, requireLogin(), requireAdmin(), requireSuperAdmin()
├── jwt_helper.php           ← JWT encode/decode (HMAC-SHA256, exp 24h)
├── admin_route_guard.php    ← RBAC: map file/method → permission key cho staff
├── validator.php            ← Centralized input validation + sanitize + payment/delivery combo
├── rate_limit.php           ← IP-based rate limiting (file-based counter)
├── order_pricing.php        ← normalizeOrderItems(), normalizeOrderItemsInTransaction() + FOR UPDATE
├── order_status.php         ← Order status machine: applyOrderStatus(), hoàn kho, hoàn coupon
├── order_email_helper.php   ← Email xác nhận đơn (Resend)
├── cart_helpers.php         ← cart.php: enrich items, replace cart rows
├── products_filters.php     ← type, exclude_id, pagination cho list SP
├── product_pricing.php      ← Giá bán/gạch, min variant price
├── hot_deal_snapshot.php    ← Snapshot/khôi phục giá Hot Deal
├── coupon_apply.php         ← applyCouponByCode(), tính chiết khấu
├── payos_helper.php         ← PayOS: createPaymentLink(), verifyWebhook(), cancelPaymentLink()
├── payos_order_helpers.php  ← pending PayOS, retry checkout, assert access
├── resend_helper.php        ← Email gửi Magic Link (Resend API)
├── password_reset_helper.php ← Tạo/verify token reset mật khẩu
├── logger.php               ← logInfo(), logWarning(), logException() + IP tracking
└── api_headers.php          ← CORS headers + API versioning
```

### 3.5 JWT Flow

```
┌──────────┐                    ┌───────────┐                   ┌─────────┐
│ Frontend  │                    │  Backend   │                   │   DB    │
└─────┬────┘                    └─────┬─────┘                   └────┬────┘
      │                               │                              │
      │ POST /auth.php                │                              │
      │ {username, password}          │                              │
      │──────────────────────────────▶│  SELECT * FROM users/admins  │
      │                               │─────────────────────────────▶│
      │                               │◀─────────────────────────────│
      │                               │                              │
      │                               │  password_verify() ✅        │
      │                               │  createCustomerToken()       │
      │                               │                              │
      │        {token: "eyJ..."}      │  JWT payload:                │
      │◀──────────────────────────────│  {sub: 5, role: "customer",  │
      │                               │   name: "Nguyễn",           │
      │  localStorage.setItem(token)  │   exp: +24h, table: "users"} │
      │                               │                              │
      │  GET /orders.php              │                              │
      │  Authorization: Bearer eyJ... │                              │
      │──────────────────────────────▶│                              │
      │                               │  parseAuthHeader()           │
      │                               │  jwtDecode() → verify sig   │
      │                               │  → check exp                │
      │                               │  → return {id, role, ...}   │
      │                               │                              │
      │        {success, data}        │                              │
      │◀──────────────────────────────│                              │
```

### 3.6 Cron Jobs — Tự động xử lý đơn hàng

```
Mỗi phút, cron trong Docker container chạy 2 job:

┌───────────────────────────────────────────────────┐
│  cron_cancel_orders.php                            │
│                                                   │
│  SELECT từ orders                                 │
│  WHERE status = 'pending'                         │
│    AND created_at < NOW() - 24 giờ                │
│                                                   │
│  Cho mỗi đơn quá hạn:                             │
│  1. Nếu PayOS → cancelPaymentLink() trên PayOS   │
│  2. Hoàn trả tồn kho (product + variant)          │
│  3. Hoàn lượt dùng coupon                         │
│  4. UPDATE status = 'cancelled'                   │
│     processed_by = 'system_cron'                  │
│                                                   │
│  Toàn bộ trong transaction → rollback nếu lỗi    │
└───────────────────────────────────────────────────┘

┌───────────────────────────────────────────────────┐
│  cron_progress_orders.php                          │
│                                                   │
│  Tự động tiến trạng thái đơn hàng:                │
│  1. approved → shipping                           │
│     sau ORDER_APPROVED_TO_SHIPPING_HOURS           │
│  2. shipping → completed                          │
│     sau ORDER_SHIPPING_TO_COMPLETED_DAYS           │
│                                                   │
│  Sử dụng applyOrderStatus() từ order_status.php  │
│  Toàn bộ trong transaction → rollback nếu lỗi    │
└───────────────────────────────────────────────────┘
```

---

## 4. Luồng Dữ Liệu Chính

### 4.1 Đặt hàng (Order Flow)

```
Customer chọn SP + Thêm giỏ hàng
        │
        ▼
Checkout: chọn giao hàng (home) hoặc nhận tại shop (store)
        │
        ├─── home + COD ───────────────────────────▶ Tạo đơn (pending) + email xác nhận
        │
        ├─── home + Bank Transfer ─────────────────▶ Tạo đơn (pending)
        │
        ├─── store + pay_at_store ─────────────────▶ Tạo đơn (pending) + email xác nhận
        │
        └─── PayOS (home hoặc store) ──▶ Kiểm tra pending_payos (409 nếu trùng)
                                              │
                                        Tạo đơn (pending) ──▶ createPaymentLink()
                                              │
                                        ┌─────▼──────┐
                                        │ PayOS Page  │ ← Redirect
                                        └─────┬──────┘
                                              │
                              ┌───────────────┼───────────────┐
                              ▼               ▼               ▼
                        Thanh toán OK   Cancel redirect   retry_payos /
                              │               │           cancel_pending
                        Webhook POST          │               │
                        code = "00"           ▼               ▼
                              │         PaymentResultView   Hoàn kho
                        orders.status =     poll status
                        "approved"
```

### 4.2 Order Status Machine

```
pending ──→ approved ──→ shipping ──→ completed
   │            │            │              ▲
   │            │            └─ confirm_received (customer)
   └────────────┴────────────┘
                │
          → cancelled (hoàn kho + hoàn coupon)

Cron tự động tiến trạng thái:
  approved → shipping (sau N giờ)
  shipping → completed (sau N ngày)
  pending  → cancelled (sau 24h, chỉ cron_cancel)
```

### 4.3 AI Chatbot Flow

```
Khách gửi tin nhắn
        │
        ▼
chatbot_engine.php
        │
        ├── 1. Kiểm tra API keys → chọn engine
        │
        ├── 2. Build system prompt + chat history + context
        │
        ├── 3. Gọi Groq API (LLaMA 4 Scout)
        │       │
        │       ├── finish_reason: "tool_calls"
        │       │       │
        │       │       ▼ Execute tool locally
        │       │   ┌─────────────────────────────┐
        │       │   │ search_products($pdo, args)  │ ← Query MySQL thực tế
        │       │   │ get_product_specs($pdo, kw)  │
        │       │   │ list_product_types($pdo)     │
        │       │   │ get_store_faq(topic)         │
        │       │   └─────────────────────────────┘
        │       │       │
        │       │       ▼ Gửi tool result → Groq lần 2
        │       │       → Trả lời tự nhiên có data thật
        │       │
        │       ├── finish_reason: "stop" → Trả lời trực tiếp
        │       │
        │       └── Error / Rate limit → Fallback ↓
        │
        ├── 4. Rate limit → retry Groq 1 lần (2s)
        │
        └── 5. Fallback: Rule-based (regex + context SP → DB query / FAQ)
                │
                ▼
        JSON Response: { reply, products[] }
```

---

## 5. Security Architecture

### 5.1 Defense in Depth

```
┌─────────────────────────────────────────────────────┐
│                    LAYER 1: NETWORK                  │
│  CORS Whitelist │ Rate Limiting │ HTTPS (production) │
├─────────────────────────────────────────────────────┤
│                    LAYER 2: AUTH                     │
│  JWT HMAC-SHA256 │ Token Expiration │ RBAC 3-tier   │
├─────────────────────────────────────────────────────┤
│                    LAYER 3: ADMIN GUARD              │
│  admin_route_guard.php │ Permission map per endpoint │
├─────────────────────────────────────────────────────┤
│                    LAYER 4: INPUT                    │
│  Centralized Validator │ sanitizeString() │ Type Cast│
├─────────────────────────────────────────────────────┤
│                    LAYER 5: DATABASE                 │
│  Prepared Statements │ EMULATE_PREPARES=false       │
│  Parameterized Queries │ No string concatenation    │
├─────────────────────────────────────────────────────┤
│                    LAYER 6: FILE                     │
│  MIME Validation (finfo) │ Size Limit │ Unique Name │
├─────────────────────────────────────────────────────┤
│                    LAYER 7: LOGGING                  │
│  logInfo/logWarning/logException │ IP tracking      │
└─────────────────────────────────────────────────────┘
```

### 5.2 Password Security

```
Registration                         Login
     │                                  │
     ▼                                  ▼
password_hash($pw, PASSWORD_DEFAULT)   password_verify($pw, $hash)
     │                                  │
     ▼                                  ▼
bcrypt hash (auto salt)               TRUE/FALSE
"$2y$10$xKL3..."                      │
     │                                  ├── TRUE → createToken()
     ▼                                  └── FALSE → 401
Store in DB
```

### 5.3 PayOS Webhook Security

```
PayOS Server ──POST──▶ payos_webhook.php
                              │
                     1. Đọc raw body
                     2. verifyWebhookSignature()
                        │
                        ├── Tính HMAC-SHA256 từ data fields
                        ├── So sánh với signature trong payload
                        │
                        ├── Match ✅ → Xử lý đơn hàng
                        └── Mismatch ✖ → 400 Bad Request (log warning)
```

---

## 6. Performance Considerations

### 6.1 Database Optimization

| Kỹ thuật | Áp dụng |
|---|---|
| **Indexes** | `ma_san_pham` (UNIQUE), `slug` (UNIQUE), FK columns, `token_hash`, `session_token` |
| **Soft Delete** | `deleted_at IS NULL` trong WHERE clause (products, orders, news) |
| **Eager Loading** | Products list → batch load variants + images (không N+1) |
| **Pagination** | Server-side: `LIMIT ? OFFSET ?` |
| **Prepared Statements** | Tái sử dụng cho batch operations |

### 6.2 Frontend Optimization

| Kỹ thuật | Áp dụng |
|---|---|
| **Vite Build** | Tree-shaking, code splitting, minification |
| **Nginx Gzip** | Nén tĩnh HTML/CSS/JS |
| **Lazy Loading** | Route-based code splitting |
| **Skeleton Loading** | ProductSkeleton shimmer effect khi chờ data |
| **Responsive** | Mobile-first: Cart cards, Profile grid, hamburger menu, breadcrumb collapse |
| **Product pricing UI** | `productPrice.js`: 「Từ min」 khi biến thể giá khác nhau; giá gạch chỉ khi `old_price` > giá bán |
| **Sticky Navbar** | Glassmorphism khi cuộn (backdrop-filter blur), hiện Cart/Account |
| **Image Compression** | Client-side Canvas nén ảnh > 500KB trước khi upload (quality 0.82) |
| **Banner Ad System** | 3 vị trí QC: skyscraper dọc (trái/phải), horizontal (dưới Hot Deal) |
| **Checkout Guard** | onBeforeRouteLeave + beforeunload chống mất dữ liệu |
| **Excel Export** | Dynamic import xlsx module + requestIdleCallback prefetch |
| **HTML Sanitize** | sanitizeNewsHtml() loại bỏ đoạn trống/ảnh lỗi từ WYSIWYG editor |
| **Image** | Upload resize, WebP support |
| **State Persist** | localStorage cache → giảm API calls |
| **Admin order poll** | `AdminView`: `GET orders.php` mỗi 5s (tab visible); toast khi `pending` tăng — HTTP, không WebSocket |

### 6.3 Luồng tạo đơn (khóa tồn kho)

```
POST /orders.php
    → beginTransaction()
    → normalizeOrderItemsInTransaction()  // SELECT … FOR UPDATE từng SKU
    → applyCoupon (coupon row FOR UPDATE nếu có mã)
    → INSERT order + order_items
    → UPDATE stock = stock - qty
    → commit
```

---

## 7. Deployment

### 7.1 Development

```bash
docker-compose up -d --build
```

### 7.2 Production Checklist

| # | Hạng mục | Thực hiện |
|---|---|---|
| 1 | HTTPS (SSL/TLS) | Reverse proxy: Nginx hoặc Caddy |
| 2 | `.env` security | Không commit, dùng `.env.example` |
| 3 | DB credentials | Đổi password mặc định |
| 4 | JWT secret | Rotational, strong random string |
| 5 | CORS origins | Whitelist domain cụ thể |
| 6 | Log rotation | Cấu hình logrotate cho error logs |
| 7 | Backup | mysqldump cron daily |
| 8 | Monitoring | Health check endpoint |
