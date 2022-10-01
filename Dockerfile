FROM existenz/webstack:8.0

WORKDIR /app

ENV S6_READ_ONLY_ROOT=1

RUN apk -U --no-cache add \
      php8-bcmath \
      php8-ctype \
      php8-fileinfo \
      php8-json \
      php8-mbstring \
      php8-openssl \
      php8-pdo \
      php8-tokenizer \
      php8-xml \
      php8-session

# Setup lambda web adapter
COPY --from=public.ecr.aws/awsguru/aws-lambda-adapter:0.4.0 /lambda-adapter /opt/extensions/lambda-adapter

# nginx config
COPY docker/nginx.conf /etc/nginx/nginx.conf
COPY docker/nginx-config /etc/nginx/conf.d

# App source code
COPY . .

EXPOSE 8080