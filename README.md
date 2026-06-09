<p align="center">
  <h1 align="center">ĐÈN HOA MỸ — E-Commerce Platform</h1>
  <p align="center">
    <strong>Hệ thống thương mại điện tử chuyên đèn trang trí nội thất cao cấp</strong>
  </p>
  <p align="center">
    Vue 3 · PHP 8.2 · MySQL 8.0 · Docker · AI Chatbot
  </p>
</p>

---

## Giới Thiệu

**Đèn Hoa Mỹ** là nền tảng thương mại điện tử fullstack được xây dựng cho cửa hàng đèn trang trí tại Hải Phòng. Hệ thống cung cấp:

- **Thanh toán đa kênh** — COD, PayOS online, nhận tại cửa hàng (`pay_at_store`); giao hàng hoặc pickup tại shop
- **PayOS an toàn** — Chặn đơn pending trùng, retry/hủy link, poll trạng thái sau redirect
- **AI Chatbot thông minh** — Tư vấn sản phẩm bằng LLaMA 4 (Groq) với Function Calling truy vấn kho thực tế
- **Admin Dashboard toàn diện** — Quản lý sản phẩm, đơn hàng, khách hàng, thống kê doanh thu
- **Bảo mật production-grade** — JWT + RBAC + Rate Limiting + Input Validation
- **Đặt hàng an toàn tồn kho** — Transaction + pessimistic lock (`FOR UPDATE`) khi tạo đơn
- **Giỏ hàng đồng bộ DB** — Customer đăng nhập: `cart.php` + merge khi login
- **Admin cập nhật đơn** — Polling 5s + thông báo đơn `pending` mới (HTTP, chưa WebSocket)
- **Docker one-command deploy** — Khởi chạy toàn bộ hệ thống bằng 1 lệnh duy nhất

---

## Tech Stack

### Frontend
| Công nghệ | Phiên bản | Vai trò |
|---|---|---|
| **Vue.js** | 3.5 | UI Framework (Composition API) |
| **Vite** | 8.0 | Build tool + Dev server |
| **Pinia** | 3.0 | State Management |
| **Vue Router** | 4.6 | Client-side routing + Guards |
| **Element Plus** | 2.13 | UI Component Library |
| **Axios** | 1.13 | HTTP Client + Interceptors |
| **Chart.js** | 4.5 | Biểu đồ thống kê Dashboard |
| **Marked + DOMPurify** | - | Markdown rendering (Chatbot) |

### Backend
| Công nghệ | Phiên bản | Vai trò |
|---|---|---|
| **PHP** | 8.2 | API Server (Apache) |
| **MySQL** | 8.0 | Relational Database |
| **JWT** | Custom HMAC-SHA256 | Authentication |
| **Groq API** | LLaMA 4 Scout | AI Chatbot (tool calling + tra kho) |
| **PayOS** | - | Online Payment Gateway |
| **Resend** | - | Transactional Email (Magic Link) |

### DevOps
| Công nghệ | Vai trò |
|---|---|
| **Docker Compose** | Container orchestration (4 services) |
| **Nginx** | Frontend reverse proxy |
| **Apache** | Backend web server |
| **Cron** | Tự động hủy đơn pending quá 24h + Tự động tiến trạng thái đơn |

---

## Kiến Trúc Hệ Thống

```
┌─────────────────────────────────────────────────────────────────┐
│                        CLIENT (Browser)                         │
└───────────────────────────────┬─────────────────────────────────┘
                                │
                    ┌───────────▼───────────┐
                    │   Vue 3 SPA (Nginx)   │ ← Port 3000
                    │  Pinia · Router · EP  │
                    └───────────┬───────────┘
                                │ RESTful API (JSON)
                    ┌───────────▼───────────┐
                    │  PHP 8.2 API (Apache) │ ← Port 8080
                    │  JWT · RBAC · Validator│
                    ├───────────────────────┤
                    │    lib/ (Middleware)   │
                    │  ┌─────┬─────┬─────┐  │
                    │  │Auth │Rate │Valid.│  │
                    │  │MW   │Limit│ator │  │
                    │  └─────┴─────┴─────┘  │
                    └───┬───────┬───────┬───┘
                        │       │       │
               ┌────────▼┐  ┌──▼──┐  ┌─▼────────┐
               │ MySQL 8 │  │Groq │  │  PayOS   │
               │(21 bảng)│  │ API │  │ Payment  │
               │Port 3307│  └──┬──┘  └──────────┘
               └─────────┘     │
                          ┌────▼────┐
                          │  Rule-  │ (Fallback)
                          │  Based  │
                          └─────────┘
```

---

## Tính Năng

### Khách Hàng (Customer)

| Tính năng | Mô tả |
|---|---|
| Trang chủ | Banner carousel, Banner QC dọc (trái/phải), Banner ngang, Danh mục icon, Hot Deals, Sản phẩm mới (slider), Khám phá bộ sưu tập |
| Navbar | Sticky + Glassmorphism khi cuộn, hiện Cart/Account trên navbar, dynamic category menu |
| Danh mục | Filter loại đèn, phong cách / Tìm kiếm / Sắp xếp giá / Phân trang / Skeleton loading |
| Chi tiết sản phẩm | Gallery, biến thể, đánh giá, tag "Hàng mới về", **sản phẩm liên quan**; giá thẻ danh mục: **「Từ」** nếu biến thể giá khác nhau |
| Giỏ hàng | Pinia + `localStorage`; customer đăng nhập đồng bộ `cart.php` (merge khi login) |
| Thanh toán | Checkout (**đăng nhập bắt buộc**): giao hàng/nhận tại shop; PTTT COD/PayOS/`pay_at_store`; coupon; dialog đơn PayOS pending |
| Kết quả PayOS | `/payment/success` & `/payment/cancel` — poll API, retry thanh toán, xóa giỏ khi paid |
| Mã giảm giá | Dialog chọn coupon, nhập mã → validate → tự động tính chiết khấu |
| Tài khoản | Đăng ký/Đăng nhập, hồ sơ + lịch sử đơn + wishlist + **xác nhận đã nhận hàng** — responsive mobile |
| Chính sách | Trang `/policy` (CMS 4 mục: bảo hành, đổi trả, vận chuyển, hướng dẫn) |
| Quên mật khẩu | Magic Link gửi qua email (Resend API) |
| Yêu thích | Lưu sản phẩm yêu thích (Wishlist) |
| AI Chatbot | Tư vấn sản phẩm, tra cứu giá/tồn kho, FAQ cửa hàng |
| Trang 404 | Custom animated 404 page với hiệu ứng đèn trang trí |
| Tin tức | Blog/bài viết, SEO-friendly slug URL, sanitize HTML content |

### Quản Trị (Admin Dashboard)

| Module | Chức năng |
|---|---|
| Dashboard | Biểu đồ doanh thu (Chart.js), Top SP bán chạy, SP sắp hết hàng (search + paginate), Lợi nhuận, Xuất Excel |
| Sản phẩm | CRUD + Import Excel, Gallery, Biến thể, Giá nhập; **giá cũ (gạch)** tùy chọn — không tự bằng giá bán |
| Danh mục | Cây phân cấp (cha/con), Drag sort |
| Đơn hàng | Filter/Search, trạng thái 5 bước, hoàn kho khi hủy; **poll đơn mới 5s** + toast khi có `pending` |
| Hot Deal | Chọn SP nổi bật, Sửa giá nhanh |
| Mã giảm giá | CRUD, Giới hạn lượt dùng, Thời gian hiệu lực |
| Đánh giá | Duyệt/Từ chối, Trả lời khách hàng |
| Tin tức | CRUD bài viết, WYSIWYG editor (Quill), sanitize HTML |
| Chính sách | CMS HTML 4 tab (`AdminPolicy.vue`) → keys `policy_*` |
| Khách hàng | Danh sách, Khóa/Mở khóa tài khoản |
| Tài khoản | Quản lý Admin/Staff, Phân quyền chi tiết (11 module) |
| Cài đặt | Logo, Banner carousel (tối đa 6), Banner QC dọc (trái/phải), Banner ngang, Hotline, Email, QR, Nén ảnh client-side |

### AI Chatbot — Groq + Rule-based

```
Khách hàng gửi tin nhắn
        │
        ▼
   ┌─────────┐     ┌───────────┐
   │  Groq   │────▶│ Rule-Based│
   │ LLaMA 4 │fail │ + DB/FAQ  │
   │ +Tools  │     │ Matching  │
   └─────────┘     └───────────┘
        │
        ▼ Function Calling
   ┌─────────────┐
   │ search_products     → Tìm SP theo keyword, giá, loại
   │ get_product_specs   → Chi tiết 1 SP cụ thể
   │ list_product_types  → Liệt kê loại đèn
   │ get_store_faq       → FAQ: ship, bảo hành, giờ mở cửa
   └─────────────┘
```

### Bảo Mật

| Layer | Cơ chế |
|---|---|
| Authentication | JWT (HMAC-SHA256) với token expiration |
| Authorization | RBAC 3 cấp: Admin → Staff → Customer |
| Admin Guard | `admin_route_guard.php` map endpoint → permission key |
| Rate Limiting | 5/phút (login), 120/phút (API), riêng (chatbot) |
| Input Validation | Centralized validator: sanitize + validate mọi input |
| SQL Injection | Prepared Statements + `EMULATE_PREPARES = false` |
| XSS | `sanitizeString()` strip HTML tags |
| Password | `password_hash()` + `password_verify()` (bcrypt) |
| CORS | Whitelist origins cụ thể |
| File Upload | MIME type validation (finfo), Size limit 10MB |

---

## Khởi Chạy

### Yêu cầu
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (bắt buộc)
- [Node.js](https://nodejs.org/) (nếu muốn dev frontend)

### 1 lệnh duy nhất

```bash
docker-compose up -d --build
```

### Truy cập

| Dịch vụ | URL | Mô tả |
|---|---|---|
| Website | http://localhost:3000 | Giao diện khách hàng |
| Admin | http://localhost:3000/admin | Dashboard quản trị |
| API | http://localhost:8080 | Backend REST API |
| phpMyAdmin | http://localhost:8081 | Quản lý Database |

### Tài khoản mặc định

| Loại | Username | Password |
|---|---|---|
| Admin | `admin` | `123456` |
| Database | `root` | `root123` |

> Chi tiết cài đặt: xem [README_SETUP.md](README_SETUP.md)

---

## Cấu Trúc Dự Án

```
denhoamy-ecommerce/
│
├── docker-compose.yml          ← Orchestration (4 containers)
├── denhoamy_db.sql             ← Dump DB chính (21 bảng, init Docker)
├── database.sql                ← Schema cũ (tham chiếu)
├── .env                        ← Environment variables
│
├── my-vue-app/                 ← FRONTEND (Vue 3)
│   ├── src/
│   │   ├── views/        (17)     ← Pages + Admin shell
│   │   ├── components/   (19)     ← Admin modules (12) + Layout (4) + UI (3)
│   │   ├── services/     (17)     ← API layer (Axios)
│   │   ├── stores/       (3)      ← Pinia: Auth, Cart, Settings
│   │   ├── utils/        (12)     ← PayOS pending, session, SEO, format, ...
│   │   ├── composables/           ← useMobileLayout
│   │   ├── router/                ← Route config + Guards
│   │   └── App.vue + main.js
│   ├── docs/VIEWS_MAP.md          ← Bản đồ views/components
│   ├── Dockerfile                 ← Nginx production build
│   └── package.json
│
├── scripts/                    ← Smoke / E2E helpers
│   ├── payos_e2e_test.php         ← PayOS API flow test
│   └── phase2-smoke.mjs           ← Frontend logic smoke (Node)
│
├── denhoamy_api/               ← BACKEND (PHP 8.2)
│   ├── auth.php                ← Login / Register
│   ├── products.php            ← CRUD sản phẩm
│   ├── orders.php              ← CRUD đơn hàng + PayOS
│   ├── categories.php          ← CRUD danh mục
│   ├── users.php               ← Quản lý user + admin
│   ├── coupons.php             ← Mã giảm giá
│   ├── reviews.php             ← Đánh giá sản phẩm
│   ├── news.php                ← Tin tức / Blog
│   ├── chatbot_engine.php      ← AI Chatbot (Groq + Rule-based)
│   ├── upload.php              ← Upload ảnh (MIME validate, nén)
│   ├── statistics.php          ← Thống kê Dashboard
│   ├── settings.php            ← Cài đặt website
│   ├── wishlist.php            ← Yêu thích
│   ├── cart.php                ← Giỏ hàng (customer, đồng bộ DB)
│   ├── inventory.php           ← Quản lý kho
│   ├── forgot-password.php     ← Quên mật khẩu
│   ├── payos_webhook.php       ← PayOS callback
│   ├── cron_cancel_orders.php  ← Cron: tự động hủy đơn pending >24h
│   ├── cron_progress_orders.php← Cron: tự động tiến trạng thái đơn
│   ├── API_DOCUMENTATION.md    ← Tài liệu API đầy đủ
│   ├── tests/                     ← Smoke: order_status, order_stock
│   ├── lib/                       ← Middleware & Helpers
│   │   ├── order_pricing.php      ← Chuẩn hóa giá đơn + lock tồn kho
│   │   ├── payos_order_helpers.php← PayOS pending / retry / cancel
│   │   ├── hot_deal_snapshot.php  ← Snapshot giá Hot Deal
│   │   ├── order_email_helper.php ← Email xác nhận đơn (Resend)
│   │   ├── cart_helpers.php       ← Giỏ hàng server-side
│   │   ├── coupon_apply.php       ← Áp mã giảm giá
│   │   ├── product_pricing.php    ← Giá bán/gạch, variant min
│   │   ├── products_filters.php   ← Filter danh sách SP
│   │   ├── auth_middleware.php    ← JWT + RBAC
│   │   ├── admin_route_guard.php  ← Permission mapping cho staff
│   │   ├── jwt_helper.php        ← JWT encode/decode (24h)
│   │   ├── validator.php         ← Input validation + delivery/PTTT combo
│   │   ├── rate_limit.php        ← Rate limiting
│   │   ├── order_status.php      ← Order status machine + hoàn kho/coupon
│   │   ├── payos_helper.php      ← PayOS integration
│   │   ├── resend_helper.php     ← Email (Resend)
│   │   ├── password_reset_helper.php
│   │   ├── logger.php            ← Centralized logging
│   │   └── api_headers.php       ← CORS + versioning
│   ├── Dockerfile                 ← Apache + Cron
│   └── uploads/                   ← Ảnh sản phẩm, logo, banner...
│
└── mysql/                      ← DB config + migrations
    ├── my.cnf
    ├── migrate_index_softdelete.sql
    ├── migrate_order_delivery_method.sql
    ├── migrate_pay_at_store.sql
    ├── migrate_hot_deal_price_snapshot.sql
    ├── migrate_inventory_variant.sql
    ├── migrate_password_reset.sql
    ├── migrate_user_rbac.sql
    └── migrate_drop_supplier_legacy.sql
```

---

## Tài Liệu

| Tài liệu | Đường dẫn | Mô tả |
|---|---|---|
| API Documentation | [denhoamy_api/API_DOCUMENTATION.md](denhoamy_api/API_DOCUMENTATION.md) | 17 modules — v1.2 (PayOS pending, delivery, policy) |
| Deploy checklist | [DEPLOY.md](DEPLOY.md) | VPS Docker deploy + smoke test |
| Database Design | [docs/DATABASE_DESIGN.md](docs/DATABASE_DESIGN.md) | ERD, 21 bảng, migrations |
| Architecture | [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Kiến trúc, luồng dữ liệu, bảo mật |
| Hạn chế đồ án | [docs/HAN_CHE_DO_AN.md](docs/HAN_CHE_DO_AN.md) | Hạn chế hệ thống + hướng phát triển (báo cáo) |
| Slide bảo vệ | [docs/presentation/README.md](docs/presentation/README.md) | Outline 38 slide, sơ đồ, demo script, Q&A appendix |
| Views Map | [my-vue-app/docs/VIEWS_MAP.md](my-vue-app/docs/VIEWS_MAP.md) | Bản đồ views + components |
| Setup Guide | [README_SETUP.md](README_SETUP.md) | Hướng dẫn cài đặt chi tiết |

---

## Tác Giả

**Trần Minh Hiếu**  
Email: hieu.it@denhoamy.com  
Phone: 0978.897.579  
Address: Hải Phòng, Việt Nam

---

<p align="center">
  <sub>Built with Vue 3, PHP 8.2, MySQL 8.0 & Docker</sub>
</p>
