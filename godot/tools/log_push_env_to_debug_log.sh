#!/usr/bin/env bash
# Append one NDJSON line to .cursor/debug-2272c4.log with current Git/Cursor env (for 401 / askpass-main.js).
# Run in the same terminal immediately before: git push
# Args: $1 = location string (default script name), $2 = message (default manual_env)
set -euo pipefail
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || {
	echo "Run from inside the git repository." >&2
	exit 1
}
LOG="$ROOT/.cursor/debug-2272c4.log"
mkdir -p "$(dirname "$LOG")"
loc="${1:-godot/tools/log_push_env_to_debug_log.sh}"
msg="${2:-manual_env}"
ts=$(($(date +%s) * 1000))
ap_len=0
[[ -n "${GIT_ASKPASS:-}" ]] && ap_len=${#GIT_ASKPASS}
ap_set=false
[[ -n "${GIT_ASKPASS:-}" ]] && ap_set=true
vs_main=false
[[ -n "${VSCODE_GIT_ASKPASS_MAIN:-}" ]] && vs_main=true
tp="${TERM_PROGRAM:-}"
tp="${tp//\\/\\\\}"
tp="${tp//\"/\\\"}"
remote_url="$(git remote get-url origin 2>/dev/null || true)"
ru="${remote_url//\\/\\\\}"
ru="${ru//\"/\\\"}"
printf '{"sessionId":"2272c4","timestamp":%s,"hypothesisId":"H-push-env","location":"%s","message":"%s","data":{"GIT_ASKPASS_set":%s,"GIT_ASKPASS_len":%s,"VSCODE_GIT_ASKPASS_MAIN_set":%s,"TERM_PROGRAM":"%s","origin":"%s"}}\n' \
	"$ts" "$loc" "$msg" "$ap_set" "$ap_len" "$vs_main" "$tp" "$ru" >>"$LOG"

export H_DOC_LOG="$LOG" H_DOC_LOC="$loc" H_DOC_MSG="${msg}_py"
python3 -c "
import json, os, time
keys = (
    'GIT_ASKPASS', 'SSH_ASKPASS', 'SSH_ASKPASS_REQUIRE',
    'VSCODE_GIT_ASKPASS_MAIN', 'VSCODE_GIT_ASKPASS_NODE',
    'VSCODE_GIT_IPC_HANDLE', 'TERM_PROGRAM',
)
data = {k: os.environ.get(k, '') for k in keys}
data['GIT_ASKPASS_set'] = bool(os.environ.get('GIT_ASKPASS'))
payload = {
    'sessionId': '2272c4',
    'timestamp': int(time.time() * 1000),
    'hypothesisId': 'H-push-env',
    'location': os.environ.get('H_DOC_LOC', ''),
    'message': os.environ.get('H_DOC_MSG', ''),
    'data': data,
}
with open(os.environ['H_DOC_LOG'], 'a', encoding='utf-8') as f:
    f.write(json.dumps(payload, ensure_ascii=False) + '\n')
" 2>/dev/null || true
