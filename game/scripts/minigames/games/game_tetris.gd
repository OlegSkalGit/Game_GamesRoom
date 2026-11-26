extends MinigameBase

const COLS := 10
const ROWS := 20
const CELL := 18.0
const BOARD_ORIGIN := Vector2(170.0, 20.0)

const SHAPES := [
	[[Vector2i(0,1), Vector2i(1,1), Vector2i(2,1), Vector2i(3,1)], Color(0.18, 0.86, 0.94), 4], # I (4x4 box)
	[[Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1)], Color(0.95, 0.84, 0.18), 2], # O (2x2 box, no rotate shift)
	[[Vector2i(1,0), Vector2i(0,1), Vector2i(1,1), Vector2i(2,1)], Color(0.72, 0.28, 0.92), 3], # T
	[[Vector2i(1,0), Vector2i(2,0), Vector2i(0,1), Vector2i(1,1)], Color(0.24, 0.88, 0.38), 3], # S
	[[Vector2i(0,0), Vector2i(1,0), Vector2i(1,1), Vector2i(2,1)], Color(0.94, 0.26, 0.26), 3], # Z
	[[Vector2i(0,0), Vector2i(0,1), Vector2i(1,1), Vector2i(2,1)], Color(0.26, 0.48, 0.96), 3], # J
	[[Vector2i(2,0), Vector2i(0,1), Vector2i(1,1), Vector2i(2,1)], Color(0.96, 0.56, 0.18), 3]  # L
]

var _grid: Array = []
var _cur_cells: Array[Vector2i] = []
var _cur_color: Color = Color.WHITE
var _cur_dim: int = 3
var _cur_pos: Vector2i = Vector2i(3, 0)
var _next_idx: int = 0
var _fall_timer: float = 0.0
var _lines_cleared: int = 0
var _flash_t: float = 0.0
var _horiz_dir: int = 0
var _das_timer: float = 0.0
var _arr_timer: float = 0.0


func get_game_title() -> String:
	return "Тетріс"


func get_controls_hint() -> String:
	return "A/D або ◀/▶ — зсув | W/▲ — поворот | S/▼ — швидше | Пробіл — скинути | R — заново | Esc — вийти"


func reset_game() -> void:
	_grid = []
	for _r in range(ROWS):
		var row := []
		row.resize(COLS)
		row.fill(null)
		_grid.append(row)
	_lines_cleared = 0
	_fall_timer = 0.0
	_flash_t = 0.0
	_horiz_dir = 0
	_das_timer = 0.0
	_arr_timer = 0.0
	_next_idx = randi() % SHAPES.size()
	_spawn_piece()
	super.reset_game()


func _spawn_piece() -> void:
	var idx := _next_idx
	_next_idx = randi() % SHAPES.size()
	_cur_cells.clear()
	for c: Vector2i in SHAPES[idx][0]:
		_cur_cells.append(c)
	_cur_color = SHAPES[idx][1]
	_cur_dim = int(SHAPES[idx][2])
	_cur_pos = Vector2i(3, 0)
	if not _fits(_cur_pos, _cur_cells):
		game_over = true
		AudioSfx.play_hit()
		status_changed.emit("Заповнено!")


func _fits(pos: Vector2i, cells: Array[Vector2i]) -> bool:
	for c in cells:
		var gx := pos.x + c.x
		var gy := pos.y + c.y
		if gx < 0 or gx >= COLS or gy < 0 or gy >= ROWS:
			return false
		if _grid[gy][gx] != null:
			return false
	return true


func _rotate_cur() -> void:
	if _cur_dim == 2:
		return
	var rotated: Array[Vector2i] = []
	for c in _cur_cells:
		rotated.append(Vector2i(_cur_dim - 1 - c.y, c.x))
	for kick: int in [0, -1, 1, -2, 2]:
		var np := _cur_pos + Vector2i(kick, 0)
		if _fits(np, rotated):
			_cur_pos = np
			_cur_cells = rotated
			AudioSfx.play_tetris_rotate()
			return


func _lock_piece() -> void:
	for c in _cur_cells:
		var gx := _cur_pos.x + c.x
		var gy := _cur_pos.y + c.y
		if gy >= 0 and gy < ROWS and gx >= 0 and gx < COLS:
			_grid[gy][gx] = _cur_color
	var cleared := 0
	var r := ROWS - 1
	while r >= 0:
		var full := true
		for x in range(COLS):
			if _grid[r][x] == null:
				full = false; break
		if full:
			_grid.remove_at(r)
			var empty_row := []
			empty_row.resize(COLS)
			empty_row.fill(null)
			_grid.push_front(empty_row)
			cleared += 1
		else:
			r -= 1
	if cleared > 0:
		_lines_cleared += cleared
		_flash_t = 0.25
		add_score([0, 100, 300, 500, 800][mini(cleared, 4)])
		AudioSfx.play_tetris_clear(cleared)
	else:
		add_score(10)
		AudioSfx.play_tetris_drop()
	_spawn_piece()


func on_key_pressed(phys_key: int) -> void:
	if game_over:
		return
	if is_left_key(phys_key):
		_horiz_dir = -1
		_das_timer = 0.14
		_arr_timer = 0.0
		if _fits(_cur_pos + Vector2i(-1, 0), _cur_cells):
			_cur_pos.x -= 1
			AudioSfx.play_tetris_move()
	elif is_right_key(phys_key):
		_horiz_dir = 1
		_das_timer = 0.14
		_arr_timer = 0.0
		if _fits(_cur_pos + Vector2i(1, 0), _cur_cells):
			_cur_pos.x += 1
			AudioSfx.play_tetris_move()
	elif is_up_key(phys_key):
		_rotate_cur()
	elif is_down_key(phys_key):
		_fall_timer = maxf(_fall_timer, 0.025)
	elif is_action_key(phys_key):
		while _fits(_cur_pos + Vector2i(0, 1), _cur_cells):
			_cur_pos.y += 1
		_lock_piece()
	queue_redraw()


func step_game(delta: float) -> void:
	_flash_t = maxf(0.0, _flash_t - delta)
	if game_over:
		return

	# Continuous hold-repeat Left/Right matching soft-drop (0.045s) speed!
	var held_dir := (-1 if is_left_held() else 0) + (1 if is_right_held() else 0)
	if held_dir == 0:
		_horiz_dir = 0
		_das_timer = 0.0
		_arr_timer = 0.0
	elif held_dir != _horiz_dir:
		_horiz_dir = held_dir
		_das_timer = 0.14
		_arr_timer = 0.0
		if _fits(_cur_pos + Vector2i(_horiz_dir, 0), _cur_cells):
			_cur_pos.x += _horiz_dir
			AudioSfx.play_tetris_move()
			queue_redraw()
	else:
		if _das_timer > 0.0:
			_das_timer -= delta
		if _das_timer <= 0.0:
			_arr_timer += delta
			while _arr_timer >= 0.045:
				_arr_timer -= 0.045
				if _fits(_cur_pos + Vector2i(_horiz_dir, 0), _cur_cells):
					_cur_pos.x += _horiz_dir
					AudioSfx.play_tetris_move()
					queue_redraw()

	var lvl := 1 + _lines_cleared / 6
	var interval := maxf(0.10, 0.56 - float(lvl - 1) * 0.05)
	if is_down_held():
		interval = 0.045
	_fall_timer += delta
	if _fall_timer >= interval:
		_fall_timer = 0.0
		if _fits(_cur_pos + Vector2i(0, 1), _cur_cells):
			_cur_pos.y += 1
		else:
			_lock_piece()
		queue_redraw()
	elif _flash_t > 0.0:
		queue_redraw()


func _draw_bevel_block(pos: Vector2, sz: float, col: Color) -> void:
	draw_rect(Rect2(pos + Vector2(1, 1), Vector2(sz - 2, sz - 2)), col)
	draw_line(pos + Vector2(1, 1.5), pos + Vector2(sz - 1, 1.5), col.lightened(0.45), 1.5)
	draw_line(pos + Vector2(1.5, 1), pos + Vector2(1.5, sz - 1), col.lightened(0.35), 1.5)
	draw_line(pos + Vector2(1, sz - 1.5), pos + Vector2(sz - 1, sz - 1.5), col.darkened(0.42), 1.5)
	draw_line(pos + Vector2(sz - 1.5, 1), pos + Vector2(sz - 1.5, sz - 1), col.darkened(0.42), 1.5)
	draw_rect(Rect2(pos + Vector2(4.5, 4.5), Vector2(sz - 9, sz - 9)), col.lightened(0.14))


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, CANVAS_SIZE), Color(0.05, 0.06, 0.11))
	var bw := COLS * CELL
	var bh := ROWS * CELL
	draw_rect(Rect2(BOARD_ORIGIN, Vector2(bw, bh)), Color(0.025, 0.032, 0.06))
	if _flash_t > 0.0:
		draw_rect(Rect2(BOARD_ORIGIN, Vector2(bw, bh)), Color(0.8, 0.95, 1.0, _flash_t * 0.45))
	draw_rect(Rect2(BOARD_ORIGIN - Vector2(2, 2), Vector2(bw + 4, bh + 4)), Color(0.84, 0.68, 0.28), false, 2.5)

	for r in range(ROWS):
		for c in range(COLS):
			var cell_pos := BOARD_ORIGIN + Vector2(c * CELL, r * CELL)
			draw_rect(Rect2(cell_pos, Vector2(CELL, CELL)), Color(0.10, 0.12, 0.18), false, 1.0)
			if _grid[r][c] != null:
				_draw_bevel_block(cell_pos, CELL, _grid[r][c])

	if not game_over:
		var gy_pos := _cur_pos
		while _fits(gy_pos + Vector2i(0, 1), _cur_cells):
			gy_pos.y += 1
		for c in _cur_cells:
			var gp := BOARD_ORIGIN + Vector2((gy_pos.x + c.x) * CELL, (gy_pos.y + c.y) * CELL)
			draw_rect(Rect2(gp + Vector2(2, 2), Vector2(CELL - 4, CELL - 4)), Color(_cur_color.r, _cur_color.g, _cur_color.b, 0.35), false, 1.5)
		for c in _cur_cells:
			var gx := _cur_pos.x + c.x
			var gy := _cur_pos.y + c.y
			if gy >= 0 and gy < ROWS and gx >= 0 and gx < COLS:
				_draw_bevel_block(BOARD_ORIGIN + Vector2(gx * CELL, gy * CELL), CELL, _cur_color)

	# Centered Next Piece & Stats Panel strictly inside 640x400
	var f := ThemeDB.fallback_font
	draw_rect(Rect2(385, 32, 160, 118), Color(0.07, 0.09, 0.14))
	draw_rect(Rect2(385, 32, 160, 118), Color(0.75, 0.60, 0.25), false, 2.0)
	draw_string(f, Vector2(400, 56), "Наступна:", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.92, 0.90, 0.82))
	var n_cells: Array = SHAPES[_next_idx][0]
	var min_cx := 9; var max_cx := 0; var min_cy := 9; var max_cy := 0
	for nc: Vector2i in n_cells:
		min_cx = mini(min_cx, nc.x); max_cx = maxi(max_cx, nc.x)
		min_cy = mini(min_cy, nc.y); max_cy = maxi(max_cy, nc.y)
	var pw := float(max_cx - min_cx + 1) * 16.0
	var ph := float(max_cy - min_cy + 1) * 16.0
	var base_p := Vector2(465.0 - pw * 0.5, 102.0 - ph * 0.5)
	for nc: Vector2i in n_cells:
		_draw_bevel_block(base_p + Vector2((nc.x - min_cx) * 16.0, (nc.y - min_cy) * 16.0), 16.0, SHAPES[_next_idx][1])

	draw_rect(Rect2(385, 168, 160, 86), Color(0.07, 0.09, 0.14))
	draw_rect(Rect2(385, 168, 160, 86), Color(0.45, 0.50, 0.60), false, 1.5)
	draw_string(f, Vector2(400, 198), "Рівень: %d" % (1 + _lines_cleared / 6), HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color(0.98, 0.85, 0.35))
	draw_string(f, Vector2(400, 228), "Ліній: %d" % _lines_cleared, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color(0.82, 0.94, 0.85))
	draw_game_over_banner()
