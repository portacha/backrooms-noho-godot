"""Adapta Meshy a un GLB ligero: blender -b -P tools/blender/adapt_entity.py -- --input DIR.

El manifiesto DIR/clips.json relaciona cada clip con {file, action}.
La salida intermedia se revisa antes de copiarla al modelo de producción.
"""
import argparse
import hashlib
import json
import math
from pathlib import Path
import sys
import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
CLIPS = ('idle', 'walk', 'search', 'run', 'attack', 'scream')


def import_glb(path):
    before = set(bpy.context.scene.objects)
    bpy.ops.import_scene.gltf(filepath=str(path))
    return [obj for obj in bpy.context.scene.objects if obj not in before]


def action_curves(action):
    for layer in action.layers:
        for strip in layer.strips:
            for bag in strip.channelbags:
                yield from bag.fcurves


def use_action(rig, action):
    rig.animation_data_create()
    for track in rig.animation_data.nla_tracks:
        track.mute = True
    rig.animation_data.action = action
    if action.slots:
        rig.animation_data.action_slot = action.slots[0]


def material_texture(mesh):
    images = []
    for mat in mesh.data.materials:
        if mat and mat.use_nodes:
            for node in mat.node_tree.nodes:
                if node.type == 'TEX_IMAGE' and node.image:
                    images.append(node.image)
    unique = list(dict.fromkeys(images))
    if len(unique) != 1:
        raise RuntimeError(f'Se esperaba una textura base; hay {len(unique)}')
    image = unique[0].copy()
    image.name = 'Olvidado_Albedo'
    image.scale(min(1024, image.size[0]), min(1024, image.size[1]))
    # Conserva bordados y pétalos; la linterna no debe revelar blancos quemados.
    pixels = list(image.pixels[:])
    for i in range(0, len(pixels), 4):
        r, g, b = pixels[i:i+3]
        grey = r * .2126 + g * .7152 + b * .0722
        pixels[i:i+3] = [max(0, (.82 * c + .18 * grey) * .70) for c in (r, g, b)]
    image.pixels[:] = pixels
    image.pack()
    mat = bpy.data.materials.new('Olvidado_Mate')
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get('Principled BSDF')
    bsdf.inputs['Roughness'].default_value = 1
    bsdf.inputs['Metallic'].default_value = 0
    texture = mat.node_tree.nodes.new('ShaderNodeTexImage')
    texture.image = image
    mat.node_tree.links.new(texture.outputs['Color'], bsdf.inputs['Base Color'])
    mesh.data.materials.clear()
    mesh.data.materials.append(mat)
    for poly in mesh.data.polygons:
        poly.material_index = 0
        poly.use_smooth = False
    return image


def contact_sheet(mesh, rig, clips, out):
    scene = bpy.context.scene
    scene.render.engine = 'CYCLES'
    scene.cycles.samples = 16
    scene.render.resolution_x = 400
    scene.render.resolution_y = 640
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = 'PNG'
    scene.view_settings.view_transform = 'Standard'
    scene.world.use_nodes = True
    scene.world.node_tree.nodes.get('Background').inputs[0].default_value = (.32, .32, .32, 1)
    scene.world.node_tree.nodes.get('Background').inputs[1].default_value = .8
    data = bpy.data.cameras.new('CameraRevision')
    camera = bpy.data.objects.new('CameraRevision', data)
    scene.collection.objects.link(camera)
    scene.camera = camera
    data.type = 'ORTHO'
    data.ortho_scale = 3.15
    images = []
    # Frente de exportación: Blender +Y corresponde a Godot -Z.
    for label, angle, clip, moment in [
        ('front', 0, 'idle', 0), ('side', math.pi/2, 'idle', 0),
        ('back', math.pi, 'idle', 0), ('run', 0, 'run', .35), ('attack', 0, 'attack', .45)]:
        use_action(rig, clips[clip])
        start, end = clips[clip].frame_range
        scene.frame_set(round(start + (end - start) * moment))
        camera.location = (6 * math.sin(angle), 6 * math.cos(angle), 1.3)
        camera.rotation_euler = (Vector((0, 0, 1.3)) - camera.location).to_track_quat('-Z', 'Y').to_euler()
        scene.render.filepath = str(out.parent / f'view-{label}.png')
        bpy.ops.render.render(write_still=True)
        images.append(bpy.data.images.load(scene.render.filepath))
    sheet = bpy.data.images.new('Hoja de contacto', width=2000, height=640, alpha=False)
    import numpy as np
    rows = [np.array(image.pixels[:], dtype=np.float32).reshape(640,400,4) for image in images]
    sheet.pixels[:] = np.concatenate(rows,axis=1).ravel()
    sheet.filepath_raw = str(out)
    sheet.file_format = 'PNG'
    sheet.save()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--input', type=Path, required=True)
    parser.add_argument('--out', type=Path, default=ROOT/'builds/meshy/olvidado/adapted.glb')
    parser.add_argument('--sheet', type=Path, default=ROOT/'builds/meshy/olvidado/sheet.png')
    parser.add_argument('--front', choices=['-Y', '+Y'], default='-Y')
    args = parser.parse_args(sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else [])
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    for action in list(bpy.data.actions):
        bpy.data.actions.remove(action)
    manifest = json.loads((args.input/'clips.json').read_text())
    objects = import_glb(args.input/manifest['model'])
    rig = next(obj for obj in objects if obj.type == 'ARMATURE')
    if len(rig.data.bones) > 60:
        raise RuntimeError('Más de 60 huesos; no se exporta')
    meshes = [obj for obj in objects if obj.type == 'MESH']
    bpy.ops.object.select_all(action='DESELECT')
    for obj in meshes:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    if len(meshes) > 1:
        bpy.ops.object.join()
    mesh = bpy.context.view_layer.objects.active
    mesh.data.calc_loop_triangles()
    if len(mesh.data.loop_triangles) > 8000:
        mod = mesh.modifiers.new('Presupuesto', 'DECIMATE')
        mod.ratio = 6000/len(mesh.data.loop_triangles)
        bpy.ops.object.modifier_apply(modifier=mod.name)
    material_texture(mesh)
    base_objects = set(bpy.context.scene.objects)
    scene = bpy.context.scene
    scene.render.fps = 24
    clips = {}
    native_speeds = {}
    for name in CLIPS:
        item = manifest[name]
        before_actions = set(bpy.data.actions)
        source_objects = import_glb(args.input/item['file'])
        source_rig = next(obj for obj in source_objects if obj.type == 'ARMATURE')
        imported = [action for action in bpy.data.actions if action not in before_actions]
        source_action = next((action for action in imported if action.name.split('.')[0] == item['action']), None)
        if source_action is None:
            raise RuntimeError(f'Clip {item["action"]} ausente: {[a.name for a in imported]}')
        use_action(source_rig, source_action)
        # glTF importa segundos a 24 fps porque el FPS se fija antes de importar.
        start, end = source_action.frame_range
        samples = []
        root_bone = next(bone for bone in source_rig.pose.bones if bone.parent is None)
        origin = None
        root_positions = []
        foot_positions = []
        for frame in range(math.floor(start), math.ceil(end)+1):
            scene.frame_set(frame)
            root_at = source_rig.matrix_world @ root_bone.matrix.translation
            if origin is None:
                origin = root_at.copy()
            root_positions.append(root_at.copy())
            feet = [source_rig.matrix_world @ bone.matrix.translation - root_at
                for bone in source_rig.pose.bones if 'foot' in bone.name.lower()]
            foot_positions.append(feet)
            sample = {bone.name: bone.matrix_basis.copy() for bone in source_rig.pose.bones}
            drift = root_at-origin
            drift.z = 0
            # Locomoción en sitio: el CharacterBody3D es el único que avanza.
            rest_world = source_rig.matrix_world @ root_bone.bone.matrix_local
            sample[root_bone.name].translation -= rest_world.to_3x3().inverted() @ drift
            samples.append(sample)
        duration = max((end-start)/24,1/24)
        distances = []
        for previous, current in zip(root_positions,root_positions[1:]):
            step = current-previous
            step.z = 0
            distances.append(step.length)
        # Una búsqueda que vuelve al origen conserva su velocidad recorrida.
        pace = sum(distances)/duration
        if foot_positions and foot_positions[0]:
            # Alternativa para acciones que ya vienen en sitio: excursión de pie.
            foot_pace = max(sum(abs(current[i].y-previous[i].y)
                for previous,current in zip(foot_positions,foot_positions[1:]))/duration
                for i in range(len(foot_positions[0])))
            pace = max(pace, foot_pace)
        native_speeds[name] = max(pace,.1)
        clip = bpy.data.actions.new(name)
        use_action(rig, clip)
        for frame, sample in enumerate(samples):
            for bone in rig.pose.bones:
                bone.matrix_basis = sample[bone.name]
                bone.rotation_mode = 'QUATERNION'
                bone.keyframe_insert('location', frame=frame)
                bone.keyframe_insert('rotation_quaternion', frame=frame)
                bone.keyframe_insert('scale', frame=frame)
        clip.use_fake_user = True
        clips[name] = clip
        for obj in source_objects:
            bpy.data.objects.remove(obj, do_unlink=True)
        for action in imported:
            bpy.data.actions.remove(action)
    # Elimina los clips básicos duplicados, conserva exactamente seis acciones.
    rig.animation_data.action = None
    for track in list(rig.animation_data.nla_tracks):
        rig.animation_data.nla_tracks.remove(track)
    for action in list(bpy.data.actions):
        if action not in clips.values():
            bpy.data.actions.remove(action)
    # Un portador común conserva matrices de bind y escala sin alterar las curvas.
    rig.data.pose_position = 'REST'
    scene.frame_set(0)
    bpy.context.view_layer.update()
    points = [mesh.matrix_world @ Vector(v) for v in mesh.bound_box]
    height = max(p.z for p in points)-min(p.z for p in points)
    carrier = bpy.data.objects.new('OlvidadoMeshy', None)
    scene.collection.objects.link(carrier)
    for obj in base_objects:
        if obj.parent is None:
            obj.parent = carrier
    scale = 2.6/height
    native_speeds = {name:pace*scale for name,pace in native_speeds.items()}
    carrier.scale = (scale,scale,scale)
    carrier.location.z = -min(p.z for p in points)*scale
    if args.front == '-Y':
        carrier.rotation_euler.z = math.pi
    rig.data.pose_position = 'POSE'
    args.out.parent.mkdir(parents=True,exist_ok=True)
    args.sheet.parent.mkdir(parents=True,exist_ok=True)
    # NLA con una pista por clip; evita mezclarlos en una sola toma.
    for name, clip in clips.items():
        track = rig.animation_data.nla_tracks.new()
        track.name = name
        track.strips.new(name,0,clip)
        track.mute = True
    bpy.ops.object.select_all(action='DESELECT')
    for obj in [*base_objects,carrier]:
        if obj.name in scene.objects:
            obj.select_set(True)
    bpy.context.view_layer.objects.active = rig
    bpy.ops.export_scene.gltf(filepath=str(args.out),export_format='GLB',use_selection=True,
        export_animation_mode='NLA_TRACKS',export_frame_range=False,export_force_sampling=True,
        export_materials='EXPORT',export_yup=True,export_image_format='JPEG',export_jpeg_quality=85)
    mesh.data.calc_loop_triangles()
    metrics = {'triangles':len(mesh.data.loop_triangles),'bones':len(rig.data.bones),
        'bytes':args.out.stat().st_size,'height':2.6,'fps':24,
        'clips':{name:(clip.frame_range[1]-clip.frame_range[0])/24 for name,clip in clips.items()},
        'native_speeds':native_speeds,
        'sha256':hashlib.sha256(args.out.read_bytes()).hexdigest()}
    (args.out.parent/'metrics.json').write_text(json.dumps(metrics,indent=2))
    if metrics['bytes'] > 3*1024*1024:
        raise RuntimeError('GLB excede 3 MB; revisar antes de integrar')
    contact_sheet(mesh, rig, clips, args.sheet)
    print('ENTITY ADAPT OK',json.dumps(metrics))


if __name__ == '__main__':
    main()
