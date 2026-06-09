# Checklist Screenshot cho Slide

> Lưu ảnh vào `docs/presentation/assets/` với tên file gợi ý bên dưới.  
> Chạy app: `docker-compose up -d --build` → http://localhost:3000

## Tài khoản test

| Loại | Username | Password | URL |
|------|----------|----------|-----|
| Admin | `admin` | `123456` | http://localhost:3000/admin |
| Customer | (tự đăng ký hoặc seed DB) | — | http://localhost:3000/login |

---

## Danh sách 10 screenshot bắt buộc

| # | File gợi ý | Slide | URL / Hành động | Nội dung cần thấy |
|---|------------|-------|-----------------|-------------------|
| 1 | `01-home-desktop.png` | 21 | `/` | Banner carousel, Hot Deal, navbar sticky |
| 2 | `02-category-filter.png` | 21 | `/category` | Filter loại đèn, sort, skeleton đã load xong |
| 3 | `03-product-detail.png` | 22 | `/product/:id` | Gallery, biến thể, đánh giá, SP liên quan |
| 4 | `04-cart-mobile.png` | 23 | `/cart` (DevTools mobile 375px) | Layout card mobile |
| 5 | `05-checkout.png` | 24 | `/checkout` | Giao hàng/nhận shop, COD/PayOS/pay_at_store, coupon |
| 6 | `06-admin-dashboard.png` | 28 | `/admin` → Dashboard | Chart.js doanh thu, top SP, export Excel |
| 7 | `07-admin-orders.png` | 28 | Admin → Đơn hàng | Filter, trạng thái đơn |
| 8 | `08-admin-users-rbac.png` | 29 | Admin → Tài khoản/KH | Phân quyền staff hoặc danh sách admin |
| 9 | `09-chatbot.png` | 30 | Mở ChatWidget góc phải | Câu hỏi + trả lời có sản phẩm/giá |
| 10 | `10-profile-orders.png` | 27 | `/profile` | Lịch sử đơn, nút xác nhận đã nhận (nếu có đơn shipping) |

---

## Screenshot bổ sung (tuỳ chọn)

| File | Slide | Mô tả |
|------|-------|-------|
| `11-payment-result.png` | 25 | `/payment/success` sau PayOS hoặc mock |
| `12-payos-pending-dialog.png` | 25 | Dialog đơn PayOS pending khi checkout lần 2 |
| `13-admin-settings.png` | 31 | Banner, logo, QR trong AdminSettings |
| `14-news-detail.png` | — | Trang tin tức SEO slug |
| `15-docker-ps.png` | 31 | Terminal `docker-compose ps` 4 container running |

---

## Yêu cầu kỹ thuật

- Độ phân giải: ≥ 1920×1080 (desktop), 390×844 (mobile)
- Che/thay email-SĐT thật nếu cần
- Trình duyệt: Chrome, zoom 100%
- Chụp khi data đã load (không skeleton, không lỗi API)

---

## Map sơ đồ → slide

| Sơ đồ | File nguồn | Slide |
|-------|------------|-------|
| D1 Kiến trúc 3-tier | [SLIDE_DIAGRAMS.md](SLIDE_DIAGRAMS.md) D1 | 13 |
| D2 Docker | D2 | 14 |
| D3 Request lifecycle | D3 | 18 |
| D4 Giỏ hàng | D4 | 23 |
| D5 Order + PayOS | D5 | 24–25 |
| D6 Status machine | D6 | 27 |
| D8 Chatbot | D8 | 30 |
| D9 ERD | D9 | 16 |
| D10 RBAC | D10 | 29 |
| D11 Bảo mật | D11 | 19 |
| D12 Use case | D12 | 10 |
