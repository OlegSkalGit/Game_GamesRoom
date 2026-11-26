extends MinigameBase

# Hexagonal Sliding & Merging Puzzle (HEXA Color Puzzle Pro):
# Slide in 6 hex directions (Q/E/A/D/Z/C, hex-compass buttons, or mouse swipe on board).
# Merges 3 matching tiles along the slide line (or toggle 2-tile Hex-2048 mode!).

const RADIUS := 4 # 61 hex cells (5..9 cells per line)
const HEX_SIZE := 18.8
const CENTER := Vector2(216.0, 200.0)
const COLORS := [
	Color(0.15, 0.19, 0.26), # 0 empty dark slate
	Color(0.22, 0.78, 0.96), # 1 Ice Cyan
	Color(0.18, 0.84, 0.48), # 2 Mint Emerald
	Color(0.98, 0.78, 0.18), # 3 Sunny Gold
	Color(0.98, 0.46, 0.16), # 4 Coral Orange
	Color(0.92, 0.22, 0.30), # 5 Ruby Red
	Color(0.70, 0.34, 0.95), # 6 Violet Purple
	Color(0.26, 0.46, 0.98), # 7 Royal Cobalt
	Color(0.96, 0.30, 0.78), # 8 Hot Magenta
	Color(0.12, 0.92, 0.82), # 9 Aqua Neon
	Color(0.98, 0.92, 0.52), # 10 Pale Sun
	Color(0.96, 0.96, 0.98), # 11 Diamond White
	Color(0.98, 0.68, 0.90)  # 12 Rose Prism
]
const DIRS := [
	{"name": "↗ E", "dq": 1, "dr": -1, "btn": Rect2(536, 134, 72, 34), "ang": -PI / 3.0},
	{"name": "→ D", "dq": 1, "dr": 0, "btn": Rect2(546, 174, 72, 34), "ang": 0.0},
	{"name": "↘ C", "dq": 0, "dr": 1, "btn": Rect2(536, 214, 72, 34), "ang": PI / 3.0},
	{"name": "↙ Z", "dq": -1, "dr": 1, "btn": Rect2(452, 214, 72, 34), "ang": 2.0 * PI / 3.0},
	{"name": "← A", "dq": -1, "dr": 0, "btn": Rect2(442, 174, 72, 34), "ang": PI},
	{"name": "↖ Q", "dq": 0, "dr": -1, "btn": Rect2(452, 134, 72, 34), "ang": -2.0 * PI / 3.0}
]
const BTN_MODE := Rect2(446, 266, 168, 36)
const BTN_UNDO := Rect2(446, 312, 168, 36)

var _board: Dictionary = {} # Vector2i(q, r) -> int tier (0 = empty)
var _cells: Array[Vector2i] = []
var _undo: Array[Dictionary] = []
var _merge_req: int = 2 # 2 = Pair-merge (classic Hex-2048); 3 = HEXA Triple-merge
var _merge_fx: Dictionary = {} # Vector2i -> float pulse timer
var _drag_active: bool = false
var _drag_start: Vector2 = Vector2.ZERO


func get_game_title() -> String:
	return "Гекса"


func get_controls_hint() -> String:
	return "Свайп мишею по полю або Q/E/A/D/Z/C або кнопки — зсув | U — назад | R — заново"


func reset_game() -> void:
	_cells.clear()
	_board.clear()
	_undo.clear()
	_merge_fx.clear()
	_drag_active = false
	for q: int in range(-RADIUS, RADIUS + 1):
		var r1 := maxi(-RADIUS, -q - RADIUS)
		var r2 := mini(RADIUS, -q + RADIUS)
		for r: int in range(r1, r2 + 1):
			var k := Vector2i(q, r)
			_cells.append(k)
			_board[k] = 0
	super.reset_game()
	_spawn_tiles(5 if _merge_req == 3 else 3)
	_update_status()
	queue_redraw()


func _spawn_tiles(cnt: int) -> void:
	var empty: Array[Vector2i] = []
	for k: Vector2i in _cells:
		if int(_board[k]) == 0:
			empty.append(k)
	empty.shuffle()
	for i: int in range(mini(cnt, empty.size())):
		_board[empty[i]] = 1 if (i < cnt - 1 or randf() < 0.72) else 2


func _hex_to_px(q: int, r: int) -> Vector2:
	return CENTER + Vector2(HEX_SIZE * sqrt(3.0) * (float(q) + float(r) * 0.5), HEX_SIZE * 1.5 * float(r))


func _tile_display_value(tier: int) -> int:
	return int(pow(float(_merge_req), float(tier)))


func _try_slide(dir_idx: int) -> void:
	if game_over:
		return
	var d: Dictionary = DIRS[dir_idx]
	var dq := int(d["dq"])
	var dr := int(d["dr"])
	var prev_state := {"b": _board.duplicate(), "s": score}

	var lines: Array[Array] = []
	for k: Vector2i in _cells:
		if not _board.has(Vector2i(k.x - dq, k.y - dr)):
			var line: Array[Vector2i] = []
			var cur := k
			while _board.has(cur):
				line.append(cur)
				cur = Vector2i(cur.x + dq, cur.y + dr)
			lines.append(line)

	var moved := false
	var did_merge := false
	var max_merged_tier := 1
	_merge_fx.clear()

	for line: Array in lines:
		var vals: Array[int] = []
		for idx: int in range(line.size() - 1, -1, -1):
			var v := int(_board[line[idx]])
			if v > 0:
				vals.append(v)

		var merged: Array[int] = []
		var merged_slots: Array[int] = []
		var i := 0
		while i < vals.size():
			var can_merge := (i + _merge_req - 1 < vals.size()) and vals[i] < 12
			if can_merge:
				for m: int in range(1, _merge_req):
					if vals[i + m] != vals[i]:
						can_merge = false
						break
			if can_merge:
				var nv := vals[i] + 1
				merged_slots.append(merged.size())
				merged.append(nv)
				add_score(_tile_display_value(nv))
				did_merge = true
				max_merged_tier = maxi(max_merged_tier, nv)
				i += _merge_req
			else:
				merged.append(vals[i])
				i += 1
		while merged.size() < line.size():
			merged.append(0)

		for idx: int in range(line.size()):
			var target_k: Vector2i = line[line.size() - 1 - idx]
			var new_v := merged[idx]
			if int(_board[target_k]) != new_v:
				_board[target_k] = new_v
				moved = true
		for slot_i: int in merged_slots:
			var mk: Vector2i = line[line.size() - 1 - slot_i]
			_merge_fx[mk] = 0.42

	if moved:
		_undo.append(prev_state)
		if _undo.size() > 20:
			_undo.remove_at(0)
		if did_merge:
			AudioSfx.play_tile_merge(_tile_display_value(max_merged_tier))
		else:
			AudioSfx.play_tetris_move()
		_spawn_tiles(2 if _merge_req == 3 else 1)
		if _is_board_stuck():
			game_over = true
		_update_status()
		queue_redraw()
	elif _has_adjacent_pair() and _merge_req == 3:
		status_changed.emit("Гекса [Трійки ×3]: потрібно 3 однакових підряд (або перемкніть режим «по 2») | Рахунок: %d" % score)


func _has_adjacent_pair() -> bool:
	for d in DIRS:
		var dq := int(d["dq"])
		var dr := int(d["dr"])
		for k: Vector2i in _cells:
			var v := int(_board[k])
			if v <= 0 or v >= 12:
				continue
			var km := Vector2i(k.x + dq, k.y + dr)
			if _board.has(km) and int(_board[km]) == v:
				return true
	return false


func _is_board_stuck() -> bool:
	for k: Vector2i in _cells:
		if int(_board[k]) == 0:
			return false
	for d_idx: int in range(DIRS.size()):
		var dq := int(DIRS[d_idx]["dq"])
		var dr := int(DIRS[d_idx]["dr"])
		for k: Vector2i in _cells:
			var v := int(_board[k])
			if v <= 0 or v >= 12:
				continue
			var all_match := true
			for m: int in range(1, _merge_req):
				var km := Vector2i(k.x + dq * m, k.y + dr * m)
				if not _board.has(km) or int(_board[km]) != v:
					all_match = false
					break
			if all_match:
				return false
	return true


func _update_status() -> void:
	var mode_str := "Трійки (×3)" if _merge_req == 3 else "Пари (×2)"
	if game_over:
		status_changed.emit("Ходів немає (%s)! Рахунок: %d | R — заново" % [mode_str, score])
	else:
		status_changed.emit("Гекса [%s]: зсувайте плитки по %d однакових | Рахунок: %d" % [mode_str, _merge_req, score])


func step_game(delta: float) -> void:
	if not _merge_fx.is_empty():
		var keys := _merge_fx.keys()
		for k: Vector2i in keys:
			var t := float(_merge_fx[k]) - delta
			if t <= 0.0:
				_merge_fx.erase(k)
			else:
				_merge_fx[k] = t
		queue_redraw()


func on_key_pressed(phys_key: int) -> void:
	match phys_key:
		KEY_E: _try_slide(0)
		KEY_D, KEY_RIGHT: _try_slide(1)
		KEY_C, KEY_X, KEY_S, KEY_DOWN: _try_slide(2)
		KEY_Z: _try_slide(3)
		KEY_A, KEY_LEFT: _try_slide(4)
		KEY_Q, KEY_W, KEY_UP: _try_slide(5)
		KEY_U, KEY_BACKSPACE: _do_undo()


func _do_undo() -> void:
	if _undo.is_empty():
		return
	var st: Dictionary = _undo.pop_back()
	_board = st["b"]
	score = int(st["s"])
	score_changed.emit(score)
	game_over = false
	_merge_fx.clear()
	_update_status()
	AudioSfx.play_ui_click()
	queue_redraw()


func on_mouse_click(pos: Vector2) -> void:
	for i: int in range(DIRS.size()):
		if (DIRS[i]["btn"] as Rect2).has_point(pos):
			_try_slide(i)
			return
	if BTN_MODE.has_point(pos):
		_merge_req = 2 if _merge_req == 3 else 3
		AudioSfx.play_ui_click()
		reset_game()
		return
	if BTN_UNDO.has_point(pos):
		_do_undo()
		return
	if pos.x < 420.0:
		_drag_active = true
		_drag_start = pos


func on_mouse_release(pos: Vector2) -> void:
	if not _drag_active:
		return
	_drag_active = false
	var dv := pos - _drag_start
	if dv.length() < 18.0:
		return
	var best_i := 0
	var best_dot := -2.0
	var dir_v := dv.normalized()
	for i: int in range(DIRS.size()):
		var ang := float(DIRS[i]["ang"])
		var dp := dir_v.dot(Vector2(cos(ang), sin(ang)))
		if dp > best_dot:
			best_dot = dp
			best_i = i
	_try_slide(best_i)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, CANVAS_SIZE), Color(0.06, 0.08, 0.11))
	var f := ThemeDB.fallback_font
	for k: Vector2i in _cells:
		var c := _hex_to_px(k.x, k.y)
		var v := int(_board[k])
		var fx_t := float(_merge_fx.get(k, 0.0))
		var pts := PackedVector2Array()
		var rad := HEX_SIZE - 1.8 + fx_t * 5.0
		for h: int in range(6):
			var ang := deg_to_rad(60.0 * float(h) - 30.0)
			pts.append(c + Vector2(cos(ang), sin(ang)) * rad)
		draw_colored_polygon(pts, COLORS[clampi(v, 0, COLORS.size() - 1)])
		var rim_col := Color(1.0, 0.94, 0.42) if fx_t > 0.0 else (Color(0.28, 0.34, 0.44) if v == 0 else Color(0.95, 0.96, 1.0, 0.35))
		draw_polyline(pts + PackedVector2Array([pts[0]]), rim_col, 2.2 if fx_t > 0.0 else 1.2)
		if v > 0:
			var label := str(_tile_display_value(v))
			var tcol := Color(0.06, 0.08, 0.12) if v <= 4 or v >= 9 else Color.WHITE
			var fsz := 12 if label.length() <= 2 else (10 if label.length() == 3 else 8)
			draw_string(f, c + Vector2(-16, 4.5), label, HORIZONTAL_ALIGNMENT_CENTER, 32, fsz, tcol)

	# Right Control Compass & Progression Legend
	draw_string(f, Vector2(436, 36), "ШКАЛА (%d В РЯД)" % _merge_req, HORIZONTAL_ALIGNMENT_CENTER, 190, 14, Color(0.98, 0.84, 0.34))
	for li: int in range(1, 7):
		var lr := Rect2(436.0 + float(li - 1) * 32.0, 48.0, 29.0, 28.0)
		draw_rect(lr, COLORS[li])
		var ltxt := str(_tile_display_value(li))
		draw_string(f, Vector2(lr.position.x, lr.position.y + 19), ltxt, HORIZONTAL_ALIGNMENT_CENTER, 29, 10 if ltxt.length() < 4 else 8, Color(0.06, 0.08, 0.12) if li <= 4 else Color.WHITE)

	draw_string(f, Vector2(436, 118), "НАПРЯМКИ (або свайп)", HORIZONTAL_ALIGNMENT_CENTER, 190, 14, Color(0.84, 0.90, 0.96))
	for d in DIRS:
		MinigameBase.draw_ui_btn(self, d["btn"], str(d["name"]), not game_over)
	MinigameBase.draw_ui_btn(self, BTN_MODE, "Режим: по %d однакових" % _merge_req, true, Color(0.98, 0.78, 0.22))
	MinigameBase.draw_ui_btn(self, BTN_UNDO, "Крок назад [U]", not _undo.is_empty(), Color(0.32, 0.84, 0.96))
