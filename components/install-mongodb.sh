#!/bin/sh
###############################################################################
# Apinizer - MongoDB Installation (Ubuntu)
# Installs MongoDB 8.0 as a single-node replica set with an authorized user.
# Aligned with https://docs.apinizer.com (tr/setup/mongodb/ubuntu-mongodb)
#
# Standalone usage:
#   sudo bash install-mongodb.sh
###############################################################################
echo 'Apinizer - MongoDB Installation started'

### Versions / credentials
MONGODB_VERSION=8.0.17
MONGO_USER=apinizer
MONGO_PASSWORD=Apinizer.1

CURRENT_USER=$(whoami)
NODE_IP=$(ip -o route get to 8.8.8.8 | sed -n 's/.*src \([0-9.]\+\).*/\1/p')
echo 'Current User:' $CURRENT_USER
echo 'Your Server IP Address:' $NODE_IP

### OS prerequisites
sudo systemctl stop ufw 2>/dev/null
sudo systemctl disable ufw 2>/dev/null
sudo apt update
sudo apt install -y curl wget net-tools gnupg2 software-properties-common apt-transport-https ca-certificates lsb-release jq
sudo swapoff -a

### libssl1.1 dependency
wget http://archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2_amd64.deb
sudo dpkg -i ./libssl1.1_1.1.1f-1ubuntu2_amd64.deb

### MongoDB repository
curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/mongodb-8.gpg
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/8.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list

sudo apt update
sudo apt install -y mongodb-org=${MONGODB_VERSION}
sudo apt-mark hold mongodb-org*

### Replica set key file
sudo mkdir -p /etc/mongodb/keys/
sudo chown -Rf $CURRENT_USER:$CURRENT_USER /etc/mongodb/keys
sudo chmod -Rf 700 /etc/mongodb/keys
sudo openssl rand -base64 756 > /etc/mongodb/keys/mongo-key
sudo chmod -Rf 400 /etc/mongodb/keys/mongo-key
sudo chown -Rf mongodb:mongodb /etc/mongodb

### MongoDB configuration
sudo bash -c 'cat << EOF > /etc/mongod.conf
storage:
  dbPath: /var/lib/mongodb
  wiredTiger:
    engineConfig:
       cacheSizeGB: 2

systemLog:
  destination: file
  logAppend: true
  path: /var/log/mongodb/mongod.log

net:
  port: 25080
  bindIp: 0.0.0.0

replication:
  replSetName: apinizer-replicaset

security:
  authorization: enabled
  keyFile:  /etc/mongodb/keys/mongo-key

setParameter:
  transactionLifetimeLimitSeconds: 300

processManagement:
  timeZoneInfo: /usr/share/zoneinfo
EOF'

sudo systemctl start mongod
sudo systemctl enable mongod

sleep 60

### Initialize the replica set
mongosh mongodb://localhost:25080 --eval "rs.initiate()"

### Create the authorized Apinizer user
bash -c "cat << EOF > mongoUser.js
use admin
db.createUser(
  {
    user: \"${MONGO_USER}\",
    pwd: \"${MONGO_PASSWORD}\",
    roles: [ { role: \"root\", db: \"admin\"} ],
    mechanisms: [ \"SCRAM-SHA-1\" ]
  }
 );
EOF"
mongosh mongodb://localhost:25080 < mongoUser.js

### Set the replica set member host to this server's IP
bash -c 'cat << EOF > mongoReplicaChange.js
cfg = rs.conf()
cfg.members[0].host = nodeIpPort
rs.reconfig(cfg)
EOF'
mongosh mongodb://localhost:25080 --authenticationDatabase "admin" -u "${MONGO_USER}" -p "${MONGO_PASSWORD}" --quiet --eval "var nodeIpPort='$NODE_IP:25080'" mongoReplicaChange.js

echo 'Apinizer - MongoDB Installation completed'
