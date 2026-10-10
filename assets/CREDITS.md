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

## Niveles 2–4 y final — texturas (2026-10-09)

| Archivo | Origen | Licencia | Notas |
|---|---|---|---|
| `textures/concrete_brutalist.png` | Stock CC0 — ambientCG `Concrete034` (`https://ambientcg.com/a/Concrete034`), variante `1K-JPG` | CC0-1.0 (`https://docs.ambientcg.com/license/`) | Concreto con huellas de encofrado de tabla; se añadieron agujeros de anclaje. Desaturado y oscurecido. 1024×1024. SHA-256 salida `4525d3b1…6f5e61` |
| `textures/concrete_floor.png` | Stock CC0 — ambientCG `Concrete023` (`https://ambientcg.com/a/Concrete023`) | CC0-1.0 | Losa pulida: manchas de humedad y juntas tenues añadidas. Oscurecido. 512×512. SHA-256 `da77e7df…a2e9823a` |
| `textures/concrete_ceiling_dark.png` | Stock CC0 — ambientCG `Concrete044D` (`https://ambientcg.com/a/Concrete044D`) | CC0-1.0 | Losa casetonada muy oscura; artesonado dibujado sobre hormigón. 512×512. SHA-256 `b55dd572…3fa7b80f` |
| `textures/adobe_dark.png` | Stock CC0 — ambientCG `Ground036` (`https://ambientcg.com/a/Ground036`) | CC0-1.0 | Barro/ tierra con paja; teñido a adobe oscuro y desaturado. 512×512. SHA-256 `125607ed…fcde0892` |
| `textures/volcanic_stone.png` | Stock CC0 — ambientCG `PavingStones046` (`https://ambientcg.com/a/PavingStones046`) | CC0-1.0 | Sillares recolorados a tezontle/basalto oscuro con poros añadidos. 512×512. SHA-256 `b1a6382b…158527a4` |
| `textures/wallpaper_peeling.png` | Derivada — `backrooms_wallpaper.png` (OpenAI) + `adobe_dark.png` (ambientCG, arriba) | Generado + CC0 | Papel tapiz del N1 desprendido a jirones, con adobe a la vista. Oscurecido/desaturado. 512×512. SHA-256 `3b228f1f…2b3efc23` |
| `textures/tunnel_concrete_wet.png` | Stock CC0 — ambientCG `Concrete048` (`https://ambientcg.com/a/Concrete048`) | CC0-1.0 | Concreto mojado de túnel con churretes de óxido y banda de marea. 1024×1024. SHA-256 `725ef831…21b606e` |
| `textures/tunnel_floor_silt.png` | Stock CC0 — ambientCG `Ground106` (`https://ambientcg.com/a/Ground106`) | CC0-1.0 | Limo oscuro de fondo inundado. 512×512. SHA-256 `bd1b9df5…d9da549` |
| `textures/water_marigold.png` | Generada — OpenAI Images (`gpt-image-2`), 2026-10-09 con `tools/assets/gen_image.py` | Generado; uso comercial según los términos de OpenAI | Vista cenital de agua turbia cubierta de cempasúchil; opaca, repetible. 1024×1024. SHA-256 `45c781e8…147aeae` |
| `textures/clay_black.png` | Ídem | Ídem | Barro negro oaxaqueño bruñido con grecas y calados. 1024×1024. SHA-256 `a3910b23…9f1c54c` |
| `textures/duct_metal.png` | Stock CC0 — ambientCG `Metal063` (`https://ambientcg.com/a/Metal063`) | CC0-1.0 | Chapa galvanizada; remaches y costuras dibujados. 512×512. SHA-256 `6fafca48…ad404972` |
| `textures/cavern_rock.png` | Stock CC0 — ambientCG `Rock058` (`https://ambientcg.com/a/Rock058`) | CC0-1.0 | Roca de caverna oscura. 1024×1024. SHA-256 `5c56dbba…3820aaec` |
| `textures/office_carpet_torn.png` | Derivada — `office_carpet.png` (OpenAI) + `petals.png` (propia) | Generado + propia | Alfombra rasgada con pétalos (islas del N4). 512×512. SHA-256 `d31eee5e…88f8bcdc` |
| `textures/papel_picado.png` | Generada — OpenAI Images (`gpt-image-2`), 2026-10-09 | Generado; términos de OpenAI | Papel picado magenta/morado/naranja con calados; opaco, calado en negro. Recorte de una columna del diseño y repetición para cerrar el mosaico. 1024×1024. SHA-256 `23930d16…c588322` |
| `textures/petals_path.png` | Derivada — `petals.png` (propia) estampada | Propia del proyecto | Sendero de pétalos de cempasúchil con alfa, 512×1024. SHA-256 `f9ea9545…dbf0c1e` |
| `textures/oak_planks.png` | Stock CC0 — ambientCG `Planks037A` (`https://ambientcg.com/a/Planks037A`) | CC0-1.0 | Tablones de roble antiguo oscurecidos. 512×512. SHA-256 `ba43a5ef…cf5dbf1c` |
| `textures/painting_grey.png` | Derivada — `painting_a.png` (OpenAI), con Pillow | Generado; términos de OpenAI | El cuadro del final sin color, gris ceniza; mismo tamaño 1024×683. SHA-256 `5c5e95cf…effa70d9` |

Atribución: los recursos de ambientCG son **CC0-1.0** (no exigen atribución;
se acredita por transparencia). Las imágenes generadas con OpenAI no requieren
atribución; se registran por trazabilidad. Los hashes SHA-256 de los mapas de
color de origen (JPG 1K) y de la procedencia quedan en
`builds/asset_staging/ambientcg/<ID>/provenance.json`.

**Autoría**: stock de **ambientCG** (proyecto ambientCG; cada ficha del sitio
identifica a su autor; los materiales usados no declaran autoría individual en la
API v3 y su licencia es CC0-1.0). Superficies generadas y derivadas: **OpenAI
Images (`gpt-image-2`)** y **obra propia del proyecto** (`petals.png`); sin
atribución obligatoria.

## Niveles 2–4 y entidad — audio (2026-10-09)


- **Herramienta**: ElevenLabs Sound Effects, modelo `eleven_text_to_sound_v2`
  (`POST /v1/sound-generation`, `output_format=pcm_44100`).
- **Fecha**: 2026-10-09.
- **Licencia**: Generado; uso comercial según el plan de ElevenLabs. Sin stock de
  terceros ni CC.
- **Posproceso** (ffmpeg, dentro del archivo; regla dura 5): mono 44,1 kHz, recorte
  de colas, normalizado a −3 dBFS (efectos/entidad) y −9 dBFS (ambientes), fundido
  cruzado de potencia constante en los bucles y codificación OGG Vorbis `-q 4`
  (efectos cortos e inmediatos en WAV 16 bit).

## Filas para la tabla de Audio

| Archivo | Origen | Licencia | Notas |
|---|---|---|---|
| `audio/entity/bones_step_01–04.wav` | ElevenLabs Sound Effects (`eleven_text_to_sound_v2`), generado 2026-10-09 | Generado; uso comercial según el plan de ElevenLabs | Crujido de huesos secos sobre laminado con roce de papel, 4 tomas, 0,4–0,6 s |
| `audio/entity/breath_loop.ogg` | Ídem | Ídem | Respiración de ruido blanco grave, bucle de 6 s |
| `audio/entity/listen_breath_loop.ogg` | Derivado de `breath_loop.ogg` (eco de conducto metálico con `tools/assets/gen_level_audio.py`) | Ídem | La misma respiración, muy cerca; bucle de 6 s |
| `audio/entity/screech.ogg` | ElevenLabs Sound Effects, generado 2026-10-09 | Ídem | Alarma contra incendios + silbato de la muerte azteca, disonante, 2,5 s |
| `audio/entity/static_shriek.ogg` | Ídem | Ídem | Estática grave que se corta en seco, 1,5 s |
| `audio/entity/chase_loop.ogg` | Ídem | Ídem | Persecución: pulso grave, huesos acelerados, alarma lejana; bucle de 8 s |
| `audio/ambient/level2_hall_loop.ogg` | Ídem | Ídem | Nave de concreto: viento, campanas lejanas, ozono; bucle de 20 s |
| `audio/ambient/copal_crackle_loop.ogg` | Ídem | Ídem | Brasas de copal y veladoras; bucle de 8 s |
| `audio/ambient/level3_tunnel_loop.ogg` | Ídem | Ídem | Túnel inundado: goteo, agua, resonancia de tubería; bucle de 20 s |
| `audio/ambient/level4_abyss_loop.ogg` | Ídem | Ídem | Caverna abisal: viento profundo + guitarra lejana distorsionada; bucle de 24 s |
| `audio/ambient/alarm_red_loop.ogg` | Ídem | Ídem | Clímax: klaxon de emergencia, estruendo, metal que cede; bucle de 8 s |
| `audio/ambient/neon_buzz_loop.ogg` | Ídem | Ídem | Zumbido de tubo de neón defectuoso; bucle de 6 s |
| `audio/ambient/office_silence_loop.ogg` | Ídem | Ídem | Oficina vacía casi muda (aire acondicionado mínimo); bucle de 10 s |
| `audio/ambient/brand_sting.ogg` | Ídem | Ídem | Firma sonora de marca: dos notas, cálida y limpia, 3 s (no es bucle) |
| `audio/sfx/footstep_water_01–06.wav` | Ídem | Ídem | Paso en agua a la altura del tobillo, 6 tomas, 0,5 s |
| `audio/sfx/splash_run_01–03.wav` | Ídem | Ídem | Salpicadura estridente al correr, 3 tomas, 0,7 s |
| `audio/sfx/footstep_concrete_01–06.wav` | Ídem | Ídem | Zapato sobre concreto en sala enorme (con cola), 6 tomas, 0,4 s |
| `audio/sfx/flashlight_fail.wav` | Ídem | Ídem | Fallo eléctrico: rugido electromagnético grave, 0,8 s |
| `audio/sfx/fall_sting.ogg` | Ídem | Ídem | Caída al vacío: viento + golpe sordo invertido, 1,5 s |
| `audio/sfx/ofrenda_collapse.ogg` | Ídem | Ídem | Pirámide de archiveros metálicos que se viene abajo, 3 s |
| `audio/sfx/clay_crack.ogg` | Ídem | Ídem | Pared de barro que se resquebraja, 2,5 s |
| `audio/sfx/water_drain.ogg` | Ídem | Ídem | Agua drenándose por un sumidero enorme, 4 s |
| `audio/sfx/door_oak_open.ogg` | Ídem | Ídem | Puerta de roble antigua, pesada, 2 s |
| `audio/sfx/petal_reveal.wav` | Ídem | Ídem | Susurro cálido de pétalos al iluminarlos, 0,8 s |
| `audio/sfx/letter_ignite.ogg` | Ídem | Ídem | Veladoras que se encienden una a una, 2 s |

## Niveles 2–4 y final — modelos (2026-10-09)

Los 38 modelos nuevos de `assets/models/` (letras O/H, ofrendas, conductos, umbral, gafete) y `olvidado.glb` son **modelado propio por script** (`tools/blender/build_models.py`, `tools/blender/build_entity.py`), sin recursos externos.
