#!/usr/bin/env bash
# Netlify build: use committed dist, or build with Godot if CLI + templates exist.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
INDEX="$ROOT/dist/godot-web/site_nothreads/index.html"

if [[ -f "$INDEX" ]]; then
  echo "netlify_build: using existing $INDEX"
  exit 0
fi

if command -v godot >/dev/null 2>&1; then
  echo "netlify_build: Godot found; running build_web.sh"
  bash "$ROOT/godot/tools/build_web.sh" "$ROOT/dist/godot-web"
  exit 0
fi

echo "netlify_build: ERROR — publish folder missing. Run locally: bash godot/tools/build_web.sh dist/godot-web" >&2
echo "netlify_build: Then commit dist/godot-web/site_nothreads/ (and dist/godot-web/game.zip if needed) and push." >&2
exit 1
