FROM localhost/claude-sandbox:latest

RUN apt-get update && apt-get install -y --no-install-recommends \
    apache2 \
    php \
    php-mysql \
    php-curl \
    php-gd \
    php-mbstring \
    php-xml \
    php-xmlrpc \
    php-zip \
    mariadb-server \
    && rm -rf /var/lib/apt/lists/*

# Enable Apache rewrite module (required for WordPress permalinks)
RUN a2enmod rewrite

# Configure Apache to listen on 8080 (avoids needing root for port 80)
RUN sed -i 's/Listen 80/Listen 8080/' /etc/apache2/ports.conf \
    && sed -i 's/<VirtualHost \*:80>/<VirtualHost *:8080>/' /etc/apache2/sites-enabled/000-default.conf

# Allow .htaccess overrides in the web root
RUN sed -i '/<Directory \/var\/www\/>/,/<\/Directory>/ s/AllowOverride None/AllowOverride All/' \
        /etc/apache2/apache2.conf

# WP-CLI
RUN curl -fsSL https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
        -o /usr/local/bin/wp \
    && chmod +x /usr/local/bin/wp

# Download WordPress into the web root, removing Apache's default index.html
# so index.php takes precedence
RUN curl -fsSL https://wordpress.org/latest.tar.gz \
        | tar -xz --no-same-permissions -C /var/www/html --strip-components=1 \
    || true \
    && test -f /var/www/html/wp-login.php \
    && rm -f /var/www/html/index.html \
    && chmod -R a+rX /var/www/html \
    && cp -a /var/www/html /var/www/html-seed

COPY entrypoint.sh /entrypoint.sh

EXPOSE 8080

ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]
