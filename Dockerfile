FROM php:8.2-fpm-alpine

RUN apk add --no-cache \
    libpng-dev \
    libzip-dev \
    oniguruma-dev \
    sqlite \
    sqlite-dev \
    curl \
    nginx \
    supervisor \
    && docker-php-ext-install \
    pdo \
    pdo_sqlite \
    mbstring \
    zip \
    gd \
    bcmath \
    opcache

COPY --from=composer:2.7 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

COPY composer.json composer.lock ./
RUN composer install \
    --no-dev \
    --no-interaction \
    --no-scripts \
    --optimize-autoloader \
    --prefer-dist

COPY . .

RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html/storage \
    && chmod -R 755 /var/www/html/bootstrap/cache

COPY docker/nginx.conf       /etc/nginx/http.d/default.conf
COPY docker/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY docker/start.sh         /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

EXPOSE 8080

CMD ["/usr/local/bin/start.sh"]