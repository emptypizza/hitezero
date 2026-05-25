extends Node

# Procedural retro SFX — all sounds generated from PCM math, no external files.
# Usage: AudioManager.play("sound_name")

const SAMPLE_RATE := 22050

var _players: Dictionary = {}


func _ready() -> void:
	_build_all_sounds()


func play(sound_name: String) -> void:
	if not _players.has(sound_name):
		return
	var p: AudioStreamPlayer = _players[sound_name]
	p.stop()
	p.play()


func _build_all_sounds() -> void:
	_add("knife_launch",         _gen_knife_launch(),         -4.0)
	_add("block_hit",            _gen_block_hit(),            -6.0)
	_add("block_destroy_normal", _gen_block_destroy_normal(), -3.0)
	_add("block_destroy_pow",    _gen_block_destroy_pow(),    -1.0)
	_add("block_destroy_star",   _gen_block_destroy_star(),   -3.0)
	_add("enemy_warning",        _gen_enemy_warning(),        -2.0)
	_add("stage_clear",          _gen_stage_clear(),          -2.0)
	_add("game_over",            _gen_game_over(),            -2.0)
	_add("tray_bounce",          _gen_tray_bounce(),          -5.0)
	_add("ui_click",             _gen_ui_click(),             -8.0)


func _add(sound_name: String, stream: AudioStreamWAV, volume_db: float) -> void:
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.volume_db = volume_db
	p.bus = "Master"
	add_child(p)
	_players[sound_name] = p


func _make_wav(buf: PackedFloat32Array) -> AudioStreamWAV:
	var count := buf.size()
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	for i in range(count):
		var s := clampi(int(buf[i] * 32767.0), -32768, 32767)
		bytes.encode_s16(i * 2, s)
	var stream := AudioStreamWAV.new()
	stream.format = 1  # AudioStreamWAV.FORMAT_16_BIT
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = bytes
	return stream


# ─── Sound generators ────────────────────────────────────────────────────────

func _gen_knife_launch() -> AudioStreamWAV:
	# Short whoosh: noise burst mixed with descending frequency sweep, 0.15 s
	var dur := 0.15
	var n := int(SAMPLE_RATE * dur)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var phase := 0.0
	for i in range(n):
		var t := float(i) / float(SAMPLE_RATE)
		var env := exp(-t * 18.0)
		var freq := lerpf(1000.0, 200.0, t / dur)
		phase += TAU * freq / float(SAMPLE_RATE)
		var noise := randf_range(-1.0, 1.0)
		buf[i] = (noise * 0.55 + sin(phase) * 0.45) * env * 0.7
	return _make_wav(buf)


func _gen_block_hit() -> AudioStreamWAV:
	# Light tap: short high-frequency click, 0.06 s
	var dur := 0.06
	var n := int(SAMPLE_RATE * dur)
	var buf := PackedFloat32Array()
	buf.resize(n)
	for i in range(n):
		var t := float(i) / float(SAMPLE_RATE)
		var s := sin(TAU * 2000.0 * t) * exp(-t * 55.0) * 0.5
		s += randf_range(-1.0, 1.0) * exp(-t * 110.0) * 0.4
		buf[i] = clampf(s, -1.0, 1.0)
	return _make_wav(buf)


func _gen_block_destroy_normal() -> AudioStreamWAV:
	# Pop/burst: noise + descending tone, 0.18 s
	var dur := 0.18
	var n := int(SAMPLE_RATE * dur)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var phase := 0.0
	for i in range(n):
		var t := float(i) / float(SAMPLE_RATE)
		var env := exp(-t * 13.0)
		var freq := lerpf(300.0, 70.0, t / dur)
		phase += TAU * freq / float(SAMPLE_RATE)
		buf[i] = (randf_range(-1.0, 1.0) * 0.6 + sin(phase) * 0.4) * env * 0.8
	return _make_wav(buf)


func _gen_block_destroy_pow() -> AudioStreamWAV:
	# Big explosion: low boom sweep + noise rumble, 0.40 s
	var dur := 0.40
	var n := int(SAMPLE_RATE * dur)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var phase := 0.0
	for i in range(n):
		var t := float(i) / float(SAMPLE_RATE)
		var env := exp(-t * 7.0)
		var freq := lerpf(110.0, 28.0, t / dur)
		phase += TAU * freq / float(SAMPLE_RATE)
		var tone := sin(phase) * 0.4 + sin(phase * 2.0) * 0.2
		var noise := randf_range(-1.0, 1.0) * 0.4
		buf[i] = clampf((tone + noise) * env * 0.9, -1.0, 1.0)
	return _make_wav(buf)


func _gen_block_destroy_star() -> AudioStreamWAV:
	# Sparkly chime: four ascending sine notes staggered, 0.45 s
	var dur := 0.45
	var n := int(SAMPLE_RATE * dur)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var freqs := PackedFloat32Array([880.0, 1100.0, 1320.0, 1760.0])
	var onsets := PackedFloat32Array([0.0, 0.06, 0.13, 0.21])
	for i in range(n):
		var t := float(i) / float(SAMPLE_RATE)
		var s := 0.0
		for j in range(4):
			var nt: float = t - onsets[j]
			if nt <= 0.0:
				continue
			var env := (1.0 - exp(-nt * 80.0)) * exp(-nt * 9.0)
			s += sin(TAU * freqs[j] * nt) * env * 0.24
		buf[i] = clampf(s, -1.0, 1.0)
	return _make_wav(buf)


func _gen_enemy_warning() -> AudioStreamWAV:
	# Two-pulse alarm buzz: square wave with tremolo, 0.34 s
	var dur := 0.34
	var n := int(SAMPLE_RATE * dur)
	var buf := PackedFloat32Array()
	buf.resize(n)
	for i in range(n):
		var t := float(i) / float(SAMPLE_RATE)
		var pulse_t := -1.0
		if t < 0.13:
			pulse_t = t
		elif t >= 0.18 and t < 0.31:
			pulse_t = t - 0.18
		if pulse_t < 0.0:
			buf[i] = 0.0
			continue
		var square := 1.0 if sin(TAU * 220.0 * t) >= 0.0 else -1.0
		var tremolo := 0.65 + 0.35 * sin(TAU * 18.0 * t)
		var env := minf(pulse_t * 30.0, 1.0) * (1.0 - maxf(0.0, (pulse_t - 0.10) * 25.0))
		buf[i] = square * tremolo * clampf(env, 0.0, 1.0) * 0.55
	return _make_wav(buf)


func _gen_stage_clear() -> AudioStreamWAV:
	# Victory arpeggio: C5 E5 G5 C6, 0.85 s
	var dur := 0.85
	var n := int(SAMPLE_RATE * dur)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var freqs := PackedFloat32Array([523.25, 659.25, 783.99, 1046.50])
	var starts := PackedFloat32Array([0.0, 0.16, 0.32, 0.50])
	var note_len := 0.36
	for i in range(n):
		var t := float(i) / float(SAMPLE_RATE)
		var s := 0.0
		for j in range(4):
			var nt: float = t - starts[j]
			if nt <= 0.0 or nt > note_len:
				continue
			var env := (1.0 - exp(-nt * 50.0)) * exp(-nt * 5.5)
			s += sin(TAU * freqs[j] * nt) * env * 0.22
			s += sin(TAU * freqs[j] * 2.0 * nt) * env * 0.07
		buf[i] = clampf(s, -1.0, 1.0)
	return _make_wav(buf)


func _gen_game_over() -> AudioStreamWAV:
	# Descending sad tones: A4 F#4 D4 A3, 0.70 s
	var dur := 0.70
	var n := int(SAMPLE_RATE * dur)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var freqs := PackedFloat32Array([440.0, 369.99, 293.66, 220.0])
	var starts := PackedFloat32Array([0.0, 0.14, 0.29, 0.45])
	var note_len := 0.30
	for i in range(n):
		var t := float(i) / float(SAMPLE_RATE)
		var s := 0.0
		for j in range(4):
			var nt: float = t - starts[j]
			if nt <= 0.0 or nt > note_len:
				continue
			var env := (1.0 - exp(-nt * 30.0)) * exp(-nt * 5.0)
			s += sin(TAU * freqs[j] * nt) * env * 0.22
			s += sin(TAU * freqs[j] * 0.5 * nt) * env * 0.08
		buf[i] = clampf(s, -1.0, 1.0)
	return _make_wav(buf)


func _gen_tray_bounce() -> AudioStreamWAV:
	# Quick boing: ascending frequency glide, 0.15 s
	var dur := 0.15
	var n := int(SAMPLE_RATE * dur)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var phase := 0.0
	for i in range(n):
		var t := float(i) / float(SAMPLE_RATE)
		var freq := lerpf(240.0, 680.0, t / dur)
		phase += TAU * freq / float(SAMPLE_RATE)
		buf[i] = sin(phase) * exp(-t * 14.0) * 0.65
	return _make_wav(buf)


func _gen_ui_click() -> AudioStreamWAV:
	# Tiny click: very short high-freq transient, 0.04 s
	var dur := 0.04
	var n := int(SAMPLE_RATE * dur)
	var buf := PackedFloat32Array()
	buf.resize(n)
	for i in range(n):
		var t := float(i) / float(SAMPLE_RATE)
		var env := exp(-t * 95.0)
		buf[i] = (sin(TAU * 3000.0 * t) * 0.5 + randf_range(-1.0, 1.0) * 0.5) * env * 0.5
	return _make_wav(buf)
