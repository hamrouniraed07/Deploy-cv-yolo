#!/usr/bin/env bash
set -e

echo "Test TorchServe..."
curl -s -X POST http://localhost:8085/predictions/yolo -T samples/street.jpg | head -c 300
echo
echo "Test API Gateway..."
curl -s -X POST "http://localhost:8000/predict" -F "file=@samples/street.jpg" | head -c 300
echo
echo "OK"
