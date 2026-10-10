#!/usr/bin/env python3
"""Cliente Meshy con reserva de créditos, recuperación y resultados locales.

Solo biblioteca estándar. Referencia: https://docs.meshy.ai/en/api/animation
Las tareas POST nunca se reintentan automáticamente para evitar cobros dobles.
"""
import argparse
import base64
import datetime
import fcntl
import hashlib
import json
import mimetypes
import os
from pathlib import Path
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

ROOT = Path(__file__).resolve().parents[2]
LEDGER = ROOT / 'builds/meshy/ledger.json'
BASE = 'https://api.meshy.ai'
ENDPOINTS = {'image-to-3d', 'rigging', 'animations'}


def api_key():
    if os.environ.get('MESHYAI'):
        return os.environ['MESHYAI']
    for line in (ROOT / '.env').read_text().splitlines():
        name, sep, value = line.strip().partition('=')
        if sep and name == 'MESHYAI':
            return value.strip().strip('\"\'')
    raise RuntimeError('MESHYAI no configurada en .env')


def request(path, payload=None):
    req = urllib.request.Request(BASE + path,
        data=json.dumps(payload).encode() if payload is not None else None,
        headers={'Authorization': 'Bearer ' + api_key(), 'Content-Type': 'application/json'})
    try:
        with urllib.request.urlopen(req, timeout=90) as response:
            return json.load(response)
    except urllib.error.HTTPError as error:
        # Solo mensaje del servidor; jamás cabeceras ni cuerpo enviado (imagen/clave).
        detail = error.read().decode(errors='replace')[:1500]
        detail = detail.replace(api_key(), '[secreto]')
        raise RuntimeError(f'Meshy HTTP {error.code}: {detail}') from None


def balance():
    return float(request('/openapi/v1/balance')['balance'])


def save(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + '.part')
    temporary.write_text(json.dumps(value, indent=2, ensure_ascii=False) + '\n')
    temporary.replace(path)


def entries():
    return json.loads(LEDGER.read_text()) if LEDGER.exists() else []


def update(entry):
    rows = entries()
    rows = [row for row in rows if row['id'] != entry['id']]
    rows.append(entry)
    save(LEDGER, rows)


def urls(value, prefix=''):
    if isinstance(value, dict):
        for key, child in value.items():
            yield from urls(child, prefix + '_' + key)
    elif isinstance(value, list):
        for i, child in enumerate(value):
            yield from urls(child, prefix + '_' + str(i))
    elif isinstance(value, str) and value.startswith('https://'):
        yield prefix.strip('_'), value


def download_results(task, out):
    """Descarga todas las URLs de resultados, texturas y vistas; guarda hashes."""
    manifest = []
    errors = []
    for label, url in urls(task):
        extension = Path(urllib.parse.urlsplit(url).path).suffix or '.bin'
        name = re.sub(r'[^a-zA-Z0-9_-]', '_', label) + extension
        dest = out / name
        for attempt in range(3):
            try:
                with urllib.request.urlopen(url, timeout=180) as response:
                    data = response.read()
                dest.write_bytes(data)
                manifest.append({'file': name, 'bytes': len(data),
                    'sha256': hashlib.sha256(data).hexdigest()})
                print('descargado', name, len(data), flush=True)
                break
            except (OSError, urllib.error.URLError) as error:
                if attempt == 2:
                    errors.append(f'{name}: {type(error).__name__}')
                else:
                    time.sleep(2)
    save(out / 'downloads.json', manifest)
    if errors:
        raise RuntimeError('Descargas incompletas; usar status --out para recuperar: ' + '; '.join(errors))


def poll(endpoint, task_id, out, timeout, entry):
    deadline = time.monotonic() + timeout
    while True:
        task = request(f'/openapi/v1/{endpoint}/{urllib.parse.quote(task_id, safe="")}')
        save(out / 'task.json', task)
        entry.update(status=task['status'], consumed_credits=task.get('consumed_credits'),
            balance=balance())
        update(entry)
        print(task_id, task['status'], task.get('progress', 0), flush=True)
        if task['status'] == 'SUCCEEDED':
            download_results(task, out)
            return task
        if task['status'] in ('FAILED', 'CANCELED', 'CANCELLED', 'EXPIRED'):
            raise RuntimeError('Tarea terminada sin resultado: ' + json.dumps(task.get('task_error', {})))
        if time.monotonic() >= deadline:
            raise RuntimeError(f'Tiempo agotado; recuperar con status {endpoint} {task_id} --out {out}')
        time.sleep(min(5, max(0, deadline - time.monotonic())))


def create(endpoint, payload, args, estimate):
    out = Path(args.out).resolve()
    out.mkdir(parents=True, exist_ok=True)
    before = balance()
    # Coste conservador; las tareas pendientes reservan también su coste estimado.
    rows = entries()
    spent = sum(row.get('consumed_credits') if row.get('consumed_credits') is not None
        else row.get('estimated_credits', 0) for row in rows)
    if not args.force and before - estimate < 200:
        raise RuntimeError(f'Reserva protegida: saldo {before:g}, coste máximo previsto {estimate}, reserva 200')
    if spent + estimate > args.budget:
        raise RuntimeError(f'Tope de presupuesto {args.budget}: contabilizado {spent:g}, previsto {estimate}')
    subject = str(out.parent)
    if endpoint == 'image-to-3d' and sum(row['endpoint'] == endpoint and row.get('subject') == subject for row in rows) >= 3:
        raise RuntimeError('Máximo de tres intentos 3D por objeto alcanzado')
    safe_payload = dict(payload)
    if 'image_url' in safe_payload:
        safe_payload['image_url'] = 'sha256:' + hashlib.sha256(Path(args.image).read_bytes()).hexdigest()
    save(out / 'request.json', safe_payload)
    result = request('/openapi/v1/' + endpoint, payload)
    task_id = result['result']
    entry = {'date': datetime.datetime.now(datetime.timezone.utc).isoformat(),
        'endpoint': endpoint, 'id': task_id, 'consumed_credits': None,
        'estimated_credits': estimate, 'balance_before': before, 'balance': None,
        'subject': subject, 'out': str(out), 'status': 'CREATED'}
    update(entry)
    save(out / 'created.json', result)
    print('creada', task_id, 'saldo previo', before, flush=True)
    poll(endpoint, task_id, out, args.timeout, entry)


def parser():
    p = argparse.ArgumentParser(description=__doc__)
    sub = p.add_subparsers(dest='command', required=True)
    sub.add_parser('balance')
    actions = sub.add_parser('actions')
    actions.add_argument('--search')
    status = sub.add_parser('status')
    status.add_argument('endpoint', choices=sorted(ENDPOINTS))
    status.add_argument('id')
    status.add_argument('--out', help='Recupera, espera y descarga una tarea existente')
    status.add_argument('--timeout', type=float, default=1800)
    image = sub.add_parser('image-to-3d')
    image.add_argument('--image', required=True)
    image.add_argument('--polycount', type=int, default=6000)
    image.add_argument('--model-type', default='lowpoly', choices=['lowpoly', 'standard'])
    image.add_argument('--pose', default='a-pose', choices=['a-pose', 't-pose', ''])
    image.add_argument('--texture-res', type=int, default=1024, choices=[1024, 2048, 4096])
    rig = sub.add_parser('rig')
    rig.add_argument('--task', required=True)
    rig.add_argument('--height', type=float, required=True)
    animate = sub.add_parser('animate')
    animate.add_argument('--rig', required=True)
    animate.add_argument('--actions', required=True)
    animate.add_argument('--fps', type=int, default=24, choices=[24, 25, 30, 60])
    for command in (image, rig, animate):
        command.add_argument('--out', required=True)
        command.add_argument('--force', action='store_true', help='Permite consumir la reserva de 200; no el tope')
        command.add_argument('--budget', type=int, default=300, help='Tope total del ledger (predeterminado: 300)')
        command.add_argument('--timeout', type=float, default=1800)
    return p


def main():
    args = parser().parse_args()
    if hasattr(args, 'timeout') and args.timeout <= 0:
        raise RuntimeError('El tiempo límite debe ser positivo')
    if hasattr(args, 'budget') and args.budget <= 0:
        raise RuntimeError('El presupuesto debe ser positivo')
    # Las consultas no modifican el ledger ni gastan; no esperan a otra generación.
    if args.command == 'balance':
        print(json.dumps({'balance': balance()}))
        return
    if args.command == 'actions':
        query = '?' + urllib.parse.urlencode({'search': args.search}) if args.search else ''
        print(json.dumps(request('/openapi/v1/animations/library' + query), indent=2))
        return
    if args.command == 'status' and not args.out:
        print(json.dumps(request(f'/openapi/v1/{args.endpoint}/{urllib.parse.quote(args.id, safe="")}'), indent=2))
        return
    LEDGER.parent.mkdir(parents=True, exist_ok=True)
    # Un solo cliente pagado a la vez: saldo, creación y ledger son coherentes.
    with (LEDGER.parent / '.client.lock').open('a') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        if args.command == 'status':
            out = Path(args.out).resolve()
            out.mkdir(parents=True, exist_ok=True)
            entry = next((row for row in entries() if row['id'] == args.id),
                {'date': datetime.datetime.now(datetime.timezone.utc).isoformat(), 'endpoint': args.endpoint, 'id': args.id})
            poll(args.endpoint, args.id, out, args.timeout, entry)
        elif args.command == 'image-to-3d':
            if not 1000 <= args.polycount <= 300000:
                raise RuntimeError('polycount fuera de rango (1000–300000)')
            source = Path(args.image)
            mime = mimetypes.guess_type(source.name)[0]
            if mime not in ('image/png', 'image/jpeg', 'image/webp'):
                raise RuntimeError('Formato de imagen no admitido')
            create('image-to-3d', {'image_url': 'data:' + mime + ';base64,' + base64.b64encode(source.read_bytes()).decode(),
                'ai_model': 'latest', 'model_type': args.model_type, 'topology': 'triangle',
                'should_remesh': True, 'target_polycount': args.polycount, 'should_texture': True,
                # Meshy no ofrece 1k: se reduce a 1024 durante la adaptación.
                'texture_resolution': {1024: '2k', 2048: '2k', 4096: '4k'}[args.texture_res], 'enable_pbr': False,
                'pose_mode': args.pose, 'target_formats': ['glb'], 'enable_thumbnail': True}, args, 60)
        elif args.command == 'rig':
            if args.height <= 0:
                raise RuntimeError('La altura debe ser positiva')
            create('rigging', {'input_task_id': args.task, 'height_meters': args.height}, args, 5)
        elif args.command == 'animate':
            ids = [int(value) for value in args.actions.split(',')]
            if not 1 <= len(ids) <= 10 or len(set(ids)) != len(ids):
                raise RuntimeError('actions requiere de 1 a 10 identificadores únicos')
            create('animations', {'rig_task_id': args.rig, 'action_ids': ids,
                'post_process': {'operation_type': 'change_fps', 'fps': args.fps}}, args, 3 * len(ids))


if __name__ == '__main__':
    try:
        main()
    except (RuntimeError, OSError, ValueError, KeyError, urllib.error.URLError) as error:
        print('ERROR:', error, file=sys.stderr)
        sys.exit(1)
