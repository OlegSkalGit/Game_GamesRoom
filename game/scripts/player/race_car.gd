class_name RaceCarController
extends Node3D

const RaceTrackScript := preload("res://scripts/world/race_track.gd")
const LAPS_TOTAL := 3
const GRID_START_OFFSET := 6.0

enum Phase { COUNTDOWN = 0, RACING = 1, FINISHED = 2 }

signal exit_car_requested
signal hud_updated(text: String)
signal race_banner_updated(text: String, color: Color, show: bool)
signal race_completed(rank: int, race_time: float)

var _track
var _car_mesh: Node3D
var _body_pivot: Node3D
var _wheel_pivots: Array = []
var _wheels: Array = []
var _cam: Camera3D
var _active: bool = false

var _phase: int = Phase.COUNTDOWN
var _countdown_t: float = 3.0
var _countdown_step: int = -1
var _banner_hold_t: float = 0.0
var _race_time: float = 0.0
var _finished_rank: int = 0

var _track_idx: int = -1
var _track_s: float = 0.0
var _progress_dist: float = 0.0
var _speed: float = 0.0
var _lat: float = 0.0
var _steer_input: float = 0.0
var _rel_yaw: float = 0.0
var _nitro: float = 100.0
var _lap: int = 1
var _airborne: bool = false
var _air_vel: Vector3 = Vector3.ZERO
var _air_t: float = 0.0
var _crest_cooldown: float = 0.0
var _hood_cam: bool = false
var _cam_pos_smooth: Vector3 = Vector3.ZERO
var _cam_up_smooth: Vector3 = Vector3.UP


func _ready() -> void:
	_car_mesh = RaceTrackScript.build_sports_car_mesh(Color(0.14, 0.48, 0.96), true)
	add_child(_car_mesh)
	_body_pivot = _car_mesh.get_meta("body_pivot", null)
	_wheel_pivots = _car_mesh.get_meta("wheel_pivots", [])
	_wheels = _car_mesh.get_meta("wheels", [])

	_cam = Camera3D.new()
	_cam.name = "RaceCamera"
	_cam.fov = 76.0
	_cam.far = 850.0
	add_child(_cam)
	visible = false


func setup(p_track) -> void:
	_track = p_track


func start_race() -> void:
	if _track == null:
		return
	_track.prepare_race_start()
	_track_s = fposmod(float(_track.total_length) - GRID_START_OFFSET, float(_track.total_length))
	var sp: Dictionary = _track.sample_at_s(_track_s)
	_track_idx = int(sp.get("idx", 0))
	_progress_dist = -GRID_START_OFFSET
	_speed = 0.0
	_lat = 0.0
	_steer_input = 0.0
	_rel_yaw = 0.0
	_nitro = 100.0
	_lap = 1
	_airborne = false
	_air_t = 0.0
	_crest_cooldown = 0.0
	_race_time = 0.0
	_finished_rank = 0

	_phase = Phase.COUNTDOWN
	_countdown_t = 3.0
	_countdown_step = 3
	_banner_hold_t = 0.0

	if _body_pivot:
		_body_pivot.rotation = Vector3.ZERO
	for i: int in range(mini(2, _wheel_pivots.size())):
		(_wheel_pivots[i] as Node3D).rotation.y = 0.0

	global_transform = Transform3D(Basis(sp["right"], sp["up"], -(sp["fwd"] as Vector3)), sp["pos"])
	_cam_pos_smooth = global_position - (sp["fwd"] as Vector3) * 7.6 + (sp["up"] as Vector3) * 2.85
	_cam_up_smooth = sp["up"]
	visible = true
	_active = true
	_track.set_player_driving(true)
	_track.set_traffic_light("red3")
	AudioSfx.play_countdown_beep(false)
	race_banner_updated.emit("3", Color(1.0, 0.28, 0.22), true)
	_cam.current = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func stop_race() -> void:
	_active = false
	visible = false
	_cam.current = false
	race_banner_updated.emit("", Color.WHITE, false)
	if _track:
		_track.set_player_driving(false)


func reset_to_track() -> void:
	if _track == null:
		return
	var f: Dictionary = _track.find_closest_frame(global_position, _track_idx)
	_track_s = float(f.get("s", _track_s))
	var sp: Dictionary = _track.sample_at_s(_track_s)
	_track_idx = int(sp.get("idx", 0))
	_lat = 0.0
	_steer_input = 0.0
	_rel_yaw = 0.0
	_speed = 10.0
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
				if _phase == Phase.FINISHED:
					start_race()
				else:
					reset_to_track()
			elif k.physical_keycode == KEY_V:
				_hood_cam = not _hood_cam


func _physics_process(delta: float) -> void:
	if not _active or _track == null:
		return

	if _crest_cooldown > 0.0:
		_crest_cooldown = maxf(0.0, _crest_cooldown - delta)

	if _banner_hold_t > 0.0:
		_banner_hold_t -= delta
		if _banner_hold_t <= 0.0 and _phase == Phase.RACING:
			race_banner_updated.emit("", Color.WHITE, false)
			_track.set_traffic_light("off")

	var raw_accel := (1.0 if (Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)) else 0.0) - (1.0 if (Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) else 0.0)
	var raw_steer := (1.0 if (Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)) else 0.0) - (1.0 if (Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) else 0.0)
	_steer_input = move_toward(_steer_input, raw_steer, delta * (4.2 if absf(raw_steer) > 0.1 else 5.8))

	# Countdown 3 -> 2 -> 1 -> GO! synchronized with 3D Start Gantry Traffic Light ("Світлофор")
	if _phase == Phase.COUNTDOWN:
		_countdown_t -= delta
		if _countdown_t <= 2.0 and _countdown_step == 3:
			_countdown_step = 2
			_track.set_traffic_light("red2")
			AudioSfx.play_countdown_beep(false)
			race_banner_updated.emit("2", Color(1.0, 0.45, 0.18), true)
		elif _countdown_t <= 1.0 and _countdown_step == 2:
			_countdown_step = 1
			_track.set_traffic_light("amber1")
			AudioSfx.play_countdown_beep(false)
			race_banner_updated.emit("1", Color(1.0, 0.82, 0.18), true)
		elif _countdown_t <= 0.0:
			_countdown_step = 0
			_phase = Phase.RACING
			_banner_hold_t = 0.95
			_track.set_traffic_light("go")
			_track.set_race_mode("racing")
			AudioSfx.play_countdown_beep(true)
			race_banner_updated.emit("РУШ!", Color(0.24, 1.0, 0.48), true)

		# Subtle wheel preview & engine vibration during countdown
		for i: int in range(mini(2, _wheel_pivots.size())):
			(_wheel_pivots[i] as Node3D).rotation.y = _steer_input * 0.42
		if _body_pivot and raw_accel > 0.0:
			_body_pivot.rotation.x = sin(Time.get_ticks_msec() * 0.05) * 0.006
		_update_camera_and_hud(false, false, delta)
		return

	if _phase == Phase.RACING:
		_race_time += delta

	var boosting := (Input.is_physical_key_pressed(KEY_SHIFT) or Input.is_physical_key_pressed(KEY_SPACE)) and _nitro > 2.0 and raw_accel > 0.0
	if boosting:
		_nitro = maxf(0.0, _nitro - delta * 24.0)
	else:
		_nitro = minf(100.0, _nitro + delta * 14.0)

	var max_fwd := 66.0 if boosting else 49.0

	if not _airborne:
		var sp: Dictionary = _track.sample_at_s(_track_s)
		if sp.is_empty():
			return
		_track_idx = int(sp["idx"])
		var fwd: Vector3 = sp["fwd"]
		var up: Vector3 = sp["up"]
		var in_loop := bool(sp["is_loop"])

		# Hill gravity + Smooth loop magnetic climb traction (zero speed teleporting; works at ANY speed!)
		var slope_weight := 0.10 if in_loop else 0.42
		var slope_g := -fwd.y * 12.5
		if raw_accel > 0.0:
			_speed = move_toward(_speed, max_fwd, (34.0 if boosting else 25.0) * delta)
		elif raw_accel < 0.0:
			_speed = move_toward(_speed, -15.0, 30.0 * delta)
		else:
			_speed = move_toward(_speed, 0.0, 8.5 * delta)
		_speed += slope_g * delta * slope_weight

		if in_loop and raw_accel >= 0.0 and _speed > 0.2 and _speed < 14.0:
			_speed = move_toward(_speed, 14.0, delta * 14.0)

		if bool(sp["is_boost"]) or bool(sp["is_crest_boost"]):
			if _speed < 48.0:
				AudioSfx.play_boost_whoosh()
			_speed = move_toward(_speed, maxf(_speed, 54.0), delta * 45.0)

		# Smooth speed-sensitive bicycle/caster steering
		var max_yaw := lerpf(0.46, 0.26, clampf(absf(_speed) / 58.0, 0.0, 1.0))
		var rev_sign := 1.0 if _speed >= -0.2 else -1.0
		var target_yaw := _steer_input * max_yaw * rev_sign
		_rel_yaw = lerpf(_rel_yaw, target_yaw, clampf(delta * 5.8, 0.0, 1.0))

		var advance := _speed * cos(_rel_yaw) * delta
		var lat_move := -_speed * sin(_rel_yaw) * delta
		var t_len := float(_track.total_length)
		_track_s = fposmod(_track_s + advance, t_len)
		_progress_dist += advance
		_track.player_progress_dist = _progress_dist

		# Anti-cheat continuous 3-lap counting & Finish check
		if _phase == Phase.RACING:
			var cur_lap := mini(LAPS_TOTAL, maxi(1, int(floor(maxf(_progress_dist, 0.0) / t_len)) + 1))
			if cur_lap > _lap and _progress_dist < float(LAPS_TOTAL) * t_len:
				_lap = cur_lap
				AudioSfx.play_race_lap()
				_banner_hold_t = 1.85
				var lap_msg := "ФІНАЛЬНЕ КОЛО 3 / 3!" if _lap == LAPS_TOTAL else ("КОЛО %d / %d" % [_lap, LAPS_TOTAL])
				race_banner_updated.emit(lap_msg, Color(0.98, 0.86, 0.28), true)
			elif _progress_dist >= float(LAPS_TOTAL) * t_len:
				_phase = Phase.FINISHED
				_finished_rank = _compute_rank()
				AudioSfx.play_race_finish()
				race_banner_updated.emit(
					"🏆 ФІНІШ!  Місце: %d / 5  |  Час: %s\n[R] Нова гонка   [Esc] Вийти з боліда" % [_finished_rank, _format_time(_race_time)],
					Color(0.32, 1.0, 0.56),
					true
				)
				race_completed.emit(_finished_rank, _race_time)

		var half_w := float(sp["width"]) * 0.5 - 1.25
		_lat += lat_move
		# Soft car-to-car bumper push against AI rivals
		for r in _track.rivals:
			var ds_r := absf(wrapf(float(r["s"]) - _track_s, -t_len * 0.5, t_len * 0.5))
			if ds_r < 3.6:
				var dlat := _lat - float(r["lat"])
				if absf(dlat) < 2.05:
					var push_dir := 1.0 if dlat >= 0.0 else -1.0
					_lat = move_toward(_lat, float(r["lat"]) + push_dir * 2.1, delta * 12.0)
					_speed *= 0.992

		if absf(_lat) > half_w:
			_lat = signf(_lat) * half_w
			_rel_yaw = move_toward(_rel_yaw, 0.0, delta * 8.0)
			_speed *= (1.0 - delta * 0.35)

		var sp_next: Dictionary = _track.sample_at_s(_track_s)
		# Tabletop crest jump only launches fast cars (slow cars ride cleanly over the solid deck!)
		if bool(sp_next.get("is_crest_boost", false)) and _speed >= 36.0 and _crest_cooldown <= 0.0:
			_airborne = true
			_air_t = 0.0
			_crest_cooldown = 2.4
			_air_vel = (fwd * _speed) + up * maxf(_speed * 0.16, 4.8)
			AudioSfx.play_jump()
		else:
			var n_fwd: Vector3 = sp_next["fwd"]
			var n_up: Vector3 = sp_next["up"]
			var n_right: Vector3 = sp_next["right"]
			var car_basis := Basis(n_right, n_up, -n_fwd) * Basis(Vector3.UP, _rel_yaw)
			var car_pos := (sp_next["pos"] as Vector3) + n_right * _lat
			global_transform = Transform3D(car_basis, car_pos)
	else:
		# Smooth ballistic crest flight landing cleanly back onto the solid tabletop downslope!
		_air_t += delta
		_air_vel.y -= 17.5 * delta
		global_position += _air_vel * delta
		var f_near: Dictionary = _track.find_closest_frame(global_position, _track_idx)
		var f_pos: Vector3 = f_near["pos"]
		var f_up: Vector3 = f_near["up"]
		var rel_h: float = (global_position - f_pos).dot(f_up)
		var lat_off: float = (global_position - f_pos).dot(f_near["right"] as Vector3)
		if rel_h <= 0.45 and rel_h >= -3.0 and absf(lat_off) <= float(f_near["width"]) * 0.55 and _air_t > 0.25:
			_airborne = false
			_track_s = float(f_near["s"])
			_track_idx = int(f_near["idx"])
			_lat = clampf(lat_off, -float(f_near["width"]) * 0.42, float(f_near["width"]) * 0.42)
			_speed = clampf(_air_vel.length(), 20.0, 66.0)
			_rel_yaw = 0.0
			AudioSfx.play_player_land(false)
		elif _air_t > 2.4 or global_position.y < -2.0:
			reset_to_track()

	# Spin wheels cleanly on +X axle, turn front wheels visibly, apply suspension body roll & pitch
	for w: Node3D in _wheels:
		w.rotate_x(-_speed * delta * 1.9)
	for i: int in range(mini(2, _wheel_pivots.size())):
		(_wheel_pivots[i] as Node3D).rotation.y = _steer_input * 0.42
	if _body_pivot:
		var spd_ratio := clampf(absf(_speed) / 38.0, 0.0, 1.0)
		var target_roll := -_steer_input * 0.075 * spd_ratio
		var target_pitch := (raw_accel * -0.028) if not _airborne else -0.06
		_body_pivot.rotation.z = lerpf(_body_pivot.rotation.z, target_roll, clampf(delta * 9.0, 0.0, 1.0))
		_body_pivot.rotation.x = lerpf(_body_pivot.rotation.x, target_pitch, clampf(delta * 8.0, 0.0, 1.0))

	_update_camera_and_hud(boosting, true, delta)


func _update_camera_and_hud(boosting: bool, allow_speed_fov: bool, delta: float) -> void:
	var sp_cur: Dictionary = _track.sample_at_s(_track_s) if _track else {}
	var in_loop := bool(sp_cur.get("is_loop", false))
	var basis_now := global_transform.basis
	var cam_fwd := -basis_now.z
	var cam_up := basis_now.y
	if _hood_cam:
		_cam.global_transform = Transform3D(basis_now, global_position + cam_up * 1.48 + cam_fwd * 0.55)
	else:
		var up_lift := 3.18 if in_loop else 2.82
		var target_cam_pos := global_position - cam_fwd * 7.6 + cam_up * up_lift
		_cam_pos_smooth = _cam_pos_smooth.lerp(target_cam_pos, clampf(delta * 11.5, 0.0, 1.0))
		_cam_up_smooth = _cam_up_smooth.lerp(cam_up, clampf(delta * (10.5 if in_loop else 7.8), 0.0, 1.0)).normalized()
		_cam.global_position = _cam_pos_smooth
		_cam.look_at(global_position + cam_fwd * 6.8 + _cam_up_smooth * 0.9, _cam_up_smooth)
	if allow_speed_fov:
		_cam.fov = lerpf(_cam.fov, 88.0 if boosting else clampf(72.0 + absf(_speed) * 0.24, 72.0, 85.0), delta * 6.0)
	else:
		_cam.fov = lerpf(_cam.fov, 74.0, delta * 5.0)

	var rank := _finished_rank if _phase == Phase.FINISHED else _compute_rank()
	var kmh := int(round(absf(_speed) * 3.6))
	hud_updated.emit("Швидкість: %d км/год  |  Місце: %d/%d  |  Коло: %d/%d  |  Час: %s  |  Нітро: %d%%  |  [Shift] Нітро  [V] Камера  [R] Рестарт  [Esc] Вийти" % [kmh, rank, _track.rivals.size() + 1, _lap, LAPS_TOTAL, _format_time(_race_time), int(round(_nitro))])


func _compute_rank() -> int:
	var rank := 1
	for r in _track.rivals:
		if float(r.get("progress_dist", 0.0)) > _progress_dist:
			rank += 1
	return rank


static func _format_time(sec: float) -> String:
	var total_ds := int(floor(maxf(sec, 0.0) * 10.0))
	var ds := total_ds % 10
	var total_s := total_ds / 10
	var s := total_s % 60
	var m := total_s / 60
	return "%02d:%02d.%d" % [m, s, ds]
