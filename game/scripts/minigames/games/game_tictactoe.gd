extends MinigameBase

# Tic-Tac-Toe 3x3 & 5x5 Extended vs Smart Minimax AI (from Крестики.html):

const BOARD_ORG := Vector2(100.0, 34.0)
const BOARD_SZ := 332.0
const BTN_MODE := Rect2(470, 96, 144, 40)
const BTN_FIRST := Rect2(470, 152, 144, 40)
const BTN_NEW := Rect2(470, 208, 144, 40)

var _n: int = 3 # 3x3 (3-in-row) or 5x5 (4-in-row!)
var _grid: Array[int] = [] # 0=empty, 1=Player(X), 2=AI(O)
var _ai_first: bool = false
var _win_line: Array[Vector2i] = []
var _wins_p: int = 0
var _wins_ai: int = 0
var _draws: int = 0


func get_game_title() -> String:
	return "Хрестики-Нулики"


func get_controls_hint() -> String:
	return "Миша — поставити Х | Перемикайте 3x3 та 5x5 (4 в ряд) або хто ходить першим | R — новий раунд"


func reset_game() -> void:
	_new_round()


func _new_round() -> void:
	_grid.clear()
	for _i: int in range(_n * _n):
		_grid.append(0)
	_win_line.clear()
	game_over = false
	score_changed.emit(score)
	if _ai_first:
		_ai_move()
	else:
		status_changed.emit("Ваш хід (X) • Ви %d : %d Бот (Нічиї: %d)" % [_wins_p, _wins_ai, _draws])
	queue_redraw()


func on_mouse_click(pos: Vector2) -> void:
	if BTN_MODE.has_point(pos):
		_n = 5 if _n == 3 else 3
		AudioSfx.play_ui_click()
		_new_round()
		return
	if BTN_FIRST.has_point(pos):
		_ai_first = not _ai_first
		AudioSfx.play_ui_click()
		_new_round()
		return
	if BTN_NEW.has_point(pos):
		AudioSfx.play_ui_click()
		_new_round()
		return
	if game_over:
		return
	var rel := pos - BOARD_ORG
	if rel.x >= 0 and rel.y >= 0 and rel.x < BOARD_SZ and rel.y < BOARD_SZ:
		var cell := BOARD_SZ / float(_n)
		var c := int(rel.x / cell)
		var r := int(rel.y / cell)
		var idx := r * _n + c
		if _grid[idx] == 0:
			_grid[idx] = 1
			AudioSfx.play_puzzle_snap()
			if not _check_end(1):
				_ai_move()
			queue_redraw()


func _find_win(player_val: int) -> Array[Vector2i]:
	var need := 3 if _n == 3 else 4
	for r: int in range(_n):
		for c: int in range(_n):
			for d: Vector2i in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, -1)]:
				var line: Array[Vector2i] = []
				var ok := true
				for k: int in range(need):
					var rr := r + d.y * k
					var cc := c + d.x * k
					if rr < 0 or rr >= _n or cc < 0 or cc >= _n or _grid[rr * _n + cc] != player_val:
						ok = false; break
					line.append(Vector2i(cc, rr))
				if ok:
					return line
	return []


func _check_end(who: int) -> bool:
	var wl := _find_win(who)
	if not wl.is_empty():
		_win_line = wl
		game_over = true
		if who == 1:
			_wins_p += 1
			add_score(150)
			AudioSfx.play_fanfare()
			status_changed.emit("ВИ ПЕРЕМОГЛИ! • Ви %d : %d Бот | R — ще" % [_wins_p, _wins_ai])
		else:
			_wins_ai += 1
			AudioSfx.play_hit()
			status_changed.emit("БОТ ПЕРЕМІГ • Ви %d : %d Бот | R — реванш" % [_wins_p, _wins_ai])
		return true
	if not (0 in _grid):
		_draws += 1
		game_over = true
		add_score(30)
		AudioSfx.play_coin()
		status_changed.emit("НІЧИЯ! • Ви %d : %d Бот | R — ще" % [_wins_p, _wins_ai])
		return true
	return false


func _ai_move() -> void:
	if game_over:
		return
	var best_idx := -1
	if _n == 3:
		var best_val := -999
		for i: int in range(9):
			if _grid[i] == 0:
				_grid[i] = 2
				var v := _minimax(false, 0)
				_grid[i] = 0
				if v > best_val:
					best_val = v; best_idx = i
	else:
		# Heuristic for 5x5: immediate win -> block player win -> center preference
		var empty: Array[int] = []
		for i: int in range(_n * _n):
			if _grid[i] == 0: empty.append(i)
		for i: int in empty:
			_grid[i] = 2
			if not _find_win(2).is_empty(): best_idx = i
			_grid[i] = 0
			if best_idx >= 0: break
		if best_idx < 0:
			for i: int in empty:
				_grid[i] = 1
				if not _find_win(1).is_empty(): best_idx = i
				_grid[i] = 0
				if best_idx >= 0: break
		if best_idx < 0 and _grid[12] == 0:
			best_idx = 12
		if best_idx < 0 and not empty.is_empty():
			best_idx = empty[randi() % empty.size()]

	if best_idx >= 0:
		_grid[best_idx] = 2
		if not _check_end(2):
			status_changed.emit("Ваш хід (X) • Ви %d : %d Бот (Нічиї: %d)" % [_wins_p, _wins_ai, _draws])


func _minimax(is_max: bool, depth: int) -> int:
	if not _find_win(2).is_empty(): return 10 - depth
	if not _find_win(1).is_empty(): return depth - 10
	if not (0 in _grid): return 0
	var best := -99 if is_max else 99
	for i: int in range(9):
		if _grid[i] == 0:
			_grid[i] = 2 if is_max else 1
			var v := _minimax(not is_max, depth + 1)
			_grid[i] = 0
			best = maxi(best, v) if is_max else mini(best, v)
	return best


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, CANVAS_SIZE), Color(0.06, 0.08, 0.11))
	draw_rect(Rect2(BOARD_ORG - Vector2(6, 6), Vector2(BOARD_SZ + 12, BOARD_SZ + 12)), Color(0.12, 0.15, 0.20))
	var cell := BOARD_SZ / float(_n)
	for i: int in range(1, _n):
		var off := float(i) * cell
		draw_line(BOARD_ORG + Vector2(off, 0), BOARD_ORG + Vector2(off, BOARD_SZ), Color(0.32, 0.42, 0.54), 3.0)
		draw_line(BOARD_ORG + Vector2(0, off), BOARD_ORG + Vector2(BOARD_SZ, off), Color(0.32, 0.42, 0.54), 3.0)
	for i: int in range(_grid.size()):
		var c := i % _n; var r := i / _n
		var ctr := BOARD_ORG + Vector2(float(c) + 0.5, float(r) + 0.5) * cell
		var rad := cell * 0.30
		if _grid[i] == 1:
			draw_line(ctr - Vector2(rad, rad), ctr + Vector2(rad, rad), Color(0.24, 0.78, 0.98), 5.0)
			draw_line(ctr + Vector2(-rad, rad), ctr + Vector2(rad, -rad), Color(0.24, 0.78, 0.98), 5.0)
		elif _grid[i] == 2:
			draw_arc(ctr, rad, 0.0, TAU, 36, Color(0.96, 0.36, 0.34), 5.0)
	if _win_line.size() >= 2:
		var a := BOARD_ORG + (Vector2(_win_line[0]) + Vector2(0.5, 0.5)) * cell
		var b := BOARD_ORG + (Vector2(_win_line[_win_line.size() - 1]) + Vector2(0.5, 0.5)) * cell
		draw_line(a, b, Color(0.98, 0.88, 0.22), 6.0)

	var f := ThemeDB.fallback_font
	draw_string(f, Vector2(470, 56), "ВИ %d : %d БОТ" % [_wins_p, _wins_ai], HORIZONTAL_ALIGNMENT_CENTER, 144, 18, Color(0.98, 0.84, 0.34))
	MinigameBase.draw_ui_btn(self, BTN_MODE, "Поле: %dx%d" % [_n, _n], true, Color(0.32, 0.84, 0.96))
	MinigameBase.draw_ui_btn(self, BTN_FIRST, "Перший: " + ("Бот" if _ai_first else "Ви"), true)
	MinigameBase.draw_ui_btn(self, BTN_NEW, "Новий раунд [R]", true, Color(0.24, 0.88, 0.48))
