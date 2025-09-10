# Guide Utilisateur - Prompt2Prod
## Documentation fonctionnelle et cas d'usage

**Version:** 1.0  
**Public cible:** Développeurs, DevOps, Product Managers  
**Prérequis:** Notions de base en développement

---

## Table des Matières

1. [Introduction](#introduction)
2. [Cas d'usage principaux](#cas-dusage-principaux)
3. [Guide de démarrage rapide](#guide-de-démarrage-rapide)
4. [Utilisation de l'API](#utilisation-de-lapi)
5. [Exemples pratiques](#exemples-pratiques)
6. [Bonnes pratiques](#bonnes-pratiques)
7. [Dépannage](#dépannage)
8. [FAQ](#faq)

---

## Introduction

### Qu'est-ce que Prompt2Prod ?

**Prompt2Prod** est un Proof of Concept (POC) révolutionnaire qui transforme vos idées de projets logiciels en code prêt pour la production, simplement en décrivant ce que vous voulez créer en langage naturel.

### Le problème résolu

- ⏰ **Temps de setup initial** : Plus besoin de passer des heures à configurer l'architecture de base
- 🔧 **Boilerplate repetitif** : Génération automatique du code de base
- 📚 **Documentation manquante** : Code généré avec documentation intégrée
- 🚀 **Time-to-market** : De l'idée au prototype fonctionnel en secondes

### Qui peut l'utiliser ?

- **Développeurs** : Prototypage rapide d'applications
- **Product Managers** : Validation d'idées avec des prototypes
- **Startups** : MVP rapides pour validation marché
- **Formateurs** : Création d'exemples de code pour l'apprentissage
- **DevOps** : Templates d'infrastructure et déploiement

---

## Cas d'usage principaux

### 1. 🏗️ Génération de projets complets

**Exemple concret :** Créer une API REST complète

```
Prompt: "Create a Node.js Express API for a library management system with user authentication, book CRUD operations, and borrowing system"
```

**Résultat généré :**
- Structure complète du projet
- Configuration Express.js
- Modèles de données (User, Book, Borrow)
- Routes API RESTful
- Middleware d'authentification JWT
- Configuration de base de données MongoDB
- Tests unitaires
- Dockerfile et docker-compose.yml
- README avec instructions de déploiement

### 2. 🎨 Génération d'interfaces utilisateur

**Exemple concret :** Interface web moderne

```
Prompt: "Create a React dashboard with TypeScript for an e-commerce admin panel with charts, product management, and order tracking"
```

**Résultat généré :**
- Application React avec TypeScript
- Composants réutilisables
- Routing avec React Router
- État global avec Context/Redux
- Graphiques avec Chart.js
- Interface responsive avec CSS moderne
- Mock API pour les tests
- Tests avec Jest et React Testing Library

### 3. 🐍 Scripts et outils de développement

**Exemple concret :** Outil en ligne de commande

```
Prompt: "Create a Python CLI tool for analyzing log files with filtering, statistics, and export to CSV"
```

**Résultat généré :**
- Script Python avec argparse
- Classes pour parsing des logs
- Fonctions de filtrage avancées
- Génération de statistiques
- Export CSV/JSON
- Tests unitaires avec pytest
- Configuration setuptools
- Documentation complète

### 4. 📱 Applications mobiles

**Exemple concret :** App mobile simple

```
Prompt: "Create a React Native todo app with offline storage and sync capabilities"
```

**Résultat généré :**
- Structure React Native
- Navigation avec React Navigation
- Storage local avec AsyncStorage
- Synchronisation avec API
- Interface utilisateur moderne
- Gestion d'état avec hooks
- Build scripts pour iOS/Android

---

## Guide de démarrage rapide

### Étape 1: Accéder à l'API

L'API est accessible à l'adresse : `http://localhost:8080` une fois déployée.

### Étape 2: Première génération

```bash
# Test simple avec curl
curl -X POST "http://localhost:8080/generate" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "Create a simple Python hello world script with documentation",
    "model": "llama3.2:1b",
    "mode": "local"
  }'
```

### Étape 3: Analyser le résultat

La réponse contient :
- **Code généré** : Prêt à être utilisé
- **Documentation** : Explications intégrées
- **Instructions** : Comment exécuter/déployer
- **Métadonnées** : Modèle utilisé, temps de génération

### Étape 4: Itération et amélioration

```bash
# Affinage du prompt pour plus de détails
curl -X POST "http://localhost:8080/generate" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "Create a Python hello world script with argument parsing, logging, and unit tests",
    "model": "llama3.2:1b",
    "mode": "local"
  }'
```

---

## Utilisation de l'API

### Interface Web (Swagger)

La façon la plus simple d'utiliser l'API est via l'interface Swagger :

1. Ouvrez `http://localhost:8080/docs`
2. Cliquez sur l'endpoint `/generate`
3. Cliquez sur "Try it out"
4. Saisissez votre prompt
5. Exécutez la requête
6. Copiez le code généré

### Modes de génération disponibles

#### Mode Local (`"mode": "local"`)

**Avantages :**
- ✅ Gratuit et illimité
- ✅ Données privées (pas d'envoi vers le cloud)
- ✅ Latence faible
- ✅ Fonctionne offline

**Inconvénients :**
- ❌ Qualité variable selon le modèle
- ❌ Limité pour des tâches très complexes
- ❌ Consomme des ressources locales

**Modèles recommandés :**
- `llama3.2:1b` : Ultra-rapide, idéal pour prototypage
- `mistral:7b` : Équilibré qualité/performance
- `codellama:13b` : Spécialisé développement

#### Mode Cloud (`"mode": "cloud"`)

**Avantages :**
- ✅ Très haute qualité de génération
- ✅ Gestion de projets complexes
- ✅ Modèles spécialisés disponibles
- ✅ Pas de consommation locale

**Inconvénients :**
- ❌ Coût par utilisation
- ❌ Dépendance réseau
- ❌ Données envoyées vers le cloud
- ❌ Latence plus élevée

**Modèles recommandés :**
- `gpt-4` : Excellence pour projets complexes
- `claude-3-sonnet` : Excellent pour le code
- `gpt-3.5-turbo` : Rapport qualité/prix optimal

---

## Exemples pratiques

### Exemple 1: API de blog avec authentification

**Prompt optimisé :**
```
Create a FastAPI blog application with:
- User authentication using JWT tokens
- CRUD operations for blog posts
- Comment system with moderation
- PostgreSQL database with SQLAlchemy
- API documentation with examples
- Docker configuration for deployment
- Basic frontend with HTML templates
```

**Utilisation :**
```bash
curl -X POST "http://localhost:8080/generate" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "Create a FastAPI blog application with: - User authentication using JWT tokens - CRUD operations for blog posts - Comment system with moderation - PostgreSQL database with SQLAlchemy - API documentation with examples - Docker configuration for deployment - Basic frontend with HTML templates",
    "model": "mistral:7b",
    "mode": "local"
  }'
```

### Exemple 2: Dashboard React avec graphiques

**Prompt optimisé :**
```
Create a React TypeScript dashboard application featuring:
- Modern Material-UI design
- Real-time data visualization with Chart.js
- User management interface
- Responsive layout for mobile/desktop
- API integration with axios
- State management with Redux Toolkit
- Unit tests with Jest and React Testing Library
- Webpack configuration for production build
```

### Exemple 3: Microservice en Go

**Prompt optimisé :**
```
Create a Go microservice for user management with:
- RESTful API using Gin framework
- PostgreSQL database with GORM
- JWT authentication middleware
- Input validation and error handling
- Structured logging with logrus
- Health check endpoints
- Docker multi-stage build
- Kubernetes deployment manifests
- Unit and integration tests
```

---

## Bonnes pratiques

### 📝 Rédaction de prompts efficaces

#### ✅ DO - Bonnes pratiques

1. **Soyez spécifique :**
   ```
   ❌ "Create a web app"
   ✅ "Create a React e-commerce app with product catalog, shopping cart, and checkout"
   ```

2. **Mentionnez la stack technique :**
   ```
   ❌ "Create a database app"
   ✅ "Create a Python Flask app with PostgreSQL database and SQLAlchemy ORM"
   ```

3. **Demandez la documentation :**
   ```
   ✅ "Include API documentation and setup instructions"
   ```

4. **Spécifiez les fonctionnalités :**
   ```
   ✅ "With user authentication, CRUD operations, and search functionality"
   ```

5. **Mentionnez les tests :**
   ```
   ✅ "Include unit tests and example usage"
   ```

#### ❌ DON'T - À éviter

1. **Prompts trop vagues :**
   ```
   ❌ "Make something cool"
   ❌ "Create an app"
   ```

2. **Trop de technologies incompatibles :**
   ```
   ❌ "Use React, Vue, Angular, and jQuery together"
   ```

3. **Demandes irréalisables :**
   ```
   ❌ "Create the next Facebook in one request"
   ```

### 🔄 Processus d'itération

1. **Démarrez simple :**
   ```
   "Create a basic Python web API with Flask"
   ```

2. **Ajoutez des détails :**
   ```
   "Create a Python Flask API for user management with SQLite database"
   ```

3. **Précisez les fonctionnalités :**
   ```
   "Create a Python Flask API for user management with SQLite database, JWT authentication, and CRUD endpoints"
   ```

4. **Finalisez avec la production :**
   ```
   "Create a production-ready Python Flask API for user management with PostgreSQL, JWT authentication, CRUD endpoints, logging, and Docker configuration"
   ```

### 🎯 Sélection du bon modèle

| Type de projet | Complexité | Modèle recommandé | Mode |
|---------------|------------|-------------------|------|
| Scripts simples | Faible | `llama3.2:1b` | Local |
| APIs standards | Moyenne | `mistral:7b` | Local |
| Apps complètes | Moyenne | `codellama:13b` | Local |
| Architectures complexes | Élevée | `gpt-4` | Cloud |
| Code critique | Élevée | `claude-3-sonnet` | Cloud |

---

## Dépannage

### Problèmes courants et solutions

#### 🚫 Erreur "Model not found"

**Symptôme :** `{"detail": "Model 'xyz' not available"}`

**Solutions :**
1. Vérifier les modèles disponibles :
   ```bash
   curl http://localhost:8080/models
   ```
2. Utiliser un modèle existant
3. Charger le modèle manquant :
   ```bash
   kubectl exec deployment/ollama -- ollama pull model-name
   ```

#### ⏱️ Timeouts fréquents

**Symptôme :** `{"detail": "LLM timeout"}`

**Solutions :**
1. Simplifier le prompt
2. Utiliser un modèle plus léger (`llama3.2:1b`)
3. Diviser en plusieurs requêtes
4. Passer en mode cloud pour les gros projets

#### 🔌 Erreur de connexion

**Symptôme :** `Connection refused` ou `Service unavailable`

**Solutions :**
1. Vérifier que les services sont démarrés :
   ```bash
   kubectl get pods -A
   ```
2. Redémarrer les services :
   ```bash
   kubectl rollout restart deployment/app
   ```
3. Vérifier les logs :
   ```bash
   kubectl logs deployment/app
   ```

#### 📝 Réponses de mauvaise qualité

**Symptômes :** Code incomplet, erreurs de syntaxe

**Solutions :**
1. Améliorer la précision du prompt
2. Utiliser un modèle plus performant
3. Passer en mode cloud
4. Demander explicitement la documentation
5. Spécifier la version des technologies

### Debug et monitoring

```bash
# Vérifier l'état de l'API
curl http://localhost:8080/health

# Voir les logs en temps réel
kubectl logs -f deployment/app

# Vérifier les ressources
kubectl top pods

# Test de connectivité
kubectl exec deployment/app -- curl -I http://ollama:11434
```

---

## FAQ

### Questions générales

**Q: L'API est-elle gratuite ?**
R: Oui, ce POC est entièrement gratuit. Il utilise Ollama localement sans coûts externes.

**Q: Peut-on utiliser l'API pour des projets commerciaux ?**
R: Oui, vérifiez simplement les licences des modèles utilisés.

**Q: Quelle est la limite de taille des prompts ?**
R: Les prompts peuvent contenir jusqu'à 4000 caractères pour un résultat optimal.

**Q: Le code généré est-il sécurisé ?**
R: Le code suit les bonnes pratiques basiques, mais un audit de sécurité est recommandé pour la production.

### Questions techniques

**Q: Comment ajouter un nouveau modèle ?**
R: Connectez-vous au pod Ollama et utilisez `ollama pull model-name`.

**Q: Peut-on personnaliser les réponses ?**
R: Actuellement non, mais vous pouvez affiner vos prompts pour obtenir le style souhaité.

**Q: Y a-t-il une limite de requêtes par minute ?**
R: Non, mais les ressources système peuvent limiter la performance.

**Q: L'API sauvegarde-t-elle les générations ?**
R: Non, ce POC ne sauvegarde pas l'historique. C'est une fonctionnalité à implémenter si nécessaire.

### Questions sur la performance

**Q: Quel est le temps de réponse moyen ?**
R: Mode local : 2-60 secondes selon la complexité du prompt et le modèle utilisé

**Q: Comment optimiser les performances ?**
R: 
- Utilisez des modèles adaptés à la complexité
- Gardez les prompts concis mais précis
- Utilisez le mode local pour les tâches simples

**Q: L'API peut-elle gérer plusieurs utilisateurs ?**
R: Oui, l'architecture async permet la gestion de requêtes concurrentes.

---

## Support et communauté

### Comment obtenir de l'aide ?

1. **Documentation** : Consultez d'abord cette documentation
2. **Issues GitHub** : Signalez les bugs ou demandez des fonctionnalités
3. **Logs** : Consultez les logs pour diagnostiquer les problèmes
4. **Tests** : Utilisez l'interface Swagger pour tester interactivement

### Contribuer au projet

- 🐛 **Signaler des bugs** via GitHub Issues
- 💡 **Suggérer des améliorations** avec des cas d'usage concrets
- 📚 **Améliorer la documentation** avec vos retours d'expérience
- 🧪 **Partager vos prompts réussis** pour aider la communauté

---

## À propos de ce POC

Ce **Prompt2Prod** est une démonstration d'architecture DevOps moderne intégrant l'IA. 

### Fonctionnalités actuelles

- ✅ **Génération de code** via modèles Ollama locaux
- ✅ **API FastAPI** avec documentation Swagger
- ✅ **Architecture Kubernetes** cloud-native
- ✅ **Pipeline CI/CD** avec GitHub Actions
- ✅ **Routage intelligent** via KGateway

### Limitations du POC

- ⚠️ Pas de sauvegarde d'historique
- ⚠️ Mode cloud non implémenté (architecture seulement)
- ⚠️ Pas d'authentification
- ⚠️ Génération limitée aux capacités d'Ollama local

---

*Guide utilisateur généré automatiquement - Dernière mise à jour: Septembre 2025*