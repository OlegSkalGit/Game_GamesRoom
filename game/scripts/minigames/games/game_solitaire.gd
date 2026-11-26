extends MinigameBase

const RANKS := ["", "A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"]
const CARD_SZ := Vector2(62.0, 88.0)

var _stock: Array[Dictionary] = []
var _waste: Array[Dictionary] = []
var _foundations: Array = [[], [], [], []]
var _tableau: Array = [[], [], [], [], [], [], []]
var _sel_kind: String = "" # "waste", "tab", "found"
var _sel_idx: int = -1
var _sel_card_i: int = -1
var _won: bool = false


func get_game_title() -> String:
	return "Косинка"


func get_controls_hint() -> String:
	return "ЛКМ — колода або перенос карт | ПКМ / Пробіл — авто-збір на базу | R — роздати | Esc — вийти"


func reset_game() -> void:
	_won = false
	_sel_kind = ""
	_stock.clear(); _waste.clear()
	_foundations = [[], [], [], []]
	_tableau = [[], [], [], [], [], [], []]

	var deck: Array[Dictionary] = []
	for s in range(4):
		for r in range(1, 14):
			deck.append({"suit": s, "rank": r, "up": false})
	deck.shuffle()

	for col in range(7):
		for row in range(col + 1):
			var c: Dictionary = deck.pop_back()
			c["up"] = (row == col)
			(_tableau[col] as Array).append(c)
	_stock = deck
	super.reset_game()
	status_changed.emit("Розкладіть масті від Туза до Короля")


func _is_red(suit: int) -> bool:
	return suit == 1 or suit == 2


func _can_stack_tab(card: Dictionary, col: int) -> bool:
	var pile: Array = _tableau[col]
	if pile.is_empty():
		return int(card["rank"]) == 13
	var top: Dictionary = pile[pile.size() - 1]
	return bool(top["up"]) and _is_red(int(card["suit"])) != _is_red(int(top["suit"])) and int(card["rank"]) == int(top["rank"]) - 1


func _can_place_foundation(card: Dictionary, fi: int) -> bool:
	var pile: Array = _foundations[fi]
	if pile.is_empty():
		return int(card["rank"]) == 1
	var top: Dictionary = pile[pile.size() - 1]
	return int(card["suit"]) == int(top["suit"]) and int(card["rank"]) == int(top["rank"]) + 1


func _flip_exposed_tops() -> void:
	for col in range(7):
		var pile: Array = _tableau[col]
		if not pile.is_empty() and not bool(pile[pile.size() - 1]["up"]):
			pile[pile.size() - 1]["up"] = true
			add_score(15)


func _check_win() -> void:
	var total := 0
	for fi in range(4):
		total += (_foundations[fi] as Array).size()
	if total == 52:
		_won = true
		game_over = true
		add_score(500)
		AudioSfx.play_fanfare()
		status_changed.emit("ПАСЬЯНС ЗІБРАНО!")
	else:
		status_changed.emit("На базі: %d / 52  |  Колода: %d" % [total, _stock.size()])


func _try_auto_foundation_from(kind: String, col: int) -> bool:
	var card: Dictionary = {}
	if kind == "waste" and not _waste.is_empty():
		card = _waste[_waste.size() - 1]
	elif kind == "tab" and not (_tableau[col] as Array).is_empty():
		var pile: Array = _tableau[col]
		card = pile[pile.size() - 1]
	else:
		return false
	for fi in range(4):
		if _can_place_foundation(card, fi):
			if kind == "waste":
				(_foundations[fi] as Array).append(_waste.pop_back())
			else:
				(_foundations[fi] as Array).append((_tableau[col] as Array).pop_back())
				_flip_exposed_tops()
			add_score(50)
			AudioSfx.play_puzzle_snap()
			_sel_kind = ""
			_check_win()
			queue_redraw()
			return true
	return false


func _auto_any_step() -> void:
	if _try_auto_foundation_from("waste", 0):
		return
	for col in range(7):
		if _try_auto_foundation_from("tab", col):
			return
	_draw_stock()


func _draw_stock() -> void:
	_sel_kind = ""
	if not _stock.is_empty():
		var c: Dictionary = _stock.pop_back()
		c["up"] = true
		_waste.append(c)
		AudioSfx.play_card_flip()
	elif not _waste.is_empty():
		while not _waste.is_empty():
			var c2: Dictionary = _waste.pop_back()
			c2["up"] = false
			_stock.append(c2)
		AudioSfx.play_switch()
	_check_win()
	queue_redraw()


func _tab_card_pos(col: int, row: int) -> Vector2:
	return Vector2(46.0 + float(col) * 80.0, 134.0 + float(row) * 20.0)


func on_mouse_click(pos: Vector2) -> void:
	if _won:
		return
	# 1. Stock click
	if Rect2(Vector2(46, 20), CARD_SZ).has_point(pos):
		_draw_stock(); return

	# 2. Waste click
	if Rect2(Vector2(126, 20), CARD_SZ).has_point(pos) and not _waste.is_empty():
		if _sel_kind == "waste":
			if not _try_auto_foundation_from("waste", 0):
				_sel_kind = ""
		else:
			_sel_kind = "waste"
			AudioSfx.play_ui_click()
		queue_redraw(); return

	# 3. Foundation click
	for fi in range(4):
		var fr := Rect2(Vector2(286.0 + float(fi) * 80.0, 20.0), CARD_SZ)
		if fr.has_point(pos) and _sel_kind != "":
			if _sel_kind == "waste" and not _waste.is_empty() and _can_place_foundation(_waste[_waste.size() - 1], fi):
				(_foundations[fi] as Array).append(_waste.pop_back()); add_score(50); AudioSfx.play_puzzle_snap()
			elif _sel_kind == "tab":
				var tp: Array = _tableau[_sel_idx]
				if _sel_card_i == tp.size() - 1 and _can_place_foundation(tp[_sel_card_i], fi):
					(_foundations[fi] as Array).append(tp.pop_back()); _flip_exposed_tops(); add_score(50); AudioSfx.play_puzzle_snap()
			_sel_kind = ""; _check_win(); queue_redraw(); return

	# 4. Tableau click (from top card downward!)
	for col in range(7):
		var pile: Array = _tableau[col]
		if pile.is_empty():
			var empty_r := Rect2(_tab_card_pos(col, 0), CARD_SZ)
			if empty_r.has_point(pos) and _sel_kind != "":
				_move_selection_to_tab(col)
				return
			continue
		for row in range(pile.size() - 1, -1, -1):
			var cr := Rect2(_tab_card_pos(col, row), Vector2(CARD_SZ.x, CARD_SZ.y if row == pile.size() - 1 else 20.0))
			if cr.has_point(pos):
				if _sel_kind != "" and (_sel_kind != "tab" or _sel_idx != col):
					if _move_selection_to_tab(col):
						return
				if bool(pile[row]["up"]):
					if _sel_kind == "tab" and _sel_idx == col and _sel_card_i == row and row == pile.size() - 1:
						_try_auto_foundation_from("tab", col)
					else:
						_sel_kind = "tab"; _sel_idx = col; _sel_card_i = row
						AudioSfx.play_ui_click()
						queue_redraw()
				return


func _move_selection_to_tab(dst_col: int) -> bool:
	if _sel_kind == "waste" and not _waste.is_empty():
		var c: Dictionary = _waste[_waste.size() - 1]
		if _can_stack_tab(c, dst_col):
			(_tableau[dst_col] as Array).append(_waste.pop_back())
			_sel_kind = ""; add_score(20); AudioSfx.play_card_flip(); _check_win(); queue_redraw()
			return true
	elif _sel_kind == "tab":
		var src: Array = _tableau[_sel_idx]
		if _sel_card_i >= 0 and _sel_card_i < src.size() and _can_stack_tab(src[_sel_card_i], dst_col):
			while _sel_card_i < src.size():
				(_tableau[dst_col] as Array).append(src.pop_at(_sel_card_i))
			_flip_exposed_tops()
			_sel_kind = ""; add_score(25); AudioSfx.play_card_flip(); _check_win(); queue_redraw()
			return true
	return false


func on_right_click(pos: Vector2) -> void:
	if Rect2(Vector2(126, 20), CARD_SZ).has_point(pos):
		_try_auto_foundation_from("waste", 0); return
	for col in range(7):
		var pile: Array = _tableau[col]
		if not pile.is_empty() and Rect2(_tab_card_pos(col, pile.size() - 1), CARD_SZ).has_point(pos):
			_try_auto_foundation_from("tab", col); return


func on_key_pressed(phys_key: int) -> void:
	if is_action_key(phys_key):
		_auto_any_step()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, CANVAS_SIZE), Color(0.05, 0.24, 0.14))
	draw_rect(Rect2(14, 10, 612, 380), Color(0.84, 0.68, 0.28, 0.55), false, 2.0)

	# Stock & Waste
	if _stock.is_empty():
		draw_rect(Rect2(Vector2(46, 20), CARD_SZ), Color(0.04, 0.16, 0.10))
		draw_rect(Rect2(Vector2(46, 20), CARD_SZ), Color(0.65, 0.72, 0.68, 0.5), false, 1.5)
	else:
		draw_playing_card(self, Vector2(46, 20), CARD_SZ, "", 0, false)
	if not _waste.is_empty():
		var w: Dictionary = _waste[_waste.size() - 1]
		draw_playing_card(self, Vector2(126, 20), CARD_SZ, RANKS[int(w["rank"])], int(w["suit"]), true, _sel_kind == "waste")

	# Foundations
	for fi in range(4):
		var fp := Vector2(286.0 + float(fi) * 80.0, 20.0)
		var pile: Array = _foundations[fi]
		if pile.is_empty():
			draw_rect(Rect2(fp, CARD_SZ), Color(0.04, 0.17, 0.10))
			draw_rect(Rect2(fp, CARD_SZ), Color(0.84, 0.68, 0.28, 0.6), false, 1.6)
			draw_suit_pip(self, fp + CARD_SZ * 0.5, fi, 12.0, Color(0.84, 0.68, 0.28, 0.35))
		else:
			var top: Dictionary = pile[pile.size() - 1]
			draw_playing_card(self, fp, CARD_SZ, RANKS[int(top["rank"])], int(top["suit"]), true)

	# Tableau
	for col in range(7):
		var pile: Array = _tableau[col]
		if pile.is_empty():
			draw_rect(Rect2(_tab_card_pos(col, 0), CARD_SZ), Color(0.04, 0.17, 0.10), false, 1.4)
			continue
		for row in range(pile.size()):
			var c: Dictionary = pile[row]
			var hi := (_sel_kind == "tab" and _sel_idx == col and row >= _sel_card_i)
			draw_playing_card(self, _tab_card_pos(col, row), CARD_SZ, RANKS[int(c["rank"])], int(c["suit"]), bool(c["up"]), hi)

	if _won:
		draw_game_over_banner("ПЕРЕМОГА! ПАСЬЯНС ЗІБРАНО — [R] Ще раз")
