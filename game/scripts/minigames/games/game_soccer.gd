extends MinigameBase

const PITCH := Rect2(44, 34, 552, 332)
const GOAL_TOP := 128.0
const GOAL_BOT := 272.0

var _p_pos: Vector2 = Vector2(160, 200)
var _p_gk_pos: Vector2 = Vector2(56, 200)
var _ai_pos: Vector2 = Vector2(460, 200)
var _gk_pos: Vector2 = Vector2(582, 200)
var _ball_pos: Vector2 = Vector2(320, 200)
var _ball_vel: Vector2 = Vector2.ZERO
var _p_goals: int = 0
var _ai_goals: int = 0
var _match_t: float = 90.0
var _ai_kick_cd: float = 0.0
var _anim_t: float = 0.0


func get_game_title() -> String:
	return "Соккер"


func get_controls_hint() -> String:
	return "WASD / Стрілки — біг | Пробіл — сильний удар | R — новий матч | Esc — вийти"


func reset_game() -> void:
	_p_goals = 0; _ai_goals = 0; _match_t = 90.0
	_ai_kick_cd = 0.0
	_reset_kickoff()
	AudioSfx.play_whistle()
	super.reset_game()


func _reset_kickoff() -> void:
	_p_pos = Vector2(180, 200)
	_p_gk_pos = Vector2(58, 200)
	_ai_pos = Vector2(440, 200)
	_gk_pos = Vector2(582, 200)
	_ball_pos = Vector2(320, 200)
	_ball_vel = Vector2.ZERO


func on_key_pressed(phys_key: int) -> void:
	if game_over:
		return
	if is_action_key(phys_key) and _p_pos.distance_to(_ball_pos) < 42.0:
		var raw_dir := (_ball_pos - _p_pos)
		var kick_dir := raw_dir.normalized() if raw_dir.length_squared() > 0.01 else Vector2(1, 0)
		if kick_dir.x > -0.15:
			# On attack, guide shot cleanly inside the goal frame toward the aimed corner
			var corner_bias := kick_dir.y * 68.0
			var target_y := clampf(_ball_pos.y + corner_bias, GOAL_TOP + 18.0, GOAL_BOT - 18.0)
			var goal_dir := (Vector2(PITCH.end.x + 12.0, target_y) - _ball_pos).normalized()
			kick_dir = kick_dir.lerp(goal_dir, 0.72).normalized()
		_ball_vel = kick_dir * 565.0
		AudioSfx.play_kick()


func step_game(delta: float) -> void:
	_anim_t += delta
	_ai_kick_cd = maxf(0.0, _ai_kick_cd - delta)
	if game_over:
		queue_redraw()
		return
	_match_t -= delta
	if _match_t <= 0.0:
		_match_t = 0.0
		game_over = true
		AudioSfx.play_whistle()
		status_changed.emit("ФІНАЛ %d:%d" % [_p_goals, _ai_goals])
		queue_redraw()
		return

	var mv := Vector2.ZERO
	if is_left_held(): mv.x -= 1.0
	if is_right_held(): mv.x += 1.0
	if is_up_held(): mv.y -= 1.0
	if is_down_held(): mv.y += 1.0
	if mv.length_squared() > 0.01:
		_p_pos += mv.normalized() * 228.0 * delta
	_p_pos.x = clampf(_p_pos.x, PITCH.position.x + 14, PITCH.end.x - 14)
	_p_pos.y = clampf(_p_pos.y, PITCH.position.y + 14, PITCH.end.y - 14)

	# Fair AI defender with realistic pace & kick cooldown
	var ai_target := _ball_pos + Vector2(24, 0) if _ball_pos.x < 510 else Vector2(410, 200)
	var ai_dir := ai_target - _ai_pos
	if ai_dir.length() > 6.0:
		_ai_pos += ai_dir.normalized() * 116.0 * delta
	_ai_pos.x = clampf(_ai_pos.x, PITCH.position.x + 14, PITCH.end.x - 14)
	_ai_pos.y = clampf(_ai_pos.y, PITCH.position.y + 14, PITCH.end.y - 14)
	if _ai_kick_cd <= 0.0 and _ai_pos.distance_to(_ball_pos) < 25.0:
		_ai_kick_cd = 0.72
		var shot := (Vector2(PITCH.position.x, randf_range(GOAL_TOP + 20.0, GOAL_BOT - 20.0)) - _ball_pos).normalized()
		_ball_vel = shot * 295.0
		AudioSfx.play_kick()

	# Realistic human-speed Goalkeepers (capped max speed 78 px/s instead of instant lerpf!)
	_p_gk_pos.y = move_toward(_p_gk_pos.y, clampf(_ball_pos.y, GOAL_TOP + 22.0, GOAL_BOT - 22.0), 86.0 * delta)
	_gk_pos.y = move_toward(_gk_pos.y, clampf(_ball_pos.y, GOAL_TOP + 22.0, GOAL_BOT - 22.0), 76.0 * delta)

	# Soft player dribble vs firm GK/AI deflections
	var dp := _ball_pos - _p_pos
	var dp_len := dp.length()
	if dp_len < 19.0 and dp_len > 0.01:
		_ball_pos = _p_pos + dp.normalized() * 19.0
		_ball_vel = dp.normalized() * clampf(maxf(_ball_vel.length() * 0.75, 130.0), 130.0, 260.0)
	for actor_info: Array in [[_ai_pos, 18.0], [_gk_pos, 15.0], [_p_gk_pos, 15.0]]:
		var actor: Vector2 = actor_info[0]
		var rad: float = float(actor_info[1])
		var d := _ball_pos - actor
		var dist := d.length()
		if dist < rad and dist > 0.01:
			_ball_pos = actor + d.normalized() * rad
			_ball_vel = d.normalized() * maxf(_ball_vel.length() * 0.80, 180.0)
			if rad < 16.0:
				AudioSfx.play_kick()

	_ball_pos += _ball_vel * delta
	_ball_vel *= pow(0.32, delta)

	if _ball_pos.y > GOAL_TOP + 4 and _ball_pos.y < GOAL_BOT - 4:
		if _ball_pos.x > PITCH.end.x + 4:
			_p_goals += 1; add_score(100); AudioSfx.play_fanfare(); _reset_kickoff()
		elif _ball_pos.x < PITCH.position.x - 4:
			_ai_goals += 1; AudioSfx.play_hit(); _reset_kickoff()
	else:
		if _ball_pos.x < PITCH.position.x + 8:
			_ball_pos.x = PITCH.position.x + 8; _ball_vel.x = absf(_ball_vel.x)
		elif _ball_pos.x > PITCH.end.x - 8:
			_ball_pos.x = PITCH.end.x - 8; _ball_vel.x = -absf(_ball_vel.x)

	if _ball_pos.y < PITCH.position.y + 8:
		_ball_pos.y = PITCH.position.y + 8; _ball_vel.y = absf(_ball_vel.y)
	elif _ball_pos.y > PITCH.end.y - 8:
		_ball_pos.y = PITCH.end.y - 8; _ball_vel.y = -absf(_ball_vel.y)

	status_changed.emit("%d : %d  |  %dс" % [_p_goals, _ai_goals, ceili(_match_t)])
	queue_redraw()


func _draw_player_sprite(pos: Vector2, jersey: Color, trim: Color) -> void:
	draw_circle(pos + Vector2(2, 4), 11.0, Color(0, 0, 0, 0.25))
	draw_circle(pos, 12.0, jersey)
	draw_rect(Rect2(pos.x - 5, pos.y - 11, 10, 22), trim)
	draw_circle(pos, 5.5, Color(0.95, 0.80, 0.65))


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, CANVAS_SIZE), Color(0.06, 0.28, 0.11))
	for s in range(10):
		if s % 2 == 0:
			draw_rect(Rect2(PITCH.position.x + s * (PITCH.size.x / 10.0), PITCH.position.y, PITCH.size.x / 10.0, PITCH.size.y), Color(0.10, 0.42, 0.17))
		else:
			draw_rect(Rect2(PITCH.position.x + s * (PITCH.size.x / 10.0), PITCH.position.y, PITCH.size.x / 10.0, PITCH.size.y), Color(0.08, 0.36, 0.14))

	draw_rect(PITCH, Color(0.94, 0.98, 0.94), false, 2.5)
	draw_line(Vector2(320, PITCH.position.y), Vector2(320, PITCH.end.y), Color(0.94, 0.98, 0.94), 2.0)
	draw_arc(Vector2(320, 200), 46.0, 0, TAU, 32, Color(0.94, 0.98, 0.94), 2.0)
	# Penalty areas
	draw_rect(Rect2(PITCH.position.x, 110, 76, 180), Color(0.94, 0.98, 0.94), false, 2.0)
	draw_rect(Rect2(PITCH.end.x - 76, 110, 76, 180), Color(0.94, 0.98, 0.94), false, 2.0)

	# Hatched Goal Nets cleanly inside outer bounds!
	for gx: float in [PITCH.position.x - 22.0, PITCH.end.x]:
		draw_rect(Rect2(gx, GOAL_TOP, 22, GOAL_BOT - GOAL_TOP), Color(0.04, 0.16, 0.08, 0.65))
		for ny in range(int(GOAL_TOP), int(GOAL_BOT), 10):
			draw_line(Vector2(gx, ny), Vector2(gx + 22, ny), Color(0.85, 0.88, 0.85, 0.35), 1.0)
		draw_rect(Rect2(gx, GOAL_TOP, 22, GOAL_BOT - GOAL_TOP), Color(0.95, 0.98, 0.95), false, 2.8)

	_draw_player_sprite(_p_gk_pos, Color(0.14, 0.72, 0.86), Color(0.08, 0.16, 0.24))
	_draw_player_sprite(_p_pos, Color(0.18, 0.48, 0.96), Color(0.96, 0.96, 1.0))
	_draw_player_sprite(_ai_pos, Color(0.92, 0.22, 0.22), Color(0.22, 0.06, 0.06))
	_draw_player_sprite(_gk_pos, Color(0.96, 0.65, 0.14), Color(0.15, 0.15, 0.18))

	draw_circle(_ball_pos + Vector2(2, 3), 8.0, Color(0, 0, 0, 0.28))
	draw_circle(_ball_pos, 8.0, Color(0.98, 0.98, 0.98))
	draw_circle(_ball_pos, 3.0, Color(0.12, 0.12, 0.15))
	draw_arc(_ball_pos, 8.0, 0, TAU, 16, Color(0.1, 0.1, 0.12), 1.5)
	draw_game_over_banner("МАТЧ ЗАВЕРШЕНО (%d : %d) — [R] Реванш" % [_p_goals, _ai_goals])
