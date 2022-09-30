FROM  webdevops/php-nginx:8.0-alpine

ENV WEB_DOCUMENT_ROOT /app/public
ENV APP_ENV production

WORKDIR /app

# Setup lambda web adapter
COPY --from=public.ecr.aws/awsguru/aws-lambda-adapter:0.4.0 /lambda-adapter /opt/extensions/lambda-adapter

# nginx config
COPY docker/nginx-config /opt/docker/etc/nginx/conf.d

# App source code
COPY . .

# Install required dependencies
RUN composer install --no-interaction --optimize-autoloader --no-dev
# Optimizing Configuration loading
RUN php artisan config:cache
# Optimizing Route loading
RUN php artisan route:cache
# Optimizing View loading
RUN php artisan view:cache

EXPOSE 8080

RUN chown -R application:application .