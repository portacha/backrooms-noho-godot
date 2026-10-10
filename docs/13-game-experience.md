# Game Experience — NOHO Backrooms Escape

> **Tipo**: Documento de experiencia de juego (serie de diseño; no derivado de `investigacion.txt`).
> **Versión**: 1.0 — 2026-10-09. **Deriva de**: [`10-high-concept.md`](10-high-concept.md) (pilares, momento memorable), [`11-historia-y-guion.md`](11-historia-y-guion.md) (final), [`12-dinamica-de-niveles.md`](12-dinamica-de-niveles.md) (recursos, dificultad, reintento).
> **Normativo con**: `docs/01` (política de sustos), `docs/02` (audio >50%), `docs/03` (interacción, controles), `docs/06` (marca), `docs/07` (60 FPS, Web/Android).
> **Cierre de la serie de diseño**: este documento define **cómo se siente** el juego en las manos, no qué pasa en él.

---

## 1. Alcance

Game feel, cámara y confort, HUD, feedback de sistemas, muerte y reintento, menús, accesibilidad y el *guion de sensación* del final. Es la capa entre el diseño lúdico (`12`) y la implementación.

## 2. La promesa de experiencia

**"Estoy solo, la luz me falla cuando algo se acerca, y tengo que salir antes de que la marca me recuerde para siempre."**

Cada decisión de este documento se valida contra esa frase. Si un feedback, un menú o un efecto rompe la soledad, la fragilidad de la luz o el silencio, se corta.

## 3. Game feel — sistema por sistema

### 3.1 Movimiento y cámara

| Elemento | Especificación |
|---|---|
| FOV | 75° escritorio · 70° móvil (menos *motion sickness*) |
| Head-bob | Sutil (amplitud ~1,5% de la altura de cámara); desactivable en Opciones |
| Inclinación al correr | Ligero *roll* (≤1,5°) + escala de respiración. Nunca *motion blur* |
| Velocidad percibida | La cámara transmite lentitud deliberada: el *sprint* se siente como un esfuerzo, no como un *dash* |
| Parada de emergencia | Al soltar el movimiento, la cámara se asienta en 0,2 s (nunca oscila) |

### 3.2 Linterna (el idioma del juego)

| Situación | Feedback |
|---|---|
| Normal | Haz frío estable + zumbido eléctrico lejano (pre-renderizado) |
| Entidad cercana | Parpadeo con **ritmo reconocible** (parpadeo = radar): más rápido = más cerca |
| Fallo fuerte | Apagado + rugido EM grave + vibración (móvil) |
| N4 | El haz **revela senderos de pétalos** con un brillo cálido al barrerlos |
| Recogida de letra | Las veladoras del altar se encienden una a una (bloom + swell de audio) |

Regla: el jugador debe poder **leer la linterna sin mirar ningún HUD**. El parpadeo es la interfaz.

### 3.3 Resistencia (invisible, presente) — retirada

> **Enmienda 2026-10-09 (prevalece):** se retiran la **resistencia** y los **niveles de dificultad**. El jugador corre siempre que quiera, sin consumo, jadeo ni señales de cansancio; el precio de correr es solo el **ruido**. Hay una única dificultad, el **ajuste estándar** (los valores "Intermedio" de `docs/12`, en `scripts/core/difficulty.gd`). Añadir perfiles se decidirá cuando el estándar esté afinado. Tampoco hay selector de dificultad en el menú (§5), en la pausa ni en opciones (§8): esas menciones quedan sin efecto.

Sin barra jamás (`docs/03`). Se comunica por: respiración (audio pre-renderizado por intensidad), oscilación sutil de cámara, y oscurecimiento periférico leve al agotarse (<20 u). En **Fácil** (resistencia ∞) estos cues desaparecen por completo, no se desactivan a medias.

### 3.4 Interacción

| Objeto | Acción | Feedback |
|---|---|---|
| Documento | Toque / clic (instantáneo) | Retícula se expande a anillo + sonido de papel + overlay de lectura |
| Puerta | Toque / clic | Tirador animado + crujido pre-renderizado |
| Letra-altar | **Mantener 1,5 s** (ritual) | Anillo de progreso tenue + encendido de veladoras + perturbación |
| Gafete final | Automático | Sin interacción: la cámara baja sola |

Retícula: punto central de 4 px que se expande a anillo de 24 px solo dentro del rango de acción (`docs/03`). Es **toda** la UI permanente del juego.

## 4. Confort y *motion sickness* (crítico en Web y móvil)

- Opción **"Movimiento de cámara reducido"**: elimina head-bob, roll y oscilaciones; solo queda el desplazamiento.
- Opción **"Invertir eje Y"** y **sensibilidad de cámara** (móvil: porcentaje; escritorio: *slider*).
- Giro en móvil (`InputEventScreenDrag`, mitad derecha): curva suave de aceleración, sin *snapping*.
- Transiciones de nivel (§9 de `12`) sin *flash* blanco: aberración cromática sí, fotogramas de contraste máximo no.
- Pausa real disponible en cualquier momento (ver §6): quien necesita parar, para.

## 5. HUD y UI en partida (minimalismo extremo)

| Elemento | Comportamiento |
|---|---|
| Retícula | Único elemento permanente |
| Indicador de interacción | Solo en rango |
| Overlay de documentos | Papel sobre pantalla, tipografía monoespaciada para voz corporativa, manuscrita para voz íntima (`11` §4); se cierra con cualquier botón/atraso |
| **Nunca** | Vida, resistencia, munición, minimapa, marcadores de objetivo, flechas de guía, contadores |

En móvil, `TouchScreenButton` de *sprint* y linterna en `CanvasLayer` (siempre sobre la geometría, `docs/03`), opacidad ~35% y tamaño configurables; safe areas respetadas (notch/Android). En escritorio, sin iconos: WASD + Shift + F + E (`docs/03`).

## 6. Menús, pausa y pantallas de resolución

### 6.1 Menú principal
- Fondo **diegético**: la oficina del prólogo con el cuadro NOHO (la marca vive aquí, no en partida).
- **JUGAR** es el botón primario, un toque, siempre visible. Nada lo retrasa (regla de `docs/06`).
- Debajo: **Dificultad** (selector segmentado de 3, §4.3 de `12`), **Opciones**, **Créditos**.
- Presencia de marca de alto impacto permitida aquí (lockup NOHO) — es el vehículo publicitario, no el juego.

### 6.2 Pausa
- **Pausa real** (single-player offline): la entidad se congela y el audio hace *fade* al 10% en 0,3 s. El horror no castiga a quien necesita atender el mundo real (audiencia casual/móvil).
- Menú de pausa: Reanudar · Dificultad (efecto en el siguiente tramo) · Opciones · Menú principal. Nunca redirige a marca.

### 6.3 Pantalla de muerte
- Negro + **una sola línea de la voz grabada** (calaverita, `11` §7) + botón **REINTENTAR** (teclado: Enter/espacio; táctil: tap en cualquier lado).
- Tiempo objetivo **muerte → juego activo: < 8 s**. No hay menú automático, no hay animación de espera.
- Marca: bloque secundario opcional (`docs/06`: la derrota es pantalla de resolución), **subordinado** al botón Reintentar. Nunca bloquea.

### 6.4 Pantalla de victoria
- Primer plano del **gafete** (D16) → *fade* → pantalla de resolución con CTA de **lovenoho.com** y código promo (`docs/06`).
- Botones: **Jugar de nuevo** (reinicia en el perfil elegido) · **Menú**. La marca es el premio, no el muro.
- El silencio del cruce se rompe aquí con el audio de marca, nunca con música de juego.

## 7. Muerte y reintento (feel)

| Beat | Especificación |
|---|---|
| Captura | `AttackState` toma la cámara (`docs/05`): encuadre forzado + chillido de alarma/silbato (`docs/05`) + animación breve (≤1,5 s) |
| Apagón | 0,5 s de negro absoluto, audio cortado (eco del cruce final) |
| Reintento | Pantalla §6.3 → checkpoint (`12` §10) con entidad reubicada según perfil |
| Susto | El *shock* de la captura está **racionado**: es el único *scare* garantizado por nivel, junto a la captura misma (`docs/01`) |
| Frustración | Regla de compasión de `12` §4.5; tras 3 muertes seguidas en el mismo tramo, un *hint* diegético (los pétalos marcan el camino durante 10 s) |

*Screen shake*: máximo en 3 eventos de toda la partida — recogida de letra, inicio de la persecución final, captura. Racionado como los sustos (`docs/01`).

## 8. Accesibilidad y usabilidad

| Necesidad | Solución |
|---|---|
| **Jugar sin auriculares** (móvil) | **Leyendas de sonido** opcionales: texto discreto abajo-izquierda que nombra el sonido sin explicar la trama, ej. `[pasos que imitan tu ritmo — lejos]`. + vibración del móvil como radar EM (pulso corto al parpadear la linterna, pulso largo con entidad <6 m) |
| **Baja visión / contraste** | Pétalos naranjas y neón magenta siempre con halo de brillo (nunca solo por color); texto de documentos con fondo opaco y zoom hasta 200% |
| **Daltonismo** | La jerarquía informativa (luz = seguridad, oscuridad = peligro, neón = salida) no depende del color: se refuerza con forma y movimiento |
| **Motricidad** | Controles táctiles con tamaño/opacidad configurables; sin acciones que exijan mantener botones (la letra usa *hold* de 1,5 s con tolerancia) |
| **Sesión corta** | Autosave silencioso al inicio de cada tramo; retomar en <5 s desde el menú |
| **Dificultad** | Selector de 3 perfiles (`12` §4); **Fácil** es el modo historia/casual, diseñado con el mismo cuidado |
| **Confort** | Opciones de §4 (movimiento reducido, sensibilidad, FOV, head-bob, vibración, leyendas de sonido, volúmenes) |

Ubicación: todas las opciones en un solo panel del menú, con previsualización inmediata. Ninguna opción requiere reiniciar la partida salvo el perfil de dificultad (siguiente tramo).

## 9. Audio como experiencia (operativo)

- El audio carga **>50% del terror** (`docs/02`): se presupuesta y se mezcla antes que el arte de partículas.
- **Web = un hilo, sin `AudioEffect` en buses** (regla dura 5): toda la mezcla es pre-renderizada. *Ducking*, filtros y *pitch* se resuelven en los propios archivos y con automatización de volumen de `AudioStreamPlayer`.
- Capas por nivel (resumen de `docs/02`): zumbido eléctrico → viento + campanas → guitarra distorsionada y lenta (nostalgia corrupta).
- El beat de audio más importante de la partida: **el silencio de 0,5 s al cruzar la puerta final**. Se construye todo el juego para que ese silencio se oiga.

## 10. Performance feel

- **60 FPS** como estándar de sensación, no solo de métrica (`docs/07`): el *stutter* rompe el terror más que cualquier baja de calidad.
- *Loading*: pantalla de carga con el neón de marca (no con spinners); primer frame jugable en <3 s en móvil medio.
- Escala de render en móvil (resolución interna) con umbral: nunca por debajo de la legibilidad de la retícula.
- Presupuesto de partículas/luces: la linterna es la única luz en tiempo real (regla dura 4); el resto es emisión y `LightmapGI`.

## 11. El momento memorable (guion de sensación)

Secuencia subjetiva del sprint final (`11` §9 + `12` §8.4), beat a beat:

1. **La letra se enciende.** Las veladoras arden; el altar tiembla; por primera vez el juego te da algo (bloom, swell).
2. **El entorno se rompe.** Luces rojas, clímax ensordecedor, la geometría falla. *Screen shake* #2.
3. **La carrera.** 18 s (perfil Intermedio). La linterna muere; el neón magenta es lo único que queda. La respiración es lo único que se oye encima del caos.
4. **El cruce.** Silencio. **Absoluto.** Ni zumbido, ni pasos, ni aliento. (0,5 s que la jugadora recuerda años después.)
5. **El retorno.** La oficina, el cuadro, sin color. Todo normal. Demasiado normal.
6. **El gafete.** La cámara baja sola. La marca te recuerda. Sonrisa incómoda.
7. **Negro → marca.** CTA y código promo. Fin de la sesión.

## 12. Ritmo de sesión y retención

| Punto | Diseño |
|---|---|
| Sesión completa | 30–45 min (`12` §7), jugable en 1–2 sesiones por el autosave por tramo |
| Primeros 3 min | Prólogo: la interacción se enseña con D01 en la única ruta; la linterna brilla sola en la recepción (tutorial diegético) |
| Rejugabilidad | Documentos ocultos (16 piezas, `11` §7), perfiles de dificultad, y la curiosidad de "qué pasa si miro a la criatura" |
| Fin de sesión natural | Tras la victoria: pantalla de resolución con "Jugar de nuevo" — la marca cierra el bucle, no lo interrumpe |

## 13. Guardas de la experiencia (qué NO)

- HUD denso, números de daño, barras, flechas de objetivo, *pop-ups* de tutorial.
- *Jump scares* baratos o constantes: máximo uno guionizado por nivel + la captura (`docs/01`).
- Música constante; el silencio es herramienta activa.
- Publicidad durante la partida; interrupciones que retrasen "Jugar" o "Reintentar" (`docs/06`).
- Cinemáticas largas o explicativas; el misterio no se cierra (`10` §3).
- Trucos de *fake-pause* o penalizaciones a quien pausa.

## 14. Métricas de experiencia

| Métrica | Objetivo |
|---|---|
| Finalización por perfil | F ≥ 85% · I ≥ 60% · D ≥ 40% (`12` §13) |
| Tiempo muerte → reintento | < 8 s (mediana) |
| Uso de opciones de confort | > 20% activa al menos una (si es <5%, la opción no se está encontrando) |
| Activación de leyendas de sonido | > 15% en móvil |
| Satisfacción del final | > 70% valora el gafete como "me gustó / me incomodó" (el objetivo es la incomodidad cómplice) |
| Sesiones por partida | 1–2 |

## 15. Orden sugerido de implementación (fase de producción)

1. Movimiento + cámara + confort (§3.1, §4) sobre el prólogo.
2. Interacción + retícula + overlay de documentos (§3.4, §5).
3. Linterna como lenguaje + audio pre-renderizado base (§3.2, §9).
4. Reintento + checkpoints + pantallas de resolución (§6, §7).
5. Perfiles de dificultad + opciones de accesibilidad (§8) con `12` §4.
6. Pase de game feel (vibración, bloom, *screen shake* racionado) y validación de métricas (§14).

## Ver también

- Pilares y momento memorable: [`10-high-concept.md`](10-high-concept.md) · Guion del final y voz: [`11-historia-y-guion.md`](11-historia-y-guion.md)
- Recursos, dificultad y reintento: [`12-dinamica-de-niveles.md`](12-dinamica-de-niveles.md)
- Mecánicas y controles: `docs/03` · Audio y paleta: `docs/02` · Marca: `docs/06` · Render y exports: `docs/07` · Playtests: `docs/08`
