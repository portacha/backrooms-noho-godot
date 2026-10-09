# Flujos de Trabajo y Desarrollo Asistido por Inteligencia Artificial

> Fuente: `investigacion.txt` — sección "Flujos de Trabajo y Desarrollo Asistido por Inteligencia Artificial".

## Contexto

La creación de un producto tridimensional inmersivo con recursos humanos acotados experimenta una aceleración transformacional mediante la integración sistemática de **modelos de lenguaje grande (LLMs)** y agentes de codificación avanzados como **Claude, OpenAI Codex** y extensiones de desarrollo como **OpenCode o Cursor AI**.

No obstante, el desarrollo empírico ha demostrado que delegar ciegamente la programación a estos modelos introduce vulnerabilidades graves en el código, primordialmente debido a lo que se clasifica como **"alucinaciones de versiones"**.

## El problema: alucinaciones de versiones

Dado que la arquitectura de Godot experimentó una **reescritura fundacional entre la versión 3.x y la actual serie 4.x**, los modelos de IA (cuyos conjuntos de datos de entrenamiento históricos están sobresaturados con documentación antigua) frecuentemente recomiendan y generan scripts obsoletos, por ejemplo:

- Invocar el nodo abolido **`KinematicBody`** en sustitución del moderno **`CharacterBody3D`**.
- Usar incorrectamente métodos de física con **parámetros obsoletos**.

## Solución: Prompts de Sistema arquitectónicos

Para lograr resultados consistentes y de alta fidelidad sintáctica en Godot 4.7, la interacción con la inteligencia artificial debe abordarse mediante la técnica de **ingesta de directrices arquitectónicas**, utilizando **Prompts de Sistema ("System Prompts") exhaustivos** que restrinjan el margen de error del agente conversacional.

### Formulación estándar de Prompt de Sistema (Claude y Codex)

> Actúa como un Ingeniero de Software Sénior especializado exclusivamente en la arquitectura de **Godot 4.7** y el lenguaje **GDScript 2.0**. Rechaza proactivamente cualquier sintaxis, convención de nombres o diseño de nodos proveniente de **Godot 3**. Implementa **tipado estático estricto** de forma obligatoria en la declaración de variables (ejemplo: `var speed: float = 5.0`) y retornos de funciones (ejemplo: `-> void`). Para la construcción de personajes jugables y entidades enemigas, instancia exclusivamente el nodo **`CharacterBody3D`**, gestionando el cálculo de colisiones mediante la modificación directa de la propiedad interna **`velocity`** previo a la ejecución del método **`move_and_slide()`** sin argumentos. Aplica rigorosamente el patrón de diseño de **Máquina de Estados Finitos orientada a nodos** para toda la inteligencia artificial. Estructura los componentes jerárquicos minimizando el acoplamiento directo, utilizando arquitecturas basadas en **emisiones de señales nativas (Signals)** para la propagación de datos hacia las capas superiores de la jerarquía visual.

## Ciclo de desarrollo iterativo asistido

El ciclo de desarrollo operará mediante la siguiente división secuencial del trabajo:

### 1. Macro-arquitectura con Claude (modelos Opus/Sonnet)

Se desplegará la capacidad de razonamiento profundo del modelo para generar las **estructuras lógicas fundacionales**. Ejemplo: instruir la creación de los esqueletos del código base para el patrón de la IA del enemigo, solicitando la generación de:

- El **contrato** del script base abstracto `state.gd`.
- El **controlador jerárquico** del enrutamiento `state_machine.gd`.
- Un caso de uso específico como la lógica computacional interna del comportamiento de patrullaje `patrol.gd` correspondiente a un nodo `CharacterBody3D`.

### 2. Codificación contextual y completado analítico con OpenCode / Cursor

Durante el ensamble directo en el IDE, los agentes de completado en línea que interpretan en tiempo real el contexto del archivo analizarán los patrones de código en pantalla. Se usarán primordialmente para redactar **algoritmos matemáticos complejos**:

- Cálculo de vectores tridimensionales para el movimiento del jugador.
- Interpolación fluida de la cámara espacial.
- Operaciones lógicas de intersección geométrica para que los nodos `RayCast3D` determinen con exactitud la **línea de visión** del monstruo.

### 3. Análisis topológico y resolución de cuellos de botella de rendimiento

En fases avanzadas de pruebas operativas (especialmente en simulaciones de exportación móvil en Android, donde el rendimiento es vital), se recolectarán las métricas y registros arrojados por el **"Profiler" nativo** del motor Godot:

- Milisegundos consumidos por ciclos de CPU.
- Saturación del ancho de banda de memoria de Video.
- Conteo de **Draw Calls**.

Esta telemetría estructurada se suministrará de vuelta a Claude para solicitar **auditorías de optimización**, permitiendo a la IA sugerir ajustes precisos en:

- La colocación de volúmenes de `OccluderInstance3D`.
- Alteraciones en la escala de resolución para mitigar el consumo de procesamiento.

## Reglas derivadas para el código generado

| Regla | Detalle |
|---|---|
| Motor objetivo | Godot 4.7 / GDScript 2.0 — **nunca** sintaxis de Godot 3 |
| Tipado | Estático estricto: `var x: float = …`, `func f() -> void` |
| Cuerpos físicos | `CharacterBody3D` (prohibido `KinematicBody`/`KinematicBody2D`) |
| Movimiento | Asignar `velocity` y llamar `move_and_slide()` **sin argumentos** |
| IA | FSM orientada a nodos con `enter()`, `exit()`, `can_exit()` |
| Acoplamiento | Desacoplar mediante **Signals** hacia capas superiores |
| Optimización | Alimentar al modelo con datos del Profiler (CPU ms, VRAM, Draw Calls) |
