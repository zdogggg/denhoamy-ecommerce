FROM php:8.2-apache

# Cài đặt pdo_mysql extension
RUN docker-php-ext-install pdo pdo_mysql

# Bật mod_rewrite của Apache
RUN a2enmod rewrite

# Tăng giới hạn upload của PHP (tránh lỗi khi tải quá nhiều ảnh base64)
RUN echo "post_max_size = 50M\nupload_max_filesize = 50M\nmemory_limit = 256M" > /usr/local/etc/php/conf.d/uploads.ini

# Cấu hình Apache cho phép .htaccess
RUN sed -i 's/AllowOverride None/AllowOverride All/g' /etc/apache2/apache2.conf

# Cài đặt cron để chạy tác vụ tự động hủy đơn hàng
RUN apt-get update && apt-get install -y cron && rm -rf /var/lib/apt/lists/*

# Cron: hủy đơn pending quá hạn (phút 0) + tiến trạng approved/shipping (phút 30)
RUN echo "0 * * * * root DB_HOST=\$DB_HOST DB_NAME=\$DB_NAME DB_USER=\$DB_USER DB_PASS=\$DB_PASS php /var/www/html/cron_cancel_orders.php >> /var/log/cron.log 2>&1\n30 * * * * root DB_HOST=\$DB_HOST DB_NAME=\$DB_NAME DB_USER=\$DB_USER DB_PASS=\$DB_PASS php /var/www/html/cron_progress_orders.php >> /var/log/cron.log 2>&1" > /etc/cron.d/order-jobs \
    && chmod 0644 /etc/cron.d/order-jobs \
    && crontab /etc/cron.d/order-jobs \
    && touch /var/log/cron.log

# Copy source code vào container
COPY . /var/www/html/

# Tạo thư mục logs cho Error Logging
RUN mkdir -p /var/www/html/logs && chown -R www-data:www-data /var/www/html/logs

# Set quyền
RUN chown -R www-data:www-data /var/www/html

# Entrypoint: khởi chạy cả cron daemon lẫn Apache
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 80

CMD ["/entrypoint.sh"]
