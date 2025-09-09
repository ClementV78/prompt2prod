#!/bin/bash
set -e

echo "🏗️ Setting up local registry..."

# Create registry namespace
kubectl create namespace registry 2>/dev/null || true

# Deploy local registry
kubectl apply -f - << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: registry
  namespace: registry
spec:
  selector:
    matchLabels:
      app: registry
  template:
    metadata:
      labels:
        app: registry
    spec:
      containers:
        - name: registry
          image: registry:2
          ports:
            - containerPort: 5000
---
apiVersion: v1
kind: Service
metadata:
  name: registry
  namespace: registry
spec:
  type: NodePort
  ports:
    - port: 5000
      nodePort: 31500
  selector:
    app: registry
EOF

echo "⏳ Waiting for registry to be ready..."
kubectl rollout status deployment/registry -n registry

# Create localhost:5000 port-forward
echo "🔄 Setting up port-forward..."
nohup kubectl port-forward -n registry svc/registry 5000:5000 >/dev/null 2>&1 &

echo "✅ Local registry setup complete"
echo ""
echo "💡 You can now build and push images to localhost:5000"
