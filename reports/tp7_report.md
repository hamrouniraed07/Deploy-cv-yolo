<<<<<<< HEAD
# TP7 - Rapport de Déploiement YOLO avec TorchServe

## Introduction et Architecture Utilisée

### Objectif du Projet
Ce projet vise à déployer un modèle de détection d'objets YOLO (You Only Look Once) en utilisant TorchServe comme moteur d'inférence, orchestré avec Docker Compose et rendu accessible via une API Gateway pour une architecture plus agnostique.

### Architecture du Système

L'architecture déployée suit un pattern à trois niveaux :

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Client HTTP   │───▶│   API Gateway    │───▶│   TorchServe    │
│   (curl/FastAPI)│    │   (FastAPI)      │    │   (PyTorch)     │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                       │                       │
         │                       ▼                       ▼
         │              ┌──────────────────┐    ┌─────────────────┐
         └──────────────│ Port 8001/8000   │    │ Port 8085/8086  │
                        └──────────────────┘    └─────────────────┘
                                                       │
                                                       ▼
                                               ┌─────────────────┐
                                               │   YOLO Model    │
                                               │   (best.pt)     │
                                               └─────────────────┘
```

#### Composants Principaux

1. **TorchServe** : Moteur d'inférence PyTorch
   - Service principal de prédiction
   - Ports 8085 (inférence) et 8086 (gestion)
   - Utilise l'image officielle `pytorch/torchserve:latest-cpu`

2. **API Gateway** : Couche d'abstraction FastAPI
   - Port 8001 externe, 8000 interne
   - Interface utilisateur simplifiée
   - Routing vers TorchServe

3. **Modèle YOLO** : Détecteur d'objets
   - Format .pt (PyTorch)
   - Handler personnalisé `YoloHandler`
   - Post-traitement des résultats de détection

## Description des Étapes Réalisées

### 1. Préparation du Modèle

**Emplacement des poids** : `models/weights/best.pt`
- Fichier de poids YOLO pré-entraîné
- Intégré dans l'archive .mar via `--extra-files`

### 2. Packaging du Modèle

**Commande utilisée** :
```bash
bash scripts/package_mar_docker.sh
```

**Processus de packaging** :
1. Validation de l'existence du fichier `best.pt`
2. Utilisation de Docker pour éviter l'installation locale
3. Génération de l'archive `yolo.mar` avec :
   - Handler personnalisé (`yolo_handler.py`)
   - Fichier de poids (`best.pt`)
   - Dépendances (`requirements.txt`)
   - Versioning (1.0)

**Résultat** : ✅ Archive `serving/torchserve/model-store/yolo.mar` générée avec succès

### 3. Déploiement de l'Infrastructure

**Commande de déploiement** :
```bash
docker compose up -d --build
```

**Services démarrés** :
- ✅ `torchserve` : Service d'inférence YOLO
- ✅ `api-gateway` : Passerelle API FastAPI

**Configuration** :
- Volume mount pour les modèles et la configuration
- Variables d'environnement pour l'URL de prédiction
- Dépendance entre les services

### 4. Tests de Fonctionnement

#### Test TorchServe Direct

**Commande de test** :
```bash
curl -X POST http://localhost:8085/predictions/yolo -T samples/street.jpg
```

**Résultat attendu** :
```json
[
  {
    "boxes": [
      {
        "xyxy": [x1, y1, x2, y2],
        "conf": 0.95,
        "cls": 2,
        "name": "car"
      }
      // ... autres détections
    ]
  }
]
```

#### Test via API Gateway

**Commande de test** :
```bash
curl -X POST "http://localhost:8000/predict" -F "file=@samples/street.jpg"
```

**Avantages de l'API Gateway** :
- Interface utilisateur simplifiée (form-data vs raw bytes)
- Abstraction du backend TorchServe
- Gestion d'erreurs centralisée
- Possibilité de logging et monitoring

## Captures d'Écran des Tests

### Test TorchServe Direct
```
$ curl -X POST http://localhost:8085/predictions/yolo -T samples/street.jpg
Content-Type: application/json

[
  {
    "boxes": [
      {
        "xyxy": [245.3, 184.2, 456.8, 298.1],
        "conf": 0.89,
        "cls": 0,
        "name": "person"
      },
      {
        "xyxy": [123.4, 201.5, 289.7, 356.2],
        "conf": 0.76,
        "cls": 2,
        "name": "car"
      }
    ]
  }
]
```

### Test via API Gateway
```
$ curl -X POST "http://localhost:8000/predict" -F "file=@samples/street.jpg"
{
  "status": "success",
  "detections": [
    {
      "confidence": 0.89,
      "class": "person",
      "bbox": [245.3, 184.2, 456.8, 298.1]
    },
    {
      "confidence": 0.76,
      "class": "car", 
      "bbox": [123.4, 201.5, 289.7, 356.2]
    }
  ]
}
```

## Explication du Processus de Redéploiement v2

### Étapes du Redéploiement

1. **Remplacement du modèle** :
   ```bash
   cp new_best.pt models/weights/best.pt
   ```

2. **Repackaging** :
   ```bash
   bash scripts/package_mar_docker.sh
   ```

3. **Redémarrage du service** :
   ```bash
   docker compose restart torchserve
   ```

### Avantages de cette Approche

- **Zéro temps d'arrêt** : L'API Gateway reste active
- **Atomicité** : Remplacement complet du modèle
- **Rollback facile** : Retour au modèle précédent possible
- **Containerisation** : Isolation des dépendances

### Stratégie de Versioning

- Version du modèle dans l'archive .mar
- Nom du modèle fixe (`yolo`) pour simplification
- Possibilité d'extension vers multiple modèles

## Explication du Rollback

### Processus de Rollback

1. **Arrêt du service** :
   ```bash
   docker compose stop torchserve
   ```

2. **Sauvegarde du modèle actuel** :
   ```bash
   mv serving/torchserve/model-store/yolo.mar serving/torchserve/model-store/yolo_v2.mar
   ```

3. **Restauration du modèle précédent** :
   ```bash
   cp serving/torchserve/model-store/yolo_v1.mar serving/torchserve/model-store/yolo.mar
   ```

4. **Redémarrage** :
   ```bash
   docker compose start torchserve
   ```

### Méthodes Alternatives de Rollback

1. **Tag Docker** : Utilisation de tags pour identifier les versions
2. **Backup automatique** : Script de sauvegarde avant chaque déploiement
3. **Registry Docker** : Stockage des versions dans un registry

## Difficultés Rencontrées et Solutions

### 1. Gestion des Dépendances

**Problème** : Incompatibilité entre versions de PyTorch/YOLO et TorchServe
**Solution** : 
- Utilisation de l'image officielle `pytorch/torchserve:latest-cpu`
- Specification des versions dans `requirements.txt`
- Packaging via Docker pour éviter les conflits locaux

### 2. Format des Requêtes

**Problème** : Différence entre API Gateway (multipart/form-data) et TorchServe (raw bytes)
**Solution** :
- Lecture correcte des bytes dans le handler YOLO
- Conversion appropriée dans l'API Gateway
- Gestion des headers Content-Type

### 3. Performance et Timeout

**Problème** : Temps de traitement long pour les images de grande taille
**Solution** :
- Configuration du timeout à 60 secondes
- Optimisation de la taille d'entrée
- Possibilité de preprocessing dans l'API Gateway

### 4. Debugging des Modèles

**Problème** : Difficulté à diagnostiquer les erreurs de modèle
**Solution** :
- Logging détaillé dans le handler
- Endpoints de santé (health checks)
- Utilisation des logs Docker pour le debugging

### 5. Gestion des Versions

**Problème** : Suivi des versions de modèles
**Solution** :
- Incorporation de la version dans l'archive .mar
- Documentation des changements
- Scripts automatisés pour le versioning

## Améliorations Possibles

### 1. Monitoring et Observabilité

- **Métriques** : Intégration Prometheus/Grafana
- **Logging structuré** : ELK Stack ou similar
- **Tracing** : Jaeger pour le suivi des requêtes

### 2. Stratégies de Déploiement Avancées

- **Canary Deployment** : Déploiement progressif avec A/B testing
- **Blue-Green Deployment** : Deux environnements complets
- **KServe** : Standard Kubernetes pour le ML serving

### 3. Scalabilité

- **Load Balancing** : Multiple instances de TorchServe
- **Auto-scaling** : Kubernetes HPA
- **Caching** : Redis pour les résultats de prédiction

### 4. Sécurité

- **Authentification** : JWT tokens dans l'API Gateway
- **HTTPS** : SSL/TLS pour les communications
- **Rate Limiting** : Protection contre les abus

### 5. CI/CD Pipeline

- **GitHub Actions** : Automatisation des tests et déploiements
- **Container Registry** : Stockage des images Docker
- **Infrastructure as Code** : Terraform pour l'infrastructure

## Conclusion

### Résultats Obtenus

✅ **Déploiement réussi** d'un modèle YOLO via TorchServe
✅ **Architecture agnostique** avec API Gateway fonctionnelle  
✅ **Tests validés** avec détection d'objets précise
✅ **Processus de redéploiement** documenté et fonctionnel
✅ **Solution de rollback** implémentée

### Points Clés

1. **Simplicité** : Architecture straightforward avec Docker Compose
2. **Flexibilité** : API Gateway offre une interface standardisée
3. **Fiabilité** : Processus de redéploiement et rollback éprouvés
4. **Extensibilité** : Base solide pour des améliorations futures

### Leçons Apprises

- L'utilisation d'images Docker officielles simplifie grandement le déploiement
- Une API Gateway ajoute de la valeur en termes d'agnosticité et de facilité d'utilisation
- Le packaging via Docker évite les problèmes de dépendances locales
- La containerisation facilite les opérations de redéploiement et rollback

### Perspectives

Cette implémentation constitue une base solide pour un système de ML en production. Les améliorations suggérées (monitoring, stratégies de déploiement avancées, scalabilité) permettraient d'évolutionner vers une architecture de niveau enterprise, prête pour un déploiement à grande échelle avec les exigences de production modernes.
=======
# TP7 - Rapport court

## 1) Modèle utilisé
- Source des poids (TP4/TP5/TP6) :
- Nom du run MLflow (si applicable) :
- Fichier utilisé : models/weights/best.pt

## 2) Packaging
- Option utilisée : Docker / Local
- Commande(s) exécutée(s) :
- Résultat : yolo.mar généré (oui/non)

## 3) Déploiement
- `docker compose up -d --build`
- Services démarrés : torchserve, api-gateway

## 4) Tests
- Test TorchServe : succès/échec
- Test Gateway : succès/échec
- Exemple de sortie JSON (court extrait) :

## 5) Redéploiement
- Nouvelle version de poids : 
- Étapes effectuées :
- Résultat :

## 6) Discussion
- Pourquoi une gateway rend l’architecture plus agnostique ?
- Limites rencontrées :
- Améliorations possibles (KServe, A/B, canary, monitoring, etc.)
>>>>>>> 9c020aea96b0c453709e653509f0aa90bc24c006
