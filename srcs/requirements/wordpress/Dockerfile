FROM debian:12

ENV WORDPRESS_VERSION=7.0
ENV WP_CLI_VERSION=2.12.0

RUN apt-get update \
    && apt-get install -y \
        php8.2-fpm \
        php8.2-cli \
        php8.2-mysql \
        php8.2-curl \
        php8.2-gd \
        php8.2-mbstring \
        php8.2-xml \
        php8.2-zip \
        mariadb-client \
        curl \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL \
        "https://github.com/wp-cli/wp-cli/releases/download/v${WP_CLI_VERSION}/wp-cli-${WP_CLI_VERSION}.phar" \
        -o /usr/local/bin/wp \
    && chmod +x /usr/local/bin/wp

RUN mkdir -p /usr/src/wordpress \
    && curl -fsSL \
        "https://wordpress.org/wordpress-${WORDPRESS_VERSION}.tar.gz" \
        -o /tmp/wordpress.tar.gz \
    && tar -xzf /tmp/wordpress.tar.gz \
        --strip-components=1 \
        -C /usr/src/wordpress \
    && rm /tmp/wordpress.tar.gz

COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf

COPY tools/setup.sh /usr/local/bin/setup.sh

RUN chmod +x /usr/local/bin/setup.sh

EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/setup.sh"]