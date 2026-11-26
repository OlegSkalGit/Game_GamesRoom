extends MinigameBase

const BALL_R := 11.2
const BALL_DIAM := 22.4
const BALL_COLORS: Array[Color] = [
	Color(0.95, 0.20, 0.22), # Ruby
	Color(0.18, 0.56, 0.98), # Sapphire
	Color(0.20, 0.86, 0.38), # Emerald
	Color(0.98, 0.80, 0.14), # Amber
	Color(0.76, 0.26, 0.94)  # Amethyst
]

var _level: int = 1
var _path_pts: Array[Vector2] = []
var _track_len: float = 100.0
var _frog_pos: Vector2 = Vector2(320.0, 200.0)
var _aim_angle: float = -PI * 0.5
var _cur_color: int = 0
var _next_color: int = 1
var _cur_power: String = "" # "", "bomb"
var _chain: Array[Dictionary] = []
var _shots: Array[Dictionary] = []
var _particles: Array[Dictionary] = []
var _popups: Array[Dictionary] = []
var _to_spawn: int = 24
var _spawn_pool: Array[int] = []
var _base_speed: float = 34.0
var _slow_t: float = 0.0
var _reverse_t: float = 0.0
var _lives: int = 3
var _combo: int = 0
var _anim_t: float = 0.0


func get_game_title() -> String:
	return "Зума: Храм Скарбів"


func get_controls_hint() -> String:
	return "Миша або A/D — приціл | ЛКМ / Пробіл — постріл | ПКМ / Tab — зміна кулі | R — заново"


func reset_game() -> void:
	_level = 1
	_lives = 3
	_shots.clear()
	_particles.clear()
	_popups.clear()
	_setup_level(1)
	super.reset_game()


func _setup_level(lvl: int) -> void:
	_level = lvl
	_shots.clear()
	_chain.clear()
	_slow_t = 0.0
	_reverse_t = 0.0
	_combo = 0
	var way: Array[Vector2] = []
	var lv_idx := (lvl - 1) % 3
	if lv_idx == 0:
		# Classic Inward Temple Spiral around central Frog
		_frog_pos = Vector2(326.0, 206.0)
		for i in range(68):
			var u := float(i) / 67.0
			var ang := -0.45 + u * TAU * 2.15
			var rx := lerpf(288.0, 74.0, u)
			var ry := lerpf(174.0, 52.0, u)
			way.append(Vector2(320.0 + cos(ang) * rx, 200.0 + sin(ang) * ry))
	elif lv_idx == 1:
		# Sweeping S-Serpentine Altar
		_frog_pos = Vector2(320.0, 212.0)
		way = [
			Vector2(28, 42), Vector2(180, 34), Vector2(440, 34), Vector2(588, 72), Vector2(598, 160),
			Vector2(510, 212), Vector2(150, 128), Vector2(56, 175), Vector2(58, 290),
			Vector2(170, 354), Vector2(490, 354), Vector2(582, 295), Vector2(510, 248), Vector2(418, 248)
		]
	else:
		# Twin Dragon Arena
		_frog_pos = Vector2(320.0, 202.0)
		for i in range(60):
			var u := float(i) / 59.0
			var ang := -PI * 0.9 + u * TAU * 1.85
			var mod_r := 1.0 + 0.16 * sin(ang * 3.0)
			var rx := lerpf(278.0, 82.0, u) * mod_r
			var ry := lerpf(168.0, 58.0, u) * mod_r
			way.append(Vector2(320.0 + cos(ang) * rx, 200.0 + sin(ang) * ry))

	_resample_path(way)
	var num_cols := mini(4 + (lvl - 1) / 2, BALL_COLORS.size())
	_to_spawn = 22 + lvl * 8
	_base_speed = 32.0 + float(lvl - 1) * 5.5
	_spawn_pool.clear()
	while _spawn_pool.size() < _to_spawn:
		var c := randi() % num_cols
		var run_n := 1 if randf() < 0.55 else 2
		for _r in range(run_n):
			_spawn_pool.append(c)

	# Initial surge of marbles onto temple track
	for k in range(mini(12, _spawn_pool.size())):
		var col_idx := _spawn_pool.pop_front() as int
		_chain.append({"col": col_idx, "power": "", "s": float(11 - k) * BALL_DIAM + 14.0, "draw_s": float(11 - k) * BALL_DIAM + 14.0})
	_cur_color = randi() % num_cols
	_next_color = randi() % num_cols
	_cur_power = ""
	status_changed.emit("Рівень %d  |  Життів: %d  |  Залишилось: %d" % [_level, _lives, _chain.size() + _spawn_pool.size()])


func _resample_path(raw: Array[Vector2]) -> void:
	_path_pts.clear()
	var smooth: Array[Vector2] = []
	for i in range(raw.size() - 1):
		var p0 := raw[maxi(0, i - 1)]
		var p1 := raw[i]
		var p2 := raw[i + 1]
		var p3 := raw[mini(raw.size() - 1, i + 2)]
		for s_i in range(6):
			var t := float(s_i) / 6.0
			var t2 := t * t
			var t3 := t2 * t
			var pt := 0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3)
			smooth.append(pt)
	smooth.append(raw[raw.size() - 1])

	_path_pts.append(smooth[0])
	var accum := 0.0
	var step_len := 4.0
	for i in range(1, smooth.size()):
		var seg_d := smooth[i - 1].distance_to(smooth[i])
		var cur_d := 0.0
		while accum + (seg_d - cur_d) >= step_len:
			var need := step_len - accum
			cur_d += need
			var frac := cur_d / maxf(seg_d, 0.001)
			_path_pts.append(smooth[i - 1].lerp(smooth[i], frac))
			accum = 0.0
		accum += seg_d - cur_d
	_track_len = float(maxi(1, _path_pts.size() - 1)) * 4.0


func _sample_track(s_dist: float) -> Vector2:
	if _path_pts.is_empty():
		return Vector2.ZERO
	var fidx := clampf(s_dist / 4.0, 0.0, float(_path_pts.size() - 1))
	var i0 := mini(int(fidx), _path_pts.size() - 1)
	var i1 := mini(i0 + 1, _path_pts.size() - 1)
	return _path_pts[i0].lerp(_path_pts[i1], fidx - float(i0))


func _pick_active_color() -> int:
	if _chain.is_empty():
		return randi() % 4
	var seen: Dictionary = {}
	for b in _chain:
		seen[int(b["col"])] = true
	var list := seen.keys()
	return int(list[randi() % list.size()])


func _fire_orb() -> void:
	if game_over:
		return
	var dir := Vector2.from_angle(_aim_angle)
	_shots.append({"pos": _frog_pos + dir * 20.0, "vel": dir * 560.0, "col": _cur_color, "power": _cur_power})
	AudioSfx.play_ui_click()
	_cur_color = _next_color
	_next_color = _pick_active_color()
	_cur_power = "bomb" if randf() < 0.07 else ""


func on_mouse_move(pos: Vector2) -> void:
	var diff := pos - _frog_pos
	if diff.length_squared() > 4.0:
		_aim_angle = diff.angle()
		queue_redraw()


func on_mouse_click(pos: Vector2) -> void:
	on_mouse_move(pos)
	_fire_orb()


func on_right_click(_pos: Vector2) -> void:
	if game_over:
		return
	var tmp := _cur_color
	_cur_color = _next_color
	_next_color = tmp
	AudioSfx.play_switch()
	queue_redraw()


func on_key_pressed(phys_key: int) -> void:
	if game_over:
		return
	if is_action_key(phys_key) or is_up_key(phys_key):
		_fire_orb()
	elif phys_key == KEY_TAB:
		on_right_click(Vector2.ZERO)


func _spawn_gem_burst(pos: Vector2, col: Color, cnt: int = 8) -> void:
	for _i in range(cnt):
		var a := randf() * TAU
		var spd := randf_range(40.0, 145.0)
		_particles.append({"pos": pos, "vel": Vector2(cos(a), sin(a)) * spd, "col": col, "t": 0.45})


func _resolve_matches(check_idx: int, is_combo: bool = false) -> void:
	if check_idx < 0 or check_idx >= _chain.size():
		return
	var c_target := int(_chain[check_idx]["col"])
	var lo := check_idx
	var hi := check_idx
	while lo > 0 and int(_chain[lo - 1]["col"]) == c_target and absf(float(_chain[lo - 1]["s"]) - float(_chain[lo]["s"])) <= BALL_DIAM * 1.4:
		lo -= 1
	while hi + 1 < _chain.size() and int(_chain[hi + 1]["col"]) == c_target and absf(float(_chain[hi]["s"]) - float(_chain[hi + 1]["s"])) <= BALL_DIAM * 1.4:
		hi += 1

	if hi - lo + 1 >= 3:
		_combo = (_combo + 1) if is_combo else 1
		var mid_pos := _sample_track(float(_chain[check_idx]["s"]))
		var count_rm := hi - lo + 1
		for k in range(hi, lo - 1, -1):
			var pw := str(_chain[k]["power"])
			var gp := _sample_track(float(_chain[k]["s"]))
			_spawn_gem_burst(gp, BALL_COLORS[int(_chain[k]["col"]) % BALL_COLORS.size()], 7)
			if pw == "slow": _slow_t = 5.0
			elif pw == "reverse": _reverse_t = 2.2
			_chain.remove_at(k)
		var pts := count_rm * 40 * _combo
		add_score(pts)
		AudioSfx.play_marble_pop(_combo)
		_popups.append({"pos": mid_pos, "txt": "+%d x%d!" % [pts, _combo] if _combo > 1 else "+%d" % pts, "t": 0.75})


func step_game(delta: float) -> void:
	_anim_t += delta
	for i in range(_particles.size() - 1, -1, -1):
		_particles[i]["t"] = float(_particles[i]["t"]) - delta
		_particles[i]["pos"] = (_particles[i]["pos"] as Vector2) + (_particles[i]["vel"] as Vector2) * delta
		if float(_particles[i]["t"]) <= 0.0:
			_particles.remove_at(i)
	for i in range(_popups.size() - 1, -1, -1):
		_popups[i]["t"] = float(_popups[i]["t"]) - delta
		_popups[i]["pos"] = (_popups[i]["pos"] as Vector2) + Vector2(0, -32.0 * delta)
		if float(_popups[i]["t"]) <= 0.0:
			_popups.remove_at(i)

	if game_over:
		queue_redraw()
		return

	if is_left_held(): _aim_angle -= delta * 2.8
	if is_right_held(): _aim_angle += delta * 2.8

	_slow_t = maxf(0.0, _slow_t - delta)
	_reverse_t = maxf(0.0, _reverse_t - delta)

	# 1. Advance chain back-to-front along track
	var spd := _base_speed * (0.45 if _slow_t > 0.0 else (-1.35 if _reverse_t > 0.0 else 1.0))
	if not _chain.is_empty():
		var tail_idx := _chain.size() - 1
		_chain[tail_idx]["s"] = maxf(8.0, float(_chain[tail_idx]["s"]) + spd * delta)
		for i in range(tail_idx - 1, -1, -1):
			var back_s := float(_chain[i + 1]["s"])
			var cur_s := float(_chain[i]["s"])
			if cur_s < back_s + BALL_DIAM:
				_chain[i]["s"] = back_s + BALL_DIAM
			elif cur_s > back_s + BALL_DIAM + 1.5:
				# Magnetic pull if same color on both sides of gap
				if int(_chain[i]["col"]) == int(_chain[i + 1]["col"]):
					_chain[i]["s"] = maxf(back_s + BALL_DIAM, cur_s - 210.0 * delta)
					if float(_chain[i]["s"]) <= back_s + BALL_DIAM + 1.0:
						_chain[i]["s"] = back_s + BALL_DIAM
						_resolve_matches(i, true)
						break

	# Spawn new marbles cleanly at tunnel entrance (s = 8)
	if not _spawn_pool.is_empty():
		var room_ok := _chain.is_empty() or float(_chain[_chain.size() - 1]["s"]) >= BALL_DIAM + 10.0
		if room_ok:
			var ncol := _spawn_pool.pop_front() as int
			var pw := "slow" if randf() < 0.06 else ("reverse" if randf() < 0.05 else "")
			_chain.append({"col": ncol, "power": pw, "s": 8.0, "draw_s": 8.0})

	for b in _chain:
		b["draw_s"] = lerpf(float(b["draw_s"]), float(b["s"]), minf(delta * 16.0, 1.0))

	# 2. Check shot collisions against chain
	for si in range(_shots.size() - 1, -1, -1):
		var sh: Dictionary = _shots[si]
		var sp: Vector2 = (sh["pos"] as Vector2) + (sh["vel"] as Vector2) * delta
		sh["pos"] = sp
		if sp.x < -15 or sp.x > CANVAS_SIZE.x + 15 or sp.y < -15 or sp.y > CANVAS_SIZE.y + 15:
			_shots.remove_at(si)
			continue
		var hit_i := -1
		for bi in range(_chain.size()):
			if sp.distance_to(_sample_track(float(_chain[bi]["s"]))) <= BALL_DIAM * 0.92:
				hit_i = bi
				break
		if hit_i >= 0:
			var sc_col := int(sh["col"])
			var spw := str(sh["power"])
			var hit_s := float(_chain[hit_i]["s"])
			var hit_p := _sample_track(hit_s)
			_shots.remove_at(si)
			if spw == "bomb":
				AudioSfx.play_explosion()
				_spawn_gem_burst(hit_p, Color(1.0, 0.72, 0.16), 18)
				var rm_cnt := 0
				for k in range(_chain.size() - 1, -1, -1):
					if absf(float(_chain[k]["s"]) - hit_s) <= 58.0:
						_spawn_gem_burst(_sample_track(float(_chain[k]["s"])), Color(1.0, 0.6, 0.2), 6)
						_chain.remove_at(k)
						rm_cnt += 1
				add_score(rm_cnt * 65)
				_popups.append({"pos": hit_p, "txt": "БУМ +%d" % (rm_cnt * 65), "t": 0.8})
			else:
				var front_s := _sample_track(hit_s + BALL_DIAM * 0.45)
				var back_s := _sample_track(hit_s - BALL_DIAM * 0.45)
				var ins_idx := hit_i if sp.distance_to(front_s) < sp.distance_to(back_s) else hit_i + 1
				var new_s := hit_s + BALL_DIAM if ins_idx == hit_i else hit_s
				_chain.insert(ins_idx, {"col": sc_col, "power": "", "s": new_s, "draw_s": new_s})
				for k in range(ins_idx - 1, -1, -1):
					_chain[k]["s"] = maxf(float(_chain[k]["s"]), float(_chain[k + 1]["s"]) + BALL_DIAM)
				_resolve_matches(ins_idx, false)

	# 3. Check lose (reached Skull Vortex) or level clear
	if not _chain.is_empty() and float(_chain[0]["s"]) >= _track_len - 16.0:
		_lives -= 1
		AudioSfx.play_hit()
		if _lives <= 0:
			game_over = true
			status_changed.emit("Змії дістались черепа! Фінал")
		else:
			_setup_level(_level)
	elif _chain.is_empty() and _spawn_pool.is_empty():
		add_score(350 * _level)
		AudioSfx.play_fanfare()
		_setup_level(_level + 1)
	else:
		status_changed.emit("Рівень %d  |  Життів: %d  |  Куль: %d" % [_level, _lives, _chain.size() + _spawn_pool.size()])

	queue_redraw()


func _draw_gem_ball(pos: Vector2, col_idx: int, power: String = "", rad: float = BALL_R) -> void:
	var c := BALL_COLORS[col_idx % BALL_COLORS.size()]
	draw_circle(pos + Vector2(2, 3), rad, Color(0, 0, 0, 0.38))
	draw_circle(pos, rad, c.darkened(0.32))
	draw_circle(pos - Vector2(1.0, 1.0), rad * 0.86, c)
	draw_circle(pos - Vector2(rad * 0.34, rad * 0.34), rad * 0.32, Color(1, 1, 1, 0.72))
	if power == "bomb":
		draw_circle(pos, rad * 0.45, Color(0.12, 0.12, 0.14))
		draw_circle(pos + Vector2(3, -4), 3.0, Color(1.0, 0.75, 0.15))
	elif power == "slow":
		draw_arc(pos, rad * 0.52, 0, TAU, 10, Color(0.75, 0.96, 1.0), 2.0)
	elif power == "reverse":
		draw_arc(pos, rad * 0.52, 0.4, PI * 1.6, 10, Color(1.0, 0.96, 0.4), 2.0)


func _draw() -> void:
	# Ancient mossy temple background + stone tiles
	draw_rect(Rect2(Vector2.ZERO, CANVAS_SIZE), Color(0.07, 0.11, 0.08))
	for gx in range(0, 640, 64):
		for gy in range(0, 400, 64):
			draw_rect(Rect2(gx + 2, gy + 2, 60, 60), Color(0.10, 0.15, 0.11), false, 1.2)

	# Carved stone track trench
	if _path_pts.size() >= 2:
		var poly := PackedVector2Array(_path_pts)
		draw_polyline(poly, Color(0.04, 0.06, 0.05), 32.0, true)
		draw_polyline(poly, Color(0.24, 0.27, 0.22), 25.0, true)
		draw_polyline(poly, Color(0.14, 0.16, 0.13), 8.0, true)

		# Entry temple tunnel mouth
		var entry := _path_pts[0]
		draw_circle(entry, 19.0, Color(0.18, 0.20, 0.16))
		draw_circle(entry, 12.0, Color(0.03, 0.04, 0.03))

		# Golden Skull Vortex at end
		var goal := _path_pts[_path_pts.size() - 1]
		var pulse := 1.0 + sin(_anim_t * 5.0) * 0.12
		draw_circle(goal, 22.0 * pulse, Color(0.85, 0.62, 0.14, 0.35))
		draw_circle(goal, 17.0, Color(0.72, 0.58, 0.24))
		draw_circle(goal + Vector2(-5, -3), 4.2, Color(0.12, 0.04, 0.04))
		draw_circle(goal + Vector2(5, -3), 4.2, Color(0.12, 0.04, 0.04))
		draw_rect(Rect2(goal + Vector2(-5, 6), Vector2(10, 5)), Color(0.12, 0.04, 0.04))

	# Draw marbles chain
	for b in _chain:
		_draw_gem_ball(_sample_track(float(b["draw_s"])), int(b["col"]), str(b["power"]))

	# Draw flying projectiles
	for sh in _shots:
		_draw_gem_ball(sh["pos"], int(sh["col"]), str(sh["power"]), BALL_R * 0.95)

	# Laser aim guide dots
	var aim_dir := Vector2.from_angle(_aim_angle)
	for d_i in range(1, 9):
		draw_circle(_frog_pos + aim_dir * (26.0 + float(d_i) * 18.0), 2.2, Color(BALL_COLORS[_cur_color].r, BALL_COLORS[_cur_color].g, BALL_COLORS[_cur_color].b, 0.55 - float(d_i) * 0.05))

	# Aztec Emerald Frog Shooter
	var perp := Vector2(-aim_dir.y, aim_dir.x)
	draw_circle(_frog_pos + Vector2(2, 4), 22.0, Color(0, 0, 0, 0.45))
	draw_circle(_frog_pos, 20.0, Color(0.16, 0.54, 0.28))
	draw_circle(_frog_pos, 16.0, Color(0.24, 0.68, 0.36))
	draw_circle(_frog_pos + aim_dir * 6.0 + perp * 11.0, 5.5, Color(0.98, 0.84, 0.22))
	draw_circle(_frog_pos + aim_dir * 6.0 - perp * 11.0, 5.5, Color(0.98, 0.84, 0.22))
	draw_circle(_frog_pos + aim_dir * 6.0 + perp * 11.0, 2.2, Color.BLACK)
	draw_circle(_frog_pos + aim_dir * 6.0 - perp * 11.0, 2.2, Color.BLACK)
	_draw_gem_ball(_frog_pos + aim_dir * 16.0, _cur_color, _cur_power, 8.8)
	_draw_gem_ball(_frog_pos - aim_dir * 6.0, _next_color, "", 6.2)

	for pt in _particles:
		draw_circle(pt["pos"], 3.2, pt["col"])
	var f := ThemeDB.fallback_font
	for pp in _popups:
		draw_string(f, pp["pos"] - Vector2(36, 0), str(pp["txt"]), HORIZONTAL_ALIGNMENT_CENTER, 72, 16, Color(1.0, 0.94, 0.36))

	draw_game_over_banner()
