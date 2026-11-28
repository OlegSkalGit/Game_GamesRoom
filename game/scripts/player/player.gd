class_name PlayerController
extends CharacterBody3D

signal interact_painting_requested(painting_id: String)
signal target_painting_changed(painting_id: String, title: String)
signal interact_prop_requested(prop_id: String)
signal target_prop_changed(prop_id: String, title: String)

const WALK_SPEED := 5.6
const SPRINT_SPEED := 9.2
const JUMP_VELOCITY := 5.4
const GRAVITY := 15.0
const EYE_HEIGHT := 1.68

var controls_enabled: bool = false
var _yaw: float = 0.0
var _pitch: float = 0.0
var _targeted_painting_id: String = ""
var _targeted_painting_title: String = ""
var _targeted_prop_id: String = ""
var _targeted_prop_title: String = ""
var _step_timer: float = 0.0
var _rustle_timer: float = 0.0
var _lantern_on: bool = false
var _was_on_floor: bool = true

var _camera: Camera3D
var _ray: RayCast3D
var _lantern: SpotLight3D
var _casino_room: CasinoRoom


func _ready() -> void:
	floor_max_angle = deg_to_rad(52.0)
	floor_snap_length = 0.35

	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.36
	cap.height = 1.78
	col.shape = cap
	col.position = Vector3(0, 0.89, 0)
	add_child(col)

	_camera = Camera3D.new()
	_camera.name = "PlayerCamera"
	_camera.position = Vector3(0, EYE_HEIGHT, 0)
	_camera.fov = 74.0
	_camera.far = 650.0
	_camera.current = true
	add_child(_camera)

	_ray = RayCast3D.new()
	_ray.target_position = Vector3(0, 0, -4.8)
	_ray.collision_mask = 3 # Layers 1 (walls/terrain) + 2 (paintings & interactive props)
	_ray.collide_with_areas = false
	_ray.collide_with_bodies = true
	_camera.add_child(_ray)

	_lantern = SpotLight3D.new()
	_lantern.light_color = Color(1.0, 0.92, 0.78)
	_lantern.light_energy = 3.6
	_lantern.spot_range = 32.0
	_lantern.spot_angle = 36.0
	_lantern.shadow_enabled = int(ConfigManager.graphics.get("shadows", 3)) >= 2
	_lantern.shadow_bias = 0.04
	_lantern.shadow_blur = 1.4
	_lantern.visible = false
	_camera.add_child(_lantern)
	ConfigManager.graphics_changed.connect(func():
		if is_instance_valid(_lantern):
			_lantern.shadow_enabled = int(ConfigManager.graphics.get("shadows", 3)) >= 2
	)


func set_casino_room(room: CasinoRoom) -> void:
	_casino_room = room


func get_camera() -> Camera3D:
	return _camera


func reset_to_casino_spawn() -> void:
	global_position = Vector3(0.0, 6.12, 4.4)
	velocity = Vector3.ZERO
	_yaw = 0.0 # Facing North (-Z) toward the Roulette table & paintings!
	_pitch = -0.04
	rotation = Vector3.ZERO
	_camera.position = Vector3(0, EYE_HEIGHT, 0)
	_camera.rotation = Vector3(_pitch, _yaw, 0.0)
	_camera.fov = 74.0
	reset_physics_interpolation()
	_camera.reset_physics_interpolation()


func get_save_state() -> Dictionary:
	return {
		"pos": global_position,
		"yaw": _yaw,
		"pitch": _pitch,
		"lantern": _lantern_on
	}


func apply_save_state(st: Dictionary) -> void:
	global_position = st.get("pos", Vector3(0.0, 6.12, 4.4)) as Vector3
	velocity = Vector3.ZERO
	_yaw = float(st.get("yaw", 0.0))
	_pitch = clampf(float(st.get("pitch", -0.04)), -1.35, 1.35)
	_lantern_on = bool(st.get("lantern", false))
	_lantern.visible = _lantern_on
	rotation = Vector3.ZERO
	_camera.position = Vector3(0, EYE_HEIGHT, 0)
	_camera.rotation = Vector3(_pitch, _yaw, 0.0)
	_camera.fov = 74.0
	reset_physics_interpolation()
	_camera.reset_physics_interpolation()
	_clear_target()
	_ray.force_raycast_update()


func set_controls_active(active: bool) -> void:
	controls_enabled = active
	if active:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		_clear_target()


func _clear_target() -> void:
	if _targeted_painting_id != "":
		_targeted_painting_id = ""
		_targeted_painting_title = ""
		target_painting_changed.emit("", "")
		if _casino_room:
			_casino_room.set_highlighted_painting("")
	if _targeted_prop_id != "":
		_targeted_prop_id = ""
		_targeted_prop_title = ""
		target_prop_changed.emit("", "")


func _input(event: InputEvent) -> void:
	if not controls_enabled:
		return

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var mm := event as InputEventMouseMotion
		_yaw -= mm.relative.x * 0.0022
		_pitch = clampf(_pitch - mm.relative.y * 0.0022, -1.35, 1.35)
		_camera.rotation = Vector3(_pitch, _yaw, 0.0)

	# Physical key E (any keyboard layout EN/UK/RU, Shift does NOT matter!)
	elif event is InputEventKey:
		var k := event as InputEventKey
		if k.pressed and not k.echo:
			if k.physical_keycode == KEY_E:
				if _targeted_painting_id != "":
					get_viewport().set_input_as_handled()
					interact_painting_requested.emit(_targeted_painting_id)
				elif _targeted_prop_id != "":
					get_viewport().set_input_as_handled()
					interact_prop_requested.emit(_targeted_prop_id)
			elif k.physical_keycode == KEY_F:
				_lantern_on = not _lantern_on
				_lantern.visible = _lantern_on
				AudioSfx.play_switch()

	# Left Mouse Button interaction with targeted painting or interactive prop
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			elif _targeted_painting_id != "":
				get_viewport().set_input_as_handled()
				interact_painting_requested.emit(_targeted_painting_id)
			elif _targeted_prop_id != "":
				get_viewport().set_input_as_handled()
				interact_prop_requested.emit(_targeted_prop_id)


func _physics_process(delta: float) -> void:
	if not controls_enabled:
		return

	var on_floor := is_on_floor()
	var outside_casino := absf(global_position.x) > 22.5 or absf(global_position.z) > 12.5
	var in_shallow_water := outside_casino and global_position.y <= WorldBuilder.WATER_LEVEL + 0.25
	if on_floor and not _was_on_floor:
		AudioSfx.play_player_land(in_shallow_water)
	_was_on_floor = on_floor

	if not on_floor:
		velocity.y -= GRAVITY * delta
	elif Input.is_physical_key_pressed(KEY_SPACE):
		velocity.y = JUMP_VELOCITY
		AudioSfx.play_player_jump()

	var move_2d := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		move_2d.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		move_2d.y += 1.0
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		move_2d.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		move_2d.x += 1.0

	var forward := Vector3(-sin(_yaw), 0.0, -cos(_yaw))
	var right := Vector3(cos(_yaw), 0.0, -sin(_yaw))
	var wish_dir := (right * move_2d.x + forward * (-move_2d.y))
	if wish_dir.length_squared() > 0.001:
		wish_dir = wish_dir.normalized()

	var spd := SPRINT_SPEED if Input.is_physical_key_pressed(KEY_SHIFT) else WALK_SPEED
	if in_shallow_water:
		var depth := clampf(WorldBuilder.WATER_LEVEL - global_position.y, 0.0, 2.5)
		spd *= clampf(0.84 - depth * 0.16, 0.50, 0.84)
		# Keep player smoothly buoyed in deeper water instead of walking completely underwater
		if global_position.y < WorldBuilder.WATER_LEVEL - 0.85:
			global_position.y = lerpf(global_position.y, WorldBuilder.WATER_LEVEL - 0.85, clampf(delta * 10.0, 0.0, 1.0))
			velocity.y = maxf(velocity.y, 0.0)
	velocity.x = lerpf(velocity.x, wish_dir.x * spd, delta * 11.0)
	velocity.z = lerpf(velocity.z, wish_dir.z * spd, delta * 11.0)

	move_and_slide()

	# Keep inside valley playable bounds (-235..235)
	global_position.x = clampf(global_position.x, -235.0, 235.0)
	global_position.z = clampf(global_position.z, -235.0, 235.0)

	var sg_singleton := get_node_or_null("/root/SimpleGrass")
	if sg_singleton:
		sg_singleton.call("set_player_position", global_position)

	# Footsteps & surface awareness (carpet / parquet-stone / shallow water / forest grass)
	var horiz_speed := Vector2(velocity.x, velocity.z).length()
	var in_complex := absf(global_position.x) < 20.5 and absf(global_position.z) < 9.5
	var on_carpet := ((absf(global_position.x) < 6.4 and absf(global_position.z) < 6.4 and global_position.y > 5.8 and global_position.y < 11.0) or (global_position.y >= 12.6 and absf(global_position.x) < 12.0 and absf(global_position.z) < 7.5))
	var on_stone := in_complex or (absf(global_position.x) < 23.2 and absf(global_position.z) < 12.2 and global_position.y > 5.4)
	if (on_floor or in_shallow_water) and horiz_speed > 1.0:
		_step_timer -= delta * (horiz_speed / WALK_SPEED)
		if _step_timer <= 0.0:
			_step_timer = 0.36 if in_shallow_water else 0.42
			var surf := "water" if in_shallow_water else ("carpet" if on_carpet else ("stone" if on_stone else "grass"))
			AudioSfx.play_step(surf)
		if not in_shallow_water and not on_carpet and not on_stone and horiz_speed > 2.2:
			_rustle_timer -= delta
			if _rustle_timer <= 0.0:
				_rustle_timer = randf_range(0.55, 0.95)
				AudioSfx.play_foliage_rustle(randf_range(-0.35, 0.35))
		else:
			_rustle_timer = minf(_rustle_timer, 0.15)
	else:
		_step_timer = 0.08

	# Auto-bounce if stepping onto giant Mushroom Trampoline (-30, y, 8)
	if on_floor and Vector2(global_position.x + 30.0, global_position.z - 8.0).length() < 1.55 and global_position.y < 10.0 and velocity.y < 5.0:
		interact_prop_requested.emit("bounce_shroom")

	_update_painting_target()


func _is_painting_unobstructed(pn: Node3D) -> bool:
	var cam_pos := _camera.global_position
	var face_pos := pn.global_position + pn.global_transform.basis.z * 0.14
	if (cam_pos - pn.global_position).dot(pn.global_transform.basis.z) < 0.15:
		return false
	var space := get_world_3d().direct_space_state
	if space == null:
		return true
	var q := PhysicsRayQueryParameters3D.create(cam_pos, face_pos, 1)
	return space.intersect_ray(q).is_empty()


func _update_painting_target() -> void:
	var best_id := ""
	var best_title := ""
	var prop_id := ""
	var prop_title := ""

	# Primary: direct raycast within 4.8m (layer 1 blocks walls; layer 2 detects paintings & interactive props)
	if _ray.is_colliding():
		var col := _ray.get_collider()
		if col and col.has_meta("painting_id"):
			var cand := str(col.get_meta("painting_id"))
			if _casino_room:
				var info_c := _casino_room.get_painting_by_id(cand)
				if not info_c.is_empty() and _is_painting_unobstructed(info_c["node"] as Node3D):
					best_id = cand
		elif col and col.has_meta("interact_id"):
			prop_id = str(col.get_meta("interact_id"))
			prop_title = str(col.get_meta("interact_title", prop_id))

	# Secondary convenience for paintings: standing close inside front hemisphere
	if best_id == "" and prop_id == "" and _casino_room:
		var cam_pos := _camera.global_position
		var cam_fwd := -_camera.global_transform.basis.z
		var best_score := -1.0
		for p in _casino_room.paintings:
			var pn: Node3D = p["node"]
			var to_p := pn.global_position - cam_pos
			var dist := to_p.length()
			if dist <= 3.1:
				var dot := cam_fwd.dot(to_p.normalized())
				if dot > 0.55 and dot > best_score and _is_painting_unobstructed(pn):
					best_score = dot
					best_id = str(p["id"])

	if best_id != "" and _casino_room:
		var info := _casino_room.get_painting_by_id(best_id)
		best_title = str(info.get("title", best_id))

	if best_id != _targeted_painting_id:
		_targeted_painting_id = best_id
		_targeted_painting_title = best_title
		if best_id != "":
			AudioSfx.play_hover_painting()
		target_painting_changed.emit(best_id, best_title)
		if _casino_room:
			_casino_room.set_highlighted_painting(best_id)

	if prop_id != _targeted_prop_id:
		_targeted_prop_id = prop_id
		_targeted_prop_title = prop_title
		if prop_id != "":
			AudioSfx.play_hover_painting()
		target_prop_changed.emit(prop_id, prop_title)
