class_name RouletteOverlay
extends CanvasLayer

signal bet_placed(total_bet: int)
signal spin_requested(bets: Dictionary)
signal exit_requested

const EURO_ORDER: Array[int] = [
	0, 32, 15, 19, 4, 21, 2, 25, 17, 34, 6, 27, 13, 36, 11, 30, 8, 23, 10,
	5, 24, 16, 33, 1, 20, 14, 31, 9, 22, 18, 29, 7, 28, 12, 35, 3, 26
]
const RED_NUMS: Array[int] = [1, 3, 5, 7, 9, 12, 14, 16, 18, 19, 21, 23, 25, 27, 30, 32, 34, 36]
const CHIP_VALS: Array[int] = [10, 25, 50, 100]

var _panel: PanelContainer
var _bank_lbl: Label
var _status_lbl: Label
var _hist_lbl: Label
var _chip_val: int = 25
var _chip_btns: Array[Button] = []
var _bet_btns: Dictionary = {}
var _bets: Dictionary = {} # key: String ("n_17", "red", "black", "even", "odd", "low", "high", "d1", "d2", "d3") -> int amount
var _last_bets: Dictionary = {}
var _spin_btn: Button
var _clear_btn: Button
var _rebet_btn: Button
var _exit_btn: Button
var _spinning: bool = false
var _chips_ref: int = 0
var _history: Array[int] = []


static func is_red(n: int) -> bool:
	return n in RED_NUMS


static func pocket_color_tag(n: int) -> String:
	if n == 0:
		return "🟢 0 ЗЕРО"
	return ("🔴 %d Червоне" if is_red(n) else "⚫ %d Чорне") % n


static func compute_payout(bets: Dictionary, win_n: int) -> int:
	var won := 0
	var red := is_red(win_n)
	for bk in bets.keys():
		var amt := int(bets[bk])
		var key := str(bk)
		if key.begins_with("n_"):
			if int(key.substr(2)) == win_n:
				won += amt * 36
		elif win_n > 0:
			match key:
				"red":
					if red: won += amt * 2
				"black":
					if not red: won += amt * 2
				"even":
					if win_n % 2 == 0: won += amt * 2
				"odd":
					if win_n % 2 == 1: won += amt * 2
				"low":
					if win_n <= 18: won += amt * 2
				"high":
					if win_n >= 19: won += amt * 2
				"d1":
					if win_n <= 12: won += amt * 3
				"d2":
					if win_n >= 13 and win_n <= 24: won += amt * 3
				"d3":
					if win_n >= 25: won += amt * 3
	return won


func _ready() -> void:
	layer = 35
	visible = false
	_build_ui()


func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(root)

	# Top compact status header (leaves center of screen open so 3D wheel & ivory ball are in full view!)
	var top_bar := PanelContainer.new()
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bar.offset_left = 180; top_bar.offset_right = -180
	top_bar.offset_top = 12; top_bar.offset_bottom = 68
	var tsb := StyleBoxFlat.new()
	tsb.bg_color = Color(0.05, 0.08, 0.07, 0.88)
	tsb.border_color = Color(0.88, 0.72, 0.30)
	tsb.set_border_width_all(2); tsb.set_corner_radius_all(8)
	top_bar.add_theme_stylebox_override("panel", tsb)
	root.add_child(top_bar)

	var tv := VBoxContainer.new()
	top_bar.add_child(tv)
	_bank_lbl = Label.new()
	_bank_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bank_lbl.add_theme_font_size_override("font_size", 18)
	_bank_lbl.add_theme_color_override("font_color", Color(0.98, 0.86, 0.40))
	tv.add_child(_bank_lbl)
	_status_lbl = Label.new()
	_status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_lbl.add_theme_font_size_override("font_size", 15)
	_status_lbl.add_theme_color_override("font_color", Color(0.90, 0.96, 0.92))
	tv.add_child(_status_lbl)

	# Bottom compact European Roulette Betting Cloth
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_panel.offset_left = 80; _panel.offset_right = -80
	_panel.offset_top = -238; _panel.offset_bottom = -12
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.14, 0.09, 0.92)
	sb.border_color = Color(0.86, 0.68, 0.28)
	sb.set_border_width_all(2); sb.set_corner_radius_all(10)
	sb.content_margin_left = 12; sb.content_margin_right = 12
	sb.content_margin_top = 10; sb.content_margin_bottom = 10
	_panel.add_theme_stylebox_override("panel", sb)
	root.add_child(_panel)

	var main_v := VBoxContainer.new()
	main_v.add_theme_constant_override("separation", 6)
	_panel.add_child(main_v)

	# Controls + chips row
	var ctrl_h := HBoxContainer.new()
	ctrl_h.add_theme_constant_override("separation", 8)
	main_v.add_child(ctrl_h)

	var chip_lbl := Label.new(); chip_lbl.text = "Фішка:"
	chip_lbl.add_theme_font_size_override("font_size", 14)
	ctrl_h.add_child(chip_lbl)
	for cv in CHIP_VALS:
		var cb := Button.new(); cb.text = str(cv)
		cb.pressed.connect(func():
			AudioSfx.play_ui_click()
			_chip_val = cv
			_refresh_texts()
		)
		ctrl_h.add_child(cb)
		_chip_btns.append(cb)

	_hist_lbl = Label.new()
	_hist_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hist_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hist_lbl.add_theme_font_size_override("font_size", 13)
	_hist_lbl.add_theme_color_override("font_color", Color(0.84, 0.90, 0.86))
	ctrl_h.add_child(_hist_lbl)

	_rebet_btn = Button.new(); _rebet_btn.text = "Повтор"
	_rebet_btn.pressed.connect(_on_rebet)
	ctrl_h.add_child(_rebet_btn)

	_clear_btn = Button.new(); _clear_btn.text = "Очистити"
	_clear_btn.pressed.connect(_on_clear)
	ctrl_h.add_child(_clear_btn)

	_spin_btn = Button.new(); _spin_btn.text = "КРУТИТИ [Пробіл]"
	_spin_btn.pressed.connect(_on_spin)
	ctrl_h.add_child(_spin_btn)

	_exit_btn = Button.new(); _exit_btn.text = "Встати [Esc]"
	_exit_btn.pressed.connect(func():
		AudioSfx.play_ui_click()
		exit_requested.emit()
	)
	ctrl_h.add_child(_exit_btn)

	# Number Grid: 0 + 3x12 (row 0: 3,6..36; row 1: 2,5..35; row 2: 1,4..34)
	var grid_h := HBoxContainer.new()
	grid_h.add_theme_constant_override("separation", 4)
	main_v.add_child(grid_h)

	var z_btn := _make_bet_btn("n_0", "0", Color(0.08, 0.50, 0.24))
	z_btn.custom_minimum_size = Vector2(56, 84)
	grid_h.add_child(z_btn)

	var num_grid := GridContainer.new()
	num_grid.columns = 12
	num_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	num_grid.add_theme_constant_override("h_separation", 3)
	num_grid.add_theme_constant_override("v_separation", 3)
	grid_h.add_child(num_grid)
	for r_off: int in [3, 2, 1]:
		for col in range(12):
			var n: int = col * 3 + r_off
			var bg := Color(0.64, 0.12, 0.14) if is_red(n) else Color(0.11, 0.12, 0.15)
			var b := _make_bet_btn("n_%d" % n, str(n), bg)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.custom_minimum_size = Vector2(0, 26)
			num_grid.add_child(b)

	# Outside Bets row: Dozens + Even-money
	var out_h := HBoxContainer.new()
	out_h.add_theme_constant_override("separation", 4)
	main_v.add_child(out_h)
	for spec in [
		["d1", "1-12 (×3)", Color(0.12, 0.26, 0.19)],
		["d2", "13-24 (×3)", Color(0.12, 0.26, 0.19)],
		["d3", "25-36 (×3)", Color(0.12, 0.26, 0.19)],
		["low", "1-18", Color(0.14, 0.22, 0.28)],
		["even", "ПАРНІ", Color(0.14, 0.22, 0.28)],
		["red", "ЧЕРВОНЕ", Color(0.66, 0.13, 0.15)],
		["black", "ЧОРНЕ", Color(0.12, 0.13, 0.16)],
		["odd", "НЕПАРНІ", Color(0.14, 0.22, 0.28)],
		["high", "19-36", Color(0.14, 0.22, 0.28)]
	]:
		var b := _make_bet_btn(str(spec[0]), str(spec[1]), spec[2] as Color)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 32)
		out_h.add_child(b)


func _make_bet_btn(key: String, label: String, base_col: Color) -> Button:
	var b := Button.new()
	b.text = label
	b.add_theme_font_size_override("font_size", 12)
	var sb := StyleBoxFlat.new()
	sb.bg_color = base_col
	sb.border_color = Color(0.75, 0.62, 0.28, 0.65)
	sb.set_border_width_all(1); sb.set_corner_radius_all(4)
	b.add_theme_stylebox_override("normal", sb)
	b.set_meta("base_label", label)
	b.pressed.connect(func(): _place_bet(key))
	_bet_btns[key] = b
	return b


func open(chips_balance: int) -> void:
	_chips_ref = chips_balance
	_spinning = false
	_bets.clear()
	_status_lbl.text = "Оберіть номінал фішки і натисніть на поля столу, потім КРУТИТИ!"
	visible = true
	_refresh_texts()


func close_overlay() -> void:
	visible = false


func total_bet() -> int:
	var sum := 0
	for k in _bets.keys():
		sum += int(_bets[k])
	return sum


func _place_bet(key: String) -> void:
	if _spinning:
		return
	var avail := _chips_ref - total_bet()
	if avail <= 0:
		AudioSfx.play_brick_bump()
		_status_lbl.text = "Недостатньо фішок для нової ставки!"
		return
	var add := mini(_chip_val, avail)
	_bets[key] = int(_bets.get(key, 0)) + add
	AudioSfx.play_ui_click()
	_refresh_texts()
	bet_placed.emit(total_bet())


func _on_clear() -> void:
	if _spinning:
		return
	_bets.clear()
	AudioSfx.play_ui_click()
	_refresh_texts()
	bet_placed.emit(0)


func _on_rebet() -> void:
	if _spinning or _last_bets.is_empty():
		return
	_bets.clear()
	var needed := 0
	for k in _last_bets.keys():
		needed += int(_last_bets[k])
	if needed > _chips_ref:
		_status_lbl.text = "Замало фішок для повтору минулої ставки!"
		AudioSfx.play_brick_bump()
		return
	_bets = _last_bets.duplicate()
	AudioSfx.play_ui_click()
	_refresh_texts()
	bet_placed.emit(total_bet())


func _on_spin() -> void:
	if _spinning:
		return
	if _bets.is_empty():
		AudioSfx.play_brick_bump()
		_status_lbl.text = "Спочатку поставте хоча б одну ставку на сукно!"
		return
	_spinning = true
	_last_bets = _bets.duplicate()
	_status_lbl.text = "Кулька побігла по ободу 3D-рулетки... Ставки прийнято!"
	_refresh_texts()
	spin_requested.emit(_bets.duplicate())


func on_spin_result(win_n: int, payout: int, new_balance: int) -> void:
	_spinning = false
	_chips_ref = new_balance
	var staked := total_bet()
	_history.push_front(win_n)
	if _history.size() > 8:
		_history.pop_back()
	var tag := pocket_color_tag(win_n)
	if payout > 0:
		_status_lbl.text = "Випало %s! ВИГРАШ +%d фішок (ставка %d)" % [tag, payout, staked]
	else:
		_status_lbl.text = "Випало %s. Наступного разу пощастить!" % tag
	_bets.clear()
	_refresh_texts()
	bet_placed.emit(0)


func _refresh_texts() -> void:
	var tb := total_bet()
	_bank_lbl.text = "🎰 3D РУЛЕТКА  |  Ваші фішки: %d  |  Поточна ставка: %d  |  Обрано фішку: %d" % [_chips_ref - tb, tb, _chip_val]
	for i in range(CHIP_VALS.size()):
		var b := _chip_btns[i]
		b.text = ("[%d]" if CHIP_VALS[i] == _chip_val else "%d") % CHIP_VALS[i]
		b.disabled = _spinning
	for k in _bet_btns.keys():
		var btn: Button = _bet_btns[k]
		var base := str(btn.get_meta("base_label"))
		var amt := int(_bets.get(k, 0))
		btn.text = "%s\n(%d)" % [base, amt] if amt > 0 else base
	_spin_btn.disabled = _spinning
	_clear_btn.disabled = _spinning
	_rebet_btn.disabled = _spinning or _last_bets.is_empty()
	_exit_btn.disabled = _spinning
	var h_parts: Array[String] = []
	for hn in _history:
		h_parts.append(pocket_color_tag(hn))
	_hist_lbl.text = "Історія: " + ("  |  ".join(h_parts) if not h_parts.is_empty() else "—")


func handle_key(phys_key: int) -> bool:
	if not visible:
		return false
	if phys_key == KEY_SPACE:
		_on_spin()
		return true
	if phys_key == KEY_ESCAPE and not _spinning:
		exit_requested.emit()
		return true
	return false
