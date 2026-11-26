extends MinigameBase

# Heads-Up No-Limit Texas Hold'em Poker vs AI with 7-card best-5 Evaluator
const RANKS := ["", "", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A"]
const HAND_NAMES := ["Старша карта", "Пара", "Дві пари", "Трійка", "Стріт", "Флеш", "Фул-хаус", "Каре", "Стріт-флеш"]
const CARD_SZ := Vector2(54, 78)

const BTN_CHECK_CALL := Rect2(80, 342, 130, 36)
const BTN_RAISE := Rect2(225, 342, 130, 36)
const BTN_FOLD := Rect2(370, 342, 100, 36)
const BTN_NEXT := Rect2(235, 342, 170, 36)

var _deck: Array[Dictionary] = []
var _p_cards: Array[Dictionary] = []
var _ai_cards: Array[Dictionary] = []
var _board_cards: Array[Dictionary] = []
var _p_chips: int = 1000
var _ai_chips: int = 1000
var _pot: int = 0
var _street: int = 0 # 0=Preflop, 1=Flop, 2=Turn, 3=River, 4=Showdown
var _msg: String = ""
var _reveal_ai: bool = false


func get_game_title() -> String:
	return "Техаський Покер (проти ШІ)"


func get_controls_hint() -> String:
	return "ЛКМ — Чек/Кол, Рейз +40, Фолд | R — перезапуск | Esc — вийти"


func reset_game() -> void:
	_p_chips = 1000; _ai_chips = 1000
	super.reset_game()
	_deal_hand()


func _deal_hand() -> void:
	if _p_chips <= 0: _p_chips = 1000
	if _ai_chips <= 0: _ai_chips = 1000
	_deck.clear()
	for s in range(4):
		for r in range(2, 15):
			_deck.append({"r": r, "s": s})
	_deck.shuffle()
	_p_cards = [_deck.pop_back(), _deck.pop_back()]
	_ai_cards = [_deck.pop_back(), _deck.pop_back()]
	_board_cards.clear()
	_pot = 40
	_p_chips -= 20; _ai_chips -= 20
	_street = 0; _reveal_ai = false
	_msg = "Префлоп: Чек, Рейз або Фолд?"
	AudioSfx.play_tetris_move()
	status_changed.emit("Ваші фішки: %d  |  Банк: %d" % [_p_chips, _pot])
	queue_redraw()


func _score_5(five: Array[Dictionary]) -> int:
	var rs: Array[int] = []
	var ss: Array[int] = []
	var counts: Dictionary = {}
	for c in five:
		var r := int(c["r"]); var s := int(c["s"])
		rs.append(r); ss.append(s)
		counts[r] = int(counts.get(r, 0)) + 1
	rs.sort(); rs.reverse()

	var is_flush := ss[0] == ss[1] and ss[1] == ss[2] and ss[2] == ss[3] and ss[3] == ss[4]
	var is_straight := (rs[0] - rs[4] == 4 and counts.size() == 5) or (rs == [14, 5, 4, 3, 2])
	var hi_str := 5 if rs == [14, 5, 4, 3, 2] else rs[0]

	var groups: Array[Vector2i] = []
	for k in counts.keys():
		groups.append(Vector2i(int(counts[k]), int(k)))
	groups.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return a.x > b.x if a.x != b.x else a.y > b.y
	)

	var cat := 0
	if is_straight and is_flush: cat = 8
	elif groups[0].x == 4: cat = 7
	elif groups[0].x == 3 and groups.size() > 1 and groups[1].x == 2: cat = 6
	elif is_flush: cat = 5
	elif is_straight: cat = 4
	elif groups[0].x == 3: cat = 3
	elif groups[0].x == 2 and groups.size() > 1 and groups[1].x == 2: cat = 2
	elif groups[0].x == 2: cat = 1

	var tie := hi_str if is_straight else (groups[0].y * 15 + (groups[1].y if groups.size() > 1 else 0))
	return cat * 10000 + tie * 20 + rs[0]


func _best_hand(hole: Array[Dictionary], board: Array[Dictionary]) -> int:
	var all: Array[Dictionary] = []
	all.append_array(hole); all.append_array(board)
	if all.size() < 5:
		return maxi(int(hole[0]["r"]), int(hole[1]["r"]))
	var best := 0
	var n := all.size()
	for a in range(n - 4):
		for b in range(a + 1, n - 3):
			for c in range(b + 1, n - 2):
				for d in range(c + 1, n - 1):
					for e in range(d + 1, n):
						var s := _score_5([all[a], all[b], all[c], all[d], all[e]])
						if s > best: best = s
	return best


func _advance_street(raise_amt: int) -> void:
	if raise_amt > 0:
		var pay := mini(raise_amt, mini(_p_chips, _ai_chips))
		_p_chips -= pay; _ai_chips -= pay; _pot += pay * 2
		AudioSfx.play_coin()

	if _street == 0:
		for _i in range(3): _board_cards.append(_deck.pop_back())
		_street = 1; _msg = "Флоп — ваш хід!"
	elif _street == 1:
		_board_cards.append(_deck.pop_back())
		_street = 2; _msg = "Терн — ваш хід!"
	elif _street == 2:
		_board_cards.append(_deck.pop_back())
		_street = 3; _msg = "Рівер — останній торг!"
	elif _street == 3:
		_street = 4; _reveal_ai = true
		var ps := _best_hand(_p_cards, _board_cards)
		var ais := _best_hand(_ai_cards, _board_cards)
		var pname: String = HAND_NAMES[ps / 10000]
		var ainame: String = HAND_NAMES[ais / 10000]
		if ps > ais:
			_p_chips += _pot; add_score(_pot); AudioSfx.play_fanfare()
			_msg = "ВИГРАШ (%s > %s) +%d!" % [pname, ainame, _pot]
		elif ais > ps:
			_ai_chips += _pot; AudioSfx.play_hit()
			_msg = "ШІ ВИГРАВ (%s > %s)" % [ainame, pname]
		else:
			_p_chips += _pot / 2; _ai_chips += _pot / 2; AudioSfx.play_ui_click()
			_msg = "ДІЛЕННЯ БАНКУ (%s)" % pname
	AudioSfx.play_tetris_move()
	status_changed.emit("Фішки: %d | ШІ: %d | Банк: %d" % [_p_chips, _ai_chips, _pot])
	queue_redraw()


func on_mouse_click(pos: Vector2) -> void:
	if _street == 4:
		if BTN_NEXT.has_point(pos): _deal_hand()
		return
	if BTN_CHECK_CALL.has_point(pos):
		_advance_street(0)
	elif BTN_RAISE.has_point(pos):
		_advance_street(40)
	elif BTN_FOLD.has_point(pos):
		_ai_chips += _pot; _street = 4; _reveal_ai = true
		_msg = "Ви скинули карти (Фолд)"
		AudioSfx.play_hit()
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, CANVAS_SIZE), Color(0.05, 0.20, 0.16))
	draw_rect(Rect2(20, 18, 600, 364), Color(0.75, 0.60, 0.25, 0.45), false, 2.0)
	var f := ThemeDB.fallback_font

	# AI Hand
	for i in range(_ai_cards.size()):
		var c: Dictionary = _ai_cards[i]
		draw_playing_card(self, Vector2(262 + float(i) * 60, 26), CARD_SZ, RANKS[int(c["r"])], int(c["s"]), _reveal_ai)
	draw_string(f, Vector2(36, 62), "ШІ банк: %d" % _ai_chips, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.92, 0.85, 0.72))
	draw_string(f, Vector2(465, 62), "БАНК: %d" % _pot, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.98, 0.85, 0.30))

	# Community 5-Card Board
	for i in range(5):
		var bx := 162.0 + float(i) * 64.0
		if i < _board_cards.size():
			var c: Dictionary = _board_cards[i]
			draw_playing_card(self, Vector2(bx, 134), CARD_SZ, RANKS[int(c["r"])], int(c["s"]), true)
		else:
			draw_rect(Rect2(bx, 134, CARD_SZ.x, CARD_SZ.y), Color(0.04, 0.14, 0.10), false, 1.5)

	# Player Hand
	for i in range(_p_cards.size()):
		var c: Dictionary = _p_cards[i]
		draw_playing_card(self, Vector2(262 + float(i) * 60, 248), CARD_SZ, RANKS[int(c["r"])], int(c["s"]), true)
	draw_string(f, Vector2(36, 286), "Ваші фішки: %d" % _p_chips, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.45, 0.96, 0.58))
	draw_string(f, Vector2(120, 232), _msg, HORIZONTAL_ALIGNMENT_CENTER, 400, 15, Color(1.0, 0.94, 0.68))

	if _street < 4:
		draw_ui_btn(self, BTN_CHECK_CALL, "Чек / Далі", true)
		draw_ui_btn(self, BTN_RAISE, "Рейз +40", _p_chips >= 40 and _ai_chips >= 40)
		draw_ui_btn(self, BTN_FOLD, "Фолд", true, Color(0.90, 0.35, 0.30))
	else:
		draw_ui_btn(self, BTN_NEXT, "Наступна роздача", true)
