"""
Tests d'intégration pour l'API Prompt2Prod
Tests end-to-end avec l'application déployée
"""
import pytest
import httpx
import asyncio
import os
from typing import Optional


class TestAPIIntegration:
    """Tests d'intégration de l'API"""
    
    @pytest.fixture(scope="class")
    def api_base_url(self) -> str:
        """URL de base de l'API pour les tests d'intégration"""
        # Priorité à la variable d'environnement API_URL définie par la pipeline
        api_url = os.getenv("API_URL")
        if api_url:
            print(f"🔍 Using API_URL from environment: {api_url}")
            return api_url
        
        # Fallback : En CI/CD avec K3d (ancien comportement)
        if os.getenv("GITHUB_ACTIONS"):
            fallback_url = "http://localhost:31104"
            print(f"🔍 Using GitHub Actions fallback: {fallback_url}")
            return fallback_url
        # En local avec K3s
        fallback_url = "http://192.168.31.106:31104"
        print(f"🔍 Using local fallback: {fallback_url}")
        return fallback_url
    
    @pytest.fixture(scope="class") 
    def timeout(self) -> float:
        """Timeout pour les requêtes d'intégration"""
        return 60.0  # 60s pour les tests d'intégration
    
    @pytest.mark.asyncio
    async def test_health_check(self, api_base_url: str, timeout: float):
        """Test de santé de l'API déployée"""
        async with httpx.AsyncClient(timeout=timeout) as client:
            response = await client.get(f"{api_base_url}/health")
            assert response.status_code == 200
            data = response.json()
            assert data["status"] == "healthy"
    
    @pytest.mark.asyncio
    async def test_root_endpoint(self, api_base_url: str, timeout: float):
        """Test du endpoint racine"""
        async with httpx.AsyncClient(timeout=timeout) as client:
            response = await client.get(f"{api_base_url}/")
            assert response.status_code == 200
            data = response.json()
            assert data["message"] == "Prompt2Prod API"
            assert data["status"] == "running"
    
    @pytest.mark.asyncio
    async def test_models_endpoint(self, api_base_url: str, timeout: float):
        """Test du listing des modèles"""
        async with httpx.AsyncClient(timeout=timeout) as client:
            response = await client.get(f"{api_base_url}/models")
            assert response.status_code == 200
            data = response.json()
            
            # Structure attendue
            assert "models" in data
            assert "cloud" in data["models"] 
            assert "local" in data["models"]
            assert "summary" in data
            assert "usage" in data
            
            # Modèles cloud toujours disponibles
            cloud_models = data["models"]["cloud"]
            assert len(cloud_models) >= 2
            assert any(model["id"] == "gpt-4o-mini" for model in cloud_models)
            assert any(model["id"] == "gpt-3.5-turbo" for model in cloud_models)
    
    @pytest.mark.asyncio
    async def test_openapi_schema(self, api_base_url: str, timeout: float):
        """Test de la documentation OpenAPI/Swagger"""
        async with httpx.AsyncClient(timeout=timeout) as client:
            # Test de l'endpoint OpenAPI
            response = await client.get(f"{api_base_url}/openapi.json")
            assert response.status_code == 200
            schema = response.json()
            
            # Vérifications du schéma OpenAPI
            assert schema["info"]["title"] == "Prompt2Prod API"
            assert schema["info"]["version"] == "1.0.0"
            assert "paths" in schema
            
            # Endpoints attendus
            expected_paths = ["/", "/health", "/generate", "/models"]
            for path in expected_paths:
                assert path in schema["paths"]
            
            # Test de l'interface Swagger UI
            response = await client.get(f"{api_base_url}/docs")
            assert response.status_code == 200
            assert "swagger" in response.text.lower()
            
            # Test de ReDoc
            response = await client.get(f"{api_base_url}/redoc")
            assert response.status_code == 200
            assert "redoc" in response.text.lower()


class TestGenerationIntegration:
    """Tests d'intégration de génération de code"""
    
    @pytest.fixture(scope="class")
    def api_base_url(self) -> str:
        if os.getenv("GITHUB_ACTIONS"):
            return "http://localhost:31104"
        return os.getenv("API_URL", "http://192.168.31.106:31104")
    
    @pytest.fixture(scope="class")
    def long_timeout(self) -> float:
        return 180.0  # 3 minutes pour la génération
    
    @pytest.mark.asyncio
    @pytest.mark.integration
    async def test_generate_cloud_integration(self, api_base_url: str, long_timeout: float):
        """Test d'intégration avec modèle cloud (OpenAI)"""
        # Skip si pas de clé API OpenAI en test
        if not os.getenv("OPENAI_API_KEY") and not os.getenv("GITHUB_ACTIONS"):
            pytest.skip("OpenAI API key not available for integration test")
        
        async with httpx.AsyncClient(timeout=long_timeout) as client:
            response = await client.post(
                f"{api_base_url}/generate",
                json={
                    "prompt": "Create a simple Python function that returns 'Hello World'",
                    "mode": "cloud",
                    "model": "gpt-4o-mini"
                }
            )
            
            # En cas d'erreur d'API, afficher les détails pour debug
            if response.status_code != 200:
                print(f"Error response: {response.status_code}")
                print(f"Error body: {response.text}")
            
            assert response.status_code == 200
            data = response.json()
            
            # Vérifications de la structure
            assert "response" in data
            assert "model" in data
            assert "provider" in data
            assert "mode" in data
            
            assert data["mode"] == "cloud"
            assert data["model"] == "gpt-4o-mini"
            assert data["provider"] == "openai"
            
            # Le contenu doit être non-vide
            assert len(data["response"].strip()) > 0
            assert "hello" in data["response"].lower() or "print" in data["response"].lower()
    
    @pytest.mark.asyncio
    @pytest.mark.integration
    async def test_generate_local_integration(self, api_base_url: str, long_timeout: float):
        """Test d'intégration avec modèle local (Ollama)"""
        # Vérifier d'abord si Ollama est disponible
        async with httpx.AsyncClient(timeout=10.0) as client:
            try:
                models_response = await client.get(f"{api_base_url}/models")
                models_data = models_response.json()
                
                if models_data["summary"]["ollama_status"]["status"] != "available":
                    pytest.skip("Ollama not available for integration test")
                
                local_models = models_data["models"]["local"]
                if not local_models:
                    pytest.skip("No local models available for integration test")
                
                # Utiliser le premier modèle disponible
                test_model = local_models[0]["id"]
                
            except Exception as e:
                pytest.skip(f"Cannot check Ollama availability: {e}")
        
        # Test de génération avec Ollama
        async with httpx.AsyncClient(timeout=long_timeout) as client:
            response = await client.post(
                f"{api_base_url}/generate",
                json={
                    "prompt": "Write a Python function",
                    "mode": "local",
                    "model": test_model
                }
            )
            
            if response.status_code != 200:
                print(f"Error response: {response.status_code}")
                print(f"Error body: {response.text}")
            
            assert response.status_code == 200
            data = response.json()
            
            assert data["mode"] == "local"
            assert data["model"] == test_model
            assert data["provider"] == "ollama"
            assert len(data["response"].strip()) > 0


class TestKubernetesIntegration:
    """Tests spécifiques au déploiement Kubernetes"""
    
    @pytest.mark.asyncio
    @pytest.mark.k8s
    async def test_service_accessibility(self):
        """Test d'accessibilité du service Kubernetes"""
        # Ces tests ne s'exécutent qu'en environnement K8s
        if not os.getenv("KUBERNETES_SERVICE_HOST"):
            pytest.skip("Not running in Kubernetes environment")
        
        # Test d'accès interne au service
        internal_url = "http://app.prompt2prod.svc.cluster.local:8000"
        
        async with httpx.AsyncClient(timeout=30.0) as client:
            try:
                response = await client.get(f"{internal_url}/health")
                assert response.status_code == 200
            except httpx.ConnectError:
                pytest.skip("Internal service not accessible from test pod")
    
    @pytest.mark.asyncio  
    @pytest.mark.k8s
    async def test_readiness_and_liveness(self):
        """Test des probes Kubernetes"""
        if not os.getenv("GITHUB_ACTIONS"):
            pytest.skip("Kubernetes probes test only in CI")
        
        # En CI, l'app est accessible via NodePort
        base_url = "http://localhost:31104"
        
        async with httpx.AsyncClient(timeout=30.0) as client:
            # Test de readiness (utilisé par K8s)
            response = await client.get(f"{base_url}/health")
            assert response.status_code == 200
            
            # Test de liveness (utilisé par K8s)
            response = await client.get(f"{base_url}/")
            assert response.status_code == 200


# Configuration des markers pytest
pytestmark = [
    pytest.mark.integration,  # Tous les tests de ce fichier sont des tests d'intégration
]