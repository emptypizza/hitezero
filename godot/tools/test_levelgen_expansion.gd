extends SceneTree
# Behavioural checks for LD-01 (pattern pool expansion + anti-repeat).
# Pure-static LevelGenerator surface only — no scenes are instantiated.
#
# Run: godot --headless --path godot -s tools/test_levelgen_expansion.gd

const LevelGen = preload("res://scripts/level_generator.gd")

var failures: Array[String] = []


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _init() -> void:
	_check_pool_shapes()
	_check_tier_routing()
	_check_anti_repeat()
	_check_slot_resolution()

	if failures.is_empty():
		print("PASS test_levelgen_expansion (LD-01)")
		quit(0)
	else:
		for failure in failures:
			push_error("FAIL: " + failure)
		quit(1)


func _check_pool_shapes() -> void:
	var pools := {
		"EASY": LevelGen.PATTERNS_EASY,
		"MEDIUM": LevelGen.PATTERNS_MEDIUM,
		"COMPLEX": LevelGen.PATTERNS_COMPLEX,
		"DENSE": LevelGen.PATTERNS_DENSE,
		"BRUTAL": LevelGen.PATTERNS_BRUTAL,
	}
	for pool_name in pools:
		var pool: Array = pools[pool_name]
		_check(pool.size() > 0, pool_name + " pool is empty")
		for pattern in pool:
			_check(pattern.size() >= 1 and pattern.size() <= 6,
				pool_name + " pattern row count out of range")
			for row in pattern:
				var row_str: String = row
				_check(row_str.length() == 7, pool_name + " row not 7 cols: " + row_str)
				for i in range(row_str.length()):
					_check(row_str[i] in ".NSEPX", pool_name + " bad slot char: " + row_str)
	_check(LevelGen.PATTERNS_DENSE.size() >= 7, "DENSE pool must hold >= 7 patterns")
	_check(LevelGen.PATTERNS_BRUTAL.size() >= 4, "BRUTAL pool must hold >= 4 patterns")


func _check_tier_routing() -> void:
	# Over many draws each band must only emit patterns from its allowed pools.
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260612
	var late_pools := LevelGen.PATTERNS_BRUTAL + LevelGen.PATTERNS_DENSE + LevelGen.PATTERNS_COMPLEX
	var saw_brutal := false
	for i in range(300):
		var p21: Array = LevelGen._pick_pattern(21, rng)
		_check(late_pools.has(p21), "lv21 pick escaped BRUTAL/DENSE/COMPLEX pools")
		if LevelGen.PATTERNS_BRUTAL.has(p21):
			saw_brutal = true
	_check(saw_brutal, "lv21 never drew from BRUTAL across 300 picks")

	for i in range(100):
		var p2: Array = LevelGen._pick_pattern(2, rng)
		_check(LevelGen.PATTERNS_EASY.has(p2), "lv2 pick escaped the EASY pool")
		var p15: Array = LevelGen._pick_pattern(15, rng)
		_check(LevelGen.PATTERNS_DENSE.has(p15) or LevelGen.PATTERNS_COMPLEX.has(p15),
			"lv15 pick escaped DENSE/COMPLEX pools")


func _check_anti_repeat() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var prev: Array = LevelGen._pick_pattern(21, rng)
	for i in range(400):
		var current: Array = LevelGen._pick_pattern(21, rng)
		_check(current != prev, "two consecutive picks returned the same pattern")
		prev = current


func _check_slot_resolution() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	_check(LevelGen._resolve_slot("N", 1, rng) == "NORMAL", "N must resolve to NORMAL")
	_check(LevelGen._resolve_slot("S", 1, rng) == "STAR", "S must resolve to STAR")
	_check(LevelGen._resolve_slot("P", 1, rng) == "POW", "P must resolve to POW")
	_check(LevelGen._resolve_slot("E", 1, rng) == "NORMAL", "E before lv3 must soften to NORMAL")
	_check(LevelGen._resolve_slot("E", 3, rng) == "RED_ENEMY", "E at lv3+ must resolve to RED_ENEMY")
	for i in range(50):
		var resolved := LevelGen._resolve_slot("X", 25, rng)
		_check(resolved in ["NORMAL", "STAR", "POW", "RED_ENEMY"], "X resolved to invalid type")
