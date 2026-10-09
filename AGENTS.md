# AGENTS.md — NOHO Backrooms Escape (game-godot)

Guía de navegación para agentes que trabajan en este proyecto. Lee este archivo primero; luego carga **solo** los documentos de `docs/` que la tarea requiera.

## Qué es este proyecto

Videojuego de **terror psicológico y escape en primera persona** — *NOHO Backrooms Escape* — construido en **Godot 4.7 / GDScript 2.0**, con exportación a **Web (HTML5/WebAssembly)** y **Android**. Fusión de horror liminal ("Backrooms") × estética del **Día de Muertos mexicano** (Mictlán). Es un *advergame* de la marca **NOHO / lovenoho.com**: el jugador (un oficinista) cae por un cuadro corporativo a pasillos infinitos y debe recolectar las letras **N-O-H-O** para escapar.

- Fuente única de la investigación original: `investigacion.txt` (no editar; es el documento de origen).
- Motor esperado: Godot 4.7.x (local: `godot4`, ver `~/.local/bin/godot4`).
- Estado actual: **fase de diseño** — aún no existe `project.godot`; la documentación define todo antes de implementar.

## Mapa de documentación (`docs/`)

| Archivo | Contenido | Cuándo leerlo |
|---|---|---|
| [docs/00-resumen-y-vision.md](docs/00-resumen-y-vision.md) | Visión general, concepto, mecánicas resumidas, plataformas, separación publicitaria | Siempre, al empezar cualquier tarea |
| [docs/01-legal-y-mitologia-liminal.md](docs/01-legal-y-mitologia-liminal.md) | **Licencias CC BY-SA 3.0 (Wikidot/Fandom)**, canon original obligatorio, reglas psicológicas del horror (presupuestos y prohibiciones) | Antes de crear lore, nombres, entidades o niveles |
| [docs/02-diseno-tematico.md](docs/02-diseno-tematico.md) | Sincretismo liminalidad × Día de Muertos: paleta, iluminación, audio, letras-altares | Dirección de arte, shaders, diseño de niveles, audio |
| [docs/03-mecanicas-y-controles.md](docs/03-mecanicas-y-controles.md) | Movimiento, sprint/resistencia, linterna errática, tabla de controles (VirtualJoystick táctil + WASD), interacción por proximidad | Implementar jugador, input, HUD o interacción |
| [docs/04-niveles-y-progresion.md](docs/04-niveles-y-progresion.md) | Prólogo + 4 niveles (N, O, H, O), mecánicas por nivel, clímax y final | Diseñar/mapear niveles, pacing, objetivos |
| [docs/05-entidad-y-ia.md](docs/05-entidad-y-ia.md) | "El Olvidado": diseño visual/sonoro + FSM por nodos (`WanderState`, `InvestigateState`, `ChaseState`, `AmbushState`, `AttackState`) | Implementar enemigo, IA, animaciones, audio de la entidad |
| [docs/06-monetizacion-y-marca.md](docs/06-monetizacion-y-marca.md) | Integración diegética en partida vs. publicidad agresiva en menú y pantallas de resolución (códigos promo, CTA) | UI del menú, pantallas de fin, integración de marca |
| [docs/07-render-y-optimizacion.md](docs/07-render-y-optimizacion.md) | Renderer **Compatibility**, atlas de texturas, `OccluderInstance3D`, `LightmapGI`, 60 FPS, export Android (GABE) y Web (COOP/COEP) | Configurar proyecto, materiales, iluminación, exports |
| [docs/08-desarrollo-asistido-por-ia.md](docs/08-desarrollo-asistido-por-ia.md) | Reglas anti-"alucinación de versiones" de Godot 3→4, System Prompt estándar, flujo de trabajo con IA y Profiler | Siempre al generar código GDScript |
| [docs/09-activos-3d-audio-y-referencias.md](docs/09-activos-3d-audio-y-referencias.md) | Estética Low Poly + "valle inquietante", fuentes de assets (poly.pizza, Blender, Sketchfab, Freesound, Sonniss), límite <100 MB | Adquirir/modelar assets, audio, presupuesto de peso |

## Reglas duras (no negociables)

1. **Legal / canon**: prohibido usar contenido de las wikis de Backrooms (niveles numerados, entidades con nombre como Smilers/Partygoers, facciones como M.E.G.). El canon es **original**. Ver `docs/01`.
2. **Godot 4.7 / GDScript 2.0**: nunca sintaxis de Godot 3. Prohibido `KinematicBody`; usar `CharacterBody3D` + `velocity` + `move_and_slide()` sin argumentos. Tipado estático estricto (`var speed: float = 5.0`, `-> void`). Ver `docs/08`.
3. **IA del enemigo**: FSM orientada a nodos (`enter()`, `exit()`, `can_exit()`) bajo `CharacterBody3D > StateMachine > *State`. Desacoplamiento por **Signals**. Ver `docs/05`.
4. **Render**: renderer **Compatibility** (OpenGL/GLES3) bloqueado para Web+Android. Iluminación estática horneada con `LightmapGI` (hornear con Forward+, ejecutar en Compatibility); única luz dinámica: linterna. Atlas de texturas y `OccluderInstance3D` obligatorios. Ver `docs/07`.
5. **Export Web**: el servidor debe servir cabeceras `Cross-Origin-Opener-Policy` y `Cross-Origin-Embedder-Policy` (requeridas por `SharedArrayBuffer`/multi-hilo). Ver `docs/07`.
6. **Horror sin combate**: el jugador **no pelea** — camina, corre (resistencia), ilumina, interactúa. Sin jump scares baratos, sin sobreexponer al monstruo, sin explicar la dimensión. Ver `docs/01` y `docs/03`.
7. **Publicidad**: durante la partida solo integración **diegética**; publicidad agresiva únicamente en menú principal y pantallas de resolución. Ver `docs/06`.
8. **Presupuesto de assets**: estética Low Poly, binario idealmente **< 100 MB**. Ver `docs/09`.
9. **Controles**: móvil = `VirtualJoystick` (`JOYSTICK_DYNAMIC`, izquierda) + `InputEventScreenDrag` (derecha) + `TouchScreenButton` en `CanvasLayer`; web = WASD via `InputMap` + `Input.set_mouse_mode(MOUSE_MODE_CAPTURED)`. Ver `docs/03`.

## Skills instalados (`.agents/skills/`)

Curaduría del ecosistema abierto de agent skills (instalados con `npx skills add`, proyecto-local). Úsalos como referencia de implementación; el `docs/` de este proyecto tiene prioridad en caso de conflicto de diseño.

### Godot 4.7 — motor

| Skill | Uso | Fuente |
|---|---|---|
| `godot-gdscript-patterns` | Patrones de producción GDScript: FSM, autoloads, pooling, tipado | `wshobson/agents` (repo 40K★, audits Snyk/Socket) |
| `godot-gdscript` | Lenguaje GDScript: tipado, ciclo de vida, `@export`, signals | `gamedev-skills/awesome-gamedev-agent-skills` (baseline Godot 4.7) |
| `godot-nodes-scenes` | Árbol de escenas, composición, instancing, autoloads, `PackedScene` | ídem |
| `godot-signals-groups` | Diseño event-driven con Signals + groups (desacoplamiento de la IA) | ídem |
| `godot-3d-essentials` | Nodos 3D, cámaras, luces, environment/post, `GridMap` | ídem |
| `godot-physics` | Bodies 2D/3D, capas de colisión, raycasts (`CharacterBody3D`, `RayCast3D`) | ídem |
| `godot-shaders` | Shading language 2D/3D (aberración cromática, distorsión del cuadro, parpadeos) | ídem |
| `godot-audio` | `AudioStreamPlayer`, buses, efectos (zumbidos, pasos, chillidos) | ídem |
| `godot-animation` | `AnimationPlayer`, `AnimationTree`, `Tween` (entidad, cámara, muerte) | ídem |
| `godot-resources` | `Resource` custom, `.tres`, diseño data-driven (niveles, config) | ídem |
| `godot-ui-control` | Nodos `Control`, contenedores, themes (HUD, menús, TouchScreenButton) | ídem |
| `godot-export` | Export presets, builds de plataforma, export headless (Android/Web) | ídem |

### Game development / diseño de juego

| Skill | Uso | Fuente |
|---|---|---|
| `game-ai` | FSMs, pathfinding, steering → comportamiento de El Olvidado | `gamedev-skills/...` |
| `level-design` | Whitebox/blockout, layout, pacing → laberintos y ofrendas | ídem |
| `game-feel` | Juice: screen shake, hit-stop, feedback → clímax, ataques, linterna | ídem |
| `audio-design` | Mezcla, música adaptativa, SFX, ducking → terror sonoro | ídem |
| `camera-systems` | Primera persona, orbit, screen-shake hook → cámara del jugador/ataque final | ídem |
| `input-systems` | Action mapping, multi-device, rebinding → táctil + WASD | ídem |
| `game-ui-ux` | HUD/menús, safe areas, escalado → menú publicitario y pantallas de fin | ídem |
| `performance-optimization` | Presupuesto de frame, draw calls, pooling, GC → objetivo 60 FPS | ídem |
| `shader-programming` | Conceptos cross-engine de shaders (vertex/fragment, UVs, efectos) | ídem |
| `create-game-assets` | Pipeline de dirección de arte y producción de assets 2D/3D cohesivos | ídem |
| `router` | Selector automático de skills según motor y tarea | ídem |

Actualizar con: `npx skills update` (desde `game-godot/`).

## Flujo de trabajo sugerido

1. Identifica la tarea → lee el/los documento(s) de `docs/` indicados en la tabla.
2. Genera código respetando las **reglas duras** y el System Prompt de `docs/08`.
3. Usa los skills de `.agents/skills/` para patrones concretos de Godot/GDScript (solo Godot 4.x).
4. Valida rendimiento con el Profiler de Godot y retroalimenta (ver `docs/08`, punto 3).

## Comandos útiles

```bash
godot4 --path game-godot          # abrir el proyecto en Godot 4.7 (una vez exista project.godot)
npx skills ls                     # listar skills instalados del proyecto
npx skills find <query>           # buscar más skills en el ecosistema
npx skills update                 # actualizar skills
```

---
*Mantiene el agente de diseño. Fuente de verdad: `investigacion.txt` → `docs/*.md` (validado 2026-10-09).*
