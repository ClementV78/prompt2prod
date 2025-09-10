# Prompt2Prod

## 🎯 Vue d'ensemble

**Prompt2Prod** est un système DevOps qui génère du code à partir de prompts en langage naturel en utilisant une architecture cloud-native moderne.

### Fonctionnalités

- **Génération de code** via modèles Ollama locaux
- **API moderne** FastAPI avec documentation Swagger
- **Architecture Kubernetes** cloud-native
- **Pipeline CI/CD** avec GitHub Actions
- **Routage intelligent** via KGateway (CNCF Gateway API)

## 🚀 Démarrage rapide

```bash
# 1. Cloner le repository
git clone https://github.com/ClementV78/prompt2prod.git
cd prompt2prod

# 2. Setup infrastructure
./scripts/setup-k3s.sh          # Setup cluster Kubernetes
./scripts/setup-kgateway.sh     # Setup Gateway API
./scripts/deploy.sh             # Déployer les services

# 3. Charger les modèles IA
./scripts/setup-ollama-models.sh

# 4. Tester l'API
curl -X POST "http://localhost:8080/generate" \
  -H "Content-Type: application/json" \
  -d '{"prompt": "Create a Python hello world script", "model": "llama3.2:1b", "mode": "local"}'
```

## 📋 Prérequis

- Docker
- kubectl 
- k3s (ou cluster Kubernetes)
- Python 3.11+

```bash
# Dependencies Python
pip install -r requirements.txt
pip install -r requirements-test.txt  # Pour les tests
```

## 📁 Structure

```
prompt2prod/
├── .github/workflows/     # CI/CD GitHub Actions
├── src/api/              # API FastAPI
├── k8s/base/             # Manifests Kubernetes  
├── docker/               # Dockerfile
├── scripts/              # Scripts d'automatisation
├── tests/                # Tests unitaires
└── docs/                 # Documentation complète
```

## 🛠️ Architecture technique

### Stack technologique

- **API**: FastAPI avec validation Pydantic
- **IA**: Ollama local (Llama3.2, Mistral, CodeLlama)
- **Orchestration**: Kubernetes avec K3s
- **Routage**: KGateway (CNCF Gateway API)
- **CI/CD**: GitHub Actions + GHCR
- **Containerisation**: Docker multi-stage builds

### Architecture

```
User → FastAPI → Ollama → Generated Code
  ↓
GitHub Actions → GHCR → Kubernetes
```

### Composants déployés

- **FastAPI App**: API de génération de code
- **Ollama**: Service IA local 
- **KGateway**: Routage et load balancing
- **Monitoring**: Health checks et observabilité

## 🧪 Tests

```bash
# Tests unitaires
pytest tests/unit/

# Tests d'intégration
./scripts/test.sh

# Test API direct
curl http://localhost:8080/health
```

## 📊 Monitoring

```bash
# Status des pods
kubectl get pods -A

# Logs de l'application
kubectl logs -f deployment/app

# Logs Ollama
kubectl logs -f deployment/ollama

# Models disponibles
kubectl exec deployment/ollama -- ollama list
```

## 📝 Documentation

- **[🏗️ Architecture](docs/html/architecture.html)** - Guide DevOps complet
- **[🔌 API Reference](docs/html/api-reference.html)** - Documentation des endpoints
- **[👤 Guide Utilisateur](docs/html/user-guide.html)** - Guide fonctionnel
- **[📖 Documentation complète](docs/html/index.html)** - Interface d'accueil

## 🔧 Développement

```bash
# Déploiement local
kubectl apply -f k8s/base/

# Rebuild et redéploiement
docker build -t ghcr.io/clementv78/prompt2prod:latest -f docker/Dockerfile .
kubectl rollout restart deployment/app

# Accès aux logs
kubectl logs -f deployment/app
```

## ⚡ Exemple d'utilisation

```bash
# Génération simple
curl -X POST "http://localhost:8080/generate" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "Create a Python FastAPI hello world",
    "model": "llama3.2:1b", 
    "mode": "local"
  }'

# Interface Swagger
open http://localhost:8080/docs
```

## 📄 Licence

MIT

## 🚀 Status

✅ **Production Ready** - Architecture DevOps moderne avec patterns cloud-native

---

**Note**: Ce projet démontre une architecture DevOps complète intégrant l'IA locale sans dépendances externes payantes.