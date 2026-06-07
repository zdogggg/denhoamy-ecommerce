# Hướng dẫn cài đặt 

## 1. Yêu cầu hệ thống
- Đã cài đặt [Docker Desktop](https://www.docker.com/products/docker-desktop/) (rất quan trọng)
- Đã cài đặt [Node.js](https://nodejs.org/) (nếu muốn chỉnh sửa code frontend)

## 2. Các bước khởi động

### Bước 1: Mở Terminal tại thư mục dự án
Mở terminal tại thư mục gốc repo (ví dụ `Test Vue`) — chuột phải "Open in Terminal" hoặc `powershell` tại thanh địa chỉ.

### Bước 2: Khởi chạy Docker
Gõ lệnh sau để xây dựng và chạy các dịch vụ:
```bash
docker-compose up -d --build
```
*Lưu ý: Lần đầu tiên sẽ mất khoảng vài phút để hệ thống tải và cài đặt các thành phần.*

### Bước 3: Truy cập hệ thống
Sau khi các container báo trạng thái `Started`, truy cập các địa chỉ sau:

- **Giao diện bán hàng (Frontend):** [http://localhost:3000](http://localhost:3000)
- **Quản trị (Admin):** [http://localhost:3000/admin](http://localhost:3000/admin)
- **Quản lý Database (phpMyAdmin):** [http://localhost:8081](http://localhost:8081)
- **API Backend:** [http://localhost:8080](http://localhost:8080)

## 3. Thông tin tài khoản mặc định
- **Tài khoản Admin:** `admin` / `123456`
- **Database:** `denhoamy_db` (User: `root`, Pass: `root123`)

## 4. Các cổng dịch vụ sử dụng
- `db`: Port **3307** trên máy thật (MySQL)
- `api`: Port **8080** (PHP + Apache)
- `frontend`: Port **3000** (Nginx + Vue)
- `phpmyadmin`: Port **8081** (Quản lý DB)

## 5. Lưu ý về Upload ảnh
Toàn bộ ảnh upload sẽ được lưu vào: `denhoamy_api/uploads/`. Thư mục này đã được mount volume, vì vậy ảnh sẽ được lưu trữ thật trên máy tính dù có tắt Docker.

## 6. Chatbot AI (Groq)
Thêm vào file `.env` ở thư mục gốc dự án:
```env
GROQ_API_KEY=your_groq_api_key_here
GROQ_MODEL=meta-llama/llama-4-scout-17b-16e-instruct
```
Chatbot sử dụng **Groq** (Function Calling tra kho) → **rule-based** khi Groq lỗi/rate limit (retry 1 lần trước khi fallback).

Sau khi sửa `.env`, chạy lại: `docker compose up -d` để API nhận biến môi trường.

## 7. Quên mật khẩu (Resend)

Khách hàng nhập **SĐT đã đăng ký** → nhận **magic link** tại email đăng ký → đặt mật khẩu mới tại `/reset-password`.

Thêm vào `.env` (xem mẫu [`.env.example`](.env.example)):

```env
RESEND_API_KEY=re_xxxxxxxx
RESEND_FROM_EMAIL=noreply@yourdomain.com
RESEND_FROM_NAME=Đèn Hoa Mỹ
FRONTEND_URL=http://localhost:3000
```

**Database:** Nếu DB đã tạo trước khi có tính năng này, chạy migration:

```bash
Get-Content mysql/migrate_password_reset.sql | docker exec -i denhoamy_db mysql -uroot -proot123 denhoamy_db
```

**Resend:** Verify domain trên [resend.com](https://resend.com). Môi trường dev có thể chỉ gửi tới email đã verify trên dashboard Resend.

Sau khi sửa `.env`: `docker compose up -d api` (restart container API).

## 8. PayOS (Thanh toán online)

Thêm vào `.env` (xem [`.env.example`](.env.example)):

```env
PAYOS_CLIENT_ID=your_client_id
PAYOS_API_KEY=your_api_key
PAYOS_CHECKSUM_KEY=your_checksum_key
FRONTEND_URL=http://localhost:3000
```

- Checkout chọn **PayOS** → redirect cổng thanh toán → về `/payment/success` hoặc `/payment/cancel`.
- Customer chỉ được **một đơn PayOS pending**; frontend hiện dialog retry/hủy (`pending_payos`, `retry_payos`, `cancel_pending`).
- Webhook: PayOS gọi `payos_webhook.php` (production cần URL public HTTPS).

Sau khi sửa `.env`: `docker compose up -d api`.

## 9. Cron Jobs (Tự động xử lý đơn hàng)

Docker container API chạy 2 cron job mỗi phút:

| Cron Job | Chức năng |
|---|---|
| `cron_cancel_orders.php` | Tự động **hủy** đơn hàng `pending` quá 24h (hoàn kho + hoàn coupon) |
| `cron_progress_orders.php` | Tự động **tiến trạng thái**: `approved` → `shipping` → `completed` theo thời gian cấu hình |

Cron được cài đặt sẵn trong Dockerfile backend — không cần thao tác thủ công.

## 10. Database migrations

- **DB mới (Docker lần đầu):** [`denhoamy_db.sql`](denhoamy_db.sql) — tự chạy khi container MySQL khởi tạo (xem `docker-compose.yml`).
- **DB đã có từ trước:** xem [`mysql/README.md`](mysql/README.md) để chạy từng file migration.

**Các file migration hiện có:**

| File | Mô tả |
|---|---|
| `migrate_user_rbac.sql` | Thêm RBAC cho admins, `is_locked`/`address` cho users |
| `migrate_password_reset.sql` | Tạo bảng `password_reset_tokens` |
| `migrate_index_softdelete.sql` | Thêm `deleted_at` + indexes cho products, orders, news |
| `migrate_order_delivery_method.sql` | Thêm `delivery_method` (home/store) cho orders — dùng email xác nhận đơn |
| `migrate_pay_at_store.sql` | Thêm `pay_at_store` vào enum `payments.method` |
| `migrate_hot_deal_price_snapshot.sql` | Snapshot giá Hot Deal trên products/variants |
| `migrate_inventory_variant.sql` | Thêm `variant_id` + `type` cho inventory_history |
| `migrate_drop_supplier_legacy.sql` | Gỡ cột supplier legacy trên DB/VPS cũ |

**Chạy migration (PowerShell):**
```bash
Get-Content mysql/migrate_user_rbac.sql | docker exec -i denhoamy_db mysql -uroot -proot123 denhoamy_db
```

Trên **phpMyAdmin**: import hoặc dán nội dung SQL (bỏ qua lỗi cột trùng nếu đã migrate trước đó).

Cấu trúc API PHP: endpoint `*.php` ở [`denhoamy_api/`](denhoamy_api/), helpers trong [`denhoamy_api/lib/`](denhoamy_api/lib/).

## 11. Giỏ hàng đồng bộ (customer)

- Bảng `carts` / `cart_items` có trong [`denhoamy_db.sql`](denhoamy_db.sql) (init Docker).
- API: [`denhoamy_api/cart.php`](denhoamy_api/cart.php) — cần JWT customer.
- Khách **chưa login**: giỏ vẫn chỉ `localStorage` (Pinia).

## 12. Smoke test (tùy chọn)

**Backend** (trong container API):

```bash
docker exec -it denhoamy_api php /var/www/html/tests/order_status_smoke.php
docker exec -it denhoamy_api php /var/www/html/tests/order_stock_smoke.php
```

**PayOS E2E** (cần credentials + customer id test trong script):

```bash
docker cp scripts/payos_e2e_test.php denhoamy_api:/var/www/html/payos_e2e_test.php
docker exec -it denhoamy_api php /var/www/html/payos_e2e_test.php
```

**Frontend logic** (Node, không cần Docker):

```bash
node scripts/phase2-smoke.mjs
```

## 13. Admin — thông báo đơn mới

- [`AdminView.vue`](my-vue-app/src/views/AdminView.vue) poll `GET orders.php` **mỗi 5 giây** khi tab đang mở.
- Có `ElNotification` khi số đơn `pending` tăng — **HTTP polling**, không WebSocket.

---
