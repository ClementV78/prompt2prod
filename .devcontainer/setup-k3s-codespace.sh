#!/bin/bash
# Setup K3s in GitHub Codespace

set -e

echo "🚀 Setting up K3s in GitHub Codespace..."

# Install K3s
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable=traefik --write-kubeconfig-mode=644" sh -

# Wait for K3s to be ready
echo "⏳ Waiting for K3s to be ready..."
sudo k3s kubectl wait --for=condition=Ready nodes --all --timeout=60s

# Setup kubectl config for current user
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config

# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install Gateway API CRDs
echo "📋 Installing Gateway API CRDs..."
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.3.0/standard-install.yaml

# Install KGateway with AI support
echo "🌐 Installing KGateway with AI support..."
helm upgrade -i --create-namespace --namespace kgateway-system \
  --version v2.0.4 \
  --set gateway.aiExtension.enabled=true \
  kgateway-crds \
  oci://cr.kgateway.dev/kgateway-dev/charts/kgateway-crds

helm upgrade -i --namespace kgateway-system \
  --version v2.0.4 \
  --set gateway.aiExtension.enabled=true \
  kgateway \
  oci://cr.kgateway.dev/kgateway-dev/charts/kgateway

echo "✅ K3s setup completed in Codespace!"
echo ""
echo "📋 Next steps:"
echo "1. kubectl get pods -A"
echo "2. kubectl apply -R -f k8s/base/"
echo "3. Open ports 8000 (API) and 31104 (KGateway) in Codespace"