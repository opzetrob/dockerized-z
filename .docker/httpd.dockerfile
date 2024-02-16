FROM php:8.1-apache

ARG UID
ARG GID

ENV UID=${UID}
ENV GID=${GID}

# Add Subversion
RUN apt-get update && \
    apt-get install -y \
    git \
    subversion \
    libpq-dev \
    postgresql \
    libicu-dev \
    libzip-dev \
    zip
RUN export PATH=${PATH}:/usr/bin/svn

RUN a2enmod ssl
RUN a2enmod proxy
RUN a2enmod proxy_http
RUN a2enmod proxy_fcgi
RUN a2enmod rewrite

RUN docker-php-ext-install pgsql
RUN docker-php-ext-install pdo pdo_mysql mysqli
RUN docker-php-ext-install intl
RUN docker-php-ext-install zip

# Copy the certificate and key to the container
RUN mkdir -p /etc/apache2/ssl
COPY httpd/cert/httpd-self-signed.cert /etc/apache2/ssl/httpd-self-signed.cert
COPY httpd/cert/httpd-self-signed.key /etc/apache2/ssl/httpd-self-signed.key

# Copy the Apache configuration file to the container
COPY httpd/httpd.conf /etc/apache2/conf/httpd.conf

# Copy the Apache virtual host configuration file to the container
COPY httpd/000-default.conf /etc/apache2/sites-available/000-default.conf

RUN mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"

RUN mkdir -p /var/www/html

WORKDIR /var/www/html

COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

# MacOS staff group's gid is 20, so is the dialout group in alpine linux. We're not using it, let's just remove it.
RUN groupdel dialout
RUN addgroup -gid ${GID} --system laravel
RUN adduser --ingroup laravel --system --disabled-password --shell /bin/sh -u ${UID} laravel

EXPOSE 80
EXPOSE 443
