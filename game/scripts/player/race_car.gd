class_name RaceCarController
extends Node3D

const RaceTrackScript := preload("res://scripts/world/race_track.gd")

signal exit_car_requested
signal hud_updated(text: String)

var _track
var _car_mesh: Node3D
var _cam: Camera3D
var _active: bool = false

var _track_idx: int = -1
var _track_s: float = 0.0
var _speed: float = 0.0
var _lat: float = 0.0
var _rel_yaw: float = 0.0
var _nitro: float = 100.0
var _lap: int = 1
var _airborne: bool = false
var _air_vel: Vector3 = Vector3.ZERO
var _air_t: float = 0.0
var _prev_start_side: float = 0.0
var _hood_cam: bool = false
var _cam_pos_smooth: Vector3 = Vector3.ZERO
var _cam_up_smooth: Vector3 = Vector3.UP


func _ready() -> void:
	_car_mesh = RaceTrackScript.build_sports_car_mesh(Color(0.14, 0.48, 0.96))
	add_child(_car_mesh)

	_cam = Camera3D.new()
	_cam.name = "RaceCamera"
	_cam.fov = 76.0
	_cam.far = 750.0
	add_child(_cam)
	visible = false


func setup(p_track) -> void:
	_track = p_track


func start_race() -> void:
	if _track == null:
		return
	_track_s = float(_track.get_pit_start_s())
	var sp: Dictionary = _track.sample_at_s(_track_s)
	_track_idx = int(sp.get("idx", 0))
	_speed = 0.0
	_lat = 0.0
	_rel_yaw = 0.0
	_nitro = 100.0
	_lap = 1
	_airborne = false
	_air_t = 0.0
	_prev_start_side = 0.0
	global_transform = Transform3D(Basis(sp["right"], sp["up"], -(sp["fwd"] as Vector3)), sp["pos"])
	_cam_pos_smooth = global_position - (sp["fwd"] as Vector3) * 7.2 + (sp["up"] as Vector3) * 2.8
	_cam_up_smooth = sp["up"]
	visible = true
	_active = true
	_track.set_player_driving(true)
	_cam.current = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func stop_race() -> void:
	_active = false
	visible = false
	_cam.current = false
	if _track:
		_track.set_player_driving(false)


func reset_to_track() -> void:
	if _track == null:
		return
	var f: Dictionary = _track.find_closest_frame(global_position, _track_idx)
	if bool(f.get("is_gap", false)):
		_track_s = fposmod(_track_s - 25.0, float(_track.total_length))
	else:
		_track_s = float(f.get("s", _track_s))
	var sp: Dictionary = _track.sample_at_s(_track_s)
	_track_idx = int(sp.get("idx", 0))
	_lat = 0.0
	_rel_yaw = 0.0
	_speed = 8.0
	_airborne = false
	_air_t = 0.0
	global_transform = Transform3D(Basis(sp["right"], sp["up"], -(sp["fwd"] as Vector3)), sp["pos"])


func _input(event: InputEvent) -> void:
	if not _active:
		return
	if event is InputEventKey:
		var k := event as InputEventKey
		if k.pressed and not k.echo:
			if k.physical_keycode == KEY_ESCAPE:
				get_viewport().set_input_as_handled()
				exit_car_requested.emit()
			elif k.physical_keycode == KEY_R:
				get_viewport().set_input_as_handled()
				reset_to_track()
			elif k.physical_keycode == KEY_V:
				_hood_cam = not _hood_cam


func _physics_process(delta: float) -> void:
	if not _active or _track == null:
		return

	var accel := (1.0 if (Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)) else 0.0) - (1.0 if (Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) else 0.0)
	var steer := (1.0 if (Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)) else 0.0) - (1.0 if (Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) else 0.0)
	var boosting := (Input.is_physical_key_pressed(KEY_SHIFT) or Input.is_physical_key_pressed(KEY_SPACE)) and _nitro > 2.0 and accel > 0.0

	if boosting:
		_nitro = maxf(0.0, _nitro - delta * 26.0)
	else:
		_nitro = minf(100.0, _nitro + delta * 12.0)

	var max_fwd := 56.0 if boosting else 39.0

	if not _airborne:
		var sp: Dictionary = _track.sample_at_s(_track_s)
		if sp.is_empty():
			return
		_track_idx = int(sp["idx"])
		var fwd: Vector3 = sp["fwd"]
		var up: Vector3 = sp["up"]

		# Slope gravity feel + Loop adhesion check
		var slope_g := -fwd.y * 12.0
		if accel > 0.0:
			_speed = move_toward(_speed, max_fwd, (32.0 if boosting else 22.0) * delta)
		elif accel < 0.0:
			_speed = move_toward(_speed, -14.0, 28.0 * delta)
		else:
			_speed = move_toward(_speed, 0.0, 9.5 * delta)
		_speed += slope_g * delta * 0.45

		# Boost pad auto launch surge!
		if bool(sp["is_boost"]):
			if _speed < 44.0:
				AudioSfx.play_boost_whoosh()
			_speed = maxf(_speed, 46.0)

		# Smooth loop stability if entering loop slightly slow
		if bool(sp["is_loop"]) and _speed > 4.0 and _speed < 24.0:
			_speed = maxf(_speed, 26.0)

		var steer_rate := clampf(absf(_speed) / 14.0, 0.15, 1.0) * (1.0 if _speed >= 0.0 else -1.0)
		_rel_yaw = clampf(_rel_yaw + steer * steer_rate * delta * 1.45, -0.52, 0.52)
		if absf(steer) < 0.05:
			_rel_yaw = move_toward(_rel_yaw, 0.0, delta * 2.2)

		var advance := _speed * cos(_rel_yaw) * delta
		var lat_move := -_speed * sin(_rel_yaw) * delta
		var prev_s := _track_s
		_track_s = fposmod(_track_s + advance, _track.total_length)
		if prev_s > _track.total_length * 0.85 and _track_s < _track.total_length * 0.15:
			_lap += 1
			AudioSfx.play_race_lap()

		var half_w := float(sp["width"]) * 0.5 - 1.15
		_lat += lat_move
		if absf(_lat) > half_w:
			_lat = signf(_lat) * half_w
			_rel_yaw *= 0.25
			_speed *= 0.96

		var sp_next: Dictionary = _track.sample_at_s(_track_s)
		if bool(sp_next["is_gap"]):
			_airborne = true
			_air_t = 0.0
			_air_vel = (fwd * _speed) + up * maxf(_speed * 0.18, 4.5)
			AudioSfx.play_jump()
		else:
			var n_fwd: Vector3 = sp_next["fwd"]
			var n_up: Vector3 = sp_next["up"]
			var n_right: Vector3 = sp_next["right"]
			var car_basis := Basis(n_right, n_up, -n_fwd) * Basis(Vector3.UP, _rel_yaw)
			var car_pos := (sp_next["pos"] as Vector3) + n_right * _lat
			global_transform = Transform3D(car_basis, car_pos)
	else:
		# Ballistic 3D canyon gap flight!
		_air_t += delta
		_air_vel.y -= 17.5 * delta
		global_position += _air_vel * delta
		var f_near: Dictionary = _track.find_closest_frame(global_position, _track_idx)
		if not bool(f_near.get("is_gap", true)):
			var f_pos: Vector3 = f_near["pos"]
			var f_up: Vector3 = f_near["up"]
			var rel_h: float = (global_position - f_pos).dot(f_up)
			var lat_off: float = (global_position - f_pos).dot(f_near["right"] as Vector3)
			if rel_h <= 0.55 and rel_h >= -3.5 and absf(lat_off) <= float(f_near["width"]) * 0.55 and _air_t > 0.25:
				_airborne = false
				_track_s = float(f_near["s"])
				_track_idx = int(f_near["idx"])
				_lat = clampf(lat_off, -float(f_near["width"]) * 0.42, float(f_near["width"]) * 0.42)
				_speed = clampf(_air_vel.length(), 18.0, 56.0)
				_rel_yaw = 0.0
				AudioSfx.play_player_land(false)
		if _air_t > 2.2 or global_position.y < -1.0:
			reset_to_track()

	# Spin wheels & update dynamic chase/hood camera
	var wheels: Array = _car_mesh.get_meta("wheels", [])
	for w: MeshInstance3D in wheels:
		w.rotate_x(-_speed * delta * 1.9)

	var basis_now := global_transform.basis
	var cam_fwd := -basis_now.z
	var cam_up := basis_now.y
	if _hood_cam:
		_cam.global_transform = Transform3D(basis_now, global_position + cam_up * 1.45 + cam_fwd * 0.55)
	else:
		var target_cam_pos := global_position - cam_fwd * 7.6 + cam_up * 2.75
		_cam_pos_smooth = _cam_pos_smooth.lerp(target_cam_pos, clampf(delta * 10.5, 0.0, 1.0))
		_cam_up_smooth = _cam_up_smooth.lerp(cam_up, clampf(delta * 7.5, 0.0, 1.0)).normalized()
		_cam.global_position = _cam_pos_smooth
		_cam.look_at(global_position + cam_fwd * 6.5 + _cam_up_smooth * 0.9, _cam_up_smooth)
	_cam.fov = lerpf(_cam.fov, 86.0 if boosting else clampf(72.0 + absf(_speed) * 0.25, 72.0, 84.0), delta * 6.0)

	# Compute live rank against the 3 AI rivals
	var rank := 1
	var t_len := float(_track.total_length)
	var my_prog: float = float(_lap) * t_len + _track_s
	for r in _track.rivals:
		var r_prog: float = float(int(r["lap"])) * t_len + float(r["s"])
		if r_prog > my_prog:
			rank += 1

	var kmh := int(round(absf(_speed) * 3.6))
	hud_updated.emit("Швидкість: %d км/год  |  Місце: %d/4  |  Коло: %d  |  Нітро: %d%%  |  [Shift] Нітро  [V] Камера  [R] Трек  [Esc] Вийти" % [kmh, rank, _lap, int(round(_nitro))])
