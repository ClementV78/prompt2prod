# API Reference - Prompt2Prod
## Documentation technique des endpoints

**Version API:** 1.0  
**Base URL:** `http://localhost:8080`  
**Content-Type:** `application/json`

---

## Table des Matières

1. [Vue d'ensemble](#vue-densemble)
2. [Authentification](#authentification)
3. [Endpoints](#endpoints)
4. [Modèles de données](#modèles-de-données)
5. [Codes d'erreur](#codes-derreur)
6. [Exemples d'utilisation](#exemples-dutilisation)
7. [SDK et clients](#sdk-et-clients)

---

## Vue d'ensemble

L'API Prompt2Prod expose des endpoints RESTful pour la génération de projets via intelligence artificielle. Elle supporte deux modes de traitement :

- **Mode Local** (`local`) : Utilise Ollama avec modèles locaux (Llama, Mistral)
- **Mode Cloud** (`cloud`) : Routage via KGateway (architecture de démonstration)

### Caractéristiques techniques

- **Framework**: FastAPI avec validation automatique
- **Format**: JSON pour toutes les requêtes/réponses
- **Documentation**: Swagger UI disponible sur `/docs`
- **Validation**: Pydantic pour la sérialisation des données
- **Performances**: Architecture async pour haute concurrence

---

## Authentification

**Aucune authentification n'est requise** pour ce POC. L'API est ouverte et accessible directement.

---

## Endpoints

### 1. Health Check

Vérification de l'état de l'API et des services dépendants.

```http
GET /health
```

**Response 200:**
```json
{
  "status": "healthy",
  "timestamp": "2025-09-10T09:00:00Z",
  "services": {
    "ollama": "connected",
    "kgateway": "available"
  }
}
```

---

### 2. Root Endpoint

Information générale sur l'API.

```http
GET /
```

**Response 200:**
```json
{
  "message": "POC OpenHands API",
  "status": "running",
  "version": "1.0.0",
  "docs": "/docs"
}
```

---

### 3. Generate Project

**Endpoint principal** pour la génération de projets via LLM.

```http
POST /generate
```

#### Paramètres de requête

| Paramètre | Type | Requis | Défaut | Description |
|-----------|------|---------|--------|-------------|
| `prompt` | string | ✅ | - | Description du projet à générer |
| `model` | string | ❌ | "llama3.2:1b" | Modèle LLM à utiliser |
| `mode` | string | ❌ | "local" | Mode de traitement (`local` ou `cloud`) |

#### Modèles disponibles

**Mode Local (Ollama):**
- `llama3.2:1b` - Modèle léger, rapide (par défaut)
- `mistral:7b` - Équilibre performance/qualité
- `codellama:13b` - Spécialisé développement
- *Autres modèles Ollama selon installation*

**Mode Cloud :**
- ⚠️ Non implémenté dans ce POC
- Architecture prête pour intégration future
- Routage via KGateway fonctionnel

#### Exemple de requête

```bash
curl -X POST "http://localhost:8080/generate" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "Create a Python FastAPI todo application with PostgreSQL database",
    "model": "llama3.2:1b",
    "mode": "local"
  }'
```

#### Response 200 - Succès

```json
{
  "response": "# Todo API with FastAPI and PostgreSQL\n\n## Structure du projet\n\n```\ntodo-api/\n├── app/\n│   ├── __init__.py\n│   ├── main.py\n│   ├── database.py\n│   ├── models.py\n│   ├── schemas.py\n│   └── crud.py\n├── requirements.txt\n└── README.md\n```\n\n## Installation\n\n```bash\npip install fastapi uvicorn psycopg2-binary sqlalchemy\n```\n\n## Code principal (main.py)\n\n```python\nfrom fastapi import FastAPI, Depends, HTTPException\nfrom sqlalchemy.orm import Session\nfrom . import crud, models, schemas, database\n\nmodels.Base.metadata.create_all(bind=database.engine)\n\napp = FastAPI(title=\"Todo API\", version=\"1.0.0\")\n\n# Dependency\ndef get_db():\n    db = database.SessionLocal()\n    try:\n        yield db\n    finally:\n        db.close()\n\n@app.post(\"/todos/\", response_model=schemas.Todo)\ndef create_todo(todo: schemas.TodoCreate, db: Session = Depends(get_db)):\n    return crud.create_todo(db=db, todo=todo)\n\n@app.get(\"/todos/\", response_model=list[schemas.Todo])\ndef read_todos(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):\n    todos = crud.get_todos(db, skip=skip, limit=limit)\n    return todos\n```\n\n## Modèles de données (models.py)\n\n```python\nfrom sqlalchemy import Column, Integer, String, Boolean\nfrom sqlalchemy.ext.declarative import declarative_base\n\nBase = declarative_base()\n\nclass Todo(Base):\n    __tablename__ = \"todos\"\n    \n    id = Column(Integer, primary_key=True, index=True)\n    title = Column(String, index=True)\n    description = Column(String)\n    completed = Column(Boolean, default=False)\n```\n\n## Configuration Docker\n\n```dockerfile\nFROM python:3.11-slim\n\nWORKDIR /app\nCOPY requirements.txt .\nRUN pip install -r requirements.txt\n\nCOPY . .\nEXPOSE 8000\n\nCMD [\"uvicorn\", \"app.main:app\", \"--host\", \"0.0.0.0\", \"--port\", \"8000\"]\n```",
  "model": "llama3.2:1b",
  "mode": "local",
  "generation_time": 2.34,
  "token_count": 456
}
```

#### Response 400 - Erreur de validation

```json
{
  "detail": [
    {
      "loc": ["body", "prompt"],
      "msg": "field required",
      "type": "value_error.missing"
    }
  ]
}
```

#### Response 500 - Erreur LLM

```json
{
  "detail": "Client error '404 Not Found' for url 'http://ollama:11434/api/generate'\nFor more information check: https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/404"
}
```

#### Response 504 - Timeout

```json
{
  "detail": "LLM timeout"
}
```

---

### 4. List Models

Récupération de la liste des modèles disponibles.

```http
GET /models
```

#### Response 200 - Succès

```json
{
  "models": [
    {
      "name": "llama3.2:1b",
      "size": 1337000000,
      "digest": "74701a8c35f6",
      "modified_at": "2025-09-10T08:30:00Z"
    },
    {
      "name": "mistral:7b",
      "size": 4109000000,
      "digest": "e8a35b5937a5",
      "modified_at": "2025-09-09T14:20:00Z"
    }
  ]
}
```

#### Response 500 - Erreur

```json
{
  "models": [],
  "error": "Connection failed to Ollama service"
}
```

---

## Modèles de données

### PromptRequest

Modèle pour les requêtes de génération.

```python
class PromptRequest(BaseModel):
    prompt: str = Field(..., description="Description du projet à générer", min_length=10)
    model: Optional[str] = Field("llama3.2:1b", description="Modèle LLM à utiliser")
    mode: Optional[str] = Field("local", description="Mode de traitement", regex="^(local|cloud)$")
```

**Exemple JSON:**
```json
{
  "prompt": "Create a React TypeScript application with authentication",
  "model": "llama3.2:1b",
  "mode": "local"
}
```

### PromptResponse

Modèle pour les réponses de génération.

```python
class PromptResponse(BaseModel):
    response: str = Field(..., description="Code/projet généré")
    model: str = Field(..., description="Modèle utilisé")
    mode: str = Field(..., description="Mode de traitement utilisé")
    generation_time: Optional[float] = Field(None, description="Temps de génération en secondes")
    token_count: Optional[int] = Field(None, description="Nombre de tokens générés")
```

**Exemple JSON:**
```json
{
  "response": "# React TypeScript App\n\n## Installation\n\n```bash\nnpx create-react-app my-app --template typescript\n```",
  "model": "llama3.2:1b",
  "mode": "local",
  "generation_time": 1.23,
  "token_count": 234
}
```

---

## Codes d'erreur

| Code | Status | Description | Action recommandée |
|------|--------|-------------|-------------------|
| 200 | OK | Succès | - |
| 400 | Bad Request | Données invalides | Vérifier les paramètres |
| 404 | Not Found | Endpoint inexistant | Vérifier l'URL |
| 422 | Unprocessable Entity | Validation échouée | Corriger les données JSON |
| 500 | Internal Server Error | Erreur serveur | Retry ou contacter support |
| 504 | Gateway Timeout | Timeout LLM | Retry avec prompt plus simple |

---

## Exemples d'utilisation

### Génération d'une API REST

```bash
curl -X POST "http://localhost:8080/generate" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "Create a Node.js Express API for user management with JWT authentication and MongoDB",
    "model": "llama3.2:1b",
    "mode": "local"
  }'
```

### Génération d'une application frontend

```bash
curl -X POST "http://localhost:8080/generate" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "Create a Vue.js application with Vuetify for a task management system",
    "model": "mistral:7b",
    "mode": "local"
  }'
```

### Mode cloud pour projets complexes

```bash
curl -X POST "http://localhost:8080/generate" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "Create a microservices architecture with Docker, Kubernetes, and service mesh for an e-commerce platform",
    "model": "gpt-4",
    "mode": "cloud"
  }'
```

### Vérification de santé

```bash
curl -X GET "http://localhost:8080/health"
```

### Liste des modèles

```bash
curl -X GET "http://localhost:8080/models"
```

---

## Intégration

### Exemples d'intégration

Le POC expose une API REST standard. Voici des exemples simples d'intégration :

#### Python avec requests
```python
import requests

def generate_code(prompt, model="llama3.2:1b"):
    response = requests.post("http://localhost:8080/generate", 
                           json={"prompt": prompt, "model": model, "mode": "local"})
    return response.json()

result = generate_code("Create a Python hello world script")
print(result["response"])
```

#### JavaScript avec fetch
```javascript
async function generateCode(prompt, model = "llama3.2:1b") {
    const response = await fetch("http://localhost:8080/generate", {
        method: "POST",
        headers: {"Content-Type": "application/json"},
        body: JSON.stringify({prompt, model, mode: "local"})
    });
    return response.json();
}

generateCode("Create a Node.js hello world script")
    .then(result => console.log(result.response));
```

**Note :** Ce POC n'inclut pas de SDK officiel. Les exemples ci-dessus montrent une intégration basique via HTTP.

---

## Documentation interactive

L'API expose automatiquement une documentation Swagger interactive accessible à :

- **Swagger UI**: `http://localhost:8080/docs`
- **ReDoc**: `http://localhost:8080/redoc`
- **OpenAPI Schema**: `http://localhost:8080/openapi.json`

Ces interfaces permettent de :
- ✅ Tester les endpoints directement
- ✅ Voir les schémas de données en détail
- ✅ Générer des clients dans différents languages
- ✅ Valider les réponses en temps réel

---

*Documentation générée automatiquement - Dernière mise à jour: Septembre 2025*