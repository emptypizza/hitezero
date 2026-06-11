extends Node

# Mobile/web haptic feedback (autoload: Haptics).
#
# Branches by platform:
#   • Web   → navigator.vibrate(ms) via JavaScriptBridge (Android Chrome etc.).
#   • Native → Input.vibrate_handheld(ms) (Android/iOS; harmless no-op on desktop).
#   • Unsupported / disabled → silent no-op.
#
# Presets map game-feel weight to pulse length:
#   light  — every block/boss hit
#   medium — block destruction / tray bounce
#   heavy  — heart loss / boss defeat / POW
#
# A short throttle prevents the "constant buzz" failure mode when many light
# hits land in the same frame (spread/blast); medium & heavy bypass it.

const LIGHT_MS := 12
const MEDIUM_MS := 22
const HEAVY_MS := 42
const MIN_INTERVAL_MS := 16   # min gap between throttled (light) pulses

var enabled: bool = true

var _is_web: bool = false
var _web_supported: bool = false
var _last_ms: int = -100000


func _ready() -> void:
	_is_web = OS.has_feature("web")
	if _is_web:
		# Feature-detect navigator.vibrate once so we never throw on iOS Safari etc.
		var res: Variant = JavaScriptBridge.eval(
			"(typeof navigator !== 'undefined' && typeof navigator.vibrate === 'function')",
			true
		)
		_web_supported = bool(res) if res != null else false


func set_enabled(on: bool) -> void:
	enabled = on


func is_supported() -> bool:
	return _web_supported if _is_web else true


func light() -> void:
	_vibrate(LIGHT_MS, true)


func medium() -> void:
	_vibrate(MEDIUM_MS, false)


func heavy() -> void:
	_vibrate(HEAVY_MS, false)


func _vibrate(ms: int, throttle: bool) -> void:
	if not enabled or ms <= 0:
		return
	var now := Time.get_ticks_msec()
	if throttle and now - _last_ms < MIN_INTERVAL_MS:
		return
	_last_ms = now
	if _is_web:
		if _web_supported:
			JavaScriptBridge.eval("navigator.vibrate(%d);" % ms, true)
	else:
		Input.vibrate_handheld(ms)
