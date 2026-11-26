class_name Python3DArenas
extends RefCounted

# 18 themed worlds matching 3D Snake Adventure original campaign + textures.
const TEX_DIR := "res://assets/textures/python3d/"

const WORLD_SPECS: Array[Dictionary] = [
	{"id": 1, "theme": "forest", "name": "Смарагдовий Ліс", "size": 44.0, "quota": 24, "speed": 8.5, "enemies": 2,
	 "bg": Color(0.055, 0.102, 0.078), "wall": Color(0.373, 0.255, 0.149), "grid": Color(0.157, 0.541, 0.227),
	 "amb": Color(0.647, 0.706, 0.647), "tex": "ground_forest.png"},
	{"id": 2, "theme": "desert", "name": "Золота Пустеля", "size": 46.0, "quota": 28, "speed": 9.0, "enemies": 2,
	 "bg": Color(0.176, 0.118, 0.063), "wall": Color(0.588, 0.412, 0.216), "grid": Color(0.902, 0.706, 0.373),
	 "amb": Color(0.784, 0.725, 0.588), "tex": "ground_desert.png"},
	{"id": 3, "theme": "ocean", "name": "Підводний Океан", "size": 48.0, "quota": 32, "speed": 9.5, "enemies": 2,
	 "bg": Color(0.031, 0.086, 0.149), "wall": Color(0.078, 0.471, 0.549), "grid": Color(0.110, 0.333, 0.451),
	 "amb": Color(0.510, 0.686, 0.784), "tex": "ground_ocean.png"},
	{"id": 4, "theme": "space", "name": "Глибокий Космос", "size": 50.0, "quota": 36, "speed": 10.0, "enemies": 2,
	 "bg": Color(0.024, 0.024, 0.071), "wall": Color(0.510, 0.275, 0.863), "grid": Color(0.294, 0.176, 0.549),
	 "amb": Color(0.588, 0.549, 0.745), "tex": "ground_space.png"},
	{"id": 5, "theme": "factory", "name": "Кібер-Фабрика", "size": 52.0, "quota": 40, "speed": 10.5, "enemies": 2,
	 "bg": Color(0.086, 0.078, 0.086), "wall": Color(0.706, 0.196, 0.118), "grid": Color(0.863, 0.549, 0.078),
	 "amb": Color(0.706, 0.627, 0.549), "tex": "ground_factory.png"},
	{"id": 6, "theme": "city", "name": "Неоновий Мегаполіс", "size": 54.0, "quota": 44, "speed": 11.0, "enemies": 3,
	 "bg": Color(0.047, 0.039, 0.110), "wall": Color(1.000, 0.000, 0.502), "grid": Color(0.000, 0.863, 1.000),
	 "amb": Color(0.667, 0.627, 0.824), "tex": "ground_city.png"},
	{"id": 7, "theme": "arctic", "name": "Крижана Арктика", "size": 54.0, "quota": 48, "speed": 11.4, "enemies": 3,
	 "bg": Color(0.059, 0.118, 0.176), "wall": Color(0.275, 0.549, 0.745), "grid": Color(0.471, 0.745, 0.902),
	 "amb": Color(0.824, 0.902, 1.000), "tex": "ground_arctic.png"},
	{"id": 8, "theme": "lava", "name": "Пекельна Лава", "size": 56.0, "quota": 52, "speed": 11.8, "enemies": 3,
	 "bg": Color(0.137, 0.039, 0.031), "wall": Color(0.627, 0.118, 0.059), "grid": Color(1.000, 0.275, 0.078),
	 "amb": Color(0.824, 0.510, 0.353), "tex": "ground_lava.png"},
	{"id": 9, "theme": "crystal", "name": "Кришталеві Печери", "size": 56.0, "quota": 56, "speed": 12.2, "enemies": 3,
	 "bg": Color(0.071, 0.031, 0.118), "wall": Color(0.549, 0.118, 0.784), "grid": Color(0.745, 0.235, 1.000),
	 "amb": Color(0.706, 0.549, 0.863), "tex": "ground_crystal.png"},
	{"id": 10, "theme": "jungle", "name": "Загублені Джунглі", "size": 58.0, "quota": 60, "speed": 12.6, "enemies": 4,
	 "bg": Color(0.039, 0.110, 0.055), "wall": Color(0.431, 0.314, 0.176), "grid": Color(0.235, 0.627, 0.314),
	 "amb": Color(0.667, 0.784, 0.627), "tex": "ground_jungle.png"},
	{"id": 11, "theme": "sky", "name": "Штормове Святилище", "size": 60.0, "quota": 64, "speed": 13.0, "enemies": 4,
	 "bg": Color(0.078, 0.137, 0.235), "wall": Color(0.353, 0.510, 0.784), "grid": Color(0.941, 0.941, 0.392),
	 "amb": Color(0.784, 0.843, 0.961), "tex": "ground_sky.png"},
	{"id": 12, "theme": "toxic", "name": "Радіоактивна Зона", "size": 60.0, "quota": 68, "speed": 13.4, "enemies": 4,
	 "bg": Color(0.063, 0.098, 0.047), "wall": Color(0.549, 0.627, 0.118), "grid": Color(0.314, 1.000, 0.196),
	 "amb": Color(0.667, 0.863, 0.549), "tex": "ground_toxic.png"},
	{"id": 13, "theme": "swamp", "name": "Містичне Болото", "size": 62.0, "quota": 72, "speed": 13.7, "enemies": 4,
	 "bg": Color(0.071, 0.086, 0.063), "wall": Color(0.294, 0.373, 0.176), "grid": Color(0.471, 0.627, 0.235),
	 "amb": Color(0.588, 0.706, 0.549), "tex": "ground_swamp.png"},
	{"id": 14, "theme": "necropolis", "name": "Давній Некрополь", "size": 62.0, "quota": 76, "speed": 14.0, "enemies": 4,
	 "bg": Color(0.125, 0.094, 0.059), "wall": Color(0.549, 0.373, 0.157), "grid": Color(0.863, 0.667, 0.275),
	 "amb": Color(0.745, 0.667, 0.510), "tex": "ground_necropolis.png"},
	{"id": 15, "theme": "steampunk", "name": "Острови Стімпанку", "size": 64.0, "quota": 80, "speed": 14.3, "enemies": 5,
	 "bg": Color(0.137, 0.098, 0.071), "wall": Color(0.667, 0.353, 0.137), "grid": Color(0.902, 0.627, 0.196),
	 "amb": Color(0.784, 0.667, 0.510), "tex": "ground_steampunk.png"},
	{"id": 16, "theme": "event_horizon", "name": "Горизонт Подій", "size": 64.0, "quota": 84, "speed": 14.6, "enemies": 5,
	 "bg": Color(0.016, 0.016, 0.039), "wall": Color(0.627, 0.157, 0.863), "grid": Color(1.000, 0.392, 0.118),
	 "amb": Color(0.667, 0.471, 0.863), "tex": "ground_event_horizon.png"},
	{"id": 17, "theme": "dungeon", "name": "Підземелля Дракона", "size": 66.0, "quota": 88, "speed": 14.9, "enemies": 5,
	 "bg": Color(0.078, 0.047, 0.055), "wall": Color(0.431, 0.118, 0.098), "grid": Color(0.863, 0.196, 0.157),
	 "amb": Color(0.745, 0.471, 0.431), "tex": "ground_dungeon.png"},
	{"id": 18, "theme": "quantum", "name": "Квантова Цитадель", "size": 68.0, "quota": 95, "speed": 15.2, "enemies": 5,
	 "bg": Color(0.020, 0.020, 0.047), "wall": Color(0.000, 0.941, 1.000), "grid": Color(1.000, 0.000, 0.502),
	 "amb": Color(0.745, 0.667, 0.863), "tex": "ground_quantum.png"}
]

static var _tex_cache: Dictionary = {}


static func get_tex(fname: String) -> Texture2D:
	if fname == "":
		return null
	if _tex_cache.has(fname):
		return _tex_cache[fname] as Texture2D
	var path := TEX_DIR + fname
	if ResourceLoader.exists(path):
		var t := load(path) as Texture2D
		_tex_cache[fname] = t
		return t
	return null


static func make_mat(col: Color, tex_name: String = "", rough: float = 0.52, metal: float = 0.08, emit_e: float = 0.0, uv_scale: Vector2 = Vector2.ONE, alpha: float = 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(col.r, col.g, col.b, alpha)
	m.roughness = rough
	m.metallic = metal
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	var tex := get_tex(tex_name)
	if tex != null:
		m.albedo_texture = tex
		m.uv1_scale = Vector3(uv_scale.x, uv_scale.y, 1.0)
	if alpha < 0.99:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if emit_e > 0.0:
		m.emission_enabled = true
		m.emission = col
		if tex != null and tex_name == "cyber_building.png":
			m.emission_texture = tex
		m.emission_energy_multiplier = emit_e
	return m


static func _mesh(parent: Node3D, mesh: Mesh, pos: Vector3, rot_deg: Vector3, mat: Material, nodes: Array[Node3D]) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot_deg
	parent.add_child(mi)
	nodes.append(mi)
	return mi


static func _box(parent: Node3D, pos: Vector3, sz: Vector3, mat: Material, nodes: Array[Node3D], rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var bm := BoxMesh.new()
	bm.size = sz
	return _mesh(parent, bm, pos, rot_deg, mat, nodes)


static func _cyl(parent: Node3D, x: float, base_y: float, z: float, r_top: float, r_bot: float, h: float, mat: Material, nodes: Array[Node3D], segs: int = 12, rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var cm := CylinderMesh.new()
	cm.top_radius = r_top
	cm.bottom_radius = r_bot
	cm.height = h
	cm.radial_segments = segs
	var y_c := base_y + h * 0.5 if rot_deg == Vector3.ZERO else base_y
	return _mesh(parent, cm, Vector3(x, y_c, z), rot_deg, mat, nodes)


static func _sph(parent: Node3D, pos: Vector3, scale_v: Vector3, mat: Material, nodes: Array[Node3D], rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var sm := SphereMesh.new()
	sm.radius = 0.5
	sm.height = 1.0
	var mi := _mesh(parent, sm, pos, rot_deg, mat, nodes)
	mi.scale = scale_v
	return mi


static func _add_obs(out_obs: Array[Dictionary], pos: Vector2, rad: float) -> void:
	out_obs.append({"pos": pos, "rad": rad})


static func _add_spin(spinners: Array[Dictionary], node: Node3D, speed_deg: float) -> void:
	spinners.append({"node": node, "speed": speed_deg})


static func _add_laser(world: Node3D, haz: Array[Dictionary], nodes: Array[Node3D], spinners: Array[Dictionary], p1: Vector3, p2: Vector3, spd: float, col: Color) -> void:
	var root := Node3D.new()
	root.position = p1
	world.add_child(root)
	nodes.append(root)
	var bmat := make_mat(col, "", 0.2, 0.3, 1.5)
	_box(root, Vector3.ZERO, Vector3(2.6, 0.35, 0.35), bmat, nodes)
	var emat := make_mat(Color(0.18, 0.20, 0.24), "", 0.4, 0.7)
	_cyl(root, -1.3, 0.0, 0.0, 0.22, 0.22, 0.65, emat, nodes, 10, Vector3(0, 0, 90))
	_cyl(root, 1.3, 0.0, 0.0, 0.22, 0.22, 0.65, emat, nodes, 10, Vector3(0, 0, 90))
	_box(root, Vector3.ZERO, Vector3(2.5, 0.14, 0.14), make_mat(Color.WHITE, "", 0.1, 0.0, 2.0), nodes)
	var ring := _box(root, Vector3.ZERO, Vector3(0.18, 1.15, 1.15), bmat, nodes, Vector3(45, 0, 0))
	_add_spin(spinners, ring, 140.0)
	haz.append({"kind": "laser", "node": root, "p1": p1, "p2": p2, "speed": spd, "phase": randf_range(0.0, TAU), "pos": Vector2(p1.x, p1.z), "rad": 0.90})


static func _add_gear(world: Node3D, haz: Array[Dictionary], nodes: Array[Node3D], col: Color, pos: Vector3, rot_spd: float, rad: float) -> void:
	var root := Node3D.new()
	root.position = pos
	world.add_child(root)
	nodes.append(root)
	var gmat := make_mat(col, "metal_crate.png", 0.35, 0.65, 0.25)
	_cyl(root, 0.0, -0.31, 0.0, rad, rad, 0.62, gmat, nodes, 16)
	_cyl(root, 0.0, -0.42, 0.0, rad * 0.44, rad * 0.44, 0.84, make_mat(col.darkened(0.32), "", 0.3, 0.7), nodes, 12)
	_sph(root, Vector3(0, 0.15, 0), Vector3(rad * 0.52, 0.85, rad * 0.52), make_mat(col.lightened(0.35), "", 0.2, 0.3, 1.1), nodes)
	var tmat := make_mat(col.darkened(0.15), "", 0.4, 0.6)
	for i in range(8):
		var ang := float(i) * 45.0
		var rr := deg_to_rad(ang)
		_box(root, Vector3(sin(rr) * rad * 1.04, 0.0, cos(rr) * rad * 1.04), Vector3(0.46, 0.66, 0.46), tmat, nodes, Vector3(0, ang, 0))
	haz.append({"kind": "gear", "node": root, "rot_speed": rot_spd, "pos": Vector2(pos.x, pos.z), "rad": rad})


static func build_world(world: Node3D, env: Environment, key_light: DirectionalLight3D, rim_light: DirectionalLight3D, spec: Dictionary, arena_nodes: Array[Node3D], obstacles: Array[Dictionary], hazards: Array[Dictionary], spinners: Array[Dictionary]) -> void:
	var sz := float(spec["size"])
	var half := sz * 0.5
	var wall_col: Color = spec["wall"]
	var grid_col: Color = spec["grid"]
	var bg_col: Color = spec["bg"]

	env.background_color = bg_col
	env.ambient_light_color = spec["amb"]
	env.ambient_light_energy = 0.82
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_light_color = bg_col
	env.fog_depth_begin = 68.0
	env.fog_depth_end = 215.0
	key_light.light_energy = 1.45
	rim_light.light_energy = 0.55

	# HD Textured Floor
	var floor_m := PlaneMesh.new()
	floor_m.size = Vector2(sz, sz)
	var floor_mat := make_mat(Color.WHITE, str(spec["tex"]), 0.78, 0.05, 0.0, Vector2(sz / 8.0, sz / 8.0))
	_mesh(world, floor_m, Vector3.ZERO, Vector3.ZERO, floor_mat, arena_nodes)

	# Sub-floor Citadel Plinth
	var plinth_mat := make_mat(wall_col.darkened(0.35), "stone_brick.png", 0.75, 0.12, 0.0, Vector2(sz / 6.0, 1.0))
	_box(world, Vector3(0, -1.55, 0), Vector3(sz + 3.4, 3.0, sz + 3.4), plinth_mat, arena_nodes)

	# Perimeter Walls + Top Energy Rail + Buttresses
	var wt := 1.4
	var wh := 2.8
	var wmat := make_mat(wall_col, "stone_brick.png", 0.55, 0.25, 0.0, Vector2(sz / 6.0, 1.0))
	var rmat := make_mat(wall_col.lightened(0.35), "", 0.25, 0.4, 0.85)
	var bmat := make_mat(wall_col.darkened(0.15), "stone_brick.png", 0.65, 0.15, 0.0, Vector2(1.0, 1.0))
	var wall_defs := [
		[Vector3(0, wh * 0.5, half + wt * 0.5), Vector3(sz + wt * 2.0, wh, wt), Vector3(sz + wt * 2.0, 0.36, wt * 0.85)],
		[Vector3(0, wh * 0.5, -half - wt * 0.5), Vector3(sz + wt * 2.0, wh, wt), Vector3(sz + wt * 2.0, 0.36, wt * 0.85)],
		[Vector3(half + wt * 0.5, wh * 0.5, 0), Vector3(wt, wh, sz), Vector3(wt, 0.36, sz)],
		[Vector3(-half - wt * 0.5, wh * 0.5, 0), Vector3(wt, wh, sz), Vector3(wt, 0.36, sz)]
	]
	for wd in wall_defs:
		_box(world, wd[0], wd[1], wmat, arena_nodes)
		_box(world, Vector3(wd[0].x, wh + 0.18, wd[0].z), wd[2], rmat, arena_nodes)

	for off in [-sz * 0.25, 0.0, sz * 0.25]:
		for wz in [half + wt * 0.55, -half - wt * 0.55]:
			_box(world, Vector3(off, wh * 0.59, wz), Vector3(1.8, wh * 1.18, wt * 1.35), bmat, arena_nodes)
		for wx in [half + wt * 0.55, -half - wt * 0.55]:
			_box(world, Vector3(wx, wh * 0.59, off), Vector3(wt * 1.35, wh * 1.18, 1.8), bmat, arena_nodes)

	# 4 Corner Watchtowers with Conical Spires & Spinning Beacons
	var pmat := make_mat(wall_col.darkened(0.18), "stone_brick.png", 0.6, 0.2, 0.0, Vector2(2.0, 2.0))
	var roof_mat := make_mat(wall_col.lightened(0.15), "", 0.4, 0.3)
	var bcn_mat := make_mat(grid_col, "", 0.2, 0.4, 1.4)
	for corner in [Vector2(-half, -half), Vector2(half, -half), Vector2(-half, half), Vector2(half, half)]:
		_cyl(world, corner.x, 0.0, corner.y, wt, wt, wh * 1.55, pmat, arena_nodes, 14)
		_cyl(world, corner.x, wh * 1.55, corner.y, 0.0, wt * 1.25, 2.2, roof_mat, arena_nodes, 14)
		var bcn := _box(world, Vector3(corner.x, wh * 1.55 + 2.8, corner.y), Vector3(0.75, 0.75, 0.75), bcn_mat, arena_nodes, Vector3(45, 45, 45))
		_add_spin(spinners, bcn, 95.0)

	# Ring of 12 Distant Scenic Horizon Mountains + Glowing Orbs
	var vista_r := sz * 0.86
	var m_mat := make_mat(wall_col.darkened(0.32), "", 0.85, 0.05)
	var o_mat := make_mat(grid_col, "", 0.2, 0.2, 1.5)
	for i in range(12):
		var ang := deg_to_rad(float(i) * 30.0 + 15.0)
		var vx := sin(ang) * vista_r
		var vz := cos(ang) * vista_r
		var ph := 14.0 + float(i % 3) * 5.0
		var pw := 4.5 + float(i % 2) * 1.75
		_cyl(world, vx, -2.0, vz, 0.0, pw, ph, m_mat, arena_nodes, 6, Vector3(0, float(i) * 30.0, 0))
		_sph(world, Vector3(vx, ph - 0.8, vz), Vector3(1.2, 1.2, 1.2), o_mat, arena_nodes)

	_build_theme_props(world, str(spec["theme"]), arena_nodes, obstacles, hazards, spinners)


static func _build_theme_props(world: Node3D, theme: String, n: Array[Node3D], obs: Array[Dictionary], haz: Array[Dictionary], spn: Array[Dictionary]) -> void:
	match theme:
		"forest":
			var bark := make_mat(Color(0.45, 0.30, 0.18), "bark.png", 0.85)
			var root_m := make_mat(Color(0.37, 0.24, 0.14), "bark.png", 0.85)
			for p in [Vector2(-13,-13), Vector2(13,-13), Vector2(-13,13), Vector2(13,13), Vector2(-16,0), Vector2(16,0), Vector2(-8,-14), Vector2(8,14)]:
				_cyl(world, p.x, 0, p.y, 0.58, 0.65, 0.53, root_m, n, 12)
				var tr := _cyl(world, p.x, 0, p.y, 0.34, 0.36, 6.2, bark, n, 12)
				_cyl(tr, 0.32, -1.6, 0.0, 0.11, 0.13, 1.1, bark, n, 8, Vector3(0, 0, -55))
				_add_obs(obs, p, 0.85)
				for t in [[3.0, 3.6, 1.8, Color(0.12, 0.50, 0.20)], [2.4, 3.2, 3.6, Color(0.14, 0.56, 0.23)], [1.8, 2.8, 5.3, Color(0.17, 0.61, 0.26)], [1.12, 2.4, 6.9, Color(0.22, 0.67, 0.29)]]:
					_cyl(world, p.x, t[2], p.y, 0.0, t[0], t[1], make_mat(t[3], "pine_needles.png", 0.78), n, 16)
			var stem_m := make_mat(Color(0.96, 0.96, 0.90), "", 0.65)
			var cap_m := make_mat(Color(0.92, 0.16, 0.16), "", 0.35, 0.1)
			var dot_m := make_mat(Color.WHITE, "", 0.3)
			for m in [Vector2(-6,-7), Vector2(7,-6), Vector2(-7,8), Vector2(6,7), Vector2(-5,-11), Vector2(5,11), Vector2(-9,2), Vector2(9,-2)]:
				_cyl(world, m.x, 0, m.y, 0.26, 0.28, 1.3, stem_m, n, 10)
				_cyl(world, m.x, 0.82, m.y, 0.25, 0.42, 0.22, make_mat(Color(0.92, 0.90, 0.82)), n, 10)
				var cap := _sph(world, Vector3(m.x, 1.3, m.y), Vector3(1.5, 0.75, 1.5), cap_m, n)
				for sp in [Vector2(-0.35,0.25), Vector2(0.35,-0.25), Vector2(0.25,0.35), Vector2(-0.25,-0.35), Vector2(0,0.45), Vector2.ZERO]:
					_sph(cap, Vector3(sp.x, 0.32, sp.y), Vector3(0.20, 0.16, 0.20), dot_m, n)
				_add_obs(obs, m, 0.9)
			var r_m := make_mat(Color(0.37, 0.41, 0.35), "stone_brick.png", 0.85)
			var moss_m := make_mat(Color(0.18, 0.55, 0.22), "pine_needles.png", 0.8)
			for b in [Vector2(-10,5), Vector2(10,-5), Vector2(-5,-15), Vector2(5,15), Vector2(14,7), Vector2(-14,-7)]:
				var rk := _sph(world, Vector3(b.x, 0.8, b.y), Vector3(2.6, 1.6, 2.4), r_m, n)
				_sph(rk, Vector3(0, 0.40, 0), Vector3(0.86, 0.38, 0.86), moss_m, n)
				_add_obs(obs, b, 1.3)
			for l in [Vector3(-6, -11, 35), Vector3(6, 11, -25)]:
				_cyl(world, l.x, 0.65, l.y, 0.65, 0.65, 4.2, bark, n, 12, Vector3(90, l.z, 0))
				_add_obs(obs, Vector2(l.x, l.y), 1.5)
		"desert":
			var sand := make_mat(Color(0.84, 0.69, 0.43), "sandstone_rune.png", 0.75)
			var gold := make_mat(Color(1.0, 0.84, 0.20), "", 0.25, 0.75, 0.3)
			var flame := make_mat(Color(1.0, 0.43, 0.08), "", 0.2, 0.0, 1.5)
			var br_stand := make_mat(Color(0.31, 0.27, 0.24), "", 0.6)
			for p in [Vector2(-13,-13), Vector2(13,-13), Vector2(-13,13), Vector2(13,13)]:
				_box(world, Vector3(p.x, 0.6, p.y), Vector3(5.4, 1.2, 5.4), sand, n)
				_box(world, Vector3(p.x, 1.8, p.y), Vector3(3.8, 1.2, 3.8), sand, n)
				_box(world, Vector3(p.x, 2.9, p.y), Vector3(2.2, 1.0, 2.2), sand, n)
				_cyl(world, p.x, 3.4, p.y, 0.0, 1.25, 1.4, gold, n, 4, Vector3(0, 45, 0))
				for bz in [Vector2(-2.2,-2.2), Vector2(2.2,-2.2), Vector2(-2.2,2.2), Vector2(2.2,2.2)]:
					_cyl(world, p.x + bz.x, 0, p.y + bz.y, 0.21, 0.21, 1.05, br_stand, n, 8)
					_sph(world, Vector3(p.x + bz.x, 1.15, p.y + bz.y), Vector3(0.38, 0.45, 0.38), flame, n)
				_add_obs(obs, p, 2.6)
			var cact := make_mat(Color(0.18, 0.57, 0.25), "", 0.65)
			var flw := make_mat(Color(0.98, 0.20, 0.31), "", 0.4, 0.0, 0.4)
			for c in [Vector2(-6,-12), Vector2(6,-12), Vector2(-6,12), Vector2(6,12), Vector2(-14,0), Vector2(14,0), Vector2(-6,-6), Vector2(6,6)]:
				_cyl(world, c.x, 0, c.y, 0.47, 0.47, 3.8, cact, n, 12)
				_cyl(world, c.x - 0.7, 2.0, c.y, 0.25, 0.25, 1.1, cact, n, 8, Vector3(0, 0, 90))
				_cyl(world, c.x - 1.2, 1.4, c.y, 0.25, 0.25, 1.5, cact, n, 8)
				_cyl(world, c.x + 0.7, 1.5, c.y, 0.25, 0.25, 1.1, cact, n, 8, Vector3(0, 0, 90))
				_cyl(world, c.x + 1.2, 0.9, c.y, 0.25, 0.25, 1.5, cact, n, 8)
				_sph(world, Vector3(c.x, 3.9, c.y), Vector3(0.55, 0.38, 0.55), flw, n)
				_add_obs(obs, c, 1.0)
			for o in [Vector2(-7,-4), Vector2(7,4), Vector2(-7,4), Vector2(7,-4)]:
				_box(world, Vector3(o.x, 0.4, o.y), Vector3(1.8, 0.8, 1.8), sand, n)
				_box(world, Vector3(o.x, 3.2, o.y), Vector3(1.2, 5.0, 1.2), sand, n)
				_cyl(world, o.x, 5.7, o.y, 0.0, 0.95, 1.2, gold, n, 4, Vector3(0, 45, 0))
				var sd := _box(world, Vector3(o.x, 7.3, o.y), Vector3(0.65, 0.65, 0.15), gold, n, Vector3(45, 0, 45))
				_add_spin(spn, sd, 110.0)
				_add_obs(obs, o, 1.25)
		"ocean":
			var corals := [[Vector2(-13,-13), Color(1.0, 0.31, 0.47)], [Vector2(13,-13), Color(1.0, 0.59, 0.16)], [Vector2(-13,13), Color(0.0, 0.90, 0.96)], [Vector2(13,13), Color(1.0, 0.43, 0.71)], [Vector2(-16,0), Color(1.0, 0.71, 0.20)], [Vector2(16,0), Color(0.16, 0.96, 0.71)]]
			for cd in corals:
				var p: Vector2 = cd[0]; var col: Color = cd[1]
				var cm := make_mat(col, "", 0.45, 0.1, 0.25)
				var base := _sph(world, Vector3(p.x, 0.9, p.y), Vector3(2.8, 1.8, 2.8), cm, n)
				for i in range(6):
					var rr := deg_to_rad(float(i) * 60.0)
					_cyl(base, sin(rr) * 0.30, 0.50, cos(rr) * 0.30, 0.12, 0.14, 0.9, cm, n, 8, Vector3(25.0 * cos(rr), float(i) * 60.0, 25.0 * sin(rr)))
				_add_obs(obs, p, 1.45)
			var sh_b := make_mat(Color(0.35, 0.43, 0.57), "", 0.5)
			var sh_t := make_mat(Color(0.45, 0.54, 0.69), "", 0.5)
			var prl := make_mat(Color(1.0, 0.98, 0.94), "", 0.15, 0.2, 0.6)
			for k in [Vector2(-7,-7), Vector2(7,-7), Vector2(-7,7), Vector2(7,7), Vector2(-11,-11), Vector2(11,11)]:
				_sph(world, Vector3(k.x, 0.4, k.y), Vector3(2.4, 0.8, 2.0), sh_b, n)
				_sph(world, Vector3(k.x, 1.15, k.y), Vector3(2.4, 0.8, 2.0), sh_t, n, Vector3(-28, 0, 0))
				var p_sp := _sph(world, Vector3(k.x, 0.78, k.y), Vector3(0.9, 0.9, 0.9), prl, n)
				var hl := _box(p_sp, Vector3.ZERO, Vector3(1.4, 0.08, 1.4), make_mat(Color(0.47, 0.94, 1.0), "", 0.2, 0.0, 1.2, Vector2.ONE, 0.68), n, Vector3(25, 0, 25))
				_add_spin(spn, hl, 130.0)
				_add_obs(obs, k, 1.3)
			_add_laser(world, haz, n, spn, Vector3(-10, 0.6, -10), Vector3(10, 0.6, -10), 2.2, Color(0.0, 0.90, 1.0))
			_add_laser(world, haz, n, spn, Vector3(10, 0.6, 10), Vector3(-10, 0.6, 10), 2.2, Color(1.0, 0.31, 0.63))
		"space":
			var s_m := make_mat(Color(0.96, 0.78, 0.18), "", 0.25, 0.8, 0.25)
			var pan_m := make_mat(Color(0.12, 0.29, 0.80), "", 0.25, 0.6)
			for a in [Vector2(-14,-14), Vector2(14,-14), Vector2(-14,14), Vector2(14,14), Vector2(-16,0), Vector2(16,0)]:
				var core := _sph(world, Vector3(a.x, 2.2, a.y), Vector3(2.0, 2.0, 2.0), s_m, n)
				_box(core, Vector3(-1.3, 0, 0), Vector3(1.5, 0.08, 0.75), pan_m, n)
				_box(core, Vector3(1.3, 0, 0), Vector3(1.5, 0.08, 0.75), pan_m, n)
				_add_spin(spn, core, 32.0)
				_add_obs(obs, a, 1.4)
			var ast_m := make_mat(Color(0.49, 0.43, 0.61), "magma_rock.png", 0.8)
			var cry_m := make_mat(Color(0.71, 0.35, 1.0), "crystal_facet.png", 0.2, 0.3, 0.7)
			for s in [Vector2(-8,-8), Vector2(8,8), Vector2(-8,8), Vector2(8,-8)]:
				var ast := _sph(world, Vector3(s.x, 1.2, s.y), Vector3(2.8, 2.2, 2.8), ast_m, n)
				for i in range(4):
					var rr := deg_to_rad(float(i) * 90.0)
					_cyl(ast, sin(rr) * 0.36, 0.25, cos(rr) * 0.36, 0.0, 0.22, 0.65, cry_m, n, 5, Vector3(35 * cos(rr), i * 90, 35 * sin(rr)))
				_add_obs(obs, s, 1.45)
			_add_gear(world, haz, n, Color(0.67, 0.24, 1.0), Vector3(0, 0.6, 14), 55.0, 2.2)
			_add_laser(world, haz, n, spn, Vector3(-12, 0.6, -11), Vector3(12, 0.6, -11), 2.6, Color(1.0, 0.16, 0.71))
		"factory":
			var tow_m := make_mat(Color(0.51, 0.54, 0.59), "metal_crate.png", 0.45, 0.65)
			var rim_m := make_mat(Color(0.94, 0.69, 0.08), "", 0.35, 0.4)
			var cor_m := make_mat(Color(1.0, 0.43, 0.08), "", 0.2, 0.0, 1.6)
			for f in [Vector2(-15,-15), Vector2(15,-15), Vector2(-15,15), Vector2(15,15), Vector2(-8,0), Vector2(8,0)]:
				_cyl(world, f.x, 0, f.y, 1.3, 1.3, 4.8, tow_m, n, 16)
				_cyl(world, f.x, 4.4, f.y, 1.48, 1.48, 0.5, rim_m, n, 16)
				_sph(world, Vector3(f.x, 5.0, f.y), Vector3(1.5, 0.6, 1.5), cor_m, n)
				_add_obs(obs, f, 1.5)
			var crate_m := make_mat(Color(0.88, 0.73, 0.24), "metal_crate.png", 0.45, 0.55)
			for t in [Vector2(-6,-10), Vector2(6,10), Vector2(-6,10), Vector2(6,-10)]:
				_box(world, Vector3(t.x, 1.2, t.y), Vector3(2.4, 2.4, 2.4), crate_m, n)
				_add_obs(obs, t, 1.35)
			_add_gear(world, haz, n, Color(0.86, 0.55, 0.08), Vector3(-10, 0.5, -6), 80.0, 1.8)
			_add_gear(world, haz, n, Color(0.86, 0.55, 0.08), Vector3(10, 0.5, 6), -80.0, 1.8)
			_add_laser(world, haz, n, spn, Vector3(-10, 0.6, -5), Vector3(10, 0.6, -5), 3.0, Color(1.0, 0.24, 0.16))
		"city":
			var sky_d := [Vector3(-16,-16,12), Vector3(16,-16,15), Vector3(-16,16,14), Vector3(16,16,16), Vector3(-10,-8,9), Vector3(10,8,9.5), Vector3(-10,8,10), Vector3(10,-8,8.5)]
			var cy_m := make_mat(Color(0.0, 0.92, 1.0), "", 0.2, 0.4, 1.6)
			var pk_m := make_mat(Color(1.0, 0.0, 0.55), "", 0.2, 0.4, 1.8)
			for s in sky_d:
				var h := float(s.z)
				var bmat := make_mat(Color.WHITE, "cyber_building.png", 0.35, 0.3, 0.85, Vector2(1.0, maxf(1.0, floor(h / 4.0))))
				_box(world, Vector3(s.x, h * 0.5, s.y), Vector3(3.4, h, 3.4), bmat, n)
				_box(world, Vector3(s.x, h + 0.15, s.y), Vector3(3.55, 0.35, 3.55), cy_m, n)
				_cyl(world, s.x, h + 0.3, s.y, 0.08, 0.14, 2.2, pk_m, n, 8)
				_add_obs(obs, Vector2(s.x, s.y), 1.9)
			_add_laser(world, haz, n, spn, Vector3(-12, 0.6, -7), Vector3(12, 0.6, -7), 2.8, Color(1.0, 0.0, 0.50))
			_add_laser(world, haz, n, spn, Vector3(12, 0.6, 7), Vector3(-12, 0.6, 7), 2.8, Color(0.0, 0.86, 1.0))
			_add_gear(world, haz, n, Color(1.0, 0.0, 0.50), Vector3(0, 0.6, -15), 70.0, 2.0)
		"arctic":
			var ice_m := make_mat(Color(0.65, 0.92, 1.0), "crystal_facet.png", 0.18, 0.2, 0.45)
			var snow_m := make_mat(Color(0.96, 0.98, 1.0), "", 0.85)
			for i in [Vector2(-14,-14), Vector2(14,-14), Vector2(-14,14), Vector2(14,14), Vector2(-16,0), Vector2(16,0)]:
				_cyl(world, i.x, 0, i.y, 0.0, 1.1, 6.5, ice_m, n, 8)
				_sph(world, Vector3(i.x, 0.4, i.y), Vector3(3.0, 1.0, 3.0), snow_m, n)
				_add_obs(obs, i, 1.45)
			var ig_m := make_mat(Color(0.88, 0.95, 1.0), "stone_brick.png", 0.65)
			for s in [Vector2(-8,-8), Vector2(8,8), Vector2(-8,8), Vector2(8,-8)]:
				_sph(world, Vector3(s.x, 1.1, s.y), Vector3(3.2, 2.4, 3.2), ig_m, n)
				_cyl(world, s.x, 0.7, s.y + 1.6, 0.6, 0.6, 1.6, ig_m, n, 10, Vector3(90, 0, 0))
				_add_obs(obs, s, 1.7)
			_add_laser(world, haz, n, spn, Vector3(-10, 0.6, -10), Vector3(10, 0.6, -10), 2.5, Color(0.39, 0.86, 1.0))
		"lava":
			var mag_m := make_mat(Color(0.76, 0.55, 0.47), "magma_rock.png", 0.75, 0.1, 0.35)
			var pool_m := make_mat(Color(1.0, 0.37, 0.06), "", 0.2, 0.0, 1.6)
			var core_m := make_mat(Color(1.0, 0.65, 0.12), "", 0.15, 0.0, 2.0)
			for l in [Vector2(-15,-15), Vector2(15,-15), Vector2(-15,15), Vector2(15,15), Vector2(-10,0), Vector2(10,0)]:
				_cyl(world, l.x, 0, l.y, 0.25, 1.6, 4.5, mag_m, n, 12)
				_sph(world, Vector3(l.x, 0.06, l.y), Vector3(3.6, 0.16, 3.6), pool_m, n)
				_sph(world, Vector3(l.x, 4.3, l.y), Vector3(1.25, 1.25, 1.25), core_m, n)
				_add_obs(obs, l, 1.65)
			var bas_m := make_mat(Color(0.55, 0.43, 0.45), "magma_rock.png", 0.8)
			for o in [Vector2(-7,-7), Vector2(7,7), Vector2(-7,7), Vector2(7,-7)]:
				_cyl(world, o.x, 0, o.y, 0.9, 0.9, 5.2, bas_m, n, 6)
				_cyl(world, o.x, 5.1, o.y, 0.75, 0.75, 0.25, pool_m, n, 6)
				_add_obs(obs, o, 1.3)
			_add_laser(world, haz, n, spn, Vector3(-12, 0.6, -8), Vector3(12, 0.6, -8), 3.2, Color(1.0, 0.24, 0.04))
		"crystal":
			var gm := make_mat(Color(0.29, 0.25, 0.33), "stone_brick.png", 0.8)
			var spk := make_mat(Color(0.88, 0.37, 1.0), "crystal_facet.png", 0.15, 0.3, 0.85)
			for c in [Vector2(-14,-14), Vector2(14,-14), Vector2(-14,14), Vector2(14,14), Vector2(-8,-8), Vector2(8,8), Vector2(-8,8), Vector2(8,-8)]:
				_sph(world, Vector3(c.x, 0.6, c.y), Vector3(2.6, 1.2, 2.6), gm, n)
				var spk_cfgs := [[4.6, 15, 20], [3.8, -20, 15], [3.2, 10, -25], [3.5, -12, -18]]
				for idx in range(spk_cfgs.size()):
					var sc: Array = spk_cfgs[idx]
					_cyl(world, c.x, 0.6, c.y, 0.0, 0.55, float(sc[0]), spk, n, 6, Vector3(sc[1], idx * 90, sc[2]))
				_add_obs(obs, c, 1.4)
			_add_gear(world, haz, n, Color(0.82, 0.31, 1.0), Vector3(0, 0.6, 12), 65.0, 2.2)
			_add_gear(world, haz, n, Color(0.82, 0.31, 1.0), Vector3(0, 0.6, -12), -65.0, 2.2)
		"jungle":
			var tot_m := make_mat(Color(0.65, 0.51, 0.33), "sandstone_rune.png", 0.7)
			var red_m := make_mat(Color(0.92, 0.22, 0.16), "", 0.4, 0.0, 0.4)
			var eye_m := make_mat(Color(0.16, 1.0, 0.47), "", 0.15, 0.0, 1.8)
			for t in [Vector2(-16,-16), Vector2(16,-16), Vector2(-16,16), Vector2(16,16)]:
				_cyl(world, t.x, 0, t.y, 0.8, 0.8, 5.5, tot_m, n, 12)
				_box(world, Vector3(t.x, 4.2, t.y), Vector3(2.8, 0.55, 0.4), red_m, n)
				_sph(world, Vector3(t.x - 0.35, 4.6, t.y + 0.65), Vector3(0.32, 0.32, 0.32), eye_m, n)
				_sph(world, Vector3(t.x + 0.35, 4.6, t.y + 0.65), Vector3(0.32, 0.32, 0.32), eye_m, n)
				_add_obs(obs, t, 1.45)
			var palm_b := make_mat(Color(0.49, 0.33, 0.19), "bark.png", 0.85)
			var leaf_m := make_mat(Color(0.15, 0.69, 0.23), "pine_needles.png", 0.65)
			var coco_m := make_mat(Color(0.35, 0.22, 0.10), "", 0.8)
			for p in [Vector2(-9,-9), Vector2(9,9), Vector2(-9,9), Vector2(9,-9), Vector2(-14,0), Vector2(14,0)]:
				_sph(world, Vector3(p.x, 0.1, p.y), Vector3(1.2, 0.33, 1.2), tot_m, n)
				_cyl(world, p.x, 0, p.y, 0.31, 0.33, 5.0, palm_b, n, 10)
				for ci in range(3):
					var ca := float(ci) * TAU / 3.0
					_sph(world, Vector3(p.x + sin(ca) * 0.38, 4.65, p.y + cos(ca) * 0.38), Vector3(0.42, 0.42, 0.42), coco_m, n)
				for fi in range(8):
					var fa := float(fi) * 45.0; var fr := deg_to_rad(fa)
					_sph(world, Vector3(p.x + sin(fr) * 1.95, 4.95, p.y + cos(fr) * 1.95), Vector3(4.2, 0.22, 1.2), leaf_m, n, Vector3(-18, fa, 0))
				_add_obs(obs, p, 0.70)
		"sky":
			var mrb := make_mat(Color(0.95, 0.97, 1.0), "stone_brick.png", 0.4)
			var gld := make_mat(Color(0.96, 0.84, 0.35), "", 0.2, 0.8, 0.4)
			var hl_m := make_mat(Color(1.0, 0.94, 0.47), "", 0.15, 0.0, 1.4, Vector2.ONE, 0.75)
			for t in [Vector2(-15,-15), Vector2(15,-15), Vector2(-15,15), Vector2(15,15), Vector2(-10,0), Vector2(10,0)]:
				_box(world, Vector3(t.x, 0.3, t.y), Vector3(1.8, 0.6, 1.8), mrb, n)
				_cyl(world, t.x, 0.6, t.y, 0.55, 0.55, 4.8, mrb, n, 16)
				_box(world, Vector3(t.x, 5.7, t.y), Vector3(1.9, 0.6, 1.9), gld, n)
				var h := _box(world, Vector3(t.x, 6.6, t.y), Vector3(1.6, 0.12, 1.6), hl_m, n, Vector3(25, 0, 25))
				_add_spin(spn, h, 90.0)
				_add_obs(obs, t, 1.3)
			_add_laser(world, haz, n, spn, Vector3(-14, 0.6, -8), Vector3(14, 0.6, -8), 3.4, Color(1.0, 1.0, 0.31))
		"toxic":
			var dm := make_mat(Color(0.88, 0.78, 0.14), "metal_crate.png", 0.45, 0.5)
			var acid := make_mat(Color(0.25, 1.0, 0.12), "", 0.15, 0.0, 1.5)
			for b in [Vector2(-15,-15), Vector2(15,-15), Vector2(-15,15), Vector2(15,15), Vector2(-9,-9), Vector2(9,9), Vector2(-12,0), Vector2(12,0)]:
				_cyl(world, b.x, 0, b.y, 0.9, 0.9, 3.4, dm, n, 14)
				_sph(world, Vector3(b.x, 0.05, b.y), Vector3(2.8, 0.12, 2.8), acid, n)
				_cyl(world, b.x, 3.4, b.y, 0.75, 0.75, 0.15, acid, n, 12)
				_add_obs(obs, b, 1.35)
			_add_laser(world, haz, n, spn, Vector3(-12, 0.6, -8), Vector3(12, 0.6, -8), 3.2, Color(0.31, 1.0, 0.16))
			_add_gear(world, haz, n, Color(0.75, 0.86, 0.12), Vector3(0, 0.6, 13), 70.0, 2.2)
		"swamp":
			var c_tr := make_mat(Color(0.35, 0.24, 0.16), "bark.png", 0.88)
			var c_ms := make_mat(Color(0.22, 0.57, 0.25), "pine_needles.png", 0.8)
			var wisp := make_mat(Color(0.63, 1.0, 0.35), "", 0.15, 0.0, 1.8)
			for s in [Vector2(-16,-16), Vector2(16,-16), Vector2(-16,16), Vector2(16,16), Vector2(-10,-5), Vector2(10,5), Vector2(-5,12), Vector2(5,-12)]:
				_cyl(world, s.x, 0, s.y, 0.36, 0.38, 4.6, c_tr, n, 10)
				_cyl(world, s.x, 0, s.y, 0.0, 0.94, 1.8, c_tr, n, 10)
				_sph(world, Vector3(s.x, 4.6, s.y), Vector3(4.8, 2.1, 4.8), c_ms, n)
				_sph(world, Vector3(s.x + 1.1, 2.2, s.y), Vector3(0.45, 0.45, 0.45), wisp, n)
				_add_obs(obs, s, 0.95)
			_add_laser(world, haz, n, spn, Vector3(-11, 0.6, 0), Vector3(11, 0.6, 0), 2.4, Color(0.63, 0.94, 0.31))
		"necropolis":
			var p_m := make_mat(Color(0.73, 0.57, 0.37), "sandstone_rune.png", 0.7)
			var ob_m := make_mat(Color(0.11, 0.11, 0.14), "", 0.25, 0.75)
			var gld_m := make_mat(Color(1.0, 0.82, 0.20), "", 0.2, 0.85, 0.45)
			for x in [Vector2(-16,-16), Vector2(16,-16), Vector2(-16,16), Vector2(16,16), Vector2(-8,-8), Vector2(8,8), Vector2(-8,8), Vector2(8,-8)]:
				_box(world, Vector3(x.x, 0.9, x.y), Vector3(2.2, 1.8, 2.2), p_m, n)
				_cyl(world, x.x, 1.8, x.y, 0.6, 0.6, 3.6, ob_m, n, 10)
				_cyl(world, x.x, 5.4, x.y, 0.0, 0.65, 1.35, gld_m, n, 6)
				_add_obs(obs, x, 1.45)
			_add_gear(world, haz, n, Color(0.82, 0.63, 0.24), Vector3(0, 0.6, -14), 60.0, 2.2)
			_add_laser(world, haz, n, spn, Vector3(-12, 0.6, 8), Vector3(12, 0.6, 8), 2.8, Color(0.94, 0.71, 0.16))
		"steampunk":
			var brs := make_mat(Color(0.80, 0.51, 0.25), "metal_crate.png", 0.35, 0.78)
			var g_m := make_mat(Color(0.96, 0.78, 0.35), "", 0.25, 0.85, 0.2)
			for b in [Vector2(-17,-17), Vector2(17,-17), Vector2(-17,17), Vector2(17,17), Vector2(-10,0), Vector2(10,0), Vector2(0,15), Vector2(0,-15)]:
				_cyl(world, b.x, 0, b.y, 1.1, 1.1, 4.4, brs, n, 16)
				_cyl(world, b.x + 0.55, 0.2, b.y, 0.35, 0.35, 5.0, g_m, n, 10)
				var fw := _box(world, Vector3(b.x, 4.7, b.y), Vector3(2.6, 0.28, 2.6), g_m, n, Vector3(0, 45, 0))
				_add_spin(spn, fw, 120.0)
				_add_obs(obs, b, 1.5)
			_add_gear(world, haz, n, Color(0.82, 0.55, 0.20), Vector3(-11, 0.6, -7), 85.0, 2.0)
			_add_gear(world, haz, n, Color(0.82, 0.55, 0.20), Vector3(11, 0.6, 7), -85.0, 2.0)
		"event_horizon":
			var vd := make_mat(Color(0.04, 0.03, 0.08), "", 0.1, 0.9)
			var a1 := make_mat(Color(1.0, 0.41, 0.12), "", 0.2, 0.0, 1.6, Vector2.ONE, 0.85)
			var a2 := make_mat(Color(0.73, 0.18, 1.0), "", 0.2, 0.0, 1.6, Vector2.ONE, 0.85)
			for e in [Vector2(-18,-18), Vector2(18,-18), Vector2(-18,18), Vector2(18,18), Vector2(-9,-9), Vector2(9,9), Vector2(-9,9), Vector2(9,-9)]:
				var sng := _sph(world, Vector3(e.x, 1.8, e.y), Vector3(2.6, 2.6, 2.6), vd, n)
				var r1 := _box(sng, Vector3.ZERO, Vector3(1.48, 0.08, 1.48), a1, n, Vector3(30, 45, 0))
				var r2 := _box(sng, Vector3.ZERO, Vector3(1.65, 0.08, 1.65), a2, n, Vector3(-30, -45, 0))
				_add_spin(spn, r1, 140.0); _add_spin(spn, r2, -110.0)
				_add_obs(obs, e, 1.6)
			_add_laser(world, haz, n, spn, Vector3(-15, 0.6, -9), Vector3(15, 0.6, -9), 3.6, Color(1.0, 0.31, 0.08))
			_add_laser(world, haz, n, spn, Vector3(15, 0.6, 9), Vector3(-15, 0.6, 9), 3.6, Color(0.71, 0.16, 1.0))
		"dungeon":
			var dt_m := make_mat(Color(0.33, 0.31, 0.35), "stone_brick.png", 0.7)
			var dr_m := make_mat(Color(0.18, 0.16, 0.20), "", 0.5)
			var df_m := make_mat(Color(1.0, 0.33, 0.08), "", 0.15, 0.0, 1.9)
			for d in [Vector2(-18,-18), Vector2(18,-18), Vector2(-18,18), Vector2(18,18), Vector2(-10,0), Vector2(10,0), Vector2(0,15), Vector2(0,-15)]:
				_cyl(world, d.x, 0, d.y, 1.1, 1.1, 5.2, dt_m, n, 14)
				_cyl(world, d.x, 5.0, d.y, 1.3, 1.3, 0.6, dr_m, n, 14)
				var bf := _sph(world, Vector3(d.x, 5.9, d.y), Vector3(1.15, 1.15, 1.15), df_m, n)
				_add_spin(spn, bf, 90.0)
				_add_obs(obs, d, 1.55)
			_add_laser(world, haz, n, spn, Vector3(-14, 0.6, -8), Vector3(14, 0.6, -8), 3.4, Color(1.0, 0.16, 0.08))
			_add_gear(world, haz, n, Color(0.86, 0.24, 0.12), Vector3(0, 0.6, 12), 75.0, 2.4)
		"quantum":
			var qm := make_mat(Color(1.0, 0.16, 0.63), "crystal_facet.png", 0.15, 0.4, 1.1)
			var qr1 := make_mat(Color(0.0, 0.94, 1.0), "", 0.15, 0.3, 1.6)
			var qr2 := make_mat(Color(1.0, 0.90, 0.0), "", 0.15, 0.3, 1.5)
			for q in [Vector2(-18,-18), Vector2(18,-18), Vector2(-18,18), Vector2(18,18), Vector2(-12,0), Vector2(12,0)]:
				var core := _sph(world, Vector3(q.x, 2.2, q.y), Vector3(2.2, 2.2, 2.2), qm, n)
				var r1 := _cyl(core, 0, 0, 0, 0.72, 0.72, 0.08, qr1, n, 16, Vector3(45, 0, 45))
				var r2 := _cyl(core, 0, 0, 0, 0.88, 0.88, 0.08, qr2, n, 16, Vector3(-45, 0, -45))
				_add_spin(spn, r1, 150.0); _add_spin(spn, r2, -130.0)
				_add_obs(obs, q, 1.6)
			_add_gear(world, haz, n, Color(1.0, 0.0, 0.50), Vector3(0, 0.6, 15), 95.0, 2.6)
			_add_gear(world, haz, n, Color(0.0, 0.94, 1.0), Vector3(0, 0.6, -15), -95.0, 2.6)
			_add_laser(world, haz, n, spn, Vector3(-16, 0.6, -8), Vector3(16, 0.6, -8), 3.8, Color(1.0, 0.0, 0.50))
			_add_laser(world, haz, n, spn, Vector3(16, 0.6, 8), Vector3(-16, 0.6, 8), 3.8, Color(0.0, 0.94, 1.0))
