extends MinigameBase

const ROWS := 8
const COLS := 8
const CELL := 43.0
const OX := 52.0
const OY := 28.0
const GEM_COLORS: Array[Color] = [
	Color(0.96, 0.22, 0.26), # Ruby
	Color(0.20, 0.58, 0.98), # Sapphire
	Color(0.20, 0.86, 0.42), # Emerald
	Color(0.98, 0.80, 0.14), # Topaz
	Color(0.76, 0.28, 0.96), # Amethyst
	Color(0.22, 0.90, 0.92)  # Diamond
]

var _grid: Array = []
var _sel: Vector2i = Vector2i(-1, -1)
var _cursor: Vector2i = Vector2i(3, 3)
var _moves_left: int = 24
var _level: int = 1
var _target: int = 800
var _combo: int = 0
var _sparks: Array[Dictionary] = []
var _popups: Array[Dictionary] = []
var _anim_t: float = 0.0


func get_game_title() -> String:
	return "Самоцвіти"


func get_controls_hint() -> String:
	return "Миша або WASD + Пробіл — міняйте сусідні камені місцями | R — заново | Esc — вийти"


func reset_game() -> void:
	_level = 1
	_target = 800
	_moves_left = 24
	_sel = Vector2i(-1, -1)
	_cursor = Vector2i(3, 3)
	_sparks.clear()
	_popups.clear()
	_init_board()
	super.reset_game()
	status_changed.emit("Рівень %d  |  Ціль: %d  |  Ходів: %d" % [_level, _target, _moves_left])


func _init_board() -> void:
	_grid = []
	for r in range(ROWS):
		var row: Array = []
		for c in range(COLS):
			var pick := randi() % GEM_COLORS.size()
			while (c >= 2 and int(row[c - 1]) == pick and int(row[c - 2]) == pick) or (r >= 2 and int(_grid[r - 1][c]) == pick and int(_grid[r - 2][c]) == pick):
				pick = (pick + 1) % GEM_COLORS.size()
			row.append(pick)
		_grid.append(row)


func _find_matches() -> Array[Vector2i]:
	var matched: Dictionary = {}
	for r in range(ROWS):
		var run := 1
		for c in range(1, COLS):
			if int(_grid[r][c]) == int(_grid[r][c - 1]) and int(_grid[r][c]) >= 0:
				run += 1
			else:
				if run >= 3:
					for k in range(c - run, c):
						matched[Vector2i(k, r)] = true
				run = 1
		if run >= 3:
			for k in range(COLS - run, COLS):
				matched[Vector2i(k, r)] = true

	for c in range(COLS):
		var run := 1
		for r in range(1, ROWS):
			if int(_grid[r][c]) == int(_grid[r - 1][c]) and int(_grid[r][c]) >= 0:
				run += 1
			else:
				if run >= 3:
					for k in range(r - run, r):
						matched[Vector2i(c, k)] = true
				run = 1
		if run >= 3:
			for k in range(ROWS - run, ROWS):
				matched[Vector2i(c, k)] = true

	var out: Array[Vector2i] = []
	for k in matched.keys():
		out.append(k)
	return out


func _cell_center(c: int, r: int) -> Vector2:
	return Vector2(OX + (float(c) + 0.5) * CELL, OY + (float(r) + 0.5) * CELL)


func _try_swap(a: Vector2i, b: Vector2i) -> void:
	if game_over:
		return
	if abs(a.x - b.x) + abs(a.y - b.y) != 1:
		return
	var tmp := int(_grid[a.y][a.x])
	_grid[a.y][a.x] = int(_grid[b.y][b.x])
	_grid[b.y][b.x] = tmp

	var m := _find_matches()
	if m.is_empty():
		_grid[b.y][b.x] = int(_grid[a.y][a.x])
		_grid[a.y][a.x] = tmp
		AudioSfx.play_hit()
		_sel = Vector2i(-1, -1)
		queue_redraw()
		return

	_moves_left -= 1
	_sel = Vector2i(-1, -1)
	_combo = 0
	while not m.is_empty():
		_combo += 1
		var pts := m.size() * 25 * _combo
		add_score(pts)
		var sum_p := Vector2.ZERO
		for p in m:
			var cp := _cell_center(p.x, p.y)
			sum_p += cp
			var gcol: Color = GEM_COLORS[int(_grid[p.y][p.x]) % GEM_COLORS.size()]
			for _s in range(5):
				var ang := randf() * TAU
				_sparks.append({"pos": cp, "vel": Vector2(cos(ang), sin(ang)) * randf_range(35.0, 120.0), "col": gcol, "t": 0.42})
			_grid[p.y][p.x] = -1
		_popups.append({"pos": sum_p / float(m.size()), "txt": "+%d" % pts + (" x%d!" % _combo if _combo > 1 else ""), "t": 0.70})
		AudioSfx.play_marble_pop(_combo)

		# Gravity fill
		for c in range(COLS):
			var write_r := ROWS - 1
			for r in range(ROWS - 1, -1, -1):
				if int(_grid[r][c]) >= 0:
					_grid[write_r][c] = int(_grid[r][c])
					if write_r != r:
						_grid[r][c] = -1
					write_r -= 1
			while write_r >= 0:
				_grid[write_r][c] = randi() % GEM_COLORS.size()
				write_r -= 1
		m = _find_matches()

	if score >= _target:
		_level += 1
		_target += 700 + _level * 300
		_moves_left += 15
		AudioSfx.play_fanfare()
		_popups.append({"pos": Vector2(OX + 170, OY + 170), "txt": "РІВЕНЬ %d!" % _level, "t": 1.0})
	elif _moves_left <= 0:
		game_over = true
		AudioSfx.play_hit()

	status_changed.emit("Рівень %d  |  Ціль: %d  |  Ходів: %d" % [_level, _target, _moves_left])
	queue_redraw()


func _select_cell(cell: Vector2i) -> void:
	_cursor = cell
	if _sel == Vector2i(-1, -1):
		_sel = cell
		AudioSfx.play_ui_click()
	elif _sel == cell:
		_sel = Vector2i(-1, -1)
		AudioSfx.play_switch()
	elif abs(_sel.x - cell.x) + abs(_sel.y - cell.y) == 1:
		_try_swap(_sel, cell)
	else:
		_sel = cell
		AudioSfx.play_ui_click()
	queue_redraw()


func on_mouse_click(pos: Vector2) -> void:
	if game_over:
		return
	var c := int((pos.x - OX) / CELL)
	var r := int((pos.y - OY) / CELL)
	if c >= 0 and c < COLS and r >= 0 and r < ROWS and pos.x >= OX and pos.y >= OY:
		_select_cell(Vector2i(c, r))


func on_key_pressed(phys_key: int) -> void:
	if game_over:
		return
	if is_left_key(phys_key): _cursor.x = maxi(0, _cursor.x - 1)
	elif is_right_key(phys_key): _cursor.x = mini(COLS - 1, _cursor.x + 1)
	elif is_up_key(phys_key): _cursor.y = maxi(0, _cursor.y - 1)
	elif is_down_key(phys_key): _cursor.y = mini(ROWS - 1, _cursor.y + 1)
	elif is_action_key(phys_key):
		_select_cell(_cursor)
		return
	if _sel != Vector2i(-1, -1) and abs(_sel.x - _cursor.x) + abs(_sel.y - _cursor.y) == 1:
		_try_swap(_sel, _cursor)
	queue_redraw()


func step_game(delta: float) -> void:
	_anim_t += delta
	var dirty := false
	for i in range(_sparks.size() - 1, -1, -1):
		_sparks[i]["t"] = float(_sparks[i]["t"]) - delta
		_sparks[i]["pos"] = (_sparks[i]["pos"] as Vector2) + (_sparks[i]["vel"] as Vector2) * delta
		dirty = true
		if float(_sparks[i]["t"]) <= 0.0:
			_sparks.remove_at(i)
	for i in range(_popups.size() - 1, -1, -1):
		_popups[i]["t"] = float(_popups[i]["t"]) - delta
		_popups[i]["pos"] = (_popups[i]["pos"] as Vector2) + Vector2(0, -30.0 * delta)
		dirty = true
		if float(_popups[i]["t"]) <= 0.0:
			_popups.remove_at(i)
	if dirty or _sel != Vector2i(-1, -1):
		queue_redraw()


func _draw_gem(center: Vector2, kind: int) -> void:
	var c := GEM_COLORS[kind % GEM_COLORS.size()]
	var rad := 15.0
	draw_circle(center + Vector2(2, 3), rad, Color(0, 0, 0, 0.35))
	match kind % 6:
		0, 2:
			var pts := PackedVector2Array()
			for i in range(6):
				var a := float(i) * TAU / 6.0 - PI * 0.5
				pts.append(center + Vector2(cos(a), sin(a)) * rad)
			draw_colored_polygon(pts, c)
			draw_colored_polygon(PackedVector2Array([pts[0], pts[1], center, pts[5]]), c.lightened(0.32))
		1, 4:
			var pts2 := PackedVector2Array([center + Vector2(0, -rad), center + Vector2(rad, 0), center + Vector2(0, rad), center + Vector2(-rad, 0)])
			draw_colored_polygon(pts2, c)
			draw_colored_polygon(PackedVector2Array([pts2[0], pts2[1], center]), c.lightened(0.36))
		_:
			draw_circle(center, rad - 1.0, c)
			draw_circle(center - Vector2(4, 4), 4.5, Color(1, 1, 1, 0.58))
	draw_circle(center - Vector2(3, 4), 2.5, Color(1, 1, 1, 0.72))


func _draw() -> void:
	var f := ThemeDB.fallback_font
	draw_rect(Rect2(Vector2.ZERO, CANVAS_SIZE), Color(0.06, 0.07, 0.12))
	var bw := float(COLS) * CELL
	draw_rect(Rect2(OX - 6, OY - 6, bw + 12, bw + 12), Color(0.14, 0.16, 0.24))
	draw_rect(Rect2(OX - 6, OY - 6, bw + 12, bw + 12), Color(0.86, 0.68, 0.28), false, 2.5)

	for r in range(ROWS):
		for c in range(COLS):
			var cr := Rect2(OX + float(c) * CELL, OY + float(r) * CELL, CELL, CELL)
			draw_rect(cr, Color(0.10, 0.12, 0.19) if (r + c) % 2 == 0 else Color(0.08, 0.10, 0.16))
			if int(_grid[r][c]) >= 0:
				_draw_gem(cr.get_center(), int(_grid[r][c]))

	if _sel != Vector2i(-1, -1):
		var sr := Rect2(OX + float(_sel.x) * CELL + 2, OY + float(_sel.y) * CELL + 2, CELL - 4, CELL - 4)
		draw_rect(sr, Color(1.0, 0.90, 0.25), false, 3.0 + sin(_anim_t * 10.0) * 0.8)
	var cur_r := Rect2(OX + float(_cursor.x) * CELL + 3, OY + float(_cursor.y) * CELL + 3, CELL - 6, CELL - 6)
	draw_rect(cur_r, Color(0.55, 0.90, 1.0, 0.55), false, 1.6)

	for sp in _sparks:
		draw_circle(sp["pos"], 2.8, sp["col"])
	for pp in _popups:
		draw_string(f, pp["pos"] - Vector2(45, 0), str(pp["txt"]), HORIZONTAL_ALIGNMENT_CENTER, 90, 16, Color(1.0, 0.94, 0.36))

	# Right Info Panel
	draw_rect(Rect2(416, 28, 204, 344), Color(0.09, 0.11, 0.16))
	draw_rect(Rect2(416, 28, 204, 344), Color(0.75, 0.60, 0.26), false, 2.0)
	draw_string(f, Vector2(426, 66), "САМОЦВІТИ", HORIZONTAL_ALIGNMENT_CENTER, 184, 22, Color(0.98, 0.84, 0.34))
	draw_string(f, Vector2(426, 114), "Рівень: %d" % _level, HORIZONTAL_ALIGNMENT_CENTER, 184, 18, Color.WHITE)
	draw_string(f, Vector2(426, 152), "Ціль: %d" % _target, HORIZONTAL_ALIGNMENT_CENTER, 184, 16, Color(0.66, 0.92, 0.72))
	draw_string(f, Vector2(426, 194), "Ходів: %d" % _moves_left, HORIZONTAL_ALIGNMENT_CENTER, 184, 19, Color(0.98, 0.65, 0.28) if _moves_left <= 5 else Color(0.95, 0.90, 0.78))
	draw_string(f, Vector2(432, 260), "Збирайте по 3+", HORIZONTAL_ALIGNMENT_CENTER, 172, 14, Color(0.75, 0.80, 0.85))
	draw_string(f, Vector2(432, 282), "однакових каменів", HORIZONTAL_ALIGNMENT_CENTER, 172, 14, Color(0.75, 0.80, 0.85))
	draw_game_over_banner()
