# Diseño Temático: Sincretismo entre Liminalidad y el Día de Muertos

> Fuente: `investigacion.txt` — sección "Diseño Temático: Sincretismo entre Liminalidad y el Día de Muertos".
> **Enmendado 2026-10-09**: papel de las veladoras (remansos) y audio pre-renderizado.

## Vector narrativo y visual

El vector narrativo y visual del juego radica en la **transición paulatina** desde un horror corporativo de estilo occidental hacia una representación liminal del **Mictlán**, el inframundo de la mitología mexica, enmarcado en la iconografía del **Día de Muertos**. Esta progresión temática no se presenta de forma abrupta, sino mediante una **invasión gradual** de elementos culturales sobre la arquitectura estéril de las oficinas infinitas.

## Paleta de colores

La paleta de colores experimenta una metamorfosis constante a medida que el jugador desciende por los niveles:

| Fase | Composición cromática |
|---|---|
| Inicial | Monotonía amarilla y monocromática |
| Contaminación progresiva | Vibrante **naranja de las flores de cempasúchil** |
| Contaminación progresiva | Destellos de **magenta** provenientes de decoraciones de **papel picado** translúcido |
| Contaminación progresiva | Presencia absorbente del **negro absoluto** en las áreas desprovistas de geometría |

Los colores del logotipo NOHO (azul, blanco y naranja) **no forman parte de esta paleta**: solo aparecen en los objetos de marca y en las interfaces de menú y cierre (ver `docs/06`).

## Iluminación

La iluminación acompaña este descenso, transformando las **frías luces fluorescentes LED** (que dominan los primeros pasillos) en fuentes de **luz cálidas, orgánicas y parpadeantes** provenientes de **veladoras de cera** dispuestas de forma irracional.

### Remansos de veladoras

Las veladoras dan **luz mínima y solo en zonas concretas**; no iluminan el nivel. Fuera de ellas siguen mandando la oscuridad y la linterna, así que la tensión no se pierde.

Esas zonas —pequeñas ofrendas encendidas en un recodo, y las salas de las letras— funcionan como **remansos**: pausas contemplativas donde el jugador recupera el aliento, lee un documento y mira de cerca la iconografía. Reglas:

- El Olvidado **no ataca dentro de un remanso** ni hay jump scares en ellos (salvo la sala de la última letra, donde el clímax rompe la regla a propósito).
- Son pocos (2–3 por nivel) y pequeños; su calidez contrasta con el frío del resto y hace más duro volver a salir.
- La luz que proyectan está horneada; solo parpadea la llama (ver `docs/07`).

## Diseño de audio

El diseño de audio opera bajo los mismos principios de sincretismo. El clásico **zumbido eléctrico** de la corriente alterna mutará sutilmente al progresar el juego, mezclándose con fenómenos acústicos como:

- El soplido de un **viento distante** en recintos cerrados.
- El tañido de **campanas fúnebres** de muy baja intensidad.
- El eco reverberante de **acordes de guitarra acústica** que han sido distorsionados y ralentizados digitalmente para evocar una sensación de **nostalgia corrupta**.

Toda distorsión, ralentización, eco y reverberación va **incorporada en los archivos de audio** (pre-renderizada), no aplicada por el motor: el export Web no soporta efectos en tiempo real. Ver `docs/09`.

## Elementos interactivos como faros

Los elementos interactivos actúan como faros en esta amalgama estética.

### Linterna

La linterna del jugador comienza proyectando un haz de **luz fría de oficina**, pero en los niveles inferiores su luz revela **propiedades ocultas en el entorno**, como senderos de **pétalos de cempasúchil** en el suelo, visibles solo dentro del cono de luz (shader, ver `docs/07`), que actúan como **guías espirituales tradicionales**, apuntando sutilmente hacia los objetivos.

### Letras N, O, H, O como altares

Las letras monumentales **N, O, H, O**, que funcionan como las llaves de salida del laberinto, se conceptualizan como **altares u ofrendas**. Cada estructura tipográfica está esculpida en materiales que evocan la festividad:

- Madera de **copal** tallada.
- **Cráneos de azúcar** cristalizada de tamaño arquitectónico.
- Piedra de **obsidiana** pulida.

Estas letras emiten un **resplandor de neón** que contrasta la modernidad de la marca corporativa **lovenoho.com** con el misticismo atávico del folclore mexicano.
