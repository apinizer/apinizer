#!/bin/sh
######### sudo curl -s https://raw.githubusercontent.com/apinizer/apinizer/main/uninstallApinizer.sh | bash
### Uninstall Elasticsearch

### Uninstall MongoDB
sudo service mongod stop

sudo apt-get purge mongodb-org* -y

sudo rm -rf /var/log/mongodb

sudo rm -rf /var/lib/mongodb

### Uninstall Kubernetes
sudo kubeadm reset -f
sudo apt purge kubectl kubeadm kubelet kubernetes-cni -y
sudo apt autoremove -y
sudo rm -rf /etc/kubernetes/; sudo rm -fr ~/.kube/; sudo rm -fr /var/lib/etcd; sudo rm -rf /var/lib/cni/
sudo rm -rf /etc/cni /etc/kubernetes /var/lib/dockershim /var/lib/etcd /var/lib/kubelet /var/run/kubernetes ~/.kube/*

sudo systemctl daemon-reload

# remove all running docker containers
docker rm -f `docker ps -a | grep "k8s_" | awk '{print $1}'`

### Uninstall Docker
sudo apt-get purge -y docker-engine docker docker.io docker-ce docker-ce-cli
sudo apt-get autoremove -y --purge docker-engine docker docker.io docker-ce  

sudo rm -rf /var/lib/docker /etc/docker
sudo rm -rf /etc/apparmor.d/docker
sudo groupdel docker
sudo rm -rf /var/run/docker.sock

### Uninstall Elasticsearch
sudo rm -rf /opt/elasticsearch

sudo rm -rf /etc/systemd/system/elasticsearch.service

sudo systemctl daemon-reload
echo 'Apinizer uninstall Successfully'
