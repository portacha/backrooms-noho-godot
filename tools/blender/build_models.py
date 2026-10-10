"""Modelos NOHO: blender -b -P tools/blender/build_models.py -- [nombres]."""
import math
import sys
from pathlib import Path
import bpy
import bmesh
from mathutils import Vector, Matrix

ROOT = Path(__file__).resolve().parents[2]
PALETTE = dict(zip(
    'White_Laminate Office_Green Green_Fabric Beige_Plastic Beige_Dark Dark_Plastic Metal_Grey Metal_Dark Walnut Pine Pine_Dark Cardboard Tape Paper Orange_Mug Wax Wax_Shadow Wick Ceiling_Tile Counter_Yellow Counter_Top Rubber Water_Blue Bubble_Wrap Aluminium Sign_Off Flame Glow Screen'.split(),
    'D9DAD6 1F4634 2A5A45 C2B79E 9C927B 17191B 7F8587 3A3E40 3E2A1D A8845A 8A6A45 A07C55 CDBE9A E2DFD2 E8822A E6DDC2 C9BC98 2A2622 B9AF8E 8B7A46 5A5138 101112 8FB4C8 C9D2D4 A9AEB0 2B302C FFB44C EAF4FF 0A1020 Concrete Adobe Basalt Marigold Papel_Magenta Papel_Purple Papel_Cyan Sugar Sugar_Detail Black_Clay Rust Oak Oak_Dark Iron Stone Earth Ceramic'.split()))
PALETTE.update(dict(zip('Concrete Adobe Basalt Marigold Papel_Magenta Papel_Purple Papel_Cyan Sugar Sugar_Detail Black_Clay Rust Oak Oak_Dark Iron Stone Earth Ceramic'.split(), '777875 76503C 282D32 E88A16 D83E8C 734D9E 55B8C8 F2E9D5 D7B875 17191B 78402C 68462F 39271E 45494A 45413A 47362C 17191B 77716A'.split())))
SPECS = {
    'ceiling_fixture': ((1.28,.68,.10),500),
    'desk_office': ((1.5,.75,.74),400), 'chair_office': ((.6,.6,.95),900),
    'terminal_crt': ((.46,.42,.40),500), 'keyboard_retro': ((.42,.16,.04),300),
    'phone_desk': ((.22,.2,.1),400), 'mug': ((.085,.085,.095),250),
    'partition_panel': ((1.6,.05,1.25),150), 'filing_cabinet': ((.46,.6,1.32),350),
    'water_cooler': ((.34,.34,1.35),500), 'trash_bin': ((.28,.28,.32),200),
    'wall_clock': ((.32,.05,.32),300), 'table_conference': ((1.4,3.4,.74),300),
    'crate_painting': ((2.,.45,1.45),400), 'box_cardboard_closed': ((.6,.45,.42),80),
    'box_cardboard_open': ((.45,.4,.32),120), 'ladder_a_frame': ((.55,1.1,1.9),450),
    'bubble_wrap_roll': ((.4,.4,1.1),200), 'painting_frame': ((2.56,.07,1.96),150),
    'plaque': ((.44,.02,.56),60), 'door_exit': ((1.16,.12,2.18),300),
    'exit_sign': ((.5,.07,.18),60), 'reception_counter': ((3.,.9,1.05),300),
    'reception_small': ((1.7,.7,1.),250), 'candle_short': ((.06,.06,.07),90),
    'candle_mid': ((.068,.068,.13),90), 'candle_tall': ((.075,.075,.20),90),
    'ceiling_tile_fallen': ((.6,.6,.03),60), 'flashlight': ((.17,.047,.047),300),
    'letter_n': ((.5,.1,.62),120), 'chair_tipped': ((.95,.6,.6),900),
    'sign_wall': ((.62,.026,.2),120), 'sign_wall_right': ((.62,.026,.2),140),
    'sign_wall_left': ((.62,.026,.2),140), 'sign_hanging': ((.9,.05,.56),160),
    'frame_small': ((.5,.154,.774),200), 'reception_desk': ((3.4,1.,1.08),700),
    'reception_wing': ((1.25,.65,1.08),400), 'wall_slats': ((4.,.085,2.78),320),
    'logo_plate': ((1.5,.045,.46),160), 'door_portal': ((2.32,.106,2.34),80),
    'column_round': ((.4,.38,2.8),160), 'bench_waiting': ((1.6,.48,.48),160),
    'planter': ((.58,.69,1.24),240),
    'letter_o': ((.5,.1,.62),200), 'letter_h': ((.5,.1,.62),140),
    'column_capital': ((1.6,1.6,.5),220), 'column_base': ((1.5,1.5,.35),220),
    'ofrenda_arch': ((2.4,.5,2.6),2600), 'ofrenda_tier': ((2.,1.,.45),260),
    'papel_picado_string': ((2.,.03,.45),260), 'sugar_skull': ((.2,.24,.22),1400),
    'pan_de_muerto': ((.22,.22,.1),450), 'copal_censer': ((.2,.2,.26),800),
    'marigold_vase': ((.3,.3,.5),800), 'marigold_pile': ((.9,.9,.18),900),
    'photo_frame_empty': ((.18,.08,.25),100), 'adobe_rubble': ((1.3,.9,.6),400),
    'stone_stele': ((.9,.35,1.7),1200), 'wallpaper_peel': ((1.2,.06,1.4),100),
    'cabinet_rusty_stack': ((.5,.62,2.66),700), 'sugar_skull_giant': ((1.4,1.3,1.1),3000),
    'pipe_run': ((2.,.2,.3),360), 'pipe_elbow_valve': ((.5,.3,.6),260),
    'duct_grille': ((1.9,.08,1.3),220), 'ledge_walkway': ((2.,.6,.25),280),
    'marigold_raft': ((.7,.7,.07),340), 'wallet_open': ((.2,.1,.03),220),
    'clay_wall_panel': ((2.,.25,2.7),2600), 'clay_pot_black': ((.4,.4,.45),800),
    'clay_wall_broken': ((2.,.4,2.7),2600), 'drain_grate': ((.8,.8,.04),160),
    'oak_door_monumental': ((2.6,.5,3.8),3000), 'oak_door_open': ((2.6,1.4,3.8),3000),
    'neon_noho_sign': ((2.8,.12,.8),360), 'papel_picado_bridge': ((2.,2.,.06),340),
    'island_underside': ((2.,2.,1.6),1600), 'stalagmite': ((.7,.7,1.9),500),
    'emergency_beacon': ((.22,.22,.3),140), 'door_frame_lone': ((1.2,.16,2.2),260),
    'petal_cairn': ((.5,.5,.35),360), 'badge_noho': ((.086,.012,.13),280),
}
# Las medidas nominales excluyen asa, pies de partición y solapas abiertas.
MATS = {}
# Los constructores originales siguen disponibles como fallback explícito.
MESHY_SOURCED = {
    'sugar_skull','sugar_skull_giant','ofrenda_arch','clay_wall_panel','clay_wall_broken','copal_censer',
    'marigold_vase','pan_de_muerto','clay_pot_black','marigold_pile','stone_stele','island_underside','stalagmite',
}
MESHY_MATERIAL_LIMITS = {name: 8 for name in ('sugar_skull','sugar_skull_giant','ofrenda_arch','clay_wall_panel','clay_wall_broken','copal_censer')}
# Letreros y piezas de pared: cuelgan de pared o techo, su origen no va al suelo.
SIGNS = ('sign_wall','sign_wall_right','sign_wall_left','sign_hanging','frame_small','logo_plate',
         'wallpaper_peel','pipe_run','pipe_elbow_valve','duct_grille','clay_wall_panel','clay_wall_broken',
         'neon_noho_sign','door_frame_lone','badge_noho','letter_n','letter_o','letter_h')
CEILING_MODELS = ('ceiling_fixture','column_capital','papel_picado_string','sugar_skull_giant','island_underside')


def material(name):
    if name not in MATS:
        h = PALETTE[name]
        srgb = [int(h[i:i+2],16)/255 for i in (0,2,4)]
        linear = [v/12.92 if v <= .04045 else ((v+.055)/1.055)**2.4 for v in srgb]
        m = bpy.data.materials.get(name) or bpy.data.materials.new(name)
        m.use_nodes = True
        bsdf = m.node_tree.nodes.get('Principled BSDF')
        bsdf.inputs['Base Color'].default_value = (*linear,1)
        bsdf.inputs['Roughness'].default_value = 1
        m.diffuse_color = (*linear,1)
        MATS[name] = m
    return MATS[name]


def mesh(name, verts, faces, mat):
    data = bpy.data.meshes.new(name)
    data.from_pydata(verts, [], faces)
    data.update()
    uv=data.uv_layers.new(name='UVMap')
    for poly in data.polygons:
        axes=sorted(range(3),key=lambda i:abs(poly.normal[i]))[:2]
        for li in poly.loop_indices:
            p=data.vertices[data.loops[li].vertex_index].co
            uv.data[li].uv=(p[axes[0]],p[axes[1]])
    # Normales coherentes incluso en perfiles cóncavos.
    bm = bmesh.new()
    bm.from_mesh(data)
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    bm.to_mesh(data)
    bm.free()
    o = bpy.data.objects.new(name,data)
    bpy.context.collection.objects.link(o)
    o.data.materials.append(material(mat))
    for p in data.polygons:
        p.use_smooth = False
    return o


def bevel(o, width):
    bpy.context.view_layer.objects.active = o
    mod = o.modifiers.new('Chaflán','BEVEL')
    mod.width = width
    mod.segments = 1
    bpy.ops.object.modifier_apply(modifier=mod.name)
    return o


def prism(name, outline, bottom, top, mat, axis='Z'):
    n = len(outline)
    def point(p,h):
        return (p[0],p[1],h) if axis == 'Z' else (p[0],h,p[1])
    v = [point(p,h) for h in (bottom,top) for p in outline]
    f = [tuple(range(n-1,-1,-1)), tuple(range(n,2*n))]
    f += [(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
    return mesh(name,v,f,mat)


def rect(w,d,c=0):
    x,y = w/2,d/2
    if not c:
        return [(-x,-y),(x,-y),(x,y),(-x,y)]
    return [(-x+c,-y),(x-c,-y),(x,-y+c),(x,y-c),(x-c,y),(-x+c,y),(-x,y-c),(-x,-y+c)]


def box(name, loc, size, mat, chamfer=0):
    o = prism(name,rect(size[0],size[1]),-size[2]/2,size[2]/2,mat)
    for v in o.data.vertices:
        v.co += Vector(loc)
    return bevel(o,chamfer) if chamfer else o


def slab(name, loc, size, mat, clip=.02):
    o = prism(name,rect(size[0],size[1],clip),-size[2]/2,size[2]/2,mat)
    for v in o.data.vertices:
        v.co += Vector(loc)
    return o


def beam(name,a,b,width,depth,mat):
    a,b = Vector(a),Vector(b)
    o = box(name,(0,0,0),(width,depth,(b-a).length),mat)
    rot = (b-a).to_track_quat('Z','Y').to_matrix()
    for v in o.data.vertices:
        v.co = rot @ v.co + (a+b)/2
    return o


def lathe(name, rings, mat, n=8, loc=(0,0,0), axis='Z', caps=True):
    # Perfil radial: permite cuellos, rebordes e interiores abiertos.
    verts = []
    for r,z in rings:
        for i in range(n):
            t = 2*math.pi*i/n
            p = Vector((r*math.cos(t),r*math.sin(t),z))
            if axis == 'X': p = Vector((p.z,p.y,-p.x))
            if axis == 'Y': p = Vector((p.x,-p.z,p.y))
            verts.append(p+Vector(loc))
    faces = [(j*n+i,j*n+(i+1)%n,(j+1)*n+(i+1)%n,(j+1)*n+i)
             for j in range(len(rings)-1) for i in range(n)]
    if caps:
        faces += [tuple(range(n-1,-1,-1)),tuple(range((len(rings)-1)*n,len(rings)*n))]
    return mesh(name,verts,faces,mat)


def tube(name, points, radius, mat, sides=4):
    verts=[]
    for j,p in enumerate(points):
        tangent=Vector(points[min(j+1,len(points)-1)])-Vector(points[max(0,j-1)])
        rot=tangent.to_track_quat('Z','Y').to_matrix()
        for i in range(sides):
            a=2*math.pi*i/sides
            verts.append(Vector(p)+rot @ Vector((radius*math.cos(a),radius*math.sin(a),0)))
    faces=[(j*sides+i,j*sides+(i+1)%sides,(j+1)*sides+(i+1)%sides,(j+1)*sides+i)
           for j in range(len(points)-1) for i in range(sides)]
    faces += [tuple(range(sides-1,-1,-1)),tuple(range((len(points)-1)*sides,len(points)*sides))]
    return mesh(name,verts,faces,mat)


def frame(name,w,h,opening_w,opening_h,depth,mat,z=0):
    # Marco cerrado de perfil escalonado: el hueco no tiene caras.
    loops=[(w,h,0),(w,h,-depth*.65),(w-.015,h-.015,-depth),
           (opening_w,opening_h,-depth*.85),(opening_w,opening_h,0)]
    verts=[(x,y,zz+z) for ww,hh,y in loops for x,zz in rect(ww,hh)]
    faces=[]
    for j in range(len(loops)):
        k=(j+1)%len(loops)
        for i in range(4): faces.append((j*4+i,j*4+(i+1)%4,k*4+(i+1)%4,k*4+i))
    return mesh(name,verts,faces,mat)


def ceiling_fixture():
    # Origen en el plano del plafón; la carcasa cuelga hacia Z negativo.
    # Aro continuo con pestaña superior, canto biselado y asiento del difusor.
    loops = [(1.28,.68,0), (1.28,.68,-.055),
             (1.26,.66,-.085), (1.20,.60,-.085),
             (1.18,.58,-.055), (1.18,.58,0)]
    verts = [(x,y,z) for w,d,z in loops for x,y in rect(w,d)]
    faces = [(j*4+i,j*4+(i+1)%4,((j+1)%len(loops))*4+(i+1)%4,
              ((j+1)%len(loops))*4+i) for j in range(len(loops)) for i in range(4)]
    mesh('Marco plegado',verts,faces,'White_Laminate')
    # Retícula antideslumbrante delante del difusor: una espina y seis travesaños.
    box('Espina central',(0,0,-.082),(1.18,.014,.025),'Aluminium')
    for i in range(6):
        x = -.45+i*.18
        box('Lama reflector',(x,0,-.082),(.012,.58,.025),'Aluminium')
    for x in (-.625,.625):
        for y in (-.20,.20):
            slab('Pestaña cierre',(x,y,-.093),(.024,.055,.014),'Metal_Grey',.004)
            box('Ranura cierre',(x,y,-.100),(.012,.003,.001),'Metal_Dark')


def desk_office():
    slab('Tablero',(0,0,.715),(1.5,.75,.05),'White_Laminate',.025)
    slab('Canto',(0,0,.686),(1.5,.75,.014),'Office_Green',.025)
    box('Pedestal',(.49,.04,.34),(.43,.64,.66),'Office_Green',.01)
    for i in range(3):
        z=.14+i*.205
        slab('Cajón',(.49,-.291,z),(.405,.018,.188),'Beige_Plastic',.009)
        box('Tirador hundido',(.49,-.303,z+.041),(.13,.007,.028),'Beige_Dark')
        box('Labio',(.49,-.312,z+.03),(.12,.014,.009),'Metal_Grey')
    box('Faldón',(-.1,.30,.44),(.95,.025,.40),'Office_Green')
    for y in (-.27,.27):
        box('Pata',(-.63,y,.35),(.045,.045,.66),'Metal_Grey')
        slab('Pie',(-.63,y,.017),(.18,.13,.034),'Metal_Dark',.02)


def chair_office():
    lathe('Columna',[(.032,.11),(.032,.32),(.043,.32),(.043,.43)],'Metal_Dark')
    for i in range(5):
        a=2*math.pi*i/5+math.pi/2
        x,y=.255*math.cos(a),.255*math.sin(a)
        beam('Radio',(0,0,.17),(x,y,.075),.046,.042,'Dark_Plastic')
        lathe('Rueda',[(.035,-.022),(.035,.022)],'Dark_Plastic',8,(x,y,.035),'X')
        box('Horquilla',(x,y,.082),(.028,.048,.04),'Metal_Dark')
    slab('Asiento',(0,-.015,.455),(.47,.45,.09),'Green_Fabric',.065)
    slab('Bandeja',(0,-.01,.402),(.35,.31,.025),'Dark_Plastic',.04)
    tube('Soporte curvado',[(0,.13,.41),(0,.21,.50),(0,.245,.66),(0,.26,.83)],.025,'Metal_Dark')
    # Respaldo cóncavo, segmentos anchos y bordes recortados.
    outline=[(-.205,.59),(-.235,.63),(-.235,.89),(-.19,.95),(.19,.95),(.235,.89),(.235,.63),(.205,.59)]
    o=prism('Respaldo',outline,.205,.275,'Green_Fabric','Y')
    for v in o.data.vertices:
        v.co.y += .045*(1-(v.co.x/.235)**2)
    bevel(o,.014)


def terminal_crt():
    slab('Base',(0,.015,.019),(.28,.26,.038),'Beige_Dark',.025)
    box('Articulación',(0,.01,.068),(.12,.12,.065),'Beige_Plastic',.012)
    # Carcasa con trasera estrecha, bisel frontal y panza del tubo.
    loops=[(.46,.31,-.21,.24),(.46,.31,-.165,.24),(.32,.25,.21,.245)]
    verts=[(x,y,z+zc) for w,h,y,zc in loops for x,z in rect(w,h,.022)]
    faces=[]
    for j in range(2):
        for i in range(8): faces.append((j*8+i,j*8+(i+1)%8,(j+1)*8+(i+1)%8,(j+1)*8+i))
    faces += [tuple(range(16,24))]
    mesh('Carcasa',verts,faces,'Beige_Plastic')
    # Bisel con abertura real; no una placa que oculte el cristal.
    o=frame('Bisel',.418,.276,.31,.233,.018,'Beige_Dark',.245)
    for v in o.data.vertices: v.co.y -= .192
    screen=mesh('Cristal CRT',[(-.15,-.208,.1325),(.15,-.208,.1325),(.15,-.208,.3575),(-.15,-.208,.3575),(0,-.215,.245)],[(0,1,4),(1,2,4),(2,3,4),(3,0,4)],'Screen')
    uv=screen.data.uv_layers.active
    for p in screen.data.polygons:
        for li in p.loop_indices:
            v=screen.data.vertices[screen.data.loops[li].vertex_index].co
            uv.data[li].uv=((v.x+.15)/.30,(v.z-.1325)/.225)
    for side in (-1,1):
        for i in range(5):
            box('Ranura ventilación',(side*(.226-i*.01),-.125+i*.047,.265),(.003,.023,.067),'Beige_Dark')
    lathe('Piloto',[(.005,0),(.005,.003)],'Office_Green',6,(.175,-.209,.118),'Y')


def keyboard_retro():
    o=box('Carcasa teclado',(0,0,.018),(.42,.16,.036),'Beige_Plastic',.008)
    for v in o.data.vertices: v.co.z *= .5+(v.co.y+.08)/.16*.5
    for row in range(4):
        # Teclas agrupadas; cada separación es geometría, no textura.
        for col in range(5):
            box('Grupo teclas',(-.15+col*.075,-.045+row*.029,.017+row*.0055),(.068,.023,.01),'Beige_Dark')
    box('Espacio',(0,-.068,.012),(.19,.015,.008),'Beige_Dark')


def phone_desk():
    base=slab('Base teléfono',(0,0,.025),(.205,.185,.05),'Beige_Plastic',.028)
    for v in base.data.vertices: v.co.z *= .7+(v.co.y+.1)*1.5
    for i in range(3):
        for j in range(3): box('Botón',(-.033+j*.033,-.058+i*.026,.043+i*.004),(.022,.018,.007),'Dark_Plastic')
    for x in (-.073,.073):
        slab('Auricular',(x,.049,.065),(.059,.073,.046),'Beige_Plastic',.016)
    tube('Puente auricular',[(-.071,.049,.073),(-.042,.058,.085),(.042,.058,.085),(.071,.049,.073)],.014,'Beige_Plastic')
    points=[]
    for i in range(17):
        t=i/16
        points.append((-.099+.009*math.sin(t*8*math.pi),.037-.10*t,.05-.015*t+.008*math.cos(t*8*math.pi)))
    tube('Cable rizado',points,.0025,'Dark_Plastic',3)


def mug():
    lathe('Taza',[(.034,0),(.041,.008),(.0425,.091),(.039,.095),(.0345,.091),(.033,.015)],'Orange_Mug',12)
    pts=[(.037,0,.079),(.059,0,.083),(.070,0,.067),(.070,0,.033),(.058,0,.019),(.037,0,.023)]
    tube('Asa',pts,.007,'Orange_Mug',6)


def partition_panel():
    box('Panel',(0,0,.65),(1.54,.033,1.16),'Green_Fabric')
    for x in (-.785,.785): box('Montante',(x,0,.65),(.03,.05,1.2),'Metal_Grey')
    for z in (.065,1.235): box('Travesaño',(0,0,z),(1.6,.05,.03),'Metal_Grey')
    for x in (-.57,.57): slab('Pie',(x,0,.016),(.16,.3,.032),'Metal_Grey',.016)


def filing_cabinet():
    box('Chasis',(0,.014,.66),(.46,.572,1.32),'Metal_Grey',.008)
    for i in range(4):
        z=.185+i*.315
        slab('Frente cajón',(0,-.295,z),(.412,.01,.28),'Metal_Grey',.009)
        box('Etiqueta',(0,-.304,z+.065),(.095,.008,.032),'Metal_Dark')
        for x in (-.062,.062): box('Soporte asa',(x,-.317,z),(.016,.035,.018),'Metal_Dark')
        box('Asa',(0,-.336,z),(.14,.013,.018),'Metal_Dark')


def water_cooler():
    slab('Base',(0,0,.035),(.34,.34,.07),'Beige_Dark',.025)
    # Bahía abierta construida con paredes: grifos y bandeja dentro del hueco.
    slab('Cuerpo inferior',(0,0,.30),(.33,.33,.50),'White_Laminate',.025)
    box('Trasera bahía',(0,.105,.69),(.31,.10,.29),'White_Laminate')
    for x in (-.144,.144): box('Lateral bahía',(x,-.04,.69),(.04,.25,.29),'White_Laminate')
    slab('Techo',(0,0,.85),(.33,.33,.06),'White_Laminate',.025)
    for x in (-.067,.067):
        tube('Grifo',[(x,.052,.745),(x,-.083,.745),(x,-.083,.712)],.013,'Beige_Dark')
        box('Palanca',(x,-.04,.777),(.017,.043,.015),'Dark_Plastic')
    slab('Bandeja',(0,-.08,.562),(.24,.16,.025),'Beige_Dark',.018)
    for i in range(4): box('Rejilla',(-.075+i*.05,-.086,.58),(.018,.115,.009),'Metal_Grey')
    lathe('Garrafón',[(.055,.88),(.055,.94),(.118,.98),(.145,1.035),(.145,1.29),(.119,1.35)],'Water_Blue',12)
    for z in (1.07,1.25): lathe('Nervio botella',[(.145,z),(.15,z+.015),(.145,z+.03)],'Water_Blue',12,caps=False)


def trash_bin():
    lathe('Papelera',[(.108,0),(.14,.305),(.138,.32),(.128,.32),(.127,.305),(.098,.018)],'Metal_Dark',12)


def wall_clock():
    lathe('Reloj aro',[(.145,0),(.16,.009),(.16,.043),(.147,.05),(.14,.047),(.14,.032)],'Dark_Plastic',16,axis='Y')
    mesh('Esfera',[(.14*math.cos(i*math.pi/8),-.034,.14*math.sin(i*math.pi/8)) for i in range(16)],[tuple(range(16))],'Paper')
    for i in range(12):
        a=2*math.pi*i/12
        mesh('Índice',[(r*math.sin(a)+offset*math.cos(a),-.036,r*math.cos(a)-offset*math.sin(a)) for r,offset in ((.117,-.003),(.132,-.003),(.132,.003),(.117,.003))],[(0,1,2,3)],'Dark_Plastic')
    for angle,length,width in ((2*math.pi*47/60,.112,.005),(2*math.pi*(11+47/60)/12,.073,.009)):
        beam('Aguja',(0,-.04,0),(length*math.sin(angle),-.04,length*math.cos(angle)),width,.004,'Dark_Plastic')
    lathe('Eje',[(.009,.04),(.009,.045)],'Dark_Plastic',6,axis='Y')


def table_conference():
    outline=[(-.45,-1.7),(.45,-1.7),(.64,-1.45),(.7,-.7),(.7,.7),(.64,1.45),(.45,1.7),(-.45,1.7),(-.64,1.45),(-.7,.7),(-.7,-.7),(-.64,-1.45)]
    bevel(prism('Tablero barco',outline,.675,.74,'Walnut'),.012)
    for y in (-.95,.95):
        slab('Pata panel',(0,y,.34),(.75,.10,.68),'Walnut',.025)
        slab('Zócalo',(0,y,.025),(.90,.24,.05),'Metal_Dark',.02)
    box('Travesaño',(0,0,.24),(.10,1.9,.12),'Walnut')


def crate_painting():
    for side in (-1,1):
        y=side*.193
        for i in range(5): box('Tabla',(-.8+i*.4,y,.77),(.392,.035,1.30),'Pine')
        for x in (-.96,.96): box('Batiente',(x,side*.211,.77),(.08,.028,1.35),'Pine_Dark')
        for z in (.135,1.405): box('Batiente',(0,side*.211,z),(2.,.028,.09),'Pine_Dark')
        beam('Diagonal',(-.9,side*.211,.22),(.9,side*.211,1.33),.062,.028,'Pine_Dark')
    for x in (-.98,.98): box('Costado',(x,0,.77),(.04,.38,1.30),'Pine')
    for z in (.145,1.395): box('Cierre',(0,0,z),(1.94,.38,.04),'Pine')
    for x in (-.75,.75): box('Patín',(x,0,.06),(.16,.45,.12),'Pine_Dark')
    for x in (-.95,.95):
        for z in (.20,1.32): box('Refuerzo esquina',(x,0,z),(.10,.40,.10),'Pine_Dark')


def box_cardboard_closed():
    o=box('Caja',(0,0,.21),(.6,.45,.42),'Cardboard',.005)
    for v in o.data.vertices: v.co.x += .008*(v.co.z/.42-.5)*(v.co.y/.45)
    box('Cinta superior',(0,0,.422),(.058,.447,.002),'Tape')
    for y in (-.226,.226): box('Cinta lateral',(0,y,.31),(.058,.002,.22),'Tape')


def box_cardboard_open():
    # Pared fina, interior vacío y cuatro solapas dobladas de modo distinto.
    box('Fondo',(0,0,.005),(.45,.4,.01),'Cardboard')
    for x in (-.22,.22): box('Pared',(x,0,.16),(.01,.4,.32),'Cardboard')
    for y in (-.195,.195): box('Pared',(0,y,.16),(.43,.01,.32),'Cardboard')
    for axis,side,angle in [('X',-1,-.40),('X',1,.28),('Y',-1,-.65),('Y',1,.8)]:
        if axis=='X':
            o=box('Solapa',(0,0,.09),(.01,.39,.18),'Cardboard')
            rot=Matrix.Rotation(angle,3,'Y'); hinge=Vector((side*.225,0,.32))
        else:
            o=box('Solapa',(0,0,.08),(.43,.01,.16),'Cardboard')
            rot=Matrix.Rotation(-angle,3,'X'); hinge=Vector((0,side*.20,.32))
        for v in o.data.vertices: v.co=rot @ v.co+hinge


def ladder_a_frame():
    for side in (-1,1):
        for x in (-.24,.24):
            beam('Larguero',(x,side*.52,.04),(x,side*.07,1.85),.045,.055,'Aluminium')
            box('Zapato',(x,side*.52,.035),(.068,.06,.07),'Rubber')
    for i in range(6):
        z=.24+i*.27; y=-.52+(z-.04)/1.81*.45
        slab('Peldaño',(0,y,z),(.49,.14,.036),'Aluminium',.009)
    for z in (.40,1.05):
        y=.52-(z-.04)/1.81*.45
        box('Travesaño posterior',(0,y,z),(.48,.025,.038),'Aluminium')
    for x in (-.245,.245):
        beam('Compás',(x,-.28,.96),(x,0,.92),.014,.026,'Metal_Grey')
        beam('Compás',(x,0,.92),(x,.28,.96),.014,.026,'Metal_Grey')
    slab('Tapa',(0,0,1.872),(.55,.24,.056),'Aluminium',.018)


def bubble_wrap_roll():
    lathe('Rollo',[(.19,0),(.2,.025),(.2,1.08),(.19,1.1),(.046,1.1),(.045,0)],'Bubble_Wrap',12)
    # Espiral en relieve en el extremo superior, sin textura.
    pts=[]
    for i in range(7):
        a=i/6*math.pi*3.7; r=.048+i/6*.13
        pts.append((r*math.cos(a),r*math.sin(a),1.104))
    tube('Espiral',pts,.004,'Bubble_Wrap',3)
    o=mesh('Solapa',[(-.14,-.14,.04),(-.14,-.14,1.06),(-.20,-.17,1.03),(-.20,-.17,.08),(-.24,-.13,.10),(-.24,-.13,.93)],[(0,1,2,3),(3,2,5,4)],'Bubble_Wrap')
    bpy.context.view_layer.objects.active=o
    mod=o.modifiers.new('Espesor envoltura','SOLIDIFY'); mod.thickness=.003
    bpy.ops.object.modifier_apply(modifier=mod.name)


def painting_frame(): frame('Marco galería',2.56,1.96,2.4,1.8,.07,'Dark_Plastic')


def plaque():
    frame('Marco aviso',.44,.56,.404,.524,.02,'Dark_Plastic')
    prism('Hoja',rect(.404,.524),-.013,-.012,'Paper','Y')


def door_exit():
    for x in (-.54,.54): box('Jamba',(x,-.06,1.09),(.08,.12,2.18),'Metal_Dark')
    box('Dintel',(0,-.06,2.14),(1.08,.12,.08),'Metal_Dark')
    # Hoja formada alrededor de dos huecos con paneles retrasados.
    for x in (-.453,.453): box('Hoja montante',(x,-.047,1.07),(.094,.056,2.10),'Office_Green')
    for z,h in ((.08,.12),(.99,.11),(2.06,.12)):
        box('Hoja travesaño',(0,-.047,z),(.81,.056,h),'Office_Green')
    for z,h in ((.545,.79),(1.55,.96)):
        box('Panel hundido',(0,-.028,z),(.812,.018,h),'Office_Green')
    box('Placa cerradura',(.38,-.08,1.05),(.048,.012,.14),'Metal_Grey',.004)
    beam('Manilla',(.38,-.089,1.07),(.38,-.11,1.07),.017,.018,'Metal_Grey')
    beam('Palanca',(.38,-.11,1.07),(.27,-.11,1.07),.017,.018,'Metal_Grey')
    for z in (.31,1.08,1.86): lathe('Bisagra',[(.012,z-.038),(.012,z+.038)],'Metal_Grey',6,(-.506,-.07,0))


def exit_sign():
    box('Carcasa',(0,-.035,0),(.5,.07,.15),'Beige_Plastic',.003)
    mesh('Cara apagada',[(-.237,-.071,-.06),(.237,-.071,-.06),(.237,-.071,.06),(-.237,-.071,.06)],[(0,1,2,3)],'Sign_Off')
    box('Soporte',(0,-.015,.0975),(.13,.027,.045),'Metal_Grey')


def reception(w=3.,d=.9,h=1.05):
    slab('Encimera pública',(0,-d/2+.095,h-.023),(w,.19,.046),'Counter_Top',.025)
    # Listones con surcos reales (separados y oscuros al fondo).
    box('Frente',(0,-d/2+.043,h*.52),(w-.04,.055,h-.14),'Counter_Yellow')
    count=9 if w>2 else 6
    for i in range(count):
        x=-w/2+.025+(i+.5)*(w-.05)/count
        box('Listón',(x,-d/2+.009,h*.52),((w-.05)/count-.012,.018,h-.18),'Counter_Yellow')
    box('Zócalo',(0,-d/2+.05,.046),(w-.10,.10,.092),'Counter_Top')
    slab('Mesa trabajo',(0,.10,h-.24),(w-.10,d-.25,.044),'Counter_Top',.02)
    for x in (-w/2+.04,w/2-.04): box('Lateral',(x,.10,(h-.27)/2),(.06,d-.20,h-.27),'Counter_Yellow')
    box('Divisor',(w*.12,.12,(h-.27)/2),(.045,d-.23,h-.27),'Counter_Yellow')
    box('Estante',(w*.30,.11,.30),(w*.33,d-.24,.035),'Counter_Top')


def reception_modern(w,d=1.,h=1.08):
    # Mostrador de recepción: frente alto de listones de nogal sobre cuerpo blanco, repisa pública
    # y mesa de trabajo detrás. El frente mira a -Y.
    f=-d/2
    box('Zócalo',(0,f+.09,.05),(w-.08,.1,.1),'Dark_Plastic')
    box('Frente',(0,f+.05,.1+(h-.15)/2),(w,.06,h-.15),'White_Laminate')
    count=round(w/.17)
    for i in range(count):
        x=-w/2+(i+.5)*w/count
        box('Listón',(x,f+.01,.16+(h-.27)/2),(w/count-.06,.02,h-.27),'Walnut')
    slab('Repisa',(0,f+.14,h-.025),(w,.28,.05),'White_Laminate',.02)
    slab('Mesa trabajo',(0,f+.26+(d-.26)/2,.72),(w-.06,d-.26,.04),'White_Laminate',.02)
    for x in (-w/2+.025,w/2-.025): box('Lateral',(x,.04,.35),(.05,d-.08,.70),'White_Laminate')
    if w>2:
        box('Cajonera',(w/2-.36,f+.6,.38),(.46,.56,.6),'Walnut',.008)
        for i in range(3):
            slab('Cajón',(w/2-.36,f+.889,.19+i*.19),(.42,.018,.17),'White_Laminate',.008)
        box('Bandeja',(-w/2+.5,f+.5,.75),(.34,.26,.02),'Metal_Dark',.004)


def frame_small():
    # Cuadro pequeño de pasillo con su aplique de latón. El lienzo lo pone el juego.
    frame('Marco',.5,.62,.42,.54,.03,'Walnut')
    prism('Paspartú',rect(.42,.54),-.012,-.010,'Paper','Y')
    box('Roseta',(0,-.008,.385),(.09,.016,.05),'Counter_Yellow',.004)
    tube('Brazo',[(0,-.016,.385),(0,-.075,.425),(0,-.13,.44)],.008,'Counter_Yellow')
    lathe('Pantalla',[(.024,-.15),(.024,.15)],'Counter_Yellow',6,(0,-.13,.44),'X')


def wall_slats():
    # Muro de acento: listones verticales de nogal sobre fondo oscuro.
    box('Fondo',(0,.02,1.39),(4.,.04,2.78),'Dark_Plastic')
    for i in range(20):
        box('Listón',(-1.9+i*.2,-.02,1.39),(.11,.05,2.78),'Walnut')


def logo_plate():
    # Placa separada del muro por cuatro casquillos; el rótulo lo escribe el juego.
    box('Placa',(0,-.03,0),(1.5,.03,.46),'White_Laminate',.006)
    for x in (-.68,.68):
        for z in (-.17,.17):
            lathe('Casquillo',[(.014,0),(.014,.015)],'Aluminium',6,(x,0,z),'Y')


def door_portal():
    # Portada de la sala de juntas: jambas y dintel de nogal con filete de latón.
    for x in (-1.08,1.08): box('Jamba',(x,0,1.17),(.16,.1,2.34),'Walnut')
    box('Dintel',(0,0,2.22),(2.,.1,.24),'Walnut')
    box('Filete',(0,-.053,2.11),(2.,.006,.02),'Counter_Yellow')


def column_round():
    lathe('Fuste',[(.2,0),(.2,.08),(.16,.1),(.16,2.68),(.2,2.7),(.2,2.8)],'White_Laminate',10)


def bench_waiting():
    slab('Asiento',(0,0,.40),(1.6,.48,.06),'Walnut',.03)
    slab('Cojín',(0,0,.455),(1.5,.42,.05),'Green_Fabric',.04)
    for x in (-.62,.62): box('Pata',(x,0,.185),(.05,.4,.37),'Metal_Dark')
    box('Travesaño',(0,0,.1),(1.24,.03,.03),'Metal_Dark')


def planter():
    # Jardinera con lengua de suegra: hojas planas que se afinan hacia la punta.
    box('Maceta',(0,0,.25),(.38,.38,.5),'White_Laminate',.02)
    box('Tierra',(0,0,.505),(.33,.33,.02),'Walnut')
    for i in range(7):
        a=2*math.pi*i/7+.3
        length=.52+.09*((i*5)%4)
        base=Vector((.07*math.cos(a),.07*math.sin(a),.51))
        tip=base+Vector((.16*math.cos(a)*(1+i%2),.16*math.sin(a)*(1+i%2),length))
        o=lathe('Hoja',[(.022,0),(.036,length*.45),(.004,length)],'Office_Green' if i%2 else 'Green_Fabric',4)
        rot=(tip-base).to_track_quat('Z','Y').to_matrix() @ Matrix.Rotation(a,3,'Z')
        for v in o.data.vertices:
            v.co=rot @ Vector((v.co.x,v.co.y*.3,v.co.z))+base


def candle(height,dia,variant):
    n=8; radius=dia/2; top=height-.023
    rings=[]
    for level in range(3):
        for i in range(n):
            a=2*math.pi*i/n
            r=radius*(.82 if level==0 else .88 if level==1 else .80)*(1+.05*math.sin(i*2.1+variant))
            z=(.004,top-.008,top)[level]
            if level==2: z-=.006*(1+math.sin(a+variant))/2
            rings.append((r*math.cos(a),r*math.sin(a),z))
    faces=[tuple(range(7,-1,-1))]
    faces += [(j*n+i,j*n+(i+1)%n,(j+1)*n+(i+1)%n,(j+1)*n+i) for j in range(2) for i in range(n)]
    rings.append((0,0,top-.010))
    faces += [(16+i,16+(i+1)%n,24) for i in range(n)]
    mesh('Cera derretida',rings,faces,'Wax')
    mesh('Charco',[(radius*math.cos(i*math.pi/4),radius*math.sin(i*math.pi/4),0) for i in range(8)],[tuple(range(8))],'Wax_Shadow')
    for i in range(2):
        index=6+i
        a=index*math.pi/4
        variation=1+.05*math.sin(index*2.1+variant)
        ztop=top-.010
        ztip=max(.008,ztop-(.012+.009*variant+.004*i))
        def wall_radius(z):
            t=max(0,min(1,(z-.004)/(top-.012)))
            return radius*(.82+.06*t)*variation
        def point(z,extra=0,tangent=0):
            r=wall_radius(z)+extra
            return (r*math.cos(a)-tangent*math.sin(a),r*math.sin(a)+tangent*math.cos(a),z)
        mesh('Gota',[point(ztop,-.001,-.003),point(ztop,-.001,.003),
                     point(ztip,-.0005),point((ztop+ztip)/2,.003)],
                     [(0,1,3),(1,2,3),(2,0,3),(0,2,1)],'Wax')
    beam('Mecha',(0,0,top-.003),(0,0,top+.005),.002,.002,'Wick')
    # Seis lados, base y punta: lágrima inclinada.
    verts=[(.006*math.cos(i*math.pi/3),.006*math.sin(i*math.pi/3),top+.011) for i in range(6)]
    verts += [(0,0,top+.003),(.003*math.sin(variant),0,height)]
    mesh('Llama',verts,[(i,(i+1)%6,7) for i in range(6)]+[(i,6,(i+1)%6) for i in range(6)],'Flame')


def ceiling_tile_fallen():
    outline=[(-.3,-.3),(.3,-.3),(.3,.19),(.24,.18),(.20,.24),(.13,.30),(-.3,.3)]
    o=prism('Loseta rota',outline,.002,.025,'Ceiling_Tile')
    for v in o.data.vertices: v.co.z += .005*(v.co.x/.3)*(v.co.y/.3)
    # Grieta: surco geométrico oscuro, usa la misma paleta.
    mesh('Grieta',[(-.13,-.30,.026),(-.124,-.30,.026),(-.03,-.04,.027),(-.036,-.04,.027),(.14,.07,.028),(.145,.064,.028)],[(0,1,2,3),(3,2,5,4)],'Beige_Dark')


def flashlight():
    z=.0235
    lathe('Cuerpo',[(.013,-.08),(.014,-.075),(.014,.019),(.019,.027),(.0235,.063),(.0235,.077)],'Dark_Plastic',8,(0,0,z),'X')
    for x in (-.064,-.037,-.01):
        lathe('Anillo agarre',[(.014,x),(.0155,x+.002),(.014,x+.004)],'Metal_Grey',6,(0,0,z),'X',False)
    lathe('Aro frontal',[(.0235,.073),(.0235,.082),(.018,.079)],'Metal_Grey',8,(0,0,z),'X',False)
    mesh('Lente',[(.080,.018*math.cos(i*math.pi/4),z+.018*math.sin(i*math.pi/4)) for i in range(8)],[tuple(range(8))],'Glow')
    box('Interruptor',(-.016,0,z+.014),(.026,.013,.006),'Metal_Grey')
    lathe('Tapón',[(.014,-.078),(.014,-.083)],'Metal_Grey',8,(0,0,z),'X')
    pts=[(-.081,.005*math.cos(i*math.pi/3),z+.005*math.sin(i*math.pi/3)) for i in range(7)]
    tube('Anilla',pts,.0015,'Metal_Grey',3)


def letter_n():
    # Contorno continuo, visto desde -Y: diagonal de arriba izquierda a abajo derecha.
    outline=[(-.25,-.31),(-.25,.31),(-.14,.31),(.14,-.10),(.14,.31),(.25,.31),(.25,-.31),(.14,-.31),(-.14,.10),(-.14,-.31)]
    bevel(prism('N sólida',outline,-.05,.05,'Glow','Y'),.006)


# Modelos añadidos para las ofrendas, conductos y el umbral abisal.
def letter_o():
    # Tubo facetado en cuatro tramos; el hueco central queda completamente abierto.
    for x in (-.19,.19): box('Costado neón',(x,0,0),(.12,.1,.62),'Glow',.018)
    for z in (-.25,.25): box('Puente neón',(0,0,z),(.26,.1,.12),'Glow',.018)


def letter_h():
    for x in (-.19,.19): box('Montante',(x,0,.31),(.12,.1,.62),'Glow',.018)
    box('Travesaño',(0,0,.31),(.5,.1,.12),'Glow',.018)


def new_model(name):
    # Cada pieza es una pequeña composición; los volúmenes se biselan y se acompañan de detalles.
    if name=='column_capital':
        box('Placa de carga',(0,0,.42),(1.6,1.6,.22),'Concrete',.04)
        box('Cuello',(0,0,.25),(1.34,1.34,.28),'Concrete',.025)
        for i in range(7): box('Huella encofrado',(-.55+i*.18,-.796,.31),(.09,.008,.16),'Stone')
    elif name=='column_base':
        box('Zócalo inferior',(0,0,.07),(1.5,1.5,.14),'Concrete',.055)
        box('Escalón',(0,0,.17),(1.34,1.34,.10),'Stone',.035)
        box('Cuello',(0,0,.265),(1.12,1.12,.09),'Concrete',.025)
        for x,z in ((-.49,.13),(.43,.16),(-.12,.08)):
            prism('Adobe expuesto',[(x-.09,-.753),(x-.04,-.758),(x+.08,-.752),(x+.02,-.748)],z,z+.045,'Adobe','Y')
    elif name=='ofrenda_arch':
        # Arco de carrizo con hojas/flores repetidas en la curva.
        for x in (-.9,.9): beam('Poste carrizo',(x,0,0),(x,0,2.05),.09,.09,'Earth')
        for i in range(13):
            a=math.pi-i*math.pi/12
            x=.9*math.cos(a); z=2.05+.48*math.sin(a)
            beam('Carrizo',(x-.09,0,z-.08),(x+.09,0,z+.08),.07,.07,'Earth')
            for side in (-1,1):
                lathe('Flor',[(.015,0),(.07,.025),(.025,.05)],'Marigold',6,(x,side*.12,z),'Y')
    elif name=='ofrenda_tier':
        box('Basamento',(0,0,.14),(2.,1.,.28),'Adobe',.04)
        slab('Mantel',(0,-.015,.31),(2.02,1.02,.035),'Papel_Magenta',.01)
        for x in [i*.15-.9 for i in range(13)]: beam('Fleco',(x,-.52,.29),(x,-.52,.20),.018,.02,'Papel_Cyan')
    elif name=='papel_picado_string':
        tube('Cordel',[(-1,0,.45),(-.5,0,.38),(0,0,.36),(.5,0,.38),(1,0,.45)],.009,'Earth',3)
        for i in range(5):
            x=-.8+i*.4; col=('Papel_Magenta','Papel_Purple','Papel_Cyan')[i%3]
            top=.37-abs(x)*.08
            outline=[(x-.16,top),(x-.08,top-.035),(x,top),(x+.08,top-.035),(x+.16,top),(x+.14,.06),(x,.03),(x-.14,.06)]
            prism('Banderín festoneado',outline,-.015,.015,col,'Y')
            if i in (0,2,4):
                prism('Calado calavera',[(x-.03,top-.18),(x-.04,top-.15),(x-.02,top-.13),(x+.02,top-.13),(x+.04,top-.15),(x+.03,top-.18),(x+.02,top-.20),(x-.02,top-.20)],-.019,-.016,'Earth','Y')
    elif name in ('sugar_skull','sugar_skull_giant'):
        sx,sy,sz=SPECS[name][0]
        # Cráneo con mandíbula contigua, cavidades empotradas y ornamento facial.
        lathe('Cráneo',[(sx*.30,0),(sx*.44,sz*.13),(sx*.48,sz*.55),(sx*.42,sz*.77),(sx*.27,sz*.91),(sx*.12,sz)],'Sugar',10)
        jaw=[(-sx*.28,sz*.27),(-sx*.34,sz*.18),(-sx*.27,sz*.06),(-sx*.17,sz*.025),(sx*.17,sz*.025),(sx*.27,sz*.06),(sx*.34,sz*.18),(sx*.28,sz*.27)]
        prism('Mandíbula integrada',jaw,-sy*.48,sy*.48,'Sugar','Y')
        eye_mat='Glow' if name.endswith('giant') else 'Basalt'
        for x in (-sx*.17,sx*.17):
            lathe('Cuenca hundida',[(sx*.075,0),(sx*.09,.008)],eye_mat,8,(x,-sy*.465,sz*.58),'Y')
        for x in (-sx*.18,-sx*.09,0,sx*.09,sx*.18):
            box('Diente integrado',(x,-sy*.49,sz*.115),(sx*.055,.018,sz*.075),'Sugar_Detail',sx*.012)
        lathe('Centro flor',[(sx*.045,0),(sx*.052,.012)],'Marigold',8,(0,-sy*.49,sz*.84),'Y')
        for i in range(4):
            a=i*math.tau/6
            lathe('Pétalo frontal',[(sx*.018,0),(sx*.04,.012)],'Marigold',5,(sx*.075*math.cos(a),-sy*.49,sz*.84+sx*.075*math.sin(a)),'Y')
        for sign in (-1,1):
            for k in range(3):
                x=sign*(sx*.25+k*sx*.025)
                beam('Filigrana pómulo',(x,-sy*.48,sz*.40-k*sz*.08),(x-sign*sx*.045,-sy*.48,sz*.36-k*sz*.08),sx*.018,.012,'Glow' if name.endswith('giant') else 'Marigold')
    elif name=='pan_de_muerto':
        lathe('Pan',[(.075,0),(.105,.025),(.10,.075),(.055,.095)],'Sugar',8)
        for a in (0,math.pi/2):
            beam('Huesito cruz',(-.09*math.cos(a),-.09*math.sin(a),.073),(.09*math.cos(a),.09*math.sin(a),.073),.026,.026,'Sugar_Detail')
        lathe('Bolita central',[(.018,0),(.025,.018)],'Sugar_Detail',6,(0,0,.085))
    elif name=='copal_censer':
        lathe('Copa',[(.055,0),(.10,.05),(.09,.15),(.05,.18)],'Ceramic',8)
        lathe('Pie',[(.035,0),(.06,.06)],'Black_Clay',8,(0,0,.0))
        for i in range(5): lathe('Brasa',[(.012,0),(.02,.015)],'Flame',5,((i-2)*.025,0,.20))
        for i in range(3): beam('Asa',(.08,0,.09),(.12,0,.13+i*.01),.012,.012,'Ceramic')
    elif name in ('marigold_vase','clay_pot_black'):
        black=name=='clay_pot_black'; lathe('Vasija',[(.10,0),(.16,.08),(.19,.24),(.14,.35),(.08,.39),(.075,.45)],'Black_Clay' if black else 'Ceramic',8)
        if black:
            for i in range(6):
                a=i*math.tau/6; lathe('Relieve floral',[(.018,0),(.04,.01)],'Stone',5,(.13*math.cos(a),.13*math.sin(a),.22))
        else:
            for i in range(7):
                a=i*math.tau/7; beam('Tallo',(.02*math.cos(a),.02*math.sin(a),.42),(.12*math.cos(a),.12*math.sin(a),.5),.012,.012,'Earth')
                lathe('Flor',[(.015,0),(.045,.025)],'Marigold',6,(.12*math.cos(a),.12*math.sin(a),.47))
    elif name=='marigold_pile':
        for i in range(25):
            a=i*2.4; r=.08+(i%6)*.065; x=r*math.cos(a); y=r*math.sin(a)
            lathe('Flor',[(.018,0),(.055,.025),(.02,.04)],'Marigold',5,(x,y,.02+(i%3)*.035))
    elif name=='photo_frame_empty':
        frame('Marco vacío',.18,.25,.12,.19,.035,'Oak')
        box('Pie',(0,.015,.015),(.20,.08,.03),'Oak_Dark')
    elif name=='adobe_rubble':
        for i in range(8):
            x=((i*37)%11)/11*1.05-.525; y=((i*17)%7)/7*.68-.34; z=.06+(i%3)*.15
            box('Adobe caído',(x,y,z),(.30,.24,.14),'Adobe' if i%3 else 'Concrete',.025)
    elif name=='stone_stele':
        box('Losa volcánica',(0,0,.85),(.9,.35,1.7),'Basalt',.035)
        for z in (.34,.66,1.0,1.32):
            beam('Greca escalonada',(-.27,-.184,z),(-.08,-.184,z),.035,.018,'Stone')
            beam('Greca escalonada',(-.27,-.184,z),(-.27,-.184,z+.14),.035,.018,'Stone')
            beam('Greca escalonada',(.08,-.184,z),(.27,-.184,z),.035,.018,'Stone')
            beam('Greca escalonada',(.27,-.184,z),(.27,-.184,z+.14),.035,.018,'Stone')
    elif name=='wallpaper_peel':
        prism('Papel desprendido',[(-.6,1.4),(-.58,.1),(-.4,.18),(-.22,0),(.05,.16),(.18,.02),(.42,.24),(.6,.08),(.6,1.4)],-.03,.03,'Paper','Y')
        for x in (-.4,0,.4): beam('Borde rasgado',(x,.02,.2),(x+.08,.02,.02),.018,.018,'Beige_Dark')
    elif name=='cabinet_rusty_stack':
        for z in (.67,1.99):
            box('Archivero',(0,0,z),(.5,.62,1.28),'Rust',.025)
            for i in range(3):
                zz=z-.43+i*.38; slab('Cajón',(0,-.32,zz),(.45,.025,.32),'Metal_Dark',.01)
                box('Asa',(0,-.345,zz),(.10,.018,.025),'Iron',.006)
        for z in (.55,1.85): slab('Cajón abierto',(0,-.39,z),(.42,.24,.035),'Rust',.01)
        for x in (-.14,0,.14): lathe('Veladora',[(.025,0),(.025,.13)],'Sugar',6,(x,-.42,2.60))
    elif name=='pipe_run':
        beam('Tubo',(-1,0,0),(1,0,0),.10,.10,'Iron')
        for x in (-.8,-.25,.3,.85):
            lathe('Abrazadera',[(.066,0),(.066,.018)],'Rust',8,(x,0,0),'X')
            box('Tornillo',(x,-.063,0),(.035,.02,.035),'Iron',.006)
    elif name=='pipe_elbow_valve':
        lathe('Tubo vertical',[(.065,0),(.065,.31)],'Iron',8,(0,0,.02))
        lathe('Codo redondo',[(.065,0),(.082,.04),(.082,.08)],'Iron',8,(0,0,.31),'Y')
        beam('Tubo horizontal',(0,0,.39),(.32,0,.39),.13,.13,'Iron')
        for loc,axis in (((0,0,.11),'Z'),((.24,0,.39),'X')):
            lathe('Brida',[(.095,0),(.105,.025),(.095,.05)],'Rust',6,loc,axis)
        lathe('Aro volante',[(.115,0),(.115,.018)],'Rust',8,(.30,-.02,.39),'Y',False)
        for i in range(3):
            a=i*math.pi/2
            beam('Radio volante',(.30,-.035,.39),(.30+.11*math.cos(a),-.035,.39+.11*math.sin(a)),.018,.018,'Iron')
        lathe('Cubo volante',[(.035,0),(.035,.035)],'Metal_Grey',8,(.30,-.04,.39),'Y')
    elif name=='duct_grille':
        frame('Marco boca',1.9,1.3,1.5,1.1,.04,'Iron')
        # Rejilla abierta y abatida bajo el hueco.
        for i in range(7): beam('Barrote',(-.65+i*.22,.05,.16),(-.65+i*.22,.05,-.52),.025,.025,'Metal_Grey')
        beam('Bisagra',(-.75,0,.12),(.75,0,.12),.04,.04,'Rust')
    elif name=='ledge_walkway':
        box('Marco pasarela',(0,0,.06),(2.,.6,.10),'Iron',.02)
        for x in [i*.14-.91 for i in range(14)]: box('Rejilla',(x,0,.125),(.018,.56,.025),'Metal_Grey')
        for y in (-.27,.27): beam('Borde',( -1,y,.17),(1,y,.17),.025,.025,'Iron')
    elif name=='marigold_raft':
        for i in range(18):
            a=i*2.4; r=.08+(i%4)*.07
            lathe('Flor',[(.012,0),(.045,.025)],'Marigold',5,(r*math.cos(a),r*math.sin(a),.02))
    elif name=='wallet_open':
        slab('Cartera',(0,0,.008),(.2,.1,.016),'Oak_Dark',.01)
        slab('Solapa',(0,.045,.018),(.2,.045,.012),'Oak',.01)
        for x in (-.06,0,.06): box('Tarjeta',(x,-.02,.018),(.035,.05,.008),'Paper',.002)
    elif name in ('clay_wall_panel','clay_wall_broken'):
        broken=name.endswith('broken')
        if not broken:
            box('Muro macizo',(0,0,1.35),(2.,.25,2.7),'Black_Clay',.035)
        else:
            # Boquete central hasta el suelo: hombros completos y dintel irregular.
            box('Machón izquierdo',(-.75,0,1.35),(.5,.4,2.7),'Black_Clay',.025)
            box('Machón derecho',(.75,0,1.35),(.5,.4,2.7),'Black_Clay',.025)
            box('Dintel quebrado',(0,0,2.38),(1.02,.4,.64),'Black_Clay',.025)
            # Borde del boquete quebrado, zigzag visible desde ambos lados.
            for s in (-1,1):
                beam('Grieta quebrada',(s*.49,-.215,0),(s*.43,-.215,.38),.035,.022,'Basalt')
                beam('Grieta quebrada',(s*.43,-.215,.38),(s*.51,-.215,.70),.035,.022,'Basalt')
                beam('Grieta quebrada',(s*.51,-.215,.70),(s*.45,-.215,1.12),.035,.022,'Basalt')
            # Cascotes dispersos a cada lado del paso.
            for side in (-1,1):
                for j in range(2):
                    x=side*(.62+j*.10); z=.08+(j%2)*.04
                    prism('Cascote',[(x-.10,-.19),(x+.06,-.22),(x+.12,-.08),(x-.04,-.04)],z,z+.09,'Basalt' if j%2 else 'Stone','Y')
        # Relieve frontal oaxaqueño: grecas perimetrales, flores y calavera central.
        for z in (.20,2.50):
            for x in (-.65,.65): box('Grecas escalonadas',(x,-.145,z),(.16,.03,.04),'Stone')
        if not broken:
            for side in (-1,1):
                for z in (.75,1.45,2.15):
                    x=side*.82
                    box('Greca vertical',(x,-.15,z),(.045,.03,.16),'Stone')
        # Calavera en relieve; las cuencas son pequeños hundimientos oscuros.
        if not broken:
            box('Cráneo relieve',(0,-.145,1.48),(.42,.045,.42),'Stone',.08)
            box('Mandíbula relieve',(0,-.16,1.27),(.28,.035,.10),'Basalt')
            for x in (-.10,.10): box('Cuenca relieve',(x,-.176,1.52),(.08,.012,.09),'Basalt')
        # Flores de cempasúchil en las esquinas del panel (también visibles roto).
        for x,z in ((-.68,.68),(.68,.68),(-.68,2.0),(.68,2.0)):
            box('Centro cempasúchil',(x,-.16,z),(.08,.035,.08),'Marigold')
            for dx,dz in ((.09,0),(-.09,0)):
                box('Pétalo cempasúchil',(x+dx,-.16,z+dz),(.075,.025,.045),'Marigold')
        # Calados pequeños decorativos, ciegos (no abren paso a través del muro).
        for x,z in ((-.35,.42),(.35,.42),(-.35,2.25),(.35,2.25)):
            prism('Calado rombo ciego',[(x,z-.055),(x+.045,z),(x,z+.055),(x-.045,z)],-.181,-.17,'Basalt','Y')
    elif name=='drain_grate':
        frame('Borde desagüe',.8,.8,.7,.7,.04,'Iron')
        for i in range(7): box('Ranura',(i*.095-.285,0,.025),(.025,.68,.018),'Metal_Grey')
    elif name in ('oak_door_monumental','oak_door_open'):
        open_door=name.endswith('open'); depth=1.3 if open_door else .5
        for x in (-1.24,1.24): box('Jamba',(x,0,1.9),(.12,depth,3.8),'Oak_Dark',.025)
        box('Dintel',(0,0,3.72),(2.6,depth,.16),'Oak_Dark',.025)
        for x in (-.61,.61):
            angle=(-.65 if x<0 else .65) if open_door else 0
            for z in (.95,2.85):
                # hojas talladas con nervaduras, conservando bisagra al marco
                leaf=box('Hoja',(x,angle,1.9),(1.18,.12,3.55),'Oak',.025)
            for z in (.48,1.12,1.9,2.68,3.32):
                for y in (-.07,.07): box('Clavo',(x,y,z),(.035,.018,.035),'Iron',.008)
        for x in (-1.17,1.17):
            for z in (.4,1.9,3.4): box('Bisagra',(x,-.09,z),(.08,.04,.32),'Iron',.01)
    elif name=='neon_noho_sign':
        box('Bastidor',(0,0,.4),(2.8,.08,.8),'Iron',.035)
        for i,ch in enumerate('NOHO'):
            x=-1.04+i*.69
            if ch=='O':
                # marco octagonal hueco luminoso
                for a in range(8):
                    t=a*math.tau/8; u=(a+1)*math.tau/8
                    beam('Neón',(x+.22*math.cos(t),-.06,.4+.32*math.sin(t)),(x+.22*math.cos(u),-.06,.4+.32*math.sin(u)),.045,.045,'Glow')
            elif ch=='N':
                for a,b in (((x-.24,.1),(x-.24,.7)),((x+.24,.1),(x+.24,.7)),((x-.24,.1),(x+.24,.7))): beam('Neón',(a[0],-.06,a[1]),(b[0],-.06,b[1]),.045,.045,'Glow')
            else:
                for xx in (x-.22,x+.22): beam('Neón',(xx,-.06,.1),(xx,-.06,.7),.045,.045,'Glow')
                beam('Neón',(x-.22,-.06,.4),(x+.22,-.06,.4),.045,.045,'Glow')
    elif name=='papel_picado_bridge':
        # Superficie pisable de tiras continuas, solapadas; vanos menores de 12 cm.
        for i in range(15):
            x=i*(2/15)-1+(1/15)
            col=('Papel_Magenta','Papel_Purple','Papel_Cyan')[i%3]
            prism('Tira pisable',[(x-1/15,-1.),(x+1/15,-1.),(x+1/15,1.),(x-1/15,1.)],-.025,.025,col)
        for x in (-.94,.94): tube('Tensor lateral',[(x,-1,0),(x,0,.015),(x,1,0)],.012,'Earth',4)
        for y in (-.75,-.25,.25,.75): box('Travesaño',(0,y,-.012),(1.9,.035,.02),'Iron')
        for x in (-.94,.94):
            for y in (-.92,.92):
                prism('Fleco lateral',[(x-.04,y),(x+.04,y),(x+.035,y-.07),(x,y-.10),(x-.035,y-.07)],-.03,.03,'Papel_Cyan')
    elif name=='island_underside':
        # La masa cuelga desde z=0 hacia abajo, origen en su cara superior.
        for x,y,s in ((-.52,-.48,.88),(.48,-.42,.80),(-.42,.48,.78),(.52,.48,.76)):
            outline=[]
            for i in range(6):
                a=i*math.tau/6+.12
                radius=s*(.43+.07*math.sin(i*2.3+x))
                outline.append((x+radius*math.cos(a),y+radius*math.sin(a)))
            verts=[(px,py,-.08) for px,py in outline]
            verts += [(px*.94+x*.06,py*.94+y*.06,-s*(.72+.16*math.sin(i*1.7))) for i,(px,py) in enumerate(outline)]
            verts.append((x,y,-s))
            faces=[tuple(range(5,-1,-1))]
            for i in range(6):
                j=(i+1)%6
                faces.extend([(i,j,6+j,6+i),(6+i,6+j,12)])
            mesh('Roca facetada',verts,faces,'Basalt')
        for i in range(5): tube('Cable',[(i*.18-.36,.55,-.1),(i*.18-.36,.58,-.55-(i%3)*.2)],.012,'Iron',4)
    elif name=='stalagmite':
        lathe('Estalagmita',[(.34,0),(.32,.12),(.22,.55),(.16,1.1),(.08,1.55),(0,1.9)],'Basalt',6)
    elif name=='emergency_beacon':
        lathe('Base',[(.08,0),(.11,.04),(.09,.14)],'Iron',8)
        lathe('Cúpula',[(.09,.13),(.10,.18),(.07,.26),(.025,.30)],'Glow',8)
    elif name=='door_frame_lone':
        frame('Umbral aislado',1.2,2.2,.94,1.94,.08,'Oak_Dark')
        box('Hoja entreabierta',(.30,-.01,1.08),(.58,.08,2.08),'Oak',.018)
        for z in (.4,1.1,1.8): box('Bisagra',(.03,-.11,z),(.07,.03,.18),'Iron',.008)
    elif name=='petal_cairn':
        for i in range(15):
            a=i*2.4; r=.06+(i%4)*.045
            lathe('Pétalo',[(.015,0),(.04,.015)],'Marigold',5,(r*math.cos(a),r*math.sin(a),.015+(i%3)*.015))
        lathe('Veladora',[(.07,0),(.07,.20)],'Sugar',8,(.18,0,0))
        lathe('Llama',[(.018,0),(.025,.04),(.004,.08)],'Flame',5,(.18,0,.18))
    elif name=='badge_noho':
        box('Cuerpo gafete',(0,0,.065),(.086,.012,.13),'Iron',.004)
        box('Cara del gafete',(0,-.007,.065),(.074,.004,.112),'Oak',.003)
        box('Pantalla',(0,-.010,.078),(.064,.003,.034),'Screen',.002)
        box('Placa nombre',(0,-.010,.035),(.052,.003,.012),'Paper',.002)
        box('Pinza',(0,0,.133),(.032,.012,.014),'Iron',.002)
        tube('Cordón',[(0,0,.133),(0,0,.16),(.018,0,.18)],.003,'Oak',4)
        lathe('Pétalo',[(.003,0),(.012,.01)],'Marigold',5,(.027,-.009,.08),'Y')


NEW_MODELS=tuple(name for name in SPECS if name not in globals())
for _name in NEW_MODELS:
    globals()[_name]=lambda n=_name:new_model(n)


def chair_tipped():
    chair_office()
    rotation=Matrix.Rotation(math.pi/2,3,'Y')
    for o in bpy.context.scene.objects:
        for v in o.data.vertices: v.co=rotation @ v.co
    verts=[v.co for o in bpy.context.scene.objects for v in o.data.vertices]
    low=min(v.z for v in verts)
    centre=(min(v.x for v in verts)+max(v.x for v in verts))/2
    for o in bpy.context.scene.objects:
        for v in o.data.vertices: v.co -= Vector((centre,0,low))


BUILDERS={name:globals()[name] for name in SPECS if name in globals()}
BUILDERS.update(sign_wall=lambda:sign_plate(.62,.2),sign_hanging=lambda:sign_hanging(),sign_wall_right=lambda:sign_plate(.62,.2,1),sign_wall_left=lambda:sign_plate(.62,.2,-1))
BUILDERS.update(reception_desk=lambda:reception_modern(3.4),reception_wing=lambda:reception_modern(1.25,.65))
BUILDERS.update(reception_counter=lambda:reception(),reception_small=lambda:reception(1.7,.7,1.),
                candle_short=lambda:candle(.07,.06,0),candle_mid=lambda:candle(.13,.068,1),candle_tall=lambda:candle(.20,.075,2))


def clear():
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    for m in list(bpy.data.meshes):
        if m.users==0: bpy.data.meshes.remove(m)


def sign_arrow(center_x, direction, y):
    # Flecha en relieve (2 mm) que apunta a +X (direction=1) o -X (direction=-1), vista de frente.
    shape=[(-.06,-.012),(0,-.012),(0,-.036),(.052,0),(0,.036),(0,.012),(-.06,.012)]
    outline=[(center_x+direction*x,z) for x,z in shape]
    if direction<0: outline.reverse()
    prism('Flecha',outline,y-.002,y,'Dark_Plastic','Y')


def sign_plate(w,h,arrow=0):
    # Letrero de pared: marco biselado, placa clara y dos tornillos vistos. El texto lo pone el juego.
    frame('Marco letrero',w,h,w-.03,h-.03,.026,'Metal_Dark')
    prism('Placa',rect(w-.03,h-.03),-.019,-.017,'Paper','Y')
    for x in (-w/2+.035,w/2-.035) if not arrow else (-arrow*(w/2-.035),):
        ring=[(x+.007*math.cos(i*math.pi/3),.007*math.sin(i*math.pi/3)) for i in range(6)]
        prism('Tornillo',ring,-.022,-.019,'Metal_Grey','Y')
    if arrow: sign_arrow(arrow*(w/2-.1),arrow,-.019)


def sign_wall(): sign_plate(.62,.2)


def sign_hanging():
    # Letrero colgante de dos caras: placa en caja, varillas al techo y rosetas de anclaje.
    box('Caja',(0,0,0),(.9,.03,.26),'Metal_Dark',.004)
    for y in (-.0155,.0155):
        mesh('Cara',[(-.43,y,-.11),(.43,y,-.11),(.43,y,.11),(-.43,y,.11)],[(0,1,2,3) if y<0 else (3,2,1,0)],'Paper')
    for x in (-.32,.32):
        box('Varilla',(x,0,.28),(.012,.012,.3),'Metal_Grey')
        box('Roseta',(x,0,.425),(.05,.05,.01),'Metal_Grey',.002)


def place_origin(name):
    if name in ('wall_clock','painting_frame','plaque','exit_sign','letter_n','letter_o','letter_h','door_exit','badge_noho')+SIGNS+CEILING_MODELS: return
    points=[v.co for o in bpy.context.scene.objects for v in o.data.vertices]
    offset=Vector(((min(v.x for v in points)+max(v.x for v in points))/2,
                   (min(v.y for v in points)+max(v.y for v in points))/2,min(v.z for v in points)))
    for o in bpy.context.scene.objects:
        for v in o.data.vertices: v.co-=offset


def validate(name):
    objects=list(bpy.context.scene.objects)
    points=[o.matrix_world @ v.co for o in objects for v in o.data.vertices]
    size=tuple(max(v[i] for v in points)-min(v[i] for v in points) for i in range(3))
    tris=0; names=set()
    for o in objects:
        o.data.calc_loop_triangles(); tris+=len(o.data.loop_triangles)
        names.update(m.name for m in o.data.materials)
        assert not o.modifiers and o.type=='MESH'
        assert all(not p.use_smooth for p in o.data.polygons)
    expected,budget=SPECS[name]
    checked=size
    # Comprobar también el cuerpo nominal cuando hay apéndices intencionales.
    body_filters={'mug':lambda o:o.name.startswith('Taza'),
                  'partition_panel':lambda o:not o.name.startswith('Pie'),
                  'box_cardboard_open':lambda o:not o.name.startswith('Solapa')}
    if name in body_filters:
        body=[v.co for o in objects if body_filters[name](o) for v in o.data.vertices]
        checked=tuple(max(v[i] for v in body)-min(v[i] for v in body) for i in range(3))
        print(f'BODY {name}: {tuple(round(v,4) for v in checked)} m; nominal={expected}',flush=True)
    print(f'MODEL {name}: {tris}/{budget} tris; bbox={tuple(round(v,4) for v in size)} m; materials={sorted(names)}',flush=True)
    if names-set(PALETTE): raise ValueError(f'{name}: materiales fuera de paleta')
    material_limit=MESHY_MATERIAL_LIMITS.get(name,6 if name in MESHY_SOURCED else 5)
    if len(names)>material_limit: raise ValueError(f'{name}: demasiados materiales ({len(names)}>{material_limit})')
    if tris>budget: raise ValueError(f'{name}: presupuesto excedido ({tris}>{budget})')
    if any(abs(a-b)/b>.15 for a,b in zip(checked,expected)):
        raise ValueError(f'{name}: dimensiones {checked}, esperadas {expected}')
    floor=min(v.z for v in points)
    if name not in ('wall_clock','painting_frame','plaque','exit_sign','letter_n','letter_o','letter_h')+SIGNS+CEILING_MODELS and abs(floor)>.008:
        raise ValueError(f'{name}: no descansa sobre el suelo ({floor})')
    return tris


def fit_nominal_bounds(name):
    """Ajusta los vértices al tamaño nominal sin cambiar el origen semántico."""
    expected=SPECS[name][0]
    points=[v.co.copy() for o in bpy.context.scene.objects for v in o.data.vertices]
    lo=[min(p[i] for p in points) for i in range(3)]
    hi=[max(p[i] for p in points) for i in range(3)]
    span=[hi[i]-lo[i] for i in range(3)]
    target_min=[-expected[i]/2 for i in range(3)]
    if name=='badge_noho': target_min[2]=-expected[2]
    if name not in ('wall_clock','painting_frame','plaque','exit_sign','letter_n','letter_o','letter_h','door_exit')+SIGNS+CEILING_MODELS:
        target_min[2]=0.
    if name in CEILING_MODELS:
        target_min[2]=-expected[2]
    for o in bpy.context.scene.objects:
        for v in o.data.vertices:
            for axis in range(3):
                v.co[axis]=target_min[axis]+(v.co[axis]-lo[axis])*expected[axis]/span[axis]
        o.data.update()


def main():
    args=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else []
    script_fallback='--script-fallback' in args
    args=[arg for arg in args if arg!='--script-fallback']
    names=args if args else (list(SPECS) if script_fallback else [name for name in SPECS if name not in MESHY_SOURCED])
    blocked=set(names)&MESHY_SOURCED
    if blocked and not script_fallback:
        raise ValueError(f'Modelos de Meshy protegidos; usa --script-fallback para regenerar: {sorted(blocked)}')
    unknown=set(names)-set(BUILDERS)
    if unknown: raise ValueError(f'Modelos desconocidos: {sorted(unknown)}')
    bpy.context.scene.unit_settings.system='METRIC'
    bpy.context.scene.unit_settings.scale_length=1
    out=ROOT/'assets/models'; out.mkdir(parents=True,exist_ok=True)
    errors=[]
    for name in names:
        clear(); BUILDERS[name](); place_origin(name); fit_nominal_bounds(name)
        try: validate(name)
        except ValueError as error:
            errors.append(str(error))
            print(f'ERROR: {error}',flush=True)
            continue
        bpy.ops.object.select_all(action='SELECT')
        bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
        bpy.ops.export_scene.gltf(filepath=str(out/f'{name}.glb'),export_format='GLB',export_apply=True,
            export_yup=True,use_selection=True,export_materials='EXPORT',export_normals=True,export_texcoords=True,
            export_animations=False,export_cameras=False,export_lights=False)
    if errors: raise ValueError('\n'.join(errors))
    print(f'OK: {len(names)} modelos exportados.',flush=True)


if __name__=='__main__':
    try: main()
    except Exception:
        import traceback
        traceback.print_exc()
        sys.exit(1)
