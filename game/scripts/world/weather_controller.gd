class_name WeatherController
extends Node3D

signal weather_state_changed(label_uk: String)

enum WeatherType { CLEAR = 0, CLOUDY = 1, FOGGY = 2, RAIN = 3, STORM = 4 }

const WEATHER_LABELS: Array[String] = [
	"Ясно",
	"Хмарно",
	"Туман",
	"Дощ",
	"Гроза"
]

var sky3d: Sky3D
var water_material: ShaderMaterial
var foliage_materials: Array[ShaderMaterial] = []
var player_node: Node3D

var _mode: int = 0 # 0 = auto cycle, 1..5 = forced WeatherType + 1
var _current_weather: int = WeatherType.CLEAR
var _target_weather: int = WeatherType.CLEAR
var _cycle_timer: float = 0.0
var _blend: float = 1.0

var _rain_amount: float = 0.0
var _wind_strength: float = 0.35
var _cloud_cov: float = 0.45
var _fog_dens: float = 0.0008
var _lightning_timer: float = 6.0
var _lightning_flash: float = 0.0

var _rain_particles: GPUParticles3D
var _lightning_light: DirectionalLight3D
var _ferris_wheel
var _casino_room
var _road_bulb_mat: StandardMaterial3D
var _last_hud_min: int = -1


func setup(p_sky: Sky3D, p_water_mat: ShaderMaterial, p_foliage_mats: Array[ShaderMaterial], p_player: Node3D) -> void:
	sky3d = p_sky
	water_material = p_water_mat
	foliage_materials = p_foliage_mats
	player_node = p_player
	_build_rain_particles()
	_build_lightning()
	set_weather_mode(int(ConfigManager.graphics.get("weather_mode", 0)))
	apply_time_settings()


func bind_world_lights(p_ferris, p_casino, p_road_bulb_mat: StandardMaterial3D) -> void:
	_ferris_wheel = p_ferris
	_casino_room = p_casino
	_road_bulb_mat = p_road_bulb_mat
	_sync_darkness_lights()


func apply_time_settings() -> void:
	if sky3d == null:
		return
	var dur := clampf(float(ConfigManager.graphics.get("day_duration_min", 28.0)), 1.0, 60.0)
	sky3d.minutes_per_day = dur
	sky3d.update_interval = clampf(dur / 300.0, 0.016, 0.08)
	var t_mode := clampi(int(ConfigManager.graphics.get("day_time_mode", 0)), 0, 4)
	match t_mode:
		0:
			sky3d.game_time_enabled = true
		1:
			sky3d.game_time_enabled = false
			sky3d.current_time = 6.0
		2:
			sky3d.game_time_enabled = false
			sky3d.current_time = 13.0
		3:
			sky3d.game_time_enabled = false
			sky3d.current_time = 19.6
		4:
			sky3d.game_time_enabled = false
			sky3d.current_time = 23.5
	_sync_darkness_lights()


func get_sun_y() -> float:
	if sky3d and sky3d.sky:
		return sky3d.sky._sun_transform.origin.y
	return 1.0


func get_darkness_factor() -> float:
	# Sunset starts glowing smoothly below ~8.5 deg above horizon (sun_y <= 0.15) into full night (<= 0.04)
	return clampf((0.15 - get_sun_y()) / 0.11, 0.0, 1.0)


func is_dark_time() -> bool:
	return get_sun_y() < 0.14


func get_time_label() -> String:
	if sky3d == null:
		return ConfigManager.t("phase_day")
	var t := sky3d.current_time
	var hh := int(floor(t)) % 24
	var mm := int(floor(fmod(t, 1.0) * 60.0)) % 60
	var sy := get_sun_y()
	var p_key := "phase_night" if sy < 0.0 else ("phase_sunset" if sy < 0.14 and t >= 12.0 else ("phase_dawn" if sy < 0.14 else ("phase_morning" if t < 10.0 else "phase_day")))
	return "%02d:%02d (%s)" % [hh, mm, ConfigManager.t(p_key)]


func _sync_darkness_lights() -> void:
	var is_dark := is_dark_time()
	var dark_k := get_darkness_factor()
	if is_instance_valid(_ferris_wheel):
		_ferris_wheel.set_darkness(is_dark, dark_k)
	if is_instance_valid(_casino_room):
		_casino_room.set_searchlights_active(is_dark, dark_k)
	if _road_bulb_mat:
		_road_bulb_mat.emission_energy_multiplier = 2.4 * dark_k if is_dark else 0.0


func set_weather_mode(mode: int) -> void:
	_mode = clampi(mode, 0, 5)
	if _mode == 0:
		_target_weather = _current_weather
	else:
		_target_weather = _mode - 1
		_current_weather = _target_weather
		_blend = 0.99
	weather_state_changed.emit(get_weather_label())


func get_weather_label() -> String:
	return ConfigManager.t("w_lbl_%d" % clampi(_target_weather, 0, 4))


func get_rain_amount() -> float:
	return _rain_amount


func get_wind_strength() -> float:
	return _wind_strength


func get_save_state() -> Dictionary:
	return {
		"sky_time": sky3d.current_time if sky3d else 15.8,
		"weather_mode": int(ConfigManager.graphics.get("weather_mode", 0)),
		"current_weather": _current_weather,
		"target_weather": _target_weather,
		"cycle_timer": _cycle_timer
	}


func apply_save_state(st: Dictionary) -> void:
	if st.has("weather_mode"):
		ConfigManager.graphics["weather_mode"] = clampi(int(st["weather_mode"]), 0, 5)
		_mode = int(ConfigManager.graphics["weather_mode"])
	if sky3d and st.has("sky_time"):
		sky3d.current_time = float(st["sky_time"])
	if st.has("current_weather"):
		_current_weather = clampi(int(st["current_weather"]), 0, 4)
	if st.has("target_weather"):
		_target_weather = clampi(int(st["target_weather"]), 0, 4)
	_cycle_timer = float(st.get("cycle_timer", 0.0))
	_blend = 0.99
	_sync_darkness_lights()
	_process(0.016)
	weather_state_changed.emit(get_weather_label())


func _build_rain_particles() -> void:
	_rain_particles = GPUParticles3D.new()
	_rain_particles.name = "RainParticles"
	_rain_particles.amount = 1800
	_rain_particles.lifetime = 0.85
	_rain_particles.preprocess = 0.4
	_rain_particles.visibility_aabb = AABB(Vector3(-28, -20, -28), Vector3(56, 40, 56))
	_rain_particles.emitting = false

	var pmat := ParticleProcessMaterial.new()
	pmat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pmat.emission_box_extents = Vector3(22.0, 1.0, 22.0)
	pmat.direction = Vector3(0.18, -1.0, 0.08)
	pmat.spread = 3.5
	pmat.initial_velocity_min = 19.0
	pmat.initial_velocity_max = 24.0
	pmat.gravity = Vector3(0.0, -9.8, 0.0)
	_rain_particles.process_material = pmat

	var drop_mesh := BoxMesh.new()
	drop_mesh.size = Vector3(0.018, 0.58, 0.018)
	var drop_mat := StandardMaterial3D.new()
	drop_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	drop_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	drop_mat.albedo_color = Color(0.75, 0.84, 0.95, 0.42)
	drop_mesh.material = drop_mat
	_rain_particles.draw_pass_1 = drop_mesh

	add_child(_rain_particles)


func _build_lightning() -> void:
	_lightning_light = DirectionalLight3D.new()
	_lightning_light.name = "LightningFlash"
	_lightning_light.light_color = Color(0.78, 0.86, 1.0)
	_lightning_light.light_energy = 0.0
	_lightning_light.shadow_enabled = false
	_lightning_light.rotation_degrees = Vector3(-55.0, 35.0, 0.0)
	add_child(_lightning_light)


func _process(delta: float) -> void:
	if sky3d == null:
		return

	_sync_darkness_lights()
	var hud_min := int(floor(sky3d.current_time * 60.0)) % 1440
	if hud_min != _last_hud_min:
		_last_hud_min = hud_min
		weather_state_changed.emit(get_weather_label())

	if _mode == 0:
		_cycle_timer += delta
		var hold_dur := 240.0
		match _target_weather:
			WeatherType.CLEAR: hold_dur = 260.0
			WeatherType.CLOUDY: hold_dur = 135.0
			WeatherType.FOGGY: hold_dur = 85.0
			WeatherType.RAIN: hold_dur = 90.0
			WeatherType.STORM: hold_dur = 65.0
		if _cycle_timer >= hold_dur:
			_cycle_timer = 0.0
			if _target_weather == WeatherType.CLEAR:
				_target_weather = WeatherType.CLOUDY if randf() < 0.72 else WeatherType.FOGGY
			elif _target_weather == WeatherType.STORM:
				_target_weather = WeatherType.RAIN
			elif _target_weather == WeatherType.RAIN:
				_target_weather = WeatherType.CLOUDY if randf() < 0.70 else WeatherType.STORM
			elif _target_weather == WeatherType.FOGGY:
				_target_weather = WeatherType.CLEAR
			else:
				_target_weather = WeatherType.CLEAR if randf() < 0.65 else WeatherType.RAIN
			weather_state_changed.emit(get_weather_label())

	var t_rain := 0.0
	var t_wind := 0.25
	var t_cloud := 0.42
	var t_fog := 0.0007
	var t_sun := 1.05

	match _target_weather:
		WeatherType.CLEAR:
			t_rain = 0.0; t_wind = 0.25; t_cloud = 0.40; t_fog = 0.00012; t_sun = 1.85
		WeatherType.CLOUDY:
			t_rain = 0.0; t_wind = 0.48; t_cloud = 0.76; t_fog = 0.00045; t_sun = 1.05
		WeatherType.FOGGY:
			t_rain = 0.0; t_wind = 0.16; t_cloud = 0.65; t_fog = 0.00680; t_sun = 0.85
		WeatherType.RAIN:
			t_rain = 0.65; t_wind = 0.72; t_cloud = 0.88; t_fog = 0.00160; t_sun = 0.68
		WeatherType.STORM:
			t_rain = 1.0; t_wind = 1.20; t_cloud = 0.96; t_fog = 0.00280; t_sun = 0.52

	var rate := minf(delta * 0.16, 1.0)
	_rain_amount = lerpf(_rain_amount, t_rain, rate)
	_wind_strength = lerpf(_wind_strength, t_wind, rate)
	_cloud_cov = lerpf(_cloud_cov, t_cloud, rate)
	_fog_dens = lerpf(_fog_dens, t_fog, rate)

	if sky3d.sky:
		var want_fog := _target_weather != WeatherType.CLEAR or _rain_amount > 0.05
		if sky3d.sky.fog_visible != want_fog:
			sky3d.sky.fog_visible = want_fog
		if absf(sky3d.sky.cumulus_coverage - _cloud_cov) > 0.003:
			sky3d.sky.cumulus_coverage = _cloud_cov
			sky3d.sky.cumulus_intensity = lerpf(1.35, 0.45, _rain_amount)
		if absf(sky3d.sky.fog_density - _fog_dens) > 0.00003:
			sky3d.sky.fog_density = _fog_dens
		sky3d.wind_speed = 1.5 + _wind_strength * 6.5
		if absf(sky3d.sun_energy - t_sun) > 0.01:
			sky3d.sun_energy = lerpf(sky3d.sun_energy, t_sun, rate)

	var sg_singleton := get_node_or_null("/root/SimpleGrass")
	if sg_singleton:
		sg_singleton.call("set_wind_strength", 0.08 + _wind_strength * 0.22)

	if sky3d.environment and not ConfigManager.is_compatibility_renderer():
		if sky3d.environment.volumetric_fog_enabled:
			var clear_vf := 0.00040 if _target_weather == WeatherType.CLEAR else clampf(_fog_dens * 2.0, 0.0010, 0.028)
			if absf(sky3d.environment.volumetric_fog_density - clear_vf) > 0.00005:
				sky3d.environment.volumetric_fog_density = clear_vf

	if water_material:
		water_material.set_shader_parameter("wind_strength", _wind_strength)
	for fm in foliage_materials:
		if fm:
			fm.set_shader_parameter("wind_strength", 0.14 + _wind_strength * 0.24)
			fm.set_shader_parameter("wind_speed", 1.4 + _wind_strength * 1.8)

	# Keep rain centered around player and suppress drops directly inside Casino Pavilion roof!
	var in_casino := false
	if player_node:
		var p := player_node.global_position
		_rain_particles.global_position = Vector3(p.x, p.y + 16.0, p.z)
		var in_ground_floors := absf(p.x) < 20.5 and absf(p.z) < 9.5 and p.y < 12.8
		var in_mansard := p.x > -12.0 and p.x < 19.8 and absf(p.z) < 7.8 and p.y >= 12.8 and p.y < 18.6
		in_casino = in_ground_floors or in_mansard

	var should_rain := _rain_amount > 0.12 and not in_casino
	_rain_particles.emitting = should_rain
	if should_rain:
		_rain_particles.amount_ratio = clampf(_rain_amount, 0.15, 1.0)

	# Storm lightning flashes
	if _target_weather == WeatherType.STORM and _rain_amount > 0.7:
		_lightning_timer -= delta
		if _lightning_timer <= 0.0:
			_lightning_timer = randf_range(5.0, 13.0)
			_lightning_flash = 3.2
			AudioSfx.play_thunder()
	if _lightning_flash > 0.0:
		_lightning_flash = maxf(0.0, _lightning_flash - delta * 8.5)
	_lightning_light.light_energy = _lightning_flash
