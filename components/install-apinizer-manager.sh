#!/bin/sh
###############################################################################
# Apinizer - API Manager Installation (Virtual Server / Linux VM)
# Installs the API Manager as a standalone package (embedded OpenJDK 25,
# systemd service, Jasypt-encrypted configuration).
# Aligned with https://docs.apinizer.com (tr/setup/sanal-sunucu)
#
# Requires: a running, reachable MongoDB replica set with the 'apinizer' user.
#
# Standalone usage:
#   sudo bash install-apinizer-manager.sh
###############################################################################
echo 'Apinizer - API Manager (VM) Installation started'

### Version / MongoDB connection
# Apinizer paket surumu. packages.apinizer.com'da YAYINLANMIS gecerli bir surum olmali.
# Degistirmek icin ya bu satiri duzenleyin (sudo vi install-apinizer-manager.sh)
# ya da calistirirken gecin:  sudo -E VERSION=2026.04.2 bash install-apinizer-manager.sh
VERSION="${VERSION:-2026.04.2}"
MONGO_USER=apinizer
MONGO_PASSWORD=Apinizer.1
MONGO_PORT=25080
MONGO_DB=apinizerdb

NODE_IP=$(ip -o route get to 8.8.8.8 | sed -n 's/.*src \([0-9.]\+\).*/\1/p')
echo 'Your Server IP Address:' $NODE_IP

# MongoDB on the same host by default; change MONGO_HOST for a remote MongoDB.
MONGO_HOST=$NODE_IP
MONGO_URI="mongodb://${MONGO_USER}:${MONGO_PASSWORD}@${MONGO_HOST}:${MONGO_PORT}/?authSource=admin&replicaSet=apinizer-replicaset"

APP_DIR=/opt/apinizer-manager
ENV_FILE=${APP_DIR}/conf/application.env

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
TARBALL="apinizer-apimanager-${VERSION}-linux-x64.tar.gz"
BASE="https://packages.apinizer.com/apinizer-packages/apimanager/${VERSION}"
if ! curl -fSLO "${BASE}/${TARBALL}"; then
  echo "============================================================"
  echo "HATA: ${TARBALL} indirilemedi (muhtemelen 404)."
  echo "Bu surum packages.apinizer.com'da yayinlanmamis olabilir."
  echo "Dogru VERSION'u ayarlayip tekrar deneyin:"
  echo "  - sudo vi install-apinizer-manager.sh  (VERSION satirini degistirin)"
  echo "  - veya:  sudo -E VERSION=<surum> bash install-apinizer-manager.sh"
  echo "============================================================"
  exit 1
fi
curl -fSLO "${BASE}/checksums.sha256" && sha256sum -c --ignore-missing checksums.sha256 || \
  echo "UYARI: checksum dogrulamasi atlandi (checksums.sha256 bulunamadi)."

### 2) Extract to /opt
sudo mkdir -p /opt
if [ -d "${APP_DIR}" ]; then
  echo "${APP_DIR} already exists, skipping extraction"
else
  sudo tar -xzf "apinizer-apimanager-${VERSION}-linux-x64.tar.gz" -C /opt
  sudo mv "/opt/apinizer-apimanager-${VERSION}" "${APP_DIR}"
fi

### 3) Configure (MongoDB connection, plaintext for now)
set_env_var "${ENV_FILE}" SPRING_DATA_MONGODB_URI "${MONGO_URI}"
set_env_var "${ENV_FILE}" SPRING_DATA_MONGODB_DATABASE "${MONGO_DB}"

### 4) Run installer (creates 'apinizer' system user, master.key, systemd unit)
sudo "${APP_DIR}/bin/apimanager-install.sh"

### 5) Encrypt sensitive values in place
sudo -u apinizer "${APP_DIR}/bin/apimanager-encrypt.sh"

### 6) Start service
sudo systemctl start apinizer-apimanager
sudo systemctl enable apinizer-apimanager 2>/dev/null

echo 'Wait, API Manager is starting...'
sleep 45

### 7) Verify
curl -fsS http://127.0.0.1:8080/management/health || echo "Health check not ready yet; check: sudo journalctl -u apinizer-apimanager -f"

echo 'Apinizer - API Manager (VM) Installation completed'
echo
echo "============================================================"
echo "Apinizer Management Console : http://$NODE_IP:8080"
echo "  default user: admin   password: Apinizer.1!"
echo "  service: apinizer-apimanager   logs: journalctl -u apinizer-apimanager -f"
echo "============================================================"
