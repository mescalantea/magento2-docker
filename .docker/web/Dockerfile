ARG PHP_VERSION=8.2

FROM php:${PHP_VERSION}-apache

SHELL ["/bin/bash", "-c"]

RUN apt-get update && apt-get install -y \
    # software-properties-common \
    # build-essential \
    # libtool \
    # autoconf \
    # pkg-config \
    mariadb-client \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libmcrypt-dev \
    libedit-dev \
    libedit2 \
    libpng-dev \
    libjpeg-dev \
    # libwebp-dev \
    # libonig-dev \
    libicu-dev \
    # libxml2-dev \
    libxslt1-dev \
    libzip-dev \
    # libsodium-dev \
    libssl-dev \
    # zlib1g-dev \
    # libcurl4-openssl-dev \
    # netcat-openbsd \
    git \
    wget \
    curl \
    lynx \
    psmisc \
    unzip \
    tar \
    cron \
    libpcre3 \
    libpcre3-dev \
    && pecl install \
    redis \
    oauth \
    && echo "extension=oauth.so" > /usr/local/etc/php/conf.d/docker-php-ext-oauth.ini \
    # && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install \
    opcache \
    bcmath \
    #     ctype \
    #     curl \
    #     dom \
    #     fileinfo \
    #     filter \
    gd \
    #     hash \
    #     iconv \
    intl \
    mysqli \
    pdo_mysql \
    #     json \
    #     mbstring \
    #     # openssl \
    #     simplexml \
    soap \
    sockets \
    #     sodium \
    #     tokenizer \
    #     xmlwriter \
    xsl \
    zip \
    #     zlib \
    && apt-get clean && rm -rf /var/lib/apt/lists/* \
    && docker-php-ext-enable redis

# Install composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer


# Enable apache modules
RUN a2enmod rewrite
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

COPY ./docker-php-m2.ini /usr/local/etc/php/conf.d/docker-php-m2.ini

COPY ./m2-entrypoint.sh /usr/local/bin/m2-entrypoint
RUN chmod +x /usr/local/bin/m2-entrypoint

ARG M2_VERSION
ARG M2_REPO_KEY
ARG M2_REPO_SECRET

WORKDIR /var/www/html

RUN composer config -g http-basic.repo.magento.com $M2_REPO_KEY $M2_REPO_SECRET

RUN composer create-project --repository-url=https://repo.magento.com/ magento/project-community-edition=$M2_VERSION . \
    && chmod -R 755 ./ \
    && chown -R www-data:www-data ./

# Modify base entry point to run our custom setup script
RUN sed -i 's/exec "$@"/\/usr\/local\/bin\/m2-entrypoint \&\& exec "$@"/g' /usr/local/bin/docker-php-entrypoint
