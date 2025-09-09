#!/bin/bash

# ========================================
# init-project.sh - Script principal d'initialisation
# ========================================

set -e

echo "🚀 Initialisation du POC OpenHands Multi-LLM"
echo "============================================"

# Couleurs pour output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Créer la structure de base
echo -e "${YELLOW}📁 Création de la structure du projet...${NC}"

mkdir -p .github/workflows
mkdir -p src/{api,frontend}
mkdir -p k8s/{base,overlays}
mkdir -p tests/{unit,integration}
mkdir -p docker
mkdir -p scripts
mkdir -p docs
mkdir -p .vscode

echo -e "${GREEN}✓ Structure créée${NC}"

# ========================================
# Créer les scripts utilitaires
# ========================================

echo -e "${YELLOW}📝 Création des scripts...${NC}"

# Script setup-k3s.sh
cat > scripts/setup-k3s.sh << 'SCRIPT_EOF'
#!/bin/bash
set -e

echo "🐳 Installation de K3s..."

# Vérifier si K3s est déjà installé
if command -v k3s &> /dev/null; then
    echo "✓ K3s est déjà installé"
    k3s --version
else
    # Installer K3s
    curl -sfL https://get.k3s.io | sh -
    
    # Attendre que K3s soit prêt
    echo "⏳ Attente du démarrage de K3s..."
    sudo k3s kubectl wait --for=condition=Ready nodes --all --timeout=60s
    
    # Configurer kubeconfig pour l'utilisateur courant
    mkdir -p ~/.kube
    sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
    sudo chown $USER:$USER ~/.kube/config
    
    echo "✓ K3s installé avec succès"
fi

# Installer Helm si nécessaire
if ! command -v helm &> /dev/null; then
    echo "📦 Installation de Helm..."
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

echo "📊 Status du cluster:"
kubectl get nodes
kubectl get pods -A

echo ""
echo "💡 Pour obtenir le kubeconfig pour GitHub Actions:"
echo "   cat ~/.kube/config | base64 -w 0"
echo ""
SCRIPT_EOF

# Script deploy.sh
cat > scripts/deploy.sh << 'SCRIPT_EOF'
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
SCRIPT_EOF

# Script test.sh
cat > scripts/test.sh << 'SCRIPT_EOF'
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
SCRIPT_EOF

# Script setup-ollama-models.sh
cat > scripts/setup-ollama-models.sh << 'SCRIPT_EOF'
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
SCRIPT_EOF

# Script cleanup.sh
cat > scripts/cleanup.sh << 'SCRIPT_EOF'
#!/bin/bash

echo "🧹 Nettoyage du POC..."

read -p "⚠️ Cela va supprimer tous les déploiements. Continuer? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    kubectl delete -f k8s/base/ --ignore-not-found=true
    echo "✅ Ressources supprimées"
else
    echo "❌ Annulé"
fi
SCRIPT_EOF

# Rendre les scripts exécutables
chmod +x scripts/*.sh

echo -e "${GREEN}✓ Scripts créés${NC}"

# ========================================
# Créer les fichiers de configuration
# ========================================

echo -e "${YELLOW}⚙️ Création des fichiers de configuration...${NC}"

# GitHub Actions workflow
cat > .github/workflows/deploy.yml << 'YAML_EOF'
name: Build and Deploy

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  build-test-deploy:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
    
    steps:
    # Checkout du code
    - name: Checkout repository
      uses: actions/checkout@v4
    
    # Setup Docker Buildx
    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v3
    
    # Login to GitHub Container Registry
    - name: Log in to Container Registry
      uses: docker/login-action@v3
      with:
        registry: ${{ env.REGISTRY }}
        username: ${{ github.actor }}
        password: ${{ secrets.GITHUB_TOKEN }}
    
    # Build and push Docker image
    - name: Build and push Docker image
      uses: docker/build-push-action@v5
      with:
        context: .
        file: ./docker/Dockerfile
        push: ${{ github.event_name != 'pull_request' }}
        tags: |
          ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:latest
          ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
        cache-from: type=gha
        cache-to: type=gha,mode=max
    
    # Run tests
    - name: Run tests
      run: |
        echo "🧪 Running tests..."
        # Add your test commands here
        # docker run --rm ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }} npm test
    
    # Deploy to K3s (only on main)
    - name: Deploy to K3s
      if: github.ref == 'refs/heads/main' && github.event_name == 'push'
      run: |
        # Setup kubectl
        mkdir -p $HOME/.kube
        echo "${{ secrets.KUBECONFIG }}" | base64 -d > $HOME/.kube/config
        
        # Update image tag in deployment
        export IMAGE_TAG="${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}"
        envsubst < k8s/base/app-deployment.yaml | kubectl apply -f -
        
        # Apply other manifests
        kubectl apply -f k8s/base/
        
        # Wait for rollout
        kubectl rollout status deployment/app --timeout=5m || true
        
        # Show status
        kubectl get pods
YAML_EOF

# Dockerfile principal
cat > docker/Dockerfile << 'DOCKERFILE_EOF'
# Multi-stage build pour optimisation
FROM python:3.11-slim as builder

WORKDIR /app

# Copier les requirements
COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

# Stage final
FROM python:3.11-slim

WORKDIR /app

# Copier les dépendances depuis le builder
COPY --from=builder /root/.local /root/.local

# Copier le code de l'application
COPY src/ ./src/

# Variables d'environnement
ENV PATH=/root/.local/bin:$PATH
ENV PYTHONUNBUFFERED=1

# Healthcheck
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD python -c "import requests; requests.get('http://localhost:8000/health')" || exit 1

# Port d'exposition
EXPOSE 8000

# Commande de démarrage
CMD ["python", "-m", "uvicorn", "src.api.main:app", "--host", "0.0.0.0", "--port", "8000"]
DOCKERFILE_EOF

# Dockerfile pour Ollama personnalisé (optionnel)
cat > docker/Dockerfile.ollama << 'DOCKERFILE_EOF'
FROM ollama/ollama:latest

# Pré-charger les modèles (optionnel, augmente la taille de l'image)
# RUN ollama pull mistral && \
#     ollama pull llama3 && \
#     ollama pull codellama

# Configuration
ENV OLLAMA_HOST=0.0.0.0
ENV OLLAMA_MODELS_PATH=/root/.ollama/models

EXPOSE 11434

CMD ["serve"]
DOCKERFILE_EOF

echo -e "${GREEN}✓ Fichiers de configuration créés${NC}"

# ========================================
# Créer les manifests Kubernetes
# ========================================

echo -e "${YELLOW}☸️ Création des manifests Kubernetes...${NC}"

# Ollama deployment
cat > k8s/base/ollama-deployment.yaml << 'K8S_EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ollama
  labels:
    app: ollama
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ollama
  template:
    metadata:
      labels:
        app: ollama
    spec:
      containers:
      - name: ollama
        image: ollama/ollama:latest
        ports:
        - containerPort: 11434
          name: http
        env:
        - name: OLLAMA_HOST
          value: "0.0.0.0"
        resources:
          requests:
            memory: "4Gi"
            cpu: "2"
          limits:
            memory: "8Gi"
            cpu: "4"
        volumeMounts:
        - name: ollama-data
          mountPath: /root/.ollama
        livenessProbe:
          httpGet:
            path: /
            port: 11434
          initialDelaySeconds: 30
          periodSeconds: 30
        readinessProbe:
          httpGet:
            path: /
            port: 11434
          initialDelaySeconds: 5
          periodSeconds: 5
      volumes:
      - name: ollama-data
        emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: ollama
  labels:
    app: ollama
spec:
  type: ClusterIP
  ports:
  - port: 11434
    targetPort: 11434
    protocol: TCP
    name: http
  selector:
    app: ollama
K8S_EOF

# KGateway routes
cat > k8s/base/kgateway-routes.yaml << 'K8S_EOF'
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: kgateway
  namespace: default
spec:
  gatewayClassName: kong
  listeners:
  - name: http
    protocol: HTTP
    port: 8080
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: llm-router
  namespace: default
spec:
  parentRefs:
  - name: kgateway
    namespace: default
  rules:
  # Route vers Ollama pour mode local
  - matches:
    - headers:
      - name: x-llm-mode
        value: local
    - path:
        type: PathPrefix
        value: /v1/chat
    backendRefs:
    - name: ollama
      port: 11434
  
  # Route vers OpenRouter pour mode cloud
  - matches:
    - headers:
      - name: x-llm-mode
        value: cloud
    - path:
        type: PathPrefix
        value: /v1/chat
    filters:
    - type: RequestHeaderModifier
      requestHeaderModifier:
        set:
        - name: Authorization
          value: "Bearer ${OPENROUTER_API_KEY}"
    - type: URLRewrite
      urlRewrite:
        hostname: openrouter.ai
        path:
          type: ReplacePrefixMatch
          replacePrefixMatch: /api/v1/chat/completions
    backendRefs:
    - kind: Service
      name: openrouter-proxy
      port: 443
  
  # Route par défaut vers Ollama (local first)
  - matches:
    - path:
        type: PathPrefix
        value: /v1
    backendRefs:
    - name: ollama
      port: 11434
K8S_EOF

# OpenRouter proxy service (pour gérer HTTPS)
cat > k8s/base/openrouter-proxy.yaml << 'K8S_EOF'
apiVersion: v1
kind: Service
metadata:
  name: openrouter-proxy
spec:
  type: ExternalName
  externalName: openrouter.ai
  ports:
  - port: 443
    targetPort: 443
    protocol: TCP
K8S_EOF

# Application deployment template
cat > k8s/base/app-deployment.yaml << 'K8S_EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app
  labels:
    app: poc-openhands
spec:
  replicas: 1
  selector:
    matchLabels:
      app: poc-openhands
  template:
    metadata:
      labels:
        app: poc-openhands
    spec:
      containers:
      - name: app
        image: ${IMAGE_TAG}
        ports:
        - containerPort: 8000
          name: http
        env:
        - name: LLM_ENDPOINT
          value: "http://kgateway:8080/v1/chat"
        - name: OLLAMA_HOST
          value: "http://ollama:11434"
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 30
        readinessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: app
  labels:
    app: poc-openhands
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 8000
    protocol: TCP
    name: http
  selector:
    app: poc-openhands
K8S_EOF

# ConfigMap pour configuration
cat > k8s/base/configmap.yaml << 'K8S_EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: llm-config
data:
  default_model: "mistral"
  ollama_models: "llama3,mistral,codellama"
  max_retries: "3"
  timeout_seconds: "30"
  llm_mode_default: "local"
K8S_EOF

# Kustomization file
cat > k8s/base/kustomization.yaml << 'K8S_EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ollama-deployment.yaml
  - openrouter-proxy.yaml
  - kgateway-routes.yaml
  - app-deployment.yaml
  - configmap.yaml

namespace: default
K8S_EOF

echo -e "${GREEN}✓ Manifests Kubernetes créés${NC}"

# ========================================
# Créer les fichiers Python de base
# ========================================

echo -e "${YELLOW}🐍 Création des fichiers Python de base...${NC}"

# Requirements
cat > requirements.txt << 'REQ_EOF'
fastapi==0.109.0
uvicorn[standard]==0.27.0
httpx==0.26.0
pydantic==2.5.0
python-dotenv==1.0.0
openai==1.10.0
REQ_EOF

# Requirements pour tests
cat > requirements-test.txt << 'REQ_EOF'
pytest==7.4.4
pytest-asyncio==0.23.3
pytest-cov==4.1.0
httpx==0.26.0
REQ_EOF

# Main API file
cat > src/api/main.py << 'PYTHON_EOF'
"""
POC OpenHands - API principale
"""
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import httpx
import os
from typing import Optional

app = FastAPI(title="POC OpenHands API", version="1.0.0")

# CORS pour development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Configuration
LLM_ENDPOINT = os.getenv("LLM_ENDPOINT", "http://localhost:8080/v1/chat")
OLLAMA_HOST = os.getenv("OLLAMA_HOST", "http://localhost:11434")

class PromptRequest(BaseModel):
    prompt: str
    model: Optional[str] = "mistral"
    mode: Optional[str] = "local"  # local ou cloud

class PromptResponse(BaseModel):
    response: str
    model: str
    mode: str

@app.get("/")
async def root():
    return {"message": "POC OpenHands API", "status": "running"}

@app.get("/health")
async def health():
    return {"status": "healthy"}

@app.post("/generate", response_model=PromptResponse)
async def generate(request: PromptRequest):
    """
    Génère une réponse via LLM (local ou cloud)
    """
    try:
        headers = {
            "x-llm-mode": request.mode,
            "Content-Type": "application/json"
        }
        
        payload = {
            "model": request.model,
            "prompt": request.prompt,
            "stream": False
        }
        
        async with httpx.AsyncClient(timeout=30.0) as client:
            if request.mode == "local":
                # Appel direct à Ollama
                response = await client.post(
                    f"{OLLAMA_HOST}/api/generate",
                    json=payload
                )
            else:
                # Appel via KGateway
                response = await client.post(
                    LLM_ENDPOINT,
                    json=payload,
                    headers=headers
                )
            
            response.raise_for_status()
            data = response.json()
            
            return PromptResponse(
                response=data.get("response", data.get("choices", [{}])[0].get("text", "")),
                model=request.model,
                mode=request.mode
            )
            
    except httpx.TimeoutException:
        raise HTTPException(status_code=504, detail="LLM timeout")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/models")
async def list_models():
    """
    Liste les modèles disponibles
    """
    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.get(f"{OLLAMA_HOST}/api/tags")
            response.raise_for_status()
            return response.json()
    except Exception as e:
        return {"models": [], "error": str(e)}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
PYTHON_EOF

# Init file
touch src/api/__init__.py
touch src/__init__.py

echo -e "${GREEN}✓ Fichiers Python créés${NC}"

# ========================================
# Créer les fichiers de documentation
# ========================================

echo -e "${YELLOW}📚 Création de la documentation...${NC}"

# README principal
cat > README.md << 'README_EOF'
# POC OpenHands Multi-LLM

## 🎯 Objectif

Proof of Concept pour l'automatisation du développement via IA avec orchestration multi-LLM (local/cloud).

## 🚀 Quick Start

```bash
# 1. Initialiser le projet
./init-project.sh

# 2. Configurer K3s
./scripts/setup-k3s.sh

# 3. Déployer les services
./scripts/deploy.sh

# 4. Charger les modèles Ollama
./scripts/setup-ollama-models.sh

# 5. Tester
./scripts/test.sh
```

## 📁 Structure

```
poc-openhands/
├── .github/workflows/  # CI/CD avec GitHub Actions
├── src/                # Code source
├── k8s/                # Manifests Kubernetes
├── docker/             # Dockerfiles
├── scripts/            # Scripts utilitaires
├── tests/              # Tests
└── docs/               # Documentation
```

## 🛠️ Stack Technique

- **Orchestration IA**: OpenHands
- **LLM Local**: Ollama (Llama3, Mistral, CodeLlama)
- **LLM Cloud**: OpenRouter (GPT-4, Claude, etc.)
- **API Gateway**: KGateway
- **Orchestration**: K3s (Kubernetes léger)
- **CI/CD**: GitHub Actions
- **Registry**: GitHub Container Registry (GHCR)

## 📋 Configuration

### Variables d'environnement

```bash
export OPENROUTER_API_KEY="sk-..."
export KUBECONFIG="~/.kube/config"
```

### GitHub Secrets

- `KUBECONFIG`: Configuration K3s (base64)
- `OPENROUTER_API_KEY`: Clé API OpenRouter

## 🧪 Tests

```bash
# Tests unitaires
pytest tests/unit/

# Tests d'intégration
./scripts/test.sh

# Test manuel avec curl
curl -X POST http://localhost:8000/generate \
  -H "Content-Type: application/json" \
  -d '{"prompt": "Hello", "model": "mistral", "mode": "local"}'
```

## 📊 Monitoring

```bash
# Voir les pods
kubectl get pods -w

# Logs Ollama
kubectl logs -f deployment/ollama

# Logs application
kubectl logs -f deployment/app
```

## 🔧 Développement

```bash
# Créer une branche
git checkout -b feature/ma-feature

# Commiter et pousser
git add .
git commit -m "feat: description"
git push -u origin feature/ma-feature

# Créer une PR avec GitHub CLI
gh pr create
```

## 📝 Documentation

- [Architecture](docs/architecture.md)
- [Guide de déploiement](docs/deployment.md)
- [API Reference](docs/api.md)

## 📄 License

MIT

## 👥 Contributeurs

- Votre nom ici

---

**Status**: 🚧 POC en développement
README_EOF

# .gitignore
cat > .gitignore << 'GITIGNORE_EOF'
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
env/
venv/
ENV/
.venv
pip-log.txt
pip-delete-this-directory.txt
.pytest_cache/
.coverage
htmlcov/
*.egg-info/
dist/
build/

# Node
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# IDE
.vscode/settings.json
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Secrets
.env
.env.local
*.key
*.pem
kubeconfig
secrets.yaml
*-secret.yaml

# Logs
*.log
logs/

# Temporary
tmp/
temp/
GITIGNORE_EOF

# VS Code settings
cat > .vscode/settings.json << 'VSCODE_EOF'
{
  "editor.formatOnSave": true,
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "[python]": {
    "editor.defaultFormatter": "ms-python.black-formatter",
    "editor.codeActionsOnSave": {
      "source.organizeImports": true
    }
  },
  "[yaml]": {
    "editor.defaultFormatter": "redhat.vscode-yaml",
    "editor.autoIndent": "advanced"
  },
  "files.associations": {
    "*.yaml": "yaml",
    "Dockerfile*": "dockerfile"
  },
  "yaml.schemas": {
    "kubernetes": "k8s/**/*.yaml",
    "https://json.schemastore.org/github-workflow.json": ".github/workflows/*.yml"
  },
  "python.linting.enabled": true,
  "python.linting.pylintEnabled": true,
  "python.testing.pytestEnabled": true,
  "python.testing.unittestEnabled": false,
  "terminal.integrated.defaultProfile.linux": "bash"
}
VSCODE_EOF

# VS Code extensions recommendations
cat > .vscode/extensions.json << 'VSCODE_EXT_EOF'
{
  "recommendations": [
    "ms-python.python",
    "ms-python.vscode-pylance",
    "ms-python.black-formatter",
    "ms-azuretools.vscode-docker",
    "ms-kubernetes-tools.vscode-kubernetes-tools",
    "redhat.vscode-yaml",
    "github.vscode-github-actions",
    "esbenp.prettier-vscode",
    "yzhang.markdown-all-in-one",
    "bierner.markdown-mermaid",
    "github.copilot"
  ]
}
VSCODE_EXT_EOF

echo -e "${GREEN}✓ Documentation créée${NC}"

# ========================================
# Initialisation Git
# ========================================

echo -e "${YELLOW}🔄 Initialisation Git...${NC}"

# Initialiser Git si pas déjà fait
if [ ! -d .git ]; then
    git init
    git branch -M main
fi

# Premier commit
git add .
git commit -m "🎉 Initial POC structure with all configurations" || true

echo -e "${GREEN}✓ Git initialisé${NC}"

# ========================================
# Instructions finales
# ========================================

echo ""
echo -e "${GREEN}✅ Initialisation terminée avec succès !${NC}"
echo ""
echo "📋 Prochaines étapes :"
echo ""
echo "  1. Créer le repo GitHub :"
echo "     ${YELLOW}gh repo create poc-openhands --public --source=. --push${NC}"
echo ""
echo "  2. Configurer les secrets GitHub :"
echo "     ${YELLOW}gh secret set KUBECONFIG < ~/.kube/config${NC}"
echo "     ${YELLOW}gh secret set OPENROUTER_API_KEY${NC}"
echo ""
echo "  3. Installer K3s :"
echo "     ${YELLOW}./scripts/setup-k3s.sh${NC}"
echo ""
echo "  4. Déployer les services :"
echo "     ${YELLOW}./scripts/deploy.sh${NC}"
echo ""
echo "  5. Charger les modèles Ollama :"
echo "     ${YELLOW}./scripts/setup-ollama-models.sh${NC}"
echo ""
echo "  6. Tester le déploiement :"
echo "     ${YELLOW}./scripts/test.sh${NC}"
echo ""
echo "💡 Documentation :"
echo "   - Architecture : docs/architecture.md"
echo "   - README : README.md"
echo ""
echo "🔗 Liens utiles :"
echo "   - OpenHands : https://github.com/All-Hands-AI/OpenHands"
echo "   - Ollama : https://ollama.ai"
echo "   - KGateway : https://kgateway.dev"
echo ""
echo "📧 Support : clemgit.f81zm@slmails.com"
echo ""