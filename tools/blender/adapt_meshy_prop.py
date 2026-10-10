"""Adapta Meshy sin texturas: blender -b -P … -- nombre origen.glb [--turn grados].

Salida candidata en builds/meshy/props/nombre; no sustituye un asset sin revisión.
"""
import argparse
import importlib.util
import json
import math
from pathlib import Path
import sys
import bpy
import bmesh
import numpy as np
from mathutils import Matrix, Vector
sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('models',ROOT / 'tools/blender/build_models.py')
models = importlib.util.module_from_spec(spec); spec.loader.exec_module(models)
spec = importlib.util.spec_from_file_location('props',ROOT / 'tools/assets/meshy_props.py')
props = importlib.util.module_from_spec(spec); spec.loader.exec_module(props)


def bounds(objects):
    points = [o.matrix_world @ v.co for o in objects for v in o.data.vertices]
    return np.array([[min(p[i] for p in points) for i in range(3)], [max(p[i] for p in points) for i in range(3)]])


def load_meshes(path):
    models.clear()
    bpy.ops.import_scene.gltf(filepath=str(path))
    objects = [o for o in bpy.context.scene.objects if o.type == 'MESH']
    matrices = {o:o.matrix_world.copy() for o in objects}
    for o in objects:
        o.parent = None
        o.data.transform(matrices[o]); o.matrix_world = Matrix.Identity(4)
    for o in list(bpy.context.scene.objects):
        if o.type != 'MESH': bpy.data.objects.remove(o,do_unlink=True)
    return objects


def sample_faces(o):
    images = {}
    for i, mat in enumerate(o.data.materials):
        if mat and mat.use_nodes:
            bsdf = next((n for n in mat.node_tree.nodes if n.type == 'BSDF_PRINCIPLED'),None)
            links = bsdf.inputs['Base Color'].links if bsdf else []
            node = links[0].from_node if links else None
            if node and node.type == 'TEX_IMAGE' and node.image:
                img = node.image; w,h = img.size
                buffer = np.empty(w*h*4,dtype=np.float32); img.pixels.foreach_get(buffer)
                images[i] = (buffer.reshape(h,w,4),w,h)
    colors = []
    uv = o.data.uv_layers.active
    for face in o.data.polygons:
        entry = images.get(face.material_index)
        if entry and uv:
            data,w,h = entry
            samples = [uv.data[j].uv[:] for j in face.loop_indices]
            samples.append(tuple(np.mean(samples,axis=0)))
            color = np.mean([data[min(h-1,int((v%1)*h)),min(w-1,int((u%1)*w)),:3] for u,v in samples],axis=0)
        else:
            mat = o.data.materials[face.material_index] if o.data.materials else None
            color = np.array(mat.diffuse_color[:3] if mat else (.5,.5,.5))
        colors.append(color)
    return np.asarray(colors)


def quantize(objects,name):
    samples = [sample_faces(o) for o in objects]
    colors = np.concatenate(samples)
    # El cian puro reservado es una máscara de emisión; no confundirlo con azul/verde.
    emit = (colors[:,0] < .12) & (colors[:,1] > .70) & (colors[:,2] > .70) & (np.abs(colors[:,1]-colors[:,2]) < .22)
    use_emit = bool(emit.any()) and name in ('sugar_skull_giant','copal_censer')
    regular = colors[~emit] if use_emit else colors
    color_limit = 8 if name in props.HIGH_COLOR_PROPS else 6
    ordinary_limit = color_limit - (1 if use_emit else 0)
    if len(regular) == 0:
        regular = np.array([[242/255, 233/255, 213/255]], dtype=np.float32)
    k = min(ordinary_limit,len(regular))
    centers = np.array([regular[int(i)] for i in np.linspace(0,len(regular)-1,k)])
    # Semilla determinista por máxima distancia: evita centros repetidos.
    for i in range(1,k):
        d = ((regular[:,None,:]-centers[None,:i,:])**2).sum(axis=2).min(axis=1)
        centers[i] = regular[d.argmax()]
    for _ in range(30):
        ids = ((regular[:,None,:]-centers[None,:,:])**2).sum(axis=2).argmin(axis=1)
        updated = np.array([regular[ids==i].mean(axis=0) if (ids==i).any() else centers[i] for i in range(k)])
        if np.max(np.abs(updated-centers)) < .0001: break
        centers = updated
    names = [n for n in models.PALETTE if n not in ('Glow','Flame','Screen')]
    pal = np.array([[int(models.PALETTE[n][i:i+2],16)/255 for i in (0,2,4)] for n in names])
    pal = np.where(pal<=.04045,pal/12.92,((pal+.055)/1.055)**2.4)
    mapped = [names[i] for i in ((centers[:,None,:]-pal[None,:,:])**2).sum(axis=2).argmin(axis=1)]
    assigned = ((colors[:,None,:]-centers[None,:,:])**2).sum(axis=2).argmin(axis=1)
    offset = 0
    for o, sample in zip(objects,samples):
        o.data.materials.clear()
        unique = list(dict.fromkeys(mapped + (['Glow' if name=='sugar_skull_giant' else 'Flame'] if use_emit else [])))
        for n in unique: o.data.materials.append(models.material(n))
        for face in o.data.polygons:
            idx = offset + face.index
            n = ('Glow' if name=='sugar_skull_giant' else 'Flame') if use_emit and emit[idx] else mapped[assigned[idx]]
            face.material_index = unique.index(n); face.use_smooth = False
        offset += len(sample)
        while o.data.uv_layers: o.data.uv_layers.remove(o.data.uv_layers[0])
    return unique


def cleanup(o):
    bm = bmesh.new(); bm.from_mesh(o.data)
    bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.00001)
    bmesh.ops.dissolve_degenerate(bm,edges=list(bm.edges),dist=.000001)
    # Islas microscópicas, no ornamentos que forman piezas reconocibles.
    todo = set(bm.verts); islands = []
    while todo:
        stack = [todo.pop()]; group = set(stack)
        while stack:
            v = stack.pop()
            for edge in v.link_edges:
                other = edge.other_vert(v)
                if other in todo: todo.remove(other); group.add(other); stack.append(other)
        islands.append(group)
    if islands:
        largest = max(len(g) for g in islands)
        tiny = [v for g in islands if len(g) < max(3,largest*.0005) for v in g]
        if tiny: bmesh.ops.delete(bm,geom=tiny,context='VERTS')
    wire = [v for v in bm.verts if not v.link_faces]
    if wire: bmesh.ops.delete(bm,geom=wire,context='VERTS')
    # Caras interiores topológicas: todas sus aristas conectan >2 caras.
    interior = [f for f in bm.faces if all(len(e.link_faces)>2 for e in f.edges)]
    if interior: bmesh.ops.delete(bm,geom=interior,context='FACES')
    bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
    bm.to_mesh(o.data); bm.free(); o.data.update()


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('name',choices=list(props.BUDGETS)+['clay_wall_broken','oak_door_open'])
    p.add_argument('source',type=Path)
    p.add_argument('--turn',type=float,default=0)
    args = p.parse_args(sys.argv[sys.argv.index('--')+1:])
    folder = ROOT / 'builds/meshy/props' / args.name; folder.mkdir(parents=True,exist_ok=True)
    if not (folder / 'before.glb').exists():
        import shutil
        shutil.copy2(ROOT / 'assets/models' / (args.name+'.glb'),folder / 'before.glb')
    previous = bounds(load_meshes(folder / 'before.glb'))
    objects = load_meshes(args.source)
    for o in objects:
        o.data.transform(Matrix.Rotation(math.radians(args.turn),4,'Z'))
        if args.name=='sugar_skull_giant': o.data.transform(Matrix.Rotation(math.pi/2,4,'X'))
        cleanup(o)
    if args.name not in ('clay_wall_broken','oak_door_open'): quantize(objects,args.name)
    bpy.ops.object.select_all(action='SELECT'); bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.object.join(); o = bpy.context.object
    if args.name == 'clay_wall_broken':
        # El panel ya está centrado en pared: el boquete parte del borde inferior.
        floor = min(v.co.z for v in o.data.vertices)
        outline = [(-.50,floor-.1),(.50,floor-.1),(.48,floor+.40),(.55,floor+.75),(.47,floor+1.15),(.52,floor+1.70),(.39,floor+2.04),(-.38,floor+2.0),(-.52,floor+1.73),(-.46,floor+1.20),(-.54,floor+.65)]
        cutter = models.prism('Boquete',outline,-1.,1.,'Black_Clay','Y')
        bpy.context.view_layer.objects.active = o
        mod = o.modifiers.new('Rotura irregular','BOOLEAN'); mod.operation='DIFFERENCE'; mod.solver='EXACT'; mod.object=cutter
        bpy.ops.object.modifier_apply(modifier=mod.name)
        bpy.data.objects.remove(cutter,do_unlink=True)
        # El panel importado puede conservar una cara interior no-manifold tras la booleana.
        # Retira el núcleo del boquete en todas las profundidades y deja intacto el borde roto.
        bm = bmesh.new(); bm.from_mesh(o.data)
        core = [f for f in bm.faces if abs(f.calc_center_median().x) < .36 and floor-.02 < f.calc_center_median().z < floor+1.92]
        if core: bmesh.ops.delete(bm, geom=core, context='FACES')
        bm.to_mesh(o.data); bm.free(); o.data.update()
        for side in (-1,1):
            for i in range(3):
                x = side*(.64+.09*i)
                models.prism('Cascote',[(x-.07,-.14),(x+.04,-.18),(x+.08,-.06),(x-.03,.01)],floor,floor+.07+.02*i,'Black_Clay','Z')
        bpy.ops.object.select_all(action='SELECT'); bpy.context.view_layer.objects.active=o; bpy.ops.object.join()
    if args.name == 'oak_door_open':
        # Separa las hojas del marco por la región interior; conserva los mismos relieves.
        data = o.data; data.calc_loop_triangles()
        materials = list(data.materials)
        regions = {0:[], -1:[], 1:[]}
        for f in data.polygons:
            c = f.center
            side = (-1 if c.x < 0 else 1) if abs(c.x)<1.10 and .14<c.z<3.54 else 0
            regions[side].append(f)
        pieces = []
        for side,faces in regions.items():
            used = sorted({i for f in faces for i in f.vertices}); indices={old:new for new,old in enumerate(used)}
            verts = [data.vertices[i].co.copy() for i in used]
            if side:
                hinge = Vector((side*1.10,0,0)); rotation = Matrix.Rotation(-side*math.radians(72),4,'Z')
                verts = [rotation @ (v-hinge)+hinge for v in verts]
            mesh = bpy.data.meshes.new('Marco' if not side else 'Hoja')
            mesh.from_pydata(verts,[],[tuple(indices[i] for i in f.vertices) for f in faces])
            for mat in materials: mesh.materials.append(mat)
            for f,old in zip(mesh.polygons,faces): f.material_index=old.material_index; f.use_smooth=False
            obj=bpy.data.objects.new(mesh.name,mesh); bpy.context.collection.objects.link(obj); pieces.append(obj)
        bpy.data.objects.remove(o,do_unlink=True)
        bpy.ops.object.select_all(action='SELECT'); bpy.context.view_layer.objects.active=pieces[0]; bpy.ops.object.join(); o=bpy.context.object
    budget = props.BUDGETS.get(args.name,2500 if args.name=='oak_door_open' else 1500)
    for _ in range(5):
        o.data.calc_loop_triangles(); count = len(o.data.loop_triangles)
        if count <= budget: break
        mod = o.modifiers.new('Presupuesto','DECIMATE'); mod.ratio = budget/count*.96
        bpy.ops.object.modifier_apply(modifier=mod.name)
    for f in o.data.polygons: f.use_smooth=False
    while o.data.uv_layers: o.data.uv_layers.remove(o.data.uv_layers[0])
    # Conserva exactamente el desplazamiento nominal del asset anterior.
    current = bounds([o]); target = np.array(models.SPECS[args.name][0])
    target_min = previous[0]
    for v in o.data.vertices:
        v.co = Vector(tuple(target_min+(np.array(v.co)-current[0])*target/(current[1]-current[0])))
    o.data.update()
    actual = bounds([o]); o.data.calc_loop_triangles()
    tris = len(o.data.loop_triangles)
    materials = sorted({o.data.materials[f.material_index].name for f in o.data.polygons})
    color_limit = 8 if args.name in props.HIGH_COLOR_PROPS else 6
    if tris > budget or len(materials)>color_limit or not set(materials)<=set(models.PALETTE):
        raise ValueError(f'{args.name}: triángulos={tris}/{budget}, materiales={len(materials)}/{color_limit} {materials}')
    assert np.all(np.abs(actual[0]-previous[0])<.008)
    assert np.all(np.abs((actual[1]-actual[0])/target-1)<.1)
    assert not o.modifiers and not o.data.uv_layers
    assert all(not f.use_smooth for f in o.data.polygons)
    metric = {'name':args.name,'triangles':tris,'budget':budget,'materials':materials,'previous_bounds':previous.tolist(),'bounds':actual.tolist(),'front':'-Z Blender / -Y Godot' if args.name=='sugar_skull_giant' else '-Y Blender / +Z Godot','turn':args.turn,'source':str(args.source)}
    (folder / 'metrics.json').write_text(json.dumps(metric,indent=2)+'\n')
    bpy.ops.export_scene.gltf(filepath=str(folder / 'candidate.glb'),export_format='GLB',export_apply=True,export_yup=True,use_selection=True,export_materials='EXPORT',export_normals=True,export_texcoords=False,export_animations=False,export_cameras=False,export_lights=False)
    print('VALIDADO',json.dumps(metric),flush=True)

if __name__=='__main__':
    try: main()
    except Exception:
        import traceback; traceback.print_exc(); sys.exit(1)
