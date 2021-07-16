#!/bin/sh
#########curl -sSL https://get.docker.com/ | sh
### Uninstall Elasticsearch

### Uninstall MongoDB
sudo service mongod stop

sudo apt-get purge mongodb-org* -y

sudo rm -r /var/log/mongodb

sudo rm -r /var/lib/mongodb

### Uninstall Kubernetes

sudo apt purge kubectl kubeadm kubelet kubernetes-cni -y
sudo apt autoremove -y
sudo rm -fr /etc/kubernetes/; sudo rm -fr ~/.kube/; sudo rm -fr /var/lib/etcd; sudo rm -rf /var/lib/cni/

sudo systemctl daemon-reload

# remove all running docker containers
docker rm -f `docker ps -a | grep "k8s_" | awk '{print $1}'`

### Uninstall Docker
sudo apt-get purge -y docker-engine docker docker.io docker-ce docker-ce-cli
sudo apt-get autoremove -y --purge docker-engine docker docker.io docker-ce  

sudo rm -rf /var/lib/docker /etc/docker
sudo rm /etc/apparmor.d/docker
sudo groupdel docker
sudo rm -rf /var/run/docker.sock

