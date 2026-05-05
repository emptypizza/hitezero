#!/usr/bin/env bash
# Remove cached https://github.com credentials from macOS Keychain.
# Use when push still returns 401 after GIT_ASKPASS is fixed (stale password / old PAT).
set -euo pipefail
if [[ "$(uname -s)" != "Darwin" ]]; then
	echo "This script only applies to macOS (git credential-osxkeychain)." >&2
	exit 1
fi
printf 'host=github.com\nprotocol=https\n\n' | git credential-osxkeychain erase
echo "Erased github.com HTTPS credential from the keychain (if it existed)."
echo "Next git push over HTTPS should prompt again — use a personal access token as the password."
