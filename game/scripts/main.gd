extends Node3D

const RaceCarScript := preload("res://scripts/player/race_car.gd")
const QuestMgrScript := preload("res://scripts/autoload/quest_manager.gd")
const IntroSplashScript := preload("res://scripts/ui/intro_splash.gd")
const RouletteOverlayScript := preload("res://scripts/ui/roulette_overlay.gd")

var _world: WorldBuilder
var _player: PlayerController
var _race_car
var _quests
var _intro
var _menu: CanvasLayer
var _minigame_host: MinigameHost

var _hud_layer: CanvasLayer
var _prompt_panel: PanelContainer
var _prompt_lbl: Label
var _status_lbl: Label
var _fps_lbl: Label
var _fps_accum: float = 0.0
var _quest_hud_panel: PanelContainer
var _quest_hud_lbl: Label
var _quest_journal_panel: PanelContainer
var _quest_journal_lbl: Label
var _race_hud_lbl: Label
var _race_banner_panel: PanelContainer
var _race_banner_lbl: Label
var _toast_panel: PanelContainer
var _toast_lbl: Label
var _toast_t: float = 0.0
var _portal_overlay: ColorRect

var _bino_layer: CanvasLayer
var _bino_ctrl: Control
var _bino_cam: Camera3D
var _in_binoculars: bool = false
var _bino_yaw: float = 1.25
var _bino_pitch: float = -0.10
var _bino_zoom: float = 4.0

var _is_driving: bool = false
var _transitioning: bool = false
var _saved_cam_tf: Transform3D
var _active_painting_id: String = ""
var _games_map_panel: PanelContainer
var _games_map_lbl: Label
var _games_map_title: Label
var _games_map_hint: Label
var _quest_journal_title: Label
var _quest_journal_hint: Label
var _roulette_ui
var _roulette_cam: Camera3D
var _in_roulette: bool = false
var _active_roulette_bets: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_world = WorldBuilder.new()
	_world.name = "WorldBuilder"
	_world.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_world)

	_player = PlayerController.new()
	_player.name = "Player"
	_player.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_player)

	_world.build_world(_player)
	_player.set_casino_room(_world.casino_room)
	_player.reset_to_casino_spawn()
	_player.set_controls_active(false)

	_race_car = RaceCarScript.new()
	_race_car.name = "PlayerRaceCar"
	_race_car.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_race_car)
	_race_car.setup(_world.race_track)
	_race_car.exit_car_requested.connect(_exit_race)
	_race_car.hud_updated.connect(func(txt: String): if _race_hud_lbl: _race_hud_lbl.text = txt)
	_race_car.race_banner_updated.connect(_on_race_banner_updated)
	_race_car.race_completed.connect(_on_race_completed)

	_player.target_painting_changed.connect(_on_target_painting_changed)
	_player.interact_painting_requested.connect(_on_interact_painting_requested)
	_player.target_prop_changed.connect(_on_target_prop_changed)
	_player.interact_prop_requested.connect(_on_interact_prop_requested)

	_quests = QuestMgrScript.new()
	_quests.state_changed.connect(_refresh_quest_ui)
	_quests.quest_event.connect(func(msg: String, is_comp: bool):
		_show_toast(msg)
		if is_comp:
			AudioSfx.play_fanfare()
		else:
			AudioSfx.play_powerup()
	)

	_build_hud()
	_build_binoculars()
	_refresh_quest_ui()

	if _world and _world.casino_room:
		_world.casino_room.slot_payout.connect(_on_slot_payout)
		_world.casino_room.roulette_spin_finished.connect(_on_roulette_spin_finished)

	_roulette_ui = RouletteOverlayScript.new()
	_roulette_ui.name = "RouletteOverlay"
	add_child(_roulette_ui)
	_roulette_ui.bet_placed.connect(_on_roulette_bet_placed)
	_roulette_ui.spin_requested.connect(_on_roulette_spin_requested)
	_roulette_ui.exit_requested.connect(_exit_roulette_game)

	_roulette_cam = Camera3D.new()
	_roulette_cam.name = "RouletteCamera"
	_roulette_cam.fov = 52.0
	_roulette_cam.current = false
	add_child(_roulette_cam)

	_minigame_host = MinigameHost.new()
	_minigame_host.name = "MinigameHost"
	_minigame_host.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_minigame_host)
	_minigame_host.exit_requested.connect(_on_minigame_exit_requested)

	var menu_script := load("res://scripts/ui/main_menu.gd") as GDScript
	_menu = menu_script.new()
	_menu.name = "MainMenu"
	add_child(_menu)
	_menu.visibility_changed.connect(_on_menu_visibility_changed)
	_menu.new_game_requested.connect(_on_new_game_requested)
	_menu.resume_requested.connect(_on_resume_requested)
	_menu.save_game_requested.connect(quick_save)
	_menu.load_game_requested.connect(quick_load)
	_menu.weather_changed.connect(_on_weather_changed)
	_menu.time_settings_changed.connect(_on_time_settings_changed)
	ConfigManager.language_changed.connect(_on_language_changed)

	if _world.weather:
		_world.weather.weather_state_changed.connect(_update_status_hud)
	_update_status_hud("")

	_intro = IntroSplashScript.new()
	_intro.name = "IntroSplash"
	_intro.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_intro)


func _build_hud() -> void:
	_hud_layer = CanvasLayer.new()
	_hud_layer.layer = 10
	add_child(_hud_layer)

	# Painting interaction prompt
	_prompt_panel = PanelContainer.new()
	_prompt_panel.visible = false
	_prompt_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt_panel.offset_left = -280
	_prompt_panel.offset_right = 280
	_prompt_panel.offset_top = -125
	_prompt_panel.offset_bottom = -68
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.08, 0.07, 0.88)
	sb.border_color = Color(0.92, 0.76, 0.30, 0.95)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 18; sb.content_margin_right = 18
	sb.content_margin_top = 10; sb.content_margin_bottom = 10
	_prompt_panel.add_theme_stylebox_override("panel", sb)
	_hud_layer.add_child(_prompt_panel)

	_prompt_lbl = Label.new()
	_prompt_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_prompt_lbl.add_theme_font_size_override("font_size", 19)
	_prompt_lbl.add_theme_color_override("font_color", Color(1.0, 0.94, 0.76))
	_prompt_panel.add_child(_prompt_lbl)

	# Corner HUD status
	_status_lbl = Label.new()
	_status_lbl.position = Vector2(18, 14)
	_status_lbl.add_theme_font_size_override("font_size", 14)
	_status_lbl.add_theme_color_override("font_color", Color(0.95, 0.96, 0.92, 0.88))
	_status_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.75))
	_status_lbl.add_theme_constant_override("shadow_offset_x", 1)
	_status_lbl.add_theme_constant_override("shadow_offset_y", 1)
	_status_lbl.visible = false
	_hud_layer.add_child(_status_lbl)

	# Top-right compact Quest Tracker Pill
	_quest_hud_panel = PanelContainer.new()
	_quest_hud_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_quest_hud_panel.offset_left = -410
	_quest_hud_panel.offset_right = -16
	_quest_hud_panel.offset_top = 12
	_quest_hud_panel.offset_bottom = 66
	_quest_hud_panel.add_theme_stylebox_override("panel", sb)
	_quest_hud_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_quest_hud_panel.visible = false
	_hud_layer.add_child(_quest_hud_panel)
	_quest_hud_lbl = Label.new()
	_quest_hud_lbl.add_theme_font_size_override("font_size", 13)
	_quest_hud_lbl.add_theme_color_override("font_color", Color(0.98, 0.94, 0.78))
	_quest_hud_panel.add_child(_quest_hud_lbl)

	# Toggleable [Q] Quest Journal Overlay
	_quest_journal_panel = PanelContainer.new()
	_quest_journal_panel.set_anchors_preset(Control.PRESET_CENTER)
	_quest_journal_panel.offset_left = -330
	_quest_journal_panel.offset_right = 330
	_quest_journal_panel.offset_top = -265
	_quest_journal_panel.offset_bottom = 265
	var jsb := StyleBoxFlat.new()
	jsb.bg_color = Color(0.05, 0.06, 0.08, 0.95)
	jsb.border_color = Color(0.92, 0.76, 0.28)
	jsb.set_border_width_all(3); jsb.set_corner_radius_all(12)
	jsb.content_margin_left = 24; jsb.content_margin_right = 24
	jsb.content_margin_top = 18; jsb.content_margin_bottom = 18
	_quest_journal_panel.add_theme_stylebox_override("panel", jsb)
	_quest_journal_panel.visible = false
	_hud_layer.add_child(_quest_journal_panel)
	var jv := VBoxContainer.new()
	jv.add_theme_constant_override("separation", 10)
	_quest_journal_panel.add_child(jv)
	_quest_journal_title = Label.new()
	_quest_journal_title.text = ConfigManager.t("q_journal_title")
	_quest_journal_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_quest_journal_title.add_theme_font_size_override("font_size", 22)
	_quest_journal_title.add_theme_color_override("font_color", Color(0.98, 0.84, 0.34))
	jv.add_child(_quest_journal_title)
	_quest_journal_lbl = Label.new()
	_quest_journal_lbl.add_theme_font_size_override("font_size", 14)
	_quest_journal_lbl.add_theme_color_override("font_color", Color(0.90, 0.92, 0.88))
	_quest_journal_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_quest_journal_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	jv.add_child(_quest_journal_lbl)
	_quest_journal_hint = Label.new()
	_quest_journal_hint.text = ConfigManager.t("q_journal_hint")
	_quest_journal_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_quest_journal_hint.add_theme_font_size_override("font_size", 13)
	_quest_journal_hint.add_theme_color_override("font_color", Color(0.75, 0.82, 0.76))
	jv.add_child(_quest_journal_hint)

	# Interactive Games Directory Map Overlay
	_games_map_panel = PanelContainer.new()
	_games_map_panel.set_anchors_preset(Control.PRESET_CENTER)
	_games_map_panel.offset_left = -360
	_games_map_panel.offset_right = 360
	_games_map_panel.offset_top = -255
	_games_map_panel.offset_bottom = 255
	_games_map_panel.add_theme_stylebox_override("panel", jsb)
	_games_map_panel.visible = false
	_hud_layer.add_child(_games_map_panel)
	var mv := VBoxContainer.new()
	mv.add_theme_constant_override("separation", 10)
	_games_map_panel.add_child(mv)
	_games_map_title = Label.new()
	_games_map_title.text = ConfigManager.t("map_modal_title")
	_games_map_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_games_map_title.add_theme_font_size_override("font_size", 21)
	_games_map_title.add_theme_color_override("font_color", Color(0.98, 0.86, 0.36))
	mv.add_child(_games_map_title)
	_games_map_lbl = Label.new()
	_games_map_lbl.add_theme_font_size_override("font_size", 14)
	_games_map_lbl.add_theme_color_override("font_color", Color(0.92, 0.94, 0.90))
	_games_map_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_games_map_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mv.add_child(_games_map_lbl)
	_games_map_hint = Label.new()
	_games_map_hint.text = ConfigManager.t("map_modal_hint")
	_games_map_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_games_map_hint.add_theme_font_size_override("font_size", 13)
	_games_map_hint.add_theme_color_override("font_color", Color(0.75, 0.84, 0.78))
	mv.add_child(_games_map_hint)

	# Bottom Racing HUD bar
	_race_hud_lbl = Label.new()
	_race_hud_lbl.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_race_hud_lbl.offset_left = -460
	_race_hud_lbl.offset_right = 460
	_race_hud_lbl.offset_top = -46
	_race_hud_lbl.offset_bottom = -14
	_race_hud_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_race_hud_lbl.add_theme_font_size_override("font_size", 16)
	_race_hud_lbl.add_theme_color_override("font_color", Color(1.0, 0.94, 0.72))
	_race_hud_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	_race_hud_lbl.add_theme_constant_override("shadow_offset_x", 1)
	_race_hud_lbl.add_theme_constant_override("shadow_offset_y", 1)
	_race_hud_lbl.visible = false
	_hud_layer.add_child(_race_hud_lbl)

	# Bold Center Countdown ("3 - 2 - 1 - РУШ!") / Lap / Finish Banner
	_race_banner_panel = PanelContainer.new()
	_race_banner_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_race_banner_panel.offset_left = -330
	_race_banner_panel.offset_right = 330
	_race_banner_panel.offset_top = 84
	_race_banner_panel.offset_bottom = 186
	_race_banner_panel.add_theme_stylebox_override("panel", jsb)
	_race_banner_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_race_banner_panel.visible = false
	_hud_layer.add_child(_race_banner_panel)
	_race_banner_lbl = Label.new()
	_race_banner_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_race_banner_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_race_banner_lbl.add_theme_font_size_override("font_size", 32)
	_race_banner_lbl.add_theme_color_override("font_color", Color(1.0, 0.90, 0.32))
	_race_banner_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_race_banner_lbl.add_theme_constant_override("shadow_offset_x", 2)
	_race_banner_lbl.add_theme_constant_override("shadow_offset_y", 2)
	_race_banner_panel.add_child(_race_banner_lbl)

	# Top floating fun-gadget notification toast
	_toast_panel = PanelContainer.new()
	_toast_panel.visible = false
	_toast_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_toast_panel.offset_left = -280
	_toast_panel.offset_right = 280
	_toast_panel.offset_top = 48
	_toast_panel.offset_bottom = 96
	_toast_panel.add_theme_stylebox_override("panel", sb)
	_hud_layer.add_child(_toast_panel)
	_toast_lbl = Label.new()
	_toast_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_toast_lbl.add_theme_font_size_override("font_size", 18)
	_toast_lbl.add_theme_color_override("font_color", Color(1.0, 0.96, 0.72))
	_toast_panel.add_child(_toast_lbl)

	# Portal dissolve overlay on higher CanvasLayer
	var portal_layer := CanvasLayer.new()
	portal_layer.layer = 45
	add_child(portal_layer)
	_portal_overlay = ColorRect.new()
	_portal_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_portal_overlay.color = Color(0.06, 0.05, 0.04, 0.0)
	_portal_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portal_overlay.visible = false
	portal_layer.add_child(_portal_overlay)

	# Lightweight FPS Overlay (layer 60 so visible both in gameplay & Settings menu)
	var fps_layer := CanvasLayer.new()
	fps_layer.layer = 60
	add_child(fps_layer)
	_fps_lbl = Label.new()
	_fps_lbl.position = Vector2(18, 14)
	_fps_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fps_lbl.add_theme_font_size_override("font_size", 15)
	_fps_lbl.add_theme_color_override("font_color", Color(0.62, 0.96, 0.54, 0.95))
	_fps_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	_fps_lbl.add_theme_constant_override("shadow_offset_x", 1)
	_fps_lbl.add_theme_constant_override("shadow_offset_y", 1)
	fps_layer.add_child(_fps_lbl)
	ConfigManager.display_changed.connect(_sync_fps_overlay)
	_sync_fps_overlay()


func _build_binoculars() -> void:
	_bino_cam = Camera3D.new()
	_bino_cam.name = "BinocularsCamera"
	_bino_cam.position = Vector3(-20.1, 15.3, 0.0) # Right at West parapet edge overlooking valley, lakes & race track
	_bino_cam.far = 900.0
	add_child(_bino_cam)

	_bino_layer = CanvasLayer.new()
	_bino_layer.layer = 16
	_bino_layer.visible = false
	add_child(_bino_layer)

	_bino_ctrl = Control.new()
	_bino_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bino_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bino_ctrl.draw.connect(_draw_bino_overlay)
	_bino_layer.add_child(_bino_ctrl)


func _draw_bino_overlay() -> void:
	if not is_instance_valid(_bino_ctrl):
		return
	var sz := _bino_ctrl.size
	if sz.x < 10.0 or sz.y < 10.0:
		return
	var cy := sz.y * 0.5
	var r := minf(sz.x * 0.255, sz.y * 0.42)
	var lx := sz.x * 0.5 - r * 0.74
	var rx := sz.x * 0.5 + r * 0.74
	var mask_col := Color(0.01, 0.01, 0.02, 0.95)

	# Smooth crisp twin-circle mask using exact vertical slices (ZERO polygon triangulation bugs!)
	var min_x := int(maxf(floor(lx - r), 0.0))
	var max_x := int(minf(ceil(rx + r), sz.x))
	if min_x > 0:
		_bino_ctrl.draw_rect(Rect2(0, 0, float(min_x), sz.y), mask_col)
	if max_x < int(sz.x):
		_bino_ctrl.draw_rect(Rect2(float(max_x), 0, sz.x - float(max_x), sz.y), mask_col)

	var step_x := 2
	var x := min_x
	while x < max_x:
		var xc := float(x) + 1.0
		var h_l := sqrt(maxf(0.0, r * r - (xc - lx) * (xc - lx)))
		var h_r := sqrt(maxf(0.0, r * r - (xc - rx) * (xc - rx)))
		var h_open := maxf(h_l, h_r)
		var y_top := maxf(0.0, cy - h_open)
		var y_bot := minf(sz.y, cy + h_open)
		if y_top > 0.0:
			_bino_ctrl.draw_rect(Rect2(float(x), 0.0, float(step_x) + 0.5, y_top), mask_col)
		if y_bot < sz.y:
			_bino_ctrl.draw_rect(Rect2(float(x), y_bot, float(step_x) + 0.5, sz.y - y_bot), mask_col)
		x += step_x

	_bino_ctrl.draw_arc(Vector2(lx, cy), r, 0.0, TAU, 64, Color(0.18, 0.20, 0.22), 5.0)
	_bino_ctrl.draw_arc(Vector2(rx, cy), r, 0.0, TAU, 64, Color(0.18, 0.20, 0.22), 5.0)

	# Center optical rangefinder crosshairs
	var mid := sz * 0.5
	_bino_ctrl.draw_line(mid - Vector2(36, 0), mid - Vector2(10, 0), Color(0.32, 0.96, 0.68, 0.85), 1.5)
	_bino_ctrl.draw_line(mid + Vector2(10, 0), mid + Vector2(36, 0), Color(0.32, 0.96, 0.68, 0.85), 1.5)
	_bino_ctrl.draw_line(mid - Vector2(0, 36), mid - Vector2(0, 10), Color(0.32, 0.96, 0.68, 0.85), 1.5)
	_bino_ctrl.draw_line(mid + Vector2(0, 10), mid + Vector2(0, 36), Color(0.32, 0.96, 0.68, 0.85), 1.5)

	var f := ConfigManager.get_ui_font()
	_bino_ctrl.draw_string(f, Vector2(24, sz.y - 26), ConfigManager.t("bino_hud") % _bino_zoom, HORIZONTAL_ALIGNMENT_CENTER, sz.x - 48, 16, Color(0.95, 0.96, 0.82))


func _refresh_quest_ui() -> void:
	if _quests == null:
		return
	if _quest_hud_lbl:
		_quest_hud_lbl.text = _quests.get_hud_summary()
	if _quest_journal_lbl:
		_quest_journal_lbl.text = _quests.format_journal_text()


func _toggle_quest_journal() -> void:
	if _quest_journal_panel == null:
		return
	_quest_journal_panel.visible = not _quest_journal_panel.visible
	_refresh_quest_ui()
	AudioSfx.play_switch()


func _toggle_games_map() -> void:
	if _games_map_panel == null:
		return
	if _games_map_lbl and _world and _world.casino_room:
		_games_map_lbl.text = _world.casino_room.get_games_map_text()
	_games_map_panel.visible = not _games_map_panel.visible
	if _quests and _games_map_panel.visible:
		_quests.record_any("games_map")
	AudioSfx.play_switch()


func _show_toast(msg: String) -> void:
	if _toast_lbl and _toast_panel:
		_toast_lbl.text = msg
		_toast_panel.visible = true
		_toast_t = 3.0


func _sync_fps_overlay() -> void:
	if _fps_lbl == null:
		return
	var on := bool(ConfigManager.display.get("show_fps", false))
	_fps_lbl.visible = on
	if on:
		_fps_lbl.text = ConfigManager.t("fps_overlay") % int(round(Engine.get_frames_per_second()))


func _update_status_hud(_unused: String) -> void:
	if _status_lbl == null or _world == null or _world.weather == null:
		return
	_status_lbl.text = ConfigManager.t("hud_status") % [_world.weather.get_weather_label(), _world.weather.get_time_label()]


func _on_language_changed() -> void:
	if _quest_journal_title:
		_quest_journal_title.text = ConfigManager.t("q_journal_title")
	if _quest_journal_hint:
		_quest_journal_hint.text = ConfigManager.t("q_journal_hint")
	if _games_map_title:
		_games_map_title.text = ConfigManager.t("map_modal_title")
	if _games_map_hint:
		_games_map_hint.text = ConfigManager.t("map_modal_hint")
	if _games_map_lbl and _world and _world.casino_room:
		_games_map_lbl.text = _world.casino_room.get_games_map_text()
	_refresh_quest_ui()
	_sync_fps_overlay()
	_update_status_hud("")
	if _bino_ctrl and _in_binoculars:
		_bino_ctrl.queue_redraw()


func _process(delta: float) -> void:
	if _fps_lbl and _fps_lbl.visible:
		_fps_accum += delta
		if _fps_accum >= 0.25:
			_fps_accum = 0.0
			_fps_lbl.text = ConfigManager.t("fps_overlay") % int(round(Engine.get_frames_per_second()))

	if _toast_t > 0.0:
		_toast_t -= delta
		if _toast_t <= 0.0 and _toast_panel:
			_toast_panel.visible = false

	if _in_binoculars and _bino_cam:
		var pan_spd := delta * (1.2 / maxf(_bino_zoom * 0.45, 1.0))
		if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT): _bino_yaw += pan_spd
		if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT): _bino_yaw -= pan_spd
		if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP): _bino_pitch = clampf(_bino_pitch + pan_spd, -0.95, 0.65)
		if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN): _bino_pitch = clampf(_bino_pitch - pan_spd, -0.95, 0.65)
		_bino_cam.rotation = Vector3(_bino_pitch, _bino_yaw, 0.0)
		_bino_cam.fov = clampf(72.0 / _bino_zoom, 5.0, 38.0)

	if _world and _world.weather and _player:
		var focus_node: Node3D = _race_car if (_is_driving and _race_car) else _player
		var p: Vector3 = focus_node.global_position
		if _is_driving and _race_car:
			var sg_singleton := get_node_or_null("/root/SimpleGrass")
			if sg_singleton:
				sg_singleton.call("set_player_position", p)
		if _quests and _menu and not _menu.visible:
			if not _is_driving and p.y < 4.5 and absf(p.x) < 20.0 and absf(p.z) < 9.0:
				if p.x >= -6.8 and p.x < 5.2:
					_quests.record_step("explorer_basement", "exhibition")
				elif p.x < -6.8 and p.z < 0.0:
					_quests.record_step("explorer_basement", "cellar")
				elif p.x < -6.8 and p.z >= 0.0:
					_quests.record_step("explorer_basement", "vault")
			elif _is_driving and _race_car and _world.race_track:
				if bool(_race_car._airborne):
					_quests.record_step("stunt_driver", "jump")
				var r_sp: Dictionary = _world.race_track.sample_at_s(_race_car._track_s)
				if not r_sp.is_empty() and bool(r_sp.get("is_loop", false)):
					_quests.record_step("stunt_driver", "loop")

		var indoors := 1.0 if (absf(p.x) < 20.5 and absf(p.z) < 9.5 and p.y < 13.0) else 0.0
		var d_w := Vector2(p.x + 68.0, p.z + 28.0).length() - 36.0
		var d_e := Vector2(p.x - 72.0, p.z - 34.0).length() - 40.0
		var d_s := Vector2(p.x - 18.0, p.z - 66.0).length() - 20.0
		var lake_dist := minf(d_w, minf(d_e, d_s))
		var water_prox := clampf(1.0 - maxf(lake_dist, 0.0) / 36.0, 0.0, 1.0)
		var roulette_prox := clampf(1.0 - Vector2(p.x, p.z - 0.2).length() / 6.5, 0.0, 1.0) * indoors
		AudioSfx.set_ambient_state(_world.weather.get_rain_amount(), _world.weather.get_wind_strength(), indoors, water_prox, roulette_prox)

		if _minigame_host and _minigame_host.is_active():
			AudioSfx.set_music_mode("minigame", _active_painting_id)
		elif _menu and _menu.visible:
			AudioSfx.set_music_mode("menu")
		elif indoors > 0.5:
			AudioSfx.set_music_mode("casino")
		else:
			AudioSfx.set_music_mode("forest")


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		var hk := event as InputEventKey
		if hk.pressed and not hk.echo:
			if hk.physical_keycode == KEY_F5:
				if _menu and _menu.is_game_started and not _transitioning:
					get_viewport().set_input_as_handled()
					quick_save()
				return
			elif hk.physical_keycode == KEY_F9:
				if not _transitioning:
					get_viewport().set_input_as_handled()
					quick_load()
				return

	if _is_driving:
		return

	if _in_binoculars:
		if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			var mm := event as InputEventMouseMotion
			var sens := 0.0022 * (72.0 / maxf(_bino_zoom * 72.0 * 0.25, 14.0))
			_bino_yaw -= mm.relative.x * sens
			_bino_pitch = clampf(_bino_pitch - mm.relative.y * sens, -0.95, 0.65)
		elif event is InputEventMouseButton:
			var mb := event as InputEventMouseButton
			if mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_UP:
				_bino_zoom = clampf(_bino_zoom + 1.0, 2.0, 14.0)
				_bino_ctrl.queue_redraw()
			elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				_bino_zoom = clampf(_bino_zoom - 1.0, 2.0, 14.0)
				_bino_ctrl.queue_redraw()
		elif event is InputEventKey:
			var bk := event as InputEventKey
			if bk.pressed and not bk.echo:
				if bk.physical_keycode == KEY_ESCAPE or bk.physical_keycode == KEY_E:
					get_viewport().set_input_as_handled()
					_exit_binoculars()
				elif bk.physical_keycode == KEY_EQUAL or bk.physical_keycode == KEY_KP_ADD:
					_bino_zoom = clampf(_bino_zoom + 1.5, 2.0, 14.0); _bino_ctrl.queue_redraw()
				elif bk.physical_keycode == KEY_MINUS or bk.physical_keycode == KEY_KP_SUBTRACT:
					_bino_zoom = clampf(_bino_zoom - 1.5, 2.0, 14.0); _bino_ctrl.queue_redraw()
		return

	if _in_roulette:
		if not _transitioning and _roulette_ui and event is InputEventKey:
			var rk := event as InputEventKey
			if rk.pressed and not rk.echo and _roulette_ui.handle_key(rk.physical_keycode):
				get_viewport().set_input_as_handled()
		return

	if event is InputEventKey:
		var k := event as InputEventKey
		if k.pressed and not k.echo and _games_map_panel and _games_map_panel.visible:
			if k.physical_keycode == KEY_ESCAPE or k.physical_keycode == KEY_E or k.physical_keycode == KEY_TAB:
				get_viewport().set_input_as_handled()
				_toggle_games_map()
				return
		if k.pressed and not k.echo and _quest_journal_panel and _quest_journal_panel.visible:
			if k.physical_keycode == KEY_ESCAPE or k.physical_keycode == KEY_Q or k.physical_keycode == KEY_E:
				get_viewport().set_input_as_handled()
				_toggle_quest_journal()
				return
		if k.pressed and not k.echo and k.physical_keycode == KEY_Q:
			if _minigame_host.is_active() or _transitioning or (_menu and _menu.visible):
				return
			get_viewport().set_input_as_handled()
			_toggle_quest_journal()
		elif k.pressed and not k.echo and k.physical_keycode == KEY_ESCAPE:
			if _minigame_host.is_active() or _transitioning:
				return
			if _quest_journal_panel and _quest_journal_panel.visible:
				get_viewport().set_input_as_handled()
				_toggle_quest_journal()
				return
			if _menu.visible:
				if _menu.is_game_started:
					get_viewport().set_input_as_handled()
					_menu.close_menu()
					_on_resume_requested()
			else:
				get_viewport().set_input_as_handled()
				_pause_to_menu()


func _set_world_paused(paused: bool) -> void:
	if get_tree():
		get_tree().paused = paused


func _on_menu_visibility_changed() -> void:
	if _menu == null or get_tree() == null:
		return
	if not _menu.visible:
		_set_world_paused(false)
	elif _menu.is_game_started:
		_set_world_paused(true)


func _pause_to_menu() -> void:
	_player.set_controls_active(false)
	_prompt_panel.visible = false
	_status_lbl.visible = false
	if _quest_hud_panel: _quest_hud_panel.visible = false
	if _quest_journal_panel: _quest_journal_panel.visible = false
	if _games_map_panel: _games_map_panel.visible = false
	_menu.open_menu()
	_set_world_paused(true)


func _abort_active_modes() -> void:
	if _minigame_host and _minigame_host.is_active():
		_minigame_host.close_game()
	if _world and _world.casino_room and _active_painting_id != "":
		_world.casino_room.set_painting_transition(_active_painting_id, 0.0, 2.2)
	_active_painting_id = ""
	if _portal_overlay:
		_portal_overlay.visible = false
	if _in_roulette:
		_in_roulette = false
		if _roulette_ui:
			_roulette_ui.close_overlay()
		if _roulette_cam:
			_roulette_cam.current = false
		if _world and _world.casino_room:
			_world.casino_room.update_roulette_chips({})
		_active_roulette_bets.clear()
	if _in_binoculars:
		_in_binoculars = false
		if _bino_layer:
			_bino_layer.visible = false
		if _bino_cam:
			_bino_cam.current = false
	if _quest_journal_panel:
		_quest_journal_panel.visible = false
	if _games_map_panel:
		_games_map_panel.visible = false


func quick_save() -> bool:
	if _transitioning or _menu == null or not _menu.is_game_started:
		return false
	var race_st: Dictionary = _race_car.get_save_state()
	if _world and _world.race_track:
		race_st.merge(_world.race_track.get_save_state(), true)
	race_st["is_driving"] = _is_driving
	var world_st: Dictionary = _world.weather.get_save_state() if (_world and _world.weather) else {}
	if _world and _world.ferris_wheel:
		world_st["ferris_angle"] = _world.ferris_wheel.get_save_angle()
	if _world and _world.casino_room:
		world_st["disco_mode"] = _world.casino_room.is_disco_enabled()
	var payload := {
		"player": _player.get_save_state(),
		"race": race_st,
		"world": world_st,
		"quests": _quests.get_save_state() if _quests else {}
	}
	if ConfigManager.save_game_state(payload) == OK:
		AudioSfx.play_ui_click()
		_show_toast(ConfigManager.t("toast_saved"))
		return true
	return false


func quick_load() -> bool:
	if _transitioning or not ConfigManager.has_save():
		_show_toast(ConfigManager.t("toast_no_save"))
		return false
	var st := ConfigManager.load_game_state()
	if st.is_empty():
		_show_toast(ConfigManager.t("toast_no_save"))
		return false

	if is_instance_valid(_intro):
		_intro.skip(true)
	_abort_active_modes()
	if _menu:
		_menu.close_menu()
		_menu.set_game_started(true)

	var world_st: Dictionary = st.get("world", {}) as Dictionary
	if _world:
		if _world.ferris_wheel and world_st.has("ferris_angle"):
			_world.ferris_wheel.set_save_angle(float(world_st["ferris_angle"]))
		if _world.casino_room and world_st.has("disco_mode"):
			_world.casino_room.set_disco_enabled(bool(world_st["disco_mode"]))
		if _world.weather:
			_world.weather.apply_save_state(world_st)
	if _quests:
		_quests.apply_save_state(st.get("quests", {}) as Dictionary)

	_player.apply_save_state(st.get("player", {}) as Dictionary)
	var race_st: Dictionary = st.get("race", {}) as Dictionary
	if _world and _world.race_track:
		_world.race_track.apply_save_state(race_st)

	var want_driving := bool(race_st.get("is_driving", false))
	if want_driving and _race_car:
		_is_driving = true
		_player.set_controls_active(false)
		_prompt_panel.visible = false
		_race_hud_lbl.visible = true
		_race_car.apply_save_state(race_st)
		if _world:
			_world.set_world_focus(_race_car, true)
	else:
		if _is_driving and _race_car:
			_is_driving = false
			_race_car.stop_race()
			_race_hud_lbl.visible = false
			if _race_banner_panel:
				_race_banner_panel.visible = false
		_player.get_camera().current = true
		if _world:
			_world.set_world_focus(_player, true)
		_player.set_controls_active(true)
		if DisplayServer.get_name() == "headless":
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if _world and _world.weather:
		_world.weather._process(0.016)
	_set_world_paused(false)
	_status_lbl.visible = false
	if _quest_hud_panel:
		_quest_hud_panel.visible = false
	_update_status_hud("")
	_refresh_quest_ui()
	AudioSfx.play_switch()
	_show_toast(ConfigManager.t("toast_loaded"))
	return true


func _on_new_game_requested() -> void:
	if is_instance_valid(_intro):
		_intro.skip(true)
	_abort_active_modes()
	if _is_driving and _race_car:
		_is_driving = false
		_race_car.stop_race()
		_race_hud_lbl.visible = false
		if _race_banner_panel:
			_race_banner_panel.visible = false
	if _quests:
		_quests.apply_save_state({})
	if _world and _world.casino_room:
		_world.casino_room.set_disco_enabled(false)
	_menu.close_menu()
	_menu.set_game_started(true)
	_set_world_paused(false)
	_player.reset_to_casino_spawn()
	_player.get_camera().current = true
	if _world:
		_world.set_world_focus(_player, true)
		if _world.weather:
			_world.weather._process(0.016)
	_player.set_controls_active(true)
	_status_lbl.visible = false
	if _quest_hud_panel: _quest_hud_panel.visible = false


func _on_resume_requested() -> void:
	_set_world_paused(false)
	if _is_driving and _race_car:
		_race_car._cam.current = true
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		_player.get_camera().current = true
		_player.set_controls_active(true)
	_status_lbl.visible = false
	if _quest_hud_panel: _quest_hud_panel.visible = false


func _on_weather_changed(mode: int) -> void:
	if _world and _world.weather:
		_world.weather.set_weather_mode(mode)
		_world.weather._process(0.016)
		_update_status_hud("")


func _on_time_settings_changed() -> void:
	if _world and _world.weather:
		_world.weather.apply_time_settings()
		_world.weather._process(0.016)
		_update_status_hud("")


func _on_target_painting_changed(painting_id: String, title: String) -> void:
	if painting_id == "" or not _player.controls_enabled:
		if _player._targeted_prop_id == "":
			_prompt_panel.visible = false
	else:
		_prompt_lbl.text = ConfigManager.t("hud_prompt_paint") % ConfigManager.t("g_" + painting_id, title)
		_prompt_panel.visible = true


func _on_target_prop_changed(prop_id: String, title: String) -> void:
	if prop_id == "" or not _player.controls_enabled:
		if _player._targeted_painting_id == "":
			_prompt_panel.visible = false
	else:
		_prompt_lbl.text = ConfigManager.t("hud_prompt_prop") % ConfigManager.t("prop_" + prop_id, title)
		_prompt_panel.visible = true


func _enter_binoculars() -> void:
	_in_binoculars = true
	_bino_yaw = 1.25
	_bino_pitch = -0.10
	_bino_zoom = 4.0
	_player.set_controls_active(false)
	_prompt_panel.visible = false
	_status_lbl.visible = false
	_bino_cam.current = true
	_bino_layer.visible = true
	_bino_ctrl.queue_redraw()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	AudioSfx.play_switch()


func _exit_binoculars() -> void:
	_in_binoculars = false
	_bino_layer.visible = false
	_bino_cam.current = false
	_player.get_camera().current = true
	_player.set_controls_active(true)
	_status_lbl.visible = false
	if _quest_hud_panel:
		_quest_hud_panel.visible = false
	AudioSfx.play_switch()


func _start_race() -> void:
	if _is_driving or _race_car == null:
		return
	_is_driving = true
	_player.set_controls_active(false)
	_prompt_panel.visible = false
	_race_hud_lbl.visible = true
	_race_car.start_race()
	_race_car.reset_physics_interpolation()
	if _world:
		_world.set_world_focus(_race_car, true)


func _exit_race() -> void:
	if not _is_driving:
		return
	_is_driving = false
	_race_car.stop_race()
	_race_hud_lbl.visible = false
	if _race_banner_panel:
		_race_banner_panel.visible = false
	_player.global_position = Vector3(-16.0, 6.45, 63.5)
	_player.velocity = Vector3.ZERO
	_player.reset_physics_interpolation()
	_player.get_camera().reset_physics_interpolation()
	_player.get_camera().current = true
	if _world:
		_world.set_world_focus(_player, true)
		if _world.weather:
			_world.weather._process(0.016)
	_player.set_controls_active(true)
	_show_toast(ConfigManager.t("toast_parked"))


func _on_race_banner_updated(text: String, color: Color, show: bool) -> void:
	if _race_banner_panel == null or _race_banner_lbl == null:
		return
	_race_banner_panel.visible = show and _is_driving
	_race_banner_lbl.text = text
	_race_banner_lbl.add_theme_color_override("font_color", color)
	_race_banner_lbl.add_theme_font_size_override("font_size", 46 if text.length() <= 5 else 24)


func _on_race_completed(rank: int, _race_time: float) -> void:
	if _quests:
		var bonus := 250 if rank == 1 else (150 if rank <= 3 else 75)
		_quests.add_chips(bonus)
		_show_toast(ConfigManager.t("toast_race_done") % [rank, bonus])


func _on_interact_prop_requested(prop_id: String) -> void:
	if _transitioning or _minigame_host.is_active():
		return
	match prop_id:
		"race_start":
			_start_race()
		"binoculars":
			if _quests: _quests.record_any("binoculars")
			_enter_binoculars()
		"quest_board":
			_toggle_quest_journal()
		"vault_safe":
			if _quests:
				if _quests.record_step("vault_heist", "vault_safe"):
					_quests.add_chips(80)
					_show_toast(ConfigManager.t("toast_vault_new"))
				else:
					_show_toast(ConfigManager.t("toast_vault_empty"))
			AudioSfx.play_coin()
		"relic_cup":
			if _quests: _quests.record_any("relic_cup")
			_show_toast(ConfigManager.t("toast_relic_cup"))
			AudioSfx.play_coin()
		"relic_amphora":
			if _quests: _quests.record_any("relic_amphora")
			_show_toast(ConfigManager.t("toast_relic_amphora"))
			AudioSfx.play_coin()
		"relic_sapphire":
			if _quests: _quests.record_any("relic_sapphire")
			_show_toast(ConfigManager.t("toast_relic_sapphire"))
			AudioSfx.play_coin()
		"slot_left":
			if _world and _world.casino_room:
				_show_toast(_world.casino_room.trigger_slot(0))
		"slot_right":
			if _world and _world.casino_room:
				_show_toast(_world.casino_room.trigger_slot(1))
		"games_map":
			_toggle_games_map()
		"roulette_spin":
			_enter_roulette_game()
		"disco_button":
			if _world and _world.casino_room:
				var on := _world.casino_room.toggle_disco()
				if _quests: _quests.record_any("disco_button")
				_show_toast(ConfigManager.t("toast_disco_on" if on else "toast_disco_off"))
		"duck_horn":
			AudioSfx.play_duck_call(-0.5)
			AudioSfx.play_duck_call(0.5)
			_show_toast(ConfigManager.t("toast_duck"))
		"bounce_shroom":
			_player.velocity.y = 21.5
			if _quests: _quests.record_any("bounce_shroom")
			AudioSfx.play_boing_launch()
			_show_toast(ConfigManager.t("toast_shroom"))
		"weather_altar":
			if _world and _world.weather:
				var cur_mode := int(ConfigManager.graphics.get("weather_mode", 0))
				var next_mode := (cur_mode + 1) % 6
				if next_mode == 0:
					next_mode = 1
				ConfigManager.graphics["weather_mode"] = next_mode
				_world.weather.set_weather_mode(next_mode)
				_update_status_hud("")
				if _quests: _quests.record_any("weather_altar")
				AudioSfx.play_powerup()
				_show_toast(ConfigManager.t("toast_altar") % _world.weather.get_weather_label())


func _on_interact_painting_requested(painting_id: String) -> void:
	if _transitioning or _minigame_host.is_active() or not _world or not _world.casino_room:
		return
	var info := _world.casino_room.get_painting_by_id(painting_id)
	if info.is_empty():
		return

	if _quests:
		_quests.record_any(painting_id)

	_transitioning = true
	_active_painting_id = painting_id
	_player.set_controls_active(false)
	_prompt_panel.visible = false
	_status_lbl.visible = false

	AudioSfx.play_portal_dive()

	var cam := _player.get_camera()
	_saved_cam_tf = cam.global_transform
	var p_node: Node3D = info["node"]
	var target_pos := p_node.to_global(Vector3(0.0, 0.0, 0.36))
	var target_basis := p_node.global_transform.basis
	var target_tf := Transform3D(target_basis, target_pos)

	_portal_overlay.visible = true
	_portal_overlay.color = Color(0.08, 0.06, 0.03, 0.0)

	var tw := create_tween()
	tw.set_parallel(true)
	tw.set_trans(Tween.TRANS_CUBIC)
	tw.set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(cam, "global_transform", target_tf, 0.62)
	tw.tween_property(cam, "fov", 38.0, 0.62)
	tw.tween_method(func(v: float):
		if _world and _world.casino_room:
			_world.casino_room.set_painting_transition(painting_id, v, (1.0 - v) * 2.2)
	, 0.0, 1.0, 0.45)
	tw.tween_property(_portal_overlay, "color:a", 1.0, 0.26).set_delay(0.36)
	await tw.finished

	_minigame_host.open_game(painting_id)
	var fade_out := create_tween()
	fade_out.tween_property(_portal_overlay, "color:a", 0.0, 0.28)
	await fade_out.finished
	_portal_overlay.visible = false
	_transitioning = false


func _on_minigame_exit_requested() -> void:
	if _transitioning or not _minigame_host.is_active():
		return
	_transitioning = true
	AudioSfx.play_portal_exit()

	_portal_overlay.visible = true
	_portal_overlay.color = Color(0.08, 0.06, 0.03, 0.0)
	var fade_in := create_tween()
	fade_in.tween_property(_portal_overlay, "color:a", 1.0, 0.20)
	await fade_in.finished

	_minigame_host.close_game()
	if _world and _world.casino_room and _active_painting_id != "":
		_world.casino_room.set_painting_transition(_active_painting_id, 0.0, 2.2)

	var cam := _player.get_camera()
	var tw := create_tween()
	tw.set_parallel(true)
	tw.set_trans(Tween.TRANS_CUBIC)
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(cam, "global_transform", _saved_cam_tf, 0.45)
	tw.tween_property(cam, "fov", 74.0, 0.45)
	tw.tween_property(_portal_overlay, "color:a", 0.0, 0.42)
	await tw.finished

	_portal_overlay.visible = false
	_transitioning = false
	_player.set_controls_active(true)
	_status_lbl.visible = false
	if _quest_hud_panel:
		_quest_hud_panel.visible = false


func _on_slot_payout(chips_won: int, msg: String) -> void:
	if _quests:
		_quests.record_any("slot_left")
		if chips_won > 0:
			_quests.add_chips(chips_won)
	_show_toast(msg)


func _enter_roulette_game() -> void:
	if _transitioning or _in_roulette or _minigame_host.is_active() or _in_binoculars or _is_driving:
		return
	if _world == null or _world.casino_room == null:
		return
	var table := _world.casino_room.get_roulette_table()
	if table == null:
		return
	_transitioning = true
	_player.set_controls_active(false)
	_prompt_panel.visible = false
	_status_lbl.visible = false
	if _quest_hud_panel:
		_quest_hud_panel.visible = false
	if _games_map_panel:
		_games_map_panel.visible = false
	if _quests:
		_quests.record_any("roulette_spin")
		if int(_quests.chips) < 50:
			var bonus: int = 200 - int(_quests.chips)
			_quests.add_chips(bonus)
			_show_toast(ConfigManager.t("toast_welcome_chips") % bonus)

	var p_cam := _player.get_camera()
	var table_center := table.global_position
	var view_pos := table_center + Vector3(0.0, 2.35, 2.25)
	var look_basis := Transform3D(Basis.IDENTITY, view_pos).looking_at(table_center + Vector3(0.0, 1.08, -0.06), Vector3.UP).basis
	var target_tf := Transform3D(look_basis, view_pos)

	_roulette_cam.global_transform = p_cam.global_transform
	_roulette_cam.fov = p_cam.fov
	_roulette_cam.current = true
	AudioSfx.play_switch()

	var tw := create_tween()
	tw.set_parallel(true)
	tw.set_trans(Tween.TRANS_CUBIC)
	tw.set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(_roulette_cam, "global_transform", target_tf, 0.45)
	tw.tween_property(_roulette_cam, "fov", 52.0, 0.45)
	await tw.finished

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_in_roulette = true
	_transitioning = false
	_active_roulette_bets.clear()
	_world.casino_room.update_roulette_chips({})
	if _roulette_ui:
		_roulette_ui.open(_quests.chips if _quests else 200)


func _on_roulette_bet_placed(_total_bet: int) -> void:
	if _world and _world.casino_room and _roulette_ui:
		_world.casino_room.update_roulette_chips(_roulette_ui._bets)


func _on_roulette_spin_requested(bets: Dictionary) -> void:
	if _world == null or _world.casino_room == null:
		return
	var staked := 0
	for k in bets.keys():
		staked += int(bets[k])
	if staked <= 0:
		return
	if _quests:
		_quests.add_chips(-staked)
	_active_roulette_bets = bets.duplicate()
	_world.casino_room.update_roulette_chips(_active_roulette_bets)
	_world.casino_room.start_roulette_spin()


func _on_roulette_spin_finished(win_num: int) -> void:
	var won: int = RouletteOverlayScript.compute_payout(_active_roulette_bets, win_num)
	if won > 0 and _quests:
		_quests.add_chips(won)
	if won >= 250:
		AudioSfx.play_fanfare()
	elif won > 0:
		AudioSfx.play_coin()
	else:
		AudioSfx.play_brick_bump()
	if _world and _world.casino_room:
		_world.casino_room.update_roulette_chips({})
	if _roulette_ui and _in_roulette:
		_roulette_ui.on_spin_result(win_num, won, _quests.chips if _quests else 0)
	_active_roulette_bets.clear()
	if won > 0:
		_show_toast(ConfigManager.t("toast_roulette_win", "🎡 %s — +%d!") % [RouletteOverlayScript.pocket_color_tag(win_num), won])


func _exit_roulette_game() -> void:
	if _transitioning or not _in_roulette:
		return
	if _world and _world.casino_room and _world.casino_room.is_roulette_spinning():
		return
	_transitioning = true
	if _roulette_ui:
		_roulette_ui.close_overlay()
	AudioSfx.play_switch()
	var p_cam := _player.get_camera()
	var tw := create_tween()
	tw.set_parallel(true)
	tw.set_trans(Tween.TRANS_CUBIC)
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(_roulette_cam, "global_transform", p_cam.global_transform, 0.35)
	tw.tween_property(_roulette_cam, "fov", 74.0, 0.35)
	await tw.finished
	p_cam.current = true
	_in_roulette = false
	_transitioning = false
	_player.set_controls_active(true)
	_status_lbl.visible = false
	if _quest_hud_panel:
		_quest_hud_panel.visible = false
