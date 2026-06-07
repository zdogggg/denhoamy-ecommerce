# Database migrations

## DB mới (Docker lần đầu)

Dùng [`../denhoamy_db.sql`](../denhoamy_db.sql) (dump production đã chuẩn hóa) — mount vào MySQL qua `docker-compose.yml` (`docker-entrypoint-initdb.d/init.sql`).

File [`../database.sql`](../database.sql) giữ làm tham chiếu schema cũ; không dùng cho init Docker nữa.

## DB đã tồn tại (nâng cấp từng tính năng)

Chạy theo thứ tự khi thiếu bảng/cột (xem [README_SETUP.md](../README_SETUP.md)):

| File | Mục đích |
|------|----------|
| [`migrate_password_reset.sql`](migrate_password_reset.sql) | Bảng `password_reset_tokens` |
| [`migrate_index_softdelete.sql`](migrate_index_softdelete.sql) | Index, soft delete |
| [`migrate_user_rbac.sql`](migrate_user_rbac.sql) | RBAC: `admins.role/permissions/is_active`, `users.is_locked/address` |
| [`migrate_order_delivery_method.sql`](migrate_order_delivery_method.sql) | `orders.delivery_method` (`home` / `store`) |
| [`migrate_pay_at_store.sql`](migrate_pay_at_store.sql) | Thêm `pay_at_store` vào enum `payments.method` |
| [`migrate_drop_supplier_legacy.sql`](migrate_drop_supplier_legacy.sql) | VPS/DB cũ: xóa `supplier_id`, FK `suppliers`, thêm `idx_user_phone` |
| [`migrate_hot_deal_price_snapshot.sql`](migrate_hot_deal_price_snapshot.sql) | Snapshot giá Hot Deal: `price_before_hot_deal`, `old_price_before_hot_deal` |
| [`migrate_inventory_variant.sql`](migrate_inventory_variant.sql) | `inventory_history.variant_id` + cột `type` |

**Kiểm thử Hot Deal (sau migrate + deploy API):** (1) SP một giá — sửa giá KM → gỡ → giá về cũ. (2) SP nhiều biến thể — sửa từng dòng → gỡ → từng giá khớp. (3) + Hot Deal không sửa giá → gỡ → không đổi. (4) SP Hot Deal cũ (chưa snapshot) → gỡ → chỉ tắt cờ. (5) Bật Hot Deal lần 2 → snapshot mới.

RBAC API: map quyền tại [`denhoamy_api/lib/admin_route_guard.php`](../denhoamy_api/lib/admin_route_guard.php).

**Giỏ hàng:** bảng `carts` / `cart_items` đã có trong dump [`denhoamy_db.sql`](../denhoamy_db.sql); API [`cart.php`](../denhoamy_api/cart.php) dùng cho customer đăng nhập.

```powershell
Get-Content mysql/migrate_password_reset.sql | docker exec -i denhoamy_db mysql -uroot -proot123 denhoamy_db
```

**VPS (DB đang chạy, không muốn xóa volume):** backup trước, rồi:

```bash
mysql -u USER -p denhoamy_db < mysql/migrate_drop_supplier_legacy.sql
```

Hoặc import full [`denhoamy_db.sql`](../denhoamy_db.sql) sau khi backup (phpMyAdmin / `mysql` CLI).

## Archive (tham chiếu lịch sử)

Các file trong [`archive/`](archive/) đã được gộp vào `database.sql`. **Không** chạy lại trên DB mới.

- `create_cart_tables.sql`
- `create_user_data_tables.sql`
- `create_product_images_table.sql`
- `feature_tables.sql`
- `migrate_add_fk.sql`
- `migrate_add_role.sql`
