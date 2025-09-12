"""
Prompt2Prod - API principale
"""
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import httpx
import os
from typing import Optional

app = FastAPI(
    title="Prompt2Prod API",
    description="🚀 API pour la génération de code via modèles IA locaux et cloud",
    version="1.0.0",
    contact={
        "name": "Prompt2Prod",
        "url": "https://github.com/ClementV78/prompt2prod",
    },
    license_info={
        "name": "MIT License",
        "url": "https://github.com/ClementV78/prompt2prod/blob/main/LICENSE",
    },
)

# CORS pour development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Configuration  
OLLAMA_HOST = os.getenv("OLLAMA_HOST", "http://localhost:11434")
OPENAI_ENDPOINT = "https://api.openai.com/v1/chat/completions"
KGATEWAY_ENDPOINT = os.getenv("KGATEWAY_ENDPOINT", "http://kgateway:80")

class PromptRequest(BaseModel):
    prompt: str = "Create a Python hello world script"
    model: Optional[str] = "gpt-4o-mini"
    mode: Optional[str] = "cloud"  # local (ollama) ou cloud (openai)
    
    class Config:
        schema_extra = {
            "examples": {
                "openai_cloud": {
                    "summary": "OpenAI via KGateway",
                    "value": {
                        "prompt": "Create a Python FastAPI hello world endpoint",
                        "model": "gpt-4o-mini",
                        "mode": "cloud"
                    }
                },
                "ollama_local": {
                    "summary": "Ollama local via KGateway",
                    "value": {
                        "prompt": "Create a simple Python function",
                        "model": "llama3.2:1b",
                        "mode": "local"
                    }
                }
            }
        }

class PromptResponse(BaseModel):
    response: str
    model: str
    provider: str
    mode: str
    
    class Config:
        schema_extra = {
            "example": {
                "response": "# Python Hello World\nprint('Hello World!')",
                "model": "gpt-4o-mini",
                "provider": "openai",
                "mode": "cloud"
            }
        }

@app.get("/", tags=["Status"])
async def root():
    """
    🏠 **Point d'entrée de l'API**
    
    Retourne le statut général de l'API Prompt2Prod
    """
    return {"message": "Prompt2Prod API", "status": "running"}

@app.get("/health", tags=["Status"])
async def health():
    """
    ❤️ **Vérification de santé**
    
    Endpoint pour les health checks Kubernetes
    """
    return {"status": "healthy"}

@app.post("/generate", response_model=PromptResponse, tags=["Code Generation"])
async def generate(request: PromptRequest):
    """
    🚀 **Génération de code via IA**
    
    Génère du code à partir d'un prompt en langage naturel.
    Architecture unifiée : tous les appels passent par KGateway.
    
    **Paramètres :**
    - `prompt` : Votre demande en langage naturel
    - `model` : Modèle à utiliser (optionnel)
    - `mode` : "local" (Ollama) ou "cloud" (OpenAI)
    
    **Modes disponibles :**
    - `local` → Ollama via KGateway → llama3.2:1b, mistral:7b-instruct
    - `cloud` → OpenAI via KGateway → gpt-4o-mini, gpt-3.5-turbo
    
    **Exemples :**
    ```json
    {"prompt": "Create a Python function", "mode": "local"}
    {"prompt": "Explain async/await", "mode": "cloud", "model": "gpt-4o-mini"}
    ```
    """
    try:
        mode = request.mode or "cloud"
        print(f"[DEBUG] Starting generate request - mode: {mode}, model: {request.model}")
        
        # Tout passe par KGateway
        headers = {"Content-Type": "application/json"}
        
        if mode == "local":
            # KGateway Ollama route: /ollama (format OpenAI)
            payload = {
                "model": request.model,
                "messages": [{"role": "user", "content": request.prompt}],
                "max_tokens": 4000,
                "temperature": 0.7,
                "stream": False
            }
            endpoint = f"{KGATEWAY_ENDPOINT}/ollama"
            print(f"[DEBUG] KGateway Ollama - endpoint: {endpoint}")
        else:
            # KGateway OpenAI route: /openai
            payload = {
                "messages": [{"role": "user", "content": request.prompt}],
                "model": request.model,
                "max_tokens": 4000,
                "temperature": 0.7,
                "stream": False
            }
            endpoint = f"{KGATEWAY_ENDPOINT}/openai"
            print(f"[DEBUG] KGateway OpenAI - endpoint: {endpoint}")
        
        print(f"[DEBUG] Making HTTP request to: {endpoint}")
        print(f"[DEBUG] Headers: {headers}")
        print(f"[DEBUG] Payload: {payload}")
        
        async with httpx.AsyncClient(timeout=180.0) as client:
            print(f"[DEBUG] HTTP client created, sending POST request...")
            try:
                response = await client.post(
                    endpoint,
                    json=payload,
                    headers=headers
                )
                print(f"[DEBUG] Response received - Status: {response.status_code}")
                print(f"[DEBUG] Response headers: {dict(response.headers)}")
                print(f"[DEBUG] Raw response text: {response.text}")
                
                response.raise_for_status()
                data = response.json()
                print(f"[DEBUG] Response JSON parsed successfully")
            except httpx.HTTPStatusError as e:
                print(f"[DEBUG] HTTP error details:")
                print(f"[DEBUG]   Status: {e.response.status_code}")
                print(f"[DEBUG]   Headers: {dict(e.response.headers)}")
                print(f"[DEBUG]   Body: {e.response.text}")
                raise
            except Exception as e:
                print(f"[DEBUG] Request exception: {type(e).__name__}: {e}")
                raise
            
            # Extraction de la réponse (support format Ollama et OpenAI/OpenRouter)
            print(f"[DEBUG] Response data keys: {list(data.keys())}")
            
            if "response" in data:
                # Format Ollama
                response_text = data["response"]
                provider = "ollama"
                print(f"[DEBUG] Ollama format detected")
            elif "choices" in data and len(data["choices"]) > 0:
                # Format OpenAI/OpenRouter
                choice = data["choices"][0]
                if "message" in choice:
                    response_text = choice["message"]["content"]
                else:
                    response_text = choice.get("text", "")
                provider = "openai"
                print(f"[DEBUG] OpenRouter format detected, content length: {len(response_text)}")
            else:
                response_text = str(data)
                provider = "unknown"
                print(f"[DEBUG] Unknown format, data: {data}")
            
            print(f"[DEBUG] Returning response - provider: {provider}, mode: {mode}")
            
            return PromptResponse(
                response=response_text,
                model=request.model,
                provider=provider,
                mode=mode
            )
            
    except httpx.TimeoutException as e:
        print(f"Timeout error: {e}")
        raise HTTPException(status_code=504, detail="LLM timeout")
    except httpx.HTTPStatusError as e:
        print(f"HTTP error: {e.response.status_code} - {e.response.text}")
        raise HTTPException(status_code=e.response.status_code, detail=f"LLM error: {e.response.text}")
    except Exception as e:
        print(f"Unexpected error: {str(e)}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Unexpected error: {str(e)}")

@app.get("/models", tags=["Models"])
async def list_models():
    """
    📋 **Modèles disponibles**
    
    Liste tous les modèles IA disponibles dans l'application :
    - **Local** : Modèles Ollama hébergés localement
    - **Cloud** : Modèles OpenAI via API
    
    Format unifié avec informations pratiques pour chaque modèle.
    """
    
    # Modèles cloud supportés (OpenAI)
    cloud_models = [
        {
            "id": "gpt-4o-mini",
            "name": "GPT-4o Mini",
            "provider": "openai",
            "type": "cloud",
            "description": "Modèle rapide et économique d'OpenAI",
            "context_length": 128000,
            "pricing": {"input": 0.15, "output": 0.60, "unit": "$/1M tokens"}
        },
        {
            "id": "gpt-3.5-turbo",
            "name": "GPT-3.5 Turbo", 
            "provider": "openai",
            "type": "cloud",
            "description": "Modèle conversationnel rapide d'OpenAI",
            "context_length": 16385,
            "pricing": {"input": 0.50, "output": 1.50, "unit": "$/1M tokens"}
        }
    ]
    
    # Récupération des modèles Ollama locaux
    local_models = []
    ollama_status = {"status": "checking"}
    
    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.get(f"{OLLAMA_HOST}/api/tags")
            if response.status_code == 200:
                ollama_data = response.json()
                for model in ollama_data.get("models", []):
                    local_models.append({
                        "id": model["name"],
                        "name": model["name"].replace(":", " "),
                        "provider": "ollama",
                        "type": "local",
                        "description": f"Modèle local {model['name']}",
                        "size_gb": round(model["size"] / (1024**3), 1),
                        "modified": model["modified_at"],
                        "family": model.get("details", {}).get("family", "unknown"),
                        "parameters": model.get("details", {}).get("parameter_size", "unknown")
                    })
                ollama_status = {"status": "available", "count": len(local_models)}
            else:
                ollama_status = {"status": "error", "error": f"HTTP {response.status_code}"}
    except Exception as e:
        ollama_status = {"status": "unreachable", "error": str(e)}
    
    return {
        "models": {
            "local": local_models,
            "cloud": cloud_models
        },
        "summary": {
            "total": len(local_models) + len(cloud_models),
            "local_count": len(local_models),
            "cloud_count": len(cloud_models),
            "ollama_status": ollama_status
        },
        "usage": {
            "local": "Set mode='local' and model='model_id'",
            "cloud": "Set mode='cloud' and model='model_id'",
            "example": {
                "local": {"prompt": "Hello", "mode": "local", "model": "llama3.2:1b"},
                "cloud": {"prompt": "Hello", "mode": "cloud", "model": "gpt-4o-mini"}
            }
        }
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
