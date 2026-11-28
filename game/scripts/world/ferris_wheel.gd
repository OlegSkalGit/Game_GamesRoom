class_name FerrisWheel
extends Node3D

const FULL_ROT_SECONDS := 60.0
const OMEGA := TAU / FULL_ROT_SECONDS
const WHEEL_RADIUS := 10.5
const HANGER_LEN := 2.18
const HUB_Y := WHEEL_RADIUS + HANGER_LEN + 0.56 # Bottom cabin floor rests at y=0.56m
const CABIN_COUNT := 12

var _angle: float = -PI * 0.5 # Start with cabin #0 right at the bottom boarding platform
var _rotor: Node3D
var _cabins: Array[Dictionary] = []
var _bulb_mats: Array[StandardMaterial3D] = []
var _cabin_lantern_mat: StandardMaterial3D
var _hub_light: OmniLight3D
var _is_dark: bool = false
var _darkness: float = 0.0
var _light_t: float = 0.0


func _ready() -> void:
	_build_structure()
	_sync_cabins()


func _mat(col: Color, rough: float = 0.55, metal: float = 0.15, emit_c: Color = Color.BLACK, emit_e: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = rough
	m.metallic = metal
	if emit_e > 0.0:
		m.emission_enabled = true
		m.emission = emit_c if emit_c != Color.BLACK else col
		m.emission_energy_multiplier = emit_e
	return m


func _add_part(parent: Node3D, mesh: Mesh, pos: Vector3, mat: Material, rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot_deg
	parent.add_child(mi)
	return mi


func _add_box_col(body: StaticBody3D, size: Vector3, pos: Vector3, mat: Material = null, visual_parent: Node3D = null) -> void:
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	cs.position = pos
	body.add_child(cs)
	if mat != null:
		var bm := BoxMesh.new()
		bm.size = size
		_add_part(visual_parent if visual_parent else body, bm, pos, mat)


func _build_structure() -> void:
	var pad_mat := _mat(Color(0.38, 0.37, 0.35), 0.85, 0.05)
	var steel_mat := _mat(Color(0.86, 0.82, 0.72), 0.35, 0.65)
	var red_steel := _mat(Color(0.72, 0.14, 0.16), 0.38, 0.45)
	var gold_mat := _mat(Color(0.86, 0.68, 0.24), 0.28, 0.85)
	var deck_wood := _mat(Color(0.46, 0.30, 0.17), 0.78, 0.05)

	# 1. Ground concrete pad & Steel A-Frame Support Towers (wide enough in +-Z so cabin & stairs clear!)
	var base_body := StaticBody3D.new()
	base_body.name = "FerrisBaseAndPlatform"
	add_child(base_body)

	var pad_cyl := CylinderMesh.new(); pad_cyl.top_radius = 7.6; pad_cyl.bottom_radius = 8.2; pad_cyl.height = 0.40
	_add_part(self, pad_cyl, Vector3(0.0, -0.18, 0.0), pad_mat)
	_add_box_col(base_body, Vector3(13.6, 0.30, 12.6), Vector3(0.0, -0.15, 0.6))

	var leg_len := Vector2(5.6, HUB_Y).length()
	var leg_ang := rad_to_deg(atan2(5.6, HUB_Y))
	var leg_mesh := CylinderMesh.new(); leg_mesh.top_radius = 0.20; leg_mesh.bottom_radius = 0.28; leg_mesh.height = leg_len
	for sz: float in [-1.62, 1.62]:
		for sx: float in [-1.0, 1.0]:
			_add_part(self, leg_mesh, Vector3(sx * 2.8, HUB_Y * 0.5, sz), steel_mat, Vector3(0.0, 0.0, sx * leg_ang))
			_add_box_col(base_body, Vector3(0.9, 0.7, 0.9), Vector3(sx * 5.6, 0.35, sz), red_steel, self)
	var axle_mesh := CylinderMesh.new(); axle_mesh.top_radius = 0.34; axle_mesh.bottom_radius = 0.34; axle_mesh.height = 4.0
	_add_part(self, axle_mesh, Vector3(0.0, HUB_Y, 0.0), gold_mat, Vector3(90.0, 0.0, 0.0))

	# 2. Walkable Boarding Deck (+Z side at y=0.54m) & Gentle 5-step Stairs down to terrain (y=0.0m)
	# Deck runs X: -2.2..+2.2, Z: +0.96..+3.16 (cabins pass closely at Z: -0.85..+0.85, floor y=0.56m!)
	_add_box_col(base_body, Vector3(4.6, 0.54, 2.20), Vector3(0.0, 0.27, 2.06), deck_wood)
	# Yellow safety edge strip along boarding rim
	_add_box_col(base_body, Vector3(4.5, 0.04, 0.14), Vector3(0.0, 0.55, 1.03), gold_mat)
	# Left & Right handrails on deck (wide 3.0m central boarding opening)
	for side_x: float in [-2.22, 2.22]:
		_add_box_col(base_body, Vector3(0.12, 0.95, 2.20), Vector3(side_x, 0.98, 2.06), red_steel)
	for st: int in range(5):
		var sy := 0.44 - float(st) * 0.10
		var sz := 3.38 + float(st) * 0.44
		_add_box_col(base_body, Vector3(3.4, sy, 0.46), Vector3(0.0, sy * 0.5, sz), deck_wood)

	# 3. Rotating Wheel Rotor (2 parallel rims at Z = +-1.12, spokes & festive twinkling bulbs)
	_rotor = Node3D.new()
	_rotor.name = "FerrisRotor"
	_rotor.position = Vector3(0.0, HUB_Y, 0.0)
	add_child(_rotor)

	var hub_m := CylinderMesh.new(); hub_m.top_radius = 0.95; hub_m.bottom_radius = 0.95; hub_m.height = 2.65
	_add_part(_rotor, hub_m, Vector3.ZERO, red_steel, Vector3(90.0, 0.0, 0.0))

	var rim_seg_len := 2.0 * WHEEL_RADIUS * sin(PI / 24.0) + 0.08
	var rim_mesh := BoxMesh.new(); rim_mesh.size = Vector3(0.18, rim_seg_len, 0.14)
	var inner_seg_len := 2.0 * (WHEEL_RADIUS * 0.68) * sin(PI / 24.0) + 0.06
	var inner_mesh := BoxMesh.new(); inner_mesh.size = Vector3(0.13, inner_seg_len, 0.11)
	var bulb_mesh := SphereMesh.new(); bulb_mesh.radius = 0.19; bulb_mesh.height = 0.38
	var inner_bulb_mesh := SphereMesh.new(); inner_bulb_mesh.radius = 0.14; inner_bulb_mesh.height = 0.28

	var palette := [
		Color(1.0, 0.85, 0.24),
		Color(1.0, 0.28, 0.34),
		Color(0.24, 0.88, 1.0),
		Color(0.30, 0.98, 0.50),
		Color(0.96, 0.42, 0.94),
		Color(1.0, 0.62, 0.20)
	]
	for b_idx: int in range(palette.size()):
		_bulb_mats.append(_mat(palette[b_idx], 0.18, 0.08, palette[b_idx], 0.0))

	for i: int in range(24):
		var a := (float(i) + 0.5) * TAU / 24.0
		for rz: float in [-1.12, 1.12]:
			_add_part(_rotor, rim_mesh, Vector3(cos(a) * WHEEL_RADIUS, sin(a) * WHEEL_RADIUS, rz), steel_mat, Vector3(0.0, 0.0, rad_to_deg(a)))
			_add_part(_rotor, inner_mesh, Vector3(cos(a) * WHEEL_RADIUS * 0.68, sin(a) * WHEEL_RADIUS * 0.68, rz), red_steel, Vector3(0.0, 0.0, rad_to_deg(a)))
		var ba := float(i) * TAU / 24.0
		var bm: StandardMaterial3D = _bulb_mats[i % _bulb_mats.size()]
		for bz: float in [-1.22, 1.22]:
			_add_part(_rotor, bulb_mesh, Vector3(cos(ba) * WHEEL_RADIUS, sin(ba) * WHEEL_RADIUS, bz), bm)
		if i % 2 == 0:
			var bm_in: StandardMaterial3D = _bulb_mats[(i / 2 + 3) % _bulb_mats.size()]
			for bz_in: float in [-1.19, 1.19]:
				_add_part(_rotor, inner_bulb_mesh, Vector3(cos(ba) * WHEEL_RADIUS * 0.68, sin(ba) * WHEEL_RADIUS * 0.68, bz_in), bm_in)

	var spoke_mesh := CylinderMesh.new(); spoke_mesh.top_radius = 0.055; spoke_mesh.bottom_radius = 0.055; spoke_mesh.height = WHEEL_RADIUS
	var cross_mesh := CylinderMesh.new(); cross_mesh.top_radius = 0.065; cross_mesh.bottom_radius = 0.065; cross_mesh.height = 2.28
	for ci: int in range(CABIN_COUNT):
		var ca := float(ci) * TAU / float(CABIN_COUNT)
		for sz: float in [-1.12, 1.12]:
			_add_part(_rotor, spoke_mesh, Vector3(cos(ca) * WHEEL_RADIUS * 0.5, sin(ca) * WHEEL_RADIUS * 0.5, sz), steel_mat, Vector3(0.0, 0.0, rad_to_deg(ca) - 90.0))
		_add_part(_rotor, cross_mesh, Vector3(cos(ca) * WHEEL_RADIUS, sin(ca) * WHEEL_RADIUS, 0.0), gold_mat, Vector3(90.0, 0.0, 0.0))

	_hub_light = OmniLight3D.new()
	_hub_light.position = Vector3(0.0, HUB_Y, 0.0)
	_hub_light.light_color = Color(1.0, 0.84, 0.56)
	_hub_light.light_energy = 0.0
	_hub_light.omni_range = 24.0
	_hub_light.shadow_enabled = false
	_hub_light.visible = false
	add_child(_hub_light)

	# 4. 12 Walk-in Upright Gondola Cabins (AnimatableBody3D synchronized to physics!)
	var cab_cols := [
		Color(0.76, 0.16, 0.20),
		Color(0.12, 0.54, 0.32),
		Color(0.16, 0.36, 0.72),
		Color(0.78, 0.54, 0.14)
	]
	var cab_floor_mat := _mat(Color(0.28, 0.22, 0.18), 0.72, 0.10)
	var rod_mat := _mat(Color(0.84, 0.84, 0.86), 0.30, 0.75)
	_cabin_lantern_mat = _mat(Color(1.0, 0.92, 0.64), 0.2, 0.0, Color(1.0, 0.88, 0.48), 0.0)

	for ci: int in range(CABIN_COUNT):
		var body := AnimatableBody3D.new()
		body.name = "FerrisCabin_%d" % ci
		body.sync_to_physics = false
		body.collision_layer = 1
		body.collision_mask = 0
		add_child(body)

		var cmat := _mat(cab_cols[ci % cab_cols.size()], 0.42, 0.25)

		# Solid thick walkable floor (top at local y = 0.0, size 1.72 x 0.24 x 1.72)
		var fcs := CollisionShape3D.new()
		var fbox := BoxShape3D.new(); fbox.size = Vector3(1.72, 0.24, 1.72)
		fcs.shape = fbox; fcs.position = Vector3(0.0, -0.12, 0.0)
		body.add_child(fcs)
		var fm := BoxMesh.new(); fm.size = Vector3(1.72, 0.14, 1.72)
		_add_part(body, fm, Vector3(0.0, -0.07, 0.0), cab_floor_mat)
		var bench_m := BoxMesh.new(); bench_m.size = Vector3(1.44, 0.34, 0.38)
		_add_part(body, bench_m, Vector3(0.0, 0.17, -0.52), deck_wood)

		# Back wall (-Z) & Left/Right guard walls (-X/+X): waist-high 1.02m so player can look out AND won't slip off
		for wall_def: Array in [
			[Vector3(1.72, 1.02, 0.12), Vector3(0.0, 0.51, -0.80)],
			[Vector3(0.12, 1.02, 1.72), Vector3(-0.80, 0.51, 0.0)],
			[Vector3(0.12, 1.02, 1.72), Vector3(0.80, 0.51, 0.0)]
		]:
			var wcs := CollisionShape3D.new()
			var wbox := BoxShape3D.new(); wbox.size = wall_def[0]
			wcs.shape = wbox; wcs.position = wall_def[1]
			body.add_child(wcs)
			var wm := BoxMesh.new(); wm.size = wall_def[0]
			_add_part(body, wm, wall_def[1], cmat)

		# Small front corner posts (+Z) leaving a wide 1.44m walk-in doorway facing the boarding platform!
		var p_mesh := BoxMesh.new(); p_mesh.size = Vector3(0.14, 1.02, 0.14)
		for px: float in [-0.79, 0.79]:
			_add_part(body, p_mesh, Vector3(px, 0.51, 0.79), gold_mat)

		# Roof hanger struts up to wheel axle cross-bar at y = HANGER_LEN (2.18m headroom!)
		var strut_h := HANGER_LEN - 0.12
		var sm := CylinderMesh.new(); sm.top_radius = 0.04; sm.bottom_radius = 0.04; sm.height = strut_h
		for sz: float in [-0.76, 0.76]:
			for sx: float in [-0.62, 0.62]:
				_add_part(body, sm, Vector3(sx, strut_h * 0.5 + 0.04, sz), rod_mat)
		var roof_m := BoxMesh.new(); roof_m.size = Vector3(1.56, 0.10, 1.66)
		_add_part(body, roof_m, Vector3(0.0, HANGER_LEN - 0.10, 0.0), cmat)
		var l_sph := SphereMesh.new(); l_sph.radius = 0.10; l_sph.height = 0.20
		_add_part(body, l_sph, Vector3(0.0, HANGER_LEN - 0.22, 0.0), _cabin_lantern_mat)

		_cabins.append({"body": body, "offset": float(ci) * TAU / float(CABIN_COUNT)})


func set_darkness(active: bool, darkness: float = 1.0) -> void:
	_is_dark = active
	_darkness = clampf(darkness, 0.0, 1.0) if active else 0.0
	if _cabin_lantern_mat:
		_cabin_lantern_mat.emission_energy_multiplier = 1.65 * _darkness if _is_dark else 0.0
	if is_instance_valid(_hub_light):
		_hub_light.visible = _is_dark and _darkness > 0.01
	if not _is_dark:
		for bm: StandardMaterial3D in _bulb_mats:
			bm.emission_energy_multiplier = 0.0


func _physics_process(delta: float) -> void:
	_angle = fmod(_angle + OMEGA * delta, TAU)
	_sync_cabins()


func _process(delta: float) -> void:
	if not _is_dark or _darkness <= 0.01:
		return
	_light_t += delta
	# Alternate marquee chase wave & festive twinkle bursts when dark (sunset/night)
	var mode_mix := 0.5 + 0.5 * sin(_light_t * 0.45)
	for bi: int in range(_bulb_mats.size()):
		var chase := pow(0.5 + 0.5 * sin(_light_t * 5.2 - float(bi) * (TAU / float(_bulb_mats.size()))), 2.2)
		var alt := pow(0.5 + 0.5 * sin(_light_t * 7.5 + float(bi % 2) * PI), 3.0)
		var pulse := lerpf(chase, alt, mode_mix * 0.65)
		_bulb_mats[bi].emission_energy_multiplier = (0.35 + pulse * 4.85) * _darkness
	if is_instance_valid(_hub_light):
		_hub_light.light_energy = (1.55 + 0.35 * sin(_light_t * 2.2)) * _darkness


func get_save_angle() -> float:
	return _angle


func set_save_angle(ang: float) -> void:
	_angle = fposmod(ang, TAU)
	_sync_cabins()
	for c: Dictionary in _cabins:
		var body: AnimatableBody3D = c["body"]
		if is_instance_valid(body):
			body.reset_physics_interpolation()


func _sync_cabins() -> void:
	if _rotor:
		_rotor.rotation.z = _angle
	var rot_basis := global_transform.basis if is_inside_tree() else Basis.IDENTITY
	for c: Dictionary in _cabins:
		var a := _angle + float(c["offset"])
		var body: AnimatableBody3D = c["body"]
		body.position = Vector3(cos(a) * WHEEL_RADIUS, HUB_Y + sin(a) * WHEEL_RADIUS - HANGER_LEN, 0.0)
		body.rotation = Vector3.ZERO
		var v_loc := Vector3(-sin(a) * OMEGA * WHEEL_RADIUS, cos(a) * OMEGA * WHEEL_RADIUS, 0.0)
		body.constant_linear_velocity = rot_basis * v_loc
