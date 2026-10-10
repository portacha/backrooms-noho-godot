"""Hojas de contacto: blender -b -P tools/blender/render_sheet.py."""
import math
import sys
from pathlib import Path
import bpy
from mathutils import Vector, Matrix

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'builds'


def clear():
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)


def label(name,position,rotation):
    curve=bpy.data.curves.new('Etiqueta','FONT')
    curve.body=name
    curve.align_x='CENTER'
    curve.size=.17
    o=bpy.data.objects.new('Etiqueta',curve)
    bpy.context.collection.objects.link(o)
    o.location=position
    o.rotation_euler=rotation.to_euler()
    m=bpy.data.materials.get('Texto hoja') or bpy.data.materials.new('Texto hoja')
    m.diffuse_color=(.025,.03,.035,1)
    curve.materials.append(m)


def main():
    OUT.mkdir(exist_ok=True)
    names=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else []
    paths=sorted((ROOT/'assets/models'/f'{name}.glb' for name in names)) if names else sorted((ROOT/'assets/models').glob('*.glb'))
    if not paths: raise RuntimeError('Primero construye los modelos.')
    scene=bpy.context.scene
    scene.render.engine='BLENDER_WORKBENCH'
    scene.display.shading.light='STUDIO'
    scene.display.shading.studiolight_rotate_z=.4
    scene.display.shading.color_type='MATERIAL'
    scene.display.shading.show_shadows=True
    scene.display.shading.show_cavity=True
    scene.display.shading.cavity_type='BOTH'
    scene.display.shading.show_specular_highlight=False
    scene.display.shading.background_type='WORLD'
    scene.world.color=(.65,.65,.65)
    scene.view_settings.view_transform='Standard'
    scene.render.resolution_x=2048
    scene.render.resolution_y=1536
    scene.render.resolution_percentage=100
    scene.render.image_settings.file_format='PNG'
    direction=Vector((5,-8,5)).normalized()
    rotation=(-direction).to_track_quat('-Z','Y')
    right=rotation @ Vector((1,0,0))
    up=rotation @ Vector((0,1,0))
    for sheet,start in enumerate(range(0,len(paths),12),1):
        clear()
        for slot,path in enumerate(paths[start:start+12]):
            before=set(scene.objects)
            bpy.ops.import_scene.gltf(filepath=str(path))
            objects=[o for o in scene.objects if o not in before]
            meshes=[o for o in objects if o.type=='MESH']
            pts=[o.matrix_world @ v.co for o in meshes for v in o.data.vertices]
            centre=Vector(tuple((min(p[i] for p in pts)+max(p[i] for p in pts))/2 for i in range(3)))
            span_x=max(p.dot(right) for p in pts)-min(p.dot(right) for p in pts)
            span_y=max(p.dot(up) for p in pts)-min(p.dot(up) for p in pts)
            scale=min(2.45/span_x,2.28/span_y)
            col,row=slot%4,slot//4
            tile=right*((col-1.5)*3.15)+up*((1-row)*3.10+.15)
            # Se hornean las matrices importadas; los padres glTF no afectan al montaje.
            matrices={o:o.matrix_world.copy() for o in meshes}
            for o in meshes:
                o.parent=None
                world=matrices[o]
                for v in o.data.vertices: v.co=(world @ v.co-centre)*scale+tile
                o.matrix_world=Matrix.Identity(4)
            for o in objects:
                if o.type!='MESH': bpy.data.objects.remove(o,do_unlink=True)
            label(path.stem,right*((col-1.5)*3.15)+up*((1-row)*3.10-1.32),rotation)
        camera=bpy.data.cameras.new('Cámara hoja')
        camera.type='ORTHO'
        camera.ortho_scale=12.9
        obj=bpy.data.objects.new('Cámara hoja',camera)
        scene.collection.objects.link(obj)
        obj.location=direction*24
        obj.rotation_euler=rotation.to_euler()
        scene.camera=obj
        prefix='models_sheet_new' if names else 'models_sheet'
        scene.render.filepath=str(OUT/f'{prefix}_{sheet}.png')
        bpy.ops.render.render(write_still=True)
        print(f'HOJA {sheet}: {scene.render.filepath}',flush=True)


if __name__=='__main__': main()
