#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GODOT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$GODOT_ROOT/.." && pwd)"
OUTPUT_ROOT="${1:-$REPO_ROOT/build/godot-web}"
SITE_DIR="$OUTPUT_ROOT/site_nothreads"
PACK_PATH="$OUTPUT_ROOT/game.zip"
SITE_ZIP_PATH="$OUTPUT_ROOT/hitezero-godot-web-site_nothreads.zip"
PORT="${PORT:-8123}"
PRESET_NAME="${GODOT_WEB_PRESET:-Web}"

if ! command -v godot >/dev/null 2>&1; then
  echo "godot CLI is required." >&2
  exit 1
fi

template_root="${GODOT_TEMPLATE_DIR:-}"
if [[ -z "$template_root" ]]; then
  template_root="$(ls -d "$HOME/Library/Application Support/Godot/export_templates/"* 2>/dev/null | sort -V | tail -n 1 || true)"
fi

if [[ -z "$template_root" || ! -f "$template_root/web_nothreads_release.zip" ]]; then
  echo "Could not find web_nothreads_release.zip. Set GODOT_TEMPLATE_DIR to your Godot export template directory." >&2
  exit 1
fi

mkdir -p "$OUTPUT_ROOT"
rm -rf "$SITE_DIR"
mkdir -p "$SITE_DIR"

echo "Exporting Godot web pack..."
godot --headless --path "$GODOT_ROOT" --export-pack "$PRESET_NAME" "$PACK_PATH"

echo "Assembling no-threads web runtime..."
python3 - <<'PY' "$template_root/web_nothreads_release.zip" "$PACK_PATH" "$SITE_DIR"
import os, shutil, sys, zipfile

template_zip, pack_zip, site_dir = sys.argv[1:4]
with zipfile.ZipFile(template_zip) as zf:
    zf.extractall(site_dir)
shutil.copy2(pack_zip, os.path.join(site_dir, "game.zip"))
PY

cat > "$SITE_DIR/index.html" <<'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, user-scalable=no, initial-scale=1.0">
  <title>HiteZero Godot Web</title>
  <style>
    html, body {
      margin: 0;
      width: 100%;
      height: 100%;
      overflow: hidden;
      background: #050510;
    }

    body {
      display: grid;
      place-items: center;
    }

    #canvas {
      display: block;
      width: min(100vw, 57.14vh);
      height: min(175vw, 100vh);
      aspect-ratio: 4 / 7;
      outline: none;
      background: #050510;
    }

    #status {
      position: fixed;
      left: 12px;
      bottom: 12px;
      color: #dbeafe;
      font: 12px/1.4 sans-serif;
      background: rgba(15, 23, 42, 0.72);
      border: 1px solid rgba(96, 165, 250, 0.35);
      border-radius: 8px;
      padding: 8px 10px;
    }
  </style>
</head>
<body>
  <canvas id="canvas">Your browser does not support the canvas tag.</canvas>
  <div id="status">Loading Godot Web build...</div>

  <script src="godot.js"></script>
  <script>
    const statusEl = document.getElementById('status');
    const engine = new Engine({
      canvas: document.getElementById('canvas'),
      executable: 'godot',
      mainPack: 'game.zip',
      canvasResizePolicy: 0,
      focusCanvas: true,
      experimentalVK: true,
      serviceWorker: '',
    });

    engine.startGame().then(() => {
      statusEl.textContent = 'Running';
      window.requestAnimationFrame(() => {
        statusEl.style.display = 'none';
      });
    }).catch((err) => {
      console.error(err);
      statusEl.textContent = `Startup failed: ${err instanceof Error ? err.message : err}`;
    });
  </script>
</body>
</html>
EOF

python3 - <<'PY' "$SITE_DIR" "$SITE_ZIP_PATH"
import os, sys, zipfile

site_dir, zip_path = sys.argv[1:3]
with zipfile.ZipFile(zip_path, "w", compression=zipfile.ZIP_DEFLATED) as zf:
    for root, _, files in os.walk(site_dir):
        for file_name in files:
            full_path = os.path.join(root, file_name)
            rel_path = os.path.relpath(full_path, site_dir)
            zf.write(full_path, rel_path)
PY

cat <<EOF
Build complete.
- Pack: $PACK_PATH
- Site: $SITE_DIR
- Site zip: $SITE_ZIP_PATH
- Serve: python3 -m http.server $PORT --directory "$SITE_DIR"
- URL: http://127.0.0.1:$PORT/index.html
EOF
