# Frontend — Đèn Hoa Mỹ (Vue 3 + Vite)

SPA khách hàng + admin cho dự án TMĐT Đèn Hoa Mỹ.

## Chạy dev

```bash
npm install
npm run dev
```

API mặc định: `VITE_API_URL` trong `.env` (local thường `http://localhost:8080`).

## Tài liệu liên quan

| File | Nội dung |
|------|----------|
| [docs/VIEWS_MAP.md](docs/VIEWS_MAP.md) | Bản đồ route / view |
| [../README.md](../README.md) | Tổng quan dự án |
| [../README_SETUP.md](../README_SETUP.md) | Docker + cấu hình |
| [../denhoamy_api/API_DOCUMENTATION.md](../denhoamy_api/API_DOCUMENTATION.md) | REST API |

## Store chính (Pinia)

- **auth** — JWT, login/logout, merge giỏ sau login (customer)
- **cart** — `localStorage` + đồng bộ `cart.php` (debounce 500ms) khi customer đăng nhập
- **settings** — cấu hình shop từ API

## Utils / composables

| Path | Mô tả |
|------|--------|
| `src/utils/productPrice.js` | Giá bán, giá gạch, nhãn 「Từ」 theo biến thể |
| `src/composables/useMobileLayout.js` | Breakpoint mobile (992px) — `ProfileView` |
