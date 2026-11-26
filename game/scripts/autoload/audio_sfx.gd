extends Node

# Procedural stereo audio engine:
# - SFX channel: retro arcade SFX, 3D-panned wildlife/world events, footsteps, thunder
# - Ambient channel: wind gusts, rain drops, lakeside waves, indoor acoustic hush
# - Music channel: warm casino lounge chords indoors, distinct retro motifs per mini-game

const SAMPLE_RATE := 22050.0

var _sfx_player: AudioStreamPlayer
var _sfx_playback: AudioStreamGeneratorPlayback
var _ambient_player: AudioStreamPlayer
var _ambient_playback: AudioStreamGeneratorPlayback
var _music_player: AudioStreamPlayer
var _music_playback: AudioStreamGeneratorPlayback

var _active_tones: Array[Dictionary] = []
var _noise_seed: int = 12345
var _lp_wind: float = 0.0
var _lp_water: float = 0.0
var _lp_rain: float = 0.0
var _wave_lfo: float = 0.0
var _drop_env: float = 0.0
var _drop_phase: float = 0.0
var _drop_freq: float = 900.0

var _ambient_rain: float = 0.0
var _ambient_wind: float = 0.2
var _ambient_indoors: float = 1.0
var _ambient_water: float = 0.0
var _ambient_roulette: float = 0.0
var _roulette_tick_t: float = 0.0

var _music_mode: String = "menu" # "menu", "casino", "forest", "minigame"
var _music_game_id: String = ""
var _music_step: int = 0
var _music_timer: float = 0.0
var _music_notes: Array[Dictionary] = []
var _waka_toggle: bool = false


func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		return
	_sfx_playback = _make_stream(-3.0, 0.16, true)
	_ambient_playback = _make_stream(-9.0, 0.25, false)
	_music_playback = _make_stream(-16.0, 0.25, false, true)


func _make_stream(vol_db: float, buf_len: float, is_sfx: bool, is_music: bool = false) -> AudioStreamGeneratorPlayback:
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = SAMPLE_RATE
	gen.buffer_length = buf_len
	var player := AudioStreamPlayer.new()
	player.stream = gen
	player.volume_db = vol_db
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(player)
	player.play()
	if is_sfx:
		_sfx_player = player
	elif is_music:
		_music_player = player
	else:
		_ambient_player = player
	return player.get_stream_playback() as AudioStreamGeneratorPlayback


func set_ambient_state(rain: float, wind: float, indoors: float, water_prox: float = 0.0, roulette_prox: float = 0.0) -> void:
	_ambient_rain = clampf(rain, 0.0, 1.0)
	_ambient_wind = clampf(wind, 0.0, 1.0)
	_ambient_indoors = clampf(indoors, 0.0, 1.0)
	_ambient_water = clampf(water_prox, 0.0, 1.0)
	_ambient_roulette = clampf(roulette_prox, 0.0, 1.0)


func set_music_mode(mode: String, game_id: String = "") -> void:
	if _music_mode == mode and _music_game_id == game_id:
		return
	_music_mode = mode
	_music_game_id = game_id
	_music_step = 0
	_music_timer = 0.0
	_music_notes.clear()


func play_tone(freq: float, duration: float = 0.12, wave: String = "square", slide_to: float = -1.0, vol: float = 0.25, pan: float = 0.0, delay: float = 0.0) -> void:
	if _sfx_playback == null:
		return
	if _active_tones.size() > 40:
		_active_tones.remove_at(0)
	_active_tones.append({
		"freq": maxf(freq, 20.0),
		"end_freq": maxf(freq if slide_to < 0.0 else slide_to, 20.0),
		"dur": maxf(duration, 0.02),
		"t": -maxf(delay, 0.0),
		"phase": 0.0,
		"wave": wave,
		"vol": clampf(vol, 0.0, 1.0),
		"pan": clampf(pan, -1.0, 1.0)
	})


# --- UI & Portal ---
func play_ui_click() -> void:
	play_tone(640.0, 0.05, "sine", 920.0, 0.18)


func play_switch() -> void:
	play_tone(1200.0, 0.03, "square", 700.0, 0.14)


func play_hover_painting() -> void:
	play_tone(784.0, 0.09, "sine", 1046.0, 0.08)


func play_portal_dive() -> void:
	play_tone(220.0, 0.52, "sine", 880.0, 0.24)
	play_tone(330.0, 0.52, "triangle", 1320.0, 0.18, 0.0, 0.04)
	play_tone(523.0, 0.35, "sine", 1046.0, 0.12, 0.0, 0.18)


func play_portal_exit() -> void:
	play_tone(780.0, 0.38, "sine", 240.0, 0.22)
	play_tone(520.0, 0.30, "triangle", 190.0, 0.14, 0.0, 0.05)


# --- World & Wildlife ---
func play_step(surface: String) -> void:
	match surface:
		"carpet":
			play_tone(95.0, 0.045, "noise", 60.0, 0.08)
		"water":
			# Layered splash + bubbly droplets so wading in water sounds unmistakably wet
			play_tone(640.0, 0.16, "noise", 220.0, 0.34)
			play_tone(290.0, 0.11, "sine", 740.0, 0.16, -0.25, 0.02)
			play_tone(420.0, 0.09, "triangle", 980.0, 0.14, 0.25, 0.06)
		"stone":
			play_tone(210.0, 0.045, "noise", 120.0, 0.12)
		_:
			play_tone(165.0, 0.055, "noise", 95.0, 0.12)


func play_player_jump() -> void:
	play_tone(160.0, 0.10, "sine", 290.0, 0.13)


func play_player_land(in_water: bool = false) -> void:
	if in_water:
		play_tone(560.0, 0.22, "noise", 140.0, 0.38)
		play_tone(240.0, 0.14, "sine", 620.0, 0.18, 0.0, 0.03)
	else:
		play_tone(110.0, 0.08, "noise", 55.0, 0.16)


func play_pipe_warp() -> void:
	play_tone(440.0, 0.09, "square", 180.0, 0.18, 0.0, 0.0)
	play_tone(392.0, 0.09, "square", 150.0, 0.18, 0.0, 0.11)
	play_tone(349.0, 0.12, "square", 110.0, 0.18, 0.0, 0.22)


func play_boost_whoosh() -> void:
	play_tone(220.0, 0.28, "saw", 760.0, 0.20)
	play_tone(480.0, 0.22, "noise", 980.0, 0.18, 0.0, 0.03)


func play_slot_spin() -> void:
	for i: int in range(5):
		play_tone(520.0 + float(i) * 95.0, 0.055, "square", 660.0 + float(i) * 80.0, 0.12, 0.0, float(i) * 0.07)


func play_boing_launch() -> void:
	play_tone(180.0, 0.34, "sine", 820.0, 0.24)
	play_tone(260.0, 0.28, "triangle", 1100.0, 0.16, 0.0, 0.04)


func play_race_lap() -> void:
	play_tone(523.2, 0.10, "triangle", 523.2, 0.18, 0.0, 0.0)
	play_tone(659.2, 0.10, "triangle", 659.2, 0.18, 0.0, 0.10)
	play_tone(784.0, 0.18, "triangle", 1046.5, 0.22, 0.0, 0.20)


func play_countdown_beep(is_go: bool = false) -> void:
	if is_go:
		play_tone(880.0, 0.26, "saw", 987.7, 0.24, 0.0, 0.0)
		play_tone(1318.5, 0.34, "triangle", 1567.9, 0.22, 0.0, 0.02)
	else:
		play_tone(440.0, 0.16, "triangle", 440.0, 0.20, 0.0, 0.0)
		play_tone(220.0, 0.12, "sine", 220.0, 0.12, 0.0, 0.0)


func play_race_finish() -> void:
	var fan := [523.2, 659.2, 784.0, 1046.5, 1318.5]
	for idx: int in range(fan.size()):
		play_tone(fan[idx], 0.14 if idx < 4 else 0.42, "triangle", fan[idx] * 1.01, 0.22, 0.0, float(idx) * 0.09)


func play_bird_song(pan: float = 0.0) -> void:
	var f0 := randf_range(1750.0, 2650.0)
	play_tone(f0, 0.075, "sine", f0 * 1.32, 0.11, pan, 0.0)
	play_tone(f0 * 1.25, 0.065, "sine", f0 * 0.95, 0.10, pan, 0.09)
	play_tone(f0 * 1.08, 0.09, "sine", f0 * 1.45, 0.10, pan, 0.18)


func play_duck_call(pan: float = 0.0) -> void:
	play_tone(420.0, 0.10, "saw", 310.0, 0.10, pan, 0.0)
	play_tone(390.0, 0.11, "saw", 285.0, 0.09, pan, 0.14)


func play_hawk_cry(pan: float = 0.0) -> void:
	play_tone(1950.0, 0.36, "saw", 1180.0, 0.09, pan)


func play_animal_rustle(pan: float = 0.0) -> void:
	play_tone(320.0, 0.14, "noise", 160.0, 0.14, pan)


func play_thunder() -> void:
	play_tone(140.0, 0.22, "noise", 45.0, 0.38)
	play_tone(72.0, 1.45, "noise", 28.0, 0.32, 0.0, 0.12)
	play_tone(54.0, 1.60, "triangle", 34.0, 0.14, 0.0, 0.15)


# --- Classic Mini-Game SFX ---
func play_jump() -> void:
	play_tone(290.0, 0.14, "square", 640.0, 0.18)


func play_coin() -> void:
	play_tone(988.0, 0.06, "square", 988.0, 0.17, 0.0, 0.0)
	play_tone(1319.0, 0.16, "square", 1319.0, 0.17, 0.0, 0.06)


func play_stomp() -> void:
	play_tone(340.0, 0.09, "square", 110.0, 0.22)
	play_tone(240.0, 0.08, "triangle", 480.0, 0.14, 0.0, 0.05)


func play_brick_bump() -> void:
	play_tone(180.0, 0.08, "square", 120.0, 0.18)


func play_hit() -> void:
	play_tone(190.0, 0.18, "noise", 65.0, 0.26)
	play_tone(140.0, 0.16, "saw", 60.0, 0.16)


func play_goal() -> void:
	play_tone(523.0, 0.09, "triangle", 523.0, 0.22, 0.0, 0.0)
	play_tone(659.0, 0.09, "triangle", 659.0, 0.22, 0.0, 0.09)
	play_tone(784.0, 0.22, "triangle", 1046.0, 0.24, 0.0, 0.18)


func play_fanfare() -> void:
	var notes := [523.0, 659.0, 784.0, 1046.0]
	for idx in range(notes.size()):
		play_tone(notes[idx], 0.13 if idx < 3 else 0.34, "square", notes[idx], 0.18, 0.0, float(idx) * 0.10)


func play_tetris_move() -> void:
	play_tone(380.0, 0.028, "triangle", 420.0, 0.10)


func play_tetris_rotate() -> void:
	play_tone(520.0, 0.05, "square", 720.0, 0.14)


func play_tetris_drop() -> void:
	play_tone(160.0, 0.07, "triangle", 75.0, 0.22)


func play_tetris_clear(lines: int) -> void:
	for i in range(mini(lines, 4)):
		play_tone(440.0 * pow(1.22, i), 0.14, "square", 660.0 * pow(1.22, i), 0.18, 0.0, float(i) * 0.05)


func play_bomb_place() -> void:
	play_tone(240.0, 0.08, "triangle", 140.0, 0.18)


func play_explosion() -> void:
	play_tone(180.0, 0.36, "noise", 38.0, 0.34)
	play_tone(95.0, 0.28, "saw", 32.0, 0.22)


func play_powerup() -> void:
	play_tone(587.0, 0.07, "triangle", 784.0, 0.18, 0.0, 0.0)
	play_tone(880.0, 0.14, "triangle", 1175.0, 0.18, 0.0, 0.07)


func play_kick() -> void:
	play_tone(150.0, 0.09, "triangle", 65.0, 0.26)
	play_tone(240.0, 0.05, "noise", 110.0, 0.14)


func play_whistle() -> void:
	play_tone(2350.0, 0.16, "sine", 2520.0, 0.15, 0.0, 0.0)
	play_tone(2480.0, 0.22, "sine", 2280.0, 0.14, 0.0, 0.18)


func play_paddle_hit(pitch_shift: float = 0.0) -> void:
	play_tone(460.0 + pitch_shift * 140.0, 0.055, "square", 540.0 + pitch_shift * 140.0, 0.16)


func play_brick_break() -> void:
	play_tone(680.0, 0.07, "square", 440.0, 0.18)
	play_tone(320.0, 0.06, "noise", 180.0, 0.12)


func play_card_flip() -> void:
	play_tone(520.0, 0.035, "noise", 820.0, 0.14)
	play_tone(360.0, 0.03, "triangle", 480.0, 0.10, 0.0, 0.01)


func play_laser() -> void:
	play_tone(960.0, 0.08, "saw", 320.0, 0.15)


func play_enemy_pew() -> void:
	play_tone(420.0, 0.09, "triangle", 180.0, 0.10)


func play_waka() -> void:
	_waka_toggle = not _waka_toggle
	var f1 := 480.0 if _waka_toggle else 340.0
	var f2 := 310.0 if _waka_toggle else 520.0
	play_tone(f1, 0.055, "triangle", f2, 0.11)


func play_ricochet() -> void:
	play_tone(1250.0, 0.08, "triangle", 760.0, 0.16)


func play_tile_merge(val: int = 8) -> void:
	var base := clampf(320.0 + log(maxf(float(val), 2.0)) / log(2.0) * 55.0, 360.0, 1100.0)
	play_tone(base, 0.08, "triangle", base * 1.25, 0.18)


func play_marble_pop(combo: int = 1) -> void:
	var f := clampf(440.0 + float(combo) * 110.0, 440.0, 1280.0)
	play_tone(f, 0.09, "sine", f * 1.5, 0.22)
	play_tone(f * 1.25, 0.07, "triangle", f * 1.8, 0.15, 0.0, 0.04)


func play_puzzle_snap() -> void:
	play_tone(587.3, 0.07, "triangle", 880.0, 0.20)
	play_tone(880.0, 0.11, "sine", 1174.6, 0.18, 0.0, 0.06)


func play_intro_fanfare() -> void:
	# Warm Emerald-Gold Casino Lounge Chord + Shimmer Arpeggio
	play_tone(130.8, 1.35, "triangle", 130.8, 0.18, 0.0, 0.02)
	play_tone(261.6, 1.15, "sine", 261.6, 0.14, -0.35, 0.08)
	play_tone(329.6, 1.10, "sine", 329.6, 0.14, 0.35, 0.16)
	play_tone(392.0, 1.05, "triangle", 392.0, 0.13, -0.2, 0.24)
	play_tone(493.9, 1.00, "sine", 493.9, 0.12, 0.2, 0.34)
	play_tone(523.3, 1.10, "triangle", 523.3, 0.15, 0.0, 0.48)
	play_tone(659.3, 0.90, "sine", 659.3, 0.13, 0.0, 0.62)


func _process(delta: float) -> void:
	if _sfx_playback == null:
		return
	_fill_sfx_buffer()
	_fill_ambient_buffer(delta)
	_fill_music_buffer(delta)


func _next_noise() -> float:
	_noise_seed = (_noise_seed * 1103515245 + 12345) & 0x7fffffff
	return float(_noise_seed % 20000) / 10000.0 - 1.0


func _sample_wave(wave: String, phase: float) -> float:
	match wave:
		"square":
			return 1.0 if phase < 0.5 else -1.0
		"triangle":
			return 4.0 * absf(phase - 0.5) - 1.0
		"saw":
			return 2.0 * phase - 1.0
		"noise":
			return _next_noise()
		_:
			return sin(phase * TAU)


func _fill_sfx_buffer() -> void:
	var frames := _sfx_playback.get_frames_available()
	if frames <= 0:
		return
	var dt := 1.0 / SAMPLE_RATE
	for i in range(frames):
		var mix_l := 0.0
		var mix_r := 0.0
		for j in range(_active_tones.size() - 1, -1, -1):
			var tone: Dictionary = _active_tones[j]
			var t := float(tone["t"])
			if t < 0.0:
				tone["t"] = t + dt
				continue
			var dur := float(tone["dur"])
			if t >= dur:
				_active_tones.remove_at(j)
				continue
			var u := t / dur
			var freq := lerpf(float(tone["freq"]), float(tone["end_freq"]), u)
			var env := (1.0 - u) * minf(t / 0.006, 1.0)
			var phase := float(tone["phase"]) + freq * dt
			tone["phase"] = fmod(phase, 1.0)
			tone["t"] = t + dt
			var s := _sample_wave(str(tone["wave"]), phase) * env * float(tone["vol"])
			var pan := float(tone["pan"])
			mix_l += s * clampf(1.0 - maxf(pan, 0.0), 0.25, 1.0)
			mix_r += s * clampf(1.0 + minf(pan, 0.0), 0.25, 1.0)
		_sfx_playback.push_frame(Vector2(clampf(mix_l, -0.85, 0.85), clampf(mix_r, -0.85, 0.85)))


func _fill_ambient_buffer(delta: float) -> void:
	if _ambient_playback == null:
		return
	# Roulette wheel subtle wooden tick when standing close to the casino table
	if _ambient_roulette > 0.15 and _music_mode != "menu" and _music_mode != "minigame":
		_roulette_tick_t -= delta
		if _roulette_tick_t <= 0.0:
			_roulette_tick_t = randf_range(0.14, 0.24)
			play_tone(1450.0, 0.015, "triangle", 900.0, 0.045 * _ambient_roulette)

	var frames := _ambient_playback.get_frames_available()
	if frames <= 0:
		return
	var dt := 1.0 / SAMPLE_RATE
	var outdoors := 1.0 - _ambient_indoors * 0.72
	var wind_gain := (0.05 + _ambient_wind * 0.22) * outdoors
	var rain_gain := _ambient_rain * 0.28 * outdoors
	var water_gain := _ambient_water * 0.22 * (1.0 - _ambient_indoors * 0.5)

	for i in range(frames):
		_wave_lfo += dt * 0.28
		var n1 := _next_noise()
		var n2 := _next_noise()
		_lp_wind = lerpf(_lp_wind, n1, 0.025)
		_lp_water = lerpf(_lp_water, n2, 0.055)
		_lp_rain = lerpf(_lp_rain, n1, 0.30)

		var wave_mod := 0.45 + 0.55 * sin(_wave_lfo * TAU)
		var rain_drop := 0.0
		if _ambient_rain > 0.2 and _drop_env <= 0.001 and randf() < 0.0018 * _ambient_rain:
			_drop_env = 0.09
			_drop_freq = randf_range(650.0, 1450.0)
		if _drop_env > 0.001:
			_drop_phase = fmod(_drop_phase + _drop_freq * dt, 1.0)
			rain_drop = sin(_drop_phase * TAU) * _drop_env * outdoors
			_drop_env *= 0.992

		var s_l := _lp_wind * wind_gain + _lp_rain * rain_gain + _lp_water * water_gain * wave_mod + rain_drop
		var s_r := (_lp_wind * 0.85 + _lp_water * 0.15) * wind_gain + _lp_rain * rain_gain * 0.95 + _lp_water * water_gain * wave_mod - rain_drop * 0.7
		_ambient_playback.push_frame(Vector2(clampf(s_l, -0.65, 0.65), clampf(s_r, -0.65, 0.65)))


func _fill_music_buffer(delta: float) -> void:
	if _music_playback == null:
		return
	if _music_mode == "menu" or _music_mode == "forest":
		var avail := _music_playback.get_frames_available()
		for _i in range(avail):
			_music_playback.push_frame(Vector2.ZERO)
		return

	_music_timer -= delta
	if _music_timer <= 0.0:
		if _music_mode == "casino":
			_music_timer = 1.45
			var chords := [
				[261.6, 329.6, 392.0, 493.9], # Cmaj7
				[220.0, 261.6, 329.6, 392.0], # Am7
				[174.6, 220.0, 261.6, 329.6], # Fmaj7
				[196.0, 246.9, 293.7, 349.2]  # G7
			]
			var ch: Array = chords[_music_step % chords.size()]
			_music_step += 1
			for note in ch:
				_music_notes.append({"freq": float(note), "t": 0.0, "dur": 1.4, "phase": 0.0, "wave": "sine", "vol": 0.06})
		elif _music_mode == "minigame":
			_music_timer = 0.22
			var mel := _get_minigame_melody(_music_game_id)
			var f: float = mel[_music_step % mel.size()]
			if f > 0.0:
				_music_notes.append({"freq": f, "t": 0.0, "dur": 0.19, "phase": 0.0, "wave": "triangle", "vol": 0.12})
			if _music_step % 2 == 0:
				var bass := f * 0.5 if f > 0.0 else 110.0
				_music_notes.append({"freq": bass, "t": 0.0, "dur": 0.20, "phase": 0.0, "wave": "square", "vol": 0.045})
			_music_step += 1

	var frames := _music_playback.get_frames_available()
	if frames <= 0:
		return
	var dt := 1.0 / SAMPLE_RATE
	for i in range(frames):
		var mix := 0.0
		for j in range(_music_notes.size() - 1, -1, -1):
			var n: Dictionary = _music_notes[j]
			var t := float(n["t"])
			var dur := float(n["dur"])
			if t >= dur:
				_music_notes.remove_at(j)
				continue
			var env := sin((t / dur) * PI)
			var ph := float(n["phase"]) + float(n["freq"]) * dt
			n["phase"] = fmod(ph, 1.0)
			n["t"] = t + dt
			mix += _sample_wave(str(n["wave"]), ph) * env * float(n["vol"])
		mix = clampf(mix, -0.45, 0.45)
		_music_playback.push_frame(Vector2(mix, mix))


func _get_minigame_melody(gid: String) -> Array[float]:
	match gid:
		"mario":
			return [330.0, 330.0, 0.0, 330.0, 0.0, 262.0, 330.0, 392.0, 0.0, 196.0, 0.0, 262.0]
		"tetris":
			return [330.0, 247.0, 262.0, 294.0, 262.0, 247.0, 220.0, 220.0, 262.0, 330.0, 294.0, 262.0]
		"snake":
			return [262.0, 294.0, 330.0, 392.0, 330.0, 294.0, 262.0, 220.0]
		"bomberman":
			return [294.0, 349.0, 440.0, 349.0, 392.0, 330.0, 294.0, 220.0]
		"soccer":
			return [392.0, 392.0, 440.0, 523.0, 440.0, 392.0, 330.0, 392.0]
		"arkanoid":
			return [440.0, 523.0, 587.0, 659.0, 587.0, 523.0, 494.0, 392.0]
		"arcade":
			return [220.0, 262.0, 330.0, 440.0, 392.0, 330.0, 294.0, 247.0]
		"pacman":
			return [262.0, 523.0, 392.0, 330.0, 523.0, 392.0, 330.0, 0.0]
		"tanks":
			return [196.0, 196.0, 262.0, 294.0, 330.0, 294.0, 262.0, 220.0]
		"2048":
			return [294.0, 370.0, 440.0, 587.0, 440.0, 370.0, 330.0, 294.0]
		"zuma":
			return [220.0, 277.0, 330.0, 392.0, 440.0, 392.0, 330.0, 277.0]
		"puzzle":
			return [330.0, 392.0, 494.0, 587.0, 494.0, 440.0, 392.0, 330.0]
		"match3":
			return [392.0, 494.0, 587.0, 784.0, 587.0, 494.0, 440.0, 392.0]
		"minesweeper":
			return [220.0, 0.0, 262.0, 247.0, 220.0, 0.0, 196.0, 220.0]
		"solitaire":
			return [262.0, 330.0, 392.0, 494.0, 440.0, 392.0, 330.0, 294.0]
		"flappy":
			return [330.0, 392.0, 523.0, 440.0, 392.0, 523.0, 659.0, 523.0]
		"sudoku":
			return [247.0, 294.0, 370.0, 440.0, 370.0, 294.0, 247.0, 220.0]
		_:
			return [262.0, 330.0, 392.0, 330.0]
