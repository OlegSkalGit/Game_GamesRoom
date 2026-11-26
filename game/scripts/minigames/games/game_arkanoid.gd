extends MinigameBase

const WALL_PAD := 10.0

var _paddle_x: float = 320.0
var _paddle_w: float = 96.0
var _balls: Array[Dictionary] = []
var _bricks: Array[Dictionary] = []
var _drops: Array[Dictionary] = []
var _sparks: Array[Dictionary] = []
var _lives: int = 3
var _wide_timer: float = 0.0
var _level: int = 1
var _anim_t: float = 0.0


func get_game_title() -> String:
	return "Арканоїд"


func get_controls_hint() -> String:
	return "A/D або ◀/▶ — ракетка | Пробіл — запуск кулі | R — заново | Esc — вийти"


func reset_game() -> void:
	_lives = 3; _level = 1; _paddle_x = 320.0; _paddle_w = 96.0; _wide_timer = 0.0
	_drops.clear(); _sparks.clear()
	_build_level()
	_spawn_ball()
	super.reset_game()


func _build_level() -> void:
	_bricks.clear()
	var cols := [Color(0.95, 0.24, 0.30), Color(0.98, 0.56, 0.16), Color(0.96, 0.84, 0.22), Color(0.24, 0.86, 0.44), Color(0.24, 0.68, 0.98), Color(0.76, 0.36, 0.96)]
	var pat := (_level - 1) % 4
	for r in range(6):
		for c in range(10):
			var keep := false
			var hp := 1
			if pat == 0:
				keep = r < 5
				hp = 2 if (r == 0 and (c % 2 == 0)) else 1
			elif pat == 1:
				keep = absf(float(c) - 4.5) <= float(r) + 0.8
				hp = 2 if r == 5 else 1
			elif pat == 2:
				keep = (r == 0 or r == 5 or c == 0 or c == 9 or ((r == 2 or r == 3) and c >= 3 and c <= 6))
				hp = 2 if (r == 5 and (c >= 2 and c <= 7)) else 1
			else:
				keep = ((r + c) % 2 == 0) or (r == 1 and c >= 2 and c <= 7)
				hp = 2 if r == 0 else 1
			if not keep:
				continue
			var col: Color = Color(0.76, 0.82, 0.90) if hp > 1 else cols[(r + pat) % cols.size()]
			_bricks.append({
				"rect": Rect2(44 + c * 56, 38 + r * 22, 50, 16),
				"color": col,
				"hp": hp,
				"max_hp": hp
			})


func _spawn_ball() -> void:
	_balls = [{"pos": Vector2(_paddle_x, 350), "vel": Vector2(180, -265), "stuck": true, "trail": []}]


func _emit_sparks(pos: Vector2, col: Color) -> void:
	for _i in range(7):
		var a := randf() * TAU
		var spd := randf_range(40.0, 150.0)
		_sparks.append({"pos": pos, "vel": Vector2(cos(a), sin(a)) * spd, "col": col, "t": 0.38})


func on_key_pressed(phys_key: int) -> void:
	if game_over:
		return
	if is_action_key(phys_key):
		for b in _balls:
			if bool(b["stuck"]):
				b["stuck"] = false
				AudioSfx.play_ui_click()


func step_game(delta: float) -> void:
	_anim_t += delta
	for i in range(_sparks.size() - 1, -1, -1):
		_sparks[i]["t"] = float(_sparks[i]["t"]) - delta
		_sparks[i]["pos"] = (_sparks[i]["pos"] as Vector2) + (_sparks[i]["vel"] as Vector2) * delta
		if float(_sparks[i]["t"]) <= 0.0:
			_sparks.remove_at(i)
	if game_over:
		queue_redraw()
		return
	if _wide_timer > 0.0:
		_wide_timer -= delta
		if _wide_timer <= 0.0:
			_paddle_w = 96.0

	var mv := 0.0
	if is_left_held(): mv -= 1.0
	if is_right_held(): mv += 1.0
	_paddle_x = clampf(_paddle_x + mv * 410.0 * delta, _paddle_w * 0.5 + WALL_PAD, CANVAS_SIZE.x - _paddle_w * 0.5 - WALL_PAD)
	var paddle_rect := Rect2(_paddle_x - _paddle_w * 0.5, 360, _paddle_w, 13)
	var r_ball := 6.5

	for bi in range(_balls.size() - 1, -1, -1):
		var b: Dictionary = _balls[bi]
		if bool(b["stuck"]):
			b["pos"] = Vector2(_paddle_x, paddle_rect.position.y - r_ball - 1.0)
			continue

		var trail: Array = b["trail"]
		trail.push_front(b["pos"])
		if trail.size() > 8:
			trail.pop_back()

		var sub_dt := delta * 0.5
		var p: Vector2 = b["pos"]
		var v: Vector2 = b["vel"]
		for _sub in range(2):
			p += v * sub_dt
			if p.x < WALL_PAD + r_ball:
				p.x = WALL_PAD + r_ball; v.x = absf(v.x); AudioSfx.play_ricochet()
			elif p.x > CANVAS_SIZE.x - WALL_PAD - r_ball:
				p.x = CANVAS_SIZE.x - WALL_PAD - r_ball; v.x = -absf(v.x); AudioSfx.play_ricochet()
			if p.y < WALL_PAD + r_ball:
				p.y = WALL_PAD + r_ball; v.y = absf(v.y); AudioSfx.play_ricochet()

			if v.y > 0.0 and p.y + r_ball >= paddle_rect.position.y and p.y - r_ball <= paddle_rect.end.y and p.x >= paddle_rect.position.x - r_ball and p.x <= paddle_rect.end.x + r_ball:
				var hit_off := clampf((p.x - _paddle_x) / (_paddle_w * 0.5), -0.95, 0.95)
				var spd := clampf(v.length() * 1.015, 305.0, 510.0)
				v = Vector2(sin(hit_off * 1.05), -cos(hit_off * 1.05)).normalized() * spd
				p.y = paddle_rect.position.y - r_ball - 1.0
				AudioSfx.play_paddle_hit(hit_off)

			for k in range(_bricks.size() - 1, -1, -1):
				var br: Rect2 = _bricks[k]["rect"]
				var closest := Vector2(clampf(p.x, br.position.x, br.end.x), clampf(p.y, br.position.y, br.end.y))
				var diff := p - closest
				if diff.length_squared() <= r_ball * r_ball:
					if absf(diff.x) > absf(diff.y):
						v.x = absf(v.x) if p.x > br.get_center().x else -absf(v.x)
					else:
						v.y = absf(v.y) if p.y > br.get_center().y else -absf(v.y)
					_bricks[k]["hp"] = int(_bricks[k]["hp"]) - 1
					if int(_bricks[k]["hp"]) <= 0:
						_emit_sparks(br.get_center(), _bricks[k]["color"])
						if randf() < 0.22:
							var rk := randf()
							_drops.append({"pos": br.get_center(), "kind": "life" if rk < 0.16 else ("wide" if rk < 0.6 else "multi")})
						_bricks.remove_at(k)
						add_score(30)
						AudioSfx.play_brick_break()
					else:
						_bricks[k]["color"] = (_bricks[k]["color"] as Color).darkened(0.25)
						AudioSfx.play_ricochet()
					break

		b["pos"] = p; b["vel"] = v
		if p.y > CANVAS_SIZE.y + 14:
			_balls.remove_at(bi)

	for di in range(_drops.size() - 1, -1, -1):
		var d: Dictionary = _drops[di]
		var dp: Vector2 = d["pos"] + Vector2(0, 130.0 * delta)
		d["pos"] = dp
		if paddle_rect.grow(8.0).has_point(dp):
			var knd := str(d["kind"])
			if knd == "wide": _paddle_w = 148.0; _wide_timer = 10.0
			elif knd == "life": _lives += 1
			elif not _balls.is_empty():
				var ref_b: Dictionary = _balls[0]
				_balls.append({"pos": ref_b["pos"], "vel": (ref_b["vel"] as Vector2).rotated(0.42), "stuck": false, "trail": []})
			add_score(50)
			AudioSfx.play_powerup()
			_drops.remove_at(di)
		elif dp.y > CANVAS_SIZE.y + 12:
			_drops.remove_at(di)

	if _balls.is_empty():
		_lives -= 1
		AudioSfx.play_hit()
		if _lives <= 0:
			game_over = true
			status_changed.emit("Кінець гри!")
		else:
			_spawn_ball()

	if _bricks.is_empty():
		_level += 1
		add_score(250)
		AudioSfx.play_fanfare()
		_build_level()
		_spawn_ball()

	status_changed.emit("Рівень %d  |  Життів: %d" % [_level, _lives])
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, CANVAS_SIZE), Color(0.03, 0.04, 0.09))
	# Cyber neon grid backdrop
	var g_shift := fmod(_anim_t * 14.0, 32.0)
	for gx in range(10, 630, 32):
		draw_line(Vector2(gx, 10), Vector2(gx, 396), Color(0.10, 0.16, 0.30, 0.35), 1.0)
	for gy in range(10, 396, 32):
		draw_line(Vector2(10, gy + g_shift * 0.5), Vector2(630, gy + g_shift * 0.5), Color(0.10, 0.16, 0.30, 0.25), 1.0)
	draw_rect(Rect2(WALL_PAD, WALL_PAD, CANVAS_SIZE.x - WALL_PAD * 2.0, CANVAS_SIZE.y - WALL_PAD), Color(0.28, 0.56, 0.92), false, 3.0)

	for br in _bricks:
		var r: Rect2 = br["rect"]
		var col: Color = br["color"]
		draw_rect(Rect2(r.position + Vector2(2, 3), r.size), Color(0, 0, 0, 0.35))
		draw_rect(r, col)
		draw_rect(Rect2(r.position + Vector2(2, 2), Vector2(r.size.x - 4, 4)), Color(1, 1, 1, 0.28))
		draw_line(r.position, r.position + Vector2(r.size.x, 0), col.lightened(0.55), 1.8)
		draw_line(r.position + Vector2(0, r.size.y), r.end, col.darkened(0.5), 1.8)
		if int(br["max_hp"]) > 1:
			draw_rect(r.grow(-2.5), Color(0.95, 0.96, 1.0, 0.55), false, 1.0)

	var f := ThemeDB.fallback_font
	for d in _drops:
		var dp: Vector2 = d["pos"]
		var knd := str(d["kind"])
		var dcol := Color(0.95, 0.85, 0.25) if knd == "wide" else (Color(0.95, 0.28, 0.36) if knd == "life" else Color(0.30, 0.92, 0.96))
		draw_rect(Rect2(dp - Vector2(13, 8), Vector2(26, 16)), dcol)
		draw_rect(Rect2(dp - Vector2(13, 8), Vector2(26, 16)), Color.WHITE, false, 1.2)
		draw_string(f, dp + Vector2(-4, 4), "L" if knd == "life" else ("W" if knd == "wide" else "M"), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.BLACK)

	for sp in _sparks:
		draw_circle(sp["pos"], 2.5, sp["col"])

	var pr := Rect2(_paddle_x - _paddle_w * 0.5, 360, _paddle_w, 13)
	draw_rect(Rect2(pr.position + Vector2(0, 3), pr.size), Color(0.24, 0.72, 1.0, 0.28))
	draw_rect(pr, Color(0.84, 0.88, 0.96))
	draw_rect(Rect2(pr.position.x + 12, pr.position.y + 2, pr.size.x - 24, 4), Color(1, 1, 1, 0.45))
	draw_rect(Rect2(pr.position.x, pr.position.y, 13, 13), Color(0.95, 0.32, 0.24))
	draw_rect(Rect2(pr.end.x - 13, pr.position.y, 13, 13), Color(0.95, 0.32, 0.24))

	for b in _balls:
		var trail: Array = b["trail"]
		for ti in range(trail.size()):
			var a := 0.48 - float(ti) * 0.055
			draw_circle(trail[ti], maxf(2.0, 6.2 - ti * 0.65), Color(0.45, 0.88, 1.0, maxf(0.05, a)))
		draw_circle(b["pos"], 6.6, Color(0.98, 0.98, 1.0))
		draw_circle((b["pos"] as Vector2) + Vector2(-2, -2), 2.2, Color(0.60, 0.95, 1.0))

	draw_game_over_banner()
