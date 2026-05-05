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

# Catch one-line paste like: .../build_web.sh dist/godot-webpython3 -m http.server ...
if [[ -n "${1:-}" ]]; then
	case "$1" in
		*webpython* | *http.server*)
			echo "ERROR: First argument to build_web.sh looks merged with a python/http.server command: '$1'" >&2
			echo "Run the build alone, then on the next line start the static server (see README Build For Web)." >&2
			exit 1
			;;
	esac
fi

# Same paste pattern but with a space: .../build_web.sh dist/godot-web python3 -m http.server ...
# Those become \$2, \$3, ... here; the server never runs unless it is a separate shell command.
if [[ $# -gt 1 ]]; then
	echo "ERROR: Too many arguments ($#): only one optional output directory is allowed." >&2
	echo "Extra tokens look like a pasted http.server command: ${*:2}" >&2
	echo "Run: bash \"$SCRIPT_DIR/build_web.sh\" <out-dir>   then on the next line: python3 -m http.server ..." >&2
	echo "Or from repo root: make godot-web && make godot-web-serve" >&2
	exit 1
fi

if [[ "$OUTPUT_ROOT" != /* ]]; then
  OUTPUT_ROOT="$REPO_ROOT/$OUTPUT_ROOT"
  SITE_DIR="$OUTPUT_ROOT/site_nothreads"
  PACK_PATH="$OUTPUT_ROOT/game.zip"
  SITE_ZIP_PATH="$OUTPUT_ROOT/hitezero-godot-web-site_nothreads.zip"
fi

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

# Content-addressed pack name so browsers fetch a new URL each build (query strings break --main-pack / VFS paths).
GAME_PACK_CACHE_TAG="$(shasum -a 256 "$PACK_PATH" | awk '{print substr($1,1,16)}')"
GAME_PACK_BASENAME="game-${GAME_PACK_CACHE_TAG}.zip"
mv "$SITE_DIR/game.zip" "$SITE_DIR/$GAME_PACK_BASENAME"

cat > "$SITE_DIR/index.html" <<'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, user-scalable=no, initial-scale=1.0, viewport-fit=cover">
  <meta name="theme-color" content="#050510">
  <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate" />
  <title>HiteZero</title>
  <style>
    :root {
      --accent: rgba(96, 165, 250, 0.6);
      --accent-soft: rgba(96, 165, 250, 0.22);
      --bezel: #0b1324;
    }

    html, body {
      margin: 0;
      width: 100%;
      height: 100%;
      overflow: hidden;
      background: #050510;
      color: #dbeafe;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      -webkit-tap-highlight-color: transparent;
    }

    body {
      display: grid;
      place-items: center;
      background:
        radial-gradient(ellipse at 20% 10%, rgba(56, 189, 248, 0.12), transparent 55%),
        radial-gradient(ellipse at 85% 90%, rgba(168, 85, 247, 0.10), transparent 60%),
        #050510;
    }

    #stage {
      position: relative;
      display: block;
      height: min(100dvh, calc(100dvw * 7 / 4));
      aspect-ratio: 4 / 7;
      max-width: 100dvw;
      padding: clamp(0px, 1.2dvh, 14px);
      border-radius: clamp(0px, 1.8dvh, 22px);
      background: linear-gradient(160deg, #10182e 0%, #060914 70%);
      box-shadow:
        0 0 0 1px var(--accent-soft),
        0 20px 60px rgba(0, 0, 0, 0.55),
        0 0 80px rgba(96, 165, 250, 0.18);
    }

    /* On narrow/portrait viewports the bezel hugs the edges */
    @media (max-aspect-ratio: 4/7) {
      #stage {
        width: 100dvw;
        height: auto;
        padding: 0;
        border-radius: 0;
        box-shadow: none;
      }
    }

    #canvas {
      display: block;
      width: 100% !important;
      height: 100% !important;
      outline: none;
      background: #050510;
      border-radius: clamp(0px, 1.2dvh, 14px);
    }

    #status {
      position: fixed;
      left: 12px;
      bottom: 12px;
      font-size: 12px;
      line-height: 1.4;
      background: rgba(15, 23, 42, 0.72);
      border: 1px solid var(--accent);
      border-radius: 8px;
      padding: 8px 10px;
      pointer-events: none;
    }
  </style>
</head>
<body>
  <div id="stage">
    <canvas id="canvas">Your browser does not support the canvas tag.</canvas>
  </div>
  <div id="status">Loading...</div>

  <script src="godot.js"></script>
  <script>
    const statusEl = document.getElementById('status');
    const canvasEl = document.getElementById('canvas');

    function syncCanvasPixels() {
      const rect = canvasEl.getBoundingClientRect();
      const dpr = Math.min(window.devicePixelRatio || 1, 2);
      canvasEl.width = Math.max(1, Math.round(rect.width * dpr));
      canvasEl.height = Math.max(1, Math.round(rect.height * dpr));
    }
    syncCanvasPixels();
    window.addEventListener('resize', syncCanvasPixels);
    window.addEventListener('orientationchange', syncCanvasPixels);

    const engine = new Engine({
      canvas: canvasEl,
      executable: 'godot',
      mainPack: '__GAME_PACK_CACHE__',
      canvasResizePolicy: 2,
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

sed -i.bak "s|__GAME_PACK_CACHE__|${GAME_PACK_BASENAME}|g" "$SITE_DIR/index.html" && rm -f "$SITE_DIR/index.html.bak"

if grep -q '__GAME_PACK_CACHE__' "$SITE_DIR/index.html"; then
	echo "ERROR: index.html still contains __GAME_PACK_CACHE__ placeholder." >&2
	exit 1
fi
RESOLVED_PACK="$(sed -n "s/.*mainPack:[[:space:]]*'\\([^']*\\)'.*/\\1/p" "$SITE_DIR/index.html")"
if [[ -z "$RESOLVED_PACK" || ! -f "$SITE_DIR/$RESOLVED_PACK" ]]; then
	echo "ERROR: index.html mainPack '${RESOLVED_PACK:-<empty>}' not found in $SITE_DIR" >&2
	exit 1
fi

# Template godot.html still has unreplaced \$GODOT_* placeholders; only custom index.html is valid for this pipeline.
rm -f "$SITE_DIR/godot.html"

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

# itch.io upload alias (see godot/docs/itchio_release.md): same bytes as site zip
ITCH_HTML_ZIP="$REPO_ROOT/dist/hitezero-itch-html.zip"
ITCH_HTML_CACHE_TAG="$(shasum -a 256 "$SITE_DIR/index.html" "$SITE_DIR/$GAME_PACK_BASENAME" | shasum -a 256 | awk '{print substr($1,1,16)}')"
ITCH_HTML_VERSIONED_ZIP="$REPO_ROOT/dist/hitezero-itch-html-layoutfix-${ITCH_HTML_CACHE_TAG}.zip"
mkdir -p "$(dirname "$ITCH_HTML_ZIP")"
cp -f "$SITE_ZIP_PATH" "$ITCH_HTML_ZIP"
cp -f "$SITE_ZIP_PATH" "$ITCH_HTML_VERSIONED_ZIP"

cat <<EOF
Build complete.
- Pack: $PACK_PATH
- Main pack in site: $GAME_PACK_BASENAME
- Site: $SITE_DIR
- Site zip: $SITE_ZIP_PATH
- Itch upload copy: $ITCH_HTML_ZIP
- Itch versioned upload copy: $ITCH_HTML_VERSIONED_ZIP
- Serve: python3 -m http.server $PORT --directory "$SITE_DIR"
- URL: http://127.0.0.1:$PORT/index.html
EOF
