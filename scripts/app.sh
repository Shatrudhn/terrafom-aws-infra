#!/bin/bash
set -xe

# System Prep
apt update -y
apt upgrade -y

apt install -y \
software-properties-common \
curl \
wget \
unzip \
gnupg \
lsb-release \
ca-certificates \
apt-transport-https \
git \
nginx \
nfs-common

# PHP 8.3
add-apt-repository ppa:ondrej/php -y
apt update -y

apt install -y \
php8.3 \
php8.3-mysql \
php8.3-xml \
php8.3-curl \
php8.3-gd \
php8.3-imagick \
php8.3-cli \
php8.3-dev \
php8.3-imap \
php8.3-mbstring \
php8.3-opcache \
php8.3-soap \
php8.3-zip \
php8.3-intl \
php8.3-fpm \
php8.3-bcmath \
php8.3-memcached

# Node.js 22
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt install -y nodejs

# Global frontend packages
npm install -g gulp gulp-cli

# Composer 2.8.11
cd /tmp

php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"

php composer-setup.php --version=2.8.11

mv composer.phar /usr/local/bin/composer

chmod +x /usr/local/bin/composer

# Drupal release directories
mkdir -p /var/www/production-taxsutra/releases
mkdir -p /var/www/production-taxsutra/shared
mkdir -p /var/www/production-taxsutra/current

# EFS Mount
mount -t nfs4 ${efs_dns}:/ /var/www/production-taxsutra/shared

echo "${efs_dns}:/ /var/www/production-taxsutra/shared nfs4 defaults,_netdev 0 0" >> /etc/fstab

# Ownership
useradd -m deploy || true
groupadd devops || true
usermod -aG devops deploy

chown -R deploy:devops /var/www/production-taxsutra

# PHP tuning
cat >> /etc/php/8.3/fpm/php.ini <<EOT
max_execution_time = 90
max_input_time = 60
max_input_vars = 3000
memory_limit = 4096M
post_max_size = 560M
upload_max_filesize = 60M
max_file_uploads = 20
display_errors = Off
log_errors = On
expose_php = Off
EOT

systemctl enable nginx
systemctl enable php8.3-fpm

systemctl restart php8.3-fpm
systemctl restart nginx
