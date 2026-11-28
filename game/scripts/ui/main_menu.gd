extends CanvasLayer

signal new_game_requested
signal resume_requested
signal save_game_requested
signal load_game_requested
signal weather_changed(mode: int)
signal time_settings_changed

var is_game_started: bool = false

var _backdrop: ColorRect
var _center_hbox: HBoxContainer
var _nav_panel: PanelContainer
var _sub_panel: PanelContainer
var _settings_tabs: HBoxContainer
var _sub_scroll: ScrollContainer
var _sub_vbox: VBoxContainer
var _sub_title: Label

var _btn_game: Button
var _btn_play: Button
var _btn_resume: Button
var _btn_save: Button
var _btn_load: Button
var _btn_settings: Button
var _btn_tab_display: Button
var _btn_tab_graphics: Button
var _btn_tab_controls: Button
var _btn_quit: Button

var _active_tab: String = ""

# Live UI refs for Graphics & Display
var _opt_preset: OptionButton
var _sld_scale: HSlider
var _lbl_scale: Label
var _opt_aa: OptionButton
var _opt_shadows: OptionButton
var _sld_foliage: HSlider
var _lbl_foliage: Label
var _sld_dist: HSlider
var _lbl_dist: Label
var _chk_sdfgi: CheckButton
var _chk_ssao: CheckButton
var _chk_ssr: CheckButton
var _chk_fog: CheckButton
var _chk_glow: CheckButton
var _opt_weather: OptionButton
var _opt_time: OptionButton
var _sld_day_dur: HSlider
var _lbl_day_dur: Label
var _sld_vol: HSlider
var _lbl_vol: Label

var _opt_res: OptionButton
var _opt_win_mode: OptionButton
var _opt_vsync: OptionButton
var _opt_fps: OptionButton
var _opt_lang: OptionButton
var _chk_show_fps: CheckButton
var _lbl_title: Label
var _lbl_sub: Label
var _lbl_controls_hint: Label
var _res_list: Array[Vector2i] = []


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	ConfigManager.language_changed.connect(_refresh_language_texts)
	open_menu()


func open_menu() -> void:
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if _active_tab == "" or _active_tab == "game":
		_open_subtab("game")
	elif _active_tab == "graphics":
		_sync_graphics_controls()
	elif _active_tab == "display":
		_sync_display_controls()


func close_menu() -> void:
	visible = false
	_active_tab = ""
	_sub_panel.visible = false


func set_game_started(started: bool) -> void:
	is_game_started = started
	if visible and _active_tab == "game":
		_open_subtab("game")


func _make_panel_style(bg: Color, border: Color, radius: int = 12, border_w: int = 2) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = 22
	sb.content_margin_right = 22
	sb.content_margin_top = 18
	sb.content_margin_bottom = 18
	return sb


func _make_button_style(bg: Color, border: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	return sb


func _style_button(btn: Button, primary: bool = false, danger: bool = false) -> void:
	var normal_bg := Color(0.08, 0.17, 0.14, 0.92)
	var hover_bg := Color(0.14, 0.28, 0.22, 0.98)
	var border := Color(0.82, 0.66, 0.28, 0.75)
	if primary:
		normal_bg = Color(0.13, 0.34, 0.22, 0.96)
		hover_bg = Color(0.18, 0.45, 0.28, 1.0)
		border = Color(0.95, 0.78, 0.34, 0.95)
	elif danger:
		normal_bg = Color(0.28, 0.09, 0.09, 0.92)
		hover_bg = Color(0.42, 0.13, 0.13, 0.98)
		border = Color(0.86, 0.38, 0.32, 0.85)
	btn.add_theme_stylebox_override("normal", _make_button_style(normal_bg, border))
	btn.add_theme_stylebox_override("hover", _make_button_style(hover_bg, Color(1.0, 0.86, 0.42, 1.0)))
	btn.add_theme_stylebox_override("pressed", _make_button_style(hover_bg.darkened(0.18), border))
	btn.add_theme_stylebox_override("focus", _make_button_style(hover_bg, border))
	btn.add_theme_color_override("font_color", Color(0.97, 0.94, 0.86))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.96, 0.78))
	btn.add_theme_font_size_override("font_size", 20)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _build_ui() -> void:
	_backdrop = ColorRect.new()
	_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_backdrop.color = Color(0.03, 0.05, 0.04, 0.62)
	add_child(_backdrop)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 64)
	margin.add_theme_constant_override("margin_right", 64)
	margin.add_theme_constant_override("margin_top", 48)
	margin.add_theme_constant_override("margin_bottom", 48)
	add_child(margin)

	_center_hbox = HBoxContainer.new()
	_center_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_center_hbox.add_theme_constant_override("separation", 28)
	margin.add_child(_center_hbox)

	# Left Main Menu Navigation Panel
	_nav_panel = PanelContainer.new()
	_nav_panel.custom_minimum_size = Vector2(390, 560)
	_nav_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_nav_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.05, 0.09, 0.08, 0.94), Color(0.84, 0.68, 0.28, 0.85), 16, 2))
	_center_hbox.add_child(_nav_panel)

	var nav_vbox := VBoxContainer.new()
	nav_vbox.add_theme_constant_override("separation", 14)
	_nav_panel.add_child(nav_vbox)

	_lbl_title = Label.new()
	_lbl_title.text = ConfigManager.t("app_title")
	_lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_title.add_theme_font_size_override("font_size", 32)
	_lbl_title.add_theme_color_override("font_color", Color(0.97, 0.82, 0.38))
	nav_vbox.add_child(_lbl_title)

	_lbl_sub = Label.new()
	_lbl_sub.text = ConfigManager.t("menu_subtitle")
	_lbl_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_sub.add_theme_font_size_override("font_size", 14)
	_lbl_sub.add_theme_color_override("font_color", Color(0.75, 0.82, 0.77))
	nav_vbox.add_child(_lbl_sub)

	var sep_top := HSeparator.new()
	nav_vbox.add_child(sep_top)

	# 1. TOP OF MENU: Game section (New Game / Resume / Quick Save / Quick Load)
	_btn_game = Button.new()
	_btn_game.text = ConfigManager.t("menu_section_game")
	_style_button(_btn_game, true, false)
	_btn_game.pressed.connect(func():
		AudioSfx.play_ui_click()
		_toggle_game_panel()
	)
	nav_vbox.add_child(_btn_game)

	# 2. Settings (Display, Graphics & Controls sub-tabs)
	_btn_settings = Button.new()
	_btn_settings.text = ConfigManager.t("menu_settings")
	_style_button(_btn_settings)
	_btn_settings.pressed.connect(func():
		AudioSfx.play_ui_click()
		_toggle_settings_panel()
	)
	nav_vbox.add_child(_btn_settings)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	nav_vbox.add_child(spacer)

	_lbl_controls_hint = Label.new()
	_lbl_controls_hint.text = ConfigManager.t("menu_controls_hint")
	_lbl_controls_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lbl_controls_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_controls_hint.add_theme_font_size_override("font_size", 12)
	_lbl_controls_hint.add_theme_color_override("font_color", Color(0.68, 0.74, 0.70))
	nav_vbox.add_child(_lbl_controls_hint)

	# 4. BOTTOM OF MENU: Quit
	_btn_quit = Button.new()
	_btn_quit.text = ConfigManager.t("menu_quit")
	_style_button(_btn_quit, false, true)
	_btn_quit.pressed.connect(func():
		AudioSfx.play_ui_click()
		ConfigManager.save_config()
		get_tree().quit()
	)
	nav_vbox.add_child(_btn_quit)

	# Right Settings Sub-panel
	_sub_panel = PanelContainer.new()
	_sub_panel.custom_minimum_size = Vector2(580, 620)
	_sub_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_sub_panel.visible = false
	_sub_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.05, 0.08, 0.07, 0.95), Color(0.84, 0.68, 0.28, 0.75), 16, 2))
	_center_hbox.add_child(_sub_panel)

	var sub_outer := VBoxContainer.new()
	sub_outer.add_theme_constant_override("separation", 12)
	_sub_panel.add_child(sub_outer)

	var header_row := HBoxContainer.new()
	sub_outer.add_child(header_row)

	_sub_title = Label.new()
	_sub_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_sub_title.add_theme_font_size_override("font_size", 24)
	_sub_title.add_theme_color_override("font_color", Color(0.97, 0.82, 0.38))
	header_row.add_child(_sub_title)

	var btn_close_sub := Button.new()
	btn_close_sub.text = "✕"
	_style_button(btn_close_sub)
	btn_close_sub.pressed.connect(func():
		AudioSfx.play_ui_click()
		_active_tab = ""
		_sub_panel.visible = false
	)
	header_row.add_child(btn_close_sub)

	sub_outer.add_child(HSeparator.new())

	_settings_tabs = HBoxContainer.new()
	_settings_tabs.add_theme_constant_override("separation", 12)
	sub_outer.add_child(_settings_tabs)

	_btn_tab_display = Button.new()
	_btn_tab_display.text = ConfigManager.t("tab_display")
	_btn_tab_display.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_tab_display.pressed.connect(func():
		AudioSfx.play_ui_click()
		_open_subtab("display")
	)
	_settings_tabs.add_child(_btn_tab_display)

	_btn_tab_graphics = Button.new()
	_btn_tab_graphics.text = ConfigManager.t("tab_graphics")
	_btn_tab_graphics.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_tab_graphics.pressed.connect(func():
		AudioSfx.play_ui_click()
		_open_subtab("graphics")
	)
	_settings_tabs.add_child(_btn_tab_graphics)

	_btn_tab_controls = Button.new()
	_btn_tab_controls.text = ConfigManager.t("tab_controls")
	_btn_tab_controls.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_tab_controls.pressed.connect(func():
		AudioSfx.play_ui_click()
		_open_subtab("controls")
	)
	_settings_tabs.add_child(_btn_tab_controls)

	_sub_scroll = ScrollContainer.new()
	_sub_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sub_outer.add_child(_sub_scroll)

	_sub_vbox = VBoxContainer.new()
	_sub_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_sub_vbox.add_theme_constant_override("separation", 12)
	_sub_scroll.add_child(_sub_vbox)


func _refresh_language_texts() -> void:
	if _lbl_title: _lbl_title.text = ConfigManager.t("app_title")
	if _lbl_sub: _lbl_sub.text = ConfigManager.t("menu_subtitle")
	if _btn_game: _btn_game.text = ConfigManager.t("menu_section_game")
	if _btn_settings: _btn_settings.text = ConfigManager.t("menu_settings")
	if _lbl_controls_hint: _lbl_controls_hint.text = ConfigManager.t("menu_controls_hint")
	if _btn_quit: _btn_quit.text = ConfigManager.t("menu_quit")
	if _btn_tab_display: _btn_tab_display.text = ConfigManager.t("tab_display")
	if _btn_tab_graphics: _btn_tab_graphics.text = ConfigManager.t("tab_graphics")
	if _btn_tab_controls: _btn_tab_controls.text = ConfigManager.t("tab_controls")
	if _sub_panel and _sub_panel.visible and _active_tab != "":
		_open_subtab(_active_tab)


func _toggle_game_panel() -> void:
	if _sub_panel.visible and _active_tab == "game":
		_active_tab = ""
		_sub_panel.visible = false
		return
	_open_subtab("game")


func _toggle_settings_panel() -> void:
	if _sub_panel.visible and _active_tab != "game":
		_active_tab = ""
		_sub_panel.visible = false
		return
	_open_subtab("display")


func _open_subtab(tab: String) -> void:
	_active_tab = tab
	_sub_panel.visible = true
	var is_game_tab := (tab == "game")
	_settings_tabs.visible = not is_game_tab
	_sub_title.text = ConfigManager.t("menu_section_game") if is_game_tab else ConfigManager.t("settings_title")
	_style_button(_btn_game, is_game_tab, false)
	_style_button(_btn_settings, not is_game_tab, false)
	_style_button(_btn_tab_display, tab == "display", false)
	_style_button(_btn_tab_graphics, tab == "graphics", false)
	_style_button(_btn_tab_controls, tab == "controls", false)
	for child in _sub_vbox.get_children():
		child.queue_free()
	_btn_play = null
	_btn_resume = null
	_btn_save = null
	_btn_load = null
	if tab == "game":
		_build_game_panel()
	elif tab == "graphics":
		_build_graphics_panel()
	elif tab == "display":
		_build_display_panel()
	elif tab == "controls":
		_build_controls_panel()


func _build_game_panel() -> void:
	var has_save := ConfigManager.has_save()
	if is_game_started:
		_btn_resume = Button.new()
		_btn_resume.text = ConfigManager.t("menu_resume")
		_style_button(_btn_resume, true, false)
		_btn_resume.pressed.connect(func():
			AudioSfx.play_ui_click()
			close_menu()
			resume_requested.emit()
		)
		_sub_vbox.add_child(_btn_resume)

		_btn_save = Button.new()
		_btn_save.text = ConfigManager.t("menu_save_f5")
		_style_button(_btn_save, false, false)
		_btn_save.pressed.connect(func():
			AudioSfx.play_ui_click()
			save_game_requested.emit()
			if visible and _active_tab == "game":
				_open_subtab("game")
		)
		_sub_vbox.add_child(_btn_save)

		if has_save:
			_btn_load = Button.new()
			_btn_load.text = ConfigManager.t("menu_load_f9")
			_style_button(_btn_load, false, false)
			_btn_load.pressed.connect(func():
				AudioSfx.play_ui_click()
				load_game_requested.emit()
			)
			_sub_vbox.add_child(_btn_load)

		_sub_vbox.add_child(HSeparator.new())

	_btn_play = Button.new()
	_btn_play.text = ConfigManager.t("menu_new_game")
	_style_button(_btn_play, not is_game_started, false)
	_btn_play.pressed.connect(func():
		AudioSfx.play_ui_click()
		close_menu()
		new_game_requested.emit()
	)
	_sub_vbox.add_child(_btn_play)

	if not is_game_started and has_save:
		_btn_load = Button.new()
		_btn_load.text = ConfigManager.t("menu_load_f9")
		_style_button(_btn_load, true, false)
		_btn_load.pressed.connect(func():
			AudioSfx.play_ui_click()
			load_game_requested.emit()
		)
		_sub_vbox.add_child(_btn_load)

	var save_info := Label.new()
	save_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	save_info.add_theme_font_size_override("font_size", 13)
	if has_save:
		var ts := ConfigManager.get_save_timestamp()
		save_info.text = ConfigManager.t("menu_save_ready") % (ts if ts != "" else "savegame.cfg")
		save_info.add_theme_color_override("font_color", Color(0.62, 0.90, 0.72))
	else:
		save_info.text = ConfigManager.t("menu_no_save")
		save_info.add_theme_color_override("font_color", Color(0.68, 0.74, 0.70))
	_sub_vbox.add_child(save_info)


func _build_controls_panel() -> void:
	var sections := [
		["ctrl_cat_walk", [
			["ctrl_k_walk_move", "ctrl_d_walk_move"],
			["ctrl_k_walk_sprint", "ctrl_d_walk_sprint"],
			["ctrl_k_walk_jump", "ctrl_d_walk_jump"],
			["ctrl_k_walk_look", "ctrl_d_walk_look"],
			["ctrl_k_walk_use", "ctrl_d_walk_use"],
			["ctrl_k_walk_flash", "ctrl_d_walk_flash"],
			["ctrl_k_walk_quest", "ctrl_d_walk_quest"],
			["ctrl_k_walk_f5", "ctrl_d_walk_f5"],
			["ctrl_k_walk_f9", "ctrl_d_walk_f9"],
			["ctrl_k_walk_esc", "ctrl_d_walk_esc"]
		]],
		["ctrl_cat_race", [
			["ctrl_k_race_gas", "ctrl_d_race_gas"],
			["ctrl_k_race_steer", "ctrl_d_race_steer"],
			["ctrl_k_race_nitro", "ctrl_d_race_nitro"],
			["ctrl_k_race_look", "ctrl_d_race_look"],
			["ctrl_k_race_cam", "ctrl_d_race_cam"],
			["ctrl_k_race_rst", "ctrl_d_race_rst"],
			["ctrl_k_race_exit", "ctrl_d_race_exit"]
		]],
		["ctrl_cat_bino", [
			["ctrl_k_bino_look", "ctrl_d_bino_look"],
			["ctrl_k_bino_zoom", "ctrl_d_bino_zoom"],
			["ctrl_k_bino_exit", "ctrl_d_bino_exit"]
		]],
		["ctrl_cat_mini", [
			["ctrl_k_mini_play", "ctrl_d_mini_play"],
			["ctrl_k_mini_act", "ctrl_d_mini_act"],
			["ctrl_k_mini_rst", "ctrl_d_mini_rst"],
			["ctrl_k_mini_exit", "ctrl_d_mini_exit"]
		]]
	]
	var key_sb := _make_panel_style(Color(0.08, 0.14, 0.12, 0.96), Color(0.84, 0.68, 0.28, 0.65), 6, 1)
	key_sb.content_margin_left = 10; key_sb.content_margin_right = 10
	key_sb.content_margin_top = 4; key_sb.content_margin_bottom = 4
	for sec in sections:
		var cat_lbl := Label.new()
		cat_lbl.text = ConfigManager.t(str(sec[0]))
		cat_lbl.add_theme_font_size_override("font_size", 17)
		cat_lbl.add_theme_color_override("font_color", Color(0.98, 0.84, 0.36))
		_sub_vbox.add_child(cat_lbl)
		for pair in (sec[1] as Array):
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 12)
			var kp := PanelContainer.new()
			kp.custom_minimum_size.x = 175
			kp.add_theme_stylebox_override("panel", key_sb)
			var kl := Label.new()
			kl.text = ConfigManager.t(str(pair[0]))
			kl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			kl.add_theme_font_size_override("font_size", 13)
			kl.add_theme_color_override("font_color", Color(0.96, 0.96, 0.88))
			kp.add_child(kl)
			row.add_child(kp)
			var dl := Label.new()
			dl.text = ConfigManager.t(str(pair[1]))
			dl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			dl.add_theme_font_size_override("font_size", 14)
			dl.add_theme_color_override("font_color", Color(0.88, 0.92, 0.89))
			row.add_child(dl)
			_sub_vbox.add_child(row)
		_sub_vbox.add_child(HSeparator.new())


func _add_row(label_text: String, control: Control) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var lbl := Label.new()
	lbl.text = label_text
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color(0.92, 0.93, 0.90))
	row.add_child(lbl)
	control.custom_minimum_size.x = 260
	row.add_child(control)
	_sub_vbox.add_child(row)


func _build_graphics_panel() -> void:
	var info := Label.new()
	var compat_note := ConfigManager.t("gfx_compat_note") if ConfigManager.is_compatibility_renderer() else ""
	info.text = ConfigManager.t("gfx_renderer") % [ConfigManager.get_renderer_display_name(), compat_note]
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_theme_font_size_override("font_size", 13)
	info.add_theme_color_override("font_color", Color(0.70, 0.85, 0.76))
	_sub_vbox.add_child(info)

	_opt_preset = OptionButton.new()
	for i in range(ConfigManager.PRESET_NAMES.size()):
		_opt_preset.add_item(ConfigManager.t("preset_%d" % i, ConfigManager.PRESET_NAMES[i]))
	_opt_preset.item_selected.connect(func(idx: int):
		AudioSfx.play_ui_click()
		ConfigManager.apply_preset(idx)
		_sync_graphics_controls()
	)
	_add_row(ConfigManager.t("gfx_preset"), _opt_preset)

	# Render scale slider
	var scale_box := HBoxContainer.new()
	_sld_scale = HSlider.new()
	_sld_scale.min_value = 0.5
	_sld_scale.max_value = 1.5
	_sld_scale.step = 0.05
	_sld_scale.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lbl_scale = Label.new()
	_lbl_scale.custom_minimum_size.x = 56
	_lbl_scale.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_sld_scale.value_changed.connect(func(v: float):
		_lbl_scale.text = "%d%%" % int(round(v * 100.0))
		ConfigManager.graphics["render_scale"] = v
		ConfigManager.apply_graphics()
		ConfigManager.save_config()
	)
	scale_box.add_child(_sld_scale)
	scale_box.add_child(_lbl_scale)
	_add_row(ConfigManager.t("gfx_render_scale"), scale_box)

	_opt_aa = OptionButton.new()
	for i in range(ConfigManager.AA_NAMES.size()):
		_opt_aa.add_item(ConfigManager.t("aa_%d" % i, ConfigManager.AA_NAMES[i]))
	_opt_aa.item_selected.connect(func(idx: int):
		ConfigManager.graphics["antialiasing"] = idx
		ConfigManager.apply_graphics()
		ConfigManager.save_config()
	)
	_add_row(ConfigManager.t("gfx_aa"), _opt_aa)

	_opt_shadows = OptionButton.new()
	for i in range(ConfigManager.SHADOW_NAMES.size()):
		_opt_shadows.add_item(ConfigManager.t("sh_%d" % i, ConfigManager.SHADOW_NAMES[i]))
	_opt_shadows.item_selected.connect(func(idx: int):
		ConfigManager.graphics["shadows"] = idx
		ConfigManager.apply_graphics()
		ConfigManager.save_config()
	)
	_add_row(ConfigManager.t("gfx_shadows"), _opt_shadows)

	# Foliage density
	var fol_box := HBoxContainer.new()
	_sld_foliage = HSlider.new()
	_sld_foliage.min_value = 0.15
	_sld_foliage.max_value = 1.5
	_sld_foliage.step = 0.05
	_sld_foliage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lbl_foliage = Label.new()
	_lbl_foliage.custom_minimum_size.x = 56
	_lbl_foliage.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_sld_foliage.value_changed.connect(func(v: float):
		_lbl_foliage.text = "%d%%" % int(round(v * 100.0))
		ConfigManager.graphics["foliage_density"] = v
		ConfigManager.apply_graphics()
		ConfigManager.save_config()
	)
	fol_box.add_child(_sld_foliage)
	fol_box.add_child(_lbl_foliage)
	_add_row(ConfigManager.t("gfx_foliage"), fol_box)

	# View distance
	var dist_box := HBoxContainer.new()
	_sld_dist = HSlider.new()
	_sld_dist.min_value = 0.45
	_sld_dist.max_value = 1.6
	_sld_dist.step = 0.05
	_sld_dist.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lbl_dist = Label.new()
	_lbl_dist.custom_minimum_size.x = 56
	_lbl_dist.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_sld_dist.value_changed.connect(func(v: float):
		_lbl_dist.text = "%d%%" % int(round(v * 100.0))
		ConfigManager.graphics["view_distance"] = v
		ConfigManager.apply_graphics()
		ConfigManager.save_config()
	)
	dist_box.add_child(_sld_dist)
	dist_box.add_child(_lbl_dist)
	_add_row(ConfigManager.t("gfx_dist"), dist_box)

	_chk_sdfgi = CheckButton.new()
	_chk_sdfgi.text = ConfigManager.t("opt_on")
	_chk_sdfgi.disabled = ConfigManager.is_compatibility_renderer()
	_chk_sdfgi.toggled.connect(func(on: bool):
		ConfigManager.graphics["sdfgi"] = on
		ConfigManager.apply_graphics()
		ConfigManager.save_config()
	)
	_add_row(ConfigManager.t("gfx_sdfgi"), _chk_sdfgi)

	_chk_ssao = CheckButton.new()
	_chk_ssao.text = ConfigManager.t("opt_on")
	_chk_ssao.disabled = ConfigManager.is_compatibility_renderer()
	_chk_ssao.toggled.connect(func(on: bool):
		ConfigManager.graphics["ssao"] = on
		ConfigManager.apply_graphics()
		ConfigManager.save_config()
	)
	_add_row(ConfigManager.t("gfx_ssao"), _chk_ssao)

	_chk_ssr = CheckButton.new()
	_chk_ssr.text = ConfigManager.t("opt_on")
	_chk_ssr.disabled = ConfigManager.is_compatibility_renderer()
	_chk_ssr.toggled.connect(func(on: bool):
		ConfigManager.graphics["ssr"] = on
		ConfigManager.apply_graphics()
		ConfigManager.save_config()
	)
	_add_row(ConfigManager.t("gfx_ssr"), _chk_ssr)

	_chk_fog = CheckButton.new()
	_chk_fog.text = ConfigManager.t("opt_on")
	_chk_fog.disabled = ConfigManager.is_compatibility_renderer()
	_chk_fog.toggled.connect(func(on: bool):
		ConfigManager.graphics["volumetric_fog"] = on
		ConfigManager.apply_graphics()
		ConfigManager.save_config()
	)
	_add_row(ConfigManager.t("gfx_fog"), _chk_fog)

	_chk_glow = CheckButton.new()
	_chk_glow.text = ConfigManager.t("opt_on")
	_chk_glow.toggled.connect(func(on: bool):
		ConfigManager.graphics["glow"] = on
		ConfigManager.apply_graphics()
		ConfigManager.save_config()
	)
	_add_row(ConfigManager.t("gfx_glow"), _chk_glow)

	_opt_weather = OptionButton.new()
	for i in range(ConfigManager.WEATHER_MODE_NAMES.size()):
		_opt_weather.add_item(ConfigManager.t("w_%d" % i, ConfigManager.WEATHER_MODE_NAMES[i]))
	_opt_weather.item_selected.connect(func(idx: int):
		ConfigManager.graphics["weather_mode"] = idx
		ConfigManager.save_config()
		weather_changed.emit(idx)
	)
	_add_row(ConfigManager.t("gfx_weather"), _opt_weather)

	_opt_time = OptionButton.new()
	for i in range(ConfigManager.TIME_MODE_NAMES.size()):
		_opt_time.add_item(ConfigManager.t("t_%d" % i, ConfigManager.TIME_MODE_NAMES[i]))
	_opt_time.item_selected.connect(func(idx: int):
		ConfigManager.graphics["day_time_mode"] = idx
		ConfigManager.save_config()
		time_settings_changed.emit()
	)
	_add_row(ConfigManager.t("gfx_time"), _opt_time)

	var dur_box := HBoxContainer.new()
	_sld_day_dur = HSlider.new()
	_sld_day_dur.min_value = 1.0
	_sld_day_dur.max_value = 60.0
	_sld_day_dur.step = 1.0
	_sld_day_dur.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lbl_day_dur = Label.new()
	_lbl_day_dur.custom_minimum_size.x = 64
	_lbl_day_dur.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_sld_day_dur.value_changed.connect(func(v: float):
		_lbl_day_dur.text = ConfigManager.t("unit_min") % int(round(v))
		ConfigManager.graphics["day_duration_min"] = v
		ConfigManager.save_config()
		time_settings_changed.emit()
	)
	dur_box.add_child(_sld_day_dur)
	dur_box.add_child(_lbl_day_dur)
	_add_row(ConfigManager.t("gfx_day_dur"), dur_box)

	var vol_box := HBoxContainer.new()
	_sld_vol = HSlider.new()
	_sld_vol.min_value = 0.0
	_sld_vol.max_value = 1.0
	_sld_vol.step = 0.05
	_sld_vol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lbl_vol = Label.new()
	_lbl_vol.custom_minimum_size.x = 56
	_lbl_vol.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_sld_vol.value_changed.connect(func(v: float):
		_lbl_vol.text = "%d%%" % int(round(v * 100.0))
		ConfigManager.audio["master_volume"] = v
		ConfigManager.apply_audio()
		ConfigManager.save_config()
	)
	vol_box.add_child(_sld_vol)
	vol_box.add_child(_lbl_vol)
	_add_row(ConfigManager.t("gfx_volume"), vol_box)

	_sync_graphics_controls()


func _sync_graphics_controls() -> void:
	if _opt_preset == null:
		return
	_opt_preset.selected = clampi(int(ConfigManager.graphics.get("preset", 3)), 0, ConfigManager.PRESET_NAMES.size() - 1)
	var sc := float(ConfigManager.graphics.get("render_scale", 1.0))
	_sld_scale.set_value_no_signal(sc)
	_lbl_scale.text = "%d%%" % int(round(sc * 100.0))
	_opt_aa.selected = clampi(int(ConfigManager.graphics.get("antialiasing", 2)), 0, ConfigManager.AA_NAMES.size() - 1)
	_opt_shadows.selected = clampi(int(ConfigManager.graphics.get("shadows", 3)), 0, ConfigManager.SHADOW_NAMES.size() - 1)
	var fol := float(ConfigManager.graphics.get("foliage_density", 1.0))
	_sld_foliage.set_value_no_signal(fol)
	_lbl_foliage.text = "%d%%" % int(round(fol * 100.0))
	var dist := float(ConfigManager.graphics.get("view_distance", 1.0))
	_sld_dist.set_value_no_signal(dist)
	_lbl_dist.text = "%d%%" % int(round(dist * 100.0))
	_chk_sdfgi.set_pressed_no_signal(bool(ConfigManager.graphics.get("sdfgi", false)))
	_chk_ssao.set_pressed_no_signal(bool(ConfigManager.graphics.get("ssao", true)))
	_chk_ssr.set_pressed_no_signal(bool(ConfigManager.graphics.get("ssr", true)))
	_chk_fog.set_pressed_no_signal(bool(ConfigManager.graphics.get("volumetric_fog", true)))
	_chk_glow.set_pressed_no_signal(bool(ConfigManager.graphics.get("glow", true)))
	_opt_weather.selected = clampi(int(ConfigManager.graphics.get("weather_mode", 0)), 0, ConfigManager.WEATHER_MODE_NAMES.size() - 1)
	_opt_time.selected = clampi(int(ConfigManager.graphics.get("day_time_mode", 0)), 0, ConfigManager.TIME_MODE_NAMES.size() - 1)
	var dur := float(ConfigManager.graphics.get("day_duration_min", 28.0))
	_sld_day_dur.set_value_no_signal(dur)
	_lbl_day_dur.text = ConfigManager.t("unit_min") % int(round(dur))
	var vol := float(ConfigManager.audio.get("master_volume", 0.8))
	_sld_vol.set_value_no_signal(vol)
	_lbl_vol.text = "%d%%" % int(round(vol * 100.0))


func _build_display_panel() -> void:
	_opt_lang = OptionButton.new()
	var langs := ConfigManager.get_languages()
	for i in range(langs.size()):
		var entry: Dictionary = langs[i]
		_opt_lang.add_item(str(entry.get("name", entry.get("code", "en"))))
		_opt_lang.set_item_metadata(i, str(entry.get("code", "en")))
	_opt_lang.item_selected.connect(func(idx: int):
		AudioSfx.play_ui_click()
		var lang_code := str(_opt_lang.get_item_metadata(idx))
		ConfigManager.set_language(lang_code, true)
	)
	_add_row(ConfigManager.t("disp_lang"), _opt_lang)

	_res_list = ConfigManager.RESOLUTIONS.duplicate()
	if DisplayServer.get_name() != "headless":
		var native := DisplayServer.screen_get_size(DisplayServer.window_get_current_screen())
		if native.x >= 800 and native.y >= 600 and not _res_list.has(native):
			_res_list.append(native)
			_res_list.sort_custom(func(a: Vector2i, b: Vector2i): return a.x * a.y < b.x * b.y)

	_opt_res = OptionButton.new()
	for r in _res_list:
		_opt_res.add_item("%d x %d" % [r.x, r.y])
	_add_row(ConfigManager.t("disp_res"), _opt_res)

	_opt_win_mode = OptionButton.new()
	for i in range(ConfigManager.WINDOW_MODE_NAMES.size()):
		_opt_win_mode.add_item(ConfigManager.t("win_%d" % i, ConfigManager.WINDOW_MODE_NAMES[i]))
	_add_row(ConfigManager.t("disp_win_mode"), _opt_win_mode)

	_opt_vsync = OptionButton.new()
	var vsync_keys := ["opt_off", "opt_on", "vsync_2"]
	for i in range(ConfigManager.VSYNC_NAMES.size()):
		var k: String = vsync_keys[i] if i < vsync_keys.size() else "opt_off"
		_opt_vsync.add_item(ConfigManager.t(k, ConfigManager.VSYNC_NAMES[i]))
	_add_row(ConfigManager.t("disp_vsync"), _opt_vsync)

	_opt_fps = OptionButton.new()
	for f in [0, 30, 60, 120, 144, 240]:
		_opt_fps.add_item(ConfigManager.t("disp_fps_unlimited") if f == 0 else "%d FPS" % f, f)
	_add_row(ConfigManager.t("disp_max_fps"), _opt_fps)

	_chk_show_fps = CheckButton.new()
	_chk_show_fps.text = ConfigManager.t("opt_on")
	_chk_show_fps.toggled.connect(func(on: bool):
		ConfigManager.display["show_fps"] = on
		ConfigManager.apply_display()
		ConfigManager.save_config()
	)
	_add_row(ConfigManager.t("disp_show_fps"), _chk_show_fps)

	var apply_btn := Button.new()
	apply_btn.text = ConfigManager.t("disp_apply")
	_style_button(apply_btn, true, false)
	apply_btn.pressed.connect(func():
		AudioSfx.play_ui_click()
		var sel_res := _res_list[clampi(_opt_res.selected, 0, _res_list.size() - 1)]
		ConfigManager.display["width"] = sel_res.x
		ConfigManager.display["height"] = sel_res.y
		ConfigManager.display["window_mode"] = _opt_win_mode.selected
		ConfigManager.display["vsync"] = _opt_vsync.selected
		ConfigManager.display["max_fps"] = _opt_fps.get_selected_id()
		ConfigManager.display["show_fps"] = _chk_show_fps.button_pressed
		if _opt_lang and _opt_lang.selected >= 0 and _opt_lang.selected < _opt_lang.item_count:
			ConfigManager.display["language"] = str(_opt_lang.get_item_metadata(_opt_lang.selected))
		ConfigManager.apply_display()
		ConfigManager.save_config()
	)
	_sub_vbox.add_child(apply_btn)

	var cfg_lbl := Label.new()
	cfg_lbl.text = ConfigManager.t("disp_cfg_path") % ConfigManager.get_config_path()
	cfg_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cfg_lbl.add_theme_font_size_override("font_size", 12)
	cfg_lbl.add_theme_color_override("font_color", Color(0.65, 0.72, 0.68))
	_sub_vbox.add_child(cfg_lbl)

	_sync_display_controls()


func _sync_display_controls() -> void:
	if _opt_res == null:
		return
	var cur := Vector2i(int(ConfigManager.display.get("width", 1920)), int(ConfigManager.display.get("height", 1080)))
	var idx := _res_list.find(cur)
	if idx < 0:
		idx = 0
	_opt_res.selected = idx
	_opt_win_mode.selected = clampi(int(ConfigManager.display.get("window_mode", 0)), 0, ConfigManager.WINDOW_MODE_NAMES.size() - 1)
	_opt_vsync.selected = clampi(int(ConfigManager.display.get("vsync", 1)), 0, ConfigManager.VSYNC_NAMES.size() - 1)
	var fps_target := int(ConfigManager.display.get("max_fps", 0))
	for i in range(_opt_fps.item_count):
		if _opt_fps.get_item_id(i) == fps_target:
			_opt_fps.selected = i
			break
	if _chk_show_fps:
		_chk_show_fps.set_pressed_no_signal(bool(ConfigManager.display.get("show_fps", false)))
	if _opt_lang:
		var cur_lang := ConfigManager.get_current_language()
		for i in range(_opt_lang.item_count):
			if str(_opt_lang.get_item_metadata(i)) == cur_lang:
				_opt_lang.selected = i
				break
