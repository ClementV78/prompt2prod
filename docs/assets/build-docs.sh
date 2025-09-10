#!/bin/bash

# Script de génération de documentation PDF pour POC Prompt2Prod
# Utilise Pandoc avec des templates personnalisés

set -e

DOCS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ASSETS_DIR="$DOCS_DIR/assets"
OUTPUT_DIR="$DOCS_DIR/pdf"

# Couleurs pour la sortie console
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}📚 Génération de la documentation POC Prompt2Prod${NC}"
echo "=================================================="

# Vérification des prérequis
check_requirements() {
    echo -e "${BLUE}🔍 Vérification des prérequis...${NC}"
    
    if ! command -v pandoc &> /dev/null; then
        echo -e "${RED}❌ Pandoc n'est pas installé${NC}"
        echo "Installation requise:"
        echo "  Ubuntu/Debian: sudo apt-get install pandoc"
        echo "  macOS: brew install pandoc"
        echo "  Windows: https://pandoc.org/installing.html"
        exit 1
    fi
    
    if ! command -v pdflatex &> /dev/null; then
        echo -e "${YELLOW}⚠️  PDFLaTeX n'est pas installé (optionnel pour PDF)${NC}"
        echo "Pour générer des PDFs avec LaTeX:"
        echo "  Ubuntu/Debian: sudo apt-get install texlive-latex-extra"
        echo "  macOS: brew install mactex"
    fi
    
    echo -e "${GREEN}✅ Prérequis vérifiés${NC}"
}

# Création des répertoires
setup_directories() {
    echo -e "${BLUE}📁 Configuration des répertoires...${NC}"
    
    mkdir -p "$OUTPUT_DIR"
    mkdir -p "$OUTPUT_DIR/html"
    mkdir -p "$OUTPUT_DIR/pdf"
    
    # Création d'un logo placeholder si nécessaire
    if [ ! -f "$ASSETS_DIR/logo-placeholder.png" ]; then
        echo -e "${YELLOW}⚠️  Création du logo placeholder...${NC}"
        # Créer un logo simple avec ImageMagick si disponible
        if command -v convert &> /dev/null; then
            convert -size 200x100 xc:white \
                -pointsize 20 -fill "#00529B" \
                -gravity center -annotate 0 "POC\nPrompt2Prod" \
                "$ASSETS_DIR/logo-placeholder.png"
        else
            # Créer un fichier PNG minimal
            touch "$ASSETS_DIR/logo-placeholder.png"
        fi
    fi
}

# Génération HTML avec style
generate_html() {
    local input_file="$1"
    local output_file="$2"
    local title="$3"
    
    echo -e "${BLUE}🌐 Génération HTML: $title${NC}"
    
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
    
    echo -e "${GREEN}✅ HTML généré: $output_file${NC}"
}

# Génération PDF avec LaTeX
generate_pdf_latex() {
    local input_file="$1"
    local output_file="$2"
    local title="$3"
    
    if ! command -v pdflatex &> /dev/null; then
        echo -e "${YELLOW}⚠️  PDFLaTeX non disponible, PDF LaTeX ignoré${NC}"
        return
    fi
    
    echo -e "${BLUE}📄 Génération PDF (LaTeX): $title${NC}"
    
    pandoc "$input_file" \
        --from markdown \
        --to pdf \
        --pdf-engine=pdflatex \
        --template="$ASSETS_DIR/pandoc-template.tex" \
        --variable title="$title" \
        --variable author="Équipe DevOps" \
        --variable date="$(date +'%B %Y')" \
        --toc \
        --toc-depth=3 \
        --highlight-style=pygments \
        --variable geometry:margin=2.5cm \
        --variable fontsize:11pt \
        --variable mainfont:"Liberation Serif" \
        --variable sansfont:"Liberation Sans" \
        --variable monofont:"Liberation Mono" \
        --output "$output_file" \
        --verbose
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ PDF LaTeX généré: $output_file${NC}"
    else
        echo -e "${RED}❌ Erreur lors de la génération PDF LaTeX${NC}"
    fi
}

# Génération PDF simple (sans LaTeX)
generate_pdf_simple() {
    local input_file="$1"
    local output_file="$2"
    local title="$3"
    
    echo -e "${BLUE}📄 Génération PDF (simple): $title${NC}"
    
    pandoc "$input_file" \
        --from markdown \
        --to html5 \
        --standalone \
        --toc \
        --toc-depth=3 \
        --css="$ASSETS_DIR/style.css" \
        --metadata title="$title" \
        --metadata author="Équipe DevOps" \
        --metadata date="$(date +'%B %Y')" \
        --highlight-style=pygments \
        --print-missing-files \
        | wkhtmltopdf --page-size A4 \
                      --margin-top 25mm \
                      --margin-bottom 25mm \
                      --margin-left 25mm \
                      --margin-right 25mm \
                      --encoding UTF-8 \
                      --enable-local-file-access \
                      - "$output_file" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ PDF simple généré: $output_file${NC}"
    else
        echo -e "${YELLOW}⚠️  wkhtmltopdf non disponible ou erreur${NC}"
    fi
}

# Fonction principale de génération
generate_document() {
    local doc_type="$1"
    local title="$2"
    
    local input_file="$DOCS_DIR/$doc_type"
    local basename=$(basename "${doc_type%.*}")
    local html_output="$OUTPUT_DIR/html/${basename}.html"
    local pdf_output="$OUTPUT_DIR/pdf/${basename}.pdf"
    
    if [ ! -f "$input_file" ]; then
        echo -e "${RED}❌ Fichier source introuvable: $input_file${NC}"
        return 1
    fi
    
    # Génération HTML
    generate_html "$input_file" "$html_output" "$title"
    
    # Génération PDF (essai LaTeX puis simple)
    generate_pdf_latex "$input_file" "$pdf_output" "$title"
    
    if [ ! -f "$pdf_output" ]; then
        generate_pdf_simple "$input_file" "$pdf_output" "$title"
    fi
}

# Génération d'un document combiné
generate_combined() {
    echo -e "${BLUE}📋 Génération du document combiné...${NC}"
    
    local combined_md="$OUTPUT_DIR/combined.md"
    local combined_html="$OUTPUT_DIR/html/documentation-complete.html"
    local combined_pdf="$OUTPUT_DIR/pdf/documentation-complete.pdf"
    
    # Création du document combiné
    cat > "$combined_md" << EOF
% Documentation POC Prompt2Prod
% Équipe DevOps
% $(date +'%B %Y')

\newpage

EOF
    
    echo "# Documentation Complète POC Prompt2Prod" >> "$combined_md"
    echo "" >> "$combined_md"
    echo "Cette documentation complète rassemble tous les aspects techniques et fonctionnels du POC Prompt2Prod." >> "$combined_md"
    echo "" >> "$combined_md"
    echo "\\newpage" >> "$combined_md"
    echo "" >> "$combined_md"
    
    # Ajout du document d'architecture
    if [ -f "$DOCS_DIR/architecture/architecture.md" ]; then
        echo "\\newpage" >> "$combined_md"
        echo "" >> "$combined_md"
        cat "$DOCS_DIR/architecture/architecture.md" >> "$combined_md"
        echo "" >> "$combined_md"
    fi
    
    # Ajout de la référence API
    if [ -f "$DOCS_DIR/api/api-reference.md" ]; then
        echo "\\newpage" >> "$combined_md"
        echo "" >> "$combined_md"
        cat "$DOCS_DIR/api/api-reference.md" >> "$combined_md"
        echo "" >> "$combined_md"
    fi
    
    # Ajout du guide utilisateur
    if [ -f "$DOCS_DIR/functional/user-guide.md" ]; then
        echo "\\newpage" >> "$combined_md"
        echo "" >> "$combined_md"
        cat "$DOCS_DIR/functional/user-guide.md" >> "$combined_md"
        echo "" >> "$combined_md"
    fi
    
    # Génération des formats finaux
    generate_html "$combined_md" "$combined_html" "Documentation Complète POC Prompt2Prod"
    generate_pdf_latex "$combined_md" "$combined_pdf" "Documentation Complète POC Prompt2Prod"
    
    if [ ! -f "$combined_pdf" ]; then
        generate_pdf_simple "$combined_md" "$combined_pdf" "Documentation Complète POC Prompt2Prod"
    fi
    
    # Nettoyage
    rm -f "$combined_md"
}

# Génération du README pour les outputs
generate_readme() {
    cat > "$OUTPUT_DIR/README.md" << EOF
# Documentation Générée - POC Prompt2Prod

Cette documentation a été générée automatiquement le $(date +'%d/%m/%Y à %H:%M').

## Structure des fichiers

### Documents HTML
- [\`architecture.html\`](html/architecture.html) - Architecture technique et DevOps
- [\`api-reference.html\`](html/api-reference.html) - Référence complète des APIs
- [\`user-guide.html\`](html/user-guide.html) - Guide utilisateur fonctionnel
- [\`documentation-complete.html\`](html/documentation-complete.html) - Document combiné

### Documents PDF
- [\`architecture.pdf\`](pdf/architecture.pdf) - Architecture technique et DevOps
- [\`api-reference.pdf\`](pdf/api-reference.pdf) - Référence complète des APIs
- [\`user-guide.pdf\`](pdf/user-guide.pdf) - Guide utilisateur fonctionnel
- [\`documentation-complete.pdf\`](pdf/documentation-complete.pdf) - Document combiné

## Utilisation

Pour consulter la documentation:

1. **Version web**: Ouvrez les fichiers HTML dans votre navigateur
2. **Version impression**: Utilisez les fichiers PDF
3. **Version complète**: Le document combiné contient toute la documentation

## Régénération

Pour régénérer la documentation:

\`\`\`bash
cd docs/assets
./build-docs.sh
\`\`\`

## Outils utilisés

- **Pandoc**: Conversion Markdown vers HTML/PDF
- **LaTeX**: Génération de PDFs de haute qualité
- **CSS personnalisé**: Styles pour les versions HTML

---

*Documentation générée automatiquement*
EOF

    echo -e "${GREEN}✅ README généré: $OUTPUT_DIR/README.md${NC}"
}

# Fonction principale
main() {
    echo -e "${BLUE}🚀 Début de la génération de documentation${NC}"
    echo "Date: $(date)"
    echo "Répertoire: $DOCS_DIR"
    echo ""
    
    check_requirements
    setup_directories
    
    # Génération des documents individuels
    generate_document "architecture/architecture.md" "Architecture POC Prompt2Prod"
    generate_document "api/api-reference.md" "API Reference POC Prompt2Prod"
    generate_document "functional/user-guide.md" "Guide Utilisateur POC Prompt2Prod"
    
    # Génération du document combiné
    generate_combined
    
    # Génération du README
    generate_readme
    
    echo ""
    echo -e "${GREEN}🎉 Génération terminée avec succès!${NC}"
    echo ""
    echo "📁 Fichiers générés dans: $OUTPUT_DIR"
    echo "📊 Statistiques:"
    echo "   - HTML: $(find "$OUTPUT_DIR/html" -name "*.html" | wc -l) fichiers"
    echo "   - PDF:  $(find "$OUTPUT_DIR/pdf" -name "*.pdf" | wc -l) fichiers"
    echo ""
    echo "Pour consulter la documentation:"
    echo "   📖 HTML: open $OUTPUT_DIR/html/documentation-complete.html"
    echo "   📄 PDF:  open $OUTPUT_DIR/pdf/documentation-complete.pdf"
}

# Gestion des arguments
case "${1:-all}" in
    "architecture")
        generate_document "architecture/architecture.md" "Architecture POC Prompt2Prod"
        ;;
    "api")
        generate_document "api/api-reference.md" "API Reference POC Prompt2Prod"
        ;;
    "functional"|"user")
        generate_document "functional/user-guide.md" "Guide Utilisateur POC Prompt2Prod"
        ;;
    "all"|"")
        main
        ;;
    "help"|"-h"|"--help")
        echo "Utilisation: $0 [architecture|api|functional|all]"
        echo ""
        echo "Options:"
        echo "  architecture  - Génère uniquement le document d'architecture"
        echo "  api          - Génère uniquement la référence API"
        echo "  functional   - Génère uniquement le guide utilisateur"
        echo "  all          - Génère tous les documents (défaut)"
        echo "  help         - Affiche cette aide"
        exit 0
        ;;
    *)
        echo -e "${RED}❌ Option inconnue: $1${NC}"
        echo "Utilisez '$0 help' pour voir les options disponibles"
        exit 1
        ;;
esac