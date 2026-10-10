#!/usr/bin/env python3
"""Audio pre-renderizado de la entidad y los Niveles 2-4 (encargo 06).

Genera cada sonido con la API de efectos de ElevenLabs (text-to-sound-effects)
y, si la API falla o no hay saldo, lo sintetiza con numpy; el posproceso
(mono 44,1 kHz, recorte, normalizado, bucle sin costura, Vorbis) es siempre con
ffmpeg. Toda reverberacion/distorsion queda horneada en el archivo (regla dura 5).

Uso (desde la raiz del proyecto):
    python3 tools/assets/gen_level_audio.py                 # genera lo que falte
    python3 tools/assets/gen_level_audio.py brand_sting     # solo esos nombres
    python3 tools/assets/gen_level_audio.py --force         # regenera todo
    python3 tools/assets/gen_level_audio.py --list          # lista la tabla
    python3 tools/assets/gen_level_audio.py --mark-loops    # loop=true en los .ogg.import
    python3 tools/assets/gen_level_audio.py --synth-only    # no llama a la API

Los crudos quedan en builds/audio_raw/ (ignorado por git) para no volver a pedir
lo ya generado. La clave ELEVENLABSkey se lee de .env y nunca se imprime.
"""
from __future__ import annotations

import json
import math
import subprocess
import sys
import time
import urllib.error
import urllib.request
import wave
import zlib
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[2]
RAW = ROOT / "builds/audio_raw"
RATE = 44100
API_URL = "https://api.elevenlabs.io/v1/sound-generation"
TAU = math.tau

# ---------------------------------------------------------------------------
# Tabla de sonidos. (ruta sin extension, segundos, loop, pico dBFS, prompt,
# etiqueta de sintesis, numero de variantes, extension)
# ---------------------------------------------------------------------------
SOUNDS = [
    # --- entidad ---
    ("entity/bones_step", 0.6, False, -3.0,
     "Single footstep: hollow dry bones crunching and cracking on laminate flooring, "
     "a rustle of shredded paper, horror creature, close and dry", "step", 4, ".wav"),
    ("entity/breath_loop", 6.0, True, -3.0,
     "Slow labored monstrous breathing made of low-frequency white noise, deep inhale "
     "and heavy exhale, continuous, seamless loopable ambience", "breath", 1, ".ogg"),
    ("entity/listen_breath_loop", 6.0, True, -3.0,
     "DERIVED:entity/breath_loop", "breath_near", 1, ".ogg"),
    ("entity/screech", 2.5, False, -3.0,
     "Extreme dissonant shriek blending a corporate fire alarm siren with an Aztec death "
     "whistle, piercing, metallic, terrifying, close", "screech", 1, ".ogg"),
    ("entity/static_shriek", 1.5, False, -3.0,
     "Low frequency radio static shriek that cuts off abruptly into dead silence, harsh "
     "buzzing electric, sudden stop", "static", 1, ".ogg"),
    ("entity/chase_loop", 8.0, True, -3.0,
     "Relentless horror chase loop: deep pulsing bass, fast clattering bone footsteps, "
     "a distant fire alarm, tense, seamless loopable", "chase", 1, ".ogg"),
    # --- ambientes ---
    ("ambient/level2_hall_loop", 20.0, True, -9.0,
     "Vast concrete warehouse hall ambience: slow wind, very distant church bells, faint "
     "ozone static, enormous reverberant empty space, seamless loopable", "hall", 1, ".ogg"),
    ("ambient/copal_crackle_loop", 8.0, True, -9.0,
     "Crackling copal incense embers and candle flames, gentle close fire crackle, warm, "
     "seamless loopable", "crackle", 1, ".ogg"),
    ("ambient/level3_tunnel_loop", 20.0, True, -9.0,
     "Flooded dark tunnel ambience: water dripping, still shallow water lapping, resonant "
     "metal pipe hum, long echo, seamless loopable", "tunnel", 1, ".ogg"),
    ("ambient/level4_abyss_loop", 24.0, True, -9.0,
     "Deep abyssal cave ambience: low subterranean wind with a slow distorted distant "
     "electric guitar drone, corrupted nostalgia, seamless loopable", "abyss", 1, ".ogg"),
    ("ambient/alarm_red_loop", 8.0, True, -9.0,
     "Emergency klaxon alarm loop, booming impact, groaning metal about to give way, red "
     "alert climax, seamless loopable", "alarm", 1, ".ogg"),
    ("ambient/neon_buzz_loop", 6.0, True, -9.0,
     "Electrical buzzing hum of a faulty neon tube, crackling, mains hum, seamless loopable",
     "buzz", 1, ".ogg"),
    ("ambient/office_silence_loop", 10.0, True, -9.0,
     "Almost silent empty corporate office room tone, faint air conditioning, very quiet "
     "hum, seamless loopable", "roomtone", 1, ".ogg"),
    ("ambient/brand_sting", 3.0, False, -9.0,
     "Warm clean short brand signature sting, two soft chime notes, calm and reassuring, "
     "crisp, no game music", "chime", 1, ".ogg"),
    # --- efectos ---
    ("sfx/footstep_water", 0.5, False, -3.0,
     "Single footstep in ankle deep water, splash and slosh, wet, close, horror",
     "step_water", 6, ".wav"),
    ("sfx/splash_run", 0.7, False, -3.0,
     "Sharp loud water splash from running through a shallow puddle, aggressive, wet",
     "splash", 3, ".wav"),
    ("sfx/footstep_concrete", 0.4, False, -3.0,
     "Single shoe footstep on concrete in a huge cavernous room, short with a long reverb "
     "tail, dry", "step_concrete", 6, ".wav"),
    ("sfx/flashlight_fail", 0.8, False, -3.0,
     "Electric failure: deep electromagnetic roar, powering down buzz, short circuit zap",
     "emroar", 1, ".wav"),
    ("sfx/fall_sting", 1.5, False, -3.0,
     "Falling into a void: rushing wind with a deep reversed muffled impact, descending "
     "horror sting", "fall", 1, ".ogg"),
    ("sfx/ofrenda_collapse", 3.0, False, -3.0,
     "A pyramid of metal filing cabinets collapsing and crashing down, clatter of steel "
     "drawers, heavy metallic avalanche", "collapse", 1, ".ogg"),
    ("sfx/clay_crack", 2.5, False, -3.0,
     "A wall of dry clay cracking and fracturing, crumbling earth, deep splits, dusty",
     "crack", 1, ".ogg"),
    ("sfx/water_drain", 4.0, False, -3.0,
     "A large amount of water draining down a huge sinkhole, gurgling vortex, rushing drain",
     "drain", 1, ".ogg"),
    ("sfx/door_oak_open", 2.0, False, -3.0,
     "Heavy old oak door slowly creaking open, deep wood groan, ancient stiff hinges",
     "door", 1, ".ogg"),
    ("sfx/petal_reveal", 0.8, False, -3.0,
     "Warm soft whisper of flower petals, gentle airy whoosh, delicate shimmer",
     "petal", 1, ".wav"),
    ("sfx/letter_ignite", 2.0, False, -3.0,
     "Candles lighting one after another, successive soft flame whooshes and crackle, warm",
     "ignite", 1, ".ogg"),
]


# ---------------------------------------------------------------------------
# Utilidades de audio (numpy)
# ---------------------------------------------------------------------------
def rms_env(x: np.ndarray, win: int) -> np.ndarray:
    """Envolvente RMS suavizada."""
    kernel = np.ones(win) / win
    return np.convolve(np.abs(x), kernel, mode="same")


def trim(x: np.ndarray, thr_db: float = -55.0, pad_ms: float = 15.0) -> np.ndarray:
    """Recorta silencio de los extremos si la cola supera 0,2 s (si no, no toca)."""
    peak = float(np.max(np.abs(x))) if x.size else 0.0
    if peak <= 0.0:
        return x
    mask = np.abs(x) > peak * (10.0 ** (thr_db / 20.0))
    idx = np.flatnonzero(mask)
    if idx.size == 0:
        return x
    first, last = int(idx[0]), int(idx[-1]) + 1
    if first < 0.2 * RATE and (len(x) - last) < 0.2 * RATE:
        return x
    pad = int(pad_ms * RATE / 1000.0)
    return x[max(0, first - pad):min(len(x), last + pad)]


def fade(x: np.ndarray, ms_in: float = 5.0, ms_out: float = 20.0) -> np.ndarray:
    """Fundido lineal de entrada/salida para evitar chasquidos."""
    y = x.astype(np.float32).copy()
    a = min(int(ms_in * RATE / 1000.0), len(y))
    b = min(int(ms_out * RATE / 1000.0), len(y))
    if a > 1:
        y[:a] *= np.linspace(0.0, 1.0, a, dtype=np.float32)
    if b > 1:
        y[-b:] *= np.linspace(1.0, 0.0, b, dtype=np.float32)
    return y


def seamless(x: np.ndarray, cf_ms: float = 40.0) -> np.ndarray:
    """Bucle sin costura: fundido cruzado de potencia constante de la cola al inicio."""
    cf = min(int(cf_ms * RATE / 1000.0), len(x) // 4)
    if cf < 16:
        return x
    ramp = np.linspace(0.0, 1.0, cf, endpoint=False, dtype=np.float32)
    up = np.sin(ramp * (math.pi / 2.0))
    down = np.cos(ramp * (math.pi / 2.0))
    y = x.astype(np.float32).copy()
    y[:cf] = x[:cf] * up + x[-cf:] * down
    return y[:-cf]


def normalize(x: np.ndarray, peak_db: float) -> np.ndarray:
    """Lleva el pico al nivel pedido."""
    peak = float(np.max(np.abs(x))) if x.size else 0.0
    if peak <= 0.0:
        return x
    return (x.astype(np.float32) * (10.0 ** (peak_db / 20.0) / peak)).astype(np.float32)


def write_wav(path: Path, x: np.ndarray) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    data = (np.clip(x, -1.0, 1.0) * 32767.0).astype("<i2")
    with wave.open(str(path), "wb") as handle:
        handle.setnchannels(1)
        handle.setsampwidth(2)
        handle.setframerate(RATE)
        handle.writeframes(data.tobytes())


def encode_ogg(wav: Path, out: Path) -> None:
    out.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(wav),
                    "-c:a", "libvorbis", "-q:a", "4", str(out)], check=True)


def decode_to_mono(path: Path) -> np.ndarray:
    """Lee un WAV mono 16 bit a float."""
    with wave.open(str(path), "rb") as handle:
        assert handle.getsampwidth() == 2, "solo 16 bit"
        raw = handle.readframes(handle.getnframes())
        channels = handle.getnchannels()
    data = np.frombuffer(raw, dtype="<i2").astype(np.float32) / 32768.0
    if channels > 1:
        data = data.reshape(-1, channels).mean(axis=1)
    return data.astype(np.float32)


def peak_db(path: Path) -> float:
    """Pico real del archivo ya codificado (dBFS)."""
    out = subprocess.run(["ffmpeg", "-i", str(path), "-af", "volumedetect", "-f", "null", "-"],
                         capture_output=True, text=True).stderr
    for line in out.splitlines():
        if "max_volume:" in line:
            return float(line.split("max_volume:")[1].split("dB")[0].strip())
    return -99.0


# ---------------------------------------------------------------------------
# ElevenLabs
# ---------------------------------------------------------------------------
def read_key() -> str:
    for line in (ROOT / ".env").read_text().splitlines():
        if line.startswith("ELEVENLABSkey"):
            return line.split("=", 1)[1].strip()
    raise SystemExit("Falta ELEVENLABSkey en .env")


def api_raw(name: str, prompt: str, seconds: float, loop: bool, force: bool) -> Path | None:
    """Devuelve el WAV crudo mono, descargando el PCM de la API si hace falta."""
    raw_pcm = RAW / f"{name.replace('/', '__')}.pcm"
    raw_wav = RAW / f"{name.replace('/', '__')}.wav"
    if raw_pcm.exists() and not force:
        if raw_wav.exists():
            return raw_wav
    if force or not raw_pcm.exists():
        body = json.dumps({
            "text": prompt,
            "duration_seconds": max(0.5, min(30.0, seconds)),
            "prompt_influence": 0.5,
            "loop": bool(loop),
        }).encode()
        req = urllib.request.Request(
            API_URL + "?output_format=pcm_44100", data=body,
            headers={"xi-api-key": read_key(), "Content-Type": "application/json"})
        last: Exception | None = None
        for attempt in range(3):
            try:
                with urllib.request.urlopen(req, timeout=180) as resp:
                    raw_pcm.parent.mkdir(parents=True, exist_ok=True)
                    raw_pcm.write_bytes(resp.read())
                last = None
                break
            except Exception as exc:  # noqa: BLE001
                last = exc
                time.sleep(2.0 * (attempt + 1))
        if last is not None:
            print(f"  API fallo ({name}): {type(last).__name__} {last}")
            return None
    if not raw_pcm.exists():
        return None
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-f", "s16le", "-ar", "44100",
                    "-ac", "2", "-i", str(raw_pcm), "-ac", "1", "-ar", "44100",
                    str(raw_wav)], check=True)
    return raw_wav


# ---------------------------------------------------------------------------
# Sintesis de respaldo (numpy)
# ---------------------------------------------------------------------------
def band_noise(rng: np.random.Generator, n: int, low: float, high: float) -> np.ndarray:
    spec = np.fft.rfft(rng.standard_normal(n))
    freqs = np.fft.rfftfreq(n, 1.0 / RATE)
    shape = 1.0 / (1.0 + (freqs / high) ** 4) * (freqs / (freqs + low))
    out = np.fft.irfft(spec * shape, n)
    return (out / np.max(np.abs(out))).astype(np.float32)


def decay(n: int, tau: float, attack: float = 0.002) -> np.ndarray:
    t = np.arange(n) / RATE
    env = np.exp(-t / max(tau, 1e-3))
    a = max(1, int(attack * RATE))
    env[:a] *= np.linspace(0.0, 1.0, a)
    return env.astype(np.float32)


def tone(n: int, f: float, phase: float = 0.0) -> np.ndarray:
    return np.sin(TAU * f * np.arange(n) / RATE + phase).astype(np.float32)


def synth(tag: str, seconds: float, loop: bool, seed: int) -> np.ndarray:
    """Sintesis de respaldo; suficiente si la API no esta disponible."""
    rng = np.random.default_rng(seed)
    n = int(round(seconds * RATE))
    t = np.arange(n) / RATE
    if tag == "step":
        x = band_noise(rng, n, 60, 300) * decay(n, 0.05)
        x += band_noise(rng, n, 1500, 6000) * decay(n, 0.03) * 0.4
        for _ in range(14):
            i = int(rng.uniform(0, 0.9) * n)
            x[i:i + 300] += decay(300, 0.006) * rng.standard_normal(300) * 0.5
    elif tag in ("step_water", "splash"):
        spl = band_noise(rng, n, 200, 7000) * decay(n, 0.12 if tag == "splash" else 0.08)
        pop = band_noise(rng, n, 80, 400) * decay(n, 0.09)
        x = spl * 0.9 + pop
        for _ in range(8):
            i = int(rng.uniform(0, 0.7) * n)
            x[i:i + 200] += tone(200, rng.uniform(300, 900)) * decay(200, 0.02) * 0.3
    elif tag == "step_concrete":
        x = band_noise(rng, n, 80, 400) * decay(n, 0.04)
        x += band_noise(rng, n, 800, 4000) * decay(n, 0.02) * 0.5
        x += band_noise(rng, n, 200, 2000) * decay(n, 0.35) * 0.25
    elif tag in ("breath", "breath_near"):
        env = 0.5 + 0.5 * np.sin(TAU * (3.0 / seconds) * t)
        x = band_noise(rng, n, 40, 500) * env
        if tag == "breath_near":
            d = int(0.09 * RATE)
            y = x.copy()
            y[d:] += x[:-d] * 0.5
            x = y * 0.9
    elif tag == "screech":
        a = np.sign(tone(n, 720)) * 0.3
        b = tone(n, 1130 + 40 * np.sin(TAU * 6.0 * t)) * 0.4
        env = np.minimum(1.0, t / 0.05) * (1.0 - np.clip((t - 1.8) / 0.7, 0, 1))
        x = (a + b + band_noise(rng, n, 2000, 9000) * 0.3) * env
    elif tag == "static":
        x = band_noise(rng, n, 150, 2500)
        gate = (np.sin(TAU * 47.0 * t) > -0.2).astype(np.float32)
        x *= gate
        cut = int(min(n, 1.25 * RATE))
        x[cut:] = 0.0
        x *= decay(n, 0.6)
    elif tag == "chase":
        pulse = 0.5 + 0.5 * np.sin(TAU * 2.5 * t)
        x = tone(n, 55) * pulse * 0.5 + tone(n, 110) * pulse * 0.2
        x += band_noise(rng, n, 60, 400) * (0.4 + 0.3 * pulse)
        for k in range(28):
            i = int(k / 28 * n)
            x[i:i + 900] += decay(900, 0.02) * rng.standard_normal(900) * 0.35
        x += (tone(n, 840) + tone(n, 620)) * 0.05
    elif tag == "hall":
        x = band_noise(rng, n, 30, 300) * (0.6 + 0.4 * np.sin(TAU * 0.1 * t))
        x += band_noise(rng, n, 300, 1800) * 0.25
        for f in (196.0, 262.0, 330.0):
            x += tone(n, f) * 0.05 * (0.5 + 0.5 * np.sin(TAU * 0.07 * t + f))
    elif tag == "crackle":
        x = band_noise(rng, n, 40, 250) * 0.4
        for _ in range(120):
            i = int(rng.uniform(0, 1) * n)
            ln = int(rng.uniform(0.002, 0.02) * RATE)
            x[i:i + ln] += decay(ln, 0.01) * rng.standard_normal(ln) * rng.uniform(0.2, 1.0)
    elif tag == "tunnel":
        x = band_noise(rng, n, 30, 250) * 0.5
        x += band_noise(rng, n, 200, 1500) * 0.2
        for _ in range(60):
            i = int(rng.uniform(0, 1) * n)
            x[i:i + 400] += tone(400, rng.uniform(600, 1600)) * decay(400, 0.03) * 0.25
        x += tone(n, 118) * 0.06
    elif tag == "abyss":
        x = band_noise(rng, n, 20, 180) * (0.5 + 0.5 * np.sin(TAU * 0.05 * t))
        g = (tone(n, 82) * 0.4 + tone(n, 82.7) * 0.4 + tone(n, 123) * 0.2)
        x += np.tanh(g * 1.8) * 0.25 * (0.5 + 0.5 * np.sin(TAU * 0.04 * t))
    elif tag == "alarm":
        klax = np.sign(tone(n, 440)) * (np.sin(TAU * 1.6 * t) > 0)
        x = klax * 0.35 + tone(n, 220) * 0.25
        x += band_noise(rng, n, 40, 300) * 0.4
        for i in (int(0.2 * RATE), int(4.2 * RATE)):
            x[i:i + 4000] += decay(4000, 0.15) * rng.standard_normal(4000) * 0.5
    elif tag == "buzz":
        x = np.sign(tone(n, 60)) * 0.25 + tone(n, 120) * 0.2 + tone(n, 180) * 0.1
        x += band_noise(rng, n, 2000, 8000) * 0.15
        x *= 0.9 + 0.1 * np.sin(TAU * 0.7 * t)
    elif tag == "roomtone":
        x = band_noise(rng, n, 20, 500) * 0.25 + tone(n, 100) * 0.03
    elif tag == "chime":
        x = np.zeros(n, dtype=np.float32)
        for f, st in ((523.25, 0.0), (783.99, 0.45)):
            i = int(st * RATE)
            ln = n - i
            x[i:] += (tone(ln, f) + 0.4 * tone(ln, f * 2)) * decay(ln, 0.5) * 0.5
    elif tag == "emroar":
        x = band_noise(rng, n, 30, 300) * decay(n, 0.4) + tone(n, 50) * decay(n, 0.5) * 0.4
        x += band_noise(rng, n, 2000, 6000) * decay(n, 0.05) * 0.3
    elif tag == "fall":
        sweep = band_noise(rng, n, 200, 5000)
        env = np.concatenate([np.linspace(0.2, 1.0, n // 2), np.linspace(1.0, 0.1, n - n // 2)])
        x = sweep * env.astype(np.float32)
        x += tone(n, 60) * decay(n, 0.08) * 0.5
    elif tag == "collapse":
        x = band_noise(rng, n, 40, 600) * 0.4
        for _ in range(60):
            i = int(rng.uniform(0, 0.95) * n)
            f = rng.uniform(300, 2500)
            x[i:i + 3000] += tone(3000, f) * decay(3000, 0.1) * rng.uniform(0.1, 0.5)
        x += band_noise(rng, n, 60, 400) * decay(n, 0.6)
    elif tag == "crack":
        x = band_noise(rng, n, 100, 3000) * decay(n, 0.08)
        for _ in range(10):
            i = int(rng.uniform(0, 0.8) * n)
            x[i:i + 1500] += decay(1500, 0.03) * rng.standard_normal(1500) * 0.6
        x += band_noise(rng, n, 40, 250) * decay(n, 0.7) * 0.3
    elif tag == "drain":
        x = band_noise(rng, n, 60, 2500) * (0.6 + 0.4 * np.sin(TAU * 2.0 * t))
        x *= np.linspace(1.0, 0.4, n).astype(np.float32)
        for _ in range(20):
            i = int(rng.uniform(0, 0.8) * n)
            x[i:i + 300] += tone(300, rng.uniform(150, 500)) * decay(300, 0.05) * 0.3
    elif tag == "door":
        f = 90 + 60 * np.clip(t / seconds, 0, 1)
        x = tone(n, 0) * 0
        phase = np.cumsum(TAU * f / RATE)
        x += np.sin(phase).astype(np.float32) * decay(n, 0.9) * 0.4
        x += band_noise(rng, n, 200, 1200) * decay(n, 0.5) * 0.3
    elif tag == "petal":
        x = band_noise(rng, n, 800, 6000) * decay(n, 0.15)
    elif tag == "ignite":
        x = np.zeros(n, dtype=np.float32)
        for k in range(5):
            i = int(k / 5 * n * 0.9)
            ln = min(2500, n - i)
            x[i:i + ln] += band_noise(rng, ln, 300, 5000) * decay(ln, 0.08) * 0.6
    else:
        x = band_noise(rng, n, 40, 2000) * 0.5
    return x.astype(np.float32)


# ---------------------------------------------------------------------------
# Derivados
# ---------------------------------------------------------------------------
def derive_breath_near(mono: np.ndarray) -> np.ndarray:
    """La misma respiracion, muy cerca y con eco de conducto metalico."""
    x = mono.astype(np.float32)
    # Eco metalico del conducto (dos rebotes con filtro).
    for delay, gain in ((0.075, 0.55), (0.17, 0.3)):
        d = int(delay * RATE)
        y = x.copy()
        y[d:] += x[:-d] * gain
        x = y
    duct = band_noise(np.random.default_rng(7), len(x), 150, 2500)
    x = x * 0.92 + x * duct * 0.25
    return x


# ---------------------------------------------------------------------------
# Proceso por sonido
# ---------------------------------------------------------------------------
def expand() -> list[dict]:
    """Expande la tabla a una lista de trabajos (una entrada por archivo)."""
    jobs: list[dict] = []
    for path, seconds, loop, peak, prompt, tag, variants, ext in SOUNDS:
        for i in range(1, variants + 1):
            suffix = "".join([""] if variants == 1 else [f"_{i:02d}"])
            jobs.append({
                "base": path, "out": f"{path}{suffix}{ext}", "seconds": seconds,
                "loop": loop, "peak": peak, "prompt": prompt, "tag": tag,
                "seed": zlib.crc32(f"{path}{i}".encode()), "variant": i,
            })
    return jobs


def process(job: dict, force: bool, synth_only: bool) -> tuple[str, str]:
    """Genera y escribe un archivo. Devuelve (ruta final, origen)."""
    out = ROOT / "assets/audio" / job["out"]
    out.parent.mkdir(parents=True, exist_ok=True)
    if out.exists() and not force:
        return job["out"], "existente"

    prompt: str = job["prompt"]
    origin = "sintesis"
    x: np.ndarray | None = None

    if prompt.startswith("DERIVED:"):
        src_name = prompt.split(":", 1)[1]
        src = ROOT / "assets/audio" / f"{src_name}.ogg"
        tmp = RAW / f"_src_{src_name.replace('/', '__')}.wav"
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(src), "-ac", "1",
                        "-ar", "44100", str(tmp)], check=True)
        x = derive_breath_near(decode_to_mono(tmp))
        origin = "derivado de breath_loop"
    elif not synth_only:
        raw = api_raw(f"{job['base']}_{job['variant']:02d}" if job["variant"] > 1 else job["base"],
                      prompt, job["seconds"], job["loop"], force)
        if raw is not None:
            x = decode_to_mono(raw)
            origin = "API"

    if x is None:
        x = synth(job["tag"], job["seconds"], job["loop"], job["seed"])

    if job["loop"]:
        x = trim(x, thr_db=-60.0)
        x = seamless(x)
        x = normalize(x, job["peak"])
    else:
        # Recorta cola; nunca rellena con silencio (se informa la duracion real).
        x = trim(x)
        want = int(round(job["seconds"] * RATE))
        if x.size > want:
            x = x[:want]
        x = normalize(x, job["peak"])
        x = fade(x, 3.0, 25.0 if job["seconds"] > 0.6 else 8.0)

    if out.suffix == ".wav":
        write_wav(out, x)
    else:
        # Vorbis desvia el pico unos decimas de dB: re-codifica hasta clavarlo.
        tmp = RAW / (job["out"].replace("/", "__") + ".wav")
        gain_db = 0.0
        for _ in range(4):
            write_wav(tmp, x * (10.0 ** (gain_db / 20.0)))
            encode_ogg(tmp, out)
            delta = job["peak"] - peak_db(out)
            if abs(delta) <= 0.35:
                break
            gain_db += delta
    return job["out"], origin


# ---------------------------------------------------------------------------
# Marcado de bucles en los .import
# ---------------------------------------------------------------------------
def mark_loops() -> None:
    loops = {j["out"] for j in expand() if j["loop"] and j["out"].endswith(".ogg")}
    for rel in sorted(loops):
        imp = ROOT / "assets/audio" / (rel + ".import")
        if not imp.exists():
            print("  sin .import:", rel)
            continue
        text = imp.read_text()
        if "loop=true" in text:
            continue
        if "loop=false" in text:
            imp.write_text(text.replace("loop=false", "loop=true"))
            print("  loop=true ->", rel)
        else:
            print("  sin parametro loop:", rel)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
def main() -> None:
    args = sys.argv[1:]
    force = "--force" in args
    synth_only = "--synth-only" in args
    if "--mark-loops" in args:
        mark_loops()
        return
    if "--list" in args:
        for j in expand():
            print(f"{j['out']:44s} {j['seconds']:.1f}s loop={str(j['loop']):5s} "
                  f"pico={j['peak']:.0f}dB tag={j['tag']}")
        return
    names = [a for a in args if not a.startswith("--")]
    jobs = expand()
    if names:
        jobs = [j for j in jobs
                if any(n in j["base"] or n in j["out"] for n in names)]
    RAW.mkdir(parents=True, exist_ok=True)
    origins: dict[str, str] = {}
    for job in jobs:
        try:
            rel, origin = process(job, force, synth_only)
        except Exception as exc:  # noqa: BLE001
            print(f"ERROR {job['out']}: {type(exc).__name__} {exc}")
            continue
        origins[rel] = origin
        size = (ROOT / "assets/audio" / rel).stat().st_size
        print(f"OK {rel:44s} {origin:20s} {size / 1024.0:6.1f} KiB")
    log = RAW / "origins.json"
    previous: dict[str, str] = {}
    if log.exists():
        try:
            previous = json.loads(log.read_text())
        except json.JSONDecodeError:
            previous = {}
    for rel, origin in origins.items():
        if origin == "existente" and rel in previous:
            continue  # conserva el origen real de la corrida anterior
        previous[rel] = origin
    log.write_text(json.dumps(previous, indent=2, ensure_ascii=False))
    print(f"\n{len(jobs)} archivos procesados. Origenes en {log}")


if __name__ == "__main__":
    main()
