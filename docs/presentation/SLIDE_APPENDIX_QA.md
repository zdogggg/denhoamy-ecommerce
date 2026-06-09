# Appendix Slide & Q&A — Bảo vệ Đèn Hoa Mỹ

> **Không trình bày** trong phần chính — mở khi hội đồng hỏi sâu.  
> Giữ file PowerPoint appendix sau slide 38 (slide A1–A5).

---

## Appendix A1 — JWT Authentication Flow

**Câu hỏi thường gặp:** *"Hệ thống xác thực như thế nào?"*

**Trả lời ngắn (30 giây):**
> Khách đăng nhập qua `auth.php`, server verify bcrypt rồi cấp JWT HMAC-SHA256, hết hạn 24h. Mọi request sau gửi header `Authorization: Bearer`. Axios interceptor bắt 401 → logout đồng bộ.

**Slide content:**
- Payload JWT: `{ sub, role, name, exp, table }`
- Không lưu session server-side — stateless
- File: `denhoamy_api/lib/jwt_helper.php`, `my-vue-app/src/services/httpClient.js`

**Visual:** Sơ đồ D7 trong [SLIDE_DIAGRAMS.md](SLIDE_DIAGRAMS.md)

---

## Appendix A2 — PayOS Webhook Security

**Câu hỏi:** *"Làm sao đảm bảo webhook PayOS không bị giả mạo?"*

**Trả lời ngắn:**
> `payos_webhook.php` đọc raw body, tính HMAC-SHA256 từ các field theo spec PayOS, so sánh signature. Không khớp → 400 + log warning. Chỉ khi `code = "00"` mới cập nhật đơn `approved`.

**Slide content:**
```
PayOS Server ──POST──▶ payos_webhook.php
                              │
                     verifyWebhookSignature()
                              │
                     Match → update order
                     Mismatch → 400 Bad Request
```

**File:** `denhoamy_api/lib/payos_helper.php`, `payos_webhook.php`

---

## Appendix A3 — Tại sao không dùng Laravel?

**Câu hỏi:** *"Sao không dùng framework PHP phổ biến?"*

**Trả lời ngắn (trung thực):**
> Thời gian đồ án và mục tiêu kiểm soát từng endpoint. Core PHP + lib/ middleware giúp hiểu rõ request lifecycle. Hạn chế: code dài, tái sử dụng thấp — **hướng phát triển: migrate Laravel + OpenAPI**.

**Slide content:**

| Lý do chọn Core PHP | Hạn chế | Hướng khắc phục |
|---------------------|---------|-----------------|
| Học tập, kiểm soát API | Khó scale team | Laravel MVC |
| Deploy Docker đơn giản | Không ORM | Eloquent + migrations |
| Đủ cho quy mô shop vừa | Thiếu Swagger | OpenAPI `/api/v1` |

---

## Appendix A4 — Polling vs WebSocket (Admin notify)

**Câu hỏi:** *"Thông báo đơn realtime chưa?"*

**Trả lời ngắn:**
> Hiện tại **HTTP polling 5 giây** trong `AdminView.vue` — gọi `GET orders.php`, so sánh count `pending`, toast khi tăng. Tab ẩn thì pause poll. **Chưa WebSocket/SSE** — độ trễ tối đa ~5s, đủ cho quy mô shop. Production scale → SSE hoặc WebSocket.

**Slide content:**
- Ưu điểm polling: đơn giản, không cần server push infra
- Nhược điểm: latency, tải API lặp
- Hướng: Server-Sent Events + Redis pub/sub

**File:** `my-vue-app/src/views/AdminView.vue` (poll interval 5s)

---

## Appendix A5 — SQL Injection & XSS

**Câu hỏi:** *"Chống SQL injection và XSS thế nào?"*

**Trả lời ngắn:**

**SQL Injection:**
- PDO prepared statements toàn bộ query
- `EMULATE_PREPARES = false`
- Không nối chuỗi SQL với input user

**XSS:**
- `sanitizeString()` strip HTML phía server
- Tin tức: `sanitizeNewsHtml()` + DOMPurify client
- Chatbot: `renderSafeMarkdown()` + DOMPurify

**File:** `denhoamy_api/lib/validator.php`, `my-vue-app/src/utils/chatMarkdown.js`

---

## Bảng câu hỏi hội đồng — Quick reference

| Câu hỏi | Trả lời 1 câu | Appendix |
|---------|---------------|----------|
| Xác thực? | JWT Bearer 24h, bcrypt password | A1 |
| PayOS an toàn? | Webhook HMAC verify, chặn pending trùng 409 | A2 |
| Oversell kho? | Transaction + SELECT FOR UPDATE | Slide 26 |
| Chatbot sai? | Tool calling query DB + rule fallback | Slide 30 |
| SEO SPA? | Meta động client; hướng Nuxt SSR | Slide 34–35 |
| Scale nhiều user? | Redis cache, CDN, load balancer | Slide 35 |
| Test tự động? | Smoke PHP; chưa Vitest/Playwright | Slide 32 |
| Phân quyền staff? | RBAC 11 keys, admin_route_guard | Slide 29 |
| Giỏ guest? | localStorage; chưa session_id server | Slide 34 |
| Docker production? | DEPLOY.md: HTTPS, JWT secret, backup | Slide 31 |

---

## Mẹo trả lời Q&A

1. **Nghe hết câu hỏi** — xin 2 giây suy nghĩ nếu cần
2. **Trả lời ngắn trước**, chi tiết sau nếu hội đồng hỏi tiếp
3. **Thừa nhận hạn chế** thay vì biện minh — kèm hướng khắc phục
4. **Không nói "realtime"** cho admin poll — nói **"cập nhật định kỳ 5 giây"**
5. Mở appendix slide tương ứng khi câu hỏi kỹ thuật sâu

---

## Liên kết

- Outline 38 slide: [SLIDE_OUTLINE.md](SLIDE_OUTLINE.md)
- Sơ đồ JWT (D7): [SLIDE_DIAGRAMS.md](SLIDE_DIAGRAMS.md)
- Hạn chế đầy đủ: [HAN_CHE_DO_AN.md](../HAN_CHE_DO_AN.md)
