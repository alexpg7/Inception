FROM debian:12

RUN apt-get update \
    && apt-get install -y \
        php8.2-fpm \
        php8.2-mysql \
        php8.2-curl \
        php8.2-gd \
        php8.2-mbstring \
        php8.2-xml \
        php8.2-zip \
        curl \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf

EXPOSE 9000

CMD ["php-fpm8.2", "-F"]