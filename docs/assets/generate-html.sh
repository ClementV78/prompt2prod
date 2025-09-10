#!/bin/bash

# Script simplifié pour générer la documentation HTML
set -e

DOCS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ASSETS_DIR="$DOCS_DIR/assets"
OUTPUT_DIR="$DOCS_DIR/html"

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}📚 Génération de la documentation HTML${NC}"
echo "=========================================="

mkdir -p "$OUTPUT_DIR"

# Fonction de génération HTML
generate_html() {
    local input_file="$1"
    local output_file="$2"
    local title="$3"
    
    echo -e "${BLUE}🌐 Génération: $title${NC}"
    
    pandoc "$input_file" \
        --from markdown \
        --to html5 \
        --standalone \
        --toc \
        --toc-depth=3 \
        --css="../assets/style.css" \
        --metadata title="$title" \
        --metadata author="Équipe DevOps" \
        --metadata date="$(date +'%B %Y')" \
        --highlight-style=pygments \
        --output "$output_file"
    
    echo -e "${GREEN}✅ Généré: $output_file${NC}"
}

# Génération des documents
generate_html "$DOCS_DIR/architecture/architecture.md" "$OUTPUT_DIR/architecture.html" "Architecture POC Prompt2Prod"
generate_html "$DOCS_DIR/api/api-reference.md" "$OUTPUT_DIR/api-reference.html" "API Reference POC Prompt2Prod"  
generate_html "$DOCS_DIR/functional/user-guide.md" "$OUTPUT_DIR/user-guide.html" "Guide Utilisateur POC Prompt2Prod"

# Document combiné
echo -e "${BLUE}📋 Génération du document combiné...${NC}"

cat > "$OUTPUT_DIR/combined.md" << 'EOF'
# Documentation Complète POC Prompt2Prod

*Guide technique et fonctionnel complet*

---

EOF

cat "$DOCS_DIR/architecture/architecture.md" >> "$OUTPUT_DIR/combined.md"
echo -e "\n\n---\n\n" >> "$OUTPUT_DIR/combined.md"
cat "$DOCS_DIR/api/api-reference.md" >> "$OUTPUT_DIR/combined.md"
echo -e "\n\n---\n\n" >> "$OUTPUT_DIR/combined.md"
cat "$DOCS_DIR/functional/user-guide.md" >> "$OUTPUT_DIR/combined.md"

generate_html "$OUTPUT_DIR/combined.md" "$OUTPUT_DIR/documentation-complete.html" "Documentation Complète POC Prompt2Prod"

rm "$OUTPUT_DIR/combined.md"

# Index HTML
cat > "$OUTPUT_DIR/index.html" << 'EOF'
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Documentation POC Prompt2Prod</title>
    <link rel="stylesheet" href="../assets/style.css">
    <style>
        body { max-width: 800px; }
        .doc-card {
            background: #f8f9fa;
            border: 1px solid #dee2e6;
            border-radius: 8px;
            padding: 1.5rem;
            margin: 1rem 0;
            transition: box-shadow 0.2s;
        }
        .doc-card:hover {
            box-shadow: 0 4px 8px rgba(0,0,0,0.1);
        }
        .doc-title {
            color: var(--primary-blue);
            font-size: 1.3rem;
            font-weight: 600;
            margin-bottom: 0.5rem;
        }
        .doc-desc {
            color: #666;
            margin-bottom: 1rem;
        }
        .doc-link {
            background: var(--primary-blue);
            color: white;
            padding: 0.5rem 1rem;
            text-decoration: none;
            border-radius: 4px;
            display: inline-block;
        }
        .doc-link:hover {
            background: var(--secondary-blue);
            color: white;
            border-bottom: none;
        }
    </style>
</head>
<body>
    <div class="document-header">
        <h1>📚 Documentation POC Prompt2Prod</h1>
        <p>Guide technique et fonctionnel complet</p>
    </div>

    <div class="doc-card">
        <div class="doc-title">🏗️ Architecture Technique</div>
        <div class="doc-desc">
            Documentation complète de l'architecture DevOps, stack technologique,
            pipeline CI/CD, et instructions de déploiement.
        </div>
        <a href="architecture.html" class="doc-link">Consulter →</a>
    </div>

    <div class="doc-card">
        <div class="doc-title">🔌 Référence API</div>
        <div class="doc-desc">
            Documentation technique détaillée des endpoints, modèles de données,
            codes d'erreur, et exemples d'utilisation.
        </div>
        <a href="api-reference.html" class="doc-link">Consulter →</a>
    </div>

    <div class="doc-card">
        <div class="doc-title">👤 Guide Utilisateur</div>
        <div class="doc-desc">
            Guide fonctionnel avec cas d'usage, bonnes pratiques, exemples
            pratiques, et dépannage.
        </div>
        <a href="user-guide.html" class="doc-link">Consulter →</a>
    </div>

    <div class="doc-card">
        <div class="doc-title">📖 Documentation Complète</div>
        <div class="doc-desc">
            Document unique combinant toute la documentation technique et
            fonctionnelle pour une consultation complète.
        </div>
        <a href="documentation-complete.html" class="doc-link">Consulter →</a>
    </div>

    <hr style="margin: 2rem 0;">
    
    <p style="text-align: center; color: #666; font-size: 0.9rem;">
        Documentation générée automatiquement le $(date +'%d/%m/%Y à %H:%M')<br>
        <strong>POC Prompt2Prod</strong> - Transformation d'idées en code de production
    </p>
</body>
</html>
EOF

echo ""
echo -e "${GREEN}🎉 Documentation HTML générée avec succès!${NC}"
echo ""
echo "📁 Fichiers disponibles dans: $OUTPUT_DIR"
echo "   📖 Index: $OUTPUT_DIR/index.html"
echo "   🏗️  Architecture: $OUTPUT_DIR/architecture.html"
echo "   🔌 API: $OUTPUT_DIR/api-reference.html"  
echo "   👤 Guide: $OUTPUT_DIR/user-guide.html"
echo "   📋 Complet: $OUTPUT_DIR/documentation-complete.html"
echo ""
echo "Pour consulter: open $OUTPUT_DIR/index.html"