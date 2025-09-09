#!/bin/bash
set -e

echo "🐳 Installation de K3s..."

# Vérifier si K3s est déjà installé
if command -v k3s &> /dev/null; then
    echo "✓ K3s est déjà installé"
    k3s --version
else
    # Installer K3s
    curl -sfL https://get.k3s.io | sh -
    
    # Attendre que K3s soit prêt
    echo "⏳ Attente du démarrage de K3s..."
    sudo k3s kubectl wait --for=condition=Ready nodes --all --timeout=60s
    
    # Configurer kubeconfig pour l'utilisateur courant
    mkdir -p ~/.kube
    sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
    sudo chown $USER:$USER ~/.kube/config
    
    echo "✓ K3s installé avec succès"
fi

# Installer Helm si nécessaire
if ! command -v helm &> /dev/null; then
    echo "📦 Installation de Helm..."
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

echo "📊 Status du cluster:"
kubectl get nodes
kubectl get pods -A

echo ""
echo "💡 Pour obtenir le kubeconfig pour GitHub Actions:"
echo "   cat ~/.kube/config | base64 -w 0"
echo ""
