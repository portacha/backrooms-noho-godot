# Arquitectura de Renderizado y Optimización en Godot 4.7

> Fuente: `investigacion.txt` — sección "Arquitectura de Renderizado y Optimización en Godot 4.7".
> **Enmendado 2026-10-09** tras contrastar con la documentación de Godot 4.7: export Web de un solo hilo (sin COOP/COEP), culling por sectores, luz dinámica, geometría mutante, posprocesado, atlas y export Android. Donde difiera de `investigacion.txt`, gana este documento.

## Motor y requisitos

El proyecto usa **Godot 4.7** y debe funcionar sin latencia tanto en **navegadores web** (HTML5/WebAssembly, WebGL 2) como de forma nativa en **teléfonos Android** de gama media.

**Objetivo de rendimiento: 60 FPS sostenidos.**

## Selección del renderizador: Compatibility

El proyecto queda **bloqueado en el renderizador Compatibility** (OpenGL / GLES3 / WebGL 2). Forward+ y Mobile dependen de Vulkan y no son viables en Web.

Consecuencia de diseño: todo efecto visual debe poder hacerse con lo que Compatibility ofrece (ver "Posprocesado"). No se diseña ningún efecto que dependa de SSAO, SSR, SDFGI ni niebla volumétrica.

## Pilar 1 — Reducción de Draw Calls

La estética es Low Poly de **colores planos** (`docs/09`), así que no hay "cientos de texturas": hay muy pocos materiales.

- **Una textura de paleta/atlas por nivel** (máx. 1024×1024) con los colores planos y los pocos detalles pintados (vetas, manchas, bordados).
- **Materiales de patrón repetido** aparte solo donde el mosaico es imprescindible: papel tapiz, alfombra, agua, papel picado.
- **Presupuesto: máximo 6 materiales por nivel**, compartidos por todas las mallas.
- Elementos repetidos en masa (veladoras, pétalos, columnas, archiveros) con **`MultiMeshInstance3D`**.

## Pilar 2 — Visibilidad: culling por sectores

`OccluderInstance3D` **no funciona en las plantillas Web por defecto** (requiere compilar plantillas propias con `module_raycast_enabled=yes`) y no aporta nada en espacios abiertos. Por eso la visibilidad no depende de él:

| Técnica | Dónde | Detalle |
|---|---|---|
| **Sectores** (obligatorio) | Todos los niveles | Cada nivel se divide en sectores (escenas independientes). Solo están visibles y procesando el sector actual y sus vecinos directos; el resto se oculta mediante disparadores `Area3D` en los umbrales. |
| **Niebla de profundidad + oscuridad** (obligatorio) | Niveles 2 y 4 (espacios abiertos) | La niebla del `Environment` y el `far` de la cámara limitan la distancia de dibujado. La oscuridad es parte de la estética, no un parche. |
| **`visibility_range`** | Niveles 2 y 4 | Utilería pequeña desaparece a distancia. |
| **`OccluderInstance3D`** (opcional) | Android, niveles 1 y 3 | Mejora adicional en laberintos cerrados. Requiere `rendering/occlusion_culling/use_occlusion_culling = true` y hornear los oclusores. En Web simplemente no actúa. |

## Pilar 3 — Iluminación horneada (LightmapGI)

> **Enmendado 2026-10-09**: el prólogo y el Nivel 1 hornean la luz en **colores de vértice** con `tools/build_levels.gd` en lugar de `LightmapGI` (no se puede hornear sin editor). La regla no cambia: cero luces en tiempo real salvo la linterna. Detalle en `docs/15` §2.

Toda la **iluminación estática** se hornea con `LightmapGI`: fluorescentes de oficina, resplandor de veladoras, fosforescencia de las calaveras, neón de las letras.

- Cada **sector se hornea por separado** con su propio `LightmapGI`. Los sectores se unen en umbrales oscuros (marcos de puerta, recodos) para que no se note la costura de luz.
- El horneado se hace en el **editor de escritorio** con una GPU compatible con Vulkan; los datos horneados se ejecutan en Compatibility. Si el editor en Compatibility no permite hornear, se cambia temporalmente el proyecto a Forward+ solo para hornear. *(Pendiente de confirmar en el primer horneado.)*

### Luz dinámica

**Única luz en tiempo real: la linterna** (`SpotLight3D` con sombras). Todo lo demás que "parece" luz dinámica se resuelve sin luces:

| Efecto | Técnica |
|---|---|
| Parpadeo de veladoras | La luz que proyectan está horneada y es fija; solo parpadea la **llama** (material emisivo animado por shader) y, sutilmente, un halo aditivo. |
| Parpadeo de fluorescentes | Emisión del tubo animada por shader; la luz horneada no cambia. |
| Luces rojas de emergencia (clímax) | `Tween` sobre el `Environment` (color ambiental, niebla, corrección de color) + materiales emisivos rojos. Sin luces nuevas. |
| Senderos de pétalos que revela la linterna | Shader del material de pétalos que recibe posición y dirección de la linterna como *shader globals* y solo se muestra dentro del cono. |
| Fallos de la linterna | Se anima la energía del propio `SpotLight3D`. |

### Veladoras: luz mínima, zonas concretas

Las veladoras **no iluminan el nivel**: su luz es de corto alcance y aparecen solo en **zonas específicas** (remansos de ofrenda, las salas de las letras). Fuera de ellas manda la oscuridad y la linterna. Esto mantiene la tensión y da a esas zonas un papel de pausa contemplativa (ver `docs/02`).

## Geometría mutante ("no euclidiana")

Los lightmaps, el navmesh y los oclusores son estáticos, así que la geometría no se deforma en tiempo real. La mutación se consigue con dos trucos baratos:

1. **Variantes de sector**: algunos sectores tienen 2–3 variantes pre-construidas y pre-horneadas (una puerta de más, un pasillo que ahora gira al otro lado, un mueble cambiado). El intercambio ocurre **solo cuando el sector está fuera de la vista del jugador y El Olvidado no está dentro**. Cada variante lleva su propio lightmap y su propia `NavigationRegion3D`.
2. **Pasillos en bucle**: tramos idénticos entre los que se teletransporta al jugador sin corte visible, para que un pasillo recto devuelva al punto de partida o no termine nunca.

Presupuesto: **3–5 mutaciones por nivel**, colocadas a mano. El detalle por nivel va en `docs/12`.

## Posprocesado

El "valle inquietante" de `docs/09` se obtiene con lo que Compatibility sí tiene:

| Efecto | Técnica | Coste |
|---|---|---|
| Sombras suaves, oclusión, rebotes | Horneados en el lightmap | Cero en ejecución |
| Corrección de color agresiva | `Environment`: tonemap + ajustes (brillo, contraste, saturación, LUT) por nivel | Muy bajo |
| Resplandor de neón y veladoras | `Environment` glow, con intensidad contenida | Bajo; desactivable en gama baja |
| Profundidad y oscuridad | Niebla de profundidad del `Environment` | Muy bajo |
| Humo de copal | Planos con textura alfa desplazada + pocas partículas; no hay niebla volumétrica | Bajo si se dosifica |
| Aberración cromática, viñeta, grano | **Un único shader de pantalla completa** (`ColorRect` en `CanvasLayer` leyendo la textura de pantalla) | Medio: una copia de pantalla |

El shader de pantalla completa es **por eventos, no permanente**: se activa en la caída por el cuadro, con El Olvidado cerca y en el clímax; el resto del tiempo el nodo está oculto. En Android de gama baja se ofrece un ajuste de calidad que lo deja en viñeta simple.

*(Glow y niebla en Compatibility: validar en el primer prototipo visual sobre Web y Android.)*

## Distribución y compilación

### Exportación Web (HTML5/WebAssembly)

- **Un solo hilo** (*Thread Support* desactivado), que es el modo por defecto desde Godot 4.3. **No requiere cabeceras COOP/COEP** ni `SharedArrayBuffer`, y funciona en cualquier hosting, incluido un incrustado en lovenoho.com.
- No se activan hilos ni GDExtensions: ambos exigirían aislamiento cross-origin, que impide integraciones de terceros en la página.
- **Audio en modo *Sample*** (por defecto en Web): no soporta `AudioEffects`, reverberación, doppler ni audio procedural. Por eso todo el audio va **pre-renderizado** (ver `docs/09`).
- Requiere WebGL 2 y contexto seguro (HTTPS).

### Exportación Android

Desde el editor de escritorio se necesitan **OpenJDK 17**, el **Android SDK** (configurado en los ajustes del editor) y un keystore de firma. Produce `.apk` o `.aab`. La compilación con Gradle solo hace falta si se añaden plugins nativos.

*(La "Godot Android Build Environment (GABE)" de `investigacion.txt`, que evitaría instalar Java y SDK, aplicaría solo a exportar desde el editor de Android; no se usa en este flujo.)*

## Resumen de decisiones técnicas

| Decisión | Valor elegido | Motivo |
|---|---|---|
| Motor | Godot 4.7 | Multiplataforma (Web + Android), open source |
| Renderizador | **Compatibility** | Alcance universal en navegadores y móviles gama media |
| Objetivo FPS | 60 sostenidos | Rendimiento fluido |
| Materiales | Paleta/atlas por nivel, máx. 6 materiales, `MultiMesh` | Minimizar draw calls |
| Visibilidad | **Sectores** + niebla; `OccluderInstance3D` opcional solo Android | Los oclusores no funcionan en Web por defecto |
| Iluminación estática | `LightmapGI` por sector | Sin costo en tiempo real |
| Iluminación dinámica | Solo linterna; el resto por emisión, shader y `Environment` | Presupuesto de iluminación |
| Geometría mutante | Variantes de sector pre-horneadas + pasillos en bucle | Compatible con horneado |
| Posprocesado | `Environment` + un shader de pantalla por eventos | Lo disponible en Compatibility |
| Export Web | Un solo hilo, sin COOP/COEP, audio *Sample* pre-renderizado | Hosting sin restricciones |
| Export Android | OpenJDK 17 + Android SDK, `.apk`/`.aab` | Flujo estándar de escritorio |
