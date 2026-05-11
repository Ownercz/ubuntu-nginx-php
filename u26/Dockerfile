FROM ubuntu:26.04

LABEL maintainer="radim@lipovcan.cz"
ENV DEBIAN_FRONTEND noninteractive

ARG PHP_VERSION=8.5
ENV PHP_VERSION=${PHP_VERSION}

# Ubuntu codename used for third-party apt repositories (nginx, ondrej/php).
# If upstream repos do not yet ship packages for "resolute" at build time,
# fall back to the previous LTS codename ("noble") via:
#   --build-arg UBUNTU_CODENAME=noble
ARG UBUNTU_CODENAME=resolute
ENV UBUNTU_CODENAME=${UBUNTU_CODENAME}

# Release / provenance metadata. Populated by CI; safe defaults for local builds.
ARG VCS_REF=local
ARG BUILD_DATE=unknown
ARG IMAGE_SOURCE=https://github.com/Ownercz/ubuntu-nginx-php

LABEL org.opencontainers.image.title="ubuntu-nginx-php" \
      org.opencontainers.image.description="Ubuntu 26.04 + Nginx mainline + PHP-FPM (multi-arch, multi-PHP)" \
      org.opencontainers.image.url="https://hub.docker.com/r/ownercz/nginx-php" \
      org.opencontainers.image.source="${IMAGE_SOURCE}" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.vendor="ownercz" \
      org.opencontainers.image.authors="radim@lipovcan.cz" \
      org.opencontainers.image.base.name="docker.io/library/ubuntu:26.04" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      cz.lipovcan.php.version="${PHP_VERSION}" \
      cz.lipovcan.ubuntu.codename="${UBUNTU_CODENAME}"

# Set architecture-specific variables
ARG TARGETPLATFORM
ARG BUILDPLATFORM

RUN set -x \
    && apt-get update \
    && apt-get install -yq --no-install-recommends apt-utils

RUN set -x \
    && apt-get install -yq --no-install-recommends \
        curl \
        gnupg2 \
        software-properties-common \
        unzip \
        zip \
# includes envsubst
        gettext

RUN set -x \
    && apt-get install -yq --no-install-recommends \
        iproute2 \
        mysql-client \
        python3-pip \
        python3-setuptools \
        python3-wheel \
        libsasl2-modules \
        postfix \
        rsyslog \
        mailutils \
        nano \
        vim \
        less \
        dnsutils \
        iputils-ping \
        telnet

RUN set -x \
    && success=0 \
    && for attempt in 1 2 3; do \
        if LC_ALL=C.UTF-8 add-apt-repository ppa:ondrej/php -y; then \
            success=1; \
            break; \
        fi; \
        echo "add-apt-repository failed on attempt ${attempt}"; \
    done \
    && [ "$success" -eq 1 ]

RUN set -x \
    && curl -fsSL -o /usr/share/keyrings/nginx_signing.key http://nginx.org/keys/nginx_signing.key \
    && echo "deb [signed-by=/usr/share/keyrings/nginx_signing.key] http://nginx.org/packages/mainline/ubuntu/ ${UBUNTU_CODENAME} nginx" > /etc/apt/sources.list.d/nginx.list

RUN set -x \
    && apt-get update

RUN set -x \
    && apt-get install -yq --no-install-recommends \
        nginx \
        php${PHP_VERSION}-bcmath \
        php${PHP_VERSION}-cli \
        php${PHP_VERSION}-curl \
        php${PHP_VERSION}-fpm \
        php${PHP_VERSION}-gd \
        php${PHP_VERSION}-gmp \
        php${PHP_VERSION}-intl \
        php${PHP_VERSION}-mbstring \
        php${PHP_VERSION}-mysql \
        php${PHP_VERSION}-readline \
        php${PHP_VERSION}-soap \
        php${PHP_VERSION}-xml \
        php${PHP_VERSION}-zip \
        php${PHP_VERSION}-yaml \
        php${PHP_VERSION}-imagick \
        php${PHP_VERSION}-redis

RUN set -x \
    && if dpkg --compare-versions "$PHP_VERSION" lt 8.5; then apt-get install -yq --no-install-recommends php${PHP_VERSION}-opcache; fi

RUN set -x  \
    && pip3 install --no-cache-dir supervisor --break-system-packages 
RUN set -x  \
    && printf "#!/bin/sh\nexit 0" > /usr/sbin/policy-rc.d 
RUN set -x  \
    &&  apt-get autoremove --purge -y \
        software-properties-common \
        gnupg2 
RUN set -x  \
    && apt-get -y clean 
RUN set -x  \
    &&  rm -rf /var/lib/apt/lists/* /var/tmp/* 
RUN set -x  \
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
        /etc/php/${PHP_VERSION}/fpm/php.ini

RUN set -x \
    && sed -i \
        -e "s/;daemonize\s*=\s*yes/daemonize = no/g" \
        /etc/php/${PHP_VERSION}/fpm/php-fpm.conf 

RUN set -x \
    && sed -i \
        -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" \
        -e "s/pm.max_children = 5/pm.max_children = 4/g" \
        -e "s/pm.start_servers = 2/pm.start_servers = 3/g" \
        -e "s/pm.min_spare_servers = 1/pm.min_spare_servers = 2/g" \
        -e "s/pm.max_spare_servers = 3/pm.max_spare_servers = 4/g" \
        -e "s/;pm.max_requests = 500/pm.max_requests = 200/g" \
        -e "s/^;clear_env = no$/clear_env = no/" \
        /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf 

RUN set -x \
    && mkdir -p /run/php

# Nginx config
COPY conf/nginx /etc/nginx

# Nginx default config (template)
COPY conf/nginx/conf.d/default.conf.template  /etc/nginx/conf.d/default.conf.template
RUN envsubst '$PHP_VERSION' < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf

# Supervisor config (template)
COPY conf/supervisor/supervisord.conf.template /etc/supervisord.conf.template
RUN envsubst < /etc/supervisord.conf.template > /etc/supervisord.conf

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
