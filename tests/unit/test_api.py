"""
Tests unitaires pour l'API Prompt2Prod
"""
import pytest
from unittest.mock import AsyncMock, patch, MagicMock
from fastapi.testclient import TestClient
import httpx
from src.api.main import app, PromptRequest, PromptResponse


@pytest.fixture
def client():
    """Client de test FastAPI"""
    return TestClient(app)


@pytest.fixture
def mock_httpx_client():
    """Mock du client HTTP"""
    return MagicMock()


class TestHealthEndpoints:
    """Tests des endpoints de santé"""
    
    def test_root_endpoint(self, client):
        """Test du endpoint racine"""
        response = client.get("/")
        assert response.status_code == 200
        assert response.json()["message"] == "Prompt2Prod API"
        assert response.json()["status"] == "running"
    
    def test_health_endpoint(self, client):
        """Test du endpoint de santé"""
        response = client.get("/health")
        assert response.status_code == 200
        assert response.json()["status"] == "healthy"


class TestModelsEndpoint:
    """Tests du endpoint des modèles"""
    
    @patch('httpx.AsyncClient')
    def test_list_models_ollama_available(self, mock_client_class, client):
        """Test avec Ollama disponible"""
        # Mock de la réponse Ollama
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            "models": [
                {
                    "name": "llama3.2:1b",
                    "size": 1073741824,  # 1GB
                    "modified_at": "2024-01-01T00:00:00Z",
                    "details": {
                        "family": "llama",
                        "parameter_size": "1B"
                    }
                }
            ]
        }
        
        mock_client = MagicMock()
        mock_client.__aenter__ = AsyncMock(return_value=mock_client)
        mock_client.__aexit__ = AsyncMock(return_value=None)
        mock_client.get = AsyncMock(return_value=mock_response)
        mock_client_class.return_value = mock_client
        
        response = client.get("/models")
        
        assert response.status_code == 200
        data = response.json()
        
        assert "models" in data
        assert "cloud" in data["models"]
        assert "local" in data["models"]
        assert len(data["models"]["cloud"]) == 2  # gpt-4o-mini, gpt-3.5-turbo
        assert len(data["models"]["local"]) == 1
        assert data["summary"]["ollama_status"]["status"] == "available"
    
    @patch('httpx.AsyncClient')
    def test_list_models_ollama_unavailable(self, mock_client_class, client):
        """Test avec Ollama indisponible"""
        mock_client = MagicMock()
        mock_client.__aenter__ = AsyncMock(return_value=mock_client)
        mock_client.__aexit__ = AsyncMock(return_value=None)
        mock_client.get = AsyncMock(side_effect=httpx.ConnectError("Connection failed"))
        mock_client_class.return_value = mock_client
        
        response = client.get("/models")
        
        assert response.status_code == 200
        data = response.json()
        
        assert data["summary"]["ollama_status"]["status"] == "unreachable"
        assert len(data["models"]["local"]) == 0
        assert len(data["models"]["cloud"]) == 2


class TestGenerateEndpoint:
    """Tests du endpoint de génération"""
    
    def test_prompt_request_validation(self):
        """Test de validation du modèle PromptRequest"""
        # Données valides
        valid_data = {
            "prompt": "Create a Python function",
            "model": "gpt-4o-mini",
            "mode": "cloud"
        }
        request = PromptRequest(**valid_data)
        assert request.prompt == "Create a Python function"
        assert request.model == "gpt-4o-mini"
        assert request.mode == "cloud"
        
        # Données minimales
        minimal_data = {"prompt": "Hello"}
        request = PromptRequest(**minimal_data)
        assert request.prompt == "Hello"
        assert request.model == "gpt-4o-mini"  # valeur par défaut
        assert request.mode == "cloud"  # valeur par défaut
    
    @patch('httpx.AsyncClient')
    def test_generate_cloud_success(self, mock_client_class, client):
        """Test de génération réussie avec OpenAI (cloud)"""
        # Mock de la réponse OpenAI
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            "choices": [
                {
                    "message": {
                        "content": "print('Hello World!')"
                    }
                }
            ]
        }
        mock_response.raise_for_status.return_value = None
        mock_response.text = '{"choices":[{"message":{"content":"print(\'Hello World!\')"}}]}'
        mock_response.headers = {"content-type": "application/json"}
        
        mock_client = MagicMock()
        mock_client.__aenter__ = AsyncMock(return_value=mock_client)
        mock_client.__aexit__ = AsyncMock(return_value=None)
        mock_client.post = AsyncMock(return_value=mock_response)
        mock_client_class.return_value = mock_client
        
        response = client.post("/generate", json={
            "prompt": "Create a hello world",
            "mode": "cloud",
            "model": "gpt-4o-mini"
        })
        
        assert response.status_code == 200
        data = response.json()
        assert data["response"] == "print('Hello World!')"
        assert data["provider"] == "openai"
        assert data["mode"] == "cloud"
        assert data["model"] == "gpt-4o-mini"
    
    @patch('httpx.AsyncClient')
    def test_generate_local_success(self, mock_client_class, client):
        """Test de génération réussie avec Ollama (local)"""
        # Mock de la réponse Ollama
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            "response": "def hello():\n    print('Hello World!')"
        }
        mock_response.raise_for_status.return_value = None
        mock_response.text = '{"response":"def hello():\\n    print(\'Hello World!\')"}'
        mock_response.headers = {"content-type": "application/json"}
        
        mock_client = MagicMock()
        mock_client.__aenter__ = AsyncMock(return_value=mock_client)
        mock_client.__aexit__ = AsyncMock(return_value=None)
        mock_client.post = AsyncMock(return_value=mock_response)
        mock_client_class.return_value = mock_client
        
        response = client.post("/generate", json={
            "prompt": "Create a hello function",
            "mode": "local",
            "model": "llama3.2:1b"
        })
        
        assert response.status_code == 200
        data = response.json()
        assert data["response"] == "def hello():\n    print('Hello World!')"
        assert data["provider"] == "ollama"
        assert data["mode"] == "local"
        assert data["model"] == "llama3.2:1b"
    
    @patch('httpx.AsyncClient')
    def test_generate_timeout_error(self, mock_client_class, client):
        """Test de gestion d'erreur de timeout"""
        mock_client = MagicMock()
        mock_client.__aenter__ = AsyncMock(return_value=mock_client)
        mock_client.__aexit__ = AsyncMock(return_value=None)
        mock_client.post = AsyncMock(side_effect=httpx.TimeoutException("Request timed out"))
        mock_client_class.return_value = mock_client
        
        response = client.post("/generate", json={
            "prompt": "Create a function",
            "mode": "cloud"
        })
        
        assert response.status_code == 504
        assert "timeout" in response.json()["detail"].lower()
    
    @patch('httpx.AsyncClient')
    def test_generate_http_error(self, mock_client_class, client):
        """Test de gestion d'erreur HTTP"""
        mock_response = MagicMock()
        mock_response.status_code = 429
        mock_response.text = "Rate limit exceeded"
        
        mock_client = MagicMock()
        mock_client.__aenter__ = AsyncMock(return_value=mock_client)
        mock_client.__aexit__ = AsyncMock(return_value=None)
        mock_client.post = AsyncMock(side_effect=httpx.HTTPStatusError(
            "Rate limit exceeded", request=MagicMock(), response=mock_response
        ))
        mock_client_class.return_value = mock_client
        
        response = client.post("/generate", json={
            "prompt": "Create a function",
            "mode": "cloud"
        })
        
        assert response.status_code == 429
    
    def test_generate_invalid_input(self, client):
        """Test avec des données d'entrée invalides"""
        # Prompt manquant (doit utiliser la valeur par défaut)
        response = client.post("/generate", json={})
        # Le prompt par défaut sera utilisé, donc cela ne doit PAS être 422
        assert response.status_code in [200, 500, 504]  # 500/504 car pas de backend réel
        
        # Prompt non-string
        response = client.post("/generate", json={"prompt": 123})
        assert response.status_code == 422


class TestPromptResponseModel:
    """Tests du modèle de réponse"""
    
    def test_prompt_response_creation(self):
        """Test de création du modèle PromptResponse"""
        response = PromptResponse(
            response="Hello World!",
            model="gpt-4o-mini",
            provider="openai",
            mode="cloud"
        )
        
        assert response.response == "Hello World!"
        assert response.model == "gpt-4o-mini"
        assert response.provider == "openai"
        assert response.mode == "cloud"


class TestConfigurationLoading:
    """Tests de chargement de configuration"""
    
    @patch.dict('os.environ', {
        'KGATEWAY_ENDPOINT': 'http://test-gateway:8080',
        'OLLAMA_HOST': 'http://test-ollama:11434'
    })
    def test_environment_variables(self):
        """Test du chargement des variables d'environnement"""
        # Rechargement du module pour prendre en compte les nouvelles variables
        import importlib
        import src.api.main
        importlib.reload(src.api.main)
        
        assert src.api.main.KGATEWAY_ENDPOINT == "http://test-gateway:8080"
        assert src.api.main.OLLAMA_HOST == "http://test-ollama:11434"