# AGENTS.md — Backrooms NOHO

Guía de navegación para agentes que trabajan en este proyecto. Lee este archivo primero; luego carga **solo** los documentos de `docs/` que la tarea requiera.

## Qué es este proyecto

Videojuego de **terror psicológico y escape en primera persona** — *Backrooms NOHO* — construido en **Godot 4.7 / GDScript 2.0**, con exportación a **Web (HTML5/WebAssembly)** y **Android**. Fusión de horror liminal ("Backrooms") × estética del **Día de Muertos mexicano** (Mictlán). Es un *advergame* de la marca **NOHO / lovenoho.com**: el jugador (un oficinista) cae por un cuadro corporativo a pasillos infinitos y debe recolectar las letras **N-O-H-O** para escapar.

- Fuente de la investigación original: `investigacion.txt` (no editar; es el documento de origen). Los `docs/` marcados como **"Enmendado"** recogen decisiones posteriores y **prevalecen** sobre `investigacion.txt` donde difieran.
- Motor esperado: Godot 4.7.x (local: `godot`, en `~/.local/bin/godot`; 4.7.2 estable).
- Estado actual: **fase de diseño** — existe un proyecto base (`project.godot` + `scenes/main.tscn`, una habitación de prueba en renderer Compatibility) sin jugabilidad; la documentación define todo antes de implementar. La raíz del repositorio es la raíz del proyecto Godot.

## Mapa de documentación (`docs/`)

| Archivo | Contenido | Cuándo leerlo |
|---|---|---|
| [docs/00-resumen-y-vision.md](docs/00-resumen-y-vision.md) | Visión general, concepto, mecánicas resumidas, plataformas, separación publicitaria | Siempre, al empezar cualquier tarea |
| [docs/01-legal-y-mitologia-liminal.md](docs/01-legal-y-mitologia-liminal.md) | **Licencias CC BY-SA 3.0 (Wikidot/Fandom)**, canon original obligatorio, licencias de assets aceptadas, reglas psicológicas del horror y política de jump scares | Antes de crear lore, nombres, entidades o niveles, o de incorporar assets externos |
| [docs/02-diseno-tematico.md](docs/02-diseno-tematico.md) | Sincretismo liminalidad × Día de Muertos: paleta, iluminación, audio, letras-altares | Dirección de arte, shaders, diseño de niveles, audio |
| [docs/03-mecanicas-y-controles.md](docs/03-mecanicas-y-controles.md) | Movimiento, sprint/resistencia, linterna errática, tabla de controles (VirtualJoystick táctil + WASD), interacción por proximidad | Implementar jugador, input, HUD o interacción |
| [docs/04-niveles-y-progresion.md](docs/04-niveles-y-progresion.md) | Prólogo + 4 niveles (N, O, H, O), mecánicas por nivel, clímax y final | Diseñar/mapear niveles, pacing, objetivos |
| [docs/05-entidad-y-ia.md](docs/05-entidad-y-ia.md) | "El Olvidado": diseño visual/sonoro + FSM por nodos (`WanderState`, `InvestigateState`, `ChaseState`, `AmbushState`, `AttackState`) | Implementar enemigo, IA, animaciones, audio de la entidad |
| [docs/06-monetizacion-y-marca.md](docs/06-monetizacion-y-marca.md) | Marca solo NOHO: diegética en partida; mínima y no bloqueante en menú y pantallas de resolución (código promo al ganar) | UI del menú, pantallas de fin, integración de marca |
| [docs/07-render-y-optimizacion.md](docs/07-render-y-optimizacion.md) | Renderer **Compatibility**, materiales/atlas, culling por sectores, `LightmapGI`, luz dinámica, geometría mutante, posprocesado, export Web (un hilo) y Android | Configurar proyecto, materiales, iluminación, exports |
| [docs/08-desarrollo-asistido-por-ia.md](docs/08-desarrollo-asistido-por-ia.md) | Reglas anti-"alucinación de versiones" de Godot 3→4, System Prompt estándar, flujo de trabajo con IA y Profiler | Siempre al generar código GDScript |
| [docs/09-activos-3d-audio-y-referencias.md](docs/09-activos-3d-audio-y-referencias.md) | Estética Low Poly + "valle inquietante", fuentes de assets (poly.pizza, Blender, Sketchfab, Freesound, Sonniss), límite <100 MB | Adquirir/modelar assets, audio, presupuesto de peso |

Los archivos `00`–`09` se destilan de `investigacion.txt` y son **normativos**. A partir de `10` comienza la **serie de diseño** (trabajo nuevo, sin violar los `00`–`09`):

| Archivo | Contenido | Cuándo leerlo |
|---|---|---|
| [docs/10-high-concept.md](docs/10-high-concept.md) | **High Concept**: pitch, pilares de diseño, arco afectivo, bucle de juego, USP, guardas de alcance y riesgos | Siempre, al empezar cualquier tarea de diseño (historia, niveles, game experience) |
| [docs/11-historia-y-guion.md](docs/11-historia-y-guion.md) | **Historia y guion**: tesis, temas, voces narrativas, mito de El Olvidado, bóveda de 16 documentos con textos de producción, guion del final (gafete lovenoho.com) | Escribir lore, documentos encontrados, diálogos, cinemáticas o textos de pantallas |
| [docs/12-dinamica-de-niveles.md](docs/12-dinamica-de-niveles.md) | **Dinámica de niveles**: bucles micro/tramo/nivel, economía (resistencia, linterna, ruido), **niveles de dificultad (Fácil casual / Intermedio / Difícil core)**, sistema de estímulos para la FSM, tramos y ritmo, presupuesto de apariciones, fail states, checkpoints y matriz de ajuste | Implementar gameplay, nivel, IA, pacing, balance o ajuste de dificultad |
| [docs/13-game-experience.md](docs/13-game-experience.md) | **Game experience**: game feel (linterna como lenguaje, respiración, interacción), cámara y confort, HUD mínimo, menús y pantallas de resolución, muerte/reintento <8 s, accesibilidad (leyendas de sonido, vibración, opciones), guion de sensación del final y orden de implementación | Implementar UI/HUD, menús, feedback, accesibilidad o polish de sensación |

## Reglas duras (no negociables)

1. **Legal / canon**: prohibido usar contenido de las wikis de Backrooms (niveles numerados, entidades con nombre como Smilers/Partygoers, facciones como M.E.G.). El canon es **original**. Ver `docs/01`.
2. **Godot 4.7 / GDScript 2.0**: nunca sintaxis de Godot 3. Prohibido `KinematicBody`; usar `CharacterBody3D` + `velocity` + `move_and_slide()` sin argumentos. Tipado estático estricto (`var speed: float = 5.0`, `-> void`). Ver `docs/08`.
3. **IA del enemigo**: FSM orientada a nodos (`enter()`, `exit()`, `can_exit()`) bajo `CharacterBody3D > StateMachine > *State`. Desacoplamiento por **Signals**. Ver `docs/05`.
4. **Render**: renderer **Compatibility** bloqueado para Web+Android. Iluminación estática horneada con `LightmapGI` por sector; **única luz en tiempo real: la linterna** (parpadeos y luces de emergencia por emisión, shader y `Environment`). Visibilidad por **sectores** + niebla; `OccluderInstance3D` es opcional y solo sirve en Android (no funciona en las plantillas Web por defecto). Máx. 6 materiales por nivel. Geometría mutante solo mediante variantes de sector pre-horneadas y pasillos en bucle. Ver `docs/07`.
5. **Export Web**: **un solo hilo** (*Thread Support* desactivado), sin cabeceras COOP/COEP. No activar hilos ni GDExtensions. Como el audio Web va en modo *Sample*, **todo el audio es pre-renderizado**: prohibido depender de `AudioEffect` en buses, reverberación del motor o audio procedural. Ver `docs/07` y `docs/09`.
6. **Horror sin combate**: el jugador **no pelea** — camina, corre (resistencia), ilumina, interactúa; agacharse y ocultarse son automáticos, sin botón. Jump scares **racionados** (máx. uno guionizado por nivel + la captura), nunca baratos ni constantes; sin sobreexponer al monstruo, sin explicar la dimensión. Ver `docs/01` y `docs/03`.
7. **Marca**: solo NOHO, sin anuncios de terceros. En partida, solo integración **diegética**; en menú y pantallas de resolución, presencia **mínima y no bloqueante** con los colores del logotipo (azul, blanco, naranja) como acento; esos colores no tiñen la estética del juego (`docs/02`). Nada retrasa "Jugar" ni "Reintentar". Ver `docs/06`.
8. **Presupuesto de assets**: estética Low Poly, binario idealmente **< 100 MB**. Solo licencias CC0, CC BY o comerciales royalty-free (nunca SA/NC/ND); cada asset externo se registra en `assets/CREDITS.md`. Ver `docs/09` y `docs/01`.
9. **Controles**: móvil = `VirtualJoystick` (`JOYSTICK_DYNAMIC`, izquierda) + `InputEventScreenDrag` (derecha) + `TouchScreenButton` en `CanvasLayer`; web = WASD + Shift/F/E via `InputMap` + `Input.set_mouse_mode(MOUSE_MODE_CAPTURED)`. Mismas acciones (`sprint`, `flashlight`, `interact`) en ambas plataformas. Ver `docs/03`.

## Skills instalados (`.agents/skills/`)

Curaduría del ecosistema abierto de agent skills (instalados con `npx skills add`, proyecto-local). Úsalos como referencia de implementación; el `docs/` de este proyecto tiene prioridad en caso de conflicto de diseño. En particular, ignora cualquier consejo de un skill que contradiga las reglas duras 4 y 5 (luces en tiempo real, efectos de audio en buses, hilos en Web).

> `.agents/` está en `.gitignore`: tras clonar, los skills **no están en disco**. Restáuralos con `npx skills experimental_install` (lee `skills-lock.json`). `godot-3d-essentials` no figura en el lock; hay que añadirlo con `npx skills add` si se quiere usar.

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

Actualizar con: `npx skills update` (desde la raíz del repositorio).

## Flujo de trabajo sugerido

1. Identifica la tarea → lee el/los documento(s) de `docs/` indicados en la tabla.
2. Genera código respetando las **reglas duras** y el System Prompt de `docs/08`.
3. Usa los skills de `.agents/skills/` para patrones concretos de Godot/GDScript (solo Godot 4.x).
4. Valida rendimiento con el Profiler de Godot y retroalimenta (ver `docs/08`, punto 3).

## Comandos útiles

```bash
godot --editor --path .           # abrir el proyecto en el editor de Godot 4.7
godot --path .                    # ejecutar el proyecto
npx skills experimental_install   # restaurar skills desde skills-lock.json
npx skills ls                     # listar skills instalados del proyecto
npx skills find <query>           # buscar más skills en el ecosistema
npx skills update                 # actualizar skills
```

---
*Mantiene el agente de diseño. Fuente de verdad: `investigacion.txt` → `docs/*.md` (validado 2026-10-09).*
