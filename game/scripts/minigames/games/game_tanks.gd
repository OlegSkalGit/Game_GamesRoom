extends MinigameBase

const COLS := 16
const ROWS := 12
const CELL := 32.0
const OX := 64.0
const OY := 8.0

# 0=empty, 1=brick, 2=steel, 3=base eagle, 4=water moat, 5=camo foliage
var _grid: Array = []
var _p_pos: Vector2 = Vector2(OX + 5 * CELL + 16, OY + 10 * CELL + 16)
var _p_dir: Vector2 = Vector2(0, -1)
var _shoot_cd: float = 0.0
var _lives: int = 3
var _wave: int = 1
var _bullets: Array[Dictionary] = []
var _enemies: Array[Dictionary] = []
var _booms: Array[Dictionary] = []
var _anim_t: float = 0.0


func get_game_title() -> String:
	return "Танчики"


func get_controls_hint() -> String:
	return "WASD / Стрілки — танк | Пробіл — постріл | Захищайте штаб! | R — заново | Esc — вийти"


func reset_game() -> void:
	_lives = 3; _wave = 1
	_build_map()
	_p_pos = Vector2(OX + 5 * CELL + 16, OY + 10 * CELL + 16)
	_p_dir = Vector2(0, -1)
	_bullets.clear(); _booms.clear()
	_spawn_enemies()
	super.reset_game()


func _build_map() -> void:
	_grid = []
	var lv := (_wave - 1) % 3
	for r in range(ROWS):
		var row := []
		for c in range(COLS):
			if r == 11 and c in [7, 8]:
				row.append(3)
			elif (r == 10 and c in [6, 7, 8, 9]) or (r == 11 and c in [6, 9]):
				row.append(1)
			elif lv == 0 and r in [2, 3, 6, 7] and c in [2, 3, 5, 10, 12, 13]:
				row.append(1)
			elif lv == 0 and r == 5 and c in [7, 8]:
				row.append(2)
			elif lv == 1 and r == 5 and c in [2, 3, 12, 13]:
				row.append(4)
			elif lv == 1 and r in [3, 4, 7] and c in [5, 6, 9, 10]:
				row.append(5 if r == 7 else 1)
			elif lv == 1 and r == 2 and c in [7, 8]:
				row.append(2)
			elif lv == 2 and ((r == 4 and c in [4, 5, 10, 11]) or (r == 7 and c in [2, 13])):
				row.append(2)
			elif lv == 2 and r in [2, 6, 8] and c in [3, 6, 9, 12]:
				row.append(5 if r == 6 else 1)
			elif r == 4 and c in [1, 14]:
				row.append(5)
			else:
				row.append(0)
		_grid.append(row)


func _spawn_enemies() -> void:
	_enemies.clear()
	for i in range(mini(3 + _wave, 6)):
		var col := 1 + (i * 3) % 14
		_enemies.append({
			"pos": Vector2(OX + col * CELL + 16, OY + 1 * CELL + 16),
			"dir": Vector2(0, 1),
			"fire_t": randf_range(0.8, 2.0),
			"turn_t": randf_range(0.6, 1.8)
		})


func _collides_world(pos: Vector2, half: float) -> bool:
	var min_x := pos.x - OX - half
	var max_x := pos.x - OX + half
	var min_y := pos.y - OY - half
	var max_y := pos.y - OY + half
	if min_x < 1.0 or max_x > COLS * CELL - 1.0 or min_y < 1.0 or max_y > ROWS * CELL - 1.0:
		return true
	for r in range(maxi(0, int(min_y / CELL)), mini(ROWS, int(max_y / CELL) + 1)):
		for c in range(maxi(0, int(min_x / CELL)), mini(COLS, int(max_x / CELL) + 1)):
			var gt := int(_grid[r][c])
			if gt in [1, 2, 3, 4]:
				return true
	return false


func step_game(delta: float) -> void:
	_anim_t += delta
	for i in range(_booms.size() - 1, -1, -1):
		_booms[i]["t"] = float(_booms[i]["t"]) - delta
		if float(_booms[i]["t"]) <= 0.0:
			_booms.remove_at(i)
	if game_over:
		queue_redraw()
		return

	var mv := Vector2.ZERO
	if is_left_held(): mv = Vector2(-1, 0)
	elif is_right_held(): mv = Vector2(1, 0)
	elif is_up_held(): mv = Vector2(0, -1)
	elif is_down_held(): mv = Vector2(0, 1)

	if mv != Vector2.ZERO:
		_p_dir = mv
		var np := _p_pos + mv * 124.0 * delta
		if not _collides_world(np, 12.5):
			_p_pos = np

	_shoot_cd = maxf(0.0, _shoot_cd - delta)
	if is_action_held() and _shoot_cd <= 0.0:
		_shoot_cd = 0.34
		_bullets.append({"pos": _p_pos + _p_dir * 13.0, "vel": _p_dir * 310.0, "from_player": true})
		AudioSfx.play_explosion()

	for e in _enemies:
		var ep: Vector2 = e["pos"]
		var ed: Vector2 = e["dir"]
		var next_ep := ep + ed * 80.0 * delta
		e["turn_t"] = float(e["turn_t"]) - delta
		if _collides_world(next_ep, 12.5) or float(e["turn_t"]) <= 0.0:
			e["turn_t"] = randf_range(0.8, 2.2)
			var dirs := [Vector2(0, 1), Vector2(1, 0), Vector2(-1, 0), Vector2(0, -1)]
			e["dir"] = dirs[randi() % dirs.size()]
		else:
			e["pos"] = next_ep

		e["fire_t"] = float(e["fire_t"]) - delta
		if float(e["fire_t"]) <= 0.0:
			e["fire_t"] = randf_range(1.0, 2.2)
			_bullets.append({"pos": (e["pos"] as Vector2) + ed * 13.0, "vel": ed * 255.0, "from_player": false})

	for bi in range(_bullets.size() - 1, -1, -1):
		var b: Dictionary = _bullets[bi]
		var bp: Vector2 = b["pos"] + (b["vel"] as Vector2) * delta
		b["pos"] = bp
		if bp.x < OX + 3 or bp.x > OX + COLS * CELL - 3 or bp.y < OY + 3 or bp.y > OY + ROWS * CELL - 3:
			_bullets.remove_at(bi); continue
		var gc := int((bp.x - OX) / CELL)
		var gr := int((bp.y - OY) / CELL)
		if gr >= 0 and gr < ROWS and gc >= 0 and gc < COLS:
			var tile := int(_grid[gr][gc])
			if tile == 1:
				_grid[gr][gc] = 0
				_booms.append({"pos": bp, "t": 0.25})
				AudioSfx.play_brick_break()
				_bullets.remove_at(bi); continue
			elif tile == 2:
				_booms.append({"pos": bp, "t": 0.16})
				AudioSfx.play_ricochet()
				_bullets.remove_at(bi); continue
			elif tile == 3:
				_grid[gr][gc] = 0
				_booms.append({"pos": bp, "t": 0.45})
				_bullets.remove_at(bi)
				game_over = true
				AudioSfx.play_hit()
				status_changed.emit("ШТАБ ЗНИЩЕНО!")
				continue

		if bool(b["from_player"]):
			var hit_e := false
			for ei in range(_enemies.size() - 1, -1, -1):
				if bp.distance_to(_enemies[ei]["pos"]) < 15.0:
					_booms.append({"pos": _enemies[ei]["pos"], "t": 0.35})
					_enemies.remove_at(ei)
					add_score(120)
					AudioSfx.play_coin()
					hit_e = true; break
			if hit_e:
				_bullets.remove_at(bi)
		else:
			if bp.distance_to(_p_pos) < 15.0:
				_booms.append({"pos": _p_pos, "t": 0.35})
				_bullets.remove_at(bi)
				_lives -= 1
				AudioSfx.play_hit()
				if _lives <= 0:
					game_over = true
					status_changed.emit("Танк знищено!")
				else:
					_p_pos = Vector2(OX + 5 * CELL + 16, OY + 10 * CELL + 16)

	if _enemies.is_empty() and not game_over:
		_wave += 1
		add_score(250)
		AudioSfx.play_goal()
		_build_map()
		_spawn_enemies()

	if not game_over:
		status_changed.emit("Хвиля %d  |  Життів: %d" % [_wave, _lives])
	queue_redraw()


func _draw_tank(pos: Vector2, dir: Vector2, col: Color) -> void:
	# Treads + armored hull + turret + cannon strictly within 13.5px radius
	var perp := Vector2(-dir.y, dir.x)
	for side: float in [-1.0, 1.0]:
		var tc: Vector2 = pos + perp * (9.5 * side)
		var tread_sz := Vector2(6, 23) if absf(dir.y) > 0.5 else Vector2(23, 6)
		draw_rect(Rect2(tc - tread_sz * 0.5, tread_sz), Color(0.16, 0.16, 0.18))
	draw_rect(Rect2(pos - Vector2(9, 9), Vector2(18, 18)), col)
	draw_rect(Rect2(pos - Vector2(9, 9), Vector2(18, 18)), col.darkened(0.4), false, 1.4)
	draw_circle(pos, 5.5, col.lightened(0.22))
	draw_line(pos, pos + dir * 13.0, col.lightened(0.45), 3.4)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, CANVAS_SIZE), Color(0.06, 0.06, 0.07))
	draw_rect(Rect2(OX, OY, COLS * CELL, ROWS * CELL), Color(0.09, 0.11, 0.09))
	draw_rect(Rect2(OX - 2, OY - 2, COLS * CELL + 4, ROWS * CELL + 4), Color(0.60, 0.56, 0.42), false, 2.0)
	for r in range(ROWS):
		for c in range(COLS):
			var t := int(_grid[r][c])
			var p := Vector2(OX + c * CELL, OY + r * CELL)
			if t == 1:
				draw_rect(Rect2(p + Vector2(1, 1), Vector2(CELL - 2, CELL - 2)), Color(0.68, 0.28, 0.14))
				draw_line(p + Vector2(1, CELL * 0.5), p + Vector2(CELL - 1, CELL * 0.5), Color(0.32, 0.14, 0.06), 2.0)
				draw_line(p + Vector2(CELL * 0.5, 1), p + Vector2(CELL * 0.5, CELL * 0.5), Color(0.32, 0.14, 0.06), 2.0)
			elif t == 2:
				draw_rect(Rect2(p + Vector2(1, 1), Vector2(CELL - 2, CELL - 2)), Color(0.68, 0.72, 0.78))
				draw_rect(Rect2(p + Vector2(5, 5), Vector2(CELL - 10, CELL - 10)), Color(0.86, 0.90, 0.96))
			elif t == 4:
				draw_rect(Rect2(p, Vector2(CELL, CELL)), Color(0.10, 0.34, 0.68))
				draw_line(p + Vector2(4, 10 + sin(_anim_t * 3.0) * 2.0), p + Vector2(CELL - 4, 10 + sin(_anim_t * 3.0) * 2.0), Color(0.45, 0.78, 0.98), 2.0)
				draw_line(p + Vector2(6, 22 - sin(_anim_t * 3.0) * 2.0), p + Vector2(CELL - 6, 22 - sin(_anim_t * 3.0) * 2.0), Color(0.45, 0.78, 0.98), 2.0)
			elif t == 3:
				draw_rect(Rect2(p + Vector2(2, 2), Vector2(CELL - 4, CELL - 4)), Color(0.18, 0.16, 0.14))
				draw_colored_polygon(PackedVector2Array([
					p + Vector2(16, 4), p + Vector2(27, 14), p + Vector2(22, 26),
					p + Vector2(16, 22), p + Vector2(10, 26), p + Vector2(5, 14)
				]), Color(0.95, 0.78, 0.20))

	_draw_tank(_p_pos, _p_dir, Color(0.84, 0.70, 0.22))
	for e in _enemies:
		_draw_tank(e["pos"], e["dir"], Color(0.74, 0.28, 0.26) if _wave > 1 else Color(0.66, 0.72, 0.78))
	for r in range(ROWS):
		for c in range(COLS):
			if int(_grid[r][c]) == 5:
				var fp := Vector2(OX + c * CELL, OY + r * CELL)
				draw_rect(Rect2(fp + Vector2(2, 2), Vector2(CELL - 4, CELL - 4)), Color(0.14, 0.48, 0.20, 0.85))
				draw_circle(fp + Vector2(10, 12), 7.0, Color(0.22, 0.64, 0.28, 0.9))
				draw_circle(fp + Vector2(22, 20), 6.5, Color(0.18, 0.56, 0.22, 0.9))
	for b in _bullets:
		draw_circle(b["pos"], 3.5, Color(1.0, 0.94, 0.35))
	for bm in _booms:
		var t := float(bm["t"])
		draw_circle(bm["pos"], (0.35 - t) * 55.0 + 4.0, Color(1.0, 0.55, 0.14, t * 2.5))
	draw_game_over_banner()
