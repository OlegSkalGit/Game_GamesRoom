extends MinigameBase

# Color Peg Codebreaker Lock (from Код.html):
# Guess 4-color secret code from 6 colors within 10 tries!
# Green dot = exact color & slot | Amber dot = right color, wrong slot.

const PALETTE := [
	{"name": "Черв.", "col": Color(0.92, 0.22, 0.22)},
	{"name": "Син.", "col": Color(0.22, 0.54, 0.96)},
	{"name": "Зел.", "col": Color(0.20, 0.82, 0.40)},
	{"name": "Жовт.", "col": Color(0.96, 0.82, 0.16)},
	{"name": "Фіол.", "col": Color(0.68, 0.30, 0.92)},
	{"name": "Пом.", "col": Color(0.96, 0.52, 0.14)}
]
const MAX_TRIES := 10
const CODE_LEN := 4
const BTN_CHECK := Rect2(430, 326, 176, 44)
const BTN_CLEAR := Rect2(430, 272, 176, 38)

var _secret: Array[int] = []
var _cur_guess: Array[int] = [-1, -1, -1, -1]
var _history: Array[Dictionary] = [] # {"g": Array[int], "exact": int, "near": int}
var _won: bool = false


func get_game_title() -> String:
	return "Кодовий замок"


func get_controls_hint() -> String:
	return "Миша або клавіші 1..6 — вибір кольору в замок | Enter / Пробіл — перевірити | Backspace — стерти"


func reset_game() -> void:
	_secret.clear()
	for _i: int in range(CODE_LEN):
		_secret.append(randi() % PALETTE.size())
	_cur_guess = [-1, -1, -1, -1]
	_history.clear()
	_won = false
	super.reset_game()
	status_changed.emit("Зламайте 4-колірний замок (Спроб: 0/%d)" % MAX_TRIES)
	queue_redraw()


func _push_color(ci: int) -> void:
	if game_over or _won:
		return
	for i: int in range(CODE_LEN):
		if _cur_guess[i] == -1:
			_cur_guess[i] = ci
			AudioSfx.play_ui_click()
			queue_redraw()
			return


func _pop_color() -> void:
	if game_over or _won:
		return
	for i: int in range(CODE_LEN - 1, -1, -1):
		if _cur_guess[i] != -1:
			_cur_guess[i] = -1
			AudioSfx.play_switch()
			queue_redraw()
			return


func _submit_guess() -> void:
	if game_over or _won:
		return
	if -1 in _cur_guess:
		AudioSfx.play_brick_bump()
		return

	var exact := 0
	var s_used := [false, false, false, false]
	var g_used := [false, false, false, false]
	for i: int in range(CODE_LEN):
		if _cur_guess[i] == _secret[i]:
			exact += 1
			s_used[i] = true
			g_used[i] = true
	var near := 0
	for i: int in range(CODE_LEN):
		if g_used[i]: continue
		for j: int in range(CODE_LEN):
			if not s_used[j] and _cur_guess[i] == _secret[j]:
				near += 1
				s_used[j] = true
				break

	_history.append({"g": _cur_guess.duplicate(), "exact": exact, "near": near})
	_cur_guess = [-1, -1, -1, -1]

	if exact == CODE_LEN:
		_won = true
		game_over = true
		add_score(1000 - (_history.size() - 1) * 80)
		AudioSfx.play_fanfare()
		status_changed.emit("ЗАМОК ВІДКРИТО за %d спроб! Натисніть R" % _history.size())
	elif _history.size() >= MAX_TRIES:
		game_over = true
		AudioSfx.play_hit()
		status_changed.emit("Спроби вичерпано! Код розкрито нижче | R — знову")
	else:
		AudioSfx.play_coin() if exact > 0 else AudioSfx.play_paddle_hit(0.0)
		status_changed.emit("Точно: %d | Не на місці: %d (Спроба %d/%d)" % [exact, near, _history.size(), MAX_TRIES])
	queue_redraw()


func on_key_pressed(phys_key: int) -> void:
	if phys_key >= KEY_1 and phys_key <= KEY_6:
		_push_color(phys_key - KEY_1)
	elif phys_key == KEY_BACKSPACE:
		_pop_color()
	elif phys_key == KEY_ENTER or phys_key == KEY_SPACE:
		_submit_guess()


func on_mouse_click(pos: Vector2) -> void:
	if BTN_CHECK.has_point(pos):
		_submit_guess(); return
	if BTN_CLEAR.has_point(pos):
		_pop_color(); return
	# Check palette circles on right panel
	for ci: int in range(PALETTE.size()):
		var cpos := Vector2(458.0 + float(ci % 3) * 58.0, 128.0 + float(ci / 3) * 62.0)
		if pos.distance_to(cpos) <= 23.0:
			_push_color(ci)
			return
	# Click on active guess peg to cycle color
	for i: int in range(CODE_LEN):
		var gpos := Vector2(82.0 + float(i) * 56.0, 352.0)
		if pos.distance_to(gpos) <= 20.0 and not game_over:
			_cur_guess[i] = (_cur_guess[i] + 1) % PALETTE.size()
			AudioSfx.play_ui_click()
			queue_redraw()
			return


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, CANVAS_SIZE), Color(0.07, 0.08, 0.11))
	draw_rect(Rect2(28, 16, 368, 306), Color(0.11, 0.13, 0.18))
	draw_rect(Rect2(28, 16, 368, 306), Color(0.32, 0.38, 0.48), false, 1.5)
	var f := ThemeDB.fallback_font

	# History rows (10 rows)
	for ri: int in range(MAX_TRIES):
		var y := 34.0 + float(ri) * 28.0
		draw_string(f, Vector2(36, y + 6), "%2d." % (ri + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.55, 0.60, 0.68))
		var has_row := ri < _history.size()
		for i: int in range(CODE_LEN):
			var p := Vector2(86.0 + float(i) * 44.0, y)
			if has_row:
				var col_idx: int = _history[ri]["g"][i]
				draw_circle(p, 10.5, PALETTE[col_idx]["col"])
			else:
				draw_circle(p, 9.5, Color(0.18, 0.21, 0.28))
		if has_row:
			var ex := int(_history[ri]["exact"])
			var nr := int(_history[ri]["near"])
			for k: int in range(CODE_LEN):
				var kp := Vector2(276.0 + float(k) * 22.0, y)
				if k < ex:
					draw_circle(kp, 6.5, Color(0.22, 0.90, 0.44))
				elif k < ex + nr:
					draw_circle(kp, 6.5, Color(0.96, 0.80, 0.18))
				else:
					draw_circle(kp, 4.5, Color(0.25, 0.28, 0.34))

	# Current guess row
	draw_rect(Rect2(28, 330, 368, 46), Color(0.14, 0.18, 0.24))
	for i: int in range(CODE_LEN):
		var gp := Vector2(82.0 + float(i) * 56.0, 353.0)
		if game_over and _secret.size() == CODE_LEN:
			draw_circle(gp, 16.0, PALETTE[_secret[i]]["col"])
		elif _cur_guess[i] >= 0:
			draw_circle(gp, 16.0, PALETTE[_cur_guess[i]]["col"])
		else:
			draw_circle(gp, 16.0, Color(0.22, 0.26, 0.34))
			draw_string(f, gp + Vector2(-6, 5), "?", HORIZONTAL_ALIGNMENT_CENTER, 12, 14, Color.WHITE)

	# Right panel palette
	draw_string(f, Vector2(430, 44), "ПАЛІТРА [1..6]", HORIZONTAL_ALIGNMENT_CENTER, 176, 16, Color(0.98, 0.86, 0.36))
	draw_string(f, Vector2(430, 74), "Зелений = точний збіг\nЖовтий = інше місце", HORIZONTAL_ALIGNMENT_CENTER, 176, 12, Color(0.75, 0.82, 0.80))
	for ci: int in range(PALETTE.size()):
		var cpos := Vector2(458.0 + float(ci % 3) * 58.0, 128.0 + float(ci / 3) * 62.0)
		draw_circle(cpos, 20.0, PALETTE[ci]["col"])
		draw_string(f, cpos + Vector2(-10, 5), str(ci + 1), HORIZONTAL_ALIGNMENT_CENTER, 20, 14, Color(0.05, 0.05, 0.05))

	MinigameBase.draw_ui_btn(self, BTN_CLEAR, "Стерти [Bksp]", not game_over, Color(0.86, 0.56, 0.24))
	MinigameBase.draw_ui_btn(self, BTN_CHECK, "Перевірити [Enter]", not (-1 in _cur_guess) and not game_over, Color(0.24, 0.90, 0.48))
