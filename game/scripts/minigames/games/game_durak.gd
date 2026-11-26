extends MinigameBase

# Classic 36-Card Podkidnoy Durak (Підкидний Дурак) vs Smart AI
const CARD_SZ := Vector2(56, 82)
const RANKS := ["", "", "", "", "", "", "6", "7", "8", "9", "10", "В", "Д", "К", "Т"]
const BTN_ACTION := Rect2(495, 290, 125, 40)

var _deck: Array[Dictionary] = []
var _trump_suit: int = 0
var _p_hand: Array[Dictionary] = []
var _ai_hand: Array[Dictionary] = []
var _table: Array[Dictionary] = [] # [{"atk": card, "def": card_or_null}]
var _attacker: int = 1 # 1=Player, -1=AI
var _turn_owner: int = 1 # Who acts right now
var _ai_timer: float = 0.0
var _msg: String = ""
var _banner: String = ""


func get_game_title() -> String:
	return "Дурак (36 карт проти ШІ)"


func get_controls_hint() -> String:
	return "ЛКМ по карті — хід / підкинути / відбити | Кнопка справа — Бито / Взяти | R — нова гра"


func reset_game() -> void:
	_deck.clear()
	for s in range(4):
		for r in range(6, 15):
			_deck.append({"r": r, "s": s})
	_deck.shuffle()
	_trump_suit = int(_deck[0]["s"])
	_p_hand.clear(); _ai_hand.clear(); _table.clear()
	for _i in range(6):
		_p_hand.append(_deck.pop_back())
		_ai_hand.append(_deck.pop_back())
	_sort_hand(_p_hand); _sort_hand(_ai_hand)
	_attacker = 1; _turn_owner = 1; _ai_timer = 0.0; _banner = ""
	_msg = "Ваш хід — атакуйте!"
	super.reset_game()
	status_changed.emit(_msg)


func _sort_hand(hand: Array[Dictionary]) -> void:
	hand.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var at := 1 if int(a["s"]) == _trump_suit else 0
		var bt := 1 if int(b["s"]) == _trump_suit else 0
		if at != bt: return at < bt
		return int(a["r"]) < int(b["r"])
	)


func _can_beat(atk: Dictionary, def_c: Dictionary) -> bool:
	var sa := int(atk["s"]); var ra := int(atk["r"])
	var sd := int(def_c["s"]); var rd := int(def_c["r"])
	if sd == sa and rd > ra:
		return true
	if sd == _trump_suit and sa != _trump_suit:
		return true
	return false


func _table_ranks() -> Array[int]:
	var ranks: Array[int] = []
	for p: Dictionary in _table:
		var ar := int((p["atk"] as Dictionary)["r"])
		if not ranks.has(ar): ranks.append(ar)
		if p["def"] != null:
			var dr := int((p["def"] as Dictionary)["r"])
			if not ranks.has(dr): ranks.append(dr)
	return ranks


func _all_defended() -> bool:
	for p: Dictionary in _table:
		if p["def"] == null:
			return false
	return true


func _end_bout(defender_took: bool) -> void:
	var defender := -_attacker
	if defender_took:
		var target_h := _p_hand if defender == 1 else _ai_hand
		for p: Dictionary in _table:
			target_h.append(p["atk"])
			if p["def"] != null: target_h.append(p["def"])
	_table.clear()

	# Refill hands to 6 (attacker draws first!)
	var first_h := _p_hand if _attacker == 1 else _ai_hand
	var sec_h := _ai_hand if _attacker == 1 else _p_hand
	while first_h.size() < 6 and not _deck.is_empty():
		first_h.append(_deck.pop_back())
	while sec_h.size() < 6 and not _deck.is_empty():
		sec_h.append(_deck.pop_back())
	_sort_hand(_p_hand); _sort_hand(_ai_hand)

	if _p_hand.is_empty() and _ai_hand.is_empty() and _deck.is_empty():
		game_over = true; _banner = "НІЧИЯ!"; add_score(150); AudioSfx.play_goal()
		status_changed.emit(_banner); queue_redraw(); return
	elif _p_hand.is_empty() and _deck.is_empty():
		game_over = true; _banner = "ВИ ПЕРЕМОГЛИ!"; add_score(400); AudioSfx.play_fanfare()
		status_changed.emit(_banner); queue_redraw(); return
	elif _ai_hand.is_empty() and _deck.is_empty():
		game_over = true; _banner = "ШІ ПЕРЕМІГ — ВИ ДУРАК!"; AudioSfx.play_hit()
		status_changed.emit(_banner); queue_redraw(); return

	if not defender_took:
		_attacker = -_attacker
	_turn_owner = _attacker
	if _turn_owner == -1:
		_ai_timer = 0.40
		_msg = "Атакує комп'ютер..."
	else:
		_msg = "Ваш хід — атакуйте!"
	status_changed.emit(_msg)
	queue_redraw()


func _pick_ai_defense(atk: Dictionary) -> int:
	var best_i := -1; var best_val := 999
	for i in range(_ai_hand.size()):
		if _can_beat(atk, _ai_hand[i]):
			var v := int(_ai_hand[i]["r"]) + (20 if int(_ai_hand[i]["s"]) == _trump_suit else 0)
			if v < best_val:
				best_val = v; best_i = i
	return best_i


func _ai_step() -> void:
	if _attacker == -1:
		# AI attacking or throwing in
		if _table.is_empty():
			var c: Dictionary = _ai_hand[0]
			_ai_hand.remove_at(0)
			_table.append({"atk": c, "def": null})
			AudioSfx.play_tetris_move()
			_turn_owner = 1
			_msg = "Відбийтеся або натисніть Взяти!"
		elif _all_defended():
			var tr := _table_ranks()
			var max_cards := mini(6, _table.size() + _p_hand.size())
			var threw := false
			if _table.size() < max_cards and _p_hand.size() > 0:
				for i in range(_ai_hand.size()):
					if tr.has(int(_ai_hand[i]["r"])) and (int(_ai_hand[i]["s"]) != _trump_suit or _deck.size() < 4):
						var tc: Dictionary = _ai_hand[i]
						_ai_hand.remove_at(i)
						_table.append({"atk": tc, "def": null})
						AudioSfx.play_tetris_move()
						_turn_owner = 1
						_msg = "ШІ підкинув карту!"
						threw = true; break
			if not threw:
				_msg = "Бито!"
				AudioSfx.play_ui_click()
				_end_bout(false)
				return
		status_changed.emit(_msg)
		queue_redraw()
	else:
		# AI defending against player's unbeaten attack(s)
		var open_idx := -1
		for i in range(_table.size()):
			if _table[i]["def"] == null:
				open_idx = i; break
		if open_idx >= 0:
			var di := _pick_ai_defense(_table[open_idx]["atk"])
			if di >= 0:
				_table[open_idx]["def"] = _ai_hand[di]
				_ai_hand.remove_at(di)
				add_score(10)
				AudioSfx.play_tetris_move()
				_turn_owner = 1
				_msg = "ШІ відбився — підкиньте або тисніть Бито"
			else:
				_msg = "ШІ забирає карти!"
				AudioSfx.play_hit()
				_end_bout(true)
				return
		status_changed.emit(_msg)
		queue_redraw()


func step_game(delta: float) -> void:
	if game_over: return
	if _turn_owner == -1:
		_ai_timer -= delta
		if _ai_timer <= 0.0:
			_ai_step()


func on_mouse_click(pos: Vector2) -> void:
	if game_over or _turn_owner != 1:
		return
	if not _table.is_empty() and BTN_ACTION.has_point(pos):
		if _attacker == 1 and _all_defended():
			add_score(25); AudioSfx.play_ui_click()
			_end_bout(false)
			return
		elif _attacker == -1 and not _all_defended():
			AudioSfx.play_hit()
			_end_bout(true)
			return

	# Check click on player's hand cards
	var n := _p_hand.size()
	if n == 0: return
	var total_w := minf(float(n) * 62.0, 560.0)
	var start_x := (CANVAS_SIZE.x - total_w) * 0.5
	var step_x := (total_w - CARD_SZ.x) / maxf(float(n - 1), 1.0) if n > 1 else 0.0

	for i in range(n - 1, -1, -1):
		var cp := Vector2(start_x + float(i) * step_x, 302.0)
		if Rect2(cp, CARD_SZ).has_point(pos):
			var c: Dictionary = _p_hand[i]
			if _attacker == 1:
				if _table.is_empty() or (_table_ranks().has(int(c["r"])) and _table.size() < 6 and _ai_hand.size() > 0):
					if not _all_defended(): return
					_p_hand.remove_at(i)
					_table.append({"atk": c, "def": null})
					AudioSfx.play_tetris_move()
					_turn_owner = -1; _ai_timer = 0.36
					_msg = "ШІ думає..."
					queue_redraw()
			else:
				for p: Dictionary in _table:
					if p["def"] == null and _can_beat(p["atk"], c):
						p["def"] = c
						_p_hand.remove_at(i)
						add_score(20)
						AudioSfx.play_tetris_move()
						if _all_defended():
							_turn_owner = -1; _ai_timer = 0.38
							_msg = "Відбито!"
						queue_redraw()
						return
			return


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, CANVAS_SIZE), Color(0.05, 0.24, 0.13))
	draw_rect(Rect2(12, 12, CANVAS_SIZE.x - 24, CANVAS_SIZE.y - 24), Color(0.75, 0.60, 0.25, 0.45), false, 2.0)
	var f := ThemeDB.fallback_font

	# AI Hand (top face-down)
	var ai_n := _ai_hand.size()
	for i in range(ai_n):
		draw_playing_card(self, Vector2(180 + float(i) * 38.0, 20), Vector2(48, 68), "", 0, false)
	draw_string(f, Vector2(26, 52), "Суперник: %d" % ai_n, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.92, 0.90, 0.80))

	# Deck & visible Trump card on the left
	if not _deck.is_empty():
		var tc: Dictionary = _deck[0]
		draw_playing_card(self, Vector2(36, 152), Vector2(68, 48), RANKS[int(tc["r"])], int(tc["s"]), true)
		if _deck.size() > 1:
			draw_playing_card(self, Vector2(22, 134), Vector2(50, 72), "", 0, false)
		draw_string(f, Vector2(24, 224), "Колода: %d" % _deck.size(), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.88, 0.94, 0.88))
	else:
		draw_string(f, Vector2(28, 175), "КОЗИР:", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.95, 0.85, 0.35))
		draw_suit_pip(self, Vector2(46, 196), _trump_suit, 14.0, Color(0.88, 0.18, 0.18) if _trump_suit in [1,2] else Color(0.95, 0.95, 0.95))

	# Table pairs cleanly centered
	for i in range(_table.size()):
		var p: Dictionary = _table[i]
		var tx := 136.0 + float(i) * 70.0
		var atk: Dictionary = p["atk"]
		draw_playing_card(self, Vector2(tx, 132), CARD_SZ, RANKS[int(atk["r"])], int(atk["s"]), true)
		if p["def"] != null:
			var df: Dictionary = p["def"]
			draw_playing_card(self, Vector2(tx + 12, 154), CARD_SZ, RANKS[int(df["r"])], int(df["s"]), true)

	# Player Hand
	var n := _p_hand.size()
	if n > 0:
		var total_w := minf(float(n) * 62.0, 560.0)
		var start_x := (CANVAS_SIZE.x - total_w) * 0.5
		var step_x := (total_w - CARD_SZ.x) / maxf(float(n - 1), 1.0) if n > 1 else 0.0
		for i in range(n):
			var c: Dictionary = _p_hand[i]
			var hi := _attacker == 1 and (_table.is_empty() or _table_ranks().has(int(c["r"])))
			draw_playing_card(self, Vector2(start_x + float(i) * step_x, 302.0), CARD_SZ, RANKS[int(c["r"])], int(c["s"]), true, hi)

	if not _table.is_empty() and _turn_owner == 1 and not game_over:
		var lbl := "Бито" if (_attacker == 1 and _all_defended()) else ("Взяти" if (_attacker == -1 and not _all_defended()) else "")
		if lbl != "":
			draw_ui_btn(self, BTN_ACTION, lbl, true)

	draw_string(f, Vector2(120, 114), _msg, HORIZONTAL_ALIGNMENT_CENTER, 380, 14, Color(1.0, 0.94, 0.72))
	draw_game_over_banner(_banner + " — [R] Знову")
