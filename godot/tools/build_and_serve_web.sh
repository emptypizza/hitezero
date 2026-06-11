#!/usr/bin/env bash
# One safe command: build the web bundle, then serve site_nothreads (same shell).
# Avoids pasted one-liners that merge dist/godot-web with python3.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GODOT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$GODOT_ROOT/.." && pwd)"
PORT="${PORT:-8123}"
OUT="${1:-$REPO_ROOT/dist/godot-web}"

if [[ $# -gt 1 ]]; then
	echo "ERROR: Only one optional output directory is allowed (got $# args)." >&2
	exit 1
fi

if [[ "$OUT" != /* ]]; then
	OUT="$REPO_ROOT/$OUT"
fi

bash "$SCRIPT_DIR/build_web.sh" "$OUT"
echo "Starting http.server on port $PORT (Ctrl+C to stop)..."
exec python3 -m http.server "$PORT" --directory "$OUT/site_nothreads"
