# Referencias Visuales y Estrategia de Adquisición de Activos Tridimensionales

> Fuente: `investigacion.txt` — sección "Referencias Visuales y Estrategia de Adquisición de Activos Tridimensionales".
> **Enmendado 2026-10-09**: audio pre-renderizado y ElevenLabs, posprocesado realista para Compatibility, licencias.

## Objetivo de peso del binario

Mantener el peso total del archivo binario compilado bajo estrictos límites de tamaño (**idealmente por debajo de los 100 Megabytes**) es **mandatorio** para:

- Asegurar una tasa de conversión alta en plataformas web.
- Evitar tasas de rebote prolongadas durante los tiempos de carga en dispositivos de gama media.

## Dirección de arte: estética Low Poly

Para acelerar dramáticamente el ciclo de producción de arte visual, el diseño favorece una estética de geometría de **baja densidad poligonal (Low Poly)**. Esta técnica estilizada se basa en:

- Modelado con formas geométricas muy **angulares**.
- Prescindir de texturas fotográficas de alta resolución, empleando superficies de **colores sólidos mate**.

Sin embargo, al combinar modelos primitivos Low Poly con **iluminación horneada de calidad y un posprocesado cinematográfico** (sombras suaves y rebotes en el lightmap, corrección de color agresiva, resplandor, niebla y **aberración cromática** en momentos puntuales; técnica y límites en `docs/07`), se produce un contraste cognitivo conocido como el **"valle inquietante"** (*uncanny valley*), que resulta excepcional para catalizar el horror liminal que requiere la experiencia.

## Adquisición de activos por categoría

### Criterio de elección: importancia y visibilidad

**Enmienda 2026-10-09, decisión del usuario**: los objetos importantes, narrativos,
interactivos o muy visibles se modelan a medida en Blender; para utilería secundaria,
incidental o de relleno se buscan assets de stock primero. La categoría del objeto
no basta: una silla protagonista se modela, una silla de fondo puede ser stock.
Importar stock mediante Blender MCP sigue siendo adquisición de stock.

El procedimiento operativo, las fuentes verificadas de **modelos y texturas**, los
límites de acceso API/MCP y las descargas de prueba están en
[16 — Assets de stock y metodología para agentes](16-assets-stock.md).
Ese documento complementa estas reglas y las licencias de `docs/01`.

### 1. Ambientación corporativa secundaria — bibliotecas externas

Se aprovecharán bibliotecas externas de modelos libres y de bajo costo como **poly.pizza**, orientando las búsquedas a través de términos descriptivos en inglés:

- "office supplies"
- "furniture"
- Colecciones estandarizadas: **"low poly office pack"**; como alternativa de pago, **"POLYGON Office"** (Synty Store)

Esto facilita el ensamble paramétrico rápido de componentes ambientales mundanos:

- Escritorios tabulares.
- Hileras interminables de archiveros de gaveta.
- Teclados desprovistos de computadoras.
- Sillas giratorias abandonadas.

…permitiendo enfocar los recursos del equipo de diseño gráfico en las áreas de **mayor impacto narrativo**.

### 2. Elementos del Día de Muertos — modelado a medida

Los elementos autóctonos e iconográficos de la festividad demandan un **tratamiento visual a medida**. Pueden modelarse rápidamente desde cero en **Blender** (baja exigencia poligonal):

- Coronas flotantes de flores de **cempasúchil**.
- Arreglos detallados de **pan de muerto**.
- Ofrendas piramidales precolombinas.
- Estelas decorativas simulando **papel picado** rasgado.
- **Calaveritas de azúcar** estilizadas.

Alternativamente, iteraciones de alta calidad preparadas para motores de renderizado en tiempo real podrán licenciarse desde repositorios tridimensionales comerciales como **Sketchfab**, revisando la licencia de cada modelo (ver tabla de licencias en `docs/01`).

### 3. Ambiente acústico — bibliotecas royalty-free

La orquestación del ambiente acústico representa el **pilar crítico de inmersión**, constituyendo **más del cincuenta por ciento del peso psicológico** en el género del terror.

Fuentes de audio, por orden de preferencia:

- **ElevenLabs** (generación): efectos de sonido a medida y material vocal sin habla — jadeos e hiperventilación del protagonista, respiración y chillido de El Olvidado. Requiere un plan con licencia de uso comercial.
- **Sonniss** (bibliotecas royalty-free de la industria).
- **Freesound.org**, solo archivos CC0 o CC BY (la licencia es por archivo; ver `docs/01`).

### Audio pre-renderizado (obligatorio)

El export Web reproduce en modo *Sample*, que **no soporta efectos en tiempo real** (reverberación, distorsión, filtros en buses, doppler, audio procedural). Por tanto:

- Todo efecto se **hornea en el archivo** fuera del motor: eco, reverberación, distorsión, cambio de tono, ralentización.
- Los sonidos que dependen del espacio se entregan en **variantes por tipo de recinto**: p. ej. pasos en alfombra (seco), en planicie (eco largo), en agua, en conducto.
- Las variaciones (tono, pequeñas diferencias) se resuelven con **varias tomas** elegidas al azar, no con procesado.
- En el motor solo se usan volumen, paneo y atenuación por distancia de `AudioStreamPlayer3D`; el audio posicional debe probarse pronto en Web.
- Formato: OGG Vorbis para ambientes y música; WAV corto para efectos de respuesta inmediata. El audio cuenta para el límite de 100 MB.

Tipos de material bruto a recopilar:

| Categoría | Ejemplos |
|---|---|
| Ambiente eléctrico | Zumbido hipnótico capturado en grabaciones electromagnéticas de balastros de luces de neón defectuosas |
| Pasos / foley | Impacto sonoro de pisadas en alfombras sintéticas bajo diversos grados de humedad |
| Estática | Ráfagas inestables de estática radiofónica |
| Mecánica | Distorsiones mecánicas |

Estos audios se someterán a **compresión y alteración de tono fuera del motor**, completando así la arquitectura estética de los pasillos infinitos del Mictlán corporativo, donde el logotipo brillante y pulido de NOHO descansa como el único remanente de civilización y la clave indiscutible de la supervivencia.

## Resumen de fuentes de activos

| Activo | Fuente | Licencia / método |
|---|---|---|
| Mobiliario oficina (low poly) | poly.pizza ("low poly office pack"); Synty "POLYGON Office" | CC0 / CC BY con créditos; pack de pago |
| Iconografía Día de Muertos | Modelado propio en **Blender** | Autoral |
| Alternativa alta calidad 3D | **Sketchfab** | Comercial, licencia por modelo |
| Audio (efectos, voces) | **ElevenLabs** | Generado; plan con uso comercial |
| Audio (ambiente, foley, estática) | **Sonniss**, **Freesound.org** | Royalty-free; en Freesound solo CC0 / CC BY |

Todo asset externo se registra en `assets/CREDITS.md` (ver `docs/01`).

Para texturas repetibles secundarias, comenzar por **ambientCG** y **Poly Haven**
(CC0); alternativa: **3DTextures**. Para modelos secundarios low poly, añadir
**Kenney** a las fuentes anteriores. Las APIs oficiales de Poly Haven y ambientCG
se usan con `tools/assets/stock_assets.py`; revisar ficha/licencia vigente, descargar
a staging y adaptar a la paleta y al límite de materiales antes de integrar.
Recetas y evidencia de acceso en [docs/16](16-assets-stock.md).
