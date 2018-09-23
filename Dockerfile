
FROM alpine:3.8

WORKDIR /app

RUN apk add --no-cache --update ca-certificates nginx dcron curl tini php7 php7-bcmath php7-common php7-dom php7-fpm php7-gd php7-mbstring php7-openssl php7-zip php7-pdo php7-phar php7-json php7-pdo_mysql php7-session php7-ctype php7-tokenizer php7-zlib php7-simplexml supervisor \
    && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

RUN curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/download/v0.7.10/panel.tar.gz \
    && tar --strip-components=1 -xzvf panel.tar.gz \
    && chmod -R 755 storage/* bootstrap/cache/

RUN cp .env.example .env \
 && composer install --no-dev --optimize-autoloader \
 && rm .env \
 && chown -R nginx:nginx . && chmod -R 777 storage/* bootstrap/cache

COPY ./docker /docker

RUN cp /docker/default.conf /etc/nginx/conf.d/default.conf \
 && cp /docker/www.conf /etc/php7/php-fpm.d/www.conf \
 && cp /docker/entrypoint.sh /entrypoint.sh \
 && cat /docker/supervisord.conf > /etc/supervisord.conf \
 && echo "* * * * * /usr/bin/php /app/pterodactyl/artisan schedule:run >> /dev/null 2>&1" >> /var/spool/cron/crontabs/root \
 && mkdir -p /var/run/php /var/run/nginx \
 && mkdir -p /var/log/supervisord/ \
 && rm -rf /d

EXPOSE 80

ENTRYPOINT ["/bin/ash", "/entrypoint.sh"]

CMD [ "supervisord", "-n", "-c", "/etc/supervisord.conf" ]
