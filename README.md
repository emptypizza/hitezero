# HiteZero

HiteZero is now maintained as a Godot 4 project.

## Project Layout
- `godot/` - main game project
- `godot/tools/build_web.sh` - reproducible web build script
- `godot/tools/build_and_serve_web.sh` - build then start `http.server` in one command (safest local loop)
- `godot/tools/dev_doctor.sh` - print git origin / 401 hints, tool PATH checks, web commands
- `godot/tools/git_push_interactive.sh` - `git push` with `GIT_ASKPASS` unset (Cursor 401 / askpass workaround)
- `godot/tools/erase_github_https_keychain.sh` - macOS: clear stale **github.com** HTTPS credentials from Keychain (401 after PAT expired)
- `godot/tools/log_push_env_to_debug_log.sh` - append Git/Cursor env to `.cursor/debug-2272c4.log` (run right before `git push`)
- `godot/tools/enable_repo_hooks.sh` - set `core.hooksPath` to `.githooks/` (optional **pre-push** log; may not run if push fails at credential)
- `build/godot-web/` - default local output (gitignored)
- `dist/godot-web/site_nothreads/` - committed web bundle used for Netlify when present on the deployed branch

## Run In Godot
Open `godot/project.godot` in Godot 4.6+.

## Build For Web
```bash
bash "godot/tools/build_web.sh"
```

The script exports the game pack, assembles a no-threads browser runtime, and writes output to `build/godot-web/` by default.

**Easiest local preview (one command, no paste traps):**

```bash
bash "godot/tools/build_and_serve_web.sh" "dist/godot-web"
```

Or from the repo root: `make godot-web-dev` (override port: `PORT=9000 make godot-web-dev`).

For Netlify, build into the repo-root publish folder (two lines is fine if you prefer):

```bash
bash "godot/tools/build_web.sh" "dist/godot-web"
python3 -m http.server 8123 --directory "dist/godot-web/site_nothreads"
```

Do not append `python3` to the same line as `build_web.sh`’s path. The build script **refuses** a merged path (`webpython`), **extra arguments** (a pasted `python3 -m http.server` tail), or use **`make godot-web`** then **`make godot-web-serve`**.

## Netlify
Configuration is in `netlify.toml` at the repository root (`publish = "dist/godot-web/site_nothreads"`).

**GitHub must contain the built folder.** If your fixes exist only on your laptop, Netlify will keep serving an old tree or return “Page not found”. Push the branch that includes `dist/godot-web/site_nothreads/` (for example `neon-style-7cc31`), then in Netlify set **Site configuration → Build & deploy → Production branch** to that same branch (or merge into `main` and deploy `main`).

Check local state:

```bash
bash "godot/tools/netlify_diagnose.sh"
# Inspect .cursor/debug-2272c4.log for branch_push_state.unpushed_commits (should be 0 after push)
```

**Deploy without git push** (uploads from your machine): install the [Netlify CLI](https://docs.netlify.com/cli/get-started/), link the site once, then from the repo root:

```bash
netlify deploy --prod --dir dist/godot-web/site_nothreads
```

### If `git push` fails (password prompt, **401**, or “Invalid username or token”)
GitHub no longer accepts account passwords over HTTPS. Cursor/VS Code can inject **`GIT_ASKPASS`** into the **integrated** terminal (stack: **`askpass-main.js`**), which then returns no valid token and GitHub responds **401**.

This repo’s **`.vscode/settings.json`** turns off **`git.terminalAuthentication`**, **`git.useIntegratedAskPass`**, **`git.githubAuthentication`** (VS Code–documented name), and **`github.gitAuthentication`** (GitHub extension) so the integrated terminal stops using the editor GitHub/askpass path that shows **`askpass-main.js`** in 401 traces. **Trust this workspace** if prompted. If you **cannot pull** yet, run `bash "godot/tools/print_workspace_git_settings.sh"` and merge the output into **User** settings JSON. **Reload the window**, run **Terminal: Kill All Terminals**, open **one new** terminal (old tabs can keep **`GIT_ASKPASS`**), run `bash godot/tools/dev_doctor.sh` to confirm **`GIT_ASKPASS`** is `<unset>`, then **`git push`**.

Your clone may still use **`https://…@github.com/…`**; you need a stored PAT or helper. If 401 persists:

Quick copy-paste for **SSH** (after your SSH key is on GitHub):

```bash
bash "godot/tools/github_ssh_remote_hint.sh"
```

If push fails inside Cursor with **`askpass-main.js`** in the trace, run from **Terminal.app**:  
`bash "godot/tools/git_push_interactive.sh" -u origin <branch>` — use your GitHub username and a **PAT** as the password when prompted.

**Push env log** (for debugging **401** / **`askpass-main.js`**): in the **same terminal** you use for push, run **`bash "godot/tools/log_push_env_to_debug_log.sh"`** immediately before **`git push`** (always writes **`.cursor/debug-2272c4.log`**). Optional: **`bash "godot/tools/enable_repo_hooks.sh"`** installs a **pre-push** hook that logs too — but Git may fail **before** that hook runs during credential errors, so prefer the explicit **`log_push_env_to_debug_log.sh`** line first.

1. **GitHub CLI** (simplest on macOS): `brew install gh && gh auth login`, then run `git push` from the same terminal (or configure Git to use `gh` as credential helper).
2. **SSH**: add an SSH key to your GitHub account, run the hint script above (or `git remote set-url origin git@github.com:emptypizza/hitezero.git`), then `git push -u origin <branch>`.
3. **HTTPS + PAT**: create a *personal access token* with `repo` scope and use it **as the password** when Git prompts, or use [Git Credential Manager](https://github.com/git-ecosystem/git-credential-manager). On macOS, if **`GIT_ASKPASS`** is already unset but you still get **401**, the Keychain may hold an old password: run `bash "godot/tools/erase_github_https_keychain.sh"` and push again with a **new PAT**.

Until `git fetch` shows `origin/neon-style-7cc31` **past** commit `7a40cd5`, Netlify will not receive `netlify.toml` or `dist/godot-web/site_nothreads/`, and the site can keep showing Netlify’s “Page not found”.
