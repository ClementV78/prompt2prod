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

# 2. Setup infrastructure (one-time)
./scripts/setup-k3s.sh          # Setup cluster Kubernetes
./scripts/setup-kgateway.sh     # Setup Gateway API
./scripts/setup-ollama-models.sh # Charger les modèles IA

# 3. Déployer l'application
kubectl apply -R -f k8s/base/

# 4. Tester l'API
curl -X POST "http://192.168.31.106:31104/generate" \
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
- **IA**: Ollama local (Llama3.2:1b, phi3:mini, mistral:7b-instruct) + Cloud (OpenAI)
- **Orchestration**: Kubernetes avec K3s
- **Routage**: KGateway (CNCF Gateway API)
- **CI/CD**: GitHub Actions + GHCR
- **Containerisation**: Docker multi-stage builds

### Architecture

```
User → FastAPI → KGateway → [Local: Ollama | Cloud: OpenAI] → Generated Code
                    ↓ (unified routing)
           [llama3.2:1b, phi3:mini, mistral:7b] | [gpt-4o-mini, gpt-3.5-turbo]
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

- **[🏗️ Architecture](https://htmlpreview.github.io/?https://github.com/ClementV78/prompt2prod/blob/main/docs/html/architecture.html)** - Guide DevOps complet
- **[🔌 API Reference](https://htmlpreview.github.io/?https://github.com/ClementV78/prompt2prod/blob/main/docs/html/api-reference.html)** - Documentation des endpoints
- **[👤 Guide Utilisateur](https://htmlpreview.github.io/?https://github.com/ClementV78/prompt2prod/blob/main/docs/html/user-guide.html)** - Guide fonctionnel
- **[📖 Documentation complète](https://htmlpreview.github.io/?https://github.com/ClementV78/prompt2prod/blob/main/docs/html/index.html)** - Interface d'accueil

## 🔧 Développement

### Déploiement manuel (après GitHub Actions build)

```bash
# 1. Récupérer l'image buildée par GitHub Actions
export IMAGE_TAG="ghcr.io/clementv78/prompt2prod:$(git rev-parse HEAD)"
docker pull $IMAGE_TAG

# 2. Déployer avec la nouvelle image
envsubst < k8s/base/app/deployment.yaml | kubectl apply -f -
kubectl apply -R -f k8s/base/

# 3. Vérifier le rollout
kubectl rollout status deployment/app -n prompt2prod

# 4. Accès aux logs
kubectl logs -f deployment/app -n prompt2prod
```

### Déploiement automatique (self-hosted runner)

Pour un déploiement automatique, voir la [documentation du self-hosted runner](docs/SELF_HOSTED_RUNNER.md).

### Build local (développement)

```bash
# Build et test local
docker build -t prompt2prod:dev -f docker/Dockerfile .
docker run --rm -p 8000:8000 prompt2prod:dev
```

## ⚡ Exemple d'utilisation

```bash
# Génération avec modèle local (recommandé: phi3:mini)
curl -X POST "http://localhost:8080/generate" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "Create a Python FastAPI hello world",
    "model": "phi3:mini", 
    "mode": "local"
  }'

# Génération avec modèle cloud (OpenAI)
curl -X POST "http://localhost:8080/generate" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "Create a complex microservice architecture",
    "model": "gpt-4o-mini", 
    "mode": "cloud"
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