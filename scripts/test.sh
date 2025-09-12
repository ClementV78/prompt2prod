#!/bin/bash

# Script de test complet pour Prompt2Prod
# Exécute tous les types de tests: unitaires, sécurité, et intégration

set -e

echo "🧪 Starting complete test suite for Prompt2Prod"
echo "================================================"

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

# Vérifier la structure Python
if [ ! -f "requirements.txt" ] || [ ! -f "requirements-test.txt" ]; then
    echo "❌ Missing requirements files"
    exit 1
fi

# Installer les dépendances si nécessaire
echo "📦 Installing dependencies..."
if [ ! -d "venv" ]; then
    echo "🔧 Creating virtual environment..."
    python -m venv venv
fi

source venv/bin/activate
python -m pip install --upgrade pip
pip install -r requirements.txt
pip install -r requirements-test.txt
pip install pbr  # For bandit

# 1. Tests unitaires
echo ""
echo "🔬 Running unit tests..."
PYTHONPATH=$PROJECT_DIR:$PYTHONPATH pytest tests/unit/ -v \
    --cov=src \
    --cov-report=term-missing \
    --cov-report=html:htmlcov \
    --cov-report=xml:coverage.xml \
    --junitxml=test-results.xml

# 2. Tests de sécurité
echo ""
echo "🔒 Running security tests..."
PYTHONPATH=$PROJECT_DIR:$PYTHONPATH pytest tests/security/ -v -m security --tb=short

# 3. Scan de sécurité avec Bandit
echo ""
echo "🐍 Running Bandit security scan..."
bandit -r src/ -ll --skip B101 || {
    echo "⚠️  Security issues found, but continuing..."
}

# 4. Scan des vulnérabilités des dépendances
echo ""
echo "🔍 Checking dependencies for vulnerabilities..."
safety check || {
    echo "⚠️  Vulnerability warnings found, review them carefully"
}

# 5. Configuration pour tests d'intégration LLM
echo ""
echo "⚙️ Configuring LLM backends for integration tests..."

# Vérifier si OpenAI est disponible
if [ -n "$OPENAI_API_KEY" ]; then
    echo "✅ OpenAI API key found - cloud tests will run"
    OPENAI_AVAILABLE=true
else
    echo "⚠️  OpenAI API key not found - cloud tests will be skipped"
    OPENAI_AVAILABLE=false
fi

# Configurer Ollama local si disponible
if command -v ollama &> /dev/null; then
    echo "🤖 Ollama found - setting up local LLM backend..."
    
    # Démarrer Ollama si pas déjà lancé
    if ! curl -s http://localhost:11434/api/version >/dev/null 2>&1; then
        echo "🚀 Starting Ollama service..."
        ollama serve >/dev/null 2>&1 &
        OLLAMA_PID=$!
        
        # Attendre que Ollama soit prêt
        for i in {1..30}; do
            if curl -s http://localhost:11434/api/version >/dev/null 2>&1; then
                echo "✅ Ollama service ready"
                break
            fi
            if [ $i -eq 30 ]; then
                echo "❌ Ollama failed to start"
                kill $OLLAMA_PID 2>/dev/null || true
                OLLAMA_PID=""
                break
            fi
            sleep 1
        done
    fi
    
    # Vérifier/installer un modèle léger pour tests
    if [ -n "$OLLAMA_PID" ] || curl -s http://localhost:11434/api/version >/dev/null 2>&1; then
        if ! curl -s http://localhost:11434/api/tags | grep -q "phi3"; then
            echo "📥 Installing lightweight model for tests (phi3:mini)..."
            ollama pull phi3:mini >/dev/null 2>&1 &
            PULL_PID=$!
            echo "⏳ Model download in background..."
        else
            echo "✅ Test model (phi3:mini) already available"
        fi
        OLLAMA_AVAILABLE=true
    else
        OLLAMA_AVAILABLE=false
    fi
else
    echo "⚠️  Ollama not found - local LLM tests will be skipped"
    OLLAMA_AVAILABLE=false
fi

# 6. Tests d'intégration (si API_URL est définie)
if [ -n "$API_URL" ]; then
    echo ""
    echo "🌐 Running integration tests against $API_URL..."
    PYTHONPATH=$PROJECT_DIR:$PYTHONPATH pytest tests/integration/ -v -m integration --tb=short
elif command -v docker &> /dev/null; then
    # Builder l'image si elle n'existe pas
    if ! docker images | grep -q "prompt2prod.*latest"; then
        echo "🔧 Building Docker image for integration tests..."
        docker build -f docker/Dockerfile -t prompt2prod:latest .
    fi
    echo ""
    echo "🐳 Starting local Docker container for integration tests..."
    
    # Arrêter le container s'il existe déjà
    docker stop prompt2prod-test 2>/dev/null || true
    docker rm prompt2prod-test 2>/dev/null || true
    
    # Déployer la stack complète pour tests d'intégration
    echo "🚀 Deploying full integration test stack..."
    
    # 1. Démarrer Ollama avec modèle pré-installé
    echo "🤖 Setting up Ollama with cached models..."
    if ! pgrep -f "ollama serve" > /dev/null; then
        ollama serve >/dev/null 2>&1 &
        OLLAMA_PID=$!
        sleep 5
    fi
    
    # Installer un modèle léger s'il n'existe pas
    if ! ollama list | grep -q "phi3:mini"; then
        echo "📦 Installing phi3:mini model (lightweight for tests)..."
        ollama pull phi3:mini >/dev/null 2>&1 &
        PULL_PID=$!
        # Ne pas attendre la fin, utiliser le modèle par défaut en attendant
    fi
    
    # 2. Créer un réseau Docker pour les tests
    docker network create prompt2prod-test 2>/dev/null || true
    
    # 3. Démarrer Mock KGateway pour tests d'intégration
    echo "🎭 Starting Mock KGateway (simulates real KGateway behavior)..."
    source venv/bin/activate
    python tests/mock_kgateway.py 8080 &
    MOCK_KGATEWAY_PID=$!
    
    # Attendre que le mock soit prêt
    echo "⏳ Waiting for Mock KGateway to be ready..."
    for i in {1..15}; do
        if curl -f http://localhost:8080/health >/dev/null 2>&1; then
            echo "✅ Mock KGateway ready"
            break
        fi
        if [ $i -eq 15 ]; then
            echo "❌ Mock KGateway failed to start"
            kill $MOCK_KGATEWAY_PID 2>/dev/null || true
            exit 1
        fi
        sleep 1
    done
    
    # 4. Démarrer l'application connectée au Mock KGateway
    echo "🚀 Starting application with Mock KGateway backend..."
    docker run -d --name prompt2prod-test \
        --network prompt2prod-test \
        -p 8888:8000 \
        -e KGATEWAY_ENDPOINT="http://host.docker.internal:8080" \
        -e OLLAMA_HOST="http://host.docker.internal:11434" \
        ${OPENAI_API_KEY:+-e OPENAI_API_KEY="$OPENAI_API_KEY"} \
        --add-host=host.docker.internal:host-gateway \
        prompt2prod:latest
    
    # Attendre que l'API soit prête
    echo "⏳ Waiting for API to be ready..."
    for i in {1..30}; do
        if curl -f http://localhost:8888/health >/dev/null 2>&1; then
            echo "✅ API is ready"
            break
        fi
        if [ $i -eq 30 ]; then
            echo "❌ API not ready after 30 attempts"
            docker logs prompt2prod-test
            docker stop prompt2prod-test
            docker rm prompt2prod-test
            exit 1
        fi
        sleep 2
    done
    
    # Exécuter les tests d'intégration avec variables d'env
    export API_URL="http://localhost:8888"
    ${OPENAI_API_KEY:+export OPENAI_API_KEY="$OPENAI_API_KEY"}
    PYTHONPATH=$PROJECT_DIR:$PYTHONPATH pytest tests/integration/ -v -m integration --tb=short
    
    # Nettoyer
    docker stop prompt2prod-test
    docker rm prompt2prod-test
    
    echo "✅ Integration tests completed"
    
    # Nettoyer les processus et containers
    if [ -n "$MOCK_KGATEWAY_PID" ]; then
        echo "🧹 Stopping Mock KGateway..."
        kill $MOCK_KGATEWAY_PID 2>/dev/null || true
    fi
    if [ -n "$OLLAMA_PID" ]; then
        echo "🧹 Stopping Ollama service..."
        kill $OLLAMA_PID 2>/dev/null || true
    fi
    if [ -n "$PULL_PID" ]; then
        kill $PULL_PID 2>/dev/null || true
    fi
    
    # Nettoyer le réseau Docker
    docker network rm prompt2prod-test 2>/dev/null || true
else
    echo "⚠️  Skipping integration tests (no API_URL or Docker image)"
fi

# 6. Résumé
echo ""
echo "📊 Test Summary"
echo "==============="

if [ -f "coverage.xml" ]; then
    # Extraire le pourcentage de couverture
    COVERAGE=$(grep -o 'line-rate="[^"]*"' coverage.xml | head -1 | sed 's/line-rate="//;s/"//' | awk '{printf "%.1f", $1*100}')
    echo "📈 Code coverage: ${COVERAGE}%"
fi

if [ -f "test-results.xml" ]; then
    TESTS_COUNT=$(grep -o 'tests="[^"]*"' test-results.xml | sed 's/tests="//;s/"//')
    FAILURES=$(grep -o 'failures="[^"]*"' test-results.xml | sed 's/failures="//;s/"//')
    ERRORS=$(grep -o 'errors="[^"]*"' test-results.xml | sed 's/errors="//;s/"//')
    
    echo "🧪 Tests executed: $TESTS_COUNT"
    echo "❌ Failures: $FAILURES"
    echo "💥 Errors: $ERRORS"
    
    if [ "$FAILURES" -gt 0 ] || [ "$ERRORS" -gt 0 ]; then
        echo "❌ Some tests failed!"
        exit 1
    fi
fi

echo ""
echo "🎉 All tests passed successfully!"
echo ""
echo "📁 Generated reports:"
echo "  • HTML coverage: htmlcov/index.html"
echo "  • XML coverage: coverage.xml"
echo "  • Test results: test-results.xml"