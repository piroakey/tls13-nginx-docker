# Nginx build with OpenSSL 1.1.1a(TLS1.3 supported) container image.
# Get Started:
#   docker build -t tls13_nginx .
#   docker run --name nginx -d -p 443:10443 tls13_nginx
FROM ubuntu:18.04

LABEL ITAKURA Hiroaki <piroakey@gmail.com>

# OpenSSL Version (see https://www.openssl.org/source/)
ENV OPENSSL_VERSION 1.1.1a

# Nginx Version (see https://nginx.org/en/download.html)
ENV NGINX_VERSION 1.15.8

# Build as root
USER root
WORKDIR /root

# www-data user
RUN usermod www-data --home /etc/nginx --shell /sbin/nologin

# Install deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    gcc \
    libpcre3 \
    libpcre3-dev \
    make \
    perl \
    zlib1g-dev \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# Get sources, compile and install
RUN curl -sSLO https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz \
 && curl -sSLO https://nginx.org/download/nginx-$NGINX_VERSION.tar.gz \
 && tar xzvf openssl-$OPENSSL_VERSION.tar.gz \
 && rm -v openssl-$OPENSSL_VERSION.tar.gz \
 && tar xzvf nginx-$NGINX_VERSION.tar.gz \
 && rm -v nginx-$NGINX_VERSION.tar.gz \
 && cd "/root/nginx-$NGINX_VERSION/" \
 && ./configure --prefix=/etc/nginx \
        --sbin-path=/usr/sbin/nginx \
        --conf-path=/etc/nginx/nginx.conf \
        --pid-path=/var/run/nginx.pid \
        --http-log-path=/var/log/nginx/access.log \
        --error-log-path=/var/log/nginx/error.log \
        --lock-path=/var/run/nginx.lock \
        --http-client-body-temp-path=/var/cache/nginx/client_temp \
        --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
        --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
        --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
        --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
        --user=nginx \
        --group=nginx \
        --with-compat \
        --with-file-aio \
        --with-threads \
        --with-http_addition_module \
        --with-http_auth_request_module \
        --with-http_dav_module \
        --with-http_flv_module \
        --with-http_gunzip_module \
        --with-http_gzip_static_module \
        --with-http_mp4_module \
        --with-http_random_index_module \
        --with-http_realip_module \
        --with-http_secure_link_module \
        --with-http_slice_module \
        --with-http_ssl_module \
        --with-http_stub_status_module \
        --with-http_sub_module \
        --with-http_v2_module \
        --with-mail \
        --with-mail_ssl_module \
        --with-stream \
        --with-stream_realip_module \
        --with-stream_ssl_module \
        --with-stream_ssl_preread_module \
#       --with-cc-opt='-g -O2 -fstack-protector-strong -Wformat -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2 -fPIC' \
#       --with-ld-opt='-Wl,-Bsymbolic-functions -Wl,-z,relro -Wl,-z,now -Wl,--as-needed -pie' \
        --with-openssl="$HOME/openssl-$OPENSSL_VERSION" \
        --with-openssl-opt="enable-ec_nistp_64_gcc_128 enable-tls1_3" \
#       --with-openssl-opt="enable-tls1_3" \
 && make \
 && make install \
 && apt-get purge -y --auto-remove curl gcc perl make \
 && rm -R "/root/nginx-$NGINX_VERSION" \
 && rm -R "/root/openssl-$OPENSSL_VERSION/"


# Copy cert and /etc/nginx/nginx.conf etc.
COPY conf/nginx.conf /etc/nginx/nginx.conf

COPY certs/server.crt /etc/nginx/certs/server.crt
COPY certs/server.key /etc/nginx/certs/server.key

# Make sure the permissions are set.
RUN chown -R www-data:www-data /etc/nginx \
 && chown -R www-data:www-data /var/log/nginx \
 && mkdir -p /var/cache/nginx/ \
 && chown -R www-data:www-data /var/cache/nginx/ \
 && touch /var/run/nginx.pid \
 && chown -R www-data:www-data /var/run/nginx.pid

# build options report
RUN nginx -V

# Launch
USER www-data
WORKDIR /etc/nginx

EXPOSE 10080 10443 10444

CMD ["nginx", "-g", "daemon off;"]

