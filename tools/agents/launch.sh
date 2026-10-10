#!/usr/bin/env bash
# Uso: tools/agents/launch.sh <codex|opencode> <modelo> <id-spec>
set -uo pipefail
cd "$(dirname "$0")/../.."
tool="$1"; model="$2"; id="$3"
prompt="Eres un agente de desarrollo trabajando en el repositorio actual (juego Godot 4.7 'Backrooms NOHO'). Tu encargo completo está en builds/specs/${id}.md; antes lee builds/specs/00-common.md. Ejecútalo de principio a fin sin pedir confirmación, verifica como se exige y termina escribiendo tu informe en builds/reports/${id}.md. No toques archivos fuera de los tuyos."
log="builds/logs/${id}.log"
if [ "$tool" = codex ]; then
  codex exec -m "$model" -s workspace-write -c sandbox_workspace_write.network_access=true \
    --add-dir "$HOME/.local/share/godot" --add-dir "$HOME/.config/godot" --add-dir "$HOME/.cache/godot" \
    --add-dir "$HOME/.config/blender" --add-dir "$HOME/snap/blender" \
    "$prompt" < /dev/null > "$log" 2>&1
else
  opencode run -m "$model" "$prompt" < /dev/null > "$log" 2>&1
fi
echo "EXIT $? ${id}" >> "$log"
