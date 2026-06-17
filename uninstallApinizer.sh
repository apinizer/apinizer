#!/bin/sh

######### sudo curl -s https://raw.githubusercontent.com/apinizer/apinizer/main/uninstallApinizer.sh | bash
#
# Uninstalls a single-server Virtual Server (Linux VM) Apinizer installation:
# Apinizer standalone modules, MongoDB and Elasticsearch.

### Uninstall Apinizer modules (standalone VM packages)
for svc in apimanager apiworker apicache apiintegration apiportal; do
  sudo systemctl stop "apinizer-${svc}" 2>/dev/null
  sudo systemctl disable "apinizer-${svc}" 2>/dev/null
  sudo rm -f "/etc/systemd/system/apinizer-${svc}.service"
done

sudo rm -rf /opt/apinizer-manager /opt/apinizer-worker /opt/apinizer-cache /opt/apinizer-integration /opt/apinizer-portal

sudo systemctl daemon-reload

### Uninstall MongoDB
sudo apt-mark unhold mongodb-org* 2>/dev/null
sudo systemctl stop mongod
sudo apt-get purge mongodb-org* -y
sudo rm -rf /var/log/mongodb
sudo rm -rf /var/lib/mongodb
sudo rm -rf /etc/mongodb /etc/mongod.conf
sudo rm -rf /etc/apt/sources.list.d/mongodb-org-8.0.list /etc/apt/trusted.gpg.d/mongodb-8.gpg

### Uninstall Elasticsearch
sudo systemctl stop elasticsearch
sudo rm -rf /opt/elasticsearch
sudo rm -rf /data/elastic-data /data/elastic-snapdata
sudo rm -rf /etc/systemd/system/elasticsearch.service
sudo rm -rf /etc/sysctl.d/99-elasticsearch.conf

sudo systemctl daemon-reload

### Remove the apinizer/elasticsearch system users (ignore errors if in use)
sudo userdel apinizer 2>/dev/null
sudo userdel elasticsearch 2>/dev/null

### Remove leftover files
rm -rf mongoReplicaChange.js mongoUser.js elastic-passwords.yaml libssl1.1_1.1.1f-1ubuntu2_amd64.deb

echo 'Apinizer uninstall Successfully'
