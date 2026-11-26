extends MinigameBase

var _bird_y: float = 190.0
var _bird_vy: float = 0.0
var _started: bool = false
var _pipes: Array[Dictionary] = []
var _coins: Array[Dictionary] = []
var _sparks: Array[Dictionary] = []
var _spawn_t: float = 0.0
var _scroll_x: float = 0.0
var _anim_t: float = 0.0


func get_game_title() -> String:
	return "Сокіл Долини"


func get_controls_hint() -> String:
	return "Пробіл / W / ЛКМ — помах крилами | Збирайте монети між трубами! | R — заново | Esc — вийти"


func reset_game() -> void:
	_bird_y = 190.0
	_bird_vy = 0.0
	_started = false
	_pipes.clear()
	_coins.clear()
	_sparks.clear()
	_spawn_t = 0.18
	_scroll_x = 0.0
	super.reset_game()
	status_changed.emit("Натисніть Пробіл або ЛКМ для зльоту!")


func _flap() -> void:
	if game_over:
		return
	_started = true
	_bird_vy = -275.0
	AudioSfx.play_jump()
	for _i in range(4):
		_sparks.append({"pos": Vector2(132.0, _bird_y + 4.0), "vel": Vector2(-randf_range(40.0, 95.0), randf_range(-20.0, 40.0)), "t": 0.35})


func on_key_pressed(phys_key: int) -> void:
	if is_action_key(phys_key) or is_up_key(phys_key):
		_flap()


func on_mouse_click(_pos: Vector2) -> void:
	_flap()


func step_game(delta: float) -> void:
	_anim_t += delta
	for i in range(_sparks.size() - 1, -1, -1):
		_sparks[i]["t"] = float(_sparks[i]["t"]) - delta
		_sparks[i]["pos"] = (_sparks[i]["pos"] as Vector2) + (_sparks[i]["vel"] as Vector2) * delta
		if float(_sparks[i]["t"]) <= 0.0:
			_sparks.remove_at(i)

	if game_over or not _started:
		queue_redraw()
		return

	var spd := minf(265.0, 160.0 + float(score) * 0.14)
	_scroll_x += spd * delta
	_bird_vy += 760.0 * delta
	_bird_y += _bird_vy * delta

	_spawn_t -= delta
	if _spawn_t <= 0.0:
		_spawn_t = maxf(1.25, 1.72 - float(score) * 0.0005)
		var gap_y := randf_range(115.0, 275.0)
		var gap_h := maxf(108.0, 128.0 - float(score) * 0.02)
		_pipes.append({"x": 665.0, "gap_y": gap_y, "gap_h": gap_h, "passed": false})
		if randf() < 0.7:
			_coins.append({"pos": Vector2(691.0, gap_y), "taken": false})

	var bird_pos := Vector2(142.0, _bird_y)
	for pi in range(_pipes.size() - 1, -1, -1):
		var p: Dictionary = _pipes[pi]
		var px := float(p["x"]) - spd * delta
		p["x"] = px
		var gy := float(p["gap_y"])
		var gh := float(p["gap_h"]) * 0.5
		if not bool(p["passed"]) and px + 26.0 < bird_pos.x:
			p["passed"] = true
			add_score(25)
			AudioSfx.play_ui_click()
		if px < bird_pos.x + 12.0 and px + 52.0 > bird_pos.x - 12.0:
			if _bird_y - 11.0 < gy - gh or _bird_y + 11.0 > gy + gh:
				game_over = true
				AudioSfx.play_hit()
				status_changed.emit("Зіткнення! Рахунок: %d" % score)
		if px < -70.0:
			_pipes.remove_at(pi)

	for ci in range(_coins.size() - 1, -1, -1):
		var cp: Vector2 = (_coins[ci]["pos"] as Vector2) - Vector2(spd * delta, 0.0)
		_coins[ci]["pos"] = cp
		if not bool(_coins[ci]["taken"]) and cp.distance_to(bird_pos) < 22.0:
			_coins[ci]["taken"] = true
			add_score(50)
			AudioSfx.play_coin()
		if cp.x < -30.0 or bool(_coins[ci]["taken"]):
			_coins.remove_at(ci)

	if _bird_y < 14.0 or _bird_y > 352.0:
		game_over = true
		AudioSfx.play_hit()
		status_changed.emit("Фінал польоту!")
	elif not game_over:
		status_changed.emit("Швидкість: %d  |  Рахунок: %d" % [int(spd), score])
	queue_redraw()


func _draw() -> void:
	# Sunset sky gradient
	for sy in range(0, 360, 12):
		var u := float(sy) / 360.0
		draw_rect(Rect2(0, sy, 640, 13), Color(0.10, 0.16, 0.36).lerp(Color(0.88, 0.48, 0.24), u))
	draw_circle(Vector2(500, 96), 34.0, Color(1.0, 0.90, 0.48, 0.92))

	# Parallax Alpine peaks & silhouetted pines
	for mx in range(-1, 6):
		var bx := float(mx) * 160.0 - fmod(_scroll_x * 0.22, 160.0)
		draw_colored_polygon(PackedVector2Array([Vector2(bx, 360), Vector2(bx + 80, 210), Vector2(bx + 170, 360)]), Color(0.14, 0.18, 0.28))
	for tx in range(-1, 14):
		var px := float(tx) * 56.0 - fmod(_scroll_x * 0.55, 56.0)
		draw_colored_polygon(PackedVector2Array([Vector2(px + 20, 285), Vector2(px, 360), Vector2(px + 40, 360)]), Color(0.06, 0.18, 0.10))

	# Emerald Marble Pipes with golden caps
	for p in _pipes:
		var px := float(p["x"])
		var top_h := float(p["gap_y"]) - float(p["gap_h"]) * 0.5
		var bot_y := float(p["gap_y"]) + float(p["gap_h"]) * 0.5
		draw_rect(Rect2(px, 0, 52, top_h), Color(0.12, 0.52, 0.28))
		draw_rect(Rect2(px + 6, 0, 10, top_h), Color(0.28, 0.78, 0.44))
		draw_rect(Rect2(px - 4, top_h - 18, 60, 18), Color(0.86, 0.68, 0.24))
		draw_rect(Rect2(px, bot_y, 52, 360 - bot_y), Color(0.12, 0.52, 0.28))
		draw_rect(Rect2(px + 6, bot_y, 10, 360 - bot_y), Color(0.28, 0.78, 0.44))
		draw_rect(Rect2(px - 4, bot_y, 60, 18), Color(0.86, 0.68, 0.24))

	for c in _coins:
		var cp: Vector2 = c["pos"]
		var r := 8.5 + sin(_anim_t * 6.0) * 1.2
		draw_circle(cp, r, Color(0.98, 0.80, 0.18))
		draw_circle(cp - Vector2(2, 2), 3.0, Color(1, 1, 0.8, 0.8))

	# Meadow grass floor
	draw_rect(Rect2(0, 360, 640, 40), Color(0.16, 0.44, 0.18))
	draw_rect(Rect2(0, 360, 640, 6), Color(0.30, 0.72, 0.28))

	for sp in _sparks:
		draw_circle(sp["pos"], 2.6, Color(1.0, 0.88, 0.38, clampf(float(sp["t"]) * 2.5, 0.0, 1.0)))

	# Bird sprite
	var bp := Vector2(142.0, _bird_y)
	draw_circle(bp, 13.0, Color(0.98, 0.76, 0.18))
	draw_circle(bp + Vector2(-4, 2 + sin(_anim_t * 16.0) * 3.0), 7.0, Color(1.0, 0.92, 0.55))
	draw_circle(bp + Vector2(6, -3), 4.0, Color.WHITE)
	draw_circle(bp + Vector2(7, -3), 1.8, Color.BLACK)
	draw_colored_polygon(PackedVector2Array([bp + Vector2(10, 0), bp + Vector2(20, 3), bp + Vector2(10, 6)]), Color(0.96, 0.42, 0.12))

	draw_game_over_banner()
