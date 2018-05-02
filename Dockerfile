FROM ubuntu:xenial

LABEL maintainer "Fachruzi Ramadhan <mabuak@live.com>"

ENV DEBIAN_FRONTEND=noninteractive

RUN \
    apt-get update && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git-core \
        openssh-client \
        openssl \
        unzip \
        vim \
        wget

# Nginx 1.13.2
RUN \
    wget --quiet -O - https://nginx.org/keys/nginx_signing.key | apt-key add - \
    && echo "deb http://nginx.org/packages/mainline/ubuntu/ xenial nginx" >> /etc/apt/sources.list.d/nginx.list \
    && echo "deb-src http://nginx.org/packages/mainline/ubuntu/ xenial nginx" >> /etc/apt/sources.list.d/nginx.list \
    && apt-get update && apt-get install -y --no-install-recommends nginx=1.13.2-1~xenial \
    # forward request and error logs to docker log collector
    && ln -sf /dev/stdout /var/log/nginx/access.log \
	&& ln -sf /dev/stderr /var/log/nginx/error.log

# PHP 5.6
RUN \
    apt-get install -y --no-install-recommends software-properties-common \
    && LANG=C.UTF-8 add-apt-repository -y ppa:ondrej/php \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        php5.6-bcmath \
        php5.6-cli \
        php5.6-common \
        php5.6-curl \
        php5.6-dev \
        php5.6-fpm \
        php5.6-gd \
        php5.6-intl \
        php5.6-json \
        php5.6-mbstring \
        php5.6-mysql \
        php5.6-opcache \
        php5.6-pgsql \
        php5.6-sqlite3 \
        php5.6-xml \
        php5.6-zip \
        php5.6-mcrypt \
        php-apcu \
        php-imagick \
        php-mongodb \
        php-redis \
        php-xdebug \
    # forward logs to docker log collector
    && ln -sf /dev/stdout /var/log/php5.6-fpm.log

# Config PHP and NGINX
RUN \
    mkdir -p /run/php \
    && chown root:root /run/php \
    && sed -i "s/;date.timezone =.*/date.timezone = Asia\/Jakarta/g" /etc/php/5.6/fpm/php.ini \
    && sed -i "s/;date.timezone =.*/date.timezone = Asia\/Jakarta/g" /etc/php/5.6/cli/php.ini \
    && sed -i "s/upload_max_filesize =.*/upload_max_filesize = 250M/g" /etc/php/5.6/fpm/php.ini \
    && sed -i "s/memory_limit = 128M/memory_limit = 512M/g" /etc/php/5.6/fpm/php.ini \
    && sed -i "s/post_max_size =.*/post_max_size = 250M/g" /etc/php/5.6/fpm/php.ini \
    && sed -i "s/user = www-data/user = root/g" /etc/php/5.6/fpm/pool.d/www.conf \
    && sed -i "s/group = www-data/group = root/g" /etc/php/5.6/fpm/pool.d/www.conf \
    && sed -i "s/listen.owner = www-data/listen.owner = root/g" /etc/php/5.6/fpm/pool.d/www.conf \
    && sed -i "s/listen.group = www-data/listen.group = root/g" /etc/php/5.6/fpm/pool.d/www.conf \
    && sed -i "s/pm = dynamic/pm = ondemand/g" /etc/php/5.6/fpm/pool.d/www.conf \
    && sed -i "s/pm.max_children = 5/pm.max_children = 15/g" /etc/php/5.6/fpm/pool.d/www.conf \
    && sed -i "s/;pm.process_idle_timeout = 10s;/pm.process_idle_timeout = 10s;/g" /etc/php/5.6/fpm/pool.d/www.conf \
    && sed -i "s/worker_processes 2;/worker_processes auto;/g" /etc/nginx/nginx.conf \
    && sed -i "s/listen       80;/listen       80    default_server;/g" /etc/nginx/conf.d/default.conf \
    # clear cache
    && apt-get clean \
    && apt-get autoremove --purge \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

EXPOSE 80

# Project
RUN mkdir -p /home/projects
VOLUME /home/projects
WORKDIR /home/projects

# Docker Container
COPY ./entrypoint.sh /home/projects
CMD ["/bin/bash", "/home/projects/entrypoint.sh"]
