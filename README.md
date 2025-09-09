# Prompt2Prod -##

## 🎯 Overview

Prompt2Prod is a proof-of-concept DevOps platform that transforms natural language prompts into production-ready GitHub projects. It leverages OpenHands orchestration along with local (Ollama) and cloud (OpenRouter) AI models to generate, configure, and deploy complete project structures with built-in CI/CD pipelines, infrastructure as code, and cloud-native best practices.

### Key Features

- **Automated Project Generation**: Create GitHub projects from natural language prompts
- **Multi-LLM Orchestration**: Combine local models (Ollama) and cloud models (OpenRouter) for optimal results
- **Intelligent Project Scaffolding**: Generate proper project structure, CI/CD, and documentation
- **Cloud-Native Architecture**: Kubernetes-based deployment for scalability
- **GitOps Integration**: Direct integration with GitHub for repository management
- **Smart Model Selection**: Automatically choose between local/cloud models based on task complexity

🚀 Quick Start

`````bash
# 1. Clone the repository
git clone https://github.com/ClementV78/prompt2prod.git
cd prompt2prod

# 2. Setup environment variables
export OPENROUTER_API_KEY="your-openrouter-api-key"
export GITHUB_TOKEN="your-github-token"

# 3. Setup infrastructure
./scripts/setup-k3s.sh          # Setup Kubernetes cluster
./scripts/setup-kgateway.sh     # Setup Kubernetes Gateway API
./scripts/setup-secrets.sh      # Configure API keys and tokens

# 4. Deploy components
kubectl apply -k k8s/base       # Deploy all components
./scripts/setup-ollama-models.sh # Load AI models

# 5. Access OpenHands UI
kubectl get svc -n poc-openhands kgateway # Get the UI URLroduction

## 🚀 Quick Start

````bash
# 1. Initialize the project
./init-project.sh

# 2. Setup Kubernetes cluster
./scripts/setup-k3s.sh

# 3. Setup Kubernetes Gateway API
./scripts/setup-kgateway.sh

# 4. Setup Ollama models
./scripts/setup-ollama-models.sh

# 5. Deploy services
./scripts/deploy.sh

# 6. Run tests
./scripts/test.sh

## � Prerequisites

- Docker
- kubectl
- k3s (or any Kubernetes cluster)
- Python 3.x
- Helm (for KGateway installation)

Install Python dependencies:
```bash
# For development
pip install -r requirements.txt

# For testing
pip install -r requirements-test.txt
`````

## �📁 Structure

```
poc-openhands/
├── .github/workflows/  # CI/CD with GitHub Actions
├── src/               # Source code
├── k8s/               # Kubernetes manifests
├── docker/            # Dockerfiles
├── scripts/           # Utility scripts
├── tests/            # Test suites
└── docs/             # Documentation
```

## 🛠️ Technical Stack & Architecture

### Core Technologies

- **Project Generation**:

  - **Orchestration**: OpenHands (AI workflow orchestration)
  - **Local Models**: Ollama (Llama3, Mistral, CodeLlama) for code generation
  - **Cloud Models**: OpenRouter (GPT-4, Claude) for architecture decisions

- **Infrastructure & Deployment**:

  - **Container Orchestration**: K3s (Lightweight Kubernetes)
  - **API Gateway**: KGateway (CNCF-based routing & load balancing)
  - **Container Registry**: GitHub Container Registry (GHCR)
  - **Infrastructure**: Infrastructure as Code (IaC) with Kubernetes manifests

- **CI/CD & Automation**:
  - **Pipeline**: GitHub Actions with GitOps workflow
  - **Quality**: Automated testing, linting, and security scanning
  - **Deployment**: Automated Kubernetes deployments
  - **Monitoring**: Prometheus metrics collection

### Architecture Diagram

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   Browser    │────▶│   KGateway   │────▶│  OpenHands   │
│              │     │   (Ingress)  │     │ Orchestrator │
└──────────────┘     └──────────────┘     └──────────────┘
                                                 │
                                         ┌───────┴───────┐
                                         │               │
                                   ┌──────────┐   ┌──────────┐
                                   │  Ollama  │   │OpenRouter │
                                   │ (Local)  │   │ (Cloud)  │
                                   └──────────┘   └──────────┘
                                         │               │
                                         └───────┬───────┘
                                                 │
                                         ┌──────────────┐
                                         │   GitHub     │
                                         │     API      │
                                         └──────────────┘
```

### Key Components

- **OpenHands Web UI**: Interface principale pour la génération de projets
- **KGateway**: Gestion du trafic entrant et routage des services (CNCF Ingress alternative)
- **AI Models**:
  - **Local**: Ollama (Llama3, Mistral, CodeLlama) pour la génération de code
  - **Cloud**: OpenRouter (GPT-4, Claude) pour le raisonnement complexe
- **GitHub Integration**: Création et configuration automatique des repositories
- **Prometheus Metrics**: Monitoring des performances et de l'utilisation des modèles

## 📋 Configuration & Deployment

### Environment Setup

```bash
# Required environment variables
export OPENROUTER_API_KEY="sk-..."
export KUBECONFIG="~/.kube/config"
```

### GitHub Secrets Configuration

- `KUBECONFIG`: K3s configuration (base64 encoded)
- `OPENROUTER_API_KEY`: OpenRouter API key for cloud models
- `GHCR_TOKEN`: GitHub Container Registry access token

### Security Considerations

- Secrets management using Kubernetes Secrets
- RBAC configuration for service accounts
- Network policies for pod-to-pod communication
- TLS encryption for API endpoints

## 🧪 Testing & Quality Assurance

### Automated Testing

```bash
# Unit tests with coverage
pytest tests/unit/ --cov

# Integration tests
./scripts/test.sh

# Load testing
k6 run tests/performance/load-test.js
```

### Manual Testing

```bash
# Test API endpoint
curl -X POST http://localhost:8000/generate \
  -H "Content-Type: application/json" \
  -d '{"prompt": "Hello", "model": "mistral", "mode": "local"}'
```

### CI/CD Pipeline Stages

1. Code linting and formatting
2. Unit tests and coverage analysis
3. Container build and security scan
4. Integration tests
5. Performance testing
6. Automated deployment

## 📊 Monitoring & Observability

```bash
# Voir les pods
kubectl get pods -w

# Logs Ollama
kubectl logs -f deployment/ollama

# Logs application
kubectl logs -f deployment/app
```

## 🔧 Development Workflow

### Git Flow

```bash
# Create feature branch
git checkout -b feature/new-feature

# Commit changes following conventional commits
git add .
git commit -m "feat: implement new feature"
git push -u origin feature/new-feature

# Create PR
gh pr create --title "feat: New Feature Implementation" --body "Description of changes"
```

### Local Development

```bash
# Start local k3s cluster
./scripts/setup-k3s.sh

# Deploy services locally
./scripts/deploy.sh --env=dev

# Watch for changes
kubectl get pods -w
```

### Best Practices

- Conventional Commits for clear history
- Branch protection rules
- Required PR reviews
- Automated testing on PR
- GitOps workflow with ArgoCD/Flux

## 📝 Documentation & Resources

- [Architecture](docs/architecture.md)
- [Guide de déploiement](docs/deployment.md)
- [API Reference](docs/api.md)

## 📄 License

MIT

## 👥 Contributeurs

- Votre nom ici

---

**Status**: 🚧 POC en développement
