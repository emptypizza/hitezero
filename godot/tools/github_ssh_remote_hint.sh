#!/usr/bin/env bash
# Prints commands to switch origin from https://github.com/... to SSH (avoids HTTPS 401 in Cursor / PAT prompts).
set -euo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null)" || {
	echo "Run this from inside the git repository." >&2
	exit 1
}
u="$(git remote get-url origin 2>/dev/null)" || {
	echo "No origin remote configured." >&2
	exit 1
}
case "$u" in
https://*github.com/* | http://*github.com/*) ;;
*)
	echo "Origin is not an https GitHub URL: $u"
	echo "Nothing to convert. For 401 on push, ensure a PAT/SSH key is configured for GitHub."
	exit 0
	;;
esac
path="${u#*github.com/}"
path="${path%.git}"
echo "Current origin: $u"
echo ""
echo "HTTPS push can fail with 401 if no token is stored (e.g. Cursor askpass). To use SSH instead:"
echo "  git remote set-url origin git@github.com:${path}.git"
echo "  ssh -T git@github.com"
echo "The second command should greet you by GitHub username once your SSH key is added to GitHub."
