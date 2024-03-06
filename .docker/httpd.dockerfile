FROM php:8.1-apache

ARG UID
ARG GID
ARG DOMAIN
ARG CERT
ARG KEY

ENV UID=${UID}
ENV GID=${GID}

RUN apt-get update && \
    apt-get install -y \
    ca-certificates \
    git \
    subversion \
    libpq-dev \
    postgresql \
    libicu-dev \
    libzip-dev \
    zip

RUN pecl install xdebug && \
    docker-php-ext-enable xdebug && \
    echo "xdebug.mode=debug" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini && \
    echo "xdebug.discover_client_host=true" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini && \
    echo "xdebug.client_host = host.docker.internal" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini

RUN export PATH=${PATH}:/usr/bin/svn

RUN a2enmod ssl \
    proxy \
    proxy_http \
    proxy_fcgi \
    rewrite

RUN docker-php-ext-install pgsql \
    pdo pdo_mysql mysqli \
    intl \
    zip

# Copy the pem-files to the container
RUN mkdir -p /etc/apache2/ssl
COPY /httpd/cert/${CERT} /etc/apache2/ssl/${CERT}
COPY /httpd/cert/${KEY} /etc/apache2/ssl/${KEY}
#COPY /httpd/cert/cacert.pem /etc/ssl/certs/cacert.pem
#RUN echo "curl.cainfo=\"/etc/apache2/ssl/${CERT}\"" >> $PHP_INI_DIR/php.ini-development && \
#    echo "openssl.cafile=\"/etc/apache2/ssl/${CERT}\"" >> $PHP_INI_DIR/php.ini-development

# Add our domain and pem-files to Apache envvars
RUN echo "export DOMAIN=${DOMAIN}" >> /etc/apache2/envvars && \
    echo "export DOMAIN_CERT=${CERT}" >> /etc/apache2/envvars && \
    echo "export DOMAIN_KEY=${KEY}" >> /etc/apache2/envvars

# Copy the Apache ssl virtual host configuration to the container
COPY httpd/default-ssl.conf /etc/apache2/sites-enabled/default-ssl.conf

# Activate php.ini-development
RUN mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"

RUN mkdir -p /var/www/html
WORKDIR /var/www/html

COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

# MacOS staff group's gid is 20, so is the dialout group in alpine linux. We're not using it, let's just remove it.
RUN groupdel dialout
RUN addgroup -gid ${GID} --system laravel
RUN adduser --ingroup laravel --system --disabled-password --shell /bin/sh -u ${UID} laravel

EXPOSE 443
