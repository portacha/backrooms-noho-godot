#!/usr/bin/env bash
# Serializa las ejecuciones de Godot sobre este proyecto (varios agentes comparten .godot/).
# Uso: tools/run_godot.sh --headless --path . res://tools/debug/playthrough.tscn
# Las ejecuciones con ventana (capturas) van a una pantalla virtual para no abrir ventanas en
# el escritorio de quien trabaja. NOHO_WINDOW=1 las muestra de verdad.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p builds
headless=0
for arg in "$@"; do
	[ "$arg" = "--headless" ] && headless=1
done
if [ "$headless" = 0 ] && [ "${NOHO_WINDOW:-0}" != 1 ] && command -v xvfb-run >/dev/null; then
	exec flock builds/.godot.lock env -u WAYLAND_DISPLAY xvfb-run -a -s "-screen 0 1280x720x24" godot --display-driver x11 "$@"
fi
exec flock builds/.godot.lock godot "$@"
