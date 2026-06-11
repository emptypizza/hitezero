#!/usr/bin/env bash
# Run git push without Cursor/VS Code askpass (401 stack: .../askpass-main.js).
# -c core.askPass= forces terminal prompts when combined with GIT_TERMINAL_PROMPT=1.
# Use from Terminal.app if embedded terminal still injects askpass: PAT as "Password".
set -euo pipefail
exec env GIT_TERMINAL_PROMPT=1 \
	-u GIT_ASKPASS \
	-u SSH_ASKPASS \
	-u SSH_ASKPASS_REQUIRE \
	git -c core.askPass= push "$@"
