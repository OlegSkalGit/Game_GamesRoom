extends Node

signal graphics_changed
signal display_changed

const PRESET_NAMES: Array[String] = [
	"Мінімальна (Слабкий ПК)",
	"Низька",
	"Середня",
	"Висока",
	"Ультра (Потужний ПК)",
	"Кінематографічна (Максимум)"
]

const AA_NAMES: Array[String] = [
	"Вимкнено",
	"FXAA",
	"TAA",
	"MSAA 2x",
	"MSAA 4x",
	"MSAA 4x + TAA"
]

const SHADOW_NAMES: Array[String] = [
	"Вимкнено",
	"Низькі (1024)",
	"Середні (2048)",
	"Високі (4096)",
	"Ультра (6144)"
]

const WINDOW_MODE_NAMES: Array[String] = [
	"Віконний",
	"Повноекранний"
]

const VSYNC_NAMES: Array[String] = [
	"Вимкнено",
	"Увімкнено",
	"Адаптивний"
]

const WEATHER_MODE_NAMES: Array[String] = [
	"Динамічна (Авто-цикл)",
	"Ясно (Сонячно)",
	"Хмарно",
	"Туман",
	"Дощ",
	"Гроза"
]

const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1366, 768),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
	Vector2i(3840, 2160)
]

var graphics: Dictionary = {
	"preset": 3,
	"render_scale": 1.0,
	"antialiasing": 2,
	"shadows": 3,
	"sdfgi": true,
	"ssao": true,
	"ssr": true,
	"volumetric_fog": true,
	"glow": true,
	"foliage_density": 1.0,
	"view_distance": 1.0,
	"weather_mode": 0
}

var display: Dictionary = {
	"width": 1920,
	"height": 1080,
	"window_mode": 0,
	"vsync": 1,
	"max_fps": 0
}

var audio: Dictionary = {
	"master_volume": 0.8
}


func _ready() -> void:
	load_config()
	apply_all()


func get_config_path() -> String:
	var res_cfg := ProjectSettings.globalize_path("res://config.cfg")
	if not OS.has_feature("standalone"):
		return res_cfg
	var exe_cfg := OS.get_executable_path().get_base_dir().path_join("config.cfg")
	if FileAccess.file_exists(exe_cfg):
		return exe_cfg
	return "user://config.cfg"


func load_config() -> void:
	var cfg := ConfigFile.new()
	var path := get_config_path()
	if cfg.load(path) != OK:
		save_config()
		return
	for key in graphics.keys():
		if cfg.has_section_key("graphics", key):
			graphics[key] = cfg.get_value("graphics", key, graphics[key])
	for key in display.keys():
		if cfg.has_section_key("display", key):
			display[key] = cfg.get_value("display", key, display[key])
	for key in audio.keys():
		if cfg.has_section_key("audio", key):
			audio[key] = cfg.get_value("audio", key, audio[key])


func save_config() -> void:
	var cfg := ConfigFile.new()
	for key in graphics.keys():
		cfg.set_value("graphics", key, graphics[key])
	for key in display.keys():
		cfg.set_value("display", key, display[key])
	for key in audio.keys():
		cfg.set_value("audio", key, audio[key])
	var path := get_config_path()
	var err := cfg.save(path)
	if err != OK and path != "user://config.cfg":
		cfg.save("user://config.cfg")


func is_compatibility_renderer() -> bool:
	return RenderingServer.get_current_rendering_method() == "gl_compatibility"


func get_renderer_display_name() -> String:
	var method := RenderingServer.get_current_rendering_method()
	var adapter := RenderingServer.get_video_adapter_name()
	if method == "gl_compatibility":
		return "OpenGL 3 (%s)" % adapter
	return "%s (%s)" % [method.to_upper(), adapter]


func apply_preset(preset_idx: int) -> void:
	preset_idx = clampi(preset_idx, 0, PRESET_NAMES.size() - 1)
	graphics["preset"] = preset_idx
	match preset_idx:
		0: # Мінімальна (Слабкий ПК)
			graphics["render_scale"] = 0.55
			graphics["antialiasing"] = 0
			graphics["shadows"] = 0
			graphics["sdfgi"] = false
			graphics["ssao"] = false
			graphics["ssr"] = false
			graphics["volumetric_fog"] = false
			graphics["glow"] = false
			graphics["foliage_density"] = 0.15
			graphics["view_distance"] = 0.40
		1: # Низька
			graphics["render_scale"] = 0.75
			graphics["antialiasing"] = 1
			graphics["shadows"] = 1
			graphics["sdfgi"] = false
			graphics["ssao"] = false
			graphics["ssr"] = false
			graphics["volumetric_fog"] = false
			graphics["glow"] = false
			graphics["foliage_density"] = 0.35
			graphics["view_distance"] = 0.60
		2: # Середня
			graphics["render_scale"] = 0.90
			graphics["antialiasing"] = 2
			graphics["shadows"] = 2
			graphics["sdfgi"] = false
			graphics["ssao"] = true
			graphics["ssr"] = false
			graphics["volumetric_fog"] = false
			graphics["glow"] = true
			graphics["foliage_density"] = 0.70
			graphics["view_distance"] = 0.82
		3: # Висока
			graphics["render_scale"] = 1.0
			graphics["antialiasing"] = 2
			graphics["shadows"] = 3
			graphics["sdfgi"] = false
			graphics["ssao"] = true
			graphics["ssr"] = true
			graphics["volumetric_fog"] = true
			graphics["glow"] = true
			graphics["foliage_density"] = 1.0
			graphics["view_distance"] = 1.0
		4: # Ультра (Потужний ПК)
			graphics["render_scale"] = 1.0
			graphics["antialiasing"] = 2
			graphics["shadows"] = 3
			graphics["sdfgi"] = true
			graphics["ssao"] = true
			graphics["ssr"] = true
			graphics["volumetric_fog"] = true
			graphics["glow"] = true
			graphics["foliage_density"] = 1.25
			graphics["view_distance"] = 1.25
		5: # Кінематографічна (Максимум)
			graphics["render_scale"] = 1.0
			graphics["antialiasing"] = 3
			graphics["shadows"] = 4
			graphics["sdfgi"] = true
			graphics["ssao"] = true
			graphics["ssr"] = true
			graphics["volumetric_fog"] = true
			graphics["glow"] = true
			graphics["foliage_density"] = 1.5
			graphics["view_distance"] = 1.45
	apply_graphics()
	save_config()


func apply_all() -> void:
	apply_display()
	apply_graphics()
	apply_audio()


func apply_audio() -> void:
	var bus := AudioServer.get_bus_index("Master")
	if bus >= 0:
		var vol: float = clampf(float(audio.get("master_volume", 0.8)), 0.0, 1.0)
		AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(vol, 0.0001)))
		AudioServer.set_bus_mute(bus, vol <= 0.001)


func apply_display() -> void:
	if DisplayServer.get_name() == "headless":
		display_changed.emit()
		return
	var w := maxi(640, int(display.get("width", 1920)))
	var h := maxi(480, int(display.get("height", 1080)))
	var mode := clampi(int(display.get("window_mode", 0)), 0, 1)
	display["window_mode"] = mode
	var vsync := int(display.get("vsync", 1))
	var max_fps := int(display.get("max_fps", 0))

	var screen_idx := DisplayServer.window_get_current_screen()
	var screen_pos := DisplayServer.screen_get_position(screen_idx)
	var screen_size := DisplayServer.screen_get_size(screen_idx)

	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
	match mode:
		0: # Віконний
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			var win_size := Vector2i(mini(w, screen_size.x), mini(h, screen_size.y))
			DisplayServer.window_set_size(win_size)
			var centered := screen_pos + (screen_size - win_size) / 2
			DisplayServer.window_set_position(centered)
		1: # Повноекранний
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)

	match vsync:
		0:
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		1:
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
		2:
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ADAPTIVE)

	Engine.max_fps = max_fps
	display_changed.emit()


func apply_graphics() -> void:
	var vp := get_viewport()
	if vp != null:
		var scale := clampf(float(graphics.get("render_scale", 1.0)), 0.5, 1.5)
		var compat := is_compatibility_renderer()
		vp.use_taa = false
		vp.scaling_3d_scale = scale
		if not compat and scale < 0.99:
			vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR2
		else:
			vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR

		var aa := int(graphics.get("antialiasing", 2))
		var fsr2_active := (vp.scaling_3d_mode == Viewport.SCALING_3D_MODE_FSR2)
		vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
		vp.msaa_3d = Viewport.MSAA_DISABLED
		if compat:
			if aa >= 2:
				vp.msaa_3d = Viewport.MSAA_2X
		else:
			match aa:
				1:
					vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
				2:
					if not fsr2_active:
						vp.use_taa = true
				3:
					vp.msaa_3d = Viewport.MSAA_2X
				4:
					vp.msaa_3d = Viewport.MSAA_4X
				5:
					vp.msaa_3d = Viewport.MSAA_4X
					if not fsr2_active:
						vp.use_taa = true

	var shadow_tier := int(graphics.get("shadows", 3))
	var shadow_sizes := [512, 1024, 2048, 4096, 6144]
	var s_size: int = shadow_sizes[clampi(shadow_tier, 0, shadow_sizes.size() - 1)]
	RenderingServer.directional_shadow_atlas_set_size(s_size, true)
	if vp != null:
		vp.positional_shadow_atlas_size = 4096 if shadow_tier >= 3 else (2048 if shadow_tier >= 1 else 512)
	match shadow_tier:
		0, 1:
			RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_HARD)
			RenderingServer.positional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_HARD)
		2:
			RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_LOW)
			RenderingServer.positional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_LOW)
		3:
			RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_MEDIUM)
			RenderingServer.positional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_MEDIUM)
		_:
			RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_HIGH)
			RenderingServer.positional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_HIGH)

	graphics_changed.emit()


func apply_to_environment(env: Environment) -> void:
	if env == null:
		return
	var compat := is_compatibility_renderer()
	var preset_idx := int(graphics.get("preset", 3))
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 0.96
	env.tonemap_white = 6.5

	env.adjustment_enabled = preset_idx >= 2
	env.adjustment_brightness = 1.0
	env.adjustment_contrast = 1.09
	env.adjustment_saturation = 1.06

	var use_glow := bool(graphics.get("glow", true))
	env.glow_enabled = use_glow
	if use_glow:
		env.glow_intensity = 0.30
		env.glow_bloom = 0.035
		env.glow_hdr_threshold = 1.24

	if compat:
		env.sdfgi_enabled = false
		env.ssao_enabled = false
		env.ssil_enabled = false
		env.ssr_enabled = false
		env.volumetric_fog_enabled = false
	else:
		var use_gi := bool(graphics.get("sdfgi", false))
		env.sdfgi_enabled = use_gi
		env.sdfgi_use_occlusion = true
		env.sdfgi_read_sky_light = true
		env.sdfgi_bounce_feedback = 0.52
		env.sdfgi_cascades = 3
		env.sdfgi_min_cell_size = 0.45

		env.ssao_enabled = bool(graphics.get("ssao", true))
		env.ssao_radius = 1.6
		env.ssao_intensity = 1.45

		env.ssil_enabled = (preset_idx >= 3)
		env.ssil_radius = 4.5
		env.ssil_intensity = 0.90
		env.ssil_sharpness = 0.92
		env.ssil_normal_rejection = 1.0

		env.ssr_enabled = bool(graphics.get("ssr", true))
		env.ssr_max_steps = 20 if preset_idx <= 4 else 28
		env.ssr_fade_in = 0.14
		env.ssr_fade_out = 2.2
		env.ssr_depth_tolerance = 0.28

		env.volumetric_fog_enabled = bool(graphics.get("volumetric_fog", true))
		env.volumetric_fog_density = 0.0014
		env.volumetric_fog_anisotropy = 0.55
		env.volumetric_fog_length = 95.0 * float(graphics.get("view_distance", 1.0))
