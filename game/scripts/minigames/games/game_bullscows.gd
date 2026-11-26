extends MinigameBase

# Bulls & Cows 4-Digit Logic Deduction (from Корови.html):
# Guess 4 unique digits (0-9) within 10 tries using Bulls & Cows feedback!

const CODE_LEN := 4
const MAX_TRIES := 10
const BTN_CHECK := Rect2(396, 320, 212, 42)
const BTN_BACK := Rect2(538, 250, 70, 52)

var _secret: String = ""
var _cur: String = ""
var _history: Array[Dictionary] = []


func get_game_title() -> String:
	return "Бики та Корови"


func get_controls_hint() -> String:
	return "Цифри 0..9 (без повторів!) — ввід або клік по клавіатурі | Enter — перевірити | Backspace — стерти"


func reset_game() -> void:
	var digits := ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
	digits.shuffle()
	_secret = digits[0] + digits[1] + digits[2] + digits[3]
	_cur = ""
	_history.clear()
	super.reset_game()
	status_changed.emit("Вгадайте 4 різні цифри (0..9) | Спроба 0/%d" % MAX_TRIES)
	queue_redraw()


func _add_digit(d: String) -> void:
	if game_over or _cur.length() >= CODE_LEN:
		return
	if _cur.contains(d):
		AudioSfx.play_brick_bump()
		return
	_cur += d
	AudioSfx.play_ui_click()
	queue_redraw()


func _submit() -> void:
	if game_over or _cur.length() < CODE_LEN:
		AudioSfx.play_brick_bump()
		return
	var bulls := 0
	var cows := 0
	for i: int in range(CODE_LEN):
		if _cur[i] == _secret[i]:
			bulls += 1
		elif _secret.contains(_cur[i]):
			cows += 1
	_history.append({"g": _cur, "b": bulls, "c": cows})
	_cur = ""

	if bulls == CODE_LEN:
		game_over = true
		add_score(1000 - (_history.size() - 1) * 90)
		AudioSfx.play_fanfare()
		status_changed.emit("ПЕРЕМОГА! Число %s вгадано за %d спроб! | R — знову" % [_secret, _history.size()])
	elif _history.size() >= MAX_TRIES:
		game_over = true
		AudioSfx.play_hit()
		status_changed.emit("Спроби закінчилися! Було загадано: %s | R — заново" % _secret)
	else:
		AudioSfx.play_coin() if bulls > 0 else AudioSfx.play_paddle_hit(0.0)
		status_changed.emit("Биків: %d  |  Корів: %d  (Спроба %d/%d)" % [bulls, cows, _history.size(), MAX_TRIES])
	queue_redraw()


func on_key_pressed(phys_key: int) -> void:
	if phys_key >= KEY_0 and phys_key <= KEY_9:
		_add_digit(str(phys_key - KEY_0))
	elif phys_key >= KEY_KP_0 and phys_key <= KEY_KP_9:
		_add_digit(str(phys_key - KEY_KP_0))
	elif phys_key == KEY_BACKSPACE and _cur.length() > 0:
		_cur = _cur.substr(0, _cur.length() - 1)
		AudioSfx.play_switch()
		queue_redraw()
	elif phys_key == KEY_ENTER or phys_key == KEY_KP_ENTER or phys_key == KEY_SPACE:
		_submit()


func _pad_rect(d_idx: int) -> Rect2:
	# 1..9 in 3x3 + 0 at bottom
	if d_idx == 0:
		return Rect2(468, 250, 62, 52)
	var i := d_idx - 1
	return Rect2(396 + float(i % 3) * 72.0, 74.0 + float(i / 3) * 58.0, 62.0, 50.0)


func on_mouse_click(pos: Vector2) -> void:
	if BTN_CHECK.has_point(pos):
		_submit(); return
	if BTN_BACK.has_point(pos):
		if _cur.length() > 0:
			_cur = _cur.substr(0, _cur.length() - 1)
			AudioSfx.play_switch()
			queue_redraw()
		return
	for d: int in range(10):
		if _pad_rect(d).has_point(pos):
			_add_digit(str(d))
			return


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, CANVAS_SIZE), Color(0.06, 0.08, 0.11))
	draw_rect(Rect2(24, 18, 344, 304), Color(0.11, 0.13, 0.18))
	draw_rect(Rect2(24, 18, 344, 304), Color(0.32, 0.38, 0.48), false, 1.5)
	var f := ThemeDB.fallback_font

	for ri: int in range(MAX_TRIES):
		var y := 44.0 + float(ri) * 28.0
		if ri < _history.size():
			var row: Dictionary = _history[ri]
			draw_string(f, Vector2(38, y), "%2d.   %s" % [ri + 1, row["g"]], HORIZONTAL_ALIGNMENT_LEFT, 160, 17, Color.WHITE)
			draw_rect(Rect2(190, y - 16, 74, 22), Color(0.14, 0.56, 0.28))
			draw_string(f, Vector2(190, y), "%d Бик." % int(row["b"]), HORIZONTAL_ALIGNMENT_CENTER, 74, 13, Color.WHITE)
			draw_rect(Rect2(274, y - 16, 82, 22), Color(0.76, 0.56, 0.10))
			draw_string(f, Vector2(274, y), "%d Кор." % int(row["c"]), HORIZONTAL_ALIGNMENT_CENTER, 82, 13, Color.WHITE)
		else:
			draw_string(f, Vector2(38, y), "%2d.   _ _ _ _" % (ri + 1), HORIZONTAL_ALIGNMENT_LEFT, 160, 15, Color(0.40, 0.45, 0.52))

	# Current code display boxes
	for i: int in range(CODE_LEN):
		var br := Rect2(44 + float(i) * 76.0, 334, 62, 46)
		draw_rect(br, Color(0.16, 0.20, 0.28))
		draw_rect(br, Color(0.88, 0.72, 0.28), false, 2.0)
		var ch := _secret[i] if game_over else (_cur[i] if i < _cur.length() else "")
		draw_string(f, Vector2(br.position.x, br.position.y + 32), ch, HORIZONTAL_ALIGNMENT_CENTER, 62, 26, Color(0.32, 0.96, 0.56) if game_over else Color.WHITE)

	draw_string(f, Vector2(396, 48), "КЛАВІАТУРА", HORIZONTAL_ALIGNMENT_CENTER, 212, 17, Color(0.98, 0.84, 0.34))
	for d: int in range(10):
		var used := _cur.contains(str(d))
		MinigameBase.draw_ui_btn(self, _pad_rect(d), str(d), not used and not game_over)
	MinigameBase.draw_ui_btn(self, BTN_BACK, "⌫", _cur.length() > 0 and not game_over, Color(0.86, 0.52, 0.24))
	MinigameBase.draw_ui_btn(self, BTN_CHECK, "Перевірити [Enter]", _cur.length() == CODE_LEN and not game_over, Color(0.24, 0.90, 0.48))
