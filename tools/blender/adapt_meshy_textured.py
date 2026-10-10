"""Modelos de Meshy CON su textura ("hero"): blender -b -P tools/blender/adapt_meshy_textured.py -- nombre [...]

Parte del .glb crudo de Meshy (builds/meshy/props/<nombre>/attempt*/model_url.glb), lo encaja en la
caja, origen y orientación del modelo de color plano del mismo nombre (assets/models/<nombre>.glb),
lo decima con moderación y lo exporta con su textura (JPEG ≤ 1024 px) a assets/models/hero/.
El nivel los instancia aparte, con `shaders/hero_prop.gdshader`, en vez de fundirlos en la paleta.
"""
import json, math, sys
from pathlib import Path
import bpy
from mathutils import Matrix, Vector

ROOT = Path(__file__).resolve().parents[2]
BUDGET = {'sugar_skull': 2600, 'sugar_skull_giant': 6000, 'ofrenda_arch': 7000, 'clay_wall_panel': 5000,
          'oak_door_monumental': 6000, 'stone_stele': 2500, 'marigold_pile': 2500}
DEFAULT_BUDGET = 1800


def clear():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def load(path):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=str(path))
    meshes = [o for o in bpy.data.objects if o not in before and o.type == 'MESH']
    for o in meshes:
        bpy.context.view_layer.objects.active = o
        o.select_set(True)
        mat = o.matrix_world.copy()
        o.parent = None
        o.matrix_world = mat
    bpy.ops.object.select_all(action='DESELECT')
    for o in meshes:
        o.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    for o in list(bpy.data.objects):
        if o not in meshes:
            bpy.data.objects.remove(o, do_unlink=True)
    return meshes


def bounds(objects):
    pts = [o.matrix_world @ v.co for o in objects for v in o.data.vertices]
    return Vector([min(p[i] for p in pts) for i in range(3)]), Vector([max(p[i] for p in pts) for i in range(3)])


def adapt(name):
    folder = ROOT / 'builds/meshy/props' / name
    metric = json.loads((folder / 'metrics.json').read_text())
    clear()
    target_min, target_max = bounds(load(ROOT / 'assets/models' / f'{name}.glb'))
    clear()
    objects = load(ROOT / metric['source'])
    if len(objects) > 1:
        bpy.ops.object.join()
    o = bpy.context.view_layer.objects.active
    o.data.transform(Matrix.Rotation(math.radians(metric.get('turn', 0)), 4, 'Z'))
    if name == 'sugar_skull_giant':
        o.data.transform(Matrix.Rotation(math.pi / 2, 4, 'X'))
    lo, hi = bounds([o])
    size, target = hi - lo, target_max - target_min
    scale = Matrix.Diagonal((target.x / size.x, target.y / size.y, target.z / size.z, 1.0))
    o.data.transform(Matrix.Translation(target_min) @ scale @ Matrix.Translation(-lo))
    o.data.calc_loop_triangles()
    tris = len(o.data.loop_triangles)
    budget = BUDGET.get(name, DEFAULT_BUDGET)
    if tris > budget:
        mod = o.modifiers.new('Decimar', 'DECIMATE')
        mod.ratio = budget / tris
        bpy.ops.object.modifier_apply(modifier=mod.name)
    for polygon in o.data.polygons:
        polygon.use_smooth = True
    for image in bpy.data.images:
        if image.size[0] > 1024:
            image.scale(1024, 1024)
    o.name = name
    out = ROOT / 'assets/models/hero'
    out.mkdir(parents=True, exist_ok=True)
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.export_scene.gltf(filepath=str(out / f'{name}.glb'), export_format='GLB', export_apply=True, export_yup=True,
        use_selection=True, export_materials='EXPORT', export_image_format='JPEG', export_jpeg_quality=85,
        export_normals=True, export_texcoords=True, export_animations=False, export_cameras=False, export_lights=False)
    o.data.calc_loop_triangles()
    print(f'HERO {name}: {len(o.data.loop_triangles)} tris, {(out / (name + ".glb")).stat().st_size // 1024} KiB', flush=True)


if __name__ == '__main__':
    for model in sys.argv[sys.argv.index('--') + 1:]:
        adapt(model)
