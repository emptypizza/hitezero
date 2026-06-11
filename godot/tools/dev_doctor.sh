#!/usr/bin/env bash
# One-shot local diagnostics: git remote (401 hints), Godot/python on PATH, web preview commands.
set -euo pipefail
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || {
	echo "Not a git repository (run from hitezero clone)." >&2
	exit 1
}
cd "$ROOT"
TOOLS="$ROOT/godot/tools"

echo "=== HiteZero dev doctor ==="
echo
echo "-- Git --"
branch="$(git branch --show-current 2>/dev/null || echo "?")"
echo "branch: $branch"
o="$(git remote get-url origin 2>/dev/null || true)"
echo "origin: ${o:-<none>}"
hp="$(git config core.hooksPath 2>/dev/null || true)"
echo "core.hooksPath: ${hp:-<default; push debug hook inactive>}"
if [[ -z "${hp:-}" ]]; then
	echo "  Tip: bash \"$ROOT/godot/tools/enable_repo_hooks.sh\" — optional pre-push log (may not run if push fails at credential)"
fi
echo "  Push debug: bash \"$ROOT/godot/tools/log_push_env_to_debug_log.sh\" then git push (same terminal)"
helper="$(git config --get credential.helper 2>/dev/null || true)"
echo "credential.helper: ${helper:-<none>}"
echo "GIT_ASKPASS (this shell): ${GIT_ASKPASS:-<unset>}"
if [[ -n "${GIT_ASKPASS:-}" ]]; then
	echo "  ^ Cursor/VS Code often set this; it triggers askpass-main.js on push (see your 401 stack trace)."
	echo "  Reload window, run Terminal: Kill All Terminals, open a new terminal; ensure .vscode/settings.json disables git terminal auth."
fi
case "$o" in
https://*github.com/* | http://*github.com/*)
	echo
	echo "HTTPS GitHub remote: push may return 401 if no PAT/credential helper."
	echo "Cursor often sets GIT_ASKPASS (stack: .../askpass-main.js); try:"
	echo "  0) bash \"$TOOLS/print_workspace_git_settings.sh\"  # paste into User JSON if you cannot pull .vscode yet"
	echo "  1) gh auth login && gh auth setup-git"
	echo "  2) bash \"$TOOLS/github_ssh_remote_hint.sh\"  # SSH set-url"
	echo "  3) bash \"$TOOLS/git_push_interactive.sh\"  # Terminal PAT prompt (use outside Cursor if needed)"
	echo "  3b) bash \"$TOOLS/git_push_with_env_log.sh\" -u origin <branch>  # logs env to .cursor/debug-2272c4.log then pushes"
	if [[ "$(uname -s)" == "Darwin" ]] && [[ "${helper:-}" == *osxkeychain* ]]; then
		echo "  4) If GIT_ASKPASS is <unset> but push still 401: stale keychain password —"
		echo "     bash \"$TOOLS/erase_github_https_keychain.sh\"  then push again with a fresh PAT"
	fi
	;;
esac
unpushed="$(git rev-list --count "@{upstream}..HEAD" 2>/dev/null || echo "?")"
if [[ "$unpushed" != "?" ]] && [[ "${unpushed:-0}" -gt 0 ]] 2>/dev/null; then
	echo "unpushed commits (vs upstream): $unpushed"
fi

# #region agent log
DEBUG_LOG="$ROOT/.cursor/debug-2272c4.log"
mkdir -p "$(dirname "$DEBUG_LOG")"
export H_DOC_LOG="$DEBUG_LOG" H_DOC_BRANCH="$branch" H_DOC_ORIGIN="${o:-}" H_DOC_HELPER="${helper:-}"
python3 -c "
import json, os, time
log = os.environ['H_DOC_LOG']
payload = {
  'sessionId': '2272c4',
  'timestamp': int(time.time() * 1000),
  'location': 'dev_doctor.sh',
  'message': 'git_env',
  'hypothesisId': 'H-git',
  'data': {
    'branch': os.environ.get('H_DOC_BRANCH', ''),
    'origin': os.environ.get('H_DOC_ORIGIN', ''),
    'credential_helper': os.environ.get('H_DOC_HELPER', ''),
    'GIT_ASKPASS_set': bool(os.environ.get('GIT_ASKPASS')),
    'GIT_ASKPASS_tail': (os.environ.get('GIT_ASKPASS') or '')[-48:],
  },
}
with open(log, 'a', encoding='utf-8') as f:
  f.write(json.dumps(payload, ensure_ascii=False) + '\n')
" 2>/dev/null || true
# #endregion

echo
echo "-- Tools --"
if command -v godot >/dev/null 2>&1; then
	echo "godot: $(godot --version 2>/dev/null | head -1 || echo ok)"
else
	echo "godot: not on PATH (install Godot 4.6+ and enable CLI)"
fi
if command -v python3 >/dev/null 2>&1; then
	echo "python3: $(command -v python3)"
else
	echo "python3: not on PATH"
fi

echo
echo "-- Web preview --"
echo "  make godot-web-dev"
echo "  # or: bash \"$TOOLS/build_and_serve_web.sh\" dist/godot-web"
