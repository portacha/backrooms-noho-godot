#!/usr/bin/env python3
"""Texturas de los Niveles 2–4 y el final (encargo 07) — procesado reproducible.

Lee las fuentes de `builds/asset_staging/` (stock CC0 de ambientCG y las
superficies generadas con `gen_image.py`), las adapta a la dirección de arte
(tono oscuro y desaturado, mate, sin negros aplastados) y escribe los PNG
finales en `assets/textures/`. También produce las vistas 2×2 de control en
`builds/tex_preview/`.

Uso (desde la raíz): python3 tools/assets/gen_level_textures.py
Requiere Pillow y numpy. No descarga nada por sí solo.
"""
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
STOCK = ROOT / "builds/asset_staging/ambientcg"
GEN = ROOT / "builds/asset_staging/gen"
TEX = ROOT / "assets/textures"
PREV = ROOT / "builds/tex_preview"

arr = lambda im: np.asarray(im.convert("RGB")).astype(np.float32) / 255.0
def to_img(a: np.ndarray) -> Image.Image:
    return Image.fromarray((np.clip(a, 0.0, 1.0) * 255.0 + 0.5).astype(np.uint8))

def stock(name: str, size: int = 1024) -> Image.Image:
    im = Image.open(STOCK / name / f"{name}_1K-JPG_Color.jpg").convert("RGB")
    return im.resize((size, size), Image.LANCZOS) if im.width != size else im

def load(path: Path) -> Image.Image:
    return Image.open(path).convert("RGB")

def gray(a: np.ndarray) -> np.ndarray:
    return a @ np.array([0.2126, 0.7152, 0.0722], dtype=np.float32)

def desat(a: np.ndarray, amount: float) -> np.ndarray:
    """amount 0 = gris, 1 = color original."""
    g = gray(a)[..., None]
    return g + (a - g) * amount

def tint(a: np.ndarray, rgb) -> np.ndarray:
    return a * (np.array(rgb, dtype=np.float32) / 255.0)

def gamma(a: np.ndarray, g: float) -> np.ndarray:
    return np.power(np.clip(a, 0.0, 1.0), g)

def periodic_noise(h: int, w: int, feature_px: float, seed: int,
                   feature_y_px: float | None = None) -> np.ndarray:
    """Ruido suave periódico (0..1): al venir de una FFT circular, el mosaico no tiene costura.

    `feature_y_px` permite estirar el ruido en vertical (jirones, churretes).
    """
    fy_px = feature_y_px if feature_y_px is not None else feature_px
    rng = np.random.default_rng(seed)
    f = np.fft.fft2(rng.standard_normal((h, w)))
    fy = np.fft.fftfreq(h)[:, None]
    fx = np.fft.fftfreq(w)[None, :]
    lp = np.exp(-(fy ** 2) / (2.0 * (1.0 / fy_px) ** 2) - (fx ** 2) / (2.0 * (1.0 / feature_px) ** 2))
    field = np.real(np.fft.ifft2(f * lp))
    field -= field.min()
    peak = field.max()
    return field / peak if peak > 1e-6 else field

def blur_mask(mask: np.ndarray, radius: float) -> np.ndarray:
    im = Image.fromarray((np.clip(mask, 0.0, 1.0) * 255).astype(np.uint8))
    im = im.filter(ImageFilter.GaussianBlur(radius))
    return np.asarray(im).astype(np.float32) / 255.0

def save_png(im: Image.Image, name: str, limit_bytes: int = 1_500_000) -> int:
    """Guarda en assets/textures/<name>.png respetando el límite de 1,5 MB."""
    out = TEX / f"{name}.png"
    im.save(out, optimize=True)
    size = out.stat().st_size
    if size > limit_bytes:
        q = im.convert("RGB").quantize(colors=192, method=Image.MEDIANCUT, dither=Image.NONE)
        q.save(out, optimize=True)
        size = out.stat().st_size
    if size > limit_bytes:
        im = im.resize((max(1, im.width * 3 // 4), max(1, im.height * 3 // 4)), Image.LANCZOS)
        im.save(out, optimize=True)
        size = out.stat().st_size
    print(f"{name}.png {im.size} {size} B")
    return size

def preview(name: str) -> None:
    """Vista 2×2 para comprobar costuras; compone sobre gris para ver el alfa."""
    im = Image.open(TEX / f"{name}.png")
    if im.mode == "RGBA":
        bg = Image.new("RGB", im.size, (60, 60, 64))
        bg.paste(im, (0, 0), im)
        cell = bg
    else:
        cell = im.convert("RGB")
    sheet = Image.new("RGB", (cell.width * 2, cell.height * 2))
    for i in range(4):
        sheet.paste(cell, ((i % 2) * cell.width, (i // 2) * cell.height))
    if max(sheet.size) > 1400:
        k = 1400 / max(sheet.size)
        sheet = sheet.resize((int(sheet.width * k), int(sheet.height * k)), Image.LANCZOS)
    sheet.save(PREV / f"{name}.png", optimize=True)
    print(f"preview {name}")


# --- superficies de stock adaptadas -----------------------------------------

def concrete_brutalist() -> None:
    a = arr(stock("Concrete034"))
    a = desat(a, 0.55)
    a = gamma(a, 1.45) * np.array([0.62, 0.63, 0.65], dtype=np.float32)
    im = to_img(a)
    d = ImageDraw.Draw(im, "RGBA")
    # Agujeros de anclaje del encofrado: rejilla regular con sombra y leve reborde.
    for gy in range(2):
        for gx in range(2):
            x = 256 + gx * 512
            y = 256 + gy * 512
            d.ellipse([x - 13, y - 13, x + 13, y + 13], fill=(18, 17, 16, 235))
            d.arc([x - 13, y - 13, x + 13, y + 13], 200, 330, fill=(150, 148, 144, 90), width=3)
    im = im.filter(ImageFilter.GaussianBlur(0.4)).resize((1024, 1024), Image.LANCZOS)
    save_png(im, "concrete_brutalist")


def concrete_floor() -> None:
    a = arr(stock("Concrete023", 512))
    a = desat(a, 0.6)
    a = gamma(a, 1.45) * np.array([0.68, 0.69, 0.70], dtype=np.float32)
    # Manchas de humedad.
    stain = periodic_noise(512, 512, 90.0, 71)
    a *= (0.78 + 0.22 * stain)[..., None]
    im = to_img(a).filter(ImageFilter.GaussianBlur(0.5))
    d = ImageDraw.Draw(im)
    # Juntas tenues de la losa.
    d.line([(256, 0), (256, 512)], fill=(52, 52, 54), width=3)
    d.line([(0, 256), (512, 256)], fill=(52, 52, 54), width=3)
    im = im.filter(ImageFilter.GaussianBlur(0.6))
    save_png(im, "concrete_floor")


def concrete_ceiling_dark() -> None:
    a = arr(stock("Concrete044D", 512))
    a = desat(a, 0.5)
    a = gamma(a, 1.75) * np.array([0.5, 0.5, 0.54], dtype=np.float32)
    im = to_img(a)
    d = ImageDraw.Draw(im, "RGBA")
    for i in range(1, 4):
        p = i * 128
        d.line([(p, 0), (p, 512)], fill=(6, 6, 8, 170), width=4)
        d.line([(0, p), (512, p)], fill=(6, 6, 8, 170), width=4)
    for cy in range(4):
        for cx in range(4):
            x, y = cx * 128 + 64, cy * 128 + 64
            d.rectangle([x - 44, y - 44, x + 44, y + 44], fill=(0, 0, 0, 45))
            d.rectangle([x - 44, y - 44, x + 44, y - 42], fill=(90, 90, 96, 40))
    im = im.filter(ImageFilter.GaussianBlur(1.2))
    save_png(im, "concrete_ceiling_dark")


def adobe_dark() -> None:
    a = arr(stock("Ground036", 512))
    a = desat(a, 0.35)
    a = gamma(a, 1.5) * np.array([0.72, 0.5, 0.4], dtype=np.float32)
    im = to_img(a)
    return_im = im.filter(ImageFilter.GaussianBlur(0.4))
    save_png(return_im, "adobe_dark")


def volcanic_stone() -> None:
    a = arr(stock("PavingStones046", 512))
    a = desat(a, 0.45)
    a = gamma(a, 1.75) * np.array([0.66, 0.42, 0.37], dtype=np.float32)
    # Poros del tezontle.
    pore = periodic_noise(512, 512, 5.0, 33)
    a *= (0.78 + 0.44 * pore)[..., None]
    im = to_img(a).filter(ImageFilter.GaussianBlur(0.5))
    save_png(im, "volcanic_stone")


def tunnel_concrete_wet() -> None:
    a = arr(stock("Concrete048"))
    a = desat(a, 0.5)
    a = gamma(a, 1.6) * np.array([0.62, 0.63, 0.65], dtype=np.float32)
    # Humedad: manchas y una banda de marea suave que envuelve en vertical.
    wet = periodic_noise(1024, 1024, 160.0, 12)
    a *= (0.72 + 0.28 * wet)[..., None]
    tide = 0.5 + 0.5 * np.cos(np.linspace(0, 2 * np.pi, 1024))[:, None]
    a *= (0.86 + 0.14 * tide)[..., None]
    im = to_img(a)
    # Churretes de óxido verticales (envueltos con módulo para no romper el mosaico).
    rng = np.random.default_rng(5)
    d = ImageDraw.Draw(im, "RGBA")
    for _ in range(26):
        x = int(rng.integers(0, 1024))
        y = int(rng.integers(0, 900))
        h = int(rng.integers(60, 220))
        w = int(rng.integers(2, 6))
        for k in range(w):
            xx = (x + k) % 1024
            if xx < w and x + k >= 1024:  # evita el salto de columna al envolver
                continue
            d.line([(xx, y), (xx, y + h)], fill=(78, 44, 22, 70), width=1)
    im = im.filter(ImageFilter.GaussianBlur(1.0))
    save_png(im, "tunnel_concrete_wet")


def tunnel_floor_silt() -> None:
    a = arr(stock("Ground106", 512))
    a = desat(a, 0.4)
    a = gamma(a, 2.0) * np.array([0.6, 0.5, 0.42], dtype=np.float32)
    sheen = periodic_noise(512, 512, 120.0, 44)
    a *= (0.8 + 0.25 * sheen)[..., None]
    im = to_img(a).filter(ImageFilter.GaussianBlur(0.5))
    save_png(im, "tunnel_floor_silt")


def duct_metal() -> None:
    a = arr(stock("Metal063", 512))
    a = desat(a, 0.5)
    a = gamma(a, 1.4) * np.array([0.66, 0.69, 0.72], dtype=np.float32)
    im = to_img(a)
    d = ImageDraw.Draw(im, "RGBA")
    # Costuras de chapa y remaches en filas.
    for x in (0, 256, 512):
        d.line([(x, 0), (x, 512)], fill=(40, 44, 48, 120), width=2)
    for ry in range(6):
        y = 40 + ry * 86
        for rx in range(7):
            x = 24 + rx * 74
            d.ellipse([x - 4, y - 4, x + 4, y + 4], fill=(90, 96, 100, 160))
            d.arc([x - 4, y - 4, x + 4, y + 4], 180, 300, fill=(20, 22, 24, 150), width=2)
    im = im.filter(ImageFilter.GaussianBlur(0.6))
    save_png(im, "duct_metal")


def cavern_rock() -> None:
    a = arr(stock("Rock058"))
    a = desat(a, 0.55)
    a = gamma(a, 1.7) * np.array([0.52, 0.54, 0.6], dtype=np.float32)
    im = to_img(a).filter(ImageFilter.GaussianBlur(0.4))
    save_png(im, "cavern_rock")


def oak_planks() -> None:
    a = arr(stock("Planks037A", 512))
    a = desat(a, 0.72)
    a = gamma(a, 1.3) * np.array([0.62, 0.5, 0.4], dtype=np.float32)
    im = to_img(a).filter(ImageFilter.GaussianBlur(0.4))
    save_png(im, "oak_planks")


# --- superficies generadas ---------------------------------------------------

def water_marigold() -> None:
    a = arr(load(GEN / "water_marigold.png"))
    a = desat(a, 0.9)
    a = gamma(a, 1.25) * np.array([0.9, 0.82, 0.74], dtype=np.float32)
    save_png(to_img(a), "water_marigold")


def clay_black() -> None:
    a = arr(load(GEN / "clay_black.png"))
    a = desat(a, 0.45)
    a = gamma(a, 1.15) * np.array([0.82, 0.8, 0.86], dtype=np.float32)
    save_png(to_img(a), "clay_black")


def papel_picado() -> None:
    # Recorte de una columna del diseño generado (bandas rosa/morado/naranja) y
    # repetición en horizontal: los bordes caen en los huecos negros entre
    # banderines, así que el mosaico cierra sin costura y sin duplicados translúcidos.
    raw = arr(load(GEN / "papel_picado_raw.png"))
    strip = raw[:, 0:341]
    out = np.concatenate([strip, strip, strip, strip], axis=1)[:, :1024]
    out = desat(out, 0.98)
    out = gamma(out, 1.05)
    save_png(to_img(out), "papel_picado")


# --- derivadas con Pillow ----------------------------------------------------

def wallpaper_peeling() -> None:
    wall = desat(arr(load(TEX / "backrooms_wallpaper.png")), 0.68)
    wall = gamma(wall, 1.2) * np.array([0.9, 0.88, 0.8], dtype=np.float32)
    adobe = arr(load(TEX / "adobe_dark.png"))
    if adobe.shape[:2] != wall.shape[:2]:
        adobe = arr(Image.fromarray((adobe * 255).astype(np.uint8)).resize(
            (wall.shape[1], wall.shape[0]), Image.LANCZOS))
    mask = periodic_noise(wall.shape[0], wall.shape[1], 74.0, 909, feature_y_px=280.0)
    torn = np.clip((mask - 0.6) * 5.0, 0.0, 1.0)
    torn = blur_mask(torn, 3.0)
    torn = np.clip((torn - 0.18) * 1.6, 0.0, 1.0)
    shadow = blur_mask(torn, 6.0) - torn
    out = wall * (1.0 - torn[..., None]) + np.clip(adobe * 1.35, 0.0, 1.0) * torn[..., None]
    out *= (1.0 - 0.35 * np.clip(shadow, 0.0, 1.0))[..., None]
    save_png(to_img(out), "wallpaper_peeling")


def office_carpet_torn() -> None:
    carpet = arr(load(TEX / "office_carpet.png"))
    mask = periodic_noise(512, 512, 55.0, 404)
    torn = np.clip((mask - 0.55) * 6.0, 0.0, 1.0)
    torn = blur_mask(torn, 2.0)
    torn = np.clip((torn - 0.3) * 1.6, 0.0, 1.0)
    under = np.array([0.10, 0.09, 0.08], dtype=np.float32)
    out = carpet * (1.0 - torn[..., None]) + under * torn[..., None]
    out *= (1.0 - 0.4 * blur_mask(torn, 5.0))[..., None]
    im = to_img(out)
    # Pétalos sueltos sobre la alfombra (polvo de cempasúchil, docs/02).
    petals = Image.open(TEX / "petals.png").convert("RGBA")
    rng = np.random.default_rng(77)
    for _ in range(8):
        s = int(rng.integers(46, 80))
        p = petals.resize((s, s), Image.LANCZOS).rotate(float(rng.integers(0, 360)))
        px = int(rng.integers(0, 512 - s))
        py = int(rng.integers(0, 512 - s))
        im.paste(p, (px, py), p)
    save_png(im, "office_carpet_torn")


def petals_path() -> None:
    """Sendero de pétalos con alfa: se estampa `petals.png` en una banda central,
    con copias desplazadas para que el mosaico cierre en las cuatro costuras."""
    petals = Image.open(TEX / "petals.png").convert("RGBA")
    canvas = Image.new("RGBA", (512, 1024), (0, 0, 0, 0))
    rng = np.random.default_rng(31)
    for _ in range(320):
        cx = 256 + int(np.clip(rng.normal(0.0, 95.0), -215.0, 215.0))
        cy = int(rng.integers(0, 1024))
        s = int(rng.integers(58, 142))
        p = petals.resize((s, s), Image.LANCZOS).rotate(float(rng.integers(0, 360)))
        for dx in (-512, 0, 512):
            for dy in (-1024, 0, 1024):
                canvas.paste(p, (cx - s // 2 + dx, cy - s // 2 + dy), p)
    out = TEX / "petals_path.png"
    canvas.save(out, optimize=True)
    print(f"petals_path.png {canvas.size} {out.stat().st_size} B")


def painting_grey() -> None:
    im = load(TEX / "painting_a.png")
    g = Image.fromarray((gray(arr(im)) * 255.0 + 0.5).astype(np.uint8), "L")
    # Gris ceniza: se sube un poco el nivel para que el shader no aplaste.
    g = g.point(lambda v: int(min(255, v * 0.85 + 22)))
    out = g.convert("RGB")
    out.save(TEX / "painting_grey.png", optimize=True)
    print(f"painting_grey.png {out.size} {(TEX / 'painting_grey.png').stat().st_size} B")


TEXTURES = {
    "concrete_brutalist": concrete_brutalist,
    "concrete_floor": concrete_floor,
    "concrete_ceiling_dark": concrete_ceiling_dark,
    "adobe_dark": adobe_dark,
    "volcanic_stone": volcanic_stone,
    "tunnel_concrete_wet": tunnel_concrete_wet,
    "tunnel_floor_silt": tunnel_floor_silt,
    "duct_metal": duct_metal,
    "cavern_rock": cavern_rock,
    "oak_planks": oak_planks,
    "water_marigold": water_marigold,
    "clay_black": clay_black,
    "papel_picado": papel_picado,
    "wallpaper_peeling": wallpaper_peeling,
    "office_carpet_torn": office_carpet_torn,
    "petals_path": petals_path,
    "painting_grey": painting_grey,
}


def main() -> None:
    import sys
    want = sys.argv[1:] or list(TEXTURES)
    total = 0
    for name in want:
        TEXTURES[name]()
        preview(name)
    total = sum(f.stat().st_size for f in TEX.glob("*.png"))
    print(f"total assets/textures: {total} B")
    print("---")


if __name__ == "__main__":
    main()
