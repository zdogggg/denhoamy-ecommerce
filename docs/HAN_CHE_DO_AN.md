# Hạn chế của hệ thống và hướng phát triển

> Tài liệu tham khảo cho Chương kết luận / Đánh giá đồ án — Website thương mại điện tử Đèn Hoa Mỹ.  
> **Cập nhật:** 06/06/2026 (PayOS pending flow, nhận tại shop, xác nhận đã nhận hàng, session expired).

---

## 0. Các hạng mục đã hoàn thiện (đối chiếu codebase)

Nhóm đã bổ sung một số cơ chế quan trọng; phần dưới vẫn liệt kê **hạn chế còn lại**, không phủ nhận kết quả đạt được:

| Hạng mục | Mô tả ngắn |
|----------|------------|
| Khóa tồn kho đặt hàng | `normalizeOrderItemsInTransaction()` — `SELECT … FOR UPDATE` trong transaction, trừ kho `stock - qty` ([`order_pricing.php`](../denhoamy_api/lib/order_pricing.php), [`orders.php`](../denhoamy_api/orders.php)) |
| Giỏ hàng customer | API [`cart.php`](../denhoamy_api/cart.php) + Pinia sync/merge khi đăng nhập; khách chưa login vẫn `localStorage` |
| Sản phẩm liên quan | Trang chi tiết gọi API `type` + `exclude_id` + `limit` (không tải full catalog) |
| Thông báo đơn admin | HTTP **polling 5 giây** + `ElNotification` khi số đơn `pending` tăng — **chưa dùng WebSocket/SSE** |
| Smoke test backend | [`order_status_smoke.php`](../denhoamy_api/tests/order_status_smoke.php), [`order_stock_smoke.php`](../denhoamy_api/tests/order_stock_smoke.php) |
| Tài khoản khách (mobile) | [`ProfileView.vue`](../my-vue-app/src/views/ProfileView.vue) — CSS Grid 1 cột ≤992px, tab ngang, đơn/yêu thích dạng thẻ; [`useMobileLayout.js`](../my-vue-app/src/composables/useMobileLayout.js) |
| Giá sản phẩm (admin + hiển thị) | Giá cũ tùy chọn (không tự = giá bán); nhãn **「Từ」** khi biến thể có giá bán khác nhau — [`productPrice.js`](../my-vue-app/src/utils/productPrice.js) |
| Hot Deal — snapshot giá | Lưu `price_before_hot_deal` / `old_price_before_hot_deal` khi bật hoặc lưu giá KM; **gỡ Hot Deal** khôi phục giá — [`hot_deal_snapshot.php`](../denhoamy_api/lib/hot_deal_snapshot.php), migration [`migrate_hot_deal_price_snapshot.sql`](../mysql/migrate_hot_deal_price_snapshot.sql). **Chưa** tự gỡ theo ngày hết hạn. |
| Giao hàng / nhận tại shop | `deliveryMethod` (`home`/`store`) + PTTT `pay_at_store`; validate combo server — [`validator.php`](../denhoamy_api/lib/validator.php), [`CheckoutView.vue`](../my-vue-app/src/views/CheckoutView.vue) |
| PayOS — đơn pending | Chặn tạo đơn trùng (409); `pending_payos`, `retry_payos`, `cancel_pending`; UI dialog + `PaymentResultView` poll — [`payos_order_helpers.php`](../denhoamy_api/lib/payos_order_helpers.php) |
| Xác nhận đã nhận hàng | Customer `confirm_received` khi đơn `shipping` — [`orders.php`](../denhoamy_api/orders.php), [`ProfileView.vue`](../my-vue-app/src/views/ProfileView.vue) |
| CMS chính sách | Admin module `AdminPolicy.vue` + trang `/policy` — keys `policy_*` trong `settings` |
| Session hết hạn | Axios 401 → logout đồng bộ — [`sessionExpired.js`](../my-vue-app/src/utils/sessionExpired.js), [`httpClient.js`](../my-vue-app/src/services/httpClient.js) |
| Nền tảng sẵn có | JWT, RBAC, prepared statements, transaction đơn hàng, Docker, PayOS webhook, tài liệu API Markdown |

---

## 1. Hạn chế

Mặc dù hệ thống website của nhóm đã đáp ứng được các yêu cầu cơ bản về chức năng đề ra và có thể đưa vào sử dụng trong thực tế, tuy nhiên trong quá trình thực hiện đề tài do yếu tố thời gian và sự thiếu kinh nghiệm trong quá trình làm bài nên đồ án của nhóm vẫn còn tồn tại một số hạn chế nhất định:

**Thứ nhất**, tầng xử lý nghiệp vụ phía máy chủ (backend) được xây dựng chủ yếu bằng Core PHP, với các endpoint tách theo từng file (`products.php`, `orders.php`, …) thay vì tổ chức theo các mô hình phát triển hiện đại như MVC hoặc các framework phổ biến như Laravel. Điều này khiến mã nguồn phía server còn khá dài, độ tái sử dụng chưa cao và gây khó khăn trong quá trình bảo trì, nâng cấp hoặc mở rộng hệ thống trong tương lai. Mặc dù đã có [`API_DOCUMENTATION.md`](../denhoamy_api/API_DOCUMENTATION.md), hợp đồng API chưa được chuẩn hóa bằng OpenAPI/Swagger và chưa có kiểm thử tích hợp tự động giữa frontend–backend.

**Thứ hai**, các thao tác truy xuất cơ sở dữ liệu của nhóm hiện chủ yếu được thực hiện thông qua các câu lệnh SQL viết trực tiếp trong mã nguồn PHP. Khi số lượng chức năng và dữ liệu tăng lên, các truy vấn trở nên dài và phức tạp hơn, gây khó khăn cho việc quản lý, bảo trì cũng như tối ưu hiệu suất hệ thống. Bên cạnh đó, hệ thống chưa áp dụng ORM hoặc Query Builder.

**Thứ ba**, hệ thống website hiện chưa triển khai cơ chế lưu trữ tạm (cache) đối với **dữ liệu nghiệp vụ thường xuyên truy vấn** từ cơ sở dữ liệu (ví dụ: danh mục, danh sách sản phẩm nổi bật, thống kê dashboard). Mặc dù đã có cache tĩnh cho file build frontend trên Nginx và lưu trữ nhẹ trên trình duyệt (`localStorage`), trong trường hợp lượng dữ liệu lớn hoặc số lượng người dùng truy cập đồng thời tăng cao, hệ thống vẫn có thể phát sinh thêm nhiều truy vấn đến MySQL. Các giải pháp cache phân tán như Redis hoặc Memcached chưa được tích hợp.

**Thứ tư**, mặc dù nhóm đã tích hợp ChatBot AI hỗ trợ tư vấn khách hàng thông qua API Groq (mô hình ngôn ngữ lớn kết hợp tool calling truy vấn kho hàng thực tế), chatbot vẫn phụ thuộc vào dịch vụ bên thứ ba, chịu giới hạn rate limit và có cơ chế fallback dựa trên quy tắc (rule-based) khi API lỗi hoặc hết quota. Hệ thống cũng chưa có cơ chế huấn luyện hoặc fine-tune riêng trên dữ liệu nội bộ của cửa hàng.

**Thứ năm**, hệ thống chưa tích hợp chức năng gợi ý sản phẩm thông minh (AI Recommendation). Đã có wishlist API và block sản phẩm liên quan theo **cùng danh mục** (`loai_den`) phía server; tuy nhiên chưa khai thác lịch sử đơn hàng, wishlist và hành vi xem để cá nhân hóa (collaborative filtering / ML).

**Thứ sáu**, quy trình kiểm thử tự động và CI/CD chưa đầy đủ. Hiện có script smoke test phía backend (`order_status_smoke.php`, `order_stock_smoke.php`); phía frontend (Vue) chưa có unit test hoặc end-to-end test. Các thay đổi phần lớn vẫn kiểm tra thủ công trên Docker local / VPS trước khi vận hành.

**Thứ bảy**, giỏ hàng **khách chưa đăng nhập** vẫn chủ yếu lưu `localStorage`; chưa triển khai giỏ theo `session_id` trên server cho guest. Tài khoản **customer** đã đồng bộ giỏ qua `cart.php` (GET/PUT/DELETE) và merge khi login — chưa thu thập đầy đủ phân tích “thêm giỏ chưa thanh toán” cho toàn bộ khách vãng lai.

**Thứ tám**, website được triển khai theo mô hình Single Page Application (Vue 3). Việc tối ưu SEO chủ yếu dựa trên cập nhật thẻ meta động phía client (`title`, Open Graph, canonical), chưa áp dụng SSR hoặc SSG.

**Thứ chín**, hệ thống phụ thuộc vào nhiều dịch vụ bên thứ ba: **Groq**, **PayOS**, **Resend**. Khi một dịch vụ gặp sự cố hoặc thay đổi chính sách API, trải nghiệm tương ứng có thể bị ảnh hưởng.

**Thứ mười**, ảnh sản phẩm và media upload được lưu trữ cục bộ trên máy chủ (`uploads/`), chưa tích hợp CDN hoặc object storage trên cloud.

**Thứ mười một**, rate limiting dùng lưu trữ file tạm trên đĩa, phù hợp môi trường đơn instance; khi scale nhiều container API song song cần Redis tập trung.

**Thứ mười hai**, thông báo đơn mới cho quản trị viên dùng **HTTP polling 5 giây** (gọi `GET orders.php`, so sánh số đơn `pending`, hiển thị `ElNotification`) — **không phải WebSocket hay SSE**. Độ trễ tối đa khoảng 5 giây; khi tab admin ẩn thì tạm dừng poll. Chưa có APM, cảnh báo lỗi tập trung hay audit log thao tác admin.

**Thứ mười ba**, mã nguồn frontend sử dụng JavaScript thuần, chưa chuyển sang TypeScript.

**Thứ mười bốn**, hệ thống mới hỗ trợ tiếng Việt, chưa triển khai i18n; chưa xây dựng PWA hoặc ứng dụng mobile native. Giao diện web đã responsive (giỏ hàng, tài khoản khách, header mobile) nhưng chưa có app native.

---

## 2. Hướng phát triển (gợi ý đi kèm từng nhóm hạn chế)

| Hạn chế | Hướng khắc phục đề xuất |
|--------|-------------------------|
| Backend Core PHP | Chuyển dần sang Laravel hoặc tách service theo lớp Repository; OpenAPI + versioning `/api/v1` |
| SQL thủ công | Eloquent ORM hoặc Query Builder; migration có kiểm soát |
| Thiếu cache DB | Redis cache cho danh mục, sản phẩm hot, thống kê dashboard |
| Chatbot | Fine-tune / RAG trên FAQ và catalog; giảm phụ thuộc một nhà cung cấp LLM |
| Gợi ý sản phẩm | Collaborative filtering; gợi ý theo đơn + wishlist + danh mục đã xem |
| Thiếu test/CI/CD | PHPUnit + Vitest/Playwright; GitHub Actions |
| Giỏ guest | `session_id` + API giỏ cho khách chưa login |
| SEO SPA | Nuxt SSR/SSG hoặc prerender trang SP/tin tức |
| Dịch vụ bên thứ ba | Retry, circuit breaker, theo dõi SLA |
| Media local | CDN + S3/Cloudinary; WebP, lazy load |
| Rate limit file | Redis rate limiter dùng chung giữa instance |
| Thông báo admin | **SSE hoặc WebSocket** thay polling; Web Push khi tab đóng |
| JavaScript | Migration TypeScript từng module |
| Đa ngôn ngữ / mobile | vue-i18n; PWA hoặc app gọi API hiện có |

---

## 3. Ghi chú khi chép vào Word

- Có thể **rút gọn** từ Thứ sáu trở đi thành 2–3 đoạn gộp nếu báo cáo giới hạn số trang.
- Mục **§0** dùng cho phần “kết quả đạt được”; mục **§1** là hạn chế còn lại.
- Khi trình bày miệng về “realtime đơn hàng”: nói rõ **polling HTTP 5s**, **chưa WebSocket**; WebSocket là hướng mở rộng trên production khi cần độ trễ dưới 1 giây.

---

## 4. Mục 4.2 — Hai ý bổ sung (chép thẳng vào Word)

Đặt sau **9 ý** Laravel → Chatbot (hoặc đánh số **Thứ mười**, **Thứ mười một**). Có thể chỉnh “Thứ chín” thành “Thứ chín (Chatbot)” nếu đã dùng số cho các ý trước.

**Thứ mười**, nhóm hướng tới tối ưu hạ tầng kỹ thuật và quy trình vận hành nhằm nâng cao độ ổn định cũng như khả năng mở rộng của hệ thống khi lượng truy cập và dữ liệu gia tăng. Cụ thể, nhóm dự kiến triển khai cơ chế lưu trữ tạm (cache) phân tán bằng Redis cho các dữ liệu được truy vấn thường xuyên như danh mục sản phẩm, sản phẩm nổi bật và thống kê trên trang quản trị; chuyển lưu trữ hình ảnh và media từ thư mục cục bộ trên máy chủ sang CDN hoặc dịch vụ object storage trên cloud; đồng thời chuẩn hóa hợp đồng API theo chuẩn OpenAPI/Swagger và áp dụng kiểm thử tự động (PHPUnit phía backend, Vitest hoặc Playwright phía frontend) kết hợp pipeline CI/CD để giảm rủi ro khi triển khai phiên bản mới. Bên cạnh đó, nhóm sẽ nâng cấp cơ chế thông báo đơn hàng mới cho quản trị viên từ polling HTTP định kỳ sang Server-Sent Events (SSE) hoặc WebSocket nhằm rút ngắn độ trễ cập nhật trạng thái, đồng thời bổ sung nhật ký kiểm toán (audit log) các thao tác quan trọng trên khu vực quản trị. Các hướng này góp phần đưa website tiến gần hơn tới mô hình vận hành chuyên nghiệp, phù hợp với yêu cầu chuyển đổi số bền vững của cửa hàng.

**Thứ mười một**, nhóm sẽ tiếp tục cải thiện khả năng tiếp cận và trải nghiệm người dùng trên nhiều kênh. Về mặt công nghệ, website hiện triển khai theo mô hình Single Page Application (Vue 3) với cập nhật thẻ meta động phía client; trong tương lai nhóm nghiên cứu áp dụng Server-Side Rendering (SSR) hoặc Static Site Generation (SSG) thông qua Nuxt hoặc prerender các trang sản phẩm và tin tức nhằm tăng hiệu quả index trên công cụ tìm kiếm. Đồng thời, nhóm có thể triển khai đa ngôn ngữ (i18n), xây dựng Progressive Web App (PWA) hoặc ứng dụng di động gọi chung API hiện có, và đồng bộ giỏ hàng khách chưa đăng nhập theo phiên (`session_id`) trên máy chủ để thuận tiện cho việc chăm sóc khách hàng và phân tích hành vi mua sắm. Những cải tiến trên sẽ giúp mở rộng tệp khách hàng, nâng cao độ tin cậy thương hiệu và tăng hiệu quả kinh doanh trong môi trường cạnh tranh của thương mại điện tử.

### 4.1. Gợi ý chỉnh nhẹ các ý đã có (tùy chọn)

- **Thứ tư (gợi ý sản phẩm):** thêm một câu — hiện hệ thống đã có sản phẩm liên quan theo danh mục và danh sách yêu thích; hướng tới cá nhân hóa theo lịch sử đơn hàng và hành vi xem.
- **Thứ bảy (đánh giá):** dùng “**mở rộng** đánh giá bằng hình ảnh và video” — đánh giá văn bản và xếp hạng sao đã triển khai.
- **Chatbot (cuối):** có thể thêm “áp dụng RAG trên dữ liệu FAQ và danh mục nội bộ” sau câu về mở rộng tri thức.
