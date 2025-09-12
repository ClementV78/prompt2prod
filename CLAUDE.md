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
- **Test API generation**: 
  ```bash
  curl -X POST http://192.168.31.106:31104/generate \
    -H "Content-Type: application/json" \
    -d '{"prompt": "Create a Python function", "mode": "local", "model": "llama3.2:1b"}'
  ```
- **List available models**: `curl http://192.168.31.106:31104/models`
- **KGateway unified routing**: All requests go through KGateway (OpenAI + Ollama)

### Development Commands
- **Python tests**: `pytest tests/unit/` or `./scripts/test.sh` (full integration testing)
- **Local API**: `python -m uvicorn src.api.main:app --host 0.0.0.0 --port 8000`
- **Requirements**: `pip install -r requirements.txt` and `pip install -r requirements-test.txt`
- **Build & Deploy**: `docker build -f docker/Dockerfile -t ghcr.io/clementv78/prompt2prod:latest . && docker push ghcr.io/clementv78/prompt2prod:latest`

### Kubernetes Operations
- **K3s cluster**: `./scripts/setup-k3s.sh` (lightweight K8s for demos)
- **Deploy stack**: `./scripts/deploy.sh` (Ollama + KGateway + App)
- **Apply configs**: `kubectl apply -f k8s/base/ollama/ -f k8s/base/openai/ -f k8s/base/app/`
- **Monitor**: `kubectl get pods -w` and `kubectl logs -f deployment/ollama`
- **Restart app**: `kubectl rollout restart deployment/app -n prompt2prod`

## Architecture Overview - DevOps Patterns Demonstration

This **Prompt2Prod POC** showcases modern DevOps practices through AI-driven project generation, emphasizing cloud-native patterns and automation.

### DevOps Skills Demonstrated

**1. OpenHands Orchestration (AI Workflow Management)**:
- Complex workflow orchestration for automated project generation
- Integration with multiple AI models for different tasks
- Event-driven architecture with proper error handling and retries

**2. KGateway (CNCF Gateway API)**:
- Implementation of CNCF Gateway API standard (not Ingress)
- Standard path-based routing: `/ollama` → Ollama, `/openai` → OpenAI
- AI Backend configuration with OpenAI-compatible API format
- Production-ready timeouts and error handling

**3. Multi-LLM Architecture**:
- **Ollama** (local): Resource-efficient local inference (llama3.2:1b, phi3:mini, mistral:7b-instruct)
- **OpenAI** (cloud): High-capability models (gpt-4o-mini, gpt-3.5-turbo)
- **Unified routing**: All LLM requests go through KGateway for consistency
- **Smart timeouts**: 40s KGateway → Backend, 180s App → KGateway

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
2. **KGateway routing** → Route to optimal LLM (path-based: `/ollama` or `/openai`)
3. **LLM Processing** → Generate code based on prompt:
   - Local models (Ollama): Fast, private, cost-effective
   - Cloud models (OpenAI): High-capability, latest features
   - Unified OpenAI-compatible API format
4. **GitHub integration** → Automatic repository creation with:
   - Complete source code
   - GitHub Actions workflow (CI/CD)
   - Dockerfile + K8s manifests
   - README with deployment instructions
   - Basic test suite
5. **Auto-deployment** → Triggered GitHub Actions pipeline deploys to K8s

### Current Architecture (Post-Refactoring)

**Unified KGateway Architecture:**
```
Client → App (FastAPI) → KGateway → {Ollama | OpenAI}
```

**API Endpoints:**
- `POST /generate` - Generate content with any available model
- `GET /models` - List all models (local + cloud) with real-time status
- `GET /health` - Health check endpoint

**Model Selection:**
- `mode: "local"` → Routes to Ollama via KGateway `/ollama`
- `mode: "cloud"` → Routes to OpenAI via KGateway `/openai`

### Key Implementation Directories
- `k8s/base/app/`: FastAPI application deployment
- `k8s/base/ollama/`: Ollama backend + HTTPRoute (AI Backend)
- `k8s/base/openai/`: OpenAI backend + HTTPRoute (AI Backend)
- `src/api/main.py`: FastAPI with unified KGateway routing
- `docker/Dockerfile`: Multi-stage Python build

## DevOps Interview Demo Script

**"Show me how you'd implement a complete LLM integration platform"**

1. **Demo the core use case**:
   ```bash
   # Test local model
   curl -X POST http://192.168.31.106:31104/generate \
     -d '{"prompt": "Create a Python function", "mode": "local", "model": "llama3.2:1b"}'
   
   # Test cloud model
   curl -X POST http://192.168.31.106:31104/generate \
     -d '{"prompt": "Explain microservices", "mode": "cloud", "model": "gpt-4o-mini"}'
     
   # List available models
   curl http://192.168.31.106:31104/models
   ```

2. **Highlight modern DevOps tools**:
   - **KGateway (CNCF)**: "Modern Gateway API with AI Backend support"  
   - **Multi-LLM**: "Unified API for local (Ollama) and cloud (OpenAI) models"
   - **Docker + K8s**: "Production-ready containerized deployment"
   - **Real-time model discovery**: "Dynamic model listing from live services"

3. **Technical depth discussion**:
   - **Infrastructure-as-Code**: K3s automation, Kustomize configurations
   - **Container optimization**: Multi-stage builds, layer caching
   - **Production readiness**: Health checks, resource limits, monitoring
   - **Security**: Secret management, RBAC, container scanning

**Key talking points**: This demonstrates a **production-ready LLM integration platform** with modern DevOps practices: Gateway API routing, containerized deployments, unified APIs, and real-time model management across local and cloud providers.