# Orquestación de agentes — cómo se reparte el trabajo

> **Tipo**: Documento de proceso. **Versión**: 1.0 — 2026-10-09.
> Describe cómo el agente principal (Claude Code) delega en `codex` y `opencode` para avanzar varias tareas a la vez sin que se pisen. Es el método; el estado puntual de cada ola está en `builds/reports/` (no versionado).

---

## 1. Papeles

| Quién | Hace | No hace |
|---|---|---|
| **Orquestador** (Claude Code) | Lee el diseño, fija los **contratos** compartidos, redacta los encargos, lanza, revisa informes y pruebas, integra, actualiza `docs/15` y `assets/CREDITS.md` | Código pesado que pueda delegarse |
| **Delegados** (`codex exec`, `opencode run`) | Un encargo cerrado cada uno, sobre **archivos propios**, con verificación exigida e informe | Tocar archivos ajenos, comandos git que cambien estado, decidir diseño |

Nadie hace commits salvo que el usuario lo pida.

## 2. Modelos y para qué se usa cada uno

| CLI · modelo | Uso |
|---|---|
| `codex` · `gpt-6.1-sol` (por defecto en `~/.codex/config.toml`) | Lo más difícil: constructor de niveles, entidad/FSM, niveles completos |
| `codex` · `gpt-6-luna` | Modelado por script en Blender, niveles |
| `opencode` · `opencode-go/muse-spark-1.3-contributor` | Sistemas de jugador, escenas pequeñas |
| `opencode` · `opencode-go/mimo-v2.6-pro` | UI, menús, recursos de datos |
| `opencode` · `opencode-go/deepseek-v4.1-flash` | Canalizaciones de assets (audio, texturas) |

`opencode models` lista los disponibles. Claves para generación en `.env` (`openaiKey`, `ELEVENLABSkey`); nunca se imprimen ni se copian.

## 3. Lanzamiento

```bash
tools/agents/launch.sh <codex|opencode> <modelo> <id-encargo>     # en segundo plano, uno por encargo
```

- El encargo vive en `builds/specs/<id>.md`; el registro en `builds/logs/<id>.log` (termina con `EXIT <código> <id>`); el informe en `builds/reports/<id>.md`.
- `codex` va con `-s workspace-write`, red habilitada y `--add-dir` para los directorios de Godot y Blender del usuario; `stdin` a `/dev/null` (si no, puede quedarse esperando).
- `opencode` no escribe fuera del repo: todo lo temporal va a `builds/`.
- **Godot siempre con `tools/run_godot.sh`**: un `flock` serializa las ejecuciones, porque todos comparten `.godot/`.

## 4. Reglas que hacen posible el paralelo

1. **Propiedad exclusiva de archivos.** Cada encargo lista "Archivos tuyos"; el resto es de solo lectura. Dos encargos de la misma ola nunca comparten archivo. Los archivos compartidos por naturaleza se resuelven así:
   - `assets/CREDITS.md` → cada agente deja un fragmento `builds/credits_<x>.md`; lo funde el orquestador.
   - `tools/blender/build_models.py` → un único agente de modelos por ola; la entidad usa su propio `build_entity.py`.
   - `scripts/levels/level_base.gd`, `scripts/core/*`, `tools/debug/playthrough.gd`, `docs/*`, `AGENTS.md` → solo el orquestador.
2. **Contratos antes que código.** Lo que varios agentes necesitan (autoload `Game`, `Difficulty`, firmas de la entidad y del jugador, rutas de audio/modelos/texturas) lo escribe o lo fija el orquestador **antes** de lanzar, y el encargo lo cita al pie de la letra.
3. **Recursos de otro agente se cargan en ejecución** (`ResourceLoader.exists` + `load`, nunca `preload`) y los métodos de otro agente se comprueban con `has_method` mientras dure la ola. Así nada se rompe si el otro va más lento.
4. **Olas por dependencia**, no por tamaño: dentro de una ola todo es independiente; lo que depende del resultado de otra cosa espera a la ola siguiente.
5. **Verificación exigida en el encargo**: una prueba headless propia que imprime `<X> TEST OK/FAIL`, la prueba de punta a punta (`PLAYTHROUGH OK`) y, si hay algo visual, capturas u hojas de contacto que el agente debe **mirar**. El informe pega la salida literal.
6. **Lo ajeno roto no se arregla**: se anota en el informe. El orquestador decide.

## 5. Anatomía de un encargo (`builds/specs/NN-nombre.md`)

1. Título + id de informe.
2. Qué leer (siempre `builds/specs/00-common.md` + los docs concretos + los archivos de código de referencia).
3. **Archivos tuyos** (lista cerrada).
4. Por qué (el objetivo, en dos frases).
5. Qué construir: API pública con firmas exactas, comportamiento con referencias a secciones de `docs/`, nombres de archivo exactos.
6. **Verificación obligatoria**.

`00-common.md` lleva lo común: convivencia, estilo de código, contratos existentes, formato de entrega. Los encargos de nivel añaden `10-levels-common.md` (cómo se hace un nivel, API de `LevelBase`, reglas de diseño, verificación de nivel).

## 6. Plan de olas para terminar el juego (2026-10-09)

| Ola | Encargos (id → agente) | Depende de |
|---|---|---|
| **0** — orquestador | `Game` + `Difficulty`, `tools/run_godot.sh`, encargos | — |
| **1** — cimientos | `01-builder` → codex sol · `02-entity` → codex sol · `03-player` → opencode muse · `04-ui` → opencode mimo · `05-models` → codex luna · `06-audio` → opencode deepseek · `07-textures` → opencode deepseek | Ola 0 |
| **1→2** — orquestador | Revisar informes y pruebas; `LevelBase` (checkpoints, `spawn_entity`, zonas, `LetterAltar`, ritual de letra, carrera final); enlazar prólogo → N1 → N2 con `Game.next_level`; fundir créditos | Ola 1 |
| **2** — contenido | `11-level2` · `12-level3` · `13-level4` → codex · `14-ending` → opencode | Ola 1 + `LevelBase` |
| **3** — orquestador | Recorrido completo menú → final en `playthrough`, pase de rendimiento y de reglas duras, `docs/15`, `assets/CREDITS.md`, `AGENTS.md` | Ola 2 |

## 7. Revisión de una ola (lista del orquestador)

1. `tail` de cada `builds/logs/<id>.log`: ¿`EXIT 0`? ¿Existe el informe?
2. Leer el informe: API real frente a la del encargo, pendientes y peticiones de cambio fuera de sus archivos.
3. `git status --short`: ¿alguien tocó algo que no era suyo?
4. Volver a ejecutar **yo** sus pruebas y el playthrough; mirar capturas y hojas de contacto.
5. Si un encargo quedó a medias: relanzarlo con un encargo corto de corrección (`NNb-…`), no reescribirlo a mano salvo que sea trivial.
6. Solo entonces lanzar la ola siguiente.

## 8. Cuando un agente se corta a medias (cuota, caída)

`codex` tiene límite de uso por ventana: al agotarse, **todos** los `codex exec` en marcha mueren a la vez con `EXIT 1` y el mensaje `You've hit your usage limit … try again at HH:MM` al final del registro (pasó el 2026-10-09 con seis encargos abiertos). No lanzar más de 3–4 encargos largos de codex a la vez, y repartir el resto en `opencode-go/*`, que va por otra suscripción.

Para retomar sin perder lo hecho: un encargo corto de **continuación** `NNc-<nombre>.md` que apunta al original, manda leer las últimas ~400 líneas del registro anterior y el estado en disco, mantiene los mismos archivos propios y exige la misma verificación. Se lanza con otro modelo (`opencode-go/gpt-6-luna`, `muse-spark-1.3-contributor`, `mimo-v2.6-pro`). En tareas con gasto externo (Meshy, ElevenLabs, OpenAI) la continuación debe leer primero el libro de gastos (`builds/meshy/ledger.json`) y **recuperar las tareas ya pagadas** en lugar de crearlas otra vez.
