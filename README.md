# HiteZero

HiteZero is now maintained as a Godot 4 project.

## Project Layout
- `godot/` - main game project
- `godot/tools/build_web.sh` - reproducible web build script
- `build/godot-web/` - default local output (gitignored)
- `dist/godot-web/site_nothreads/` - committed web bundle used for Netlify when present on the deployed branch

## Run In Godot
Open `godot/project.godot` in Godot 4.6+.

## Build For Web
```bash
bash "godot/tools/build_web.sh"
```

The script exports the game pack, assembles a no-threads browser runtime, and writes output to `build/godot-web/` by default. For Netlify, build into the repo-root publish folder:

```bash
bash "godot/tools/build_web.sh" "dist/godot-web"
```

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
