# Diseño de Entidad y Arquitectura de Inteligencia Artificial

> Fuente: `investigacion.txt` — sección "Diseño de Entidad y Arquitectura de Inteligencia Artificial".
> **Enmendado 2026-10-09**: reacción a la linterna unificada, perfiles por nivel, remansos, audio pre-renderizado.

## Nombre y concepto

Para salvaguardar la originalidad del producto y evadir conflictos legales con los derechos de autor de las comunidades de creadores, se ha conceptualizado una entidad enemiga **completamente exclusiva** para el universo de lovenoho.com. Esta criatura, referida internamente como **"El Olvidado"**, representa la **asimilación antinatural de la cultura laboral moderna y los ritos fúnebres ancestrales**.

## Diseño visual

El Olvidado es una **anomalía biomecánica**:

- **Fisiología**: humanoide anormalmente **alargado y demacrado**, superando los **dos metros y medio** de estatura.
- **Extremidades**: carecen de musculatura; compuestas por **alambres de telecomunicaciones corporativas** que se entrelazan de forma parasitaria con **huesos humanos calcificados y ennegrecidos**.
- **Rostro**: desprovisto de rasgos anatómicos; presenta un **vacío cóncavo de oscuridad absoluta** del cual emana una cascada continua e inagotable de **pétalos de cempasúchil marchitos**.
- **Vestimenta**: jirones podridos de un **traje sastre de oficinista** que se fusionan grotescamente con los remanentes polvorientos y bordados de un atuendo tradicional de **charro**.

## Diseño sonoro

Su diseño sonoro está meticulosamente estructurado para inducir pavor:

| Situación | Sonido |
|---|---|
| Locomoción | Crujido hueco de **huesos secos** friccionando contra pisos laminados, acompañado por el **susurro de papel triturado** |
| Respiración pasiva | Emulada mediante **ruido blanco de baja frecuencia** |
| Persecución y ataque final | **Chillido estridente** generado mediante la síntesis de una **alarma contra incendios corporativa** y la reverberación acústica de un **silbato de la muerte azteca**, creando una disonancia auditiva extrema |

Todos estos sonidos se entregan **pre-renderizados** (mezcla, distorsión y reverberación incluidas en el archivo), en variantes seca y con eco según el tipo de espacio. Ver `docs/09`.

## Arquitectura de IA — Máquina de Estados Finitos (FSM)

La arquitectura de la Inteligencia Artificial que gobierna el comportamiento de la criatura se desarrollará empleando el patrón de diseño de software **Máquina de Estados Finitos (FSM — Finite State Machine)** basado en una **estructura de nodos independientes**, el cual es considerado un estándar de oro para proyectos serios desarrollados en el motor Godot 4.7.

Este modelo arquitectónico permite:

- Desacoplar la lógica de comportamiento.
- Evitar la creación de estructuras condicionales frágiles.
- Garantizar que el comportamiento de la entidad sea altamente escalable y predecible para el diseñador.

### Estructura jerárquica de nodos

En la estructura jerárquica del motor:

- Raíz del monstruo: nodo `CharacterBody3D`.
  - Nodo hijo `StateMachine`.
    - Múltiples nodos individuales que representan comportamientos discretos, ejecutando funciones estandarizadas como `enter()`, `exit()`, y comprobaciones de bloqueo como `can_exit()`.

### Tabla de estados

| Estado Computacional de la IA | Condición de Transición Activa | Comportamiento del Monstruo en el Entorno |
|---|---|---|
| **Estado Base: Patrullaje** (`WanderState`) | Estado por defecto tras ser instanciado o perder el rastro. | Calcula rutas aleatorias a través del nivel utilizando el servidor de navegación `NavigationAgent3D`. Se desplaza a baja velocidad, ignorando al jugador si el contacto visual o auditivo no supera el umbral establecido. |
| **Estado Reactivo: Investigación** (`InvestigateState`) | El jugador corre (incrementando el radio sonoro), colisiona ruidosamente, o el haz de la linterna interseca el cuerpo de la criatura (esto último solo en los niveles 3 y 4). | Interrumpe la patrulla. Gira hacia el último vector espacial donde se originó el estímulo. La animación transiciona hacia una postura errática. Aumenta la velocidad de desplazamiento temporalmente. |
| **Estado Agresivo: Persecución** (`ChaseState`) | El cálculo de rayos ininterrumpidos (`RayCast3D`) confirma línea de visión directa y clara hacia el jugador. | Abandona el sigilo. Inicia un correteo rápido hacia el objetivo, reproduciendo la pista de audio de persecución y activando las fallas eléctricas en la linterna del usuario de forma sostenida. |
| **Estado Estratégico: Emboscada** (`AmbushState`) | (a) El jugador permanece inmóvil u oculto en la misma área durante un periodo prolongado (prevención de estancamiento). (b) En el nivel 2, el foco central de la linterna ilumina directamente a la criatura: chilla, desaparece y se reubica más cerca tras el siguiente parpadeo. | Utiliza lógica de **teletransportación** para reubicarse silenciosamente en una sala o pasillo adyacente fuera del cono de visión o el *frustum* de la cámara del jugador, forzando un encuentro. |
| **Resolución: Ataque Final** (`AttackState`) | La distancia matemática entre las coordenadas de la entidad y las del jugador se reduce a **menos de 1.5 metros**. | Ejecuta la función `can_exit() = false` para bloquear interrupciones. Toma **control forzado de la cámara** del jugador para asegurar el encuadre, reproduce la animación de muerte y transiciona la pantalla a negro absoluto. |

Las transiciones **no son una cadena lineal**: `WanderState` es el estado de reposo y cualquier estado puede volver a él al perder el rastro; `AttackState` es terminal.

### Perfil por nivel

Los estados y disparadores activos se configuran con un `Resource` (`EntityProfile`, un `.tres` por nivel), sin duplicar código:

| Nivel | Presencia | Estados activos | Linterna sobre la entidad |
|---|---|---|---|
| 1 | No se instancia; solo pasos espejo por audio | — | — |
| 2 | Manifestación lejana | `Wander`, `Ambush` (y `Attack` si llega a 1.5 m) | → `AmbushState` (chillido + reubicación más cerca) |
| 3 | Cazador activo | Todos | → `InvestigateState` |
| 4 | Enfurecido tras la última letra | Todos, con velocidad y radios aumentados | → `InvestigateState` |

### Reglas transversales

- **Remansos de veladoras**: la entidad no entra ni ataca dentro de ellos (su navmesh los excluye); puede merodear fuera. Ver `docs/02`.
- **Jugador oculto** (quieto, linterna apagada, en zona de escondite): reduce los radios de detección; si se prolonga, dispara `AmbushState`. Ver `docs/03`.
- **Reubicación** (`AmbushState`): el destino se elige entre puntos marcados a mano por sector, fuera del *frustum* de la cámara y nunca dentro de un remanso.
- **Captura** (`AttackState`): es el jump scare permitido por la política de `docs/01`; breve, y da paso inmediato a la pantalla de derrota con "Reintentar" (`docs/06`).
- La navegación requiere una `NavigationRegion3D` horneada por sector; las variantes de sector llevan la suya (`docs/07`).

## Ver también

- Mecánicas que disparan los estados: [03 — Mecánicas y controles](03-mecanicas-y-controles.md) (sprint/hiperventilación, linterna errática).
- Apariciones por nivel: [04 — Niveles y progresión](04-niveles-y-progresion.md) (Nivel 2: primera manifestación; Nivel 3: cazador activo; Nivel 4: enfurecimiento).
