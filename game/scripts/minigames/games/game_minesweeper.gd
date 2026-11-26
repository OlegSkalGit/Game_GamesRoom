extends MinigameBase

const MODES := [
	{"name": "9x9", "cols": 9, "rows": 9, "mines": 10},
	{"name": "12x10", "cols": 12, "rows": 10, "mines": 20},
	{"name": "16x10", "cols": 16, "rows": 10, "mines": 34}
]
const NUM_COLS: Array[Color] = [
	Color.WHITE, Color(0.28, 0.62, 1.0), Color(0.26, 0.82, 0.36), Color(0.96, 0.28, 0.28),
	Color(0.62, 0.42, 0.98), Color(0.86, 0.24, 0.20), Color(0.22, 0.86, 0.86),
	Color(0.92, 0.92, 0.92), Color(0.66, 0.70, 0.74)
]

var _mode_idx: int = 0
var _cols: int = 9
var _rows: int = 9
var _mines_total: int = 10
var _mines: Array = []
var _revealed: Array = []
var _flagged: Array = []
var _adj: Array = []
var _first_click: bool = true
var _won: bool = false
var _cursor: Vector2i = Vector2i(4, 4)

const BTN_MODES: Array[Rect2] = [Rect2(24, 14, 72, 28), Rect2(104, 14, 78, 28), Rect2(190, 14, 82, 28)]


func get_game_title() -> String:
	return "Сапер"


func get_controls_hint() -> String:
	return "ЛКМ / Пробіл — відкрити | ПКМ / F — прапорець | 1/2/3 — складність | R — заново | Esc — вийти"


func reset_game() -> void:
	_setup_mode(_mode_idx)
	super.reset_game()


func _setup_mode(idx: int) -> void:
	_mode_idx = clampi(idx, 0, MODES.size() - 1)
	var m: Dictionary = MODES[_mode_idx]
	_cols = int(m["cols"]); _rows = int(m["rows"]); _mines_total = int(m["mines"])
	_first_click = true
	_won = false
	game_over = false
	_cursor = Vector2i(_cols / 2, _rows / 2)
	_mines.clear(); _revealed.clear(); _flagged.clear(); _adj.clear()
	for _r in range(_rows):
		var mr: Array = []; mr.resize(_cols); mr.fill(false); _mines.append(mr)
		var rr: Array = []; rr.resize(_cols); rr.fill(false); _revealed.append(rr)
		var fr: Array = []; fr.resize(_cols); fr.fill(false); _flagged.append(fr)
		var ar: Array = []; ar.resize(_cols); ar.fill(0); _adj.append(ar)
	status_changed.emit("%s  |  Мін: %d" % [m["name"], _mines_total])
	queue_redraw()


func _place_mines(safe: Vector2i) -> void:
	var cands: Array[Vector2i] = []
	for r in range(_rows):
		for c in range(_cols):
			if abs(c - safe.x) <= 1 and abs(r - safe.y) <= 1:
				continue
			cands.append(Vector2i(c, r))
	cands.shuffle()
	for i in range(mini(_mines_total, cands.size())):
		var p := cands[i]
		_mines[p.y][p.x] = true

	for r in range(_rows):
		for c in range(_cols):
			var cnt := 0
			for dr: int in [-1, 0, 1]:
				for dc: int in [-1, 0, 1]:
					var nr: int = r + dr
					var nc: int = c + dc
					if nr >= 0 and nr < _rows and nc >= 0 and nc < _cols and bool(_mines[nr][nc]):
						cnt += 1
			_adj[r][c] = cnt


func _board_layout() -> Dictionary:
	var cell := minf(590.0 / float(_cols), 328.0 / float(_rows))
	var bw := cell * float(_cols)
	var bh := cell * float(_rows)
	return {"cell": cell, "ox": (CANVAS_SIZE.x - bw) * 0.5, "oy": 54.0 + (332.0 - bh) * 0.5}


func _reveal_cell(p: Vector2i) -> void:
	if game_over or _won or p.x < 0 or p.x >= _cols or p.y < 0 or p.y >= _rows:
		return
	if bool(_flagged[p.y][p.x]):
		return
	if _first_click:
		_first_click = false
		_place_mines(p)

	if bool(_revealed[p.y][p.x]):
		# Chord open if adjacent flags match count
		var req := int(_adj[p.y][p.x])
		if req > 0:
			var f_cnt := 0
			for dr: int in [-1, 0, 1]:
				for dc: int in [-1, 0, 1]:
					var nr: int = p.y + dr
					var nc: int = p.x + dc
					if nr >= 0 and nr < _rows and nc >= 0 and nc < _cols and bool(_flagged[nr][nc]):
						f_cnt += 1
			if f_cnt == req:
				for dr: int in [-1, 0, 1]:
					for dc: int in [-1, 0, 1]:
						var nr: int = p.y + dr
						var nc: int = p.x + dc
						if nr >= 0 and nr < _rows and nc >= 0 and nc < _cols and not bool(_revealed[nr][nc]) and not bool(_flagged[nr][nc]):
							_reveal_cell(Vector2i(nc, nr))
		return

	var stack: Array[Vector2i] = [p]
	while not stack.is_empty():
		var cur := stack.pop_back() as Vector2i
		if bool(_revealed[cur.y][cur.x]) or bool(_flagged[cur.y][cur.x]):
			continue
		_revealed[cur.y][cur.x] = true
		if bool(_mines[cur.y][cur.x]):
			game_over = true
			for r in range(_rows):
				for c in range(_cols):
					if bool(_mines[r][c]):
						_revealed[r][c] = true
			AudioSfx.play_explosion()
			status_changed.emit("Вибух! Натисніть [R]")
			queue_redraw()
			return
		add_score(10)
		if int(_adj[cur.y][cur.x]) == 0:
			for dr: int in [-1, 0, 1]:
				for dc: int in [-1, 0, 1]:
					var nr: int = cur.y + dr
					var nc: int = cur.x + dc
					if nr >= 0 and nr < _rows and nc >= 0 and nc < _cols and not bool(_revealed[nr][nc]):
						stack.append(Vector2i(nc, nr))
	AudioSfx.play_ui_click()
	_check_win()
	queue_redraw()


func _toggle_flag(p: Vector2i) -> void:
	if game_over or _won or p.x < 0 or p.x >= _cols or p.y < 0 or p.y >= _rows or bool(_revealed[p.y][p.x]):
		return
	_flagged[p.y][p.x] = not bool(_flagged[p.y][p.x])
	AudioSfx.play_switch()
	_check_win()
	queue_redraw()


func _check_win() -> void:
	var rem := 0
	var flags := 0
	for r in range(_rows):
		for c in range(_cols):
			if bool(_flagged[r][c]): flags += 1
			if not bool(_mines[r][c]) and not bool(_revealed[r][c]): rem += 1
	if rem == 0:
		_won = true
		game_over = true
		add_score(300)
		AudioSfx.play_fanfare()
		status_changed.emit("ПЕРЕМОГА! Усі міни знешкоджено!")
	else:
		status_changed.emit("%s  |  Прапорців: %d / %d" % [MODES[_mode_idx]["name"], flags, _mines_total])


func _pos_to_cell(pos: Vector2) -> Vector2i:
	var lay := _board_layout()
	var cell := float(lay["cell"])
	var c := int(floor((pos.x - float(lay["ox"])) / cell))
	var r := int(floor((pos.y - float(lay["oy"])) / cell))
	if c >= 0 and c < _cols and r >= 0 and r < _rows:
		return Vector2i(c, r)
	return Vector2i(-1, -1)


func on_mouse_click(pos: Vector2) -> void:
	for i in range(BTN_MODES.size()):
		if BTN_MODES[i].has_point(pos):
			_setup_mode(i); score = 0; score_changed.emit(0); AudioSfx.play_ui_click(); return
	var cell := _pos_to_cell(pos)
	if cell.x >= 0:
		_cursor = cell
		_reveal_cell(cell)


func on_right_click(pos: Vector2) -> void:
	var cell := _pos_to_cell(pos)
	if cell.x >= 0:
		_cursor = cell
		_toggle_flag(cell)


func on_key_pressed(phys_key: int) -> void:
	if phys_key == KEY_1: _setup_mode(0); return
	if phys_key == KEY_2: _setup_mode(1); return
	if phys_key == KEY_3: _setup_mode(2); return
	if is_left_key(phys_key): _cursor.x = maxi(0, _cursor.x - 1)
	elif is_right_key(phys_key): _cursor.x = mini(_cols - 1, _cursor.x + 1)
	elif is_up_key(phys_key): _cursor.y = maxi(0, _cursor.y - 1)
	elif is_down_key(phys_key): _cursor.y = mini(_rows - 1, _cursor.y + 1)
	elif phys_key == KEY_F: _toggle_flag(_cursor); return
	elif is_action_key(phys_key): _reveal_cell(_cursor); return
	queue_redraw()


func _draw() -> void:
	var f := ThemeDB.fallback_font
	draw_rect(Rect2(Vector2.ZERO, CANVAS_SIZE), Color(0.08, 0.10, 0.12))
	for i in range(BTN_MODES.size()):
		draw_ui_btn(self, BTN_MODES[i], MODES[i]["name"], _mode_idx == i)
	draw_string(f, Vector2(300, 34), "САПЕР • ПОШУК МІН", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.97, 0.82, 0.36))

	var lay := _board_layout()
	var cell := float(lay["cell"])
	var ox := float(lay["ox"])
	var oy := float(lay["oy"])

	for r in range(_rows):
		for c in range(_cols):
			var rect := Rect2(ox + float(c) * cell + 1, oy + float(r) * cell + 1, cell - 2, cell - 2)
			if bool(_revealed[r][c]):
				if bool(_mines[r][c]):
					draw_rect(rect, Color(0.75, 0.18, 0.18))
					draw_circle(rect.get_center(), cell * 0.28, Color(0.10, 0.10, 0.12))
					draw_circle(rect.get_center() + Vector2(-2, -2), cell * 0.10, Color(1.0, 0.65, 0.20))
				else:
					draw_rect(rect, Color(0.16, 0.19, 0.22))
					draw_rect(rect, Color(0.24, 0.28, 0.32), false, 1.0)
					var a := int(_adj[r][c])
					if a > 0:
						draw_string(f, Vector2(rect.position.x, rect.position.y + cell * 0.68), str(a), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, int(cell * 0.56), NUM_COLS[a % NUM_COLS.size()])
			else:
				draw_rect(rect, Color(0.26, 0.32, 0.38))
				draw_line(rect.position, rect.position + Vector2(rect.size.x, 0), Color(0.42, 0.50, 0.58), 1.8)
				draw_line(rect.position, rect.position + Vector2(0, rect.size.y), Color(0.42, 0.50, 0.58), 1.8)
				if bool(_flagged[r][c]):
					var p0 := rect.get_center()
					draw_line(p0 + Vector2(-3, 7), p0 + Vector2(-3, -7), Color(0.90, 0.90, 0.90), 2.0)
					draw_colored_polygon(PackedVector2Array([p0 + Vector2(-3, -7), p0 + Vector2(8, -3), p0 + Vector2(-3, 1)]), Color(0.96, 0.22, 0.22))

	var cur_r := Rect2(ox + float(_cursor.x) * cell + 1, oy + float(_cursor.y) * cell + 1, cell - 2, cell - 2)
	draw_rect(cur_r, Color(0.98, 0.84, 0.28, 0.72), false, 2.0)

	if _won:
		draw_game_over_banner("ПЕРЕМОГА! [R] Зіграти ще")
	elif game_over:
		draw_game_over_banner("МІНА! [R] Спробувати знову")
