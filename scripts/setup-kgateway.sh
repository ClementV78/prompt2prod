#!/bin/bash
# scripts/setup-kgateway.sh

set -e

echo "🌐 Installation de KGateway (CNCF Gateway API Controller)"
echo "========================================================="

# Vérifier les prérequis
check_prerequisites() {
    echo "🔍 Vérification des prérequis..."
    
    if ! command -v kubectl &> /dev/null; then
        echo "❌ kubectl non trouvé. Installez K3s d'abord: ./scripts/setup-k3s.sh"
        exit 1
    fi
    
    if ! command -v helm &> /dev/null; then
        echo "📦 Installation de Helm..."
        curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    fi
    
    echo "✅ Prérequis OK"
}

# Installer Gateway API CRDs
install_gateway_api_crds() {
    echo "📋 Installation des CRDs Gateway API..."
    
    # Vérifier si déjà installés
    if kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null; then
        echo "  ✓ CRDs Gateway API déjà installés"
    else
        kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.3.0/standard-install.yaml
        echo "  ✓ CRDs Gateway API installés"
    fi
}

# Installer KGateway
install_kgateway() {
    echo "🚀 Installation de KGateway..."
    
    # Vérifier si déjà installé
    if kubectl get pods -n kgateway-system 2>/dev/null | grep -q kgateway; then
        echo "  ✓ KGateway déjà installé"
        read -p "  Voulez-vous le mettre à jour ? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return
        fi
    fi
    
    # Installer CRDs KGateway
    echo "  📦 Installation des CRDs KGateway..."
    helm upgrade -i --create-namespace \
        --namespace kgateway-system \
        --version v2.0.4 \
        kgateway-crds \
        oci://cr.kgateway.dev/kgateway-dev/charts/kgateway-crds
    
    # Installer KGateway Controller
    echo "  📦 Installation du controller KGateway..."
    helm upgrade -i \
        --namespace kgateway-system \
        --version v2.0.4 \
        kgateway \
        oci://cr.kgateway.dev/kgateway-dev/charts/kgateway
    
    # Attendre que ce soit prêt
    echo "  ⏳ Attente du démarrage de KGateway..."
    kubectl wait --for=condition=ready pod \
        -l app.kubernetes.io/name=kgateway \
        -n kgateway-system \
        --timeout=120s || true
}

# Vérifier l'installation
verify_installation() {
    echo "✅ Vérification de l'installation..."
    
    # Vérifier les pods
    echo "  Pods KGateway:"
    kubectl get pods -n kgateway-system
    
    # Vérifier GatewayClass
    echo "  GatewayClass disponibles:"
    kubectl get gatewayclass
    
    # Créer GatewayClass si nécessaire
    if ! kubectl get gatewayclass kgateway &> /dev/null; then
        echo "  📝 Création du GatewayClass kgateway..."
        cat <<EOF | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: kgateway
spec:
  controllerName: kgateway.dev/kgateway-controller
EOF
    fi
}

# Main
main() {
    check_prerequisites
    install_gateway_api_crds
    install_kgateway
    verify_installation
    
    echo ""
    echo "✅ KGateway installé avec succès!"
    echo ""
    echo "📋 Prochaines étapes:"
    echo "  1. Déployer vos services: ./scripts/deploy.sh"
    echo "  2. Vérifier les routes: kubectl get gateway,httproute -A"
    echo ""
}

main "$@"