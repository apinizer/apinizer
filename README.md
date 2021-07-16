# Apinizer Management Platform

# Apinizer Installation

# Apinizer completely uninstall

This a gist for quick uninstall kubernetes

If the cluster is node, First delete it from master
```
kubectl drain <node name> — delete-local-data — force — ignore-daemonsets
kubectl delete node <node name>
```

Then remove kubeadm completely
```
kubeadm reset 
# on debian base 
sudo apt-get purge kubeadm kubectl kubelet kubernetes-cni kube* 
#on centos base
sudo yum remove kubeadm kubectl kubelet kubernetes-cni kube*
# on debian base
sudo apt-get autoremove
#on centos base
sudo yum autoremove
 
sudo rm -rf ~/.kube
```
