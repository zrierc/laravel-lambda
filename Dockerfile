FROM bref/php-80-fpm

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

COPY . /var/task

# Configure the handler file (the entrypoint that receives all HTTP requests)
CMD ["public/index.php"]