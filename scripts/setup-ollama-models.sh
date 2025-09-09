#!/bin/bash
set -e

echo "📚 Chargement des modèles Ollama..."

# Attendre qu'Ollama soit prêt
echo "⏳ Attente du pod Ollama..."
kubectl wait --for=condition=Ready pod -l app=ollama --timeout=300s

OLLAMA_POD=$(kubectl get pod -l app=ollama -o jsonpath="{.items[0].metadata.name}")

# Modèles à charger
MODELS=("mistral" "llama3" "codellama")

for MODEL in "${MODELS[@]}"; do
    echo "📥 Téléchargement de $MODEL..."
    kubectl exec $OLLAMA_POD -- ollama pull $MODEL
    echo "✓ $MODEL chargé"
done

echo "✅ Tous les modèles sont chargés"
kubectl exec $OLLAMA_POD -- ollama list
