# Adquisición de recursos para agentes

Leer primero [docs/16 — Modelos y texturas](../../docs/16-assets-stock.md) y las
reglas del proyecto. **Modelar en Blender los objetos importantes o muy visibles;
buscar stock para recursos secundarios o de relleno.**

## Descargador de stock CC0

`stock_assets.py` usa Python 3.9+ estándar y HTTPS, sin claves ni instalación pip.
Implementa APIs oficiales de Poly Haven y ambientCG. Ejemplo completo:

```bash
python3 tools/assets/stock_assets.py search polyhaven --kind models --query office
python3 tools/assets/stock_assets.py files polyhaven --kind models --id office_notepads
python3 tools/assets/stock_assets.py download polyhaven --kind models --id office_notepads \
  --variant gltf/1k/gltf --out builds/asset_staging/polyhaven/office_notepads

python3 tools/assets/stock_assets.py search ambientcg --query carpet
python3 tools/assets/stock_assets.py files ambientcg --id Carpet016
python3 tools/assets/stock_assets.py download ambientcg --id Carpet016 \
  --variant 1K-JPG --out builds/asset_staging/ambientcg/Carpet016
```

Ejecutar desde la raíz del proyecto; elegir IDs y variantes devueltos por las
consultas. `--kind` por defecto es `textures`. `--out` debe ser un directorio
nuevo. `--max-mb` limita los bytes con dependencias (30 MiB por defecto).
`python3 tools/assets/stock_assets.py --help` muestra las opciones.

Incluye dependencias de glTF, verifica tamaño y MD5 cuando existe y escribe hashes
SHA-256 en `provenance.json`. No extrae ZIPs ni convierte modelos; un estado
`downloading` indica descarga incompleta. Tras un fallo, revisar staging y repetir
con un directorio nuevo. No aumentar automáticamente el límite ante un asset caro.

Staging no se versiona ni se integra solo. Inspeccionar, adaptar y exportar GLB
con colores planos compatibles con el constructor; convertir/reducir las texturas
necesarias. Registrar los derivados en [assets/CREDITS.md](../../assets/CREDITS.md)
y conservar procedencia y licencia. La guía incluye recetas para Kenney y acceso
condicional por Blender MCP, Poly Pizza, Sketchfab y tiendas comerciales.

## Otras herramientas

- `gen_image.py`: generación de imágenes/texturas a medida; documentada en
  [docs/15](../../docs/15-implementacion.md). Usar las condiciones del servicio
  correspondiente y mantener credenciales fuera de Git.
- Para modelado propio reproducible, ver `tools/blender/build_models.py`.
