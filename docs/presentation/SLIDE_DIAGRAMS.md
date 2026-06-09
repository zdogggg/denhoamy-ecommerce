# Sơ đồ cho Slide — Đèn Hoa Mỹ

> Export: dán Mermaid vào [mermaid.live](https://mermaid.live) hoặc draw.io, xuất PNG/SVG cho PowerPoint.  
> Gắn vào slide theo cột **Slide** bên dưới.

---

## D1 — Kiến trúc 3-tier (Slide 13)

```mermaid
flowchart TB
  subgraph client [Client]
    Browser[Browser]
  end
  subgraph docker [DockerHost]
    Frontend["Vue3_SPA\nNginx :3000"]
    API["PHP82_API\nApache :8080"]
    DB["MySQL8\n:3307"]
    PMA[phpMyAdmin :8081]
  end
  subgraph external [ThirdParty]
    Groq[Groq_LLaMA4]
    PayOS[PayOS]
    Resend[Resend_Email]
  end
  Browser -->|HTTPS_JSON| Frontend
  Frontend -->|REST_API| API
  API -->|PDO| DB
  API --> Groq
  API --> PayOS
  API --> Resend
  PMA --> DB
```

---

## D2 — Docker Compose services (Slide 14)

```mermaid
flowchart LR
  frontend[frontend_Nginx_Vue]
  api[api_PHP_Apache_Cron]
  db[db_MySQL]
  pma[phpmyadmin]
  frontend -->|depends_on| api
  api -->|depends_on_healthcheck| db
  pma --> db
```

---

## D3 — Request lifecycle Backend (Slide 18)

```mermaid
flowchart TD
  req[ClientRequest] --> cors[CORS_db.php]
  cors --> rate[RateLimiter]
  rate --> auth[JWT_AuthMiddleware]
  auth --> guard[AdminRouteGuard]
  guard --> valid[InputValidator]
  valid --> biz[BusinessLogic_PDO]
  biz --> json[JSON_Response]
```

---

## D4 — Giỏ hàng & đồng bộ (Slide 23)

```mermaid
flowchart LR
  guest[Guest] -->|localStorage| cartLocal[CartLocal]
  customer[CustomerLoggedIn] -->|Pinia| cartStore[CartStore]
  cartStore -->|GET_PUT| cartApi[cart.php]
  loginEvent[Login] -->|mergeAfterLogin| cartApi
  cartApi --> mysql[(cart_items)]
```

---

## D5 — Luồng đặt hàng & PayOS (Slide 24–25)

```mermaid
flowchart TD
  start[CustomerCheckout] --> delivery{deliveryMethod}
  delivery -->|home| pttm1[COD_or_PayOS]
  delivery -->|store| pttm2[pay_at_store_or_PayOS]
  pttm1 --> createOrder[POST_orders.php]
  pttm2 --> createOrder
  createOrder --> lockStock[Transaction_FOR_UPDATE]
  lockStock --> payChoice{payment}
  payChoice -->|COD_pay_at_store| pending[pending_email]
  payChoice -->|PayOS| checkPending{pending_payos?}
  checkPending -->|409| block[BlockDuplicate]
  checkPending -->|ok| payosLink[createPaymentLink]
  payosLink --> redirect[PayOS_Page]
  redirect -->|success| webhook[payos_webhook.php]
  redirect -->|cancel| pollUI[PaymentResultView_poll]
  webhook --> approved[status_approved]
```

---

## D6 — Order status machine (Slide 27)

```mermaid
stateDiagram-v2
  [*] --> pending
  pending --> approved: admin_approve_or_PayOS_webhook
  pending --> cancelled: admin_cancel_or_cron_24h
  approved --> shipping: admin_or_cron_auto
  shipping --> completed: cron_auto_or_confirm_received
  approved --> cancelled: admin_cancel
  shipping --> cancelled: admin_cancel
  completed --> [*]
  cancelled --> [*]
```

---

## D7 — JWT authentication flow (Appendix A1)

```mermaid
sequenceDiagram
  participant FE as Frontend
  participant API as auth.php
  participant DB as MySQL
  FE->>API: POST username password
  API->>DB: SELECT users
  DB-->>API: user row
  API->>API: password_verify bcrypt
  API->>API: createToken HMAC_SHA256 exp24h
  API-->>FE: token JWT
  FE->>FE: localStorage token
  FE->>API: GET orders Authorization Bearer
  API->>API: jwtDecode verify exp
  API-->>FE: success data
```

---

## D8 — AI Chatbot flow (Slide 30)

```mermaid
flowchart TD
  msg[UserMessage] --> engine[chatbot_engine.php]
  engine --> groq[Groq_LLaMA4_Scout]
  groq -->|tool_calls| tools[ExecuteToolsLocally]
  tools --> search[search_products]
  tools --> specs[get_product_specs]
  tools --> types[list_product_types]
  tools --> faq[get_store_faq]
  search --> mysql[(MySQL)]
  specs --> mysql
  tools --> groq2[SecondGroqCall]
  groq2 --> reply[NaturalReply]
  groq -->|error_rate_limit| fallback[RuleBased_FAQ_DB]
  fallback --> reply
  reply --> jsonOut[JSON reply products]
```

---

## D9 — ERD rút gọn (Slide 16)

```mermaid
erDiagram
  categories ||--o{ products : phan_loai
  categories ||--o{ categories : cha_con
  products ||--o{ product_variants : bien_the
  products ||--o{ product_images : gallery
  products ||--o{ order_items : ban_ra
  users ||--o{ orders : dat_hang
  orders ||--o{ order_items : chi_tiet
  users ||--o{ carts : gio_hang
  carts ||--o{ cart_items : items
  users ||--o{ wishlists : yeu_thich
  products ||--o{ reviews : danh_gia
```

---

## D10 — RBAC 3 cấp (Slide 29)

```mermaid
flowchart TB
  admin[Admin_full_access]
  staff[Staff_limited_permissions]
  customer[Customer_public_profile]
  admin --> allModules[All_11_admin_modules]
  staff --> permMap[admin_route_guard.php]
  permMap --> mod1[products]
  permMap --> mod2[orders]
  permMap --> modN[settings_etc]
  customer --> shop[Shop_checkout_profile]
```

---

## D11 — Bảo mật 7 lớp (Slide 19)

```mermaid
flowchart TB
  L1[L1_Network_CORS_RateLimit_HTTPS]
  L2[L2_Auth_JWT_expiration]
  L3[L3_RBAC_admin_route_guard]
  L4[L4_Input_validator_sanitize]
  L5[L5_DB_prepared_statements]
  L6[L6_File_MIME_size_limit]
  L7[L7_Logging_IP_tracking]
  L1 --> L2 --> L3 --> L4 --> L5 --> L6 --> L7
```

---

## D12 — Use case tổng quan (Slide 10)

```mermaid
flowchart LR
  subgraph actors [Actors]
    KH[KhachHang]
    AD[Admin_Staff]
    HT[HeThong_Cron_PayOS_Groq]
  end
  subgraph system [HeThong_DenHoaMy]
    UC1[MuaHang_ThanhToan]
    UC2[QuanTri_SP_Don]
    UC3[Chatbot_TuVan]
    UC4[TuDongDonHang]
  end
  KH --> UC1
  KH --> UC3
  AD --> UC2
  HT --> UC4
```
