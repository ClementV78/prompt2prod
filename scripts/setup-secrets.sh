#!/bin/bash
set -e

echo "🔐 Setting up secrets..."

# Use environment variables or defaults for testing
OPENROUTER_API_KEY=${OPENROUTER_API_KEY:-"test-key-change-me"}
GITHUB_TOKEN=${GITHUB_TOKEN:-"test-token-change-me"}

if [ "$OPENROUTER_API_KEY" = "test-key-change-me" ]; then
    echo "⚠️  Warning: Using default OPENROUTER_API_KEY - cloud mode will not work"
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
  namespace: prompt2prod
type: Opaque
data:
  openrouter_api_key: $OPENROUTER_API_KEY_BASE64
  github_token: $GITHUB_TOKEN_BASE64
EOF

echo "✅ Secrets configured successfully"
