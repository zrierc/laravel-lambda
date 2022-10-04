#!/usr/bin/env sh
set -eu

php-fpm8

nginx -g 'daemon off;';