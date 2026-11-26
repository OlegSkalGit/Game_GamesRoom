extends Node

# Automated headless self-check verifying:
# 1. ConfigManager reads/writes game/config.cfg & presets 0..5 + display settings
# 2. WorldBuilder initializes Sky3D + Terrain3D + Lakes + Dense Vegetation + Wildlife + CasinoRoom
# 3. CasinoRoom has exactly 9 paintings, each opens cleanly in MinigameHost
# 4. Physical KEY_E interaction works regardless of Shift modifier
# 5. All 9 classic mini-games load, step, handle input, and clean up without errors

func _ready() -> void:
	await get_tree().process_frame
	_run_checks()


func _check(cond: bool, msg: String) -> bool:
	if not cond:
		push_error("[FAIL] " + msg)
		print("[FAIL] " + msg)
		get_tree().quit(1)
		return false
	return true


func _run_checks() -> void:
	print("=== SELF CHECK START ===")

	# 1. ConfigManager & game/config.cfg root check
	var cfg_path := ConfigManager.get_config_path()
	if not _check(cfg_path.ends_with("game/config.cfg") or cfg_path.ends_with("game\\config.cfg"), "Config must live in game/ root: " + cfg_path): return
	for preset_idx in range(ConfigManager.PRESET_NAMES.size()):
		ConfigManager.apply_preset(preset_idx)
		if not _check(int(ConfigManager.graphics["preset"]) == preset_idx, "Preset mismatch"): return
	ConfigManager.apply_preset(3)
	if not _check(FileAccess.file_exists(cfg_path), "config.cfg was not saved to game/ root"): return
	print("[PASS] ConfigManager presets & game/config.cfg")

	# 2. Load Main scene cleanly
	var main_scene := load("res://scenes/main.tscn") as PackedScene
	if not _check(main_scene != null, "Failed to load res://scenes/main.tscn"): return
	var main := main_scene.instantiate()
	get_tree().root.add_child(main)
	await get_tree().process_frame
	await get_tree().process_frame

	var world: WorldBuilder = main.get_node("WorldBuilder")
	var player: PlayerController = main.get_node("Player")
	var menu: CanvasLayer = main.get_node("MainMenu")
	var host: MinigameHost = main.get_node("MinigameHost")

	if not _check(world != null and world.sky3d != null, "Sky3D missing"): return
	if not _check(world.terrain != null and world.terrain.data != null, "Terrain3D missing"): return
	if not _check(world.casino_room != null, "CasinoRoom missing"): return
	if not _check(world.weather != null, "WeatherController missing"): return
	if not _check(world.wildlife != null, "WildlifeController missing"): return
	if not _check(world.race_track != null and world.race_track.rivals.size() == 3, "MountainRaceTrack or AI rivals missing"): return
	if not _check(menu.visible == true, "Menu must be open on first start"): return
	var intro = main.get_node_or_null("IntroSplash")
	if not _check(intro != null and intro.is_playing(), "IntroSplash missing on startup"): return
	intro.skip(false)
	await get_tree().create_timer(0.4).timeout
	if not _check(main.get_node_or_null("IntroSplash") == null, "IntroSplash did not skip cleanly"): return
	menu._open_subtab("display")
	if not _check(menu._sub_panel.visible and menu._active_tab == "display", "Settings Display tab failed"): return
	menu._open_subtab("graphics")
	if not _check(menu._sub_panel.visible and menu._active_tab == "graphics", "Settings Graphics tab failed"): return
	menu._toggle_settings_panel()
	if not _check(not menu._sub_panel.visible, "Settings panel toggle close failed"): return

	# Check Terrain3D height at South entrance plaza & lake depressions (basement spans under interior)
	var plaza_h := world.sample_height(0.0, 11.5)
	var lake1_h := world.sample_height(-68.0, -28.0)
	var lake2_h := world.sample_height(72.0, 34.0)
	if not _check(absf(plaza_h - 6.0) < 0.15, "South entrance plaza should be ~6.0m, got %s" % plaza_h): return
	if not _check(lake1_h < WorldBuilder.WATER_LEVEL - 0.5, "Lake 1 must dip below water level"): return
	if not _check(lake2_h < WorldBuilder.WATER_LEVEL - 0.5, "Lake 2 must dip below water level"): return
	var t3d_h := world.terrain.data.get_height(Vector3(0.0, 0.0, 11.5))
	if not _check(absf(t3d_h - 6.0) < 0.35, "Terrain3D imported height mismatch: %s" % t3d_h): return
	print("[PASS] WorldBuilder (Sky3D, Terrain3D, Lakes, Weather, Wildlife)")

	# 3. Verify all unique games & exhibition tripods (including Basement Card Club, Exhibition Hall, Cellar & Vault)
	if not _check(world.casino_room.paintings.size() == CasinoRoom.PAINTING_SPECS.size(), "Expected %d paintings/tripods, got %d" % [CasinoRoom.PAINTING_SPECS.size(), world.casino_room.paintings.size()]): return
	for gid_key: String in MinigameHost.GAME_SCRIPTS.keys():
		if not _check(not world.casino_room.get_painting_by_id(gid_key).is_empty(), "Missing painting/tripod for game: " + gid_key): return
	if not _check(world.casino_room.get_node_or_null("StairRampCollider") != null, "Basement stair ramp missing"): return
	if not _check(world.casino_room.get_node_or_null("MansardStairRampCollider") != null, "Mansard stair ramp missing"): return
	for i_sl in range(3):
		if not _check(world.casino_room.get_node_or_null("RoofSearchlight_" + str(i_sl)) != null, "Searchlight missing"): return

	for gid_key: String in MinigameHost.GAME_SCRIPTS.keys():
		var ok := host.open_game(gid_key)
		if not _check(ok, "Failed to open minigame: " + gid_key): return
		var g := host.get_active_game()
		if not _check(g != null, "Active game null for " + gid_key): return
		for _f in range(5):
			g.step_game(0.05)
		var kev := InputEventKey.new()
		kev.pressed = true
		kev.physical_keycode = KEY_SPACE
		g.handle_input_event(kev)
		var mev := InputEventMouseButton.new()
		mev.pressed = true
		mev.button_index = MOUSE_BUTTON_LEFT
		mev.position = Vector2(200, 200)
		g.handle_input_event(mev)
		g.step_game(0.05)
		host.close_game()
	print("[PASS] All %d unique games + %d wall/tripod stations verified" % [MinigameHost.GAME_SCRIPTS.size(), world.casino_room.paintings.size()])

	# 4. Verify Menu starts game in Casino Room & physical KEY_E + Shift check
	menu.new_game_requested.emit()
	await get_tree().process_frame
	if not _check(player.controls_enabled == true, "Player controls must enable when clicking Гра"): return
	if not _check(absf(player.global_position.x) < 1.0 and absf(player.global_position.z - 4.4) < 0.5, "Player should start in Casino Room"): return

	# Outside North wall right behind 'tetris' must NEVER target painting through wall!
	player.global_position = Vector3(0.0, 6.12, -9.85)
	player._yaw = PI
	player._pitch = 0.0
	player.get_camera().rotation = Vector3.ZERO
	await get_tree().physics_frame
	await get_tree().physics_frame
	if not _check(player._targeted_painting_id == "", "Exterior wall failed to block painting prompt, got '%s'" % player._targeted_painting_id): return

	# Aim near North-Center painting (tetris at z=-8.68) and press physical E WITH Shift held
	player.global_position = Vector3(0.0, 6.12, -6.4)
	player._yaw = 0.0
	player._pitch = 0.0
	player.get_camera().rotation = Vector3.ZERO
	await get_tree().physics_frame
	await get_tree().physics_frame
	if not _check(player._targeted_painting_id == "tetris", "Expected target 'tetris', got '%s'" % player._targeted_painting_id): return

	var e_shift := InputEventKey.new()
	e_shift.pressed = true
	e_shift.physical_keycode = KEY_E
	e_shift.shift_pressed = true
	e_shift.keycode = KEY_U
	player._input(e_shift)
	await get_tree().create_timer(1.0).timeout
	if not _check(host.is_active() and host.get_active_game().get_game_title() == "Тетріс", "Painting dive did not open Тетріс"): return

	host.exit_requested.emit()
	await get_tree().create_timer(0.9).timeout
	if not _check(not host.is_active(), "Exit from minigame did not return to room"): return
	if not _check(player.controls_enabled == true, "Player controls not restored after exiting painting"): return
	print("[PASS] Player Casino spawn, painting targeting, physical KEY_E+Shift dive & exit")

	# 5. AudioSfx API & music/ambient modes smoke check
	AudioSfx.set_ambient_state(0.5, 0.7, 0.0, 0.8, 0.0)
	AudioSfx.set_music_mode("casino")
	AudioSfx.set_music_mode("minigame", "mario")
	AudioSfx.play_bird_song(-0.4)
	AudioSfx.play_duck_call(0.5)
	AudioSfx.play_hawk_cry(0.2)
	AudioSfx.play_animal_rustle(-0.6)
	AudioSfx.play_thunder()
	AudioSfx.play_explosion()
	AudioSfx.play_waka()
	AudioSfx.play_whistle()
	print("[PASS] AudioSfx world & minigame sound API")

	main.queue_free()
	await get_tree().process_frame
	print("=== ALL SELF CHECKS PASSED ===")
	get_tree().quit(0)
