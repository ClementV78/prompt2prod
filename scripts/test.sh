#!/bin/bash
set -e

echo "🧪 Lancement des tests..."

# Test de connectivité Ollama
echo "1️⃣ Test Ollama..."
OLLAMA_POD=$(kubectl get pod -l app=ollama -o jsonpath="{.items[0].metadata.name}")
if [ ! -z "$OLLAMA_POD" ]; then
    kubectl exec $OLLAMA_POD -- curl -s http://localhost:11434/api/tags || echo "⚠️ Ollama pas encore prêt"
else
    echo "⚠️ Pod Ollama non trouvé"
fi

# Test de KGateway
echo "2️⃣ Test KGateway..."
KGATEWAY_IP=$(kubectl get svc kgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "localhost")
if [ ! -z "$KGATEWAY_IP" ]; then
    curl -s -X POST http://$KGATEWAY_IP:8080/v1/chat \
        -H "x-llm-mode: local" \
        -H "Content-Type: application/json" \
        -d '{"model":"mistral","prompt":"test"}' || echo "⚠️ KGateway pas accessible"
fi

# Tests unitaires Python (si présents)
if [ -f "requirements-test.txt" ]; then
    echo "3️⃣ Tests unitaires Python..."
    python -m pytest tests/unit/ -v || true
fi

# Tests unitaires Node.js (si présents)
if [ -f "package.json" ]; then
    echo "4️⃣ Tests unitaires Node.js..."
    npm test || true
fi

echo "✅ Tests terminés"
