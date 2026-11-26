extends MinigameBase

const Arenas := preload("res://scripts/minigames/games/python3d_arenas.gd")

const SEG_DIST := 0.55
const HEAD_RAD := 0.55
const SEG_RAD := 0.48
const TAIL_MIN_SCALE := 0.55
const TURN_SPEED := deg_to_rad(145.0)
const MAX_BANK := deg_to_rad(22.0)
const BOOST_RATIO := 16.8 / 9.2
const MAGNET_RADIUS := 11.0
const MAX_LIVES := 5

const BTN_PREV_WORLD := Rect2(8, 6, 22, 22)
const BTN_NEXT_WORLD := Rect2(204, 6, 22, 22)

var _sv: SubViewport
var _sv_rect: TextureRect
var _world3d: Node3D
var _env: Environment
var _key_light: DirectionalLight3D
var _rim_light: DirectionalLight3D
var _cam: Camera3D
var _hud: Control

var _world_idx: int = 0
var _lives: int = 3
var _best_score: int = 0
var _eaten_quota: int = 0
var _target_quota: int = 24
var _half: float = 22.0
var _base_speed: float = 8.5
var _cam_mode: int = 0 # 0 Chase, 1 Top-Down, 2 First-Person
var _zoom: float = 1.25
var _cam_yaw: float = 0.0
var _elapsed: float = 0.0
var _banner_txt: String = ""
var _banner_t: float = 0.0
var _clear_wait: float = 0.0

var _p_pos: Vector2 = Vector2.ZERO
var _p_angle: float = 0.0
var _p_turn: float = 0.0
var _p_bank: float = 0.0
var _p_boost_energy: float = 100.0
var _p_total_dist: float = 0.0
var _p_last_pos: Vector2 = Vector2.ZERO
var _p_trail: Array[Dictionary] = []
var _p_nodes: Array[Node3D] = []
var _p_head_node: Node3D
var _p_tongue: Node3D
var _shield_mesh: Node3D
var _magnet_mesh: Node3D
var _magnet_ring: Node3D

var _t_shield: float = 0.0
var _t_magnet: float = 0.0
var _t_turbo: float = 0.0
var _t_slow: float = 0.0
var _t_immune: float = 0.0
var _t_golden: float = 12.0
var _t_powerup: float = 10.0

var _enemies: Array[Dictionary] = []
var _foods: Array[Dictionary] = []
var _hazards: Array[Dictionary] = []
var _obstacles: Array[Dictionary] = []
var _spinners: Array[Dictionary] = []
var _bursts: Array[Dictionary] = []
var _arena_nodes: Array[Node3D] = []

var _p_head_mat: StandardMaterial3D
var _p_body_mats: Array[StandardMaterial3D] = []
var _e_head_mat: StandardMaterial3D
var _e_body_mats: Array[StandardMaterial3D] = []


func get_game_title() -> String:
	return "Пітон"


func get_controls_hint() -> String:
	return "A/D або ←/→ — поворот | Пробіл/Shift — турбо | C — камера | Колесо/+/- — зум | [/] — світ | R — заново"


func _ready() -> void:
	super._ready()
	_build_3d()


func _exit_tree() -> void:
	if _sv_rect:
		_sv_rect.texture = null
	if _world3d:
		_clear_all_dynamic()
		_world3d.free()
		_world3d = null


static func _fwd2(yaw: float) -> Vector2:
	return Vector2(sin(yaw), -cos(yaw))


static func _right2(yaw: float) -> Vector2:
	return Vector2(cos(yaw), sin(yaw))


func _build_3d() -> void:
	_sv = SubViewport.new()
	if DisplayServer.get_name() == "headless":
		_sv.size = Vector2i(640, 400)
	else:
		var win_sz := DisplayServer.window_get_size()
		var target_h := clampi(int(float(maxi(win_sz.y, 1080)) * 0.88), 1200, 1600)
		_sv.size = Vector2i(int(round(float(target_h) * 1.6)), target_h)
	_sv.own_world_3d = true
	_sv.msaa_3d = Viewport.MSAA_4X
	_sv.use_taa = false
	_sv.use_debanding = true
	_sv.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
	_sv.scaling_3d_scale = 1.0
	_sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_sv)

	_sv_rect = TextureRect.new()
	_sv_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_sv_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_sv_rect.stretch_mode = TextureRect.STRETCH_SCALE
	_sv_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_sv_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sv_rect.texture = _sv.get_texture()
	add_child(_sv_rect)

	_world3d = Node3D.new()
	_sv.add_child(_world3d)

	_env = Environment.new()
	_env.background_mode = Environment.BG_COLOR
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_env.tonemap_mode = Environment.TONE_MAPPER_ACES
	_env.tonemap_exposure = 1.06
	_env.glow_enabled = true
	_env.glow_intensity = 0.24
	_env.glow_bloom = 0.02
	_env.glow_hdr_threshold = 1.35
	var we := WorldEnvironment.new()
	we.environment = _env
	_world3d.add_child(we)

	_key_light = DirectionalLight3D.new()
	_key_light.rotation_degrees = Vector3(-52.0, 28.0, 0.0)
	_key_light.shadow_enabled = true
	_key_light.shadow_bias = 0.04
	_key_light.shadow_blur = 1.1
	_key_light.directional_shadow_max_distance = 120.0
	_world3d.add_child(_key_light)

	_rim_light = DirectionalLight3D.new()
	_rim_light.rotation_degrees = Vector3(-35.0, -140.0, 0.0)
	_rim_light.light_color = Color(0.45, 0.52, 0.68)
	_world3d.add_child(_rim_light)

	_cam = Camera3D.new()
	_cam.fov = 52.0
	_cam.near = 0.4
	_cam.far = 360.0
	_world3d.add_child(_cam)

	_p_head_mat = Arenas.make_mat(Color(0.88, 1.0, 0.90), "snake_scales.png", 0.28, 0.14)
	_p_body_mats.clear()
	for i in range(6):
		var c := Color(0.16, 0.75, 0.37).lerp(Color(0.12, 0.63, 0.31), float(i) / 5.0)
		_p_body_mats.append(Arenas.make_mat(c, "snake_scales.png", 0.32, 0.12))
	_e_head_mat = Arenas.make_mat(Color(1.0, 0.88, 0.88), "enemy_scales.png", 0.28, 0.18)
	_e_body_mats.clear()
	for i in range(4):
		var ec := Color(0.71, 0.12, 0.12).lerp(Color(0.51, 0.08, 0.08), float(i) / 3.0)
		_e_body_mats.append(Arenas.make_mat(ec, "enemy_scales.png", 0.35, 0.16))

	_hud = Control.new()
	_hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.draw.connect(_draw_hud)
	add_child(_hud)


func _clear_all_dynamic() -> void:
	for n: Node3D in _p_nodes:
		if is_instance_valid(n): n.queue_free()
	_p_nodes.clear()
	if is_instance_valid(_p_head_node):
		_p_head_node.queue_free()
	_p_head_node = null
	for e in _enemies:
		var eh: Node3D = e.get("head")
		if is_instance_valid(eh): eh.queue_free()
		for n: Node3D in e["nodes"]:
			if is_instance_valid(n): n.queue_free()
	_enemies.clear()
	for f in _foods:
		var fn: Node3D = f.get("node")
		if is_instance_valid(fn): fn.queue_free()
	_foods.clear()
	for b in _bursts:
		for pn: Node3D in b["nodes"]:
			if is_instance_valid(pn): pn.queue_free()
	_bursts.clear()
	for n: Node3D in _arena_nodes:
		if is_instance_valid(n): n.queue_free()
	_arena_nodes.clear()
	_hazards.clear()
	_obstacles.clear()
	_spinners.clear()


func reset_game() -> void:
	_world_idx = 0
	_lives = 3
	super.reset_game()
	_load_world(0)


func _load_world(idx: int) -> void:
	_world_idx = clampi(idx, 0, Arenas.WORLD_SPECS.size() - 1)
	_clear_all_dynamic()
	var spec: Dictionary = Arenas.WORLD_SPECS[_world_idx]
	_half = float(spec["size"]) * 0.5
	_target_quota = int(spec["quota"])
	_base_speed = float(spec["speed"])
	_eaten_quota = 0
	_elapsed = 0.0
	_clear_wait = 0.0
	_t_shield = 0.0; _t_magnet = 0.0; _t_turbo = 0.0; _t_slow = 0.0; _t_immune = 2.0
	_t_golden = 12.0; _t_powerup = 9.0

	Arenas.build_world(_world3d, _env, _key_light, _rim_light, spec, _arena_nodes, _obstacles, _hazards, _spinners)
	AudioSfx.set_music_mode("minigame", "python3d_%d" % _world_idx)

	# Player init
	_p_head_node = _build_snake_head(true)
	_world3d.add_child(_p_head_node)
	_respawn_player_pose()
	for i in range(6):
		_add_player_seg()
	_rescale_segments(_p_nodes, true)
	_update_segments(_p_nodes, _p_trail, _p_total_dist)

	for _ei in range(int(spec["enemies"])):
		_spawn_enemy()
	for _fi in range(max(6, int(_half * 0.34))):
		_spawn_food()
	_spawn_powerup()

	_cam_yaw = _p_angle
	_snap_camera()
	_notify("СВІТ %d/18: %s" % [_world_idx + 1, str(spec["name"]).to_upper()])
	status_changed.emit("Світ %d/18: %s | Мета: 0/%d" % [_world_idx + 1, spec["name"], _target_quota])


func _respawn_player_pose() -> void:
	_p_pos = Vector2.ZERO
	_p_angle = 0.0
	_p_turn = 0.0
	_p_bank = 0.0
	_p_boost_energy = 100.0
	_p_total_dist = 0.0
	_p_last_pos = Vector2.ZERO
	_seed_trail(_p_trail, _p_pos, _p_angle)
	if is_instance_valid(_p_head_node):
		_p_head_node.position = Vector3(_p_pos.x, 0.45, _p_pos.y)
		_p_head_node.rotation = Vector3(0.0, -_p_angle, 0.0)


func _seed_trail(tr: Array[Dictionary], start: Vector2, yaw: float) -> void:
	tr.clear()
	var back := -_fwd2(yaw)
	for d in range(80, -1, -1):
		var db := float(d) * 0.1
		tr.append({"pos": start + back * db, "yaw": yaw, "bank": 0.0, "dist": -db})


func _record_trail(tr: Array[Dictionary], last_pos: Vector2, total_dist: float, pos: Vector2, yaw: float, bank: float, seg_cnt: int) -> Array:
	var dm := pos.distance_to(last_pos)
	if dm < 0.04:
		return [last_pos, total_dist]
	total_dist += dm
	tr.append({"pos": pos, "yaw": yaw, "bank": bank, "dist": total_dist})
	var cutoff := total_dist - (float(seg_cnt + 3) * SEG_DIST + 5.0)
	var cut := 0
	var lim := tr.size() - 4
	while cut < lim and float(tr[cut]["dist"]) < cutoff:
		cut += 1
	if cut > 0:
		for _k in range(cut):
			tr.remove_at(0)
	return [pos, total_dist]


func _sample_trail(tr: Array[Dictionary], target_d: float, fb_pos: Vector2, fb_yaw: float) -> Array:
	if tr.is_empty():
		return [fb_pos, fb_yaw, 0.0]
	var f0: Dictionary = tr[0]
	if target_d <= float(f0["dist"]):
		return [f0["pos"], float(f0["yaw"]), float(f0["bank"])]
	var f1: Dictionary = tr[tr.size() - 1]
	if target_d >= float(f1["dist"]):
		return [f1["pos"], float(f1["yaw"]), float(f1["bank"])]
	var lo := 0
	var hi := tr.size() - 1
	while lo <= hi:
		var mid := (lo + hi) >> 1
		if float(tr[mid]["dist"]) < target_d:
			lo = mid + 1
		else:
			hi = mid - 1
	var i2 := clampi(lo, 1, tr.size() - 1)
	var a: Dictionary = tr[i2 - 1]
	var b: Dictionary = tr[i2]
	var denom := float(b["dist"]) - float(a["dist"])
	var t := 0.0 if denom <= 0.0001 else clampf((target_d - float(a["dist"])) / denom, 0.0, 1.0)
	return [
		(a["pos"] as Vector2).lerp(b["pos"] as Vector2, t),
		lerp_angle(float(a["yaw"]), float(b["yaw"]), t),
		lerpf(float(a["bank"]), float(b["bank"]), t)
	]


func _build_snake_head(is_player: bool) -> Node3D:
	var root := Node3D.new()
	var sc_mat := _p_head_mat if is_player else _e_head_mat
	var sm := SphereMesh.new(); sm.radius = 0.5; sm.height = 1.0
	var skull := MeshInstance3D.new(); skull.mesh = sm; skull.material_override = sc_mat
	skull.scale = Vector3(HEAD_RAD * 1.95, HEAD_RAD * 1.52, HEAD_RAD * 2.35) if is_player else Vector3(HEAD_RAD * 1.90, HEAD_RAD * 1.48, HEAD_RAD * 2.28)
	root.add_child(skull)

	var sn_mat := sc_mat
	var snout := MeshInstance3D.new(); snout.mesh = sm; snout.material_override = sn_mat
	snout.scale = Vector3(0.68, 0.58, 0.65)
	snout.position = Vector3(0.0, -0.04, -0.44)
	root.add_child(snout)

	var brow_c := Color(0.14, 0.65, 0.29) if is_player else Color(0.47, 0.06, 0.08)
	var brow_m := Arenas.make_mat(brow_c, "", 0.4)
	var bm := BoxMesh.new(); bm.size = Vector3(0.24, 0.09, 0.38)
	var eye_c := Color(1.0, 0.96, 0.59) if is_player else Color(1.0, 0.86, 0.20)
	var eye_m := Arenas.make_mat(eye_c, "", 0.15, 0.0, 0.55)
	var pup_m := Arenas.make_mat(Color(0.06, 0.06, 0.06), "", 0.1)
	var horn_c := Color(0.71, 0.96, 0.43) if is_player else Color(1.0, 0.65, 0.16)
	var horn_m := Arenas.make_mat(horn_c, "", 0.3, 0.35, 0.2)
	var cm := CylinderMesh.new(); cm.top_radius = 0.0; cm.bottom_radius = 0.10; cm.height = 0.46 if is_player else 0.58; cm.radial_segments = 8

	for side in [-1.0, 1.0]:
		var br := MeshInstance3D.new(); br.mesh = bm; br.material_override = brow_m
		br.position = Vector3(side * 0.34, 0.34, -0.26)
		br.rotation_degrees = Vector3(-10, -side * 12, -side * 18)
		root.add_child(br)

		var hr := MeshInstance3D.new(); hr.mesh = cm; hr.material_override = horn_m
		hr.position = Vector3(side * 0.28, 0.42, 0.28)
		hr.rotation_degrees = Vector3(50, -side * 14, -side * 10)
		root.add_child(hr)

		var eye := MeshInstance3D.new(); eye.mesh = sm; eye.material_override = eye_m
		eye.scale = Vector3(0.28, 0.28, 0.28)
		eye.position = Vector3(side * 0.36, 0.25, -0.28)
		root.add_child(eye)

		var pup := MeshInstance3D.new(); pup.mesh = sm; pup.material_override = pup_m
		pup.scale = Vector3(0.34, 0.72, 0.45)
		pup.position = Vector3(0.0, 0.0, -0.36)
		eye.add_child(pup)

		var nos := MeshInstance3D.new(); nos.mesh = sm; nos.material_override = pup_m
		nos.scale = Vector3(0.11, 0.09, 0.11)
		nos.position = Vector3(side * 0.14, 0.06, -0.74)
		root.add_child(nos)

	if is_player:
		var tmat := Arenas.make_mat(Color(0.94, 0.24, 0.31), "", 0.25, 0.0, 0.35)
		var tongue := Node3D.new()
		tongue.position = Vector3(0.0, -0.07, -0.68)
		var tbm := BoxMesh.new(); tbm.size = Vector3(0.09, 0.025, 0.46)
		var tm := MeshInstance3D.new(); tm.mesh = tbm; tm.material_override = tmat; tm.position = Vector3(0, 0, -0.20)
		tongue.add_child(tm)
		var tfm := BoxMesh.new(); tfm.size = Vector3(0.04, 0.022, 0.18)
		for s in [-1.0, 1.0]:
			var tf := MeshInstance3D.new(); tf.mesh = tfm; tf.material_override = tmat
			tf.position = Vector3(s * 0.05, 0, -0.45); tf.rotation_degrees = Vector3(0, -s * 28, 0)
			tongue.add_child(tf)
		root.add_child(tongue)
		_p_tongue = tongue

		var sh_m := Arenas.make_mat(Color(0.0, 0.85, 1.0), "", 0.1, 0.1, 0.8, Vector2.ONE, 0.36)
		var sh := MeshInstance3D.new(); sh.mesh = sm; sh.material_override = sh_m; sh.scale = Vector3(2.35, 2.35, 2.35); sh.visible = false
		root.add_child(sh); _shield_mesh = sh

		var mag_m := Arenas.make_mat(Color(0.71, 0.20, 1.0), "", 0.1, 0.1, 0.9, Vector2.ONE, 0.32)
		var mag := MeshInstance3D.new(); mag.mesh = sm; mag.material_override = mag_m; mag.scale = Vector3(2.55, 2.55, 2.55); mag.visible = false
		root.add_child(mag); _magnet_mesh = mag

		var ring := MeshInstance3D.new(); var rbm := BoxMesh.new(); rbm.size = Vector3(2.8, 0.08, 2.8)
		ring.mesh = rbm; ring.material_override = Arenas.make_mat(Color(0.90, 0.43, 1.0), "", 0.2, 0.2, 1.1, Vector2.ONE, 0.65)
		ring.rotation_degrees = Vector3(25, 0, 25); ring.visible = false
		root.add_child(ring); _magnet_ring = ring
	else:
		var fang_m := Arenas.make_mat(Color(0.98, 0.96, 0.90), "", 0.2)
		var fm := CylinderMesh.new(); fm.top_radius = 0.0; fm.bottom_radius = 0.06; fm.height = 0.26; fm.radial_segments = 6
		for s in [-1.0, 1.0]:
			var fn := MeshInstance3D.new(); fn.mesh = fm; fn.material_override = fang_m
			fn.position = Vector3(s * 0.18, -0.18, -0.62); fn.rotation_degrees = Vector3(165, 0, 0)
			root.add_child(fn)
	return root


func _build_snake_seg(idx: int, is_player: bool) -> Node3D:
	var root := Node3D.new()
	var sm := SphereMesh.new(); sm.radius = SEG_RAD; sm.height = SEG_RAD * 2.0
	var body := MeshInstance3D.new(); body.mesh = sm
	body.material_override = _p_body_mats[idx % _p_body_mats.size()] if is_player else _e_body_mats[idx % _e_body_mats.size()]
	root.add_child(body)

	var ridge_c := (Color(0.57, 0.96, 0.45) if idx % 2 == 0 else Color(0.29, 0.84, 0.43)) if is_player else (Color(1.0, 0.57, 0.14) if idx % 2 == 0 else Color(0.76, 0.12, 0.14))
	var fm := CylinderMesh.new(); fm.top_radius = 0.0; fm.bottom_radius = 0.13; fm.height = 0.38; fm.radial_segments = 6 if is_player else 4
	var fin := MeshInstance3D.new(); fin.mesh = fm; fin.material_override = Arenas.make_mat(ridge_c, "", 0.35, 0.2)
	fin.position = Vector3(0.0, SEG_RAD * 0.82, 0.05)
	fin.rotation_degrees = Vector3(22.0, 0.0, 0.0)
	root.add_child(fin)
	return root


func _add_player_seg() -> void:
	var seg := _build_snake_seg(_p_nodes.size(), true)
	_world3d.add_child(seg)
	_p_nodes.append(seg)


func _rescale_segments(nodes: Array[Node3D], _is_player: bool) -> void:
	var cnt := nodes.size()
	for i in range(cnt):
		var t := float(i) / float(maxi(1, cnt - 1))
		var sc := lerpf(1.0, TAIL_MIN_SCALE, t)
		if is_instance_valid(nodes[i]):
			nodes[i].scale = Vector3(sc, sc * 0.9, sc)


func _update_segments(nodes: Array[Node3D], tr: Array[Dictionary], total_dist: float) -> void:
	if tr.is_empty():
		return
	var fb_pos: Vector2 = tr[0]["pos"]
	var fb_yaw: float = float(tr[0]["yaw"])
	for i in range(nodes.size()):
		var sn := nodes[i]
		if not is_instance_valid(sn):
			continue
		var s := _sample_trail(tr, total_dist - float(i + 1) * SEG_DIST, fb_pos, fb_yaw)
		var pos: Vector2 = s[0]
		var yaw: float = float(s[1])
		var bank: float = float(s[2])
		var ramp := minf(1.0, float(i + 1) / 4.0)
		var phase := total_dist * 1.75 - float(i) * 0.52
		var p3 := pos + _right2(yaw) * (sin(phase) * 0.24 * ramp)
		sn.position = Vector3(p3.x, 0.45, p3.y)
		sn.rotation = Vector3(0.0, -(yaw + deg_to_rad(cos(phase) * 13.5 * ramp)), (bank + deg_to_rad(sin(phase) * 4.5 * ramp)) * 0.7)


func _spawn_enemy() -> void:
	var lim := _half - 5.0
	var pos := Vector2(lim * 0.6, lim * 0.6)
	for _try in range(40):
		var cand := Vector2(randf_range(-lim, lim), randf_range(-lim, lim))
		if cand.distance_to(_p_pos) < 13.0:
			continue
		if not _hits_obstacle(cand, 2.2):
			pos = cand
			break
	var yaw := randf_range(0.0, TAU)
	var e_len := 6 + _world_idx / 3
	var head := _build_snake_head(false)
	head.position = Vector3(pos.x, 0.45, pos.y)
	head.rotation.y = -yaw
	_world3d.add_child(head)

	var tr: Array[Dictionary] = []
	_seed_trail(tr, pos, yaw)
	var nodes: Array[Node3D] = []
	for i in range(e_len):
		var seg := _build_snake_seg(i, false)
		_world3d.add_child(seg)
		nodes.append(seg)
	_rescale_segments(nodes, false)
	_update_segments(nodes, tr, 0.0)
	_enemies.append({
		"pos": pos, "last_pos": pos, "yaw": yaw, "turn": 0.0, "bank": 0.0,
		"total_dist": 0.0, "trail": tr, "head": head, "nodes": nodes,
		"wander_t": 0.0, "wander_turn": 0.0, "t_turbo": 0.0, "t_slow": 0.0
	})


func _hits_obstacle(pos: Vector2, pad: float) -> bool:
	for ob in _obstacles:
		if pos.distance_to(ob["pos"] as Vector2) < float(ob["rad"]) + pad:
			return true
	for hz in _hazards:
		if pos.distance_to(hz["pos"] as Vector2) < float(hz["rad"]) + pad:
			return true
	return false


func _valid_spawn_pos(min_p_dist: float = 4.5) -> Vector2:
	var lim := _half - 2.6
	for _t in range(45):
		var p := Vector2(randf_range(-lim, lim), randf_range(-lim, lim))
		if p.distance_to(_p_pos) < min_p_dist or _hits_obstacle(p, 1.5):
			continue
		var crowd := false
		for f in _foods:
			if p.distance_to(f["pos"] as Vector2) < 2.2:
				crowd = true; break
		if not crowd:
			return p
	return Vector2(randf_range(-lim, lim), randf_range(-lim, lim))


func _spawn_food(fixed_pos: Vector2 = Vector2(999, 999), forced_kind: String = "") -> void:
	var table := [
		["apple", "Яблуко", Color(0.92, 0.18, 0.18), 10, 1, 1],
		["pear", "Груша", Color(0.69, 0.84, 0.18), 15, 1, 1],
		["banana", "Банан", Color(1.0, 0.86, 0.14), 20, 1, 1],
		["orange", "Апельсин", Color(1.0, 0.53, 0.06), 20, 1, 1],
		["strawberry", "Полуниця", Color(0.94, 0.14, 0.24), 25, 1, 2],
		["watermelon", "Кавун", Color(0.96, 0.16, 0.27), 30, 2, 2],
		["cherries", "Вишні", Color(0.86, 0.08, 0.19), 35, 2, 2],
		["pineapple", "Ананас", Color(0.92, 0.65, 0.10), 45, 2, 3],
		["starfruit", "Зірка", Color(1.0, 0.90, 0.18), 50, 2, 4],
		["golden", "Золоте яблуко", Color(1.0, 0.84, 0.0), 60, 3, 5]
	]
	var pick: Array = table[randi() % (table.size() - 1)]
	if forced_kind != "":
		for entry in table:
			if entry[0] == forced_kind:
				pick = entry; break
	var p := fixed_pos if fixed_pos.x < 900.0 else _valid_spawn_pos()
	var col: Color = pick[2]
	var node := _make_collectible_node(str(pick[0]), col)
	node.position = Vector3(p.x, 0.55, p.y)
	_world3d.add_child(node)
	_foods.append({"pos": p, "kind": str(pick[0]), "name": str(pick[1]), "pts": int(pick[3]), "grow": int(pick[4]), "quota": int(pick[5]), "col": col, "node": node, "is_pw": false, "life": 22.0 if pick[0] == "golden" else -1.0, "phase": randf_range(0.0, TAU)})


func _spawn_powerup() -> void:
	var table := [
		["speed", "ТУРБО (+25%)", Color(1.0, 0.55, 0.08), 0, 0],
		["slow", "СПОВІЛЬНЕННЯ", Color(0.0, 0.86, 1.0), 0, 0],
		["magnet", "МАГНІТ", Color(0.67, 0.18, 0.96), 0, 0],
		["shield", "ЗАХИСНИЙ ЩИТ", Color(0.0, 0.71, 1.0), 0, 0],
		["life", "+1 ЖИТТЯ", Color(1.0, 0.18, 0.33), 0, 0],
		["mega_food", "МЕГА-КАВУН (+6 ЇЖІ)", Color(1.0, 0.82, 0.16), 3, 6]
	]
	var pk: Array = table[randi() % table.size()]
	var p := _valid_spawn_pos()
	var col: Color = pk[2]
	var node := _make_collectible_node(str(pk[0]), col)
	node.position = Vector3(p.x, 0.65, p.y)
	_world3d.add_child(node)
	_foods.append({"pos": p, "kind": str(pk[0]), "name": str(pk[1]), "pts": 25 if pk[0] != "mega_food" else 100, "grow": int(pk[3]), "quota": int(pk[4]), "col": col, "node": node, "is_pw": true, "life": 18.0, "phase": randf_range(0.0, TAU)})


func _make_collectible_node(kind: String, col: Color) -> Node3D:
	var root := Node3D.new()
	var am := CylinderMesh.new(); am.top_radius = 0.52; am.bottom_radius = 0.52; am.height = 0.03; am.radial_segments = 12
	var aura := MeshInstance3D.new(); aura.mesh = am; aura.material_override = Arenas.make_mat(col, "", 0.2, 0.0, 1.1, Vector2.ONE, 0.32)
	aura.position = Vector3(0.0, -0.38, 0.0); root.add_child(aura)

	var m := Arenas.make_mat(col, "", 0.25, 0.15, 0.45)
	var sm := SphereMesh.new(); sm.radius = 0.5; sm.height = 1.0
	var lf_m := Arenas.make_mat(Color(0.18, 0.80, 0.24), "", 0.4)
	var st_m := Arenas.make_mat(Color(0.42, 0.24, 0.12), "", 0.7)
	match kind:
		"apple", "golden", "orange":
			var sc := 1.04 if kind == "golden" else 0.88
			var sp := MeshInstance3D.new(); sp.mesh = sm; sp.material_override = m; sp.scale = Vector3(sc, sc * 0.94, sc); root.add_child(sp)
			var st := MeshInstance3D.new(); var scm := CylinderMesh.new(); scm.top_radius = 0.04; scm.bottom_radius = 0.05; scm.height = 0.32
			st.mesh = scm; st.material_override = st_m; st.position = Vector3(0, sc * 0.52, 0); root.add_child(st)
			var lf := MeshInstance3D.new(); lf.mesh = sm; lf.material_override = lf_m; lf.scale = Vector3(0.32, 0.08, 0.18); lf.position = Vector3(0.16, sc * 0.56, 0); root.add_child(lf)
			if kind == "golden":
				var rm := BoxMesh.new(); rm.size = Vector3(1.36, 0.07, 1.36)
				var h := MeshInstance3D.new(); h.mesh = rm; h.material_override = Arenas.make_mat(Color(1.0, 1.0, 0.65), "", 0.1, 0.2, 1.4, Vector2.ONE, 0.75)
				h.rotation_degrees = Vector3(32, 0, 32); root.add_child(h)
		"pear":
			var b := MeshInstance3D.new(); b.mesh = sm; b.material_override = m; b.scale = Vector3(0.84, 0.78, 0.84); root.add_child(b)
			var t := MeshInstance3D.new(); t.mesh = sm; t.material_override = m; t.scale = Vector3(0.56, 0.62, 0.56); t.position = Vector3(0, 0.40, 0); root.add_child(t)
		"banana":
			for seg in [[-0.28, 0.12, -28.0], [0.0, 0.0, 0.0], [0.28, 0.12, 28.0]]:
				var c := MeshInstance3D.new(); var cm := CylinderMesh.new(); cm.top_radius = 0.13; cm.bottom_radius = 0.13; cm.height = 0.48
				c.mesh = cm; c.material_override = m; c.position = Vector3(seg[0], seg[1], 0); c.rotation_degrees = Vector3(0, 0, seg[2]); root.add_child(c)
		"watermelon":
			var cm := CylinderMesh.new(); cm.top_radius = 0.52; cm.bottom_radius = 0.52; cm.height = 0.20; cm.radial_segments = 14
			var r := MeshInstance3D.new(); r.mesh = cm; r.material_override = lf_m; r.rotation_degrees = Vector3(90, 0, 0); root.add_child(r)
			var p := MeshInstance3D.new(); var pm := CylinderMesh.new(); pm.top_radius = 0.42; pm.bottom_radius = 0.42; pm.height = 0.24
			p.mesh = pm; p.material_override = m; p.rotation_degrees = Vector3(90, 0, 0); root.add_child(p)
		"cherries":
			for sx in [-0.24, 0.24]:
				var c := MeshInstance3D.new(); c.mesh = sm; c.material_override = m; c.scale = Vector3(0.52, 0.52, 0.52); c.position = Vector3(sx, -0.06, 0); root.add_child(c)
		"strawberry", "pineapple", "starfruit":
			var b := MeshInstance3D.new(); var bm := CylinderMesh.new(); bm.top_radius = 0.42 if kind == "strawberry" else 0.32; bm.bottom_radius = 0.10 if kind == "strawberry" else 0.38; bm.height = 0.88
			b.mesh = bm; b.material_override = m; root.add_child(b)
			var cr := MeshInstance3D.new(); cr.mesh = sm; cr.material_override = lf_m; cr.scale = Vector3(0.75, 0.24, 0.75); cr.position = Vector3(0, 0.46, 0); root.add_child(cr)
		_:
			var pm := Arenas.make_mat(col, "crystal_facet.png" if kind == "slow" else "", 0.15, 0.4, 1.4)
			var box := BoxMesh.new(); box.size = Vector3(0.68, 0.68, 0.68)
			var core := MeshInstance3D.new(); core.mesh = box if kind != "shield" and kind != "life" and kind != "mega_food" else sm
			core.material_override = pm; core.scale = Vector3.ONE if core.mesh == box else Vector3(0.86, 0.86, 0.86)
			core.rotation_degrees = Vector3(45, 45, 45); root.add_child(core)
			var orb := MeshInstance3D.new(); var ob := BoxMesh.new(); ob.size = Vector3(1.18, 0.07, 1.18)
			orb.mesh = ob; orb.material_override = Arenas.make_mat(col.lightened(0.3), "", 0.1, 0.3, 1.6, Vector2.ONE, 0.75)
			orb.rotation_degrees = Vector3(28, 0, 28); root.add_child(orb)
	return root


func _spawn_burst(pos: Vector3, col: Color, cnt: int = 8) -> void:
	if _bursts.size() >= 4:
		var old: Dictionary = _bursts.pop_front()
		for pn: Node3D in old["nodes"]:
			if is_instance_valid(pn): pn.queue_free()
	var bm := BoxMesh.new(); bm.size = Vector3(0.18, 0.18, 0.18)
	var bmat := Arenas.make_mat(col, "", 0.2, 0.0, 1.4)
	var nodes: Array[Node3D] = []
	var vels: Array[Vector3] = []
	for _i in range(cnt):
		var mi := MeshInstance3D.new(); mi.mesh = bm; mi.material_override = bmat
		mi.position = pos + Vector3(randf_range(-0.15, 0.15), randf_range(0.0, 0.2), randf_range(-0.15, 0.15))
		_world3d.add_child(mi)
		nodes.append(mi)
		vels.append(Vector3(randf_range(-4.0, 4.0), randf_range(3.0, 6.5), randf_range(-4.0, 4.0)))
	_bursts.append({"nodes": nodes, "vels": vels, "t": 0.0})


func _notify(msg: String) -> void:
	_banner_txt = msg
	_banner_t = 2.4


func _adjust_zoom(d: float) -> void:
	_zoom = clampf(_zoom + d, 0.60, 2.60)
	_hud.queue_redraw()


func handle_input_event(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			_adjust_zoom(-0.15); return
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_adjust_zoom(0.15); return
	super.handle_input_event(event)


func on_mouse_click(pos: Vector2) -> void:
	if BTN_PREV_WORLD.has_point(pos):
		AudioSfx.play_ui_click()
		_load_world((_world_idx - 1 + Arenas.WORLD_SPECS.size()) % Arenas.WORLD_SPECS.size())
	elif BTN_NEXT_WORLD.has_point(pos):
		AudioSfx.play_ui_click()
		_load_world((_world_idx + 1) % Arenas.WORLD_SPECS.size())


func on_key_pressed(phys_key: int) -> void:
	match phys_key:
		KEY_C:
			_cam_mode = (_cam_mode + 1) % 3
			AudioSfx.play_ui_click()
			_snap_camera()
		KEY_EQUAL, KEY_KP_ADD, KEY_PAGEUP:
			_adjust_zoom(-0.15)
		KEY_MINUS, KEY_KP_SUBTRACT, KEY_PAGEDOWN:
			_adjust_zoom(0.15)
		KEY_BRACKETLEFT:
			_load_world((_world_idx - 1 + Arenas.WORLD_SPECS.size()) % Arenas.WORLD_SPECS.size())
		KEY_BRACKETRIGHT:
			_load_world((_world_idx + 1) % Arenas.WORLD_SPECS.size())


func step_game(delta: float) -> void:
	if game_over:
		return
	var dt := minf(delta, 0.05)
	_elapsed += dt
	if _clear_wait > 0.0:
		_clear_wait -= dt
		if _clear_wait <= 0.0:
			_load_world((_world_idx + 1) % Arenas.WORLD_SPECS.size())
		_hud.queue_redraw()
		return

	_t_shield = maxf(0.0, _t_shield - dt)
	_t_magnet = maxf(0.0, _t_magnet - dt)
	_t_turbo = maxf(0.0, _t_turbo - dt)
	_t_slow = maxf(0.0, _t_slow - dt)
	_t_immune = maxf(0.0, _t_immune - dt)
	_banner_t = maxf(0.0, _banner_t - dt)

	# Spinners & dynamic arena hazards
	for sp in _spinners:
		var sn: Node3D = sp["node"]
		if is_instance_valid(sn):
			sn.rotation.y += deg_to_rad(float(sp["speed"])) * dt
	for hz in _hazards:
		var hn: Node3D = hz["node"]
		if not is_instance_valid(hn): continue
		if str(hz["kind"]) == "laser":
			hz["phase"] = float(hz["phase"]) + dt * float(hz["speed"])
			var u := (sin(float(hz["phase"])) + 1.0) * 0.5
			var wp := (hz["p1"] as Vector3).lerp(hz["p2"] as Vector3, u)
			hn.position = wp
			hn.rotation.y += deg_to_rad(45.0) * dt
			hz["pos"] = Vector2(wp.x, wp.z)
		else:
			hn.rotation.y += deg_to_rad(float(hz["rot_speed"])) * dt

	# Player steering & physics
	var turn_in := 0.0
	if _keys_held.get(KEY_D, false) or _keys_held.get(KEY_RIGHT, false): turn_in += 1.0
	if _keys_held.get(KEY_A, false) or _keys_held.get(KEY_LEFT, false): turn_in -= 1.0
	_p_turn = move_toward(_p_turn, turn_in, dt * 14.0)
	_p_angle += _p_turn * TURN_SPEED * dt
	_p_bank = lerpf(_p_bank, -_p_turn * MAX_BANK, clampf(dt * 8.0, 0.0, 1.0))

	var boosting: bool = (bool(_keys_held.get(KEY_SPACE, false)) or bool(_keys_held.get(KEY_SHIFT, false))) and _p_boost_energy > 2.0
	_p_boost_energy = maxf(0.0, _p_boost_energy - 35.0 * dt) if boosting else minf(100.0, _p_boost_energy + 20.0 * dt)

	var spd := _base_speed * (BOOST_RATIO if boosting else 1.0)
	if _t_turbo > 0.0: spd *= 1.25
	if _t_slow > 0.0: spd *= 0.75
	_p_pos += _fwd2(_p_angle) * spd * dt

	var tr_res := _record_trail(_p_trail, _p_last_pos, _p_total_dist, _p_pos, _p_angle, _p_bank, _p_nodes.size())
	_p_last_pos = tr_res[0]; _p_total_dist = float(tr_res[1])

	if is_instance_valid(_p_head_node):
		_p_head_node.position = Vector3(_p_pos.x, 0.45, _p_pos.y)
		_p_head_node.rotation = Vector3(0.0, -_p_angle, _p_bank)
		var vis := true if _t_immune <= 0.0 else (int(_t_immune * 12.0) % 2 == 0)
		_p_head_node.visible = vis
		for sn in _p_nodes:
			if is_instance_valid(sn): sn.visible = vis
	if is_instance_valid(_p_tongue):
		var flick := 0.5 + 0.35 * sin(_elapsed * 12.0)
		_p_tongue.visible = flick > 0.65
		_p_tongue.scale.z = 0.8 + (flick - 0.65) * 1.8
	if is_instance_valid(_shield_mesh):
		_shield_mesh.visible = _t_shield > 0.0
		_shield_mesh.scale = Vector3.ONE * (2.35 + 0.16 * sin(_elapsed * 8.0))
	if is_instance_valid(_magnet_mesh):
		_magnet_mesh.visible = _t_magnet > 0.0
		_magnet_ring.visible = _t_magnet > 0.0
		_magnet_ring.rotation.y += dt * 3.0
	_update_segments(_p_nodes, _p_trail, _p_total_dist)

	# World wall & obstacle collision
	var invuln := _t_immune > 0.0
	if absf(_p_pos.x) > _half - 0.45 or absf(_p_pos.y) > _half - 0.45 or _hits_obstacle(_p_pos, HEAD_RAD * 0.72):
		if _t_shield > 0.0 and not invuln:
			_break_shield()
			_p_pos = _p_pos.clamp(Vector2(-_half + 1.2, -_half + 1.2), Vector2(_half - 1.2, _half - 1.2))
		elif not invuln:
			_lose_life(); return

	# Self-tail bite! Cuts own tail into loot instead of instant death
	if not invuln and _p_nodes.size() >= 8:
		var self_th := (HEAD_RAD + SEG_RAD) * 0.70
		for si in range(7, _p_nodes.size()):
			var sp := Vector2(_p_nodes[si].position.x, _p_nodes[si].position.z)
			if _p_pos.distance_to(sp) < self_th:
				var cut_pos := _cut_snake_tail(_p_nodes, si, 3)
				_drop_tail_loot(cut_pos)
				_t_immune = 1.0
				_notify("✂ ВІДКУШЕНО ХВІСТ (-%d)" % cut_pos.size())
				break

	# Items, spawners & bursts
	_step_foods_and_bursts(dt)

	# AI enemies (5-whisker navigation) + Tail Severing PvE
	_step_enemies(dt, invuln)

	# Smooth non-whipping Camera
	_update_camera(dt)

	if _eaten_quota >= _target_quota:
		add_score(250)
		_best_score = maxi(_best_score, score)
		AudioSfx.play_fanfare()
		_notify("★ СВІТ %d ПРОЙДЕНО! ★" % [_world_idx + 1])
		_clear_wait = 1.4
		return

	_best_score = maxi(_best_score, score)
	var spec: Dictionary = Arenas.WORLD_SPECS[_world_idx]
	status_changed.emit("Світ %d/18: %s | Життя: %d | Ціль: %d/%d | Турбо: %d%%" % [_world_idx + 1, spec["name"], _lives, _eaten_quota, _target_quota, int(_p_boost_energy)])
	_hud.queue_redraw()


func _step_foods_and_bursts(dt: float) -> void:
	_t_golden -= dt
	if _t_golden <= 0.0:
		_spawn_food(Vector2(999, 999), "golden")
		_t_golden = randf_range(14.0, 22.0)
	_t_powerup -= dt
	if _t_powerup <= 0.0:
		var pws := 0
		for f in _foods:
			if bool(f["is_pw"]): pws += 1
		if pws < 2:
			_spawn_powerup()
		_t_powerup = randf_range(12.0, 20.0)

	var p_rad := HEAD_RAD + (1.3 if _t_magnet > 0.0 else 0.65)
	for fi in range(_foods.size() - 1, -1, -1):
		var f: Dictionary = _foods[fi]
		var fn: Node3D = f["node"]
		if float(f["life"]) > 0.0:
			f["life"] = float(f["life"]) - dt
			if float(f["life"]) <= 0.0:
				if is_instance_valid(fn): fn.queue_free()
				_foods.remove_at(fi); continue
		var fp: Vector2 = f["pos"]
		if _t_magnet > 0.0 and fp.distance_to(_p_pos) < MAGNET_RADIUS:
			fp = fp.move_toward(_p_pos, dt * maxf(18.0, (MAGNET_RADIUS - fp.distance_to(_p_pos)) * 2.8 + 14.0))
			f["pos"] = fp
		if is_instance_valid(fn):
			fn.position = Vector3(fp.x, 0.55 + sin(_elapsed * 3.5 + float(f["phase"])) * 0.18, fp.y)
			fn.rotation.y += dt * 1.6
		if fp.distance_to(_p_pos) < p_rad:
			_collect_item(f, fi, true); continue
		for e in _enemies:
			if fp.distance_to(e["pos"] as Vector2) < HEAD_RAD + 0.65:
				_collect_item(f, fi, false, e); break

	var regular := 0
	for f in _foods:
		if not bool(f["is_pw"]): regular += 1
	while regular < maxi(6, int(_half * 0.34)):
		_spawn_food(); regular += 1

	for bi in range(_bursts.size() - 1, -1, -1):
		var b: Dictionary = _bursts[bi]
		b["t"] = float(b["t"]) + dt
		if float(b["t"]) >= 0.42:
			for pn: Node3D in b["nodes"]:
				if is_instance_valid(pn): pn.queue_free()
			_bursts.remove_at(bi); continue
		var bnodes: Array = b["nodes"]; var bvels: Array = b["vels"]
		for k in range(bnodes.size()):
			bvels[k].y -= 14.0 * dt
			(bnodes[k] as Node3D).position += (bvels[k] as Vector3) * dt
			(bnodes[k] as Node3D).scale *= maxf(0.0, 1.0 - dt * 4.2)


func _collect_item(f: Dictionary, fi: int, by_player: bool, enemy: Dictionary = {}) -> void:
	var fp: Vector2 = f["pos"]
	_spawn_burst(Vector3(fp.x, 0.5, fp.y), f["col"] as Color, 8)
	var kind := str(f["kind"])
	var fn: Node3D = f["node"]
	if is_instance_valid(fn): fn.queue_free()
	_foods.remove_at(fi)

	if not by_player:
		if kind == "speed": enemy["t_turbo"] = 10.0
		elif kind == "slow": enemy["t_slow"] = 10.0
		else:
			var enodes: Array[Node3D] = enemy["nodes"]
			for _g in range(int(f["grow"])):
				var seg := _build_snake_seg(enodes.size(), false)
				_world3d.add_child(seg); enodes.append(seg)
			_rescale_segments(enodes, false)
		return

	add_score(int(f["pts"]))
	_eaten_quota += int(f["quota"])
	for _g in range(int(f["grow"])):
		_add_player_seg()
	if int(f["grow"]) > 0:
		_rescale_segments(_p_nodes, true)
	match kind:
		"speed": _t_turbo = 10.0; _t_immune = maxf(_t_immune, 2.0); AudioSfx.play_powerup(); _notify("⚡ ТУРБО (+25% на 10с)")
		"slow": _t_slow = 10.0; _t_immune = maxf(_t_immune, 2.0); AudioSfx.play_powerup(); _notify("❄ СПОВІЛЬНЕННЯ (-25%)")
		"magnet": _t_magnet = 10.0; _t_immune = maxf(_t_immune, 2.0); AudioSfx.play_powerup(); _notify("🧲 МАГНІТ ЇЖІ (10с)")
		"shield": _t_shield = 12.0; _t_immune = maxf(_t_immune, 2.0); AudioSfx.play_powerup(); _notify("🛡 ЗАХИСНИЙ ЩИТ (12с)")
		"life": _lives = mini(MAX_LIVES, _lives + 1); _t_immune = maxf(_t_immune, 2.5); AudioSfx.play_powerup(); _notify("♥ +1 ЖИТТЯ!")
		"golden", "mega_food": _t_immune = maxf(_t_immune, 2.2); AudioSfx.play_coin(); _notify("★ %s (+%d)" % [str(f["name"]).to_upper(), int(f["pts"])])
		_: AudioSfx.play_marble_pop(1)


func _step_enemies(dt: float, invuln: bool) -> void:
	for ei in range(_enemies.size() - 1, -1, -1):
		var e: Dictionary = _enemies[ei]
		var epos: Vector2 = e["pos"]
		var eyaw := float(e["yaw"])
		e["t_turbo"] = maxf(0.0, float(e["t_turbo"]) - dt)
		e["t_slow"] = maxf(0.0, float(e["t_slow"]) - dt)

		# 5-ray Whisker obstacle avoidance [-65, -32, 0, +32, +65] deg
		var ws := [100.0, 100.0, 100.0, 100.0, 100.0]
		var angles := [-65.0, -32.0, 0.0, 32.0, 65.0]
		for wi in range(5):
			var dvec := _fwd2(eyaw + deg_to_rad(float(angles[wi])))
			for si in range(1, 7):
				var dst := float(si) / 6.0 * 7.8
				var sp := epos + dvec * dst
				var blocked := absf(sp.x) >= _half - 1.3 or absf(sp.y) >= _half - 1.3 or _hits_obstacle(sp, 0.85)
				if not blocked and _t_immune <= 0.0:
					for ps in _p_nodes:
						if sp.distance_to(Vector2(ps.position.x, ps.position.z)) < 1.1:
							blocked = true; break
				if blocked:
					ws[wi] = dst / 7.8 * 100.0; break

		var t_turn := 0.0
		var l_clr := minf(ws[0], ws[1])
		var r_clr := minf(ws[3], ws[4])
		if ws[2] < 75.0 or ws[1] < 60.0 or ws[3] < 60.0:
			t_turn = -1.0 if l_clr > r_clr else 1.0
		else:
			var best_f: Vector2 = Vector2.ZERO; var best_d := 14.5; var found := false
			for f in _foods:
				var d := epos.distance_to(f["pos"] as Vector2)
				if d < best_d: best_d = d; best_f = f["pos"] as Vector2; found = true
			if found:
				var fdir := (best_f - epos).normalized()
				var wanted := atan2(fdir.x, -fdir.y)
				t_turn = clampf(angle_difference(eyaw, wanted) / deg_to_rad(32.0), -1.0, 1.0)
			else:
				e["wander_t"] = float(e["wander_t"]) - dt
				if float(e["wander_t"]) <= 0.0:
					e["wander_turn"] = randf_range(-0.55, 0.55)
					e["wander_t"] = randf_range(1.0, 2.2)
				t_turn = float(e["wander_turn"])

		var cur_t := lerpf(float(e["turn"]), t_turn, clampf(dt * 7.5, 0.0, 1.0))
		e["turn"] = cur_t
		eyaw += cur_t * deg_to_rad(140.0) * dt
		e["yaw"] = eyaw
		var ebank := lerpf(float(e["bank"]), -cur_t * deg_to_rad(16.0), clampf(dt * 6.0, 0.0, 1.0))
		e["bank"] = ebank
		var espd := (7.4 + float(_world_idx) * 0.32) * (1.25 if float(e["t_turbo"]) > 0.0 else (0.75 if float(e["t_slow"]) > 0.0 else 1.0))
		epos += _fwd2(eyaw) * espd * dt
		e["pos"] = epos

		if absf(epos.x) >= _half - 0.4 or absf(epos.y) >= _half - 0.4 or _hits_obstacle(epos, HEAD_RAD * 0.72):
			_kill_enemy(ei); continue

		var enodes: Array[Node3D] = e["nodes"]
		var tr_res := _record_trail(e["trail"] as Array[Dictionary], e["last_pos"] as Vector2, float(e["total_dist"]), epos, eyaw, ebank, enodes.size())
		e["last_pos"] = tr_res[0]; e["total_dist"] = float(tr_res[1])
		var ehead: Node3D = e["head"]
		if is_instance_valid(ehead):
			ehead.position = Vector3(epos.x, 0.45, epos.y)
			ehead.rotation = Vector3(0.0, -eyaw, ebank)
		_update_segments(enodes, e["trail"] as Array[Dictionary], float(e["total_dist"]))

		# PvE Tail Severing & Collisions
		if _p_pos.distance_to(epos) < HEAD_RAD * 1.70:
			if _t_shield > 0.0 or invuln:
				if _t_shield > 0.0 and not invuln: _break_shield()
				_kill_enemy(ei); add_score(50); continue
			_lose_life(); return

		var bit := false
		for si in range(enodes.size()):
			var sp := Vector2(enodes[si].position.x, enodes[si].position.z)
			if _p_pos.distance_to(sp) < (HEAD_RAD + SEG_RAD) * 0.78:
				if si <= 1 or enodes.size() <= 3:
					_kill_enemy(ei); add_score(100); _notify("💥 ВОРОГА ЗНИЩЕНО! (+100)")
				else:
					var cuts := _cut_snake_tail(enodes, si, 2)
					_drop_tail_loot(cuts)
					add_score(cuts.size() * 15)
					AudioSfx.play_brick_break()
					_notify("✂ ВІДКУШЕНО ХВІСТ ВОРОГА! (+%d)" % [cuts.size() * 15])
				_t_immune = maxf(_t_immune, 0.65)
				bit = true; break
		if bit:
			continue
		if not invuln:
			for psi in range(_p_nodes.size()):
				if epos.distance_to(Vector2(_p_nodes[psi].position.x, _p_nodes[psi].position.z)) < (HEAD_RAD + SEG_RAD) * 0.75:
					if _t_shield > 0.0:
						_break_shield(); _kill_enemy(ei); break
					elif _p_nodes.size() > 4 and psi >= 3:
						var cuts := _cut_snake_tail(_p_nodes, psi, 3)
						_drop_tail_loot(cuts); _t_immune = 1.4; _notify("⚠ ВОРОГ ВКУСИВ ВАШ ХВІСТ!"); break
					else:
						_lose_life(); return


func _cut_snake_tail(nodes: Array[Node3D], hit_idx: int, min_keep: int) -> Array[Vector2]:
	var cut := maxi(min_keep, hit_idx)
	var out: Array[Vector2] = []
	for k in range(nodes.size() - 1, cut - 1, -1):
		var dn := nodes[k]
		if is_instance_valid(dn):
			out.append(Vector2(dn.position.x, dn.position.z))
			dn.queue_free()
		nodes.remove_at(k)
	_rescale_segments(nodes, true)
	return out


func _drop_tail_loot(positions: Array[Vector2]) -> void:
	for i in range(positions.size()):
		if i % 2 == 0 and _foods.size() < 28:
			_spawn_food(positions[i])
	if not positions.is_empty():
		_spawn_burst(Vector3(positions[0].x, 0.5, positions[0].y), Color(1.0, 0.5, 0.2), 10)


func _kill_enemy(ei: int) -> void:
	var e: Dictionary = _enemies[ei]
	var pts: Array[Vector2] = [e["pos"] as Vector2]
	for sn: Node3D in e["nodes"]:
		if is_instance_valid(sn):
			pts.append(Vector2(sn.position.x, sn.position.z))
			sn.queue_free()
	if is_instance_valid(e["head"]):
		(e["head"] as Node3D).queue_free()
	_enemies.remove_at(ei)
	_drop_tail_loot(pts)
	AudioSfx.play_brick_break()
	_spawn_enemy()


func _break_shield() -> void:
	_t_shield = 0.0
	_t_immune = maxf(_t_immune, 1.2)
	_spawn_burst(Vector3(_p_pos.x, 0.6, _p_pos.y), Color(0.0, 0.85, 1.0), 12)
	AudioSfx.play_hit()


func _lose_life() -> void:
	_lives -= 1
	AudioSfx.play_hit()
	_spawn_burst(Vector3(_p_pos.x, 0.6, _p_pos.y), Color(0.25, 0.95, 0.45), 14)
	if _lives <= 0:
		game_over = true
		status_changed.emit("Гру завершено! Рахунок: %d | [R] — заново" % score)
		_hud.queue_redraw()
		return
	_respawn_player_pose()
	_t_immune = 2.5
	_update_segments(_p_nodes, _p_trail, _p_total_dist)
	_snap_camera()
	_notify("♥ -1 ЖИТТЯ (Залишилось: %d)" % _lives)


func _snap_camera() -> void:
	_cam_yaw = _p_angle
	_cam.global_position = _chase_target_pos()
	_update_camera(1.0)


func _chase_target_pos() -> Vector3:
	var f := _fwd2(_cam_yaw)
	return Vector3(_p_pos.x - f.x * (19.0 * _zoom), 13.5 * _zoom, _p_pos.y - f.y * (19.0 * _zoom))


func _update_camera(dt: float) -> void:
	match _cam_mode:
		0:
			_cam_yaw = lerp_angle(_cam_yaw, _p_angle, clampf(dt * 6.5, 0.0, 1.0))
			_cam.global_position = _cam.global_position.lerp(_chase_target_pos(), clampf(dt * 10.0, 0.0, 1.0))
			_cam.look_at(Vector3(_p_pos.x, 0.85, _p_pos.y), Vector3.UP)
		1:
			var tp := Vector3(_p_pos.x * 0.25, 42.0 * _zoom, _p_pos.y * 0.25 + 14.0 * _zoom)
			_cam.global_position = _cam.global_position.lerp(tp, clampf(dt * 6.0, 0.0, 1.0))
			_cam.look_at(Vector3(_p_pos.x * 0.25, 0.0, _p_pos.y * 0.25), Vector3.UP)
		2:
			var f := _fwd2(_p_angle)
			var eye := Vector3(_p_pos.x + f.x * 0.45, 0.88, _p_pos.y + f.y * 0.45)
			_cam.global_position = eye
			_cam.look_at(eye + Vector3(f.x * 10.0, -0.5, f.y * 10.0), Vector3.UP)


func _draw_hud() -> void:
	var f := ThemeDB.fallback_font
	var spec: Dictionary = Arenas.WORLD_SPECS[_world_idx]
	_hud.draw_rect(Rect2(0, 0, 640, 42), Color(0.04, 0.06, 0.10, 0.84))
	draw_ui_btn(_hud, BTN_PREV_WORLD, "◀")
	draw_ui_btn(_hud, BTN_NEXT_WORLD, "▶")
	_hud.draw_string(f, Vector2(34, 21), "%d/18: %s" % [_world_idx + 1, str(spec["name"])], HORIZONTAL_ALIGNMENT_LEFT, 168, 12, Color(1.0, 0.86, 0.40))

	# Progress bar
	var prog := clampf(float(_eaten_quota) / float(maxi(1, _target_quota)), 0.0, 1.0)
	_hud.draw_rect(Rect2(34, 28, 168, 8), Color(0.16, 0.18, 0.26))
	_hud.draw_rect(Rect2(34, 28, 168.0 * prog, 8), Color(0.20, 0.88, 0.42))
	_hud.draw_string(f, Vector2(210, 36), "%d/%d" % [_eaten_quota, _target_quota], HORIZONTAL_ALIGNMENT_LEFT, 48, 10, Color(0.90, 0.95, 0.92))

	# Lives center card
	_hud.draw_rect(Rect2(262, 5, 138, 32), Color(0.11, 0.05, 0.08, 0.92))
	_hud.draw_rect(Rect2(262, 5, 138, 32), Color(0.95, 0.28, 0.35, 0.6), false, 1.2)
	_hud.draw_string(f, Vector2(268, 25), "ЖИТТЯ %d/%d" % [maxi(0, _lives), MAX_LIVES], HORIZONTAL_ALIGNMENT_LEFT, 74, 11, Color(1.0, 0.36, 0.44))
	for li in range(MAX_LIVES):
		var c := Vector2(347.0 + float(li) * 11.0, 21.0)
		var pts := PackedVector2Array([c + Vector2(0, -4.5), c + Vector2(4.5, 0), c + Vector2(0, 4.5), c + Vector2(-4.5, 0)])
		_hud.draw_colored_polygon(pts, Color(1.0, 0.24, 0.34) if li < _lives else Color(0.22, 0.22, 0.28))

	# Camera / enemies / best right block
	var cam_n := str(["3-тя особа", "Зверху", "1-ша особа"][_cam_mode])
	_hud.draw_string(f, Vector2(412, 18), "[C] %s | Зум %d%%" % [cam_n, int(_zoom * 100.0)], HORIZONTAL_ALIGNMENT_RIGHT, 220, 11, Color(0.72, 0.88, 1.0))
	_hud.draw_string(f, Vector2(412, 34), "Вороги: %d  |  Рекорд: %d" % [_enemies.size(), _best_score], HORIZONTAL_ALIGNMENT_RIGHT, 220, 11, Color(1.0, 0.72, 0.55))

	# Active power-up badges
	var py := 56.0
	for row in [[_t_turbo, "⚡ ТУРБО +25%: %.0fс", Color(1.0, 0.58, 0.14)], [_t_slow, "❄ СПОВІЛЬН.: %.0fс", Color(0.15, 0.88, 1.0)], [_t_magnet, "🧲 МАГНІТ: %.0fс", Color(0.74, 0.34, 1.0)], [_t_shield, "🛡 ЩИТ: %.0fс", Color(0.16, 0.94, 0.82)]]:
		if float(row[0]) > 0.0:
			_hud.draw_rect(Rect2(10, py - 12, 148, 16), Color(0.05, 0.07, 0.11, 0.78))
			_hud.draw_string(f, Vector2(14, py), str(row[1]) % float(row[0]), HORIZONTAL_ALIGNMENT_LEFT, 142, 11, row[2] as Color)
			py += 19.0

	if _banner_t > 0.0 and not game_over:
		_hud.draw_rect(Rect2(150, 56, 340, 26), Color(0.06, 0.08, 0.14, 0.82))
		_hud.draw_string(f, Vector2(154, 73), _banner_txt, HORIZONTAL_ALIGNMENT_CENTER, 332, 12, Color(1.0, 0.90, 0.42))

	# Bottom Boost Bar
	var br := clampf(_p_boost_energy / 100.0, 0.0, 1.0)
	_hud.draw_rect(Rect2(220, 381, 200, 10), Color(0.08, 0.10, 0.14, 0.85))
	_hud.draw_rect(Rect2(222, 383, 196.0 * br, 6), Color(1.0, 0.32, 0.32) if br < 0.2 else Color(0.12, 0.88, 1.0))
	_hud.draw_string(f, Vector2(220, 377), "ТУРБО [SPACE / SHIFT]", HORIZONTAL_ALIGNMENT_CENTER, 200, 10, Color(0.76, 0.94, 1.0))

	if game_over:
		draw_game_over_banner("ФІНІШ! Рахунок: %d — [R] Заново" % score)
