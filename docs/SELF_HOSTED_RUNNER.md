# Self-Hosted Runner Setup Guide

Ce guide explique comment configurer un GitHub Actions self-hosted runner pour permettre le déploiement automatique vers votre cluster K3s local.

## 🎯 Pourquoi un self-hosted runner ?

**Problème :** GitHub Actions runners cloud ne peuvent pas accéder à votre cluster K3s local (`192.168.31.106`)

**Solution :** Runner local sur votre machine → accès direct au cluster K3s

## 📋 Prérequis

- ✅ Cluster K3s fonctionnel
- ✅ KGateway installé avec support AI
- ✅ Docker installé
- ✅ kubectl configuré
- ✅ Helm installé

## 🚀 Configuration du Self-Hosted Runner

### 1. Créer le runner dans GitHub

1. Aller sur votre repo → **Settings** → **Actions** → **Runners**
2. Cliquer **New self-hosted runner**
3. Choisir **Linux** x64
4. Suivre les instructions de setup

### 2. Installation sur votre machine

```bash
# Créer dossier pour le runner
mkdir actions-runner && cd actions-runner

# Télécharger le runner (remplacer par les URLs fournies par GitHub)
curl -o actions-runner-linux-x64-2.311.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-linux-x64-2.311.0.tar.gz

# Extraire
tar xzf ./actions-runner-linux-x64-2.311.0.tar.gz

# Configurer avec le token fourni par GitHub
./config.sh --url https://github.com/ClementV78/prompt2prod --token YOUR_TOKEN_HERE

# Démarrer le runner
./run.sh
```

### 3. Configuration en tant que service (optionnel)

```bash
# Installer comme service système
sudo ./svc.sh install

# Démarrer le service
sudo ./svc.sh start

# Vérifier le status
sudo ./svc.sh status
```

## 🔧 Configuration du workflow

Une fois le runner configuré, décommentez la section de déploiement dans `.github/workflows/deploy.yml` :

```yaml
# Décommenter cette section :
# - name: Deploy to K3s
#   if: github.ref == 'refs/heads/main' && github.event_name == 'push'
#   runs-on: self-hosted  # ← Ajouter cette ligne
#   run: |
#     # ... reste du code de déploiement
```

## 🎯 Test du setup

1. **Vérifier le runner :**
   ```bash
   # Le runner doit apparaître comme "Idle" dans GitHub
   # Settings → Actions → Runners
   ```

2. **Test avec un commit :**
   ```bash
   git commit -m "test: trigger self-hosted deployment" --allow-empty
   git push
   ```

3. **Vérifier les logs :**
   - Le workflow doit s'exécuter sur votre machine locale
   - Le déploiement doit se faire directement sur K3s

## 🔒 Sécurité

**⚠️ Points d'attention :**
- Le runner a accès à votre machine locale
- Ne pas laisser de secrets sensibles dans le repo
- Utiliser des variables d'environnement pour les configurations

**🔐 Bonnes pratiques :**
- Créer un utilisateur dédié pour le runner
- Limiter les permissions
- Surveiller les logs

## 🚨 Dépannage

### Runner offline
```bash
# Redémarrer le service
sudo ./svc.sh stop
sudo ./svc.sh start
```

### Problèmes de permissions
```bash
# Vérifier les permissions kubectl
kubectl cluster-info

# Vérifier les permissions Docker
docker ps
```

### Logs du runner
```bash
# Logs du service
journalctl -u actions.runner.ClementV78-prompt2prod.your-runner-name.service -f
```

## ✅ Validation

Une fois configuré, vous devriez avoir :
- ✅ Runner visible dans GitHub (status: Idle)  
- ✅ Déploiement automatique fonctionnel
- ✅ Accès au cluster K3s local
- ✅ Pipeline complet : Build → Test → Deploy

---

**Alternative :** Si vous préférez, vous pouvez aussi déployer manuellement après chaque build en suivant les instructions affichées par le pipeline.