FROM php:8.4-apache

RUN apt-get update -y && \
    apt-get upgrade -y && \
    apt-get install -y \
            git \
            subversion \
            libpq-dev \
            postgresql \
            libicu-dev \
            libzip-dev \
            zip \
            gzip \
            curl \
            build-essential \
            libssl-dev \
            zlib1g-dev \
            libpng-dev \
            libjpeg-dev \
            libfreetype6-dev
RUN export PATH=${PATH}:/usr/bin/svn

RUN a2enmod ssl \
            proxy \
            proxy_http \
            proxy_fcgi \
            rewrite

RUN docker-php-ext-install pgsql \
                           pdo \
                           pdo_mysql \
                           mysqli \
                           intl \
                           zip

RUN docker-php-ext-configure gd \
    --with-jpeg=/usr/include/ \
    --with-freetype=/usr/include/ \
    && docker-php-ext-install gd \
    && docker-php-ext-configure ftp --with-openssl-dir=/usr \
    && docker-php-ext-install ftp

RUN curl -sSLf https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions \
    -o /usr/local/bin/install-php-extensions \
    && chmod +x /usr/local/bin/install-php-extensions \
    && install-php-extensions http

# Activate php.ini-development
RUN mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"
RUN echo "memory_limit = 512M" >> "$PHP_INI_DIR/php.ini"
RUN echo "upload_max_filesize = 128M" >> "$PHP_INI_DIR/php.ini"
RUN echo "post_max_filesize = 128M" >> "$PHP_INI_DIR/php.ini"
# Activate XDebug
RUN pecl install xdebug && \
    docker-php-ext-enable xdebug && \
    echo "xdebug.mode=debug" >> "$PHP_INI_DIR/conf.d/docker-php-ext-xdebug.ini" && \
    echo "xdebug.discover_client_host=true" >> "$PHP_INI_DIR/conf.d/docker-php-ext-xdebug.ini" && \
    echo "xdebug.client_host = host.docker.internal" >> "$PHP_INI_DIR/conf.d/docker-php-ext-xdebug.ini" && \
    echo "xdebug.start_with_request = trigger" >> "$PHP_INI_DIR/conf.d/docker-php-ext-xdebug.ini"

 # Copy the Apache ssl virtual host configuration to the container
COPY httpd/default-ssl.conf /etc/apache2/sites-enabled/default-ssl.conf

COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

# Add our domain and pem-files to Apache envvars
ARG DOMAIN
RUN echo "export DOMAIN=${DOMAIN}" >> /etc/apache2/envvars
RUN echo "export DOMAIN_CERT=cert.pem" >> /etc/apache2/envvars
RUN echo "export DOMAIN_KEY=key.pem" >> /etc/apache2/envvars

RUN mkdir -p /var/www/html
WORKDIR /var/www/html
COPY . .

ENV GIT_SSH_COMMAND='ssh -Tv'
RUN mkdir -p ~/.ssh && ssh-keyscan github.com >> ~/.ssh/known_hosts

# MacOS staff group's gid is 20, so is the dialout group in alpine linux. We're not using it, let's just remove it.
ARG UID
ARG GID
ENV UID $UID
ENV GID $GID
RUN groupdel dialout
RUN addgroup -gid $GID --system laravel
RUN adduser --ingroup laravel --system --disabled-password --shell /bin/sh -u $UID laravel

RUN apt-get install -y cron
RUN echo "* * * * * cd /var/www/html && /usr/local/bin/php artisan schedule:run >> /var/log/laravel-scheduler.log 2>&1" \
    | crontab -u www-data -

COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

EXPOSE 443
CMD ["/usr/local/bin/start.sh"]
