# Créditos de assets

Registro obligatorio de cada asset externo o generado (regla dura 8, `docs/09`).

Para adquirir modelos y texturas seguir [docs/16](../docs/16-assets-stock.md):
objetos importantes/visibles se modelan a medida; utilería secundaria se busca en
stock. Registrar aquí únicamente recursos integrados, no resultados de búsqueda
ni muestras descargadas a staging. Conservar la licencia y los hashes de origen
y derivados en `assets/provenance/<nombre>/` cuando sea redistribuible.

Para cada modelo o textura de stock registrar **archivo final, título, proveedor,
autor, URL de ficha, licencia con versión y URL, fecha y modificaciones**. CC BY
requiere atribución que acompañe también la distribución del juego. Las evidencias
de compra y fuentes con redistribución restringida permanecen privadas; citar una
referencia interna sin credenciales ni datos personales. Plantilla en `docs/16` §7.

## Audio

| Archivo | Origen | Licencia | Notas |
|---|---|---|---|
| `audio/sfx/footstep_shoe_01–06.wav` | ElevenLabs Sound Effects (`eleven_text_to_sound_v2`), generado 2026-10-09 | Generado; uso comercial según el plan de ElevenLabs | Zapato plano de suela de goma sobre suelo vinílico. Una toma de 10 s recortada en 6 pasos y normalizada a −5 dB de pico con ffmpeg |
| `audio/sfx/breath_heavy_loop.ogg` | ElevenLabs Sound Effects, generado 2026-10-09 | Ídem | Hiperventilación, bucle de 8 s, mono |
| `audio/ambient/office_hum_loop.ogg` | ElevenLabs Sound Effects, generado 2026-10-09 | Ídem | Zumbido de monitores del prólogo, bucle de 20 s, +23 dB de ganancia |
| `audio/sfx/paper_pickup.wav` | ElevenLabs Sound Effects, generado 2026-10-09 | Ídem | Hoja de papel al abrir un documento. Toma de 1,5 s recortada a 0,9 s, mono, +8 dB con ffmpeg |
| `audio/ambient/fluorescent_hum_loop.ogg` | ElevenLabs Sound Effects, generado 2026-10-09 | Ídem | Zumbido de fluorescentes del Nivel 1, bucle de 20 s, +12 dB |
| `audio/ambient/painting_tone_loop.ogg` | ElevenLabs Sound Effects, generado 2026-10-09 | Ídem | Tono grave del cuadro, bucle de 12 s |
| `audio/ambient/candles_loop.ogg` | ElevenLabs Sound Effects, generado 2026-10-09 | Ídem | Veladoras del altar, bucle de 10 s, comprimido |
| `audio/sfx/fall.ogg` | ElevenLabs Sound Effects, generado 2026-10-09 | Ídem | Caída por el cuadro: inhalación + *whoosh* + golpe, 5 s |
| `audio/sfx/letter_swell.ogg` | ElevenLabs Sound Effects, generado 2026-10-09 | Ídem | Recogida de letra: veladoras + *swell*, 5 s |
| `audio/sfx/flashlight_click.wav`, `distant_knock.wav`, `monitor_off.wav` | ElevenLabs Sound Effects, generado 2026-10-09 | Ídem | Interruptor de linterna, golpe lejano, monitor que se apaga |
| `audio/sfx/footstep_far_01–06.wav` | Derivado de `footstep_shoe_01–06.wav` | Ídem | Pasos espejo: paso bajo 700 Hz + eco pre-renderizado con ffmpeg |
| `audio/ambient/computer_fan_loop.ogg`, `audio/sfx/light_flicker.wav` | Propios: sintetizados con `tools/assets/gen_prologue_assets.py` (numpy + ffmpeg), 2026-10-09 | Propia del proyecto | Ventilador de los terminales (bucle de 8 s sin costura) y balastro que falla (2,4 s), prólogo |

## Texturas e imágenes

| Archivo | Origen | Licencia | Notas |
|---|---|---|---|
| `textures/office_wall.png`, `office_carpet.png`, `office_ceiling.png` | OpenAI Images (`gpt-image-2`), generado 2026-10-09 con `tools/assets/gen_image.py` | Generado; uso comercial según los términos de OpenAI | Oficina del prólogo. Vueltas repetibles (fundido con copia desplazada) y reducidas a 512 px |
| `textures/backrooms_wallpaper.png`, `backrooms_carpet.png`, `backrooms_ceiling.png` | Ídem | Ídem | Nivel 1. Mismo proceso |
| `textures/painting_a.png` | Ídem | Ídem | El cuadro del prólogo, 1024×683 |
| `textures/screen_lock.png` | Ídem | Ídem | Pantalla bloqueada 23:47 |
| `textures/office_posters.png` | Propio: dibujado con `tools/assets/gen_prologue_assets.py` (Pillow, tipografía Nunito), 2026-10-09 | Propia del proyecto | Atlas 3 × 2 de los cuadros de pasillo del prólogo, 1260×1080 |
| `textures/petals.png` | Ídem | Ídem | Pétalos de cempasúchil; el fondo negro se convirtió en canal alfa |

## Modelos 3D

`models/ceiling_fixture.glb`: luminaria propia modelada con `tools/blender/build_models.py`
(2026-10-09), 292 triángulos. Marco plegado, rejilla antideslumbrante y pestañas de
cierre; origen en el plafón. Se integra en la paleta horneada del prólogo y Nivel 1.
Difusor estriado mediante `shaders/light_panel.gdshader`. Licencia propia del proyecto.

| Archivo | Origen | Licencia | Notas |
|---|---|---|---|
| `models/*.glb` (44 modelos) | Propios: generados por script con Blender 5.2 (`tools/blender/build_models.py`), 2026-10-09 | Propia del proyecto | Low-poly de color plano, sin texturas; 673 KiB en total |

## Tipografías

| Archivo | Origen | Licencia | Notas |
|---|---|---|---|
| `fonts/Nunito.ttf` | Google Fonts (Vernon Adams y colaboradores) | SIL Open Font License 1.1 (`Nunito-OFL.txt`) | Tipografía general: redonda, variable en peso |
| `fonts/VT323-Regular.ttf` | Google Fonts (Peter Hull) | SIL OFL 1.1 (`VT323-OFL.txt`) | Texto de los terminales (bloc de notas en monitor viejo) |
| `fonts/Caveat.ttf` | Google Fonts (Impallari Type) | SIL OFL 1.1 (`Caveat-OFL.txt`) | Voz íntima: notas adhesivas y listas manuscritas |
