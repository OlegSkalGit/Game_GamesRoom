extends CanvasLayer

signal new_game_requested
signal resume_requested
signal weather_changed(mode: int)

var is_game_started: bool = false

var _backdrop: ColorRect
var _center_hbox: HBoxContainer
var _nav_panel: PanelContainer
var _sub_panel: PanelContainer
var _settings_tabs: HBoxContainer
var _sub_scroll: ScrollContainer
var _sub_vbox: VBoxContainer
var _sub_title: Label

var _btn_play: Button
var _btn_resume: Button
var _btn_settings: Button
var _btn_tab_display: Button
var _btn_tab_graphics: Button
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
var _sld_vol: HSlider
var _lbl_vol: Label

var _opt_res: OptionButton
var _opt_win_mode: OptionButton
var _opt_vsync: OptionButton
var _opt_fps: OptionButton
var _res_list: Array[Vector2i] = []


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	open_menu()


func open_menu() -> void:
	visible = true
	_btn_resume.visible = is_game_started
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if _active_tab == "graphics":
		_sync_graphics_controls()
	elif _active_tab == "display":
		_sync_display_controls()


func close_menu() -> void:
	visible = false
	_active_tab = ""
	_sub_panel.visible = false


func set_game_started(started: bool) -> void:
	is_game_started = started
	if _btn_resume:
		_btn_resume.visible = started


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

	var title := Label.new()
	title.text = "ЛІСОВЕ КАЗИНО"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.97, 0.82, 0.38))
	nav_vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Галерея 19 ігор, гірська траса й квести"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color(0.75, 0.82, 0.77))
	nav_vbox.add_child(subtitle)

	var sep_top := HSeparator.new()
	nav_vbox.add_child(sep_top)

	# 1. TOP OF MENU: Гра (Start new game in the Casino Room)
	_btn_play = Button.new()
	_btn_play.text = "Гра"
	_style_button(_btn_play, true, false)
	_btn_play.pressed.connect(func():
		AudioSfx.play_ui_click()
		close_menu()
		new_game_requested.emit()
	)
	nav_vbox.add_child(_btn_play)

	# Optional Resume button shown only when already in-game (Esc also resumes)
	_btn_resume = Button.new()
	_btn_resume.text = "Продовжити (Esc)"
	_style_button(_btn_resume, false, false)
	_btn_resume.visible = false
	_btn_resume.pressed.connect(func():
		AudioSfx.play_ui_click()
		close_menu()
		resume_requested.emit()
	)
	nav_vbox.add_child(_btn_resume)

	# 2. Налаштування (contains Дисплей & Графіка sub-tabs)
	_btn_settings = Button.new()
	_btn_settings.text = "Налаштування"
	_style_button(_btn_settings)
	_btn_settings.pressed.connect(func():
		AudioSfx.play_ui_click()
		_toggle_settings_panel()
	)
	nav_vbox.add_child(_btn_settings)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	nav_vbox.add_child(spacer)

	var controls_hint := Label.new()
	controls_hint.text = "WASD — рух | Shift — біг | E / ЛКМ — дія | Q — квести | F — ліхтар | Esc — меню"
	controls_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	controls_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls_hint.add_theme_font_size_override("font_size", 12)
	controls_hint.add_theme_color_override("font_color", Color(0.68, 0.74, 0.70))
	nav_vbox.add_child(controls_hint)

	# 4. BOTTOM OF MENU: Вийти
	_btn_quit = Button.new()
	_btn_quit.text = "Вийти"
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
	_btn_tab_display.text = "Дисплей"
	_btn_tab_display.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_tab_display.pressed.connect(func():
		AudioSfx.play_ui_click()
		_open_subtab("display")
	)
	_settings_tabs.add_child(_btn_tab_display)

	_btn_tab_graphics = Button.new()
	_btn_tab_graphics.text = "Графіка"
	_btn_tab_graphics.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_tab_graphics.pressed.connect(func():
		AudioSfx.play_ui_click()
		_open_subtab("graphics")
	)
	_settings_tabs.add_child(_btn_tab_graphics)

	_sub_scroll = ScrollContainer.new()
	_sub_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sub_outer.add_child(_sub_scroll)

	_sub_vbox = VBoxContainer.new()
	_sub_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_sub_vbox.add_theme_constant_override("separation", 12)
	_sub_scroll.add_child(_sub_vbox)


func _toggle_settings_panel() -> void:
	if _sub_panel.visible:
		_active_tab = ""
		_sub_panel.visible = false
		return
	_open_subtab("display")


func _open_subtab(tab: String) -> void:
	_active_tab = tab
	_sub_panel.visible = true
	_sub_title.text = "Налаштування"
	_style_button(_btn_tab_display, tab == "display", false)
	_style_button(_btn_tab_graphics, tab == "graphics", false)
	for child in _sub_vbox.get_children():
		child.queue_free()
	if tab == "graphics":
		_build_graphics_panel()
	elif tab == "display":
		_build_display_panel()


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
	var compat_note := " (режим OpenGL сумісності)" if ConfigManager.is_compatibility_renderer() else ""
	info.text = "Рендер: %s%s" % [ConfigManager.get_renderer_display_name(), compat_note]
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_theme_font_size_override("font_size", 13)
	info.add_theme_color_override("font_color", Color(0.70, 0.85, 0.76))
	_sub_vbox.add_child(info)

	_opt_preset = OptionButton.new()
	for p in ConfigManager.PRESET_NAMES:
		_opt_preset.add_item(p)
	_opt_preset.item_selected.connect(func(idx: int):
		AudioSfx.play_ui_click()
		ConfigManager.apply_preset(idx)
		_sync_graphics_controls()
	)
	_add_row("Пресет якості", _opt_preset)

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
	_add_row("Масштаб рендеру", scale_box)

	_opt_aa = OptionButton.new()
	for a in ConfigManager.AA_NAMES:
		_opt_aa.add_item(a)
	_opt_aa.item_selected.connect(func(idx: int):
		ConfigManager.graphics["antialiasing"] = idx
		ConfigManager.apply_graphics()
		ConfigManager.save_config()
	)
	_add_row("Згладжування", _opt_aa)

	_opt_shadows = OptionButton.new()
	for s in ConfigManager.SHADOW_NAMES:
		_opt_shadows.add_item(s)
	_opt_shadows.item_selected.connect(func(idx: int):
		ConfigManager.graphics["shadows"] = idx
		ConfigManager.apply_graphics()
		ConfigManager.save_config()
	)
	_add_row("Тіні", _opt_shadows)

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
	_add_row("Щільність рослинності", fol_box)

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
	_add_row("Дальність огляду", dist_box)

	_chk_sdfgi = CheckButton.new()
	_chk_sdfgi.text = "Увімкнено"
	_chk_sdfgi.disabled = ConfigManager.is_compatibility_renderer()
	_chk_sdfgi.toggled.connect(func(on: bool):
		ConfigManager.graphics["sdfgi"] = on
		ConfigManager.apply_graphics()
		ConfigManager.save_config()
	)
	_add_row("Глобальне світло (SDFGI)", _chk_sdfgi)

	_chk_ssao = CheckButton.new()
	_chk_ssao.text = "Увімкнено"
	_chk_ssao.disabled = ConfigManager.is_compatibility_renderer()
	_chk_ssao.toggled.connect(func(on: bool):
		ConfigManager.graphics["ssao"] = on
		ConfigManager.apply_graphics()
		ConfigManager.save_config()
	)
	_add_row("Затінення (SSAO)", _chk_ssao)

	_chk_ssr = CheckButton.new()
	_chk_ssr.text = "Увімкнено"
	_chk_ssr.disabled = ConfigManager.is_compatibility_renderer()
	_chk_ssr.toggled.connect(func(on: bool):
		ConfigManager.graphics["ssr"] = on
		ConfigManager.apply_graphics()
		ConfigManager.save_config()
	)
	_add_row("Відблиски води (SSR)", _chk_ssr)

	_chk_fog = CheckButton.new()
	_chk_fog.text = "Увімкнено"
	_chk_fog.disabled = ConfigManager.is_compatibility_renderer()
	_chk_fog.toggled.connect(func(on: bool):
		ConfigManager.graphics["volumetric_fog"] = on
		ConfigManager.apply_graphics()
		ConfigManager.save_config()
	)
	_add_row("Об'ємний туман", _chk_fog)

	_chk_glow = CheckButton.new()
	_chk_glow.text = "Увімкнено"
	_chk_glow.toggled.connect(func(on: bool):
		ConfigManager.graphics["glow"] = on
		ConfigManager.apply_graphics()
		ConfigManager.save_config()
	)
	_add_row("Світіння (Bloom)", _chk_glow)

	_opt_weather = OptionButton.new()
	for w in ConfigManager.WEATHER_MODE_NAMES:
		_opt_weather.add_item(w)
	_opt_weather.item_selected.connect(func(idx: int):
		ConfigManager.graphics["weather_mode"] = idx
		ConfigManager.save_config()
		weather_changed.emit(idx)
	)
	_add_row("Погода у світі", _opt_weather)

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
	_add_row("Гучність звуку", vol_box)

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
	var vol := float(ConfigManager.audio.get("master_volume", 0.8))
	_sld_vol.set_value_no_signal(vol)
	_lbl_vol.text = "%d%%" % int(round(vol * 100.0))


func _build_display_panel() -> void:
	_res_list = ConfigManager.RESOLUTIONS.duplicate()
	if DisplayServer.get_name() != "headless":
		var native := DisplayServer.screen_get_size(DisplayServer.window_get_current_screen())
		if native.x >= 800 and native.y >= 600 and not _res_list.has(native):
			_res_list.append(native)
			_res_list.sort_custom(func(a: Vector2i, b: Vector2i): return a.x * a.y < b.x * b.y)

	_opt_res = OptionButton.new()
	for r in _res_list:
		_opt_res.add_item("%d x %d" % [r.x, r.y])
	_add_row("Роздільна здатність", _opt_res)

	_opt_win_mode = OptionButton.new()
	for m in ConfigManager.WINDOW_MODE_NAMES:
		_opt_win_mode.add_item(m)
	_add_row("Режим вікна", _opt_win_mode)

	_opt_vsync = OptionButton.new()
	for v in ConfigManager.VSYNC_NAMES:
		_opt_vsync.add_item(v)
	_add_row("VSync", _opt_vsync)

	_opt_fps = OptionButton.new()
	for f in [0, 30, 60, 120, 144, 240]:
		_opt_fps.add_item("Без обмежень" if f == 0 else "%d FPS" % f, f)
	_add_row("Обмеження FPS", _opt_fps)

	var apply_btn := Button.new()
	apply_btn.text = "Застосувати та зберегти в config.cfg"
	_style_button(apply_btn, true, false)
	apply_btn.pressed.connect(func():
		AudioSfx.play_ui_click()
		var sel_res := _res_list[clampi(_opt_res.selected, 0, _res_list.size() - 1)]
		ConfigManager.display["width"] = sel_res.x
		ConfigManager.display["height"] = sel_res.y
		ConfigManager.display["window_mode"] = _opt_win_mode.selected
		ConfigManager.display["vsync"] = _opt_vsync.selected
		ConfigManager.display["max_fps"] = _opt_fps.get_selected_id()
		ConfigManager.apply_display()
		ConfigManager.save_config()
	)
	_sub_vbox.add_child(apply_btn)

	var cfg_lbl := Label.new()
	cfg_lbl.text = "Файл конфігу: %s" % ConfigManager.get_config_path()
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
