extends MinigameBase

# Classic Neon Casino Ping-Pong (from Теннис.html):
# W/S or Up/Down or Mouse Y movement | Play to 7 points per set vs AI!

const PADDLE_H := 82.0
const PADDLE_W := 14.0
const BALL_R := 8.5

var _p_y: float = 200.0
var _ai_y: float = 200.0
var _ball: Vector2 = Vector2(320, 200)
var _vel: Vector2 = Vector2(280, 140)
var _trail: Array[Vector2] = []
var _p_pts: int = 0
var _ai_pts: int = 0


func get_game_title() -> String:
	return "Теніс (Pong)"


func get_controls_hint() -> String:
	return "W/S або Стрілки ↑/↓ або Миша — ракетка | Гра до 7 очок | R — заново"


func reset_game() -> void:
	_p_pts = 0
	_ai_pts = 0
	_p_y = 200.0
	_ai_y = 200.0
	super.reset_game()
	_serve(true)


func _serve(to_right: bool) -> void:
	_ball = Vector2(320.0, 200.0)
	var ang := randf_range(-0.55, 0.55)
	var spd := 315.0
	_vel = Vector2(cos(ang) * (1.0 if to_right else -1.0), sin(ang)) * spd
	_trail.clear()
	status_changed.emit("Рахунок: Ви %d — %d Бот" % [_p_pts, _ai_pts])
	queue_redraw()


func on_mouse_move(pos: Vector2) -> void:
	_p_y = clampf(pos.y, PADDLE_H * 0.5 + 10.0, CANVAS_SIZE.y - PADDLE_H * 0.5 - 10.0)


func step_game(delta: float) -> void:
	if game_over:
		return
	var move_dir := 0.0
	if _keys_held.get(KEY_W, false) or _keys_held.get(KEY_UP, false): move_dir -= 1.0
	if _keys_held.get(KEY_S, false) or _keys_held.get(KEY_DOWN, false): move_dir += 1.0
	_p_y = clampf(_p_y + move_dir * 390.0 * delta, PADDLE_H * 0.5 + 10.0, CANVAS_SIZE.y - PADDLE_H * 0.5 - 10.0)

	# Smart AI paddle with subtle reaction speed limit
	var target_ai := _ball.y if _vel.x > 0.0 else 200.0
	_ai_y = move_toward(_ai_y, target_ai, 295.0 * delta)
	_ai_y = clampf(_ai_y, PADDLE_H * 0.5 + 10.0, CANVAS_SIZE.y - PADDLE_H * 0.5 - 10.0)

	_ball += _vel * delta
	_trail.push_front(_ball)
	if _trail.size() > 10:
		_trail.pop_back()

	if _ball.y < BALL_R + 10.0:
		_ball.y = BALL_R + 10.0
		_vel.y = absf(_vel.y)
		AudioSfx.play_paddle_hit(-0.3)
	elif _ball.y > CANVAS_SIZE.y - BALL_R - 10.0:
		_ball.y = CANVAS_SIZE.y - BALL_R - 10.0
		_vel.y = -absf(_vel.y)
		AudioSfx.play_paddle_hit(-0.3)

	# Player paddle (Left X = 32)
	if _vel.x < 0.0 and _ball.x - BALL_R <= 32.0 + PADDLE_W and _ball.x > 20.0:
		if absf(_ball.y - _p_y) <= PADDLE_H * 0.5 + BALL_R:
			var rel := clampf((_ball.y - _p_y) / (PADDLE_H * 0.5), -1.0, 1.0)
			var spd := minf(_vel.length() * 1.06, 620.0)
			var ang := rel * 0.95
			_vel = Vector2(cos(ang), sin(ang)) * spd
			_ball.x = 32.0 + PADDLE_W + BALL_R
			add_score(10)
			AudioSfx.play_paddle_hit(0.2)

	# AI paddle (Right X = 594)
	if _vel.x > 0.0 and _ball.x + BALL_R >= 594.0 and _ball.x < 620.0:
		if absf(_ball.y - _ai_y) <= PADDLE_H * 0.5 + BALL_R:
			var rel := clampf((_ball.y - _ai_y) / (PADDLE_H * 0.5), -1.0, 1.0)
			var spd := minf(_vel.length() * 1.05, 620.0)
			var ang := rel * 0.95
			_vel = Vector2(-cos(ang), sin(ang)) * spd
			_ball.x = 594.0 - BALL_R
			AudioSfx.play_paddle_hit(-0.1)

	if _ball.x < -12.0:
		_ai_pts += 1
		AudioSfx.play_hit()
		if _ai_pts >= 7:
			game_over = true
			status_changed.emit("Бот виграв (%d:%d)! Натисніть R для реваншу" % [_p_pts, _ai_pts])
		else:
			_serve(true)
	elif _ball.x > CANVAS_SIZE.x + 12.0:
		_p_pts += 1
		add_score(100)
		AudioSfx.play_goal()
		if _p_pts >= 7:
			game_over = true
			add_score(250)
			AudioSfx.play_fanfare()
			status_changed.emit("ПЕРЕМОГА (%d:%d)! Ви чемпіон столу! [R] — ще сет" % [_p_pts, _ai_pts])
		else:
			_serve(false)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, CANVAS_SIZE), Color(0.04, 0.08, 0.06))
	draw_rect(Rect2(10, 10, CANVAS_SIZE.x - 20, CANVAS_SIZE.y - 20), Color(0.22, 0.65, 0.44), false, 2.0)
	for dy: int in range(20, 385, 22):
		draw_rect(Rect2(318, dy, 4, 12), Color(0.85, 0.90, 0.86, 0.35))
	for i: int in range(_trail.size()):
		var a := 0.45 * (1.0 - float(i) / float(_trail.size()))
		draw_circle(_trail[i], BALL_R * (1.0 - float(i) * 0.06), Color(0.98, 0.84, 0.24, a))
	draw_circle(_ball, BALL_R, Color.WHITE)
	draw_rect(Rect2(32.0, _p_y - PADDLE_H * 0.5, PADDLE_W, PADDLE_H), Color(0.22, 0.78, 0.98))
	draw_rect(Rect2(594.0, _ai_y - PADDLE_H * 0.5, PADDLE_W, PADDLE_H), Color(0.96, 0.34, 0.30))
	var f := ThemeDB.fallback_font
	draw_string(f, Vector2(210, 56), "%d   :   %d" % [_p_pts, _ai_pts], HORIZONTAL_ALIGNMENT_CENTER, 220, 34, Color(0.98, 0.92, 0.56))
