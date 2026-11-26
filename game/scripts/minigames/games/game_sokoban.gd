extends MinigameBase

# Sokoban Warehouse Crate-Pushing Puzzle (Microban-inspired levels from Сокобан 2.html):
# WASD / Arrows to push crates onto glowing docks | Z — Undo step | N/P — Level

const LEVELS: Array = [
	["#####", "#   #", "#.$@#", "#   #", "#####"],
	["#####", "# . #", "# $ #", "# @ #", "# $ #", "# . #", "#####"],
	["######", "#    #", "# #.@#", "#  $ #", "#  $.#", "#    #", "######"],
	["######", "# .. #", "# $$ #", "#  $.#", "#  @ #", "######"],
	["#######", "#  .  #", "# .$. #", "# $@$ #", "#  $  #", "#  .  #", "#######"],
	["  ###", "  #.#", "  # ####", "###$ $.#", "#. $@###", "####$#", "   #.#", "   ###"],
	["  #####", "###   #", "# $ # #", "# . @ #", "# $ # #", "#.#   #", "#######"],
	["#######", "#  .  #", "# .$. #", "#  $  #", "#  @  #", "#  $  #", "#     #", "#######"],
	["  ####", "###  #", "#  $ #", "#.#  #", "#. $@#", "#  $ #", "# .  #", "######"],
	[" #######", " #  .  #", " # #$# #", " #  $  #", "##.@. ##", "#  $  #", "#     #", "#######"],
	["########", "#   #  #", "# $ .  #", "# #$## #", "#  .@. #", "#   $  #", "#      #", "########"],
	["########", "#  #   #", "# .$ $ #", "#  # . #", "## ##  #", "#  @$. #", "#      #", "########"],
	["########", "#  ... #", "#  ##  #", "#      #", "# $$$  #", "#   @  #", "#      #", "########"],
	["########", "#  .   #", "# # ## #", "# $  . #", "# . $@ #", "#  $$. #", "#      #", "########"],
	["#######", "#.   .#", "# $ $ #", "#  @  #", "# $ $ #", "#.   .#", "#######"],
	["#########", "# . . . #", "# $#$#$ #", "# . @ . #", "#  $ $  #", "#       #", "#########"]
]

var _lvl: int = 0
var _grid: Array = []
var _targets: Dictionary = {}
var _crates: Dictionary = {}
var _player: Vector2i = Vector2i.ZERO
var _undo: Array[Dictionary] = []
var _moves: int = 0
var _won: bool = false

const BTN_PREV := Rect2(44, 348, 92, 34)
const BTN_UNDO := Rect2(148, 348, 92, 34)
const BTN_NEXT := Rect2(252, 348, 92, 34)


func get_game_title() -> String:
	return "Сокобан"


func get_controls_hint() -> String:
	return "WASD / Стрілки — штовхати ящики на мітки | Z — крок назад | N/P — рівень | R — спочатку"


func reset_game() -> void:
	_lvl = 0
	super.reset_game()
	_load_level(0)


func _load_level(idx: int) -> void:
	_lvl = wrapi(idx, 0, LEVELS.size())
	var lines: Array = LEVELS[_lvl]
	_grid.clear()
	_targets.clear()
	_crates.clear()
	_undo.clear()
	_moves = 0
	_won = false

	for y: int in range(lines.size()):
		var row_str := str(lines[y])
		var row_arr: Array[String] = []
		for x: int in range(row_str.length()):
			var ch := row_str[x]
			var k := Vector2i(x, y)
			if ch == "#":
				row_arr.append("#")
			else:
				row_arr.append(" ")
				if ch == "." or ch == "*" or ch == "+":
					_targets[k] = true
				if ch == "$" or ch == "*":
					_crates[k] = true
				if ch == "@" or ch == "+":
					_player = k
		_grid.append(row_arr)
	_update_status()
	queue_redraw()


func _is_wall(p: Vector2i) -> bool:
	if p.y < 0 or p.y >= _grid.size():
		return true
	var row: Array = _grid[p.y]
	if p.x < 0 or p.x >= row.size():
		return true
	return str(row[p.x]) == "#"


func _move(d: Vector2i) -> void:
	if _won:
		return
	var nxt := _player + d
	if _is_wall(nxt):
		AudioSfx.play_brick_bump()
		return
	_undo.append({"p": _player, "c": _crates.duplicate(), "m": _moves})
	if _undo.size() > 80:
		_undo.remove_at(0)

	if _crates.has(nxt):
		var beyond := nxt + d
		if _is_wall(beyond) or _crates.has(beyond):
			_undo.pop_back()
			AudioSfx.play_brick_bump()
			return
		_crates.erase(nxt)
		_crates[beyond] = true
		AudioSfx.play_puzzle_snap()
	else:
		AudioSfx.play_step("carpet")

	_player = nxt
	_moves += 1

	var all_on := true
	for tk: Vector2i in _targets.keys():
		if not _crates.has(tk):
			all_on = false
			break
	if all_on:
		_won = true
		add_score(250)
		AudioSfx.play_fanfare()
	_update_status()
	queue_redraw()


func _update_status() -> void:
	if _won:
		status_changed.emit("Рівень %d/%d пройдено за %d ходів! Натисніть Пробіл / Далі" % [_lvl + 1, LEVELS.size(), _moves])
	else:
		status_changed.emit("Сокобан • Рівень %d/%d • Ходи: %d" % [_lvl + 1, LEVELS.size(), _moves])


func on_key_pressed(phys_key: int) -> void:
	match phys_key:
		KEY_W, KEY_UP: _move(Vector2i(0, -1))
		KEY_S, KEY_DOWN: _move(Vector2i(0, 1))
		KEY_A, KEY_LEFT: _move(Vector2i(-1, 0))
		KEY_D, KEY_RIGHT: _move(Vector2i(1, 0))
		KEY_Z, KEY_BACKSPACE: _do_undo()
		KEY_SPACE:
			if _won:
				_load_level(_lvl + 1)
		KEY_N: _load_level(_lvl + 1)
		KEY_P: _load_level(_lvl - 1)


func on_mouse_click(pos: Vector2) -> void:
	if BTN_PREV.has_point(pos):
		_load_level(_lvl - 1); AudioSfx.play_ui_click()
	elif BTN_UNDO.has_point(pos):
		_do_undo(); AudioSfx.play_ui_click()
	elif BTN_NEXT.has_point(pos):
		_load_level(_lvl + 1); AudioSfx.play_ui_click()


func _do_undo() -> void:
	if _undo.is_empty():
		return
	var u: Dictionary = _undo.pop_back()
	_player = u["p"]
	_crates = u["c"]
	_moves = int(u["m"])
	_won = false
	_update_status()
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, CANVAS_SIZE), Color(0.09, 0.11, 0.14))
	var rows := _grid.size()
	var cols := 0
	for row: Array in _grid:
		cols = maxi(cols, row.size())
	var cell := minf(36.0, minf(560.0 / maxf(cols, 1), 290.0 / maxf(rows, 1)))
	var org := Vector2((CANVAS_SIZE.x - cols * cell) * 0.5, (336.0 - rows * cell) * 0.5)

	for y: int in range(rows):
		var row: Array = _grid[y]
		for x: int in range(row.size()):
			var k := Vector2i(x, y)
			var rect := Rect2(org + Vector2(float(x), float(y)) * cell, Vector2(cell, cell))
			if str(row[x]) == "#":
				draw_rect(rect.grow(-1), Color(0.32, 0.36, 0.44))
				draw_rect(rect.grow(-3), Color(0.46, 0.50, 0.58), false, 1.5)
			else:
				draw_rect(rect, Color(0.14, 0.18, 0.22))
				if _targets.has(k):
					draw_circle(rect.get_center(), cell * 0.22, Color(0.24, 0.88, 0.52, 0.78))
				if _crates.has(k):
					var on_t := _targets.has(k)
					var cr := rect.grow(-4.0)
					draw_rect(cr, Color(0.95, 0.72, 0.18) if on_t else Color(0.68, 0.42, 0.18))
					draw_rect(cr, Color(1.0, 0.94, 0.55) if on_t else Color(0.38, 0.22, 0.08), false, 2.5)
				if k == _player:
					draw_circle(rect.get_center(), cell * 0.32, Color(0.22, 0.72, 0.98))
					draw_circle(rect.get_center() + Vector2(0, -cell * 0.08), cell * 0.10, Color.WHITE)

	MinigameBase.draw_ui_btn(self, BTN_PREV, "◀ Попер.", true)
	MinigameBase.draw_ui_btn(self, BTN_UNDO, "Назад [Z]", not _undo.is_empty(), Color(0.32, 0.82, 0.96))
	MinigameBase.draw_ui_btn(self, BTN_NEXT, "Наст. ▶", true, Color(0.32, 0.92, 0.48) if _won else Color(0.85, 0.68, 0.28))
