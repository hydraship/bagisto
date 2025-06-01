FROM serversideup/php:8.3-fpm AS base

USER root

RUN install-php-extensions intl gd bcmath calendar exif gmp

USER www-data

# Composer install
FROM registry.digitalocean.com/hydraship/bagisto:php-8.3-1-base AS composer

# COPY composer.json composer.lock ./

# RUN composer install --no-dev --no-scripts --optimize-autoloader --prefer-dist

COPY --chown=www-data:www-data . .

RUN composer install
# RUN composer install --no-dev --prefer-dist

# Frontend

FROM node:24 AS frontend

COPY --from=composer /var/www/html /var/www/html

WORKDIR /var/www/html

RUN ls -la

RUN npm install && npm run build

# Backend

FROM registry.digitalocean.com/hydraship/bagisto:php-8.3-1-base AS fpm

ENV PHP_OPCACHE_ENABLE=1
ENV PHP_MEMORY_LIMIT=2048M
ENV PHP_MAX_EXECUTION_TIME=360
ENV PHP_DATE_TIMEZONE="America/Mexico_City"
ENV AUTORUN_ENABLED=1

COPY --from=composer /var/www/html /var/www/html

COPY --from=frontend /var/www/html/public/build /var/www/html/public/build

# Web server stage
FROM nginx:1.27.5-alpine AS web

# Create directory structure
RUN mkdir -p /var/www/html

# Copy public directory from php stage to nginx html directory
COPY --from=fpm /var/www/html/public /var/www/html/public

# Set proper permissions
RUN chown -R nginx:nginx /var/www/html

# Configure nginx if needed (optional)
# COPY docker/nginx/default.conf /etc/nginx/conf.d/defaul

# Create symlinks for access and error logs
RUN ln -sf /dev/stdout  /var/log/nginx/access.log \
 && ln -sf /dev/stderr  /var/log/nginx/error.log
