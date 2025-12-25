# TP7 - Déploiement d’un modèle CV YOLO avec TorchServe (CPU)

Ce TP utilise **l’image officielle prête à l’emploi** :
`pytorch/torchserve:latest-cpu`

## Objectifs
- Déployer un modèle YOLO tiny via TorchServe.
- Orchestrer le serving avec Docker Compose.
- Introduire une architecture agnostique grâce à un API Gateway.
- Simuler un redéploiement (v1 → v2) et un rollback simple.
- Packager le modèle **sans installation locale** grâce à Docker (option recommandée).

## Pré-requis
- Avoir un fichier de poids YOLO (idéalement `best.pt`) issu des TPs précédents.
- Docker + Docker Compose.

## Démarrage rapide

### 1) Placer les poids
Copiez votre meilleur modèle ici :
```
models/weights/best.pt
```

### 2) Générer l’archive TorchServe

#### Option A (recommandée) : packaging via Docker
Linux/macOS:
```bash
bash scripts/package_mar_docker.sh
```

#### Option B : packaging local (si vous préférez)
```bash
pip install -r requirements-dev.txt
bash scripts/package_mar.sh
```

Windows PowerShell:
```powershell
docker run --rm `
  -v ${PWD}:/workspace `
  -w /workspace `
  salahgo/torchserve:latest-cpu `
  torch-model-archiver `
    --model-name yolo `
    --version 1.0 `
    --handler /workspace/serving/torchserve/yolo_handler.py `
    --extra-files /workspace/models/weights/best.pt `
    --requirements-file /workspace/serving/torchserve/requirements.txt `
    --export-path /workspace/serving/torchserve/model-store `
    --force
```

### 3) Lancer l’infrastructure
```bash
docker compose up -d --build
```

### 4) Tester

#### Test direct TorchServe
```bash
curl -X POST http://localhost:8085/predictions/yolo -T samples/street.jpg
```

#### Test via API Gateway
```bash
curl -X POST "http://localhost:8000/predict" -F "file=@samples/street.jpg"
```

## Redéploiement (simulation)
1) Remplacez `models/weights/best.pt`
2) Repackagez :
```bash
bash scripts/package_mar_docker.sh
```
3) Redémarrez :
```bash
docker compose restart torchserve
```

## Livrables
- Lien vers votre fork.
- `reports/tp7_report.md` complété.
- Captures de tests d’inférence.
