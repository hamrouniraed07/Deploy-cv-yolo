import os
import requests
from fastapi import FastAPI, UploadFile, File, HTTPException

app = FastAPI(title="YOLO Gateway", version="1.0")

TORCHSERVE_PREDICT_URL = os.getenv(
    "TORCHSERVE_PREDICT_URL",
    "http://localhost:8085/predictions/yolo"
)

@app.get("/health")
def health():
    return {"status": "ok", "backend": "torchserve"}

@app.post("/predict")
async def predict(file: UploadFile = File(...)):
    try:
        img_bytes = await file.read()
        resp = requests.post(
            TORCHSERVE_PREDICT_URL,
            data=img_bytes,
            headers={"Content-Type": "application/octet-stream"},
            timeout=60
        )
        if resp.status_code != 200:
            raise HTTPException(status_code=502, detail=resp.text)
        return resp.json()
    except requests.RequestException as e:
        raise HTTPException(status_code=503, detail=str(e))
