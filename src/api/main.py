"""
POC OpenHands - API principale
"""
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import httpx
import os
from typing import Optional

app = FastAPI(title="POC OpenHands API", version="1.0.0")

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
    prompt: str
    model: Optional[str] = "mistral"
    mode: Optional[str] = "local"  # local ou cloud

class PromptResponse(BaseModel):
    response: str
    model: str
    mode: str

@app.get("/")
async def root():
    return {"message": "POC OpenHands API", "status": "running"}

@app.get("/health")
async def health():
    return {"status": "healthy"}

@app.post("/generate", response_model=PromptResponse)
async def generate(request: PromptRequest):
    """
    Génère une réponse via LLM (local ou cloud)
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
        
        async with httpx.AsyncClient(timeout=30.0) as client:
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

@app.get("/models")
async def list_models():
    """
    Liste les modèles disponibles
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
