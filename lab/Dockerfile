FROM php:8.2-apache

RUN apt-get update && apt-get install -y --no-install-recommends \
        git zip curl unzip \
        libzip-dev zlib1g-dev libonig-dev \
        libsodium-dev libxml2-dev libcurl4-openssl-dev \
        libfreetype6-dev libjpeg62-turbo-dev libwebp-dev libpng-dev \
        sqlite3 libsqlite3-dev \
    && rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-configure gd --with-freetype --with-webp --with-jpeg \
    && docker-php-ext-install gd pdo pdo_mysql pdo_sqlite zip dom curl mbstring intl bcmath sodium opcache

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

COPY microweber2/ /var/www/html/
WORKDIR /var/www/html

ENV COMPOSER_ALLOW_SUPERUSER=1
RUN composer install --no-interaction --prefer-dist --optimize-autoloader 2>&1

RUN chmod -R 777 /var/www/html/storage \
    && chmod -R 777 /var/www/html/userfiles \
    && chmod -R 755 /var/www/html

RUN a2enmod rewrite
COPY lab/apache.conf /etc/apache2/sites-available/000-default.conf

COPY lab/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 80
CMD ["/entrypoint.sh"]
