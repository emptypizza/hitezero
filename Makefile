# Web export: `make godot-web-dev` builds then serves; or `make godot-web` then `make godot-web-serve`.
.PHONY: help godot-web godot-web-serve godot-web-dev

REPO_ROOT := $(abspath .)
GODOT_WEB_OUT := $(REPO_ROOT)/dist/godot-web
SITE := $(GODOT_WEB_OUT)/site_nothreads
PORT ?= 8123

help:
	@echo "godot-web-dev    - build then serve (one flow; PORT=$(PORT))"
	@echo "godot-web        - Godot web export to dist/godot-web"
	@echo "godot-web-serve  - static server for dist/godot-web/site_nothreads (PORT=$(PORT))"

godot-web:
	bash "$(REPO_ROOT)/godot/tools/build_web.sh" "$(GODOT_WEB_OUT)"

godot-web-serve:
	python3 -m http.server $(PORT) --directory "$(SITE)"

godot-web-dev:
	PORT=$(PORT) bash "$(REPO_ROOT)/godot/tools/build_and_serve_web.sh" "$(GODOT_WEB_OUT)"
