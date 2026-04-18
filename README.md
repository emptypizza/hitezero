# HiteZero

HiteZero is now maintained as a Godot 4 project.

## Project Layout
- `godot/` - main game project
- `godot/tools/build_web.sh` - reproducible web build script
- `build/godot-web/` - generated web build output (ignored)

## Run In Godot
Open `godot/project.godot` in Godot 4.6+.

## Build For Web
```bash
bash "godot/tools/build_web.sh"
```

The script exports the game pack, assembles a no-threads browser runtime, and writes output to `build/godot-web/`.
