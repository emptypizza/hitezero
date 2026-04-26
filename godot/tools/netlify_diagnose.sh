#!/usr/bin/env bash
# Writes NDJSON debug lines for Netlify 404 triage (session 2272c4).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LOG="$ROOT/.cursor/debug-2272c4.log"
TS="$(python3 -c 'import time; print(int(time.time() * 1000))')"
mkdir -p "$(dirname "$LOG")"
count_tracked="$(git -C "$ROOT" ls-files -- "dist/godot-web/site_nothreads" 2>/dev/null | wc -l | tr -d ' ')"
index_local=0
[[ -f "$ROOT/dist/godot-web/site_nothreads/index.html" ]] && index_local=1
# #region agent log
printf '%s\n' "{\"sessionId\":\"2272c4\",\"hypothesisId\":\"H1\",\"location\":\"netlify_diagnose.sh\",\"message\":\"publish_tracked_file_count\",\"data\":{\"count\":$count_tracked},\"timestamp\":$TS}" >>"$LOG"
printf '%s\n' "{\"sessionId\":\"2272c4\",\"hypothesisId\":\"H1\",\"location\":\"netlify_diagnose.sh\",\"message\":\"local_index_present\",\"data\":{\"present\":$index_local},\"timestamp\":$TS}" >>"$LOG"
# #endregion agent log
