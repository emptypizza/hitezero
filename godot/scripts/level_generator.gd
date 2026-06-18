extends RefCounted
class_name LevelGenerator

const Block = preload("res://scripts/block.gd")
const GameConstants = preload("res://scripts/game_constants.gd")
const BLOCK_SCENE := preload("res://scenes/block.tscn")

# ─── Pattern pool ─────────────────────────────────────────────────────────────
# Each pattern: Array of row-strings, each 7 chars wide.
# Slot types: . empty | N NORMAL | S STAR | E ENEMY | P POW | X any-block

const PATTERNS_EASY: Array = [
	# V-mini (2 rows)
	["..NSN..", ".N.N.N."],
	# Checker (2 rows)
	["N.N.N.N", ".N.S.N."],
	# Centre star row (2 rows)
	["NNNSNNN", ".N...N."],
	# Sparse (2 rows)
	[".NSNNN.", "N.....N"],
	# Thin cross (3 rows)
	["...N...", ".NSNNN.", "...N..."],
]

const PATTERNS_MEDIUM: Array = [
	# Wall (4 rows)
	["NNNNNNN", "N.....N", "N..S..N", "NNNNNNN"],
	# Cross (4 rows)
	["...N...", "NNNSNNN", "...E...", "...N..."],
	# Cluster (3 rows)
	["NN.S.NN", "NPPPPNN", ".NNNNN."],
	# Corridor (3 rows)
	["NN...NN", "NE.S.EN", "NN...NN"],
	# Checker-wide (3 rows)
	["N.N.N.N", ".N.S.N.", "N.N.N.N"],
]

const PATTERNS_COMPLEX: Array = [
	# Diamond (5 rows)
	["...N...", "..NNN..", ".NNSNN.", "..NEN..", "...P..."],
	# Fortress (5 rows)
	["NNNNNNN", "NENNNEN", "NNN.NNN", "N..S..N", "NNNNNNN"],
	# Zigzag (4 rows)
	["N.N.N.N", ".NNSNN.", "N.E.E.N", ".NNNNN."],
	# Staircase (4 rows)
	["NN.....", "NNS....", ".NNNN..", "...ENNE"],
	# Bullseye (5 rows)
	["...N...", ".NNNNN.", "NN.S.NN", ".NNNNN.", "...P..."],
]

const PATTERNS_DENSE: Array = [
	# Full grid (6 rows)
	["NNNSNNN", "NENNNEN", "NNNNNNN", "NPNSNPN", "NENNNEN", "NNNNNNN"],
	# Dense fortress (5 rows)
	["NNNNNNN", "NENSNEN", "NNNNNNN", "NENPNEN", "NNNNNNN"],
	# Chaos-X (5 rows)
	["XSXXXXX", "XXXXXEX", "XXPXXXX", "EXXXSXX", "XXXXXXX"],
	# Stacked walls (5 rows)
	["NNNNNNN", "ENNNNEN", "NNPSPNN", "ENNNNEN", "NNNNNNN"],
	# Serpent corridor (6 rows) — LD-01
	["NNNNNN.", ".....NN", "NSNNNNN", "NN.....", ".NNNNEN", "....NPN"],
	# Twin pillars (5 rows) — LD-01
	["N.NSN.N", "N.NNN.N", "E.NNN.E", "N.NPN.N", "N.NSN.N"],
	# Arena (6 rows) — LD-01
	["NNNNNNN", "N.....N", "N.ESE.N", "N..P..N", "N.....N", "NNNSNNN"],
]

# LD-01: late-run pool (lv 20+). Heavier on E threats and X wildcards so the
# end-game keeps producing layouts the DENSE pool can't — without touching the
# HP curve (difficulty still comes from _base_hp).
const PATTERNS_BRUTAL: Array = [
	# Gauntlet (5 rows)
	["XEXXXEX", "XXXSXXX", "EXXXXXE", "XXPXPXX", "XXXSXXX"],
	# Twin keeps (5 rows)
	["NNN.NNN", "NSN.NSN", "NEN.NEN", "NNN.NNN", "..NPN.."],
	# Avalanche (6 rows)
	["NNNN...", "NNNNN..", "ENNSNNE", "..NNNNN", "...NNNN", "XXPXSXX"],
	# Hive (5 rows)
	["X.XXX.X", "XENSNEX", "XXXXXXX", "XENPNEX", "X.XSX.X"],
	# Crown (5 rows)
	["N.N.N.N", "NNNNNNN", "NESNSEN", "NNNNNNN", ".NNPNN."],
]


# ─── HP formula ───────────────────────────────────────────────────────────────

static func _base_hp(level: int) -> int:
	if level <= 1:
		return 1
	return int(ceil(1.0 + log(float(level)) / log(2.0) * 1.8))


# ─── Public entry point ───────────────────────────────────────────────────────

static func is_boss_stage(level: int) -> bool:
	return level >= GameConstants.BOSS_STAGE_INTERVAL and level % GameConstants.BOSS_STAGE_INTERVAL == 0


static func get_boss_type(level: int) -> int:
	var boss_index := (level / GameConstants.BOSS_STAGE_INTERVAL - 1) % 5
	return boss_index


# Test hook for the refactor golden-trace harness: a non-negative value makes
# layout deterministic. Production leaves it at -1 (fresh random layout per run).
static var _forced_seed: int = -1


static func init_level(game_root, level: int) -> void:
	game_root.clear_level_nodes()
	game_root.pending_stars = 0
	game_root.knives_to_spawn = 0

	if is_boss_stage(level):
		# Boss stages don't generate normal blocks
		# Boss spawning is handled by game_root
		return

	var rng := RandomNumberGenerator.new()
	if _forced_seed >= 0:
		rng.seed = _forced_seed + level
	else:
		rng.randomize()

	var base_hp := _base_hp(level)
	var pattern := _pick_pattern(level, rng)
	var blocks := _apply_pattern(pattern, level, rng)
	_mutate(blocks, rng)
	_place_blocks(game_root, blocks, base_hp, rng)

	if not _has_star(game_root):
		_add_block(game_root, 3, GameConstants.LEVEL_START_Y, 1, 1, GameConstants.BLOCK_STAR)


# ─── Pattern selection ────────────────────────────────────────────────────────

# LD-01: remembers the previous pick so two consecutive stages never share a
# layout. Static, so it survives across init_level calls within a run; a stale
# value from a previous run only skips one candidate, which is harmless.
static var _last_pattern: Array = []


static func _pick_pattern(level: int, rng: RandomNumberGenerator) -> Array:
	var pool: Array
	if level <= 3:
		pool = PATTERNS_EASY
	elif level <= 7:
		pool = PATTERNS_MEDIUM
	elif level <= 12:
		pool = PATTERNS_COMPLEX
	elif level <= 19:
		pool = PATTERNS_DENSE if rng.randf() > 0.3 else PATTERNS_COMPLEX
	else:
		# Late run: BRUTAL leads, DENSE backs it up, COMPLEX as a breather.
		var r := rng.randf()
		if r < 0.5:
			pool = PATTERNS_BRUTAL
		elif r < 0.85:
			pool = PATTERNS_DENSE
		else:
			pool = PATTERNS_COMPLEX

	var idx := rng.randi() % pool.size()
	if pool.size() > 1 and pool[idx] == _last_pattern:
		# Re-roll among the remaining patterns — guaranteed different.
		idx = (idx + 1 + rng.randi() % (pool.size() - 1)) % pool.size()
	_last_pattern = pool[idx]
	return pool[idx]


# ─── Pattern → block list ─────────────────────────────────────────────────────

static func _apply_pattern(pattern: Array, level: int, rng: RandomNumberGenerator) -> Array:
	var result: Array = []
	for row_idx in range(pattern.size()):
		var row_str: String = pattern[row_idx]
		for col in range(mini(row_str.length(), GameConstants.BLOCK_COLS)):
			var slot := row_str[col]
			if slot == ".":
				continue
			var block_type := _resolve_slot(slot, level, rng)
			if block_type != "":
				result.append({"col": col, "row": row_idx, "type": block_type})
	return result


static func _resolve_slot(slot: String, level: int, rng: RandomNumberGenerator) -> String:
	var r := rng.randf()
	match slot:
		"N":
			return GameConstants.BLOCK_NORMAL
		"S":
			return GameConstants.BLOCK_STAR
		"E":
			if level >= 3:
				return GameConstants.BLOCK_RED_ENEMY
			return GameConstants.BLOCK_NORMAL
		"P":
			return GameConstants.BLOCK_POW
		"X":
			if r < 0.12:
				return GameConstants.BLOCK_STAR
			if r < 0.22:
				return GameConstants.BLOCK_POW
			if r < 0.35 and level >= 3:
				return GameConstants.BLOCK_RED_ENEMY
			return GameConstants.BLOCK_NORMAL
		_:
			return ""


# ─── Mutation (1–3 cells added/removed) ──────────────────────────────────────

static func _mutate(blocks: Array, rng: RandomNumberGenerator) -> void:
	var mutations := rng.randi_range(1, 3)
	for _i in range(mutations):
		if rng.randf() < 0.5 and blocks.size() > 2:
			blocks.remove_at(rng.randi() % blocks.size())
		else:
			var col := rng.randi_range(0, GameConstants.BLOCK_COLS - 1)
			var max_r := _max_row(blocks)
			var row := rng.randi_range(0, max_r)
			var exists := false
			for b in blocks:
				if int(b["col"]) == col and int(b["row"]) == row:
					exists = true
					break
			if not exists:
				blocks.append({"col": col, "row": row, "type": GameConstants.BLOCK_NORMAL})


static func _max_row(blocks: Array) -> int:
	var mr := 0
	for b in blocks:
		mr = maxi(mr, int(b["row"]))
	return mr


# ─── Place blocks into scene ──────────────────────────────────────────────────

static func _place_blocks(game_root, blocks: Array, base_hp: int, rng: RandomNumberGenerator) -> void:
	for b in blocks:
		var col: int = b["col"]
		var row: int = b["row"]
		var block_type: String = b["type"]
		var y := GameConstants.LEVEL_START_Y + float(row) * GameConstants.BLOCK_HEIGHT

		var hp := 1
		var max_hp := 1
		if block_type == GameConstants.BLOCK_NORMAL:
			max_hp = base_hp
			hp = rng.randi_range(maxi(1, base_hp - 2), base_hp)
		elif block_type == GameConstants.BLOCK_RED_ENEMY:
			max_hp = maxi(1, int(ceil(float(base_hp) * 0.6)))
			hp = max_hp

		_add_block(game_root, col, y, hp, max_hp, block_type)


static func _add_block(game_root, col: int, y_pos: float, hp: int, max_hp: int, block_type: String) -> void:
	var block_size := Vector2(GameConstants.BLOCK_WIDTH - 4.0, GameConstants.BLOCK_HEIGHT - 4.0)
	var x := float(col) * GameConstants.BLOCK_WIDTH + 2.0 + block_size.x * 0.5
	var y := y_pos + 2.0 + block_size.y * 0.5

	var block: Block = BLOCK_SCENE.instantiate()
	block.position = Vector2(x, y)

	var group = game_root.moving_blocks_layer if block_type == GameConstants.BLOCK_RED_ENEMY else game_root.blocks_layer
	group.add_child(block)
	block.configure(block_type, hp, max_hp, block_size)


static func _has_star(game_root) -> bool:
	for container in [game_root.blocks_layer, game_root.moving_blocks_layer]:
		for child in container.get_children():
			var block := child as Block
			if block != null and block.block_type == GameConstants.BLOCK_STAR and not block.is_destroyed():
				return true
	return false
