# Backrooms NOHO

Proyecto base 3D para Godot 4.7.2, basado en `investigacion.txt`.

## Abrir y ejecutar

Importa `project.godot` en Godot y pulsa **F6** para ejecutar la escena abierta
o **F5** para ejecutar el proyecto. También puedes usar:

```bash
godot --editor --path .
godot --path .
```

El recorrido actual incluye menú → prólogo → caída → Nivel 1 → letra N.
El renderizador es Compatibility para Web y Android. El estado y los comandos
de reconstrucción y prueba están en [docs/15 — Implementación](docs/15-implementacion.md).

## Organización

- `scenes/`: niveles, jugador e interfaces del juego.
- `scripts/`: lógica GDScript.
- `assets/`: modelos, texturas y audio; procedencia en [CREDITS.md](assets/CREDITS.md).
- `tools/`: construcción de niveles, modelado y adquisición de recursos.
- `docs/`: documentación adicional.
- `investigacion.txt`: documento de diseño original.

La caché `.godot/`, las compilaciones y credenciales de exportación se excluyen
del control de versiones.

## Modelos y texturas para ambientación

**Objetos importantes o muy visibles: modelado propio en Blender. Utilería
secundaria o de relleno: buscar stock primero.** Importar stock con Blender MCP
sigue siendo adquisición de stock; la decisión depende del papel del objeto.

La [guía de assets para agentes](docs/16-assets-stock.md) documenta fuentes,
licencias, acceso mediante API/MCP, descargas probadas, adaptación al constructor
de niveles y registro de créditos. Kenney ofrece mobiliario low poly;
Poly Haven y ambientCG tienen rutas de descarga CC0 verificadas. Poly Pizza,
Sketchfab y las tiendas comerciales tienen condiciones de acceso detalladas allí.

Para buscar y descargar mediante APIs oficiales:

```bash
python3 tools/assets/stock_assets.py search polyhaven --kind models --query office
python3 tools/assets/stock_assets.py search ambientcg --query carpet
```

Seguir después `files` → `download` como explica [tools/assets/README.md](tools/assets/README.md).
Las descargas van a staging; solo se integran derivados revisados, con licencia
y procedencia registradas en el mismo cambio. Leer [AGENTS.md](AGENTS.md) antes
de modificar el proyecto.
