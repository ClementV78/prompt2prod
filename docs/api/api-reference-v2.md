# API Reference - Prompt2Prod v2
## Documentation technique unifiée

**Version API:** 2.0  
**Base URL:** `http://192.168.31.106:31104`  
**Content-Type:** `application/json`

---

## Vue d'ensemble

L'API Prompt2Prod v2 expose une interface unifiée pour la génération de contenu IA via KGateway. Architecture simplifiée et moderne.

### Architecture KGateway Unifiée
```
Client → App (FastAPI) → KGateway → {Ollama | OpenAI}
```

### Modèles disponibles
- **Local (Ollama):** llama3.2:1b, mistral:7b-instruct, phi3:mini
- **Cloud (OpenAI):** gpt-4o-mini, gpt-3.5-turbo

---

## Endpoints

### 1. Génération de contenu
**POST /generate**

Génère du contenu IA avec le modèle spécifié.

**Paramètres:**
```json
{
  "prompt": "string",        // Requis - Votre demande
  "mode": "local|cloud",     // Requis - Type de modèle  
  "model": "string"          // Optionnel - Modèle spécifique
}
```

**Exemple local:**
```bash
curl -X POST "http://192.168.31.106:31104/generate" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "Create a Python function to calculate fibonacci",
    "mode": "local",
    "model": "llama3.2:1b"
  }'
```

**Exemple cloud:**
```bash
curl -X POST "http://192.168.31.106:31104/generate" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "Explain microservices architecture",
    "mode": "cloud", 
    "model": "gpt-4o-mini"
  }'
```

**Réponse:**
```json
{
  "response": "Generated content here...",
  "model": "llama3.2:1b",
  "provider": "ollama",
  "mode": "local"
}
```

### 2. Liste des modèles
**GET /models**

Récupère tous les modèles disponibles avec informations détaillées.

**Exemple:**
```bash
curl "http://192.168.31.106:31104/models"
```

**Réponse:**
```json
{
  "models": {
    "local": [
      {
        "id": "llama3.2:1b",
        "name": "llama3.2 1b", 
        "provider": "ollama",
        "type": "local",
        "size_gb": 1.2,
        "parameters": "1.2B"
      }
    ],
    "cloud": [
      {
        "id": "gpt-4o-mini",
        "name": "GPT-4o Mini",
        "provider": "openai", 
        "type": "cloud",
        "context_length": 128000,
        "pricing": {"input": 0.15, "output": 0.60}
      }
    ]
  },
  "summary": {
    "total": 5,
    "local_count": 3,
    "cloud_count": 2
  },
  "usage": {
    "example": {
      "local": {"prompt": "Hello", "mode": "local", "model": "llama3.2:1b"},
      "cloud": {"prompt": "Hello", "mode": "cloud", "model": "gpt-4o-mini"}
    }
  }
}
```

### 3. Status de santé
**GET /health**

Vérification de l'état de l'API.

**Exemple:**
```bash
curl "http://192.168.31.106:31104/health"
```

**Réponse:**
```json
{
  "status": "healthy"
}
```

---

## Codes d'erreur

| Code | Description |
|------|-------------|
| 200 | Succès |
| 400 | Paramètres invalides |
| 500 | Erreur LLM/serveur |
| 504 | Timeout |

---

## Timeouts

| Segment | Timeout |
|---------|---------|
| Client → App | 180s |
| App → KGateway | 40s |
| KGateway → Backend | 40s |

---

## Interface Web

Documentation interactive Swagger disponible sur :
**http://192.168.31.106:31104/docs**

---

*Documentation générée - Architecture KGateway unifiée - Septembre 2025*