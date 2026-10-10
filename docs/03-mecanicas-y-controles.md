# Mecánicas de Interacción y Sistemas del Jugador

> Fuente: `investigacion.txt` — sección "Mecánicas de Interacción y Sistemas del Jugador".
> **Enmendado 2026-10-09**: agacharse y ocultarse automáticos; teclas de escritorio para correr, linterna e interactuar.

## Principio de diseño

El diseño de la experiencia interactiva prioriza la **simplicidad cognitiva** para fomentar un estado de vulnerabilidad y tensión constante. El sistema de control está fuertemente optimizado para garantizar una usabilidad intuitiva tanto en **pantallas táctiles** de dispositivos Android como mediante **teclado y ratón** en navegadores web.

## Movimiento

### Caminata base

El movimiento base del jugador es una **caminata lenta y deliberada**, donde cada paso genera un **eco audible** que:

- Sirve para informar espacialmente sobre las dimensiones de la habitación.
- Simultáneamente incrementa la paranoia del usuario al enmascarar posibles sonidos de la entidad acechante.

### Carrera (sprint) y resistencia

> **Enmienda 2026-10-09 (prevalece):** se retiran la **resistencia** y los **niveles de dificultad**. El jugador corre siempre que quiera, sin consumo, jadeo ni señales de cansancio; el precio de correr es solo el **ruido**. Hay una única dificultad, el **ajuste estándar** (los valores "Intermedio" de `docs/12`, en `scripts/core/difficulty.gd`). Añadir perfiles se decidirá cuando el estándar esté afinado. Lo que sigue en este apartado queda como referencia histórica.

Para situaciones de peligro inminente, el jugador dispone de una mecánica de **carrera ("sprint")** que consume una **barra de resistencia invisible**. Abusar de esta capacidad tiene consecuencias auditivas severas:

- El personaje comenzará a **hiperventilar**, emitiendo jadeos pesados.
- Los jadeos **incrementan significativamente el radio de detección** de la entidad enemiga.

La resistencia se **regenera de forma pasiva únicamente** cuando el jugador se detiene o vuelve a caminar lentamente.

### Agacharse y ocultarse (automáticos)

No existen botones de agacharse ni de esconderse. El juego sigue teniendo solo cuatro verbos (caminar, correr, iluminar, interactuar); el entorno hace el resto:

- **Agacharse**: al entrar en un espacio bajo (conductos de ventilación, huecos bajo un escritorio u ofrenda), un `Area3D` baja la cámara y la cápsula de colisión, reduce la velocidad y desactiva el sprint. Al salir, el personaje se incorpora solo en cuanto hay altura libre.
- **Ocultarse**: el jugador se considera oculto cuando está **quieto, con la linterna apagada, dentro de una zona de escondite** (nicho, conducto, sombra marcada por diseño de nivel). Estar oculto reduce su radio de detección visual y sonoro. No hay animación ni indicador explícito: se comunica con el sonido de la respiración contenida.
- Quedarse oculto demasiado tiempo activa la emboscada de El Olvidado (`AmbushState`, ver `docs/05`).

## Linterna

La gestión de la linterna es la **herramienta principal de supervivencia y exploración**. A diferencia de mecánicas punitivas que obligan a recolectar baterías, la linterna del jugador **no posee una carga finita**: no hay baterías que recolectar ni indicador de carga. El jugador puede encenderla y apagarla a voluntad.

Sin embargo, su confiabilidad está directamente ligada a la **proximidad de la anomalía**: cuando el monstruo se acerca, el **campo electromagnético** de la entidad causa que la linterna:

1. Parpadee.
2. Reduzca su intensidad.
3. Eventualmente se apague por periodos cortos.

Esto fuerza al jugador a **memorizar la topografía inmediata** y a navegar a ciegas en momentos de máxima tensión.

## Controles

Para la implementación técnica de los sistemas de control táctil en dispositivos móviles, el desarrollo explotará las capacidades nativas del nodo **VirtualJoystick** introducido durante el ciclo de desarrollo de Godot 4.7, eliminando la necesidad de depender de plugins o complementos de terceros que podrían causar cuellos de botella en el rendimiento.

| Tipo de Control | Plataforma Objetivo | Implementación Técnica en Godot 4.7 |
|---|---|---|
| Desplazamiento Espacial | Dispositivos Móviles (Android) | Nodo `VirtualJoystick` instanciado en el lado izquierdo de la pantalla. Configurado bajo el modo `JOYSTICK_DYNAMIC`, lo que permite que el control direccional aparezca dinámicamente en el punto exacto donde el pulgar del usuario entra en contacto con la pantalla. |
| Rotación de Cámara | Dispositivos Móviles (Android) | Intercepción de eventos de entrada `InputEventScreenDrag` restringidos lógicamente a la mitad derecha del espacio en pantalla, mapeados a la rotación del cuello del personaje (`Camera3D`). |
| Acciones (Correr, Linterna) | Dispositivos Móviles (Android) | Nodos nativos `TouchScreenButton` superpuestos mediante una jerarquía `CanvasLayer` para asegurar que siempre se rendericen por encima de la geometría 3D del juego. |
| Interactuar | Dispositivos Móviles (Android) | Toque sobre el indicador central cuando está expandido (ver "Interacción por proximidad"). |
| Movimiento y Mirada | Navegador Web (PC/Mac) | Interfaz clásica de teclado (W, A, S, D) configurada a través del `InputMap` del motor. El cursor se oculta e intercepta utilizando el comando `Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)`. |
| Acciones | Navegador Web (PC/Mac) | Acciones del `InputMap`: `sprint` = Shift, `flashlight` = F o clic derecho, `interact` = E o clic izquierdo. |

Las mismas acciones del `InputMap` (`sprint`, `flashlight`, `interact`) las disparan los `TouchScreenButton` en móvil, de modo que el código del jugador no distingue plataforma.

## Interacción por proximidad

El sistema de interacción opera mediante **contextos de proximidad**: un elemento gráfico discreto en el centro de la pantalla se **expande** cuando el jugador se encuentra dentro del rango de acción de un objeto interactivo. Objetos interactuables:

- Puertas manipulables.
- Documentos narrativos abandonados.
- Las letras estructurales de la marca **NOHO**.
