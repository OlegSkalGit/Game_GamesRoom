extends MinigameBase

const COLS := 15
const ROWS := 11
const CELL := 34.0
const OX := 65.0
const OY := 13.0
const MOVE_DT := 0.135

var _map: Array = []
var _p_pos: Vector2i = Vector2i(1, 1)
var _p_vis: Vector2 = Vector2(1, 1)
var _move_cd: float = 0.0
var _bomb_range: int = 2
var _max_bombs: int = 2
var _bombs: Array[Dictionary] = []
var _flames: Array[Dictionary] = []
var _enemies: Array[Dictionary] = []
var _powerups: Array[Dictionary] = []
var _anim_t: float = 0.0
var _stage: int = 1


func get_game_title() -> String:
	return "Бомбермен"


func get_controls_hint() -> String:
	return "WASD або Стрілки — рух | Пробіл — бомба | R — заново | Esc — вийти"


func reset_game() -> void:
	_stage = 1
	_start_stage()
	super.reset_game()


func _start_stage() -> void:
	_map = []
	for r in range(ROWS):
		var row := []
		for c in range(COLS):
			if r == 0 or r == ROWS - 1 or c == 0 or c == COLS - 1 or (r % 2 == 0 and c % 2 == 0):
				row.append(1)
			elif (r <= 2 and c <= 2):
				row.append(0)
			elif randf() < 0.52:
				row.append(2)
			else:
				row.append(0)
		_map.append(row)
	_p_pos = Vector2i(1, 1); _p_vis = Vector2(1, 1)
	_bomb_range = 2; _max_bombs = 2
	_bombs.clear(); _flames.clear(); _powerups.clear()
	_enemies = [
		{"pos": Vector2i(COLS - 2, 1), "vis": Vector2(COLS - 2, 1), "timer": 0.0, "dir": Vector2i(-1, 0)},
		{"pos": Vector2i(COLS - 2, ROWS - 2), "vis": Vector2(COLS - 2, ROWS - 2), "timer": 0.0, "dir": Vector2i(0, -1)},
		{"pos": Vector2i(1, ROWS - 2), "vis": Vector2(1, ROWS - 2), "timer": 0.0, "dir": Vector2i(1, 0)}
	]
	for e in _enemies:
		var p: Vector2i = e["pos"]
		_map[p.y][p.x] = 0
		if _map[p.y][p.x - 1] == 2: _map[p.y][p.x - 1] = 0
	status_changed.emit("Етап %d  |  Бомб: %d  |  Сила: %d" % [_stage, _max_bombs, _bomb_range])


func _is_free(p: Vector2i) -> bool:
	if p.x < 0 or p.x >= COLS or p.y < 0 or p.y >= ROWS:
		return false
	if _map[p.y][p.x] != 0:
		return false
	for b in _bombs:
		if b["pos"] == p:
			return false
	return true


func on_key_pressed(phys_key: int) -> void:
	if game_over:
		return
	if is_action_key(phys_key) and _bombs.size() < _max_bombs:
		for b in _bombs:
			if b["pos"] == _p_pos:
				return
		_bombs.append({"pos": _p_pos, "fuse": 2.2, "range": _bomb_range})
		AudioSfx.play_bomb_place()
		queue_redraw()


func _detonate(bomb: Dictionary) -> void:
	AudioSfx.play_explosion()
	var origin: Vector2i = bomb["pos"]
	var rng_len: int = int(bomb["range"])
	_flames.append({"pos": origin, "t": 0.45})
	for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		for step in range(1, rng_len + 1):
			var p: Vector2i = origin + d * step
			if p.x < 0 or p.x >= COLS or p.y < 0 or p.y >= ROWS:
				break
			var tile := int(_map[p.y][p.x])
			if tile == 1:
				break
			_flames.append({"pos": p, "t": 0.45})
			if tile == 2:
				_map[p.y][p.x] = 0
				add_score(20)
				if randf() < 0.28:
					_powerups.append({"pos": p, "kind": "range" if randf() < 0.5 else "bomb"})
				break


func step_game(delta: float) -> void:
	_anim_t += delta
	if game_over:
		queue_redraw()
		return
	_move_cd = maxf(0.0, _move_cd - delta)
	if _move_cd <= 0.0:
		var mv := Vector2i.ZERO
		if is_left_held(): mv.x = -1
		elif is_right_held(): mv.x = 1
		elif is_up_held(): mv.y = -1
		elif is_down_held(): mv.y = 1
		if mv != Vector2i.ZERO and _is_free(_p_pos + mv):
			_p_pos += mv
			_move_cd = MOVE_DT
			for i in range(_powerups.size() - 1, -1, -1):
				if _powerups[i]["pos"] == _p_pos:
					if _powerups[i]["kind"] == "range": _bomb_range += 1
					else: _max_bombs += 1
					add_score(80)
					AudioSfx.play_powerup()
					_powerups.remove_at(i)

	_p_vis = _p_vis.lerp(Vector2(_p_pos), minf(delta * 18.0, 1.0))

	for i in range(_bombs.size() - 1, -1, -1):
		_bombs[i]["fuse"] = float(_bombs[i]["fuse"]) - delta
		if float(_bombs[i]["fuse"]) <= 0.0:
			var b: Dictionary = _bombs[i]
			_bombs.remove_at(i)
			_detonate(b)

	for i in range(_flames.size() - 1, -1, -1):
		_flames[i]["t"] = float(_flames[i]["t"]) - delta
		var fp: Vector2i = _flames[i]["pos"]
		if fp == _p_pos:
			game_over = true
			AudioSfx.play_hit()
			status_changed.emit("Вибух!")
		for j in range(_enemies.size() - 1, -1, -1):
			if _enemies[j]["pos"] == fp:
				_enemies.remove_at(j)
				add_score(200)
				AudioSfx.play_goal()
		if float(_flames[i]["t"]) <= 0.0:
			_flames.remove_at(i)

	for e in _enemies:
		e["timer"] = float(e["timer"]) + delta
		if float(e["timer"]) >= 0.40:
			e["timer"] = 0.0
			var ep: Vector2i = e["pos"]
			var d: Vector2i = e["dir"]
			if _is_free(ep + d) and randf() < 0.78:
				e["pos"] = ep + d
			else:
				var dirs := [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]
				dirs.shuffle()
				for nd in dirs:
					if _is_free(ep + nd):
						e["dir"] = nd
						e["pos"] = ep + nd
						break
		e["vis"] = (e["vis"] as Vector2).lerp(Vector2(e["pos"]), minf(delta * 10.0, 1.0))
		if e["pos"] == _p_pos:
			game_over = true
			AudioSfx.play_hit()
			status_changed.emit("Ворог торкнувся!")

	if _enemies.is_empty():
		add_score(400)
		AudioSfx.play_fanfare()
		_stage += 1
		_start_stage()
		status_changed.emit("Етап %d! Нова арена!" % _stage)

	queue_redraw()


func _cell_pt(p: Vector2) -> Vector2:
	return Vector2(OX + p.x * CELL + CELL * 0.5, OY + p.y * CELL + CELL * 0.5)


func _draw() -> void:
	var bgs: Array[Color] = [Color(0.16, 0.42, 0.18), Color(0.18, 0.24, 0.34), Color(0.28, 0.16, 0.14)]
	var arena_bg: Color = bgs[(_stage - 1) % 3]
	draw_rect(Rect2(Vector2.ZERO, CANVAS_SIZE), arena_bg.darkened(0.65))
	draw_rect(Rect2(OX, OY, COLS * CELL, ROWS * CELL), arena_bg)
	for r in range(ROWS):
		for c in range(COLS):
			var p := Vector2(OX + c * CELL, OY + r * CELL)
			var tile := int(_map[r][c])
			if tile == 1:
				draw_rect(Rect2(p + Vector2(1, 1), Vector2(CELL - 2, CELL - 2)), Color(0.42, 0.44, 0.50))
				draw_rect(Rect2(p + Vector2(4, 4), Vector2(CELL - 8, CELL - 8)), Color(0.64, 0.67, 0.74))
				draw_line(p + Vector2(4, 4), p + Vector2(CELL - 4, 4), Color(0.84, 0.87, 0.94), 1.5)
			elif tile == 2:
				draw_rect(Rect2(p + Vector2(1, 1), Vector2(CELL - 2, CELL - 2)), Color(0.72, 0.36, 0.16))
				draw_line(p + Vector2(1, CELL * 0.5), p + Vector2(CELL - 1, CELL * 0.5), Color(0.42, 0.18, 0.06), 2.0)
				draw_line(p + Vector2(CELL * 0.5, 1), p + Vector2(CELL * 0.5, CELL * 0.5), Color(0.42, 0.18, 0.06), 2.0)
				draw_rect(Rect2(p + Vector2(2, 2), Vector2(CELL - 4, CELL - 4)), Color(0.42, 0.18, 0.06), false, 1.5)

	for pu in _powerups:
		var pp := _cell_pt(Vector2(pu["pos"]))
		draw_rect(Rect2(pp - Vector2(10, 10), Vector2(20, 20)), Color(0.95, 0.80, 0.18) if pu["kind"] == "range" else Color(0.28, 0.78, 0.96))
		draw_string(ThemeDB.fallback_font, pp + Vector2(-4, 5), "F" if pu["kind"] == "range" else "B", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.BLACK)

	for b in _bombs:
		var bp := _cell_pt(Vector2(b["pos"]))
		var pulse := 1.0 + sin(_anim_t * 14.0) * 0.12
		draw_circle(bp, 11.5 * pulse, Color(0.10, 0.10, 0.14))
		draw_circle(bp + Vector2(-3, -4), 3.0, Color(0.45, 0.45, 0.52))
		draw_circle(bp + Vector2(6, -9), 3.8, Color(1.0, 0.75, 0.15))

	for fl in _flames:
		var fp := Vector2(OX + fl["pos"].x * CELL, OY + fl["pos"].y * CELL)
		draw_rect(Rect2(fp + Vector2(2, 2), Vector2(CELL - 4, CELL - 4)), Color(1.0, 0.55, 0.10, 0.92))
		draw_rect(Rect2(fp + Vector2(7, 7), Vector2(CELL - 14, CELL - 14)), Color(1.0, 0.92, 0.45, 0.95))

	for e in _enemies:
		var ep := _cell_pt(e["vis"])
		draw_circle(ep, 11.5, Color(0.92, 0.25, 0.28))
		draw_circle(ep + Vector2(-4, -3), 2.8, Color.WHITE)
		draw_circle(ep + Vector2(4, -3), 2.8, Color.WHITE)
		draw_circle(ep + Vector2(-4, -3), 1.3, Color.BLACK)
		draw_circle(ep + Vector2(4, -3), 1.3, Color.BLACK)

	# Bomberman character
	var pl := _cell_pt(_p_vis)
	draw_circle(pl + Vector2(0, 4), 8.5, Color(0.16, 0.44, 0.94))
	draw_circle(pl + Vector2(0, -4), 9.5, Color(0.96, 0.96, 0.98))
	draw_rect(Rect2(pl + Vector2(-6, -7), Vector2(12, 6)), Color(0.96, 0.80, 0.64))
	draw_rect(Rect2(pl + Vector2(-3, -6), Vector2(2, 3)), Color.BLACK)
	draw_rect(Rect2(pl + Vector2(2, -6), Vector2(2, 3)), Color.BLACK)
	draw_circle(pl + Vector2(0, -14), 3.0, Color(0.92, 0.30, 0.52))
	draw_game_over_banner()
