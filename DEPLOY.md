# DEPLOY CHECKLIST (LOCAL -> VPS DOCKER)

Use this runbook for every deployment to `103.166.182.90` (CloudPanel + Docker).

---

## QUICK 5 COMMANDS (CODE ONLY)

```bash
cd /root/denhoamy-ecommerce
cp .env .env.bak-$(date +%F-%H%M)
docker exec -t denhoamy_db mysqldump -uroot -p'root123' denhoamy_db > backup-$(date +%F-%H%M).sql
git pull origin main
docker compose up -d --build && docker compose ps
```

---

## 0) Preconditions

- VPS repo path: `/root/denhoamy-ecommerce`
- Stack containers: `denhoamy_api`, `denhoamy_db`, `denhoamy_frontend`, `denhoamy_pma`
- Branch deploy: `main`

---

## 1) Local workflow (before push)

1. Implement and test locally.
2. If database/schema changes:
   - Create a new migration SQL file in `mysql/`.
   - Test migration on local DB first.
3. Commit and push:

```bash
git add -A
git commit -m "feat/fix: your message"
git push origin main
```

---

## 2) VPS deploy (code only)

Run line-by-line:

```bash
cd /root/denhoamy-ecommerce
cp .env .env.bak-$(date +%F-%H%M)
docker exec -t denhoamy_db mysqldump -uroot -p'root123' denhoamy_db > backup-$(date +%F-%H%M).sql
git fetch origin
git checkout main
git pull origin main
docker compose up -d --build
docker compose ps
```

---

## 3) VPS deploy (code + DB migration)

After step 2 above, run migration:

```bash
cat mysql/<your_migration_file>.sql | docker exec -i denhoamy_db mysql -uroot -p'root123' denhoamy_db
```

Quick verify:

```bash
docker exec -it denhoamy_db mysql -uroot -p'root123' -e "USE denhoamy_db; SHOW TABLES;"
```

---

## 4) Smoke test after deploy (2-5 minutes)

- Frontend homepage loads.
- Admin login works.
- **Đơn mới:** mở `/admin`, đặt thử COD từ trình duyệt/điện thoại khác → trong ~5s admin thấy toast + badge đơn chờ (poll HTTP, không WebSocket).
- **PayOS (nếu bật online):** đặt thử PayOS → redirect → `/payment/success`; thử hủy giữa chừng → `/payment/cancel` + retry; kiểm tra không tạo được 2 đơn PayOS pending (dialog checkout).
- **Nhận tại shop:** checkout chọn `store` + `pay_at_store` → admin thấy tag giao hàng/PTTT đúng.
- **Giỏ customer:** đăng nhập customer, thêm SP → F5 hoặc đổi browser cùng account vẫn thấy giỏ (cần bảng `carts` / `cart_items` trong DB).
- Backend smoke (trong container API):
  ```bash
  docker exec -it denhoamy_api php /var/www/html/tests/order_status_smoke.php
  docker exec -it denhoamy_api php /var/www/html/tests/order_stock_smoke.php
  ```
- PayOS flow (tùy chọn — copy script vào container API trước):
  ```bash
  docker cp scripts/payos_e2e_test.php denhoamy_api:/var/www/html/payos_e2e_test.php
  docker exec -it denhoamy_api php /var/www/html/payos_e2e_test.php
  ```
- Frontend logic smoke (không cần Docker):
  ```bash
  node scripts/phase2-smoke.mjs
  ```
- Updated feature works end-to-end.
- API/frontend logs are clean:

```bash
docker logs --tail 120 denhoamy_api
docker logs --tail 120 denhoamy_frontend
```

---

## 5) Rollback (emergency)

### 5.1 Rollback code

```bash
cd /root/denhoamy-ecommerce
git log --oneline -5
git reset --hard <previous_commit_sha>
docker compose up -d --build
```

### 5.2 Restore DB backup

```bash
cat backup-YYYY-MM-DD-HHMM.sql | docker exec -i denhoamy_db mysql -uroot -p'root123' denhoamy_db
```

---

## 6) Safe deployment rules

- Always backup DB before `git pull`.
- Never edit production schema manually if migration can do it.
- One migration file per change set.
- Deploy during low traffic when possible.
- Keep rollback command ready before migration.

---

## 7) One-command quick deploy (code only)

```bash
cd /root/denhoamy-ecommerce && cp .env .env.bak-$(date +%F-%H%M) && docker exec -t denhoamy_db mysqldump -uroot -p'root123' denhoamy_db > backup-$(date +%F-%H%M).sql && git fetch origin && git checkout main && git pull origin main && docker compose up -d --build && docker compose ps
```
