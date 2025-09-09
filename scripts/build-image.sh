#!/bin/bash
set -e

echo "🏗️ Building application image..."

# Configuration
IMAGE_NAME="prompt2prod"
IMAGE_TAG="dev"

# Build the image
echo "📦 Building Docker image..."
docker build -t ${IMAGE_NAME}:${IMAGE_TAG} -f docker/Dockerfile .

# Tag for local k3s
echo "🏷️ Tagging image for k3s..."
docker tag ${IMAGE_NAME}:${IMAGE_TAG} localhost:5000/${IMAGE_NAME}:${IMAGE_TAG}

# Push to local registry
echo "⬆️ Pushing to local registry..."
docker push localhost:5000/${IMAGE_NAME}:${IMAGE_TAG}

# Update deployment
echo "🔄 Updating deployment..."
kubectl set image deployment/app app=localhost:5000/${IMAGE_NAME}:${IMAGE_TAG} -n poc-openhands

echo "✅ Image built and deployed"
echo ""
echo "💡 To check deployment status:"
echo "   kubectl rollout status deployment/app -n poc-openhands"
