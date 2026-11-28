class_name WorldBuilder
extends Node3D

const RaceTrackScript := preload("res://scripts/world/race_track.gd")
const FerrisWheelScript := preload("res://scripts/world/ferris_wheel.gd")

const WATER_LEVEL := 1.6
const TERRAIN_HALF := 256.0
const FERRIS_POS := Vector2(-56.0, 32.0)
const FERRIS_HILL_H := 14.5

var sky3d: Sky3D
var terrain: Terrain3D
var weather: WeatherController
var wildlife: WildlifeController
var casino_room: CasinoRoom
var race_track
var ferris_wheel
var _reflection_probe: ReflectionProbe

var _noise_hills: FastNoiseLite
var _noise_detail: FastNoiseLite
var _water_mat: ShaderMaterial
var _foliage_mats: Array[ShaderMaterial] = []

var _simple_grass_chunks: Array[MultiMeshInstance3D] = []
var _grass_clump_mms: Array[MultiMeshInstance3D] = []
var _fern_mms: Array[MultiMeshInstance3D] = []
var _flower_mms: Array[MultiMeshInstance3D] = []
var _bush_mms: Array[MultiMeshInstance3D] = []
var _rock_mms: Array[MultiMeshInstance3D] = []
var _reed_mm: MultiMeshInstance3D
var _tree_mms: Array[MultiMeshInstance3D] = []
var _weather_orb: MeshInstance3D
var _road_bulb_mat: StandardMaterial3D
var _track_spatial: Dictionary = {}
var _baked_track_heights: PackedFloat32Array = PackedFloat32Array()


func build_world(player: Node3D) -> void:
	_init_noises()
	race_track = RaceTrackScript.new()
	race_track.name = "MountainRaceTrack"
	race_track.prebuild_frames()
	_index_track_spatial()

	_build_sky3d()
	_build_terrain3d(player)

	race_track.terrain_height_fn = Callable(self, "sample_height")
	add_child(race_track)

	_build_lakes_and_rocks()
	_build_cobblestone_and_trails()
	_build_cosmo_forest()
	_build_simple_grass_and_plants(player)
	_build_outdoor_gadgets()

	ferris_wheel = FerrisWheelScript.new()
	ferris_wheel.name = "FerrisWheel"
	ferris_wheel.position = Vector3(FERRIS_POS.x, sample_height(FERRIS_POS.x, FERRIS_POS.y), FERRIS_POS.y)
	ferris_wheel.rotation.y = 0.58
	add_child(ferris_wheel)

	casino_room = CasinoRoom.new()
	casino_room.name = "CasinoRoom"
	casino_room.position = Vector3(0.0, 6.05, 0.0)
	add_child(casino_room)

	weather = WeatherController.new()
	weather.name = "WeatherController"
	add_child(weather)
	weather.setup(sky3d, _water_mat, _foliage_mats, player)
	weather.bind_world_lights(ferris_wheel, casino_room, _road_bulb_mat)

	wildlife = WildlifeController.new()
	wildlife.name = "WildlifeController"
	add_child(wildlife)
	wildlife.setup(Callable(self, "sample_height"), WATER_LEVEL, player)

	ConfigManager.graphics_changed.connect(_apply_graphics_settings)
	_apply_graphics_settings()


func set_world_focus(target: Node3D, snap_now: bool = false) -> void:
	if target == null:
		return
	if terrain:
		if terrain.clipmap_target != target:
			terrain.clipmap_target = target
		if terrain.collision_target != target:
			terrain.collision_target = target
		if snap_now and terrain.has_method(&"snap"):
			terrain.call(&"snap")
	if weather:
		weather.player_node = target
	var sg_singleton := get_node_or_null("/root/SimpleGrass")
	if sg_singleton:
		sg_singleton.call("set_player_position", target.global_position)


func _init_noises() -> void:
	_noise_hills = FastNoiseLite.new()
	_noise_hills.seed = 202604
	_noise_hills.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise_hills.frequency = 0.0075
	_noise_hills.fractal_octaves = 4

	_noise_detail = FastNoiseLite.new()
	_noise_detail.seed = 7731
	_noise_detail.noise_type = FastNoiseLite.TYPE_PERLIN
	_noise_detail.frequency = 0.026
	_noise_detail.fractal_octaves = 3


static func cobble_road_x(z: float) -> float:
	# Winding S-curve cobblestone road from Casino South entrance (0, 12.5) to Race Pit Stop (-16, 65.5)
	var u := clampf((z - 12.5) / (65.5 - 12.5), 0.0, 1.0)
	var su := u * u * (3.0 - 2.0 * u)
	return lerpf(0.0, -16.0, su) + sin(u * TAU * 1.15) * 9.5 * sin(u * PI)


static func mirror_trail_pos(u: float) -> Vector2:
	# Winding woodland trail from Cobble bend (-6, 22) -> (-26, 8) -> Mirror Lake Pier (-38, -16)
	var su := u * u * (3.0 - 2.0 * u)
	var p := Vector2(-6.0, 22.0).lerp(Vector2(-38.0, -16.0), su)
	p += Vector2(-6.5 * sin(u * PI * 1.5), 5.0 * sin(u * TAU))
	return p


static func east_trail_pos(u: float) -> Vector2:
	# Winding trail from Cobble bend (+4, 24) -> (24, 18) -> East Weather Altar (40, 22)
	var su := u * u * (3.0 - 2.0 * u)
	var p := Vector2(4.0, 24.0).lerp(Vector2(40.0, 22.0), su)
	p.y += sin(u * TAU) * 7.5
	return p


static func ferris_trail_pos(u: float) -> Vector2:
	# Winding path climbing West hill from Courtyard (-14, 22) straight to Ferris Wheel stairs (-52.9, 36.7)
	var su := u * u * (3.0 - 2.0 * u)
	var dest := FERRIS_POS + Vector2(sin(0.58), cos(0.58)) * 5.6
	var p := Vector2(-14.0, 22.0).lerp(dest, su)
	p.y += sin(u * PI) * 3.5
	return p


static func estimate_mountain_base(x: float, z: float) -> float:
	var dist := Vector2(x, z).length()
	var rim := clampf((dist - 120.0) / 110.0, 0.0, 1.0)
	return 1.5 + rim * rim * 26.0


func _index_track_spatial() -> void:
	_track_spatial.clear()
	if race_track == null or race_track.frames.is_empty():
		return
	for idx: int in range(race_track.frames.size()):
		var fp: Vector3 = race_track.frames[idx]["pos"]
		var cx := int(floor(fp.x / 16.0))
		var cz := int(floor(fp.z / 16.0))
		var key := Vector2i(cx, cz)
		if not _track_spatial.has(key):
			_track_spatial[key] = []
		(_track_spatial[key] as Array).append(fp)


func _is_near_road_or_track(x: float, z: float, margin: float = 4.5) -> bool:
	if absf(x) < 23.5 and absf(z) < 13.5:
		return true
	if z >= 11.0 and z <= 70.0 and absf(x - cobble_road_x(z)) < margin:
		return true
	if Vector2(x + 16.0, z - 68.0).length() < 16.0 + margin:
		return true
	if Vector2(x - FERRIS_POS.x, z - FERRIS_POS.y).length() < 15.5 + margin:
		return true
	if not _track_spatial.is_empty():
		var cx := int(floor(x / 16.0))
		var cz := int(floor(z / 16.0))
		var lim := 7.6 + margin
		var lim2 := lim * lim
		for ox: int in [-1, 0, 1]:
			for oz: int in [-1, 0, 1]:
				var key := Vector2i(cx + ox, cz + oz)
				if not _track_spatial.has(key):
					continue
				for fp: Vector3 in _track_spatial[key]:
					var dx := fp.x - x
					var dz := fp.z - z
					if dx * dx + dz * dz < lim2:
						return true
	return false


func sample_height(x: float, z: float) -> float:
	if _baked_track_heights.size() == 512 * 512:
		var fx := clampf(x + TERRAIN_HALF, 0.0, 510.999)
		var fz := clampf(z + TERRAIN_HALF, 0.0, 510.999)
		var ix := int(floor(fx))
		var iz := int(floor(fz))
		var tx := fx - float(ix)
		var tz := fz - float(iz)
		var r0 := iz * 512 + ix
		var h00 := _baked_track_heights[r0]
		var h10 := _baked_track_heights[r0 + 1]
		var h01 := _baked_track_heights[r0 + 512]
		var h11 := _baked_track_heights[r0 + 513]
		return lerpf(lerpf(h00, h10, tx), lerpf(h01, h11, tx), tz)
	return _sample_procedural_height(x, z)


func _sample_procedural_height(x: float, z: float) -> float:
	var h := 4.8
	h += _noise_hills.get_noise_2d(x, z) * 9.5
	h += _noise_detail.get_noise_2d(x, z) * 1.7

	var dist := Vector2(x, z).length()
	var rim := clampf((dist - 120.0) / 110.0, 0.0, 1.0)
	h += rim * rim * 30.0

	# West Mirror Lake around (-68, -28)
	var d_lake1 := Vector2(x + 68.0, z + 28.0).length()
	h = lerpf(h, -2.6, smoothstep_inv(18.0, 44.0, d_lake1) * 0.92)

	# East Forest Lake around (72, 34) with pine island at (78, 38)
	var d_lake2 := Vector2(x - 72.0, z - 34.0).length()
	h = lerpf(h, -2.8, smoothstep_inv(22.0, 50.0, d_lake2) * 0.92)
	var d_island := Vector2(x - 78.0, z - 38.0).length()
	h += smoothstep_inv(3.0, 11.0, d_island) * 5.2

	# South Scenic Pond around (18, 66)
	var d_lake3 := Vector2(x - 18.0, z - 66.0).length()
	h = lerpf(h, -1.6, smoothstep_inv(10.0, 26.0, d_lake3) * 0.88)

	# Center Casino Complex Plaza (X:-22..22, Z:-12..12), elevation 6.0m
	var d_plaza := maxf(maxf(absf(x) - 10.5, 0.0), absf(z))
	h = lerpf(h, 6.0, smoothstep_inv(12.5, 25.0, d_plaza))

	# Clean underground basin under the entire Casino complex (tucked cleanly underneath 23.2m x 12.2m travertine terrace!)
	if absf(x) < 22.8 and absf(z) < 11.4:
		var wx_in := 1.0
		if absf(x) > 20.2:
			wx_in = clampf((22.8 - absf(x)) / 2.6, 0.0, 1.0)
		var wz_in := 1.0
		if absf(z) > 9.2:
			wz_in = clampf((11.4 - absf(z)) / 2.2, 0.0, 1.0)
		var b_mask := wx_in * wz_in
		b_mask = b_mask * b_mask * (3.0 - 2.0 * b_mask)
		h = lerpf(h, 1.15, b_mask)

	# Smoothly graded Race Pit Stop Station pad around (-16.0, 66.5)
	var d_pit := Vector2(x + 16.0, z - 66.5).length()
	h = lerpf(h, 6.18, smoothstep_inv(11.0, 20.0, d_pit))

	# Winding S-curve Cobblestone Road from Casino (0, 12.5) to Pit Stop (-16, 65.5)
	if z >= 10.0 and z <= 68.0:
		var rc_x := cobble_road_x(z)
		var d_road := absf(x - rc_x)
		var u_r := clampf((z - 12.5) / (65.5 - 12.5), 0.0, 1.0)
		var road_target_h := lerpf(6.0, 6.18, u_r) - sin(u_r * PI) * 1.15
		h = lerpf(h, road_target_h, smoothstep_inv(2.2, 6.2, d_road) * 0.88)

	# Dramatic North Mountain Gorge chasm beneath the Track Canyon Jump (56, -146)
	var d_gorge := Vector2(x - 56.0, z + 146.0).length()
	h = lerpf(h, 3.2, smoothstep_inv(10.0, 22.0, d_gorge) * 0.90)

	# Scenic West Hill to the left of Casino for the climbable Ferris Wheel (-56, 32)
	var d_ferris := Vector2(x - FERRIS_POS.x, z - FERRIS_POS.y).length()
	h = lerpf(h, FERRIS_HILL_H, smoothstep_inv(8.0, 26.0, d_ferris))

	return h


static func smoothstep_inv(edge0: float, edge1: float, v: float) -> float:
	var t := clampf((v - edge0) / maxf(edge1 - edge0, 0.001), 0.0, 1.0)
	return 1.0 - (t * t * (3.0 - 2.0 * t))


func _build_sky3d() -> void:
	sky3d = Sky3D.new()
	sky3d.name = "Sky3D"
	add_child(sky3d)

	# Set golden late-afternoon summer angle for rich landscape shadows & volume
	if sky3d.tod:
		sky3d.tod.celestials_calculations = 1 # REALISTIC
		sky3d.tod.latitude = deg_to_rad(48.0)
		sky3d.tod.longitude = deg_to_rad(30.0)
		sky3d.tod.utc = 2.0
		sky3d.tod.month = 6
		sky3d.tod.day = 21

	sky3d.current_time = 15.8
	sky3d.minutes_per_day = 28.0
	sky3d.update_interval = 0.08
	sky3d.game_time_enabled = true
	sky3d.clouds_enabled = true
	sky3d.fog_enabled = true
	sky3d.sun_energy = 1.85
	sky3d.skydome_energy = 1.25
	sky3d.sky_contribution = 0.85
	sky3d.ambient_energy = 0.48

	if sky3d.sky:
		sky3d.sky.atm_darkness = 0.08
		sky3d.sky.atm_sun_intensity = 24.0
		sky3d.sky.atm_day_tint = Color(0.56, 0.82, 1.0)
		sky3d.sky.atm_thickness = 0.62
		sky3d.sky.fog_sea_level = WATER_LEVEL
		sky3d.sky.fog_start = 220.0
		sky3d.sky.fog_end = 1400.0
		sky3d.sky.fog_density = 0.00004
		sky3d.sky.fog_visible = false
		sky3d.sky.cumulus_coverage = 0.40
		sky3d.sky.cumulus_intensity = 1.45
		sky3d.sky.cirrus_coverage = 0.38
		sky3d.sky.cirrus_intensity = 2.2

	if sky3d.environment:
		ConfigManager.apply_to_environment(sky3d.environment)

	_reflection_probe = ReflectionProbe.new()
	_reflection_probe.name = "SkyReflectionProbe"
	_reflection_probe.size = Vector3(540.0, 140.0, 540.0)
	_reflection_probe.position = Vector3(0.0, 28.0, 0.0)
	_reflection_probe.update_mode = ReflectionProbe.UPDATE_ONCE
	_reflection_probe.box_projection = true
	_reflection_probe.ambient_mode = ReflectionProbe.AMBIENT_ENVIRONMENT
	_reflection_probe.intensity = 1.0
	_reflection_probe.enable_shadows = int(ConfigManager.graphics.get("shadows", 3)) >= 2
	add_child(_reflection_probe)


func _ensure_t3d_image_tex(tex: Texture2D) -> ImageTexture:
	if tex == null:
		return null
	var img := tex.get_image()
	img.decompress()
	if img.get_width() != 1024 or img.get_height() != 1024:
		img.resize(1024, 1024, Image.INTERPOLATE_BILINEAR)
	if img.get_format() != Image.FORMAT_RGBA8:
		img.convert(Image.FORMAT_RGBA8)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


func _pack_polyhaven_terrain_pair(folder: String) -> Array[Texture2D]:
	var diff_tex := load("res://assets/textures/pbr/%s/diff.jpg" % folder) as Texture2D
	var nor_tex := load("res://assets/textures/pbr/%s/nor.jpg" % folder) as Texture2D
	var rgh_tex := load("res://assets/textures/pbr/%s/rough.jpg" % folder) as Texture2D
	if diff_tex == null or nor_tex == null or rgh_tex == null:
		return []

	var diff_img := diff_tex.get_image()
	var nor_img := nor_tex.get_image()
	var rgh_img := rgh_tex.get_image()
	diff_img.decompress()
	nor_img.decompress()
	rgh_img.decompress()
	diff_img.resize(1024, 1024, Image.INTERPOLATE_BILINEAR)
	nor_img.resize(1024, 1024, Image.INTERPOLATE_BILINEAR)
	rgh_img.resize(1024, 1024, Image.INTERPOLATE_BILINEAR)
	diff_img.convert(Image.FORMAT_RGBA8)
	nor_img.convert(Image.FORMAT_RGBA8)

	for y in range(1024):
		for x in range(1024):
			var c := diff_img.get_pixel(x, y)
			var r := rgh_img.get_pixel(x, y).r
			diff_img.set_pixel(x, y, Color(c.r, c.g, c.b, 1.0 - r * 0.65))
			var n := nor_img.get_pixel(x, y)
			nor_img.set_pixel(x, y, Color(n.r, n.g, n.b, clampf(r, 0.25, 0.98)))

	diff_img.generate_mipmaps()
	nor_img.generate_mipmaps()
	return [ImageTexture.create_from_image(diff_img), ImageTexture.create_from_image(nor_img)]


func _build_terrain3d(player: Node3D) -> void:
	terrain = Terrain3D.new()
	terrain.name = "Terrain3D"
	terrain.free_editor_textures = false
	terrain.vertex_spacing = 1.0
	terrain.mesh_lods = 7
	terrain.mesh_size = 48
	terrain.collision_mode = 1
	terrain.collision_radius = 72
	terrain.collision_shape_size = 16
	if player:
		terrain.clipmap_target = player
		terrain.collision_target = player

	var mat := Terrain3DMaterial.new()
	mat.world_background = 0
	mat.auto_shader_enabled = true
	mat.dual_scaling_enabled = true
	mat.macro_variation_enabled = true
	mat.set_shader_param("auto_slope", 1.15)
	mat.set_shader_param("blend_sharpness", 0.88)
	terrain.material = mat

	var assets := Terrain3DAssets.new()
	var floor_pair := _pack_polyhaven_terrain_pair("forrest_ground_01")

	# Slot 0: Rich Forest Meadow (PolyHaven forrest_ground_01 or Terrain3D ground037)
	var ta_grass := Terrain3DTextureAsset.new()
	ta_grass.name = "MeadowGrass"
	ta_grass.id = 0
	if floor_pair.size() == 2:
		ta_grass.albedo_texture = floor_pair[0]
		ta_grass.normal_texture = floor_pair[1]
		ta_grass.albedo_color = Color(0.60, 0.72, 0.46)
	else:
		ta_grass.albedo_texture = _ensure_t3d_image_tex(load("res://assets/textures/terrain/ground037_alb_ht.png") as Texture2D)
		ta_grass.normal_texture = _ensure_t3d_image_tex(load("res://assets/textures/terrain/ground037_nrm_rgh.png") as Texture2D)
		ta_grass.albedo_color = Color(0.55, 0.68, 0.42)
	ta_grass.uv_scale = 0.16
	ta_grass.normal_depth = 1.15
	ta_grass.ao_strength = 0.65
	ta_grass.detiling_rotation = 0.28
	ta_grass.detiling_shift = 0.28
	assets.set_texture_asset(0, ta_grass)

	# Slot 1: Granite Cliff Rock (used only on steep slopes)
	var ta_rock := Terrain3DTextureAsset.new()
	ta_rock.name = "CliffRock"
	ta_rock.id = 1
	ta_rock.albedo_texture = _ensure_t3d_image_tex(load("res://assets/textures/terrain/rock023_alb_ht.png") as Texture2D)
	ta_rock.normal_texture = _ensure_t3d_image_tex(load("res://assets/textures/terrain/rock023_nrm_rgh.png") as Texture2D)
	ta_rock.albedo_color = Color(0.50, 0.48, 0.45)
	ta_rock.uv_scale = 0.10
	ta_rock.normal_depth = 1.25
	ta_rock.ao_strength = 0.70
	ta_rock.detiling_rotation = 0.22
	ta_rock.detiling_shift = 0.22
	assets.set_texture_asset(1, ta_rock)

	# Slot 2: PolyHaven CC0 Coast Sand for Lake Shores
	var sand_pair := _pack_polyhaven_terrain_pair("coast_sand_01")
	if sand_pair.size() == 2:
		var ta_sand := Terrain3DTextureAsset.new()
		ta_sand.name = "LakeSand"
		ta_sand.id = 2
		ta_sand.albedo_texture = sand_pair[0]
		ta_sand.normal_texture = sand_pair[1]
		ta_sand.albedo_color = Color(0.86, 0.80, 0.68)
		ta_sand.uv_scale = 0.16
		ta_sand.normal_depth = 1.0
		ta_sand.ao_strength = 0.55
		assets.set_texture_asset(2, ta_sand)

	# Slot 3: Mossy Pine Floor Accent
	var ta_moss := Terrain3DTextureAsset.new()
	ta_moss.name = "MossyFloor"
	ta_moss.id = 3
	ta_moss.albedo_texture = _ensure_t3d_image_tex(load("res://assets/textures/terrain/ground037_alb_ht.png") as Texture2D)
	ta_moss.normal_texture = _ensure_t3d_image_tex(load("res://assets/textures/terrain/ground037_nrm_rgh.png") as Texture2D)
	ta_moss.albedo_color = Color(0.52, 0.68, 0.38)
	ta_moss.uv_scale = 0.14
	ta_moss.normal_depth = 1.15
	ta_moss.ao_strength = 0.65
	assets.set_texture_asset(3, ta_moss)

	terrain.assets = assets
	add_child(terrain)

	var res := 512
	var h_img := Image.create(res, res, false, Image.FORMAT_RF)
	var c_img := Image.create(res, res, false, Image.FORMAT_RGBA8)
	var h_arr := PackedFloat32Array()
	h_arr.resize(res * res)

	for pz in range(res):
		var wz := -TERRAIN_HALF + float(pz)
		for px in range(res):
			var wx := -TERRAIN_HALF + float(px)
			var h := _sample_procedural_height(wx, wz)
			h_arr[pz * res + px] = h
			h_img.set_pixel(px, pz, Color(h, 0.0, 0.0, 1.0))

			var col := Color(0.95, 1.0, 0.90, 0.72)
			if maxf(absf(wx), absf(wz)) < 16.5:
				col = Color(0.75, 0.73, 0.68, 0.50)
			elif h < WATER_LEVEL + 0.85:
				col = Color(1.08, 0.98, 0.82, 0.85)
			elif h > 16.0:
				col = Color(0.82, 0.82, 0.80, 0.82)
			c_img.set_pixel(px, pz, col)

	_grade_terrain_under_track(h_arr, h_img, c_img, res)
	_baked_track_heights = h_arr

	var imgs: Array[Image] = [h_img, null, c_img]
	terrain.data.import_images(imgs, Vector3(-TERRAIN_HALF, 0.0, -TERRAIN_HALF), 0.0, 1.0)
	_apply_terrain_track_cleanup(res, sand_pair, floor_pair)


func _grade_terrain_under_track(h_arr: PackedFloat32Array, h_img: Image, c_img: Image, res: int) -> void:
	if race_track == null or race_track.frames.is_empty():
		return
	var n: int = race_track.frames.size()
	for idx: int in range(0, n, 2):
		var f: Dictionary = race_track.frames[idx]
		if bool(f.get("is_loop", false)):
			var lu := float(f.get("loop_u", 0.0))
			if lu > 0.12 and lu < 0.88:
				continue
		var fp: Vector3 = f["pos"]
		var r_vec: Vector3 = f["right"]
		var w_half := float(f.get("width", 10.6)) * 0.5
		var edge_drop := absf(r_vec.y) * w_half
		var clear_y := fp.y - edge_drop - 1.15
		var min_px := clampi(int(floor(fp.x + TERRAIN_HALF - 14.0)), 1, res - 2)
		var max_px := clampi(int(ceil(fp.x + TERRAIN_HALF + 14.0)), 1, res - 2)
		var min_pz := clampi(int(floor(fp.z + TERRAIN_HALF - 14.0)), 1, res - 2)
		var max_pz := clampi(int(ceil(fp.z + TERRAIN_HALF + 14.0)), 1, res - 2)
		for pz: int in range(min_pz, max_pz + 1):
			var wz := -TERRAIN_HALF + float(pz)
			var dz := wz - fp.z
			for px: int in range(min_px, max_px + 1):
				var wx := -TERRAIN_HALF + float(px)
				var dx := wx - fp.x
				var d := sqrt(dx * dx + dz * dz)
				if d > 14.0:
					continue
				var cell_i := pz * res + px
				var cur_h := h_arr[cell_i]
				if cur_h <= clear_y:
					continue
				var blend := clampf((d - 6.6) / 7.4, 0.0, 1.0)
				var sb := blend * blend * (3.0 - 2.0 * blend)
				var cap_h := lerpf(clear_y, cur_h, sb)
				if cap_h < cur_h:
					var safe_h := maxf(cap_h, WATER_LEVEL + 0.15) if cur_h > WATER_LEVEL + 0.15 else cap_h
					h_arr[cell_i] = safe_h
					h_img.set_pixel(px, pz, Color(safe_h, 0.0, 0.0, 1.0))
					if d < 9.5:
						c_img.set_pixel(px, pz, Color(0.68, 0.66, 0.62, 0.85))


func _apply_terrain_track_cleanup(res: int, sand_pair: Array[Texture2D], floor_pair: Array[Texture2D]) -> void:
	# Paint sandy shores and pine needle patches cleanly outside Casino footprint
	if sand_pair.size() == 2 or floor_pair.size() == 2:
		for pz in range(8, res - 8, 2):
			var wz := -TERRAIN_HALF + float(pz)
			for px in range(8, res - 8, 2):
				var wx := -TERRAIN_HALF + float(px)
				if absf(wx) < 23.0 and absf(wz) < 13.0:
					continue
				var h := sample_height(wx, wz)
				if h < WATER_LEVEL + 0.75 and sand_pair.size() == 2:
					var pos := Vector3(wx, 0.0, wz)
					terrain.data.set_control_auto(pos, false)
					terrain.data.set_control_base_id(pos, 2)
					terrain.data.set_control_overlay_id(pos, 0)
					var blend := clampf((h - (WATER_LEVEL - 0.3)) / 1.05, 0.0, 1.0)
					terrain.data.set_control_blend(pos, blend * 0.85)
				elif h > WATER_LEVEL + 1.4 and (absf(wx) > 25.0 or absf(wz) > 16.0) and floor_pair.size() == 2:
					var on_trail := (wz >= 12.0 and wz <= 66.0 and absf(wx - cobble_road_x(wz)) < 3.0)
					if not on_trail:
						for t_i: int in range(28):
							var u := float(t_i) / 27.0
							if Vector2(wx, wz).distance_to(mirror_trail_pos(u)) < 2.2 or Vector2(wx, wz).distance_to(east_trail_pos(u)) < 2.2:
								on_trail = true; break
					if on_trail and sand_pair.size() == 2:
						var pos_t := Vector3(wx, 0.0, wz)
						terrain.data.set_control_auto(pos_t, false)
						terrain.data.set_control_base_id(pos_t, 2)
						terrain.data.set_control_overlay_id(pos_t, 0)
						terrain.data.set_control_blend(pos_t, 0.25)
					else:
						var n_val := _noise_detail.get_noise_2d(wx * 0.4, wz * 0.4)
						if n_val > 0.14:
							var pos2 := Vector3(wx, 0.0, wz)
							terrain.data.set_control_auto(pos2, false)
							terrain.data.set_control_base_id(pos2, 0)
							terrain.data.set_control_overlay_id(pos2, 3)
							terrain.data.set_control_blend(pos2, clampf((n_val - 0.14) * 3.2, 0.0, 0.88))
		terrain.data.update_maps(Terrain3DRegion.TYPE_MAX, true, false)


func _extract_merged_mesh(scene_path: String) -> ArrayMesh:
	var ps := load(scene_path) as PackedScene
	if ps == null:
		return null
	var root := ps.instantiate()
	var mat_groups: Dictionary = {}
	_collect_mesh_surfaces(root, Transform3D.IDENTITY, mat_groups)
	root.free()

	if mat_groups.is_empty():
		return null
	var out_mesh := ArrayMesh.new()
	for mat_key in mat_groups.keys():
		var group: Dictionary = mat_groups[mat_key]
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var chunks: Array = group["chunks"]
		for ch in chunks:
			var mdt := MeshDataTool.new()
			var src_mesh: Mesh = ch["mesh"]
			var surf_idx: int = int(ch["surf"])
			var tf: Transform3D = ch["tf"]
			if mdt.create_from_surface(src_mesh, surf_idx) == OK:
				var st_sub := SurfaceTool.new()
				st_sub.create_from(src_mesh, surf_idx)
				var arr := st_sub.commit_to_arrays()
				var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
				var norms: PackedVector3Array = arr[Mesh.ARRAY_NORMAL] if arr[Mesh.ARRAY_NORMAL] != null else PackedVector3Array()
				var uvs: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV] if arr[Mesh.ARRAY_TEX_UV] != null else PackedVector2Array()
				var indices: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
				var nrm_basis := tf.basis.inverse().transposed()
				if indices.size() > 0:
					for idx in indices:
						if uvs.size() > idx: st.set_uv(uvs[idx])
						if norms.size() > idx: st.set_normal((nrm_basis * norms[idx]).normalized())
						st.add_vertex(tf * verts[idx])
				else:
					for idx in range(verts.size()):
						if uvs.size() > idx: st.set_uv(uvs[idx])
						if norms.size() > idx: st.set_normal((nrm_basis * norms[idx]).normalized())
						st.add_vertex(tf * verts[idx])
		var built := st.commit()
		if built and built.get_surface_count() > 0:
			out_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, built.surface_get_arrays(0))
			if group["mat"] != null:
				out_mesh.surface_set_material(out_mesh.get_surface_count() - 1, group["mat"])
	return out_mesh


func _collect_mesh_surfaces(node: Node, parent_tf: Transform3D, groups: Dictionary) -> void:
	var tf := parent_tf
	if node is Node3D:
		tf = parent_tf * (node as Node3D).transform
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		if mi.mesh != null:
			for s in range(mi.mesh.get_surface_count()):
				var mat := mi.get_active_material(s)
				var key := mat.get_instance_id() if mat != null else 0
				if not groups.has(key):
					groups[key] = {"mat": mat, "chunks": []}
				(groups[key]["chunks"] as Array).append({"mesh": mi.mesh, "surf": s, "tf": tf})
	for c in node.get_children():
		_collect_mesh_surfaces(c, tf, groups)


func _extract_named_mesh(scene_path: String, mesh_name: String) -> ArrayMesh:
	var ps := load(scene_path) as PackedScene
	if ps == null:
		return null
	var root := ps.instantiate()
	var found: MeshInstance3D = null
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is MeshInstance3D and n.name == mesh_name:
			found = n as MeshInstance3D
			break
		for c in n.get_children():
			stack.append(c)

	var out_mesh: ArrayMesh = null
	if found and found.mesh:
		out_mesh = ArrayMesh.new()
		var aabb: AABB = found.mesh.get_aabb()
		var center_xz := Vector3(aabb.position.x + aabb.size.x * 0.5, aabb.position.y, aabb.position.z + aabb.size.z * 0.5)
		for s in range(found.mesh.get_surface_count()):
			var arr := found.mesh.surface_get_arrays(s)
			var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			for vi in range(verts.size()):
				verts[vi] = verts[vi] - center_xz
			arr[Mesh.ARRAY_VERTEX] = verts
			out_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
			var mat := found.get_active_material(s)
			if mat:
				out_mesh.surface_set_material(out_mesh.get_surface_count() - 1, mat)
	root.free()
	return out_mesh


func _decimate_mesh_grid(src: ArrayMesh, cell_size: float) -> ArrayMesh:
	if src == null:
		return null
	var out_mesh := ArrayMesh.new()
	var inv_cell := 1.0 / maxf(cell_size, 0.02)
	for s in range(src.get_surface_count()):
		var st_src := SurfaceTool.new()
		st_src.create_from(src, s)
		var arr := st_src.commit_to_arrays()
		var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var uvs: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV] if arr[Mesh.ARRAY_TEX_UV] != null else PackedVector2Array()
		var indices: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()

		var cell_map: Dictionary = {}
		var new_verts := PackedVector3Array()
		var new_uvs := PackedVector2Array()
		var old_to_new := PackedInt32Array()
		old_to_new.resize(verts.size())

		for i in range(verts.size()):
			var v: Vector3 = verts[i]
			var key := Vector3i(floori(v.x * inv_cell), floori(v.y * inv_cell), floori(v.z * inv_cell))
			if cell_map.has(key):
				old_to_new[i] = int(cell_map[key])
			else:
				var idx_new := new_verts.size()
				cell_map[key] = idx_new
				new_verts.append(v)
				if uvs.size() > i:
					new_uvs.append(uvs[i])
				else:
					new_uvs.append(Vector2.ZERO)
				old_to_new[i] = idx_new

		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var tri_count := (indices.size() / 3) if indices.size() > 0 else (verts.size() / 3)
		for t in range(tri_count):
			var i0 := indices[t * 3] if indices.size() > 0 else t * 3
			var i1 := indices[t * 3 + 1] if indices.size() > 0 else t * 3 + 1
			var i2 := indices[t * 3 + 2] if indices.size() > 0 else t * 3 + 2
			var n0 := old_to_new[i0]
			var n1 := old_to_new[i1]
			var n2 := old_to_new[i2]
			if n0 == n1 or n1 == n2 or n0 == n2:
				continue
			st.set_uv(new_uvs[n0]); st.add_vertex(new_verts[n0])
			st.set_uv(new_uvs[n1]); st.add_vertex(new_verts[n1])
			st.set_uv(new_uvs[n2]); st.add_vertex(new_verts[n2])
		st.generate_normals()
		st.index()
		var built := st.commit()
		if built and built.get_surface_count() > 0:
			out_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, built.surface_get_arrays(0))
			var mat := src.surface_get_material(s)
			if mat:
				out_mesh.surface_set_material(out_mesh.get_surface_count() - 1, mat)
	return out_mesh


func _build_lakes_and_rocks() -> void:
	_water_mat = ShaderMaterial.new()
	_water_mat.shader = load("res://shaders/water_lake.gdshader")
	_water_mat.set_shader_parameter("sky_tint", Color(0.45, 0.72, 0.96, 1.0))

	var water_mesh := PlaneMesh.new()
	water_mesh.size = Vector2(280.0, 280.0)
	water_mesh.subdivide_width = 220
	water_mesh.subdivide_depth = 220

	var water := MeshInstance3D.new()
	water.name = "LakesWater"
	water.mesh = water_mesh
	water.material_override = _water_mat
	water.position = Vector3(0.0, WATER_LEVEL, 0.0)
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(water)

	# Decimated Photogrammetry Boulders & Low-poly Terrain3D Rocks along lakes & hillsides
	var rng := RandomNumberGenerator.new()
	rng.seed = 8801
	var boulder_raw := _extract_merged_mesh("res://assets/models/boulder_01/boulder_01.gltf")
	var boulder_mesh := _decimate_mesh_grid(boulder_raw, 0.14) if boulder_raw else null
	var rock_a_mesh := _extract_merged_mesh("res://assets/models/RockA.glb")
	var rock_b_mesh := _extract_merged_mesh("res://assets/models/RockB.glb")
	var rock_c_mesh := _extract_merged_mesh("res://assets/models/RockC.glb")

	var b_tfs: Array[Transform3D] = []
	var ra_tfs: Array[Transform3D] = []
	var rb_tfs: Array[Transform3D] = []

	for i in range(340):
		var wx := rng.randf_range(-145.0, 145.0)
		var wz := rng.randf_range(-145.0, 145.0)
		if (absf(wx) < 25.0 and absf(wz) < 15.0) or _is_near_road_or_track(wx, wz, 5.0):
			continue
		var h := sample_height(wx, wz)
		if h > WATER_LEVEL - 2.6 and h < WATER_LEVEL + 1.4:
			var r_pick := i % 4
			if r_pick == 0 and rock_a_mesh:
				var sc := rng.randf_range(0.18, 0.44)
				ra_tfs.append(Transform3D(Basis.from_euler(Vector3(rng.randf() * 0.4, rng.randf() * TAU, rng.randf() * 0.4)).scaled(Vector3(sc, sc, sc)), Vector3(wx, h - 0.25, wz)))
			elif r_pick == 1 and rock_b_mesh:
				var sc := rng.randf_range(0.20, 0.46)
				rb_tfs.append(Transform3D(Basis.from_euler(Vector3(rng.randf() * 0.4, rng.randf() * TAU, rng.randf() * 0.4)).scaled(Vector3(sc, sc, sc)), Vector3(wx, h - 0.25, wz)))
			elif r_pick == 2 and rock_c_mesh:
				var sc := rng.randf_range(0.22, 0.50)
				rb_tfs.append(Transform3D(Basis.from_euler(Vector3(rng.randf() * 0.4, rng.randf() * TAU, rng.randf() * 0.4)).scaled(Vector3(sc, sc, sc)), Vector3(wx, h - 0.22, wz)))
			elif boulder_mesh:
				var sc := rng.randf_range(0.85, 2.2)
				b_tfs.append(Transform3D(Basis.from_euler(Vector3(rng.randf() * 0.2, rng.randf() * TAU, rng.randf() * 0.2)).scaled(Vector3(sc, sc * 0.85, sc)), Vector3(wx, h - 0.12, wz)))

	if boulder_mesh and b_tfs.size() > 0:
		_rock_mms.append_array(_populate_chunked_mm("Boulder", boulder_mesh, null, b_tfs, true, 120.0, 135.0, 3))
	if rock_a_mesh and ra_tfs.size() > 0:
		_rock_mms.append_array(_populate_chunked_mm("RockA", rock_a_mesh, null, ra_tfs, true, 120.0, 135.0, 3))
	if rock_b_mesh and rb_tfs.size() > 0:
		_rock_mms.append_array(_populate_chunked_mm("RockB", rock_b_mesh, null, rb_tfs, true, 120.0, 135.0, 3))

	# Fallen mossy dead tree trunks (decimated ~50x faster!)
	var trunk_raw := _extract_merged_mesh("res://assets/models/dead_tree_trunk/dead_tree_trunk.gltf")
	var trunk_mesh := _decimate_mesh_grid(trunk_raw, 0.16) if trunk_raw else null
	if trunk_mesh:
		var log_tfs: Array[Transform3D] = []
		for _i in range(36):
			var wx := rng.randf_range(-125.0, 125.0)
			var wz := rng.randf_range(-125.0, 125.0)
			if maxf(absf(wx), absf(wz)) < 22.0: continue
			var h := sample_height(wx, wz)
			if h < WATER_LEVEL + 0.8: continue
			var sc := rng.randf_range(0.95, 1.45)
			log_tfs.append(Transform3D(Basis.from_euler(Vector3(0, rng.randf() * TAU, rng.randf_range(-0.08, 0.08))).scaled(Vector3(sc, sc, sc)), Vector3(wx, h + 0.05, wz)))
		_rock_mms.append_array(_populate_chunked_mm("DeadLog", trunk_mesh, null, log_tfs, true, 110.0, 125.0, 3))


func _build_spruce_preset(seed_offset: int, height_val: float) -> CosmoTreePreset:
	var preset := CosmoTreePreset.new()
	var tp := CosmoTrunkParams.new()
	tp.height = height_val
	tp.radius_bottom = 0.28 + float(seed_offset) * 0.04
	tp.radius_top = 0.03
	tp.lean = 0.08
	tp.flare = 0.65
	tp.flare_height = 0.28
	tp.sink_depth = 0.20
	preset.trunk_params = tp

	var lvl := CosmoBranchLevel.new()
	lvl.count = 56
	lvl.terminal = true
	lvl.start = 0.12
	lvl.end = 0.97
	lvl.angle = 68.0
	lvl.length = 0.42
	lvl.radius = 0.46
	lvl.gnarl = 0.16
	lvl.up_force = -0.32
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 1.0))
	curve.add_point(Vector2(0.55, 0.64))
	curve.add_point(Vector2(1.0, 0.16))
	lvl.length_curve = curve
	preset.branch_levels = [lvl]

	var fp := CosmoFoliageParams.new()
	fp.type = 2 # Card leaves
	fp.leaf_count = 18
	fp.leaf_tip = true
	fp.leaf_size = 1.52
	fp.leaf_size_variance = 0.28
	fp.leaf_start = 0.06
	fp.leaf_angle = 52.0
	preset.foliage_params = fp

	preset.trunk_material = load("res://addons/cosmo_tree_gen/materials/bark.tres") as Material
	var lmat := (load("res://addons/cosmo_tree_gen/materials/leaves_03.tres") as ShaderMaterial).duplicate() as ShaderMaterial
	var pine_col := Color(0.16, 0.30, 0.14) if seed_offset % 2 == 0 else Color(0.20, 0.34, 0.17)
	lmat.set_shader_parameter("albedo", pine_col)
	preset.foliage_material = lmat
	return preset


func _make_cosmo_tree_mesh(preset: CosmoTreePreset, seed_val: int) -> ArrayMesh:
	var tg := CosmoTreeGen.new()
	tg.auto_generate = false
	tg.noise_seed = seed_val
	tg.apply_preset(preset)
	tg.generate()
	var mesh_out: ArrayMesh = null
	var child := tg.get_node_or_null("CosmoTree") as MeshInstance3D
	if child and child.mesh:
		mesh_out = child.mesh.duplicate() as ArrayMesh
	tg.free()
	return mesh_out


func _build_birch_or_autumn_preset(is_birch: bool) -> CosmoTreePreset:
	var preset := _build_spruce_preset(1 if is_birch else 0, 10.6 if is_birch else 9.8)
	var tp := preset.trunk_params as CosmoTrunkParams
	tp.height = 11.4 if is_birch else 9.6
	tp.radius_bottom = 0.21 if is_birch else 0.30
	tp.lean = 0.16
	var lvl: CosmoBranchLevel = preset.branch_levels[0]
	lvl.count = 34
	lvl.start = 0.32
	lvl.angle = 52.0
	lvl.up_force = 0.24
	if is_birch:
		var bark_m := StandardMaterial3D.new()
		bark_m.albedo_color = Color(0.58, 0.56, 0.52)
		bark_m.roughness = 0.90
		preset.trunk_material = bark_m
	var lmat := (load("res://addons/cosmo_tree_gen/materials/leaves_03.tres") as ShaderMaterial).duplicate() as ShaderMaterial
	lmat.set_shader_parameter("albedo", Color(0.46, 0.64, 0.24) if is_birch else Color(0.76, 0.42, 0.14))
	preset.foliage_material = lmat
	return preset


func _build_cobblestone_and_trails() -> void:
	# Winding S-curve 3D Cobblestone Road ("бруківка з вигинами") + Basalt Curbs + Lanterns from Casino (0,12.5) to Pit Stop (-16,65.5)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var cobble_mat := StandardMaterial3D.new()
	cobble_mat.vertex_color_use_as_albedo = true
	cobble_mat.roughness = 0.78
	var tex_stone := load("res://assets/textures/pbr/marble_01/diff.jpg") as Texture2D
	if tex_stone:
		cobble_mat.albedo_texture = tex_stone
	var tex_norm := load("res://assets/textures/pbr/marble_01/nor.jpg") as Texture2D
	if tex_norm:
		cobble_mat.normal_enabled = true
		cobble_mat.normal_texture = tex_norm
		cobble_mat.normal_scale = 0.8
	var tex_rough := load("res://assets/textures/pbr/marble_01/rough.jpg") as Texture2D
	if tex_rough:
		cobble_mat.roughness_texture = tex_rough
		cobble_mat.roughness = 0.95

	var steps := 92
	var road_half_w := 2.3
	var lantern_mat := StandardMaterial3D.new(); lantern_mat.albedo_color = Color(0.18, 0.17, 0.16); lantern_mat.metallic = 0.65
	_road_bulb_mat = StandardMaterial3D.new(); _road_bulb_mat.albedo_color = Color(1.0, 0.86, 0.50); _road_bulb_mat.emission_enabled = true; _road_bulb_mat.emission = Color(1.0, 0.78, 0.35); _road_bulb_mat.emission_energy_multiplier = 0.0
	var glow_bulb := _road_bulb_mat
	var rng := RandomNumberGenerator.new(); rng.seed = 4421

	for i: int in range(steps):
		var z0 := lerpf(12.2, 65.8, float(i) / float(steps))
		var z1 := lerpf(12.2, 65.8, float(i + 1) / float(steps))
		var c0 := Vector3(cobble_road_x(z0), sample_height(cobble_road_x(z0), z0) + 0.22, z0)
		var c1 := Vector3(cobble_road_x(z1), sample_height(cobble_road_x(z1), z1) + 0.22, z1)
		var fwd := Vector3(c1.x - c0.x, 0.0, c1.z - c0.z).normalized()
		var rt := Vector3(fwd.z, 0.0, -fwd.x).normalized() * road_half_w
		var uv0 := Vector2(0.0, float(i) * 0.55)
		var uv1 := Vector2(1.0, float(i) * 0.55)
		var uv2 := Vector2(1.0, float(i + 1) * 0.55)
		var uv3 := Vector2(0.0, float(i + 1) * 0.55)

		var shade := Color(0.56, 0.54, 0.50) if (i % 2 == 0) else Color(0.48, 0.46, 0.44)
		var curb_col := Color(0.32, 0.31, 0.30)
		var r_in := rt * 0.86
		# Road bed quad
		for tri: Array in [[c0 - r_in, uv0, c0 + r_in, uv1, c1 + r_in, uv2], [c0 - r_in, uv0, c1 + r_in, uv2, c1 - r_in, uv3]]:
			st.set_color(shade); st.set_normal(Vector3.UP)
			st.set_uv(tri[1]); st.add_vertex(tri[0])
			st.set_uv(tri[3]); st.add_vertex(tri[2])
			st.set_uv(tri[5]); st.add_vertex(tri[4])
		# Curb strips + deeper solid stone skirt into ground
		for side: float in [-1.0, 1.0]:
			var a := c0 + r_in * side; var b := c0 + rt * side - Vector3(0, 0.42, 0)
			var c := c1 + rt * side - Vector3(0, 0.42, 0); var d := c1 + r_in * side
			st.set_color(curb_col); st.set_normal(Vector3.UP)
			st.set_uv(uv0); st.add_vertex(a); st.set_uv(uv1); st.add_vertex(b); st.set_uv(uv2); st.add_vertex(c)
			st.set_uv(uv0); st.add_vertex(a); st.set_uv(uv2); st.add_vertex(c); st.set_uv(uv3); st.add_vertex(d)

		if i % 8 == 3:
			var side_s := 1.0 if ((i / 8) % 2 == 0) else -1.0
			var lp := c0 + rt * side_s * 1.18
			var post := MeshInstance3D.new(); var pm := CylinderMesh.new(); pm.top_radius = 0.06; pm.bottom_radius = 0.09; pm.height = 2.4
			post.mesh = pm; post.material_override = lantern_mat; post.position = lp + Vector3(0, 1.2, 0)
			add_child(post)
			var bulb := MeshInstance3D.new(); var bm := SphereMesh.new(); bm.radius = 0.15
			bulb.mesh = bm; bulb.material_override = glow_bulb; bulb.position = lp + Vector3(0, 2.48, 0)
			add_child(bulb)

	var rmi := MeshInstance3D.new()
	rmi.name = "CobblestoneRoadMesh"
	rmi.mesh = st.commit()
	rmi.material_override = cobble_mat
	add_child(rmi)

	# Stepping stones along winding forest trails ("тропи")
	var step_mat := StandardMaterial3D.new(); step_mat.albedo_color = Color(0.46, 0.44, 0.40); step_mat.roughness = 0.92
	var step_mesh := CylinderMesh.new(); step_mesh.top_radius = 0.65; step_mesh.bottom_radius = 0.72; step_mesh.height = 0.12; step_mesh.radial_segments = 7
	var stone_tfs: Array[Transform3D] = []
	for ti: int in range(26):
		var u := float(ti) / 25.0
		for p2: Vector2 in [mirror_trail_pos(u), east_trail_pos(u), ferris_trail_pos(u)]:
			var jx := p2.x + rng.randf_range(-0.35, 0.35)
			var jz := p2.y + rng.randf_range(-0.35, 0.35)
			var hy := sample_height(jx, jz)
			if hy > WATER_LEVEL + 0.15:
				var sc := rng.randf_range(0.75, 1.25)
				stone_tfs.append(Transform3D(Basis.from_euler(Vector3(0, rng.randf() * TAU, 0)).scaled(Vector3(sc, 1.0, sc * 0.8)), Vector3(jx, hy - 0.01, jz)))
	if stone_tfs.size() > 0:
		_populate_mm(MultiMeshInstance3D.new(), step_mesh, step_mat, stone_tfs, false)


func _build_outdoor_gadgets() -> void:
	# 1. Mirror Lake Wooden Dock Pier + Interactive Brass Duck Horn at (-39.0, 1.92, -16.0)
	var wood_mat := StandardMaterial3D.new(); wood_mat.albedo_color = Color(0.42, 0.28, 0.16); wood_mat.roughness = 0.85
	var wd := load("res://assets/textures/pbr/wood_planks_dirt/diff.jpg") as Texture2D
	if wd: wood_mat.albedo_texture = wd
	var pier := StaticBody3D.new(); pier.name = "MirrorLakePier"; pier.position = Vector3(-42.0, WATER_LEVEL + 0.35, -18.0); pier.rotation.y = 0.45
	add_child(pier)
	var pmesh := BoxMesh.new(); pmesh.size = Vector3(2.8, 0.22, 7.6)
	var pmi := MeshInstance3D.new(); pmi.mesh = pmesh; pmi.material_override = wood_mat; pier.add_child(pmi)
	var pcs := CollisionShape3D.new(); var pb := BoxShape3D.new(); pb.size = Vector3(2.8, 0.22, 7.6); pcs.shape = pb; pier.add_child(pcs)
	for px: float in [-1.15, 1.15]:
		for pz: float in [-2.8, 0.2, 3.0]:
			var post := MeshInstance3D.new(); var pm := CylinderMesh.new(); pm.top_radius = 0.12; pm.bottom_radius = 0.14; pm.height = 1.6
			post.mesh = pm; post.material_override = wood_mat; post.position = Vector3(px, -0.35, pz); pier.add_child(post)

	var brass := StandardMaterial3D.new(); brass.albedo_color = Color(0.88, 0.70, 0.22); brass.metallic = 0.85; brass.roughness = 0.25
	var horn := MeshInstance3D.new(); var hm := CylinderMesh.new(); hm.top_radius = 0.22; hm.bottom_radius = 0.05; hm.height = 0.55
	horn.mesh = hm; horn.material_override = brass; horn.position = Vector3(1.15, 0.68, -2.8); horn.rotation_degrees = Vector3(72.0, 0.0, 0.0)
	pier.add_child(horn)
	var horn_body := StaticBody3D.new(); horn_body.collision_layer = 2; horn_body.collision_mask = 0; horn_body.position = Vector3(1.15, 0.72, -2.8)
	var hcs := CollisionShape3D.new(); var hbox := BoxShape3D.new(); hbox.size = Vector3(1.4, 1.6, 1.4); hcs.shape = hbox; horn_body.add_child(hcs)
	horn_body.set_meta("interact_id", "duck_horn"); horn_body.set_meta("interact_title", "Подути в качину манку (покликати птахів)")
	pier.add_child(horn_body)

	# 2. Giant Bouncy Forest Mushroom Trampoline along Mirror Lake Trail (-30.0, h, 8.0)
	var sy := sample_height(-30.0, 8.0)
	var shroom := Node3D.new(); shroom.position = Vector3(-30.0, sy, 8.0)
	add_child(shroom)
	var stem_m := CylinderMesh.new(); stem_m.top_radius = 0.42; stem_m.bottom_radius = 0.56; stem_m.height = 0.9
	var smi := MeshInstance3D.new(); smi.mesh = stem_m; smi.material_override = StandardMaterial3D.new()
	(smi.material_override as StandardMaterial3D).albedo_color = Color(0.92, 0.88, 0.78); smi.position = Vector3(0, 0.45, 0); shroom.add_child(smi)
	var cap_m := SphereMesh.new(); cap_m.radius = 1.45; cap_m.height = 0.95
	var cap_mat := StandardMaterial3D.new(); cap_mat.albedo_color = Color(0.92, 0.22, 0.28); cap_mat.emission_enabled = true; cap_mat.emission = Color(0.75, 0.14, 0.24); cap_mat.emission_energy_multiplier = 0.65
	var cmi := MeshInstance3D.new(); cmi.mesh = cap_m; cmi.material_override = cap_mat; cmi.position = Vector3(0, 0.95, 0); shroom.add_child(cmi)
	var sh_body := StaticBody3D.new(); sh_body.collision_layer = 2; sh_body.collision_mask = 0; sh_body.position = Vector3(0, 1.0, 0)
	var scs := CollisionShape3D.new(); var scyl := CylinderShape3D.new(); scyl.radius = 1.5; scyl.height = 1.6; scs.shape = scyl; sh_body.add_child(scs)
	sh_body.set_meta("interact_id", "bounce_shroom"); sh_body.set_meta("interact_title", "Стрибнути на грибі-батуті (Політ над долиною!)")
	shroom.add_child(sh_body)

	# 3. Ancient Weather Altar on East Overlook (40.0, h, 22.0)
	var wy := sample_height(40.0, 22.0)
	var altar := Node3D.new(); altar.position = Vector3(40.0, wy, 22.0)
	add_child(altar)
	var stone_m := BoxMesh.new(); stone_m.size = Vector3(1.4, 1.35, 1.4)
	var am := MeshInstance3D.new(); am.mesh = stone_m; am.material_override = StandardMaterial3D.new()
	(am.material_override as StandardMaterial3D).albedo_color = Color(0.45, 0.47, 0.50); am.position = Vector3(0, 0.68, 0); altar.add_child(am)
	var orb_mat := StandardMaterial3D.new(); orb_mat.albedo_color = Color(0.32, 0.88, 1.0); orb_mat.emission_enabled = true; orb_mat.emission = Color(0.32, 0.88, 1.0); orb_mat.emission_energy_multiplier = 2.2
	_weather_orb = MeshInstance3D.new(); var om := SphereMesh.new(); om.radius = 0.42
	_weather_orb.mesh = om; _weather_orb.material_override = orb_mat; _weather_orb.position = Vector3(0, 1.85, 0); altar.add_child(_weather_orb)
	var ab := StaticBody3D.new(); ab.collision_layer = 2; ab.collision_mask = 0; ab.position = Vector3(0, 1.35, 0)
	var acs := CollisionShape3D.new(); var abox := BoxShape3D.new(); abox.size = Vector3(1.8, 2.4, 1.8); acs.shape = abox; ab.add_child(acs)
	ab.set_meta("interact_id", "weather_altar"); ab.set_meta("interact_title", "Вівтар погоди (змінити погоду миттєво)")
	altar.add_child(ab)


func _build_cosmo_forest() -> void:
	var ash_preset := load("res://addons/cosmo_tree_gen/presets/ash.tres") as CosmoTreePreset
	var lp_tree_preset := load("res://addons/cosmo_tree_gen/presets/low_poly_tree.tres") as CosmoTreePreset
	var bush_preset := load("res://addons/cosmo_tree_gen/presets/bush.tres") as CosmoTreePreset
	var lp_bush_preset := load("res://addons/cosmo_tree_gen/presets/low_poly_bush.tres") as CosmoTreePreset

	var tree_meshes: Array[ArrayMesh] = [
		_make_cosmo_tree_mesh(_build_spruce_preset(0, 11.2), 101),
		_make_cosmo_tree_mesh(_build_spruce_preset(1, 13.4), 202),
		_make_cosmo_tree_mesh(ash_preset, 303),
		_make_cosmo_tree_mesh(_build_birch_or_autumn_preset(true), 404),
		_make_cosmo_tree_mesh(_build_birch_or_autumn_preset(false), 505),
		_make_cosmo_tree_mesh(lp_tree_preset if lp_tree_preset else ash_preset, 606)
	]
	var bush_meshes: Array[ArrayMesh] = [
		_make_cosmo_tree_mesh(bush_preset, 707),
		_make_cosmo_tree_mesh(lp_bush_preset if lp_bush_preset else bush_preset, 808)
	]

	var tree_buckets: Array[Array] = [[], [], [], [], [], []]
	var bush_buckets: Array[Array] = [[], []]

	var tree_collider_parent := StaticBody3D.new()
	tree_collider_parent.name = "TreeColliders"
	add_child(tree_collider_parent)
	var trunk_shape := CylinderShape3D.new()
	trunk_shape.radius = 0.34
	trunk_shape.height = 5.5

	var rng := RandomNumberGenerator.new()
	rng.randomize()

	for i in range(760):
		var wx := rng.randf_range(-190.0, 190.0)
		var wz := rng.randf_range(-190.0, 190.0)
		if _is_near_road_or_track(wx, wz, 4.8):
			continue
		var h := sample_height(wx, wz)
		if h < WATER_LEVEL + 0.85:
			continue
		var sc := rng.randf_range(0.75, 1.42)
		var b := Basis.from_euler(Vector3(rng.randf_range(-0.04, 0.04), rng.randf() * TAU, rng.randf_range(-0.04, 0.04))).scaled(Vector3(sc, sc, sc))
		var r_pick := rng.randf()
		var variant := 0 if r_pick < 0.25 else (1 if r_pick < 0.45 else (2 if r_pick < 0.65 else (3 if r_pick < 0.82 else (4 if r_pick < 0.92 else 5))))
		tree_buckets[variant].append(Transform3D(b, Vector3(wx, h - 0.12, wz)))

		if Vector2(wx, wz).length() < 130.0:
			var cs := CollisionShape3D.new()
			cs.shape = trunk_shape
			cs.position = Vector3(wx, h + 2.6, wz)
			tree_collider_parent.add_child(cs)

	for v in range(tree_meshes.size()):
		var tm := tree_meshes[v]
		var list: Array = tree_buckets[v]
		if tm and list.size() > 0:
			var tfs: Array[Transform3D] = []
			for tf in list:
				tfs.append(tf)
			_tree_mms.append_array(_populate_chunked_mm("TreeV" + str(v), tm, null, tfs, true, 0.0, 195.0, 4))

	for bi: int in range(bush_meshes.size()):
		var bm := bush_meshes[bi]
		if bm == null:
			continue
		for _i in range(310):
			var wx := rng.randf_range(-132.0, 132.0)
			var wz := rng.randf_range(-132.0, 132.0)
			if _is_near_road_or_track(wx, wz, 3.2): continue
			var h := sample_height(wx, wz)
			if h < WATER_LEVEL + 0.55 or h > 17.5: continue
			var sc := rng.randf_range(0.80, 1.62)
			bush_buckets[bi].append(Transform3D(Basis.from_euler(Vector3(0, rng.randf() * TAU, 0)).scaled(Vector3(sc, sc, sc)), Vector3(wx, h - 0.05, wz)))
		var btfs: Array[Transform3D] = []
		for tf in bush_buckets[bi]:
			btfs.append(tf)
		if btfs.size() > 0:
			_bush_mms.append_array(_populate_chunked_mm("Bush" + str(bi), bm, null, btfs, true, 85.0, 135.0, 4))


func _build_simple_grass_and_plants(player: Node3D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	# 1. Chunked SimpleGrassTextured (organic non-linear random scatter!)
	var sgt_script := load("res://addons/simplegrasstextured/grass.gd") as GDScript
	if sgt_script:
		var sgt_mesh := load("res://addons/simplegrasstextured/default_mesh.tres") as Mesh
		var grass_cells: Dictionary = {}
		for _i in range(36000):
			var wx := rng.randf_range(-98.0, 98.0)
			var wz := rng.randf_range(-98.0, 98.0)
			if absf(wx) < 22.8 and absf(wz) < 12.8: continue
			if wz >= 11.5 and wz <= 66.0 and absf(wx - cobble_road_x(wz)) < 2.6: continue
			if Vector2(wx + 16.0, wz - 66.5).length() < 12.0: continue
			var h := sample_height(wx, wz)
			if h < WATER_LEVEL + 0.45 or h > 16.5: continue
			var sc := rng.randf_range(0.75, 1.55)
			var rot := rng.randf() * TAU
			var b := Basis.from_euler(Vector3(rng.randf_range(-0.08, 0.08), rot, rng.randf_range(-0.08, 0.08))).scaled(Vector3(sc, sc, sc))
			var gx := clampi(int((wx + 98.0) / 49.0), 0, 3)
			var gz := clampi(int((wz + 98.0) / 49.0), 0, 3)
			var gk := Vector2i(gx, gz)
			if not grass_cells.has(gk):
				grass_cells[gk] = [] as Array[Transform3D]
			(grass_cells[gk] as Array[Transform3D]).append(Transform3D(b, Vector3(wx, h - 0.03, wz)))

		for gk in grass_cells.keys():
			var cell_tfs: Array[Transform3D] = grass_cells[gk]
			var sg_node: MultiMeshInstance3D = sgt_script.new()
			sg_node.name = "SimpleGrassChunk_%d_%d" % [gk.x, gk.y]
			add_child(sg_node)

			sg_node.multimesh = MultiMesh.new()
			sg_node.multimesh.transform_format = MultiMesh.TRANSFORM_3D
			sg_node.multimesh.mesh = sgt_mesh
			sg_node.multimesh.instance_count = cell_tfs.size()
			for idx in range(cell_tfs.size()):
				sg_node.multimesh.set_instance_transform(idx, cell_tfs[idx])

			sg_node.set("albedo", Color(0.24, 0.42, 0.16))
			sg_node.set("scale_h", 0.85)
			sg_node.set("scale_w", 1.05)
			sg_node.set("scale_var", -0.35)
			sg_node.set("grass_strength", 0.55)
			sg_node.set("interactive", true)
			sg_node.set("optimization_by_distance", false)
			sg_node.visibility_range_end = 62.0
			sg_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			_simple_grass_chunks.append(sg_node)

		var sg_singleton := get_node_or_null("/root/SimpleGrass")
		if sg_singleton:
			sg_singleton.call("set_interactive", true)
			if player:
				sg_singleton.call("set_player_position", player.global_position)

	# 2. ALL 4 PolyHaven 3D Fern Variants scattered naturally
	for f_name: String in ["fern_02_a", "fern_02_b", "fern_02_c", "fern_02_d"]:
		var fmesh := _extract_named_mesh("res://assets/models/fern_02/fern_02.gltf", f_name)
		if fmesh == null: continue
		var fern_tfs: Array[Transform3D] = []
		for _i in range(360):
			var wx := rng.randf_range(-108.0, 108.0)
			var wz := rng.randf_range(-108.0, 108.0)
			if _is_near_road_or_track(wx, wz, 2.8): continue
			var h := sample_height(wx, wz)
			if h < WATER_LEVEL + 0.55 or h > 15.5: continue
			var sc := rng.randf_range(0.90, 1.85)
			fern_tfs.append(Transform3D(Basis.from_euler(Vector3(0, rng.randf() * TAU, 0)).scaled(Vector3(sc, sc, sc)), Vector3(wx, h - 0.02, wz)))
		_fern_mms.append_array(_populate_chunked_mm("Fern_" + f_name, fmesh, null, fern_tfs, false, 52.0, 108.0, 4))

	# 3. 6 Distinct Gazania Wildflower Species in organic meadow patches!
	for fl_name: String in ["flower_gazania_a_LOD0", "flower_gazania_b_LOD0", "flower_gazania_c_LOD0", "flower_gazania_d_LOD0", "flower_gazania_e_LOD0", "flower_gazania_f_LOD0"]:
		var flm := _extract_named_mesh("res://assets/models/flower_gazania/flower_gazania.gltf", fl_name)
		if flm == null: continue
		var fl_tfs: Array[Transform3D] = []
		for _c in range(60):
			var cx := rng.randf_range(-92.0, 92.0)
			var cz := rng.randf_range(-92.0, 92.0)
			for _k in range(6):
				var wx := cx + rng.randf_range(-3.8, 3.8)
				var wz := cz + rng.randf_range(-3.8, 3.8)
				if _is_near_road_or_track(wx, wz, 2.5): continue
				var h := sample_height(wx, wz)
				if h < WATER_LEVEL + 0.50 or h > 14.0: continue
				var sc := rng.randf_range(1.4, 2.8)
				fl_tfs.append(Transform3D(Basis.from_euler(Vector3(0, rng.randf() * TAU, 0)).scaled(Vector3(sc, sc, sc)), Vector3(wx, h - 0.01, wz)))
		_flower_mms.append_array(_populate_chunked_mm("Flower_" + fl_name, flm, null, fl_tfs, false, 48.0, 95.0, 4))

	# 4. 5 Varied Grass Clump Species (not 1 uniform mesh!)
	for cl_name: String in ["grass_medium_01_tall_a_LOD0", "grass_medium_01_tall_b_LOD0", "grass_medium_01_mid_a_LOD0", "grass_medium_01_large_a_LOD0", "grass_medium_01_small_a_LOD0"]:
		var clm := _extract_named_mesh("res://assets/models/grass_medium_01/grass_medium_01.gltf", cl_name)
		if clm == null: continue
		var cl_tfs: Array[Transform3D] = []
		for _i in range(680):
			var wx := rng.randf_range(-98.0, 98.0)
			var wz := rng.randf_range(-98.0, 98.0)
			if _is_near_road_or_track(wx, wz, 2.4): continue
			var h := sample_height(wx, wz)
			if h < WATER_LEVEL + 0.42 or h > 15.0: continue
			var sc := rng.randf_range(1.7, 3.4)
			cl_tfs.append(Transform3D(Basis.from_euler(Vector3(0, rng.randf() * TAU, 0)).scaled(Vector3(sc, sc, sc)), Vector3(wx, h - 0.02, wz)))
		_grass_clump_mms.append_array(_populate_chunked_mm("GrassClump_" + cl_name, clm, null, cl_tfs, false, 52.0, 98.0, 4))

	# 5. Floating Lake Water Lilies ("латаття") & Organic Marsh Reed Clusters (never contour lines!)
	var lily_pad := CylinderMesh.new(); lily_pad.top_radius = 0.42; lily_pad.bottom_radius = 0.42; lily_pad.height = 0.03; lily_pad.radial_segments = 9
	var lily_mat := StandardMaterial3D.new(); lily_mat.albedo_color = Color(0.14, 0.44, 0.16); lily_mat.roughness = 0.55
	var lily_tfs: Array[Transform3D] = []
	for lake_c: Vector2 in [Vector2(-68.0, -28.0), Vector2(72.0, 34.0), Vector2(18.0, 66.0)]:
		for _k in range(28):
			var ang := rng.randf() * TAU
			var rad := rng.randf_range(8.0, 28.0)
			var lx := lake_c.x + cos(ang) * rad
			var lz := lake_c.y + sin(ang) * rad
			if sample_height(lx, lz) < WATER_LEVEL - 0.25:
				var sc := rng.randf_range(0.65, 1.45)
				lily_tfs.append(Transform3D(Basis.from_euler(Vector3(0, rng.randf() * TAU, 0)).scaled(Vector3(sc, 1.0, sc)), Vector3(lx, WATER_LEVEL + 0.03, lz)))
	if lily_tfs.size() > 0:
		_flower_mms.append_array(_populate_chunked_mm("WaterLily", lily_pad, lily_mat, lily_tfs, false, 65.0, 120.0, 3))

	# 5b. Swaying Underwater Lake Algae / Kelp Tufts ("водорослі") on Lake Beds
	var algae_blade := CylinderMesh.new()
	algae_blade.top_radius = 0.010; algae_blade.bottom_radius = 0.055; algae_blade.height = 1.0; algae_blade.radial_segments = 4
	var algae_mat := ShaderMaterial.new()
	algae_mat.shader = load("res://shaders/foliage_wind.gdshader")
	algae_mat.set_shader_parameter("color_base", Color(0.06, 0.26, 0.12))
	algae_mat.set_shader_parameter("color_tip", Color(0.24, 0.66, 0.30))
	algae_mat.set_shader_parameter("wind_speed", 1.25)
	algae_mat.set_shader_parameter("wind_strength", 0.15)
	algae_mat.set_shader_parameter("is_grass_blade", true)
	_foliage_mats.append(algae_mat)

	var algae_tfs: Array[Transform3D] = []
	var algae_zones := [
		[Vector2(-49.0, -21.0), 36, 2.0, 11.0], # Near Mirror Lake Pier in clear shallow view
		[Vector2(-68.0, -28.0), 85, 4.0, 28.0],
		[Vector2(72.0, 34.0), 90, 5.0, 32.0],
		[Vector2(18.0, 66.0), 45, 3.0, 17.0]
	]
	for az in algae_zones:
		var center: Vector2 = az[0]
		for _a in range(int(az[1])):
			var ang := rng.randf() * TAU
			var rad := rng.randf_range(float(az[2]), float(az[3]))
			var cx := center.x + cos(ang) * rad
			var cz := center.y + sin(ang) * rad
			if absf(cx) < 25.0 and absf(cz) < 15.0: continue
			var h := sample_height(cx, cz)
			if h < WATER_LEVEL - 0.35:
				var max_h := maxf(0.28, WATER_LEVEL - h - 0.18)
				for _b in range(rng.randi_range(4, 7)):
					var bx := cx + rng.randf_range(-0.45, 0.45)
					var bz := cz + rng.randf_range(-0.45, 0.45)
					var bh := sample_height(bx, bz)
					if bh < WATER_LEVEL - 0.30:
						var sy := minf(rng.randf_range(0.45, 1.35), max_h)
						var sx := rng.randf_range(0.8, 1.4)
						algae_tfs.append(Transform3D(Basis.from_euler(Vector3(rng.randf_range(-0.18, 0.18), rng.randf() * TAU, rng.randf_range(-0.18, 0.18))).scaled(Vector3(sx, sy, sx)), Vector3(bx, bh + sy * 0.45, bz)))
	if algae_tfs.size() > 0:
		_flower_mms.append_array(_populate_chunked_mm("UnderwaterAlgae", algae_blade, algae_mat, algae_tfs, false, 70.0, 120.0, 3))

	# Forest Red-Cap Mushrooms scattered randomly on forest floor
	var sh_cap := SphereMesh.new(); sh_cap.radius = 0.18; sh_cap.height = 0.16; sh_cap.radial_segments = 8
	var sh_mat := StandardMaterial3D.new(); sh_mat.albedo_color = Color(0.82, 0.16, 0.14); sh_mat.roughness = 0.55
	var sh_tfs: Array[Transform3D] = []
	for _m in range(140):
		var wx := rng.randf_range(-90.0, 90.0)
		var wz := rng.randf_range(-90.0, 90.0)
		if _is_near_road_or_track(wx, wz, 2.8): continue
		var h := sample_height(wx, wz)
		if h > WATER_LEVEL + 1.1:
			var sc := rng.randf_range(0.6, 1.5)
			sh_tfs.append(Transform3D(Basis.IDENTITY.scaled(Vector3(sc, sc, sc)), Vector3(wx, h + 0.08 * sc, wz)))
	if sh_tfs.size() > 0:
		_flower_mms.append_array(_populate_chunked_mm("ForestMushroom", sh_cap, sh_mat, sh_tfs, false, 45.0, 95.0, 3))

	# 6. Clustered Organic Lakeside Reeds (tufts, NOT rigid contour rows!)
	var reed_mesh := CylinderMesh.new()
	reed_mesh.top_radius = 0.014
	reed_mesh.bottom_radius = 0.042
	reed_mesh.height = 1.65
	reed_mesh.radial_segments = 5
	var reed_mat := ShaderMaterial.new()
	reed_mat.shader = load("res://shaders/foliage_wind.gdshader")
	reed_mat.set_shader_parameter("color_base", Color(0.16, 0.28, 0.09))
	reed_mat.set_shader_parameter("color_tip", Color(0.45, 0.38, 0.16))
	reed_mat.set_shader_parameter("is_grass_blade", false)
	_foliage_mats.append(reed_mat)

	var reed_tfs: Array[Transform3D] = []
	for _c in range(95):
		var anchor_x := rng.randf_range(-115.0, 115.0)
		var anchor_z := rng.randf_range(-115.0, 115.0)
		if absf(anchor_x) < 25.0 and absf(anchor_z) < 15.0: continue
		var ah := sample_height(anchor_x, anchor_z)
		if ah < WATER_LEVEL - 0.35 or ah > WATER_LEVEL + 0.65: continue
		var blades := rng.randi_range(4, 11)
		for _b in range(blades):
			var wx := anchor_x + rng.randf_range(-1.9, 1.9)
			var wz := anchor_z + rng.randf_range(-1.9, 1.9)
			var h := sample_height(wx, wz)
			if h >= WATER_LEVEL - 0.45 and h <= WATER_LEVEL + 0.65:
				var sc := rng.randf_range(0.55, 1.38)
				reed_tfs.append(Transform3D(Basis.from_euler(Vector3(rng.randf_range(-0.14, 0.14), rng.randf() * TAU, rng.randf_range(-0.14, 0.14))).scaled(Vector3(sc, sc, sc)), Vector3(wx, h + 0.60 * sc, wz)))
	_reed_mm = _populate_mm(MultiMeshInstance3D.new(), reed_mesh, reed_mat, reed_tfs, false)
	_reed_mm.visibility_range_end = 95.0


func _populate_chunked_mm(prefix: String, mesh: Mesh, mat: Material, transforms: Array[Transform3D], shadow: bool, vis_end: float, bounds_half: float, grid_n: int) -> Array[MultiMeshInstance3D]:
	var cells: Dictionary = {}
	var step := (bounds_half * 2.0) / float(grid_n)
	for tf in transforms:
		var gx := clampi(int((tf.origin.x + bounds_half) / step), 0, grid_n - 1)
		var gz := clampi(int((tf.origin.z + bounds_half) / step), 0, grid_n - 1)
		var k := Vector2i(gx, gz)
		if not cells.has(k):
			cells[k] = [] as Array[Transform3D]
		(cells[k] as Array[Transform3D]).append(tf)

	var out: Array[MultiMeshInstance3D] = []
	for k in cells.keys():
		var c_tfs: Array[Transform3D] = cells[k]
		var inst := _populate_mm(MultiMeshInstance3D.new(), mesh, mat, c_tfs, shadow)
		inst.name = "%s_%d_%d" % [prefix, k.x, k.y]
		if vis_end > 0.0:
			inst.visibility_range_end = vis_end
		out.append(inst)
	return out


func _populate_mm(mm_inst: MultiMeshInstance3D, mesh: Mesh, mat: Material, transforms: Array[Transform3D], shadow: bool) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = transforms.size()
	for i in range(transforms.size()):
		mm.set_instance_transform(i, transforms[i])
	mm_inst.multimesh = mm
	if mat:
		mm_inst.material_override = mat
	mm_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mm_inst)
	return mm_inst


func _apply_graphics_settings() -> void:
	var preset_idx := int(ConfigManager.graphics.get("preset", 3))
	var fol_density := clampf(float(ConfigManager.graphics.get("foliage_density", 1.0)), 0.12, 1.5)
	var dist_scale := clampf(float(ConfigManager.graphics.get("view_distance", 1.0)), 0.40, 1.5)
	var shadow_tier := int(ConfigManager.graphics.get("shadows", 3))
	var grass_ratio := clampf(fol_density / 1.5, 0.08, 1.0)
	var tree_ratio := clampf(0.35 + (float(preset_idx) / 3.0) * 0.65, 0.35, 1.0)

	for sg in _simple_grass_chunks:
		if sg and sg.multimesh:
			sg.multimesh.visible_instance_count = mini(
				sg.multimesh.instance_count,
				int(round(float(sg.multimesh.instance_count) * grass_ratio))
			)
			sg.set("optimization_dist_max", 48.0 * dist_scale)
			sg.visibility_range_end = 56.0 * dist_scale

	for mm_list in [_fern_mms, _flower_mms, _grass_clump_mms]:
		for mm_node in mm_list:
			if mm_node and mm_node.multimesh:
				mm_node.multimesh.visible_instance_count = mini(
					mm_node.multimesh.instance_count,
					int(round(float(mm_node.multimesh.instance_count) * grass_ratio))
				)
				mm_node.visibility_range_end = 48.0 * dist_scale

	for mm_node in _bush_mms:
		if mm_node and mm_node.multimesh:
			mm_node.multimesh.visible_instance_count = mini(
				mm_node.multimesh.instance_count,
				int(round(float(mm_node.multimesh.instance_count) * clampf(grass_ratio + 0.18, 0.2, 1.0)))
			)
			mm_node.visibility_range_end = 78.0 * dist_scale
			mm_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadow_tier >= 3 else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	for tm_node in _tree_mms:
		if tm_node and tm_node.multimesh:
			tm_node.multimesh.visible_instance_count = mini(
				tm_node.multimesh.instance_count,
				int(round(float(tm_node.multimesh.instance_count) * tree_ratio))
			)
			tm_node.visibility_range_end = (145.0 * dist_scale) if preset_idx >= 4 else (130.0 * dist_scale)
			tm_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadow_tier >= 1 else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	for rm_node in _rock_mms:
		if rm_node:
			rm_node.visibility_range_end = 105.0 * dist_scale
			rm_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadow_tier >= 2 else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	if terrain:
		terrain.mesh_lods = 5 if preset_idx <= 0 else (6 if preset_idx <= 2 else 7)
		if terrain.material:
			terrain.material.set("dual_scaling_enabled", preset_idx >= 2)
			terrain.material.set("macro_variation_enabled", preset_idx >= 1)

	if sky3d:
		if sky3d.sun:
			sky3d.sun.shadow_enabled = shadow_tier > 0
			sky3d.sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS if shadow_tier >= 2 else DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
			sky3d.sun.directional_shadow_blend_splits = shadow_tier >= 2
			sky3d.sun.directional_shadow_max_distance = 260.0 * dist_scale
			sky3d.sun.directional_shadow_fade_start = 0.85
			sky3d.sun.shadow_bias = 0.032
			sky3d.sun.shadow_normal_bias = 1.15
		if sky3d.moon:
			sky3d.moon.shadow_enabled = shadow_tier >= 2
		if sky3d.sky:
			sky3d.clouds_enabled = preset_idx > 0
		if sky3d.environment:
			ConfigManager.apply_to_environment(sky3d.environment)
	if is_instance_valid(_reflection_probe):
		_reflection_probe.enable_shadows = shadow_tier >= 2
