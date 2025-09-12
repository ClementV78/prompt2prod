#!/bin/bash

# Script de test local simplifié avec Mock KGateway
# Pour les tests complets avec vraies APIs : voir GitHub Actions

set -e

echo "🧪 Starting LOCAL test suite for Prompt2Prod"
echo "=============================================="
echo "📝 Note: Uses Mock KGateway - real LLM integration tested in CI/CD"

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

# Installer les dépendances si nécessaire
echo "📦 Installing dependencies..."
if [ ! -d "venv" ]; then
    echo "🔧 Creating virtual environment..."
    python -m venv venv
fi

source venv/bin/activate
python -m pip install --upgrade pip >/dev/null 2>&1
pip install -r requirements.txt >/dev/null 2>&1
pip install -r requirements-test.txt >/dev/null 2>&1
pip install pbr >/dev/null 2>&1

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

# 3. Tests d'intégration avec Mock KGateway
if command -v docker &> /dev/null; then
    # Builder l'image si elle n'existe pas
    if ! docker images | grep -q "prompt2prod.*latest"; then
        echo "🔧 Building Docker image..."
        docker build -f docker/Dockerfile -t prompt2prod:latest . >/dev/null 2>&1
    fi
    
    echo ""
    echo "🎭 Running integration tests with Mock KGateway..."
    
    # Nettoyer d'éventuels containers précédents
    docker stop prompt2prod-test mock-kgateway-test 2>/dev/null || true
    docker rm prompt2prod-test mock-kgateway-test 2>/dev/null || true
    docker network rm prompt2prod-test 2>/dev/null || true
    
    # Créer réseau de test
    docker network create prompt2prod-test 2>/dev/null || true
    
    # Démarrer Mock KGateway
    echo "🎭 Starting Mock KGateway..."
    docker run -d --name mock-kgateway-test \
        --network prompt2prod-test \
        -p 8080:8080 \
        -v "$PROJECT_DIR":/app \
        -w /app \
        python:3.11-slim \
        sh -c "pip install fastapi uvicorn httpx >/dev/null 2>&1 && python tests/mock_kgateway.py 8080" >/dev/null 2>&1
    
    # Attendre Mock KGateway
    echo "⏳ Waiting for Mock KGateway..."
    for i in {1..20}; do
        if curl -f http://localhost:8080/health >/dev/null 2>&1; then
            echo "✅ Mock KGateway ready"
            break
        fi
        if [ $i -eq 20 ]; then
            echo "❌ Mock KGateway failed to start"
            docker logs mock-kgateway-test
            exit 1
        fi
        sleep 1
    done
    
    # Démarrer l'application
    echo "🚀 Starting application..."
    docker run -d --name prompt2prod-test \
        --network prompt2prod-test \
        -p 8888:8000 \
        -e KGATEWAY_ENDPOINT="http://mock-kgateway-test:8080" \
        prompt2prod:latest >/dev/null 2>&1
    
    # Attendre l'application
    echo "⏳ Waiting for application..."
    for i in {1..30}; do
        if curl -f http://localhost:8888/health >/dev/null 2>&1; then
            echo "✅ Application ready"
            break
        fi
        if [ $i -eq 30 ]; then
            echo "❌ Application failed to start"
            docker logs prompt2prod-test
            exit 1
        fi
        sleep 1
    done
    
    # Exécuter tests d'intégration
    export API_URL="http://localhost:8888"
    PYTHONPATH=$PROJECT_DIR:$PYTHONPATH pytest tests/integration/ -v -m integration --tb=short
    
    # Nettoyer
    echo "🧹 Cleaning up..."
    docker stop prompt2prod-test mock-kgateway-test >/dev/null 2>&1
    docker rm prompt2prod-test mock-kgateway-test >/dev/null 2>&1
    docker network rm prompt2prod-test >/dev/null 2>&1
    
    echo "✅ Integration tests completed"
else
    echo "⚠️  Skipping integration tests (Docker not available)"
fi

# 4. Résumé
echo ""
echo "📊 Local Test Summary"
echo "====================="

if [ -f "coverage.xml" ]; then
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
echo "🎉 All local tests passed!"
echo ""
echo "📝 Note: Full LLM integration (OpenAI + Ollama + KGateway) tested in:"
echo "   → GitHub Actions pipeline with K3d deployment"
echo ""
echo "📁 Generated reports:"
echo "  • HTML coverage: htmlcov/index.html"
echo "  • XML coverage: coverage.xml" 
echo "  • Test results: test-results.xml"