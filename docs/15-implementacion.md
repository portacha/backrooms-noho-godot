# Implementación — estado y canalización

> **Tipo**: Documento técnico de la serie de diseño. **Versión**: 1.0 — 2026-10-09.
> **Normativo con**: reglas duras de `AGENTS.md`, `docs/07` (render), `docs/08` (código). Describe **lo que hay construido** y cómo se reconstruye; el diseño vive en `10`–`14`.

---

## 1. Qué es jugable hoy

Menú principal → **Prólogo** → caída por el cuadro → **Nivel 1** → letra **N** → tarjeta de cierre ("Continuará — Nivel 2"). Sin muerte (el Nivel 1 no instancia a la entidad, `docs/04`). Niveles 2–4, El Olvidado, perfiles de dificultad, opciones y guardado: **pendientes**.

| Tramo | Escena | Qué incluye |
|---|---|---|
| Menú | `scenes/ui/main_menu.tscn` | `Portada.png` de fondo, JUGAR, SALIR (solo escritorio), enlace a lovenoho.com |
| Prólogo | `scenes/levels/prologue.tscn` | Oficina estéril retro-moderna (estética *Severance*, decorado propio), D01–D03, terminal que se bloquea, vestíbulo con recepción, cuadros de pasillo, luces que fallan en el cruce, cuadro que cambia fuera de encuadre, **mirada sostenida** (3 s → transición reversible → caída) |
| Nivel 1 | `scenes/levels/level1.tscn` | Laberinto de papel tapiz, linterna en la recepción, D04–D06, pasos espejo, pasillo en bucle, remanso de veladoras, altar de la N, contaminación de pétalos |

## 2. Iluminación: horneado propio en colores de vértice

`LightmapGI` no se puede hornear desde la línea de comandos, así que la luz estática se hornea con una herramienta propia. Cumple la regla dura 4 igual que un lightmap: **no hay ninguna luz en tiempo real salvo la linterna**.

- Cada nivel se define en `tools/levels/<nombre>_def.gd` (`extends LevelDef`): mapa ASCII de celdas de 2 m, materiales, cajas de mobiliario, luces y marcadores.
- `tools/level_builder/level_builder.gd` genera una malla con una superficie por material, colisiones fusionadas, paneles de luz y `Marker3D`, y calcula por vértice: luz directa con oclusión (rejilla + cajas), rebote aproximado y oclusión ambiental barata. Los fluorescentes que parpadean van en el canal alfa.
- `shaders/baked_surface.gdshader` pone la luz horneada en `EMISSION` y deja `ALBEDO` para que la linterna sume encima. El `Environment` tiene ambiente negro.
- Las luminarias de techo usan `ceiling_fixture.glb` (292 triángulos): marco plegado con profundidad, rejilla y pestañas de cierre, fundidos en la paleta. El difusor queda detrás de la rejilla y lleva estrías suaves en `light_panel.gdshader`; conserva la energía y el parpadeo de cada fuente horneada.
- Globales de shader: `world_light` (atenúa todo el mundo; lo usa la recogida de la letra), `flicker_seed` y `flicker_override` (−1 = cada tubo parpadea solo, como en el Nivel 1; ≥ 0 = el guion del nivel dicta el brillo de los tubos `flicker`, como en los pasillos del prólogo). `LevelDef.flicker_color` da el color de esos tubos.
- **Mobiliario y utilería son modelos** (regla dura 10): `tools/blender/build_models.py` genera 44 modelos low-poly en `assets/models/*.glb` (materiales de color plano, sin texturas). La definición del nivel los coloca en `props` y el constructor los **funde en la malla horneada**: cada material de Blender pasa a ser un tinte de un único material de paleta, así reciben la luz horneada y no se pasa de 6 materiales por nivel. Las superficies `Screen` y `Flame` van a los materiales emisivos del nivel.
- Los objetos dinámicos (linterna, letra N) usan los mismos `.glb` instanciados en ejecución con `LevelBase.spawn_model()`.

**Reconstruir** (obligatorio tras tocar un `_def.gd` o un modelo; el resultado `scenes/levels/generated/*.scn` se versiona):

```bash
blender -b -P tools/blender/build_models.py                               # modelos (solo si cambian)
blender -b -P tools/blender/render_sheet.py                               # hojas de contacto en builds/
godot --headless --path . --import                                        # importa los .glb
godot --headless --path . --script res://tools/build_levels.gd            # todos
godot --headless --path . --script res://tools/build_levels.gd -- level1  # uno
```

### Señalética y lectura

- **Letreros** (`LevelDef.add_sign`): modelos `sign_wall`, `sign_wall_left/right` (flecha en relieve) y `sign_hanging`. La definición los coloca y el nivel escribe el texto con `LevelBase.build_signs()`. Prólogo: "SALA DE JUNTAS" en el cruce, en las esquinas de los dos rodeos y junto a la puerta. Nivel 1: "RECEPCIÓN" en la pared del fondo de uno de cada dos recodos de la ruta principal, envejecidos, y un colgante ante la sala central. Guían sin HUD; no hay uno en cada giro a propósito.
- **Soporte del documento** (`DocumentData.medium`): `SCREEN` abre un **monitor viejo con bloc de notas** (barra de título, menú, cursor que parpadea, líneas de barrido y viñeta de tubo: `shaders/crt_overlay.gdshader`); `STICKY_NOTE` una nota adhesiva torcida; `PAPER` una hoja; `WALL` una inscripción. D01 es `SCREEN`, D02 es `STICKY_NOTE`.
- **Vestíbulo y cuadros del prólogo**: `door_portal`, `column_round`, `reception_desk` + `reception_wing` (mostrador en L en dos piezas, para que la colisión deje entrar detrás), `wall_slats`, `logo_plate`, `bench_waiting`, `planter` y `frame_small` (marco con aplique). Los seis lienzos son una sola malla y un material sobre el atlas `assets/textures/office_posters.png`, que junto con el ventilador y el balastro genera `tools/assets/gen_prologue_assets.py`.
- **Frase del protagonista**: `Hud.show_line()` (subtítulo sin voz).
- **Tipografías** (`assets/fonts`, todas SIL OFL): Nunito (general, redonda), VT323 (terminales), Caveat (voz íntima, manuscrita).

## 3. Mapa del código

| Ruta | Contenido |
|---|---|
| `scripts/core/game.gd` | Autoload `Game`: cambio de escena, color del fundido de entrada, ajustes de sesión |
| `scripts/player/` | `player.gd` (movimiento, resistencia, cámara), `interactor.gd` (foco + toque/mantener), `flashlight.gd` |
| `scripts/interaction/` | `Interactable`, `DocumentPickup`, `DocumentData` (los textos están en `resources/documents/*.tres`) |
| `scripts/ui/` | `hud.gd` (retícula, lectura, pistas, tarjeta final), `main_menu.gd`, `pause_menu.gd`, `touch_controls.gd` |
| `scripts/fx/screen_fx.gd` + `shaders/screen_fx.gdshader` | Aberración, distorsión, viñeta y fundidos; visible solo durante eventos |
| `scripts/levels/` | `level_base.gd` (marcadores, utilidades), `prologue.gd`, `level1.gd`, `mirror_steps.gd` |
| `tools/blender/` | `build_models.py` (modelos por script) y `render_sheet.py` (hojas de contacto para revisarlos) |
| `tools/assets/gen_image.py` | Texturas con la API de imágenes de OpenAI (clave en `.env`) y conversión a mosaico repetible |
| `tools/assets/gen_prologue_assets.py` | Recursos propios del prólogo: atlas de cuadros de pasillo (Pillow) y sonidos sintetizados (numpy + ffmpeg) |
| `tools/assets/stock_assets.py` | Busca, enumera variantes y descarga CC0 desde las APIs oficiales de Poly Haven y ambientCG; staging con hashes y procedencia. Método y decisión Blender/stock en [docs/16](16-assets-stock.md) |
| `tools/debug/` | Pruebas y capturas (§4) |

Los objetos de juego **no se colocan a mano** en las escenas: cada script de nivel los crea en los marcadores que exporta la definición.

## 4. Pruebas

```bash
# Recorrido completo: menú → prólogo (luces, mirada al cuadro y su corte) → caída → Nivel 1 → letra → tarjeta final
godot --headless --path . res://tools/debug/playthrough.tscn
# Lo mismo con ventana y capturas en builds/play_*.png
PLAY_SHOTS=1 godot --path . res://tools/debug/playthrough.tscn
# Caminar de verdad (físicas) por una lista de puntos x,z
WALK_SCENE=res://scenes/levels/level1.tscn WALK_POINTS="5,49;11,49;11,51" \
  godot --headless --path . --fixed-fps 60 res://tools/debug/walk.tscn
# Capturas desde posiciones concretas (nombre:x,z,yaw,pitch)
SHOT_SCENE=res://scenes/levels/prologue.tscn SHOT_VIEWS="a:21,23,0,0" \
  godot --path . res://tools/debug/shot.tscn
```

## 5. Desviaciones respecto al diseño

| Diseño | Implementado | Motivo |
|---|---|---|
| `docs/07`: `LightmapGI` por sector | Colores de vértice horneados por herramienta propia | Se puede regenerar sin editor; mismo coste en ejecución (cero) |
| `docs/07`: sectores con *culling* | Un sector por nivel | Prólogo y Nivel 1 son pequeños (73 k y 90 k vértices con el mobiliario). Hará falta desde el Nivel 2 |
| `docs/14`: planta de cubículos en penumbra | Sala de trabajo con filas de puestos + pasillos blancos, luz uniforme | Estética *Severance* (2026-10-09), sin copiar sus decorados. Ver enmienda en `docs/14` |
| `docs/14`: frente de vidrio en la sala de juntas | Hueco de puerta | El constructor aún no emite superficies transparentes |
| `docs/12` §8.1: una puerta que alterna entre dos variantes de sala | Solo el pasillo en bucle | Pendiente: variantes de sector |
| `docs/01`: solo CC0, CC BY o comercial royalty-free | Tres fuentes con licencia SIL OFL 1.1 | Pedido expreso de cambiar la tipografía (2026-10-09). La OFL permite uso comercial e incrustación; falta añadirla a la lista de `docs/01` si se acepta |

| `docs/14` §6.2: mantener 1,5 s sobre el cuadro | Mirada sostenida, sin tocar; apartar la vista corta la transición | Decisión del usuario (2026-10-09). Enmienda en `docs/14` |
| `docs/14` §1 y §8: nada se mueve; sin aire | Los tubos de los pasillos fallan una vez en el cruce (con frase del oficinista) y hay ventilador leve junto a los terminales | Ídem |
| `docs/07`: máx. 6 materiales por nivel | El prólogo suma un material para los lienzos de pasillo (una sola malla) | Ya se superaba con cuadro, pantallas y paneles; pendiente de unificar en atlas |

## 6. Pendiente inmediato

1. Jugar a mano en escritorio y en un móvil real (los controles táctiles solo están probados con eventos simulados).
2. Exportación Web y Android: no hay plantillas de exportación instaladas en esta máquina.
3. Escuchar y mezclar el audio generado (niveles fijados a ojo, por medición de pico).
4. Opciones (movimiento reducido, sensibilidad, leyendas de sonido), perfiles de dificultad, guardado.
5. Nivel 2 y El Olvidado (`docs/05`).
