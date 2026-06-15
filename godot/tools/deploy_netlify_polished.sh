#!/usr/bin/env bash
# deploy_netlify_polished.sh — 웹 빌드에 마무리 폴리싱(파비콘·OG·메타·/privacy)을
# 주입한 publish 폴더를 만든다. 그 폴더를 Netlify에 올리면 끝.
#
# 왜 스크립트?: Cowork 샌드박스는 godot.wasm(37MB) 빌드가 마운트로 안 닿을 때가 있어
# 재배포를 못 함. 이 스크립트는 "실제 빌드 파일이 있는 환경"(터미널 에이전트/로컬)에서
# 한 줄로 폴리싱+publish 준비를 끝낸다. Godot 재export 불필요 — 기존 빌드 그대로 쓴다.
#
# 사용:
#   bash godot/tools/deploy_netlify_polished.sh <web_build_dir> [out_dir]
# 예:
#   bash godot/tools/deploy_netlify_polished.sh dist/godot-web/site_nothreads
#   bash godot/tools/deploy_netlify_polished.sh build/godot-web/site_nothreads dist/netlify-polished
#
# 그 다음(둘 중 하나):
#   A) app.netlify.com/drop 에 <out_dir> 폴더를 드래그   (자격증명 불필요, 제일 확실)
#   B) netlify deploy --prod --dir <out_dir>             (netlify CLI 로그인 시)
#   C) Netlify MCP: deploy-site로 받은 npx 명령을 <out_dir>에서 실행
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BUILD_DIR="${1:-}"
OUT_DIR="${2:-$REPO_ROOT/dist/netlify-polished}"

# --- 가드: 빈 인자 금지(빈 변수→루트 복사 사고 방지) ---
if [[ -z "$BUILD_DIR" ]]; then
  echo "ERROR: web build dir 인자 필요. 예: bash $0 dist/godot-web/site_nothreads" >&2; exit 1
fi
[[ -d "$BUILD_DIR" ]] || { echo "ERROR: '$BUILD_DIR' 디렉터리 없음" >&2; exit 1; }
[[ -f "$BUILD_DIR/index.html" && -f "$BUILD_DIR/godot.wasm" ]] || {
  echo "ERROR: '$BUILD_DIR'에 index.html/godot.wasm 없음 — 진짜 웹 빌드 폴더인지 확인" >&2; exit 1; }

echo "build_dir=$BUILD_DIR"; echo "out_dir=$OUT_DIR"
rm -rf "$OUT_DIR"; mkdir -p "$OUT_DIR/privacy"
cp -r "$BUILD_DIR"/. "$OUT_DIR"/

# --- 폴리싱 자산 복사 (store_assets/web/) ---
WEB_ASSETS="$REPO_ROOT/store_assets/web"
if [[ -d "$WEB_ASSETS" ]]; then
  cp "$WEB_ASSETS"/favicon-*.png "$OUT_DIR"/ 2>/dev/null || true
  cp "$WEB_ASSETS"/og_image_1200x630.png "$OUT_DIR"/ 2>/dev/null || true
  cp "$WEB_ASSETS"/manifest.webmanifest "$OUT_DIR"/ 2>/dev/null || true   # P8: PWA manifest
else
  echo "WARN: $WEB_ASSETS 없음 — 파비콘/OG 생략(생성: ai 파이프 또는 store_assets/web)" >&2
fi
# privacy 페이지
[[ -f "$REPO_ROOT/store_assets/privacy.html" ]] && cp "$REPO_ROOT/store_assets/privacy.html" "$OUT_DIR/privacy/index.html"

# --- netlify.toml (wasm MIME + 캐시 헤더) ---
cat > "$OUT_DIR/netlify.toml" <<'TOML'
[build]
  publish = "."
[[headers]]
  for = "/*.wasm"
  [headers.values]
    Content-Type = "application/wasm"
    Cache-Control = "public, max-age=31536000, immutable"
[[headers]]
  for = "/index.html"
  [headers.values]
    Cache-Control = "public, max-age=0, must-revalidate"
[[headers]]
  for = "/manifest.webmanifest"
  [headers.values]
    Content-Type = "application/manifest+json; charset=utf-8"
    Cache-Control = "public, max-age=0, must-revalidate"
TOML

# --- index.html <head>에 폴리싱 스니펫 주입(이미 있으면 스킵) ---
python3 - "$OUT_DIR/index.html" <<'PY'
import sys, io
p = sys.argv[1]
html = io.open(p, encoding="utf-8").read()
if "og_image_1200x630.png" in html:
    print("polish snippet already present, skip"); raise SystemExit
snippet = '''<!-- HiteZero web polish -->
<link rel="icon" type="image/png" sizes="32x32" href="favicon-32.png">
<link rel="icon" type="image/png" sizes="16x16" href="favicon-16.png">
<link rel="apple-touch-icon" sizes="180x180" href="favicon-180.png">
<meta name="description" content="HiteZero - aim, ricochet knives, and smash neon blocks. One-handed neon arcade. Play free in browser.">
<meta property="og:type" content="website">
<meta property="og:title" content="HiteZero - Neon Knife Arcade">
<meta property="og:description" content="Aim, ricochet knives, smash neon blocks. One-handed arcade - play free in browser.">
<meta property="og:url" content="https://hitezero.netlify.app/">
<meta property="og:image" content="https://hitezero.netlify.app/og_image_1200x630.png">
<meta property="og:image:width" content="1200">
<meta property="og:image:height" content="630">
<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:title" content="HiteZero - Neon Knife Arcade">
<meta name="twitter:image" content="https://hitezero.netlify.app/og_image_1200x630.png">
<link rel="manifest" href="manifest.webmanifest">
<meta name="mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
<meta name="apple-mobile-web-app-title" content="HiteZero">
'''
i = html.lower().find("</head>")
html = (html[:i] + snippet + html[i:]) if i != -1 else (snippet + html)
io.open(p, "w", encoding="utf-8").write(html)
print("injected polish snippet into index.html")
PY

echo ""
echo "=== DONE: polished publish folder ready ==="
echo "  $OUT_DIR"
echo "다음 중 하나로 배포:"
echo "  A) app.netlify.com/drop 에 위 폴더 드래그"
echo "  B) netlify deploy --prod --dir \"$OUT_DIR\""
echo "  C) Netlify MCP deploy-site의 npx 명령을 위 폴더에서 실행(site_id 742653ed-62bd-4e8b-bcd0-a85cc36ac4ed)"
echo "배포 후 확인: https://hitezero.netlify.app (탭 파비콘) · /privacy · OG 미리보기"
