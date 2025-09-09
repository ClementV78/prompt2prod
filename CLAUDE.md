# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## POC Overview - Prompt-to-Production Pipeline

This **Prompt2Prod** POC demonstrates a complete DevOps automation pipeline where:

**Input**: Natural language project idea (e.g., "Create a Node.js REST API for a todo app")  
**Output**: Complete GitHub repository with production-ready code, CI/CD, tests, and deployment

**Core Use Case**: User submits a prompt → System automatically generates:
1. **GitHub Repository** with complete source code
2. **GitHub Actions Pipeline** with modern CI/CD practices  
3. **Basic Documentation** (README, API docs, deployment guides)
4. **Test Suite** with coverage and quality gates
5. **Deployment Configuration** (Docker, K8s manifests, infrastructure)

**Modern DevOps Tools Showcased**:
- **OpenHands** for AI workflow orchestration
- **KGateway (CNCF)** for cloud-native API routing  
- **Multi-LLM** architecture (local Ollama + cloud OpenRouter)
- **GitHub Actions** with advanced pipeline features

## Common Commands

### Core DevOps Operations
- **Full POC deployment**: `./init-project.sh && ./scripts/setup-k3s.sh && ./scripts/deploy.sh`
- **Test prompt-to-repo generation**: 
  ```bash
  curl -X POST http://localhost:8080/generate-project \
    -H "Content-Type: application/json" \
    -d '{"prompt": "Create a Python FastAPI todo app with PostgreSQL"}'
  ```
- **KGateway routing**: `./scripts/setup-kgateway.sh` (CNCF Gateway API)
- **Multi-LLM selection**: Headers `x-llm-mode: local` (Ollama) vs `x-llm-mode: cloud` (OpenRouter)

### Development Commands
- **Python tests**: `pytest tests/unit/` or `./scripts/test.sh` (full integration testing)
- **Local API**: `python -m uvicorn src.api.main:app --host 0.0.0.0 --port 8000`
- **Requirements**: `pip install -r requirements.txt` and `pip install -r requirements-test.txt`

### Kubernetes Operations
- **K3s cluster**: `./scripts/setup-k3s.sh` (lightweight K8s for demos)
- **Deploy stack**: `./scripts/deploy.sh` (Ollama + KGateway + App)
- **Load AI models**: `./scripts/setup-ollama-models.sh`
- **Monitor**: `kubectl get pods -w` and `kubectl logs -f deployment/ollama`
- **GitOps**: `kubectl apply -k k8s/base` (Kustomize-based deployments)

## Architecture Overview - DevOps Patterns Demonstration

This **Prompt2Prod POC** showcases modern DevOps practices through AI-driven project generation, emphasizing cloud-native patterns and automation.

### DevOps Skills Demonstrated

**1. OpenHands Orchestration (AI Workflow Management)**:
- Complex workflow orchestration for automated project generation
- Integration with multiple AI models for different tasks
- Event-driven architecture with proper error handling and retries

**2. KGateway (CNCF Gateway API)**:
- Implementation of CNCF Gateway API standard (not Ingress)
- Intelligent request routing based on headers (`x-llm-mode`)
- Load balancing between local (Ollama) and cloud (OpenRouter) services
- Demonstrates modern API gateway patterns vs traditional reverse proxies

**3. Multi-LLM Architecture**:
- **Ollama** (local): Resource-efficient local inference (Llama3, Mistral, CodeLlama)
- **OpenRouter** (cloud): High-capability models for complex reasoning
- Dynamic model selection based on task complexity and requirements
- Fallback strategies and cost optimization patterns

**4. GitHub Actions & GitOps**:
- Multi-stage CI/CD pipeline with parallel job execution
- Container build optimization with layer caching
- Automated K8s deployments with proper secret management
- GitHub Container Registry integration
- Environment-specific deployment strategies

### Infrastructure-as-Code Stack
- **K3s**: Production-grade K8s in minimal footprint
- **Kustomize**: Configuration management without templating
- **Multi-stage Dockerfiles**: Optimized container builds
- **Health checks & Probes**: Production readiness patterns
- **Resource management**: Proper CPU/memory limits and requests

### Prompt-to-Production Flow
1. **User prompt** → "Create a React app with TypeScript and testing"
2. **KGateway routing** → Route to optimal LLM (`x-llm-mode` header)
3. **OpenHands orchestration** → Multi-step project generation workflow:
   - Code generation (Ollama for implementation)
   - Architecture decisions (OpenRouter for complex planning)
   - Documentation generation
   - Test creation
4. **GitHub integration** → Automatic repository creation with:
   - Complete source code
   - GitHub Actions workflow (CI/CD)
   - Dockerfile + K8s manifests
   - README with deployment instructions
   - Basic test suite
5. **Auto-deployment** → Triggered GitHub Actions pipeline deploys to K8s

### Key Implementation Directories
- `k8s/base/`: Complete K8s stack with Gateway API resources
- `.github/workflows/deploy.yml`: Multi-stage CI/CD with parallel execution
- `scripts/`: Infrastructure automation (K3s, KGateway, Ollama setup)
- `docker/`: Multi-stage builds with optimization patterns
- `src/api/main.py`: FastAPI with dual LLM integration logic

## DevOps Interview Demo Script

**"Show me how you'd implement a complete automation pipeline"**

1. **Demo the core use case**:
   ```bash
   # Submit a project idea
   curl -X POST http://localhost:8080/generate-project \
     -d '{"prompt": "Node.js Express API with MongoDB and Jest tests"}'
   
   # Show the generated GitHub repo with:
   # - Complete source code
   # - GitHub Actions CI/CD pipeline  
   # - Dockerfile + K8s manifests
   # - README and API documentation
   # - Jest test suite with coverage
   ```

2. **Highlight modern DevOps tools**:
   - **OpenHands**: "Complex workflow orchestration beyond simple scripts"
   - **KGateway (CNCF)**: "Modern Gateway API, not legacy Ingress controllers"  
   - **Multi-LLM**: "Cost optimization with local/cloud model selection"
   - **GitHub Actions**: "Modern CI/CD with parallel jobs and optimized caching"

3. **Technical depth discussion**:
   - **Infrastructure-as-Code**: K3s automation, Kustomize configurations
   - **Container optimization**: Multi-stage builds, layer caching
   - **Production readiness**: Health checks, resource limits, monitoring
   - **Security**: Secret management, RBAC, container scanning

**Key talking points**: This isn't just "AI generates code" - it's a **complete DevOps automation platform** that demonstrates modern infrastructure patterns, CI/CD best practices, and production-ready deployment strategies.