extends MinigameBase

# Smooth 3D Snake Arena inside embedded SubViewport:
# - Continuous curved movement along high-res trail history
# - Food (red 3D apples + golden berries), Obstacles (3D stone pillars & crates),
#   Poison (glowing purple toxic mushrooms), & 2 AI 3D Rival Snakes competing for apples!

const ARENA_HALF_X := 11.5
const ARENA_HALF_Z := 7.6
const SEG_SPACING := 0.50

var _sv: SubViewport
var _sv_rect: TextureRect
var _world3d: Node3D
var _hud: Control

var _p_pos: Vector2 = Vector2(-4.0, 0.0)
var _p_angle: float = 0.0
var _p_target_angle: float = 0.0
var _p_len: int = 6
var _p_trail: Array[Vector2] = []
var _p_nodes: Array[Node3D] = []
var _poison_fx_t: float = 0.0

var _rivals: Array[Dictionary] = []
var _obstacles: Array[Dictionary] = []
var _foods: Array[Dictionary] = []
var _poisons: Array[Dictionary] = []
var _anim_t: float = 0.0

var _apple_mat: StandardMaterial3D
var _gold_mat: StandardMaterial3D
var _poison_mat: StandardMaterial3D
var _p_head_mat: StandardMaterial3D
var _p_body_mat: StandardMaterial3D
var _rival_mats: Array[StandardMaterial3D] = []


func get_game_title() -> String:
	return "Змійка 3D"


func get_controls_hint() -> String:
	return "WASD / Стрілки — плавний поворот | Збирайте яблука, уникайте отрути, перешкод і суперників! | R — заново"


func _ready() -> void:
	super._ready()
	_build_3d_viewport()


func _exit_tree() -> void:
	if _sv_rect:
		_sv_rect.texture = null
	if _world3d:
		_clear_dynamic_nodes()
		_world3d.free()
		_world3d = null


func _build_3d_viewport() -> void:
	_sv = SubViewport.new()
	if DisplayServer.get_name() == "headless":
		_sv.size = Vector2i(640, 400)
	else:
		var win_sz := DisplayServer.window_get_size()
		var target_h := clampi(int(float(maxi(win_sz.y, 1080)) * 0.88), 1100, 1500)
		_sv.size = Vector2i(int(round(float(target_h) * 1.6)), target_h)
	_sv.own_world_3d = true
	_sv.msaa_3d = Viewport.MSAA_4X
	_sv.use_taa = false
	_sv.use_debanding = true
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

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.05, 0.09, 0.12)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.32, 0.44, 0.38)
	env.ambient_light_energy = 0.75
	env.glow_enabled = true
	env.glow_intensity = 0.35
	var we := WorldEnvironment.new()
	we.environment = env
	_world3d.add_child(we)

	var dir_l := DirectionalLight3D.new()
	dir_l.rotation_degrees = Vector3(-52.0, 28.0, 0.0)
	dir_l.light_color = Color(1.0, 0.96, 0.88)
	dir_l.light_energy = 1.65
	dir_l.shadow_enabled = false
	_world3d.add_child(dir_l)

	var cam := Camera3D.new()
	cam.fov = 46.0
	_world3d.add_child(cam)
	cam.look_at_from_position(Vector3(0.0, 17.5, 11.2), Vector3(0.0, 0.0, 0.4), Vector3.UP)

	# Tiled Arena Floor & Chamfered Perimeter Walls
	var floor_a := _make_mat(Color(0.11, 0.22, 0.14), 0.72)
	var floor_b := _make_mat(Color(0.14, 0.27, 0.17), 0.72)
	var wall_mat := _make_mat(Color(0.28, 0.24, 0.22), 0.62)
	var gold_trim := _make_mat(Color(0.76, 0.60, 0.24), 0.30, 0.85)

	var base := MeshInstance3D.new()
	var bm := BoxMesh.new(); bm.size = Vector3(ARENA_HALF_X * 2.0 + 0.6, 0.4, ARENA_HALF_Z * 2.0 + 0.6)
	base.mesh = bm; base.material_override = floor_a; base.position = Vector3(0, -0.22, 0)
	_world3d.add_child(base)

	var tile_m := BoxMesh.new(); tile_m.size = Vector3(1.9, 0.04, 1.9)
	for tx in range(-5, 6):
		for tz in range(-3, 4):
			if (tx + tz) % 2 == 0:
				var tm := MeshInstance3D.new(); tm.mesh = tile_m; tm.material_override = floor_b
				tm.position = Vector3(float(tx) * 2.0, 0.0, float(tz) * 2.0)
				_world3d.add_child(tm)

	# Arena border walls & corner gold pillars
	for wz in [-ARENA_HALF_Z - 0.3, ARENA_HALF_Z + 0.3]:
		_add_box(_world3d, Vector3(ARENA_HALF_X * 2.0 + 1.2, 0.9, 0.6), Vector3(0, 0.42, wz), wall_mat)
	for wx in [-ARENA_HALF_X - 0.3, ARENA_HALF_X + 0.3]:
		_add_box(_world3d, Vector3(0.6, 0.9, ARENA_HALF_Z * 2.0 + 1.2), Vector3(wx, 0.42, 0), wall_mat)
	for cx in [-ARENA_HALF_X - 0.3, ARENA_HALF_X + 0.3]:
		for cz in [-ARENA_HALF_Z - 0.3, ARENA_HALF_Z + 0.3]:
			_add_box(_world3d, Vector3(0.9, 1.3, 0.9), Vector3(cx, 0.62, cz), gold_trim)

	# Shared materials for entities
	_apple_mat = _make_mat(Color(0.95, 0.16, 0.16), 0.25, 0.0, Color(0.9, 0.12, 0.10), 0.55)
	_gold_mat = _make_mat(Color(1.0, 0.84, 0.20), 0.18, 0.6, Color(1.0, 0.78, 0.18), 0.85)
	_poison_mat = _make_mat(Color(0.66, 0.14, 0.92), 0.30, 0.0, Color(0.62, 0.12, 0.95), 0.95)
	_p_head_mat = _make_mat(Color(0.32, 0.96, 0.44), 0.28)
	_p_body_mat = _make_mat(Color(0.18, 0.74, 0.30), 0.38)
	_rival_mats = [
		_make_mat(Color(0.96, 0.36, 0.22), 0.32),
		_make_mat(Color(0.24, 0.68, 0.98), 0.32)
	]

	_hud = Control.new()
	_hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.draw.connect(_draw_hud)
	add_child(_hud)


func _make_mat(col: Color, rough: float = 0.6, metal: float = 0.0, emit: Color = Color.BLACK, emit_e: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col; m.roughness = rough; m.metallic = metal
	if emit_e > 0.0:
		m.emission_enabled = true; m.emission = emit; m.emission_energy_multiplier = emit_e
	return m


func _add_box(parent: Node3D, sz: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new(); b.size = sz
	mi.mesh = b; mi.material_override = mat; mi.position = pos
	parent.add_child(mi)
	return mi


func _clear_dynamic_nodes() -> void:
	for n in _p_nodes:
		if is_instance_valid(n): n.free()
	_p_nodes.clear()
	for r in _rivals:
		for n: Node3D in r["nodes"]:
			if is_instance_valid(n): n.free()
	_rivals.clear()
	for o in _obstacles:
		var onode := o["node"] as Node3D
		if is_instance_valid(onode): onode.free()
	_obstacles.clear()
	for f in _foods:
		var fnode := f["node"] as Node3D
		if is_instance_valid(fnode): fnode.free()
	_foods.clear()
	for p in _poisons:
		var pnode := p["node"] as Node3D
		if is_instance_valid(pnode): pnode.free()
	_poisons.clear()


func reset_game() -> void:
	if _world3d == null:
		return
	_clear_dynamic_nodes()
	_p_pos = Vector2(-5.5, 2.5)
	_p_angle = 0.0
	_p_target_angle = 0.0
	_p_len = 7
	_poison_fx_t = 0.0
	_p_trail.clear()
	for i in range(40):
		_p_trail.append(_p_pos - Vector2(float(i) * 0.16, 0.0))

	# 3D Obstacles (stone pillars + wooden crates cleanly away from center spawn!)
	var pillar_mat := _make_mat(Color(0.46, 0.44, 0.48), 0.7)
	var crate_mat := _make_mat(Color(0.56, 0.34, 0.16), 0.65)
	var obs_coords := [
		{"pos": Vector2(-6.0, -4.0), "r": 0.72, "crate": false},
		{"pos": Vector2(-6.0, 4.0), "r": 0.72, "crate": false},
		{"pos": Vector2(6.0, -4.0), "r": 0.72, "crate": false},
		{"pos": Vector2(6.0, 4.0), "r": 0.72, "crate": false},
		{"pos": Vector2(0.0, -4.8), "r": 0.68, "crate": true},
		{"pos": Vector2(0.0, 4.8), "r": 0.68, "crate": true},
		{"pos": Vector2(0.0, 0.0), "r": 0.76, "crate": false}
	]
	for oc in obs_coords:
		var node := Node3D.new()
		var p2: Vector2 = oc["pos"]
		node.position = Vector3(p2.x, 0.0, p2.y)
		if bool(oc["crate"]):
			_add_box(node, Vector3(1.15, 0.95, 1.15), Vector3(0, 0.48, 0), crate_mat)
		else:
			var cyl := CylinderMesh.new(); cyl.top_radius = 0.56; cyl.bottom_radius = 0.66; cyl.height = 1.25
			var mi := MeshInstance3D.new(); mi.mesh = cyl; mi.material_override = pillar_mat; mi.position = Vector3(0, 0.62, 0)
			node.add_child(mi)
		_world3d.add_child(node)
		_obstacles.append({"pos": p2, "r": float(oc["r"]), "node": node})

	# Spawn 2 AI 3D Rival Snakes
	var r_starts := [Vector2(7.5, -5.5), Vector2(7.5, 5.5)]
	for ri in range(2):
		var sp: Vector2 = r_starts[ri]
		var tr: Array[Vector2] = []
		for i in range(30):
			tr.append(sp + Vector2(float(i) * 0.16, 0.0))
		var rnodes: Array[Node3D] = []
		_rivals.append({
			"pos": sp, "angle": PI, "len": 6, "trail": tr,
			"nodes": rnodes, "mat": _rival_mats[ri], "alive": true, "respawn_t": 0.0
		})
		_sync_snake_nodes(rnodes, 6, _rival_mats[ri], _rival_mats[ri], true)

	_sync_snake_nodes(_p_nodes, _p_len, _p_head_mat, _p_body_mat, false)

	for _f in range(4):
		_spawn_item(false)
	for _p in range(3):
		_spawn_item(true)

	super.reset_game()


func _make_snake_segment(is_head: bool, head_mat: Material, body_mat: Material) -> Node3D:
	var n := Node3D.new()
	var sph := SphereMesh.new()
	sph.radius = 0.36 if is_head else 0.30
	sph.height = sph.radius * 1.9
	var mi := MeshInstance3D.new(); mi.mesh = sph; mi.material_override = head_mat if is_head else body_mat
	n.add_child(mi)
	if is_head:
		var eye_m := _make_mat(Color(1, 1, 1), 0.2)
		var pup_m := _make_mat(Color(0.05, 0.05, 0.05), 0.2)
		var tongue_m := _make_mat(Color(0.95, 0.15, 0.2), 0.3)
		for side in [-0.16, 0.16]:
			var em := MeshInstance3D.new(); var es := SphereMesh.new(); es.radius = 0.085; es.height = 0.17
			em.mesh = es; em.material_override = eye_m; em.position = Vector3(0.22, 0.14, side); n.add_child(em)
			var pm := MeshInstance3D.new(); var ps := SphereMesh.new(); ps.radius = 0.045; ps.height = 0.09
			pm.mesh = ps; pm.material_override = pup_m; pm.position = Vector3(0.28, 0.15, side); n.add_child(pm)
		_add_box(n, Vector3(0.28, 0.03, 0.07), Vector3(0.42, -0.02, 0.0), tongue_m)
	return n


func _sync_snake_nodes(nodes: Array[Node3D], target_len: int, h_mat: Material, b_mat: Material, _is_rival: bool) -> void:
	while nodes.size() < target_len:
		var seg := _make_snake_segment(nodes.is_empty(), h_mat, b_mat)
		seg.position = Vector3(0, 0.34, 0)
		_world3d.add_child(seg)
		nodes.append(seg)
	while nodes.size() > target_len:
		var last := nodes.pop_back() as Node3D
		last.queue_free()


func _free_spawn_pos() -> Vector2:
	for _a in range(80):
		var cand := Vector2(randf_range(-ARENA_HALF_X + 1.4, ARENA_HALF_X - 1.4), randf_range(-ARENA_HALF_Z + 1.4, ARENA_HALF_Z - 1.4))
		if cand.distance_to(_p_pos) < 2.6:
			continue
		var ok := true
		for o in _obstacles:
			if cand.distance_to(o["pos"]) < float(o["r"]) + 0.9:
				ok = false; break
		if ok:
			return cand
	return Vector2(3.0, 2.0)


func _spawn_item(is_poison: bool) -> void:
	var pos := _free_spawn_pos()
	var node := Node3D.new()
	node.position = Vector3(pos.x, 0.35, pos.y)
	if is_poison:
		var stem := CylinderMesh.new(); stem.top_radius = 0.11; stem.bottom_radius = 0.15; stem.height = 0.32
		var smi := MeshInstance3D.new(); smi.mesh = stem; smi.material_override = _make_mat(Color(0.84, 0.78, 0.86)); smi.position = Vector3(0, -0.1, 0)
		var cap := SphereMesh.new(); cap.radius = 0.32; cap.height = 0.36
		var cmi := MeshInstance3D.new(); cmi.mesh = cap; cmi.material_override = _poison_mat; cmi.position = Vector3(0, 0.12, 0)
		node.add_child(smi); node.add_child(cmi)
		_world3d.add_child(node)
		_poisons.append({"pos": pos, "node": node})
	else:
		var is_gold := randf() < 0.20
		var sph := SphereMesh.new(); sph.radius = 0.32 if not is_gold else 0.38; sph.height = sph.radius * 1.9
		var mi := MeshInstance3D.new(); mi.mesh = sph; mi.material_override = _gold_mat if is_gold else _apple_mat
		var leaf := _add_box(node, Vector3(0.20, 0.06, 0.12), Vector3(0.08, 0.34, 0.0), _make_mat(Color(0.2, 0.78, 0.25)))
		leaf.rotation.z = 0.4
		node.add_child(mi)
		_world3d.add_child(node)
		_foods.append({"pos": pos, "node": node, "gold": is_gold})


func on_key_pressed(phys_key: int) -> void:
	if game_over:
		return
	var cand := _p_target_angle
	if is_right_key(phys_key): cand = 0.0
	elif is_down_key(phys_key): cand = PI * 0.5
	elif is_left_key(phys_key): cand = PI
	elif is_up_key(phys_key): cand = -PI * 0.5
	# Prevent direct 180-degree self-reversal bite!
	if absf(angle_difference(_p_angle, cand)) < PI * 0.85:
		_p_target_angle = cand


func _sample_trail(trail: Array[Vector2], dist_back: float) -> Vector2:
	if trail.is_empty():
		return Vector2.ZERO
	var acc := 0.0
	for i in range(trail.size() - 1):
		var seg := trail[i].distance_to(trail[i + 1])
		if acc + seg >= dist_back:
			var t := (dist_back - acc) / maxf(seg, 0.0001)
			return trail[i].lerp(trail[i + 1], t)
		acc += seg
	return trail[trail.size() - 1]


func _hits_obstacle_or_wall(pos: Vector2, rad: float) -> bool:
	if absf(pos.x) > ARENA_HALF_X - rad or absf(pos.y) > ARENA_HALF_Z - rad:
		return true
	for o in _obstacles:
		if pos.distance_to(o["pos"]) < float(o["r"]) + rad:
			return true
	return false


func step_game(delta: float) -> void:
	_anim_t += delta
	_poison_fx_t = maxf(0.0, _poison_fx_t - delta)
	if game_over:
		_hud.queue_redraw()
		return

	# Continuous target heading also supports holding keys smoothly
	var hold := Vector2.ZERO
	if is_right_held(): hold.x += 1.0
	if is_left_held(): hold.x -= 1.0
	if is_down_held(): hold.y += 1.0
	if is_up_held(): hold.y -= 1.0
	if hold.length_squared() > 0.1:
		var cand := hold.angle()
		if absf(angle_difference(_p_angle, cand)) < PI * 0.85:
			_p_target_angle = cand

	_p_angle = lerp_angle(_p_angle, _p_target_angle, minf(delta * 9.5, 1.0))
	var spd := 5.6 + minf(float(_p_len) * 0.07, 2.2)
	_p_pos += Vector2.from_angle(_p_angle) * spd * delta

	if _p_trail.is_empty() or _p_pos.distance_to(_p_trail[0]) >= 0.12:
		_p_trail.push_front(_p_pos)
		while _p_trail.size() > _p_len * 6 + 20:
			_p_trail.pop_back()

	if _hits_obstacle_or_wall(_p_pos, 0.34):
		game_over = true
		AudioSfx.play_hit()
		status_changed.emit("Зіткнення з перешкодою!")
		_hud.queue_redraw()
		return

	# Self-collision check (skip neck segments)
	for i in range(4, _p_nodes.size()):
		var sp := _sample_trail(_p_trail, float(i) * SEG_SPACING)
		if _p_pos.distance_to(sp) < 0.44:
			game_over = true
			AudioSfx.play_hit()
			status_changed.emit("Укусили себе!")
			_hud.queue_redraw()
			return

	# Update 3D player visual transforms smoothly
	for i in range(_p_nodes.size()):
		var sp := _sample_trail(_p_trail, float(i) * SEG_SPACING)
		var n: Node3D = _p_nodes[i]
		n.position = Vector3(sp.x, 0.32 + sin(_anim_t * 6.0 - float(i) * 0.5) * 0.03, sp.y)
		if i == 0:
			n.rotation.y = -_p_angle
		var taper := 1.0 - float(i) / maxf(float(_p_nodes.size() + 4), 1.0) * 0.45
		n.scale = Vector3(taper, taper, taper)

	# Animate food & poison bobbing, check eats
	for fi in range(_foods.size() - 1, -1, -1):
		var f: Dictionary = _foods[fi]
		var fn: Node3D = f["node"]
		fn.position.y = 0.34 + sin(_anim_t * 3.5 + float(fi)) * 0.08
		fn.rotation.y += delta * 1.8
		if _p_pos.distance_to(f["pos"]) < 0.72:
			var is_gold := bool(f["gold"])
			add_score(100 if is_gold else 25)
			_p_len += 2 if is_gold else 1
			_sync_snake_nodes(_p_nodes, _p_len, _p_head_mat, _p_body_mat, false)
			AudioSfx.play_powerup() if is_gold else AudioSfx.play_coin()
			fn.queue_free()
			_foods.remove_at(fi)
			_spawn_item(false)

	for pi in range(_poisons.size() - 1, -1, -1):
		var p: Dictionary = _poisons[pi]
		var pn: Node3D = p["node"]
		pn.position.y = 0.30 + sin(_anim_t * 4.5 + float(pi)) * 0.05
		if _p_pos.distance_to(p["pos"]) < 0.65:
			add_score(-40)
			_p_len -= 3
			_poison_fx_t = 1.4
			AudioSfx.play_hit()
			pn.queue_free()
			_poisons.remove_at(pi)
			_spawn_item(true)
			if _p_len < 3:
				game_over = true
				status_changed.emit("Смертельне отруєння!")
				_hud.queue_redraw()
				return
			_sync_snake_nodes(_p_nodes, _p_len, _p_head_mat, _p_body_mat, false)

	# AI Rival 3D Snakes
	for r in _rivals:
		if not bool(r["alive"]):
			r["respawn_t"] = float(r["respawn_t"]) - delta
			if float(r["respawn_t"]) <= 0.0:
				r["alive"] = true
				r["pos"] = _free_spawn_pos()
				r["len"] = 5
				(r["trail"] as Array[Vector2]).clear()
				for k in range(25):
					(r["trail"] as Array[Vector2]).append(r["pos"])
				_sync_snake_nodes(r["nodes"], 5, r["mat"], r["mat"], true)
			continue

		var rp: Vector2 = r["pos"]
		var ra := float(r["angle"])
		# Seek nearest apple while steering clear of obstacles/walls/poison
		var best_food := rp
		var best_d := 9999.0
		for f in _foods:
			var d := rp.distance_to(f["pos"])
			if d < best_d:
				best_d = d; best_food = f["pos"]
		var goal_ang := (best_food - rp).angle()
		for look_a: float in [0.0, 0.6, -0.6, 1.3, -1.3, 2.2, -2.2]:
			var test_ang: float = ra + look_a
			var ahead := rp + Vector2.from_angle(test_ang) * 1.45
			var avoid_p := false
			for po in _poisons:
				if ahead.distance_to(po["pos"]) < 1.1:
					avoid_p = true; break
			if not _hits_obstacle_or_wall(ahead, 0.5) and not avoid_p:
				if look_a == 0.0:
					ra = lerp_angle(ra, goal_ang, delta * 3.8)
				else:
					ra = lerp_angle(ra, test_ang, delta * 5.2)
				break

		rp += Vector2.from_angle(ra) * 4.5 * delta
		r["pos"] = rp; r["angle"] = ra
		var tr: Array[Vector2] = r["trail"]
		if tr.is_empty() or rp.distance_to(tr[0]) >= 0.14:
			tr.push_front(rp)
			while tr.size() > int(r["len"]) * 6 + 15:
				tr.pop_back()

		var rnodes: Array[Node3D] = r["nodes"]
		if _hits_obstacle_or_wall(rp, 0.34):
			r["alive"] = false; r["respawn_t"] = 3.0
			for n: Node3D in rnodes: n.visible = false
			continue

		# Rival eats apples
		for fi in range(_foods.size() - 1, -1, -1):
			if rp.distance_to(_foods[fi]["pos"]) < 0.72:
				r["len"] = mini(int(r["len"]) + 1, 14)
				_sync_snake_nodes(rnodes, int(r["len"]), r["mat"], r["mat"], true)
				(_foods[fi]["node"] as Node3D).queue_free()
				_foods.remove_at(fi)
				_spawn_item(false)

		for i in range(rnodes.size()):
			var sp := _sample_trail(tr, float(i) * SEG_SPACING)
			var rn: Node3D = rnodes[i]
			rn.visible = true
			rn.position = Vector3(sp.x, 0.32, sp.y)
			if i == 0: rn.rotation.y = -ra
			# Rival body hurts player head, player body destroys rival (+120 pts!)
			if _p_pos.distance_to(sp) < 0.56:
				game_over = true
				AudioSfx.play_hit()
				status_changed.emit("Зіткнення із суперником!")
				_hud.queue_redraw()
				return
			if i == 0:
				for pi in range(1, _p_nodes.size()):
					if rp.distance_to(_sample_trail(_p_trail, float(pi) * SEG_SPACING)) < 0.55:
						r["alive"] = false; r["respawn_t"] = 3.5
						add_score(120)
						AudioSfx.play_goal()
						for n2: Node3D in rnodes: n2.visible = false
						break

	status_changed.emit("Довжина: %d  |  Суперників: 2" % _p_len)
	_hud.queue_redraw()


func _draw_hud() -> void:
	if not is_instance_valid(_hud):
		return
	var f := ThemeDB.fallback_font
	if _poison_fx_t > 0.0:
		_hud.draw_rect(Rect2(Vector2.ZERO, CANVAS_SIZE), Color(0.55, 0.12, 0.85, _poison_fx_t * 0.25))
		_hud.draw_string(f, Vector2(210, 44), "ОТРУТА! -3 СЕГМЕНТИ", HORIZONTAL_ALIGNMENT_CENTER, 220, 16, Color(0.92, 0.52, 1.0))
	_hud.draw_rect(Rect2(12, 10, 232, 26), Color(0.03, 0.06, 0.05, 0.72))
	_hud.draw_string(f, Vector2(20, 28), "Яблуко: +25  |  Отрута: -3 сегм.", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.88, 0.94, 0.88))
	if game_over:
		_hud.draw_rect(Rect2(90, 155, 460, 90), Color(0.05, 0.05, 0.08, 0.88))
		_hud.draw_rect(Rect2(90, 155, 460, 90), Color(0.95, 0.78, 0.3), false, 2.5)
		_hud.draw_string(f, Vector2(110, 206), "ГРУ ЗАВЕРШЕНО — [R] Почати знову", HORIZONTAL_ALIGNMENT_CENTER, 420, 20, Color(1.0, 0.92, 0.72))
