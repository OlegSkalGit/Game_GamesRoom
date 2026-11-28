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

	# 1. ConfigManager & game/config.cfg root check (plus preserving external [launcher] section)
	var cfg_path := ConfigManager.get_config_path()
	var prev_cfg_gfx: Dictionary = ConfigManager.graphics.duplicate()
	var prev_cfg_display: Dictionary = ConfigManager.display.duplicate()
	var prev_lang: String = ConfigManager.get_current_language()
	if not _check(cfg_path.ends_with("game/config.cfg") or cfg_path.ends_with("game\\config.cfg"), "Config must live in game/ root: " + cfg_path): return
	var pre_cfg := ConfigFile.new()
	var had_launcher_mode := (pre_cfg.load(cfg_path) == OK and pre_cfg.has_section_key("launcher", "renderer_mode"))
	var prev_launcher_mode = pre_cfg.get_value("launcher", "renderer_mode", 1) if had_launcher_mode else null
	pre_cfg.set_value("launcher", "renderer_mode", 2)
	pre_cfg.save(cfg_path)
	for preset_idx in range(ConfigManager.PRESET_NAMES.size()):
		ConfigManager.apply_preset(preset_idx)
		if not _check(int(ConfigManager.graphics["preset"]) == preset_idx, "Preset mismatch"): return
	ConfigManager.apply_preset(3)
	if not _check(int(ConfigManager.graphics["antialiasing"]) >= 3, "High preset must use sharp MSAA (>=3), not blurry TAA"): return
	if not _check(FileAccess.file_exists(cfg_path), "config.cfg was not saved to game/ root"): return
	var post_cfg := ConfigFile.new()
	if not _check(post_cfg.load(cfg_path) == OK and int(post_cfg.get_value("launcher", "renderer_mode", -1)) == 2, "save_config overwrote [launcher] section!"): return
	if prev_launcher_mode != null:
		post_cfg.set_value("launcher", "renderer_mode", prev_launcher_mode)
	else:
		post_cfg.erase_section("launcher")
	post_cfg.save(cfg_path)
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
	if not _check(ConfigManager.t("sign_marquee") == "★ HOUSE OF GAMES ★", "Entrance sign default mismatch: " + ConfigManager.t("sign_marquee")): return
	for bid: String in ["chess", "checkers", "corners", "tictactoe", "battleship"]:
		var bp: Vector3 = world.casino_room.get_painting_by_id(bid)["node"].position
		if not _check(bp.x < -9.0 and absf(bp.y - 2.75) < 0.5, "Board game %s should be in West Wing: %s" % [bid, bp]): return
	for cid: String in ["durak", "blackjack", "poker", "solitaire"]:
		var cp_p: Vector3 = world.casino_room.get_painting_by_id(cid)["node"].position
		if not _check(cp_p.x > 5.0 and cp_p.y < 0.0, "Card game %s should be in Card Club: %s" % [cid, cp_p]): return
	for pid: String in ["tetris", "2048", "hexa", "match3", "zuma", "puzzle"]:
		var pp: Vector3 = world.casino_room.get_painting_by_id(pid)["node"].position
		if not _check(pp.x >= -5.0 and pp.x <= 5.0 and pp.y < 0.0, "Puzzle game %s should be in Basement Puzzles Hall: %s" % [pid, pp]): return
	var sn_p: Vector3 = world.casino_room.get_painting_by_id("snake")["node"].position
	var py_p: Vector3 = world.casino_room.get_painting_by_id("python3d")["node"].position
	if not _check(sn_p.y > 6.5 and py_p.y > 6.5 and absf(sn_p.x - py_p.x) < 1.0, "Snake 3D and Python 3D should be paired in Mansard"): return
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

	# Aim near North-Center painting (pacman at z=-8.68) and press physical E WITH Shift held
	player.global_position = Vector3(0.0, 6.12, -6.4)
	player._yaw = 0.0
	player._pitch = 0.0
	player.get_camera().rotation = Vector3.ZERO
	await get_tree().physics_frame
	await get_tree().physics_frame
	if not _check(player._targeted_painting_id == "pacman", "Expected target 'pacman', got '%s'" % player._targeted_painting_id): return

	var e_shift := InputEventKey.new()
	e_shift.pressed = true
	e_shift.physical_keycode = KEY_E
	e_shift.shift_pressed = true
	e_shift.keycode = KEY_U
	player._input(e_shift)
	await get_tree().create_timer(1.0).timeout
	if not _check(host.is_active() and host.get_active_game().get_game_title() == "Пак-Лабіринт", "Painting dive did not open Пак-Лабіринт"): return

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
	var barrier_mi := rt.get_node_or_null("RaceTrackBarrierMesh") as MeshInstance3D
	if not _check(barrier_mi != null and rt.get_node_or_null("_rail_mm") == null, "Monolithic track barrier mesh missing"): return
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
	if not _check((max_rad - min_rad) >= 120.0 and (max_y - min_y) >= 50.0 and max_y >= 60.0, "Expected double spirals + steep hills (y: %.1f..%.1f)" % [min_y, max_y]): return
	if not _check(max_bank >= 20.0, "Expected banked turns proportional to curvature"): return
	var rt_n: int = rt.frames.size()
	for p_info in rt._pillar_positions:
		var pxz: Vector2 = p_info["xz"]
		var top_y := float(p_info["top_y"])
		var bot_y := float(p_info["bot_y"])
		var own_idx := int(p_info["idx"])
		var is_out := bool(p_info["outrigger"])
		for j: int in range(rt_n):
			var d_idx := mini(abs(j - own_idx), rt_n - abs(j - own_idx))
			if not is_out and d_idx <= 4:
				continue
			var rf: Dictionary = rt.frames[j]
			var rfp: Vector3 = rf["pos"]
			var d_xz := Vector2(pxz.x - rfp.x, pxz.y - rfp.z).length()
			if d_xz < float(rf["width"]) * 0.5 + 1.2:
				if not _check(rfp.y >= top_y - 0.8 or rfp.y < bot_y - 1.0, "Pillar at %s (idx=%d) intersected track frame %d at %s" % [pxz, own_idx, j, rfp]): return

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
	# Verify mouse camera look orbits freely WITHOUT changing car steering or heading
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var look_ev := InputEventMouseMotion.new()
	look_ev.relative = Vector2(220.0, -50.0)
	car._input(look_ev)
	car._physics_process(1.0 / 60.0)
	if not _check(absf(car._cam_yaw_offset) > 0.35 and absf(car._cam_pitch_offset) > 0.05, "Mouse camera look failed to rotate car camera"): return
	if not _check(absf(car._rel_yaw) < 0.001 and absf(car._steer_input) < 0.001, "Mouse look must NEVER change car steering direction!"): return
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
	var qb0 := world.casino_room.get_node_or_null("QuestBoardStand_0") as Node3D
	if not _check(qb0 != null and absf(qb0.rotation.y - (PI - 0.36)) < 0.05, "Lobby QuestBoard must face North-East into Casino Hall"): return
	main._toggle_quest_journal()
	if not _check(main._quest_journal_panel.visible and main._quest_journal_lbl.text.contains(ConfigManager.t("q_explorer_basement_t")), "Quest journal modal failed to open with quests"): return
	main._toggle_quest_journal()
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
	if not _check(main._roulette_ui._spin_btn.text.contains("SPIN") and main._roulette_ui.handle_key(KEY_ENTER) and int(key_spin_cnt[0]) == 1, "Roulette launch button / KEY_ENTER trigger failed"): return
	main._roulette_ui.close_overlay()
	print("[PASS] Exit-Left 34-Game Map, 3-Reel Animated Slots, & Full 3D Roulette")

	# 8. Climbable 1-RPM Ferris Wheel on West Hill
	var fw = world.ferris_wheel
	if not _check(fw != null and fw.position.x < -40.0 and fw.position.y >= 14.0 and fw._cabins.size() == 12, "FerrisWheel missing or not placed on West hill"): return
	var start_ang: float = fw._angle
	for _ft in range(15):
		fw._physics_process(1.0)
	var d_ang := wrapf(fw._angle - start_ang, -PI, PI)
	if not _check(absf(d_ang - PI * 0.5) < 0.02, "FerrisWheel angular speed mismatch (expected 90 deg in 15s, got %.3f rad)" % d_ang): return
	var cab0: AnimatableBody3D = fw._cabins[0]["body"]
	player.set_controls_active(true)
	player.velocity = Vector3.ZERO
	player.global_position = cab0.global_position + Vector3(0.0, 0.04, 0.0)
	var start_c_pos := cab0.global_position
	var start_p_pos := player.global_position
	for _fp in range(45):
		await get_tree().physics_frame
	var carried := (player.global_position - start_p_pos).length()
	var cab_moved := (cab0.global_position - start_c_pos).length()
	var y_off := absf(player.global_position.y - cab0.global_position.y)
	player.set_controls_active(false)
	player.reset_to_casino_spawn()
	if not _check(y_off < 0.35 and carried > 0.35, "Player failed to ride moving FerrisWheel cabin cleanly (carried=%.2f cab_moved=%.2f y_off=%.2f on_floor=%s p_y=%.2f c_y=%.2f)" % [carried, cab_moved, y_off, str(player.is_on_floor()), player.global_position.y, cab0.global_position.y]): return
	print("[PASS] Climbable 1-RPM Ferris Wheel on West Hill")

	# 9. Day/Night Modes, Day Duration, & Dark-Gated Searchlights / Ferris Twinkling Bulbs
	ConfigManager.graphics["day_time_mode"] = 2 # Day 13:00
	ConfigManager.graphics["day_duration_min"] = 12.0
	world.weather.apply_time_settings()
	if not _check(absf(world.sky3d.minutes_per_day - 12.0) < 0.01 and not world.sky3d.game_time_enabled, "Day duration or pause failed"): return
	if not _check(not world.weather.is_dark_time() and not world.casino_room._searchlights_active and not fw._is_dark, "Lights must stay OFF in daylight"): return
	if not _check(is_equal_approx(fw._bulb_mats[0].emission_energy_multiplier, 0.0), "Ferris bulbs must stay unlit in daytime"): return

	ConfigManager.graphics["day_time_mode"] = 3 # Sunset 19:36
	world.weather.apply_time_settings()
	if not _check(world.weather.is_dark_time() and world.casino_room._searchlights_active and fw._is_dark, "Searchlights & Ferris bulbs must activate at sunset"): return
	fw._process(0.18)
	var b_e1: float = fw._bulb_mats[0].emission_energy_multiplier
	fw._process(0.25)
	var b_e2: float = fw._bulb_mats[0].emission_energy_multiplier
	if not _check(b_e1 > 0.05 and absf(b_e2 - b_e1) > 0.01, "Ferris bulbs failed to blink at sunset"): return

	ConfigManager.graphics["day_time_mode"] = 4 # Night 23:30
	world.weather.apply_time_settings()
	if not _check(world.sky3d.is_night() and world.weather.is_dark_time() and bool(world.casino_room._searchlights[0]["spot"].visible), "Night spotlight/sky check failed"): return
	var prev_show_fps := bool(ConfigManager.display.get("show_fps", false))
	ConfigManager.display["show_fps"] = true
	ConfigManager.apply_display()
	if not _check(main._fps_lbl != null and main._fps_lbl.visible, "FPS overlay did not show when show_fps=true"): return
	ConfigManager.display["show_fps"] = false
	ConfigManager.apply_display()
	if not _check(not main._fps_lbl.visible, "FPS overlay did not hide when show_fps=false"): return
	ConfigManager.display["show_fps"] = prev_show_fps
	ConfigManager.apply_display()
	print("[PASS] Day/Night Modes, Day Duration, FPS Display, & Sunset/Night Lights")

	# 10. Multi-Language Support (English + 30 Languages, Native Alphabetical Sort, Folder Scan & Display Dropdown)
	var langs := ConfigManager.get_languages()
	if not _check(langs.size() >= 31, "Expected at least 31 languages in game/lang/, got %d" % langs.size()): return
	if not _check(ConfigManager.get_current_language() == "en", "Default language must be 'en', got '%s'" % ConfigManager.get_current_language()): return
	var idx_de := -1
	var idx_en := -1
	var idx_es := -1
	var idx_ru := -1
	var idx_uk := -1
	for i in range(langs.size()):
		if i > 0:
			if not _check(str(langs[i - 1]["sort_key"]) <= str(langs[i]["sort_key"]), "Languages not sorted alphabetically at idx %d: %s vs %s" % [i, langs[i - 1]["name"], langs[i]["name"]]): return
		var c := str(langs[i]["code"])
		var nm := str(langs[i]["name"])
		match c:
			"de":
				idx_de = i
				if not _check(nm == "Deutsch", "Native name mismatch for de: " + nm): return
			"en":
				idx_en = i
				if not _check(nm == "English", "Native name mismatch for en: " + nm): return
			"es":
				idx_es = i
				if not _check(nm == "Español", "Native name mismatch for es: " + nm): return
			"ru":
				idx_ru = i
				if not _check(nm == "Русский", "Native name mismatch for ru: " + nm): return
			"uk":
				idx_uk = i
				if not _check(nm == "Українська", "Native name mismatch for uk: " + nm): return
	if not _check(idx_de >= 0 and idx_en > idx_de and idx_es > idx_en and idx_ru > idx_es and idx_uk > idx_ru, "Alphabetical order check failed for de/en/es/ru/uk"): return

	var ui_font := ConfigManager.get_ui_font()
	for cp: int in [ord("Ї"), ord("日"), ord("ع"), ord("अ"), ord("한"), ord("ก")]:
		if not _check(ui_font.has_char(cp), "UI fallback font missing glyph for codepoint %d" % cp): return

	# Dynamic manual drop-in .cfg test in game/lang/
	var custom_path := ConfigManager.get_lang_dir().path_join("_tmp_selfcheck_lang.cfg")
	var tmp_cfg := ConfigFile.new()
	tmp_cfg.set_value("meta", "native_name", "Azbuka Test")
	tmp_cfg.set_value("strings", "menu_play", "Play Custom")
	tmp_cfg.save(custom_path)
	ConfigManager.load_available_languages()
	var found_custom := false
	for entry in ConfigManager.get_languages():
		if str(entry["code"]) == "_tmp_selfcheck_lang" and str(entry["name"]) == "Azbuka Test":
			found_custom = true
			break
	if not _check(found_custom, "Dynamic game/lang/*.cfg scan failed to pick up added file"): return
	ConfigManager.set_language("_tmp_selfcheck_lang", false)
	if not _check(ConfigManager.t("menu_play") == "Play Custom" and ConfigManager.t("menu_quit") == "Quit", "Custom lang override or English fallback failed"): return
	DirAccess.remove_absolute(custom_path)
	ConfigManager.load_available_languages()

	# Display Settings Language selector & live switch test
	main._menu.open_menu()
	main._menu._open_subtab("display")
	if not _check(main._menu._opt_lang != null and main._menu._opt_lang.item_count == ConfigManager.get_languages().size(), "Display Language OptionButton count mismatch"): return
	var uk_opt_idx := -1
	for i in range(main._menu._opt_lang.item_count):
		if str(main._menu._opt_lang.get_item_metadata(i)) == "uk":
			uk_opt_idx = i
			break
	if not _check(uk_opt_idx >= 0, "Ukrainian entry missing from Display Language dropdown"): return
	ConfigManager.set_language("uk", true)
	await get_tree().process_frame
	if not _check(main._menu._btn_game.text == "Гра" and main._status_lbl.text.contains("Погода:"), "Live language switch to Ukrainian failed"): return
	var saved_lang_cfg := ConfigFile.new()
	if not _check(saved_lang_cfg.load(cfg_path) == OK and str(saved_lang_cfg.get_value("display", "language", "")) == "uk", "Language selection was not saved to config.cfg"): return
	ConfigManager.set_language("en", true)
	await get_tree().process_frame
	if not _check(main._menu._btn_game.text == "Game" and main._status_lbl.text.contains("Weather:"), "Live language switch back to English failed"): return
	main._menu.close_menu()
	print("[PASS] Multi-Language (31 langs, alphabetical native names, game/lang scan, live Display UI)")

	# 11. Dedicated Game Section (New/Resume/Save/Load), Controls Tab, & F5/F9 Save/Load World Teleport Sync
	var save_path := ConfigManager.get_save_path()
	var prev_save_bytes: PackedByteArray = FileAccess.get_file_as_bytes(save_path) if FileAccess.file_exists(save_path) else PackedByteArray()
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(save_path)

	main._menu.set_game_started(true)
	main._menu.open_menu()
	if not _check(main._menu._active_tab == "game" and main._menu._btn_resume != null and main._menu._btn_save != null and main._menu._btn_load == null and main._menu._btn_play != null, "Game panel buttons mismatch before any save exists"): return
	main._menu._open_subtab("controls")
	if not _check(main._menu._btn_tab_controls != null and main._menu._sub_vbox.get_child_count() >= 20, "Controls settings tab missing full control descriptions"): return
	main._menu.close_menu()

	# A) F5 on foot at distant ridge -> start Race -> F9 loads back onto foot & restores Terrain3D/Weather/Player sync
	var foot_pos := Vector3(-124.0, 26.0, -96.0)
	main._player.global_position = foot_pos
	main._player._yaw = 1.15
	main._player._pitch = -0.18
	main._player._lantern_on = true
	main._player._lantern.visible = true
	main._quests.add_chips(333)
	var chips_saved: int = main._quests.chips
	main._input(func_make_key(KEY_F5, true))
	if not _check(ConfigManager.has_save(), "F5 Quick Save failed to create save file"): return

	main._start_race()
	if not _check(main._is_driving and world.terrain.clipmap_target == main._race_car, "Entering race must focus Terrain3D clipmap on car"): return
	main._race_car._track_s = 250.0
	main._race_car._physics_process(0.05)
	main._quests.add_chips(99)

	main._input(func_make_key(KEY_F9, true))
	if not _check(not main._is_driving and not main._race_car._active, "F9 Quick Load from Race Car back to foot failed to exit car"): return
	if not _check(main._player.global_position.distance_to(foot_pos) < 0.05 and absf(main._player._yaw - 1.15) < 0.01 and main._player._lantern_on, "F9 failed to restore exact player position/look/lantern"): return
	if not _check(main._quests.chips == chips_saved, "F9 failed to restore saved chips (%d vs %d)" % [main._quests.chips, chips_saved]): return
	if not _check(world.terrain.clipmap_target == main._player and world.terrain.collision_target == main._player and world.weather.player_node == main._player and main._player.get_camera().current, "F9 failed to sync Terrain3D, Weather & Camera back to Player"): return

	# Verify Game panel now offers Quick Load when save exists (both in-game & pre-game)
	main._menu.open_menu()
	if not _check(main._menu._btn_load != null, "Game panel must offer Load button when save exists"): return
	main._menu.set_game_started(false)
	main._menu._open_subtab("game")
	if not _check(main._menu._btn_play != null and main._menu._btn_load != null, "Pre-game Game panel must offer Load alongside New Game when save exists"): return
	main._menu.close_menu()
	main._menu.set_game_started(true)

	# B) F5 mid-race on distant spiral -> exit to Casino Basement -> F9 loads back into Race Car & snaps Terrain3D
	main._start_race()
	main._race_car._phase = 1
	main._race_car._track_s = 420.0
	main._race_car._speed = 46.0
	main._race_car._lap = 2
	main._race_car._physics_process(0.05)
	var saved_s: float = main._race_car._track_s
	main._input(func_make_key(KEY_F5, true))

	main._exit_race()
	main._player.global_position = Vector3(0.0, 2.5, 0.0)
	main._world.set_world_focus(main._player, true)
	main._input(func_make_key(KEY_F9, true))
	if not _check(main._is_driving and main._race_car._active and absf(main._race_car._track_s - saved_s) < 0.2 and main._race_car._lap == 2, "F9 failed to restore mid-race car state"): return
	if not _check(world.terrain.clipmap_target == main._race_car and world.terrain.collision_target == main._race_car and world.weather.player_node == main._race_car and main._race_car._cam.current, "F9 failed to sync Terrain3D, Weather & Camera to Race Car"): return
	main._exit_race()

	if prev_save_bytes.is_empty():
		if FileAccess.file_exists(save_path):
			DirAccess.remove_absolute(save_path)
	else:
		var fw_prev := FileAccess.open(save_path, FileAccess.WRITE)
		fw_prev.store_buffer(prev_save_bytes)
		fw_prev.close()
	print("[PASS] Game Section, Controls Tab, & F5/F9 Save/Load with Full World/Race Sync")

	main.queue_free()
	await get_tree().process_frame
	ConfigManager.graphics = prev_cfg_gfx
	ConfigManager.display = prev_cfg_display
	ConfigManager.set_language(prev_lang, false)
	ConfigManager.apply_graphics()
	ConfigManager.apply_display()
	ConfigManager.save_config()
	print("=== ALL SELF CHECKS PASSED ===")
	get_tree().quit(0)
