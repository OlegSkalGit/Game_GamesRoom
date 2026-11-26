class_name IntroSplash
extends CanvasLayer

signal finished

var _canvas: _IntroDraw
var _t: float = 0.0
var _fading_out: bool = false
var _fade_a: float = 1.0
var _done: bool = false


func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	_canvas = _IntroDraw.new()
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_canvas)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if DisplayServer.get_name() != "headless":
		AudioSfx.play_intro_fanfare()


func _process(delta: float) -> void:
	if _done:
		return
	_t += delta
	if _fading_out:
		_fade_a = maxf(0.0, _fade_a - delta * 3.8)
		if _fade_a <= 0.0:
			_finish_now()
			return
	elif _t >= 2.65:
		_fade_a = maxf(0.0, 1.0 - (_t - 2.65) / 0.65)
		if _fade_a <= 0.0:
			_finish_now()
			return
	_canvas.anim_t = _t
	_canvas.master_alpha = _fade_a
	_canvas.queue_redraw()


func _input(event: InputEvent) -> void:
	if _done:
		return
	var triggered := false
	if event is InputEventKey:
		var k := event as InputEventKey
		if k.pressed and not k.echo:
			if k.physical_keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER, KEY_ESCAPE]:
				triggered = true
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and (mb.button_index == MOUSE_BUTTON_LEFT or mb.button_index == MOUSE_BUTTON_RIGHT):
			triggered = true
	if triggered:
		get_viewport().set_input_as_handled()
		skip(false)


func skip(immediate: bool = false) -> void:
	if _done:
		return
	if immediate:
		_finish_now()
		return
	if not _fading_out:
		_fading_out = true
		AudioSfx.play_ui_click()


func is_playing() -> bool:
	return not _done


func _finish_now() -> void:
	if _done:
		return
	_done = true
	visible = false
	finished.emit()
	queue_free()


class _IntroDraw extends Control:
	var anim_t: float = 0.0
	var master_alpha: float = 1.0
	var _logo_tex: Texture2D
	var _sparks: Array[Dictionary] = []

	func _ready() -> void:
		if ResourceLoader.exists("res://splash.png"):
			_logo_tex = load("res://splash.png") as Texture2D
		if _logo_tex == null:
			var abs_p := ProjectSettings.globalize_path("res://splash.png")
			if FileAccess.file_exists(abs_p):
				var img := Image.load_from_file(abs_p)
				if img != null:
					_logo_tex = ImageTexture.create_from_image(img)
		for i in range(44):
			_sparks.append({
				"x": fmod(float(i) * 0.618034, 1.0),
				"y": fmod(float(i) * 0.381966 + 0.12, 1.0),
				"spd": 0.04 + fmod(float(i) * 0.17, 0.09),
				"r": 1.4 + fmod(float(i) * 0.73, 2.4),
				"ph": float(i) * 0.9
			})

	func _draw() -> void:
		var sz := size
		if sz.x < 10.0 or sz.y < 10.0:
			return
		var a := master_alpha
		draw_rect(Rect2(Vector2.ZERO, sz), Color(0.008, 0.028, 0.02, a))

		# Animated dual golden searchlights sweeping behind the crest
		var cx := sz.x * 0.5
		var cy := sz.y * 0.44
		var glow_in := clampf(anim_t / 0.55, 0.0, 1.0)
		for side: float in [-1.0, 1.0]:
			var base_pt := Vector2(cx + side * sz.x * 0.28, sz.y * 0.98)
			var sway := sin(anim_t * 1.45 + side * 0.9) * sz.x * 0.16
			var top_c := Vector2(cx + sway, -sz.y * 0.05)
			var spread := sz.x * 0.11
			var beam := PackedVector2Array([
				base_pt + Vector2(-18, 0), base_pt + Vector2(18, 0),
				top_c + Vector2(spread, 0), top_c - Vector2(spread, 0)
			])
			draw_colored_polygon(beam, Color(0.96, 0.78, 0.30, 0.08 * glow_in * a))

		# Emblem backdrop texture (seamless #080D0A vignette)
		if _logo_tex:
			var sc := lerpf(0.92, 1.02, clampf(anim_t / 3.2, 0.0, 1.0))
			var tex_sz := _logo_tex.get_size()
			var fit := minf(sz.x * 0.68 / maxf(tex_sz.x, 1.0), sz.y * 0.56 / maxf(tex_sz.y, 1.0)) * sc
			var draw_w := tex_sz.x * fit
			var draw_h := tex_sz.y * fit
			var logo_rect := Rect2(cx - draw_w * 0.5, cy - draw_h * 0.52, draw_w, draw_h)
			draw_texture_rect(_logo_tex, logo_rect, false, Color(1, 1, 1, glow_in * a))
		else:
			draw_arc(Vector2(cx, cy), minf(sz.x, sz.y) * 0.18, 0.0, TAU, 48, Color(0.95, 0.78, 0.34, glow_in * a), 4.0)

		# Floating golden dust sparks
		for sp in _sparks:
			var sy := fposmod(float(sp["y"]) - anim_t * float(sp["spd"]), 1.0)
			var sx := float(sp["x"]) + sin(anim_t * 1.2 + float(sp["ph"])) * 0.015
			var twk := 0.35 + 0.65 * absf(sin(anim_t * 2.6 + float(sp["ph"])))
			draw_circle(Vector2(sx * sz.x, sy * sz.y), float(sp["r"]), Color(1.0, 0.86, 0.42, 0.52 * twk * glow_in * a))

		# Animated Title & Shimmer Rule
		var txt_in := clampf((anim_t - 0.25) / 0.55, 0.0, 1.0)
		var f := ThemeDB.fallback_font
		var title_y := minf(sz.y * 0.77, cy + sz.y * 0.30)
		var slide_y := (1.0 - txt_in) * 18.0
		draw_string(f, Vector2(0, title_y + slide_y), "ЛІСОВЕ КАЗИНО", HORIZONTAL_ALIGNMENT_CENTER, sz.x, 44, Color(0.98, 0.84, 0.36, txt_in * a))

		var bar_w := clampf((anim_t - 0.35) / 0.50, 0.0, 1.0) * minf(sz.x * 0.42, 460.0)
		draw_line(Vector2(cx - bar_w * 0.5, title_y + 14.0), Vector2(cx + bar_w * 0.5, title_y + 14.0), Color(0.95, 0.78, 0.32, 0.85 * a), 2.2)

		var sub_in := clampf((anim_t - 0.50) / 0.55, 0.0, 1.0)
		draw_string(f, Vector2(0, title_y + 42.0), "СВІТ 24 ІГОР  •  ПІДЗЕМНА ГАЛЕРЕЯ  •  ГІРСЬКИЙ ТРЕК", HORIZONTAL_ALIGNMENT_CENTER, sz.x, 18, Color(0.88, 0.92, 0.86, sub_in * a))

		var hint_pulse := (0.60 + 0.30 * sin(anim_t * 3.5)) * txt_in * a
		draw_string(f, Vector2(0, sz.y - 26.0), "Натисніть [Пробіл], [Enter], [Esc] або ЛКМ — пропустити", HORIZONTAL_ALIGNMENT_CENTER, sz.x, 14, Color(0.76, 0.82, 0.78, hint_pulse))
