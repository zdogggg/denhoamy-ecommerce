#!/bin/bash
# =============================================
# Entrypoint: Khởi chạy Cron + Apache đồng thời
# =============================================

# Truyền biến môi trường vào cron (DB, PayOS, JWT, Groq chatbot, Resend email)
printenv | grep -E "^(DB_|MYSQL_|PAYOS_|JWT_|GROQ_|RESEND_|FRONTEND_)" >> /etc/environment

# Apache mod_php: getenv() không luôn đọc được Docker env → SetEnv cho PHP
ENV_CONF=/etc/apache2/conf-enabled/docker-app-env.conf
: > "$ENV_CONF"
for var in DB_HOST DB_NAME DB_USER DB_PASS MYSQL_ROOT_PASSWORD MYSQL_DATABASE \
    PAYOS_CLIENT_ID PAYOS_API_KEY PAYOS_CHECKSUM_KEY \
    JWT_SECRET FRONTEND_URL \
    RESEND_API_KEY RESEND_FROM_EMAIL RESEND_FROM_NAME \
    GROQ_API_KEY GROQ_MODEL APP_DEBUG; do
    if [ -n "${!var}" ]; then
        printf 'SetEnv %s "%s"\n' "$var" "${!var}" >> "$ENV_CONF"
    fi
done

# Khởi động cron daemon (chạy nền)
cron

# Khởi động Apache (chạy foreground để container không thoát)
apache2-foreground
