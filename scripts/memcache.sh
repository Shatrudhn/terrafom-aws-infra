#!/bin/bash
set -xe

apt update -y

apt install -y memcached libmemcached-tools

sed -i 's/^-l 127.0.0.1/-l 0.0.0.0/' /etc/memcached.conf
sed -i 's/^-m 64/-m 1024/' /etc/memcached.conf

systemctl enable memcached
systemctl restart memcached
