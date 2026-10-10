#!/usr/bin/env python3
"""Tanda de props: referencias, Meshy y saldo aislado; nunca modifica el cliente común."""
import argparse
import fcntl
import importlib.util
import json
from pathlib import Path
import shutil
import sys
sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'builds/meshy/props'
DESCRIPTIONS = {
'sugar_skull': 'Authentic Mexican sugar skull calavera, recognizable rounded human cranium, large deeply hollow black eye sockets, triangular nasal cavity, sculpted cheekbones, integrated jaw and individual scalloped teeth. Raised orange marigold flower on forehead, bold magenta and orange scrolling icing filigree around eyes and cheeks. Ivory sugar body, dark sockets. All ornament must be raised geometric relief, not fine painted lines.',
'sugar_skull_giant': 'Massive ceiling inset Mexican sugar skull, same ivory sugar cranium and recognizable large hollow eye sockets, triangular nose, integrated scalloped teeth, raised marigold forehead flower. Broad raised filigree and inner eye sockets colored PURE CYAN #00FFFF reserved emission marker; no other cyan. Show upright skull for reconstruction, it will be rotated to look downward in adaptation.',
'ofrenda_arch': 'Freestanding tall Mexican ofrenda arch made of bent cane reeds thickly covered with sculpted orange marigold clusters. Open empty central passage, two vertical legs and rounded arch, no floor or pedestal. Flowers form bold facet geometry, dark brown cane visible underneath.',
'clay_wall_panel': 'Solid rectangular upright Oaxaca burnished black clay wall panel with thick slab body, prominent sculpted central skull relief, raised four flowers and original stepped geometric fret border. Tiny decorative diamond perforations, no doorway. Black charcoal body, subdued gray relief and a few orange flower accents. Complete front rectangular silhouette.',
'copal_censer': 'Mexican clay copal incense censer, deep open bowl supported on THREE sturdy short ceramic legs. Dark warm brown clay, visible chunky embers in bowl PURE CYAN #00FFFF reserved emission marker, no smoke, no flame plume, no other cyan.',
'marigold_vase': 'Dark earthenware Mexican vase with short neck, round belly and a compact full bouquet of sculpted orange cempasuchil marigold blossoms. Several densely layered petal clusters, dark stems, integrated sturdy silhouette.',
'pan_de_muerto': 'Traditional Mexican pan de muerto bread, round low domed bun with prominent raised crossed bone strips and rounded central knot, golden brown crust and ivory sugar on raised bones. Recognizable baked bread, no plate.',
'clay_pot_black': 'Oaxaca black clay pitcher with rounded belly, short neck, side handle and tiny diamond openwork carvings. Burnished charcoal black, subdued gray relief.',
'marigold_pile': 'Low dense irregular circular mound of orange cempasuchil marigold blossoms lying on ground, dozens of faceted petal clusters, no vase or stems or ground plane.',
'stone_stele': 'Upright volcanic stone stele with original stepped geometric fret patterns deeply carved in front, rectangular thick slab, dark desaturated stone, no letters or archaeological replica.',
'oak_door_monumental': 'Ancient monumental double leaf oak door in solid surrounding rectangular frame, two clearly separate closed wooden leaves, raised panels, iron straps, hinges and studs, dark brown oak. No building or ground.',
'island_underside': 'Underside of floating rock island, broad flat upper rim and tapering jagged broken volcanic rock below with few thick dangling cables, dark stone brown gray, no buildings or vegetation.',
'stalagmite': 'Single irregular faceted volcanic stone stalagmite, broad rocky foot and tapering asymmetrical pointed tip, charcoal dark gray, no ground plane.'}
BUDGETS = dict(zip(DESCRIPTIONS, [1400,3000,2600,2600,800,800,450,800,900,1200,3000,1600,500]))
BUDGETS['clay_wall_broken'] = 2600
BUDGETS['oak_door_open'] = 3000
HIGH_COLOR_PROPS = set(list(DESCRIPTIONS)[:5]) | {'clay_wall_broken'}
MAX_BATCH_CREDITS = 420  # 60 ya consumidos por las dos tareas prepagadas; quedan 360 para esta tanda.
TASK_ESTIMATE = 30  # Coste real observado en las dos tareas de referencia.
STYLE = ' Single isolated complete object, frontal three quarter view slightly elevated, plain uniform gray background, flat diffuse lighting, no cast shadows, no text or logo. Modern low poly faceted 3D game asset, flat solid colors, coarse bold sculpted details, restrained somber palette with marigold orange accents, no photoreal texture, no thin floating details.'

def module(name, path):
    spec = importlib.util.spec_from_file_location(name, ROOT / path)
    result = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(result)
    return result

def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('command', choices=['image','submit','balance','recover'])
    p.add_argument('name', nargs='?', choices=list(DESCRIPTIONS))
    args = p.parse_args()
    OUT.mkdir(parents=True, exist_ok=True)
    m = module('meshy_client', 'tools/assets/meshy.py')
    m.LEDGER = OUT / 'ledger.json'
    update_original = m.update
    def update_locked(entry):
        with (OUT / '.ledger.lock').open('a') as ledger_lock:
            fcntl.flock(ledger_lock, fcntl.LOCK_EX)
            update_original(entry)
    m.update = update_locked
    if args.command == 'image':
        if not args.name: p.error('Falta nombre')
        folder = OUT / args.name; folder.mkdir(exist_ok=True)
        refs = list(folder.glob('ref*.png'))
        if len(refs) >= 3: raise RuntimeError('Máximo tres imágenes')
        if not refs:
            shutil.copy2(ROOT / 'assets/models' / (args.name + '.glb'), folder / 'before.glb')
        prompt = DESCRIPTIONS[args.name] + STYLE
        if args.name in ('island_underside','stalagmite'):
            prompt = prompt.replace('with marigold orange accents','without any orange accents') + ' Pure desaturated charcoal and brown stone only, no gold, no orange veins, no gems, no glowing cracks.'
        if args.name == 'island_underside': prompt += ' Cables hang vertically down from the rim, not a garland.'
        if args.name == 'stalagmite': prompt += ' Only natural rock, no cables, metal, rope, manmade parts or ornaments.'
        (folder / 'prompt.txt').write_text(prompt + '\n')
        g = module('gen_image', 'tools/assets/gen_image.py')
        image = g.generate(prompt, '1024x1024')
        path = folder / ('ref.png' if not refs else f'ref{len(refs)+1}.png')
        image.save(path); print('IMAGEN', path, flush=True)
        return
    # El mismo candado que el cliente compartido, abierto sin escribirlo.
    with (ROOT / 'builds/meshy/.client.lock').open('r') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        before = m.balance()
        if args.command == 'balance':
            m.save(OUT / 'balance_latest.json', {'balance':before}); print(json.dumps({'balance':before})); return
        folder = OUT / args.name
        if args.command == 'recover':
            attempt = sorted(folder.glob('attempt*'))[-1]
            task = json.loads((attempt / 'created.json').read_text())['result']
            entry = next(row for row in m.entries() if row['id'] == task)
            m.poll('image-to-3d', task, attempt, 1800, entry); return
        rows = m.entries()
        spent = sum(r.get('consumed_credits') if r.get('consumed_credits') is not None else r.get('estimated_credits',60) for r in rows)
        if before - TASK_ESTIMATE < 250: raise RuntimeError(f'Reserva 250 protegida: saldo {before}')
        if spent + TASK_ESTIMATE > MAX_BATCH_CREDITS: raise RuntimeError(f'Tope tanda {MAX_BATCH_CREDITS}: gastado/reservado {spent}')
        attempts = list(folder.glob('attempt*'))
        if len(attempts) >= 2: raise RuntimeError('Máximo dos intentos 3D')
        if not (folder / 'review_ref.json').exists(): raise RuntimeError('Revisar imagen y guardar review_ref.json antes de gastar')
        import base64
        image = folder / 'ref.png'
        payload = {'image_url':'data:image/png;base64,' + base64.b64encode(image.read_bytes()).decode(), 'ai_model':'latest','model_type':'lowpoly','topology':'triangle','should_remesh':True,'target_polycount':max(1000,round(BUDGETS[args.name]*1.5)),'should_texture':True,'texture_resolution':'2k','enable_pbr':False,'pose_mode':'','target_formats':['glb'],'enable_thumbnail':True}
        ns = argparse.Namespace(out=str(folder / f'attempt{len(attempts)+1}'), force=False,budget=MAX_BATCH_CREDITS,timeout=1800,image=str(image))
        poll_original = m.poll
        def poll_unlocked(*params):
            # El saldo y la reserva ya están anotados: no bloquear trabajos independientes.
            fcntl.flock(lock, fcntl.LOCK_UN)
            return poll_original(*params)
        m.poll = poll_unlocked
        m.create('image-to-3d',payload,ns,TASK_ESTIMATE)

if __name__ == '__main__':
    try: main()
    except Exception as e:
        print('ERROR:', str(e), file=sys.stderr); sys.exit(1)
