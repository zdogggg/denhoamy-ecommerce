# Outline Slide Bảo Vệ — Đèn Hoa Mỹ (38 slide)

> Copy nội dung từng slide sang PowerPoint/Google Slides.  
> Sơ đồ: [SLIDE_DIAGRAMS.md](SLIDE_DIAGRAMS.md) | Screenshot: [SLIDE_SCREENSHOTS.md](SLIDE_SCREENSHOTS.md) | Demo: [DEMO_SCRIPT.md](DEMO_SCRIPT.md) | Q&A: [SLIDE_APPENDIX_QA.md](SLIDE_APPENDIX_QA.md)

---

## Hướng dẫn nhanh

- Font body ≥ 24pt, tối đa 5–6 bullet/slide
- Màu: vàng/đen/trắng (tone shop đèn cao cấp), logo góc slide
- Thiếu thời gian: bỏ slide 5, 6, 18, 19 — **không bỏ** 24–26, 30

---

# CHƯƠNG 1 — MỞ ĐẦU

## Slide 1 — Trang bìa

**Tiêu đề:** XÂY DỰNG WEBSITE THƯƠNG MẠI ĐIỆN TỬ CHO CỬA HÀNG ĐÈN HOA MỸ

**Phụ đề:** Đồ án tốt nghiệp — Năm 2026

**Thông tin:**
- Sinh viên thực hiện: **Trần Minh Hiếu**
- Giảng viên hướng dẫn: *[Điền tên GVHD]*
- Khoa / Trường: *[Điền]*

**Visual:** Logo shop + ảnh đèn trang trí nền mờ

**Ghi chú trình bày:** 30 giây, giới thiệu tên đề tài và bản thân.

---

## Slide 2 — Mục lục

1. Giới thiệu đề tài
2. Cơ sở lý thuyết & khảo sát
3. Phân tích & thiết kế hệ thống
4. Cài đặt & triển khai
5. Kết quả, hạn chế & kết luận

**Visual:** Layout 5 block hoặc timeline ngang

---

## Slide 3 — Lý do chọn đề tài

- **Bối cảnh thực tế:** Cửa hàng Đèn Hoa Mỹ — chuyên đèn trang trí nội thất cao cấp tại Hải Phòng
- **Nhu cầu kinh doanh:** Mở rộng kênh bán online, quản lý kho và đơn hàng tập trung
- **Xu hướng công nghệ:** TMĐT B2C, thanh toán điện tử, AI tư vấn khách hàng 24/7
- **Ý nghĩa:** Giải pháp fullstack có thể triển khai thực tế cho doanh nghiệp vừa và nhỏ

**Visual:** Ảnh showroom / logo cửa hàng

---

## Slide 4 — Mục tiêu & phạm vi

**Mục tiêu:**
- Xây dựng website TMĐT fullstack (Vue 3 + PHP + MySQL)
- Tích hợp thanh toán PayOS, chatbot AI (Groq LLaMA 4)
- Admin dashboard quản trị toàn diện
- Triển khai bằng Docker một lệnh

**Trong phạm vi:**
- Giao diện khách hàng + quản trị (Admin/Staff)
- 21 bảng CSDL, JWT + RBAC, responsive web

**Ngoài phạm vi:**
- Ứng dụng mobile native, đa ngôn ngữ (i18n)
- SSR/SEO nâng cao, WebSocket realtime

---

# CHƯƠNG 2 — CƠ SỞ LÝ THUYẾT & KHẢO SÁT

## Slide 5 — Khái niệm thương mại điện tử

- **TMĐT:** Mua bán hàng hóa/dịch vụ qua mạng Internet
- **Mô hình B2C:** Doanh nghiệp bán trực tiếp cho người tiêu dùng
- **Thành phần hệ thống:**
  - Frontend — giao diện người dùng
  - Backend — xử lý nghiệp vụ, API
  - Database — lưu trữ dữ liệu

**Visual:** Sơ đồ 3-tier đơn giản (Client → Server → DB)

---

## Slide 6 — Công nghệ nền tảng

| Khái niệm | Ứng dụng trong đồ án |
|-----------|----------------------|
| SPA (Single Page Application) | Vue 3 + Vue Router |
| REST API | PHP 8.2, JSON response |
| JWT Authentication | Đăng nhập, phân quyền |
| Container Docker | Docker Compose 4 service |

**Visual:** Icon stack hoặc bảng 2 cột

---

## Slide 7 — Khảo sát hiện trạng

**Quy trình bán hàng offline hiện tại:**
1. Khách đến showroom → tư vấn trực tiếp
2. Chọn mẫu đèn → kiểm tra tồn kho thủ công
3. Thanh toán tiền mặt/chuyển khoản
4. Giao hàng hoặc khách mang về

**Hạn chế:**
- Khó tra cứu kho nhanh khi nhiều biến thể
- Không có báo cáo doanh thu tập trung
- Khách không mua được ngoài giờ mở cửa

---

## Slide 8 — Khảo sát nhu cầu

**Khách hàng cần:**
- Xem danh mục, lọc/tìm kiếm sản phẩm
- Thanh toán online (PayOS) hoặc COD
- Chính sách bảo hành, đổi trả rõ ràng
- Tư vấn nhanh qua chatbot

**Quản trị cần:**
- CRUD sản phẩm, biến thể, ảnh gallery
- Quản lý đơn hàng, mã giảm giá, thống kê
- Phân quyền nhân viên (Staff)

---

## Slide 9 — Yêu cầu hệ thống

**Yêu cầu chức năng:**
- Mua hàng: giỏ, checkout, coupon, wishlist
- Thanh toán: COD, PayOS, nhận tại shop (`pay_at_store`)
- Admin: 11 module (Dashboard → Settings)
- Chatbot AI tra kho thực tế
- Tin tức, CMS chính sách

**Yêu cầu phi chức năng:**
- Bảo mật: JWT, RBAC, rate limit, prepared statements
- Responsive mobile (giỏ hàng, profile)
- Deploy Docker một lệnh
- Hiệu năng: pagination, skeleton loading

**Visual:** Bảng 2 cột Chức năng | Phi chức năng

---

# CHƯƠNG 3 — PHÂN TÍCH & THIẾT KẾ

## Slide 10 — Use case tổng quan

**Actors:**
- **Khách hàng** — duyệt web, mua hàng, chatbot
- **Admin / Staff** — quản trị hệ thống
- **Hệ thống** — Cron, PayOS webhook, Groq API

**Visual:** Sơ đồ D12 trong [SLIDE_DIAGRAMS.md](SLIDE_DIAGRAMS.md)

---

## Slide 11 — Use case khách hàng

- Duyệt trang chủ, danh mục (filter, sort, search)
- Xem chi tiết sản phẩm (biến thể, đánh giá, SP liên quan)
- Giỏ hàng → Checkout (đăng nhập bắt buộc)
- Thanh toán: COD / PayOS / pay_at_store
- Wishlist, quên mật khẩu (Magic Link email)
- AI Chatbot tư vấn sản phẩm
- Profile: lịch sử đơn, xác nhận đã nhận hàng

---

## Slide 12 — Use case quản trị

**11 module Admin Dashboard:**

| Module | Chức năng chính |
|--------|-----------------|
| Dashboard | Doanh thu, top SP, xuất Excel |
| Sản phẩm | CRUD, biến thể, import Excel |
| Danh mục | Cây phân cấp, drag sort |
| Đơn hàng | Filter, cập nhật trạng thái |
| Hot Deal | SP nổi bật, sửa giá nhanh |
| Mã giảm giá | CRUD, giới hạn lượt dùng |
| Đánh giá | Duyệt, trả lời khách |
| Tin tức | WYSIWYG editor |
| Chính sách | CMS 4 tab HTML |
| Khách hàng | Khóa/mở tài khoản |
| Cài đặt | Logo, banner, hotline, QR |

---

## Slide 13 — Kiến trúc hệ thống

**Mô hình 3-Tier:**

```
Browser → Vue 3 SPA (Nginx :3000)
       → PHP 8.2 API (Apache :8080)
       → MySQL 8.0 (:3307)
```

**Tích hợp bên thứ 3:** Groq (AI), PayOS (thanh toán), Resend (email)

**Visual:** Sơ đồ D1 — [ARCHITECTURE.md](../ARCHITECTURE.md) §1.1

---

## Slide 14 — Triển khai Docker Compose

| Service | Port | Vai trò |
|---------|------|---------|
| `frontend` | 3000 | Vue build + Nginx |
| `api` | 8080 | PHP + Apache + Cron |
| `db` | 3307 | MySQL 8.0 |
| `phpmyadmin` | 8081 | Quản lý DB |

**Khởi chạy:** `docker-compose up -d --build`

**Visual:** Sơ đồ D2

---

## Slide 15 — Thiết kế CSDL

**Database:** `denhoamy_db` — **21 bảng**, utf8mb4

| Nhóm | Số bảng | Ví dụ |
|------|---------|-------|
| Sản phẩm | 5 | products, product_variants, categories |
| Thương mại | 6 | orders, order_items, coupons, carts |
| Người dùng | 3 | users, admins, password_reset_tokens |
| Tương tác | 5 | reviews, wishlists, news, chat_* |
| Hệ thống | 2 | settings, inventory_history |

**Nguồn:** [DATABASE_DESIGN.md](../DATABASE_DESIGN.md)

---

## Slide 16 — ERD (rút gọn)

**Quan hệ cốt lõi:**
- `categories` → `products` → `product_variants`
- `users` → `orders` → `order_items` → `products`
- `users` → `carts` → `cart_items`

**Visual:** Sơ đồ D9 (8–10 entity, không cần full 21 bảng)

---

## Slide 17 — Thiết kế Frontend

**Cấu trúc Vue 3 (Composition API):**
- **17 views** — HomeView, CheckoutView, AdminView, …
- **19 components** — 12 admin modules + layout
- **17 services** — Axios API layer
- **3 Pinia stores:** `auth`, `cart`, `settings`

**Route guards:**
- Public — ai cũng truy cập
- `requiresAuth` — checkout, profile
- `requiresAdmin` — `/admin/*`

**Nguồn:** [router/index.js](../../my-vue-app/src/router/index.js)

---

## Slide 18 — Thiết kế Backend

**File-based routing:** 1 file PHP = 1 resource
- `orders.php`, `products.php`, `auth.php`, …

**Middleware stack (theo thứ tự):**
1. CORS + kết nối DB
2. Rate limiting (IP-based)
3. JWT Auth (`requireLogin`, `requireAdmin`)
4. Admin route guard (RBAC staff)
5. Input validator + sanitize
6. Business logic + PDO prepared statements

**Visual:** Sơ đồ D3 — [ARCHITECTURE.md](../ARCHITECTURE.md) §3.1

---

## Slide 19 — Thiết kế API & bảo mật

**API:** 17 REST modules, response JSON `{ success, data, message }`

**7 lớp bảo mật (Defense in Depth):**

| Lớp | Cơ chế |
|-----|--------|
| Network | CORS whitelist, rate limit |
| Auth | JWT HMAC-SHA256, exp 24h |
| Authorization | RBAC Admin → Staff → Customer |
| Input | Centralized validator, sanitize XSS |
| Database | Prepared statements, no string concat |
| File upload | MIME finfo, limit 10MB |
| Logging | logInfo/Warning/Exception + IP |

**Visual:** Sơ đồ D11

---

# CHƯƠNG 4 — CÀI ĐẶT & TRIỂN KHAI

## Slide 20 — Tech stack

**Frontend:** Vue 3.5 · Vite 8 · Pinia 3 · Vue Router 4 · Element Plus · Axios · Chart.js

**Backend:** PHP 8.2 · MySQL 8.0 · JWT custom · Groq LLaMA 4 · PayOS · Resend

**DevOps:** Docker Compose · Nginx · Apache · Cron jobs

**Visual:** Bảng 3 hàng — copy từ [README.md](../../README.md) mục Tech Stack

---

## Slide 21 — Giao diện: Trang chủ & Danh mục

**Trang chủ:**
- Banner carousel (tối đa 6), banner QC dọc/ngang
- Hot Deals, sản phẩm mới (slider), khám phá bộ sưu tập

**Danh mục:**
- Filter loại đèn, phong cách
- Tìm kiếm, sắp xếp giá, phân trang
- Skeleton loading (ProductSkeleton)

**UX:** Navbar sticky glassmorphism khi cuộn

**Visual:** Screenshot `01-home-desktop.png`, `02-category-filter.png`

---

## Slide 22 — Chi tiết sản phẩm

- Gallery ảnh, chọn biến thể (kích thước, ánh sáng)
- Đánh giá sao, tag "Hàng mới về"
- **Sản phẩm liên quan** — cùng `loai_den`, API `exclude_id`
- **Giá hiển thị:** nhãn **「Từ」** khi biến thể có giá khác nhau
- Giá gạch chỉ khi `old_price` > giá bán

**Visual:** Screenshot `03-product-detail.png`

**Code tham chiếu:** `my-vue-app/src/utils/productPrice.js`

---

## Slide 23 — Giỏ hàng & đồng bộ

**Khách chưa đăng nhập:**
- Pinia + `localStorage`

**Customer đã đăng nhập:**
- Đồng bộ server qua `cart.php` (GET/PUT)
- **Merge giỏ** khi login (`mergeAfterLogin`)

**Giao diện:** Desktop (bảng) + Mobile (card layout)

**Visual:** Sơ đồ D4 + screenshot `04-cart-mobile.png`

---

## Slide 24 — Luồng đặt hàng (Checkout)

**Bước checkout:**
1. Chọn hình thức nhận: **Giao hàng** (`home`) / **Nhận tại shop** (`store`)
2. Chọn PTTT: **COD** | **PayOS** | **pay_at_store**
3. Áp mã giảm giá (validate server)
4. POST `/orders.php` → tạo đơn `pending`

**Validate combo:** Server kiểm tra delivery + payment hợp lệ

**Visual:** Sơ đồ D5 (phần đầu) + screenshot `05-checkout.png`

---

## Slide 25 — Tích hợp PayOS

**Cơ chế an toàn:**
- Chặn đơn PayOS pending trùng → HTTP **409 Conflict**
- Endpoints: `pending_payos`, `retry_payos`, `cancel_pending`

**Luồng:**
1. Tạo đơn → `createPaymentLink()` → redirect PayOS
2. Thanh toán OK → `payos_webhook.php` verify **HMAC signature**
3. Cancel → `PaymentResultView` poll status, retry/hủy

**Visual:** Sơ đồ D5 (phần PayOS) + screenshot `11-payment-result.png` (tuỳ chọn)

**Nguồn:** `denhoamy_api/lib/payos_order_helpers.php`

---

## Slide 26 — Khóa tồn kho khi đặt hàng

**Vấn đề:** Nhiều khách cùng mua → oversell

**Giải pháp:**
```
beginTransaction()
→ normalizeOrderItemsInTransaction()  // SELECT … FOR UPDATE
→ trừ stock (product + variant)
→ INSERT order + order_items
→ commit (rollback nếu lỗi)
```

**Kết quả:** Đảm bảo tồn kho nhất quán trong transaction

**Nguồn:** `denhoamy_api/lib/order_pricing.php`

---

## Slide 27 — Máy trạng thái đơn hàng

```
pending → approved → shipping → completed
       ↘ cancelled (hoàn kho + hoàn coupon)
```

**Tự động (Cron):**
- `pending` > 24h → `cancelled` (+ hủy link PayOS)
- `approved` → `shipping` (sau N giờ)
- `shipping` → `completed` (sau N ngày)

**Khách hàng:** `confirm_received` khi đơn đang `shipping`

**Visual:** Sơ đồ D6 + screenshot `10-profile-orders.png`

---

## Slide 28 — Admin Dashboard

**Dashboard:**
- Biểu đồ doanh thu (Chart.js)
- Top sản phẩm bán chạy
- Sản phẩm sắp hết hàng (search + paginate)
- Xuất Excel (dynamic import xlsx)

**Thông báo đơn mới:**
- HTTP **polling 5 giây** — so sánh số đơn `pending`
- Toast `ElNotification` khi có đơn mới
- **Lưu ý:** Chưa WebSocket/SSE — độ trễ tối đa ~5s

**Visual:** Screenshot `06-admin-dashboard.png`, `07-admin-orders.png`

---

## Slide 29 — RBAC & phân quyền Staff

**3 cấp vai trò:**

| Role | Quyền |
|------|-------|
| Admin | Toàn quyền 11 module |
| Staff | Theo `permissions[]` — map endpoint |
| Customer | Shop + profile |

**Cơ chế:** `admin_route_guard.php` map file/method → permission key

**Visual:** Sơ đồ D10 + screenshot `08-admin-users-rbac.png`

---

## Slide 30 — AI Chatbot (Groq + Tool Calling)

**Engine:** Groq API — LLaMA 4 Scout

**4 Function Calling tools (query MySQL thật):**
- `search_products` — tìm theo keyword, giá, loại
- `get_product_specs` — chi tiết 1 SP
- `list_product_types` — liệt kê loại đèn
- `get_store_faq` — ship, bảo hành, giờ mở cửa

**Fallback:** Rule-based (regex + FAQ) khi API lỗi/rate limit

**Visual:** Sơ đồ D8 + screenshot `09-chatbot.png`

**Câu demo:** *"Có đèn chùm phòng khách dưới 5 triệu không?"*

---

## Slide 31 — Triển khai & vận hành

**Development:**
```bash
docker-compose up -d --build
```

**Truy cập:**
- Website: http://localhost:3000
- Admin: http://localhost:3000/admin
- API: http://localhost:8080

**Production checklist** ([DEPLOY.md](../../DEPLOY.md)):
- HTTPS, đổi JWT secret, CORS domain
- Backup DB hàng ngày, log rotation

**Cron trong container API:** hủy đơn pending, auto progress trạng thái

**Visual:** Screenshot `15-docker-ps.png` (tuỳ chọn)

---

# CHƯƠNG 5 — KẾT QUẢ & KẾT LUẬN

## Slide 32 — Kiểm thử

**Backend smoke test:**
- `denhoamy_api/tests/order_status_smoke.php`
- `denhoamy_api/tests/order_stock_smoke.php`

**PayOS E2E:** `scripts/payos_e2e_test.php`

**Frontend:** `scripts/phase2-smoke.mjs` (logic smoke Node)

**Kiểm thử thủ công:** Checklist chức năng trên Docker local / VPS

**Hạn chế test:** Chưa có unit test Vue, chưa CI/CD pipeline đầy đủ

---

## Slide 33 — Kết quả đạt được

| Hạng mục | Mô tả |
|----------|-------|
| TMĐT fullstack | 17 views customer + 11 module admin |
| Thanh toán đa kênh | COD, PayOS, pay_at_store |
| PayOS an toàn | Chặn pending trùng, retry, webhook |
| Khóa tồn kho | Transaction + FOR UPDATE |
| Giỏ hàng DB | Sync + merge khi login |
| AI Chatbot | Groq tool calling + fallback |
| Bảo mật | JWT, RBAC, rate limit, validator |
| DevOps | Docker one-command deploy |

**Nguồn:** [HAN_CHE_DO_AN.md](../HAN_CHE_DO_AN.md) §0

---

## Slide 34 — Hạn chế (5 ý then chốt)

1. **Backend Core PHP** — chưa MVC/Laravel, tái sử dụng code hạn chế
2. **Chưa cache Redis** — truy vấn DB trực tiếp khi traffic cao
3. **Admin notify = polling 5s** — chưa SSE/WebSocket realtime
4. **SEO SPA** — meta động client, chưa SSR/Nuxt
5. **Phụ thuộc bên thứ 3** — Groq, PayOS, Resend (rate limit, downtime)

**Ghi chú trình bày:** Nói thẳng + có hướng khắc phục ở slide sau.

---

## Slide 35 — Hướng phát triển

| Hạn chế | Hướng khắc phục |
|---------|-----------------|
| Core PHP | Laravel / Repository pattern |
| Thiếu cache | Redis cho danh mục, dashboard |
| Polling admin | SSE hoặc WebSocket |
| Thiếu test/CI | PHPUnit + Playwright + GitHub Actions |
| SEO SPA | Nuxt SSR/SSG, prerender SP/tin tức |
| Media local | CDN + S3/Cloudinary |
| Chatbot | RAG trên FAQ + catalog nội bộ |

**Nguồn:** [HAN_CHE_DO_AN.md](../HAN_CHE_DO_AN.md) §2

---

## Slide 36 — Kịch bản Demo

| Bước | Hành động | Thời gian |
|------|-----------|-----------|
| 1 | Trang chủ → danh mục → SP → thêm giỏ | ~1.5 phút |
| 2 | Login → checkout + coupon | ~1 phút |
| 3 | Thanh toán COD (backup nếu PayOS lỗi) | ~1 phút |
| 4 | Admin → toast đơn pending → duyệt | ~1 phút |
| 5 | Chatbot hỏi SP theo giá | ~1 phút |

**Chuẩn bị:** Docker running, tài khoản admin/customer, SP còn tồn kho

**Chi tiết:** [DEMO_SCRIPT.md](DEMO_SCRIPT.md)

---

## Slide 37 — Kết luận

- Đã xây dựng **hệ thống TMĐT hoàn chỉnh** cho cửa hàng Đèn Hoa Mỹ
- Đáp ứng nhu cầu **bán online, quản trị, thanh toán, tư vấn AI**
- Triển khai được qua **Docker**, có tài liệu API và kiến trúc đầy đủ
- Hạn chế đã được **nhận diện rõ** với **lộ trình mở rộng** cụ thể

---

## Slide 38 — Cảm ơn & Q&A

**Cảm ơn Hội đồng đã lắng nghe!**

**Thông tin liên hệ:**
- Trần Minh Hiếu
- Email: hieu.it@denhoamy.com
- Phone: 0978.897.579

**Sẵn sàng trả lời câu hỏi.**

**Appendix (không trình bày):** [SLIDE_APPENDIX_QA.md](SLIDE_APPENDIX_QA.md)

---

## Phụ lục — Phân bổ thời gian trình bày

| Kịch bản | Slide | Demo | Q&A |
|----------|-------|------|-----|
| ~15 phút | 8–10 phút (bỏ 5,6,18,19) | 4 phút | 1–2 phút |
| ~20 phút | 12 phút | 5–6 phút | 2–3 phút |
| ~25–30 phút | 15–18 phút | 6–7 phút | 5 phút |

**Slide bắt buộc:** 1, 4, 13, 24–26, 30, 33–35, 37–38
