extends MinigameBase

const BOARD_POS := Vector2(40.0, 24.0)
const CELL := 39.0
const DIFFS := [
	{"name": "Легко", "holes": 32},
	{"name": "Норма", "holes": 44},
	{"name": "Важко", "holes": 54}
]

var _diff_idx: int = 0
var _sol: Array = []
var _grid: Array = []
var _fixed: Array = []
var _sel: Vector2i = Vector2i(0, 0)
var _won: bool = false
var _mistakes: int = 0

const BTN_NUMS_OX := 424.0
const BTN_NUMS_OY := 146.0


func get_game_title() -> String:
	return "Судоку"


func get_controls_hint() -> String:
	return "Миша / Стрілки — клітинка | 1-9 — цифра | Backspace/0 — стерти | H — підказка | Esc — вийти"


func reset_game() -> void:
	_build_puzzle(_diff_idx)
	super.reset_game()


func _build_puzzle(d_idx: int) -> void:
	_diff_idx = clampi(d_idx, 0, DIFFS.size() - 1)
	_won = false
	_mistakes = 0
	game_over = false

	# Valid base Latin Sudoku pattern permuted cleanly across bands & digits
	var digits := [1, 2, 3, 4, 5, 6, 7, 8, 9]
	digits.shuffle()
	var row_ord: Array[int] = []
	var col_ord: Array[int] = []
	for band in range(3):
		var sr: Array[int] = [0, 1, 2]; sr.shuffle()
		for r: int in sr: row_ord.append(band * 3 + r)
		var sc: Array[int] = [0, 1, 2]; sc.shuffle()
		for c: int in sc: col_ord.append(band * 3 + c)

	_sol = []
	_grid = []
	_fixed = []
	for r in range(9):
		var srow: Array = []; var grow: Array = []; var frow: Array = []
		for c in range(9):
			var base_v := (row_ord[r] * 3 + row_ord[r] / 3 + col_ord[c]) % 9
			var val := int(digits[base_v])
			srow.append(val); grow.append(val); frow.append(true)
		_sol.append(srow); _grid.append(grow); _fixed.append(frow)

	var cells: Array[Vector2i] = []
	for r in range(9):
		for c in range(9):
			cells.append(Vector2i(c, r))
	cells.shuffle()
	var holes := int(DIFFS[_diff_idx]["holes"])
	for i in range(holes):
		var p := cells[i]
		_grid[p.y][p.x] = 0
		_fixed[p.y][p.x] = false

	_sel = cells[0]
	status_changed.emit("%s  |  Порожніх: %d" % [DIFFS[_diff_idx]["name"], holes])
	queue_redraw()


func _put_digit(d: int) -> void:
	if _won or bool(_fixed[_sel.y][_sel.x]):
		return
	_grid[_sel.y][_sel.x] = d
	if d == 0:
		AudioSfx.play_switch()
	elif d == int(_sol[_sel.y][_sel.x]):
		add_score(35)
		AudioSfx.play_puzzle_snap()
		_check_win()
	else:
		_mistakes += 1
		AudioSfx.play_hit()
	queue_redraw()


func _use_hint() -> void:
	if _won:
		return
	for r in range(9):
		for c in range(9):
			if int(_grid[r][c]) != int(_sol[r][c]):
				_sel = Vector2i(c, r)
				_grid[r][c] = int(_sol[r][c])
				_fixed[r][c] = true
				AudioSfx.play_powerup()
				_check_win()
				queue_redraw()
				return


func _check_win() -> void:
	var rem := 0
	for r in range(9):
		for c in range(9):
			if int(_grid[r][c]) != int(_sol[r][c]):
				rem += 1
	if rem == 0:
		_won = true
		game_over = true
		add_score(400)
		AudioSfx.play_fanfare()
		status_changed.emit("СУДОКУ ВИРІШЕНО!")
	else:
		status_changed.emit("%s  |  Залишилось: %d  |  Помилок: %d" % [DIFFS[_diff_idx]["name"], rem, _mistakes])


func on_mouse_click(pos: Vector2) -> void:
	for i in range(DIFFS.size()):
		if Rect2(424.0 + float(i) * 62.0, 92.0, 58.0, 32.0).has_point(pos):
			_build_puzzle(i); score = 0; score_changed.emit(0); AudioSfx.play_ui_click(); return

	# Keypad 1..9
	for d in range(1, 10):
		var r := (d - 1) / 3
		var c := (d - 1) % 3
		if Rect2(BTN_NUMS_OX + float(c) * 62.0, BTN_NUMS_OY + float(r) * 50.0, 56.0, 44.0).has_point(pos):
			_put_digit(d); return

	if Rect2(424.0, 304.0, 88.0, 36.0).has_point(pos):
		_put_digit(0); return
	if Rect2(518.0, 304.0, 88.0, 36.0).has_point(pos):
		_use_hint(); return

	var gc := int(floor((pos.x - BOARD_POS.x) / CELL))
	var gr := int(floor((pos.y - BOARD_POS.y) / CELL))
	if gc >= 0 and gc < 9 and gr >= 0 and gr < 9:
		_sel = Vector2i(gc, gr)
		AudioSfx.play_ui_click()
		queue_redraw()


func on_key_pressed(phys_key: int) -> void:
	if is_left_key(phys_key): _sel.x = maxi(0, _sel.x - 1)
	elif is_right_key(phys_key): _sel.x = mini(8, _sel.x + 1)
	elif is_up_key(phys_key): _sel.y = maxi(0, _sel.y - 1)
	elif is_down_key(phys_key): _sel.y = mini(8, _sel.y + 1)
	elif phys_key == KEY_H or is_action_key(phys_key): _use_hint(); return
	elif phys_key == KEY_BACKSPACE or phys_key == KEY_DELETE or phys_key == KEY_0: _put_digit(0); return
	elif phys_key >= KEY_1 and phys_key <= KEY_9: _put_digit(phys_key - KEY_0); return
	queue_redraw()


func _draw() -> void:
	var f := ThemeDB.fallback_font
	draw_rect(Rect2(Vector2.ZERO, CANVAS_SIZE), Color(0.06, 0.08, 0.12))
	var bw := CELL * 9.0
	draw_rect(Rect2(BOARD_POS - Vector2(4, 4), Vector2(bw + 8, bw + 8)), Color(0.84, 0.68, 0.28), false, 2.5)
	var sel_val := int(_grid[_sel.y][_sel.x])

	for r in range(9):
		for c in range(9):
			var rect := Rect2(BOARD_POS.x + float(c) * CELL, BOARD_POS.y + float(r) * CELL, CELL, CELL)
			var is_sel := (_sel.x == c and _sel.y == r)
			var is_peer := (_sel.x == c or _sel.y == r or (_sel.x / 3 == c / 3 and _sel.y / 3 == r / 3))
			var v := int(_grid[r][c])
			var bg := Color(0.20, 0.34, 0.46) if is_sel else (Color(0.14, 0.20, 0.28) if (sel_val > 0 and v == sel_val) else (Color(0.10, 0.13, 0.19) if is_peer else Color(0.08, 0.10, 0.15)))
			draw_rect(rect, bg)
			draw_rect(rect, Color(0.20, 0.24, 0.32), false, 1.0)
			if v > 0:
				var col := Color(0.95, 0.94, 0.88) if bool(_fixed[r][c]) else (Color(0.32, 0.90, 0.56) if v == int(_sol[r][c]) else Color(0.96, 0.32, 0.32))
				draw_string(f, Vector2(rect.position.x, rect.position.y + CELL * 0.72), str(v), HORIZONTAL_ALIGNMENT_CENTER, CELL, 20, col)

	# Bold 3x3 subgrid lines
	for b in [3, 6]:
		var p := float(b) * CELL
		draw_line(BOARD_POS + Vector2(p, 0), BOARD_POS + Vector2(p, bw), Color(0.86, 0.70, 0.30), 2.4)
		draw_line(BOARD_POS + Vector2(0, p), BOARD_POS + Vector2(bw, p), Color(0.86, 0.70, 0.30), 2.4)

	# Side Panel
	draw_rect(Rect2(414, 24, 204, 351), Color(0.09, 0.11, 0.16))
	draw_rect(Rect2(414, 24, 204, 351), Color(0.75, 0.60, 0.26), false, 2.0)
	draw_string(f, Vector2(420, 62), "СУДОКУ • СХОВИЩЕ", HORIZONTAL_ALIGNMENT_CENTER, 192, 18, Color(0.98, 0.84, 0.34))
	for i in range(DIFFS.size()):
		draw_ui_btn(self, Rect2(424.0 + float(i) * 62.0, 92.0, 58.0, 32.0), DIFFS[i]["name"], _diff_idx == i)
	for d in range(1, 10):
		var r := (d - 1) / 3
		var c := (d - 1) % 3
		draw_ui_btn(self, Rect2(BTN_NUMS_OX + float(c) * 62.0, BTN_NUMS_OY + float(r) * 50.0, 56.0, 44.0), str(d), true)
	draw_ui_btn(self, Rect2(424.0, 304.0, 88.0, 36.0), "Стерти", true)
	draw_ui_btn(self, Rect2(518.0, 304.0, 88.0, 36.0), "Підказка", true)

	if _won:
		draw_game_over_banner("СУДОКУ РОЗГАДАНО! [R] Нове")
