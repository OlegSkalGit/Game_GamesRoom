class_name CasinoRoom
extends Node3D

# 34 completely unique games across Casino, Underground Complex & Mansard Gallery:
# Main Hall (7), West Strategy Lounge (5), East Arcade Landing (1),
# Basement Card Club (3), Basement Exhibition Hall Tripods (6), Wine Cellar & Vault Tripods (2), Mansard Gallery Tripods (10)
const PAINTING_SPECS: Array[Dictionary] = [
	{"id": "mario", "title": "Маріо", "pos": Vector3(-5.2, 2.75, -8.68), "yaw": 0.0},
	{"id": "tetris", "title": "Тетріс", "pos": Vector3(0.0, 2.75, -8.68), "yaw": 0.0},
	{"id": "snake", "title": "Змійка 3D", "pos": Vector3(5.2, 2.75, -8.68), "yaw": 0.0},
	{"id": "bomberman", "title": "Бомбермен", "pos": Vector3(-8.68, 2.75, -5.2), "yaw": PI * 0.5},
	{"id": "arkanoid", "title": "Арканоїд", "pos": Vector3(-8.68, 2.75, 5.2), "yaw": PI * 0.5},
	{"id": "arcade", "title": "Космічна Аркада", "pos": Vector3(8.68, 2.75, -5.2), "yaw": -PI * 0.5},
	{"id": "tanks", "title": "Танчики", "pos": Vector3(8.68, 2.75, 5.2), "yaw": -PI * 0.5},

	# West Strategy Lounge (X: -20 .. -9)
	{"id": "soccer", "title": "Соккер", "pos": Vector3(-14.5, 2.75, -8.68), "yaw": 0.0},
	{"id": "chess", "title": "Шахи", "pos": Vector3(-19.68, 2.75, -5.0), "yaw": PI * 0.5},
	{"id": "checkers", "title": "Шашки", "pos": Vector3(-19.68, 2.75, 0.0), "yaw": PI * 0.5},
	{"id": "corners", "title": "Уголки", "pos": Vector3(-19.68, 2.75, 5.0), "yaw": PI * 0.5},
	{"id": "battleship", "title": "Морський бій", "pos": Vector3(-14.5, 2.75, 8.68), "yaw": PI},

	# East Hall (X: +9 .. +20)
	{"id": "pacman", "title": "Пак-Лабіринт", "pos": Vector3(14.5, 2.75, -8.68), "yaw": 0.0},

	# Basement Room 1: VIP Card Club (Y = -4.0, X: +5.2 .. +19.0)
	{"id": "durak", "title": "Дурак", "pos": Vector3(8.0, -1.95, -8.12), "yaw": 0.0},
	{"id": "blackjack", "title": "Блекджек", "pos": Vector3(12.2, -1.95, -8.12), "yaw": 0.0},
	{"id": "poker", "title": "Покер", "pos": Vector3(5.68, -1.95, -4.5), "yaw": PI * 0.5},

	# Basement Room 2: Grand Exhibition Hall with Wooden Artist Tripods (X: -6.8 .. +5.2)
	{"id": "2048", "title": "2048", "pos": Vector3(-3.3, -2.28, -4.4), "yaw": PI * 0.35, "easel": true},
	{"id": "zuma", "title": "Зума", "pos": Vector3(-3.9, -2.28, 0.0), "yaw": PI * 0.50, "easel": true},
	{"id": "puzzle", "title": "Пазли", "pos": Vector3(-3.3, -2.28, 4.4), "yaw": PI * 0.65, "easel": true},
	{"id": "match3", "title": "Самоцвіти", "pos": Vector3(2.2, -2.28, -5.2), "yaw": -PI * 0.30, "easel": true},
	{"id": "minesweeper", "title": "Сапер", "pos": Vector3(2.2, -2.28, 5.2), "yaw": -PI * 0.70, "easel": true},
	{"id": "solitaire", "title": "Косинка", "pos": Vector3(-0.6, -2.28, -6.5), "yaw": 0.0, "easel": true},

	# Basement Room 3 (Wine Cellar Tripod) & Room 4 (Vault Tripod)
	{"id": "flappy", "title": "Сокіл Долини", "pos": Vector3(-11.2, -2.28, -6.1), "yaw": -0.45, "easel": true},
	{"id": "sudoku", "title": "Судоку", "pos": Vector3(-11.2, -2.28, 6.1), "yaw": PI + 0.45, "easel": true},

	# Mansard Arcade Gallery with 10 Exhibition Tripods (Floor Y=+6.80 -> Easel Y=+8.52)
	{"id": "python3d", "title": "Пітон", "pos": Vector3(12.6, 8.52, -4.6), "yaw": -0.22, "easel": true},
	{"id": "hexa", "title": "Гекса", "pos": Vector3(12.6, 8.52, 4.6), "yaw": PI + 0.22, "easel": true},
	{"id": "sokoban", "title": "Сокобан", "pos": Vector3(6.8, 8.52, -4.6), "yaw": 0.0, "easel": true},
	{"id": "fifteen", "title": "П'ятнашки", "pos": Vector3(6.8, 8.52, 4.6), "yaw": PI, "easel": true},
	{"id": "tictactoe", "title": "Хрестики-Нулики", "pos": Vector3(1.6, 8.52, -4.6), "yaw": 0.0, "easel": true},
	{"id": "pong", "title": "Теніс (Pong)", "pos": Vector3(1.6, 8.52, 4.6), "yaw": PI, "easel": true},
	{"id": "memory", "title": "Меморі", "pos": Vector3(-3.6, 8.52, -4.6), "yaw": 0.0, "easel": true},
	{"id": "codelock", "title": "Кодовий замок", "pos": Vector3(-3.6, 8.52, 4.6), "yaw": PI, "easel": true},
	{"id": "bullscows", "title": "Бики та Корови", "pos": Vector3(-8.6, 8.52, -4.6), "yaw": 0.28, "easel": true},
	{"id": "balda", "title": "Балда", "pos": Vector3(-8.6, 8.52, 4.6), "yaw": PI - 0.28, "easel": true}
]

var paintings: Array[Dictionary] = []
var _roulette_wheel: Node3D
var _roulette_boost: float = 0.0
var _slot_levers: Array[Node3D] = []
var _slot_pulls: Array[float] = [0.0, 0.0]
var _disco_mode: bool = false
var _disco_lights: Array[OmniLight3D] = []
var _arch_shadow_lights: Array[OmniLight3D] = []
var _casino_probe: ReflectionProbe
var _preview_drawer_nodes: Array[Dictionary] = []
var _searchlights: Array[Dictionary] = []
var _preview_time: float = 0.0
var _frame_counter: int = 0
var _mat_cache: Dictionary = {}


func _ready() -> void:
	_build_structure()
	_build_west_wing()
	_build_east_wing_and_stairs()
	_build_basement_vault()
	_build_mansard()
	_build_casino_centerpiece()
	_build_casino_luxury_props()
	_build_chandeliers()
	_build_all_paintings()
	_build_roof_searchlights()
	_build_interior_reflection_probe()
	ConfigManager.graphics_changed.connect(_apply_lighting_quality)
	_apply_lighting_quality()


func _mat(col: Color, rough: float = 0.7, metal: float = 0.0, emission: Color = Color.BLACK, emit_e: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = rough
	m.metallic = metal
	if emit_e > 0.0:
		m.emission_enabled = true
		m.emission = emission
		m.emission_energy_multiplier = emit_e
	return m


func _pbr_mat(folder: String, tint: Color, uv_scale: Vector3 = Vector3(3.0, 3.0, 1.0), rough_override: float = -1.0, metal: float = 0.0) -> StandardMaterial3D:
	var key := "%s_%s_%s_%s_%s" % [folder, tint, uv_scale, rough_override, metal]
	if _mat_cache.has(key):
		return _mat_cache[key] as StandardMaterial3D
	var m := StandardMaterial3D.new()
	m.albedo_color = tint
	m.uv1_scale = uv_scale
	m.metallic = metal
	if rough_override >= 0.0:
		m.roughness = rough_override
	var d := load("res://assets/textures/pbr/%s/diff.jpg" % folder) as Texture2D
	var n := load("res://assets/textures/pbr/%s/nor.jpg" % folder) as Texture2D
	var r := load("res://assets/textures/pbr/%s/rough.jpg" % folder) as Texture2D
	if d: m.albedo_texture = d
	if n:
		m.normal_enabled = true
		m.normal_scale = 0.85
		m.normal_texture = n
	if r and rough_override < 0.0:
		m.roughness_texture = r
	_mat_cache[key] = m
	return m


func _textile_mat(albedo_tex: Texture2D, tint: Color, uv_scale: Vector3, rough: float = 0.88) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = tint
	if albedo_tex:
		m.albedo_texture = albedo_tex
	m.uv1_scale = uv_scale
	m.roughness = rough
	var n := load("res://assets/textures/pbr/denim_fabric/nor.jpg") as Texture2D
	var r := load("res://assets/textures/pbr/denim_fabric/rough.jpg") as Texture2D
	if n:
		m.normal_enabled = true
		m.normal_scale = 0.65
		m.normal_texture = n
	if r:
		m.roughness_texture = r
	return m


func _make_woven_rug_texture() -> ImageTexture:
	var sz := 512
	var img := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	for y in range(sz):
		for x in range(sz):
			var nx := float(x) / sz
			var ny := float(y) / sz
			var border := minf(minf(nx, 1.0 - nx), minf(ny, 1.0 - ny))
			var weave := sin(float(x) * 1.6) * sin(float(y) * 1.6) * 0.025
			var diamond := absf(fmod(nx * 24.0, 1.0) - 0.5) + absf(fmod(ny * 24.0, 1.0) - 0.5)
			var col := Color(0.24 + weave, 0.045, 0.060)
			if diamond < 0.22:
				col = Color(0.29 + weave, 0.065, 0.075)
			elif diamond > 0.68:
				col = col.darkened(0.12)
			if (border > 0.025 and border < 0.036) or (border > 0.055 and border < 0.068):
				col = Color(0.46, 0.36, 0.19)
			elif border > 0.036 and border < 0.055:
				col = Color(0.14, 0.03, 0.04)
			var dist := Vector2(nx - 0.5, ny - 0.5).length()
			if dist > 0.225 and dist < 0.236:
				col = Color(0.46, 0.36, 0.19)
			elif dist > 0.205 and dist <= 0.225:
				col = Color(0.11, 0.13, 0.10)
			elif dist <= 0.205:
				col = Color(0.07 + weave, 0.14, 0.10)
			img.set_pixel(x, y, col)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


func _add_box_body(parent: Node3D, size: Vector3, pos: Vector3, mat: Material, with_collision: bool = true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)

	if with_collision:
		var sb := StaticBody3D.new()
		sb.position = pos
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = size
		cs.shape = bs
		sb.add_child(cs)
		parent.add_child(sb)
	return mi


func _add_occluder(sz: Vector3, pos: Vector3) -> void:
	var oi := OccluderInstance3D.new()
	var bo := BoxOccluder3D.new()
	bo.size = sz
	oi.occluder = bo
	oi.position = pos
	add_child(oi)


func _build_arched_partition(x_pos: float, plaster_wall: Material, walnut_mat: Material, bronze_mat: Material) -> void:
	# Partition wall at x_pos spanning Z=-9..+9 with a grand 4.0m wide x 4.4m tall doorway at Z=-2..+2
	_add_box_body(self, Vector3(0.46, 6.2, 7.0), Vector3(x_pos, 3.1, -5.5), plaster_wall, true)
	_add_box_body(self, Vector3(0.46, 6.2, 7.0), Vector3(x_pos, 3.1, 5.5), plaster_wall, true)
	_add_box_body(self, Vector3(0.46, 1.8, 4.0), Vector3(x_pos, 5.3, 0.0), plaster_wall, true)
	# Arch door casing
	_add_box_body(self, Vector3(0.56, 4.4, 0.22), Vector3(x_pos, 2.2, -2.05), walnut_mat, false)
	_add_box_body(self, Vector3(0.56, 4.4, 0.22), Vector3(x_pos, 2.2, 2.05), walnut_mat, false)
	_add_box_body(self, Vector3(0.58, 0.22, 4.35), Vector3(x_pos, 4.42, 0.0), bronze_mat, false)


func _build_structure() -> void:
	var stone_mat := _pbr_mat("marble_01", Color(0.84, 0.80, 0.74), Vector3(6.0, 4.0, 1.0), 0.38)
	var parquet_mat := _pbr_mat("herringbone_parquet", Color(0.76, 0.66, 0.55), Vector3(6.0, 6.0, 1.0), 0.36, 0.04)
	var plaster_wall := _pbr_mat("painted_plaster_wall", Color(0.19, 0.30, 0.23), Vector3(5.5, 2.4, 1.0), 0.86)
	var walnut_mat := _pbr_mat("american_walnut_veneer", Color(0.60, 0.45, 0.34), Vector3(2.8, 2.0, 1.0), 0.42, 0.04)
	var dark_walnut := _pbr_mat("american_walnut_veneer", Color(0.36, 0.25, 0.18), Vector3(2.8, 2.0, 1.0), 0.48, 0.04)
	var bronze_mat := _mat(Color(0.56, 0.43, 0.20), 0.34, 0.86)
	var velvet_drape := _textile_mat(null, Color(0.32, 0.045, 0.060), Vector3(2.0, 6.0, 1.0), 0.90)
	var ceiling_mat := _pbr_mat("american_walnut_veneer", Color(0.38, 0.27, 0.19), Vector3(4.0, 4.0, 1.0), 0.58)
	var roof_ext := _pbr_mat("marble_01", Color(0.24, 0.24, 0.25), Vector3(8.0, 4.0, 1.0), 0.68)
	var glass_mat := _mat(Color(0.78, 0.88, 0.94, 0.18), 0.06, 0.15)
	glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	# Exterior travertine terrace slabs strictly OUTSIDE walls (zero overlaps, zero basement protrusion!)
	_add_box_body(self, Vector3(3.2, 0.8, 18.0), Vector3(-21.6, -0.4, 0.0), stone_mat, true)
	_add_box_body(self, Vector3(3.2, 0.8, 18.0), Vector3(21.6, -0.4, 0.0), stone_mat, true)
	_add_box_body(self, Vector3(46.4, 0.8, 2.8), Vector3(0.0, -0.4, -10.4), stone_mat, true)
	_add_box_body(self, Vector3(46.4, 0.8, 3.2), Vector3(0.0, -0.4, 10.6), stone_mat, true)

	# Continuous West Wing + Main Hall Parquet Floor (X: -20..+9, top Y=+0.06 matching East Wing seamlessly!)
	_add_box_body(self, Vector3(29.0, 0.14, 17.8), Vector3(-5.5, -0.01, 0.0), parquet_mat, true)

	# South terrace stone stairs
	for s in range(4):
		var sy := -0.15 - float(s) * 0.22
		var sz := 12.6 + float(s) * 0.75
		_add_box_body(self, Vector3(8.5, 0.24, 0.85), Vector3(0, sy, sz), stone_mat, true)

	# Main Hall woven Monte-Carlo broadloom rug + entrance runner
	var carpet_mat := _textile_mat(_make_woven_rug_texture(), Color(1.0, 1.0, 1.0), Vector3(1.0, 1.0, 1.0), 0.94)
	carpet_mat.uv1_scale = Vector3(1.0, 1.0, 1.0)
	var runner_mat := _textile_mat(null, Color(0.36, 0.05, 0.07), Vector3(4.0, 4.0, 1.0), 0.92)
	_add_box_body(self, Vector3(12.6, 0.024, 12.6), Vector3(0, 0.072, 0), carpet_mat, false)
	_add_box_body(self, Vector3(3.0, 0.020, 2.4), Vector3(0, 0.070, 7.8), runner_mat, false)

	# North & South Perimeter Walls spanning entire 40m complex (X: -20 .. +20)
	_add_box_body(self, Vector3(40.6, 6.2, 0.5), Vector3(0.0, 3.1, -9.0), plaster_wall, true)
	_add_box_body(self, Vector3(17.2, 6.2, 0.5), Vector3(-11.6, 3.1, 9.0), plaster_wall, true)
	_add_box_body(self, Vector3(17.2, 6.2, 0.5), Vector3(11.6, 3.1, 9.0), plaster_wall, true)
	_add_box_body(self, Vector3(6.2, 1.8, 0.5), Vector3(0.0, 5.3, 9.0), plaster_wall, true)
	_add_box_body(self, Vector3(3.4, 3.2, 0.08), Vector3(-6.0, 2.7, 9.0), glass_mat, false)
	_add_box_body(self, Vector3(3.4, 3.2, 0.08), Vector3(6.0, 2.7, 9.0), glass_mat, false)

	# Inner arched partitions at X=-9 and X=+9 between Main Hall and Side Wings
	_build_arched_partition(-9.0, plaster_wall, walnut_mat, bronze_mat)
	_build_arched_partition(9.0, plaster_wall, walnut_mat, bronze_mat)

	# Outer West (X=-20) and East (X=+20) walls
	_add_box_body(self, Vector3(0.5, 6.2, 18.6), Vector3(-20.0, 3.1, 0.0), plaster_wall, true)
	_add_box_body(self, Vector3(0.5, 6.2, 18.6), Vector3(20.0, 3.1, 0.0), plaster_wall, true)

	# Occluders embedded INSIDE opaque N/W/E walls (omit overhead deck so Mansard stays unobstructed!)
	_add_occluder(Vector3(40.0, 6.0, 0.3), Vector3(0.0, 3.1, -9.0))
	_add_occluder(Vector3(0.3, 6.0, 18.0), Vector3(-20.0, 3.1, 0.0))
	_add_occluder(Vector3(0.3, 6.0, 18.0), Vector3(20.0, 3.1, 0.0))

	# Main Hall Walnut Wainscoting & Dado Rail (with doorway gaps)
	_add_box_body(self, Vector3(17.8, 1.08, 0.14), Vector3(0, 0.54, -8.72), dark_walnut, false)
	_add_box_body(self, Vector3(17.8, 0.09, 0.18), Vector3(0, 1.10, -8.71), bronze_mat, false)
	for side_x in [-8.72, 8.72]:
		_add_box_body(self, Vector3(0.14, 1.08, 6.6), Vector3(side_x, 0.54, -5.5), dark_walnut, false)
		_add_box_body(self, Vector3(0.14, 1.08, 6.6), Vector3(side_x, 0.54, 5.5), dark_walnut, false)
		_add_box_body(self, Vector3(0.18, 0.09, 6.6), Vector3(side_x, 1.10, -5.5), bronze_mat, false)
		_add_box_body(self, Vector3(0.18, 0.09, 6.6), Vector3(side_x, 1.10, 5.5), bronze_mat, false)

	# Fluted Walnut Pilasters & Warm Bronze Sconces in Main Hall
	var sconce_glass := _mat(Color(1.0, 0.88, 0.68), 0.35, 0.0, Color(1.0, 0.78, 0.48), 0.90)
	for off in [-2.6, 2.6]:
		_add_box_body(self, Vector3(0.36, 4.75, 0.14), Vector3(off, 3.45, -8.70), walnut_mat, false)
		_add_box_body(self, Vector3(0.44, 0.14, 0.18), Vector3(off, 5.75, -8.68), bronze_mat, false)
		_add_box_body(self, Vector3(0.10, 0.24, 0.08), Vector3(off, 3.10, -8.56), sconce_glass, false)
		for wx in [-8.70, 8.70]:
			var s_sign := 1.0 if wx < 0.0 else -1.0
			_add_box_body(self, Vector3(0.14, 4.75, 0.36), Vector3(wx, 3.45, off), walnut_mat, false)
			_add_box_body(self, Vector3(0.18, 0.14, 0.44), Vector3(wx, 5.75, off), bronze_mat, false)
			_add_box_body(self, Vector3(0.08, 0.24, 0.10), Vector3(wx + s_sign * 0.14, 3.10, off), sconce_glass, false)

	# Burgundy velvet drapes flanking South entrance
	for dx in [-3.1, 3.1]:
		_add_box_body(self, Vector3(0.55, 4.4, 0.22), Vector3(dx, 2.25, 8.65), velvet_drape, false)
		_add_box_body(self, Vector3(0.62, 0.08, 0.26), Vector3(dx, 1.45, 8.65), bronze_mat, false)

	# Exterior Entrance Columns & Marquee
	for cx in [-3.4, 3.4]:
		var col_mesh := CylinderMesh.new(); col_mesh.top_radius = 0.28; col_mesh.bottom_radius = 0.32; col_mesh.height = 5.6
		var cmi := MeshInstance3D.new(); cmi.mesh = col_mesh; cmi.material_override = stone_mat; cmi.position = Vector3(cx, 2.8, 10.6)
		add_child(cmi)
		_add_box_body(self, Vector3(0.75, 0.30, 0.75), Vector3(cx, 5.65, 10.6), bronze_mat, false)
		_add_box_body(self, Vector3(0.80, 0.30, 0.80), Vector3(cx, 0.15, 10.6), bronze_mat, true)

	var marquee_glow := _mat(Color(0.95, 0.78, 0.36), 0.25, 0.7, Color(0.96, 0.74, 0.28), 1.35)
	_add_box_body(self, Vector3(6.8, 1.05, 0.35), Vector3(0.0, 5.45, 9.45), dark_walnut, false)
	_add_box_body(self, Vector3(6.95, 0.10, 0.42), Vector3(0.0, 5.98, 9.45), marquee_glow, false)
	_add_box_body(self, Vector3(6.95, 0.10, 0.42), Vector3(0.0, 4.92, 9.45), marquee_glow, false)
	var sign_lbl := Label3D.new()
	sign_lbl.text = "★ КАЗИНО • 24 ІГРИ ★"
	sign_lbl.position = Vector3(0.0, 5.45, 9.66)
	sign_lbl.pixel_size = 0.0085
	sign_lbl.font_size = 56
	sign_lbl.modulate = Color(1.0, 0.88, 0.48)
	add_child(sign_lbl)

	# CEILING & MANSARD FLOOR DECK WITHOUT Z-FIGHTING (cutout ONLY for East Mansard stairs X:17.3..19.8, Z:-7.8..+1.0):
	_add_box_body(self, Vector3(37.3, 0.16, 17.6), Vector3(-1.35, 6.22, 0.0), ceiling_mat, false)
	_add_box_body(self, Vector3(2.5, 0.16, 7.8), Vector3(18.55, 6.22, 4.9), ceiling_mat, false)
	_add_box_body(self, Vector3(2.5, 0.16, 1.0), Vector3(18.55, 6.22, -8.3), ceiling_mat, false)

	_add_box_body(self, Vector3(38.0, 0.42, 19.6), Vector3(-1.7, 6.59, 0.0), roof_ext, true)
	_add_box_body(self, Vector3(3.4, 0.42, 8.8), Vector3(19.0, 6.59, 5.4), roof_ext, true)
	_add_box_body(self, Vector3(3.4, 0.42, 2.0), Vector3(19.0, 6.59, -8.8), roof_ext, true)

	# Perimeter bronze fascia ONLY along 4 outer edges
	_add_box_body(self, Vector3(41.8, 0.24, 0.30), Vector3(0, 6.32, 9.75), bronze_mat, false)
	_add_box_body(self, Vector3(41.8, 0.24, 0.30), Vector3(0, 6.32, -9.75), bronze_mat, false)
	_add_box_body(self, Vector3(0.30, 0.24, 19.8), Vector3(-20.75, 6.32, 0), bronze_mat, false)
	_add_box_body(self, Vector3(0.30, 0.24, 19.8), Vector3(20.75, 6.32, 0), bronze_mat, false)

	# Exposed Coffered Walnut Ceiling Beams protruding cleanly below 6.14 (skipping Mansard stair cutout!)
	for beam_x in [-14.5, -5.5, 0.0, 5.5, 14.5]:
		_add_box_body(self, Vector3(0.32, 0.23, 17.6), Vector3(beam_x, 6.045, 0), dark_walnut, false)
	for beam_z in [-5.5, 0.0, 5.5]:
		var max_bx := 17.25 if beam_z < 1.0 else 19.8
		var span_x := max_bx + 19.8
		_add_box_body(self, Vector3(span_x, 0.23, 0.32), Vector3(-19.8 + span_x * 0.5, 6.045, beam_z), dark_walnut, false)


func _build_west_wing() -> void:
	var parquet_mat := _pbr_mat("herringbone_parquet", Color(0.76, 0.66, 0.55), Vector3(4.0, 6.0, 1.0), 0.36, 0.04)
	var walnut_mat := _pbr_mat("american_walnut_veneer", Color(0.55, 0.40, 0.30), Vector3(2.5, 2.0, 1.0), 0.42)
	var dark_walnut := _pbr_mat("american_walnut_veneer", Color(0.36, 0.25, 0.18), Vector3(2.5, 2.0, 1.0), 0.48)
	var leather_mat := _pbr_mat("fabric_leather_02", Color(0.30, 0.12, 0.10), Vector3(4.0, 2.0, 1.0), 0.52)
	var bronze_mat := _mat(Color(0.56, 0.43, 0.20), 0.34, 0.86)
	var runner_mat := _textile_mat(null, Color(0.30, 0.05, 0.07), Vector3(3.0, 6.0, 1.0), 0.92)

	# West Wing runner & wainscoting (floor already spans X:-20..+9 flush at Y=+0.06!)
	_add_box_body(self, Vector3(7.2, 0.022, 4.4), Vector3(-13.8, 0.072, 0), runner_mat, false)

	# Wainscoting along N/W/S West Wing walls
	_add_box_body(self, Vector3(10.6, 1.08, 0.14), Vector3(-14.5, 0.54, -8.72), dark_walnut, false)
	_add_box_body(self, Vector3(10.6, 1.08, 0.14), Vector3(-14.5, 0.54, 8.72), dark_walnut, false)
	_add_box_body(self, Vector3(0.14, 1.08, 17.6), Vector3(-19.72, 0.54, 0), dark_walnut, false)
	_add_box_body(self, Vector3(10.6, 0.09, 0.18), Vector3(-14.5, 1.10, -8.71), bronze_mat, false)
	_add_box_body(self, Vector3(10.6, 0.09, 0.18), Vector3(-14.5, 1.10, 8.71), bronze_mat, false)
	_add_box_body(self, Vector3(0.18, 0.09, 17.6), Vector3(-19.71, 1.10, 0), bronze_mat, false)

	# Wing sign above arch
	var lbl := Label3D.new()
	lbl.text = "◀ ЗАЛ ШАХІВ ТА СТРАТЕГІЇ"
	lbl.position = Vector3(-12.5, 4.55, 0.0)
	lbl.rotation.y = PI * 0.5
	lbl.pixel_size = 0.0055
	lbl.font_size = 42
	lbl.modulate = Color(0.95, 0.84, 0.45)
	add_child(lbl)

	# Central Lounge Chess Table + 2 Leather Armchairs
	var tbl := Node3D.new()
	tbl.position = Vector3(-14.6, 0.0, 0.0)
	add_child(tbl)
	_add_box_body(tbl, Vector3(0.28, 0.72, 0.28), Vector3(0, 0.36, 0), dark_walnut, true)
	_add_box_body(tbl, Vector3(1.15, 0.07, 1.15), Vector3(0, 0.75, 0), walnut_mat, true)
	var board_mat := _mat(Color(0.84, 0.78, 0.65), 0.35)
	_add_box_body(tbl, Vector3(0.68, 0.025, 0.68), Vector3(0, 0.795, 0), board_mat, false)
	for side_z in [-1.05, 1.05]:
		_add_box_body(tbl, Vector3(0.65, 0.44, 0.58), Vector3(0, 0.22, side_z), leather_mat, true)
		_add_box_body(tbl, Vector3(0.65, 0.48, 0.12), Vector3(0, 0.66, side_z + (0.24 if side_z > 0 else -0.24)), leather_mat, true)

	var l_west := OmniLight3D.new()
	l_west.position = Vector3(-14.5, 4.8, 0.0)
	l_west.light_color = Color(1.0, 0.90, 0.72)
	l_west.light_energy = 4.2
	l_west.omni_range = 21.0
	l_west.omni_attenuation = 1.15
	l_west.shadow_bias = 0.045
	l_west.shadow_blur = 1.5
	add_child(l_west)
	_arch_shadow_lights.append(l_west)


func _build_east_wing_and_stairs() -> void:
	var parquet_mat := _pbr_mat("herringbone_parquet", Color(0.76, 0.66, 0.55), Vector3(4.0, 6.0, 1.0), 0.36, 0.04)
	var stone_mat := _pbr_mat("marble_01", Color(0.84, 0.80, 0.74), Vector3(3.0, 3.0, 1.0), 0.35)
	var dark_walnut := _pbr_mat("american_walnut_veneer", Color(0.36, 0.25, 0.18), Vector3(2.5, 2.0, 1.0), 0.48)
	var bronze_mat := _mat(Color(0.56, 0.43, 0.20), 0.34, 0.86)
	var runner_mat := _textile_mat(null, Color(0.32, 0.05, 0.07), Vector3(2.5, 8.0, 1.0), 0.90)

	# East Wing floor tiles (top Y=+0.06 matching Main Hall flush, ZERO overlap!) surrounding stairwell X:[11.6..17.4], Z:[-2.2..+6.4]
	_add_box_body(self, Vector3(2.6, 0.14, 17.8), Vector3(10.3, -0.01, 0.0), parquet_mat, true)
	_add_box_body(self, Vector3(5.8, 0.14, 6.7), Vector3(14.5, -0.01, -5.55), parquet_mat, true)
	_add_box_body(self, Vector3(2.6, 0.14, 17.8), Vector3(18.7, -0.01, 0.0), parquet_mat, true)
	_add_box_body(self, Vector3(5.8, 0.14, 2.5), Vector3(14.5, -0.01, 7.65), parquet_mat, true)

	# Clean dark walnut stairwell fascia lining the vertical gap Y=[-0.40 .. +0.06]
	_add_box_body(self, Vector3(0.08, 0.46, 8.6), Vector3(11.64, -0.17, 2.1), dark_walnut, false)
	_add_box_body(self, Vector3(0.08, 0.46, 8.6), Vector3(17.36, -0.17, 2.1), dark_walnut, false)
	_add_box_body(self, Vector3(5.8, 0.46, 0.08), Vector3(14.5, -0.17, -2.16), dark_walnut, false)
	_add_box_body(self, Vector3(5.8, 0.46, 0.08), Vector3(14.5, -0.17, 6.36), dark_walnut, false)

	# Wainscoting on East Wing N/E/S walls
	_add_box_body(self, Vector3(10.6, 1.08, 0.14), Vector3(14.5, 0.54, -8.72), dark_walnut, false)
	_add_box_body(self, Vector3(10.6, 1.08, 0.14), Vector3(14.5, 0.54, 8.72), dark_walnut, false)
	_add_box_body(self, Vector3(0.14, 1.08, 17.6), Vector3(19.72, 0.54, 0), dark_walnut, false)
	_add_box_body(self, Vector3(10.6, 0.09, 0.18), Vector3(14.5, 1.10, -8.71), bronze_mat, false)
	_add_box_body(self, Vector3(0.18, 0.09, 17.6), Vector3(19.71, 1.10, 0), bronze_mat, false)

	# Staircase Sign
	var lbl := Label3D.new()
	lbl.text = "▼ СХОДИ У ПІДВАЛ • 4 ЗАЛИ ТА ВИСТАВКА"
	lbl.position = Vector3(14.5, 3.85, -2.1)
	lbl.pixel_size = 0.0052
	lbl.font_size = 38
	lbl.modulate = Color(1.0, 0.85, 0.42)
	add_child(lbl)

	# Guard Railings around East, West & South stairwell edges
	for rx in [11.65, 17.35]:
		_add_box_body(self, Vector3(0.10, 0.95, 8.6), Vector3(rx, 0.48, 2.1), bronze_mat, true)
	_add_box_body(self, Vector3(5.8, 0.95, 0.10), Vector3(14.5, 0.48, 6.45), bronze_mat, true)

	# 16 Grand Marble Stairs descending smoothly from Z=-2.2 (Y=0.0) to Z=+5.8 (Y=-4.0)
	var step_count := 16
	var run_len := 8.0 / float(step_count)
	var drop_h := 4.0 / float(step_count)
	for i in range(step_count):
		var sy := -float(i + 1) * drop_h + drop_h * 0.5
		var sz := -2.2 + (float(i) + 0.5) * run_len
		_add_box_body(self, Vector3(5.2, drop_h + 0.18, run_len + 0.04), Vector3(14.5, sy - 0.08, sz), stone_mat, false)
		_add_box_body(self, Vector3(3.4, 0.02, run_len + 0.05), Vector3(14.5, sy + drop_h * 0.5 + 0.01, sz), runner_mat, false)
		_add_box_body(self, Vector3(5.22, 0.025, 0.04), Vector3(14.5, sy + drop_h * 0.5 + 0.015, sz - run_len * 0.48), bronze_mat, false)

	# Smooth collision ramp ending 0.42m before top landing + horizontal bridge over slab edge (zero capsule snag!)
	_add_stair_ramp_collider("StairRampCollider", 14.5, 5.4, Vector2(-2.24, 0.064), Vector2(5.85, -4.00))

	var l_east := OmniLight3D.new()
	l_east.position = Vector3(14.5, 4.8, -3.5)
	l_east.light_color = Color(1.0, 0.90, 0.72)
	l_east.light_energy = 3.85
	l_east.omni_range = 20.0
	l_east.omni_attenuation = 1.15
	l_east.shadow_bias = 0.045
	l_east.shadow_blur = 1.5
	add_child(l_east)
	_arch_shadow_lights.append(l_east)


func _add_stair_ramp_collider(node_name: String, x_pos: float, width: float, p_a: Vector2, p_b: Vector2) -> void:
	# p_a / p_b are Vector2(z, top_surface_y); places ramp reaching hi.y 0.42m early + flat landing bridge across slab edge
	var hi := p_a if p_a.y >= p_b.y else p_b
	var lo := p_b if p_a.y >= p_b.y else p_a
	var dir_to_lo := signf(lo.x - hi.x)
	var bridge_z := hi.x + dir_to_lo * 0.42
	var dz := lo.x - bridge_z
	var dy := hi.y - lo.y
	var seg_len := sqrt(dz * dz + dy * dy)
	var thickness := 0.24
	var rot_x := atan2(dy, dz) if dz >= 0.0 else -atan2(dy, -dz)
	var normal := Vector3(0.0, cos(rot_x), sin(rot_x))
	var mid := Vector3(x_pos, (hi.y + lo.y) * 0.5, (bridge_z + lo.x) * 0.5)

	var sb := StaticBody3D.new()
	sb.name = node_name
	sb.position = mid - normal * (thickness * 0.5)
	sb.rotation.x = rot_x
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(width, thickness, seg_len)
	cs.shape = box
	sb.add_child(cs)
	add_child(sb)

	# Flat collider bridge covering the 90-deg floor lip cleanly across hi.x..bridge_z
	var br_len := 0.56
	var br_sb := StaticBody3D.new()
	br_sb.name = node_name + "_Bridge"
	br_sb.position = Vector3(x_pos, hi.y - 0.08, (hi.x + bridge_z) * 0.5 - dir_to_lo * 0.05)
	var br_cs := CollisionShape3D.new()
	var br_box := BoxShape3D.new()
	br_box.size = Vector3(width, 0.16, br_len)
	br_cs.shape = br_box
	br_sb.add_child(br_cs)
	add_child(br_sb)


func _build_basement_vault() -> void:
	# Expanded 4-Room Underground Complex (Y = -4.0 .. -0.35, X: -19.5 .. +19.0, Z: -8.5 .. +8.5):
	# 1) East Card Club (X:+5.2..+19.0)  2) Central Exhibition Hall with Tripods (X:-6.8..+5.2)
	# 3) NW Wine Cellar (X:-19.5..-6.8, Z:-8.5..0)  4) SW Secret Bank Vault (X:-19.5..-6.8, Z:0..+8.5)
	var stone_floor := _pbr_mat("marble_01", Color(0.28, 0.26, 0.24), Vector3(10.0, 6.0, 1.0), 0.34, 0.05)
	var gallery_floor := _pbr_mat("marble_01", Color(0.68, 0.65, 0.60), Vector3(5.0, 6.0, 1.0), 0.24, 0.08)
	var vault_floor := _pbr_mat("marble_01", Color(0.16, 0.20, 0.22), Vector3(4.0, 4.0, 1.0), 0.26, 0.25)
	var plaster_dark := _pbr_mat("painted_plaster_wall", Color(0.22, 0.12, 0.11), Vector3(5.0, 2.0, 1.0), 0.88)
	var gallery_wall := _pbr_mat("painted_plaster_wall", Color(0.18, 0.23, 0.28), Vector3(5.0, 2.0, 1.0), 0.80)
	var cellar_stone := _pbr_mat("painted_plaster_wall", Color(0.26, 0.21, 0.17), Vector3(4.0, 2.0, 1.0), 0.92)
	var vault_steel := _mat(Color(0.38, 0.42, 0.46), 0.28, 0.88)
	var gold_mat := _mat(Color(0.92, 0.74, 0.22), 0.22, 0.92, Color(0.85, 0.65, 0.16), 0.15)
	var sapphire_mat := _mat(Color(0.16, 0.56, 0.98), 0.10, 0.3, Color(0.18, 0.62, 1.0), 1.4)
	var dark_walnut := _pbr_mat("american_walnut_veneer", Color(0.34, 0.22, 0.15), Vector3(3.0, 2.0, 1.0), 0.48)
	var oak_mat := _pbr_mat("american_walnut_veneer", Color(0.48, 0.32, 0.19), Vector3(2.0, 2.0, 1.0), 0.58)
	var bronze_mat := _mat(Color(0.56, 0.43, 0.20), 0.34, 0.86)
	var baize_mat := _textile_mat(null, Color(0.06, 0.24, 0.13), Vector3(4.0, 4.0, 1.0), 0.90)
	var leather_mat := _pbr_mat("fabric_leather_02", Color(0.28, 0.12, 0.10), Vector3(4.0, 2.0, 1.0), 0.52)
	var runner_mat := _textile_mat(null, Color(0.30, 0.04, 0.06), Vector3(4.0, 4.0, 1.0), 0.92)

	# Full Continuous Basement Floor & Non-Overlapping Ceiling (cutout strictly for East Wing stairwell!)
	_add_box_body(self, Vector3(39.2, 0.4, 17.6), Vector3(-0.25, -4.2, 0.0), stone_floor, true)
	_add_box_body(self, Vector3(12.0, 0.02, 16.8), Vector3(-0.8, -3.99, 0.0), gallery_floor, false)
	_add_box_body(self, Vector3(12.4, 0.02, 8.2), Vector3(-13.1, -3.99, 4.2), vault_floor, false)
	_add_box_body(self, Vector3(31.2, 0.30, 17.4), Vector3(-4.0, -0.25, 0.0), dark_walnut, true)
	_add_box_body(self, Vector3(7.6, 0.30, 6.5), Vector3(15.4, -0.25, -5.45), dark_walnut, true)
	_add_box_body(self, Vector3(7.6, 0.30, 2.3), Vector3(15.4, -0.25, 7.55), dark_walnut, true)
	_add_box_body(self, Vector3(1.8, 0.30, 8.6), Vector3(18.3, -0.25, 2.1), dark_walnut, true)

	# Outer Underground Perimeter Walls
	_add_box_body(self, Vector3(39.2, 3.8, 0.4), Vector3(-0.25, -2.1, -8.5), plaster_dark, true)
	_add_box_body(self, Vector3(39.2, 3.8, 0.4), Vector3(-0.25, -2.1, 8.5), plaster_dark, true)
	_add_box_body(self, Vector3(0.4, 3.8, 17.6), Vector3(-19.5, -2.1, 0.0), gallery_wall, true)
	_add_box_body(self, Vector3(0.4, 3.8, 17.6), Vector3(19.0, -2.1, 0.0), plaster_dark, true)

	# Partition 1: Card Club <-> Exhibition Hall at X=+5.2 (open doorway Z:+1.8..+5.4)
	_add_box_body(self, Vector3(0.42, 3.8, 10.3), Vector3(5.2, -2.1, -3.35), plaster_dark, true)
	_add_box_body(self, Vector3(0.42, 3.8, 3.1), Vector3(5.2, -2.1, 6.95), plaster_dark, true)
	_add_box_body(self, Vector3(0.42, 0.9, 3.6), Vector3(5.2, -0.75, 3.6), plaster_dark, true)
	_add_box_body(self, Vector3(0.50, 3.1, 0.22), Vector3(5.2, -2.45, 1.78), bronze_mat, false)
	_add_box_body(self, Vector3(0.50, 3.1, 0.22), Vector3(5.2, -2.45, 5.42), bronze_mat, false)
	_add_box_body(self, Vector3(0.52, 0.20, 3.85), Vector3(5.2, -0.95, 3.6), bronze_mat, false)

	# Partition 2: Exhibition Hall <-> West Chambers (Wine Cellar N, Secret Vault S) at X=-6.8
	_add_box_body(self, Vector3(0.42, 3.8, 2.7), Vector3(-6.8, -2.1, -7.15), gallery_wall, true)
	_add_box_body(self, Vector3(0.42, 3.8, 5.0), Vector3(-6.8, -2.1, 0.0), gallery_wall, true)
	_add_box_body(self, Vector3(0.42, 3.8, 2.7), Vector3(-6.8, -2.1, 7.15), gallery_wall, true)
	_add_box_body(self, Vector3(0.42, 0.9, 3.4), Vector3(-6.8, -0.75, -4.15), gallery_wall, true)
	_add_box_body(self, Vector3(0.42, 0.9, 3.4), Vector3(-6.8, -0.75, 4.15), gallery_wall, true)
	# Wine Cellar Arch Frame (-6.8, -4.15)
	_add_box_body(self, Vector3(0.50, 3.1, 0.20), Vector3(-6.8, -2.45, -5.85), dark_walnut, false)
	_add_box_body(self, Vector3(0.50, 3.1, 0.20), Vector3(-6.8, -2.45, -2.45), dark_walnut, false)
	_add_box_body(self, Vector3(0.52, 0.20, 3.65), Vector3(-6.8, -0.95, -4.15), bronze_mat, false)
	# Secret Vault Heavy Steel Arch Frame + Open Vault Door (-6.8, +4.15)
	_add_box_body(self, Vector3(0.54, 3.15, 0.28), Vector3(-6.8, -2.42, 2.45), vault_steel, false)
	_add_box_body(self, Vector3(0.54, 3.15, 0.28), Vector3(-6.8, -2.42, 5.85), vault_steel, false)
	_add_box_body(self, Vector3(0.56, 0.28, 3.70), Vector3(-6.8, -0.90, 4.15), vault_steel, false)
	var vdoor_m := CylinderMesh.new(); vdoor_m.top_radius = 1.42; vdoor_m.bottom_radius = 1.42; vdoor_m.height = 0.24
	var vdoor_mi := MeshInstance3D.new(); vdoor_mi.mesh = vdoor_m; vdoor_mi.material_override = vault_steel
	vdoor_mi.position = Vector3(-7.9, -2.50, 2.05); vdoor_mi.rotation = Vector3(PI * 0.5, 0.45, 0.0)
	add_child(vdoor_mi)

	# Partition 3: Wine Cellar <-> Vault connecting doorway at Z=0.0 (X:-19.5..-6.8, archway X:-16..-13)
	_add_box_body(self, Vector3(6.2, 3.8, 0.40), Vector3(-9.9, -2.1, 0.0), cellar_stone, true)
	_add_box_body(self, Vector3(3.3, 3.8, 0.40), Vector3(-17.85, -2.1, 0.0), cellar_stone, true)
	_add_box_body(self, Vector3(3.2, 0.9, 0.40), Vector3(-14.6, -0.75, 0.0), cellar_stone, true)
	_add_box_body(self, Vector3(0.22, 3.1, 0.48), Vector3(-13.0, -2.45, 0.0), vault_steel, false)
	_add_box_body(self, Vector3(0.22, 3.1, 0.48), Vector3(-16.2, -2.45, 0.0), vault_steel, false)

	# --- ROOM 1: CARD CLUB DETAILS (X:+5.2..+19.0) ---
	_add_box_body(self, Vector3(6.8, 0.025, 7.6), Vector3(10.0, -3.99, 0.0), runner_mat, false)
	_add_box_body(self, Vector3(0.4, 0.72, 0.4), Vector3(8.8, -3.64, -1.0), dark_walnut, true)
	_add_box_body(self, Vector3(2.8, 0.12, 1.5), Vector3(8.8, -3.22, -1.0), dark_walnut, true)
	_add_box_body(self, Vector3(2.5, 0.04, 1.2), Vector3(8.8, -3.14, -1.0), baize_mat, false)
	for sx in [-1.5, 1.5]:
		_add_box_body(self, Vector3(0.55, 0.42, 0.55), Vector3(8.8 + sx, -3.79, -1.0), leather_mat, true)
	for sz in [-1.05, 1.05]:
		_add_box_body(self, Vector3(0.55, 0.42, 0.55), Vector3(8.8, -3.79, -1.0 + sz), leather_mat, true)

	for bz in [-6.0, -4.4, 4.4, 6.0]:
		var brl := CylinderMesh.new(); brl.top_radius = 0.34; brl.bottom_radius = 0.34; brl.height = 0.92
		var bmi := MeshInstance3D.new(); bmi.mesh = brl; bmi.material_override = dark_walnut; bmi.position = Vector3(17.8, -3.54, bz)
		add_child(bmi)
		_add_box_body(self, Vector3(0.75, 0.92, 0.75), Vector3(17.8, -3.54, bz), dark_walnut, true).visible = false

	var lbl_club := Label3D.new()
	lbl_club.text = "♠ КАРТКОВИЙ КЛУБ ♣  |  ◀ ВИСТАВОЧНИЙ ЗАЛ"
	lbl_club.position = Vector3(10.0, -0.68, -8.20)
	lbl_club.pixel_size = 0.0044; lbl_club.font_size = 38; lbl_club.modulate = Color(0.95, 0.80, 0.38)
	add_child(lbl_club)

	var ab := StaticBody3D.new(); ab.collision_layer = 2; ab.collision_mask = 0
	var ped_m := CylinderMesh.new(); ped_m.top_radius = 0.14; ped_m.bottom_radius = 0.16; ped_m.height = 0.90
	var pm_d := MeshInstance3D.new(); pm_d.mesh = ped_m; pm_d.material_override = bronze_mat; pm_d.position = Vector3(8.8, -3.55, 0.35); add_child(pm_d)
	var btn_m := SphereMesh.new(); btn_m.radius = 0.14
	var btn_mat := _mat(Color(0.95, 0.12, 0.14), 0.25, 0.2, Color(0.98, 0.16, 0.18), 1.6)
	var bm_d := MeshInstance3D.new(); bm_d.mesh = btn_m; bm_d.material_override = btn_mat; bm_d.position = Vector3(8.8, -3.05, 0.35); add_child(bm_d)
	var dcs := CollisionShape3D.new(); var dbox := BoxShape3D.new(); dbox.size = Vector3(0.8, 1.3, 0.8); dcs.shape = dbox; ab.position = Vector3(8.8, -3.15, 0.35); ab.add_child(dcs)
	ab.set_meta("interact_id", "disco_button"); ab.set_meta("interact_title", "НЕ ТИСНУТИ! (Таємний диско-режим)")
	add_child(ab)

	# --- ROOM 2: CENTRAL EXHIBITION HALL WITH TRIPODS (X:-6.8..+5.2) ---
	_add_box_body(self, Vector3(2.8, 0.025, 13.8), Vector3(-0.8, -3.975, 0.0), runner_mat, false)
	var lbl_ex := Label3D.new()
	lbl_ex.text = "★ ВИСТАВОЧНИЙ ЗАЛ З ТРИНОГАМИ • 2048 • ЗУМА • ПАЗЛИ ★"
	lbl_ex.position = Vector3(-0.8, -0.68, -8.20)
	lbl_ex.pixel_size = 0.0044; lbl_ex.font_size = 38; lbl_ex.modulate = Color(0.98, 0.86, 0.45)
	add_child(lbl_ex)
	var lbl_west_w := Label3D.new()
	lbl_west_w.text = "◀ ВИННИЙ ПОГРІБ (ПІВНІЧ)   |   ТАЄМНЕ СХОВИЩЕ (ПІВДЕНЬ) ▶"
	lbl_west_w.position = Vector3(-6.45, -0.78, 0.0); lbl_west_w.rotation.y = PI * 0.5
	lbl_west_w.pixel_size = 0.0040; lbl_west_w.font_size = 32; lbl_west_w.modulate = Color(0.94, 0.84, 0.52)
	add_child(lbl_west_w)

	# Velvet Museum Stanchions flanking central gallery runner
	var post_m := CylinderMesh.new(); post_m.top_radius = 0.035; post_m.bottom_radius = 0.09; post_m.height = 0.92
	var rope_m := CylinderMesh.new(); rope_m.top_radius = 0.025; rope_m.bottom_radius = 0.025; rope_m.height = 2.6
	for px: float in [-2.1, 0.5]:
		for pz: float in [-2.6, 0.0, 2.6]:
			var ps := MeshInstance3D.new(); ps.mesh = post_m; ps.material_override = bronze_mat; ps.position = Vector3(px, -3.54, pz); add_child(ps)
		for rz: float in [-1.3, 1.3]:
			var rm := MeshInstance3D.new(); rm.mesh = rope_m; rm.material_override = runner_mat; rm.position = Vector3(px, -3.22, rz); rm.rotation.x = PI * 0.5; add_child(rm)

	# Central Relic #1: Golden Casino Trophy Cup on Velvet Plinth
	_add_box_body(self, Vector3(0.95, 1.05, 0.95), Vector3(-0.8, -3.47, 0.0), leather_mat, true)
	_add_box_body(self, Vector3(1.05, 0.08, 1.05), Vector3(-0.8, -2.92, 0.0), gold_mat, false)
	var cup_m := CylinderMesh.new(); cup_m.top_radius = 0.24; cup_m.bottom_radius = 0.08; cup_m.height = 0.48
	var cpm := MeshInstance3D.new(); cpm.mesh = cup_m; cpm.material_override = gold_mat; cpm.position = Vector3(-0.8, -2.62, 0.0); add_child(cpm)
	var r1 := StaticBody3D.new(); r1.collision_layer = 2; r1.collision_mask = 0; r1.position = Vector3(-0.8, -2.62, 0.0)
	var r1cs := CollisionShape3D.new(); var r1b := BoxShape3D.new(); r1b.size = Vector3(1.2, 1.4, 1.2); r1cs.shape = r1b; r1.add_child(r1cs)
	r1.set_meta("interact_id", "relic_cup"); r1.set_meta("interact_title", "Оглянути Артефакт #1: Золотий Кубок")
	add_child(r1)

	# --- ROOM 3: WINE CELLAR & TASTING LOUNGE (X:-19.5..-6.8, Z:-8.5..0.0) ---
	var lbl_wine := Label3D.new()
	lbl_wine.text = "🍷 ВИННИЙ ПОГРІБ І ТАВЕРНА 1898 🍷"
	lbl_wine.position = Vector3(-13.0, -0.70, -8.20)
	lbl_wine.pixel_size = 0.0044; lbl_wine.font_size = 38; lbl_wine.modulate = Color(0.96, 0.78, 0.42)
	add_child(lbl_wine)
	var wine_glass := _mat(Color(0.32, 0.06, 0.08), 0.15, 0.2, Color(0.45, 0.05, 0.06), 0.45)
	var btl_m := CylinderMesh.new(); btl_m.top_radius = 0.055; btl_m.bottom_radius = 0.065; btl_m.height = 0.34
	for rx_c: float in [-18.2, -16.0]:
		_add_box_body(self, Vector3(1.8, 2.2, 0.45), Vector3(rx_c, -2.9, -8.0), oak_mat, true)
		for row_y: float in [-3.4, -2.8, -2.2]:
			_add_box_body(self, Vector3(1.7, 0.06, 0.44), Vector3(rx_c, row_y, -7.95), oak_mat, false)
			for bx_i in range(-2, 3):
				var btl := MeshInstance3D.new(); btl.mesh = btl_m; btl.material_override = wine_glass
				btl.position = Vector3(rx_c + float(bx_i) * 0.30, row_y + 0.18, -7.85); btl.rotation.x = PI * 0.35; add_child(btl)
	for cask_z: float in [-6.0, -3.6, -1.6]:
		var cask_m := CylinderMesh.new(); cask_m.top_radius = 0.46; cask_m.bottom_radius = 0.46; cask_m.height = 1.15
		var cmi := MeshInstance3D.new(); cmi.mesh = cask_m; cmi.material_override = oak_mat; cmi.position = Vector3(-18.4, -3.38, cask_z); cmi.rotation.z = PI * 0.5; add_child(cmi)
		_add_box_body(self, Vector3(1.2, 1.0, 1.0), Vector3(-18.4, -3.45, cask_z), oak_mat, true).visible = false
	# Relic #2: Aged Wine Amphora on Tasting Pedestal
	_add_box_body(self, Vector3(0.85, 0.95, 0.85), Vector3(-15.5, -3.52, -4.2), oak_mat, true)
	var amp_m := SphereMesh.new(); amp_m.radius = 0.24
	var amp_mi := MeshInstance3D.new(); amp_mi.mesh = amp_m; amp_mi.material_override = gold_mat; amp_mi.position = Vector3(-15.5, -2.82, -4.2); amp_mi.scale = Vector3(0.9, 1.35, 0.9); add_child(amp_mi)
	var r2 := StaticBody3D.new(); r2.collision_layer = 2; r2.collision_mask = 0; r2.position = Vector3(-15.5, -2.82, -4.2)
	var r2cs := CollisionShape3D.new(); var r2b := BoxShape3D.new(); r2b.size = Vector3(1.2, 1.4, 1.2); r2cs.shape = r2b; r2.add_child(r2cs)
	r2.set_meta("interact_id", "relic_amphora"); r2.set_meta("interact_title", "Оглянути Артефакт #2: Винна Амфора 1898")
	add_child(r2)

	# --- ROOM 4: SECRET TREASURE VAULT (X:-19.5..-6.8, Z:0.0..+8.5) ---
	var lbl_v := Label3D.new()
	lbl_v.text = "💎 ТАЄМНЕ СХОВИЩЕ БАНКУ • СЕЙФ І САПФІР 💎"
	lbl_v.position = Vector3(-13.0, -0.70, 8.20); lbl_v.rotation.y = PI
	lbl_v.pixel_size = 0.0044; lbl_v.font_size = 38; lbl_v.modulate = Color(0.50, 0.92, 1.0)
	add_child(lbl_v)
	# Stacked Gold Bullion Pyramid
	for by in range(3):
		for bx in range(3 - by):
			_add_box_body(self, Vector3(0.46, 0.22, 0.28), Vector3(-18.0 + float(bx) * 0.50 + float(by) * 0.25, -3.88 + float(by) * 0.24, 6.2), gold_mat, false)
	_add_box_body(self, Vector3(1.8, 0.9, 0.8), Vector3(-17.5, -3.55, 6.2), gold_mat, true).visible = false
	# Interactive Bank Safe Cabinet (West wall)
	_add_box_body(self, Vector3(1.1, 1.85, 1.45), Vector3(-18.6, -3.05, 3.6), vault_steel, true)
	var dial_m := CylinderMesh.new(); dial_m.top_radius = 0.22; dial_m.bottom_radius = 0.22; dial_m.height = 0.14
	var dmi := MeshInstance3D.new(); dmi.mesh = dial_m; dmi.material_override = gold_mat; dmi.position = Vector3(-18.0, -2.95, 3.6); dmi.rotation.z = PI * 0.5; add_child(dmi)
	var vsafe := StaticBody3D.new(); vsafe.collision_layer = 2; vsafe.collision_mask = 0; vsafe.position = Vector3(-18.3, -2.95, 3.6)
	var vscs := CollisionShape3D.new(); var vsb := BoxShape3D.new(); vsb.size = Vector3(1.5, 2.0, 1.7); vscs.shape = vsb; vsafe.add_child(vscs)
	vsafe.set_meta("interact_id", "vault_safe"); vsafe.set_meta("interact_title", "Відкрити Сейф Сховища")
	add_child(vsafe)
	# Relic #3: Royal Sapphire Diamond in Glass Display
	_add_box_body(self, Vector3(0.9, 1.05, 0.9), Vector3(-14.0, -3.47, 3.8), vault_steel, true)
	var sap_m := BoxMesh.new(); sap_m.size = Vector3(0.32, 0.32, 0.32)
	var sap_mi := MeshInstance3D.new(); sap_mi.mesh = sap_m; sap_mi.material_override = sapphire_mat; sap_mi.position = Vector3(-14.0, -2.65, 3.8)
	sap_mi.rotation = Vector3(0.6, 0.8, 0.4); add_child(sap_mi)
	var r3 := StaticBody3D.new(); r3.collision_layer = 2; r3.collision_mask = 0; r3.position = Vector3(-14.0, -2.65, 3.8)
	var r3cs := CollisionShape3D.new(); var r3b := BoxShape3D.new(); r3b.size = Vector3(1.2, 1.4, 1.2); r3cs.shape = r3b; r3.add_child(r3cs)
	r3.set_meta("interact_id", "relic_sapphire"); r3.set_meta("interact_title", "Оглянути Артефакт #3: Королівський Сапфір")
	add_child(r3)

	# --- QUEST BOARDS (Upstairs Lobby + Basement Exhibition Hall) ---
	for qb_pos: Array in [[Vector3(-4.4, 0.06, 7.2), 0.35], [Vector3(4.2, -4.0, -6.4), -0.45]]:
		var qp: Vector3 = qb_pos[0]
		var qyaw: float = float(qb_pos[1])
		var qroot := Node3D.new(); qroot.position = qp; qroot.rotation.y = qyaw; add_child(qroot)
		_add_box_body(qroot, Vector3(0.10, 1.65, 0.10), Vector3(-0.62, 0.82, 0.0), dark_walnut, false)
		_add_box_body(qroot, Vector3(0.10, 1.65, 0.10), Vector3(0.62, 0.82, 0.0), dark_walnut, false)
		_add_box_body(qroot, Vector3(1.45, 1.05, 0.09), Vector3(0.0, 1.42, 0.0), bronze_mat, false)
		_add_box_body(qroot, Vector3(1.30, 0.90, 0.11), Vector3(0.0, 1.42, 0.01), _mat(Color(0.10, 0.14, 0.18), 0.6), false)
		var qlbl := Label3D.new()
		qlbl.text = "📜 ДОШКА КВЕСТІВ\n[E] або [Q] — Відкрити"
		qlbl.position = Vector3(0.0, 1.42, 0.08); qlbl.pixel_size = 0.0042; qlbl.font_size = 36; qlbl.modulate = Color(1.0, 0.90, 0.48)
		qroot.add_child(qlbl)
		var qsb := StaticBody3D.new(); qsb.collision_layer = 2; qsb.collision_mask = 0; qsb.position = Vector3(0.0, 1.2, 0.0)
		var qcs := CollisionShape3D.new(); var qb_sh := BoxShape3D.new(); qb_sh.size = Vector3(1.6, 2.0, 0.6); qcs.shape = qb_sh; qsb.add_child(qcs)
		qsb.set_meta("interact_id", "quest_board"); qsb.set_meta("interact_title", "Відкрити Журнал Квестів")
		qroot.add_child(qsb)

	# --- LIGHTING ACROSS ALL 4 BASEMENT ROOMS ---
	var shade_mat := _mat(Color(1.0, 0.90, 0.72), 0.35, 0.0, Color(1.0, 0.80, 0.50), 0.95)
	var stem_mesh := CylinderMesh.new(); stem_mesh.top_radius = 0.028; stem_mesh.bottom_radius = 0.028; stem_mesh.height = 0.24
	var canopy_mesh := CylinderMesh.new(); canopy_mesh.top_radius = 0.14; canopy_mesh.bottom_radius = 0.12; canopy_mesh.height = 0.05
	var shade_cyl := CylinderMesh.new(); shade_cyl.top_radius = 0.12; shade_cyl.bottom_radius = 0.20; shade_cyl.height = 0.12
	var ring_mesh := TorusMesh.new(); ring_mesh.inner_radius = 0.24; ring_mesh.outer_radius = 0.29
	var lamp_specs := [
		[Vector3(8.5, -0.40, -3.6), Color(1.0, 0.84, 0.62), 1.65],
		[Vector3(8.5, -0.40, 3.6), Color(1.0, 0.84, 0.62), 1.65],
		[Vector3(15.2, -0.40, -5.2), Color(1.0, 0.84, 0.62), 1.6],
		[Vector3(15.2, -0.40, 7.5), Color(1.0, 0.84, 0.62), 1.6],
		# Exhibition Hall museum spots
		[Vector3(-0.8, -0.40, -4.4), Color(1.0, 0.95, 0.86), 2.1],
		[Vector3(-0.8, -0.40, 4.4), Color(1.0, 0.95, 0.86), 2.1],
		[Vector3(-3.8, -0.40, 0.0), Color(0.95, 0.94, 1.0), 1.85],
		[Vector3(2.2, -0.40, 0.0), Color(0.95, 0.94, 1.0), 1.85],
		# Wine Cellar & Secret Vault
		[Vector3(-13.0, -0.40, -4.2), Color(1.0, 0.76, 0.44), 1.9],
		[Vector3(-13.0, -0.40, 4.2), Color(0.76, 0.94, 1.0), 2.0]
	]
	for ls in lamp_specs:
		var lp: Vector3 = ls[0]
		var cap := MeshInstance3D.new(); cap.mesh = canopy_mesh; cap.material_override = bronze_mat; cap.position = lp + Vector3(0, -0.02, 0); add_child(cap)
		var stm := MeshInstance3D.new(); stm.mesh = stem_mesh; stm.material_override = bronze_mat; stm.position = lp + Vector3(0, -0.14, 0); add_child(stm)
		var shd := MeshInstance3D.new(); shd.mesh = shade_cyl; shd.material_override = shade_mat; shd.position = lp + Vector3(0, -0.24, 0); add_child(shd)
		var rmi := MeshInstance3D.new(); rmi.mesh = ring_mesh; rmi.material_override = bronze_mat; rmi.position = lp + Vector3(0, -0.25, 0); add_child(rmi)
		var bl := OmniLight3D.new()
		bl.position = lp + Vector3(0, -0.42, 0)
		bl.light_color = ls[1]
		bl.light_energy = float(ls[2]) * 1.40
		bl.omni_range = 16.0
		bl.omni_attenuation = 1.12
		bl.shadow_bias = 0.045
		bl.shadow_blur = 1.5
		bl.shadow_enabled = false
		add_child(bl)
		if absf(lp.x + 0.8) < 0.5 and lp.z > 0.0:
			_arch_shadow_lights.append(bl)

	# Stairwell Wall Sconce mounted cleanly on East wall (illuminates marble steps with NO floating fixtures!)
	_add_box_body(self, Vector3(0.08, 0.24, 0.22), Vector3(18.76, -1.75, 1.8), bronze_mat, false)
	_add_box_body(self, Vector3(0.10, 0.22, 0.14), Vector3(18.68, -1.68, 1.8), shade_mat, false)
	var stair_l := OmniLight3D.new()
	stair_l.position = Vector3(17.9, -1.55, 1.8)
	stair_l.light_color = Color(1.0, 0.86, 0.64)
	stair_l.light_energy = 2.4
	stair_l.omni_range = 13.0
	stair_l.shadow_enabled = false
	add_child(stair_l)


func _build_mansard() -> void:
	# Grand East Staircase ascending from Y=+0.06 to Mansard Roof Loft at Y=+6.80, plus Attic Observatory & West Balcony
	var stone_mat := _pbr_mat("marble_01", Color(0.84, 0.80, 0.74), Vector3(4.0, 4.0, 1.0), 0.35)
	var parquet_mat := _pbr_mat("herringbone_parquet", Color(0.72, 0.58, 0.44), Vector3(6.0, 6.0, 1.0), 0.38, 0.04)
	var walnut_mat := _pbr_mat("american_walnut_veneer", Color(0.56, 0.41, 0.30), Vector3(3.0, 2.0, 1.0), 0.44)
	var dark_walnut := _pbr_mat("american_walnut_veneer", Color(0.32, 0.21, 0.14), Vector3(3.0, 2.0, 1.0), 0.48)
	var roof_slate := _pbr_mat("marble_01", Color(0.20, 0.21, 0.24), Vector3(6.0, 4.0, 1.0), 0.72)
	var bronze_mat := _mat(Color(0.56, 0.43, 0.20), 0.32, 0.88)
	var leather_mat := _pbr_mat("fabric_leather_02", Color(0.32, 0.13, 0.11), Vector3(4.0, 2.0, 1.0), 0.52)
	var runner_mat := _textile_mat(null, Color(0.32, 0.05, 0.07), Vector3(2.5, 10.0, 1.0), 0.90)
	var glass_mat := _mat(Color(0.78, 0.88, 0.95, 0.18), 0.06, 0.15)
	glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var shade_mat := _mat(Color(1.0, 0.90, 0.72), 0.35, 0.0, Color(1.0, 0.80, 0.50), 0.95)

	# 1. East Wing Grand Ascent Stairs (X=18.55, rising from Z=+6.6 Y=0.06 -> Z=-5.6 Y=6.80)
	var m_steps := 22
	var z_start := 6.6
	var z_end := -5.6
	var run_len := (z_start - z_end) / float(m_steps) # ~0.5545m per tread going -Z
	var rise_h := (6.80 - 0.06) / float(m_steps)
	for i in range(m_steps):
		var sy := 0.06 + (float(i) + 0.5) * rise_h
		var sz := z_start - (float(i) + 0.5) * run_len
		_add_box_body(self, Vector3(2.1, rise_h + 0.16, run_len + 0.04), Vector3(18.55, sy - 0.08, sz), stone_mat, false)
		_add_box_body(self, Vector3(1.35, 0.02, run_len + 0.04), Vector3(18.55, sy + rise_h * 0.5 + 0.01, sz), runner_mat, false)
		_add_box_body(self, Vector3(2.12, 0.025, 0.04), Vector3(18.55, sy + rise_h * 0.5 + 0.015, sz + run_len * 0.48), bronze_mat, false)

	_add_stair_ramp_collider("MansardStairRampCollider", 18.55, 2.2, Vector2(-5.64, 6.805), Vector2(6.65, 0.06))

	# Upper Mansard Staircase Sign & Side Railing along stairwell
	var lbl_up := Label3D.new()
	lbl_up.text = "▲ СХОДИ НА МАНСАРДУ • ОБСЕРВАТОРІЯ"
	lbl_up.position = Vector3(18.55, 4.4, 5.2)
	lbl_up.rotation.y = PI
	lbl_up.pixel_size = 0.0045
	lbl_up.font_size = 34
	lbl_up.modulate = Color(1.0, 0.85, 0.42)
	add_child(lbl_up)

	# Upper Deck Guardrails around East Mansard stair cutout ONLY (leave Z:-7.6..-5.2 OPEN for landing exit!)
	_add_box_body(self, Vector3(0.10, 1.0, 6.2), Vector3(17.25, 7.30, -2.1), bronze_mat, true)
	_add_box_body(self, Vector3(2.55, 1.0, 0.10), Vector3(18.55, 7.30, 1.02), bronze_mat, true)
	# Top arrival landing bridging Z=-7.8..-5.6 at Y=6.80 (zero overlap with East North cap!)
	_add_box_body(self, Vector3(2.5, 0.14, 2.2), Vector3(18.55, 6.73, -6.70), parquet_mat, true)

	# 2. Mansard Interior Floor Inlay & Crimson Rug (X:-11.5 .. +17.25, Z:-7.4 .. +7.4)
	_add_box_body(self, Vector3(28.7, 0.03, 14.8), Vector3(2.85, 6.815, 0.0), parquet_mat, false)
	_add_box_body(self, Vector3(14.0, 0.025, 7.6), Vector3(2.0, 6.842, 0.0), runner_mat, false)

	# 3. Sloped Mansard Roof, Panoramic Dormer Windows & Timber A-Frame Trusses (Y=6.80 .. 11.80, >=2.05m headroom everywhere!)
	# Knee walls + continuous panoramic windows along North (Z=-7.6) & South (Z=+7.6)
	for side_z in [-7.6, 7.6]:
		_add_box_body(self, Vector3(31.6, 0.85, 0.28), Vector3(4.1, 7.225, side_z), walnut_mat, true)
		_add_box_body(self, Vector3(31.6, 0.22, 0.32), Vector3(4.1, 8.76, side_z), dark_walnut, true)
		_add_box_body(self, Vector3(31.2, 1.02, 0.06), Vector3(4.1, 8.15, side_z), glass_mat, false)
		for mx in [-11.5, -5.5, 0.5, 6.5, 12.5, 19.7]:
			_add_box_body(self, Vector3(0.24, 2.08, 0.32), Vector3(mx, 7.84, side_z), dark_walnut, true)

	# North & South pitched roof slopes meeting seamlessly at ridge (Z=0.0, Y=11.80)
	var slope_run := 7.85
	var slope_rise := 2.95
	var slope_hyp := sqrt(slope_run * slope_run + slope_rise * slope_rise)
	var pitch_ang := atan2(slope_rise, slope_run) # ~20.6 deg
	for s_dir in [-1.0, 1.0]:
		var rp := Node3D.new()
		rp.position = Vector3(4.1, 8.85 + slope_rise * 0.5, s_dir * slope_run * 0.5)
		rp.rotation.x = s_dir * pitch_ang
		add_child(rp)
		_add_box_body(rp, Vector3(32.2, 0.22, slope_hyp + 0.45), Vector3.ZERO, roof_slate, true)
		_add_box_body(rp, Vector3(31.8, 0.08, slope_hyp), Vector3(0, -0.14, 0), walnut_mat, false)

	# Ridge Beam + Exposed A-frame Rafters inside Mansard
	_add_box_body(self, Vector3(31.8, 0.28, 0.28), Vector3(4.1, 11.66, 0.0), dark_walnut, false)
	for rx in [-10.5, -5.5, -0.5, 4.5, 9.5, 14.5, 17.2]:
		for s_dir in [-1.0, 1.0]:
			var rf := Node3D.new()
			rf.position = Vector3(rx, 8.85 + slope_rise * 0.5 - 0.18, s_dir * slope_run * 0.5)
			rf.rotation.x = s_dir * pitch_ang
			add_child(rf)
			_add_box_body(rf, Vector3(0.22, 0.22, slope_hyp), Vector3.ZERO, dark_walnut, false)

	# East Mansard Gable Wall (X = +19.85, closing off the top of the stairs cleanly!)
	_add_box_body(self, Vector3(0.32, 2.08, 15.2), Vector3(19.85, 7.84, 0.0), walnut_mat, true)
	_add_box_body(self, Vector3(0.32, 1.70, 9.2), Vector3(19.85, 9.75, 0.0), walnut_mat, true)
	_add_box_body(self, Vector3(0.32, 1.15, 4.2), Vector3(19.85, 11.10, 0.0), walnut_mat, true)

	# West Gable Wall (X = -11.5) & East Gable Wall (X = +19.85) with full eave infill + open archway at Z:[-2.2..+2.2]
	_add_box_body(self, Vector3(0.32, 2.08, 5.4), Vector3(-11.5, 7.84, -4.9), walnut_mat, true)
	_add_box_body(self, Vector3(0.32, 2.08, 5.4), Vector3(-11.5, 7.84, 4.9), walnut_mat, true)
	_add_box_body(self, Vector3(0.32, 1.55, 13.4), Vector3(-11.5, 9.62, 0.0), walnut_mat, true)
	_add_box_body(self, Vector3(0.32, 1.15, 7.6), Vector3(-11.5, 10.95, 0.0), walnut_mat, true)
	_add_box_body(self, Vector3(0.40, 2.4, 0.20), Vector3(-11.5, 8.0, -2.2), bronze_mat, false)
	_add_box_body(self, Vector3(0.40, 2.4, 0.20), Vector3(-11.5, 8.0, 2.2), bronze_mat, false)
	# Seal outer East wall band around Y=[6.2..6.85] behind stairs
	_add_box_body(self, Vector3(0.55, 0.72, 18.6), Vector3(20.0, 6.48, 0.0), dark_walnut, true)

	# West Roof Scenic Balcony Terrace (X: -20.6..-11.5, Z: -9.6..+9.6, floor Y=6.80) with OPEN Scenic Balustrades!
	_add_box_body(self, Vector3(0.22, 0.14, 19.2), Vector3(-20.4, 6.87, 0.0), dark_walnut, true)
	_add_box_body(self, Vector3(0.14, 0.08, 19.2), Vector3(-20.4, 7.86, 0.0), bronze_mat, true)
	_add_box_body(self, Vector3(0.14, 1.02, 19.2), Vector3(-20.4, 7.35, 0.0), glass_mat, false)
	for bz in range(-9, 10, 2):
		_add_box_body(self, Vector3(0.16, 1.0, 0.16), Vector3(-20.4, 7.36, float(bz)), bronze_mat, false)
	for side_z in [-9.5, 9.5]:
		_add_box_body(self, Vector3(9.0, 0.14, 0.22), Vector3(-16.0, 6.87, side_z), dark_walnut, true)
		_add_box_body(self, Vector3(9.0, 0.08, 0.14), Vector3(-16.0, 7.86, side_z), bronze_mat, true)
		_add_box_body(self, Vector3(9.0, 1.02, 0.14), Vector3(-16.0, 7.35, side_z), glass_mat, false)
		for bx in [-19, -17, -15, -13, -11.6]:
			_add_box_body(self, Vector3(0.16, 1.0, 0.16), Vector3(float(bx), 7.36, side_z), bronze_mat, false)

	# 4. Cozy Mansard Observatory Furniture, Brass Telescope & Warm Pendant Chandeliers
	_add_box_body(self, Vector3(1.1, 0.45, 3.2), Vector3(4.5, 7.04, 0.0), leather_mat, true)
	_add_box_body(self, Vector3(0.25, 0.55, 3.2), Vector3(4.92, 7.50, 0.0), leather_mat, true)
	_add_box_body(self, Vector3(1.2, 0.48, 2.0), Vector3(1.8, 7.06, 0.0), walnut_mat, true)
	var lbl_mansard := Label3D.new()
	lbl_mansard.text = "★ МАНСАРДА: ГАЛЕРЕЯ ІГОР ТА ПІТОН 3D ★"
	lbl_mansard.position = Vector3(-11.2, 8.88, 0.0)
	lbl_mansard.rotation.y = PI * 0.5
	lbl_mansard.pixel_size = 0.0052
	lbl_mansard.font_size = 38
	lbl_mansard.modulate = Color(1.0, 0.88, 0.48)
	add_child(lbl_mansard)

	# Observatory Brass Telescope / Binoculars on West Balcony (Interactive!)
	var tele_pod := CylinderMesh.new(); tele_pod.top_radius = 0.06; tele_pod.bottom_radius = 0.24; tele_pod.height = 1.25
	var tpm := MeshInstance3D.new(); tpm.mesh = tele_pod; tpm.material_override = dark_walnut; tpm.position = Vector3(-16.5, 7.42, 0.0)
	add_child(tpm)
	var tele_tube := CylinderMesh.new(); tele_tube.top_radius = 0.09; tele_tube.bottom_radius = 0.055; tele_tube.height = 1.45
	var ttm := MeshInstance3D.new(); ttm.mesh = tele_tube; ttm.material_override = bronze_mat
	ttm.position = Vector3(-16.75, 8.15, 0.0); ttm.rotation_degrees = Vector3(0.0, 0.0, 62.0)
	add_child(ttm)
	var tb := StaticBody3D.new(); tb.collision_layer = 2; tb.collision_mask = 0; tb.position = Vector3(-16.6, 7.85, 0.0)
	var tcs := CollisionShape3D.new(); var tbox := BoxShape3D.new(); tbox.size = Vector3(1.6, 1.8, 1.6); tcs.shape = tbox; tb.add_child(tcs)
	tb.set_meta("interact_id", "binoculars"); tb.set_meta("interact_title", "Дивитись у бінокль (локація й гоночна траса)")
	add_child(tb)

	# Mansard Pendant Lights hung from Roof Ridge (Y=11.66)
	var m_rod := CylinderMesh.new(); m_rod.top_radius = 0.025; m_rod.bottom_radius = 0.025; m_rod.height = 1.85
	var m_shd := CylinderMesh.new(); m_shd.top_radius = 0.16; m_shd.bottom_radius = 0.34; m_shd.height = 0.22
	for mx in [-4.5, 3.0, 10.5]:
		var mr := MeshInstance3D.new(); mr.mesh = m_rod; mr.material_override = bronze_mat; mr.position = Vector3(mx, 10.72, 0.0); add_child(mr)
		var ms := MeshInstance3D.new(); ms.mesh = m_shd; ms.material_override = shade_mat; ms.position = Vector3(mx, 9.76, 0.0); add_child(ms)
		var ml := OmniLight3D.new()
		ml.position = Vector3(mx, 9.50, 0.0)
		ml.light_color = Color(1.0, 0.88, 0.68)
		ml.light_energy = 3.45
		ml.omni_range = 18.0
		ml.omni_attenuation = 1.12
		ml.shadow_bias = 0.045
		ml.shadow_blur = 1.5
		add_child(ml)
		if absf(mx - 3.0) < 0.5:
			_arch_shadow_lights.append(ml)


func _build_casino_centerpiece() -> void:
	var table_root := Node3D.new()
	table_root.name = "CasinoRouletteTable"
	table_root.position = Vector3(0.0, 0.0, 0.2)
	add_child(table_root)

	var walnut_mat := _pbr_mat("american_walnut_veneer", Color(0.54, 0.40, 0.30), Vector3(2.0, 2.0, 1.0), 0.36, 0.05)
	var leather_mat := _pbr_mat("fabric_leather_02", Color(0.34, 0.14, 0.11), Vector3(6.0, 2.0, 1.0), 0.52)
	var baize_mat := _textile_mat(null, Color(0.06, 0.24, 0.13), Vector3(5.0, 5.0, 1.0), 0.90)
	var bronze_mat := _mat(Color(0.56, 0.43, 0.20), 0.30, 0.88)
	var red_pocket := _mat(Color(0.58, 0.08, 0.09), 0.45)
	var blk_pocket := _mat(Color(0.06, 0.06, 0.07), 0.45)
	var gold_line := _mat(Color(0.70, 0.56, 0.24), 0.35, 0.70)

	var ped := CylinderMesh.new(); ped.top_radius = 0.52; ped.bottom_radius = 0.84; ped.height = 0.86
	var ped_mi := MeshInstance3D.new(); ped_mi.mesh = ped; ped_mi.material_override = walnut_mat; ped_mi.position = Vector3(0, 0.43, 0)
	table_root.add_child(ped_mi)

	var rim := CylinderMesh.new(); rim.top_radius = 1.84; rim.bottom_radius = 1.78; rim.height = 0.14
	var rim_mi := MeshInstance3D.new(); rim_mi.mesh = rim; rim_mi.material_override = walnut_mat; rim_mi.position = Vector3(0, 0.90, 0)
	table_root.add_child(rim_mi)

	var bumper := TorusMesh.new(); bumper.inner_radius = 1.72; bumper.outer_radius = 1.90
	var bmp_mi := MeshInstance3D.new(); bmp_mi.mesh = bumper; bmp_mi.material_override = leather_mat; bmp_mi.position = Vector3(0, 0.97, 0)
	bmp_mi.scale = Vector3(1.0, 0.65, 1.0)
	table_root.add_child(bmp_mi)

	var felt := CylinderMesh.new(); felt.top_radius = 1.72; felt.bottom_radius = 1.72; felt.height = 0.04
	var felt_mi := MeshInstance3D.new(); felt_mi.mesh = felt; felt_mi.material_override = baize_mat; felt_mi.position = Vector3(0, 0.96, 0)
	table_root.add_child(felt_mi)

	var felt_ring := TorusMesh.new(); felt_ring.inner_radius = 1.12; felt_ring.outer_radius = 1.15
	var fr_mi := MeshInstance3D.new(); fr_mi.mesh = felt_ring; fr_mi.material_override = gold_line; fr_mi.position = Vector3(0, 0.985, 0)
	table_root.add_child(fr_mi)

	var bowl := CylinderMesh.new(); bowl.top_radius = 0.66; bowl.bottom_radius = 0.74; bowl.height = 0.14
	var bowl_mi := MeshInstance3D.new(); bowl_mi.mesh = bowl; bowl_mi.material_override = walnut_mat; bowl_mi.position = Vector3(0, 1.03, 0)
	table_root.add_child(bowl_mi)

	_roulette_wheel = Node3D.new()
	_roulette_wheel.position = Vector3(0, 1.11, 0)
	table_root.add_child(_roulette_wheel)

	var disk := CylinderMesh.new(); disk.top_radius = 0.56; disk.bottom_radius = 0.56; disk.height = 0.04
	var disk_mi := MeshInstance3D.new(); disk_mi.mesh = disk; disk_mi.material_override = bronze_mat
	_roulette_wheel.add_child(disk_mi)

	for p_idx in range(18):
		var pa := float(p_idx) * TAU / 18.0
		var pocket := BoxMesh.new(); pocket.size = Vector3(0.075, 0.025, 0.14)
		var pmi := MeshInstance3D.new(); pmi.mesh = pocket
		pmi.material_override = red_pocket if p_idx % 2 == 0 else blk_pocket
		pmi.position = Vector3(cos(pa) * 0.43, 0.028, sin(pa) * 0.43)
		pmi.rotation.y = -pa
		_roulette_wheel.add_child(pmi)

	for k in range(4):
		var bar := BoxMesh.new(); bar.size = Vector3(0.42, 0.032, 0.032)
		var bar_mi := MeshInstance3D.new(); bar_mi.mesh = bar; bar_mi.material_override = bronze_mat
		bar_mi.position = Vector3(0, 0.065, 0); bar_mi.rotation.y = float(k) * PI * 0.25
		_roulette_wheel.add_child(bar_mi)

	var spire := CylinderMesh.new(); spire.top_radius = 0.018; spire.bottom_radius = 0.085; spire.height = 0.18
	var spire_mi := MeshInstance3D.new(); spire_mi.mesh = spire; spire_mi.material_override = bronze_mat; spire_mi.position = Vector3(0, 0.11, 0)
	_roulette_wheel.add_child(spire_mi)

	var chip_cols := [Color(0.55, 0.12, 0.14), Color(0.14, 0.24, 0.45), Color(0.66, 0.54, 0.24), Color(0.14, 0.14, 0.16)]
	for i in range(8):
		var ang := float(i) * TAU / 8.0 + 0.22
		var stack_h := 0.045 + float(i % 3) * 0.022
		var chip := CylinderMesh.new(); chip.top_radius = 0.042; chip.bottom_radius = 0.042; chip.height = stack_h
		var cm := MeshInstance3D.new(); cm.mesh = chip; cm.material_override = _mat(chip_cols[i % chip_cols.size()], 0.65)
		cm.position = Vector3(cos(ang) * 1.32, 0.985 + stack_h * 0.5, sin(ang) * 1.32)
		table_root.add_child(cm)

	var stool_post := CylinderMesh.new(); stool_post.top_radius = 0.038; stool_post.bottom_radius = 0.045; stool_post.height = 0.64
	var stool_base := CylinderMesh.new(); stool_base.top_radius = 0.22; stool_base.bottom_radius = 0.26; stool_base.height = 0.045
	var foot_ring := TorusMesh.new(); foot_ring.inner_radius = 0.19; foot_ring.outer_radius = 0.215
	var stool_shell := CylinderMesh.new(); stool_shell.top_radius = 0.255; stool_shell.bottom_radius = 0.235; stool_shell.height = 0.055
	var stool_cushion := CylinderMesh.new(); stool_cushion.top_radius = 0.235; stool_cushion.bottom_radius = 0.250; stool_cushion.height = 0.085
	var back_pad := BoxMesh.new(); back_pad.size = Vector3(0.42, 0.22, 0.08)

	for s_idx in range(4):
		var sa := float(s_idx) * TAU / 4.0 + 0.78
		var stool := Node3D.new()
		stool.position = Vector3(cos(sa) * 2.38, 0.0, sin(sa) * 2.38)
		stool.rotation.y = atan2(-cos(sa), -sin(sa))
		table_root.add_child(stool)
		var sba := MeshInstance3D.new(); sba.mesh = stool_base; sba.material_override = bronze_mat; sba.position = Vector3(0, 0.022, 0)
		var sp := MeshInstance3D.new(); sp.mesh = stool_post; sp.material_override = bronze_mat; sp.position = Vector3(0, 0.34, 0)
		var fr := MeshInstance3D.new(); fr.mesh = foot_ring; fr.material_override = bronze_mat; fr.position = Vector3(0, 0.24, 0)
		var sh := MeshInstance3D.new(); sh.mesh = stool_shell; sh.material_override = walnut_mat; sh.position = Vector3(0, 0.66, 0)
		var sc := MeshInstance3D.new(); sc.mesh = stool_cushion; sc.material_override = leather_mat; sc.position = Vector3(0, 0.72, 0)
		var bp := MeshInstance3D.new(); bp.mesh = back_pad; bp.material_override = leather_mat; bp.position = Vector3(0, 0.87, -0.22)
		var bbw := BoxMesh.new(); bbw.size = Vector3(0.45, 0.24, 0.04)
		var bwm := MeshInstance3D.new(); bwm.mesh = bbw; bwm.material_override = walnut_mat; bwm.position = Vector3(0, 0.87, -0.26)
		stool.add_child(sba); stool.add_child(sp); stool.add_child(fr); stool.add_child(sh); stool.add_child(sc); stool.add_child(bp); stool.add_child(bwm)

	var sb := StaticBody3D.new()
	sb.collision_layer = 3
	sb.collision_mask = 0
	var cs := CollisionShape3D.new()
	var cyl := CylinderShape3D.new(); cyl.radius = 2.0; cyl.height = 1.3
	cs.shape = cyl; cs.position = Vector3(0, 0.65, 0)
	sb.add_child(cs)
	sb.set_meta("interact_id", "roulette_spin")
	sb.set_meta("interact_title", "Крутнути рулетку")
	table_root.add_child(sb)


func _build_casino_luxury_props() -> void:
	var bronze_mat := _mat(Color(0.56, 0.43, 0.20), 0.32, 0.88)
	var walnut_mat := _pbr_mat("american_walnut_veneer", Color(0.52, 0.38, 0.28), Vector3(2.0, 2.0, 1.0), 0.38, 0.05)
	var chrome_mat := _mat(Color(0.76, 0.78, 0.82), 0.18, 0.92)
	var cord_mat := _textile_mat(null, Color(0.36, 0.05, 0.07), Vector3(2.0, 6.0, 1.0), 0.86)
	var reel_glow := _mat(Color(0.95, 0.90, 0.76), 0.25, 0.0, Color(0.95, 0.82, 0.48), 0.85)
	var header_glow := _mat(Color(0.85, 0.24, 0.20), 0.25, 0.0, Color(0.85, 0.20, 0.16), 0.95)

	var slot_ids := ["slot_left", "slot_right"]
	for idx_s: int in range(2):
		var sx: float = -5.8 if idx_s == 0 else 5.8
		var slot := Node3D.new()
		slot.position = Vector3(sx, 0.0, 7.2)
		slot.rotation.y = PI
		add_child(slot)
		_add_box_body(slot, Vector3(0.92, 1.90, 0.70), Vector3(0, 0.95, 0), walnut_mat, true)
		_add_box_body(slot, Vector3(0.98, 0.08, 0.74), Vector3(0, 1.92, 0), bronze_mat, false)
		_add_box_body(slot, Vector3(0.76, 0.46, 0.06), Vector3(0, 1.34, 0.35), reel_glow, false)
		_add_box_body(slot, Vector3(0.78, 0.30, 0.06), Vector3(0, 1.74, 0.35), header_glow, false)
		var lever_pivot := Node3D.new(); lever_pivot.position = Vector3(0.52, 1.02, 0.0); slot.add_child(lever_pivot)
		var lever := CylinderMesh.new(); lever.top_radius = 0.022; lever.bottom_radius = 0.022; lever.height = 0.52
		var lmi := MeshInstance3D.new(); lmi.mesh = lever; lmi.material_override = chrome_mat; lmi.position = Vector3(0.0, 0.24, 0.05); lmi.rotation_degrees.x = -22.0
		lever_pivot.add_child(lmi)
		var knob := SphereMesh.new(); knob.radius = 0.055
		var kmi := MeshInstance3D.new(); kmi.mesh = knob; kmi.material_override = cord_mat; kmi.position = Vector3(0.0, 0.50, 0.15)
		lever_pivot.add_child(kmi)
		_slot_levers.append(lever_pivot)
		var slb := StaticBody3D.new(); slb.collision_layer = 2; slb.collision_mask = 0; slb.position = Vector3(0, 1.25, 0.25)
		var scs := CollisionShape3D.new(); var sbox := BoxShape3D.new(); sbox.size = Vector3(1.15, 1.8, 0.9); scs.shape = sbox; slb.add_child(scs)
		slb.set_meta("interact_id", slot_ids[idx_s]); slb.set_meta("interact_title", "Крутнути гральний автомат")
		slot.add_child(slb)

	var post_mesh := CylinderMesh.new(); post_mesh.top_radius = 0.030; post_mesh.bottom_radius = 0.032; post_mesh.height = 0.90
	var base_mesh := CylinderMesh.new(); base_mesh.top_radius = 0.13; base_mesh.bottom_radius = 0.15; base_mesh.height = 0.04
	var cap_mesh := CylinderMesh.new(); cap_mesh.top_radius = 0.042; cap_mesh.bottom_radius = 0.034; cap_mesh.height = 0.045
	var rope_mesh := CylinderMesh.new(); rope_mesh.top_radius = 0.020; rope_mesh.bottom_radius = 0.020; rope_mesh.height = 2.2
	for side_x in [-2.65, 2.65]:
		for pz in [6.0, 8.2]:
			var pmi := MeshInstance3D.new(); pmi.mesh = post_mesh; pmi.material_override = bronze_mat; pmi.position = Vector3(side_x, 0.45, pz)
			var bmi := MeshInstance3D.new(); bmi.mesh = base_mesh; bmi.material_override = bronze_mat; bmi.position = Vector3(side_x, 0.02, pz)
			var cmi := MeshInstance3D.new(); cmi.mesh = cap_mesh; cmi.material_override = bronze_mat; cmi.position = Vector3(side_x, 0.92, pz)
			add_child(pmi); add_child(bmi); add_child(cmi)
		var rmi := MeshInstance3D.new(); rmi.mesh = rope_mesh; rmi.material_override = cord_mat
		rmi.position = Vector3(side_x, 0.74, 7.1)
		rmi.rotation_degrees.x = 90.0
		add_child(rmi)


func _build_chandeliers() -> void:
	var bronze_mat := _mat(Color(0.45, 0.34, 0.16), 0.34, 0.88)
	var shade_mat := _mat(Color(0.98, 0.91, 0.76), 0.55, 0.0, Color(0.98, 0.82, 0.54), 0.78)
	var crystal_mat := _mat(Color(0.90, 0.94, 0.98, 0.45), 0.06, 0.15)
	crystal_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	for cz in [-3.0, 3.0]:
		var ch := Node3D.new()
		ch.position = Vector3(0.0, 5.90, cz)
		add_child(ch)

		var rod := CylinderMesh.new(); rod.top_radius = 0.032; rod.bottom_radius = 0.032; rod.height = 1.25
		var rmi := MeshInstance3D.new(); rmi.mesh = rod; rmi.material_override = bronze_mat; rmi.position = Vector3(0, -0.35, 0)
		ch.add_child(rmi)

		var ring_outer := TorusMesh.new(); ring_outer.inner_radius = 0.84; ring_outer.outer_radius = 0.92
		var ro_mi := MeshInstance3D.new(); ro_mi.mesh = ring_outer; ro_mi.material_override = bronze_mat; ro_mi.position = Vector3(0, -0.92, 0)
		ch.add_child(ro_mi)

		var ring_inner := TorusMesh.new(); ring_inner.inner_radius = 0.42; ring_inner.outer_radius = 0.48
		var ri_mi := MeshInstance3D.new(); ri_mi.mesh = ring_inner; ri_mi.material_override = bronze_mat; ri_mi.position = Vector3(0, -1.20, 0)
		ch.add_child(ri_mi)

		var shade_mesh := CylinderMesh.new(); shade_mesh.top_radius = 0.045; shade_mesh.bottom_radius = 0.075; shade_mesh.height = 0.15
		var drop_mesh := CylinderMesh.new(); drop_mesh.top_radius = 0.016; drop_mesh.bottom_radius = 0.004; drop_mesh.height = 0.12
		for b in range(8):
			var a := float(b) * TAU / 8.0
			var smi := MeshInstance3D.new(); smi.mesh = shade_mesh; smi.material_override = shade_mat
			smi.position = Vector3(cos(a) * 0.88, -0.78, sin(a) * 0.88)
			ch.add_child(smi)
			var cmi := MeshInstance3D.new(); cmi.mesh = drop_mesh; cmi.material_override = crystal_mat
			cmi.position = Vector3(cos(a) * 0.88, -1.03, sin(a) * 0.88)
			ch.add_child(cmi)

		var light := OmniLight3D.new()
		light.position = Vector3(0, -1.25, 0)
		light.light_color = Color(1.0, 0.88, 0.70)
		light.light_energy = 3.65
		light.omni_range = 20.0
		light.omni_attenuation = 1.15
		light.shadow_bias = 0.045
		light.shadow_blur = 1.5
		ch.add_child(light)
		_disco_lights.append(light)
		_arch_shadow_lights.append(light)


func _build_all_paintings() -> void:
	var bronze_mat := _mat(Color(0.54, 0.41, 0.19), 0.34, 0.86)
	var walnut_mat := _pbr_mat("american_walnut_veneer", Color(0.45, 0.32, 0.24), Vector3(1.5, 1.5, 1.0), 0.45)
	var painting_shader := load("res://shaders/painting_canvas.gdshader") as Shader

	for spec in PAINTING_SPECS:
		var p_node := Node3D.new()
		p_node.name = "Painting_" + str(spec["id"])
		p_node.position = spec["pos"] as Vector3
		p_node.rotation.y = float(spec["yaw"])
		add_child(p_node)

		var frame_w := 2.78
		var frame_h := 1.88
		var bar_t := 0.14
		_add_box_body(p_node, Vector3(frame_w, bar_t, 0.12), Vector3(0, frame_h * 0.5, 0.04), bronze_mat, false)
		_add_box_body(p_node, Vector3(frame_w, bar_t, 0.12), Vector3(0, -frame_h * 0.5, 0.04), bronze_mat, false)
		_add_box_body(p_node, Vector3(bar_t, frame_h, 0.12), Vector3(-frame_w * 0.5, 0, 0.04), bronze_mat, false)
		_add_box_body(p_node, Vector3(bar_t, frame_h, 0.12), Vector3(frame_w * 0.5, 0, 0.04), bronze_mat, false)
		_add_box_body(p_node, Vector3(frame_w - 0.18, frame_h - 0.18, 0.05), Vector3(0, 0, 0.01), walnut_mat, false)

		var highlight_mat := _mat(Color(0.85, 0.68, 0.30), 0.25, 0.8, Color(0.95, 0.78, 0.34), 0.0)
		var rim_mesh := BoxMesh.new(); rim_mesh.size = Vector3(frame_w + 0.08, frame_h + 0.08, 0.04)
		var rim_mi := MeshInstance3D.new()
		rim_mi.mesh = rim_mesh; rim_mi.material_override = highlight_mat; rim_mi.position = Vector3(0, 0, -0.01)
		p_node.add_child(rim_mi)

		_add_box_body(p_node, Vector3(0.95, 0.045, 0.06), Vector3(0, frame_h * 0.5 + 0.18, 0.24), bronze_mat, false)

		var vp := SubViewport.new()
		vp.size = Vector2i(256, 160)
		vp.render_target_update_mode = SubViewport.UPDATE_ONCE
		vp.transparent_bg = false
		p_node.add_child(vp)

		var drawer := PaintingCanvasDrawer.new()
		drawer.game_id = str(spec["id"])
		drawer.custom_minimum_size = Vector2(256, 160)
		drawer.size = Vector2(256, 160)
		vp.add_child(drawer)

		var canvas_mat := ShaderMaterial.new()
		canvas_mat.shader = painting_shader
		canvas_mat.set_shader_parameter("canvas_tex", vp.get_texture())
		canvas_mat.set_shader_parameter("color_mix", 0.0)
		canvas_mat.set_shader_parameter("blur_amount", 2.2)
		canvas_mat.set_shader_parameter("emission_strength", 0.38)

		var canvas_quad := QuadMesh.new()
		canvas_quad.size = Vector2(2.44, 1.54)
		var canvas_mi := MeshInstance3D.new()
		canvas_mi.mesh = canvas_quad; canvas_mi.material_override = canvas_mat; canvas_mi.position = Vector3(0, 0, 0.05)
		p_node.add_child(canvas_mi)

		_add_box_body(p_node, Vector3(1.26, 0.22, 0.04), Vector3(0, -1.16, 0.03), bronze_mat, false)
		var lbl3d := Label3D.new()
		lbl3d.text = str(spec["title"])
		lbl3d.position = Vector3(0, -1.16, 0.06)
		lbl3d.pixel_size = 0.0045
		lbl3d.font_size = 34
		lbl3d.modulate = Color(0.12, 0.07, 0.02)
		lbl3d.outline_size = 0
		p_node.add_child(lbl3d)

		var lamp := OmniLight3D.new()
		lamp.position = Vector3(0, 1.08, 0.42)
		lamp.light_color = Color(1.0, 0.88, 0.70)
		lamp.light_energy = 0.52
		lamp.omni_range = 3.8
		lamp.shadow_enabled = false
		p_node.add_child(lamp)

		var area := StaticBody3D.new()
		area.collision_layer = 2
		area.collision_mask = 0
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new(); bs.size = Vector3(2.85, 2.0, 0.25)
		cs.shape = bs
		area.add_child(cs)
		area.set_meta("painting_id", str(spec["id"]))
		p_node.add_child(area)

		if bool(spec.get("easel", false)):
			var oak := _pbr_mat("american_walnut_veneer", Color(0.46, 0.30, 0.18), Vector3(1.0, 2.0, 1.0), 0.50)
			# Solid oak A-frame Artist Tripod ("тринога") reaching down to Basement floor (-4.0, -1.72 local)
			for side_x: float in [-0.52, 0.52]:
				var leg := Node3D.new()
				leg.position = Vector3(side_x * 0.72, -0.78, -0.04)
				leg.rotation = Vector3(-0.08, 0.0, side_x * 0.20)
				_add_box_body(leg, Vector3(0.08, 2.02, 0.08), Vector3.ZERO, oak, false)
				p_node.add_child(leg)
			var back_leg := Node3D.new()
			back_leg.position = Vector3(0.0, -0.62, -0.44)
			back_leg.rotation.x = -0.34
			_add_box_body(back_leg, Vector3(0.08, 2.38, 0.08), Vector3.ZERO, oak, false)
			p_node.add_child(back_leg)
			_add_box_body(p_node, Vector3(2.15, 0.09, 0.18), Vector3(0.0, -0.98, 0.04), oak, false)
			_add_box_body(p_node, Vector3(0.26, 0.14, 0.14), Vector3(0.0, 1.02, 0.02), bronze_mat, false)
			# Floor collider so player walks cleanly around tripods without blocking Layer-2 raycast
			var f_sb := StaticBody3D.new(); f_sb.collision_layer = 1; f_sb.position = Vector3(0.0, -1.10, -0.20)
			var f_cs := CollisionShape3D.new(); var f_b := BoxShape3D.new(); f_b.size = Vector3(1.4, 1.2, 0.85); f_cs.shape = f_b; f_sb.add_child(f_cs)
			p_node.add_child(f_sb)

		paintings.append({
			"id": str(spec["id"]),
			"title": str(spec["title"]),
			"node": p_node,
			"collider": area,
			"highlight_mat": highlight_mat,
			"canvas_mat": canvas_mat,
			"viewport": vp
		})
		_preview_drawer_nodes.append({"drawer": drawer, "vp": vp})


func _build_roof_searchlights() -> void:
	var housing_mat := _mat(Color(0.18, 0.18, 0.20), 0.35, 0.85)
	var lens_mat := _mat(Color(1.0, 0.96, 0.80), 0.1, 0.0, Color(1.0, 0.92, 0.65), 3.0)
	var beam_shader := load("res://shaders/searchlight_beam.gdshader") as Shader

	var roof_configs := [
		{"pos": Vector3(-18.2, 6.80, -7.8), "color": Color(1.0, 0.92, 0.66), "speed_x": 0.65, "speed_y": 0.42, "phase": 0.0},
		{"pos": Vector3(0.0, 11.82, 0.0), "color": Color(0.75, 0.92, 1.0), "speed_x": 0.52, "speed_y": 0.58, "phase": 2.1},
		{"pos": Vector3(-18.2, 6.80, 7.8), "color": Color(1.0, 0.84, 0.56), "speed_x": 0.72, "speed_y": 0.36, "phase": 4.2}
	]

	var cone_mesh := CylinderMesh.new()
	cone_mesh.top_radius = 7.5
	cone_mesh.bottom_radius = 0.35
	cone_mesh.height = 70.0
	cone_mesh.radial_segments = 16
	cone_mesh.cap_top = false
	cone_mesh.cap_bottom = false

	for idx in range(roof_configs.size()):
		var cfg: Dictionary = roof_configs[idx]
		var base := Node3D.new()
		base.name = "RoofSearchlight_%d" % idx
		base.position = cfg["pos"]
		add_child(base)

		var ped := CylinderMesh.new(); ped.top_radius = 0.35; ped.bottom_radius = 0.45; ped.height = 0.45
		var pmi := MeshInstance3D.new(); pmi.mesh = ped; pmi.material_override = housing_mat
		base.add_child(pmi)

		var turret := Node3D.new()
		turret.position = Vector3(0, 0.35, 0)
		base.add_child(turret)

		var drum := CylinderMesh.new(); drum.top_radius = 0.38; drum.bottom_radius = 0.36; drum.height = 0.65
		var dmi := MeshInstance3D.new(); dmi.mesh = drum; dmi.material_override = housing_mat; dmi.position = Vector3(0, 0.2, 0)
		turret.add_child(dmi)

		var lens := CylinderMesh.new(); lens.top_radius = 0.34; lens.bottom_radius = 0.34; lens.height = 0.06
		var lmi := MeshInstance3D.new(); lmi.mesh = lens; lmi.material_override = lens_mat; lmi.position = Vector3(0, 0.53, 0)
		turret.add_child(lmi)

		var beam_mat := ShaderMaterial.new()
		beam_mat.shader = beam_shader
		beam_mat.set_shader_parameter("beam_color", cfg["color"])
		beam_mat.set_shader_parameter("intensity", 0.35)

		var beam := MeshInstance3D.new()
		beam.mesh = cone_mesh
		beam.material_override = beam_mat
		beam.position = Vector3(0, 35.4, 0)
		beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		turret.add_child(beam)

		var spot := SpotLight3D.new()
		spot.position = Vector3(0, 0.6, 0)
		spot.rotation_degrees.x = 90.0
		spot.light_color = cfg["color"]
		spot.light_energy = 5.0
		spot.spot_range = 85.0
		spot.spot_angle = 18.0
		spot.shadow_enabled = false
		turret.add_child(spot)

		_searchlights.append({
			"turret": turret,
			"speed_x": float(cfg["speed_x"]),
			"speed_y": float(cfg["speed_y"]),
			"phase": float(cfg["phase"])
		})


func _build_interior_reflection_probe() -> void:
	_casino_probe = ReflectionProbe.new()
	_casino_probe.name = "CasinoReflectionProbe"
	_casino_probe.size = Vector3(44.0, 22.0, 22.0)
	_casino_probe.position = Vector3(0.0, 4.2, 0.0)
	_casino_probe.update_mode = ReflectionProbe.UPDATE_ONCE
	_casino_probe.box_projection = true
	_casino_probe.interior = true
	_casino_probe.ambient_mode = ReflectionProbe.AMBIENT_COLOR
	_casino_probe.ambient_color = Color(0.32, 0.28, 0.22)
	_casino_probe.ambient_color_energy = 0.92
	_casino_probe.intensity = 1.25
	_casino_probe.enable_shadows = int(ConfigManager.graphics.get("shadows", 3)) >= 2
	add_child(_casino_probe)


func _apply_lighting_quality() -> void:
	var shadow_tier := int(ConfigManager.graphics.get("shadows", 3))
	var enable_arch_shadows := (shadow_tier >= 2)
	for l: OmniLight3D in _arch_shadow_lights:
		if is_instance_valid(l):
			l.shadow_enabled = enable_arch_shadows
	if is_instance_valid(_casino_probe):
		_casino_probe.enable_shadows = enable_arch_shadows


func set_highlighted_painting(painting_id: String) -> void:
	for p in paintings:
		var hm: StandardMaterial3D = p["highlight_mat"]
		var active := str(p["id"]) == painting_id
		hm.emission_energy_multiplier = 1.6 if active else 0.0


func set_painting_transition(painting_id: String, color_mix: float, blur_amount: float) -> void:
	var info := get_painting_by_id(painting_id)
	if info.is_empty():
		return
	var cm: ShaderMaterial = info["canvas_mat"]
	cm.set_shader_parameter("color_mix", color_mix)
	cm.set_shader_parameter("blur_amount", blur_amount)
	var vp := info.get("viewport") as SubViewport
	if vp:
		vp.render_target_update_mode = SubViewport.UPDATE_ONCE


func get_painting_by_id(painting_id: String) -> Dictionary:
	for p in paintings:
		if str(p["id"]) == painting_id:
			return p
	return {}


func trigger_slot(idx: int) -> String:
	if idx >= 0 and idx < _slot_pulls.size():
		_slot_pulls[idx] = 1.0
	AudioSfx.play_slot_spin()
	var roll := randi() % 10
	if roll == 0:
		AudioSfx.play_fanfare()
		return "★ ДЖЕКПОТ 7-7-7! (+500 фішок!) ★"
	elif roll <= 3:
		AudioSfx.play_coin()
		return "🍒 Вишні x3! (+120 фішок)"
	elif roll <= 6:
		AudioSfx.play_coin()
		return "🔔 Дзвіночки! (+60 фішок)"
	return "🍋 Повз! Крутніть ще раз!"


func trigger_roulette() -> String:
	_roulette_boost = 14.0
	AudioSfx.play_slot_spin()
	var pocket := randi() % 37
	if pocket == 0:
		AudioSfx.play_fanfare()
		return "🟢 0 ЗЕРО! Неймовірний куш!"
	var col := "🔴 Червоне" if pocket % 2 == 1 else "⚫ Чорне"
	return "🎡 Рулетка крутиться... випало %s %d!" % [col, pocket]


func toggle_disco() -> bool:
	_disco_mode = not _disco_mode
	if not _disco_mode:
		for dl: OmniLight3D in _disco_lights:
			if dl: dl.light_color = Color(1.0, 0.88, 0.70)
	AudioSfx.play_race_lap()
	return _disco_mode


func _process(delta: float) -> void:
	if _roulette_wheel:
		_roulette_boost = maxf(0.0, _roulette_boost - delta * 3.8)
		_roulette_wheel.rotate_y(delta * (0.65 + _roulette_boost))
	for si: int in range(_slot_levers.size()):
		if _slot_pulls[si] > 0.0:
			_slot_pulls[si] = maxf(0.0, _slot_pulls[si] - delta * 2.2)
			_slot_levers[si].rotation_degrees.x = sin(_slot_pulls[si] * PI) * 58.0
	_preview_time += delta
	if _disco_mode:
		for di: int in range(_disco_lights.size()):
			var dl: OmniLight3D = _disco_lights[di]
			if dl:
				dl.light_color = Color.from_hsv(fmod(_preview_time * 0.65 + float(di) * 0.35, 1.0), 0.78, 1.0)

	for sl in _searchlights:
		var t_node: Node3D = sl["turret"]
		var ph := float(sl["phase"])
		t_node.rotation.y = sin(_preview_time * float(sl["speed_y"]) + ph) * 1.35
		t_node.rotation.x = 0.24 + cos(_preview_time * float(sl["speed_x"]) + ph) * 0.28
		t_node.rotation.z = sin(_preview_time * float(sl["speed_x"]) * 0.8 + ph) * 0.24

	_frame_counter += 1
	var cam := get_viewport().get_camera_3d()
	if cam and cam.global_position.distance_to(global_position) < 34.0 and not _preview_drawer_nodes.is_empty():
		if _frame_counter % 2 == 0:
			var idx := (_frame_counter / 2) % _preview_drawer_nodes.size()
			var item: Dictionary = _preview_drawer_nodes[idx]
			var d: PaintingCanvasDrawer = item["drawer"]
			var vp: SubViewport = item["vp"]
			d.anim_t = _preview_time
			d.queue_redraw()
			vp.render_target_update_mode = SubViewport.UPDATE_ONCE


class PaintingCanvasDrawer extends Control:
	var game_id: String = ""
	var anim_t: float = 0.0

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		var f := ThemeDB.fallback_font
		match game_id:
			"python3d":
				draw_rect(r, Color(0.05, 0.12, 0.07))
				for seg in range(9):
					var ang := anim_t * 2.4 - float(seg) * 0.28
					var col := Color(0.22, 0.94, 0.44) if seg < 5 else Color(0.95, 0.24, 0.20)
					draw_circle(Vector2(128.0 + cos(ang) * 52.0, 80.0 + sin(ang * 1.4) * 34.0), 8.5 - seg * 0.4, col)
				draw_circle(Vector2(62, 48), 6.0, Color(0.98, 0.80, 0.16))
				draw_circle(Vector2(198, 114), 6.5, Color(0.24, 0.86, 1.0))
			"hexa":
				draw_rect(r, Color(0.08, 0.09, 0.13))
				var hc := [Color(0.98, 0.56, 0.18), Color(0.26, 0.82, 0.96), Color(0.14, 0.84, 0.58), Color(0.92, 0.24, 0.36), Color(0.66, 0.38, 0.92)]
				for k in range(7):
					var a := float(k) * TAU / 6.0
					var p := Vector2(128, 80) + (Vector2(cos(a), sin(a)) * 36.0 if k < 6 else Vector2.ZERO)
					draw_circle(p, 15.0, hc[k % hc.size()])
			"sokoban":
				draw_rect(r, Color(0.09, 0.11, 0.15))
				draw_rect(Rect2(58, 28, 140, 104), Color(0.28, 0.32, 0.40), false, 4.0)
				draw_circle(Vector2(166, 80), 9.0, Color(0.22, 0.88, 0.48))
				draw_rect(Rect2(108 + sin(anim_t * 2.0) * 14.0, 62, 32, 32), Color(0.76, 0.48, 0.18))
				draw_circle(Vector2(82, 78), 11.0, Color(0.22, 0.72, 0.98))
			"fifteen":
				draw_rect(r, Color(0.07, 0.10, 0.14))
				for idx in range(8):
					var tx := 74.0 + float(idx % 3) * 36.0
					var ty := 24.0 + float(idx / 3) * 36.0
					draw_rect(Rect2(tx, ty, 32, 32), Color(0.20, 0.42, 0.64) if idx != 4 else Color(0.16, 0.60, 0.38))
					draw_string(f, Vector2(tx, ty + 22), str(idx + 1), HORIZONTAL_ALIGNMENT_CENTER, 32, 14, Color.WHITE)
			"pong":
				draw_rect(r, Color(0.04, 0.08, 0.06))
				draw_rect(Rect2(26, 46 + sin(anim_t * 2.5) * 26.0, 10, 44), Color(0.22, 0.78, 0.98))
				draw_rect(Rect2(220, 46 - sin(anim_t * 2.2) * 24.0, 10, 44), Color(0.96, 0.32, 0.28))
				draw_circle(Vector2(128 + cos(anim_t * 3.8) * 70.0, 80 + sin(anim_t * 4.2) * 40.0), 6.0, Color.WHITE)
			"memory":
				draw_rect(r, Color(0.06, 0.12, 0.09))
				var mc := [Color(0.95, 0.26, 0.30), Color(0.24, 0.74, 0.98), Color(0.96, 0.80, 0.18), Color(0.24, 0.88, 0.44)]
				for ci in range(4):
					draw_rect(Rect2(44 + ci * 44, 48, 36, 56), mc[ci])
			"codelock":
				draw_rect(r, Color(0.08, 0.09, 0.13))
				var cc := [Color(0.92, 0.22, 0.22), Color(0.22, 0.56, 0.96), Color(0.22, 0.86, 0.42), Color(0.96, 0.82, 0.16)]
				for ci in range(4):
					draw_circle(Vector2(70 + ci * 38, 80), 13.0, cc[ci])
			"bullscows":
				draw_rect(r, Color(0.07, 0.09, 0.13))
				draw_string(f, Vector2(36, 68), "4 8 1 7", HORIZONTAL_ALIGNMENT_CENTER, 184, 24, Color.WHITE)
				draw_rect(Rect2(56, 88, 66, 24), Color(0.14, 0.58, 0.28))
				draw_rect(Rect2(134, 88, 66, 24), Color(0.76, 0.56, 0.12))
			"tictactoe":
				draw_rect(r, Color(0.06, 0.08, 0.12))
				draw_line(Vector2(106, 26), Vector2(106, 134), Color(0.36, 0.48, 0.62), 3.0)
				draw_line(Vector2(150, 26), Vector2(150, 134), Color(0.36, 0.48, 0.62), 3.0)
				draw_line(Vector2(66, 62), Vector2(190, 62), Color(0.36, 0.48, 0.62), 3.0)
				draw_line(Vector2(66, 98), Vector2(190, 98), Color(0.36, 0.48, 0.62), 3.0)
				draw_circle(Vector2(128, 80), 12.0, Color(0.96, 0.36, 0.34), false, 3.0)
				draw_line(Vector2(74, 34), Vector2(96, 54), Color(0.24, 0.78, 0.98), 3.0)
				draw_line(Vector2(96, 34), Vector2(74, 54), Color(0.24, 0.78, 0.98), 3.0)
			"balda":
				draw_rect(r, Color(0.08, 0.10, 0.14))
				var w := "КАЗКА"
				for ci in range(5):
					draw_rect(Rect2(44 + ci * 34, 62, 30, 34), Color(0.18, 0.34, 0.54))
					draw_string(f, Vector2(44 + ci * 34, 86), w[ci], HORIZONTAL_ALIGNMENT_CENTER, 30, 18, Color.WHITE)
			"match3":
				draw_rect(r, Color(0.06, 0.08, 0.14))
				var gc := [Color(0.95, 0.22, 0.26), Color(0.22, 0.56, 0.98), Color(0.22, 0.86, 0.42), Color(0.98, 0.80, 0.16)]
				for row in range(4):
					for col in range(5):
						draw_circle(Vector2(62 + col * 32, 34 + row * 30), 10.0, gc[(row + col) % gc.size()])
			"minesweeper":
				draw_rect(r, Color(0.09, 0.11, 0.14))
				for row in range(4):
					for col in range(6):
						draw_rect(Rect2(44 + col * 28, 24 + row * 28, 25, 25), Color(0.26, 0.32, 0.38))
				draw_circle(Vector2(142, 66), 8.0, Color(0.92, 0.22, 0.22))
				draw_string(f, Vector2(78, 72), "2", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.32, 0.88, 0.42))
			"solitaire":
				draw_rect(r, Color(0.05, 0.24, 0.14))
				for ci in range(4):
					draw_rect(Rect2(36 + ci * 46, 36 + ci * 8, 42, 58), Color(0.97, 0.96, 0.92))
					draw_string(f, Vector2(44 + ci * 46, 62 + ci * 8), ["A", "K", "Q", "J"][ci], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.84, 0.14, 0.14) if ci % 2 == 0 else Color.BLACK)
			"flappy":
				draw_rect(r, Color(0.18, 0.28, 0.52))
				draw_rect(Rect2(150, 0, 28, 52), Color(0.16, 0.62, 0.28))
				draw_rect(Rect2(150, 102, 28, 58), Color(0.16, 0.62, 0.28))
				draw_circle(Vector2(78, 76 + sin(anim_t * 4.5) * 10.0), 11.0, Color(0.98, 0.76, 0.18))
			"sudoku":
				draw_rect(r, Color(0.06, 0.08, 0.13))
				draw_rect(Rect2(60, 14, 136, 136), Color(0.84, 0.68, 0.28), false, 2.0)
				for k in [1, 2]:
					draw_line(Vector2(60 + k * 45, 14), Vector2(60 + k * 45, 150), Color(0.84, 0.68, 0.28), 2.0)
					draw_line(Vector2(60, 14 + k * 45), Vector2(196, 14 + k * 45), Color(0.84, 0.68, 0.28), 2.0)
				draw_string(f, Vector2(76, 46), "9", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.32, 0.90, 0.56))
				draw_string(f, Vector2(120, 90), "5", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
				draw_string(f, Vector2(166, 134), "7", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.98, 0.84, 0.34))
			"2048":
				draw_rect(r, Color(0.14, 0.10, 0.08))
				draw_rect(Rect2(56, 8, 144, 144), Color(0.24, 0.19, 0.15))
				var tiles := [
					["2", Color(0.92, 0.88, 0.80)], ["4", Color(0.92, 0.85, 0.68)], ["8", Color(0.95, 0.62, 0.36)], ["16", Color(0.95, 0.45, 0.24)],
					["32", Color(0.94, 0.32, 0.22)], ["64", Color(0.92, 0.22, 0.16)], ["128", Color(0.92, 0.78, 0.32)], ["2048", Color(0.98, 0.76, 0.14)]
				]
				for idx in range(8):
					var row := idx / 4
					var col := idx % 4
					var tx := 62.0 + float(col) * 34.0
					var ty := 14.0 + float(row) * 34.0 + (sin(anim_t * 2.5 + float(idx)) * 3.0 if idx >= 6 else 0.0)
					draw_rect(Rect2(tx, ty, 30, 30), tiles[idx][1])
					draw_string(f, Vector2(tx, ty + 20), str(tiles[idx][0]), HORIZONTAL_ALIGNMENT_CENTER, 30, 11 if idx == 7 else 13, Color(0.16, 0.12, 0.10) if idx < 2 else Color.WHITE)
			"zuma":
				draw_rect(r, Color(0.07, 0.13, 0.09))
				var z_cols := [Color(0.94, 0.22, 0.24), Color(0.22, 0.56, 0.96), Color(0.96, 0.80, 0.16), Color(0.24, 0.84, 0.38), Color(0.76, 0.26, 0.92)]
				for k in range(18):
					var ang := 0.25 + float(k) * 0.28 + anim_t * 0.55
					var rad := 76.0 - float(k) * 2.6
					var p := Vector2(128.0 + cos(ang) * rad, 80.0 + sin(ang) * rad * 0.72)
					draw_circle(p, 8.5, z_cols[k % z_cols.size()])
					draw_circle(p + Vector2(-2.5, -2.5), 2.5, Color(1, 1, 1, 0.6))
				draw_circle(Vector2(128, 80), 16.0, Color(0.16, 0.55, 0.28))
				draw_circle(Vector2(128, 70), 6.0, Color(0.96, 0.80, 0.16))
			"puzzle":
				draw_rect(r, Color(0.14, 0.10, 0.07))
				var p_cols := [Color(0.26, 0.56, 0.88), Color(0.86, 0.64, 0.26), Color(0.28, 0.74, 0.44), Color(0.72, 0.32, 0.58), Color(0.92, 0.42, 0.26), Color(0.24, 0.78, 0.86)]
				for r_i in range(2):
					for c_i in range(3):
						var px := 56.0 + float(c_i) * 48.0 + (sin(anim_t * 2.0) * 6.0 if (r_i == 1 and c_i == 2) else 0.0)
						var py := 32.0 + float(r_i) * 48.0
						draw_rect(Rect2(px, py, 44, 44), p_cols[(r_i * 3 + c_i) % p_cols.size()])
						draw_circle(Vector2(px + 44, py + 22), 7.0, p_cols[(r_i * 3 + c_i) % p_cols.size()])
						draw_rect(Rect2(px, py, 44, 44), Color(0.98, 0.88, 0.45), false, 1.5)
			"mario":
				draw_rect(r, Color(0.28, 0.60, 0.96))
				draw_rect(Rect2(0, 126, 256, 34), Color(0.55, 0.28, 0.12))
				draw_rect(Rect2(0, 122, 256, 7), Color(0.22, 0.68, 0.22))
				draw_rect(Rect2(175, 86, 28, 40), Color(0.14, 0.68, 0.20))
				draw_rect(Rect2(170, 80, 38, 9), Color(0.18, 0.78, 0.24))
				draw_rect(Rect2(92, 62, 22, 22), Color(0.95, 0.72, 0.14))
				draw_string(f, Vector2(98, 79), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.35, 0.18, 0.0))
				var mx := 38.0 + fmod(anim_t * 28.0, 96.0)
				draw_rect(Rect2(mx, 96, 18, 26), Color(0.88, 0.18, 0.14))
				draw_circle(Vector2(142, 52), 7.0, Color(0.98, 0.84, 0.20))
			"tetris":
				draw_rect(r, Color(0.06, 0.08, 0.14))
				draw_rect(Rect2(72, 10, 112, 140), Color(0.10, 0.14, 0.24))
				var cy := 22.0 + fmod(anim_t * 18.0, 74.0)
				for b in [Vector2(114, cy), Vector2(128, cy), Vector2(142, cy), Vector2(128, cy + 14)]:
					draw_rect(Rect2(b, Vector2(13, 13)), Color(0.75, 0.30, 0.92))
				for bx in [74, 88, 102, 116, 130, 144, 158]:
					draw_rect(Rect2(bx, 134, 13, 13), Color(0.20, 0.78, 0.88))
				draw_rect(Rect2(74, 120, 27, 13), Color(0.92, 0.32, 0.24))
				draw_rect(Rect2(144, 120, 27, 27), Color(0.95, 0.82, 0.22))
			"snake":
				draw_rect(r, Color(0.06, 0.14, 0.10))
				draw_rect(Rect2(20, 16, 216, 128), Color(0.10, 0.22, 0.14), false, 4.0)
				for seg in range(7):
					var ang := anim_t * 2.0 - float(seg) * 0.32
					draw_circle(Vector2(122.0 + cos(ang) * 44.0, 80.0 + sin(ang * 1.3) * 32.0), 8.0 - seg * 0.4, Color(0.24, 0.85, 0.40))
				draw_circle(Vector2(194, 52), 7.0, Color(0.94, 0.22, 0.18))
				draw_circle(Vector2(66, 108), 6.0, Color(0.68, 0.20, 0.92))
			"bomberman":
				draw_rect(r, Color(0.16, 0.42, 0.18))
				for gy in range(18, 150, 28):
					for gx in range(26, 230, 28):
						draw_rect(Rect2(gx, gy, 22, 22), Color(0.38, 0.40, 0.46) if ((gx + gy) % 56 == 0) else Color(0.72, 0.42, 0.22))
				var pulse := 1.0 + sin(anim_t * 5.0) * 0.18
				draw_circle(Vector2(124, 80), 9.0 * pulse, Color(0.12, 0.12, 0.14))
				draw_rect(Rect2(106, 75, 36, 10), Color(1.0, 0.65, 0.15, 0.85))
			"soccer":
				draw_rect(r, Color(0.12, 0.48, 0.18))
				draw_rect(Rect2(12, 12, 232, 136), Color(1, 1, 1, 0.85), false, 2.0)
				draw_line(Vector2(128, 12), Vector2(128, 148), Color(1, 1, 1, 0.85), 2.0)
				draw_circle(Vector2(128, 80), 22.0, Color(1, 1, 1, 0.85), false, 2.0)
				draw_circle(Vector2(128 + cos(anim_t * 2.4) * 32.0, 80 + sin(anim_t * 3.1) * 18.0), 6.0, Color.WHITE)
			"arkanoid":
				draw_rect(r, Color(0.06, 0.08, 0.15))
				var colors := [Color(0.95, 0.28, 0.28), Color(0.95, 0.62, 0.18), Color(0.92, 0.88, 0.22), Color(0.28, 0.86, 0.42)]
				for row in range(4):
					for col in range(8):
						draw_rect(Rect2(18 + col * 28, 18 + row * 14, 24, 10), colors[row])
				var px := 102.0 + sin(anim_t * 2.2) * 48.0
				draw_rect(Rect2(px, 136, 48, 9), Color(0.32, 0.78, 0.98))
				draw_circle(Vector2(128 + sin(anim_t * 3.0) * 52.0, 92 + cos(anim_t * 3.4) * 28.0), 5.0, Color.WHITE)
			"arcade":
				draw_rect(r, Color(0.03, 0.04, 0.09))
				for e_col in range(5):
					var ex := 36.0 + float(e_col) * 40.0 + sin(anim_t * 1.8) * 16.0
					draw_rect(Rect2(ex, 26, 20, 14), Color(0.92, 0.28, 0.52))
					draw_rect(Rect2(ex + 3, 48, 16, 12), Color(0.42, 0.90, 0.48))
				draw_polygon(PackedVector2Array([Vector2(128, 122), Vector2(114, 144), Vector2(142, 144)]), PackedColorArray([Color(0.25, 0.82, 0.98)]))
			"pacman":
				draw_rect(r, Color(0.04, 0.05, 0.12))
				draw_rect(Rect2(34, 26, 68, 22), Color(0.16, 0.28, 0.88), false, 3.0)
				draw_rect(Rect2(154, 26, 68, 22), Color(0.16, 0.28, 0.88), false, 3.0)
				for dot_x in range(30, 230, 22):
					draw_circle(Vector2(dot_x, 92), 3.0, Color(0.98, 0.86, 0.65))
				draw_circle(Vector2(44.0 + fmod(anim_t * 36.0, 168.0), 92), 12.0, Color(0.98, 0.88, 0.18))
				draw_circle(Vector2(180, 62), 10.0, Color(0.96, 0.26, 0.32))
			"tanks":
				draw_rect(r, Color(0.08, 0.10, 0.08))
				for bx in [48, 96, 168, 196]:
					draw_rect(Rect2(bx, 42, 24, 24), Color(0.66, 0.34, 0.18))
				draw_rect(Rect2(96, 118, 22, 24), Color(0.88, 0.72, 0.22))
				draw_rect(Rect2(158, 34 + sin(anim_t * 1.5) * 14.0, 22, 24), Color(0.75, 0.24, 0.22))
			"chess":
				draw_rect(r, Color(0.26, 0.16, 0.10))
				for row in range(8):
					for col in range(8):
						draw_rect(Rect2(60 + col * 17, 12 + row * 17, 17, 17), Color(0.86, 0.78, 0.62) if (row + col) % 2 == 0 else Color(0.42, 0.26, 0.16))
				draw_circle(Vector2(120, 72 + sin(anim_t * 1.8) * 6.0), 6.0, Color(0.96, 0.94, 0.86))
				draw_circle(Vector2(137, 106), 6.0, Color(0.14, 0.12, 0.12))
			"checkers":
				draw_rect(r, Color(0.22, 0.14, 0.09))
				for row in range(8):
					for col in range(8):
						draw_rect(Rect2(60 + col * 17, 12 + row * 17, 17, 17), Color(0.84, 0.74, 0.56) if (row + col) % 2 == 0 else Color(0.32, 0.20, 0.12))
						if (row + col) % 2 == 1 and row < 2:
							draw_circle(Vector2(68.5 + col * 17, 20.5 + row * 17), 5.5, Color(0.78, 0.14, 0.14))
						elif (row + col) % 2 == 1 and row > 5:
							draw_circle(Vector2(68.5 + col * 17, 20.5 + row * 17), 5.5, Color(0.94, 0.90, 0.80))
			"corners":
				draw_rect(r, Color(0.18, 0.22, 0.18))
				for row in range(8):
					for col in range(8):
						draw_rect(Rect2(60 + col * 17, 12 + row * 17, 17, 17), Color(0.80, 0.78, 0.70) if (row + col) % 2 == 0 else Color(0.35, 0.42, 0.36))
						if row < 3 and col < 3:
							draw_circle(Vector2(68.5 + col * 17, 20.5 + row * 17), 5.5, Color(0.22, 0.55, 0.88))
						elif row > 4 and col > 4:
							draw_circle(Vector2(68.5 + col * 17, 20.5 + row * 17), 5.5, Color(0.94, 0.72, 0.20))
			"battleship":
				draw_rect(r, Color(0.06, 0.18, 0.32))
				for i in range(11):
					draw_line(Vector2(54 + i * 14, 12), Vector2(54 + i * 14, 148), Color(0.22, 0.48, 0.72, 0.5), 1.0)
					draw_line(Vector2(54, 12 + i * 13.6), Vector2(194, 12 + i * 13.6), Color(0.22, 0.48, 0.72, 0.5), 1.0)
				draw_rect(Rect2(84, 54, 54, 12), Color(0.62, 0.68, 0.74))
				draw_circle(Vector2(112, 60), 5.0 + sin(anim_t * 4.0) * 1.5, Color(0.98, 0.42, 0.14))
			"durak":
				draw_rect(r, Color(0.05, 0.28, 0.14))
				for idx in range(3):
					var cp := Vector2(62 + idx * 36, 46 + (idx % 2) * 14)
					draw_rect(Rect2(cp, Vector2(46, 66)), Color(0.97, 0.96, 0.92))
					draw_rect(Rect2(cp, Vector2(46, 66)), Color(0.2, 0.2, 0.2), false, 1.5)
					draw_circle(cp + Vector2(23, 33), 10.0, Color(0.84, 0.14, 0.14) if idx % 2 == 0 else Color(0.14, 0.14, 0.16))
			"blackjack":
				draw_rect(r, Color(0.04, 0.24, 0.14))
				draw_arc(Vector2(128, 30), 90.0, 0.2, PI - 0.2, 24, Color(0.86, 0.70, 0.28), 2.0)
				draw_rect(Rect2(76, 56, 44, 64), Color(0.97, 0.96, 0.92))
				draw_rect(Rect2(132, 56, 44, 64), Color(0.97, 0.96, 0.92))
				draw_string(f, Vector2(84, 96), "A", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.84, 0.14, 0.14))
				draw_string(f, Vector2(140, 96), "K", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.12, 0.12, 0.15))
			"poker":
				draw_rect(r, Color(0.07, 0.22, 0.18))
				for ci in range(4):
					draw_rect(Rect2(34 + ci * 48, 48, 40, 58), Color(0.97, 0.96, 0.92))
				draw_circle(Vector2(90, 128), 10.0, Color(0.84, 0.18, 0.18))
				draw_circle(Vector2(128, 128), 10.0, Color(0.92, 0.74, 0.24))
				draw_circle(Vector2(166, 128), 10.0, Color(0.18, 0.42, 0.85))
