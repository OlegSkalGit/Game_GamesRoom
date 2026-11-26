extends MinigameBase

const MAPS := [
	[
		"#####################",
		"#o........#........o#",
		"#.##.###..#..###.##.#",
		"#...................#",
		"#.##.#.#######.#.##.#",
		"#....#....#....#....#",
		"####.###..#..###.####",
		"....#...........#....",
		"####.#.##.#.##.#.####",
		"#o........#........o#",
		"#.##.###..#..###.##.#",
		"#...................#",
		"#####################"
	],
	[
		"#####################",
		"#o...#.........#...o#",
		"#.##.#.#######.#.##.#",
		"#...................#",
		"#.##.##..###..##.##.#",
		"#.......#...#.......#",
		"###.###.#...#.###.###",
		"........#...#........",
		"###.###.#####.###.###",
		"#o.................o#",
		"#.##.####.#.####.##.#",
		"#...................#",
		"#####################"
	]
]
const CELL := 28.0
const OX := 26.0
const OY := 18.0
const BASE_STEP_INTERVAL := 0.310 # 2x slower initial pace than 0.155s; gently speeds up per maze


func _get_step_interval() -> float:
	return maxf(0.155, BASE_STEP_INTERVAL - float(_level - 1) * 0.025)

var _level: int = 1
var _map_cur: Array = MAPS[0]

var _dots: Dictionary = {}
var _pills: Dictionary = {}
var _fruit_pos: Vector2i = Vector2i(10, 7)
var _fruit_active: bool = false
var _p_pos: Vector2i = Vector2i(10, 11)
var _p_prev: Vector2i = Vector2i(10, 11)
var _p_dir: Vector2i = Vector2i(1, 0)
var _next_dir: Vector2i = Vector2i(1, 0)
var _step_t: float = 0.0
var _fright_t: float = 0.0
var _lives: int = 3
var _anim_t: float = 0.0
var _ghosts: Array[Dictionary] = []


func get_game_title() -> String:
	return "Пак-Лабіринт"


func get_controls_hint() -> String:
	return "WASD або Стрілки — поворот | Зберіть усі точки! | R — заново | Esc — вийти"


func reset_game() -> void:
	_level = 1
	_lives = 3
	_load_maze()
	super.reset_game()


func _load_maze() -> void:
	_map_cur = MAPS[(_level - 1) % MAPS.size()]
	_dots.clear(); _pills.clear()
	for r in range(_map_cur.size()):
		var row_str: String = str(_map_cur[r])
		for c in range(row_str.length()):
			var ch: String = row_str[c]
			if ch == ".":
				_dots[Vector2i(c, r)] = true
			elif ch == "o":
				_pills[Vector2i(c, r)] = true
	_fright_t = 0.0; _fruit_active = false
	_reset_positions()


func _reset_positions() -> void:
	_p_pos = Vector2i(10, 11)
	_p_prev = Vector2i(10, 11)
	_p_dir = Vector2i(1, 0)
	_next_dir = Vector2i(1, 0)
	_step_t = 0.0
	_ghosts = [
		{"pos": Vector2i(9, 7), "prev": Vector2i(9, 7), "dir": Vector2i(1, 0), "color": Color(0.95, 0.22, 0.24)},
		{"pos": Vector2i(10, 7), "prev": Vector2i(10, 7), "dir": Vector2i(-1, 0), "color": Color(0.96, 0.58, 0.80)},
		{"pos": Vector2i(11, 7), "prev": Vector2i(11, 7), "dir": Vector2i(0, -1), "color": Color(0.24, 0.90, 0.96)},
		{"pos": Vector2i(10, 5), "prev": Vector2i(10, 5), "dir": Vector2i(1, 0), "color": Color(0.98, 0.62, 0.16)}
	]


func _is_wall(p: Vector2i) -> bool:
	if p.y < 0 or p.y >= _map_cur.size():
		return true
	var wx := wrapi(p.x, 0, str(_map_cur[0]).length())
	return str(_map_cur[p.y])[wx] == "#"


func on_key_pressed(phys_key: int) -> void:
	if is_left_key(phys_key): _next_dir = Vector2i(-1, 0)
	elif is_right_key(phys_key): _next_dir = Vector2i(1, 0)
	elif is_up_key(phys_key): _next_dir = Vector2i(0, -1)
	elif is_down_key(phys_key): _next_dir = Vector2i(0, 1)


func step_game(delta: float) -> void:
	_anim_t += delta
	if game_over:
		queue_redraw()
		return
	if _fright_t > 0.0:
		_fright_t = maxf(0.0, _fright_t - delta)

	var step_iv := _get_step_interval()
	_step_t += delta
	if _step_t >= step_iv:
		_step_t -= step_iv
		_p_prev = _p_pos
		if not _is_wall(_p_pos + _next_dir):
			_p_dir = _next_dir
		var np := _p_pos + _p_dir
		if not _is_wall(np):
			if np.x < 0 or np.x >= str(_map_cur[0]).length():
				np.x = wrapi(np.x, 0, str(_map_cur[0]).length())
				_p_prev = np
			_p_pos = np

		if _dots.has(_p_pos):
			_dots.erase(_p_pos)
			add_score(10)
			AudioSfx.play_waka()
			if _dots.size() == 50:
				_fruit_active = true
		elif _pills.has(_p_pos):
			_pills.erase(_p_pos)
			_fright_t = 7.5
			add_score(50)
			AudioSfx.play_powerup()
		if _fruit_active and _p_pos == _fruit_pos:
			_fruit_active = false
			add_score(300)
			AudioSfx.play_coin()

		for g in _ghosts:
			var gp: Vector2i = g["pos"]
			g["prev"] = gp
			var dirs := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
			var valid: Array[Vector2i] = []
			for d in dirs:
				if not _is_wall(gp + d) and d != -(g["dir"] as Vector2i):
					valid.append(d)
			if valid.is_empty():
				for d in dirs:
					if not _is_wall(gp + d):
						valid.append(d)
			if not valid.is_empty():
				var chosen: Vector2i = valid[randi() % valid.size()]
				if _fright_t <= 0.0 and randf() < 0.70:
					var best_d := 99999.0
					for d in valid:
						var dist := Vector2(gp + d).distance_to(Vector2(_p_pos))
						if dist < best_d:
							best_d = dist; chosen = d
				g["dir"] = chosen
				var ng := gp + chosen
				if ng.x < 0 or ng.x >= str(_map_cur[0]).length():
					ng.x = wrapi(ng.x, 0, str(_map_cur[0]).length())
					g["prev"] = ng
				g["pos"] = ng

		for g in _ghosts:
			if g["pos"] == _p_pos or (g["pos"] == _p_prev and g["prev"] == _p_pos):
				if _fright_t > 0.0:
					g["pos"] = Vector2i(10, 7); g["prev"] = Vector2i(10, 7)
					add_score(200)
					AudioSfx.play_goal()
				else:
					_lives -= 1
					AudioSfx.play_hit()
					if _lives <= 0:
						game_over = true
						status_changed.emit("Спіймано!")
					else:
						_reset_positions()
					break

		if _dots.is_empty() and _pills.is_empty():
			add_score(400)
			AudioSfx.play_fanfare()
			_level += 1
			_load_maze()

	status_changed.emit("Лабіринт %d  |  Життів: %d  |  Точок: %d" % [_level, _lives, _dots.size() + _pills.size()])
	queue_redraw()


func _cell_center(grid_p: Vector2) -> Vector2:
	return Vector2(OX + grid_p.x * CELL + CELL * 0.5, OY + grid_p.y * CELL + CELL * 0.5)


func _draw() -> void:
	var wall_fill := Color(0.10, 0.22, 0.65) if (_level % 2 == 1) else Color(0.14, 0.44, 0.34)
	var wall_rim := Color(0.24, 0.52, 1.0) if (_level % 2 == 1) else Color(0.28, 0.92, 0.62)
	draw_rect(Rect2(Vector2.ZERO, CANVAS_SIZE), Color(0.02, 0.02, 0.07))
	draw_rect(Rect2(OX, OY, str(_map_cur[0]).length() * CELL, _map_cur.size() * CELL), wall_rim, false, 2.0)
	for r in range(_map_cur.size()):
		var rs := str(_map_cur[r])
		for c in range(rs.length()):
			if rs[c] == "#":
				var wp := Vector2(OX + c * CELL, OY + r * CELL)
				draw_rect(Rect2(wp + Vector2(2, 2), Vector2(CELL - 4, CELL - 4)), wall_fill)
				draw_rect(Rect2(wp + Vector2(4, 4), Vector2(CELL - 8, CELL - 8)), wall_rim, false, 1.8)

	for dp: Vector2i in _dots.keys():
		draw_circle(_cell_center(Vector2(dp)), 2.8, Color(1.0, 0.88, 0.65))
	for pp: Vector2i in _pills.keys():
		var pr := 5.5 + sin(_anim_t * 6.0) * 1.4
		draw_circle(_cell_center(Vector2(pp)), pr, Color(1.0, 0.94, 0.72))

	if _fruit_active:
		var fp := _cell_center(Vector2(_fruit_pos))
		draw_circle(fp + Vector2(-3, 2), 4.5, Color(0.92, 0.14, 0.18))
		draw_circle(fp + Vector2(3, 3), 4.5, Color(0.92, 0.14, 0.18))
		draw_line(fp + Vector2(-3, -2), fp + Vector2(1, -8), Color(0.25, 0.80, 0.24), 1.8)
		draw_line(fp + Vector2(3, -1), fp + Vector2(1, -8), Color(0.25, 0.80, 0.24), 1.8)

	var frac := clampf(_step_t / _get_step_interval(), 0.0, 1.0)
	var p_smooth := Vector2(_p_prev).lerp(Vector2(_p_pos), frac)
	var pc := _cell_center(p_smooth)
	draw_circle(pc, 10.5, Color(1.0, 0.88, 0.14))
	var mouth := 0.15 + absf(sin(_anim_t * 14.0)) * 0.52
	var ang := Vector2(_p_dir).angle()
	draw_colored_polygon(PackedVector2Array([
		pc,
		pc + Vector2.from_angle(ang - mouth) * 11.2,
		pc + Vector2.from_angle(ang + mouth) * 11.2
	]), Color(0.02, 0.02, 0.07))

	for g in _ghosts:
		var gs := Vector2(g["prev"]).lerp(Vector2(g["pos"]), frac)
		var gp := _cell_center(gs)
		var scared := _fright_t > 0.0
		var flash := scared and _fright_t < 2.0 and int(_anim_t * 10.0) % 2 == 0
		var gcol: Color = Color(0.92, 0.94, 1.0) if flash else (Color(0.16, 0.34, 0.95) if scared else g["color"])
		draw_circle(gp + Vector2(0, -1), 10.0, gcol)
		draw_rect(Rect2(gp - Vector2(10, 1), Vector2(20, 9)), gcol)
		# Wavy skirt scallops strictly within cell bounds
		for sc_i in range(3):
			draw_circle(gp + Vector2(-6.6 + float(sc_i) * 6.6, 8.0), 3.3, gcol)
		if scared:
			draw_circle(gp + Vector2(-3.5, -2), 1.8, Color.WHITE)
			draw_circle(gp + Vector2(3.5, -2), 1.8, Color.WHITE)
		else:
			var gd := Vector2(g["dir"]) * 1.4
			draw_circle(gp + Vector2(-3.5, -2), 2.8, Color.WHITE)
			draw_circle(gp + Vector2(3.5, -2), 2.8, Color.WHITE)
			draw_circle(gp + Vector2(-3.5, -2) + gd, 1.4, Color(0.08, 0.15, 0.45))
			draw_circle(gp + Vector2(3.5, -2) + gd, 1.4, Color(0.08, 0.15, 0.45))

	draw_game_over_banner()
