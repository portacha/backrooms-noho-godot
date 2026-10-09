# High Concept Document — Backrooms NOHO

> **Tipo**: High Concept Document (documento de diseño de partida, no derivado de `investigacion.txt`).
> **Versión**: 1.1 — 2026-10-09 (alineado con las enmiendas de `docs/00`–`09`). **Nombre interno de producción**: *Mictlán Corporativo*.
> **Función**: brújula de la serie de diseño **historia → dinámica de niveles → game experience**. Todo documento posterior se deriva de este; si contradice `docs/00`–`docs/09`, ganan esos documentos y este se corrige.
> **Canon**: contenido original obligatorio (ver `docs/01`). Prohibido usar niveles, entidades o facciones de las wikis de Backrooms.

---

## 1. Pitch de ascensor (15 segundos)

Un oficinista toca un cuadro corporativo de **NOHO** y cae fuera de la realidad: pasillos infinitos, pétalos de cempasúchil sobre la alfombra húmeda, zumbido eléctrico. Para escapar debe recuperar **N · O · H · O** — las cuatro letras de la marca, ahora altares en un Mictlán corporativo — antes de que *El Olvidado* lo encuentre. **No hay armas.** Solo una linterna que falla cuando algo se acerca.

## 2. High concept (una frase)

**Terror liminal de escape en primera persona donde la marca es la salida: el inframundo del Día de Muertos filtrado a través de la arquitectura corporativa.**

| Ecuación | Aporta |
|---|---|
| *Backrooms* / espacios liminales | Geometría repetitiva, incomodidad por ausencia de propósito |
| Día de Muertos × Mictlán | Invasión estética gradual: cempasúchil, papel picado, calaveras, ofrendas |
| Horror sin combate (*Amnesia*, *Outlast*) | Vulnerabilidad total: caminar, correr, iluminar, interactuar |
| Advergame **NOHO / lovenoho.com** | La marca no interrumpe el juego: **es** la mecánica de escape |

## 3. Pilares de diseño (normativos)

| # | Pilar | Exige | Prohíbe |
|---|---|---|---|
| 1 | **Vulnerabilidad sin combate** | Caminar, sprint con resistencia, linterna, interacción por proximidad; agacharse y ocultarse automáticos | Armas, ataque, barra de vida, muerte por combate |
| 2 | **Invasión gradual, nunca corte** | El Día de Muertos contamina lo corporativo por acumulación (paleta, luz, audio) | Niveles "temáticos" que cambian de golpe de estilo |
| 3 | **Misterio absoluto** | La dimensión nunca se explica; el miedo es el catalizador | Cinemáticas explicativas, lore derivado de las wikis |
| 4 | **Audio primero** | Silencio opresivo + zumbido + eco de pasos; el audio carga >50% del terror; jump scares racionados (máx. uno guionizado por nivel + la captura) | Música constante, jump scares baratos o constantes, sobreexposición del monstruo |
| 5 | **La marca es llave diegética** | En partida, NOHO solo existe dentro del mundo del juego; fuera, presencia mínima en menú y pantallas finales | Anuncios de terceros, banners, pop-ups, esperas o interrupciones |

## 4. Jugador objetivo

- **Perfil**: 16–35 años, afines al horror liminal / creepypasta / fandom de los Backrooms; público hispanohablante y global casual.
- **Plataformas**: navegador web (desktop, WASD + ratón) y Android (táctil). Motor Godot 4.7, renderer Compatibility, binario < 100 MB.
- **Sesión**: partida completa **30–45 min**; nivel individual **6–10 min**; rejugable por documentos narrativos ocultos y ritmo de huida.
- **Competencias que exige**: navegación espacial, lectura de pistas auditivas, gestión del pánico (resistencia y linterna). Sin curva de combate.

## 5. Estructura de partida y arco afectivo

| # | Nivel | Letra | Emoción dominante | Mecánica que la produce | Duración |
|---|---|---|---|---|---|
| 0 | Prólogo: "La Oficina de la Realidad" | — | Inquietud cotidiana | Oficina estéril sin sonido exterior; el cuadro NOHO como único color | ~3 min |
| 1 | "El Laberinto de Papel Tapiz" | **N** | Paranoia | Líneas de visión rotas + pasos espejo en habitaciones adyacentes (solo audio) | ~6 min |
| 2 | "Las Ofrendas Infinitas" | **O** | Pavor reverente | Primera manifestación visible de El Olvidado; evitar iluminarlo directamente | ~8 min |
| 3 | "El Pasaje de las Calaveras" | **H** | Opresión / sigilo | Agua que penaliza el ruido; linterna fallando; cazador activo | ~9 min |
| 4 | "El Umbral del Mictlán" | **O** | Vértigo y pánico | Caídas que reinician el puente; clímax desesperado hacia la puerta | ~10 min |
| — | Escape y final | **NOHO** | Catarsis inquietante | Sprint final, silencio de golpe, retorno con accesorio de lovenoho.com | ~2 min |

**Arco afectivo global**: inquietud → paranoia → pavor reverente → opresión → vértigo y pánico → catarsis inquietante. Ningún nivel se sale de su emoción dominante; los **remansos de veladoras** (`docs/02`) son las únicas pausas, breves y contemplativas.

## 6. Bucle de juego

**Micro-bucle (segundo a segundo)**: iluminar → escuchar → decidir (avanzar / quedarse quieto a oscuras en un escondite / correr) → gestionar resistencia y fallos de linterna. Ocultarse no es un botón: es estar quieto, sin luz, en el sitio adecuado (`docs/03`).

**Bucle de nivel**: explorar el laberinto → recoger documentos narrativos → localizar la letra-altar → interactuar con ella → el nivel colapsa parcialmente (transición). Cada recolección desestabiliza el siguiente tramo: sube la presión de El Olvidado y avanza la invasión estética (paleta, luz, audio).

## 7. Premisa narrativa (resumen)

Un oficinista de cualquier corporación se queda solo frente a un cuadro de **NOHO** en la sala de juntas. Al tocarlo, la realidad se quiebra y cae a través de la pintura a un espacio que combina la esterilidad infinita de una oficina con los ritos del Mictlán. En ese lugar, las cuatro letras de la marca son **altares-ofrenda** que mantienen sellada la salida. *El Olvidado* —algo que también fue oficinista, o eso sugieren los documentos— patrulla el descenso. Al reunir **N-O-H-O**, el jugador abre la puerta de roble bajo el neón magenta y regresa a la oficina… llevando puesto un accesorio de **lovenoho.com**.

El protagonista **no lleva nombre propio en pantalla**: su identidad solo aparece fragmentada en documentos encontrados (decisión que protege el pilar 3 y el aislamiento).

> Desarrollo completo (arco, documentos encontrados, voz narrativa, mito de El Olvidado, final): `docs/11-historia-y-guion.md`.

## 8. Amenaza — *El Olvidado* (resumen)

Anomalía biomecánica de más de 2.5 m: extremidades de cables de telecomunicaciones y hueso ennegrecido, rostro-vacío que derrama pétalos de cempasúchil, traje de oficinista fusionado con atuendo de charro. IA por **FSM de nodos** con cinco estados (`Wander`, `Investigate`, `Chase`, `Ambush`, `Attack`) y un perfil por nivel; las transiciones no son lineales (ver `docs/05`).

Escalada por nivel: **(1)** solo audio / pasos espejo → **(2)** manifestación distante; iluminarlo directamente lo hace chillar y reaparecer más cerca → **(3)** cazador activo atraído por el ruido del agua → **(4)** modo enfurecido con fallos sistémicos del entorno.

**Regla dura**: el monstruo se muestra poco y se intuye mucho (pilar 4).

## 9. Tono, arte y audio (resumen)

- **Arte**: Low Poly + iluminación horneada y posprocesado cinematográfico (sombras suaves, corrección de color agresiva, resplandor, niebla, aberración cromática puntual) = *valle inquietante*. Ver `docs/09` y `docs/07`.
- **Paleta**: monocromo amarillo → contaminación naranja de cempasúchil + destellos magenta de papel picado → negro absorbente.
- **Luz**: fluorescentes fríos LED → oscuridad con remansos de luz cálida de veladoras, mínima y solo en zonas concretas.
- **Audio**: zumbido eléctrico que muta a viento distante, campanas fúnebres tenues y guitarra acústica distorsionada y ralentizada (nostalgia corrupta). Todo pre-renderizado; efectos y voces con ElevenLabs. Ver `docs/02` y `docs/09`.

## 10. Marca y monetización (bloque no negociable)

| Ámbito | Regla |
|---|---|
| Bucle de juego | **Diegético exclusivamente**: el cuadro y objetos de oficina membretados que evocan lovenoho.com; las letras N-O-H-O *son* la marca |
| Menú y pantallas de resolución | Solo NOHO, **mínima y no bloqueante**, con los colores del logotipo (azul, blanco, naranja) como acento; código promo al ganar — ver `docs/06` |
| Recompensa narrativa del final | El accesorio de lovenoho.com que el personaje lleva de vuelta al mundo real |

## 11. Unique selling points

1. **Fusión inédita** liminalidad (Backrooms) × Día de Muertos / Mictlán — un "Mictlán corporativo" sin equivalente en el mercado.
2. **La marca es mecánica de escape**: el logotipo literalmente abre la puerta. Advergame que no rompe el terror.
3. **Linterna sin baterías pero electromagnéticamente frágil**: falla con la proximidad del enemigo, forzando navegación a ciegas.
4. **Invasión estética gradual**: paleta, luz y audio mutan a lo largo del descenso; el tema es progresión, no decorado.
5. **IA por FSM con modos por nivel**, incluida la evitación de iluminación directa y la emboscada anti-estancamiento.
6. **Accesibilidad de plataforma**: 30–45 min, < 100 MB, web + Android, 60 FPS en renderer Compatibility.

## 12. Momento memorable

El sprint final a través del vacío colapsante —luces rojas de emergencia, clímax ensordecedor— hacia la puerta monumental de roble bajo el neón magenta **"NOHO"**… y el **silencio absoluto** al otro lado.

## 13. Lo que este juego NO es (guardas de alcance)

- No es un shooter ni un survival de combate: **no hay armas ni lucha**.
- No es un walking sim con voces: la historia es **ambiental y por documentos**, sin actores que expliquen la trama.
- No usa el canon de las wikis de Backrooms (niveles numerados, Smilers, Partygoers, M.E.G., etc.) — ver `docs/01`.
- No tiene mundo abierto, multiplayer, inventario ni crafting.
- **No interrumpe la partida con publicidad** bajo ninguna forma, ni muestra anuncios de terceros en ningún momento.

## 14. Riesgos y mitigaciones

| Riesgo | Mitigación |
|---|---|
| Monotonía del laberinto repetitivo | Mutaciones sutiles de geometría + evento de audio/hallazgo por tramo (cuantificar en `docs/12`) |
| Sobreexposición de El Olvidado | Presupuesto de apariciones visibles y de jump scares por nivel; el audio prescinde de él (pilar 4) |
| Audio sin efectos en tiempo real en Web | Todo pre-renderizado, con variantes por tipo de recinto (`docs/09`) |
| Uso de "Backrooms" en el título | Validación legal pendiente; nombre de reserva *Mictlán Corporativo* (`docs/01`) |
| Terror diluido en móvil (pantalla pequeña, sin auriculares) | HUD mínimo + pistas de audio con refuerzo visual discreto (a resolver en game experience) |
| Expectativa de "otro Backrooms de wiki" | Comunicar el canon original desde el menú (sin prometer lore de las wikis) |
| Publicidad rompiendo la inmersión | Marca diegética en partida y mínima fuera de ella (`docs/06`); nada bloquea "Jugar" ni "Reintentar" |

## 15. Decisiones ya cerradas por este documento

- Título comercial: **Backrooms NOHO**. Nombre interno de producción: *Mictlán Corporativo*.
- Protagonista **sin nombre propio en pantalla**; identidad solo en documentos encontrados.
- Duración objetivo de partida: **30–45 min**, seis tramos (prólogo + 4 niveles + escape).
- Silencio del audio como herramienta de terror activa (no solo ausencia de música).
- El final devuelve al jugador al mundo real con producto de lovenoho.com: cierre irónico del advergame.

## 16. Próximos documentos de la serie

| Documento | Resuelve | Depende de |
|---|---|---|
| [`11-historia-y-guion.md`](11-historia-y-guion.md) | Arco narrativo, voz, documentos encontrados, mito de El Olvidado, finales | Pilares §3, premisa §7 |
| `12-dinamica-de-niveles.md` (pendiente) | Bucle por nivel, pacing, economía de recursos, curva de presión, fail states y checkpoints | Estructura §5, amenaza §8 |
| `13-game-experience.md` (pendiente) | Game feel, feedback, cámara, HUD, accesibilidad, muerte/reintento, dificultad | Todo lo anterior |

## Ver también

- Visión y restricciones de origen: `docs/00` · Legal y canon: `docs/01` · Temática: `docs/02`
- Mecánicas y controles: `docs/03` · Niveles: `docs/04` · IA: `docs/05` · Marca: `docs/06`
- Render: `docs/07` · Flujos con IA: `docs/08` · Assets y audio: `docs/09`
