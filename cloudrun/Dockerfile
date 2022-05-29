FROM php:8.1-apache

ENV APP_ENV=prod
ENV APP_DEBUG=0
ARG APCU_VERSION=5.1.18

RUN apt-get update && apt-get -y install zip unzip libpq-dev libpng-dev libicu-dev git-core libonig-dev

RUN docker-php-ext-install mbstring opcache -j$(nproc) gd intl \
 && docker-php-ext-configure opcache --enable-opcache


RUN echo "memory_limit = -1" > /usr/local/etc/php/conf.d/memory_limit.ini

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

COPY . /var/www/html/
WORKDIR /var/www/html/

# COMPOSER INSTALL
RUN composer install --no-ansi --no-dev --no-interaction --no-progress --no-scripts --optimize-autoloader
RUN php bin/console cache:clear

## PHP.INI
RUN cp $PHP_INI_DIR/php.ini-production $PHP_INI_DIR/conf.d/php.ini
RUN cp -R /var/www/html/cloudrun/*.ini $PHP_INI_DIR/conf.d/

## INFRA
RUN chmod 777 -Rf var
RUN cp cloudrun/apache-default.conf /etc/apache2/sites-available/000-default.conf
RUN echo "ServerTokens Prod" >> /etc/apache2/apache2.conf
RUN echo "ServerSignature Off" >> /etc/apache2/apache2.conf
RUN a2enmod rewrite
## INFRA
EXPOSE 8080
