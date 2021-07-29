#!/bin/sh
echo
echo -e "     _      ____    ___   _   _   ___   _____  _____   ____                \033[0m"
echo -e "    / \    |  _ \  |_ _| | \ | | |_ _| |__  / | ____| |  _ \			      \033[0m"
echo -e "   / _ \   | |_) |  | |  |  \| |  | |    / /  |  _|   | |_) |			      \033[0m"
echo -e "  / ___ \  |  __/   | |  | |\  |  | |   / /_  | |___  |  _ <			      \033[0m"
echo -e " /_/   \_\ |_|     |___| |_| \_| |___| /____| |_____| |_| \_\			      \033[0m"
echo -e "                   \033[0mhttps://apinizer.com\033[0m"                       
echo -e "                                                                             \033[0m"

echo 'Started Apinizer API Management Platform Installation'
### sudo curl -s https://raw.githubusercontent.com/apinizer/apinizer/main/installApinizer.sh | bash
sudo apt-get update  

sudo apt -y install curl apt-transport-https wget ca-certificates curl software-properties-common

sudo swapoff -a

sudo bash -c 'cat << EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward=1
net.ipv4.tcp_max_syn_backlog=40000
net.core.somaxconn=40000
net.core.wmem_default=8388608
net.core.rmem_default=8388608
net.ipv4.tcp_sack=1
net.ipv4.tcp_window_scaling=1
net.ipv4.tcp_fin_timeout=15
net.ipv4.tcp_keepalive_intvl=30
net.ipv4.tcp_tw_reuse=1
net.ipv4.tcp_moderate_rcvbuf=1
net.core.rmem_max=134217728
net.core.wmem_max=134217728
net.ipv4.tcp_mem=134217728 134217728 134217728
net.ipv4.tcp_rmem=4096 277750 134217728
net.ipv4.tcp_wmem=4096 277750 134217728
net.core.netdev_max_backlog=300000
EOF'

sudo modprobe br_netfilter

sudo sysctl --system

sudo lsmod | grep br_netfilter

sudo apt update

sudo apt install -y curl gnupg2 software-properties-common apt-transport-https ca-certificates

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

sudo apt update

sudo apt install -y containerd.io docker-ce docker-ce-cli

sudo mkdir -p /etc/systemd/system/docker.service.d
   
   
sudo bash -c 'cat << EOF > /etc/docker/daemon.json
{
   "exec-opts": ["native.cgroupdriver=systemd"]
}
EOF'

sudo systemctl daemon-reload 
sudo systemctl restart docker
sudo systemctl enable docker

sudo groupadd docker

sudo gpasswd -a $USER docker


# Install Kubernetes
   
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
   
sudo bash -c 'cat << EOF > /etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF'
   
sudo apt update
sudo apt -y install kubelet=1.18.4-00 kubeadm=1.18.4-00 kubectl=1.18.4-00
sudo systemctl enable kubelet
sudo systemctl start kubelet
sleep 20
sudo kubeadm init --pod-network-cidr=10.244.0.0/16
   
echo 'Wait, Installation in progress...' 
sleep 90

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown -R $(id -u):$(id -g) $HOME/.kube
 
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

echo 'Wait, Installation in progress...' 
sleep 10
 
# Allow workloads to be scheduled to the master node
kubectl taint nodes `hostname`  node-role.kubernetes.io/master:NoSchedule-
 
# Create an admin user that will be needed in order to access the Kubernetes Dashboard
sudo bash -c 'cat << EOF > admin-user.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kube-system
EOF'
 
kubectl create -f admin-user.yaml
 
# Create an admin role that will be needed in order to access the Kubernetes Dashboard
sudo bash -c 'cat << EOF > role-binding.yaml
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kube-system
EOF'
 
kubectl create -f role-binding.yaml

kubectl create clusterrolebinding permissive-binding --clusterrole=cluster-admin --user=admin --user=kubelet --group=system:serviceaccounts

kubectl create clusterrolebinding kubernetes-dashboard -n kube-system --clusterrole=cluster-admin --serviceaccount=kube-system:kubernetes-dashboard

# Install MongoDB Replicaset
#!/bin/sh
sudo apt-get update  

sudo sed -i 's/^SELINUX=enforcing$/SELINUX=disabled/' /etc/selinux/config

sudo swapoff -a

wget -qO - https://www.mongodb.org/static/pgp/server-4.2.asc | sudo apt-key add -

echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/4.2 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.2.list

sudo apt update

sudo apt install mongodb-org -y

sudo bash -c 'cat << EOF > /etc/mongod.conf
storage:
  dbPath: /var/lib/mongodb
  journal:
    enabled: true

systemLog:
  destination: file
  logAppend: true
  path: /var/log/mongodb/mongod.log

processManagement:
  timeZoneInfo: /usr/share/zoneinfo

net:
  port: 25080
  bindIp: 0.0.0.0

replication:
 replSetName: apinizer-replicaset

security:
    authorization: "enabled"
EOF'

sudo systemctl start mongod

sudo systemctl enable mongod

sleep 60

mongo mongodb://localhost:25080 --eval "rs.initiate()"

bash -c 'cat << EOF > mongoUser.js
use admin
db.createUser(
  {
    user: "apinizer",
    pwd: "Apinizer.1",
    roles: [ { role: "root", db: "admin"} ]
  }
 );
EOF'

mongo mongodb://localhost:25080 < mongoUser.js

NODE_IP=$(kubectl get nodes --selector=node-role.kubernetes.io/master -o jsonpath='{$.items[*].status.addresses[?(@.type=="InternalIP")].address}')

bash -c 'cat << EOF > mongoReplicaChange.js
cfg = rs.conf()
cfg.members[0].host = nodeIpPort
rs.reconfig(cfg)
EOF'

mongo mongodb://localhost:25080 --authenticationDatabase "admin" -u "apinizer" -p "Apinizer.1" --quiet --eval "var nodeIpPort='$NODE_IP:25080'" mongoReplicaChange.js

wget --no-cache https://github.com/apinizer/apinizer/raw/main/apinizer-initialdb.archive

mongorestore --host=localhost --port=25080 --username=apinizer --password Apinizer.1 --authenticationDatabase=admin --gzip --archive=apinizer-initialdb.archive

echo 'Wait, Installation in progress...' 
sleep 60

######## Deploy Apinizer 
kubectl apply -f https://raw.githubusercontent.com/apinizer/apinizer/main/apinizer-deployment.yaml

echo 'Wait, Installation in progress...' 
sleep 60

######## Install elasticsearch

sudo adduser elasticsearch

sudo usermod --password $(echo Apinizer.1 | openssl passwd -1 -stdin) elasticsearch

sudo usermod -aG sudo elasticsearch

ulimit -n 65535


sudo bash -c 'cat << EOF > /etc/security/limits.conf
elasticsearch  -  nofile  65535
elasticsearch soft memlock unlimited
elasticsearch hard memlock unlimited
EOF'

sudo sysctl -w vm.swappiness=1

sudo sysctl -w vm.max_map_count=262144

sudo bash -c 'cat << EOF > /etc/sysctl.conf
vm.max_map_count=262144 elasticsearch
EOF'


sudo sysctl -p

sudo sysctl vm.max_map_count

sudo mkdir -p /opt/elasticsearch

sudo chown -Rf elasticsearch:elasticsearch /opt/elasticsearch

sudo chmod -Rf 775 /opt/elasticsearch

sudo mkdir -p /mnt/elastic-data/

sudo chown -Rf elasticsearch:elasticsearch /mnt/elastic-data/

sudo chmod -Rf 775 /mnt/elastic-data/

cd /opt/elasticsearch

sudo wget --no-cache https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.9.2-linux-x86_64.tar.gz

sudo tar -xzf elasticsearch-7.9.2-linux-x86_64.tar.gz

sudo bash -c 'cat << EOF > /opt/elasticsearch/elasticsearch-7.9.2/config/elasticsearch.yml
cluster.name: ApinizerEsCluster
#give your node a name (the same as your hostname)
node.name: "apinizeres"
node.master: true
node.data: true
#enter the private IP and port of your node (the same ip as your machine)
network.host: 0.0.0.0
http.port: 9200
#detail the private IPs of your nodes:
#to avoid split brain ([Master Eligible Node) / 2 + 1])

cluster.initial_master_nodes: ["0.0.0.0"]

discovery.seed_hosts: []
path.data: /mnt/elastic-data/

bootstrap.memory_lock: true

http.cors.enabled : true
http.cors.allow-origin : "*"
http.cors.allow-methods : OPTIONS, HEAD, GET, POST, PUT, DELETE
http.cors.allow-headers : X-Requested-With,X-Auth-Token,Content-Type, Content-Length
EOF'

sudo wget --no-cache https://raw.githubusercontent.com/apinizer/apinizer/main/elasticsearch-service.sh -O /opt/elasticsearch/elasticsearch-7.9.2/bin/elasticsearch-service.sh

sudo chown -Rf elasticsearch:elasticsearch /opt/elasticsearch/elasticsearch-7.9.2/*
sudo chmod -Rf 775 /opt/elasticsearch/elasticsearch-7.9.2/*

sudo bash -c 'cat << EOF > /etc/systemd/system/elasticsearch.service
#!/bin/sh
[Unit]
Description=ElasticSearch Server
After=network.target
After=syslog.target

[Install]
WantedBy=multi-user.target

[Service]
Type=forking
ExecStart=/opt/elasticsearch/elasticsearch-7.9.2/bin/elasticsearch-service.sh start
ExecStop=/opt/elasticsearch/elasticsearch-7.9.2/bin/elasticsearch-service.sh stop
ExecReload=/opt/elasticsearch/elasticsearch-7.9.2/bin/elasticsearch-service.sh restart
LimitNOFILE=65536
LimitMEMLOCK=infinity
User=elasticsearch
EOF'

sudo systemctl daemon-reload

sudo systemctl start elasticsearch

sudo systemctl enable elasticsearch


echo 'Wait, Installation in progress...' 
sleep 30

sudo wget --no-cache https://raw.githubusercontent.com/apinizer/apinizer/main/changeElasticIp.js

mongo mongodb://localhost:25080/apinizerdb --authenticationDatabase "admin" -u "apinizer" -p "Apinizer.1" --eval "var nodeIpPort='$NODE_IP'" changeElasticIp.js

echo 'Apinizer API Management Platform Installation Successfully'

