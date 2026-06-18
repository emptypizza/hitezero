extends CanvasLayer
## RevivePrompt — minimal "watch ad to revive?" offer (v1.1).
##
## Self-contained: builds its own UI in code and frees itself after a choice or
## timeout. Inert in v1.0 — game_root only instances this when a rewarded ad is
## actually ready (AdsManager.is_revive_available() == true), which requires
## AdsManager.ADS_ENABLED == true.
##
## NOTE (juice-smith handoff): this is functional placeholder UI. Visual polish
## — fonts, heart icon, button styling, the "−1s" tick animation — is a separate
## pass once the loop is verified on device.

signal chosen(accepted: bool)

var _seconds: float = 6.0
var _on_yes: Callable
var _on_no: Callable
var _timer_label: Label
var _decided := false


## Call BEFORE adding to the tree.
func setup(seconds: float, on_yes: Callable, on_no: Callable) -> void:
	_seconds = maxf(1.0, seconds)
	_on_yes = on_yes
	_on_no = on_no


func _ready() -> void:
	layer = 100

	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.66)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	dim.add_child(box)

	var title := Label.new()
	title.text = "CONTINUE?"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	_timer_label = Label.new()
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_timer_label)

	var yes := Button.new()
	yes.text = "WATCH AD  ·  REVIVE (+1 ♥)"
	yes.pressed.connect(_accept)
	box.add_child(yes)

	var no := Button.new()
	no.text = "NO THANKS"
	no.pressed.connect(_decline)
	box.add_child(no)

	_update_label()


func _process(delta: float) -> void:
	if _decided:
		return
	_seconds -= delta
	if _seconds <= 0.0:
		_decline()  # auto-decline on timeout
	else:
		_update_label()


func _update_label() -> void:
	_timer_label.text = "Revive your run  ·  %ds" % int(ceil(_seconds))


func _accept() -> void:
	if _decided:
		return
	_decided = true
	chosen.emit(true)
	if _on_yes.is_valid():
		_on_yes.call()
	queue_free()


func _decline() -> void:
	if _decided:
		return
	_decided = true
	chosen.emit(false)
	if _on_no.is_valid():
		_on_no.call()
	queue_free()
