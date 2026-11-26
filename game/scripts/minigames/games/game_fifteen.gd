extends MinigameBase

# Classic 15-Puzzle Sliding Tiles (from Пятнашки.html):
# Guaranteed solvable via legal scramble moves; click tiles or press Arrows / WASD!

const BOARD_ORG := Vector2(160.0, 28.0)
const BOARD_SZ := 320.0
const BTN_SHUFFLE := Rect2(506, 92, 110, 38)
const BTN_SIZE := Rect2(506, 146, 110, 38)

var _n: int = 4
var _tiles: Array[int] = [] # 0 = blank
var _blank: int = 15
var _moves: int = 0
var _solved: bool = false


func get_game_title() -> String:
	return "П'ятнашки"


func get_controls_hint() -> String:
	return "Миша — зсунути плитку поруч із пустою | WASD / Стрілки — зсув | R — перемішати"


func reset_game() -> void:
	super.reset_game()
	_init_board()


func _init_board() -> void:
	_tiles.clear()
	var total := _n * _n
	for i: int in range(1, total):
		_tiles.append(i)
	_tiles.append(0)
	_blank = total - 1
	_moves = 0
	_solved = false

	# Scramble strictly via valid slides (guaranteed solvable!)
	var last_blank := -1
	for _s: int in range(140 + _n * 25):
		var br := _blank / _n
		var bc := _blank % _n
		var cands: Array[int] = []
		for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var nr := br + d.y
			var nc := bc + d.x
			if nr >= 0 and nr < _n and nc >= 0 and nc < _n:
				var ni := nr * _n + nc
				if ni != last_blank:
					cands.append(ni)
		var pick := cands[randi() % cands.size()]
		last_blank = _blank
		_tiles[_blank] = _tiles[pick]
		_tiles[pick] = 0
		_blank = pick
	status_changed.emit("П'ятнашки (%dx%d) | Ходи: 0" % [_n, _n])
	queue_redraw()


func _slide_idx(idx: int) -> void:
	if _solved or idx < 0 or idx >= _tiles.size():
		return
	var r0 := idx / _n; var c0 := idx % _n
	var r1 := _blank / _n; var c1 := _blank % _n
	if abs(r0 - r1) + abs(c0 - c1) != 1:
		return
	_tiles[_blank] = _tiles[idx]
	_tiles[idx] = 0
	_blank = idx
	_moves += 1
	AudioSfx.play_puzzle_snap()

	var ok := true
	for i: int in range(_tiles.size() - 1):
		if _tiles[i] != i + 1:
			ok = false
			break
	if ok:
		_solved = true
		add_score(maxi(100, 600 - _moves * 2))
		AudioSfx.play_fanfare()
		status_changed.emit("ПЕРЕМОГА за %d ходів! Натисніть R для нового розкладу" % _moves)
	else:
		status_changed.emit("П'ятнашки (%dx%d) | Ходи: %d" % [_n, _n, _moves])
	queue_redraw()


func on_key_pressed(phys_key: int) -> void:
	var br := _blank / _n; var bc := _blank % _n
	var target := -1
	match phys_key:
		KEY_UP, KEY_W:
			if br + 1 < _n: target = (br + 1) * _n + bc
		KEY_DOWN, KEY_S:
			if br - 1 >= 0: target = (br - 1) * _n + bc
		KEY_LEFT, KEY_A:
			if bc + 1 < _n: target = br * _n + (bc + 1)
		KEY_RIGHT, KEY_D:
			if bc - 1 >= 0: target = br * _n + (bc - 1)
	if target >= 0:
		_slide_idx(target)


func on_mouse_click(pos: Vector2) -> void:
	if BTN_SHUFFLE.has_point(pos):
		_init_board(); AudioSfx.play_ui_click(); return
	if BTN_SIZE.has_point(pos):
		_n = 5 if _n == 4 else (3 if _n == 5 else 4)
		_init_board(); AudioSfx.play_ui_click(); return
	var cell := BOARD_SZ / float(_n)
	var rel := pos - BOARD_ORG
	if rel.x >= 0.0 and rel.y >= 0.0 and rel.x < BOARD_SZ and rel.y < BOARD_SZ:
		var c := int(rel.x / cell)
		var r := int(rel.y / cell)
		_slide_idx(r * _n + c)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, CANVAS_SIZE), Color(0.07, 0.09, 0.12))
	draw_rect(Rect2(BOARD_ORG - Vector2(6, 6), Vector2(BOARD_SZ + 12, BOARD_SZ + 12)), Color(0.16, 0.20, 0.26))
	var cell := BOARD_SZ / float(_n)
	var f := ThemeDB.fallback_font
	for i: int in range(_tiles.size()):
		var v := _tiles[i]
		if v == 0:
			continue
		var r := i / _n; var c := i % _n
		var rect := Rect2(BOARD_ORG + Vector2(float(c), float(r)) * cell, Vector2(cell, cell)).grow(-4.0)
		var correct := (v == i + 1)
		draw_rect(rect, Color(0.14, 0.52, 0.34) if correct else Color(0.22, 0.34, 0.56))
		draw_rect(rect, Color(0.96, 0.82, 0.32) if _solved else Color(0.62, 0.76, 0.94), false, 2.0)
		draw_string(f, Vector2(rect.position.x, rect.position.y + rect.size.y * 0.65), str(v), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 26 if _n <= 4 else 20, Color.WHITE)

	MinigameBase.draw_ui_btn(self, BTN_SHUFFLE, "Перемішати [R]", true)
	MinigameBase.draw_ui_btn(self, BTN_SIZE, "Поле %dx%d" % [_n, _n], true, Color(0.32, 0.86, 0.96))
