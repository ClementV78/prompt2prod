#!/bin/bash

echo "🧹 Nettoyage du POC..."

read -p "⚠️ Cela va supprimer tous les déploiements. Continuer? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    kubectl delete -f k8s/base/ --ignore-not-found=true
    echo "✅ Ressources supprimées"
else
    echo "❌ Annulé"
fi
