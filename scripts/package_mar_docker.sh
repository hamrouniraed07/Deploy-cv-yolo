#!/usr/bin/env bash
set -e

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

WEIGHTS="$ROOT_DIR/models/weights/best.pt"
MODEL_STORE="$ROOT_DIR/serving/torchserve/model-store"

mkdir -p "$MODEL_STORE"

if [ ! -f "$WEIGHTS" ]; then
  echo "ERREUR: Poids introuvables: $WEIGHTS"
  echo "Copiez votre best.pt dans models/weights/ avant de packager."
  exit 1
fi

echo "Packaging TorchServe .mar via Docker (image CPU)..."

docker run --rm   -v "$ROOT_DIR":/workspace   -w /workspace   pytorch/torchserve:latest-cpu   torch-model-archiver     --model-name yolo     --version 1.0     --handler /workspace/serving/torchserve/yolo_handler.py     --extra-files /workspace/models/weights/best.pt     --requirements-file /workspace/serving/torchserve/requirements.txt     --export-path /workspace/serving/torchserve/model-store     --force

echo "OK: serving/torchserve/model-store/yolo.mar généré."
