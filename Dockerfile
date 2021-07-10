FROM docker.io/library/debian:10-slim

LABEL vendor="jlisher"
LABEL version="v0.0.1"
LABEL description="A simple preconfigured development environment for Phalcon v2 with PHP 5.6"

# fixes some weird terminal issues such as broken clear / CTRL+L
ENV TERM=linux

# ensure apt doesn't ask questions when installing stuff
ENV DEBIAN_FRONTEND=noninteractive

# install Ondrej repos for PHP7.4 and selected extensions - better selection than
# the distro's packages
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get -y --no-install-recommends install \
        apt-transport-https \
        lsb-release \
        ca-certificates \
        curl \
    && curl -L -o /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg \
    && echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list \
    && apt-get update \
    && apt-get -y --no-install-recommends install \
        libfcgi-bin \
        unzip \
        php5.6-apc \
        php5.6-apcu \
        php5.6-bcmath \
        php5.6-cli \
        php5.6-curl \
        php5.6-fpm \
        php5.6-gd \
        php5.6-gmp \
        php5.6-intl \
        php5.6-json \
        php5.6-mbstring \
        php5.6-mcrypt \
        php5.6-mysql \
        php5.6-opcache \
        php5.6-readline \
        php5.6-soap \
        php5.6-xdebug \
        php5.6-xml \
        php5.6-zip \
    && apt-get -y clean \
    && apt-get -y autoclean \
    && apt-get -y autoremove \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*

# PHP-FPM packages need a nudge to make them docker-friendly
COPY ./php-fpm/overrides.conf /etc/php/5.6/fpm/pool.d/z-overrides.conf

# copy our xdegug ini file
COPY ./php-fpm/xdebug.ini /etc/php/5.6/fpm/conf.d/90-xdebug.ini

# Set www-data user id and group id to pervent permissions errors
# (33 is the default)
ARG RUN_UID=33
ENV RUN_UID ${RUN_UID}
ARG RUN_GID=33
ENV RUN_GID ${RUN_GID}
RUN groupmod -g "${RUN_GID}" -o www-data \
    && usermod -u "${RUN_UID}" -g "${RUN_GID}" -o www-data

# install composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# add legacy php run directory
RUN mkdir -p /run/php \
    && chown www-data:www-data -R /run/php

# add phalcon source files
COPY ./phalcon /phalcon
RUN apt-get update \
    && apt-get install -y gcc make php5.6-dev re2c \
    && (cd /phalcon/build && ./install) \
    && apt-get -y clean \
    && apt-get -y autoclean \
    && apt-get -y autoremove \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/* \
    && echo "extension=phalcon.so" >/etc/php/5.6/mods-available/phalcon.ini \
    && ln -sn /etc/php/5.6/mods-available/phalcon.ini /etc/php/5.6/fpm/conf.d/30-phalcon.ini \
    && ln -sn /etc/php/5.6/mods-available/phalcon.ini /etc/php/5.6/cli/conf.d/30-phalcon.ini

# install phalcon developer tools
COPY ./phalcon-devtools /phalcon-devtools
RUN ln -sn /phalcon-devtools/phalcon.php /usr/bin/phalcon \
    && chmod +x /usr/bin/phalcon
ENV PTOOLSPATH /phalcon-devtools

# set the working directory to our application's root directory
WORKDIR /app

# set stop signal to send
STOPSIGNAL SIGQUIT

# open up fcgi port
EXPOSE 9000

# set a good default starting script
CMD ["/usr/sbin/php-fpm5.6", "-O"]
