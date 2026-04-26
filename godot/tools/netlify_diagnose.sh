#!/usr/bin/env bash
# Writes NDJSON debug lines for Netlify 404 triage (session 2272c4).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GIT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
ROOT="${GIT_ROOT:-$(cd "$SCRIPT_DIR/../.." && pwd)}"
LOG="$ROOT/.cursor/debug-2272c4.log"
TS="$(python3 -c 'import time; print(int(time.time() * 1000))')"
mkdir -p "$(dirname "$LOG")"
count_tracked="$(git -C "$ROOT" ls-files -- "dist/godot-web/site_nothreads" 2>/dev/null | wc -l | tr -d ' ')"
index_local=0
[[ -f "$ROOT/dist/godot-web/site_nothreads/index.html" ]] && index_local=1
branch="$(git -C "$ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "?")"
unpushed=-1
if git -C "$ROOT" rev-parse --verify "origin/$branch" >/dev/null 2>&1; then
  unpushed="$(git -C "$ROOT" rev-list --count "origin/$branch..HEAD" 2>/dev/null || echo -1)"
fi
remote_tip="$(git -C "$ROOT" rev-parse --short "origin/$branch" 2>/dev/null || echo none)"
main_has_netlify=0
git -C "$ROOT" cat-file -e "main:netlify.toml" 2>/dev/null && main_has_netlify=1 || true
# #region agent log
printf '%s\n' "{\"sessionId\":\"2272c4\",\"hypothesisId\":\"H1\",\"location\":\"netlify_diagnose.sh\",\"message\":\"publish_tracked_file_count\",\"data\":{\"count\":$count_tracked},\"timestamp\":$TS}" >>"$LOG"
printf '%s\n' "{\"sessionId\":\"2272c4\",\"hypothesisId\":\"H1\",\"location\":\"netlify_diagnose.sh\",\"message\":\"local_index_present\",\"data\":{\"present\":$index_local},\"timestamp\":$TS}" >>"$LOG"
printf '%s\n' "{\"sessionId\":\"2272c4\",\"hypothesisId\":\"H8\",\"location\":\"netlify_diagnose.sh\",\"message\":\"branch_push_state\",\"data\":{\"branch\":\"$branch\",\"unpushed_commits\":$unpushed,\"origin_tip\":\"$remote_tip\",\"main_has_netlify\":$main_has_netlify},\"timestamp\":$TS}" >>"$LOG"
# #endregion agent log
