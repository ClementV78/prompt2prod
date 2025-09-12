#!/bin/bash
set -e

# Setup secrets with environment variables for KGateway LLM routing
echo "Setting up AI Gateway secrets..."

# Check required environment variables
required_vars=("OPENAI_API_KEY")
optional_vars=("OPENROUTER_API_KEY" "MISTRAL_API_KEY")

for var in "${required_vars[@]}"; do
    if [[ -z "${!var}" ]]; then
        echo "Error: Required environment variable $var is not set"
        exit 1
    fi
done

# Create namespace if not exists
kubectl create namespace kgateway-system --dry-run=client -o yaml | kubectl apply -f -

# Apply OpenAI secret (required)
envsubst < k8s/base/secrets.yaml | kubectl apply -f -

# Verify secrets
echo "Verifying secrets..."
kubectl get secrets -n kgateway-system -l app=ai-gateway

echo "✅ Secrets configured successfully!"
echo ""
echo "Available LLM routes:"
echo "  - /ollama     (Local Ollama)"
echo "  - /openai     (OpenAI GPT models)"
echo "  - /openrouter (OpenRouter models - if API key provided)"
echo ""
echo "Header-based routing:"
echo "  - x-llm-mode: local  -> Ollama"
echo "  - x-llm-mode: cloud  -> OpenAI"
echo "  - x-llm-provider: openrouter -> OpenRouter"