extends MinigameBase

const BOARD_BOX := Rect2(56.0, 26.0, 344.0, 344.0)
const TILE_PALETTE := {
	0: Color(0.24, 0.20, 0.17, 0.55),
	2: Color(0.93, 0.89, 0.84),
	4: Color(0.93, 0.86, 0.72),
	8: Color(0.95, 0.65, 0.40),
	16: Color(0.96, 0.50, 0.30),
	32: Color(0.96, 0.38, 0.26),
	64: Color(0.94, 0.24, 0.18),
	128: Color(0.94, 0.80, 0.36),
	256: Color(0.94, 0.76, 0.26),
	512: Color(0.95, 0.72, 0.18),
	1024: Color(0.96, 0.68, 0.12),
	2048: Color(0.99, 0.78, 0.14),
	4096: Color(0.32, 0.78, 0.96),
	8192: Color(0.66, 0.34, 0.96)
}

var _n: int = 4
var _grid: Array = []
var _prev_grid: Array = []
var _prev_score: int = 0
var _can_undo: bool = false
var _best: int = 0
var _won_2048: bool = false
var _keep_playing: bool = false
var _anim_t: float = 0.0
var _slide_t: float = 0.0
var _moves: Array[Dictionary] = []
var _pop_cells: Dictionary = {}
var _popups: Array[Dictionary] = []
var _sparks: Array[Dictionary] = []
var _drag_active: bool = false
var _drag_start: Vector2 = Vector2.ZERO

const BTN_MODE4 := Rect2(430.0, 178.0, 86.0, 34.0)
const BTN_MODE5 := Rect2(524.0, 178.0, 86.0, 34.0)
const BTN_UNDO := Rect2(430.0, 224.0, 180.0, 36.0)
const BTN_NEW := Rect2(430.0, 270.0, 180.0, 36.0)


func get_game_title() -> String:
	return "2048"


func get_controls_hint() -> String:
	return "WASD / Стрілки або свайп мишею — зсув плиток | M — 4x4/5x5 | Z — скасувати | Esc — вийти"


func reset_game() -> void:
	_grid = []
	for _r in range(_n):
		var row: Array = []
		row.resize(_n)
		row.fill(0)
		_grid.append(row)
	_prev_grid.clear()
	_can_undo = false
	_won_2048 = false
	_keep_playing = false
	_moves.clear()
	_pop_cells.clear()
	_popups.clear()
	_sparks.clear()
	_slide_t = 0.0
	_spawn_tile()
	_spawn_tile()
	super.reset_game()
	status_changed.emit("Режим %dx%d  |  Рекорд: %d" % [_n, _n, _best])


func _clone_grid(src: Array) -> Array:
	var out: Array = []
	for row in src:
		out.append((row as Array).duplicate())
	return out


func _cell_center(r: int, c: int) -> Vector2:
	var pad := 8.0
	var inner := BOARD_BOX.size.x - pad * 2.0
	var step := inner / float(_n)
	return Vector2(BOARD_BOX.position.x + pad + (float(c) + 0.5) * step, BOARD_BOX.position.y + pad + (float(r) + 0.5) * step)


func _cell_size() -> float:
	return (BOARD_BOX.size.x - 16.0) / float(_n) - 8.0


func _spawn_tile() -> void:
	var empties: Array[Vector2i] = []
	for r in range(_n):
		for c in range(_n):
			if int(_grid[r][c]) == 0:
				empties.append(Vector2i(c, r))
	if empties.is_empty():
		return
	var pick := empties[randi() % empties.size()]
	_grid[pick.y][pick.x] = 2 if randf() < 0.9 else 4
	_pop_cells[Vector2i(pick.x, pick.y)] = 1.0


func _add_sparkles(pos: Vector2, col: Color, cnt: int) -> void:
	for _i in range(cnt):
		var ang := randf() * TAU
		var spd := randf_range(35.0, 125.0)
		_sparks.append({"pos": pos, "vel": Vector2(cos(ang), sin(ang)) * spd, "t": 0.42, "col": col})


func _shift(dir: Vector2i) -> void:
	if game_over or (_won_2048 and not _keep_playing):
		return
	var snap := _clone_grid(_grid)
	var snap_score := score
	var moved := false
	var merge_pts := 0
	var new_moves: Array[Dictionary] = []
	var merged_flags: Dictionary = {}

	for line_idx in range(_n):
		var vals: Array[Dictionary] = []
		for step_i in range(_n):
			var r := line_idx if dir.x != 0 else (step_i if dir.y < 0 else _n - 1 - step_i)
			var c := step_i if dir.x < 0 else (_n - 1 - step_i if dir.x > 0 else line_idx)
			var v := int(_grid[r][c])
			if v != 0:
				vals.append({"v": v, "r": r, "c": c})
			_grid[r][c] = 0

		var write_i := 0
		var i := 0
		while i < vals.size():
			var tr := line_idx if dir.x != 0 else (write_i if dir.y < 0 else _n - 1 - write_i)
			var tc := write_i if dir.x < 0 else (_n - 1 - write_i if dir.x > 0 else line_idx)
			var cur_d: Dictionary = vals[i]
			var v_cur := int(cur_d["v"])
			if i + 1 < vals.size() and int(vals[i + 1]["v"]) == v_cur:
				var nxt_d: Dictionary = vals[i + 1]
				var nv := v_cur * 2
				_grid[tr][tc] = nv
				merge_pts += nv
				merged_flags[Vector2i(tc, tr)] = 1.0
				new_moves.append({"from": Vector2i(cur_d["c"], cur_d["r"]), "to": Vector2i(tc, tr), "v": nv})
				new_moves.append({"from": Vector2i(nxt_d["c"], nxt_d["r"]), "to": Vector2i(tc, tr), "v": nv})
				var center := _cell_center(tr, tc)
				_popups.append({"pos": center, "txt": "+%d" % nv, "t": 0.65})
				_add_sparkles(center, TILE_PALETTE.get(nv, Color(1.0, 0.85, 0.25)), 10 if nv >= 128 else 5)
				if nv >= 2048 and not _won_2048:
					_won_2048 = true
					AudioSfx.play_fanfare()
				moved = true
				i += 2
			else:
				_grid[tr][tc] = v_cur
				if int(cur_d["r"]) != tr or int(cur_d["c"]) != tc:
					moved = true
				new_moves.append({"from": Vector2i(cur_d["c"], cur_d["r"]), "to": Vector2i(tc, tr), "v": v_cur})
				i += 1
			write_i += 1

	if not moved:
		_grid = snap
		return

	_prev_grid = snap
	_prev_score = snap_score
	_can_undo = true
	_moves = new_moves
	_slide_t = 1.0
	_pop_cells = merged_flags
	_spawn_tile()

	if merge_pts > 0:
		add_score(merge_pts)
		_best = maxi(_best, score)
		AudioSfx.play_tile_merge(merge_pts)
	else:
		AudioSfx.play_ui_click()

	if _has_no_moves():
		game_over = true
		AudioSfx.play_hit()
		status_changed.emit("Ходів не лишилось! Рекорд: %d" % _best)
	else:
		status_changed.emit("Режим %dx%d  |  Рекорд: %d" % [_n, _n, _best])
	queue_redraw()


func _has_no_moves() -> bool:
	for r in range(_n):
		for c in range(_n):
			var v := int(_grid[r][c])
			if v == 0:
				return false
			if r + 1 < _n and int(_grid[r + 1][c]) == v:
				return false
			if c + 1 < _n and int(_grid[r][c + 1]) == v:
				return false
	return true


func on_key_pressed(phys_key: int) -> void:
	if _won_2048 and not _keep_playing and is_action_key(phys_key):
		_keep_playing = true
		queue_redraw()
		return
	if phys_key == KEY_M:
		_n = 5 if _n == 4 else 4
		reset_game()
		return
	if phys_key == KEY_Z and _can_undo and not _prev_grid.is_empty():
		_grid = _clone_grid(_prev_grid)
		score = _prev_score
		score_changed.emit(score)
		_can_undo = false
		game_over = false
		AudioSfx.play_switch()
		queue_redraw()
		return
	if is_left_key(phys_key): _shift(Vector2i(-1, 0))
	elif is_right_key(phys_key): _shift(Vector2i(1, 0))
	elif is_up_key(phys_key): _shift(Vector2i(0, -1))
	elif is_down_key(phys_key): _shift(Vector2i(0, 1))
	elif is_action_key(phys_key): _shift(Vector2i(1, 0))


func on_mouse_click(pos: Vector2) -> void:
	if BTN_MODE4.has_point(pos):
		_n = 4; reset_game(); AudioSfx.play_ui_click(); return
	if BTN_MODE5.has_point(pos):
		_n = 5; reset_game(); AudioSfx.play_ui_click(); return
	if BTN_UNDO.has_point(pos) and _can_undo and not _prev_grid.is_empty():
		on_key_pressed(KEY_Z); return
	if BTN_NEW.has_point(pos):
		reset_game(); AudioSfx.play_ui_click(); return
	if _won_2048 and not _keep_playing and BOARD_BOX.has_point(pos):
		_keep_playing = true; queue_redraw(); return
	if BOARD_BOX.has_point(pos):
		_drag_active = true
		_drag_start = pos


func on_mouse_release(pos: Vector2) -> void:
	if not _drag_active:
		return
	_drag_active = false
	var dv := pos - _drag_start
	if dv.length() < 20.0:
		return
	if absf(dv.x) > absf(dv.y):
		_shift(Vector2i(1, 0) if dv.x > 0.0 else Vector2i(-1, 0))
	else:
		_shift(Vector2i(0, 1) if dv.y > 0.0 else Vector2i(0, -1))


func step_game(delta: float) -> void:
	_anim_t += delta
	var dirty := false
	if _slide_t > 0.0:
		_slide_t = maxf(0.0, _slide_t - delta * 8.5)
		dirty = true
	for k in _pop_cells.keys():
		_pop_cells[k] = maxf(0.0, float(_pop_cells[k]) - delta * 4.5)
		dirty = true
		if float(_pop_cells[k]) <= 0.0:
			_pop_cells.erase(k)
	for i in range(_popups.size() - 1, -1, -1):
		_popups[i]["t"] = float(_popups[i]["t"]) - delta
		_popups[i]["pos"] = (_popups[i]["pos"] as Vector2) + Vector2(0, -34.0 * delta)
		dirty = true
		if float(_popups[i]["t"]) <= 0.0:
			_popups.remove_at(i)
	for i in range(_sparks.size() - 1, -1, -1):
		_sparks[i]["t"] = float(_sparks[i]["t"]) - delta
		_sparks[i]["pos"] = (_sparks[i]["pos"] as Vector2) + (_sparks[i]["vel"] as Vector2) * delta
		dirty = true
		if float(_sparks[i]["t"]) <= 0.0:
			_sparks.remove_at(i)
	if dirty:
		queue_redraw()


func _draw_gloss_tile(center: Vector2, sz: float, val: int) -> void:
	var half := sz * 0.5
	var rect := Rect2(center - Vector2(half, half), Vector2(sz, sz))
	var col: Color = TILE_PALETTE.get(val, Color(0.86, 0.28, 0.78))
	draw_rect(Rect2(rect.position + Vector2(2, 4), rect.size), Color(0, 0, 0, 0.36))
	draw_rect(rect, col)
	draw_rect(Rect2(rect.position + Vector2(2, 2), Vector2(rect.size.x - 4, rect.size.y * 0.36)), Color(1, 1, 1, 0.16))
	draw_rect(rect, col.lightened(0.40), false, 2.0)
	if val >= 128:
		draw_rect(rect.grow(2.0), Color(col.r, col.g, col.b, 0.32), false, 3.0)
	var f := ThemeDB.fallback_font
	var tc := Color(0.24, 0.20, 0.17) if val <= 4 else Color(0.99, 0.98, 0.94)
	var digits := str(val).length()
	var fs := int(sz * (0.44 if digits <= 2 else (0.34 if digits == 3 else 0.27)))
	draw_string(f, Vector2(rect.position.x, center.y + float(fs) * 0.36), str(val), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, fs, tc)


func _draw() -> void:
	var f := ThemeDB.fallback_font
	draw_rect(Rect2(Vector2.ZERO, CANVAS_SIZE), Color(0.08, 0.06, 0.05))
	# Ambient warm bokeh aura
	draw_circle(Vector2(220, 195), 220.0, Color(0.28, 0.18, 0.09, 0.25))
	# Outer wood & brass board casing
	draw_rect(BOARD_BOX.grow(6.0), Color(0.16, 0.12, 0.09))
	draw_rect(BOARD_BOX.grow(6.0), Color(0.86, 0.68, 0.28), false, 3.0)
	draw_rect(BOARD_BOX, Color(0.20, 0.16, 0.13))

	var sz := _cell_size()
	for r in range(_n):
		for c in range(_n):
			var cc := _cell_center(r, c)
			draw_rect(Rect2(cc - Vector2(sz, sz) * 0.5, Vector2(sz, sz)), TILE_PALETTE[0])

	if _slide_t > 0.0 and not _moves.is_empty():
		var t := 1.0 - _slide_t
		t = 1.0 - pow(1.0 - t, 2.0)
		for m in _moves:
			var from_c := _cell_center((m["from"] as Vector2i).y, (m["from"] as Vector2i).x)
			var to_c := _cell_center((m["to"] as Vector2i).y, (m["to"] as Vector2i).x)
			_draw_gloss_tile(from_c.lerp(to_c, t), sz, int(m["v"]))
	else:
		for r in range(_n):
			for c in range(_n):
				var v := int(_grid[r][c])
				if v > 0:
					var sc := 1.0 + 0.18 * sin(float(_pop_cells.get(Vector2i(c, r), 0.0)) * PI)
					_draw_gloss_tile(_cell_center(r, c), sz * sc, v)

	for sp in _sparks:
		draw_circle(sp["pos"], 2.8, sp["col"])
	for pp in _popups:
		draw_string(f, pp["pos"] - Vector2(36, 0), str(pp["txt"]), HORIZONTAL_ALIGNMENT_CENTER, 72, 16, Color(1.0, 0.94, 0.36, clampf(float(pp["t"]) * 1.8, 0.0, 1.0)))

	# Right Info & Control Panel
	draw_rect(Rect2(416, 26, 206, 344), Color(0.11, 0.09, 0.08))
	draw_rect(Rect2(416, 26, 206, 344), Color(0.75, 0.60, 0.25), false, 2.0)
	draw_string(f, Vector2(426, 62), "2048 • ЛЮКС", HORIZONTAL_ALIGNMENT_CENTER, 186, 22, Color(0.98, 0.84, 0.34))
	draw_rect(Rect2(430, 76, 86, 62), Color(0.16, 0.13, 0.11))
	draw_rect(Rect2(524, 76, 86, 62), Color(0.16, 0.13, 0.11))
	draw_string(f, Vector2(430, 96), "РАХУНОК", HORIZONTAL_ALIGNMENT_CENTER, 86, 11, Color(0.76, 0.72, 0.65))
	draw_string(f, Vector2(430, 124), str(score), HORIZONTAL_ALIGNMENT_CENTER, 86, 18, Color.WHITE)
	draw_string(f, Vector2(524, 96), "РЕКОРД", HORIZONTAL_ALIGNMENT_CENTER, 86, 11, Color(0.76, 0.72, 0.65))
	draw_string(f, Vector2(524, 124), str(_best), HORIZONTAL_ALIGNMENT_CENTER, 86, 18, Color(0.98, 0.85, 0.35))
	draw_string(f, Vector2(430, 166), "Сітка:", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.84, 0.80, 0.72))
	draw_ui_btn(self, BTN_MODE4, "4x4", _n == 4)
	draw_ui_btn(self, BTN_MODE5, "5x5", _n == 5)
	draw_ui_btn(self, BTN_UNDO, "Скасувати (Z)", _can_undo)
	draw_ui_btn(self, BTN_NEW, "Нова гра (R)", true)
	draw_string(f, Vector2(430, 330), "З'єднайте плитки,", HORIZONTAL_ALIGNMENT_CENTER, 180, 13, Color(0.75, 0.82, 0.78))
	draw_string(f, Vector2(430, 350), "щоб зібрати 2048!", HORIZONTAL_ALIGNMENT_CENTER, 180, 13, Color(0.95, 0.85, 0.45))

	if _won_2048 and not _keep_playing:
		draw_rect(Rect2(76, 145, 304, 105), Color(0.06, 0.12, 0.08, 0.90))
		draw_rect(Rect2(76, 145, 304, 105), Color(0.98, 0.82, 0.25), false, 3.0)
		draw_string(f, Vector2(84, 186), "ПЕРЕМОГА: 2048!", HORIZONTAL_ALIGNMENT_CENTER, 288, 22, Color(1.0, 0.92, 0.36))
		draw_string(f, Vector2(84, 224), "Клік або [Пробіл] — далі!", HORIZONTAL_ALIGNMENT_CENTER, 288, 15, Color(0.90, 0.96, 0.90))

	draw_game_over_banner("ГРУ ЗАВЕРШЕНО — [R] Ще раз")
