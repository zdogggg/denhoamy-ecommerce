# Kịch bản Demo Live — Bảo vệ Đèn Hoa Mỹ

> Thời lượng mục tiêu: **5–7 phút** | Rehearse tối thiểu **2 lần** trước ngày bảo vệ

---

## Chuẩn bị trước demo (T-30 phút)

### 1. Khởi động hệ thống

```bash
cd "e:\Test Vue"
docker-compose up -d --build
docker-compose ps
```

Kiểm tra 4 service `running`: `frontend`, `api`, `db`, `phpmyadmin`.

### 2. Smoke test nhanh

- Mở http://localhost:3000 — trang chủ load OK
- Mở http://localhost:3000/admin — redirect login
- API: http://localhost:8080/products.php — JSON response

### 3. Tài khoản & dữ liệu

| Mục | Giá trị |
|-----|---------|
| Admin | `admin` / `123456` |
| Customer | Đăng ký trước: `demo_customer` / `Demo@123456` hoặc dùng account có sẵn |
| Sản phẩm demo | Chọn SP **còn tồn kho ≥ 2**, có biến thể (slide 22) |
| Coupon test | Tạo trong Admin → Mã giảm giá (VD: `DEMO10`, giảm 10%, còn hiệu lực) |

### 4. Trình duyệt

- **Tab 1:** Customer (incognito) — http://localhost:3000
- **Tab 2:** Admin — http://localhost:3000/admin (đăng nhập sẵn)
- Đóng tab/chat không cần thiết, zoom 100%

### 5. Backup plan

| Tình huống | Xử lý |
|------------|-------|
| PayOS lỗi / sandbox down | Demo **COD** + nói luồng PayOS bằng slide 25 |
| Docker không lên | Video quay sẵn 2–3 phút HOẶC screenshot + slide |
| Chatbot Groq hết quota | Hỏi câu FAQ đơn giản (*"Giờ mở cửa?"*) → rule-based fallback |
| Mạng chậm | Bỏ bước 6 (confirm_received), rút demo còn 4 bước |

---

## Kịch bản chi tiết

### Bước 1 — Duyệt sản phẩm (~1.5 phút)

**Slide liên quan:** 21, 22

**Lời dẫn mẫu:**
> "Em demo luồng khách hàng từ trang chủ. Trang chủ có banner carousel, Hot Deal và sản phẩm mới."

**Hành động:**
1. Trang chủ `/` — chỉ banner, Hot Deal
2. Navbar → Danh mục hoặc `/category`
3. Filter loại đèn / sort giá
4. Click 1 sản phẩm → chi tiết
5. Chọn biến thể → **Thêm vào giỏ**
6. (Tuỳ chọn) Chỉ nhãn giá **「Từ」** nếu SP nhiều giá biến thể

---

### Bước 2 — Checkout (~1 phút)

**Slide liên quan:** 23, 24

**Lời dẫn mẫu:**
> "Checkout yêu cầu đăng nhập. Giỏ hàng customer được đồng bộ server qua cart.php và merge khi login."

**Hành động:**
1. Vào giỏ `/cart` — xác nhận sản phẩm
2. **Đăng nhập** customer (nếu chưa)
3. **Thanh toán** → `/checkout`
4. Chọn **Giao hàng tận nhà** + **COD** (an toàn cho demo)
5. Nhập địa chỉ (data test)
6. Áp coupon `DEMO10` (nếu có)
7. **Đặt hàng** → thông báo thành công

---

### Bước 3 — Thanh toán (~1 phút)

**Slide liên quan:** 25, 26

**Phương án A — COD (khuyến nghị):**
> "Với COD, đơn tạo ở trạng thái pending, server đã khóa tồn kho bằng transaction FOR UPDATE."

**Phương án B — PayOS (nếu mạng ổn):**
1. Checkout chọn **PayOS**
2. Redirect sandbox PayOS → thanh toán test
3. Quay về `/payment/success` — poll status
4. Nếu muốn show pending: mở tab mới checkout PayOS lần 2 → dialog 409/pending

---

### Bước 4 — Admin duyệt đơn (~1 phút)

**Slide liên quan:** 28, 27

**Lời dẫn mẫu:**
> "Admin dashboard poll đơn pending mỗi 5 giây qua HTTP. Khi có đơn mới sẽ hiện toast notification."

**Hành động:**
1. Chuyển **Tab Admin** (đã login `admin`)
2. Chờ toast đơn pending (hoặc vào module **Đơn hàng**)
3. Mở đơn vừa tạo → **Duyệt** (`approved`)
4. (Tuỳ chọn) Chỉ dashboard Chart.js, top SP

**Lưu ý khi bị hỏi:** Đây là **polling 5s**, chưa WebSocket.

---

### Bước 5 — AI Chatbot (~1 phút)

**Slide liên quan:** 30

**Lời dẫn mẫu:**
> "Chatbot dùng Groq LLaMA 4 với function calling — truy vấn kho thật trên MySQL, không trả lời bịa."

**Hành động:**
1. Click icon chat góc phải
2. Gõ: **"Có đèn chùm phòng khách dưới 5 triệu không?"**
3. Chờ reply — highlight danh sách SP + giá
4. (Tuỳ chọn) Hỏi: **"Chính sách bảo hành?"** → FAQ tool

---

### Bước 6 — Xác nhận nhận hàng (tuỳ chọn, ~30 giây)

**Slide liên quan:** 27

**Điều kiện:** Cần đơn ở trạng thái `shipping` (admin cập nhật hoặc cron)

**Hành động:**
1. Tab customer → `/profile` → tab Đơn hàng
2. Nút **Xác nhận đã nhận hàng**

*Nếu không có đơn shipping: bỏ bước này, giải thích bằng slide 27.*

---

## Checklist ngày bảo vệ

- [ ] Laptop sạc đầy, mang adapter
- [ ] Docker image đã build sẵn (tránh build lâu trước hội đồng)
- [ ] Backup: USB copy video demo HOẶC folder screenshot
- [ ] `.env` có GROQ_API_KEY, PayOS keys (nếu demo PayOS)
- [ ] Tắt notification OS không liên quan
- [ ] Rehearse đo thời gian — mục tiêu **≤ 7 phút**

---

## Timing sheet (in ra rehearse)

| Bước | Mục tiêu | Thực tế (điền khi rehearse) |
|------|----------|----------------------------|
| 1 Duyệt SP | 1:30 | |
| 2 Checkout | 1:00 | |
| 3 Thanh toán | 1:00 | |
| 4 Admin | 1:00 | |
| 5 Chatbot | 1:00 | |
| 6 Profile (opt) | 0:30 | |
| **Tổng** | **6:00** | |

---

## Liên kết slide

- Outline đầy đủ: [SLIDE_OUTLINE.md](SLIDE_OUTLINE.md)
- Screenshot cần chụp: [SLIDE_SCREENSHOTS.md](SLIDE_SCREENSHOTS.md)
- Câu hỏi hội đồng: [SLIDE_APPENDIX_QA.md](SLIDE_APPENDIX_QA.md)
