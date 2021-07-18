#!/bin/sh
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
sudo kubeadm init --pod-network-cidr=10.244.0.0/16
   
echo 'Wait, Installation in progress...' 
sleep 60

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown -R $(id -u):$(id -g) $HOME/.kube
 
echo 'Wait, Installation in progress...' 
sleep 60
 
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
 
echo 'source <(kubectl completion bash)' >>  $HOME/.bashrc
 
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

kubectl apply -f https://raw.githubusercontent.com/apinizer/apinizer/main/apinizer-deployment.yaml

echo 'Wait, Installation in progress...' 
sleep 60

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


######## Install elasticsearch
sudo usermod --password $(echo Apinizer.1 | openssl passwd -1 -stdin) elasticsearch


echo 'Apinizer API Management Platform Installation Successfully'

