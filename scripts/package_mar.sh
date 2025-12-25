#!/usr/bin/env bash
set -e

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

WEIGHTS="$ROOT_DIR/models/weights/best.pt"
MODEL_STORE="$ROOT_DIR/serving/torchserve/model-store"
HANDLER="$ROOT_DIR/serving/torchserve/yolo_handler.py"
REQS="$ROOT_DIR/serving/torchserve/requirements.txt"

mkdir -p "$MODEL_STORE"

if [ ! -f "$WEIGHTS" ]; then
  echo "ERREUR: Poids introuvables: $WEIGHTS"
  echo "Copiez votre best.pt dans models/weights/ avant de packager."
  exit 1
fi

echo "Packaging TorchServe .mar (local)..."
torch-model-archiver   --model-name yolo   --version 1.0   --handler "$HANDLER"   --extra-files "$WEIGHTS"   --requirements-file "$REQS"   --export-path "$MODEL_STORE"   --force

echo "OK: $MODEL_STORE/yolo.mar généré."
