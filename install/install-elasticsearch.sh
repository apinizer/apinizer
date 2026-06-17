#!/bin/sh
###############################################################################
# Apinizer - Elasticsearch Installation (Ubuntu)
# Installs Elasticsearch 8.17 with security (TLS + auto-generated passwords).
# Aligned with https://docs.apinizer.com (tr/installation/elasticsearch/ubuntu-elasticsearch-8.17.10)
#
# Standalone usage:
#   sudo bash install-elasticsearch.sh
#
# NOTE: Because Elasticsearch 8 requires security, the connection must be added
#       to Apinizer manually via the UI using the credentials/certificate that
#       this script prints at the end.
###############################################################################
echo 'Apinizer - Elasticsearch Installation started'

### Version
ELASTICSEARCH_VERSION=8.17.10
ES_HOME=/opt/elasticsearch/elasticsearch-${ELASTICSEARCH_VERSION}

CURRENT_USER=$(whoami)
NODE_IP=$(ip -o route get to 8.8.8.8 | sed -n 's/.*src \([0-9.]\+\).*/\1/p')
# Directory the script was started from (passwords yaml is written here)
RUN_DIR="$(pwd)"
echo 'Current User:' $CURRENT_USER
echo 'Your Server IP Address:' $NODE_IP

### OS prerequisites
sudo systemctl stop ufw 2>/dev/null
sudo systemctl disable ufw 2>/dev/null
sudo apt update
sudo apt install -y curl wget net-tools gnupg2 software-properties-common apt-transport-https ca-certificates lsb-release
sudo swapoff -a

### Dedicated elasticsearch user
sudo adduser --disabled-password --gecos "" elasticsearch
sudo usermod --password $(echo Apinizer.1 | openssl passwd -1 -stdin) elasticsearch
sudo usermod -aG sudo elasticsearch

### OS limits / sysctl
ulimit -n 65535
sudo bash -c 'cat << EOF > /etc/security/limits.conf
elasticsearch  -  nofile  65535
elasticsearch soft memlock unlimited
elasticsearch hard memlock unlimited
EOF'

sudo bash -c 'cat << EOF > /etc/sysctl.d/99-elasticsearch.conf
vm.swappiness=1
vm.max_map_count=262144
EOF'
sudo sysctl --system
sudo sysctl vm.max_map_count

### Directories
sudo mkdir -p /opt/elasticsearch
sudo chown -Rf elasticsearch:elasticsearch /opt/elasticsearch
sudo chmod -Rf 775 /opt/elasticsearch

sudo mkdir -p /data/elastic-data/
sudo mkdir -p /data/elastic-snapdata/
sudo chown -Rf elasticsearch:elasticsearch /data/elastic-*
sudo chmod -Rf 775 /data/elastic-*

### Download and extract
cd /opt/elasticsearch
sudo wget --no-cache https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-${ELASTICSEARCH_VERSION}-linux-x86_64.tar.gz
sudo tar -xzf elasticsearch-${ELASTICSEARCH_VERSION}-linux-x86_64.tar.gz

### Configuration (http.ssl is enabled later, after setup-passwords)
sudo bash -c "cat << EOF > ${ES_HOME}/config/elasticsearch.yml
cluster.name: ApinizerEsCluster
node.name: \"${NODE_IP}\"
network.host: \"${NODE_IP}\"
http.port: 9200

node.roles: [\"master\",\"data\"]

cluster.initial_master_nodes: [\"${NODE_IP}\"]

discovery.seed_hosts: []
path.data: /data/elastic-data/
path.repo: [\"/data/elastic-snapdata\"]

# Security
xpack.security.enabled: true
xpack.security.enrollment.enabled: true

# Transport SSL:
xpack.security.transport.ssl:
  enabled: true
  verification_mode: certificate
  keystore.path: certs/elastic-certificates.p12
  truststore.path: certs/elastic-certificates.p12

# CORS ayarlari
http.cors.enabled: true
http.cors.allow-origin: \"*\"
http.cors.allow-methods: OPTIONS, HEAD, GET, POST, PUT, DELETE
http.cors.allow-headers: X-Requested-With, X-Auth-Token, Content-Type, Content-Length
EOF"

### JVM heap (single-server PoC value; tune up to half of RAM / max 32g in production)
sudo mkdir -p ${ES_HOME}/config/jvm.options.d
sudo bash -c "cat << EOF > ${ES_HOME}/config/jvm.options.d/heap.options
-Xms2g
-Xmx2g
EOF"

### Generate TLS certificates (passwordless)
sudo chown -Rf elasticsearch:elasticsearch ${ES_HOME}
sudo -u elasticsearch bash -c "cd ${ES_HOME} && \
  ./bin/elasticsearch-certutil ca --silent --days 3650 --pass '' --out elastic-stack-ca.p12 && \
  ./bin/elasticsearch-certutil cert --silent --days 3650 --ca elastic-stack-ca.p12 --ca-pass '' --pass '' --out elastic-certificates.p12 && \
  mkdir -p config/certs && \
  mv elastic-certificates.p12 config/certs/ && \
  mv elastic-stack-ca.p12 config/certs/ && \
  openssl pkcs12 -in config/certs/elastic-certificates.p12 -nokeys -out config/certs/elastic-certificates.crt -passin pass:"

sudo chown -Rf elasticsearch:elasticsearch /opt/elasticsearch/elasticsearch-${ELASTICSEARCH_VERSION}/*
sudo chmod -Rf 775 /opt/elasticsearch/elasticsearch-${ELASTICSEARCH_VERSION}/*

### systemd service
sudo bash -c "cat << EOF > /etc/systemd/system/elasticsearch.service
[Unit]
Description=Elasticsearch ${ELASTICSEARCH_VERSION}
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=elasticsearch
Group=elasticsearch
ExecStart=${ES_HOME}/bin/elasticsearch
Environment=ES_PATH_CONF=${ES_HOME}/config
Restart=on-failure
RestartSec=5
LimitNOFILE=65536
LimitMEMLOCK=infinity
TimeoutStopSec=0

[Install]
WantedBy=multi-user.target
EOF"

sudo systemctl daemon-reload
sudo systemctl start elasticsearch
sudo systemctl enable elasticsearch

echo 'Wait, Installation in progress...'
sleep 60

### Create built-in user passwords (over HTTP, http.ssl still disabled)
ES_PW_OUTPUT=$(sudo -u elasticsearch ${ES_HOME}/bin/elasticsearch-setup-passwords auto -b)
echo "$ES_PW_OUTPUT" | sudo tee /opt/elasticsearch/elasticsearch-passwords.txt > /dev/null
ELASTIC_PASSWORD=$(echo "$ES_PW_OUTPUT" | grep "PASSWORD elastic " | awk '{print $4}')

### Save all credentials as YAML in the directory the script was started from
ES_PW_YAML="$RUN_DIR/elastic-passwords.yaml"
{
  echo "elasticsearch:"
  echo "  url: \"https://$NODE_IP:9200\""
  echo "  certificate: \"${ES_HOME}/config/certs/elastic-certificates.crt\""
  echo "  users:"
  echo "$ES_PW_OUTPUT" | grep '^PASSWORD ' | awk '{print "    "$2": \""$4"\""}'
} > "$ES_PW_YAML"
echo "Elasticsearch credentials saved to: $ES_PW_YAML"

### Enable TLS on the HTTP layer after passwords are set
sudo bash -c "cat << EOF >> ${ES_HOME}/config/elasticsearch.yml

xpack.security.http.ssl:
  enabled: true
  keystore.path: certs/elastic-certificates.p12
  truststore.path: certs/elastic-certificates.p12
EOF"
sudo chown -Rf elasticsearch:elasticsearch ${ES_HOME}
sudo systemctl restart elasticsearch

echo 'Wait, Installation in progress...'
sleep 30

echo 'Apinizer - Elasticsearch Installation completed'
echo
echo "============================================================"
echo "Elasticsearch ${ELASTICSEARCH_VERSION} (TLS enabled) https://$NODE_IP:9200"
echo "  username: elastic"
echo "  password: ${ELASTIC_PASSWORD}"
echo "  all credentials (YAML): ${ES_PW_YAML}"
echo "  all built-in passwords : /opt/elasticsearch/elasticsearch-passwords.txt"
echo "  certificate: ${ES_HOME}/config/certs/elastic-certificates.crt"
echo
echo "Add this connection in Apinizer manually:"
echo "  Administration > Connection Management > Elasticsearch"
echo "  Use the username/password above and the elastic-certificates.crt file."
echo "============================================================"
