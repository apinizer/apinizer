#!/bin/sh
### Uninstall Elasticsearch

### Uninstall MongoDB
sudo service mongod stop

sudo apt-get purge mongodb-org*

sudo rm -r /var/log/mongodb

sudo rm -r /var/lib/mongodb

### Uninstall Kubernetes

### Uninstall Docker


