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
