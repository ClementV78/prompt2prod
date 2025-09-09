#!/bin/bash
set -e

echo "🔐 Setting up secrets..."

# Check if required environment variables are set
if [ -z "$OPENROUTER_API_KEY" ]; then
    echo "❌ OPENROUTER_API_KEY is not set"
    exit 1
fi

if [ -z "$GITHUB_TOKEN" ]; then
    echo "❌ GITHUB_TOKEN is not set"
    exit 1
fi

# Create base64 encoded secrets
OPENROUTER_API_KEY_BASE64=$(echo -n "$OPENROUTER_API_KEY" | base64)
GITHUB_TOKEN_BASE64=$(echo -n "$GITHUB_TOKEN" | base64)

# Apply secrets to k8s
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: llm-secrets
  namespace: poc-openhands
type: Opaque
data:
  openrouter_api_key: $OPENROUTER_API_KEY_BASE64
  github_token: $GITHUB_TOKEN_BASE64
EOF

echo "✅ Secrets configured successfully"
