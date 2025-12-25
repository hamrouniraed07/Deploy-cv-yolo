$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

$Weights = Join-Path $Root "models\weights\best.pt"
$ModelStore = Join-Path $Root "serving\torchserve\model-store"
$Handler = Join-Path $Root "serving\torchserve\yolo_handler.py"
$Reqs = Join-Path $Root "serving\torchserve\requirements.txt"

New-Item -ItemType Directory -Force -Path $ModelStore | Out-Null

if (!(Test-Path $Weights)) {
  Write-Host "ERREUR: Poids introuvables: $Weights"
  Write-Host "Copiez votre best.pt dans models\weights\ avant de packager."
  exit 1
}

Write-Host "Packaging TorchServe .mar (local)..."
torch-model-archiver `
  --model-name yolo `
  --version 1.0 `
  --handler $Handler `
  --extra-files $Weights `
  --requirements-file $Reqs `
  --export-path $ModelStore `
  --force

Write-Host "OK: yolo.mar généré dans $ModelStore"
