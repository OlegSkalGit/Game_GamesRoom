class_name MinigameHost
extends CanvasLayer

signal exit_requested

const GAME_SCRIPTS: Dictionary = {
	"mario": "res://scripts/minigames/games/game_mario.gd",
	"tetris": "res://scripts/minigames/games/game_tetris.gd",
	"snake": "res://scripts/minigames/games/game_snake.gd",
	"bomberman": "res://scripts/minigames/games/game_bomberman.gd",
	"soccer": "res://scripts/minigames/games/game_soccer.gd",
	"arkanoid": "res://scripts/minigames/games/game_arkanoid.gd",
	"arcade": "res://scripts/minigames/games/game_space_arcade.gd",
	"pacman": "res://scripts/minigames/games/game_pacman.gd",
	"tanks": "res://scripts/minigames/games/game_tanks.gd",
	"chess": "res://scripts/minigames/games/game_chess.gd",
	"checkers": "res://scripts/minigames/games/game_checkers.gd",
	"corners": "res://scripts/minigames/games/game_corners.gd",
	"battleship": "res://scripts/minigames/games/game_battleship.gd",
	"durak": "res://scripts/minigames/games/game_durak.gd",
	"blackjack": "res://scripts/minigames/games/game_blackjack.gd",
	"poker": "res://scripts/minigames/games/game_poker.gd",
	"2048": "res://scripts/minigames/games/game_2048.gd",
	"zuma": "res://scripts/minigames/games/game_zuma.gd",
	"puzzle": "res://scripts/minigames/games/game_puzzle.gd",
	"match3": "res://scripts/minigames/games/game_match3.gd",
	"minesweeper": "res://scripts/minigames/games/game_minesweeper.gd",
	"solitaire": "res://scripts/minigames/games/game_solitaire.gd",
	"flappy": "res://scripts/minigames/games/game_flappy.gd",
	"sudoku": "res://scripts/minigames/games/game_sudoku.gd",
	"python3d": "res://scripts/minigames/games/game_python3d.gd",
	"hexa": "res://scripts/minigames/games/game_hexa.gd",
	"sokoban": "res://scripts/minigames/games/game_sokoban.gd",
	"fifteen": "res://scripts/minigames/games/game_fifteen.gd",
	"pong": "res://scripts/minigames/games/game_pong.gd",
	"memory": "res://scripts/minigames/games/game_memory.gd",
	"codelock": "res://scripts/minigames/games/game_codelock.gd",
	"bullscows": "res://scripts/minigames/games/game_bullscows.gd",
	"tictactoe": "res://scripts/minigames/games/game_tictactoe.gd",
	"balda": "res://scripts/minigames/games/game_balda.gd"
}

var _root_panel: ColorRect
var _title_lbl: Label
var _score_lbl: Label
var _hint_lbl: Label
var _btn_restart: Button
var _btn_exit: Button
var _viewport_container: SubViewportContainer
var _subviewport: SubViewport
var _active_game: MinigameBase


func _ready() -> void:
	layer = 40
	visible = false
	_build_ui()


func _build_ui() -> void:
	_root_panel = ColorRect.new()
	_root_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root_panel.color = Color(0.03, 0.04, 0.05, 0.98)
	add_child(_root_panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 8)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	_root_panel.add_child(margin)
	margin.add_child(vbox)

	# Top Bar
	var top_bar := HBoxContainer.new()
	top_bar.add_theme_constant_override("separation", 18)
	vbox.add_child(top_bar)

	_title_lbl = Label.new()
	_title_lbl.add_theme_font_size_override("font_size", 26)
	_title_lbl.add_theme_color_override("font_color", Color(0.97, 0.82, 0.36))
	top_bar.add_child(_title_lbl)

	_score_lbl = Label.new()
	_score_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_score_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_score_lbl.add_theme_font_size_override("font_size", 22)
	_score_lbl.add_theme_color_override("font_color", Color(0.90, 0.96, 0.90))
	top_bar.add_child(_score_lbl)

	_btn_restart = Button.new()
	_btn_restart.text = "Заново (R)"
	_btn_restart.add_theme_font_size_override("font_size", 16)
	_btn_restart.pressed.connect(func():
		AudioSfx.play_ui_click()
		if _active_game:
			_active_game.reset_game()
	)
	top_bar.add_child(_btn_restart)

	_btn_exit = Button.new()
	_btn_exit.text = "Вийти (Esc)"
	_btn_exit.add_theme_font_size_override("font_size", 16)
	var exit_sb := StyleBoxFlat.new()
	exit_sb.bg_color = Color(0.55, 0.14, 0.14)
	exit_sb.border_color = Color(0.95, 0.45, 0.40)
	exit_sb.set_border_width_all(1)
	exit_sb.set_corner_radius_all(6)
	exit_sb.content_margin_left = 14; exit_sb.content_margin_right = 14
	exit_sb.content_margin_top = 8; exit_sb.content_margin_bottom = 8
	_btn_exit.add_theme_stylebox_override("normal", exit_sb)
	_btn_exit.pressed.connect(func():
		AudioSfx.play_ui_click()
		exit_requested.emit()
	)
	top_bar.add_child(_btn_exit)

	# Frame container maintaining crisp 16:10 canvas inside ornate golden border
	var aspect := AspectRatioContainer.new()
	aspect.ratio = 1.6
	aspect.size_flags_vertical = Control.SIZE_EXPAND_FILL
	aspect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(aspect)

	var frame_panel := PanelContainer.new()
	var frame_sb := StyleBoxFlat.new()
	frame_sb.bg_color = Color(0.02, 0.02, 0.03)
	frame_sb.border_color = Color(0.88, 0.70, 0.28)
	frame_sb.set_border_width_all(6)
	frame_sb.set_corner_radius_all(8)
	frame_panel.add_theme_stylebox_override("panel", frame_sb)
	aspect.add_child(frame_panel)

	_viewport_container = SubViewportContainer.new()
	_viewport_container.stretch = true
	_viewport_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_viewport_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_viewport_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var reveal_mat := ShaderMaterial.new()
	reveal_mat.shader = load("res://shaders/minigame_reveal.gdshader") as Shader
	reveal_mat.set_shader_parameter("reveal", 1.0)
	_viewport_container.material = reveal_mat
	frame_panel.add_child(_viewport_container)

	_subviewport = SubViewport.new()
	_subviewport.size = Vector2i(640, 400)
	_subviewport.size_2d_override = Vector2i(640, 400)
	_subviewport.size_2d_override_stretch = true
	_subviewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	_viewport_container.add_child(_subviewport)

	_hint_lbl = Label.new()
	_hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_lbl.add_theme_font_size_override("font_size", 15)
	_hint_lbl.add_theme_color_override("font_color", Color(0.75, 0.80, 0.77))
	vbox.add_child(_hint_lbl)


func open_game(game_id: String) -> bool:
	if not GAME_SCRIPTS.has(game_id):
		return false
	close_game()

	var script_res := load(str(GAME_SCRIPTS[game_id])) as GDScript
	if script_res == null:
		return false
	var inst := script_res.new() as MinigameBase
	if inst == null:
		return false

	_active_game = inst
	_active_game.custom_minimum_size = MinigameBase.CANVAS_SIZE
	_active_game.size = MinigameBase.CANVAS_SIZE
	_subviewport.add_child(_active_game)
	_active_game.score_changed.connect(func(s: int): _score_lbl.text = "Рахунок: %d" % s)
	_active_game.status_changed.connect(func(t: String):
		if t != "":
			_score_lbl.text = "Рахунок: %d  |  %s" % [_active_game.score, t]
	)
	_active_game.reset_game()

	_title_lbl.text = "Картина: «%s»" % _active_game.get_game_title()
	_score_lbl.text = "Рахунок: 0"
	_hint_lbl.text = _active_game.get_controls_hint()

	visible = true
	_root_panel.modulate.a = 1.0
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if _viewport_container.material is ShaderMaterial:
		var rm := _viewport_container.material as ShaderMaterial
		rm.set_shader_parameter("reveal", 0.25)
		var tw := create_tween()
		tw.tween_method(func(v: float): rm.set_shader_parameter("reveal", v), 0.25, 1.0, 0.55)
	return true


func close_game() -> void:
	if _active_game:
		_active_game.queue_free()
		_active_game = null
	visible = false


func is_active() -> bool:
	return visible and _active_game != null


func get_active_game() -> MinigameBase:
	return _active_game


func _input(event: InputEvent) -> void:
	if not is_active():
		return
	if event is InputEventKey:
		var k := event as InputEventKey
		if k.pressed and not k.echo and k.physical_keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			exit_requested.emit()
			return
	elif event is InputEventMouse:
		var rect := _viewport_container.get_global_rect()
		if rect.size.x > 0.0 and rect.size.y > 0.0:
			var mpos := (event as InputEventMouse).position
			var is_release := (event is InputEventMouseButton and not (event as InputEventMouseButton).pressed)
			if rect.has_point(mpos) or is_release or (event is InputEventMouseMotion):
				var mev := event.duplicate() as InputEventMouse
				var scaled := (mpos - rect.position) / rect.size * MinigameBase.CANVAS_SIZE
				mev.position = Vector2(clampf(scaled.x, 0.0, MinigameBase.CANVAS_SIZE.x), clampf(scaled.y, 0.0, MinigameBase.CANVAS_SIZE.y))
				_active_game.handle_input_event(mev)
		return
	_active_game.handle_input_event(event)


func _process(delta: float) -> void:
	if is_active():
		_active_game.step_game(delta)
