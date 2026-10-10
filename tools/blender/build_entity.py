"""El Olvidado: modelo propio reproducible y hoja frontal/lateral/posterior."""
import math
from pathlib import Path
import bpy
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[2]
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
M={}
for name,col in [('Cloth',(.045,.052,.047,1)),('Bone',(.12,.115,.09,1)),('Wire',(.026,.029,.025,1)),('Embroidery',(.23,.18,.085,1)),('Void',(.001,.001,.001,1))]:
 m=bpy.data.materials.new(name);m.diffuse_color=col;m.use_nodes=True
 p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=col;p.inputs['Roughness'].default_value=1
 M[name]=m

def mesh(name,verts,faces,mat,parent=None):
 d=bpy.data.meshes.new(name);d.from_pydata(verts,[],faces);d.update()
 o=bpy.data.objects.new(name,d);bpy.context.collection.objects.link(o);d.materials.append(M[mat]);o.parent=parent
 return o

def tube(name,points,radii,mat,parent=None,sides=5):
 verts=[]
 for i,p in enumerate(points):
  v=Vector(p); direction=Vector(points[min(i+1,len(points)-1)])-Vector(points[max(i-1,0)])
  q=direction.to_track_quat('Z','Y')
  for j in range(sides):
   verts.append(v+q@Vector((radii[i]*math.cos(j*math.tau/sides),radii[i]*math.sin(j*math.tau/sides),0)))
 faces=[]
 for i in range(len(points)-1):
  for j in range(sides): faces.append((i*sides+j,i*sides+(j+1)%sides,(i+1)*sides+(j+1)%sides,(i+1)*sides+j))
 faces.extend([tuple(reversed(range(sides))),tuple((len(points)-1)*sides+j for j in range(sides))])
 return mesh(name,verts,faces,mat,parent)

def joint(name,pos,parent=None):
 o=bpy.data.objects.new(name,None);bpy.context.collection.objects.link(o);o.location=pos;o.parent=parent;return o

def limb(name,pos,length,parent=None):
 o=joint(name,pos,parent)
 tube(name+'_Bone',[(0,0,0),(.018,0,-length*.45),(-.015,0,-length)],[.055,.035,.065],'Bone',o)
 for k in range(2):
  pts=[(.06*math.cos(i*.9+k*math.pi),.06*math.sin(i*.9+k*math.pi),-length*i/7) for i in range(8)]
  tube(name+'_Cable'+str(k),pts,[.014]*8,'Wire',o,4)
 return o
root=joint('Olvidado',(0,0,0))
torso=joint('Torso',(0,0,1.55),root)
tube('Ribcage',[(0,0,0),(0,.01,.2),(0,0,.58)],[.15,.19,.28],'Bone',torso,6)
# Chaquetilla facetada con abertura central y faldones rasgados.
for s in (-1,1):
 verts=[(s*.04,-.12,.57),(s*.29,-.08,.54),(s*.26,.08,.08),(s*.1,-.1,-.1),(s*.035,-.16,.19),(s*.21,.14,.52)]
 mesh('Jacket_'+str(s),verts,[(0,1,4),(1,2,4),(2,3,4),(1,5,2)],'Cloth',torso)
 for j in range(5):
  z=.43-j*.075
  tube('Button',[(s*.12,-.145,z),(s*.12,-.17,z)],[.017,.013],'Embroidery',torso,5)
 tube('EmbroideredEdge',[(s*.25,-.105,.5),(s*.22,-.12,.32),(s*.12,-.13,.12)],[.009]*3,'Embroidery',torso,4)
 mesh('Coattail',[(s*.1,.1,.12),(s*.23,.08,.12),(s*.18,.13,-.32),(s*.12,.15,-.17),(s*.09,.14,-.38)],[(0,1,2),(0,2,3),(0,3,4)],'Cloth',torso)
 arm=limb('ArmUpper_'+('L' if s<0 else 'R'),(s*.28,0,.5),.49,torso)
 lower=limb('ArmLower_'+('L' if s<0 else 'R'),(s*.035,0,-.49),.58,arm)
 for k in range(3):
  tube('Finger',[(s*(k-1)*.027,0,-.57),(s*(k-1)*.043,-.025,-.76)],[.018,.009],'Bone',lower,4)
 leg=limb('LegUpper_'+('L' if s<0 else 'R'),(s*.115,0,1.5),.71,root)
 low=limb('LegLower_'+('L' if s<0 else 'R'),(0,0,-.71),.68,leg)
 tube('Shoe',[(0,.025,-.68),(0,-.12,-.69)],[.07,.05],'Cloth',low,6)
tube('Neck',[(0,0,2.12),(0,0,2.29)],[.055,.04],'Wire',root)
head=joint('Head',(0,0,2.34),root)
# Anillo roto con cuenca hundida: no ojos, boca ni cara sólida.
n=12;verts=[]
for rx,rz,y in [(.15,.24,-.08),(.108,.185,-.115),(.055,.10,.055)]:
 for i in range(n):
  a=i*math.tau/n;verts.append((rx*math.cos(a),y,rz*math.sin(a)))
faces=[]
for k in range(2):
 for i in range(n):faces.append((k*n+i,k*n+(i+1)%n,(k+1)*n+(i+1)%n,(k+1)*n+i))
mesh('FaceRim',verts[:24],faces[:12],'Cloth',head)
mesh('ConcaveVoid',verts,faces[12:]+[tuple(range(24,36))],'Void',head)
# Ala incompleta del sombrero suspendida detrás de los hombros.
pts=[(.38*math.cos(i*.25),.18,.28+.38*math.sin(i*.25)) for i in range(20)]
tube('BrokenHatBrim',pts,[.035]*len(pts),'Cloth',torso,5)
tube('HatEmbroidery',[(p[0],p[1]-.025,p[2]) for p in pts],[.009]*len(pts),'Embroidery',torso,4)
objects=list(bpy.context.scene.objects)
triangles=sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in objects if o.type=='MESH')
assert triangles<=3000,triangles
bpy.ops.object.select_all(action='SELECT')
bpy.ops.export_scene.gltf(filepath=str(ROOT/'assets/models/olvidado.glb'),export_format='GLB',use_selection=True,export_yup=True)
print(f'ENTITY MODEL OK triangles={triangles} height=2.58m')
# Tres vistas del mismo modelo; materiales aclarados solo para inspección.
scene=bpy.context.scene;scene.render.engine='BLENDER_WORKBENCH';scene.display.shading.light='STUDIO';scene.display.shading.color_type='MATERIAL';scene.display.shading.show_cavity=True
scene.display.shading.background_type='WORLD';scene.world.color=(.3,.3,.3)
for m in M.values():
 c=m.diffuse_color;m.diffuse_color=tuple(min(1,v*2.5) for v in c[:3])+(1,)
root.location.x=-1.15
for x,angle in [(0,math.pi/2),(1.15,math.pi)]:
 copies={}
 for o in objects:
  c=o.copy();bpy.context.collection.objects.link(c);copies[o]=c
 for o,c in copies.items():c.parent=copies.get(o.parent)
 copies[root].location.x=x;copies[root].rotation_euler.z=angle
cam=bpy.data.cameras.new('Camera');cam.type='ORTHO';cam.ortho_scale=4.2
co=bpy.data.objects.new('Camera',cam);scene.collection.objects.link(co);co.location=(0,-9,1.4);co.rotation_euler=(Vector((0,0,1.3))-co.location).to_track_quat('-Z','Y').to_euler();scene.camera=co
scene.render.resolution_x=1400;scene.render.resolution_y=1000;scene.render.resolution_percentage=100
scene.render.filepath=str(ROOT/'builds/entity_sheet.png');bpy.ops.render.render(write_still=True)
