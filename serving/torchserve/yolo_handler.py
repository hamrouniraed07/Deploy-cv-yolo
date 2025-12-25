import io
import os
from PIL import Image

from ts.torch_handler.base_handler import BaseHandler
from ultralytics import YOLO


class YoloHandler(BaseHandler):
    """
    Handler minimal pour servir un modèle YOLOv8 via TorchServe.
    Le poids `best.pt` est embarqué dans l’archive .mar via --extra-files.
    """

    def initialize(self, ctx):
        self.manifest = ctx.manifest
        props = ctx.system_properties
        model_dir = props.get("model_dir")

        # Poids inclus dans le model_dir par torch-model-archiver
        weights = os.path.join(model_dir, "best.pt")
        if not os.path.exists(weights):
            # Fallback: premier .pt trouvé
            for f in os.listdir(model_dir):
                if f.endswith(".pt"):
                    weights = os.path.join(model_dir, f)
                    break

        self.model = YOLO(weights)
        self.initialized = True

    def preprocess(self, data):
        req = data[0]
        image_bytes = req.get("body") or req.get("data")

        if not image_bytes:
            # pour éviter le "silence"
            raise ValueError("No image bytes found in request (expected 'body' or 'data').")

        import io
        from PIL import Image
        img = Image.open(io.BytesIO(image_bytes)).convert("RGB")
        return img


    def inference(self, inputs):
        results = self.model(inputs, verbose=False)
        return results

    def postprocess(self, inference_output):
        outputs = []
        for r in inference_output:
            boxes = []
            for b in r.boxes:
                boxes.append({
                    "xyxy": [float(x) for x in b.xyxy[0].tolist()],
                    "conf": float(b.conf[0]),
                    "cls": int(b.cls[0]),
                    "name": r.names[int(b.cls[0])]
                })
            outputs.append({"boxes": boxes})
        return outputs
