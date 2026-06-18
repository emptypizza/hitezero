extends Node
## AdsManager — v1.1 rewarded-ads facade (autoload).
##
## SAFETY CONTRACT (protects the v1.0 clean launch):
##   • ADS_ENABLED defaults to false → this autoload is a pure no-op.
##   • This script references NO AdMob/addon symbols, so the project compiles
##     and ships IDENTICALLY whether or not the AdMob addon is installed.
##   • export_presets.cfg is intentionally NOT modified (no INTERNET permission,
##     no SDK) — the v1.0 submission profile stays "fully offline / no ads".
##
## v1.1 ACTIVATION (full steps: godot/docs/v1.1_ads_implementation.md):
##   1. Install the godot-admob addon + enable the Gradle (custom Android) build.
##   2. Rename scripts/ads_backend.gd.txt → scripts/ads_backend.gd.
##   3. Add an `Admob` node to the main scene, group "admob", set the rewarded
##      ad-unit IDs (use Google TEST IDs first).
##   4. Flip ADS_ENABLED = true below.
##   5. Complete the 6 store-submission changes before publishing (see doc).

const ADS_ENABLED := false  ## v1.1 master switch — KEEP false for the v1.0 build.
const BACKEND_PATH := "res://scripts/ads_backend.gd"  ## exists only after v1.1 activation.

var _backend: Node = null


func _ready() -> void:
	if not ADS_ENABLED:
		return  # v1.0 path: do absolutely nothing.
	if not ResourceLoader.exists(BACKEND_PATH):
		push_warning("AdsManager: ADS_ENABLED but ads_backend.gd not activated; staying disabled.")
		return
	var backend_script: Script = load(BACKEND_PATH)
	if backend_script == null:
		push_warning("AdsManager: failed to load ads backend; staying disabled.")
		return
	_backend = backend_script.new()
	add_child(_backend)


## True only when a rewarded "revive" ad is fully loaded and ready to show.
## Always false in the v1.0 no-op state.
func is_revive_available() -> bool:
	if not ADS_ENABLED or _backend == null:
		return false
	return bool(_backend.call("is_revive_ready"))


## Show the rewarded revive ad.
##   on_reward()        — called if (and only if) the user earns the reward.
##   on_finished(bool)  — always called when the ad flow ends; arg = reward granted.
## In the v1.0 no-op state this immediately calls on_finished(false).
func request_revive(on_reward: Callable, on_finished: Callable) -> void:
	if not is_revive_available():
		if on_finished.is_valid():
			on_finished.call(false)
		return
	_backend.call("show_revive", on_reward, on_finished)
