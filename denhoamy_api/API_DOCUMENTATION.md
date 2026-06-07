# API Documentation — Đèn Hoa Mỹ E-Commerce

> **Base URL:** `http://localhost:8080`  
> **Content-Type:** `application/json`  
> **Auth:** `Authorization: Bearer <JWT_TOKEN>`  
> **Phiên bản:** 1.2 — Cập nhật: 06/06/2026 (PayOS pending/retry/cancel, giao hàng/nhận tại shop, `confirm_received`, policy CMS)

---

## Mục Lục

| # | Module | Endpoint | Mô tả |
|---|---|---|---|
| 1 | [Auth](#1-auth) | `auth.php` | Đăng nhập / Đăng ký |
| 2 | [Products](#2-products) | `products.php` | CRUD sản phẩm |
| 3 | [Orders](#3-orders) | `orders.php` | CRUD đơn hàng + PayOS |
| 4 | [Categories](#4-categories) | `categories.php` | CRUD danh mục |
| 5 | [Users](#5-users) | `users.php` | Quản lý người dùng & admin |
| 6 | [Coupons](#6-coupons) | `coupons.php` | Quản lý mã giảm giá |
| 7 | [Reviews](#7-reviews) | `reviews.php` | Đánh giá sản phẩm |
| 8 | [News](#8-news) | `news.php` | Quản lý tin tức / blog |
| 9 | [Upload](#9-upload) | `upload.php` | Upload ảnh |
| 10 | [Chatbot](#10-chatbot) | `chatbot_engine.php` | AI Chatbot tư vấn |
| 11 | [Statistics](#11-statistics) | `statistics.php` | Thống kê dashboard |
| 12 | [Settings](#12-settings) | `settings.php` | Cài đặt website |
| 13 | [Wishlist](#13-wishlist) | `wishlist.php` | Sản phẩm yêu thích |
| 14 | [Inventory](#14-inventory) | `inventory.php` | Quản lý kho |
| 15 | [Forgot Password](#15-forgot-password) | `forgot-password.php` | Quên mật khẩu |
| 16 | [PayOS Webhook](#16-payos-webhook) | `payos_webhook.php` | Webhook thanh toán |
| 17 | [Cart](#17-cart) | `cart.php` | Giỏ hàng (đồng bộ DB) |

---

## 🔐 Xác Thực (Authentication)

Hệ thống sử dụng **JWT (JSON Web Token)** với HMAC-SHA256.

```
Authorization: Bearer eyJhbGciOiJIUzI1NiIs...
```

### Phân quyền (RBAC)

| Role | Mô tả | Quyền |
|---|---|---|
| `admin` | Quản trị viên | Toàn quyền |
| `staff` | Nhân viên | Theo `permissions` JSON |
| `customer` | Khách hàng | Chỉ xem/sửa dữ liệu cá nhân |

**Enforce API:** `lib/admin_route_guard.php` — map `products.php`, `orders.php`, `settings.php` (PUT), `statistics.php`, `upload.php`, … → `requirePermission(key)`. Endpoint public (GET sản phẩm, `coupons?scope=public`, …) không qua guard.

### Rate Limiting

| Loại | Giới hạn | Áp dụng |
|---|---|---|
| Strict | 5 request/phút | Login, Forgot Password |
| Normal | 120 request/phút | Orders |
| Chatbot | Riêng | Chatbot Engine |

---

## 1. Auth

**File:** `auth.php`  
**Rate Limit:** Strict (5/phút)

### 1.1 Đăng nhập

```
POST /auth.php
```

**Request Body:**
```json
{
  "action": "login",
  "username": "0978897579",
  "password": "123456"
}
```

**Response (Admin/Staff):**
```json
{
  "success": true,
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "user": {
    "id": 1,
    "username": "admin",
    "name": "Trần Minh Hiếu",
    "phone": "0978897579",
    "email": "hieu.it@denhoamy.com",
    "avatar": "/uploads/avatars/admin.jpg",
    "role": "admin",
    "permissions": null
  }
}
```

**Response (Customer):**
```json
{
  "success": true,
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "user": {
    "id": 5,
    "username": "0901234567",
    "name": "Nguyễn Văn A",
    "phone": "0901234567",
    "email": "a@gmail.com",
    "role": "customer"
  }
}
```

**Errors:**
| Code | Message |
|---|---|
| 200 | `Tài khoản hoặc mật khẩu không đúng!` |
| 200 | `Tài khoản đã bị vô hiệu hoá!` |
| 200 | `Tài khoản của bạn đã bị khoá do vi phạm!` |
| 422 | Validation errors |

### 1.2 Đăng ký

```
POST /auth.php
```

**Request Body:**
```json
{
  "action": "register",
  "name": "Nguyễn Văn B",
  "phone": "0901234568",
  "email": "b@gmail.com",
  "password": "matkhau123"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Đăng ký thành công!"
}
```

### 1.3 Đổi mật khẩu (Admin/Staff)

```
POST /auth.php
Authorization: Bearer <admin_token>
```

**Request Body:**
```json
{
  "action": "change_password",
  "current_password": "123456",
  "new_password": "matkhaumoi"
}
```

**Response:** `{ "success": true, "message": "Đổi mật khẩu thành công" }`

> Chỉ áp dụng tài khoản trong bảng `admins` (form đổi MK trong Admin shell).

---

## 2. Products

**File:** `products.php`  
**Auth:** GET = Public | POST, PUT, DELETE = Admin

### 2.1 Lấy danh sách sản phẩm

```
GET /products.php?page=1&limit=20&type=Đèn chùm&search=pha lê&sort=asc&exclude_id=5
```

**Query Parameters:**

| Param | Type | Default | Mô tả |
|---|---|---|---|
| `page` | int | 1 | Trang hiện tại |
| `limit` | int | 200 | Số SP/trang (max 200) |
| `type` | string | - | Lọc theo loại đèn (hỗ trợ danh mục cha + con) |
| `search` | string | - | Tìm theo tên hoặc mã SP |
| `sort` | string | `new` | Sắp xếp: `new`, `asc` (giá tăng), `desc` (giá giảm) |
| `exclude_id` | int | - | Loại trừ SP (dùng cho "SP tương tự") |

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "ten_san_pham": "Đèn chùm DC04305",
      "ma_san_pham": "DC04305",
      "loai_den": "Đèn chùm",
      "price": "15000000.00",
      "old_price": "18500000.00",
      "is_hot_deal": 0,
      "image_url": "https://...",
      "stock": 15,
      "phong_cach": "Tân cổ điển",
      "chat_lieu": "Hợp kim + thủy tinh",
      "variants": [...],
      "gallery": [...]
    }
  ],
  "total": 60,
  "page": 1,
  "limit": 20
}
```

### 2.2 Lấy chi tiết sản phẩm

```
GET /products.php?id=1
```

**Response:** Giống trên + thêm `description`, `khong_gian_lap_dat`, `bong_den`, `dien_ap`, `tinh_trang`, `tuoi_tho`, `kich_thuoc`, `variants`, `gallery`.

### 2.3 Lấy Hot Deals

```
GET /products.php?hot_deal=1
```

### 2.4 Thêm sản phẩm mới

```
POST /products.php
Authorization: Bearer <admin_token>
```

**Request Body:**
```json
{
  "ma_san_pham": "DC99999",
  "ten_san_pham": "Đèn chùm mới",
  "price": 15000000,
  "old_price": 18000000,
  "loai_den": "Đèn chùm",
  "image_url": "/uploads/products/dc99999.jpg",
  "stock": 10,
  "cost_price": 8000000,
  "description": "Mô tả sản phẩm...",
  "phong_cach": "Hiện đại",
  "khong_gian_lap_dat": "phòng khách",
  "bong_den": "Led",
  "chat_lieu": "Hợp kim + pha lê",
  "kich_thuoc": "80x60cm",
  "gallery": ["/uploads/products/img1.jpg", "/uploads/products/img2.jpg"],
  "variants": [
    { "kich_thuoc": "60cm", "anh_sang": "Vàng", "price": 14000000, "cost_price": 7000000, "stock": 5 }
  ]
}
```

**Quy tắc `old_price` (POST/PUT thêm/sửa SP):**

| Trường hợp | Hành vi |
|------------|---------|
| `old_price` bỏ trống hoặc `0` | Lưu `0` — **không** tự gán bằng `price` |
| `old_price` > `price` | Lưu nguyên — hiển thị giá gạch trên shop |
| `old_price` ≤ `price` (và > 0) | Server chuẩn hóa về `0` (không hiển thị khuyến mãi) |

> SP có `variants`: giá bán trên thẻ khách có thể hiện **「Từ {min}」** khi các biến thể có giá khác nhau (logic [`product_pricing.php`](lib/product_pricing.php) + frontend `productPrice.js`).

### 2.5 Import sản phẩm hàng loạt

```
POST /products.php?action=import
Authorization: Bearer <admin_token>
```

**Request Body:** Mảng JSON các sản phẩm (format giống 2.4)

### 2.6 Cập nhật sản phẩm

```
PUT /products.php
Authorization: Bearer <admin_token>
```

**Request Body:** Giống 2.4 + thêm `"id": 1`

### 2.7 Toggle Hot Deal

```
PUT /products.php
Authorization: Bearer <admin_token>
```

```json
{
  "action": "toggle_hot_deal",
  "id": 1,
  "is_hot_deal": 1
}
```

### 2.8 Cập nhật giá nhanh

```
PUT /products.php
Authorization: Bearer <admin_token>
```

```json
{
  "action": "quick_update_price",
  "id": 1,
  "price": 14500000,
  "old_price": 18000000
}
```

### 2.9 Xóa sản phẩm (Soft Delete)

```
DELETE /products.php?id=1
DELETE /products.php?ids=1,2,3
DELETE /products.php?action=clear_all
Authorization: Bearer <admin_token>
```

---

## 3. Orders

**File:** `orders.php`  
**Rate Limit:** Normal (120/phút)

### 3.1 Lấy danh sách đơn hàng

```
GET /orders.php?phone=0901234567&page=1&limit=20&status=pending&search=Nguyễn
Authorization: Bearer <token>
```

**Query Parameters:**

| Param | Type | Mô tả |
|---|---|---|
| `phone` | string | SĐT khách (bắt buộc cho customer, optional cho admin) |
| `page` | int | Trang (0 = lấy hết) |
| `limit` | int | Số đơn/trang (max 100) |
| `status` | string | Filter: `pending`, `approved`, `shipping`, `completed`, `cancelled` |
| `search` | string | Tìm theo tên, SĐT, email |

**Auth Logic:**
- Không có `phone` → yêu cầu Admin
- Có `phone` → Customer chỉ xem đơn của mình

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "customer_name": "Nguyễn Văn A",
      "phone": "0901234567",
      "email": "a@gmail.com",
      "address": "Hải Phòng",
      "payment_method": "cod",
      "total": "15000000",
      "coupon_code": "SALE10",
      "discount_amount": "1500000",
      "status": "pending",
      "created_at": "2026-05-25 10:00:00",
      "items": [
        {
          "product_id": 1,
          "product_name": "Đèn chùm DC04305",
          "quantity": 1,
          "price": "15000000"
        }
      ]
    }
  ],
  "pagination": {
    "total": 50,
    "totalPages": 3,
    "currentPage": 1,
    "limit": 20
  }
}
```

### 3.2 Tạo đơn hàng

```
POST /orders.php
```

**Request Body:**
```json
{
  "user_id": 5,
  "name": "Nguyễn Văn A",
  "phone": "0901234567",
  "email": "a@gmail.com",
  "address": "123 Lê Lợi, Hải Phòng",
  "deliveryMethod": "home",
  "note": "Giao giờ hành chính",
  "paymentMethod": "cod",
  "total": 15000000,
  "discountAmount": 0,
  "couponCode": "",
  "items": [
    { "id": 1, "name": "Đèn chùm DC04305", "quantity": 1, "price": 15000000 },
    { "id": "2_5", "name": "Đèn thả 60cm Vàng", "quantity": 2, "price": 3200000 }
  ]
}
```

> **Lưu ý:** `id` có thể là `"productId_variantId"` (VD: `"2_5"`) cho biến thể sản phẩm.

> **Giá đơn hàng (server authoritative):** Backend **không tin** `items[].price` từ client. Khi tạo đơn, server đọc lại giá bán từ `products` / `product_variants` (logic giống frontend `resolveSalePrice`), tính `subtotal`, áp voucher, lưu `order_items.price` và `orders.total` theo giá DB. Client gửi `price` sai sẽ bị ghi đè.

> **Tồn kho:** Trong transaction, `normalizeOrderItemsInTransaction()` khóa dòng `SELECT … FOR UPDATE`, kiểm tra đủ hàng rồi trừ `stock`. Thiếu tồn → HTTP 400.

**Delivery Methods:** `home` (giao tận nơi) | `store` (nhận tại cửa hàng)

**Payment Methods:** `cod` | `bank_transfer` | `payos` | `pay_at_store`

**Combo hợp lệ** (validate `validateOrderPaymentCombo()`):

| `deliveryMethod` | PTTT được phép |
|---|---|
| `home` | `cod`, `bank_transfer`, `payos` |
| `store` | `pay_at_store`, `payos` |

> **PayOS trùng đơn:** Nếu customer còn đơn PayOS `pending` chưa thanh toán → HTTP **409** + `pendingOrderId`. Frontend hiện dialog retry/hủy trước khi tạo đơn mới.

> **Email xác nhận:** COD / `pay_at_store` → gửi email qua Resend sau khi tạo đơn (không chặn luồng nếu mail lỗi). PayOS → email sau webhook thành công.

**Response (PayOS):**
```json
{
  "success": true,
  "message": "Đặt hàng thành công! Đang chuyển sang thanh toán...",
  "orderId": 1,
  "checkoutUrl": "https://pay.payos.vn/web/...",
  "qrCode": "data:image/png;base64,..."
}
```

**Response (COD/Bank):**
```json
{
  "success": true,
  "message": "Đặt hàng thành công!",
  "orderId": 1
}
```

### 3.3 Kiểm tra trạng thái thanh toán

```
GET /orders.php?action=payment_status&orderId=1
```

**Response:**
```json
{
  "success": true,
  "orderId": 1,
  "orderStatus": "approved",
  "paymentMethod": "payos",
  "paymentStatus": "completed",
  "isPaid": true,
  "isPending": false,
  "isCancelled": false
}
```

### 3.4 Lấy đơn PayOS pending của khách

```
GET /orders.php?action=pending_payos
Authorization: Bearer <customer_token>
```

**Response (có đơn chờ):**
```json
{
  "success": true,
  "data": {
    "id": 42,
    "total": 15000000,
    "status": "pending",
    "paymentMethod": "payos",
    "paymentStatus": "pending",
    "createdAt": "2026-06-06 10:00:00"
  }
}
```

**Response (không có):** `{ "success": true, "data": null }`

### 3.5 Tạo lại link PayOS (retry)

```
POST /orders.php
Authorization: Bearer <customer_token>
```

```json
{
  "action": "retry_payos",
  "orderId": 42
}
```

**Response:** Giống 3.2 PayOS (`checkoutUrl`, `qrCode`). Hủy link cũ trên PayOS trước khi tạo link mới (`createPayosCheckoutForOrder()`).

### 3.6 Khách hủy đơn PayOS pending

```
PUT /orders.php
Authorization: Bearer <customer_token>
```

```json
{
  "action": "cancel_pending",
  "orderId": 42
}
```

> Hủy link PayOS + `applyOrderStatus(..., 'cancelled')` → hoàn kho + hoàn coupon.

### 3.7 Khách xác nhận đã nhận hàng

```
PUT /orders.php
Authorization: Bearer <customer_token>
```

```json
{
  "action": "confirm_received",
  "orderId": 42
}
```

> Chỉ khi `status = shipping`. Customer phải khớp SĐT đơn; admin/staff bỏ qua kiểm tra SĐT. Chuyển `shipping` → `completed`.

### 3.8 Cập nhật trạng thái đơn (Admin)

```
PUT /orders.php
Authorization: Bearer <admin_token>
```

```json
{
  "id": 1,
  "status": "approved",
  "admin_id": 1
}
```

> **Lưu ý:** Khi chuyển sang `cancelled`, tồn kho tự động hoàn trả + lượt dùng coupon giảm.

### 3.9 Xóa đơn hàng (Soft Delete)

```
DELETE /orders.php?id=1
Authorization: Bearer <admin_token>
```

---

## 4. Categories

**File:** `categories.php`  
**Auth:** GET = Public | POST, PUT, DELETE = Admin

### 4.1 Lấy cây danh mục

```
GET /categories.php
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "Đèn chùm",
      "parent_id": null,
      "count": 15,
      "children": [
        { "id": 5, "name": "Đèn chùm hiện đại", "parent_id": 1, "count": 8 }
      ]
    }
  ],
  "flat": [...]
}
```

### 4.2 Thêm danh mục

```
POST /categories.php
Authorization: Bearer <admin_token>
```

```json
{ "name": "Đèn bàn", "parent_id": null, "sort_order": 5 }
```

### 4.3 Sửa danh mục

```
PUT /categories.php
Authorization: Bearer <admin_token>
```

```json
{ "id": 1, "name": "Đèn chùm cao cấp", "parent_id": null, "sort_order": 1 }
```

### 4.4 Xóa danh mục

```
DELETE /categories.php?id=5
Authorization: Bearer <admin_token>
```

> **Lưu ý:** SP thuộc danh mục bị xóa sẽ chuyển `loai_den` thành `"Chưa phân loại"`.

---

## 5. Users

**File:** `users.php`  
**Auth:** RBAC theo JWT permissions (trừ `target=profile` = customer tự sửa)

| Endpoint | Quyền |
|----------|--------|
| `GET ?scope=customers` | `customers` hoặc `admin` |
| `GET ?scope=admins` | `accounts` hoặc `admin` |
| `POST` role `staff` | `accounts` hoặc `admin` |
| `POST` role `admin` | Chỉ `admin` |
| `PUT target=customer` | `customers` hoặc `admin` |
| `PUT target=admin` (is_active, name…) | `accounts` hoặc `admin` |
| `PUT target=admin` (role, permissions, password) | Chỉ `admin` |
| `DELETE` | Chỉ `admin` |

### 5.1 Lấy danh sách

```
GET /users.php?scope=customers
GET /users.php?scope=admins
Authorization: Bearer <admin_token>
```

### 5.2 Thêm admin/staff

```
POST /users.php
Authorization: Bearer <admin_token>
```

```json
{
  "username": "staff01",
  "password": "matkhau123",
  "name": "Nhân viên A",
  "phone": "0901111111",
  "email": "staff@denhoamy.com",
  "role": "staff",
  "permissions": {
    "dashboard": true,
    "products": true,
    "orders": true,
    "categories": true,
    "reviews": true,
    "customers": false,
    "coupons": true,
    "news": true,
    "policy": true,
    "accounts": false,
    "settings": false
  }
}
```

### 5.3 Cập nhật

```
PUT /users.php
Authorization: Bearer <token>
```

**Targets:** `customer` (admin khoá/mở khoá) | `admin` (cập nhật admin) | `profile` (customer tự sửa)

```json
{
  "id": 5,
  "target": "profile",
  "name": "Tên mới",
  "email": "new@gmail.com",
  "phone": "0901234567",
  "address": "Địa chỉ mới"
}
```

### 5.4 Xóa admin

```
DELETE /users.php?id=2
Authorization: Bearer <super_admin_token>
```

> **Lưu ý:** Không thể xóa hoặc vô hiệu admin ID = 1 (admin gốc). Chỉ **Super Admin** (`role=admin`) mới xóa / đổi role / permissions.

**DB:** Bảng `admins` + `users` — migration [`mysql/migrate_user_rbac.sql`](../mysql/migrate_user_rbac.sql) cho phpMyAdmin.

---

## 6. Coupons

**File:** `coupons.php`  
**Auth:** Public (scope=public, apply) | Admin (CRUD)

### 6.1 Lấy danh sách (Public)

```
GET /coupons.php?scope=public
```

### 6.2 Lấy danh sách (Admin)

```
GET /coupons.php
Authorization: Bearer <admin_token>
```

### 6.3 Áp dụng mã giảm giá

```
POST /coupons.php
```

```json
{
  "action": "apply",
  "code": "SALE10",
  "order_value": 15000000
}
```

**Response:**
```json
{
  "success": true,
  "message": "Áp dụng mã thành công!",
  "data": {
    "code": "SALE10",
    "discount_amount": 1500000,
    "coupon_id": 3
  }
}
```

### 6.4 Tạo mã giảm giá

```
POST /coupons.php
Authorization: Bearer <admin_token>
```

```json
{
  "code": "NEWYEAR",
  "discount_percent": 15,
  "discount_amount": 0,
  "max_discount_amount": 2000000,
  "min_order_value": 5000000,
  "usage_limit": 100,
  "start_date": "2026-01-01",
  "end_date": "2026-01-31"
}
```

### 6.5 Cập nhật / Toggle Active

```
PUT /coupons.php
Authorization: Bearer <admin_token>
```

### 6.6 Xóa mã giảm giá

```
DELETE /coupons.php?id=3
Authorization: Bearer <admin_token>
```

---

## 7. Reviews

**File:** `reviews.php`  
**Auth:** GET (product_id) = Public | POST = Public | PUT, DELETE = Admin

### 7.1 Lấy đánh giá theo sản phẩm

```
GET /reviews.php?product_id=1
```

### 7.2 Lấy tất cả đánh giá (Admin)

```
GET /reviews.php
Authorization: Bearer <admin_token>
```

### 7.3 Gửi đánh giá

```
POST /reviews.php
```

```json
{
  "product_id": 1,
  "user_name": "Nguyễn Văn A",
  "rating": 5,
  "comment": "Sản phẩm rất đẹp!"
}
```

> **Lưu ý:** Đánh giá mới mặc định `is_approved = 0`, cần Admin duyệt.

### 7.4 Duyệt / Trả lời

```
PUT /reviews.php
Authorization: Bearer <admin_token>
```

```json
{ "id": 1, "is_approved": 1, "reply": "Cảm ơn Quý khách!" }
```

### 7.5 Xóa đánh giá

```
DELETE /reviews.php?id=1
Authorization: Bearer <admin_token>
```

---

## 8. News

**File:** `news.php`  
**Auth:** GET = Public | POST, PUT, DELETE = Admin

### 8.1 Lấy danh sách bài viết

```
GET /news.php
GET /news.php?admin=1    (bao gồm bài chưa publish)
```

### 8.2 Lấy bài viết theo slug

```
GET /news.php?slug=huong-dan-chon-den
```

> **Lưu ý:** Tự động tăng `view_count` khi đọc.

### 8.3 Thêm bài viết

```
POST /news.php
Authorization: Bearer <admin_token>
```

```json
{
  "title": "Hướng dẫn chọn đèn",
  "slug": "huong-dan-chon-den",
  "thumbnail": "/uploads/news/thumb.jpg",
  "summary": "Tổng hợp kinh nghiệm...",
  "content": "<h2>Nội dung bài viết HTML</h2>...",
  "author_id": 1,
  "is_published": 1
}
```

> **Validation:** `title`, `slug`, `content` là bắt buộc. Nếu thiếu sẽ trả 400.

### 8.4 Sửa bài viết

```
PUT /news.php
Authorization: Bearer <admin_token>
```

### 8.5 Xóa bài viết (Soft Delete)

```
DELETE /news.php?id=1
Authorization: Bearer <admin_token>
```

---

## 9. Upload

**File:** `upload.php`  
**Auth:** Admin  
**Method:** POST only

### 9.1 Upload file (multipart/form-data)

```
POST /upload.php?type=product
Content-Type: multipart/form-data
Authorization: Bearer <admin_token>
```

**Form Fields:**
- `file`: File ảnh (JPEG, PNG, GIF, WebP — max 10MB)
- `type`: `product` | `logo` | `banner` | `avatar` | `gallery` | `news_content` | `bank_qr`

> **Bảo mật:** Server kiểm tra MIME type thực tế bằng `finfo` (fallback `$_FILES['type']` nếu finfo không khả dụng). Chỉ chấp nhận `image/jpeg`, `image/png`, `image/gif`, `image/webp`.

**Response:**
```json
{
  "success": true,
  "url": "/uploads/products/product_6651a2b3c4d5e.jpg",
  "filename": "product_6651a2b3c4d5e.jpg"
}
```

### 9.2 Upload multiple files

```
POST /upload.php?type=gallery
```

**Form Fields:** `files[]` (multiple)

### 9.3 Upload Base64

```
POST /upload.php?type=logo
Content-Type: application/json
```

```json
{
  "base64": "data:image/png;base64,iVBORw0KGgo..."
}
```

### 9.4 Upload multiple Base64

```json
{
  "images": [
    "data:image/png;base64,...",
    "data:image/jpeg;base64,..."
  ]
}
```

---

## 10. Chatbot

**File:** `chatbot_engine.php`  
**Auth:** Public  
**Rate Limit:** Chatbot-specific  
**Engine:** Groq (LLaMA 4, tool calling) → Rule-based

### 10.1 Gửi tin nhắn

```
POST /chatbot_engine.php
```

```json
{
  "message": "Có đèn chùm pha lê không?",
  "history": [
    { "sender": "user", "text": "Xin chào" },
    { "sender": "bot", "text": "Chào Quý khách..." }
  ],
  "context": {
    "productId": 5,
    "route": "/product/5",
    "lastProductIds": [5, 12]
  }
}
```

**Response:**
```json
{
  "success": true,
  "reply": "Dạ, bên tôi có nhiều mẫu đèn chùm pha lê...\n\n| Tên | Giá | Loại |\n|---|---|---|\n| DC04303 | 18.000.000 VNĐ | Đèn chùm |",
  "engine": "groq",
  "products": [
    {
      "id": 5,
      "ten_san_pham": "Đèn chùm DC04303",
      "price": 18000000,
      "image_url": "https://...",
      "loai_den": "Đèn chùm",
      "stock": 15
    }
  ]
}
```

**Available Tools (AI Function Calling):**

| Tool | Mô tả |
|---|---|
| `search_products` | Tìm SP: keyword, loại, phong cách, khong_gian, kich_thuoc, price_min/max (giá bán/biến thể), hot deal. Server tự parse câu hỏi dạng **1–10 triệu**, **trên 10tr**, **dưới 5tr** và pre-search trước Groq |
| `get_product_specs` | Chi tiết 1 SP theo mã/ID/tên |
| `compare_products` | So sánh 2–3 SP theo `product_ids` |
| `list_product_types` | Liệt kê các loại đèn |
| `get_store_faq` | FAQ: giờ, ship, bảo hành (từ `policy_bao_hanh` settings), đổi trả, thanh toán, liên hệ |

---

## 11. Statistics

**File:** `statistics.php`  
**Auth:** Admin

### 11.1 Lấy thống kê dashboard

```
GET /statistics.php
Authorization: Bearer <admin_token>
```

**Response:**
```json
{
  "success": true,
  "data": {
    "revenue": [
      { "month": "Tháng 1", "amount": 50000000 },
      { "month": "Tháng 2", "amount": 75000000 }
    ],
    "categories": [
      { "category": "Đèn chùm", "sold_count": 25 }
    ],
    "topProducts": [
      { "id": 1, "name": "Đèn chùm DC04305", "sold_count": 10, "price": "15000000", "image": "..." }
    ],
    "lowStock": [
      { "id": 3, "name": "Đèn thả DT03308", "real_stock": 2 }
    ],
    "financials": {
      "total_revenue": 500000000,
      "total_profit": 200000000
    }
  }
}
```

---

## 12. Settings

**File:** `settings.php`  
**Auth:** GET = Public | PUT = Admin

### 12.1 Lấy cài đặt

```
GET /settings.php
```

**Response:**
```json
{
  "success": true,
  "data": {
    "shop_name": "ĐÈN HOA MỸ",
    "hotline": "0978897579",
    "email": "hieu.it@denhoamy.com",
    "address": "Hải Phòng, Việt Nam",
    "logo_url": "/uploads/logo/logo.png",
    "banner_urls": "[\"/uploads/banners/b1.jpg\", \"/uploads/banners/b2.jpg\"]",
    "bank_name": "Vietcombank",
    "bank_account_no": "0123456789",
    "bank_account_name": "CÔNG TY TNHH ĐÈN HOA MỸ",
    "bank_qr": "/uploads/banners/qr.jpg",
    "ads_left_url": "/uploads/banners/skyscraper_left.png",
    "ads_left_link": "/category?type=Đèn thả",
    "ads_right_url": "/uploads/banners/skyscraper_right.png",
    "ads_right_link": "/",
    "ads_bottom_url": "/uploads/banners/horizontal.jpg",
    "ads_bottom_link": "/category?type=Đèn chùm",
    "policy_bao_hanh": "<p>Nội dung HTML...</p>",
    "policy_doi_tra": "<p>...</p>",
    "policy_van_chuyen": "<p>...</p>",
    "policy_huong_dan": "<p>...</p>"
  }
}
```

> **Lưu ý:** `banner_urls` là JSON string chứa mảng URL (tối đa 6 banners). `ads_left/right` là banner dọc (skyscraper), `ads_bottom` là banner ngang. Các key `policy_*` dùng cho trang `/policy` và FAQ chatbot.

### 12.2 Cập nhật cài đặt

```
PUT /settings.php
Authorization: Bearer <admin_token>
```

```json
{
  "shop_name": "ĐÈN HOA MỸ",
  "hotline": "0978897579",
  "email": "hieu.it@denhoamy.com",
  "banner_urls": "[\"/uploads/banners/b1.jpg\"]",
  "ads_left_url": "/uploads/banners/skyscraper_left.png",
  "ads_left_link": "/category?type=Đèn thả",
  "ads_bottom_url": "/uploads/banners/horizontal.jpg",
  "ads_bottom_link": "/category?type=Đèn chùm"
}
```

> **Lưu ý:** API sử dụng `INSERT ... ON DUPLICATE KEY UPDATE` — gửi key nào cập nhật key đó, không cần gửi hết.

> **Phân quyền policy:** PUT các key `policy_*` yêu cầu permission `policy` (staff) hoặc `admin`.

---

## 13. Wishlist

**File:** `wishlist.php`  
**Auth:** Customer only

### 13.1 Lấy danh sách yêu thích

```
GET /wishlist.php
Authorization: Bearer <customer_token>
```

### 13.2 Thêm / Bỏ yêu thích (Toggle)

```
POST /wishlist.php
Authorization: Bearer <customer_token>
```

```json
{ "product_id": 5 }
```

**Response:**
```json
{ "success": true, "action": "added", "message": "Đã thêm vào mục yêu thích" }
```
hoặc
```json
{ "success": true, "action": "removed", "message": "Đã bỏ yêu thích" }
```

---

## 17. Cart

**File:** `cart.php`  
**Auth:** Customer only (`role = customer`)

Giỏ hàng được lưu trên server theo `user_id`. Khách chưa đăng nhập vẫn dùng `localStorage` phía Vue.

### 17.1 Lấy giỏ hàng

```
GET /cart.php
Authorization: Bearer <customer_token>
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "12",
      "code": "SP001",
      "name": "Đèn chùm ...",
      "image": "/uploads/...",
      "price": 1500000,
      "stock": 5,
      "quantity": 2,
      "cart_item_id": 3,
      "product_id": 12,
      "variant_id": null
    }
  ]
}
```

`id` là composite (`product_id` hoặc `product_id_variantId`) khớp format giỏ Vue.

### 17.2 Đồng bộ toàn bộ giỏ (replace)

```
PUT /cart.php
Authorization: Bearer <customer_token>
```

```json
{
  "items": [
    { "id": "12", "quantity": 2 },
    { "id": "5_3", "quantity": 1 }
  ]
}
```

Hoặc `{ "product_id": 12, "variant_id": null, "quantity": 2 }`.

**Response:** `{ "success": true, "message": "...", "data": [ ...items enriched... ] }`

### 17.3 Xóa giỏ

```
DELETE /cart.php?clear=1
Authorization: Bearer <customer_token>
```

Xóa một dòng: `DELETE /cart.php?item_id=3` (`item_id` = `cart_items.id`).

---

## 14. Inventory

**File:** `inventory.php`
**Auth:** Admin

### 14.1 Lấy lịch sử nhập kho

```
GET /inventory.php
Authorization: Bearer <admin_token>
```

### 14.2 Nhập kho

```
POST /inventory.php
Authorization: Bearer <admin_token>
```

```json
{
  "product_id": 1,
  "quantity": 10,
  "cost": 8000000,
  "note": "Nhập lô mới từ nhà cung cấp",
  "admin_id": 1
}
```

> **Lưu ý:** Tự động cập nhật `products.stock` và `products.cost_price`.

---

## 15. Forgot Password

**File:** `forgot-password.php`  
**Auth:** Public  
**Rate Limit:** Strict (5/phút)

### 15.1 Yêu cầu reset

```
POST /forgot-password.php
```

```json
{
  "action": "request",
  "phone": "0901234567"
}
```

> **Lưu ý:** Luôn trả response thành công (chống enumeration). Magic link gửi qua email đăng ký (Resend API).

### 15.2 Đặt lại mật khẩu

```
POST /forgot-password.php
```

```json
{
  "action": "reset",
  "token": "abc123...",
  "password": "matkhaumoi",
  "confirmPassword": "matkhaumoi"
}
```

---

## 16. PayOS Webhook

**File:** `payos_webhook.php`  
**Auth:** Webhook Signature (HMAC)  
**Caller:** PayOS Server → Backend

```
POST /payos_webhook.php
```

**Xử lý:**
1. Xác thực chữ ký webhook (checksum key)
2. Tìm đơn hàng theo `orderCode`
3. So khớp số tiền
4. `code = "00"` → Cập nhật: `orders.status = 'approved'` + `payments.status = 'completed'`
5. Lỗi DB → trả 503 để PayOS retry

---

## HTTP Status Codes

| Code | Ý nghĩa |
|---|---|
| `200` | Thành công |
| `201` | Tạo mới thành công |
| `400` | Dữ liệu không hợp lệ |
| `401` | Chưa đăng nhập / Token hết hạn |
| `403` | Không đủ quyền |
| `404` | Không tìm thấy |
| `405` | Method không hỗ trợ |
| `422` | Validation Error |
| `409` | Xung đột (VD: còn đơn PayOS pending) |
| `429` | Rate Limit (quá nhiều request) |
| `500` | Lỗi server |
| `503` | Service không khả dụng (DB lỗi, retry) |

---

## Response Format

Tất cả API trả về JSON với cấu trúc:

```json
{
  "success": true|false,
  "message": "Thông báo (nếu có)",
  "data": { ... },
  "pagination": { ... }
}
```

**Validation Error (422):**
```json
{
  "success": false,
  "message": "Dữ liệu không hợp lệ",
  "errors": [
    "Họ tên không được để trống",
    "Số điện thoại không hợp lệ"
  ]
}
```
