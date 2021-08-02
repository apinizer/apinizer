# Apinizer Management Platform
Apinizer is a product family that enables the following tasks to be done easily and quickly with simple configurations, without writing code as much as possible:

Apinizer API Gateway: Performing security, traffic management, load balancing, logging, message content conversion and enrichment, validation, testing and many other tasks related to API/Web Services by configuration via form-based interfaces without writing code.
Apinizer API Creator → Mock API Creator: Creating and publishing a Mock API instantly without the need for any server or writing code.
Apinizer API Creator → DB-2-API: Creating and publishing an API/Web Service for database operations instantly without the need for a server, or the need for writing code other than SQL.
Apinizer API Creator → Script-2-API: Creating and publishing an API/Web Service for JavaScript or Groovy code instantly without the need for a server.
Apinizer API Monitor: Automatic and continuous monitoring of whether API/Web Services or external systems are working properly and being notified of problems instantly.
Apinizer API Analytics: Visualizing performance, usage detail, error metrics, and etc. of API/Web Services.
Apinizer API Portal: Providing API/Web Services documentation, trial opportunity, and collaboration platform to stakeholders.
API Portal: An individual product in Apinizer family that is not natively integrated to Apinizer and can be used independently, optionally in front of any API Gateway. It provides documentation, trial opportunity, collaboration platform and pricing plans to stakeholders.
Apinizer Integrator: Meeting and automating integration tasks without code, and optionally exposing as an API/Web Service.
Apinizer Platform: Providing API teams a single, integrated API Development Lifecycle Management platform which users with various roles can work collaboratively and operate API lifecycle steps such as requirement setting, documentation, design, development, testing, publishing, versioning, monitoring, analytics, reporting and releasing.

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
