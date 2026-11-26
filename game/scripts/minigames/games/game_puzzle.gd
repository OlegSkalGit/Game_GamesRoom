extends MinigameBase

const BOARD_POS := Vector2(26.0, 44.0)
const BOARD_SIZE := Vector2(360.0, 280.0)
const TRAY_POS := Vector2(408.0, 44.0)
const TRAY_W := 214.0
const LEVELS := [
	{"title": "Казино біля Озера", "cols": 3, "rows": 3},
	{"title": "Болід на Петлі", "cols": 4, "rows": 3},
	{"title": "Таємне Сховище", "cols": 4, "rows": 4},
	{"title": "Нічна Обсерваторія", "cols": 5, "rows": 4}
]

var _lvl_idx: int = 0
var _art_vp: SubViewport
var _art_canvas: Control
var _art_tex: Texture2D
var _cols: int = 3
var _rows: int = 3
var _placed: Dictionary = {} # Vector2i(c, r) -> source Vector2i (locked if matching!)
var _tray: Array[Vector2i] = []
var _selected_tray_i: int = -1
var _dragging: bool = false
var _drag_src: Vector2i = Vector2i(-1, -1)
var _drag_from_tray_i: int = -1
var _drag_pos: Vector2 = Vector2.ZERO
var _show_hint: bool = false
var _solved: bool = false
var _sparks: Array[Dictionary] = []

const BTN_PREV := Rect2(26.0, 342.0, 96.0, 34.0)
const BTN_HINT := Rect2(134.0, 342.0, 144.0, 34.0)
const BTN_NEXT := Rect2(290.0, 342.0, 96.0, 34.0)


func get_game_title() -> String:
	return "Пазли: Галерея"


func get_controls_hint() -> String:
	return "Миша: тягніть або клікайте фрагменти на рамку | H — підказка | Пробіл — авто-крок | Esc — вийти"


func _ready() -> void:
	super._ready()
	_art_vp = SubViewport.new()
	_art_vp.size = Vector2i(360, 280)
	_art_vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	_art_vp.transparent_bg = false
	add_child(_art_vp)
	_art_canvas = _ArtPainter.new()
	_art_canvas.custom_minimum_size = BOARD_SIZE
	_art_canvas.size = BOARD_SIZE
	_art_vp.add_child(_art_canvas)
	_art_tex = _art_vp.get_texture()


func reset_game() -> void:
	_lvl_idx = 0
	_load_level(0)
	super.reset_game()


func _load_level(idx: int) -> void:
	_lvl_idx = wrapi(idx, 0, LEVELS.size())
	var spec: Dictionary = LEVELS[_lvl_idx]
	_cols = int(spec["cols"])
	_rows = int(spec["rows"])
	_placed.clear()
	_tray.clear()
	_selected_tray_i = -1
	_dragging = false
	_solved = false
	_show_hint = false
	_sparks.clear()

	for r in range(_rows):
		for c in range(_cols):
			_tray.append(Vector2i(c, r))
	_tray.shuffle()

	if _art_canvas and _art_vp:
		(_art_canvas as _ArtPainter).scene_idx = _lvl_idx
		_art_canvas.queue_redraw()
		_art_vp.render_target_update_mode = SubViewport.UPDATE_ONCE

	status_changed.emit("%s (%dx%d) — Зібрано: 0/%d" % [spec["title"], _cols, _rows, _cols * _rows])
	queue_redraw()


func _cell_rect(c: int, r: int) -> Rect2:
	var cw := BOARD_SIZE.x / float(_cols)
	var ch := BOARD_SIZE.y / float(_rows)
	return Rect2(BOARD_POS.x + float(c) * cw, BOARD_POS.y + float(r) * ch, cw, ch)


func _tray_slot_rect(i: int) -> Rect2:
	var cols_t := 3
	var slot_w := 64.0
	var slot_h := 50.0
	var row := i / cols_t
	var col := i % cols_t
	return Rect2(TRAY_POS.x + float(col) * (slot_w + 8.0), TRAY_POS.y + float(row) * (slot_h + 6.0), slot_w, slot_h)


func _try_place(src_piece: Vector2i, target_cell: Vector2i) -> void:
	if _solved or _placed.has(target_cell):
		return
	if src_piece == target_cell:
		_placed[target_cell] = src_piece
		add_score(100)
		AudioSfx.play_puzzle_snap()
		var center := _cell_rect(target_cell.x, target_cell.y).get_center()
		for _s in range(12):
			var a := randf() * TAU
			var spd := randf_range(30.0, 120.0)
			_sparks.append({"pos": center, "vel": Vector2(cos(a), sin(a)) * spd, "t": 0.55})
		if _placed.size() == _cols * _rows:
			_solved = true
			add_score(300)
			AudioSfx.play_fanfare()
			status_changed.emit("КАРТИНУ ЗІБРАНО! Натисніть «Далі»")
		else:
			status_changed.emit("%s — Зібрано: %d/%d" % [LEVELS[_lvl_idx]["title"], _placed.size(), _cols * _rows])
	else:
		# Wrong cell -> bounce gently back into tray
		_tray.append(src_piece)
		AudioSfx.play_hit()


func on_mouse_click(pos: Vector2) -> void:
	if BTN_PREV.has_point(pos):
		_load_level(_lvl_idx - 1); AudioSfx.play_ui_click(); return
	if BTN_NEXT.has_point(pos):
		_load_level(_lvl_idx + 1); AudioSfx.play_ui_click(); return
	if BTN_HINT.has_point(pos):
		_show_hint = not _show_hint; AudioSfx.play_switch(); queue_redraw(); return

	if _solved:
		_load_level(_lvl_idx + 1)
		return

	# Pick up piece from Tray to Drag or Select
	var visible_cnt := mini(_tray.size(), 15)
	for i in range(visible_cnt):
		if _tray_slot_rect(i).has_point(pos):
			_selected_tray_i = i
			_dragging = true
			_drag_from_tray_i = i
			_drag_src = _tray[i]
			_drag_pos = pos
			AudioSfx.play_ui_click()
			queue_redraw()
			return

	# Clicking directly on Board when a Tray piece is selected
	if _selected_tray_i >= 0 and _selected_tray_i < _tray.size() and BOARD_POS.x <= pos.x and pos.x <= BOARD_POS.x + BOARD_SIZE.x and BOARD_POS.y <= pos.y and pos.y <= BOARD_POS.y + BOARD_SIZE.y:
		var cw := BOARD_SIZE.x / float(_cols)
		var ch := BOARD_SIZE.y / float(_rows)
		var gc := clampi(int((pos.x - BOARD_POS.x) / cw), 0, _cols - 1)
		var gr := clampi(int((pos.y - BOARD_POS.y) / ch), 0, _rows - 1)
		var sp := _tray[_selected_tray_i]
		_tray.remove_at(_selected_tray_i)
		_selected_tray_i = -1
		_try_place(sp, Vector2i(gc, gr))
		queue_redraw()


func on_mouse_move(pos: Vector2) -> void:
	if _dragging:
		_drag_pos = pos
		queue_redraw()


func on_mouse_release(pos: Vector2) -> void:
	if not _dragging:
		return
	_dragging = false
	var placed_ok := false
	if pos.x >= BOARD_POS.x and pos.x <= BOARD_POS.x + BOARD_SIZE.x and pos.y >= BOARD_POS.y and pos.y <= BOARD_POS.y + BOARD_SIZE.y:
		var cw := BOARD_SIZE.x / float(_cols)
		var ch := BOARD_SIZE.y / float(_rows)
		var gc := clampi(int((pos.x - BOARD_POS.x) / cw), 0, _cols - 1)
		var gr := clampi(int((pos.y - BOARD_POS.y) / ch), 0, _rows - 1)
		if not _placed.has(Vector2i(gc, gr)) and _drag_from_tray_i >= 0 and _drag_from_tray_i < _tray.size():
			_tray.remove_at(_drag_from_tray_i)
			_selected_tray_i = -1
			_try_place(_drag_src, Vector2i(gc, gr))
			placed_ok = true
	if not placed_ok:
		queue_redraw()


func on_key_pressed(phys_key: int) -> void:
	if phys_key == KEY_H:
		_show_hint = not _show_hint; AudioSfx.play_switch(); queue_redraw()
	elif is_left_key(phys_key):
		_load_level(_lvl_idx - 1)
	elif is_right_key(phys_key):
		_load_level(_lvl_idx + 1)
	elif is_action_key(phys_key):
		if _solved:
			_load_level(_lvl_idx + 1)
		elif not _tray.is_empty():
			var next_p := _tray.pop_front() as Vector2i
			_selected_tray_i = -1
			_try_place(next_p, next_p)
			queue_redraw()


func step_game(delta: float) -> void:
	if _sparks.is_empty():
		return
	for i in range(_sparks.size() - 1, -1, -1):
		_sparks[i]["t"] = float(_sparks[i]["t"]) - delta
		_sparks[i]["pos"] = (_sparks[i]["pos"] as Vector2) + (_sparks[i]["vel"] as Vector2) * delta
		if float(_sparks[i]["t"]) <= 0.0:
			_sparks.remove_at(i)
	queue_redraw()


func _draw_piece_tex(dest: Rect2, src_cell: Vector2i, alpha: float = 1.0) -> void:
	if _art_tex == null:
		return
	var cw := BOARD_SIZE.x / float(_cols)
	var ch := BOARD_SIZE.y / float(_rows)
	var src_r := Rect2(float(src_cell.x) * cw, float(src_cell.y) * ch, cw, ch)
	draw_texture_rect_region(_art_tex, dest, src_r, Color(1, 1, 1, alpha))


func _draw() -> void:
	var f := ThemeDB.fallback_font
	draw_rect(Rect2(Vector2.ZERO, CANVAS_SIZE), Color(0.11, 0.08, 0.06))
	draw_string(f, Vector2(26, 28), "ПАЗЛ %d/%d: «%s» (%dx%d)" % [_lvl_idx + 1, LEVELS.size(), LEVELS[_lvl_idx]["title"], _cols, _rows], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.98, 0.84, 0.36))

	# Wooden frame + target canvas backdrop
	draw_rect(Rect2(BOARD_POS - Vector2(6, 6), BOARD_SIZE + Vector2(12, 12)), Color(0.22, 0.15, 0.09))
	draw_rect(Rect2(BOARD_POS - Vector2(6, 6), BOARD_SIZE + Vector2(12, 12)), Color(0.84, 0.68, 0.28), false, 2.5)
	draw_rect(Rect2(BOARD_POS, BOARD_SIZE), Color(0.06, 0.05, 0.05))
	if _art_tex:
		draw_texture_rect(_art_tex, Rect2(BOARD_POS, BOARD_SIZE), false, Color(1, 1, 1, 0.92 if _show_hint else 0.14))

	for r in range(_rows):
		for c in range(_cols):
			var cr := _cell_rect(c, r)
			if _placed.has(Vector2i(c, r)):
				_draw_piece_tex(cr, _placed[Vector2i(c, r)])
				draw_rect(cr, Color(0.98, 0.86, 0.42, 0.45), false, 1.2)
			else:
				draw_rect(cr, Color(0.75, 0.68, 0.55, 0.28), false, 1.0)
				# Jigsaw notch hint circle along borders
				draw_circle(Vector2(cr.end.x, cr.get_center().y), 4.0, Color(0.75, 0.68, 0.55, 0.18))

	# Right Pieces Tray
	draw_rect(Rect2(TRAY_POS - Vector2(8, 8), Vector2(TRAY_W + 16, 336)), Color(0.08, 0.06, 0.05))
	draw_rect(Rect2(TRAY_POS - Vector2(8, 8), Vector2(TRAY_W + 16, 336)), Color(0.60, 0.46, 0.22), false, 1.8)
	draw_string(f, Vector2(TRAY_POS.x, 28), "Фрагменти (%d):" % _tray.size(), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.88, 0.86, 0.78))

	var show_n := mini(_tray.size(), 15)
	for i in range(show_n):
		if _dragging and i == _drag_from_tray_i:
			continue
		var sr := _tray_slot_rect(i)
		draw_rect(Rect2(sr.position + Vector2(2, 3), sr.size), Color(0, 0, 0, 0.35))
		_draw_piece_tex(sr, _tray[i])
		var sel := (i == _selected_tray_i)
		draw_rect(sr, Color(0.32, 0.96, 0.58) if sel else Color(0.84, 0.68, 0.28), false, 2.5 if sel else 1.2)

	if _dragging:
		var cw := BOARD_SIZE.x / float(_cols)
		var ch := BOARD_SIZE.y / float(_rows)
		var dr := Rect2(_drag_pos - Vector2(cw, ch) * 0.5, Vector2(cw, ch))
		draw_rect(Rect2(dr.position + Vector2(4, 6), dr.size), Color(0, 0, 0, 0.45))
		_draw_piece_tex(dr, _drag_src)
		draw_rect(dr, Color(1.0, 0.90, 0.36), false, 2.2)

	for sp in _sparks:
		draw_circle(sp["pos"], 3.0, Color(1.0, 0.92, 0.35))

	draw_ui_btn(self, BTN_PREV, "< Картина", true)
	draw_ui_btn(self, BTN_HINT, "Підказка (H)", _show_hint)
	draw_ui_btn(self, BTN_NEXT, "Далі >", true)

	if _solved:
		draw_rect(Rect2(66, 150, 280, 74), Color(0.05, 0.14, 0.08, 0.90))
		draw_rect(Rect2(66, 150, 280, 74), Color(0.98, 0.84, 0.26), false, 2.5)
		draw_string(f, Vector2(74, 184), "ПАЗЛ ЗІБРАНО!", HORIZONTAL_ALIGNMENT_CENTER, 264, 21, Color(1.0, 0.92, 0.38))
		draw_string(f, Vector2(74, 208), "Клік — наступна картина", HORIZONTAL_ALIGNMENT_CENTER, 264, 14, Color(0.88, 0.95, 0.88))


class _ArtPainter extends Control:
	var scene_idx: int = 0

	func _draw() -> void:
		var sz := size
		var r := Rect2(Vector2.ZERO, sz)
		if scene_idx == 0:
			# Sunset Alps & Casino by Mirror Lake
			for y in range(0, 175, 5):
				var u := float(y) / 175.0
				draw_rect(Rect2(0, y, sz.x, 6), Color(0.16, 0.24, 0.56).lerp(Color(0.96, 0.52, 0.24), u))
			draw_circle(Vector2(275, 86), 34.0, Color(1.0, 0.90, 0.48))
			draw_colored_polygon(PackedVector2Array([Vector2(0, 175), Vector2(75, 76), Vector2(165, 175)]), Color(0.18, 0.20, 0.32))
			draw_colored_polygon(PackedVector2Array([Vector2(115, 175), Vector2(225, 58), Vector2(360, 175)]), Color(0.22, 0.24, 0.36))
			draw_colored_polygon(PackedVector2Array([Vector2(204, 80), Vector2(225, 58), Vector2(248, 82)]), Color(0.92, 0.95, 0.98))
			draw_rect(Rect2(0, 175, sz.x, 105), Color(0.10, 0.32, 0.52))
			draw_rect(Rect2(105, 130, 150, 48), Color(0.24, 0.14, 0.12))
			draw_rect(Rect2(118, 142, 32, 20), Color(1.0, 0.84, 0.36))
			draw_rect(Rect2(210, 142, 32, 20), Color(1.0, 0.84, 0.36))
			draw_rect(Rect2(166, 144, 28, 34), Color(0.94, 0.72, 0.22))
			for px in [38, 62, 298, 325]:
				draw_colored_polygon(PackedVector2Array([Vector2(px, 118), Vector2(px - 18, 178), Vector2(px + 18, 178)]), Color(0.08, 0.24, 0.12))
		elif scene_idx == 1:
			# Race Car on Loop-the-Loop at Sunset
			draw_rect(r, Color(0.14, 0.28, 0.56))
			draw_rect(Rect2(0, 195, sz.x, 85), Color(0.14, 0.36, 0.16))
			draw_arc(Vector2(180, 128), 66.0, 0.0, TAU, 36, Color(0.26, 0.28, 0.32), 18.0)
			draw_arc(Vector2(180, 128), 66.0, -0.4, 1.0, 12, Color(0.26, 0.88, 1.0), 4.0)
			draw_rect(Rect2(0, 186, sz.x, 14), Color(0.24, 0.26, 0.30))
			draw_rect(Rect2(164, 52, 34, 15), Color(0.14, 0.52, 0.98))
			draw_rect(Rect2(72, 172, 36, 15), Color(0.94, 0.22, 0.20))
			draw_circle(Vector2(290, 56), 22.0, Color(1.0, 0.88, 0.40))
		elif scene_idx == 2:
			# Secret Vault Treasures
			draw_rect(r, Color(0.08, 0.10, 0.14))
			draw_circle(Vector2(105, 140), 76.0, Color(0.32, 0.36, 0.42))
			draw_circle(Vector2(105, 140), 62.0, Color(0.18, 0.22, 0.28))
			for by in range(4):
				for bx in range(4 - by):
					draw_rect(Rect2(195 + bx * 32 + by * 16, 224 - by * 18, 28, 14), Color(0.95, 0.76, 0.18))
					draw_rect(Rect2(195 + bx * 32 + by * 16, 224 - by * 18, 28, 14), Color(1.0, 0.94, 0.55), false, 1.2)
			draw_colored_polygon(PackedVector2Array([Vector2(265, 68), Vector2(302, 108), Vector2(265, 152), Vector2(228, 108)]), Color(0.18, 0.64, 1.0))
			draw_colored_polygon(PackedVector2Array([Vector2(265, 82), Vector2(286, 108), Vector2(265, 134), Vector2(244, 108)]), Color(0.55, 0.88, 1.0))
		else:
			# Aurora Borealis Observatory
			draw_rect(r, Color(0.03, 0.05, 0.14))
			for i in range(18):
				draw_circle(Vector2(fmod(float(i) * 73.0 + 25.0, sz.x), fmod(float(i) * 41.0 + 18.0, 125.0)), 1.6, Color(0.95, 0.96, 1.0))
			for ax in range(0, 360, 12):
				var h := 46.0 + sin(float(ax) * 0.03) * 20.0
				draw_line(Vector2(ax, 125), Vector2(ax, 125.0 - h), Color(0.22, 0.94, 0.64, 0.36), 8.0)
			draw_circle(Vector2(74, 62), 20.0, Color(0.96, 0.94, 0.82))
			draw_colored_polygon(PackedVector2Array([Vector2(0, 210), Vector2(120, 120), Vector2(240, 210), Vector2(360, 140), Vector2(360, 280), Vector2(0, 280)]), Color(0.06, 0.10, 0.18))
			draw_rect(Rect2(215, 132, 74, 58), Color(0.28, 0.22, 0.18))
			draw_circle(Vector2(252, 132), 34.0, Color(0.58, 0.44, 0.22))
			draw_rect(Rect2(0, 210, sz.x, 70), Color(0.06, 0.14, 0.28))
