FROM debian:12

RUN apt-get update \
    && apt-get install -y \
        nginx \
        openssl \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /etc/nginx/ssl

COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY tools/setup.sh /usr/local/bin/setup.sh

RUN chmod +x /usr/local/bin/setup.sh

EXPOSE 443

ENTRYPOINT ["/usr/local/bin/setup.sh"]