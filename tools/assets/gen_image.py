#!/usr/bin/env python3
"""Genera una imagen con la API de OpenAI y, opcionalmente, la vuelve repetible (tileable).

Uso: gen_image.py <salida.png> <tamaño_final> <seamless 0|1> <prompt> [tamaño_api]
Lee `openaiKey` del `.env` de la raíz del repositorio.
"""
import base64, io, json, os, sys, urllib.request
import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
MODEL = os.environ.get("IMAGE_MODEL", "gpt-image-2")


def api_key() -> str:
    for line in open(os.path.join(ROOT, ".env")):
        if line.startswith("openaiKey="):
            return line.split("=", 1)[1].strip().strip("\"'")
    raise SystemExit("openaiKey no encontrado en .env")


def generate(prompt: str, size: str) -> Image.Image:
    body = json.dumps({"model": MODEL, "prompt": prompt, "size": size, "quality": "medium", "n": 1}).encode()
    req = urllib.request.Request(
        "https://api.openai.com/v1/images/generations", data=body,
        headers={"Authorization": f"Bearer {api_key()}", "Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=300) as res:
        data = json.load(res)
    return Image.open(io.BytesIO(base64.b64decode(data["data"][0]["b64_json"]))).convert("RGB")


def make_seamless(img: Image.Image, blend: float = 0.18) -> Image.Image:
    """Funde la imagen con una copia desplazada medio mosaico para borrar las costuras."""
    a = np.asarray(img).astype(np.float32)
    h, w = a.shape[:2]
    rolled = np.roll(a, (h // 2, w // 2), axis=(0, 1))
    y = np.minimum(np.arange(h), np.arange(h)[::-1]) / (h * blend)
    x = np.minimum(np.arange(w), np.arange(w)[::-1]) / (w * blend)
    m = np.clip(np.minimum.outer(y, x), 0.0, 1.0)
    m = (m * m * (3.0 - 2.0 * m))[..., None]
    return Image.fromarray((a * m + rolled * (1.0 - m)).astype(np.uint8))


def main() -> None:
    out, final, seamless, prompt = sys.argv[1], int(sys.argv[2]), sys.argv[3] == "1", sys.argv[4]
    size = sys.argv[5] if len(sys.argv) > 5 else "1024x1024"
    img = generate(prompt, size)
    if seamless:
        img = make_seamless(img)
    if final and img.width != final:
        img = img.resize((final, round(img.height * final / img.width)), Image.LANCZOS)
    img.save(out)
    print("ok", out, img.size)


if __name__ == "__main__":
    main()
