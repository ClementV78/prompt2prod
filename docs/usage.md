# Using Prompt2Prod with OpenHands

## Project Generation Examples

### Basic Node.js Project

```bash
curl -X POST http://localhost:8080/generate \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "Create a Node.js REST API with Express, using TypeScript, including GitHub Actions for CI/CD",
    "template": "nodejs-typescript",
    "options": {
      "includeTests": true,
      "includeDocs": true
    }
  }'
```

### Python FastAPI Project

```bash
curl -X POST http://localhost:8080/generate \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "Create a Python FastAPI application with PostgreSQL, including Docker setup and k8s manifests",
    "template": "python-fastapi",
    "options": {
      "includeDB": true,
      "includeK8s": true
    }
  }'
```

### React Frontend Project

```bash
curl -X POST http://localhost:8080/generate \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "Create a React application with TypeScript, using Vite and including GitHub Actions",
    "template": "react-typescript",
    "options": {
      "includeTests": true,
      "includeDocs": true
    }
  }'
```

## Project Structure Generated

Each generated project includes:

- Complete source code
- GitHub Actions workflows
- Documentation
- Tests
- Infrastructure as Code (if requested)
- Docker configuration (if requested)
- Kubernetes manifests (if requested)

## OpenHands Configuration

OpenHands is configured to use:

- Ollama (local) for code generation
- OpenRouter (cloud) for architecture decisions
- GitHub API for repository creation and configuration
