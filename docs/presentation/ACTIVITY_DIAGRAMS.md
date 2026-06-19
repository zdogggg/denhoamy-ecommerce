# Activity Diagram — Đèn Hoa Mỹ (Test Vue)

> **2 sơ đồ UML Activity** khớp code thực tế.  
> **Render:** copy khối `@startuml` → [PlantUML Online](https://www.plantuml.com/plantuml/uml/) hoặc VS Code extension **PlantUML**.

---

## 1. Luồng đặt hàng & thanh toán

**File liên quan:** `CheckoutView.vue` → `orderService.createOrder` → `orders.php` POST → `payos_helper.php` / `payos_webhook.php` → `PaymentResultView.vue`

**Ghi chú quan trọng khi bảo vệ:**
- Tiền tổng **server tính lại** (`order_pricing`, `coupon_apply`) — không tin số từ Vue.
- **Trừ kho ngay khi tạo đơn** (trong transaction POST), không đợi admin duyệt.
- **COD / pay_at_store:** đơn `pending` → admin duyệt sau (Diagram 2).
- **PayOS thành công:** webhook tự chuyển `pending` → `approved` (bỏ qua bước duyệt tay).

```plantuml
@startuml Activity_DatHang_ThanhToan
title Activity Diagram — Đặt hàng & Thanh toán\n(CheckoutView → orders.php → PayOS)

skinparam ActivityBackgroundColor #FEFEFE
skinparam ActivityBorderColor #333
skinparam ArrowColor #333

|Khách hàng|
start
:Vào /checkout\n(router requiresAuth);
:Nhập thông tin giao hàng\n(SĐT, địa chỉ, ghi chú);
:Chọn phương thức giao hàng\n(home / store);
:Chọn phương thức thanh toán\n(cod / pay_at_store / payos);

if (Có mã giảm giá?) then (có)
  :Nhập & áp coupon\n(couponService → coupons.php);
else (không)
endif

:Bấm "Đặt hàng"\n(handlePlaceOrder);

|CheckoutView (Vue)|
if (Form hợp lệ & giỏ không trống?) then (không)
  :Hiển thị lỗi;
  stop
else (có)
endif

:syncCartPrices()\n(cập nhật giá SP mới nhất);

if (Đã áp coupon?) then (có)
  :Re-validate coupon\n(applyCoupon với giỏ hiện tại);
  if (Coupon còn hợp lệ?) then (không)
    :Xóa coupon + báo lỗi;
    stop
  else (có)
  endif
else (không)
endif

:Gọi createOrder(orderData)\nPOST orders.php;

|orders.php (PHP API)|
if (paymentMethod = payos\n& còn đơn pending?) then (có)
  :HTTP 409 + pendingOrderId;
  |CheckoutView|
  :Dialog: thanh toán lại / hủy đơn cũ;
  stop
else (không)
endif

:validateOrder + sanitizeInput;
:normalizeOrderItemsInTransaction\n(khóa & kiểm tra tồn kho);
:calculateOrderSubtotal;
if (Có couponCode?) then (có)
  :applyCouponByCode (server);
else (không)
endif
:finalTotal = subtotal - discount;

partition "Transaction DB" {
  :INSERT orders\nstatus = **pending**;
  if (Có coupon?) then (có)
    :used_count + 1;
  endif
  :INSERT order_items;
  :**Trừ stock** products/variants;
  :INSERT payments\nstatus = pending;
}

if (paymentMethod?) then (cod / pay_at_store)
  :Gửi email xác nhận\n(Resend — không chặn luồng);
  |CheckoutView|
  :Hiện dialog thành công\n#ORD-{id};
  :clearCart() + về trang chủ;
  note right
    Đơn COD/pay_at_store
    chờ admin duyệt
    (Diagram 2)
  end note
  stop

elseif (payos) then
  :createPayosCheckoutForOrder\n→ checkoutUrl;
  |CheckoutView|
  :Lưu payosPendingOrderId;
  :Redirect browser → PayOS;
  |Khách hàng|
  :Thanh toán trên cổng PayOS;

  fork
    |PayOS|
    :POST payos_webhook.php\n(HMAC verify);
    |orders.php / webhook|
    if (code = "00" & amount khớp?) then (thành công)
      :orders.status → **approved**;
      :payments.status → completed;
      :Gửi email xác nhận đã thanh toán;
    else (thất bại)
      :Log warning\n(đơn vẫn pending);
    endif
  fork again
    |PayOS|
    :Redirect trình duyệt\n/payment/success hoặc /cancel;
    |PaymentResultView|
    if (Route = success?) then (có)
      :Poll getPaymentStatus\n(tối đa 5 lần / 2s);
      if (isPaid = true?) then (có)
        :Hiện "Thanh toán thành công";
        :clearPayosPendingOrderId;
        :clearCart();
      elseif (isPending?) then (chờ webhook)
        :Hiện "Đang chờ xác nhận"\n+ nút Kiểm tra lại;
      else (chưa thanh toán)
        :Hiện thất bại / pending;
      endif
    else (cancel)
      :Hiện "Thanh toán chưa hoàn tất"\n(giữ giỏ hàng);
      :Có thể retryPayosPayment\n→ checkoutUrl mới;
    endif
  end fork
  stop
endif

@enduml
```

---

## 2. Luồng Admin duyệt đơn hàng

**File liên quan:** `AdminView.vue` (poll 5s) → `AdminPendingOrders.vue` → `orderService.updateOrder` → `orders.php` PUT → `lib/order_status.php`

**State machine đơn hàng:**
```
pending → approved → shipping → completed
   ↓         ↓           ↓
cancelled  cancelled   cancelled
```

**Ghi chú:** Kho đã trừ lúc tạo đơn. **Hủy đơn** mới **hoàn kho** + giảm `used_count` coupon.

```plantuml
@startuml Activity_Admin_DuyetDon
title Activity Diagram — Admin duyệt đơn hàng\n(AdminView → AdminPendingOrders → orders.php PUT)

skinparam ActivityBackgroundColor #FEFEFE
skinparam ActivityBorderColor #333

|Admin / Staff|
start
:Đăng nhập role admin/staff\n(JWT → authStore);
:Vào /admin\n(router requiresAdmin);

|AdminView (Vue)|
if (hasPermission('orders')?) then (không)
  :Không thấy menu Đơn hàng;
  stop
else (có)
endif

:Poll GET orders.php\nmỗi **5 giây**;
:Lọc đơn status = **pending**;
if (Có đơn pending mới?) then (có)
  :Badge thông báo\n+ ElNotification;
else (không)
endif

|Admin / Staff|
:Chọn menu "Đơn chờ xác nhận"\n(AdminPendingOrders);

if (Thao tác?) then (Duyệt 1 đơn)
  :Bấm "Xác nhận";
  |AdminPendingOrders|
  :updateOrder(db_id, **approved**, admin_id)\nPUT orders.php;

elseif (Duyệt hàng loạt) then
  :Bấm "Xác nhận tất cả";
  :Confirm dialog;
  :Lặp updateOrder → approved\ntừng đơn pending;

elseif (Hủy đơn) then
  :Bấm "Hủy" + confirm;
  |AdminPendingOrders|
  :updateOrder(db_id, **cancelled**, admin_id)\nPUT orders.php;

else (Chỉ xem)
  :Xem chi tiết SP trong đơn\n(expand row);
  stop
endif

|orders.php PUT|
:adminGuardAuto()\n(kiểm tra quyền admin);
:applyOrderStatus(pdo, id, newStatus, adminId);

|lib/order_status.php|
:Lấy orders.status hiện tại;
if (canTransition(from → to)?) then (không)
  :HTTP 400\n"Không thể chuyển trạng thái";
  |AdminPendingOrders|
  :ElMessage.error;
  stop
else (hợp lệ)
endif

partition "Transaction DB" {
  if (newStatus = cancelled?) then (có)
    :**restoreOrderInventory**\n(stock + quantity);
    if (Có coupon_code?) then (có)
      :used_count - 1;
    endif
  else (approved / shipping / ...)
    note right
      Duyệt đơn **không trừ kho**
      (đã trừ lúc tạo đơn)
    end note
  endif
  :UPDATE orders\nstatus, processed_by, updated_at;
}

:Trả JSON success;

|AdminView|
:emit approved / cancelled;
:fetchOrders() refresh danh sách;
:Cập nhật badge pending;

|Admin / Staff|
if (Tiếp tục xử lý?) then (có)
  :Chuyển sang "Danh sách đơn hàng"\n(AdminOrders);
  note right
    Xem đơn đã xử lý,
    lọc theo trạng thái,
    in hóa đơn (nếu không hủy)
  end note
  stop
else (chờ đơn mới)
  :Quay lại poll 5s;
  stop
endif

@enduml
```

---

## 3. Bảng mapping nhanh (đối chiếu code)

| Bước Activity | Vue | API / Lib |
|---------------|-----|-----------|
| Validate form checkout | `CheckoutView.handlePlaceOrder` | — |
| Tạo đơn | `orderService.createOrder` | `orders.php` POST |
| Trừ kho | — | `normalizeOrderItemsInTransaction` + UPDATE stock |
| PayOS link | — | `createPayosCheckoutForOrder` |
| Webhook | — | `payos_webhook.php` |
| Poll trạng thái | `PaymentResultView.pollUntilConfirmed` | `orders.php` GET payment status |
| Poll đơn pending | `AdminView` setInterval 5s | `orderService.getOrders` |
| Duyệt / Hủy | `AdminPendingOrders.approveOrder` | `orders.php` PUT + `applyOrderStatus` |
| Hoàn kho khi hủy | — | `restoreOrderInventory` |

---

## 4. Combo slide bảo vệ (gợi ý)

| Slide | Sơ đồ |
|-------|--------|
| Phạm vi chức năng | Use Case Diagram |
| Kiến trúc tổng | Flowchart (`SO_DO_LUONG_HE_THONG.md`) |
| Luồng mua hàng | **Activity Diagram 1** (file này) |
| Luồng vận hành | **Activity Diagram 2** (file này) |
| Dữ liệu | ERD PlantUML (`ERD_PLANTUML.md`) · chi tiết cột: `DATABASE_DESIGN.md` |
