# Arquitectura de Renderizado y Optimización en Godot 4.7

> Fuente: `investigacion.txt` — sección "Arquitectura de Renderizado y Optimización en Godot 4.7".

## Motor y requisitos

La elección del motor **Godot 4.7** provee una infraestructura tecnológica robusta para el desarrollo del proyecto, gracias a sus avances arquitectónicos en el renderizado y su capacidad intrínseca de exportación a múltiples plataformas simultáneamente.

Dado que los requerimientos de la marca exigen un funcionamiento impecable, libre de latencia, tanto a través de **navegadores web** (estándares HTML5) como de manera nativa en **teléfonos Android**, las decisiones de optimización deben ser drásticas y precisas.

## Selección del renderizador: Compatibility

Aunque la tecnología **"Forward+"**, basada en las capacidades de trazado y sombreado avanzadas de la API **Vulkan**, ofrece fidelidad visual fotorrealista, su implementación en exportaciones web genera barreras de adopción severas y depende de la compatibilidad del usuario con estándares modernos.

Para garantizar un alcance universal, el proyecto debe ser configurado y **bloqueado en el Renderizador de Compatibilidad (Compatibility Renderer)** de Godot:

- Basado en las directrices de la arquitectura **OpenGL y GLES3**.
- Constituye la **única vía segura** para ejecutar gráficos tridimensionales complejos en entornos de navegadores sin desencadenar caídas críticas en la tasa de cuadros por segundo (FPS) ni requerir hardware dedicado de última generación en dispositivos móviles.

**Objetivo de rendimiento: 60 FPS sostenidos** en plataformas con capacidades de procesamiento limitadas.

## Tres pilares de optimización

El diseño de la geometría y los materiales se someterá a tres pilares fundamentales de optimización.

### Pilar 1 — Reducción agresiva de Draw Calls

Las llamadas de dibujado de la interfaz de programación gráfica (**Draw Calls**) representan las instrucciones de cálculo que la CPU debe empaquetar y enviar a la GPU para renderizar cada material distinto en pantalla. Una arquitectura de nivel que utilice múltiples texturas individuales y materiales independientes causará un aumento exponencial en las llamadas, saturando la capacidad de un navegador web.

**Acción**: la totalidad de los elementos estructurales y de ambientación (desde las paredes de adobe hasta los escritorios y ofrendas) serán consolidados topológicamente en **Texturas Atlas** (archivos de imagen de alta resolución que agrupan y mapean cientos de texturas menores), permitiendo que la mayoría de los cuartos se rendericen en **una o dos llamadas de dibujado unificadas**.

### Pilar 2 — Occlusion Culling nativo

Godot 4.7 proporciona herramientas avanzadas para evitar que la GPU procese e intente dibujar geometría que físicamente se encuentra oculta detrás de otros objetos masivos, como muros o pilares.

En el contexto de un juego laberíntico de interiores cerrado como los Backrooms, donde el **noventa por ciento del mapa está fuera de la línea de visión** del jugador en cualquier momento dado, la integración sistemática de nodos **`OccluderInstance3D`** incrustados en la topología de los muros producirá un aumento de rendimiento exponencial, liberando vastas cantidades de memoria caché de video de manera dinámica conforme el jugador navega por el pasillo.

### Pilar 3 — Iluminación horneada (LightmapGI)

Calcular la dispersión de la iluminación y la proyección de sombras físicas en tiempo real sobrecargaría térmicamente a los procesadores de los dispositivos móviles y saturaría los procesos del navegador. En sustitución, la totalidad de la **iluminación estática ambiental** originada por:

- Las luces de los pasillos corporativos.
- El resplandor estático de las veladoras.
- La luminiscencia de los cráneos de azúcar.

…será sujeta a un proceso de **horneado ("baking")** mediante **Mapas de Luz**, gestionado a través del nodo **`LightmapGI`**.

> **Factor técnico crítico y peculiar de Godot 4.7**: el proceso de horneado en el editor exige obligatoriamente hardware y configuración que soporte el renderizador **Forward+**; sin embargo, los datos lumínicos horneados resultantes **pueden cargarse y ejecutarse perfectamente en tiempo de ejecución bajo el renderizador de Compatibilidad** en las plataformas de destino. Esto asegura sombras suaves, rebotes de iluminación global y sombreado oclusivo **sin costo alguno de procesamiento en tiempo real**.

**Única fuente lumínica dinámica**: el cono de proyección emitido por la **linterna** sostenida por el protagonista.

## Distribución y compilación

### Exportación nativa Android

La exportación nativa para la plataforma de Google operará a través de la arquitectura integrada **Godot Android Build Environment (GABE)**. Esta herramienta permite:

- Compilación y ensamblaje mediante scripts **Gradle**.
- Firma criptográfica.
- Exportación de paquetes instalables como **`.apk`** o **`.aab`** (Android App Bundle) directamente desde un dispositivo,

…eliminando dependencias externas o configuraciones dolorosas del entorno de desarrollo de Java y herramientas SDK.

### Exportación Web (HTML5/WebAssembly)

La compilación de la versión Web requiere una **manipulación estricta a nivel del servidor de alojamiento web** donde resida el juego. La habilitación del soporte **multi-hilo ("multi-threading")** en Godot 4 Web precisa obligatoriamente la activación de cabeceras de seguridad especializadas en el protocolo HTTP:

- `Cross-Origin-Opener-Policy` (COOP)
- `Cross-Origin-Embedder-Policy` (COEP)

Sin estas cabeceras, el navegador bloqueará el acceso a las funciones de **`SharedArrayBuffer`**, imposibilitando la ejecución del binario ensamblado en **WebAssembly**.

## Resumen de decisiones técnicas

| Decisión | Valor elegido | Motivo |
|---|---|---|
| Motor | Godot 4.7 | Multiplataforma (Web + Android), open source |
| Renderizador | **Compatibility** (OpenGL/GLES3) | Alcance universal en navegadores y móviles gama media |
| Objetivo FPS | 60 sostenidos | Rendimiento fluido sin interrupciones |
| Texturas | **Atlas** | Minimizar draw calls |
| Oclusión | `OccluderInstance3D` | Descartar geometría oculta (~90% del mapa) |
| Iluminación estática | `LightmapGI` (horneado con Forward+, ejecución en Compatibility) | Sin costo en tiempo real |
| Iluminación dinámica | Solo linterna del jugador | Presupuesto de iluminación |
| Export Android | GABE (Gradle, `.apk`/`.aab`) | Sin dependencias externas de SDK |
| Export Web | WebAssembly + cabeceras COOP/COEP | Habilitar `SharedArrayBuffer` / multi-hilo |
