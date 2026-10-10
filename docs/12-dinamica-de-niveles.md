# Dinámica de Niveles — Backrooms NOHO

> **Tipo**: Documento de diseño lúdico (serie de diseño; no derivado de `investigacion.txt`).
> **Versión**: 1.1 — 2026-10-09 (añade niveles de dificultad). **Deriva de**: [`10-high-concept.md`](10-high-concept.md) §5–§6 y [`11-historia-y-guion.md`](11-historia-y-guion.md) §7.
> **Normativo con**: `docs/03` (mecánicas), `docs/04` (estructura de niveles), `docs/05` (FSM de El Olvidado), `docs/07` (presupuesto de render).
> **Números de este documento** son *valores iniciales de ajuste* por perfil de dificultad. Se validan en playtest (`docs/08`); la sensación manda sobre la cifra.

>
> **Enmienda 2026-10-09 (prevalece):** se retiran la **resistencia** y los **niveles de dificultad**. El jugador corre siempre que quiera, sin consumo, jadeo ni señales de cansancio; el precio de correr es solo el **ruido**. Hay una única dificultad, el **ajuste estándar** (los valores "Intermedio" de `docs/12`, en `scripts/core/difficulty.gd`). Añadir perfiles se decidirá cuando el estándar esté afinado. En consecuencia: §3.1 (resistencia) y §4.1–§4.4 (perfiles y su matriz) **no aplican**; donde este documento cite "Intermedio", léase "ajuste estándar"; la compasión y las políticas de reintento de §4.5 valen con sus valores de Intermedio; la carrera final (§8.4) no ajusta ningún consumo.

---

## 1. Alcance

Operativiza **cómo se juega cada nivel**: bucle local, ritmo, economía de recursos, niveles de dificultad, curva de presión de El Olvidado, fail states y transiciones. Lo narrativo (textos, simbolismo) vive en `11`; lo que se siente con el dedo en el gatillo de la linterna vive aquí.

## 2. El bucle en tres capas

| Capa | Duración | Ciclo |
|---|---|---|
| **Micro** | 2–10 s | Iluminar → escuchar → decidir (avanzar / ocultarse / apagar la luz / correr) → gestionar resistencia y linterna |
| **Tramo** | 1,5–2,5 min | Exploración → **respiro con documento** → presión (evento de la entidad) → tramo objetivo |
| **Nivel** | 3–10 min | Tramos → **letra-altar** → transición / colapso del nivel |

Regla de oro del ritmo: **tensión y respiro se alternan; nunca dos eventos de la entidad seguidos sin un tramo de respiro entre ellos.** El ritmo es **idéntico en todas las dificultades** (§4): la dificultad cambia la tolerancia, no el guion.

## 3. Economía de recursos

El jugador no tiene vida, inventario ni balas. Sus tres recursos son **resistencia, luz y silencio**. Los valores de esta sección son del perfil **Intermedio** (referencia); los perfiles extremos están en **§4**.

### 3.1 Resistencia (invisible) — retirada (ver enmienda)

| Parámetro | Valor (Intermedio) | Notas |
|---|---|---|
| Velocidad caminando | 2,2 m/s | Eco de pasos siempre audible (`docs/03`) |
| Velocidad sprint | 4,2 m/s | Ligero ventaja sobre el Chase (4,0 m/s) |
| Fondo de resistencia | 100 u | Sin barra en pantalla |
| Consumo de sprint | 20 u/s | ≈ 5 s de carrera continua |
| Regeneración (quieto) | 12 u/s | Solo quieta o caminando lento (`docs/03`) |
| Regeneración (caminando) | 6 u/s | |
| Umbral de hiperventilación | < 20 u | Respiración audible 5 s tras detenerse; **radio de detección ×1,5** |

**Feedback sin HUD**: respiración, oscilación sutil de la cámara y rugido en el audio. La invisibilidad de la barra es intencional (`docs/03`).

### 3.2 Linterna (sin baterías, sin confianza)

| Parámetro | Valor (Intermedio) | Comportamiento |
|---|---|---|
| Cono central | 28° | Lo que "enfoca" a El Olvidado |
| Intensidad nominal | 100% | Luz fría de oficina (N1–N2) → reveladora de pétalos (N4) |
| Entidad a 12 m | — | Parpadeo leve (1 cada 3 s) |
| Entidad a 6 m | — | Caída al 50% + apagados de 1 s |
| Entidad a 2 m | — | Apagado sostenido 2 s (navegación a ciegas) |
| Durante ChaseState | — | Fallos sostenidos (`docs/05`) |
| Haz central sobre la entidad > 1,2 s | — | Ver **§6** (el umbral de gracia varía con la dificultad, §4) |

**Nunca** se apaga por agotamiento: la linterna es fiable con el tiempo, fiable **no** con la compañía.

### 3.3 Silencio (presupuesto de ruido)

| Acción | Radio audible (Intermedio) |
|---|---|
| Caminar (seco) | 5 m |
| Sprint (seco) | 14 m |
| Caminar en agua (N3) | 8 m |
| Sprint en agua (N3) | **22 m** (salpicadura estridente) |
| Agachado / conducto (automático) | 2 m |
| Hiperventilando | ×1,5 sobre el radio de la acción |

Cada evento de ruido puntual (tropiezo, objeto caído) añade **+15 estímulo** en un radio de 20 m.

## 4. Niveles de dificultad — retirados (ver enmienda); queda el ajuste estándar

Tres perfiles, elegibles por el jugador. **Por defecto: Intermedio.**

| Perfil | Para quién | Filosofía |
|---|---|---|
| **Fácil — Casual** | Jugadores casuales, móvil, primera partida, quienes vienen por la historia y la marca | **Recursos sin límite y detección corta**: el terror se siente, no se paga. Se termina siempre |
| **Intermedio** (referencia) | La mayoría; equilibrio diseño ↔ historia | Los valores base de este documento |
| **Difícil — Core** | Audiencia veteran del horror; rejugabilidad | Recursos tensos, detección larga, castigo honesto: la paranoia **es** mecánica |

### 4.1 Lo que NUNCA cambia entre perfiles

- **Contenido**: los 5 niveles, los 16 documentos y sus textos, las letras, el clímax y el final.
- **Ritmo**: duraciones de tramo, cadencia de documentos (1 / ~2 min) y tramos de respiro. El arco narrativo es idéntico.
- **Reglas de mundo**: sin combate, sin botón de agacharse (automático), linterna sin baterías, muerte solo por captura.
- **Apariciones *scripted*** de El Olvidado: se mantienen; lo que escala es la **tolerancia** alrededor de ellas.
- Canon y reglas duras (`docs/01`, `docs/03`, `docs/07`).

### 4.2 Lo que SÍ escala

Economía, radios de ruido, velocidades de la entidad, umbrales de estímulo, tolerancia de contacto visual, umbrales de emboscada y políticas de reintento. Matriz completa: §4.4.

### 4.3 Selección y persistencia

- Selector de tres opciones en el menú principal, antes de "Jugar" (segmentado, un toque — nada retrasa "Jugar", `docs/06`).
- Cambiable desde el menú de pausa; **surte efecto al inicio del siguiente tramo**, nunca en mitad de una persecución.
- Se guarda en preferencias locales. Opcional en UI (`docs/13`): etiquetas temáticas ("Casual / Equilibrio / Pesadilla") sobre los nombres funcionales.

### 4.4 Matriz de ajuste por perfil

| Parámetro | Fácil | Intermedio | Difícil |
|---|---|---|---|
| Velocidad caminar / sprint (m/s) | 2,2 / 4,2 | 2,2 / 4,2 | 2,2 / 4,2 |
| Resistencia: fondo | **∞** | 100 u | 100 u |
| Resistencia: consumo | **0** | 20 u/s | 24 u/s |
| Resistencia: regen quieto / caminando | — | 12 / 6 u/s | 8 / 4 u/s |
| Hiperventilación (detección) | **no aplica** | ×1,5 | ×1,8 |
| Linterna: parpadeo / fallo / apagado | 18 / 10 m / **nunca (mín. 40%)** | 12 / 6 / 2 m (2 s) | 16 / 8 / 3 m (3 s) |
| Linterna durante Chase | parpadeo leve | fallos sostenidos | apagados largos |
| Ruido: caminar / sprint | **3 / 8 m** | 5 / 14 m | 7 / 18 m |
| Ruido: agua cam / agua sprint | **5 / 12 m** | 8 / 22 m | 10 / 28 m |
| Ruido: conducto / agachado | 1 m | 2 m | 3 m |
| Entidad: Wander / Investigate / Chase (m/s) | 1,0 / 1,6 / **3,6** | 1,1 / 1,9 / 4,0 | 1,3 / 2,2 / **4,5** |
| Estímulo: ruido (evento) | +8–18 | +10–25 | +12–30 |
| Estímulo: linterna sobre entidad / LOS | +25 / +12 s | +40 / +20 s | +50 / +28 s |
| Estímulo: decaimiento | −8/s | −5/s | −3/s |
| Umbrales: Investigate / Chase | 30 / 70 | 25 / 60 | 20 / 55 |
| Contacto visual: gracia → teletransporte | 2,5 s → 10% más cerca | 1,2 s → 20–30% | 0,8 s → 35% |
| Emboscada (quietud leve / agresiva) | 120 / 180 s | 60 / 90 s | 45 / 70 s |
| `AttackState` | < 1,5 m | < 1,5 m | < 1,5 m |
| Persecución final (N4) | 14 s | 18 s | 22 s |
| Presupuesto: N2 manifestaciones / N3 persecuciones por tramo | 3 / 1 | 3 / 1 | 4 / 2 |

### 4.5 Políticas de reintento por perfil

| Política | Fácil | Intermedio | Difícil |
|---|---|---|---|
| **Checkpoints** | Cada tramo + letras | Tramos de respiro + letras | Inicio de nivel + letras |
| **Compasión** (tras N muertes en el tramo → umbral Chase +X%) | 2 muertes → +30% | 3 muertes → +20% | 5 muertes → +10% |
| **Reaparición** (entidad reubicada a) | ≥ 30 m | ≥ 25 m | ≥ 20 m |
| **Caídas en N4** | Reinicio de puente | Reinicio de puente | Reinicio de puente + estímulo +15 |
| **Leer un documento** | **Presión congelada** mientras se lee | Decaimiento natural | Estímulo +5/s mientras se lee |
| **Sprint en la persecución final** | Garantizado (resistencia ∞) | Exige reserva media | Exige reserva real |

> **Fácil** funciona además como *modo historia*: garantiza finalización para el público casual y móvil, y para quienes quieren la experiencia narrativa y la marca sin castigo. Es la puerta de entrada, no la excepción vergonzosa: se diseña con el mismo cuidado.

## 5. Sistema de estímulos (alimenta la FSM de `docs/05`)

Puntuación de **estímulo** 0–100 que gobierna las transiciones de estado (valores Intermedio; escala en §4.4):

| Evento | Estímulo |
|---|---|
| Ruido (según §3.3) | +10 a +25 por evento |
| Haz de linterna intersectando el cuerpo de la entidad | +40 al instante |
| Línea de visión sostenida | +20/s |
| Hiperventilación dentro de 15 m | +8/s |
| Quietud y silencio | −5/s (decaimiento) |

| Umbral | Estado resultante (`docs/05`) |
|---|---|
| 0–24 | `WanderState` — patrulla, ignora al jugador |
| 25–59 | `InvestigateState` — gira hacia el estímulo, acelera |
| 60–100 con LOS | `ChaseState` — persecución abierta |
| 100 sin LOS | `ChaseState` hacia la última posición conocida, luego `Investigate` |
| Quietud > 60 s en la misma área | `AmbushState` — teletransporte fuera del frustum, encuentro forzado |
| Quietud > 90 s | `AmbushState` agresivo (aparece a 8–12 m) |
| Distancia < 1,5 m | `AttackState` — `can_exit() = false`, cámara forzada, muerte |

`AmbushState` existe para **prevenir el estancamiento**, no para castigar el sigilo: un jugador que se mueve en silencio nunca activa la emboscada.

## 6. Mecánica de evitación de contacto visual (Nivel 2 en adelante)

- El **cono central** de la linterna sobre el cuerpo de El Olvidado durante **> 1,2 s** (Intermedio; §4.4 para extremos) dispara: chillido de estática + **teletransporte un 20–30% más cerca** tras el próximo parpadeo (`docs/04`).
- Luz periférica o vistazo breve: **seguro**.
- La entidad no castiga ser vista con la mirada del jugador: castiga ser **iluminada**. Distinción clave para el diseño de niveles: las manifestaciones de N2 se colocan siempre en ángulo que invita a apartar el haz.

## 7. Tramos y ritmo (cuantificación)

Cada nivel se divide en tramos de 1,5–2,5 min. Tipos: **E** exploración · **R** respiro (documento) · **P** presión (evento de la entidad) · **O** objetivo (letra). Duración total por nivel = [`10-high-concept.md`](10-high-concept.md) §5. **Idéntico en las tres dificultades.**

| Nivel | Tramos (tipo · duración) | Documento | Entrega |
|---|---|---|---|
| **Prólogo** | E 1' · R 0,5' · O 1,5' | D01–D03 | Caída al Mictlán |
| **1 — N** | E 1' · R 2' (D04) · P 1,5' (pasos espejo) · R+O 1,5' (D05, D06, letra) | D04–D06 | Letra N |
| **2 — O** | E 2' · R 2' (D07) · P 2' (1ª manifestación) · R+O 2' (D08, D09, letra) | D07–D09 | Letra O |
| **3 — H** | E 2' · R 2,5' (D10) · P 2,5' (cazador + conductos) · R+O 2' (D11, D12, letra) | D10–D12 | Letra H |
| **4 — O** | E 2' (D13) · E 2,5' (puentes) · R 2' (D14) · P 1,5' (enfurecimiento) · P 2' (persecución final, D15) | D13–D15 | Puerta NOHO |

- **Respiro (R)** = 20–40 s sin presión de la entidad + un documento. Es el único momento seguro de leer.
- Máximo **1 documento por cada ~2 min**; nunca durante una persecución (regla de `11` §4).

## 8. Dinámica por nivel

> Las cifras citadas aquí son del perfil **Intermedio**; los perfiles extremos están en §4.

### 8.0 Prólogo — "La Oficina de la Realidad" (3 min)

| | |
|---|---|
| **Objetivo** | Enseñar a caminar, mirar e interactuar **sin tutorial explícito** |
| **Mecánica nueva** | Caminar, interacción por proximidad (documentos). **Sin linterna y sin sprint**: la oscuridad de los cubículos es el instructor |
| **Amenaza** | Ninguna. Silencio exterior + zumbido de monitores |
| **Error típico** | Ignorar los documentos |
| **Corrección de diseño** | D01 y D03 están en la única ruta posible hacia la sala de juntas |
| **Transición** | Interacción con el cuadro → aberración cromática severa + pérdida de equilibrio de cámara → caída |

### 8.1 Nivel 1 — "El Laberinto de Papel Tapiz" (6 min)

| | |
|---|---|
| **Objetivo** | Letra **N** en la sala central anómala (recepción bajo veladoras) |
| **Mecánica nueva** | Linterna (se encuentra en la recepción de entrada), resistencia, **pasos espejo** |
| **Amenaza** | Solo audio: 3–5 eventos de pasos que imitan la cadencia del jugador a 8–12 m. Si el jugador se detiene, los pasos se detienen; si corre, se aceleran. **Nunca se acercan de verdad** |
| **Topografía** | Líneas de visión rotas cada 3–4 m. Mutaciones: 1 de cada 3 pasillos vuelve al punto anterior (bucle); 1 puerta alterna entre dos variantes de sala pre-horneadas al segundo intento |
| **Presión real** | Cero. Es el nivel de la paranoia aprendida |
| **Error típico** | Correr en pánico al oír los pasos → hiperventilar → confirmar el miedo |
| **Corrección de diseño** | Los pasos son un espejo, no una amenaza: correr no tiene consecuencia en N1 pero **sí enseña su coste** (resistencia + respiración) |
| **Transición** | Recoger N → la cera de las veladoras se derrite en masa, la alfombra se cubre de pétalos (**contaminación 5%**) → aberración cromática |

### 8.2 Nivel 2 — "Las Ofrendas Infinitas" (8 min)

| | |
|---|---|
| **Objetivo** | Letra **O** en la cúspide de la ofrenda piramidal de archiveros |
| **Mecánica nueva** | **Evitación de contacto visual** (§6) |
| **Amenaza** | Primera manifestación visual, siempre a la lejanía (planicies de concreto, humo de copal reduce visibilidad a ~15 m) |
| **Presupuesto de apariciones** | **Máximo 3 manifestaciones visibles** (4 en Difícil, §4.4): 1 *scripted* al entrar en la planicie (de perfil, para enseñar a apartar la luz), 1 aleatoria en el tramo de ofrendas, 1 *scripted* al tomar la letra |
| **Topografía** | Colosales planicies interiores con columnas brutalistas; ofrendas incrustadas en cubículos. Mutación: al volver la vista, las ofrendas de la lejanía cambian de disposición (variantes pre-horneadas) |
| **Error típico** | Iluminar a la criatura para "ver qué es" |
| **Corrección de diseño** | El castigo es inmediato pero no letal (chillido + acercamiento 20–30%); la primera manifestación está colocada para que el jugador aprenda con margen de error |
| **Transición** | Recoger O → la ofrenda colapsa sobre sí misma, los archiveros se vuelven columnas infinitas (**contaminación 35%**) |

### 8.3 Nivel 3 — "El Pasaje de las Calaveras" (9 min)

| | |
|---|---|
| **Objetivo** | Letra **H** tras la pared de barro negro oaxaqueño |
| **Mecánica nueva** | **Agua = ruido**; sigilo; **agacharse/ocultarse automático** al entrar en conductos laterales (sin botón, `docs/03`); linterna como **radar de fallos** |
| **Amenaza** | El Olvidado como **cazador activo**. Presupuesto: **máx. 1 persecución visible por tramo** (2 en Difícil); toda persecución termina al entrar en un conducto lateral |
| **Regla dura de refugio** | Los conductos laterales son **zona segura**: la entidad no entra. Se queda escuchando en la boca del conducto (audio: respiración a 2 m). El bucle es salir-caminar-esconderse, nunca pelear |
| **Topografía** | Sistema lineal de conductos inundados hasta los tobillos; alfombra de cempasúchil sobre el agua; calaveras fosforescentes cian en el techo (única luz ambiental). Mutación: las uniones de conductos se reordenan al segundo paso (variantes) |
| **Error típico** | Correr sobre el agua en pánico → radio de 22 m → atracción masiva |
| **Corrección de diseño** | D10 lo advierte literalmente ("no corras sobre el agua"); los primeros 2 min tienen cornisas secas para practicar; el silencio premia con un cazador que patrulla a 1,1 m/s |
| **Transición** | Recoger H → la pared de barro se resquebraja, el agua se drena al vacío (**contaminación 50%**) |

### 8.4 Nivel 4 — "El Umbral del Mictlán" (10 min)

| | |
|---|---|
| **Objetivo** | Segunda letra **O** → puerta de roble bajo el neón magenta NOHO |
| **Mecánica nueva** | Plataformeo estrecho **sin muerte por caída**; **senderos invisibles de pétalos que solo revela la linterna** (`docs/02`) como guía espiritual; clímax + persecución final |
| **Caídas** | Caer = **reinicio del puente actual** + estímulo +10 + *sting* de audio. Nunca muerte |
| **Amenaza** | Tras la O: modo furia (fallas sistémicas, luces rojas de emergencia, clímax ensordecedor). Presupuesto: presencia constante pero poco tiempo en pantalla; el vacío hace el trabajo de susto |
| **Persecución final** | *Scripted*, ≈ 18 s de sprint (14 s en Fácil / 22 s en Difícil) hacia la puerta. **El guion la preparó**: D10 ("guarda tu carrera para la puerta") y el regalo de resistencia del ritual de la letra (1,5 s detenido = regeneración completa). Si la resistencia se agota: la linterna muere pero el neón magenta guía desde la distancia (no hay fallo automático) |
| **Topografía** | Islas flotantes de geometría de oficina unidas por tiras de papel picado. Los senderos de pétalos marcan el tramo seguro de cada puente |
| **Error típico** | Llegar al clímax sin resistencia por haber correteado los puentes |
| **Corrección de diseño** | Los tramos de puentes se juegan a paso lento (plataformeo); la regeneración alta en el tramo del altar; la carta D10 enseñó a reservar la carrera |
| **Cierre** | Cruzar la puerta → **audio cortado de golpe** → final (`11` §9) |

## 9. Transiciones entre niveles (invasión gradual)

Cada recolección de letra **es** la transición: no hay pantallas de carga ni cortes. Secuencia estándar (≈6 s):

1. Interacción con la letra-altar (1,5 s sostenido, veladoras encendiendo).
2. Perturbación visual: aberración cromática + distorsión (`docs/02`).
3. Mutación del entorno hacia el tema del siguiente nivel (siempre hacia **más** contaminación: 5% → 35% → 50% → 80%).
4. Piso de contaminación por nivel, que el equipo de arte fija con `docs/02` (paleta, luz, audio).

## 10. Fail states, muerte y reintento

| Fail | Qué pasa | Coste real |
|---|---|---|
| **Captura** (`AttackState`) | Cámara forzada, animación de muerte, negro | Reintento |
| **Caída al vacío** (N4) | Reinicio de puente | Tiempo + estímulo |
| **Estancamiento** | `AmbushState` | Encuentro forzado (no es fail) |

**Política de reintento (anti-frustración)** — parámetros exactos por perfil en §4.5:

- **Checkpoint**: según perfil (tramos/letras/nivel). Nunca se pierde lectura ni progreso de letras.
- **Reintento**: reaparición en el checkpoint con la entidad reubicada fuera del cono de visión. El nivel recuerda la contaminación, no el trauma.
- **Regla de compasión**: tras N muertes en el mismo tramo, el umbral de `ChaseState` sube hasta superarlo. No hay menú de dificultad adicional: **el perfil de dificultad es el menú**.
- El miedo debe costar **susto y tiempo**, nunca frustración larga.

## 11. Curva de exigencia global

Descrita para el perfil **Intermedio**; Fácil la aplana (picos de sigilo/ gestión a la mitad) y Difícil la endurece de forma pareja (nunca agrega contenido).

| Nivel | Exigencia de sigilo | Exigencia de gestión | Amenaza dominante |
|---|---|---|---|
| Prólogo | — | — | — |
| 1 — N | Baja | Media (resistencia) | Audio |
| 2 — O | Media (luz) | Media | Mirada iluminada |
| 3 — H | **Alta** | Alta (ruido/linterna) | Cazador + agua |
| 4 — O | Media | **Alta** (resistencia para el clímax) | Furia + abismo |

El pico de exigencia está en **N3** (sigilo); el pico de intensidad emocional en **N4** (clímax). Nada de picos simultáneos.

## 12. Presupuesto técnico de nivel

| Regla | Fuente |
|---|---|
| Un **sector** por tramo (culling y `LightmapGI` por sector) | `docs/07` |
| Máx. **6 materiales** por nivel | `docs/07` |
| Geometría mutante **solo** como variantes de sector pre-horneadas + pasillos en bucle. Prohibida la deformación en tiempo real | Regla dura 4 |
| Una única luz en tiempo real: la linterna. Emergencias por emisión/shader | Regla dura 4 |
| Audio pre-renderizado: los eventos de pasos espejo y estática se disparan como streams, sin `AudioEffect` en buses | Regla dura 5 |
| La dificultad **no** multiplica geometría ni materiales: solo cambia constantes de script y de audio | Este documento |

## 13. Métricas de playtest (`docs/08`)

| Métrica | Objetivo |
|---|---|
| Duración total de partida | 30–45 min (±20% por tramo), idéntica en las tres dificultades |
| **Finalización** por perfil | Fácil ≥ 85% · Intermedio ≥ 60% · Difícil ≥ 40% |
| Muertes por nivel (Intermedio) | N1 ≤ 0,3 · N2 ≤ 0,6 · N3 ≤ 1,2 · N4 ≤ 1,5 |
| Tiempo en sprint | < 30% del total (Intermedio) |
| Documentos leídos | ≥ 60% de jugadores lee ≥ 8 de 16 |
| Abandono por nivel | N3 es el punto crítico a vigilar |
| Muertes por agotamiento en la persecución final | < 25% (si sube, subir la regeneración del altar) |
| Reparto de perfiles | Fácil es la puerta de entrada esperada en móvil; si Intermedio concentra >70% de muertes en N3, se revisa el refugio de conductos |

## Ver también

- Pilares, arco y duraciones: [`10-high-concept.md`](10-high-concept.md) · Textos y placement de documentos: [`11-historia-y-guion.md`](11-historia-y-guion.md)
- Mecánicas y controles: `docs/03` · Niveles y clímax: `docs/04` · Estados de la entidad: `docs/05`
- Render y sectores: `docs/07` · Flujos y métricas: `docs/08`
- Sigue: `docs/13-game-experience.md` (game feel, cámara, HUD, accesibilidad, feedback de muerte, UI del selector de dificultad)
