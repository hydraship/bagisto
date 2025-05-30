FROM serversideup/php:8.4-fpm AS base

USER root

RUN install-php-extensions intl gd bcmath calendar exif gmp

USER www-data

# Composer install
FROM base AS composer

COPY composer.json composer.lock ./

RUN composer install --no-dev --no-scripts --optimize-autoloader --prefer-dist

COPY --chown=www-data:www-data . .

RUN composer install --no-dev --prefer-dist

# Frontend

FROM node:24 AS frontend

COPY --from=composer /var/www/html /var/www/html

WORKDIR /var/www/html

RUN ls -la

RUN npm install && npm run build

# Backend

FROM base AS fpm

ENV PHP_OPCACHE_ENABLE=1
ENV PHP_MEMORY_LIMIT=2048M
ENV PHP_MAX_EXECUTION_TIME=360
ENV PHP_DATE_TIMEZONE="America/Mexico_City"
ENV AUTORUN_ENABLED=1

COPY --from=composer /var/www/html /var/www/html

COPY --from=frontend /var/www/html/public/build /var/www/html/public/build
