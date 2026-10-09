# Diseño del Prólogo — "La Oficina de la Realidad"

> **Tipo**: Documento de diseño de nivel (serie de diseño; no derivado de `investigacion.txt`). Primer documento **por nivel** de la serie.
> **Versión**: 1.0 — 2026-10-09. **Deriva de**: [`10-high-concept.md`](10-high-concept.md) §5, [`11-historia-y-guion.md`](11-historia-y-guion.md) §7 (D01–D03) y §9, [`12-dinamica-de-niveles.md`](12-dinamica-de-niveles.md) §8.0, [`13-game-experience.md`](13-game-experience.md) §3–§5.
> **Normativo con**: `docs/04` (prólogo), `docs/06` (marca diegética), `docs/07` (render).
> **Enmendado 2026-10-09 (implementación)**: la oficina toma **solo la estética** de *Severance* (blanco estéril, alfombra verde, terminales retro, luz fluorescente uniforme), no sus decorados: es una sala de trabajo con filas de puestos y mamparas bajas, pasillos blancos y sala de juntas, en vez de una planta de cubículos en penumbra. Lo que cambia respecto a este documento: (1) el jugador empieza **de cara a su terminal**, con la nota D02 en el terminal vecino, que queda en su camino hacia el pasillo central; desde ese pasillo se ve el corredor y el cuadro al fondo; (2) la caja NOHO corta el **pasillo directo** y hay dos rodeos (oeste y este) que confluyen ante la puerta de la sala de juntas, donde está D01; (3) la sala de juntas se abre por un hueco de puerta, sin vidrio; (4) las "islas de luz" de §4 no aplican: la guía es el color del cuadro y la geometría. El resto (cuadro, mantener 1,5 s, caída, audio, marca) se implementó como está escrito. Fuente de verdad del plano: `tools/levels/prologue_def.gd`. Estado: `docs/15`.
> **Estado del blockout**: `scenes/levels/prologue.tscn` ya tiene la planta, la sala de juntas y al jugador caminando. La §12 lista lo que cambia respecto a ese blockout.

> **Enmendado 2026-10-09 (color del piso, decisión del usuario)**: la alfombra de
> todas las oficinas del prólogo es **azul NOHO `#1F5FFF`**, en lugar de verde.
> Se conserva su detalle de textura mediante desaturación y tinte del material.
> El valor coincide con el acento actual del menú; el hex del manual de marca
> continúa pendiente de confirmación. Ver `docs/02` y `tools/levels/prologue_def.gd`.

> **Enmendado 2026-10-09 (mirada, vestíbulo y pasillos; decisión del usuario)**. Prevalece sobre el texto de abajo donde difiera:
> 1. **El cuadro no se toca: se mira.** Cerca del lienzo (≤ 3,2 m) y con él en el centro de la pantalla, a los **3 s** empieza la transición (aberración, distorsión, FOV); si la mirada se sostiene **1,5 s más**, la caída ya no tiene vuelta. **Apartar la vista corta la transición** y todo vuelve en 0,4 s. Sin botón, sin retícula de progreso. Ver §6.2 y §7.
> 2. **Vestíbulo y recepción.** El puesto suelto junto a la puerta de la sala de juntas se sustituye por un vestíbulo de 10 × 6 m: portada de nogal en la puerta, dos columnas, **recepción en L** al este (D01 sigue en su terminal; se lee entrando detrás del mostrador) con muro de listones y rótulo NOHO, y espera al oeste (banca, jardineras). La caja del lienzo se desplaza al tramo sur del pasillo directo.
> 3. **Cuadros de pasillo.** Seis cuadros pequeños (0,42 × 0,54 m) con aplique en los dos rodeos, tres por lado y alternando de pared. Son carteles internos de NOHO que dicen a qué se dedica la empresa sin explicarla: *conserva nombres* (`11` §4). Textos en `tools/assets/gen_prologue_assets.py`.
> 4. **Las luces fallan.** Al entrar en el cruce donde la caja corta el paso, los tubos de los pasillos parpadean ~2 s y el oficinista piensa en voz alta, como **subtítulo sin voz**: «Estas luces… ¿algún día las arreglarán?». En cada rodeo vuelven a fallar una vez, sin comentario. Es la única excepción a "nada se mueve" (§1) y a la regla de no usar voces (`11` §4): no es un susto ni una voz en off.
> 5. **Ventilador de los terminales.** Bucle de aire muy leve (−24 dB) que solo se oye a menos de 7 m de un terminal (sala de trabajo y recepción). Sustituye, para este sonido, el "nunca aire acondicionado" de §8.

---

## 1. Qué tiene que lograr

En **~3 minutos**, sin una sola línea de tutorial y sin amenaza:

1. Enseñar a **caminar, mirar e interactuar** (los tres verbos que no requieren peligro).
2. Enseñar a **leer la luz**: lo iluminado importa, lo oscuro no. Es la regla visual de toda la partida.
3. Sembrar el **cuadro** como objeto ritual-administrativo (D01–D03) y nombrar al jugador responsable de él.
4. Ejecutar **la caída**: el único evento del nivel y la plantilla de todas las transiciones posteriores.
5. Dejar construido el **encuadre espejo** que el final reutiliza (`11` §9.4) y el **fondo del menú** (`13` §6.1).

Emoción dominante: **inquietud cotidiana**. No hay sustos: el presupuesto de *jump scares* del prólogo es **cero**. Nada se mueve, nada suena fuera, nadie viene.

## 2. Premisa de la escena

Son las **23:47**. Todos los monitores de la planta muestran esa hora y ninguno avanza. El oficinista está de pie junto a su puesto; al fondo del pasillo, detrás del vidrio de la sala de juntas, hay algo con color.

El lienzo llegó **esta noche** (D01). Por eso la oficina está a medio instalar: la caja de embalaje sigue en el pasillo, la escalera y el plástico de burbuja siguen en la sala. Esos restos de instalación **son** el diseño de nivel (§4): cierran rutas y explican por qué sin decirlo.

## 3. Plano y zonas

Un solo sector (~390 m²). Norte arriba. Cotas del blockout actual; la sala de juntas se estrecha a 6 m (§12).

```
                         N
          ┌────────────────────────┐
          │    ▓▓▓▓ CUADRO ▓▓▓▓  ▪D03   ZONA E — Sala de juntas (6 × 8 m)
          │ escalera               │   El lado oeste está cerrado por la
          │ + plástico   ┌────┐    │   escalera y el plástico: solo se llega
          │ (cerrado)    │mesa│  ← │   al cuadro por el lado este, pasando
          │              └────┘    │   junto a D03.
          └──vidrio──┐      ┌─vidrio┘
   ┌─────────────────┘      └──────────────┐
   │                         ▪D01 asistente │  ZONA D — Antesala
   │  cub. ─────┤            ├───── cub.    │
   │  cub. ─────┤            ├───── cub.    │
   │  cub. ─────┼═══ CAJA ═══╡   ▪D02       │  ZONA C — El desvío
   │  cub. ─────┤    NOHO    ├──  cub. de M.│
   │  cub. ─────┤            ├───── cub.    │  ZONA B — Pasillo sur
   │  ★ tu puesto            ├───── cub.    │  ZONA A — Inicio
   └──────────── puerta de SALIDA ──────────┘
```

| Zona | Función | Qué hay |
|---|---|---|
| **A — Inicio** | Primer encuadre y primer movimiento | Tu puesto (sin placa de nombre), tu monitor, taza membretada |
| **B — Pasillo sur** | Aprender a caminar hacia la luz | Cubículos vacíos, monitores como islas de luz |
| **C — El desvío** | Aprender a rodear y a curiosear | Caja de embalaje NOHO atravesada en el pasillo; cubículo de M. con D02 |
| **D — Antesala** | Revelación completa del cuadro; enseñar a interactuar | Escritorio de asistente con D01, puerta de vidrio abierta |
| **E — Sala de juntas** | Respiro final y objetivo | Mesa, sillas, restos de instalación, D03, el cuadro |
| **Salida** (sur) | Responder "¿por qué no me voy?" | Puerta de escalera cerrada, letrero de salida **apagado** |

Distancia de ruta inicio → cuadro: **~38 m** (≈17 s caminando sin parar a 2,2 m/s). El resto de los 3 minutos son lectura y mirada. Un jugador que repite la partida llega a la caída en **< 30 s**; por eso el prólogo **no tiene botón de saltar** y nada en él retiene al jugador.

## 4. Cómo guía el espacio (sin marcadores)

| Recurso | Cómo funciona aquí |
|---|---|
| **Faro de color** | El cuadro es el único color saturado del nivel y es visible desde el primer fotograma: su franja superior asoma sobre la caja y su luz naranja-azul se derrama sobre el piso del pasillo. El objetivo se entiende sin texto |
| **Islas de luz** | Los monitores encendidos marcan la ruta; los cubículos sin nada que ver tienen el monitor apagado. Los tres documentos están siempre **dentro** de una isla de luz |
| **Bloqueos diegéticos** | La caja del lienzo cierra el pasillo central (obliga a cruzar el cubículo de M.); la escalera y el plástico cierran el lado oeste de la sala (obliga a pasar junto a D03) |
| **Oscuridad sin premio** | Los rincones oscuros no contienen nada. El jugador aprende ya en el prólogo que explorar a oscuras no paga — hasta que tenga linterna (N1) |
| **Revelación en dos tiempos** | Desde A se ve el cuadro recortado por la caja; al salir del desvío (C→D) aparece entero tras el vidrio. Es el único "momento de cámara" antes de la caída |

## 5. Guion de tramos (beat a beat)

Tramos de `12` §7: **E 1' · R 0,5' · O 1,5'**. Tiempos orientativos para un jugador que lee.

| # | Tiempo | Tramo | Beat | Qué enseña |
|---|---|---|---|---|
| 1 | 0:00 | E | Negro → *fade* de 1,5 s. Encuadre de inicio (§5.1): tu cubículo a la izquierda, el pasillo, el color al fondo | El objetivo |
| 2 | 0:03 | E | **Tu monitor se bloquea** ("Sesión bloqueada por inactividad · 23:47") y baja de brillo. Tu rincón queda más oscuro que el pasillo | Que te muevas |
| 3 | 0:10 | E | Pasillo sur. Zumbido de monitores, tus pasos nítidos sobre vinilo, ningún sonido exterior | Caminar, mirar; el eco de los pasos |
| 4 | 0:35 | E | La caja corta el paso. El único hueco es el cubículo de M., con el monitor encendido y una nota amarilla pegada: **D02** (opcional, pero está en la línea de marcha) | Rodear; la retícula se expande por primera vez |
| 5 | 1:00 | R | Sales del desvío: **el cuadro completo** tras el vidrio. A un paso de la puerta, el monitor más brillante de la planta (blanco, no azul): **D01** | Interactuar y leer |
| 6 | 1:30 | O | Cruzas la puerta. El zumbido cae 12 dB (§8): la sala está más callada que la oficina | Que el audio cambia con el espacio |
| 7 | 1:45 | O | Rodeas la mesa por el este. En la pared, a la altura de los ojos y bañada por la luz del lienzo, la placa: **D03** | "Responsable de su memoria: el último empleado que la mire" |
| 8 | 2:15 | O | Frente al cuadro. **El cuadro cambia cuando no lo miras** (§6.1) | Que D02 decía la verdad |
| 9 | 2:30 | O | Sostener la mirada sobre el cuadro (§6.2) → **la caída** (§7) | Que mirar es elegir |

### 5.1 Encuadres fijos

Tres `Marker3D` en la escena, porque el prólogo se usa tres veces:

| Marcador | Uso | Encuadre |
|---|---|---|
| `StartFrame` | Inicio de partida | De pie en tu puesto, mirando al norte por el pasillo. Cubículo y monitor en el tercio izquierdo, cuadro en el punto de fuga (composición de `concept/art/00-prologo-B.jpg`) |
| `MenuFrame` | Fondo del menú principal (`13` §6.1, `docs/06`) | Mismo eje que `StartFrame`, más bajo y más abierto, estático |
| `MirrorFrame` | Último fotograma antes de caer **y** primer fotograma del final (`11` §9.4) | A 1,2 m del lienzo, centrado, a la altura de los ojos |

`MirrorFrame` es normativo: la interacción con el cuadro lleva la cámara a ese encuadre exacto (§6.2) para que el final pueda repetirlo con el cuadro ya sin color.

## 6. El cuadro

Lienzo de **2,4 × 1,8 m** (medida canónica de D03), con marco, centrado en la pared norte. Diseño abstracto con el **logotipo NOHO tal cual** integrado, en los colores de la marca (azul, blanco, naranja; `docs/06`). Es el único lugar del prólogo donde aparecen esos colores a plena saturación, y el único material emisivo cálido.

### 6.1 "Cambia cuando lo miras de reojo"

El cuadro tiene **dos composiciones** (misma paleta, formas desplazadas). Se intercambian **solo cuando el lienzo está fuera del encuadre** de la cámara, nunca a la vista:

- Se arma al entrar en la zona E. Máximo **3 cambios** en todo el prólogo; mínimo 4 s entre cambios.
- Sin sonido, sin efecto, sin aviso. Quien no leyó D02 probablemente no lo note; quien la leyó, sí. Las dos lecturas son válidas.
- Es la misma regla que la geometría mutante del resto del juego (`docs/07`: mutar solo fuera de la vista), presentada aquí en miniatura.

### 6.2 Interacción

**Mirar, no tocar** (enmienda 2026-10-09). El cuadro no es un interactuable: el gesto es la mirada, y por eso funciona igual con ratón y en táctil.

| Momento | Feedback |
|---|---|
| A ≤ 3,2 m y con el lienzo en el centro de la pantalla (0 → 3 s) | La emisión del cuadro sube; el zumbido de la oficina y los ventiladores se desvanecen hasta cero; sube el tono grave |
| Mirada sostenida (3 → 4,5 s) | **Empieza la transición**: aberración, distorsión y FOV suben, suena la pista de la caída. El jugador **conserva el control** |
| Apartar la vista en cualquier momento | **Se corta**: imagen y sonido vuelven en 0,4 s y la cuenta empieza de cero. Sin castigo |
| 4,5 s | Se pierde el control → la caída; la cámara se centra en `MirrorFrame` |

Leer D03 no cuenta como mirar el cuadro: la placa queda fuera del lienzo y la cuenta se detiene mientras hay un documento abierto.

## 7. La caída (≈6 s)

Plantilla de las transiciones de `12` §9, en su versión más larga. Tras la enmienda de la mirada, el tramo 0,0–1,5 de la tabla son los 3 s de mirada, el tramo 1,5–3,0 es la transición reversible y el resto ocurre ya sin control. Sin *flash* blanco, sin *screen shake* (ese presupuesto es de las letras, la persecución y la captura; `13` §7).

| t (s) | Imagen | Cámara | Audio |
|---|---|---|---|
| 0,0–1,5 | *Hold*: el cuadro gana brillo | Se centra en `MirrorFrame` | El zumbido se apaga; queda un tono grave que sale del lienzo |
| 1,5–3,0 | Aberración cromática de 0 → severa; distorsión espacial con centro en el lienzo | **Pérdida de equilibrio**: balanceo lento (±6°), FOV 75° → 95°, la cabeza se vence hacia delante | Una inhalación; el tono sube |
| 3,0–4,5 | El lienzo llena la pantalla; sus colores se estiran en radial | Cae hacia delante **a través** del plano del cuadro | *Whoosh* grave pre-renderizado; los pasos y la sala desaparecen |
| 4,5–6,0 | Los colores se funden a **amarillo liminal** y luego a penumbra | Golpe seco; la cámara queda a ras de alfombra | Silencio de 0,3 s → zumbido de fluorescentes del Nivel 1 |

- La transición termina en **amarillo**, no en negro ni en blanco: el primer color del Nivel 1 (`docs/02`).
- **Movimiento de cámara reducido** (`13` §4): sin balanceo ni cambio de FOV; un avance recto hacia el lienzo + fundido, con la aberración al 30%.
- En calidad baja de Android el shader de pantalla se queda en viñeta + fundido (`docs/07`).
- El Nivel 1 se carga durante el prólogo, no durante la caída; si la carga no terminó, se alarga la fase de amarillo (nunca aparece un *spinner*).
- *Autosave* al aterrizar en N1. Dentro del prólogo no hay checkpoint: si se abandona, se repite entero.

## 8. Audio

Todo pre-renderizado (regla dura 5). Cuatro capas, ninguna musical.

| Capa | Archivo | Comportamiento |
|---|---|---|
| Zumbido de monitores | `ambient/office_hum_loop.ogg` (existe) | Constante en la planta; **−12 dB** al cruzar a la sala de juntas (fundido de 0,8 s); a cero durante el *hold* |
| Pasos | `sfx/footstep_shoe_01–06.wav` (existen) | Zapato nítido sobre vinilo. Es el sonido más alto del nivel: en una oficina en silencio, tú eres el ruido |
| Tono del cuadro | *nuevo* — bucle grave, casi subsónico | Inaudible fuera de la sala; sube con la cercanía al lienzo (automatización de volumen por distancia) |
| Caída | *nuevo* — una sola pista de ~4,5 s (inhalación + *whoosh* + golpe) | Se dispara al completar el *hold*; sincroniza la tabla de §7 |

Sonidos sueltos: papel al abrir un documento; picaporte y golpe seco de la puerta de salida cerrada; balastro que falla (`sfx/light_flicker.wav`) con el parpadeo de los pasillos. Capa de proximidad: ventilador de los terminales (`ambient/computer_fan_loop.ogg`, −24 dB, solo a menos de 7 m de un equipo). **Nunca**: tráfico, lluvia, aire acondicionado, teléfono, otra persona.

Leyendas de sonido (`13` §8): `[zumbido de monitores]` · `[el zumbido se apaga]` · `[un tono grave sale del cuadro]`.

## 9. Luz, paleta y materiales

- **Cero luces en tiempo real.** La única luz dinámica del juego es la linterna y en el prólogo no existe. Todo es `LightmapGI` de un solo sector: los monitores y el cuadro hornean su luz como emisivos.
- **Paleta**: grises azulados fríos y desaturados. Azul pálido de monitor como luz de relleno. El cuadro es el único acento. **Contaminación de Día de Muertos: 0%** (la escalera de `12` §9 empieza en 5% *después* de la N).
- **Sin exterior**: persianas cerradas; detrás, negro. Letrero de salida apagado.
- **Niebla** ligera (más suave que la del blockout) para que el cuadro se lea a 30 m.
- El "reflejo" del cuadro en el piso es luz horneada, no reflexión (Compatibility no tiene SSR).

Materiales (6 de 6, `docs/07`):

| # | Material | Usa |
|---|---|---|
| 1 | Atlas de paleta | Muros, mamparas, muebles, caja, utilería, placas |
| 2 | Piso vinílico (patrón) | Suelo |
| 3 | Plafón (patrón) | Techo |
| 4 | Pantallas (emisivo, atlas) | Monitores: bloqueo 23:47, correo de D01, apagado |
| 5 | Cuadro (shader propio) | Dos composiciones + distorsión de la caída |
| 6 | Vidrio | Mampara y puerta de la sala de juntas |

## 10. Marca en el prólogo

Diegética y sutil (`docs/06`): el **cuadro** (logotipo tal cual), la **caja** de embalaje con la tipografía NOHO, la **taza** de tu escritorio, el membrete de D01 y D03. Los monitores llevan el logotipo en **blanco monocromo** para no competir con el cuadro. Nada es interactivo como anuncio.

## 11. Controles y HUD

- Acciones activas: `move_*`, mirar, `interact`. **`sprint` y `flashlight` desactivados**; en móvil sus `TouchScreenButton` están ocultos y aparecen en el Nivel 1.
- HUD: solo la retícula (`13` §5).
- **Pista de inactividad** (única concesión): si pasan 8 s desde el inicio sin entrada de movimiento, aparece una vez, tenue, el gesto correspondiente (`WASD` / arrastre a la izquierda) y se va al primer movimiento. No es un *pop-up* de tutorial: quien se mueve nunca lo ve.

## 12. Cambios respecto al blockout actual

| Blockout (`prologue.tscn`) | Diseño |
|---|---|
| Jugador en el centro del pasillo (z = 10,5) | En `StartFrame`, junto al cubículo suroeste |
| `AisleBlocker` es una mampara | Es la **caja de embalaje** NOHO (bloquea la vista a la altura de los ojos, deja ver la franja superior del cuadro) |
| Sala de juntas de 8 m de ancho, muro macizo | 6 m de ancho, frente de **vidrio** |
| Cuadro de 3,2 × 1,9 m | 2,4 × 1,8 m + marco |
| Mesa centrada, ambos lados libres | Lado oeste cerrado por escalera y plástico |
| Luz ambiental 0,55, niebla 0,06 | Más oscuro y con menos niebla; luz horneada |
| Sin interacción | D01, D02, D03, puerta de salida, cuadro |

## 13. Orden de implementación

1. **Interacción**: componente interactuable + retícula + *overlay* de documentos (`13` §3.4, §5). D01–D03 con los textos de `11` §7.
2. **Blockout v2**: cambios de la §12 y los tres `Marker3D`.
3. **Cuadro**: intercambio fuera de encuadre (§6.1) y *hold* con centrado de cámara (§6.2).
4. **Caída**: shader de pantalla + secuencia de cámara + pista de audio (§7), con su variante de movimiento reducido.
5. **Audio por zonas** (§8) y leyendas.
6. **Arte final + horneado**: mallas low-poly (dirección B), atlas, `LightmapGI`.
7. **Fondo de menú** desde `MenuFrame`; variante de final (cuadro sin color) cuando exista el final.

## 14. Métricas de playtest

| Métrica | Objetivo |
|---|---|
| Duración (primera partida) | Mediana 2–3 min |
| Tiempo hasta el primer movimiento | < 8 s (si no, la pista de inactividad está fallando) |
| Jugadores atascados > 20 s sin avanzar | < 5% |
| Lectura de D01 / D03 / D02 | ≥ 70% / ≥ 60% / ≥ 40% |
| Completan el *hold* al primer o segundo intento | ≥ 90% |
| Abandono en el prólogo | < 10% |

## 15. Decisiones abiertas

| Decisión | Recomendación |
|---|---|
| ¿Hay Día de Muertos en la oficina antes de caer? El concept art B muestra calaveras en monitores y carteles | **No.** Contradice la invasión gradual (pilar 2) y le quita fuerza al Nivel 1. Como mucho, un calendario de pared en noviembre |
| ¿Usa el prólogo la voz corporativa (Alice)? | **No** en esta versión: `11` §4 prohíbe voces en off. Si se quiere, la única opción diegética es un aviso de megafonía del edificio al probar la puerta de salida |
| Hex y tipografía exactos del logotipo | Pendiente del manual de marca (`docs/06`) |

## Ver también

- Textos de D01–D03 y guion del final: [`11-historia-y-guion.md`](11-historia-y-guion.md) · Tramos y transiciones: [`12-dinamica-de-niveles.md`](12-dinamica-de-niveles.md) §7–§9
- Interacción, HUD y confort: [`13-game-experience.md`](13-game-experience.md) · Render y shader de pantalla: `docs/07` · Marca: `docs/06`
