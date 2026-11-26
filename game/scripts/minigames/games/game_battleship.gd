extends MinigameBase

# Classic 10x10 Naval Battleship (Морський бій) vs Smart Hunt/Target AI
const CELL := 24.0
const P_OX := 44.0
const E_OX := 348.0
const OY := 72.0
const FLEET_SIZES := [4, 3, 3, 2, 2, 2, 1, 1, 1, 1]

var _p_ships: Array = []
var _e_ships: Array = []
var _p_grid: Array = [] # 0=water, 1=ship
var _e_grid: Array = []
var _p_shots: Array = [] # Player shots at Enemy grid: 0=unknown, 1=miss, 2=hit
var _e_shots: Array = [] # AI shots at Player grid
var _ai_targets: Array[Vector2i] = []
var _player_turn: bool = true
var _started: bool = false
var _ai_timer: float = 0.0
var _banner: String = ""
const BTN_SHUFFLE := Rect2(44, 336, 175, 36)


func get_game_title() -> String:
	return "Морський бій (проти ШІ)"


func get_controls_hint() -> String:
	return "ЛКМ по правому полю — постріл | R — новий бій | Esc — вийти"


func reset_game() -> void:
	_p_ships.clear(); _e_ships.clear()
	_p_grid = _empty_grid(); _e_grid = _empty_grid()
	_p_shots = _empty_grid(); _e_shots = _empty_grid()
	_ai_targets.clear(); _player_turn = true; _started = false; _ai_timer = 0.0; _banner = ""
	_place_fleet(_p_grid, _p_ships)
	_place_fleet(_e_grid, _e_ships)
	super.reset_game()
	status_changed.emit("Стріляйте по правому полю ворога!")


func _empty_grid() -> Array:
	var g := []
	for _r in range(10):
		var row := []
		row.resize(10); row.fill(0)
		g.append(row)
	return g


func _place_fleet(grid: Array, ships: Array) -> void:
	for sz: int in FLEET_SIZES:
		for _try in range(200):
			var horiz := randf() < 0.5
			var r := randi() % (10 if horiz else (11 - sz))
			var c := randi() % ((11 - sz) if horiz else 10)
			var ok := true
			var cells: Array[Vector2i] = []
			for i in range(sz):
				var cr := r + (0 if horiz else i)
				var cc := c + (i if horiz else 0)
				cells.append(Vector2i(cc, cr))
				for dr: int in [-1, 0, 1]:
					for dc: int in [-1, 0, 1]:
						var nr: int = cr + dr; var nc: int = cc + dc
						if nr >= 0 and nr < 10 and nc >= 0 and nc < 10 and int(grid[nr][nc]) == 1:
							ok = false
			if ok:
				for p in cells: grid[p.y][p.x] = 1
				ships.append({"cells": cells, "sunk": false})
				break


func _mark_sunk_perimeter(shots: Array, ship: Dictionary) -> void:
	for p: Vector2i in ship["cells"]:
		for dr: int in [-1, 0, 1]:
			for dc: int in [-1, 0, 1]:
				var nr: int = p.y + dr; var nc: int = p.x + dc
				if nr >= 0 and nr < 10 and nc >= 0 and nc < 10 and int(shots[nr][nc]) == 0:
					shots[nr][nc] = 1


func _check_sunk(grid_ships: Array, shots: Array) -> int:
	var newly := 0
	var all_sunk := true
	for sh: Dictionary in grid_ships:
		if not bool(sh["sunk"]):
			var down := true
			for p: Vector2i in sh["cells"]:
				if int(shots[p.y][p.x]) != 2:
					down = false; break
			if down:
				sh["sunk"] = true
				_mark_sunk_perimeter(shots, sh)
				newly += 1
		if not bool(sh["sunk"]):
			all_sunk = false
	if all_sunk: return 2
	return 1 if newly > 0 else 0


func _ai_shoot() -> void:
	var target := Vector2i(-1, -1)
	while not _ai_targets.is_empty():
		var cand: Vector2i = _ai_targets.pop_back()
		if cand.x >= 0 and cand.x < 10 and cand.y >= 0 and cand.y < 10 and int(_e_shots[cand.y][cand.x]) == 0:
			target = cand; break
	if target.x < 0:
		var cands: Array[Vector2i] = []
		for r in range(10):
			for c in range(10):
				if int(_e_shots[r][c]) == 0:
					cands.append(Vector2i(c, r))
		if cands.is_empty(): return
		target = cands[randi() % cands.size()]

	if int(_p_grid[target.y][target.x]) == 1:
		_e_shots[target.y][target.x] = 2
		AudioSfx.play_explosion()
		for d: Vector2i in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
			_ai_targets.append(target + d)
		var res := _check_sunk(_p_ships, _e_shots)
		if res == 2:
			game_over = true; _banner = "ВАШ ФЛОТ ПОТОПЛЕНО!"
			status_changed.emit(_banner); queue_redraw(); return
		_ai_timer = 0.32 # Hit -> AI shoots again!
	else:
		_e_shots[target.y][target.x] = 1
		AudioSfx.play_brick_bump()
		_player_turn = true
		status_changed.emit("Ваш постріл!")
	queue_redraw()


func step_game(delta: float) -> void:
	if game_over: return
	if not _player_turn:
		_ai_timer -= delta
		if _ai_timer <= 0.0:
			_ai_shoot()


func on_mouse_click(pos: Vector2) -> void:
	if game_over: return
	if not _started and BTN_SHUFFLE.has_point(pos):
		_p_ships.clear(); _p_grid = _empty_grid()
		_place_fleet(_p_grid, _p_ships)
		AudioSfx.play_ui_click()
		queue_redraw()
		return
	if not _player_turn: return
	var gc := int((pos.x - E_OX) / CELL)
	var gr := int((pos.y - OY) / CELL)
	if gc < 0 or gc >= 10 or gr < 0 or gr >= 10 or int(_p_shots[gr][gc]) != 0:
		return
	_started = true
	if int(_e_grid[gr][gc]) == 1:
		_p_shots[gr][gc] = 2
		add_score(40)
		AudioSfx.play_explosion()
		var res := _check_sunk(_e_ships, _p_shots)
		if res == 1:
			add_score(100); status_changed.emit("КОРАБЕЛЬ ПОТОПЛЕНО! Стріляйте ще!")
		elif res == 2:
			add_score(400); game_over = true; AudioSfx.play_fanfare()
			_banner = "ПЕРЕМОГА НА МОРІ!"
			status_changed.emit(_banner)
		else:
			status_changed.emit("Влучили! Ваш хід триває!")
	else:
		_p_shots[gr][gc] = 1
		AudioSfx.play_ricochet()
		_player_turn = false
		_ai_timer = 0.35
		status_changed.emit("Мимо! Стріляє ворог...")
	queue_redraw()


func _draw_radar_grid(ox: float, show_ships: bool, grid: Array, shots: Array, ships: Array) -> void:
	var f := ThemeDB.fallback_font
	for i in range(10):
		draw_string(f, Vector2(ox + i * CELL + 8, OY - 8), char(65 + i), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.70, 0.85, 0.98))
		draw_string(f, Vector2(ox - 18, OY + i * CELL + 17), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.70, 0.85, 0.98))
	draw_rect(Rect2(ox, OY, CELL * 10, CELL * 10), Color(0.05, 0.18, 0.32))
	for r in range(10):
		for c in range(10):
			var sq := Rect2(ox + c * CELL, OY + r * CELL, CELL, CELL)
			draw_rect(sq, Color(0.18, 0.42, 0.65, 0.45), false, 1.0)
			if show_ships and int(grid[r][c]) == 1:
				draw_rect(sq.grow(-3), Color(0.48, 0.56, 0.64))
			var st := int(shots[r][c])
			if st == 1:
				draw_circle(sq.get_center(), 3.2, Color(0.45, 0.72, 0.95))
			elif st == 2:
				draw_rect(sq.grow(-3), Color(0.92, 0.34, 0.14))
				draw_line(sq.position + Vector2(4, 4), sq.end - Vector2(4, 4), Color(1.0, 0.92, 0.35), 2.0)
				draw_line(Vector2(sq.end.x - 4, sq.position.y + 4), Vector2(sq.position.x + 4, sq.end.y - 4), Color(1.0, 0.92, 0.35), 2.0)
	for sh: Dictionary in ships:
		if bool(sh["sunk"]):
			for p: Vector2i in sh["cells"]:
				draw_rect(Rect2(ox + p.x * CELL + 1, OY + p.y * CELL + 1, CELL - 2, CELL - 2), Color(0.95, 0.2, 0.2), false, 2.0)
	draw_rect(Rect2(ox, OY, CELL * 10, CELL * 10), Color(0.75, 0.62, 0.25), false, 2.0)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, CANVAS_SIZE), Color(0.03, 0.08, 0.15))
	var f := ThemeDB.fallback_font
	draw_string(f, Vector2(P_OX, 42), "ВАШ ФЛОТ", HORIZONTAL_ALIGNMENT_CENTER, CELL * 10, 16, Color(0.86, 0.95, 1.0))
	draw_string(f, Vector2(E_OX, 42), "АКВАТОРІЯ ВОРОГА", HORIZONTAL_ALIGNMENT_CENTER, CELL * 10, 16, Color(1.0, 0.78, 0.45))

	_draw_radar_grid(P_OX, true, _p_grid, _e_shots, _p_ships)
	_draw_radar_grid(E_OX, false, _e_grid, _p_shots, _e_ships)

	if not _started and not game_over:
		draw_ui_btn(self, BTN_SHUFFLE, "Перемішати флот", true)
	draw_game_over_banner(_banner + " — [R] Знову")
