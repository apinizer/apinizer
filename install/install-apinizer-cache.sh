#!/bin/sh
###############################################################################
# Apinizer - Cache (Hazelcast) Installation (Virtual Server / Linux VM)
# Installs the Cache module as a standalone package (embedded OpenJDK 25,
# systemd service, Jasypt-encrypted configuration).
# Aligned with https://docs.apinizer.com (tr/setup/sanal-sunucu) xx
#
# The Cache holds quota counters, OIDC sessions, circuit-breaker state, etc.
# It is mandatory when running multiple Workers so their counters stay in sync.
#
# Requires: a running MongoDB (same instance the Manager/Worker use).
#
# Standalone usage:
#   sudo bash install-apinizer-cache.sh
###############################################################################
echo 'Apinizer - Cache (VM) Installation started'

### Version / MongoDB connection
VERSION=2026.04.2
MONGO_USER=apinizer
MONGO_PASSWORD=Apinizer.1
MONGO_PORT=25080
MONGO_DB=apinizerdb

CACHE_QUOTA_TIMEZONE="+03:00"
# Multi-node cluster: comma-separated IP list, identical on every node
# (e.g. 10.0.0.11,10.0.0.12,10.0.0.13). Leave empty for a single-node cluster
# (defaults to 127.0.0.1).
APINIZER_CACHE_CLUSTER_MEMBERS=""

NODE_IP=$(ip -o route get to 8.8.8.8 | sed -n 's/.*src \([0-9.]\+\).*/\1/p')
echo 'Your Server IP Address:' $NODE_IP

# MongoDB on the same host by default; change MONGO_HOST for a remote MongoDB.
MONGO_HOST=$NODE_IP
MONGO_URI="mongodb://${MONGO_USER}:${MONGO_PASSWORD}@${MONGO_HOST}:${MONGO_PORT}/?authSource=admin&replicaSet=apinizer-replicaset"

APP_DIR=/opt/apinizer-cache
ENV_FILE=${APP_DIR}/conf/apinizer-cache.env

### OS prerequisites
sudo apt update 2>/dev/null
sudo apt install -y curl wget tar openssl ca-certificates

### Helper: set (replace or append) a key in the env file
set_env_var() {
  _file="$1"; _key="$2"; _val="$3"
  sudo sed -i "/^${_key}=/d" "$_file"
  echo "${_key}=\"${_val}\"" | sudo tee -a "$_file" > /dev/null
}

### 1) Download + verify
cd /tmp
curl -fSLO "https://packages.apinizer.com/apinizer-packages/cache/${VERSION}/apinizer-cache-${VERSION}-linux-x64.tar.gz"
curl -fSLO "https://packages.apinizer.com/apinizer-packages/cache/${VERSION}/checksums.sha256"
sha256sum -c --ignore-missing checksums.sha256

### 2) Extract to /opt
sudo mkdir -p /opt
if [ -d "${APP_DIR}" ]; then
  echo "${APP_DIR} already exists, skipping extraction"
else
  sudo tar -xzf "apinizer-cache-${VERSION}-linux-x64.tar.gz" -C /opt
  sudo mv "/opt/apinizer-cache-${VERSION}" "${APP_DIR}"
fi

### 3) Configure
set_env_var "${ENV_FILE}" SPRING_DATA_MONGODB_URI "${MONGO_URI}"
set_env_var "${ENV_FILE}" SPRING_DATA_MONGODB_DATABASE "${MONGO_DB}"
set_env_var "${ENV_FILE}" CACHE_QUOTA_TIMEZONE "${CACHE_QUOTA_TIMEZONE}"
if [ -n "${APINIZER_CACHE_CLUSTER_MEMBERS}" ]; then
  set_env_var "${ENV_FILE}" APINIZER_CACHE_CLUSTER_MEMBERS "${APINIZER_CACHE_CLUSTER_MEMBERS}"
fi

### 4) Run installer + encrypt sensitive values
sudo "${APP_DIR}/bin/apicache-install.sh"
sudo -u apinizer "${APP_DIR}/bin/apicache-encrypt.sh"

### 5) Start service
sudo systemctl start apinizer-apicache
sudo systemctl enable apinizer-apicache 2>/dev/null

echo 'Wait, Cache is starting...'
sleep 30

echo 'Apinizer - Cache (VM) Installation completed'
echo
echo "============================================================"
echo "Cache REST API : http://$NODE_IP:8090   (Hazelcast: 5701)"
echo "  service: apinizer-apicache   logs: journalctl -u apinizer-apicache -f"
echo
echo "Register this Cache in the Manager UI:"
echo "  Admin > Cache Servers > New  ->  host: $NODE_IP  port: 8090"
echo "============================================================"
