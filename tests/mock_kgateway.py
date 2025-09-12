"""
Mock KGateway server pour les tests d'intégration
Simule les endpoints /ollama et /openai avec des réponses réalistes
"""
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import uvicorn
import os
import httpx
from typing import Dict, List, Any, Optional
import asyncio
import sys

app = FastAPI(title="Mock KGateway", description="Mock server for integration tests")

class ChatMessage(BaseModel):
    role: str
    content: str

class ChatRequest(BaseModel):
    model: str
    messages: List[ChatMessage]
    max_tokens: Optional[int] = 4000
    temperature: Optional[float] = 0.7
    stream: Optional[bool] = False

class ChatChoice(BaseModel):
    message: ChatMessage
    finish_reason: str = "stop"

class ChatResponse(BaseModel):
    choices: List[ChatChoice]
    model: str
    usage: Dict[str, int] = {"prompt_tokens": 10, "completion_tokens": 50, "total_tokens": 60}

class OllamaResponse(BaseModel):
    response: str
    model: str

@app.get("/health")
async def health():
    """Health check endpoint"""
    return {"status": "healthy", "service": "mock-kgateway"}

@app.post("/openai", response_model=ChatResponse)
async def openai_endpoint(request: ChatRequest):
    """
    Mock OpenAI endpoint - peut faire de vrais appels ou renvoyer des mocks
    """
    openai_key = os.getenv("OPENAI_API_KEY")
    
    if openai_key and openai_key.startswith("sk-"):
        # Vraie API OpenAI si clé disponible
        try:
            async with httpx.AsyncClient(timeout=30.0) as client:
                headers = {
                    "Authorization": f"Bearer {openai_key}",
                    "Content-Type": "application/json"
                }
                
                payload = {
                    "model": request.model,
                    "messages": [msg.dict() for msg in request.messages],
                    "max_tokens": request.max_tokens,
                    "temperature": request.temperature,
                    "stream": False
                }
                
                response = await client.post(
                    "https://api.openai.com/v1/chat/completions",
                    headers=headers,
                    json=payload
                )
                
                if response.status_code == 200:
                    return response.json()
                else:
                    print(f"OpenAI API error: {response.status_code} - {response.text}")
                    # Fallback to mock
        except Exception as e:
            print(f"OpenAI API exception: {e}")
            # Fallback to mock
    
    # Réponse mockée si pas de clé API ou erreur
    prompt_content = request.messages[-1].content if request.messages else ""
    
    # Réponses intelligentes basées sur le prompt
    if "python" in prompt_content.lower():
        mock_response = """def hello_world():
    '''Simple Python function that returns Hello World'''
    return "Hello, World!"

print(hello_world())"""
    elif "hello" in prompt_content.lower():
        mock_response = "print('Hello World!')"
    elif "function" in prompt_content.lower():
        mock_response = """def example_function():
    '''Example function for testing'''
    return "This is a test function"
    
# Call the function
result = example_function()
print(result)"""
    else:
        mock_response = f"Mock response for: {prompt_content[:50]}..."
    
    return ChatResponse(
        choices=[
            ChatChoice(
                message=ChatMessage(role="assistant", content=mock_response)
            )
        ],
        model=request.model
    )

@app.post("/ollama", response_model=ChatResponse)
async def ollama_endpoint(request: ChatRequest):
    """
    Mock Ollama endpoint - simule une réponse locale
    """
    prompt_content = request.messages[-1].content if request.messages else ""
    
    # Simulation d'une réponse Ollama (plus concise que OpenAI)
    if "python" in prompt_content.lower():
        mock_response = """# Python Hello World
print("Hello from Ollama!")"""
    elif "function" in prompt_content.lower():
        mock_response = """def test_func():
    return "Local AI response"
    
test_func()"""
    else:
        mock_response = f"Local model response: {prompt_content[:30]}..."
    
    # Format OpenAI pour compatibilité avec l'app
    return ChatResponse(
        choices=[
            ChatChoice(
                message=ChatMessage(role="assistant", content=mock_response)
            )
        ],
        model=request.model
    )

if __name__ == "__main__":
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8080
    print(f"🎭 Starting Mock KGateway on port {port}")
    print(f"🔑 OpenAI API Key: {'✅ Available' if os.getenv('OPENAI_API_KEY', '').startswith('sk-') else '❌ Not configured'}")
    
    uvicorn.run(app, host="0.0.0.0", port=port, log_level="warning")