class_name MinigameBase
extends Control

signal score_changed(new_score: int)
signal status_changed(text: String)

const CANVAS_SIZE := Vector2(640.0, 400.0)

var score: int = 0
var game_over: bool = false
var _keys_held: Dictionary = {}


func get_game_title() -> String:
	return ConfigManager.t("menu_play", "Game")


func get_controls_hint() -> String:
	return ConfigManager.t("mh_hint_default", "Arrows / WASD — move | Space — action | R — restart | Esc — exit")


func reset_game() -> void:
	score = 0
	game_over = false
	score_changed.emit(score)
	status_changed.emit("")
	queue_redraw()


func _ready() -> void:
	clip_contents = true


func add_score(pts: int) -> void:
	score += pts
	score_changed.emit(score)


func handle_input_event(event: InputEvent) -> void:
	if event is InputEventKey:
		var k := event as InputEventKey
		var phys := k.physical_keycode
		if k.pressed and not k.echo:
			_keys_held[phys] = true
			if phys == KEY_R:
				reset_game()
				return
			on_key_pressed(phys)
		elif not k.pressed:
			_keys_held[phys] = false
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			on_mouse_click(mb.position)
		elif not mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			on_mouse_release(mb.position)
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_RIGHT:
			on_right_click(mb.position)
	elif event is InputEventMouseMotion:
		on_mouse_move((event as InputEventMouseMotion).position)


func on_key_pressed(_phys_key: int) -> void:
	pass


func on_mouse_click(_pos: Vector2) -> void:
	pass


func on_mouse_release(_pos: Vector2) -> void:
	pass


func on_right_click(_pos: Vector2) -> void:
	pass


func on_mouse_move(_pos: Vector2) -> void:
	pass


static func draw_ui_btn(ci: CanvasItem, rect: Rect2, label: String, active: bool = true, accent: Color = Color(0.85, 0.68, 0.28)) -> void:
	var bg := Color(0.14, 0.30, 0.22) if active else Color(0.12, 0.14, 0.16)
	var bd := accent if active else Color(0.35, 0.38, 0.42)
	ci.draw_rect(rect, bg)
	ci.draw_rect(rect, bd, false, 1.8)
	var f := ThemeDB.fallback_font
	var tc := Color(0.98, 0.94, 0.82) if active else Color(0.55, 0.58, 0.62)
	ci.draw_string(f, Vector2(rect.position.x + 4, rect.position.y + rect.size.y * 0.64), label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 8, 13, tc)


static func draw_suit_pip(ci: CanvasItem, center: Vector2, suit: int, s: float, col: Color) -> void:
	# 0=Spades, 1=Hearts, 2=Diamonds, 3=Clubs
	match suit:
		0:
			ci.draw_colored_polygon(PackedVector2Array([center + Vector2(0, -s), center + Vector2(s * 0.9, s * 0.25), center + Vector2(-s * 0.9, s * 0.25)]), col)
			ci.draw_circle(center + Vector2(-s * 0.36, s * 0.25), s * 0.42, col)
			ci.draw_circle(center + Vector2(s * 0.36, s * 0.25), s * 0.42, col)
			ci.draw_colored_polygon(PackedVector2Array([center + Vector2(0, s * 0.2), center + Vector2(-s * 0.32, s * 0.95), center + Vector2(s * 0.32, s * 0.95)]), col)
		1:
			ci.draw_circle(center + Vector2(-s * 0.38, -s * 0.25), s * 0.45, col)
			ci.draw_circle(center + Vector2(s * 0.38, -s * 0.25), s * 0.45, col)
			ci.draw_colored_polygon(PackedVector2Array([center + Vector2(-s * 0.82, -s * 0.10), center + Vector2(s * 0.82, -s * 0.10), center + Vector2(0, s * 0.95)]), col)
		2:
			ci.draw_colored_polygon(PackedVector2Array([center + Vector2(0, -s), center + Vector2(s * 0.72, 0), center + Vector2(0, s), center + Vector2(-s * 0.72, 0)]), col)
		3:
			ci.draw_circle(center + Vector2(0, -s * 0.42), s * 0.40, col)
			ci.draw_circle(center + Vector2(-s * 0.44, s * 0.18), s * 0.40, col)
			ci.draw_circle(center + Vector2(s * 0.44, s * 0.18), s * 0.40, col)
			ci.draw_colored_polygon(PackedVector2Array([center + Vector2(0, s * 0.1), center + Vector2(-s * 0.28, s * 0.92), center + Vector2(s * 0.28, s * 0.92)]), col)


static func draw_playing_card(ci: CanvasItem, pos: Vector2, card_size: Vector2, rank_str: String, suit: int, face_up: bool = true, highlighted: bool = false) -> void:
	var r := Rect2(pos, card_size)
	ci.draw_rect(Rect2(pos + Vector2(2, 3), card_size), Color(0, 0, 0, 0.35))
	if not face_up:
		ci.draw_rect(r, Color(0.14, 0.22, 0.48))
		ci.draw_rect(r.grow(-3), Color(0.75, 0.22, 0.24), false, 1.5)
		ci.draw_rect(r, Color(0.92, 0.90, 0.86), false, 1.5)
		return
	ci.draw_rect(r, Color(0.98, 0.97, 0.94))
	ci.draw_rect(r, Color(0.96, 0.80, 0.22) if highlighted else Color(0.25, 0.24, 0.22), false, 2.5 if highlighted else 1.4)
	var col := Color(0.82, 0.12, 0.14) if (suit == 1 or suit == 2) else Color(0.12, 0.12, 0.15)
	var f := ThemeDB.fallback_font
	ci.draw_string(f, pos + Vector2(5, 16), rank_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, col)
	draw_suit_pip(ci, pos + Vector2(card_size.x - 10, 12), suit, 4.5, col)
	draw_suit_pip(ci, pos + card_size * 0.52, suit, minf(card_size.x, card_size.y) * 0.22, col)


func is_phys_held(phys_key: int) -> bool:
	return bool(_keys_held.get(phys_key, false))


func is_left_held() -> bool:
	return is_phys_held(KEY_A) or is_phys_held(KEY_LEFT)


func is_right_held() -> bool:
	return is_phys_held(KEY_D) or is_phys_held(KEY_RIGHT)


func is_up_held() -> bool:
	return is_phys_held(KEY_W) or is_phys_held(KEY_UP)


func is_down_held() -> bool:
	return is_phys_held(KEY_S) or is_phys_held(KEY_DOWN)


func is_action_held() -> bool:
	return is_phys_held(KEY_SPACE) or is_phys_held(KEY_ENTER)


func step_game(_delta: float) -> void:
	pass


static func is_left_key(phys: int) -> bool:
	return phys == KEY_A or phys == KEY_LEFT


static func is_right_key(phys: int) -> bool:
	return phys == KEY_D or phys == KEY_RIGHT


static func is_up_key(phys: int) -> bool:
	return phys == KEY_W or phys == KEY_UP


static func is_down_key(phys: int) -> bool:
	return phys == KEY_S or phys == KEY_DOWN


static func is_action_key(phys: int) -> bool:
	return phys == KEY_SPACE or phys == KEY_ENTER


func draw_game_over_banner(msg: String = "") -> void:
	if not game_over:
		return
	var banner := ConfigManager.t("mh_game_over", "GAME OVER — [R] Restart") if msg == "" else msg
	draw_rect(Rect2(90, 155, 460, 90), Color(0.05, 0.05, 0.08, 0.86))
	draw_rect(Rect2(90, 155, 460, 90), Color(0.95, 0.78, 0.3), false, 2.5)
	var font := ConfigManager.get_ui_font()
	draw_string(font, Vector2(110, 206), banner, HORIZONTAL_ALIGNMENT_CENTER, 420, 20, Color(1.0, 0.92, 0.72))


# Used on the 3D wall paintings in the Casino Room to show animated iconic artwork!
func draw_wall_preview(_ci: CanvasItem, _rect: Rect2, _anim_t: float) -> void:
	pass
