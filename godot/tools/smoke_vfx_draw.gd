extends SceneTree
# Windowed visual smoke for VfxSystem draw paths (Slice 3).
#
# The golden trace only covers the coin path; the other particle systems are
# draw-only and never run under --headless. This opens a real window, spawns one
# of each particle kind via the extracted _vfx API, lets the engine update+render
# a few frames, and saves a screenshot. Pass = a PNG with visible particles and
# no draw-time errors.
#
#   godot --path godot -s tools/smoke_vfx_draw.gd -- --out=/tmp/smoke_vfx.png

func _initialize() -> void:
	_run()


func _arg_value(key: String, fallback: String) -> String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with(key + "="):
			return a.substr(key.length() + 1)
	return fallback


func _run() -> void:
	var out_path := _arg_value("--out", "user://smoke_vfx.png")
	var gc = load("res://scripts/game_constants.gd")

	var game: Node = load("res://scenes/game.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	game._set_paused(false)
	game.game_paused = false

	var vfx = game._vfx
	# One of every kind, spread across the playfield.
	vfx.spawn_destroy_vfx(Vector2(120.0, 250.0), gc.BLOCK_POW)        # ring + sparks
	vfx.spawn_destroy_vfx(Vector2(280.0, 250.0), gc.BLOCK_STAR)       # sparks + starburst
	vfx.spawn_bubble_pop(Vector2(200.0, 330.0), true)                 # bubbles
	vfx.spawn_impact_sparks(Vector2(120.0, 410.0), Vector2(1, -1), Color(1, 0.6, 0.2))  # streaks
	vfx.vfx_ring(Vector2(280.0, 410.0), Color(0.3, 1.0, 1.0, 0.9), 0.8)
	vfx.burst_feedback(Vector2(200.0, 480.0), Color(1, 0.3, 0.6), 18.0, 0.8)
	vfx.spawn_coin_shards(Vector2(200.0, 540.0), gc.BLOCK_STAR)       # coins
	game.queue_redraw()

	for _i in range(4):
		game.game_paused = false
		await process_frame

	var img: Image = root.get_texture().get_image()
	img.save_png(out_path)
	print("SAVED ", img.get_width(), "x", img.get_height(),
		" particles=", vfx.vfx_particles.size(), " coins=", vfx.coin_shards.size(),
		" bursts=", vfx.impact_bursts.size(), " -> ", out_path)
	quit(0)
