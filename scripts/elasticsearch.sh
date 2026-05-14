#!/bin/bash
set -xe

apt update -y

apt install -y \
apt-transport-https \
wget \
curl \
gnupg

wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | \
gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] \
https://artifacts.elastic.co/packages/8.x/apt stable main" \
| tee /etc/apt/sources.list.d/elastic-8.x.list

apt update -y

apt install elasticsearch=8.10.2 -y

apt-mark hold elasticsearch

# Elasticsearch Config
cat > /etc/elasticsearch/elasticsearch.yml <<EOT
cluster.name: production-es
node.name: es-node-1
network.host: 0.0.0.0
http.port: 9200
discovery.type: single-node
xpack.security.enabled: true
EOT

# Memory tuning for t3.small
mkdir -p /etc/elasticsearch/jvm.options.d

cat > /etc/elasticsearch/jvm.options.d/custom.options <<EOT
-Xms512m
-Xmx512m
EOT

# Kernel tuning
sysctl -w vm.max_map_count=262144
echo "vm.max_map_count=262144" >> /etc/sysctl.conf

systemctl daemon-reload
systemctl enable elasticsearch
systemctl start elasticsearch

sleep 30

# Generate credentials
/usr/share/elasticsearch/bin/elasticsearch-reset-password -u elastic -b \
> /root/elasticsearch-credentials.txt

chmod 600 /root/elasticsearch-credentials.txt
