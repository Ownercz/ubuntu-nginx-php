FROM ubuntu:24.04

LABEL maintainer="radim@lipovcan.cz"
ENV DEBIAN_FRONTEND noninteractive

ENV PHP_VERSION 8.3

RUN set -x \
    && apt-get update \
    && apt-get install -yq --no-install-recommends \
        apt-utils \
        curl \
        gnupg2 \
        iproute2 \
        mysql-client \
        python3-pip \
        python3-setuptools \
        python3-wheel \
        software-properties-common \
        unzip \
        zip \
        libsasl2-modules \ 
        postfix \
        rsyslog \
        mailutils \
        nano \
        vim \
        dnsutils \
        iputils-ping \
    && LC_ALL=C.UTF-8 add-apt-repository ppa:ondrej/php -y \
    && curl -o /usr/share/keyrings/nginx_signing.key http://nginx.org/keys/nginx_signing.key \
    && echo "deb [signed-by=/usr/share/keyrings/nginx_signing.key] http://nginx.org/packages/mainline/ubuntu/ noble nginx" > /etc/apt/sources.list.d/nginx.list \
    && apt-get update && apt-get install -yq --no-install-recommends \
        nginx\
        #=${NGINX_VERSION} \
        php${PHP_VERSION}-bcmath \
        php${PHP_VERSION}-cli \
        php${PHP_VERSION}-curl \
        php${PHP_VERSION}-fpm \
        php${PHP_VERSION}-gd \
        php${PHP_VERSION}-gmp \
        php${PHP_VERSION}-intl \
        php${PHP_VERSION}-mbstring \
        php${PHP_VERSION}-mysql \
        php${PHP_VERSION}-opcache \
        php${PHP_VERSION}-readline \
        php${PHP_VERSION}-soap \
        php${PHP_VERSION}-xml \
        php${PHP_VERSION}-zip \
        php${PHP_VERSION}-imagick \
        php${PHP_VERSION}-redis \
    && pip3 install --no-cache-dir supervisor --break-system-packages\
    && printf "#!/bin/sh\nexit 0" > /usr/sbin/policy-rc.d \
    && apt-get autoremove --purge -y \
        software-properties-common \
        gnupg2 \
    && apt-get -y clean \
    && rm -rf /var/lib/apt/lists/* /var/tmp/* \
    && sed -i \
        -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" \
        -e "s/memory_limit\s*=\s*.*/memory_limit = 256M/g" \
        -e "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 100M/g" \
        -e "s/post_max_size\s*=\s*8M/post_max_size = 100M/g" \
        -e "s/max_execution_time = 30/max_execution_time = 180/g" \
        -e "s/max_input_time = 60/max_input_time = 180/g" \
        -e "s/variables_order = \"GPCS\"/variables_order = \"EGPCS\"/g" \
        -e "s/;opcache.enable=1/opcache.enable=1/"\
        -e "s/;opcache.memory_consumption=128/opcache.memory_consumption=512/g" \
        -e "s/;opcache.interned_strings_buffer=8/opcache.interned_strings_buffer=64/g" \
        -e "s/;opcache.max_accelerated_files=10000/opcache.max_accelerated_files=30000/g" \
        -e "s/;opcache.revalidate_freq=2/opcache.revalidate_freq=0/g" \
        /etc/php/${PHP_VERSION}/fpm/php.ini \
    && sed -i \
        -e "s/;daemonize\s*=\s*yes/daemonize = no/g" \
        /etc/php/${PHP_VERSION}/fpm/php-fpm.conf \
    && sed -i \
        -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" \
        -e "s/pm.max_children = 5/pm.max_children = 4/g" \
        -e "s/pm.start_servers = 2/pm.start_servers = 3/g" \
        -e "s/pm.min_spare_servers = 1/pm.min_spare_servers = 2/g" \
        -e "s/pm.max_spare_servers = 3/pm.max_spare_servers = 4/g" \
        -e "s/;pm.max_requests = 500/pm.max_requests = 200/g" \
        -e "s/^;clear_env = no$/clear_env = no/" \
        /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf \
    && mkdir -p /run/php

# Nginx config
COPY conf/nginx /etc/nginx

# Supervisor config
COPY conf/supervisor/supervisord.conf /etc/supervisord.conf

# Override default nginx welcome page
COPY html /usr/share/nginx/html

# Copy Scripts
COPY start.sh /start.sh
RUN chmod 755 /start.sh

RUN chown -R www-data:www-data /var/cache/nginx \
    && chown -R www-data:www-data /var/log/nginx \
    && chown -R www-data:www-data /usr/share/nginx \
    && chown -R www-data:www-data /etc/nginx \
    && touch /var/run/nginx.pid \
    && chown -R www-data:www-data /var/run/nginx.pid \
    && touch /var/log/php-fpm.log \
    && chown -R www-data:www-data /var/log/php-fpm.log

# run container as the www-data user
USER www-data

EXPOSE 8080
ENTRYPOINT ["/start.sh"]
