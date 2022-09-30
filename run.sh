#!/usr/bin/env sh

supervisord -c /etc/supervisord.conf
# set -eu

# php-fpm
# nginx -g 'daemon off;';