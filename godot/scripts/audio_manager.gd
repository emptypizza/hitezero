extends Node

# Procedural retro SFX — all sounds generated from PCM math, no external files.
# Usage: AudioManager.play("sound_name")
#        AudioManager.play("block_hit", pitch, volume_db_offset)
#
# Dynamics: callers pass a pitch (combo ramp) and a volume offset so repeated
# hits don't sound identical. Players are polyphonic so rapid combo spam and
# simultaneous multi-hits layer instead of cutting each other off.

const SAMPLE_RATE := 22050
const MAX_POLYPHONY := 5
const PITCH_MIN := 0.25
const PITCH_MAX := 4.0

var _players: Dictionary = {}
var _base_volume: Dictionary = {}


func _ready() -> void:
	_build_all_sounds()
	_build_music()


func play(sound_name: String, pitch: float = 1.0, volume_db_offset: float = 0.0) -> void:
	if not _players.has(sound_name):
		return
	var p: AudioStreamPlayer = _players[sound_name]
	p.pitch_scale = clampf(pitch, PITCH_MIN, PITCH_MAX)
	p.volume_db = float(_base_volume.get(sound_name, 0.0)) + volume_db_offset
	# No stop(): polyphony lets overlapping plays layer for combo machine-gun feel.
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
	# Low-frequency impact body layered under destruction sounds for weight.
	_add("block_subthump",       _gen_subthump(),             -4.0)


func _add(sound_name: String, stream: AudioStreamWAV, volume_db: float) -> void:
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.volume_db = volume_db
	p.bus = "Master"
	p.max_polyphony = MAX_POLYPHONY
	add_child(p)
	_players[sound_name] = p
	_base_volume[sound_name] = volume_db


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


func _gen_subthump() -> AudioStreamWAV:
	# Short low-frequency body ("thump") layered under destroy sounds to add
	# physical weight. Descending sine 90→45 Hz with a soft click attack, 0.12 s.
	var dur := 0.12
	var n := int(SAMPLE_RATE * dur)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var phase := 0.0
	for i in range(n):
		var t := float(i) / float(SAMPLE_RATE)
		var env := exp(-t * 22.0)
		var freq := lerpf(90.0, 45.0, t / dur)
		phase += TAU * freq / float(SAMPLE_RATE)
		var click := randf_range(-1.0, 1.0) * exp(-t * 240.0) * 0.25
		buf[i] = clampf((sin(phase) * 0.85 + click) * env, -1.0, 1.0)
	return _make_wav(buf)


# ─── Procedural looping BGM ────────────────────────────────────────────────
# Two AudioStreamPlayers cross-fade so title↔play↔boss transitions don't hard
# cut. Music plays on the Master bus, so the existing mute pill (which mutes
# Master) silences BGM along with SFX — no separate music toggle needed.
#
# Usage: AudioManager.play_music("title" | "play" | "boss")  ·  stop_music()

const MUSIC_VOLUME_DB := -13.0
const MUSIC_FADE := 0.9
const MIDI_A4 := 69

var _music_players: Array[AudioStreamPlayer] = []
var _music_tracks: Dictionary = {}
var _current_music: String = ""
var _music_idx: int = 0
var _music_tween: Tween


func _build_music() -> void:
	# Each track: chord roots (MIDI note numbers, one per bar), a melody scale
	# (semitone offsets played as a 16th-note arpeggio over each chord), tempo,
	# and mood flags. Baked once into looping 16-bit PCM.
	_music_tracks["title"] = _gen_music({
		"bpm": 100.0, "roots": [60, 67, 57, 65],     # C  G  Am F  — calm major
		"scale": [0, 4, 7, 12, 7, 4], "drum": false, "lead_db": -9.0,
	})
	_music_tracks["play"] = _gen_music({
		"bpm": 132.0, "roots": [57, 65, 60, 67],     # Am F  C  G  — driving
		"scale": [0, 3, 7, 12, 10, 7], "drum": true, "lead_db": -8.0,
	})
	_music_tracks["boss"] = _gen_music({
		"bpm": 148.0, "roots": [57, 56, 55, 56],     # Am G#  G  G# — tense chromatic
		"scale": [0, 3, 6, 7, 10, 12], "drum": true, "lead_db": -7.0, "dist": true,
	})
	for i in range(2):
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		p.volume_db = -80.0
		add_child(p)
		_music_players.append(p)


func _midi_freq(midi: int) -> float:
	return 440.0 * pow(2.0, float(midi - MIDI_A4) / 12.0)


func _gen_music(cfg: Dictionary) -> AudioStreamWAV:
	var bpm: float = cfg["bpm"]
	var roots: Array = cfg["roots"]
	var scale: Array = cfg["scale"]
	var use_drum: bool = cfg.get("drum", true)
	var lead_gain := db_to_linear(float(cfg.get("lead_db", -8.0)))
	var distort: bool = cfg.get("dist", false)

	var beat := 60.0 / bpm
	var beats_per_chord := 4
	var total_beats := roots.size() * beats_per_chord
	var dur := float(total_beats) * beat
	var n := int(SAMPLE_RATE * dur)
	var buf := PackedFloat32Array()
	buf.resize(n)

	# 16th-note arpeggio: lead (square) + bass (triangle, one octave under root)
	var step := beat / 4.0
	var steps := int(dur / step)
	for s in range(steps):
		var t0 := float(s) * step
		var chord_idx := int(t0 / (beat * float(beats_per_chord))) % roots.size()
		var root: int = roots[chord_idx]
		var deg: int = scale[s % scale.size()]
		var lead_f := _midi_freq(root + 12 + deg)
		var bass_f := _midi_freq(root - 12)
		var i0 := int(t0 * SAMPLE_RATE)
		var i1 := mini(n, int((t0 + step) * SAMPLE_RATE))
		for i in range(i0, i1):
			var t := float(i) / float(SAMPLE_RATE)
			var nt := t - t0
			var env := (1.0 - exp(-nt * 60.0)) * exp(-nt * 6.0)  # plucky
			var lp := lead_f * t
			var lead := (1.0 if fmod(lp, 1.0) < 0.5 else -1.0) * env * lead_gain
			if distort:
				lead = clampf(lead * 1.6, -1.0, 1.0)
			var bp := bass_f * t
			var tri := absf(fmod(bp, 1.0) * 4.0 - 2.0) - 1.0
			buf[i] = clampf(buf[i] + lead + tri * 0.22, -1.0, 1.0)

	if use_drum:
		for b in range(total_beats):
			var bt := float(b) * beat
			_mix_kick(buf, bt)               # kick on every beat
			_mix_hat(buf, bt + beat * 0.5)   # hi-hat on the off-beat

	for i in range(n):
		buf[i] = clampf(buf[i] * 0.8, -1.0, 1.0)

	var wav := _make_wav(buf)
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = n
	return wav


func _mix_kick(buf: PackedFloat32Array, t0: float) -> void:
	var n := buf.size()
	var i0 := int(t0 * SAMPLE_RATE)
	var dur := 0.12
	var cnt := int(dur * SAMPLE_RATE)
	var phase := 0.0
	for k in range(cnt):
		var i := i0 + k
		if i < 0 or i >= n:
			continue
		var nt := float(k) / float(SAMPLE_RATE)
		var env := exp(-nt * 24.0)
		var freq := lerpf(140.0, 45.0, minf(1.0, nt / dur))
		phase += TAU * freq / float(SAMPLE_RATE)
		buf[i] = clampf(buf[i] + sin(phase) * env * 0.55, -1.0, 1.0)


func _mix_hat(buf: PackedFloat32Array, t0: float) -> void:
	var n := buf.size()
	var i0 := int(t0 * SAMPLE_RATE)
	var dur := 0.05
	var cnt := int(dur * SAMPLE_RATE)
	for k in range(cnt):
		var i := i0 + k
		if i < 0 or i >= n:
			continue
		var nt := float(k) / float(SAMPLE_RATE)
		var env := exp(-nt * 90.0)
		buf[i] = clampf(buf[i] + randf_range(-1.0, 1.0) * env * 0.14, -1.0, 1.0)


# Cross-fade to a named track. No-op if it's already the current track.
func play_music(track_name: String) -> void:
	if _current_music == track_name or not _music_tracks.has(track_name):
		return
	_current_music = track_name
	var outgoing := _music_players[_music_idx]
	_music_idx = 1 - _music_idx
	var incoming := _music_players[_music_idx]
	incoming.stream = _music_tracks[track_name]
	incoming.volume_db = -80.0
	incoming.play()
	if _music_tween != null and _music_tween.is_valid():
		_music_tween.kill()
	_music_tween = create_tween().set_parallel(true)
	_music_tween.tween_property(incoming, "volume_db", MUSIC_VOLUME_DB, MUSIC_FADE)
	_music_tween.tween_property(outgoing, "volume_db", -80.0, MUSIC_FADE)


func stop_music() -> void:
	if _current_music == "":
		return
	_current_music = ""
	if _music_tween != null and _music_tween.is_valid():
		_music_tween.kill()
	_music_tween = create_tween().set_parallel(true)
	for p in _music_players:
		_music_tween.tween_property(p, "volume_db", -80.0, MUSIC_FADE)
