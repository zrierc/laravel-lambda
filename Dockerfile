FROM composer:2.4 as builder

WORKDIR /app

COPY . .

# Install required dependencies
RUN composer install --no-interaction --optimize-autoloader --no-dev
# Optimizing Configuration loading
RUN php artisan config:cache
# Optimizing Route loading
RUN php artisan route:cache
# Optimizing View loading
RUN php artisan view:cache
# Optimize app
RUN php artisan optimize


FROM nginx:stable-alpine

WORKDIR /app

RUN apk add --no-cache \
      php8 \
      php8-fpm \
      php8-common \
      php8-bcmath \
      php8-ctype \
      php8-fileinfo \
      php8-json \
      php8-mbstring \
      php8-openssl \
      php8-pdo \
      php8-tokenizer \
      php8-xml \
      php8-session \
      php8-dom \
      openssl \
      && rm -rf /etc/nginx/conf.d/*

# Setup lambda web adapter
COPY --from=public.ecr.aws/awsguru/aws-lambda-adapter:0.4.0 /lambda-adapter /opt/extensions/lambda-adapter
ENV PORT=8000

# nginx config
COPY docker/nginx.conf /etc/nginx/nginx.conf
COPY docker/nginx-config /etc/nginx/conf.d

# Php config
COPY docker/php-conf/php.ini /etc/php8/php.ini
COPY docker/php-conf/php-fpm.conf /etc/php8/php-fpm.conf
COPY docker/php-conf/php-custom.conf /etc/php-fpm.d/php.conf

# App source code
COPY --from=builder /app .

COPY ./run.sh /run.sh
RUN chmod +x /run.sh

EXPOSE 8000
CMD [ "/run.sh" ]