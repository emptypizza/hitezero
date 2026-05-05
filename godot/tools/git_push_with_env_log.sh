#!/usr/bin/env bash
# Logs env then git push (same shell as push — works even when pre-push never runs).
set -euo pipefail
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || {
	echo "Run from inside the git repository." >&2
	exit 1
}
bash "$ROOT/godot/tools/log_push_env_to_debug_log.sh" "git_push_with_env_log.sh" "pre_push_env_wrap"
exec git push "$@"
