extends SceneTree
# Windowed visual smoke for ItemSystem.draw_orbs_into() (Slice 1).
#
# The draw path never runs under --headless (dummy renderer), so this opens a
# real window, parks a persistent orb on-screen, lets the engine render a few
# frames, and saves a screenshot. Run it WITHOUT --headless:
#
#   godot --path godot -s tools/smoke_item_draw.gd -- --out=/tmp/smoke_item_draw.png
#
# Pass = it saves a PNG with a visible glowing orb and no draw-time errors.

func _initialize() -> void:
	_run()


func _arg_value(key: String, fallback: String) -> String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with(key + "="):
			return a.substr(key.length() + 1)
	return fallback


func _run() -> void:
	var out_path := _arg_value("--out", "user://smoke_item_draw.png")
	var gc = load("res://scripts/game_constants.gd")

	var game: Node = load("res://scenes/game.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame

	# Launching from a non-GUI shell triggers the focus-out soft pause, whose dim
	# overlay would obscure the orb — force the run live for the capture.
	game._set_paused(false)
	game.game_paused = false

	# Park three persistent orbs in a clear band (left/centre/right), away from the
	# paddle and HUD text. _draw() always renders orbs; update_orbs() only runs in
	# SHOOTING, so in AIMING they stay put.
	for ox in [110.0, 200.0, 290.0]:
		game._items.orbs.append({
			"x": ox, "y": 470.0, "vy": 0.0,
			"type": gc.ItemType.BLAST, "life": 999.0, "pulse": 0.4,
		})
	game.queue_redraw()

	for _i in range(8):
		game.game_paused = false
		await process_frame

	var img: Image = root.get_texture().get_image()
	img.save_png(out_path)
	print("SAVED ", img.get_width(), "x", img.get_height(), " -> ", out_path)
	quit(0)
