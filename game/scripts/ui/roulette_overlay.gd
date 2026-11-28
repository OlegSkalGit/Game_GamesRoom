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
var _chip_lbl: Label
var _hint_lbl: Label
var _chip_val: int = 25
var _chip_btns: Array[Button] = []
var _bet_btns: Dictionary = {}
var _bets: Dictionary = {} # key: String ("n_17", "red", "black", "even", "odd", "low", "high", "d1", "d2", "d3") -> int amount
var _last_bets: Dictionary = {}
var _spin_btn: Button
var _spin_sb_ready: StyleBoxFlat
var _spin_sb_idle: StyleBoxFlat
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
		return ConfigManager.t("r_zero")
	return (ConfigManager.t("r_red") if is_red(n) else ConfigManager.t("r_black")) % n


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
	ConfigManager.language_changed.connect(_refresh_language)


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
	_panel.offset_top = -346; _panel.offset_bottom = -12
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.14, 0.09, 0.94)
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

	_chip_lbl = Label.new(); _chip_lbl.text = ConfigManager.t("r_chip")
	_chip_lbl.add_theme_font_size_override("font_size", 14)
	ctrl_h.add_child(_chip_lbl)
	for cv in CHIP_VALS:
		var cb := Button.new(); cb.text = str(cv)
		cb.focus_mode = Control.FOCUS_NONE
		cb.pressed.connect(func():
			AudioSfx.play_ui_click()
			_chip_val = cv
			_refresh_texts()
		)
		ctrl_h.add_child(cb)
		_chip_btns.append(cb)

	_hist_lbl = Label.new()
	_hist_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hist_lbl.clip_text = true
	_hist_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hist_lbl.add_theme_font_size_override("font_size", 13)
	_hist_lbl.add_theme_color_override("font_color", Color(0.84, 0.90, 0.86))
	ctrl_h.add_child(_hist_lbl)

	_rebet_btn = Button.new(); _rebet_btn.text = ConfigManager.t("r_rebet")
	_rebet_btn.focus_mode = Control.FOCUS_NONE
	_rebet_btn.pressed.connect(_on_rebet)
	ctrl_h.add_child(_rebet_btn)

	_clear_btn = Button.new(); _clear_btn.text = ConfigManager.t("r_clear")
	_clear_btn.focus_mode = Control.FOCUS_NONE
	_clear_btn.pressed.connect(_on_clear)
	ctrl_h.add_child(_clear_btn)

	_exit_btn = Button.new(); _exit_btn.text = ConfigManager.t("r_leave")
	_exit_btn.focus_mode = Control.FOCUS_NONE
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
	z_btn.custom_minimum_size = Vector2(58, 138)
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
			b.custom_minimum_size = Vector2(0, 44)
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
		["even", ConfigManager.t("r_even"), Color(0.14, 0.22, 0.28)],
		["red", ConfigManager.t("r_red_btn"), Color(0.66, 0.13, 0.15)],
		["black", ConfigManager.t("r_black_btn"), Color(0.12, 0.13, 0.16)],
		["odd", ConfigManager.t("r_odd"), Color(0.14, 0.22, 0.28)],
		["high", "19-36", Color(0.14, 0.22, 0.28)]
	]:
		var b := _make_bet_btn(str(spec[0]), str(spec[1]), spec[2] as Color)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 44)
		out_h.add_child(b)

	# Dedicated prominent SPIN LAUNCH row
	var launch_h := HBoxContainer.new()
	launch_h.add_theme_constant_override("separation", 12)
	main_v.add_child(launch_h)

	_hint_lbl = Label.new()
	_hint_lbl.text = ConfigManager.t("r_hint")
	_hint_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hint_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hint_lbl.add_theme_font_size_override("font_size", 13)
	_hint_lbl.add_theme_color_override("font_color", Color(0.84, 0.90, 0.80))
	launch_h.add_child(_hint_lbl)

	_spin_sb_ready = StyleBoxFlat.new()
	_spin_sb_ready.bg_color = Color(0.10, 0.56, 0.26)
	_spin_sb_ready.border_color = Color(0.98, 0.84, 0.26)
	_spin_sb_ready.set_border_width_all(2); _spin_sb_ready.set_corner_radius_all(6)

	_spin_sb_idle = StyleBoxFlat.new()
	_spin_sb_idle.bg_color = Color(0.16, 0.20, 0.19)
	_spin_sb_idle.border_color = Color(0.42, 0.45, 0.42)
	_spin_sb_idle.set_border_width_all(1); _spin_sb_idle.set_corner_radius_all(6)

	_spin_btn = Button.new()
	_spin_btn.text = ConfigManager.t("r_spin_need")
	_spin_btn.focus_mode = Control.FOCUS_NONE
	_spin_btn.custom_minimum_size = Vector2(390, 40)
	_spin_btn.add_theme_font_size_override("font_size", 15)
	_spin_btn.add_theme_color_override("font_color", Color(1.0, 0.96, 0.82))
	_spin_btn.add_theme_stylebox_override("normal", _spin_sb_idle)
	_spin_btn.pressed.connect(_on_spin)
	launch_h.add_child(_spin_btn)


func _make_bet_btn(key: String, label: String, base_col: Color) -> Button:
	var b := Button.new()
	b.text = label
	b.focus_mode = Control.FOCUS_NONE
	b.clip_text = true
	b.add_theme_font_size_override("font_size", 12)
	var sb := StyleBoxFlat.new()
	sb.bg_color = base_col
	sb.border_color = Color(0.75, 0.62, 0.28, 0.65)
	sb.set_border_width_all(1); sb.set_corner_radius_all(4)
	sb.content_margin_top = 2; sb.content_margin_bottom = 2
	sb.content_margin_left = 4; sb.content_margin_right = 4
	b.add_theme_stylebox_override("normal", sb)
	var sb_h := sb.duplicate() as StyleBoxFlat
	sb_h.bg_color = base_col.lightened(0.14)
	sb_h.border_color = Color(0.95, 0.80, 0.36)
	b.add_theme_stylebox_override("hover", sb_h)
	b.add_theme_stylebox_override("pressed", sb_h)
	b.set_meta("base_label", label)
	b.pressed.connect(func(): _place_bet(key))
	_bet_btns[key] = b
	return b


func _refresh_language() -> void:
	if _chip_lbl: _chip_lbl.text = ConfigManager.t("r_chip")
	if _rebet_btn: _rebet_btn.text = ConfigManager.t("r_rebet")
	if _clear_btn: _clear_btn.text = ConfigManager.t("r_clear")
	if _exit_btn: _exit_btn.text = ConfigManager.t("r_leave")
	if _hint_lbl: _hint_lbl.text = ConfigManager.t("r_hint")
	var dyn_keys := {"even": "r_even", "red": "r_red_btn", "black": "r_black_btn", "odd": "r_odd"}
	for k in dyn_keys.keys():
		if _bet_btns.has(k):
			_bet_btns[k].set_meta("base_label", ConfigManager.t(dyn_keys[k]))
	if not _spinning and _bets.is_empty():
		_status_lbl.text = ConfigManager.t("r_open_status")
	_refresh_texts()


func open(chips_balance: int) -> void:
	_chips_ref = chips_balance
	_spinning = false
	_bets.clear()
	_status_lbl.text = ConfigManager.t("r_open_status")
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
		_status_lbl.text = ConfigManager.t("r_no_chips")
		return
	var add := mini(_chip_val, avail)
	_bets[key] = int(_bets.get(key, 0)) + add
	AudioSfx.play_ui_click()
	_status_lbl.text = ConfigManager.t("r_bet_status") % total_bet()
	_refresh_texts()
	bet_placed.emit(total_bet())


func _on_clear() -> void:
	if _spinning:
		return
	_bets.clear()
	AudioSfx.play_ui_click()
	_status_lbl.text = ConfigManager.t("r_cleared")
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
		_status_lbl.text = ConfigManager.t("r_rebet_low")
		AudioSfx.play_brick_bump()
		return
	_bets = _last_bets.duplicate()
	AudioSfx.play_ui_click()
	_status_lbl.text = ConfigManager.t("r_rebet_ok") % total_bet()
	_refresh_texts()
	bet_placed.emit(total_bet())


func _on_spin() -> void:
	if _spinning:
		return
	if _bets.is_empty():
		AudioSfx.play_brick_bump()
		_status_lbl.text = ConfigManager.t("r_need_bet")
		return
	_spinning = true
	_last_bets = _bets.duplicate()
	_status_lbl.text = ConfigManager.t("r_spinning_status")
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
		_status_lbl.text = ConfigManager.t("r_win_status") % [tag, payout, staked]
	else:
		_status_lbl.text = ConfigManager.t("r_lose_status") % tag
	_bets.clear()
	_refresh_texts()
	bet_placed.emit(0)


func _refresh_texts() -> void:
	var tb := total_bet()
	_bank_lbl.text = ConfigManager.t("r_bank") % [_chips_ref - tb, tb, _chip_val]
	for i in range(CHIP_VALS.size()):
		var b := _chip_btns[i]
		b.text = ("[%d]" if CHIP_VALS[i] == _chip_val else "%d") % CHIP_VALS[i]
		b.disabled = _spinning
	for k in _bet_btns.keys():
		var btn: Button = _bet_btns[k]
		var base := str(btn.get_meta("base_label"))
		var amt := int(_bets.get(k, 0))
		btn.text = "%s\n(%d)" % [base, amt] if amt > 0 else base
	if _spinning:
		_spin_btn.text = ConfigManager.t("r_spin_busy")
		_spin_btn.disabled = true
		_spin_btn.add_theme_stylebox_override("normal", _spin_sb_idle)
		_spin_btn.add_theme_stylebox_override("hover", _spin_sb_idle)
	elif tb > 0:
		_spin_btn.text = ConfigManager.t("r_spin_ready") % tb
		_spin_btn.disabled = false
		_spin_btn.add_theme_stylebox_override("normal", _spin_sb_ready)
		_spin_btn.add_theme_stylebox_override("hover", _spin_sb_ready)
	else:
		_spin_btn.text = ConfigManager.t("r_spin_need")
		_spin_btn.disabled = false
		_spin_btn.add_theme_stylebox_override("normal", _spin_sb_idle)
		_spin_btn.add_theme_stylebox_override("hover", _spin_sb_idle)
	_clear_btn.disabled = _spinning or tb == 0
	_rebet_btn.disabled = _spinning or _last_bets.is_empty()
	_exit_btn.disabled = _spinning
	var h_parts: Array[String] = []
	for hn in _history:
		h_parts.append(pocket_color_tag(hn))
	_hist_lbl.text = "📜 " + ("  |  ".join(h_parts) if not h_parts.is_empty() else "—")


func handle_key(phys_key: int) -> bool:
	if not visible:
		return false
	if phys_key == KEY_SPACE or phys_key == KEY_ENTER or phys_key == KEY_KP_ENTER:
		_on_spin()
		return true
	if phys_key == KEY_ESCAPE and not _spinning:
		exit_requested.emit()
		return true
	return false
