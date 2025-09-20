FROM debian:buster-slim

ENV DEBIAN_FRONTEND=noninteractive

# Point sources to the Debian archive since Buster is EOL
RUN printf '%s\n' \
  'deb http://archive.debian.org/debian buster main contrib non-free' \
  'deb http://archive.debian.org/debian-security buster/updates main contrib non-free' \
  'deb http://archive.debian.org/debian buster-updates main contrib non-free' \
  > /etc/apt/sources.list \
 && echo 'Acquire::Check-Valid-Until "false";' > /etc/apt/apt.conf.d/99no-check-valid \
 && echo 'Acquire::Retries "3";' > /etc/apt/apt.conf.d/80retries

# Install exact packages available on Buster
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl wget \
    firefox-esr sudo apache2 libapache2-mod-php7.3 \
    postgresql php7.3-pgsql python3-pip cron \
 && rm -rf /var/lib/apt/lists/*

# Python deps
RUN pip3 install --no-cache-dir selenium==4.11.2

# Install geckodriver provided in the repo
COPY ./.docker/geckodriver /usr/bin/geckodriver
RUN chmod +x /usr/bin/geckodriver

# Copy web app
COPY ./admin/ /var/www/html/admin/
COPY ./images/ /var/www/html/images/
COPY ./includes/ /var/www/html/includes/
COPY ./style/ /var/www/html/style/
COPY ./templates/ /var/www/html/templates/
COPY ./templates_c/ /var/www/html/templates_c/
COPY ./vendor/ /var/www/html/vendor/
COPY ./.htaccess /var/www/html/.htaccess
COPY ./favicon.ico /var/www/html/favicon.ico
COPY ./*.php /var/www/html/

# Docker helpers
COPY ./.docker/emulate_admin.py /app/emulate_admin.py
COPY ./.docker/entrypoint.sh   /app/entrypoint.sh
COPY ./.docker/setup.sql       /app/setup.sql
RUN chmod a+r /app/setup.sql

# Cron
COPY ./.docker/emulate_cron /etc/cron.d/emulate_admin
RUN chmod 0644 /etc/cron.d/emulate_admin && crontab /etc/cron.d/emulate_admin

# Apache vhost
COPY ./.docker/vhost.conf /etc/apache2/sites-enabled/000-default.conf

# Permissions
RUN chown -R www-data:www-data /var/www/html

EXPOSE 80
ENTRYPOINT ["/bin/sh", "/app/entrypoint.sh"]
