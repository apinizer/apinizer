#!/bin/sh
###############################################################################
# Apinizer - Worker (API Gateway) Installation (Virtual Server / Linux VM)
# Installs the Worker (the API Gateway runtime) as a standalone package
# (embedded OpenJDK 25, systemd service, Jasypt-encrypted configuration).
# Aligned with https://docs.apinizer.com (tr/setup/sanal-sunucu)
#
# Requires: a running MongoDB (same instance the Manager uses) and an
#           Environment defined in the Manager UI whose name matches
#           APINIZER_ENVIRONMENT_NAME below.
#
# Standalone usage:
#   sudo bash install-apinizer-worker.sh
###############################################################################
echo 'Apinizer - Worker (VM) Installation started'

### Version / MongoDB connection
VERSION=2026.04.2
MONGO_USER=apinizer
MONGO_PASSWORD=Apinizer.1
MONGO_PORT=25080
MONGO_DB=apinizerdb

# Must match an Environment name defined in the Manager UI (case-sensitive).
APINIZER_ENVIRONMENT_NAME=prod
WORKER_TIMEZONE="+03:00"

NODE_IP=$(ip -o route get to 8.8.8.8 | sed -n 's/.*src \([0-9.]\+\).*/\1/p')
echo 'Your Server IP Address:' $NODE_IP

# MongoDB on the same host by default; change MONGO_HOST for a remote MongoDB.
MONGO_HOST=$NODE_IP
MONGO_URI="mongodb://${MONGO_USER}:${MONGO_PASSWORD}@${MONGO_HOST}:${MONGO_PORT}/?authSource=admin&replicaSet=apinizer-replicaset"

APP_DIR=/opt/apinizer-worker
ENV_FILE=${APP_DIR}/conf/apinizer-worker.env

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
curl -fSLO "https://packages.apinizer.com/apinizer-packages/worker/${VERSION}/apinizer-worker-${VERSION}-linux-x64.tar.gz"
curl -fSLO "https://packages.apinizer.com/apinizer-packages/worker/${VERSION}/checksums.sha256"
sha256sum -c --ignore-missing checksums.sha256

### 2) Extract to /opt
sudo mkdir -p /opt
if [ -d "${APP_DIR}" ]; then
  echo "${APP_DIR} already exists, skipping extraction"
else
  sudo tar -xzf "apinizer-worker-${VERSION}-linux-x64.tar.gz" -C /opt
  sudo mv "/opt/apinizer-worker-${VERSION}" "${APP_DIR}"
fi

### 3) Configure
set_env_var "${ENV_FILE}" SPRING_DATA_MONGODB_URI "${MONGO_URI}"
set_env_var "${ENV_FILE}" SPRING_DATA_MONGODB_DATABASE "${MONGO_DB}"
set_env_var "${ENV_FILE}" APINIZER_ENVIRONMENT_NAME "${APINIZER_ENVIRONMENT_NAME}"
set_env_var "${ENV_FILE}" WORKER_TIMEZONE "${WORKER_TIMEZONE}"

### 4) Run installer + encrypt sensitive values
sudo "${APP_DIR}/bin/apiworker-install.sh"
sudo -u apinizer "${APP_DIR}/bin/apiworker-encrypt.sh"

### 5) Start service
sudo systemctl start apinizer-apiworker
sudo systemctl enable apinizer-apiworker 2>/dev/null

echo 'Wait, Worker is starting...'
sleep 30

echo 'Apinizer - Worker (VM) Installation completed'
echo
echo "============================================================"
echo "Worker (API Gateway) Management API : http://$NODE_IP:8091"
echo "  environment name: ${APINIZER_ENVIRONMENT_NAME}"
echo "  service: apinizer-apiworker   logs: journalctl -u apinizer-apiworker -f"
echo
echo "Define this Worker in the Manager UI:"
echo "  Server Management > Gateway Runtimes > New"
echo "  Platform: Virtual Server, Management Type: Remote Gateway"
echo "  Environment Name must equal: ${APINIZER_ENVIRONMENT_NAME}"
echo "  Gateway Management API URL: http://$NODE_IP:8091"
echo "============================================================"
