#!/usr/bin/env bash
# Point Git at repo .githooks/ so pre-push logs debug NDJSON (see .githooks/pre-push).
set -euo pipefail
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || {
	echo "Run from inside the git repository." >&2
	exit 1
}
git config core.hooksPath "$ROOT/.githooks"
echo "Set core.hooksPath to $ROOT/.githooks"
echo "Next git push will append a line to .cursor/debug-2272c4.log (opt out: HITEZERO_SKIP_PUSH_LOG=1)."
