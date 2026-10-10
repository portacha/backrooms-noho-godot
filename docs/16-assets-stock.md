# Modelos y texturas: selección, descarga y adaptación por agentes

> Revisado: 2026-10-09. Complementa `docs/01`, `docs/02`, `docs/07` y `docs/09`.
> Decisión del usuario: **la importancia y visibilidad del objeto determinan si se modela a medida o se busca stock**. La disponibilidad de un conector no determina esa decisión.

## 1. Decidir antes de buscar

| Importancia / visibilidad en el juego | Método preferido | Ejemplos |
|---|---|---|
| Alta: protagonista, objetivo, interacción, primer plano prolongado, silueta reconocible o pieza que define el lugar | **Modelado propio en Blender**; MCP si está disponible, script local si conviene | Cuadro y marco de la caída, letras-altares, El Olvidado, linterna visible de cerca, ofrenda focal, terminal protagonista |
| Media: objeto visible que ayuda a definir la época o se repite en primer plano | Blender si destaca en el encuadre; stock solo si ya encaja con la dirección de arte y requiere ajustes menores | Escritorios, sillas, archiveros y teléfonos de la oficina |
| Baja: utilería incidental, distante, decorativa, repetida o de relleno | **Buscar y descargar stock primero**; adaptar escala, materiales y silueta | Papelería secundaria, cajas al fondo, accesorios y muebles sin relevancia narrativa |

Si se cumple **cualquier** criterio de importancia alta, elegir modelado propio aunque el objeto sea pequeño. La distancia no rebaja la importancia narrativa. Un objeto de relleno que se convierte en protagonista debe volver a evaluarse. Registrar la decisión en la ficha del recurso (§7).

**Importar stock mediante Blender MCP sigue siendo adquisición de stock**, no modelado propio. Blender sirve también para adaptar recursos secundarios descargados. No usar generación 3D remota como sustituto automático del modelado propio.

Para texturas: paleta, pinturas, documentos, marcas y detalles narrativos visibles se diseñan a medida; superficies secundarias repetibles pueden partir de stock. Preferir colores mate y detalle contenido; el catálogo fotorealista es materia prima, no la dirección de arte. Iconografía mexicana protagonista: modelado propio conforme a `docs/09`.

## 2. Fuentes de modelos 3D

| Fuente | Encaje con este proyecto | Licencia a comprobar | Uso por agentes / acceso |
|---|---|---|---|
| [Kenney — Furniture Kit](https://kenney.nl/assets/furniture-kit) | Primera búsqueda de muebles y utilería secundaria low poly | El pack consultado es CC0; conservar `License.txt` | ZIP público sin cuenta; descarga puntual por enlace oficial. No se verificó una API de catálogo oficial. **Descarga probada** |
| [Poly Pizza](https://poly.pizza/) | Catálogo de objetos low poly; buen candidato estético | Por modelo; aceptar únicamente CC0 o CC BY con atribución | API publicada y conector Blender MCP disponibles como rutas posibles, **condicionadas a configuración y términos**; no probado en esta sesión. No hacer scraping |
| [Poly Haven — modelos](https://polyhaven.com/models) | Objetos mundanos, algunos de baja complejidad; muchos requieren simplificación | CC0 | API pública sin clave; herramienta local incluida y Blender MCP opcional. **Descarga completa de glTF probada** |
| [Sketchfab](https://sketchfab.com/) | Buscar objetos específicos cuando las fuentes anteriores no cubran la necesidad | Licencia individual; excluir SA, NC, ND, editorial y descargas sin permiso comercial claro | Download API con usuario autenticado; glTF/GLB disponibles. Conector MCP opcional. Sin cuenta configurada ni descarga probada aquí |
| [Synty](https://syntystore.com/) | Packs coherentes low poly; alternativa comercial para utilería | EULA de la compra o suscripción y plazas autorizadas | Cuenta y pack licenciado. Descargar desde My Downloads; no se verificó API pública. No asumir que permite enviar modelos a servicios de IA |
| [Fab](https://www.fab.com/) | Alternativa comercial, modelos o materiales concretos | CC BY o Standard según producto; revisar acceso a archivos fuente y formato compatible | Cuenta y adquisición correspondiente. Sin automatización oficial verificada aquí; usar descarga autorizada o archivos ya facilitados |

Para props secundarios, empezar por **Kenney → Poly Pizza con acceso oficial habilitado → Poly Haven → Sketchfab**. Synty/Fab cuando ya exista licencia adecuada o una necesidad concreta justifique compra; no comprar por iniciativa del agente.

Fuentes oficiales: [ficha y licencia Furniture Kit](https://kenney.nl/assets/furniture-kit), [términos Kenney](https://kenney.nl/terms-of-service), [API Poly Pizza](https://poly.pizza/docs/api/v1.1), [términos Poly Pizza](https://poly.pizza/docs/tos), [licencia Poly Haven](https://polyhaven.com/license), [Download API Sketchfab](https://sketchfab.com/developers/download-api), [descarga autenticada Sketchfab](https://sketchfab.com/developers/download-api/downloading-models/javascript), [licencias Synty](https://syntystore.com/pages/licences-overview), [EULA de compra Synty](https://syntystore.com/pages/one-time-purchase-licence), [descargas Synty](https://syntystore.com/community/faq), [licencia Fab](https://www.fab.com/eula).

## 3. Fuentes de texturas

| Fuente | Uso sugerido | Licencia | Automatización |
|---|---|---|---|
| [ambientCG](https://ambientcg.com/) | Alfombra, yeso, vinilo, madera, azulejo, hormigón; buscar patrones discretos | CC0 | API v3 con metadatos y ZIPs públicos; sin clave en las solicitudes verificadas. **Descarga probada** |
| [Poly Haven — texturas](https://polyhaven.com/textures) | Superficies y suciedad secundaria, descargar solo mapas necesarios | CC0 | API pública y descarga por mapa; Blender MCP opcional. **Descarga probada** |
| [3DTextures](https://3dtextures.me/) | Alternativa de materiales repetibles | CC0 según su FAQ | Descargas individuales desde ficha; no se verificó API pública. Cuenta/servicio externo pueden intervenir en el enlace final |
| [Fab](https://www.fab.com/) | Packs específicos que no cubran las fuentes CC0 | Por producto | Misma ruta de cuenta/licencia que los modelos; no asumir que antiguos Megascans son gratuitos ni que licencias antiguas se transfieren |

Preferencia para texturas secundarias: **ambientCG → Poly Haven → 3DTextures**. Usar stock para arquitectura cuando aporte un patrón necesario; para mobiliario, preferir la paleta compartida. No sustituir las texturas existentes sin una tarea que lo requiera.

Fuentes: [licencia ambientCG](https://docs.ambientcg.com/license/), [API ambientCG](https://docs.ambientcg.com/api/), [endpoint v3 /assets](https://docs.ambientcg.com/api/v3/assets/), [API Poly Haven y condiciones](https://polyhaven.com/our-api), [FAQ/licencia 3DTextures](https://3dtextures.me/about/).

## 4. Flujo obligatorio para el agente

1. **Definir necesidad**: escena, función, tamaño real, distancia de cámara, importancia, paleta y presupuesto. Leer `docs/00`, `01`, `02`, `07`, `09`, `15` y el diseño del nivel correspondiente.
2. **Elegir modelado propio o stock** según §1. Comprobar primero si ya existe el modelo en `assets/models/` o en `tools/blender/build_models.py`. No reemplazar trabajo propio terminado con stock por conveniencia.
3. **Buscar candidatos**: describir objetos reales en inglés, por ejemplo `office notepad`, `filing cabinet`, `retro desk phone`, `carpet`, `plaster`, `ceiling tile`. No descargar decorados, entidades o niveles del canon de las wikis de Backrooms.
4. **Revisar ficha y licencia antes de descargar**: origen, autor, derechos comerciales, modificación, redistribución, formato, dependencias, tamaño, polígonos y calidad visual. CC0/CC BY no garantizan que logos o personajes de terceros estén autorizados. Si la licencia es ambigua, pasar al siguiente candidato.
5. **Descargar en staging**: `builds/asset_staging/<proveedor>/<id>/` (ignorado por Git) o `/tmp`. Usar interfaces oficiales, URLs devueltas por API y el directorio nuevo que pide la herramienta. Evitar bajar bibliotecas completas.
6. **Conservar procedencia**: metadatos, ficha, versión de licencia, fecha, autor, URLs, hashes y comprobante si corresponde. El manifiesto automático aporta trazabilidad; guardar también el archivo de licencia o evidencia de los términos vigentes. No publicar credenciales, recibos personales ni URLs firmadas con tokens.
7. **Adaptar e inspeccionar** en Blender; seleccionar solo las piezas necesarias, quitar logos y contrastar con la estética. Ver §6. No ejecutar scripts incrustados en `.blend`; inspeccionar ZIPs antes de extraer y rechazar rutas absolutas, `..` o enlaces que salgan de staging.
8. **Integrar derivados**, no el pack completo. Modelos en `assets/models/<nombre>.glb`, texturas en `assets/textures/`. Procedencia redistribuible en `assets/provenance/<nombre>/`; fuentes y evidencias restringidas en almacenamiento privado autorizado fuera de un repositorio público.
9. **Registrar créditos en el mismo cambio** y verificar el resultado: encuadres cercanos/lejanos, escala, colisión, luz horneada, número de materiales y peso. Si se modifica el nivel, regenerar la geometría y ejecutar las pruebas relevantes de `docs/15`.

No hay descarga de assets en tiempo de ejecución: el juego distribuye archivos locales preparados. La disponibilidad de los MCP puede variar entre agentes; el método reproducible preferido para stock CC0 es la API oficial o un enlace público autorizado. Una compra/licencia comercial para distribuir el juego no equivale a permiso para publicar los archivos fuente en Git.

## 5. Recetas de descarga reproducibles

Ejecutar desde la raíz. `tools/assets/stock_assets.py` usa **Python 3.9+ y su biblioteca estándar**, sin SDK, claves ni dependencias pip. Requiere red HTTPS. Si el sandbox bloquea red, usar el mecanismo de autorización del entorno. No interpretar un 403 como permiso para eludir restricciones; ante 429 respetar `Retry-After` y reducir solicitudes.

La herramienta solo implementa **Poly Haven y ambientCG**, sus fuentes CC0 verificadas. `search` muestra hasta 20 candidatos, `files` lista variantes con bytes incluyendo dependencias y `download` exige elegir una variante literal. Límite de descarga predeterminado: 30 MiB; no es el presupuesto del juego. Crea un directorio nuevo, comprueba tamaño, MD5 si lo entrega el proveedor y genera SHA-256 y `provenance.json`. No extrae ZIPs, convierte modelos ni edita créditos automáticamente. En caso de fallo, el staging incompleto queda identificado por el estado del manifiesto; no integrarlo.

### Poly Haven: modelos de relleno

```bash
python3 tools/assets/stock_assets.py search polyhaven --kind models --query office
python3 tools/assets/stock_assets.py files polyhaven --kind models --id office_notepads
python3 tools/assets/stock_assets.py download polyhaven --kind models --id office_notepads \
  --variant gltf/1k/gltf --out builds/asset_staging/polyhaven/office_notepads
```

El `.gltf` requiere `.bin` e imágenes. La herramienta conserva las rutas de `include` que devuelve el proveedor; no copiar únicamente el `.gltf`. Importar en Blender, adaptar y exportar el objeto seleccionado a GLB. El ejemplo es papelería incidental; no sustituye un documento narrativo modelado/diseñado a medida.

### Poly Haven: albedo de textura

```bash
python3 tools/assets/stock_assets.py search polyhaven --query carpet
python3 tools/assets/stock_assets.py files polyhaven --id dirty_carpet
python3 tools/assets/stock_assets.py download polyhaven --id dirty_carpet \
  --variant Diffuse/1k/jpg --out builds/asset_staging/polyhaven/dirty_carpet
```

Las claves son sensibles a mayúsculas y varían entre assets. Copiar siempre el valor mostrado por `files`. Reducir después a 512 px cuando sea suficiente. No descargar 4K/8K por defecto.

**API subyacente**: `GET https://api.polyhaven.com/assets?t=models` o `?t=textures`; `GET https://api.polyhaven.com/files/<id>`. La herramienta envía `User-Agent: BackroomsNOHO-StockAssets/1.0` y muestra el proveedor. La API actual permite uso comercial sin clave; su uso en una interfaz que exponga contenido vivo requiere indicar la procedencia. Los assets descargados son CC0. [Condiciones oficiales](https://polyhaven.com/our-api).

### ambientCG: buscar y elegir ZIP

```bash
python3 tools/assets/stock_assets.py search ambientcg --query carpet
python3 tools/assets/stock_assets.py files ambientcg --id Carpet016
python3 tools/assets/stock_assets.py download ambientcg --id Carpet016 \
  --variant 1K-JPG --out builds/asset_staging/ambientcg/Carpet016
```

La [API v3](https://docs.ambientcg.com/api/v3/assets/) devuelve `assets[]`, cada uno con `downloads[]`: `attributes`, `extension`, `url`, `size`. Consulta equivalente verificada:

```bash
curl -fsSL --max-time 45 -A 'BackroomsNOHO-StockAssets/1.0' \
  'https://ambientcg.com/api/v3/assets?type=material&q=carpet&limit=3&include=downloads,title,url'
```

Elegir la URL recibida, no construir nombres por suposición. La herramienta consulta un ID concreto para descargar. Para materiales basta `--kind textures`; `--kind models` consulta `type=3d-model`, pero no se probó una descarga de modelo ambientCG en esta revisión.

### Kenney: pack puntual sin cuenta

Abrir la [ficha Furniture Kit](https://kenney.nl/assets/furniture-kit), pulsar Download y Continue without donating, y usar la URL oficial del ZIP. Este enlace concreto se verificó el 2026-10-09 y puede cambiar:

```bash
mkdir -p builds/asset_staging/kenney/furniture-kit
curl --fail --location --max-time 60 \
  'https://kenney.nl/media/pages/assets/furniture-kit/440e0608a4-1677580847/kenney_furniture-kit.zip' \
  -o builds/asset_staging/kenney/furniture-kit/kenney_furniture-kit.zip
python3 -m zipfile -l builds/asset_staging/kenney/furniture-kit/kenney_furniture-kit.zip
sha256sum builds/asset_staging/kenney/furniture-kit/kenney_furniture-kit.zip
```

Guardar `License.txt`, escoger un GLB de `Models/GLTF format/` y adaptar solamente ese objeto. Registrar autor Kenney, ficha y CC0. Si el enlace falla, obtener el vigente desde la ficha; no adivinar rutas de servidor ni rastrear el catálogo entero. Esta receta no crea manifiesto automáticamente: usar la ficha §7.

### Blender MCP: modelado propio y adaptación opcional

Para una pieza importante: comprobar `get_addon_status` y `get_scene_info`, trabajar con `execute_blender_code` y revisar encuadres mediante `look`. Guardar fuente reproducible en `tools/blender/` y exportar el modelo a `assets/models/`. Usar una escena de trabajo separada sin borrar el trabajo del usuario. El script existente `tools/blender/build_models.py` es la referencia de paleta y convenciones.

Para **stock secundario**, si las bibliotecas están habilitadas y los términos lo permiten:

```text
get_addon_status({})
get_scene_info({})
search_assets({source: "polyhaven", asset_type: "models", query: "office notepad", limit: 5})
# Revisar ficha/licencia del candidato y usar el ID realmente devuelto.
import_asset({source: "polyhaven", asset_type: "models", id: "<id devuelto>", resolution: "1k"})
```

`search_assets` admite `source: "polypizza"` con `licence: "CC0"` o `"CC-BY"`, y `source: "sketchfab"` con licencias variables; el filtro no reemplaza revisar ficha y permisos del servicio. No activar conectores ni contratar planes sin una necesidad autorizada.

**Estado local comprobado (2026-10-09)**: Blender 5.2.2 LTS conectado; addon 1.7/protocolo 11 frente a protocolo esperado 13; bibliotecas `polyhaven`, `sketchfab`, `polypizza` en `off`. El servidor indicó actualizar con `uvx mcp-for-blender install-addon`, reiniciar o desactivar/activar el addon y volver a iniciar MCP Server. No se actualizó ni se cambiaron ajustes en esta tarea. Buscar/importar desde esos conectores queda pendiente de configuración; las descargas HTTP funcionan independientemente.

**Poly Pizza**: existe documentación oficial enlazada por su sitio, pero el contenido de autenticación no fue legible mediante las consultas realizadas. No se fija un endpoint, cabecera o cuota inventados. Antes de implementar acceso, revisar esa documentación desde una sesión autorizada. Sus [términos](https://poly.pizza/docs/tos) restringen bots/scraping y remiten a interfaces publicadas. La presencia del conector MCP no concede permiso por sí sola.

**Sketchfab**: la [Download API](https://sketchfab.com/developers/download-api) requiere cuenta autenticada. Obtener metadatos/licencia del UID, solicitar `GET /v3/models/<UID>/download` mediante el flujo autorizado documentado y descargar la URL temporal devuelta. No guardar tokens/URLs firmadas en créditos. No se hizo una descarga autenticada ni se verificó acceso de cuenta aquí.

## 6. Preparar para la canalización del proyecto

### Modelos

- Mantener silueta reconocible, piezas y biseles; stock no permite sustituir objetos por primitivas sueltas. Medir dimensiones reales, aplicar transformaciones y colocar pivote adecuado. Exportar GLB con dependencias incluidas, normales correctas y escala consistente con el modelo propio equivalente.
- Orientar y recolorear al lenguaje de oficina del prólogo; los backrooms mantienen su estética clásica y carecen de logos NOHO. Evitar apariencia de juguete por saturación o proporciones aunque el recurso sea low poly.
- Tomar como referencia los presupuestos por objeto de `SPECS` en `tools/blender/build_models.py`; simplificar modelos caros, mantener detalles en primeros planos y medir coste cuando se repiten. No hay un límite universal de polígonos autorizado para todos los objetos.
- **Limitación real del constructor**: `_emit_prop()` en `tools/level_builder/level_builder.gd` extrae geometría y `albedo_color` y la funde en la paleta compartida. No conserva el PBR ni las texturas del modelo stock. Las excepciones explícitas son materiales `Screen`, `Flame` y `Glow`; no asignar estos nombres accidentalmente.
- Adaptar el stock secundario a materiales planos antes de exportarlo. Si necesita textura propia indispensable, revisar la canalización y el máximo de seis materiales antes de implementarlo; no prometer que importar el GLB conserva el aspecto del catálogo.
- Añadir el prop en `tools/levels/<nivel>_def.gd` con las convenciones de `LevelDef.props` y reconstruir según `docs/15`. El constructor usa límites del modelo para la colisión; revisar pasos libres y objetos largos o irregulares en juego.

### Texturas

- Usar 512×512 como punto de partida para patrones secundarios y un atlas/paleta por nivel de hasta 1024×1024; respetar seis materiales compartidos. Estos valores provienen de la dirección de arte/presupuesto del proyecto, no del catálogo.
- Verificar mosaico en una cuadrícula 3×3 y tamaño de patrón en metros: alfombra, tapiz y plafón no deben parecer miniaturas o tener costuras. Desaturar/recolorear sin perder la licencia del original y anotar las modificaciones.
- En la ruta actual, usar albedo donde la definición del nivel ya admita textura. Revisar `shaders/baked_surface.gdshader`: no se obtiene un material PBR completo por descargar sus mapas. Roughness/AO/normal son opcionales solo si se implementan y verifican; ningún mapa debe traer luces en tiempo real.
- Displacement de catálogo no obliga a añadir geometría ni tessellation. Evitar EXR/HDR para una textura mate corriente, mapas duplicados y alfa innecesario. No introducir HDRIs que alteren la iluminación horneada del juego.
- Guardar el derivado final y su procedencia. El ZIP y mapas descartados permanecen en staging para no inflar el repositorio ni la exportación; comprobar peso real del export, objetivo <100 MB.

## 7. Registro de procedencia y créditos

Para cada recurso integrado crear una ficha, por ejemplo `assets/provenance/office_notepad/asset.json`:

```json
{
  "name": "office_notepad",
  "importance": "baja",
  "decision": "stock: papelería incidental fuera de primeros planos",
  "provider": "Poly Haven",
  "source_id": "office_notepads",
  "source_url": "https://polyhaven.com/a/office_notepads",
  "author": "Ulan Cabanilla",
  "license": "CC0-1.0",
  "license_url": "https://polyhaven.com/license",
  "retrieved_at": "2026-10-09",
  "variant": "gltf/1k/gltf",
  "source_sha256": "<copiar del manifiesto real de descarga>",
  "output_files": ["assets/models/office_notepad.glb"],
  "changes": ["escala real", "materiales planos de paleta"],
  "status": "<candidato, adaptado o integrado según comprobación real>"
}
```

Es una **plantilla**, no un recurso integrado. Adjuntar `provenance.json` real del descargador y la licencia/evidencia redistribuible. Guardar también el SHA-256 del derivado y la receta de transformación. Para CC BY indicar versión exacta, título, autor, enlace de origen, enlace de licencia y cambios; preparar esa atribución para los créditos que acompañen la distribución, además de `assets/CREDITS.md`. No afirmar autoría propia del stock.

Para pago: conservar comprobante y EULA aplicable de forma privada, registrar en créditos una referencia interna sin datos personales y comprobar que la licencia autoriza colaboradores, motor y distribución. No publicar fuentes comerciales en un repositorio accesible a terceros; una adaptación no elimina la restricción.

## 8. Verificación realizada

Las muestras se descargaron a `/tmp/noho-stock-check/`, **sin integrarlas ni cambiar escenas**. Staging temporal no es biblioteca persistente; repetir las recetas si esos archivos ya no existen.

| Fuente / muestra | Resultado comprobado | Bytes descargados |
|---|---|---:|
| Kenney Furniture Kit | ZIP descargado; CRC válido; incluye `License.txt` y modelos GLB | 5 130 729 |
| Poly Haven `office_notepads`, `gltf/1k/gltf` | Modelo + cuatro dependencias descargados; tamaños y MD5 verificados; URIs externas del glTF resuelven localmente | 1 332 895 |
| Poly Haven `dirty_carpet`, `Diffuse/1k/jpg` | Albedo descargado; tamaño y MD5 verificados | 978 020 |
| ambientCG `Carpet016`, `1K-JPG` | ZIP descargado; tamaño declarado y CRC válidos | 9 371 762 |
| Blender MCP | Estado inspeccionado; búsqueda/importación de bibliotecas no probadas porque están desactivadas | — |

SHA-256 de las muestras independientes para reproducibilidad (el glTF tiene además hashes individuales de dependencias en su manifiesto):

```text
kenney_furniture-kit.zip       e67652d0932cee41683f74711c03d3e192a2af9979ef8e6b237711f5482d46b0
office_notepads_1k.gltf        dec1bd1f656e21bbda8957bcd19a715b1d1fbc5f9f153ada7ccdaf8407d97411
dirty_carpet_diff_1k.jpg       b0ef2b248cb7dfa1d33f1b2215fb3b83e815527d4091a2c3a423bdcd63bef60a
Carpet016_1K-JPG.zip           b9e67b5d42cb47cead082dedae3767ae228175c857b6b3af6fe7bd4e69237b81
```

La descarga prueba acceso técnico e integridad, **no adecuación artística ni rendimiento en Godot**. Las fuentes no probadas quedan marcadas como condicionales. Antes de reutilizar una receta tras cambios de proveedor, revisar ficha, licencia y API vigentes; Context7 resolvió Poly Haven como `/websites/api_polyhaven`, pero las respuestas reales y los términos oficiales actuales prevalecen sobre ejemplos indexados inconsistentes.

## 9. Meshy.ai — personajes generados, rigging y animación

> **Añadido 2026-10-09** por decisión del usuario. Clave `MESHYAI` en `.env` (nunca se imprime ni se versiona). Saldo inicial: **1 000 créditos**, compartidos por todo el proyecto.

### Cuándo usarlo

| Caso | ¿Meshy? |
|---|---|
| **El Olvidado** (malla orgánica, esqueleto, animaciones) | **Sí**: es el motivo de tener la clave |
| Otro elemento **orgánico o esculpido** que por script de Blender queda pobre (calavera gigante, relieve de barro negro, roca) | Sí, si es importante y tras intentar el modelado propio |
| Mobiliario, arquitectura, utilería geométrica, letras, piezas de marca | **No**: Blender por script (`tools/blender/build_models.py`), como siempre |
| Relleno secundario | No: stock CC0 primero (este documento) |

Meshy no sustituye la regla dura 10 ni la estética: lo generado se **adapta** (escala, origen, reducción de polígonos, paleta oscura y desaturada) antes de entrar al juego.

### Flujo obligatorio: imagen primero, luego 3D

1. **Imagen de referencia con OpenAI** (`tools/assets/gen_image.py`, clave `openaiKey`): una sola figura completa, de frente, **pose en A**, fondo liso neutro, luz plana, sin sombras proyectadas ni texto. Estilo low-poly moderno (variante B de `concept/art/`). Se guarda en `builds/meshy/<nombre>/ref.png` y se **mira** antes de gastar créditos; si no convence, se regenera la imagen (barato), no el modelo (caro).
2. **Imagen → 3D** con `tools/assets/meshy.py image-to-3d` (la imagen va como data URI en base64; no hace falta alojarla).
3. **Rigging** (`meshy.py rig`, solo humanoides en pose A/T) y **animaciones** (`meshy.py animate`, acciones de la biblioteca de Meshy).
4. **Adaptación** en Blender por script (`blender -b -P …`): escala real, origen en el suelo, limpieza, un solo material, textura ≤ 1024 px, clips renombrados; exportar `.glb` a `assets/models/`.
5. **Registro** en `assets/CREDITS.md` en el mismo cambio: herramienta, fecha, IDs de tarea, prompt de la imagen, modificaciones.

### API (verificada el 2026-10-09 en docs.meshy.ai)

Base `https://api.meshy.ai`, cabecera `Authorization: Bearer $MESHYAI`. Todas las tareas son asíncronas: `POST` devuelve `{"result": "<id>"}` y se consulta con `GET …/<id>` hasta `status` `SUCCEEDED`/`FAILED`. Las URLs de resultado **caducan**: descargar enseguida.

| Paso | Endpoint | Parámetros que usamos |
|---|---|---|
| Imagen → 3D | `POST /openapi/v1/image-to-3d` | `image_url` (URL o data URI), `ai_model: "latest"`, `model_type: "lowpoly"` (no admitido por `meshy-6-lite`), `topology: "triangle"`, `should_remesh: true`, `target_polycount` (mín. 1000; personajes 5 000–8 000), `should_texture: true`, `texture_resolution: "1024"`, `enable_pbr: false`, `pose_mode: "a-pose"`, `target_formats: ["glb"]`, `enable_thumbnail: true` |
| Rigging | `POST /openapi/v1/rigging` | `input_task_id` (o `model_url`), `height_meters`. Devuelve el personaje con esqueleto y dos clips básicos (caminar, correr) |
| Animación | `POST /openapi/v1/animations` | `rig_task_id` + `action_id` o `action_ids` (1–10: un archivo con un clip por acción); `post_process: {operation_type: "change_fps", fps: 24}` |
| Consumo | Usage API / saldo | Consultar **antes y después** de cada tanda |

### Presupuesto de créditos

- Costes observados en la documentación: imagen → 3D con textura ≈ 20–30 créditos, rigging ≈ 5, animación ≈ 3 por tarea. `meshy.py` lee `consumed_credits` de cada tarea y lleva la cuenta en `builds/meshy/ledger.json`.
- **Topes**: El Olvidado ≤ 300 créditos en total (incluidos reintentos); cualquier otro objeto ≤ 60. Nunca bajar de **200 créditos de reserva** sin preguntar al usuario.
- Máximo **3 intentos** de imagen → 3D por objeto. Si el tercero no sirve, se vuelve al modelado propio y se anota por qué.
- Un agente que use Meshy escribe en su informe: saldo antes/después, tareas lanzadas y créditos de cada una.

### Restricciones del juego que lo generado debe cumplir

- Renderer Compatibility, Web de un hilo: malla con esqueleto ≤ 8 000 triángulos, **un material**, una textura ≤ 1024 px, ≤ 60 huesos, animaciones a 24 fps.
- Sin luz propia: la entidad se ve por la linterna y como silueta contra la niebla (`docs/05`, regla dura 4).
- Peso: cada `.glb` generado ≤ 3 MB (presupuesto total < 100 MB, regla dura 8).
- Canon: diseño **original** (`docs/01`, `docs/05`); nada que recuerde a entidades de las wikis de Backrooms.
