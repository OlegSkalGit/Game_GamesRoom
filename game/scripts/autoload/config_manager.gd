extends Node

signal graphics_changed
signal display_changed
signal language_changed

const _LATIN_FOLD_GROUPS := [
	["áàâäãåăắằẳẵặấầẩẫậąảạ", "a"],
	["çćč", "c"],
	["ďđ", "d"],
	["éèêëěėęẹẻẽềếểễệ", "e"],
	["ğ", "g"],
	["íìîïıįỉĩị", "i"],
	["ł", "l"],
	["ńñň", "n"],
	["óòôöõőơớờởỡợốồổỗộỏọ", "o"],
	["ŕř", "r"],
	["śšşș", "s"],
	["ťț", "t"],
	["úùûüůűưứừửữựủũụ", "u"],
	["ýÿỳỷỹỵ", "y"],
	["źżž", "z"]
]

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

const TIME_MODE_NAMES: Array[String] = [
	"Авто (Цикл доби)",
	"Ранок (06:00)",
	"День (13:00)",
	"Захід (19:35)",
	"Ніч (23:30)"
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
	"antialiasing": 3,
	"shadows": 3,
	"sdfgi": false,
	"ssao": true,
	"ssr": true,
	"volumetric_fog": true,
	"glow": true,
	"foliage_density": 1.0,
	"view_distance": 1.0,
	"weather_mode": 0,
	"day_time_mode": 0,
	"day_duration_min": 28.0
}

var display: Dictionary = {
	"width": 1920,
	"height": 1080,
	"window_mode": 0,
	"vsync": 1,
	"max_fps": 0,
	"show_fps": false,
	"language": "en"
}

var audio: Dictionary = {
	"master_volume": 0.8
}

var _ui_font: FontVariation
var _languages: Array[Dictionary] = []
var _strings: Dictionary = {}
var _fallback_strings: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_init_ui_font()
	load_available_languages()
	load_config()
	set_language(str(display.get("language", "en")), false)
	apply_all()


func _init_ui_font() -> void:
	var fallbacks: Array[Font] = []
	for fname: String in [
		"Segoe UI", "Microsoft YaHei", "Yu Gothic UI", "Malgun Gothic",
		"Nirmala UI", "Leelawadee UI", "Arial", "Tahoma",
		"Noto Sans", "Noto Sans CJK SC", "Noto Sans Arabic", "Noto Sans Devanagari", "DejaVu Sans"
	]:
		var sf := SystemFont.new()
		sf.font_names = PackedStringArray([fname])
		fallbacks.append(sf)
	_ui_font = FontVariation.new()
	_ui_font.base_font = ThemeDB.fallback_font
	_ui_font.fallbacks = fallbacks
	var def_theme := ThemeDB.get_default_theme()
	if def_theme:
		def_theme.default_font = _ui_font


func get_ui_font() -> Font:
	return _ui_font if _ui_font else ThemeDB.fallback_font


func get_lang_dir() -> String:
	var res_dir := ProjectSettings.globalize_path("res://lang")
	if not OS.has_feature("standalone"):
		return res_dir
	var exe_dir := OS.get_executable_path().get_base_dir().path_join("lang")
	if DirAccess.dir_exists_absolute(exe_dir):
		return exe_dir
	return "res://lang"


static func _lang_sort_key(s: String) -> String:
	var low := s.to_lower()
	var out := ""
	for i in range(low.length()):
		var ch := low.substr(i, 1)
		var mapped := ch
		for grp in _LATIN_FOLD_GROUPS:
			if str(grp[0]).find(ch) >= 0:
				mapped = str(grp[1])
				break
		out += mapped
	return out + "|" + low


func load_available_languages() -> void:
	_languages.clear()
	_fallback_strings.clear()
	var lang_dir := get_lang_dir()
	var da := DirAccess.open(lang_dir)
	if da == null and lang_dir != "res://lang":
		lang_dir = "res://lang"
		da = DirAccess.open(lang_dir)
	if da == null:
		return
	da.list_dir_begin()
	while true:
		var fname := da.get_next()
		if fname == "":
			break
		if da.current_is_dir() or fname.begins_with(".") or not fname.to_lower().ends_with(".cfg"):
			continue
		var fpath := lang_dir.path_join(fname)
		var cfg := ConfigFile.new()
		if cfg.load(fpath) != OK:
			continue
		var code := str(cfg.get_value("meta", "code", fname.get_basename())).strip_edges().to_lower()
		var native_name := str(cfg.get_value("meta", "native_name", code)).strip_edges()
		if code == "" or native_name == "":
			continue
		if code == "en" and cfg.has_section("strings"):
			for k in cfg.get_section_keys("strings"):
				_fallback_strings[k] = str(cfg.get_value("strings", k, ""))
		_languages.append({
			"code": code,
			"name": native_name,
			"path": fpath,
			"sort_key": _lang_sort_key(native_name)
		})
	da.list_dir_end()
	_languages.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a["sort_key"]).nocasecmp_to(str(b["sort_key"])) < 0
	)


func get_languages() -> Array[Dictionary]:
	return _languages


func get_current_language() -> String:
	return str(display.get("language", "en"))


func set_language(lang_code: String, save_to_cfg: bool = true) -> void:
	if _languages.is_empty():
		load_available_languages()
	var target := lang_code.strip_edges().to_lower()
	var picked: Dictionary = {}
	var en_fallback: Dictionary = {}
	for item in _languages:
		if str(item["code"]) == target:
			picked = item
			break
		if str(item["code"]) == "en":
			en_fallback = item
	if picked.is_empty():
		picked = en_fallback if not en_fallback.is_empty() else (_languages[0] if not _languages.is_empty() else {})
	_strings.clear()
	if not picked.is_empty():
		display["language"] = str(picked["code"])
		var cfg := ConfigFile.new()
		if cfg.load(str(picked["path"])) == OK and cfg.has_section("strings"):
			for k in cfg.get_section_keys("strings"):
				_strings[k] = str(cfg.get_value("strings", k, ""))
	else:
		display["language"] = "en"
	if save_to_cfg:
		save_config()
	language_changed.emit()


func t(key: String, default_text: String = "") -> String:
	if _strings.has(key):
		return str(_strings[key])
	if _fallback_strings.has(key):
		return str(_fallback_strings[key])
	return default_text if default_text != "" else key


func get_config_path() -> String:
	var res_cfg := ProjectSettings.globalize_path("res://config.cfg")
	if not OS.has_feature("standalone"):
		return res_cfg
	var exe_cfg := OS.get_executable_path().get_base_dir().path_join("config.cfg")
	if FileAccess.file_exists(exe_cfg):
		return exe_cfg
	return "user://config.cfg"


func get_save_path() -> String:
	return get_config_path().get_base_dir().path_join("savegame.cfg")


func has_save() -> bool:
	return FileAccess.file_exists(get_save_path())


func get_save_timestamp() -> String:
	var cfg := ConfigFile.new()
	if cfg.load(get_save_path()) != OK:
		return ""
	return str(cfg.get_value("meta", "saved_at", ""))


func save_game_state(data: Dictionary) -> int:
	var cfg := ConfigFile.new()
	cfg.set_value("meta", "version", 1)
	cfg.set_value("meta", "saved_at", Time.get_datetime_string_from_system(false, true))
	for sec_name in data.keys():
		var sec = data[sec_name]
		if sec is Dictionary:
			for k in (sec as Dictionary).keys():
				cfg.set_value(str(sec_name), str(k), sec[k])
	return cfg.save(get_save_path())


func load_game_state() -> Dictionary:
	var path := get_save_path()
	if not FileAccess.file_exists(path):
		return {}
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK:
		return {}
	var out: Dictionary = {}
	for sec_name in cfg.get_sections():
		var sec_dict: Dictionary = {}
		for k in cfg.get_section_keys(sec_name):
			sec_dict[k] = cfg.get_value(sec_name, k)
		out[sec_name] = sec_dict
	return out


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
	var path := get_config_path()
	var cfg := ConfigFile.new()
	if FileAccess.file_exists(path):
		cfg.load(path)
	for key in graphics.keys():
		cfg.set_value("graphics", key, graphics[key])
	for key in display.keys():
		cfg.set_value("display", key, display[key])
	for key in audio.keys():
		cfg.set_value("audio", key, audio[key])
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
			graphics["antialiasing"] = 3
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
			graphics["antialiasing"] = 3
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
			graphics["antialiasing"] = 4
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
		vp.use_debanding = true
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
		vp.positional_shadow_atlas_size = 2048 if shadow_tier >= 2 else 512
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
		env.sdfgi_bounce_feedback = 0.45
		env.sdfgi_cascades = 2 if preset_idx <= 4 else 3
		env.sdfgi_min_cell_size = 0.65 if preset_idx <= 4 else 0.45

		env.ssao_enabled = bool(graphics.get("ssao", true))
		env.ssao_radius = 1.10
		env.ssao_intensity = 1.0

		env.ssil_enabled = (preset_idx >= 3)
		env.ssil_radius = 2.6
		env.ssil_intensity = 0.42
		env.ssil_sharpness = 0.96
		env.ssil_normal_rejection = 1.0

		env.ssr_enabled = bool(graphics.get("ssr", true))
		env.ssr_max_steps = 16 if preset_idx <= 4 else 24
		env.ssr_fade_in = 0.14
		env.ssr_fade_out = 2.2
		env.ssr_depth_tolerance = 0.28

		env.volumetric_fog_enabled = bool(graphics.get("volumetric_fog", true))
		env.volumetric_fog_density = 0.0014
		env.volumetric_fog_anisotropy = 0.55
		env.volumetric_fog_length = 95.0 * float(graphics.get("view_distance", 1.0))
