extends MinigameBase

# Casino Memory Pairs Game (from Дубликат.html / Дубликат 2.html):
# Flip cards to find matching pairs with 4x4 (16 cards) and 6x4 (24 cards) grids!

const BTN_MODE := Rect2(492, 86, 128, 38)
const SYMBOLS := [
	{"lbl": "♦", "col": Color(0.95, 0.25, 0.25)},
	{"lbl": "♠", "col": Color(0.22, 0.72, 0.98)},
	{"lbl": "♣", "col": Color(0.24, 0.88, 0.44)},
	{"lbl": "♥", "col": Color(0.96, 0.36, 0.62)},
	{"lbl": "★", "col": Color(0.98, 0.82, 0.18)},
	{"lbl": "☀", "col": Color(0.98, 0.56, 0.16)},
	{"lbl": "☾", "col": Color(0.68, 0.48, 0.98)},
	{"lbl": "♛", "col": Color(0.24, 0.92, 0.82)},
	{"lbl": "7", "col": Color(1.00, 0.90, 0.38)},
	{"lbl": "⚓", "col": Color(0.45, 0.82, 0.96)},
	{"lbl": "⚡", "col": Color(0.98, 0.92, 0.24)},
	{"lbl": "✿", "col": Color(0.96, 0.52, 0.88)}
]

var _cols: int = 4
var _rows: int = 4
var _cards: Array[Dictionary] = []
var _open: Array[int] = []
var _hide_t: float = 0.0
var _moves: int = 0
var _matched_pairs: int = 0
var _combo: int = 0


func get_game_title() -> String:
	return "Меморі"


func get_controls_hint() -> String:
	return "Миша — відкривати карти | Знайдіть усі пари | R — новий розклад"


func reset_game() -> void:
	super.reset_game()
	_deal_board()


func _deal_board() -> void:
	var pair_cnt := (_cols * _rows) / 2
	var ids: Array[int] = []
	for i: int in range(pair_cnt):
		ids.append(i)
		ids.append(i)
	ids.shuffle()
	_cards.clear()
	for id: int in ids:
		_cards.append({"id": id, "face": false, "matched": false})
	_open.clear()
	_hide_t = 0.0
	_moves = 0
	_matched_pairs = 0
	_combo = 0
	_update_status()
	queue_redraw()


func _card_rect(i: int) -> Rect2:
	var area_w := 440.0
	var area_h := 340.0
	var cw := area_w / float(_cols)
	var ch := area_h / float(_rows)
	var c := i % _cols
	var r := i / _cols
	return Rect2(26.0 + float(c) * cw, 30.0 + float(r) * ch, cw, ch).grow(-5.0)


func step_game(delta: float) -> void:
	if _hide_t > 0.0:
		_hide_t -= delta
		if _hide_t <= 0.0:
			for idx: int in _open:
				if idx >= 0 and idx < _cards.size():
					_cards[idx]["face"] = false
			_open.clear()
			queue_redraw()


func on_mouse_click(pos: Vector2) -> void:
	if BTN_MODE.has_point(pos):
		_cols = 6 if _cols == 4 else 4
		AudioSfx.play_ui_click()
		_deal_board()
		return
	if _hide_t > 0.0 or game_over:
		return
	for i: int in range(_cards.size()):
		if _card_rect(i).has_point(pos):
			if bool(_cards[i]["face"]) or bool(_cards[i]["matched"]):
				return
			_cards[i]["face"] = true
			_open.append(i)
			AudioSfx.play_card_flip()
			if _open.size() == 2:
				_moves += 1
				var c0: Dictionary = _cards[_open[0]]
				var c1: Dictionary = _cards[_open[1]]
				if int(c0["id"]) == int(c1["id"]):
					c0["matched"] = true
					c1["matched"] = true
					_open.clear()
					_matched_pairs += 1
					_combo += 1
					add_score(60 + _combo * 25)
					AudioSfx.play_coin()
					if _matched_pairs >= (_cols * _rows) / 2:
						game_over = true
						add_score(maxi(0, 300 - _moves * 5))
						AudioSfx.play_fanfare()
				else:
					_combo = 0
					_hide_t = 0.65
			_update_status()
			queue_redraw()
			return


func _update_status() -> void:
	var tot := (_cols * _rows) / 2
	if game_over:
		status_changed.emit("Усі %d пар знайдено за %d ходів! R — нова гра" % [tot, _moves])
	else:
		status_changed.emit("Пари: %d/%d  |  Ходи: %d  |  Рахунок: %d" % [_matched_pairs, tot, _moves, score])


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, CANVAS_SIZE), Color(0.06, 0.12, 0.09))
	var f := ThemeDB.fallback_font
	for i: int in range(_cards.size()):
		var rect := _card_rect(i)
		var card: Dictionary = _cards[i]
		var shown := bool(card["face"]) or bool(card["matched"])
		if not shown:
			draw_rect(rect, Color(0.14, 0.24, 0.46))
			draw_rect(rect.grow(-4), Color(0.76, 0.60, 0.24), false, 1.5)
			draw_string(f, Vector2(rect.position.x, rect.position.y + rect.size.y * 0.62), "?", HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 22, Color(0.95, 0.85, 0.45))
		else:
			var sym: Dictionary = SYMBOLS[int(card["id"]) % SYMBOLS.size()]
			var bg := Color(0.18, 0.34, 0.22) if bool(card["matched"]) else Color(0.96, 0.95, 0.90)
			draw_rect(rect, bg)
			draw_rect(rect, sym["col"], false, 2.5 if bool(card["matched"]) else 1.8)
			draw_string(f, Vector2(rect.position.x, rect.position.y + rect.size.y * 0.68), str(sym["lbl"]), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 28, sym["col"])

	MinigameBase.draw_ui_btn(self, BTN_MODE, "Поле %dx%d" % [_cols, _rows], true, Color(0.32, 0.86, 0.96))
