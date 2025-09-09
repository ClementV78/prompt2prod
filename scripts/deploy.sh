#!/bin/bash
set -e

echo "🚀 Déploiement sur K3s..."

# Vérifier la connexion au cluster
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Impossible de se connecter au cluster K3s"
    echo "Lancez d'abord: ./scripts/setup-k3s.sh"
    exit 1
fi

# Créer un namespace pour le POC
kubectl create namespace poc-openhands

# Déployer Ollama
echo "🤖 Déploiement d'Ollama..."
kubectl apply -f k8s/base/ollama-deployment.yaml -n poc-openhands

# Déployer KGateway routes
echo "🌐 Configuration de KGateway..."
kubectl apply -f k8s/base/kgateway-routes.yaml -n poc-openhands

# Déployer l'application (si elle existe)
if [ -f "k8s/base/app-deployment.yaml" ]; then
    echo "📦 Déploiement de l'application..."
    kubectl apply -f k8s/base/app-deployment.yaml -n poc-openhands
fi

# Attendre que les pods soient prêts
echo "⏳ Attente du démarrage des pods..."
kubectl wait --for=condition=Ready pod -l app=ollama -n poc-openhands --timeout=300s || true

echo "✅ Déploiement terminé"
echo ""
kubectl get pods
echo ""
echo "💡 Pour voir les logs:"
echo "   kubectl logs -f deployment/ollama"
