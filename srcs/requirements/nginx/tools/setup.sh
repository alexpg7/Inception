#!/bin/bash

set -eu

echo "NGINX startup"
echo "============="

SSL_DIR="/etc/nginx/ssl"

mkdir -p "$SSL_DIR"

if [ ! -f "$SSL_DIR/nginx.crt" ] || [ ! -f "$SSL_DIR/nginx.key" ]; then
    echo "Generating a self-signed TLS certificate..."

    openssl req \
        -x509 \
        -nodes \
        -days 365 \
        -newkey rsa:2048 \
        -keyout "$SSL_DIR/nginx.key" \
        -out "$SSL_DIR/nginx.crt" \
        -subj "/CN=alpascua.42.fr"
fi

chmod 600 "$SSL_DIR/nginx.key"

echo "Checking NGINX configuration..."
nginx -t

echo "Starting NGINX..."
exec nginx -g "daemon off;"