extends MinigameBase

# Casino Blackjack 21 (Блекджек) vs Dealer AI
const RANKS := ["", "", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A"]
const CARD_SZ := Vector2(58, 84)
const BTN_HIT := Rect2(140, 336, 110, 38)
const BTN_STAND := Rect2(265, 336, 110, 38)
const BTN_DOUBLE := Rect2(390, 336, 110, 38)
const BTN_DEAL := Rect2(245, 336, 150, 38)

var _deck: Array[Dictionary] = []
var _chips: int = 1000
var _bet: int = 50
var _p_hand: Array[Dictionary] = []
var _d_hand: Array[Dictionary] = []
var _state: String = "PLAYER" # "PLAYER", "DEALER", "DONE"
var _msg: String = ""
var _dealer_t: float = 0.0


func get_game_title() -> String:
	return "Блекджек 21"


func get_controls_hint() -> String:
	return "ЛКМ або H/Пробіл — Ще | S — Досить | D — Подвоїти | R — новий банк | Esc — вийти"


func reset_game() -> void:
	_chips = 1000; _bet = 50
	_new_deck()
	super.reset_game()
	_deal_round()


func _new_deck() -> void:
	_deck.clear()
	for _shoe in range(2):
		for s in range(4):
			for r in range(2, 15):
				_deck.append({"r": r, "s": s})
	_deck.shuffle()


func _hand_value(hand: Array[Dictionary]) -> int:
	var sum := 0; var aces := 0
	for c in hand:
		var r := int(c["r"])
		if r == 14: aces += 1; sum += 11
		elif r >= 10: sum += 10
		else: sum += r
	while sum > 21 and aces > 0:
		sum -= 10; aces -= 1
	return sum


func _deal_round() -> void:
	if _chips < _bet:
		_chips = 1000
		_msg = "Банкрот! Новий кредит 1000 фішок"
	if _deck.size() < 20:
		_new_deck()
	_chips -= _bet
	_p_hand.clear(); _d_hand.clear()
	_p_hand.append(_deck.pop_back()); _d_hand.append(_deck.pop_back())
	_p_hand.append(_deck.pop_back()); _d_hand.append(_deck.pop_back())
	_state = "PLAYER"
	AudioSfx.play_tetris_move()

	if _hand_value(_p_hand) == 21:
		_chips += int(_bet * 2.5)
		add_score(150)
		_state = "DONE"
		_msg = "БЛЕКДЖЕК! Ви виграли +%d!" % int(_bet * 1.5)
		AudioSfx.play_fanfare()
	else:
		_msg = "Ваш хід: Ще чи Досить?"
	status_changed.emit("Фішки: %d  |  Ставка: %d" % [_chips, _bet])
	queue_redraw()


func _hit() -> void:
	if _state != "PLAYER": return
	_p_hand.append(_deck.pop_back())
	AudioSfx.play_tetris_move()
	var pv := _hand_value(_p_hand)
	if pv > 21:
		_state = "DONE"
		_msg = "ПЕРЕБІР (%d)! Дилер виграв" % pv
		AudioSfx.play_hit()
	elif pv == 21:
		_stand()
		return
	queue_redraw()


func _stand() -> void:
	if _state != "PLAYER": return
	_state = "DEALER"
	_dealer_t = 0.42
	_msg = "Хід дилера..."
	queue_redraw()


func _double_down() -> void:
	if _state != "PLAYER" or _p_hand.size() != 2 or _chips < _bet: return
	_chips -= _bet
	_bet *= 2
	_p_hand.append(_deck.pop_back())
	AudioSfx.play_coin()
	if _hand_value(_p_hand) > 21:
		_state = "DONE"
		_msg = "ПЕРЕБІР ПІСЛЯ ПОДВОЄННЯ!"
		_bet /= 2
		AudioSfx.play_hit()
	else:
		_stand()
		_bet = maxi(50, _bet / 2)
	queue_redraw()


func on_key_pressed(phys_key: int) -> void:
	if _state == "DONE":
		if is_action_key(phys_key): _deal_round()
		return
	if phys_key == KEY_H or is_action_key(phys_key): _hit()
	elif phys_key == KEY_S: _stand()
	elif phys_key == KEY_D: _double_down()


func step_game(delta: float) -> void:
	if _state == "DEALER":
		_dealer_t -= delta
		if _dealer_t <= 0.0:
			var dv := _hand_value(_d_hand)
			if dv < 17:
				_d_hand.append(_deck.pop_back())
				AudioSfx.play_tetris_move()
				_dealer_t = 0.45
			else:
				var pv := _hand_value(_p_hand)
				_state = "DONE"
				if dv > 21 or pv > dv:
					_chips += _bet * 2
					add_score(_bet)
					_msg = "ПЕРЕМОГА! (%d проти %d)" % [pv, dv]
					AudioSfx.play_fanfare()
				elif pv == dv:
					_chips += _bet
					_msg = "РІВНО (%d:%d) — ставка повернена" % [pv, dv]
					AudioSfx.play_ui_click()
				else:
					_msg = "Дилер виграв (%d проти %d)" % [dv, pv]
					AudioSfx.play_hit()
				status_changed.emit("Фішки: %d  |  Ставка: %d" % [_chips, _bet])
			queue_redraw()


func on_mouse_click(pos: Vector2) -> void:
	if _state == "PLAYER":
		if BTN_HIT.has_point(pos): _hit()
		elif BTN_STAND.has_point(pos): _stand()
		elif BTN_DOUBLE.has_point(pos): _double_down()
	elif _state == "DONE":
		if BTN_DEAL.has_point(pos): _deal_round()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, CANVAS_SIZE), Color(0.04, 0.22, 0.13))
	draw_arc(Vector2(320, 40), 270.0, 0.25, PI - 0.25, 48, Color(0.86, 0.70, 0.28, 0.55), 2.5)
	var f := ThemeDB.fallback_font
	draw_string(f, Vector2(120, 198), "BLACKJACK PAYS 3:2  •  DEALER STANDS ON 17", HORIZONTAL_ALIGNMENT_CENTER, 400, 12, Color(0.85, 0.75, 0.42, 0.75))

	# Dealer Hand
	var dx := 320.0 - float(_d_hand.size()) * 32.0
	for i in range(_d_hand.size()):
		var show := (i == 0 or _state != "PLAYER")
		var c: Dictionary = _d_hand[i]
		draw_playing_card(self, Vector2(dx + float(i) * 64.0, 26), CARD_SZ, RANKS[int(c["r"])], int(c["s"]), show)
	var dv_txt := "?" if _state == "PLAYER" else str(_hand_value(_d_hand))
	draw_string(f, Vector2(20, 68), "Дилер: %s" % dv_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.95, 0.88, 0.75))

	# Player Hand
	var px := 320.0 - float(_p_hand.size()) * 32.0
	for i in range(_p_hand.size()):
		var c: Dictionary = _p_hand[i]
		draw_playing_card(self, Vector2(px + float(i) * 64.0, 214), CARD_SZ, RANKS[int(c["r"])], int(c["s"]), true)
	draw_string(f, Vector2(20, 260), "Ви: %d" % _hand_value(_p_hand), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.98, 0.94, 0.72))
	draw_string(f, Vector2(20, 290), "Банк: %d" % _chips, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.45, 0.95, 0.58))

	draw_string(f, Vector2(100, 158), _msg, HORIZONTAL_ALIGNMENT_CENTER, 440, 17, Color(1.0, 0.94, 0.65))

	if _state == "PLAYER":
		draw_ui_btn(self, BTN_HIT, "Ще (H)", true)
		draw_ui_btn(self, BTN_STAND, "Досить (S)", true)
		draw_ui_btn(self, BTN_DOUBLE, "Подвоїти (D)", _p_hand.size() == 2 and _chips >= _bet)
	elif _state == "DONE":
		draw_ui_btn(self, BTN_DEAL, "Нова роздача", true)
