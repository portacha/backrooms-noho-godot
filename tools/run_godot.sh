#!/usr/bin/env bash
# Serializa las ejecuciones de Godot sobre este proyecto (varios agentes comparten .godot/).
# Uso: tools/run_godot.sh --headless --path . res://tools/debug/playthrough.tscn
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p builds
exec flock builds/.godot.lock godot "$@"
