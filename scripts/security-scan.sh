#!/bin/bash

# Script de scan de sécurité pour Prompt2Prod
# Utilise Bandit pour l'analyse de code Python et Trivy pour les containers

set -e

echo "🔒 Starting security scan for Prompt2Prod"
echo "==============================================="

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
REPORTS_DIR="$PROJECT_DIR/security-reports"

# Créer le dossier de rapports
mkdir -p "$REPORTS_DIR"

echo "📁 Reports will be saved to: $REPORTS_DIR"

# 1. Scan de sécurité du code Python avec Bandit
echo ""
echo "🐍 Running Bandit security scan..."
if command -v bandit &> /dev/null; then
    bandit -r "$PROJECT_DIR/src" \
        -f json \
        -o "$REPORTS_DIR/bandit-report.json" \
        -ll \
        --exclude "**/tests/**"
    
    # Rapport lisible
    bandit -r "$PROJECT_DIR/src" \
        -f txt \
        -o "$REPORTS_DIR/bandit-report.txt" \
        -ll \
        --exclude "**/tests/**"
    
    echo "✅ Bandit scan completed"
    echo "   📄 JSON report: $REPORTS_DIR/bandit-report.json"
    echo "   📄 Text report: $REPORTS_DIR/bandit-report.txt"
else
    echo "⚠️  Bandit not found, installing..."
    pip install bandit[toml]
    # Retry
    bandit -r "$PROJECT_DIR/src" -f json -o "$REPORTS_DIR/bandit-report.json" -ll
    echo "✅ Bandit scan completed"
fi

# 2. Audit des dépendances Python avec Safety
echo ""
echo "🔍 Running Safety audit for Python dependencies..."
if command -v safety &> /dev/null; then
    safety check \
        --json \
        --output "$REPORTS_DIR/safety-report.json" || echo "⚠️  Some vulnerabilities found"
    
    # Rapport lisible  
    safety check \
        --output "$REPORTS_DIR/safety-report.txt" || echo "⚠️  Some vulnerabilities found"
    
    echo "✅ Safety audit completed"
    echo "   📄 JSON report: $REPORTS_DIR/safety-report.json" 
    echo "   📄 Text report: $REPORTS_DIR/safety-report.txt"
else
    echo "⚠️  Safety not found, installing..."
    pip install safety
    safety check --json --output "$REPORTS_DIR/safety-report.json" || echo "⚠️  Some vulnerabilities found"
    echo "✅ Safety audit completed"
fi

# 3. Scan Trivy pour les images Docker (si disponible)
echo ""
echo "🐳 Running Trivy container scan..."

# Vérifier si l'image existe localement
IMAGE_NAME="ghcr.io/clementv78/prompt2prod:latest"
if docker images --format "table {{.Repository}}:{{.Tag}}" | grep -q "$IMAGE_NAME"; then
    if command -v trivy &> /dev/null; then
        # Scan de l'image Docker
        trivy image \
            --format json \
            --output "$REPORTS_DIR/trivy-image-report.json" \
            --severity HIGH,CRITICAL \
            "$IMAGE_NAME"
        
        # Rapport lisible
        trivy image \
            --format table \
            --output "$REPORTS_DIR/trivy-image-report.txt" \
            --severity HIGH,CRITICAL \
            "$IMAGE_NAME"
        
        echo "✅ Trivy container scan completed"
        echo "   📄 JSON report: $REPORTS_DIR/trivy-image-report.json"
        echo "   📄 Text report: $REPORTS_DIR/trivy-image-report.txt"
    else
        echo "⚠️  Trivy not found, skipping container scan"
        echo "   Install with: curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh"
    fi
else
    echo "⚠️  Docker image $IMAGE_NAME not found locally, skipping container scan"
    echo "   Build the image first with: docker build -f docker/Dockerfile -t $IMAGE_NAME ."
fi

# 4. Scan des secrets avec detect-secrets (optionnel)
echo ""
echo "🔑 Running secrets detection..."
if command -v detect-secrets &> /dev/null; then
    # Créer baseline s'il n'existe pas
    if [ ! -f "$PROJECT_DIR/.secrets.baseline" ]; then
        detect-secrets scan --baseline "$PROJECT_DIR/.secrets.baseline"
    fi
    
    # Audit des nouveaux secrets
    detect-secrets audit "$PROJECT_DIR/.secrets.baseline" 2>/dev/null || true
    
    # Scan des nouveaux fichiers
    detect-secrets scan \
        --baseline "$PROJECT_DIR/.secrets.baseline" \
        --exclude-files "security-reports/.*" \
        "$PROJECT_DIR" > "$REPORTS_DIR/secrets-scan.json" || echo "⚠️  New secrets detected"
    
    echo "✅ Secrets detection completed"
    echo "   📄 Report: $REPORTS_DIR/secrets-scan.json"
else
    echo "⚠️  detect-secrets not found, skipping secrets scan"
    echo "   Install with: pip install detect-secrets"
fi

# 5. Résumé des résultats
echo ""
echo "📋 Security Scan Summary"
echo "========================="

# Compter les issues Bandit
if [ -f "$REPORTS_DIR/bandit-report.json" ]; then
    BANDIT_ISSUES=$(jq '.metrics._totals.loc' "$REPORTS_DIR/bandit-report.json" 2>/dev/null || echo "0")
    echo "🐍 Bandit: Scanned $BANDIT_ISSUES lines of code"
    
    HIGH_ISSUES=$(jq '[.results[] | select(.issue_severity == "HIGH")] | length' "$REPORTS_DIR/bandit-report.json" 2>/dev/null || echo "0")
    MEDIUM_ISSUES=$(jq '[.results[] | select(.issue_severity == "MEDIUM")] | length' "$REPORTS_DIR/bandit-report.json" 2>/dev/null || echo "0")
    
    echo "   🔴 High severity issues: $HIGH_ISSUES"
    echo "   🟡 Medium severity issues: $MEDIUM_ISSUES"
fi

# Compter les vulnérabilités Safety
if [ -f "$REPORTS_DIR/safety-report.json" ]; then
    SAFETY_VULNS=$(jq 'length' "$REPORTS_DIR/safety-report.json" 2>/dev/null || echo "0")
    echo "🔍 Safety: $SAFETY_VULNS vulnerabilities in dependencies"
fi

echo ""
echo "📁 All reports saved to: $REPORTS_DIR/"
echo ""
echo "🚀 Security scan completed!"

# Exit avec code d'erreur si des problèmes critiques
if [ -f "$REPORTS_DIR/bandit-report.json" ]; then
    HIGH_ISSUES=$(jq '[.results[] | select(.issue_severity == "HIGH")] | length' "$REPORTS_DIR/bandit-report.json" 2>/dev/null || echo "0")
    if [ "$HIGH_ISSUES" -gt 0 ]; then
        echo "❌ High severity security issues found! Review the reports."
        exit 1
    fi
fi