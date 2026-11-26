extends Node

const RouletteOverlayScript := preload("res://scripts/ui/roulette_overlay.gd")

# Automated headless self-check verifying:
# 1. ConfigManager reads/writes game/config.cfg & presets 0..5 + display settings
# 2. WorldBuilder initializes Sky3D + Terrain3D + Lakes + Dense Vegetation + Wildlife + CasinoRoom
# 3. CasinoRoom has exactly 9 paintings, each opens cleanly in MinigameHost
# 4. Physical KEY_E interaction works regardless of Shift modifier
# 5. All 9 classic mini-games load, step, handle input, and clean up without errors

func _ready() -> void:
	await get_tree().process_frame
	_run_checks()


func func_make_key(phys: int, is_pressed: bool) -> InputEventKey:
	var ev := InputEventKey.new()
	ev.physical_keycode = phys
	ev.pressed = is_pressed
	return ev


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
	var prev_cfg_gfx: Dictionary = ConfigManager.graphics.duplicate()
	if not _check(cfg_path.ends_with("game/config.cfg") or cfg_path.ends_with("game\\config.cfg"), "Config must live in game/ root: " + cfg_path): return
	for preset_idx in range(ConfigManager.PRESET_NAMES.size()):
		ConfigManager.apply_preset(preset_idx)
		if not _check(int(ConfigManager.graphics["preset"]) == preset_idx, "Preset mismatch"): return
	ConfigManager.apply_preset(3)
	if not _check(int(ConfigManager.graphics["antialiasing"]) >= 3, "High preset must use sharp MSAA (>=3), not blurry TAA"): return
	if not _check(FileAccess.file_exists(cfg_path), "config.cfg was not saved to game/ root"): return
	ConfigManager.graphics = prev_cfg_gfx
	ConfigManager.apply_graphics()
	ConfigManager.save_config()
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
	if not _check(world.race_track != null and world.race_track.rivals.size() == 4, "MountainRaceTrack or 4 AI rivals missing"): return
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
	if not _check(world.wildlife._fish.size() >= 18, "Lake fish missing: %d" % world.wildlife._fish.size()): return
	for f_item in world.wildlife._fish:
		var fn: Node3D = f_item["node"]
		if not _check(fn.position.y < WorldBuilder.WATER_LEVEL - 0.1, "Fish poked above water at y=%.2f" % fn.position.y): return
	print("[PASS] WorldBuilder (Sky3D, Terrain3D, Lakes, Weather, Wildlife)")

	# 3. Verify all 24 games & paintings/tripods are strictly unique (zero duplicates!)
	if not _check(world.casino_room.paintings.size() == MinigameHost.GAME_SCRIPTS.size(), "Expected %d unique paintings/tripods, got %d" % [MinigameHost.GAME_SCRIPTS.size(), world.casino_room.paintings.size()]): return
	var seen_ids := {}
	for p in world.casino_room.paintings:
		var pid := str(p["id"])
		var ptitle := str(p["title"])
		if not _check(not seen_ids.has(pid), "Duplicate painting ID found: " + pid): return
		if not _check(not ptitle.contains("Експонат"), "Forbidden word in title: " + ptitle): return
		seen_ids[pid] = true
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

	# Verify walking cleanly up Basement stairs & Mansard stairs WITHOUT jumping
	player.global_position = Vector3(14.5, 2.08, 6.6)
	player.velocity = Vector3.ZERO
	player._yaw = 0.0
	player._pitch = 0.0
	Input.parse_input_event(func_make_key(KEY_W, true))
	for _s in range(150):
		await get_tree().physics_frame
	Input.parse_input_event(func_make_key(KEY_W, false))
	if not _check(player.global_position.z < -2.6 and player.global_position.y >= 6.08, "Player got stuck climbing Basement stairs at z=%.2f y=%.2f" % [player.global_position.z, player.global_position.y]): return

	player.global_position = Vector3(18.55, 6.14, 7.1)
	player.velocity = Vector3.ZERO
	player._yaw = 0.0
	Input.parse_input_event(func_make_key(KEY_W, true))
	for _s in range(190):
		await get_tree().physics_frame
	Input.parse_input_event(func_make_key(KEY_W, false))
	if not _check(player.global_position.z < -6.0 and player.global_position.y >= 12.80, "Player got stuck climbing Mansard stairs at z=%.2f y=%.2f" % [player.global_position.z, player.global_position.y]): return

	# Python 3D (18 original worlds/textures, smooth right steering, arc-length spacing, camera modes & AI)
	if not _check(host.open_game("python3d"), "Failed to open python3d"): return
	var py_g = host.get_active_game()
	if not _check(py_g != null and py_g._enemies.size() >= 2, "Python 3D AI enemies missing"): return
	if not _check(py_g._sv != null and py_g._sv_rect != null and py_g._sv.msaa_3d == Viewport.MSAA_4X and not py_g._sv.use_taa, "Python 3D crisp MSAA/SubViewport decoupling missing"): return
	if not _check(ResourceLoader.exists("res://assets/textures/python3d/snake_scales.png"), "Python 3D texture snake_scales.png missing"): return
	py_g._t_immune = 0.0
	py_g.handle_input_event(func_make_key(KEY_D, true))
	for _ps in range(15):
		py_g.step_game(0.03)
	py_g.handle_input_event(func_make_key(KEY_D, false))
	if not _check(py_g._p_angle > 0.2 and py_g._p_pos.x > 0.2, "Python 3D right steering failed: angle=%.2f x=%.2f" % [py_g._p_angle, py_g._p_pos.x]): return
	py_g._load_world(17) # Test Final Boss World 18 Quantum Citadel builds cleanly
	py_g.step_game(0.05)
	if not _check(py_g._world_idx == 17 and py_g._enemies.size() == 5, "Python 3D World 18 failed to load"): return
	host.close_game()

	# Deterministic edge-merge checks on Hexa (pair default + triple mode along outer edge)
	if not _check(host.open_game("hexa"), "Failed to open hexa"): return
	var hx_g = host.get_active_game()
	for hk: Vector2i in hx_g._cells:
		hx_g._board[hk] = 0
	hx_g._board[Vector2i(3, 0)] = 1
	hx_g._board[Vector2i(4, 0)] = 1
	hx_g._try_slide(1) # Two identical tiles already at right edge must merge in default x2 mode
	if not _check(int(hx_g._board[Vector2i(4, 0)]) == 2, "Hexa edge pair merge failed"): return
	hx_g._merge_req = 3
	for hk: Vector2i in hx_g._cells:
		hx_g._board[hk] = 0
	hx_g._board[Vector2i(2, 0)] = 1
	hx_g._board[Vector2i(3, 0)] = 1
	hx_g._board[Vector2i(4, 0)] = 1
	hx_g._try_slide(1) # Three identical tiles already at right edge must merge in x3 mode
	if not _check(int(hx_g._board[Vector2i(4, 0)]) == 2, "Hexa triple edge merge failed along +q axis"): return
	host.close_game()

	# Verify all Sokoban levels have matching crate & target counts and valid player spawn
	if not _check(host.open_game("sokoban"), "Failed to open sokoban"): return
	var sk_g = host.get_active_game()
	if not _check(sk_g.LEVELS.size() >= 16, "Sokoban expected >= 16 levels"): return
	for si: int in range(sk_g.LEVELS.size()):
		sk_g._load_level(si)
		if not _check(sk_g._crates.size() >= 1 and sk_g._crates.size() == sk_g._targets.size(), "Sokoban level %d mismatch crates=%d targets=%d" % [si + 1, sk_g._crates.size(), sk_g._targets.size()]): return
		if not _check(not sk_g._is_wall(sk_g._player), "Sokoban level %d invalid player position" % [si + 1]): return
	host.close_game()
	print("[PASS] Player Casino spawn, painting targeting, physical KEY_E+Shift dive & smooth stair climb")

	# 5. Lighting, Shadows, PBR Materials & Multi-Coil Spiral Perimeter Race Verification
	if not _check(world.sky3d.sun.shadow_enabled and world.sky3d.sun.directional_shadow_max_distance >= 200.0, "Directional shadows must cover perimeter"): return
	if not _check(world.casino_room.get_node_or_null("CasinoReflectionProbe") != null, "CasinoReflectionProbe missing"): return
	var road_mi := world.race_track.get_node_or_null("RaceTrackRoadMesh") as MeshInstance3D
	if not _check(road_mi != null and road_mi.material_override is StandardMaterial3D, "Track road PBR material missing"): return
	var road_pbr := road_mi.material_override as StandardMaterial3D
	if not _check(road_pbr.normal_enabled and road_pbr.roughness_texture != null, "Track asphalt normal/roughness maps missing"): return

	var rt = world.race_track
	var max_rx := 0.0
	var max_rz := 0.0
	var min_rad := 999.0
	var max_rad := 0.0
	var min_y := 999.0
	var max_y := -999.0
	var max_bank := 0.0
	var loop_cnt := 0
	var prev_in_loop := false
	for rf in rt.frames:
		var rp: Vector3 = rf["pos"]
		max_rx = maxf(max_rx, absf(rp.x))
		max_rz = maxf(max_rz, absf(rp.z))
		var r2 := Vector2(rp.x, rp.z).length()
		min_rad = minf(min_rad, r2)
		max_rad = maxf(max_rad, r2)
		min_y = minf(min_y, rp.y)
		max_y = maxf(max_y, rp.y)
		max_bank = maxf(max_bank, absf(float(rf["bank_deg"])))
		var in_lp := bool(rf["is_loop"])
		if in_lp and not prev_in_loop:
			loop_cnt += 1
		prev_in_loop = in_lp
	if not _check(max_rx >= 220.0 and max_rz >= 220.0, "Track must hug valley edge, got max_x=%.1f max_z=%.1f" % [max_rx, max_rz]): return
	if not _check(loop_cnt >= 4, "Expected >= 4 vertical loops, got %d" % loop_cnt): return
	if not _check((max_rad - min_rad) >= 120.0 and (max_y - min_y) >= 40.0, "Expected multi-coil spiral elevation variation"): return
	if not _check(max_bank >= 20.0, "Expected banked turns proportional to curvature"): return

	# Verify 3-2-1 Countdown, Simultaneous Launch, Slow Loop Entry & 3-Lap Completion
	main._start_race()
	var car = main._race_car
	var f1_body: Node3D = car._car_mesh.get_node_or_null("BodyPivot") as Node3D
	if not _check(f1_body != null and f1_body.get_child_count() >= 20, "F1 car mesh missing detailed parts"): return
	if not _check(car._phase == 0 and main._race_banner_lbl.text == "3", "Expected 3-2-1 countdown start"): return
	for rv in rt.rivals:
		if not _check(float(rv["cur_spd"]) == 0.0 and float(rv["progress_dist"]) < 0.0, "AI rivals must wait on grid at countdown"): return
	for _t in range(195): # 3.25s at 60Hz -> transitions 3 -> 2 -> 1 -> GO!
		rt._process(1.0 / 60.0)
		car._physics_process(1.0 / 60.0)
	if not _check(car._phase == 1, "Race did not transition to RACING after 3-2-1 countdown"): return
	for rv in rt.rivals:
		if not _check(float(rv["cur_spd"]) > 5.0, "AI rival did not launch simultaneously on GO"): return
	rt.player_progress_dist = 75.0
	for _rs in range(90):
		rt._process(1.0 / 60.0)
	var max_ai_spd := 0.0
	for rv in rt.rivals:
		max_ai_spd = maxf(max_ai_spd, float(rv["cur_spd"]))
	if not _check(max_ai_spd >= 52.0, "AI rivals too slow during catchup/overtake: %.1f" % max_ai_spd): return
	rt.player_progress_dist = car._progress_dist

	# Test slow-speed entry & climb through a vertical loop + smooth steering left/right
	var first_loop_s := 0.0
	for rf in rt.frames:
		if bool(rf["is_loop"]):
			first_loop_s = float(rf["s"])
			break
	car._track_s = fposmod(first_loop_s - 4.0, rt.total_length)
	car._speed = 8.5
	car._airborne = false
	Input.parse_input_event(func_make_key(KEY_W, true))
	Input.parse_input_event(func_make_key(KEY_A, true))
	var saw_loop := false
	for _s in range(180):
		car._physics_process(1.0 / 60.0)
		var fcur: Dictionary = rt.sample_at_s(car._track_s)
		if bool(fcur.get("is_loop", false)):
			saw_loop = true
	Input.parse_input_event(func_make_key(KEY_A, false))
	Input.parse_input_event(func_make_key(KEY_W, false))
	if not _check(saw_loop and car._speed >= 8.5, "Car failed smooth slow loop traversal"): return

	# Verify 3 full laps counting cleanly
	car._progress_dist = rt.total_length * 1.05
	car._physics_process(1.0 / 60.0)
	if not _check(car._lap == 2, "Expected Lap 2/3, got %d" % car._lap): return
	car._progress_dist = rt.total_length * 2.05
	car._physics_process(1.0 / 60.0)
	if not _check(car._lap == 3, "Expected Lap 3/3, got %d" % car._lap): return
	car._progress_dist = rt.total_length * 3.02
	car._physics_process(1.0 / 60.0)
	if not _check(car._phase == 2 and car._finished_rank >= 1, "Expected Race Finish after 3 full laps"): return
	main._exit_race()
	print("[PASS] Lighting/PBR/Shadows + Multi-Coil Perimeter Race (4 loops, 3-2-1, 4 AI rivals, 3 laps)")

	# 6. AudioSfx API & music/ambient modes smoke check
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
	AudioSfx.play_countdown_beep(false)
	AudioSfx.play_countdown_beep(true)
	AudioSfx.play_race_finish()
	print("[PASS] AudioSfx world & minigame sound API")

	# 7. Exit-Left Games Directory Map, Animated 3-Reel Slots, & 3D Roulette Checks
	var gm := world.casino_room.get_node_or_null("GamesMapStand") as Node3D
	if not _check(gm != null and gm.position.x > 3.0 and gm.position.z > 7.0, "GamesMapStand missing at exit-left (+X, +Z)"): return
	main._toggle_games_map()
	if not _check(main._games_map_panel.visible and main._games_map_lbl.text.contains("34"), "Games map modal toggle/text failed"): return
	main._toggle_games_map()
	if not _check(not main._games_map_panel.visible, "Games map modal failed to close"): return

	var slot_paid := [false]
	var slot_cb := func(_won: int, _msg: String): slot_paid[0] = true
	world.casino_room.slot_payout.connect(slot_cb)
	var slot_txt := world.casino_room.trigger_slot(0)
	if not _check(slot_txt != "" and world.casino_room.is_slot_spinning(0), "Slot machine failed to start animated spin"): return
	for _sl in range(14):
		world.casino_room._process(0.14)
	if not _check(not world.casino_room.is_slot_spinning(0) and bool(slot_paid[0]), "Slot machine failed to lock reels & emit payout"): return

	if not _check(RouletteOverlayScript.compute_payout({"red": 100, "n_18": 50}, 18) == 2000, "Roulette payout formula mismatch for red+straight"): return
	if not _check(RouletteOverlayScript.compute_payout({"red": 100, "black": 100}, 17) == 200, "Roulette pocket 17 black payout mismatch"): return
	if not _check(RouletteOverlayScript.compute_payout({"red": 100, "even": 100}, 0) == 0, "Roulette Zero pocket house rule mismatch"): return
	world.casino_room.update_roulette_chips({"red": 50, "n_17": 25})
	if not _check(world.casino_room._roulette_chips_root.get_child_count() == 2, "3D roulette chips stack count mismatch"): return
	var r_done := [-1]
	var r_cb := func(wn: int): r_done[0] = wn
	world.casino_room.roulette_spin_finished.connect(r_cb)
	var r_win := world.casino_room.start_roulette_spin()
	if not _check(r_win >= 0 and r_win <= 36 and world.casino_room.is_roulette_spinning(), "3D Roulette failed to start spin"): return
	for _rl in range(22):
		world.casino_room._process(0.22)
	var ball_p: Vector3 = world.casino_room._roulette_ball.position
	var wheel_c: Vector3 = world.casino_room._roulette_wheel.position
	var ball_rad := Vector2(ball_p.x - wheel_c.x, ball_p.z - wheel_c.z).length()
	if not _check(not world.casino_room.is_roulette_spinning() and int(r_done[0]) == r_win and absf(ball_rad - 0.43) < 0.03, "3D Roulette ball failed to settle in pocket (r=%.3f)" % ball_rad): return
	main._roulette_ui.open(200)
	main._roulette_ui._place_bet("red")
	var key_spin_cnt := [0]
	var ks_cb := func(_b: Dictionary): key_spin_cnt[0] = int(key_spin_cnt[0]) + 1
	main._roulette_ui.spin_requested.connect(ks_cb)
	if not _check(main._roulette_ui._spin_btn.text.contains("ЗАПУСТИТИ") and main._roulette_ui.handle_key(KEY_ENTER) and int(key_spin_cnt[0]) == 1, "Roulette launch button / KEY_ENTER trigger failed"): return
	main._roulette_ui.close_overlay()
	print("[PASS] Exit-Left 34-Game Map, 3-Reel Animated Slots, & Full 3D Roulette")

	main.queue_free()
	await get_tree().process_frame
	print("=== ALL SELF CHECKS PASSED ===")
	get_tree().quit(0)
