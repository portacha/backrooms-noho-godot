# Resumen Ejecutivo y Visión del Proyecto

> Fuente: `investigacion.txt` — sección "Resumen Ejecutivo y Visión del Proyecto".
> Proyecto: **Backrooms NOHO**.

## Concepto central

El presente documento establece la arquitectura técnica, la dirección de arte y el diseño lúdico para un videojuego de **terror psicológico y escape en primera persona**. El concepto central articula una fusión inédita entre:

- El **horror de los espacios liminales**, popularizado por el fenómeno de internet conocido como "The Backrooms".
- La rica **estética cultural del Día de Muertos mexicano**.

El jugador asume el rol de un **oficinista** que, tras interactuar con un cuadro corporativo de la marca **NOHO**, experimenta un colapso en la realidad y es transportado a una dimensión de pasillos infinitos, donde la única vía de escape consiste en **recolectar las cuatro letras que conforman la marca (N-O-H-O)**.

## Experiencia interactiva

La experiencia interactiva está diseñada para maximizar la inmersión a través de mecánicas de juego minimalistas pero tensas. El usuario está limitado a:

- Caminar.
- Correr gestionando su resistencia.
- Iluminar su entorno con una **linterna de comportamiento errático**.
- Acercarse a objetos para interactuar con ellos.

Agacharse y ocultarse son **automáticos** (los decide el entorno, sin botón propio); ver `docs/03`.

## Motor y plataformas objetivo

El proyecto se construirá utilizando el motor de código abierto **Godot 4.7**, optimizado específicamente para garantizar un rendimiento fluido y sin interrupciones tanto en:

- **Navegadores web** (exportación HTML5/WebAssembly, WebGL 2, un solo hilo).
- **Dispositivos móviles** bajo el sistema operativo **Android**.

## Estrategia publicitaria (visión general)

Para salvaguardar la atmósfera opresiva que requiere el género de terror liminal, la marca aparece poco y nunca interrumpe (enmienda 2026-10-09, ver `docs/06`):

| Ámbito | Tipo de integración |
|---|---|
| Bucle de juego principal | Completamente **diegética**: elementos del entorno que evocan sutilmente a **NOHO** |
| Menú de inicio y pantallas de victoria/derrota | Presencia **mínima y no bloqueante**, solo de NOHO, con los colores de la marca como acento |

No hay anuncios de terceros ni nada que retrase "Jugar" o "Reintentar".

## Documentos relacionados

- [01 — Análisis legal y mitología liminal](01-legal-y-mitologia-liminal.md)
- [02 — Diseño temático (Liminalidad × Día de Muertos)](02-diseno-tematico.md)
- [03 — Mecánicas de interacción y sistemas del jugador](03-mecanicas-y-controles.md)
- [04 — Progresión narrativa y diseño de niveles](04-niveles-y-progresion.md)
- [05 — Diseño de entidad y arquitectura de IA](05-entidad-y-ia.md)
- [06 — Estrategia de monetización y presencia de marca](06-monetizacion-y-marca.md)
- [07 — Arquitectura de renderizado y optimización en Godot 4.7](07-render-y-optimizacion.md)
- [08 — Flujos de trabajo y desarrollo asistido por IA](08-desarrollo-asistido-por-ia.md)
- [09 — Referencias visuales y adquisición de activos tridimensionales](09-activos-3d-audio-y-referencias.md)
- [10 — High Concept](10-high-concept.md)
