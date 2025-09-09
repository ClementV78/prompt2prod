#!/bin/bash
set -e

NAMESPACE="poc-openhands"

echo "🚀 Deploying to K3s in namespace: $NAMESPACE"

# Check cluster connection
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Cannot connect to K3s cluster"
    echo "Run first: ./scripts/setup-k3s.sh"
    exit 1
fi

# Deploy all components
echo "🤖 Deploying components..."
kubectl apply -f k8s/base/

# Wait for pods to be ready
echo "⏳ Waiting for pods to start..."
kubectl wait --for=condition=Ready pod -l app=ollama -n $NAMESPACE --timeout=300s || true
kubectl wait --for=condition=Ready pod -l app=app -n $NAMESPACE --timeout=300s || true

# Show status
echo "✅ Deployment complete in namespace: $NAMESPACE"
echo ""
echo "📊 Status:"
kubectl get pods -n $NAMESPACE
echo ""
echo "💡 To access Ollama:"
echo "   kubectl port-forward svc/ollama 11434:11434 -n $NAMESPACE"
echo "   curl http://localhost:11434/api/tags"
echo ""
echo "💡 To access OpenHands UI:"
echo "   kubectl port-forward svc/openhands 8080:8080 -n $NAMESPACE"
echo "   Then open http://localhost:8080 in your browser"