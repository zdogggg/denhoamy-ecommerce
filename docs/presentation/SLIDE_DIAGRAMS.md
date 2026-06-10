# Sơ đồ cho Slide — Đèn Hoa Mỹ

> Export: dán Mermaid vào [mermaid.live](https://mermaid.live) hoặc draw.io, xuất PNG/SVG cho PowerPoint.  
> Gắn vào slide theo cột **Slide** bên dưới.

---

## D1 — Kiến trúc 3-tier (Slide 13)

```mermaid
flowchart TB
  subgraph client [Client]
    Browser[Browser]
  end
  subgraph docker [DockerHost]
    Frontend["Vue3_SPA\nNginx :3000"]
    API["PHP82_API\nApache :8080"]
    DB["MySQL8\n:3307"]
    PMA[phpMyAdmin :8081]
  end
  subgraph external [ThirdParty]
    Groq[Groq_LLaMA4]
    PayOS[PayOS]
    Resend[Resend_Email]
  end
  Browser -->|HTTPS_JSON| Frontend
  Frontend -->|REST_API| API
  API -->|PDO| DB
  API --> Groq
  API --> PayOS
  API --> Resend
  PMA --> DB
```

---

## D2 — Docker Compose services (Slide 14)

```mermaid
flowchart LR
  frontend[frontend_Nginx_Vue]
  api[api_PHP_Apache_Cron]
  db[db_MySQL]
  pma[phpmyadmin]
  frontend -->|depends_on| api
  api -->|depends_on_healthcheck| db
  pma --> db
```

---

## D3 — Request lifecycle Backend (Slide 18)

```mermaid
flowchart TD
  req[ClientRequest] --> cors[CORS_db.php]
  cors --> rate[RateLimiter]
  rate --> auth[JWT_AuthMiddleware]
  auth --> guard[AdminRouteGuard]
  guard --> valid[InputValidator]
  valid --> biz[BusinessLogic_PDO]
  biz --> json[JSON_Response]
```

---

## D4 — Giỏ hàng & đồng bộ (Slide 23)

```mermaid
flowchart LR
  guest[Guest] -->|localStorage| cartLocal[CartLocal]
  customer[CustomerLoggedIn] -->|Pinia| cartStore[CartStore]
  cartStore -->|GET_PUT| cartApi[cart.php]
  loginEvent[Login] -->|mergeAfterLogin| cartApi
  cartApi --> mysql[(cart_items)]
```

---

## D5 — Luồng đặt hàng & PayOS (Slide 24–25)

```mermaid
flowchart TD
  start[CustomerCheckout] --> delivery{deliveryMethod}
  delivery -->|home| pttm1[COD_or_PayOS]
  delivery -->|store| pttm2[pay_at_store_or_PayOS]
  pttm1 --> createOrder[POST_orders.php]
  pttm2 --> createOrder
  createOrder --> lockStock[Transaction_FOR_UPDATE]
  lockStock --> payChoice{payment}SLIDE — TRIỂN KHAI PRODUCTION
  Tiêu đề gợi ý
  TRIỂN KHAI HỆ THỐNG LÊN SERVER PUBLIC
  
  Phần: Cài đặt & Demo / Kết luận
  
  Dòng mở:
  
  Sau khi phát triển local bằng Docker, hệ thống được đưa lên VPS INET — gắn domain, bật HTTPS Let's Encrypt, chạy public cho khách truy cập thật.
  
  Layout gợi ý: Trái = 5 bước | Phải = sơ đồ kiến trúc
  5 BƯỚC TRIỂN KHAI (nội dung chính slide)
  ① Thuê hạ tầng & chuẩn bị server
  Mục đích: Có máy chủ Linux ổn định, đủ tài nguyên chạy Docker stack.
  
  Hạng mục	Cấu hình thực tế
  Nhà cung cấp
  INET — Cloud Server
  Quản trị
  CloudPanel (quản lý site, SSL, reverse proxy)
  OS
  Ubuntu 24.04 LTS
  CPU / RAM / Disk
  2 vCPU · 3 GB RAM · SSD 30 GB
  Cài đặt trên VPS:
  
  Docker + Docker Compose
  Git (clone/pull mã nguồn)
  Mở port 80, 443 (HTTP/HTTPS)
  3 GB RAM đủ cho 4 container: frontend, API, MySQL, phpMyAdmin — phù hợp quy mô shop vừa.
  
  ② Đăng ký domain & trỏ DNS (INET)
  Mục đích: Khách truy cập bằng tên miền thay vì IP.
  
  Mua domain tại INET (vd: denhoamy.store)
  Trỏ A record → IP VPS
  (Tuỳ chọn) www → cùng IP hoặc CNAME
  Kết quả: https://denhoamy.store trỏ về server production.
  
  ③ Cấu hình HTTPS — Let's Encrypt
  Mục đích: Mã hóa kết nối — bắt buộc cho PayOS webhook, reset mật khẩu, niềm tin khách hàng.
  
  Tạo site trên CloudPanel
  Bật SSL Let's Encrypt (miễn phí, auto-renew)
  CloudPanel Nginx làm reverse proxy:
  443 HTTPS → container frontend (127.0.0.1:3000)
  API public qua path hoặc subdomain (vd: / proxy hoặc api.domain)
  Production: FRONTEND_URL=https://denhoamy.store trong .env — PayOS return URL, email magic link dùng domain HTTPS.
  
  ④ Deploy ứng dụng bằng Docker
  Mục đích: Môi trường production giống local — một lệnh khởi chạy toàn stack.
  
  git clone <repo> /root/denhoamy-ecommerce
  cd /root/denhoamy-ecommerce
  cp .env.example .env   # chỉnh secret production
  docker compose up -d --build
  4 container chạy trên VPS:
  
  Container	Vai trò	Port nội bộ
  denhoamy_frontend
  Vue 3 build + Nginx
  127.0.0.1:3000
  denhoamy_api
  PHP 8.2 + Apache
  127.0.0.1:8080
  denhoamy_db
  MySQL 8.0
  nội bộ Docker
  denhoamy_pma
  phpMyAdmin (quản trị DB)
  8081
  DB init từ denhoamy_db.sql (21 bảng)
  Upload ảnh mount volume denhoamy_api/uploads/
  Cron trong container API: hủy đơn pending 24h, tự động tiến trạng thái đơn
  ⑤ Cấu hình production & kiểm tra
  Mục đích: Đảm bảo tích hợp bên thứ 3 và bảo mật hoạt động trên môi trường thật.
  
  Hạng mục	Việc cần làm
  .env
  Đổi JWT_SECRET, mật khẩu DB mạnh
  FRONTEND_URL
  https://domain-của-bạn
  PayOS
  Webhook URL public: https://.../payos_webhook.php
  Resend
  Verify domain, RESEND_FROM_EMAIL
  Groq
  GROQ_API_KEY production
  Backup
  mysqldump trước mỗi lần git pull
  Smoke test sau deploy:
  
  Trang chủ load HTTPS
  Admin login
  Đặt thử COD → toast đơn mới (~5s poll)
  (Tuỳ chọn) PayOS sandbox → /payment/success
  Cập nhật phiên bản:
  
  git pull origin main && docker compose up -d --build
  payChoice -->|COD_pay_at_store| pending[pending_email]
  payChoice -->|PayOS| checkPending{pending_payos?}
  checkPending -->|409| block[BlockDuplicate]
  checkPending -->|ok| payosLink[createPaymentLink]
  payosLink --> redirect[PayOS_Page]
  redirect -->|success| webhook[payos_webhook.php]
  redirect -->|cancel| pollUI[PaymentResultView_poll]
  webhook --> approved[status_approved]
```

---

## D6 — Order status machine (Slide 27)

```mermaid
stateDiagram-v2
  [*] --> pending
  pending --> approved: admin_approve_or_PayOS_webhook
  pending --> cancelled: admin_cancel_or_cron_24h
  approved --> shipping: admin_or_cron_auto
  shipping --> completed: cron_auto_or_confirm_received
  approved --> cancelled: admin_cancel
  shipping --> cancelled: admin_cancel
  completed --> [*]
  cancelled --> [*]
```

---

## D7 — JWT authentication flow (Appendix A1)

```mermaid
sequenceDiagram
  participant FE as Frontend
  participant API as auth.php
  participant DB as MySQL
  FE->>API: POST username password
  API->>DB: SELECT users
  DB-->>API: user row
  API->>API: password_verify bcrypt
  API->>API: createToken HMAC_SHA256 exp24h
  API-->>FE: token JWT
  FE->>FE: localStorage token
  FE->>API: GET orders Authorization Bearer
  API->>API: jwtDecode verify exp
  API-->>FE: success data
```

---

## D8 — AI Chatbot flow (Slide 30)

```mermaid
flowchart TD
  msg[UserMessage] --> engine[chatbot_engine.php]
  engine --> groq[Groq_LLaMA4_Scout]
  groq -->|tool_calls| tools[ExecuteToolsLocally]
  tools --> search[search_products]
  tools --> specs[get_product_specs]
  tools --> types[list_product_types]
  tools --> faq[get_store_faq]
  search --> mysql[(MySQL)]
  specs --> mysql
  tools --> groq2[SecondGroqCall]
  groq2 --> reply[NaturalReply]
  groq -->|error_rate_limit| fallback[RuleBased_FAQ_DB]
  fallback --> reply
  reply --> jsonOut[JSON reply products]
```

---

## D9 — ERD rút gọn (Slide 16)

```mermaid
erDiagram
  categories ||--o{ products : phan_loai
  categories ||--o{ categories : cha_con
  products ||--o{ product_variants : bien_the
  products ||--o{ product_images : gallery
  products ||--o{ order_items : ban_ra
  users ||--o{ orders : dat_hang
  orders ||--o{ order_items : chi_tiet
  users ||--o{ carts : gio_hang
  carts ||--o{ cart_items : items
  users ||--o{ wishlists : yeu_thich
  products ||--o{ reviews : danh_gia
```

---

## D10 — RBAC 3 cấp (Slide 29)

```mermaid
flowchart TB
  admin[Admin_full_access]
  staff[Staff_limited_permissions]
  customer[Customer_public_profile]
  admin --> allModules[All_11_admin_modules]
  staff --> permMap[admin_route_guard.php]
  permMap --> mod1[products]
  permMap --> mod2[orders]
  permMap --> modN[settings_etc]
  customer --> shop[Shop_checkout_profile]
```

---

## D11 — Bảo mật 7 lớp (Slide 19)

```mermaid
flowchart TB
  L1[L1_Network_CORS_RateLimit_HTTPS]
  L2[L2_Auth_JWT_expiration]
  L3[L3_RBAC_admin_route_guard]
  L4[L4_Input_validator_sanitize]
  L5[L5_DB_prepared_statements]
  L6[L6_File_MIME_size_limit]
  L7[L7_Logging_IP_tracking]
  L1 --> L2 --> L3 --> L4 --> L5 --> L6 --> L7
```

---

## D12 — Use case tổng quan (Slide 10)

```mermaid
flowchart LR
  subgraph actors [Actors]
    KH[KhachHang]
    AD[Admin_Staff]
    HT[HeThong_Cron_PayOS_Groq]
  end
  subgraph system [HeThong_DenHoaMy]
    UC1[MuaHang_ThanhToan]
    UC2[QuanTri_SP_Don]
    UC3[Chatbot_TuVan]
    UC4[TuDongDonHang]
  end
  KH --> UC1
  KH --> UC3
  AD --> UC2
  HT --> UC4
```

---

## D13 — Giải pháp đề xuất — luồng hệ thống (Slide 9+)

> Dùng cho slide **GIẢI PHÁP ĐỀ XUẤT** (cột phải). Export PNG dọc, tông vàng/đen/trắng.

```mermaid
flowchart TB
  KH["Khách hàng"]
  WEB["Website TMĐT\n(Vue 3 SPA)"]
  BOT["Chatbot AI\n(Groq — tích hợp trên web)"]
  API["Backend API\n(PHP 8.2 REST)"]
  DB[("MySQL\n21 bảng")]
  ADMIN["Hệ thống quản trị\n(Admin / Staff)"]
  PAY["PayOS\n(thanh toán online)"]

  KH --> WEB
  WEB -.->|tư vấn bất cứ lúc nào| BOT
  BOT --> API
  WEB -->|mua hàng checkout| API
  API <-->|PDO| DB
  API --> ADMIN
  API <-->|webhook HMAC| PAY
  PAY -.->|xác nhận TT| API

  style KH fill:#1a365d,color:#fff
  style WEB fill:#c9a227,color:#1a1a1a
  style BOT fill:#f5f0e6,color:#1a1a1a,stroke:#c9a227
  style API fill:#2d3748,color:#fff
  style DB fill:#4a5568,color:#fff
  style ADMIN fill:#1a365d,color:#fff
  style PAY fill:#f5f0e6,color:#1a1a1a,stroke:#c9a227
```

**Phiên bản rút gọn** (nếu slide chật, chỉ 4 box dọc):

```mermaid
flowchart TB
  KH[Khách hàng]
  WEB["Website TMĐT\n+ Chatbot AI"]
  CORE["Backend API + MySQL"]
  ADMIN[Hệ thống quản trị]
  PAY[PayOS]

  KH --> WEB --> CORE --> ADMIN
  CORE <--> PAY

  style KH fill:#1a365d,color:#fff
  style WEB fill:#c9a227,color:#1a1a1a
  style CORE fill:#2d3748,color:#fff
  style ADMIN fill:#1a365d,color:#fff
  style PAY fill:#f5f0e6,color:#1a1a1a,stroke:#c9a227
```
