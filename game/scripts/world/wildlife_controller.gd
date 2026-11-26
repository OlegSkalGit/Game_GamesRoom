class_name WildlifeController
extends Node3D

var _height_fn: Callable
var _water_level: float = 1.6
var _player: Node3D

var _ground_animals: Array[Dictionary] = []
var _water_birds: Array[Dictionary] = []
var _flying_birds: Array[Dictionary] = []
var _bird_sound_t: float = 2.4
var _duck_sound_t: float = 4.5
var _rustle_cd: float = 0.0


func setup(height_fn: Callable, water_level: float, player: Node3D) -> void:
	_height_fn = height_fn
	_water_level = water_level
	_player = player
	_spawn_foxes()
	_spawn_horses()
	_spawn_stags()
	_spawn_waterbirds()
	_spawn_flying_birds()


func _find_dry_spot(rng: RandomNumberGenerator, min_r: float, max_r: float) -> Vector3:
	for _attempt in range(40):
		var a := rng.randf() * TAU
		var r := rng.randf_range(min_r, max_r)
		var x := cos(a) * r
		var z := sin(a) * r
		if absf(x) < 24.0 and absf(z) < 14.0:
			continue
		var y := float(_height_fn.call(x, z))
		if y > _water_level + 0.65:
			return Vector3(x, y, z)
	return Vector3(28.0, float(_height_fn.call(28.0, 28.0)), 28.0)


func _find_anim_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for c in node.get_children():
		var found := _find_anim_player(c)
		if found:
			return found
	return null


func _play_loop_anim(ap: AnimationPlayer, anim_name: String, speed_scale: float = 1.0) -> void:
	if ap == null or anim_name == "" or not ap.has_animation(anim_name):
		return
	var anim := ap.get_animation(anim_name)
	if anim and anim.loop_mode != Animation.LOOP_LINEAR:
		anim.loop_mode = Animation.LOOP_LINEAR
	ap.speed_scale = speed_scale
	if not ap.is_playing() or ap.current_animation != anim_name:
		ap.play(anim_name)


func _hide_lod1_and_tint(root: Node, coat_color: Color = Color.TRANSPARENT) -> void:
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is MeshInstance3D:
			var mi := n as MeshInstance3D
			if mi.name.ends_with("_LOD1"):
				mi.visible = false
			elif coat_color != Color.TRANSPARENT and mi.mesh != null:
				for s in range(mi.mesh.get_surface_count()):
					var mat := mi.get_active_material(s)
					if mat is StandardMaterial3D:
						var dup := (mat as StandardMaterial3D).duplicate() as StandardMaterial3D
						dup.albedo_color = coat_color
						dup.roughness = 0.72
						dup.metallic = 0.0
						mi.set_surface_override_material(s, dup)
		for c in n.get_children():
			stack.append(c)


func _spawn_foxes() -> void:
	var fox_scene := load("res://assets/models/animals/Fox.glb") as PackedScene
	var fox2_scene := load("res://assets/models/animals/animal_fox.glb") as PackedScene
	var rng := RandomNumberGenerator.new()
	rng.seed = 4402
	for i in range(7):
		var use_v2 := (i >= 4 and fox2_scene != null)
		var ps: PackedScene = fox2_scene if use_v2 else fox_scene
		if ps == null:
			continue
		var root := Node3D.new()
		var model := ps.instantiate() as Node3D
		model.scale = Vector3(1.05, 1.05, 1.05) if use_v2 else Vector3(0.011, 0.011, 0.011)
		_hide_lod1_and_tint(model)
		root.add_child(model)
		var ap := _find_anim_player(model)
		var w_anim := "walk" if use_v2 else "Walk"
		var r_anim := "run" if use_v2 else "Run"
		var i_anim := "idle" if use_v2 else "Survey"
		_play_loop_anim(ap, w_anim, 1.15)

		root.position = _find_dry_spot(rng, 20.0, 95.0)
		add_child(root)
		_ground_animals.append({
			"node": root,
			"ap": ap,
			"walk_anim": w_anim,
			"run_anim": r_anim,
			"idle_anim": i_anim,
			"dir": Vector3(rng.randf_range(-1, 1), 0, rng.randf_range(-1, 1)).normalized(),
			"speed": 2.4,
			"run_speed": 6.8,
			"pause_t": 0.0,
			"phase": rng.randf() * TAU,
			"yaw_offset": 0.0,
			"min_pause": 0.8,
			"max_pause": 1.8
		})


func _spawn_horses() -> void:
	var horse_scene := load("res://assets/models/animals/Horse.glb") as PackedScene
	if horse_scene == null:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 4403
	var horse_coats: Array[Color] = [
		Color(0.46, 0.24, 0.14),
		Color(0.28, 0.16, 0.10),
		Color(0.64, 0.48, 0.30),
		Color(0.36, 0.22, 0.15)
	]
	for i in range(4):
		var root := Node3D.new()
		var model := horse_scene.instantiate() as Node3D
		model.scale = Vector3(0.0085, 0.0085, 0.0085)
		_hide_lod1_and_tint(model, horse_coats[i % horse_coats.size()])
		root.add_child(model)
		var ap := _find_anim_player(model)
		_play_loop_anim(ap, "horse_A_", 0.65)

		root.position = _find_dry_spot(rng, 28.0, 105.0)
		add_child(root)
		_ground_animals.append({
			"node": root,
			"ap": ap,
			"walk_anim": "horse_A_",
			"run_anim": "horse_A_",
			"idle_anim": "horse_A_",
			"dir": Vector3(rng.randf_range(-1, 1), 0, rng.randf_range(-1, 1)).normalized(),
			"speed": 2.8,
			"run_speed": 7.6,
			"pause_t": 0.0,
			"phase": rng.randf() * TAU,
			"yaw_offset": 0.0,
			"min_pause": 0.0,
			"max_pause": 0.0
		})


func _spawn_stags() -> void:
	# Forest Owls (Vuena animal_owl.glb) roaming/hopping continuously without long freezes
	var owl_scene := load("res://assets/models/animals/animal_owl.glb") as PackedScene
	if owl_scene == null:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 4404
	for _i in range(6):
		var root := Node3D.new()
		var model := owl_scene.instantiate() as Node3D
		model.scale = Vector3(0.95, 0.95, 0.95)
		_hide_lod1_and_tint(model)
		root.add_child(model)
		var ap := _find_anim_player(model)
		_play_loop_anim(ap, "walk", 1.1)

		root.position = _find_dry_spot(rng, 22.0, 95.0)
		add_child(root)
		_ground_animals.append({
			"node": root,
			"ap": ap,
			"walk_anim": "walk",
			"run_anim": "jump",
			"idle_anim": "idle",
			"dir": Vector3(rng.randf_range(-1, 1), 0, rng.randf_range(-1, 1)).normalized(),
			"speed": 1.3,
			"run_speed": 3.4,
			"pause_t": 0.0,
			"phase": rng.randf() * TAU,
			"yaw_offset": 0.0,
			"min_pause": 0.9,
			"max_pause": 1.8
		})


func _spawn_waterbirds() -> void:
	var duck_scene := load("res://assets/models/animals/Duck.glb") as PackedScene
	if duck_scene == null:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 4405
	var lakes := [
		{"center": Vector2(-68.0, -28.0), "radius": 22.0},
		{"center": Vector2(72.0, 34.0), "radius": 24.0},
		{"center": Vector2(18.0, 66.0), "radius": 10.0}
	]

	for i in range(10):
		var lake: Dictionary = lakes[i % lakes.size()]
		var root := Node3D.new()
		var model := duck_scene.instantiate() as Node3D
		model.scale = Vector3(0.0048, 0.0048, 0.0048)
		model.rotation.y = -PI * 0.5 # Duck faces +X in Khronos GLTF -> align to +Z
		root.add_child(model)

		var ang := rng.randf() * TAU
		var rad := rng.randf_range(4.0, float(lake["radius"]))
		var c: Vector2 = lake["center"]
		root.position = Vector3(c.x + cos(ang) * rad, _water_level - 0.04, c.y + sin(ang) * rad)
		add_child(root)

		_water_birds.append({
			"node": root,
			"center": c,
			"orbit_r": rad,
			"angle": ang,
			"angular_speed": 0.11 * (1.0 if i % 2 == 0 else -1.0),
			"phase": rng.randf() * TAU
		})


func _spawn_flying_birds() -> void:
	var stork_scene := load("res://assets/models/animals/Stork.glb") as PackedScene
	var flamingo_scene := load("res://assets/models/animals/Flamingo.glb") as PackedScene
	var parrot_scene := load("res://assets/models/animals/Parrot.glb") as PackedScene

	var rng := RandomNumberGenerator.new()
	rng.seed = 4406

	var specs: Array[Dictionary] = []
	for _i in range(4):
		if stork_scene: specs.append({"scene": stork_scene, "anim": "storkFly_B_", "scale": 0.0085, "hawk": true})
	for _i in range(4):
		if flamingo_scene: specs.append({"scene": flamingo_scene, "anim": "flamingo_flyA_", "scale": 0.0075, "hawk": false})
	for _i in range(14):
		if parrot_scene: specs.append({"scene": parrot_scene, "anim": "parrot_A_", "scale": 0.0046, "hawk": false})

	for idx in range(specs.size()):
		var sp: Dictionary = specs[idx]
		var is_hawk := bool(sp["hawk"])
		var root := Node3D.new()
		var model := (sp["scene"] as PackedScene).instantiate() as Node3D
		var sc := float(sp["scale"])
		model.scale = Vector3(sc, sc, sc)
		root.add_child(model)
		var ap := _find_anim_player(model)
		_play_loop_anim(ap, str(sp["anim"]), rng.randf_range(0.9, 1.25))

		var center := Vector3(rng.randf_range(-85, 85), rng.randf_range(22.0 if is_hawk else 12.0, 42.0 if is_hawk else 25.0), rng.randf_range(-85, 85))
		var radius := rng.randf_range(28.0 if is_hawk else 14.0, 56.0 if is_hawk else 36.0)
		add_child(root)

		_flying_birds.append({
			"node": root,
			"center": center,
			"radius": radius,
			"angle": rng.randf() * TAU,
			"speed": rng.randf_range(0.18, 0.34) if is_hawk else rng.randf_range(0.42, 0.78),
			"is_hawk": is_hawk,
			"phase": rng.randf() * TAU
		})


func _process(delta: float) -> void:
	var t := Time.get_ticks_msec() * 0.001

	for a in _ground_animals:
		var node: Node3D = a["node"]
		var ap: AnimationPlayer = a["ap"]
		var dir: Vector3 = a["dir"]
		var speed: float = float(a["speed"])

		var fleeing := false
		if _player:
			var to_me := node.global_position - _player.global_position
			to_me.y = 0.0
			var d := to_me.length()
			if d < 10.5 and d > 0.1:
				fleeing = true
				if float(a["pause_t"]) > 0.0 and _rustle_cd <= 0.0:
					_rustle_cd = 1.6
					AudioSfx.play_animal_rustle(_calc_pan(node.global_position))
				dir = dir.lerp(to_me.normalized(), delta * 5.0).normalized()
				speed = float(a["run_speed"])
				a["pause_t"] = 0.0

		var pause_t := float(a["pause_t"])
		if pause_t > 0.0 and float(a.get("max_pause", 0.0)) > 0.0:
			a["pause_t"] = pause_t - delta
			var idle_anim := str(a["idle_anim"])
			_play_loop_anim(ap, idle_anim, 1.0)
			continue

		_play_loop_anim(ap, str(a["run_anim"] if fleeing else a["walk_anim"]), 1.25 if fleeing else 0.72 if str(a["walk_anim"]) == "horse_A_" else 1.05)

		var next_pos := node.position + dir * speed * delta
		var next_h := float(_height_fn.call(next_pos.x, next_pos.z))
		var bad_spot := next_h <= _water_level + 0.45 or (absf(next_pos.x) < 23.5 and absf(next_pos.z) < 13.5) or absf(next_pos.x) > 135.0 or absf(next_pos.z) > 135.0
		if bad_spot:
			var steered := false
			for ang_try in [0.65, -0.65, 1.35, -1.35, 2.4]:
				var cand_dir := dir.rotated(Vector3.UP, ang_try).normalized()
				var cand_pos := node.position + cand_dir * speed * delta
				var ch := float(_height_fn.call(cand_pos.x, cand_pos.z))
				if ch > _water_level + 0.45 and not (absf(cand_pos.x) < 23.5 and absf(cand_pos.z) < 13.5) and absf(cand_pos.x) <= 135.0 and absf(cand_pos.z) <= 135.0:
					dir = cand_dir
					a["dir"] = dir
					node.position = Vector3(cand_pos.x, ch, cand_pos.z)
					steered = true
					break
			if not steered:
				dir = dir.rotated(Vector3.UP, PI * 0.85).normalized()
				a["dir"] = dir
		else:
			node.position = Vector3(next_pos.x, next_h, next_pos.z)
			if randf() < delta * 0.45:
				dir = dir.rotated(Vector3.UP, randf_range(-0.75, 0.75)).normalized()
				a["dir"] = dir
			var max_p := float(a.get("max_pause", 0.0))
			if not fleeing and max_p > 0.0 and randf() < delta * 0.12:
				a["pause_t"] = randf_range(float(a.get("min_pause", 0.8)), max_p)

		var target_yaw := atan2(dir.x, dir.z) + float(a["yaw_offset"])
		node.rotation.y = lerp_angle(node.rotation.y, target_yaw, delta * 6.0)

	for wb in _water_birds:
		var node: Node3D = wb["node"]
		var ang := float(wb["angle"]) + float(wb["angular_speed"]) * delta
		wb["angle"] = ang
		var c: Vector2 = wb["center"]
		var r := float(wb["orbit_r"])
		var nx := c.x + cos(ang) * r
		var nz := c.y + sin(ang) * r
		var bob := sin(t * 2.6 + float(wb["phase"])) * 0.025
		var look_dir := Vector3(nx, _water_level, nz) - node.position
		node.position = Vector3(nx, _water_level - 0.04 + bob, nz)
		if look_dir.length_squared() > 0.00001:
			node.rotation.y = lerp_angle(node.rotation.y, atan2(look_dir.x, look_dir.z), delta * 4.0)

	for fb in _flying_birds:
		var node: Node3D = fb["node"]
		var ang := float(fb["angle"]) + float(fb["speed"]) * delta
		fb["angle"] = ang
		var c: Vector3 = fb["center"]
		var r := float(fb["radius"])
		var bob := sin(t * 1.1 + float(fb["phase"])) * 2.2
		var next_p := Vector3(c.x + cos(ang) * r, c.y + bob, c.z + sin(ang) * r)
		var vel := next_p - node.position
		node.position = next_p
		if vel.length_squared() > 0.0001:
			node.look_at(next_p + vel.normalized(), Vector3.UP)
			node.rotate_object_local(Vector3.UP, PI)

	_process_wildlife_audio(delta)


func _calc_pan(world_pos: Vector3) -> float:
	if _player == null or not (_player is PlayerController):
		return 0.0
	var cam := (_player as PlayerController).get_camera()
	if cam == null:
		return 0.0
	var to_src := (world_pos - cam.global_position).normalized()
	return clampf(cam.global_transform.basis.x.dot(to_src), -1.0, 1.0)


func _process_wildlife_audio(delta: float) -> void:
	if _player == null or not (_player is PlayerController) or not (_player as PlayerController).controls_enabled:
		return
	_rustle_cd = maxf(0.0, _rustle_cd - delta)
	var p := _player.global_position
	var indoors := absf(p.x) < 8.5 and absf(p.z) < 8.5

	_bird_sound_t -= delta
	if _bird_sound_t <= 0.0:
		_bird_sound_t = randf_range(2.2, 5.2)
		if not indoors and not _flying_birds.is_empty():
			var fb: Dictionary = _flying_birds[randi() % _flying_birds.size()]
			var bpos: Vector3 = (fb["node"] as Node3D).global_position
			if bpos.distance_to(p) < 95.0:
				var pan := _calc_pan(bpos)
				if bool(fb["is_hawk"]):
					AudioSfx.play_hawk_cry(pan)
				else:
					AudioSfx.play_bird_song(pan)

	_duck_sound_t -= delta
	if _duck_sound_t <= 0.0:
		_duck_sound_t = randf_range(4.0, 8.5)
		if not indoors and not _water_birds.is_empty():
			var wb: Dictionary = _water_birds[randi() % _water_birds.size()]
			var wpos: Vector3 = (wb["node"] as Node3D).global_position
			if wpos.distance_to(p) < 70.0:
				AudioSfx.play_duck_call(_calc_pan(wpos))
