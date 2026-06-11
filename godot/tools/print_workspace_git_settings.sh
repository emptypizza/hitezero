#!/usr/bin/env bash
# Prints .vscode/settings.json for pasting into Cursor/VS Code User settings when git push is blocked before pull.
set -euo pipefail
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || {
	echo "Run from inside the git repository." >&2
	exit 1
}
f="$ROOT/.vscode/settings.json"
if [[ ! -f "$f" ]]; then
	echo "Missing $f" >&2
	exit 1
fi
echo "Merge these into Cursor → Settings → Open User Settings (JSON), then reload + Kill All Terminals:"
echo
cat "$f"
