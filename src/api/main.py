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
LLM_ENDPOINT = os.getenv("LLM_ENDPOINT", "http://localhost:8080/v1/chat")
OLLAMA_HOST = os.getenv("OLLAMA_HOST", "http://localhost:11434")

class PromptRequest(BaseModel):
    prompt: str = "Create a Python hello world script"
    model: Optional[str] = "llama3.2:1b"
    mode: Optional[str] = "local"  # local ou cloud
    
    class Config:
        schema_extra = {
            "example": {
                "prompt": "Create a Python FastAPI hello world endpoint",
                "model": "llama3.2:1b",
                "mode": "local"
            }
        }

class PromptResponse(BaseModel):
    response: str
    model: str
    mode: str
    
    class Config:
        schema_extra = {
            "example": {
                "response": "# Python Hello World\nprint('Hello World!')",
                "model": "llama3.2:1b",
                "mode": "local"
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
    
    **Modes disponibles :**
    - `local` : Utilise Ollama (modèles locaux)
    - `cloud` : Utilise OpenRouter (modèles cloud)
    
    **Modèles disponibles :**
    - `llama3.2:1b` : Léger et rapide (recommandé pour tests)
    - `mistral:7b-instruct` : Plus puissant, temps de réponse ~30-60s
    """
    try:
        headers = {
            "x-llm-mode": request.mode,
            "Content-Type": "application/json"
        }
        
        payload = {
            "model": request.model,
            "prompt": request.prompt,
            "stream": False
        }
        
        async with httpx.AsyncClient(timeout=180.0) as client:
            if request.mode == "local":
                # Appel direct à Ollama
                response = await client.post(
                    f"{OLLAMA_HOST}/api/generate",
                    json=payload
                )
            else:
                # Appel via KGateway
                response = await client.post(
                    LLM_ENDPOINT,
                    json=payload,
                    headers=headers
                )
            
            response.raise_for_status()
            data = response.json()
            
            return PromptResponse(
                response=data.get("response", data.get("choices", [{}])[0].get("text", "")),
                model=request.model,
                mode=request.mode
            )
            
    except httpx.TimeoutException:
        raise HTTPException(status_code=504, detail="LLM timeout")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/models", tags=["Models"])
async def list_models():
    """
    📋 **Liste des modèles disponibles**
    
    Récupère la liste des modèles IA disponibles sur Ollama local.
    Utile pour connaître les modèles installés avant d'utiliser `/generate`
    """
    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.get(f"{OLLAMA_HOST}/api/tags")
            response.raise_for_status()
            return response.json()
    except Exception as e:
        return {"models": [], "error": str(e)}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
