#!/usr/bin/env python3
"""Recursos propios del prólogo: atlas de cuadros de pasillo y dos sonidos sintetizados.

Uso (desde la raíz): python3 tools/assets/gen_prologue_assets.py [posters] [audio]
Requiere Pillow y numpy; el audio además ffmpeg. Todo es obra propia (sin stock).
"""
import math
import subprocess
import sys
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
FONT = ROOT / "assets/fonts/Nunito.ttf"
CELL = (420, 540)
PAPER, INK, BLUE, ORANGE, GREY = "#EFEDE6", "#18222C", "#1F5FFF", "#FF8A1F", "#B9BBB6"
RATE = 44100

# Titular, bajada y departamento: la empresa conserva nombres (docs/11 §4). Invita, no explica.
POSTERS = [
    ("CONSERVAMOS\nNOMBRES.", "Cada registro, en su lugar.\nDesde el primer día.", "Archivo"),
    ("RECORDAR\nES VOLVER.", "Lo que guardamos por usted\nsiempre sabe el camino.", "Imagen Corporativa"),
    ("NINGÚN NOMBRE\nSE PIERDE AQUÍ.", "Verifique el suyo\nantes de retirarse.", "Custodia"),
    ("SU MEMORIA,\nNUESTRO ACTIVO.", "Usted trabaja.\nNosotros recordamos.", "Memoria Corporativa"),
    ("SIEMPRE EN EL\nORGANIGRAMA.", "Quien estuvo con nosotros\nsigue con nosotros.", "Capital Humano"),
    ("SIN REGISTRO,\nSE OLVIDA.", "Registre su jornada\nantes de salir.", "Control de Asistencia"),
]


def font(size, weight):
    from PIL import ImageFont
    face = ImageFont.truetype(str(FONT), size)
    try:
        face.set_variation_by_axes([weight])
    except OSError:
        pass
    return face


def motif(draw, index):
    """Motivo geométrico de cada cuadro, en la mitad superior (40..380 × 40..270)."""
    if index == 0:  # fichero: una ficha destaca
        for row in range(5):
            for col in range(7):
                x, y = 48 + col * 47, 48 + row * 44
                draw.rectangle([x, y, x + 38, y + 30], fill=BLUE if (row, col) == (2, 4) else GREY)
    elif index == 1:  # ondas que vuelven a un punto
        for i, radius in enumerate(range(108, 12, -24)):
            draw.ellipse([210 - radius, 155 - radius, 210 + radius, 155 + radius], outline=BLUE, width=7 - i)
        draw.ellipse([198, 143, 222, 167], fill=ORANGE)
    elif index == 2:  # lista de nombres: un renglón marcado
        for row in range(9):
            width = 180 + (row * 67) % 130
            draw.rectangle([56, 52 + row * 25, 56 + width, 62 + row * 25], fill=ORANGE if row == 5 else GREY)
    elif index == 3:  # barras que crecen
        for col in range(6):
            height = 40 + col * 34
            draw.rectangle([62 + col * 52, 268 - height, 98 + col * 52, 268], fill=BLUE if col < 5 else ORANGE)
    elif index == 4:  # organigrama con una casilla vacía
        draw.rectangle([180, 50, 240, 86], fill=BLUE)
        draw.line([210, 86, 210, 130], fill=INK, width=3)
        draw.line([90, 130, 330, 130], fill=INK, width=3)
        for col, x in enumerate((90, 210, 330)):
            draw.line([x, 130, x, 160], fill=INK, width=3)
            draw.rectangle([x - 30, 160, x + 30, 196], fill=BLUE)
            draw.line([x, 196, x, 226], fill=INK, width=3)
            if col == 2:
                draw.rectangle([x - 30, 226, x + 30, 262], outline=ORANGE, width=4)
            else:
                draw.rectangle([x - 30, 226, x + 30, 262], fill=GREY)
    else:  # hoja de asistencia con la firma pendiente
        draw.rectangle([120, 44, 300, 270], fill="#FFFFFF", outline=GREY, width=3)
        for row in range(5):
            draw.rectangle([142, 72 + row * 28, 278, 80 + row * 28], fill=GREY)
        draw.line([142, 240, 278, 240], fill=ORANGE, width=4)


def posters():
    from PIL import Image, ImageDraw
    atlas = Image.new("RGB", (CELL[0] * 3, CELL[1] * 2), PAPER)
    for index, (title, body, department) in enumerate(POSTERS):
        tile = Image.new("RGB", CELL, PAPER)
        draw = ImageDraw.Draw(tile)
        motif(draw, index)
        draw.multiline_text((40, 300), title, font=font(37, 900), fill=INK, spacing=2)
        draw.multiline_text((40, 396), body, font=font(21, 600), fill="#4A535B", spacing=4)
        draw.line([40, 478, 380, 478], fill=INK, width=2)
        draw.text((40, 490), "NOHO", font=font(26, 900), fill=BLUE)
        draw.text((380, 496), department, font=font(16, 700), fill=INK, anchor="ra")
        atlas.paste(tile, ((index % 3) * CELL[0], (index // 3) * CELL[1]))
    out = ROOT / "assets/textures/office_posters.png"
    atlas.save(out, optimize=True)
    print("OK", out)


def write_wav(path, samples):
    import numpy as np
    data = (np.clip(samples, -1.0, 1.0) * 32767).astype("<i2")
    with wave.open(str(path), "wb") as handle:
        handle.setnchannels(1)
        handle.setsampwidth(2)
        handle.setframerate(RATE)
        handle.writeframes(data.tobytes())


def band_noise(np, rng, count, low, high):
    """Ruido blanco filtrado en frecuencia; al ser periódico en `count`, el bucle no tiene costura."""
    spectrum = np.fft.rfft(rng.standard_normal(count))
    freqs = np.fft.rfftfreq(count, 1.0 / RATE)
    shape = 1.0 / (1.0 + (freqs / high) ** 4) * (freqs / (freqs + low))
    result = np.fft.irfft(spectrum * shape, count)
    return result / np.max(np.abs(result))


def audio():
    import numpy as np
    rng = np.random.default_rng(1142)
    # Ventilador de ordenador: aire (ruido de banda), giro grave y un leve vaivén. Bucle de 8 s.
    count = RATE * 8
    t = np.arange(count) / RATE
    air = band_noise(np, rng, count, 90.0, 900.0) * 0.55 + band_noise(np, rng, count, 1200.0, 3200.0) * 0.08
    whirr = 0.07 * np.sin(TAU * 118.0 * t) + 0.035 * np.sin(TAU * 236.0 * t) + 0.02 * np.sin(TAU * 59.0 * t)
    fan = (air * (1.0 + 0.06 * np.sin(TAU * 0.25 * t)) + whirr) * 0.5
    wav = ROOT / "builds/_fan.wav"
    wav.parent.mkdir(exist_ok=True)
    write_wav(wav, fan)
    out = ROOT / "assets/audio/ambient/computer_fan_loop.ogg"
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(wav), "-c:a", "libvorbis", "-q:a", "4", str(out)], check=True)
    wav.unlink()
    print("OK", out)

    # Balastro que falla: zumbido de red a ráfagas y chasquidos del cebador. 2,4 s.
    count = int(RATE * 2.4)
    t = np.arange(count) / RATE
    buzz = np.sign(np.sin(TAU * 100.0 * t)) * 0.25 + np.sin(TAU * 200.0 * t) * 0.2 + band_noise(np, rng, count, 2000.0, 6000.0) * 0.12
    gate = np.zeros(count)
    for start, length in ((0.05, 0.16), (0.3, 0.07), (0.48, 0.3), (0.95, 0.06), (1.12, 0.22), (1.5, 0.05), (1.72, 0.34)):
        a, b = int(start * RATE), int((start + length) * RATE)
        gate[a:b] = 1.0
        click = np.exp(-np.arange(400) / 40.0) * rng.standard_normal(400)
        buzz[a:a + 400] += click * 0.9
    smooth = np.convolve(gate, np.ones(220) / 220.0, mode="same")
    flicker = buzz * smooth * np.minimum(1.0, (2.4 - t) / 0.25) * 0.6
    out = ROOT / "assets/audio/sfx/light_flicker.wav"
    write_wav(out, flicker)
    print("OK", out)


TAU = math.tau

if __name__ == "__main__":
    jobs = sys.argv[1:] or ["posters", "audio"]
    if "posters" in jobs:
        posters()
    if "audio" in jobs:
        audio()
