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
#
# All-in-one orchestrator for a single-server PoC/Test setup on a Virtual
# Server (Linux VM). Apinizer modules are installed as standalone packages
# (embedded OpenJDK 25) — no Kubernetes/containers required.
#
# It runs the per-component installers in order. Each component can also be
# installed independently (e.g. on dedicated servers) by running the matching
# script under the components/ directory:
#
#   components/install-mongodb.sh           -> MongoDB 8.0 (single-node replica set)
#   components/install-elasticsearch.sh     -> Elasticsearch 8.17 (TLS + security)
#   components/install-apinizer-manager.sh  -> API Manager (VM standalone)
#   components/install-apinizer-worker.sh   -> Worker / API Gateway (VM standalone)
#   components/install-apinizer-cache.sh    -> Cache / Hazelcast (VM standalone)

BASE_URL="https://raw.githubusercontent.com/apinizer/apinizer/main/components"
SCRIPT_DIR="$(cd "$(dirname "$0")" 2>/dev/null && pwd)"

# Runs a component installer from the local components/ directory if present,
# otherwise downloads it from the repository (supports `curl ... | bash` usage).
run_module() {
  module="$1"
  if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/components/$module" ]; then
    echo ">>> Running local component: components/$module"
    bash "$SCRIPT_DIR/components/$module"
  else
    echo ">>> Downloading and running module: $module"
    curl -fsSL "$BASE_URL/$module" -o "/tmp/$module" && bash "/tmp/$module"
  fi
}

run_module install-mongodb.sh
run_module install-elasticsearch.sh
run_module install-apinizer-manager.sh
run_module install-apinizer-worker.sh
run_module install-apinizer-cache.sh

NODE_IP=$(ip -o route get to 8.8.8.8 | sed -n 's/.*src \([0-9.]\+\).*/\1/p')

echo 'Apinizer API Management Platform Installation Successfully'
echo
echo "============================================================"
echo "Apinizer Management Console      : http://$NODE_IP:8080"
echo "  default user: admin   password: Apinizer.1!"
echo
echo "Worker (API Gateway) Management API : http://$NODE_IP:8091"
echo "Cache REST API                      : http://$NODE_IP:8090"
echo
echo "Post-install steps:"
echo "  1) In the Manager UI, define the Worker as a Remote Gateway"
echo "     Environment (name must equal 'prod') and publish it."
echo "  2) Register the Cache server: Admin > Cache Servers > New"
echo "     (host: $NODE_IP  port: 8090)."
echo "  3) Add the Elasticsearch connection (credentials/cert printed above,"
echo "     also saved to elastic-passwords.yaml)."
echo "============================================================"
