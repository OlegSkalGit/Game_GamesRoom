extends MinigameBase

# Authentic pixel-matrix alien invader frames & destructible shields!
const ALIEN_A := ["..X.....X..", "...X...X...", "..XXXXXXX..", ".XX.XXX.XX.", "XXXXXXXXXXX", "X.XXXXXXX.X", "X.X.....X.X", "...XX.XX..."]
const ALIEN_B := ["...XXXXX...", ".XXXXXXXXX.", "XXXXXXXXXXX", "XXX..X..XXX", "XXXXXXXXXXX", "..XXX.XXX..", ".XX..X..XX.", "XX.......XX"]

var _ship_x: float = 320.0
var _shoot_cd: float = 0.0
var _lives: int = 3
var _wave: int = 1
var _bullets: Array[Vector2] = []
var _enemy_shots: Array[Vector2] = []
var _enemies: Array[Dictionary] = []
var _bunkers: Array[Rect2] = []
var _ufo: Dictionary = {}
var _stars: Array[Vector2] = []
var _swarm_dir: float = 1.0
var _fire_timer: float = 0.9
var _anim_t: float = 0.0


func get_game_title() -> String:
	return "Космічна Аркада"


func get_controls_hint() -> String:
	return "A/D або ◀/▶ — корабель | Пробіл — постріл | R — заново | Esc — вийти"


func reset_game() -> void:
	_ship_x = 320.0; _lives = 3; _wave = 1; _swarm_dir = 1.0
	_bullets.clear(); _enemy_shots.clear(); _ufo = {"active": false, "timer": 8.0}
	_stars.clear()
	for i in range(48):
		_stars.append(Vector2(randf() * CANVAS_SIZE.x, randf() * CANVAS_SIZE.y))
	_build_bunkers()
	_spawn_wave()
	super.reset_game()


func _build_bunkers() -> void:
	_bunkers.clear()
	for bx in [135.0, 295.0, 455.0]:
		for r in range(3):
			for c in range(5):
				if r == 2 and c in [1, 2, 3]: continue
				_bunkers.append(Rect2(bx + c * 10.0, 298 + r * 10.0, 9.0, 9.0))


func _spawn_wave() -> void:
	_enemies.clear()
	var colors := [Color(0.95, 0.30, 0.85), Color(0.26, 0.88, 0.72), Color(0.96, 0.72, 0.22), Color(0.45, 0.75, 1.0)]
	for r in range(4):
		for c in range(9):
			_enemies.append({
				"pos": Vector2(85 + c * 56, 48 + r * 34),
				"color": colors[r % colors.size()],
				"shape": 0 if r < 2 else 1,
				"dive": false,
				"dive_v": Vector2.ZERO
			})


func step_game(delta: float) -> void:
	_anim_t += delta
	for i in range(_stars.size()):
		_stars[i].y = fmod(_stars[i].y + (30.0 + float(i % 3) * 22.0) * delta, CANVAS_SIZE.y)

	if game_over:
		queue_redraw()
		return

	var mv := 0.0
	if is_left_held(): mv -= 1.0
	if is_right_held(): mv += 1.0
	_ship_x = clampf(_ship_x + mv * 315.0 * delta, 26.0, CANVAS_SIZE.x - 26.0)

	_shoot_cd = maxf(0.0, _shoot_cd - delta)
	if is_action_held() and _shoot_cd <= 0.0:
		_shoot_cd = 0.22
		_bullets.append(Vector2(_ship_x, 348))
		AudioSfx.play_laser()

	for i in range(_bullets.size() - 1, -1, -1):
		_bullets[i].y -= 470.0 * delta
		var hit_bk := false
		for bi in range(_bunkers.size() - 1, -1, -1):
			if _bunkers[bi].has_point(_bullets[i]):
				_bunkers.remove_at(bi); hit_bk = true; break
		if hit_bk or _bullets[i].y < -12.0:
			_bullets.remove_at(i)

	# Bonus UFO saucer
	if not bool(_ufo.get("active", false)):
		_ufo["timer"] = float(_ufo.get("timer", 8.0)) - delta
		if float(_ufo["timer"]) <= 0.0:
			_ufo = {"active": true, "x": -20.0, "vx": 135.0}
	else:
		_ufo["x"] = float(_ufo["x"]) + float(_ufo["vx"]) * delta
		if float(_ufo["x"]) > CANVAS_SIZE.x + 25.0:
			_ufo = {"active": false, "timer": randf_range(9.0, 15.0)}

	var hit_edge := false
	var swarm_spd := (36.0 + float(_wave) * 10.0) * _swarm_dir
	for e in _enemies:
		var ep: Vector2 = e["pos"]
		if not bool(e["dive"]):
			ep.x += swarm_spd * delta
			if ep.x < 30.0 or ep.x > CANVAS_SIZE.x - 30.0:
				hit_edge = true
		else:
			ep += (e["dive_v"] as Vector2) * delta
			if ep.y > CANVAS_SIZE.y + 18:
				ep.x = clampf(ep.x, 48.0, CANVAS_SIZE.x - 48.0)
				ep.y = 34.0; e["dive"] = false
		e["pos"] = ep

	if hit_edge:
		_swarm_dir = -_swarm_dir
		for e in _enemies:
			if not bool(e["dive"]):
				var ep2: Vector2 = e["pos"]
				ep2.y += 10.0
				e["pos"] = ep2

	_fire_timer -= delta
	if _fire_timer <= 0.0 and not _enemies.is_empty():
		_fire_timer = maxf(0.28, 0.90 - float(_wave) * 0.08)
		var shooter: Dictionary = _enemies[randi() % _enemies.size()]
		var sp: Vector2 = shooter["pos"]
		_enemy_shots.append(sp + Vector2(0, 12))
		AudioSfx.play_enemy_pew()
		if randf() < 0.22:
			shooter["dive"] = true
			shooter["dive_v"] = (Vector2(_ship_x, 380) - sp).normalized() * 175.0

	for i in range(_enemy_shots.size() - 1, -1, -1):
		_enemy_shots[i].y += 235.0 * delta
		var hit_bk := false
		for bi in range(_bunkers.size() - 1, -1, -1):
			if _bunkers[bi].has_point(_enemy_shots[i]):
				_bunkers.remove_at(bi); hit_bk = true; break
		if hit_bk:
			_enemy_shots.remove_at(i)
		elif _enemy_shots[i].distance_to(Vector2(_ship_x, 364)) < 16.0:
			_enemy_shots.remove_at(i)
			_damage_player()
		elif _enemy_shots[i].y > CANVAS_SIZE.y + 12:
			_enemy_shots.remove_at(i)

	for bi in range(_bullets.size() - 1, -1, -1):
		var bp := _bullets[bi]
		if bool(_ufo.get("active", false)) and absf(bp.x - float(_ufo["x"])) < 18.0 and absf(bp.y - 22.0) < 12.0:
			_ufo = {"active": false, "timer": 12.0}
			add_score(300)
			AudioSfx.play_powerup()
			_bullets.remove_at(bi)
			continue
		var hit := false
		for ei in range(_enemies.size() - 1, -1, -1):
			if bp.distance_to(_enemies[ei]["pos"]) < 17.0:
				_enemies.remove_at(ei)
				add_score(40)
				AudioSfx.play_coin()
				hit = true; break
		if hit:
			_bullets.remove_at(bi)

	var swarm_breached := false
	for ei in range(_enemies.size() - 1, -1, -1):
		var e: Dictionary = _enemies[ei]
		var ep: Vector2 = e["pos"]
		if ep.distance_to(Vector2(_ship_x, 364)) < 18.0:
			_enemies.remove_at(ei)
			_damage_player()
		elif not bool(e["dive"]) and ep.y > 350.0:
			swarm_breached = true

	if swarm_breached and not game_over:
		for e in _enemies:
			if not bool(e["dive"]):
				var ep_lift: Vector2 = e["pos"]
				ep_lift.y -= 95.0
				e["pos"] = ep_lift
		_damage_player()

	if _enemies.is_empty() and not game_over:
		_wave += 1
		add_score(200)
		AudioSfx.play_goal()
		_spawn_wave()

	status_changed.emit("Хвиля %d  |  Життів: %d" % [_wave, _lives])
	queue_redraw()


func _damage_player() -> void:
	_lives -= 1
	AudioSfx.play_hit()
	if _lives <= 0:
		game_over = true
		status_changed.emit("Корабель знищено!")


func _draw_alien(center: Vector2, shape_idx: int, col: Color) -> void:
	var rows := ALIEN_A if shape_idx == 0 else ALIEN_B
	var px := 2.2
	var start := center - Vector2(5.5 * px, 4.0 * px)
	for r in range(rows.size()):
		var rs := str(rows[r])
		for c in range(rs.length()):
			if rs[c] == "X":
				draw_rect(Rect2(start.x + c * px, start.y + r * px, px, px), col)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, CANVAS_SIZE), Color(0.02, 0.03, 0.07))
	for s in _stars:
		draw_circle(s, 1.4, Color(0.85, 0.90, 1.0, 0.75))

	for b in _bunkers:
		draw_rect(b, Color(0.24, 0.86, 0.34))

	if bool(_ufo.get("active", false)):
		var ux := float(_ufo["x"])
		draw_rect(Rect2(ux - 16, 18, 32, 9), Color(0.95, 0.22, 0.24))
		draw_circle(Vector2(ux, 18), 7.5, Color(0.95, 0.65, 0.25))

	for e in _enemies:
		_draw_alien(e["pos"], int(e["shape"]), e["color"])

	for b in _bullets:
		draw_rect(Rect2(b - Vector2(1.5, 7), Vector2(3, 14)), Color(1.0, 0.94, 0.25))
	for es in _enemy_shots:
		draw_circle(es, 4.0, Color(1.0, 0.30, 0.30))

	# Detailed Starfighter with cockpit & engine thruster flame
	draw_colored_polygon(PackedVector2Array([
		Vector2(_ship_x, 344), Vector2(_ship_x - 16, 376), Vector2(_ship_x + 16, 376)
	]), Color(0.24, 0.78, 0.98))
	draw_rect(Rect2(_ship_x - 3, 354, 6, 12), Color(0.95, 0.98, 1.0))
	draw_circle(Vector2(_ship_x, 380), 4.0 + sin(_anim_t * 30.0) * 1.5, Color(1.0, 0.58, 0.14))
	draw_game_over_banner()
