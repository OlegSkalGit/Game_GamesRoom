class_name MountainRaceTrack
extends Node3D

# Multi-coil perimeter mountain-edge racing circuit:
# - Sweeps all 4 outermost valley edges (|X|,|Z| up to ~235m) in asymmetric multi-diameter spiral coils
# - Automatic curvature-proportional banked corners (up to +/-40 deg leaning strictly INTO turns)
# - 4 Clothoid 360-degree Vertical Loops (smooth C2 entry/exit at any speed) + Tabletop Crest Boost Jump
# - 3D Start/Finish Gantry with physical Red-Amber-Green Traffic Light ("Світлофор")
# - 4 Simultaneous AI Rivals + Procedural PBR Asphalt & Clearcoat Metallic Car Paint + Dynamic Shadows

const TRACK_WIDTH := 10.6
const PIT_POS := Vector3(-16.0, 6.2, 72.0)
const LAPS_TOTAL := 3

var frames: Array[Dictionary] = []
var total_length: float = 0.0
var rivals: Array[Dictionary] = []
var pit_parked_car: Node3D
var terrain_height_fn: Callable = Callable()

var _road_mesh_inst: MeshInstance3D
var _rail_mesh_inst: MeshInstance3D
var _pillar_mm: MultiMeshInstance3D
var _pillar_positions: Array[Dictionary] = []
var _gantry_light: OmniLight3D
var _tl_bulbs: Dictionary = {"red": [], "amber": [], "green": []}
var _tl_mats: Dictionary = {}
var _race_mode: String = "idle" # "idle", "countdown", "racing"
var player_progress_dist: float = 0.0
var _race_elapsed: float = 0.0
static var _f1_tex_cache: Dictionary = {}


func prebuild_frames() -> void:
	if frames.is_empty():
		_build_track_frames()


func _ready() -> void:
	prebuild_frames()
	_build_track_geometry_and_collision()
	_build_pit_stop_station()
	_spawn_ai_rivals()
	ConfigManager.graphics_changed.connect(_apply_shadow_settings)
	_apply_shadow_settings()


func _build_track_frames() -> void:
	frames.clear()

	# 2 Double Spirals (2.25 stacked turns each = 810 deg corkscrew climb & corkscrew descent!)
	var spiral1 := _sample_spiral_helix(Vector3(126.0, 12.0, 134.0), Vector3(0.0, 0.0, 1.0), -1.0, 2.25, 42.0, 34.0, 54.0, 168)
	var end_s1: Vector3 = spiral1[spiral1.size() - 1]
	var dir_s1 := Vector3(1.0, 0.0, 0.0)

	var spiral2 := _sample_spiral_helix(Vector3(-164.0, 58.0, -174.0), Vector3(-1.0, 0.0, 0.0), -1.0, 2.25, 40.0, 32.0, 18.0, 168)
	var end_s2: Vector3 = spiral2[spiral2.size() - 1]
	var dir_s2 := Vector3(0.0, 0.0, 1.0)

	# 4 Clothoid 360-degree Vertical Loops placed around perimeter ridges & valleys
	var loop1 := _sample_clothoid_loop(Vector3(232.0, 22.0, -24.0), Vector3(0.0, 0.0, -1.0), 14.0, -16.0, 64)
	var end_l1: Vector3 = loop1[loop1.size() - 1]["pos"]
	var loop2 := _sample_clothoid_loop(Vector3(38.0, 24.0, -234.0), Vector3(-1.0, 0.0, 0.0), 14.0, -16.0, 64)
	var end_l2: Vector3 = loop2[loop2.size() - 1]["pos"]
	var loop3 := _sample_clothoid_loop(Vector3(-234.0, 20.0, -32.0), Vector3(0.0, 0.0, 1.0), 14.5, -16.0, 64)
	var end_l3: Vector3 = loop3[loop3.size() - 1]["pos"]
	var loop4 := _sample_clothoid_loop(Vector3(-20.0, 18.0, 224.0), Vector3(1.0, 0.0, 0.0), 14.5, -16.0, 64)
	var end_l4: Vector3 = loop4[loop4.size() - 1]["pos"]

	# Frame 0 starts strictly at PIT_POS (-16, 6.3, 72) heading +X (Start/Finish Gantry line -> s=0.0!)
	var sec0_pts: Array[Vector3] = [
		Vector3(-16.0, 6.3, 72.0),
		Vector3(18.0, 6.3, 72.0),
		Vector3(62.0, 13.0, 92.0),
		Vector3(114.0, 11.0, 110.0),
		Vector3(126.0, 12.0, 134.0)
	]
	var sec1_pts: Array[Vector3] = [
		end_s1,
		Vector3(198.0, 56.0, 168.0),      # Smooth straight exit from Double Spiral 1
		Vector3(228.0, 62.0, 148.0),      # Steep East climb peak 1
		Vector3(234.0, 18.0, 92.0),       # 44m plunge into East canyon
		Vector3(234.0, 64.0, 38.0),       # 46m Eagle Peak steep climb
		Vector3(232.0, 22.0, -24.0)       # Rapid dive into Loop 1
	]
	var sec2_pts: Array[Vector3] = [
		end_l1,
		Vector3(216.0, 52.0, -96.0),      # Steep NE climb
		Vector3(198.0, 20.0, -184.0),     # Fast drop into NE curve
		Vector3(132.0, 36.0, -228.0),
		Vector3(68.0, 24.0, -234.0),
		Vector3(38.0, 24.0, -234.0)
	]
	var sec3_pts: Array[Vector3] = [
		end_l2,
		Vector3(end_l2.x - 24.0, 27.0, end_l2.z),
		Vector3(-32.0, 42.0, -212.0),     # High Tabletop Boost Jump Crest!
		Vector3(-86.0, 23.0, -196.0),
		Vector3(-124.0, 58.0, -174.0),    # Steep climb to NW Spiral 2 top
		Vector3(-164.0, 58.0, -174.0)
	]
	var sec4_pts: Array[Vector3] = [
		end_s2,
		Vector3(-232.0, 46.0, -92.0),     # West cliff climb after NW Spiral 2
		Vector3(-234.0, 20.0, -32.0)
	]
	var sec5_pts: Array[Vector3] = [
		end_l3,
		Vector3(-224.0, 52.0, 56.0),      # Steep SW mountain peak
		Vector3(-204.0, 20.0, 148.0),     # Steep 32m ocean-valley plunge
		Vector3(-154.0, 44.0, 214.0),     # South-West ridge climb
		Vector3(-78.0, 20.0, 224.0),
		Vector3(-20.0, 18.0, 224.0)
	]
	var sec6_pts: Array[Vector3] = [
		end_l4,
		Vector3(34.0, 28.0, 202.0),
		Vector3(46.0, 32.0, 160.0),
		Vector3(-28.0, 30.0, 134.0),      # Elevated panoramic return bridge
		Vector3(-102.0, 12.0, 114.0),     # Fast sweep down to valley floor
		Vector3(-84.0, 6.8, 76.0),
		Vector3(-52.0, 6.3, 72.0),        # Straight Starting Grid approach
		Vector3(-16.0, 6.3, 72.0)
	]

	var road0 := _sample_hermite_road(sec0_pts, Vector3(1, 0, 0), Vector3(0, 0, 1), 3.0)
	var road1 := _sample_hermite_road(sec1_pts, dir_s1, Vector3(0, 0, -1), 3.0)
	var road2 := _sample_hermite_road(sec2_pts, Vector3(0, 0, -1), Vector3(-1, 0, 0), 3.0)
	var road3 := _sample_hermite_road(sec3_pts, Vector3(-1, 0, 0), Vector3(-1, 0, 0), 3.0)
	var road4 := _sample_hermite_road(sec4_pts, dir_s2, Vector3(0, 0, 1), 3.0)
	var road5 := _sample_hermite_road(sec5_pts, Vector3(0, 0, 1), Vector3(1, 0, 0), 3.0)
	var road6 := _sample_hermite_road(sec6_pts, Vector3(1, 0, 0), Vector3(1, 0, 0), 3.0)

	var empty_loop: Array[Dictionary] = []
	var sections: Array = [
		{"road": road0, "loop": empty_loop},
		{"road": spiral1, "loop": empty_loop},
		{"road": road1, "loop": loop1},
		{"road": road2, "loop": loop2},
		{"road": road3, "loop": empty_loop},
		{"road": spiral2, "loop": empty_loop},
		{"road": road4, "loop": loop3},
		{"road": road5, "loop": loop4},
		{"road": road6, "loop": empty_loop}
	]

	# Build unified ordered point & tangent sequence
	var raw_frames: Array[Dictionary] = []
	for sec in sections:
		var r_pts: Array = sec["road"]
		for ri: int in range(r_pts.size() - 1):
			var p: Vector3 = r_pts[ri]
			var flat_grid := (p.x > -58.0 and p.x < 22.0 and absf(p.z - 72.0) < 6.0)
			var crest_boost := (p.x > -40.0 and p.x < -4.0 and p.z < -198.0 and p.z > -226.0)
			raw_frames.append({"pos": p, "is_loop": false, "loop_u": 0.0, "is_flat": flat_grid, "is_crest": crest_boost})
		var l_pts: Array = sec["loop"]
		for li: int in range(maxi(l_pts.size() - 1, 0)):
			raw_frames.append(l_pts[li])

	# Compute smooth track tangents and automatic curvature-based bank angle
	var n: int = raw_frames.size()
	var banks: PackedFloat32Array = PackedFloat32Array()
	banks.resize(n)

	for i: int in range(n):
		var rf: Dictionary = raw_frames[i]
		if bool(rf["is_loop"]) or bool(rf.get("is_flat", false)):
			banks[i] = 0.0
			continue
		var p_prev: Vector3 = raw_frames[(i - 2 + n) % n]["pos"]
		var p_cur: Vector3 = rf["pos"]
		var p_next: Vector3 = raw_frames[(i + 2) % n]["pos"]
		var f0 := Vector3(p_cur.x - p_prev.x, 0.0, p_cur.z - p_prev.z).normalized()
		var f1 := Vector3(p_next.x - p_cur.x, 0.0, p_next.z - p_cur.z).normalized()
		if f0.length_squared() < 0.01 or f1.length_squared() < 0.01:
			banks[i] = 0.0
			continue
		var f_mid := (f0 + f1).normalized()
		var right_xz := f_mid.cross(Vector3.UP).normalized()
		var ds_xz := maxf(Vector2(p_next.x - p_prev.x, p_next.z - p_prev.z).length(), 1.0)
		var kappa := (f1 - f0).dot(right_xz) / ds_xz
		# Right turn (kappa > 0) -> positive bank leaning right INTO the turn; Left turn -> negative bank!
		banks[i] = clampf(atan(kappa * 42.0), -deg_to_rad(40.0), deg_to_rad(40.0))

	# Multi-pass Gaussian smoothing on bank angles so every curve leans smoothly BEFORE & THROUGH apex
	for _pass: int in range(10):
		var nb := PackedFloat32Array()
		nb.resize(n)
		for i: int in range(n):
			var rf: Dictionary = raw_frames[i]
			if bool(rf["is_loop"]):
				nb[i] = 0.0
			else:
				var w := 0.25 * banks[(i - 1 + n) % n] + 0.50 * banks[i] + 0.25 * banks[(i + 1) % n]
				if bool(rf.get("is_flat", false)):
					w *= 0.25
				nb[i] = w
		banks = nb

	# Zero residual bank inside loop entries/exits cleanly (last ~4 frames fade smoothly)
	total_length = 0.0
	for i: int in range(n):
		var cur: Dictionary = raw_frames[i]
		var next_r: Dictionary = raw_frames[(i + 1) % n]
		var prev_r: Dictionary = raw_frames[(i - 1 + n) % n]
		var p: Vector3 = cur["pos"]
		var next_p: Vector3 = next_r["pos"]

		var fwd: Vector3
		var right: Vector3
		var up: Vector3
		if bool(cur["is_loop"]):
			fwd = cur["fwd"]
			right = cur["right"]
			up = cur["up"]
		else:
			fwd = (next_p - (prev_r["pos"] as Vector3)).normalized()
			if fwd.length_squared() < 0.01:
				fwd = Vector3.RIGHT
			var raw_right := fwd.cross(Vector3.UP).normalized()
			if raw_right.length_squared() < 0.01:
				raw_right = Vector3.RIGHT
			var raw_up := raw_right.cross(fwd).normalized()
			var b_rad := banks[i]
			var rot_b := Basis(fwd, b_rad)
			right = (rot_b * raw_right).normalized()
			up = (rot_b * raw_up).normalized()

		var is_crest := bool(cur.get("is_crest", false))
		var is_boost := is_crest or (not bool(cur["is_loop"]) and bool(next_r["is_loop"])) or (bool(cur["is_loop"]) and float(cur["loop_u"]) < 0.14)
		var is_grid := bool(cur.get("is_flat", false))
		frames.append({
			"pos": p,
			"fwd": fwd,
			"right": right,
			"up": up,
			"bank_deg": rad_to_deg(banks[i]),
			"width": TRACK_WIDTH + (1.8 if is_grid else 0.0),
			"is_gap": false,
			"is_boost": is_boost,
			"is_crest_boost": is_crest,
			"is_loop": bool(cur["is_loop"]),
			"loop_u": float(cur.get("loop_u", 0.0)),
			"is_pit": is_grid,
			"s": total_length
		})
		total_length += p.distance_to(next_p)


func _sample_spiral_helix(start_pos: Vector3, fwd_dir: Vector3, turn_sign: float, turns: float, r_start: float, r_end: float, y_end: float, steps: int = 168) -> Array[Vector3]:
	var fwd0 := Vector3(fwd_dir.x, 0.0, fwd_dir.z).normalized()
	var right0 := fwd0.cross(Vector3.UP).normalized()
	var center := start_pos + right0 * (turn_sign * r_start)
	var rad0 := -right0 * turn_sign
	var out: Array[Vector3] = []
	for i: int in range(steps + 1):
		var u := float(i) / float(steps)
		var su := u * u * (3.0 - 2.0 * u)
		var r := lerpf(r_start, r_end, su)
		var y := lerpf(start_pos.y, y_end, su)
		var theta := u * turns * TAU
		var radial := rad0.rotated(Vector3.UP, -turn_sign * theta)
		out.append(Vector3(center.x + radial.x * r, y, center.z + radial.z * r))
	return out


func _sample_hermite_road(ctrl_pts: Array[Vector3], entry_tan: Vector3, exit_tan: Vector3, step_m: float = 3.0) -> Array[Vector3]:
	var n := ctrl_pts.size()
	var tans: Array[Vector3] = []
	for i: int in range(n):
		if i == 0:
			var seg0 := ctrl_pts[0].distance_to(ctrl_pts[1])
			tans.append(entry_tan.normalized() * maxf(seg0 * 0.85, 4.0))
		elif i == n - 1:
			var seg_e := ctrl_pts[n - 2].distance_to(ctrl_pts[n - 1])
			tans.append(exit_tan.normalized() * maxf(seg_e * 0.85, 4.0))
		else:
			var d := 0.5 * (ctrl_pts[i].distance_to(ctrl_pts[i - 1]) + ctrl_pts[i].distance_to(ctrl_pts[i + 1]))
			tans.append((ctrl_pts[i + 1] - ctrl_pts[i - 1]).normalized() * maxf(d * 0.90, 4.0))
	var out: Array[Vector3] = []
	for i: int in range(n - 1):
		var p0 := ctrl_pts[i]
		var p1 := ctrl_pts[i + 1]
		var m0 := tans[i]
		var m1 := tans[i + 1]
		var seg_d := p0.distance_to(p1)
		var steps := maxi(5, int(round(seg_d / step_m)))
		for s: int in range(steps):
			var t := float(s) / float(steps)
			var t2 := t * t
			var t3 := t2 * t
			var p := (2.0 * t3 - 3.0 * t2 + 1.0) * p0 + (t3 - 2.0 * t2 + t) * m0 + (-2.0 * t3 + 3.0 * t2) * p1 + (t3 - t2) * m1
			out.append(p)
	out.append(ctrl_pts[n - 1])
	return out


func _sample_clothoid_loop(start_pos: Vector3, fwd_dir: Vector3, radius_avg: float, side_shift: float, steps: int = 64) -> Array[Dictionary]:
	# Smooth C2 teardrop clothoid vertical loop: gentle large radius at entry/exit, tighter crown, smoothstep lateral helix!
	var fwd := Vector3(fwd_dir.x, 0.0, fwd_dir.z).normalized()
	var up_w := Vector3.UP
	var right := fwd.cross(up_w).normalized()
	var arc_len := TAU * radius_avg
	var ds := arc_len / float(steps)
	var theta := 0.0
	var p_f := 0.0
	var p_u := 0.0
	var out: Array[Dictionary] = []

	for i: int in range(steps + 1):
		var u := float(i) / float(steps)
		var su := u * u * (3.0 - 2.0 * u)
		var dsu := 6.0 * u * (1.0 - u)
		var pos := start_pos + fwd * p_f + up_w * p_u + right * (side_shift * su)
		var tang := (fwd * cos(theta) + up_w * sin(theta) + right * ((side_shift * dsu) / arc_len)).normalized()
		var raw_inward := (-fwd * sin(theta) + up_w * cos(theta)).normalized()
		var f_right := tang.cross(raw_inward).normalized()
		var f_up := f_right.cross(tang).normalized()
		out.append({
			"pos": pos,
			"fwd": tang,
			"right": f_right,
			"up": f_up,
			"is_loop": true,
			"loop_u": u,
			"is_flat": false,
			"is_crest": false
		})
		if i < steps:
			var u_mid := (float(i) + 0.5) / float(steps)
			var w_mid := (0.30 + 0.70 * pow(sin(PI * u_mid), 2.0)) / 0.65
			var dth := (TAU * w_mid) / float(steps)
			var th_mid := theta + dth * 0.5
			p_f += ds * cos(th_mid)
			p_u += ds * sin(th_mid)
			theta += dth
	return out


func _build_asphalt_pbr_textures() -> Array[Texture2D]:
	var sz := 256
	var alb := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	var rgh := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	var hgt := PackedFloat32Array()
	hgt.resize(sz * sz)

	var rng := RandomNumberGenerator.new()
	rng.seed = 42099

	for y: int in range(sz):
		var v := float(y) / float(sz)
		for x: int in range(sz):
			var u := float(x) / float(sz)
			var grain := rng.randf_range(-0.07, 0.07) + sin(u * TAU * 8.0 + v * TAU * 4.0) * 0.015
			hgt[y * sz + x] = grain
			# Tire track wear sheen along ~u=0.33 and u=0.67
			var tire_wear := exp(-pow((u - 0.34) / 0.11, 2.0)) + exp(-pow((u - 0.66) / 0.11, 2.0))
			var base_v := 0.28 + grain * 0.65 - tire_wear * 0.045
			var col := Color(base_v, base_v * 1.02, base_v * 1.07)

			# Subtle center dashed racing line & crisp edge shoulders
			if absf(u - 0.5) < 0.014 and fmod(v * 2.0, 1.0) < 0.55:
				col = Color(0.95, 0.80, 0.24)
			elif absf(u - 0.04) < 0.012 or absf(u - 0.96) < 0.012:
				col = Color(0.88, 0.90, 0.92)
			alb.set_pixel(x, y, col)

			var rough_v := clampf(0.76 - tire_wear * 0.34 - grain * 0.4, 0.32, 0.90)
			rgh.set_pixel(x, y, Color(rough_v, rough_v, rough_v, 1.0))

	var nor := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	for y: int in range(sz):
		var ym := (y - 1 + sz) % sz
		var yp := (y + 1) % sz
		for x: int in range(sz):
			var xm := (x - 1 + sz) % sz
			var xp := (x + 1) % sz
			var dx := (hgt[y * sz + xp] - hgt[y * sz + xm]) * 3.8
			var dy := (hgt[yp * sz + x] - hgt[ym * sz + x]) * 3.8
			var n := Vector3(-dx, -dy, 1.0).normalized() * 0.5 + Vector3(0.5, 0.5, 0.5)
			nor.set_pixel(x, y, Color(n.x, n.y, n.z, 1.0))

	alb.generate_mipmaps()
	nor.generate_mipmaps()
	rgh.generate_mipmaps()
	return [
		ImageTexture.create_from_image(alb),
		ImageTexture.create_from_image(nor),
		ImageTexture.create_from_image(rgh)
	]


func _build_track_geometry_and_collision() -> void:
	var pbr := _build_asphalt_pbr_textures()
	var road_mat := StandardMaterial3D.new()
	road_mat.albedo_color = Color(0.86, 0.88, 0.92)
	road_mat.vertex_color_use_as_albedo = true
	road_mat.albedo_texture = pbr[0]
	road_mat.normal_enabled = true
	road_mat.normal_texture = pbr[1]
	road_mat.normal_scale = 0.72
	road_mat.roughness_texture = pbr[2]
	road_mat.roughness = 0.95
	road_mat.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var rail_st := SurfaceTool.new()
	rail_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rail_mat := StandardMaterial3D.new()
	rail_mat.vertex_color_use_as_albedo = true
	rail_mat.metallic = 0.28
	rail_mat.roughness = 0.44
	rail_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var r_nor := load("res://assets/textures/pbr/marble_01/nor.jpg") as Texture2D
	if r_nor:
		rail_mat.normal_enabled = true; rail_mat.normal_texture = r_nor; rail_mat.normal_scale = 0.55

	var col_body := StaticBody3D.new()
	col_body.name = "RaceTrackCollider"
	add_child(col_body)

	_pillar_positions.clear()
	var pillar_tfs: Array[Transform3D] = []
	var lamp_positions: Array[Vector3] = []

	var n := frames.size()
	var rail_h_left := PackedFloat32Array()
	var rail_h_right := PackedFloat32Array()
	rail_h_left.resize(n)
	rail_h_right.resize(n)
	for i: int in range(n):
		var f_r: Dictionary = frames[i]
		var fp: Vector3 = f_r["pos"]
		var in_lp := bool(f_r["is_loop"])
		var pit_open := bool(f_r["is_pit"]) and fp.x >= -28.0 and fp.x <= 6.0 and absf(fp.z - 72.0) < 6.0
		rail_h_left[i] = 0.24 if in_lp else (0.12 if pit_open else 0.90)
		rail_h_right[i] = 0.24 if in_lp else 0.90
	for _rpass: int in range(3):
		var nl := PackedFloat32Array(); var nr := PackedFloat32Array()
		nl.resize(n); nr.resize(n)
		for i: int in range(n):
			nl[i] = 0.25 * rail_h_left[(i - 1 + n) % n] + 0.50 * rail_h_left[i] + 0.25 * rail_h_left[(i + 1) % n]
			nr[i] = 0.25 * rail_h_right[(i - 1 + n) % n] + 0.50 * rail_h_right[i] + 0.25 * rail_h_right[(i + 1) % n]
		rail_h_left = nl; rail_h_right = nr

	var uv_s := 0.0
	for i: int in range(n):
		var ni := (i + 1) % n
		var a: Dictionary = frames[i]
		var b: Dictionary = frames[ni]
		var pa: Vector3 = a["pos"]
		var pb: Vector3 = b["pos"]
		var seg_d := pa.distance_to(pb)
		var v0 := uv_s * 0.09
		var v1 := (uv_s + seg_d) * 0.09
		uv_s += seg_d

		var ra: Vector3 = a["right"] * (float(a["width"]) * 0.5)
		var rb: Vector3 = b["right"] * (float(b["width"]) * 0.5)
		var ra_u: Vector3 = a["right"]
		var rb_u: Vector3 = b["right"]
		var ua: Vector3 = a["up"]
		var ub: Vector3 = b["up"]

		var c_road := Color(0.92, 0.94, 0.96)
		if bool(a["is_crest_boost"]):
			c_road = Color(1.0, 0.62, 0.24)
		elif bool(a["is_boost"]):
			c_road = Color(0.95, 0.56, 0.18)
		elif bool(a["is_pit"]):
			c_road = Color(0.76, 0.80, 0.86)
		var c_curb := Color(0.92, 0.18, 0.16) if (i % 2 == 0) else Color(0.95, 0.95, 0.94)
		if bool(a["is_loop"]):
			c_curb = Color(0.14, 0.84, 1.0) if (i % 2 == 0) else Color(1.0, 0.80, 0.22)

		var ra_in: Vector3 = ra * 0.86
		var rb_in: Vector3 = rb * 0.86
		_add_quad_uv(st, pa - ra_in, pa + ra_in, pb + rb_in, pb - rb_in, ua, ub, c_road, Vector2(0.05, v0), Vector2(0.95, v0), Vector2(0.95, v1), Vector2(0.05, v1))
		_add_quad_uv(st, pa - ra, pa - ra_in, pb - rb_in, pb - rb, ua, ub, c_curb, Vector2(0.0, v0), Vector2(0.04, v0), Vector2(0.04, v1), Vector2(0.0, v1))
		_add_quad_uv(st, pa + ra_in, pa + ra, pb + rb, pb + rb_in, ua, ub, c_curb, Vector2(0.96, v0), Vector2(1.0, v0), Vector2(1.0, v1), Vector2(0.96, v1))

		var thick_a: Vector3 = -ua * 0.52
		var thick_b: Vector3 = -ub * 0.52
		_add_quad_uv(st, pb - rb + thick_b, pb + rb + thick_b, pa + ra + thick_a, pa - ra + thick_a, -ub, -ua, Color(0.16, 0.17, 0.20), Vector2.ZERO, Vector2.RIGHT, Vector2.ONE, Vector2.DOWN)
		_add_quad_uv(st, pa - ra + thick_a, pa - ra, pb - rb, pb - rb + thick_b, -ra_u, -rb_u, Color(0.32, 0.33, 0.37), Vector2.ZERO, Vector2.RIGHT, Vector2.ONE, Vector2.DOWN)
		_add_quad_uv(st, pa + ra, pa + ra + thick_a, pb + rb + thick_b, pb + rb, ra_u, rb_u, Color(0.32, 0.33, 0.37), Vector2.ZERO, Vector2.RIGHT, Vector2.ONE, Vector2.DOWN)

		var seg_mid := (pa + pb) * 0.5 - ((ua + ub) * 0.5) * 0.26
		var seg_len := seg_d + 0.16
		var seg_fwd := (pb - pa).normalized()
		var seg_up := (ua + ub).normalized()
		var seg_right := seg_fwd.cross(seg_up).normalized()
		seg_up = seg_right.cross(seg_fwd).normalized()
		var cs := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(float(a["width"]), 0.52, seg_len)
		cs.shape = box
		cs.transform = Transform3D(Basis(seg_right, seg_up, -seg_fwd), seg_mid)
		col_body.add_child(cs)

		# Continuous monolithic Jersey barriers extruded seamlessly along both edges
		for s_dir: float in [-1.0, 1.0]:
			var h_a := rail_h_left[i] if s_dir < 0.0 else rail_h_right[i]
			var h_b := rail_h_left[ni] if s_dir < 0.0 else rail_h_right[ni]
			var ea := pa + ra * s_dir
			var eb := pb + rb * s_dir
			var dir_out_a := ra_u * s_dir
			var dir_out_b := rb_u * s_dir

			var a_ib := ea - dir_out_a * 0.34
			var a_it := ea - dir_out_a * 0.18 + ua * h_a
			var a_ot := ea + dir_out_a * 0.06 + ua * h_a
			var a_ob := ea + dir_out_a * 0.06 - ua * 0.50

			var b_ib := eb - dir_out_b * 0.34
			var b_it := eb - dir_out_b * 0.18 + ub * h_b
			var b_ot := eb + dir_out_b * 0.06 + ub * h_b
			var b_ob := eb + dir_out_b * 0.06 - ub * 0.50

			var wall_c := Color(0.68, 0.72, 0.77) if not bool(a["is_loop"]) else Color(0.24, 0.34, 0.44)
			var cap_c := Color(0.92, 0.30, 0.18) if (bool(a["is_crest_boost"]) or bool(a["is_boost"])) else (Color(0.20, 0.86, 1.0) if bool(a["is_loop"]) else Color(0.86, 0.88, 0.92))
			# Inner sloped face, top cap, and outer face
			_add_quad_uv(rail_st, a_ib, a_it, b_it, b_ib, -dir_out_a, -dir_out_b, wall_c, Vector2(0, v0), Vector2(1, v0), Vector2(1, v1), Vector2(0, v1))
			_add_quad_uv(rail_st, a_it, a_ot, b_ot, b_it, ua, ub, cap_c, Vector2(0, v0), Vector2(1, v0), Vector2(1, v1), Vector2(0, v1))
			_add_quad_uv(rail_st, a_ot, a_ob, b_ob, b_ot, dir_out_a, dir_out_b, wall_c.darkened(0.14), Vector2(0, v0), Vector2(1, v0), Vector2(1, v1), Vector2(0, v1))

			var h_mid := 0.5 * (h_a + h_b)
			if h_mid >= 0.45:
				var wcs := CollisionShape3D.new()
				var wbox := BoxShape3D.new()
				wbox.size = Vector3(0.32, h_mid, seg_len)
				wcs.shape = wbox
				var edge_mid := 0.5 * (ea + eb) - 0.5 * (dir_out_a + dir_out_b) * 0.14 + seg_up * (h_mid * 0.5)
				wcs.transform = Transform3D(Basis(seg_right, seg_up, -seg_fwd), edge_mid)
				col_body.add_child(wcs)

		# Support pylons strictly verified NOT to intersect ANY other track coil, loop, or flyover
		if not bool(a["is_loop"]) and i % 6 == 0:
			var ground_c := _query_terrain_height(pa.x, pa.z)
			var slope_pad := absf((a["fwd"] as Vector3).y) * 1.15
			var center_top := pa.y - 0.56 - slope_pad
			if center_top > ground_c + 1.0:
				var r_xz := Vector3(ra_u.x, 0.0, ra_u.z)
				if r_xz.length_squared() < 0.01:
					r_xz = Vector3.RIGHT
				else:
					r_xz = r_xz.normalized()
				var c_xz := Vector2(pa.x, pa.z)
				if _can_place_pillar(c_xz, center_top, ground_c, i, false):
					var p_h := maxf(center_top - ground_c + 2.6, 2.2)
					pillar_tfs.append(Transform3D(Basis.IDENTITY.scaled(Vector3(1.0, p_h, 1.0)), Vector3(c_xz.x, center_top - p_h * 0.5, c_xz.y)))
					_pillar_positions.append({"xz": c_xz, "top_y": center_top, "bot_y": ground_c, "idx": i, "outrigger": false})
				else:
					var outriggers: Array[Vector2] = [
						Vector2(pa.x + r_xz.x * 7.8, pa.z + r_xz.z * 7.8),
						Vector2(pa.x - r_xz.x * 7.8, pa.z - r_xz.z * 7.8)
					]
					for cand: Vector2 in outriggers:
						var gh := _query_terrain_height(cand.x, cand.y)
						var top_y := pa.y - 0.56 - slope_pad
						if top_y > gh + 1.0 and _can_place_pillar(cand, top_y, gh, i, true):
							var p_h := maxf(top_y - gh + 2.6, 2.2)
							pillar_tfs.append(Transform3D(Basis.IDENTITY.scaled(Vector3(1.0, p_h, 1.0)), Vector3(cand.x, top_y - p_h * 0.5, cand.y)))
							_pillar_positions.append({"xz": cand, "top_y": top_y, "bot_y": gh, "idx": i, "outrigger": true})

		if bool(a["is_loop"]) and i % 28 == 14:
			lamp_positions.append(pa + ua * 4.0)

	_road_mesh_inst = MeshInstance3D.new()
	_road_mesh_inst.name = "RaceTrackRoadMesh"
	_road_mesh_inst.mesh = st.commit()
	_road_mesh_inst.material_override = road_mat
	add_child(_road_mesh_inst)

	_rail_mesh_inst = MeshInstance3D.new()
	_rail_mesh_inst.name = "RaceTrackBarrierMesh"
	_rail_mesh_inst.mesh = rail_st.commit()
	_rail_mesh_inst.material_override = rail_mat
	add_child(_rail_mesh_inst)

	if pillar_tfs.size() > 0:
		var pm := CylinderMesh.new(); pm.top_radius = 0.62; pm.bottom_radius = 0.85; pm.height = 1.0
		var p_mat := StandardMaterial3D.new()
		p_mat.albedo_color = Color(0.42, 0.43, 0.46)
		p_mat.roughness = 0.82
		var p_nor := load("res://assets/textures/pbr/marble_01/nor.jpg") as Texture2D
		if p_nor:
			p_mat.normal_enabled = true; p_mat.normal_texture = p_nor; p_mat.normal_scale = 0.7
		_pillar_mm = _add_mm(pm, p_mat, pillar_tfs)

	_build_loop_neon_rings(lamp_positions)


func _can_place_pillar(col_xz: Vector2, top_y: float, ground_h: float, own_idx: int, is_outrigger: bool = false) -> bool:
	if absf(col_xz.x) < 26.0 and absf(col_xz.y) < 18.0:
		return false
	if col_xz.distance_to(Vector2(-16.0, 64.0)) < 16.0:
		return false
	if col_xz.distance_to(Vector2(-58.0, 34.0)) < 18.0:
		return false
	if col_xz.y >= 10.0 and col_xz.y <= 70.0 and absf(col_xz.x) < 26.0:
		return false
	var n := frames.size()
	for j: int in range(n):
		var d_idx := mini(abs(j - own_idx), n - abs(j - own_idx))
		if not is_outrigger and d_idx <= 4:
			continue
		var qf: Dictionary = frames[j]
		var qp: Vector3 = qf["pos"]
		var q_clear := float(qf["width"]) * 0.5 + 2.5
		if Vector2(qp.x - col_xz.x, qp.z - col_xz.y).length() < q_clear:
			if qp.y <= top_y + 1.8 and qp.y >= ground_h - 1.5:
				return false
	return true


func _query_terrain_height(x: float, z: float) -> float:
	if terrain_height_fn.is_valid():
		return float(terrain_height_fn.call(x, z))
	var dist := Vector2(x, z).length()
	var rim := clampf((dist - 120.0) / 110.0, 0.0, 1.0)
	return 2.5 + rim * rim * 28.0


func _add_mm(mesh: Mesh, mat: Material, tfs: Array[Transform3D]) -> MultiMeshInstance3D:
	var mmi := MultiMeshInstance3D.new()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = tfs.size()
	for i: int in range(tfs.size()):
		mm.set_instance_transform(i, tfs[i])
	mmi.multimesh = mm
	mmi.material_override = mat
	add_child(mmi)
	return mmi


func _add_quad_uv(st: SurfaceTool, v0: Vector3, v1: Vector3, v2: Vector3, v3: Vector3, n0: Vector3, n1: Vector3, col: Color, uv0: Vector2, uv1: Vector2, uv2: Vector2, uv3: Vector2) -> void:
	st.set_color(col); st.set_normal(n0); st.set_uv(uv0); st.add_vertex(v0)
	st.set_color(col); st.set_normal(n0); st.set_uv(uv1); st.add_vertex(v1)
	st.set_color(col); st.set_normal(n1); st.set_uv(uv2); st.add_vertex(v2)
	st.set_color(col); st.set_normal(n0); st.set_uv(uv0); st.add_vertex(v0)
	st.set_color(col); st.set_normal(n1); st.set_uv(uv2); st.add_vertex(v2)
	st.set_color(col); st.set_normal(n1); st.set_uv(uv3); st.add_vertex(v3)


func _build_loop_neon_rings(lamp_positions: Array[Vector3]) -> void:
	var neon := StandardMaterial3D.new()
	neon.albedo_color = Color(0.18, 0.88, 1.0)
	neon.emission_enabled = true
	neon.emission = Color(0.18, 0.88, 1.0)
	neon.emission_energy_multiplier = 2.6
	for i: int in range(frames.size()):
		var f: Dictionary = frames[i]
		if bool(f["is_loop"]) and i % 6 == 0:
			var arch := TorusMesh.new(); arch.inner_radius = 6.0; arch.outer_radius = 6.38
			var mi := MeshInstance3D.new(); mi.mesh = arch; mi.material_override = neon
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
			var fw: Vector3 = f["fwd"]; var rt: Vector3 = f["right"]; var up: Vector3 = f["up"]
			mi.transform = Transform3D(Basis(rt, fw, up), (f["pos"] as Vector3) + up * 2.8)
			add_child(mi)
	for lp: Vector3 in lamp_positions:
		var l := OmniLight3D.new()
		l.position = lp
		l.light_color = Color(0.32, 0.88, 1.0)
		l.light_energy = 2.4
		l.omni_range = 22.0
		l.shadow_enabled = false
		add_child(l)


func _build_pit_stop_station() -> void:
	var pit := Node3D.new()
	pit.name = "RacePitStop"
	pit.position = Vector3(-16.0, 6.2, 72.0)
	add_child(pit)

	var concrete := StandardMaterial3D.new(); concrete.albedo_color = Color(0.58, 0.59, 0.62); concrete.roughness = 0.84
	var cn := load("res://assets/textures/pbr/marble_01/nor.jpg") as Texture2D
	if cn: concrete.normal_enabled = true; concrete.normal_texture = cn; concrete.normal_scale = 0.65
	var steel := StandardMaterial3D.new(); steel.albedo_color = Color(0.24, 0.26, 0.30); steel.metallic = 0.85; steel.roughness = 0.28
	var red_mat := StandardMaterial3D.new(); red_mat.albedo_color = Color(0.84, 0.16, 0.14); red_mat.roughness = 0.24; red_mat.metallic = 0.45; red_mat.clearcoat_enabled = true

	# Pit Canopy Shelter on North Side (Z=-7.4 relative to Start Line)
	var pad := BoxMesh.new(); pad.size = Vector3(16.0, 0.4, 7.2)
	var pmi := MeshInstance3D.new(); pmi.mesh = pad; pmi.material_override = concrete; pmi.position = Vector3(0.0, -0.05, -8.4)
	pit.add_child(pmi)
	var sb_pad := StaticBody3D.new(); sb_pad.position = Vector3(0.0, -0.05, -8.4)
	var cs_pad := CollisionShape3D.new(); var bs_pad := BoxShape3D.new(); bs_pad.size = Vector3(16.0, 0.4, 7.2)
	cs_pad.shape = bs_pad; sb_pad.add_child(cs_pad); pit.add_child(sb_pad)

	for px: float in [-6.8, 6.8]:
		var col := BoxMesh.new(); col.size = Vector3(0.45, 4.4, 0.45)
		var cmi := MeshInstance3D.new(); cmi.mesh = col; cmi.material_override = red_mat; cmi.position = Vector3(px, 2.2, -10.4)
		pit.add_child(cmi)
		var cmi2 := MeshInstance3D.new(); cmi2.mesh = col; cmi2.material_override = red_mat; cmi2.position = Vector3(px, 2.2, -6.4)
		pit.add_child(cmi2)

	var roof := BoxMesh.new(); roof.size = Vector3(15.6, 0.38, 6.4)
	var rmi := MeshInstance3D.new(); rmi.mesh = roof; rmi.material_override = red_mat; rmi.position = Vector3(0.0, 4.55, -8.4)
	pit.add_child(rmi)

	var sign_lbl := Label3D.new()
	sign_lbl.font = ConfigManager.get_ui_font()
	sign_lbl.text = ConfigManager.t("sign_track")
	sign_lbl.position = Vector3(0.0, 5.15, -5.0)
	sign_lbl.pixel_size = 0.0085
	sign_lbl.font_size = 48
	sign_lbl.modulate = Color(1.0, 0.90, 0.36)
	pit.add_child(sign_lbl)

	var pit_l := OmniLight3D.new()
	pit_l.position = Vector3(0.0, 3.9, -6.4); pit_l.light_color = Color(1.0, 0.90, 0.72)
	pit_l.light_energy = 2.8; pit_l.omni_range = 18.0; pit_l.shadow_enabled = false
	pit.add_child(pit_l)

	# Checkered Start/Finish Gantry Bridge across track at (0, 0, 0) in Pit space (facing -X along approaching Grid)
	for sx: float in [-6.4, 6.4]:
		var ap := BoxMesh.new(); ap.size = Vector3(0.55, 6.2, 0.55)
		var ami := MeshInstance3D.new(); ami.mesh = ap; ami.material_override = steel; ami.position = Vector3(0.0, 3.1, sx)
		pit.add_child(ami)
	var gantry_bar := BoxMesh.new(); gantry_bar.size = Vector3(1.1, 0.9, 13.6)
	var tmi := MeshInstance3D.new(); tmi.mesh = gantry_bar; tmi.material_override = steel; tmi.position = Vector3(0.0, 5.9, 0.0)
	pit.add_child(tmi)

	# Overhead 3D Racing Traffic Light ("Світлофор") visible cleanly from Starting Grid (looking +X toward X=0)!
	var tl_box := BoxMesh.new(); tl_box.size = Vector3(0.55, 2.2, 3.6)
	var tl_mi := MeshInstance3D.new(); tl_mi.mesh = tl_box; tl_mi.material_override = steel; tl_mi.position = Vector3(-0.35, 5.1, 0.0)
	pit.add_child(tl_mi)

	for key: String in ["red", "amber", "green"]:
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.14, 0.14, 0.14)
		m.roughness = 0.25
		m.emission_enabled = true
		m.emission = Color.BLACK
		m.emission_energy_multiplier = 0.0
		_tl_mats[key] = m

	var bulb_mesh := SphereMesh.new(); bulb_mesh.radius = 0.24; bulb_mesh.height = 0.44
	var rows := [
		{"key": "red", "y": 5.75},
		{"key": "amber", "y": 5.10},
		{"key": "green", "y": 4.45}
	]
	for row in rows:
		var k := str(row["key"])
		for lz: float in [-1.1, 0.0, 1.1]:
			var bmi := MeshInstance3D.new()
			bmi.mesh = bulb_mesh
			bmi.material_override = _tl_mats[k]
			bmi.position = Vector3(-0.62, float(row["y"]), lz)
			pit.add_child(bmi)
			(_tl_bulbs[k] as Array).append(bmi)

	_gantry_light = OmniLight3D.new()
	_gantry_light.position = Vector3(-1.4, 4.6, 0.0)
	_gantry_light.light_color = Color(1.0, 0.90, 0.72)
	_gantry_light.light_energy = 1.8
	_gantry_light.omni_range = 24.0
	pit.add_child(_gantry_light)

	# Parked Player Car waiting beside Pit Canopy (-X = -16, Z = -6.8)
	pit_parked_car = build_sports_car_mesh(Color(0.14, 0.48, 0.96), false)
	pit_parked_car.position = Vector3(0.0, 0.25, -7.2)
	pit_parked_car.rotation.y = -PI * 0.5
	pit.add_child(pit_parked_car)

	var inter := StaticBody3D.new()
	inter.name = "RaceStartInteract"
	inter.collision_layer = 2
	inter.collision_mask = 0
	inter.position = Vector3(0.0, 1.1, -7.2)
	var ics := CollisionShape3D.new()
	var ibox := BoxShape3D.new(); ibox.size = Vector3(5.8, 2.2, 3.4)
	ics.shape = ibox
	inter.add_child(ics)
	inter.set_meta("interact_id", "race_start")
	inter.set_meta("interact_title", ConfigManager.t("prop_race_start"))
	pit.add_child(inter)


func set_traffic_light(phase: String) -> void:
	if _tl_mats.is_empty():
		return
	var r_mat: StandardMaterial3D = _tl_mats["red"]
	var a_mat: StandardMaterial3D = _tl_mats["amber"]
	var g_mat: StandardMaterial3D = _tl_mats["green"]

	r_mat.emission = Color(1.0, 0.14, 0.10); r_mat.emission_energy_multiplier = 0.0; r_mat.albedo_color = Color(0.20, 0.06, 0.06)
	a_mat.emission = Color(1.0, 0.68, 0.08); a_mat.emission_energy_multiplier = 0.0; a_mat.albedo_color = Color(0.22, 0.15, 0.04)
	g_mat.emission = Color(0.12, 1.0, 0.36); g_mat.emission_energy_multiplier = 0.0; g_mat.albedo_color = Color(0.06, 0.20, 0.08)

	match phase:
		"red3":
			r_mat.emission_energy_multiplier = 5.5; r_mat.albedo_color = Color(1.0, 0.25, 0.20)
			if _gantry_light:
				_gantry_light.light_color = Color(1.0, 0.22, 0.18); _gantry_light.light_energy = 5.2
		"red2":
			r_mat.emission_energy_multiplier = 6.2; r_mat.albedo_color = Color(1.0, 0.25, 0.20)
			a_mat.emission_energy_multiplier = 2.6; a_mat.albedo_color = Color(1.0, 0.72, 0.20)
			if _gantry_light:
				_gantry_light.light_color = Color(1.0, 0.38, 0.15); _gantry_light.light_energy = 5.8
		"amber1":
			a_mat.emission_energy_multiplier = 6.0; a_mat.albedo_color = Color(1.0, 0.78, 0.18)
			if _gantry_light:
				_gantry_light.light_color = Color(1.0, 0.74, 0.16); _gantry_light.light_energy = 6.0
		"go":
			g_mat.emission_energy_multiplier = 6.8; g_mat.albedo_color = Color(0.24, 1.0, 0.45)
			if _gantry_light:
				_gantry_light.light_color = Color(0.24, 1.0, 0.48); _gantry_light.light_energy = 6.5
		_:
			if _gantry_light:
				_gantry_light.light_color = Color(1.0, 0.90, 0.72); _gantry_light.light_energy = 1.8


static func _get_f1_textures() -> Dictionary:
	if not _f1_tex_cache.is_empty():
		return _f1_tex_cache

	# 1. Twill 2x2 Carbon Fiber Weave (Albedo + Normal + Roughness)
	var csz := 64
	var c_alb := Image.create(csz, csz, false, Image.FORMAT_RGBA8)
	var c_rgh := Image.create(csz, csz, false, Image.FORMAT_RGBA8)
	var c_hgt := PackedFloat32Array()
	c_hgt.resize(csz * csz)
	for y: int in range(csz):
		for x: int in range(csz):
			var tx := (x / 2)
			var ty := (y / 2)
			var diag := (tx + ty) % 4
			var warp := (diag < 2)
			var sub := (x % 2) if warp else (y % 2)
			var shade := (0.24 if warp else 0.14) + float(sub) * 0.03
			c_alb.set_pixel(x, y, Color(shade, shade * 1.02, shade * 1.08, 1.0))
			c_hgt[y * csz + x] = (0.75 if warp else 0.25) + float(sub) * 0.12
			var rv := 0.28 if warp else 0.50
			c_rgh.set_pixel(x, y, Color(rv, rv, rv, 1.0))
	var c_nor := Image.create(csz, csz, false, Image.FORMAT_RGBA8)
	for y: int in range(csz):
		for x: int in range(csz):
			var dx := (c_hgt[y * csz + ((x + 1) % csz)] - c_hgt[y * csz + ((x - 1 + csz) % csz)]) * 2.2
			var dy := (c_hgt[((y + 1) % csz) * csz + x] - c_hgt[((y - 1 + csz) % csz) * csz + x]) * 2.2
			var n := Vector3(-dx, -dy, 1.0).normalized() * 0.5 + Vector3(0.5, 0.5, 0.5)
			c_nor.set_pixel(x, y, Color(n.x, n.y, n.z, 1.0))

	# 2. Glossy Team Livery Paint Texture (Metallic Flake + Racing Pin-Stripes + Panel Shutlines + Cooling Louvres)
	var lsz := 256
	var l_alb := Image.create(lsz, lsz, false, Image.FORMAT_RGBA8)
	var l_rgh := Image.create(lsz, lsz, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 77123
	for y: int in range(lsz):
		var v := float(y) / float(lsz)
		for x: int in range(lsz):
			var u := float(x) / float(lsz)
			var flake := rng.randf_range(-0.025, 0.025)
			var col := Color(0.95 + flake, 0.96 + flake, 0.98 + flake, 1.0)
			var rval := 0.14 + absf(flake) * 0.8
			# Twin white/gold center nose stripe & side accent trim
			if absf(u - 0.5) < 0.032 or absf(u - 0.14) < 0.018 or absf(u - 0.86) < 0.018:
				col = Color(1.0, 0.98, 0.92, 1.0)
			# Panel seams & micro rivets
			if (y % 64 == 0) or (absf(u - 0.25) < 0.004) or (absf(u - 0.75) < 0.004):
				col = col.darkened(0.32)
				rval = 0.42
			# Side cooling gill vents near v=0.45..0.68
			if v > 0.46 and v < 0.68 and (y % 12 < 3) and (absf(u - 0.20) < 0.05 or absf(u - 0.80) < 0.05):
				col = Color(0.28, 0.29, 0.32, 1.0)
				rval = 0.65
			l_alb.set_pixel(x, y, col)
			l_rgh.set_pixel(x, y, Color(rval, rval, rval, 1.0))

	# 3. Grooved F1 Rubber Tread & Grain Texture (Albedo + Normal)
	var tsz := 128
	var t_alb := Image.create(tsz, tsz, false, Image.FORMAT_RGBA8)
	var t_hgt := PackedFloat32Array()
	t_hgt.resize(tsz * tsz)
	for y: int in range(tsz):
		var v := float(y) / float(tsz)
		for x: int in range(tsz):
			var u := float(x) / float(tsz)
			var rubber := rng.randf_range(-0.03, 0.03)
			var groove := 0.0
			if v < 0.50: # Tire tread barrel region
				for g: float in [0.16, 0.34, 0.50, 0.66, 0.84]:
					if absf(fmod(v * 2.0, 1.0) - g) < 0.035:
						groove = 1.0
				# Angled water-channel chevron sipes
				if absf(fmod(u * 12.0 + v * 4.0, 1.0) - 0.5) < 0.07:
					groove = maxf(groove, 0.75)
			var tv := clampf(0.11 + rubber - groove * 0.05, 0.03, 0.22)
			t_alb.set_pixel(x, y, Color(tv, tv, tv * 1.04, 1.0))
			t_hgt[y * tsz + x] = 1.0 - groove * 0.85 + rubber * 2.5
	var t_nor := Image.create(tsz, tsz, false, Image.FORMAT_RGBA8)
	for y: int in range(tsz):
		for x: int in range(tsz):
			var dx := (t_hgt[y * tsz + ((x + 1) % tsz)] - t_hgt[y * tsz + ((x - 1 + tsz) % tsz)]) * 2.6
			var dy := (t_hgt[((y + 1) % tsz) * tsz + x] - t_hgt[((y - 1 + tsz) % tsz) * tsz + x]) * 2.6
			var n := Vector3(-dx, -dy, 1.0).normalized() * 0.5 + Vector3(0.5, 0.5, 0.5)
			t_nor.set_pixel(x, y, Color(n.x, n.y, n.z, 1.0))

	for img: Image in [c_alb, c_nor, c_rgh, l_alb, l_rgh, t_alb, t_nor]:
		img.generate_mipmaps()

	_f1_tex_cache = {
		"carbon_alb": ImageTexture.create_from_image(c_alb),
		"carbon_nor": ImageTexture.create_from_image(c_nor),
		"carbon_rgh": ImageTexture.create_from_image(c_rgh),
		"livery_alb": ImageTexture.create_from_image(l_alb),
		"livery_rgh": ImageTexture.create_from_image(l_rgh),
		"tire_alb": ImageTexture.create_from_image(t_alb),
		"tire_nor": ImageTexture.create_from_image(t_nor)
	}
	return _f1_tex_cache


static func _make_loft_hull_mesh(sections: Array) -> ArrayMesh:
	# Each section: [z, width, y_bot, y_top, slope_inset_top]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: Array = []
	var n_sec := sections.size()
	for si: int in range(n_sec):
		var s: Array = sections[si]
		var z := float(s[0])
		var hw := float(s[1]) * 0.5
		var yb := float(s[2])
		var yt := float(s[3])
		var it := hw * float(s[4])
		var u_v := float(si) / maxf(float(n_sec - 1), 1.0)
		# Closed 6-point cross-section (CW from rear -> counter-clockwise exterior)
		rings.append([
			{"p": Vector3(-hw, yb + 0.04, z), "u": 0.08, "v": u_v},
			{"p": Vector3(hw, yb + 0.04, z), "u": 0.92, "v": u_v},
			{"p": Vector3(hw * 0.88, (yb + yt) * 0.55, z), "u": 0.78, "v": u_v},
			{"p": Vector3(it, yt, z), "u": 0.58, "v": u_v},
			{"p": Vector3(-it, yt, z), "u": 0.42, "v": u_v},
			{"p": Vector3(-hw * 0.88, (yb + yt) * 0.55, z), "u": 0.22, "v": u_v}
		])
	var k := 6
	for si: int in range(n_sec - 1):
		var r0: Array = rings[si]
		var r1: Array = rings[si + 1]
		for j: int in range(k):
			var jn := (j + 1) % k
			var a: Dictionary = r0[j]; var b: Dictionary = r0[jn]
			var c: Dictionary = r1[jn]; var d: Dictionary = r1[j]
			st.set_uv(Vector2(a["u"], a["v"])); st.add_vertex(a["p"])
			st.set_uv(Vector2(b["u"], b["v"])); st.add_vertex(b["p"])
			st.set_uv(Vector2(c["u"], c["v"])); st.add_vertex(c["p"])
			st.set_uv(Vector2(a["u"], a["v"])); st.add_vertex(a["p"])
			st.set_uv(Vector2(c["u"], c["v"])); st.add_vertex(c["p"])
			st.set_uv(Vector2(d["u"], d["v"])); st.add_vertex(d["p"])
	# Front & Rear end caps
	for cap_idx: int in [0, n_sec - 1]:
		var rc: Array = rings[cap_idx]
		var flip := (cap_idx == n_sec - 1)
		for j: int in range(1, k - 1):
			var p0: Vector3 = rc[0]["p"]
			var p1: Vector3 = rc[j if flip else j + 1]["p"]
			var p2: Vector3 = rc[j + 1 if flip else j]["p"]
			st.set_uv(Vector2(0.5, 0.5)); st.add_vertex(p0)
			st.set_uv(Vector2(0.6, 0.5)); st.add_vertex(p1)
			st.set_uv(Vector2(0.5, 0.6)); st.add_vertex(p2)
	st.generate_normals()
	return st.commit()


static func _add_f1_part(parent: Node3D, mesh: Mesh, mat: Material, pos: Vector3, rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	if rot_deg != Vector3.ZERO:
		mi.rotation_degrees = rot_deg
	parent.add_child(mi)
	return mi


static func build_sports_car_mesh(body_col: Color, with_headlights: bool = false) -> Node3D:
	var tex := _get_f1_textures()
	var root := Node3D.new()

	var paint := StandardMaterial3D.new()
	paint.albedo_color = body_col.lightened(0.08)
	paint.albedo_texture = tex["livery_alb"]
	paint.roughness_texture = tex["livery_rgh"]
	paint.roughness = 0.85
	paint.metallic = 0.72
	paint.clearcoat_enabled = true
	paint.clearcoat = 0.96
	paint.clearcoat_roughness = 0.05

	var accent_paint := StandardMaterial3D.new()
	accent_paint.albedo_color = body_col.lightened(0.28)
	accent_paint.roughness = 0.16; accent_paint.metallic = 0.68
	accent_paint.clearcoat_enabled = true; accent_paint.clearcoat = 0.92

	var carbon := StandardMaterial3D.new()
	carbon.albedo_texture = tex["carbon_alb"]
	carbon.normal_enabled = true
	carbon.normal_texture = tex["carbon_nor"]
	carbon.normal_scale = 0.85
	carbon.roughness_texture = tex["carbon_rgh"]
	carbon.roughness = 0.95
	carbon.metallic = 0.25
	carbon.uv1_scale = Vector3(10.0, 10.0, 1.0)

	var titanium := StandardMaterial3D.new()
	titanium.albedo_color = Color(0.62, 0.65, 0.70)
	titanium.metallic = 0.92; titanium.roughness = 0.22

	var helmet_mat := StandardMaterial3D.new()
	helmet_mat.albedo_color = Color(0.95, 0.95, 0.96)
	helmet_mat.roughness = 0.12; helmet_mat.metallic = 0.35; helmet_mat.clearcoat_enabled = true

	var visor_mat := StandardMaterial3D.new()
	visor_mat.albedo_color = Color(0.06, 0.14, 0.24)
	visor_mat.metallic = 0.88; visor_mat.roughness = 0.04; visor_mat.clearcoat_enabled = true

	var tire_mat := StandardMaterial3D.new()
	tire_mat.albedo_texture = tex["tire_alb"]
	tire_mat.normal_enabled = true
	tire_mat.normal_texture = tex["tire_nor"]
	tire_mat.normal_scale = 0.9
	tire_mat.roughness = 0.88

	var compound_ring := StandardMaterial3D.new()
	var ring_tint := body_col.lightened(0.35)
	compound_ring.albedo_color = ring_tint
	compound_ring.emission_enabled = true
	compound_ring.emission = ring_tint
	compound_ring.emission_energy_multiplier = 0.55
	compound_ring.roughness = 0.35

	var rim_mat := StandardMaterial3D.new()
	rim_mat.albedo_color = Color(0.86, 0.88, 0.92); rim_mat.metallic = 0.95; rim_mat.roughness = 0.16

	var caliper_mat := StandardMaterial3D.new()
	caliper_mat.albedo_color = Color(0.92, 0.16, 0.12); caliper_mat.metallic = 0.55; caliper_mat.roughness = 0.25

	var head_glow := StandardMaterial3D.new()
	head_glow.albedo_color = Color(1.0, 0.96, 0.84); head_glow.emission_enabled = true; head_glow.emission = Color(1.0, 0.95, 0.78); head_glow.emission_energy_multiplier = 3.2

	var tail_glow := StandardMaterial3D.new()
	tail_glow.albedo_color = Color(1.0, 0.14, 0.10); tail_glow.emission_enabled = true; tail_glow.emission = Color(1.0, 0.12, 0.08); tail_glow.emission_energy_multiplier = 3.5

	var body_pivot := Node3D.new()
	body_pivot.name = "BodyPivot"
	root.add_child(body_pivot)

	# 1. Sculpted Monocoque Needle-Nose Chassis & Tapered Coke-Bottle Engine Cover
	var monocoque := _make_loft_hull_mesh([
		[-2.44, 0.24, 0.22, 0.30, 0.65],
		[-1.65, 0.46, 0.20, 0.48, 0.62],
		[-0.62, 0.68, 0.18, 0.64, 0.58],
		[0.36, 0.76, 0.18, 0.68, 0.56],
		[1.36, 0.52, 0.22, 0.74, 0.45],
		[2.16, 0.26, 0.28, 0.48, 0.52]
	])
	_add_f1_part(body_pivot, monocoque, paint, Vector3.ZERO)

	# 2. Twin Undercut Sculpted Aero Sidepods + Radiator Scoop Apertures + Mirrors
	for sx: float in [-1.0, 1.0]:
		var sidepod := _make_loft_hull_mesh([
			[-0.25, 0.48, 0.20, 0.60, 0.75],
			[0.35, 0.54, 0.20, 0.62, 0.70],
			[1.05, 0.40, 0.22, 0.52, 0.60],
			[1.65, 0.18, 0.24, 0.40, 0.50]
		])
		_add_f1_part(body_pivot, sidepod, paint, Vector3(sx * 0.52, 0.0, 0.0))
		# Dark radiator scoop cavity
		var rad := BoxMesh.new(); rad.size = Vector3(0.40, 0.28, 0.06)
		_add_f1_part(body_pivot, rad, carbon, Vector3(sx * 0.54, 0.40, -0.27))
		# Bargeboard aero vane beside cockpit
		var barge := BoxMesh.new(); barge.size = Vector3(0.04, 0.30, 0.65)
		_add_f1_part(body_pivot, barge, carbon, Vector3(sx * 0.68, 0.30, -0.68), Vector3(0.0, sx * 12.0, 0.0))
		# F1 Wing Mirror pod + carbon stalk
		var m_stalk := BoxMesh.new(); m_stalk.size = Vector3(0.24, 0.03, 0.04)
		_add_f1_part(body_pivot, m_stalk, carbon, Vector3(sx * 0.46, 0.68, -0.45))
		var m_pod := BoxMesh.new(); m_pod.size = Vector3(0.18, 0.08, 0.12)
		_add_f1_part(body_pivot, m_pod, accent_paint, Vector3(sx * 0.58, 0.72, -0.45))

	# 3. Carbon Venturi Undertray Floor Plank + Side Skirts + Rear 5-Strake Diffuser
	var floor_m := BoxMesh.new(); floor_m.size = Vector3(1.88, 0.05, 3.30)
	_add_f1_part(body_pivot, floor_m, carbon, Vector3(0.0, 0.16, 0.40))
	for sx: float in [-0.94, 0.94]:
		var skirt := BoxMesh.new(); skirt.size = Vector3(0.05, 0.08, 2.35)
		_add_f1_part(body_pivot, skirt, accent_paint, Vector3(sx, 0.18, 0.62))
	var diff_box := BoxMesh.new(); diff_box.size = Vector3(1.16, 0.18, 0.38)
	_add_f1_part(body_pivot, diff_box, carbon, Vector3(0.0, 0.24, 2.08), Vector3(-16.0, 0.0, 0.0))
	for fx: float in [-0.46, -0.23, 0.0, 0.23, 0.46]:
		var fin := BoxMesh.new(); fin.size = Vector3(0.03, 0.18, 0.42)
		_add_f1_part(body_pivot, fin, carbon, Vector3(fx, 0.23, 2.12))

	# 4. Multi-Plane Sculpted Front Wing + Cascade Flaps + Curled Endplates (Z = -2.28)
	var fw_main := BoxMesh.new(); fw_main.size = Vector3(2.14, 0.04, 0.46)
	_add_f1_part(body_pivot, fw_main, carbon, Vector3(0.0, 0.18, -2.30))
	var fw_flap := BoxMesh.new(); fw_flap.size = Vector3(2.04, 0.035, 0.24)
	_add_f1_part(body_pivot, fw_flap, accent_paint, Vector3(0.0, 0.25, -2.14), Vector3(18.0, 0.0, 0.0))
	var fw_tip := BoxMesh.new(); fw_tip.size = Vector3(0.32, 0.045, 0.14)
	_add_f1_part(body_pivot, fw_tip, head_glow, Vector3(0.0, 0.27, -2.47))
	for sx: float in [-1.07, 1.07]:
		var ep := BoxMesh.new(); ep.size = Vector3(0.045, 0.28, 0.56)
		_add_f1_part(body_pivot, ep, carbon, Vector3(sx, 0.29, -2.24))
		var ep_trim := BoxMesh.new(); ep_trim.size = Vector3(0.055, 0.06, 0.52)
		_add_f1_part(body_pivot, ep_trim, accent_paint, Vector3(sx, 0.39, -2.24))

	# 5. Open Cockpit, Driver Helmet + Visor, Titanium HALO Hoop, Airbox, Shark Fin & T-Cam
	var cockpit_well := BoxMesh.new(); cockpit_well.size = Vector3(0.52, 0.22, 0.82)
	_add_f1_part(body_pivot, cockpit_well, carbon, Vector3(0.0, 0.62, -0.02))
	var helm_s := SphereMesh.new(); helm_s.radius = 0.17; helm_s.height = 0.32
	_add_f1_part(body_pivot, helm_s, helmet_mat, Vector3(0.0, 0.78, 0.08))
	var visor_m := CylinderMesh.new(); visor_m.top_radius = 0.175; visor_m.bottom_radius = 0.175; visor_m.height = 0.09
	_add_f1_part(body_pivot, visor_m, visor_mat, Vector3(0.0, 0.79, 0.05))
	# F1 HALO protection hoop + center pillar
	var halo_ring := TorusMesh.new(); halo_ring.inner_radius = 0.23; halo_ring.outer_radius = 0.275
	_add_f1_part(body_pivot, halo_ring, titanium, Vector3(0.0, 0.89, 0.04), Vector3(12.0, 0.0, 0.0))
	var halo_strut := CylinderMesh.new(); halo_strut.top_radius = 0.032; halo_strut.bottom_radius = 0.038; halo_strut.height = 0.34
	_add_f1_part(body_pivot, halo_strut, carbon, Vector3(0.0, 0.77, -0.28), Vector3(36.0, 0.0, 0.0))
	# Airbox Roll-Hoop Intake + Shark Fin + Top T-Cam
	var airbox := BoxMesh.new(); airbox.size = Vector3(0.32, 0.34, 0.62)
	_add_f1_part(body_pivot, airbox, paint, Vector3(0.0, 0.86, 0.60))
	var air_hole := BoxMesh.new(); air_hole.size = Vector3(0.22, 0.18, 0.06)
	_add_f1_part(body_pivot, air_hole, carbon, Vector3(0.0, 0.90, 0.29))
	var shark_fin := BoxMesh.new(); shark_fin.size = Vector3(0.04, 0.34, 1.05)
	_add_f1_part(body_pivot, shark_fin, accent_paint, Vector3(0.0, 0.88, 1.35), Vector3(-12.0, 0.0, 0.0))
	var tcam_stem := CylinderMesh.new(); tcam_stem.top_radius = 0.02; tcam_stem.bottom_radius = 0.025; tcam_stem.height = 0.14
	_add_f1_part(body_pivot, tcam_stem, carbon, Vector3(0.0, 1.09, 0.56))
	var tcam_bar := BoxMesh.new(); tcam_bar.size = Vector3(0.36, 0.045, 0.10)
	_add_f1_part(body_pivot, tcam_bar, carbon, Vector3(0.0, 1.16, 0.56))

	# 6. Dual-Plane DRS Rear Wing, Slotted Endplates, Titanium Exhausts & Glowing FIA Rain Light
	var rw_pylon := BoxMesh.new(); rw_pylon.size = Vector3(0.06, 0.58, 0.34)
	_add_f1_part(body_pivot, rw_pylon, carbon, Vector3(0.0, 0.74, 2.16), Vector3(-14.0, 0.0, 0.0))
	var rw_main := BoxMesh.new(); rw_main.size = Vector3(1.56, 0.05, 0.36)
	_add_f1_part(body_pivot, rw_main, carbon, Vector3(0.0, 0.98, 2.24), Vector3(10.0, 0.0, 0.0))
	var rw_drs := BoxMesh.new(); rw_drs.size = Vector3(1.52, 0.045, 0.22)
	_add_f1_part(body_pivot, rw_drs, accent_paint, Vector3(0.0, 1.12, 2.34), Vector3(28.0, 0.0, 0.0))
	for sx: float in [-0.78, 0.78]:
		var rep := BoxMesh.new(); rep.size = Vector3(0.045, 0.62, 0.48)
		_add_f1_part(body_pivot, rep, paint, Vector3(sx, 0.92, 2.26))
	# Dual Exhaust Pipes + Center Bright Red F1 Rain Light
	for ex: float in [-0.14, 0.14]:
		var exm := CylinderMesh.new(); exm.top_radius = 0.042; exm.bottom_radius = 0.048; exm.height = 0.24
		_add_f1_part(body_pivot, exm, titanium, Vector3(ex, 0.42, 2.20), Vector3(90.0, 0.0, 0.0))
	var fia_led := BoxMesh.new(); fia_led.size = Vector3(0.14, 0.14, 0.08)
	_add_f1_part(body_pivot, fia_led, tail_glow, Vector3(0.0, 0.34, 2.26))

	# 7. Carbon Double-Wishbone Open-Wheel Suspension Arms & Real SpotLight3D Headlights
	var arm_m := BoxMesh.new(); arm_m.size = Vector3(0.68, 0.028, 0.065)
	for wp_s: Vector3 in [Vector3(-1.0, 0.36, -1.52), Vector3(1.0, 0.36, -1.52), Vector3(-1.0, 0.39, 1.46), Vector3(1.0, 0.39, 1.46)]:
		_add_f1_part(body_pivot, arm_m, carbon, Vector3(wp_s.x * 0.58, wp_s.y + 0.06, wp_s.z - 0.08), Vector3(0.0, wp_s.x * 14.0, wp_s.x * -6.0))
		_add_f1_part(body_pivot, arm_m, carbon, Vector3(wp_s.x * 0.58, wp_s.y - 0.08, wp_s.z + 0.08), Vector3(0.0, -wp_s.x * 14.0, 0.0))

	if with_headlights:
		for lx: float in [-0.55, 0.55]:
			var spot := SpotLight3D.new()
			spot.position = Vector3(lx, 0.58, -2.35)
			spot.light_color = Color(1.0, 0.96, 0.86)
			spot.light_energy = 4.6
			spot.spot_range = 64.0
			spot.spot_angle = 32.0
			spot.shadow_enabled = (lx < 0.0) and int(ConfigManager.graphics.get("shadows", 3)) >= 2
			spot.shadow_bias = 0.04
			body_pivot.add_child(spot)

	# 8. True Staggered Open-Wheel F1 Tires (Pure +X Axle Spin Pivot + Sidewall Compound Rings + 5-Spoke Rims!)
	var wheel_specs := [
		{"pos": Vector3(-1.02, 0.36, -1.54), "rad": 0.36, "w": 0.34, "side": -1.0},
		{"pos": Vector3(1.02, 0.36, -1.54), "rad": 0.36, "w": 0.34, "side": 1.0},
		{"pos": Vector3(-1.04, 0.39, 1.46), "rad": 0.39, "w": 0.44, "side": -1.0},
		{"pos": Vector3(1.04, 0.39, 1.46), "rad": 0.39, "w": 0.44, "side": 1.0}
	]
	var wheel_pivots: Array[Node3D] = []
	var wheel_spins: Array[Node3D] = []
	for ws in wheel_specs:
		var wpiv := Node3D.new()
		wpiv.position = ws["pos"]
		root.add_child(wpiv)

		var spin_piv := Node3D.new()
		wpiv.add_child(spin_piv)

		var rad := float(ws["rad"])
		var wid := float(ws["w"])
		var side := float(ws["side"])

		var wm := CylinderMesh.new(); wm.top_radius = rad; wm.bottom_radius = rad; wm.height = wid; wm.radial_segments = 24
		_add_f1_part(spin_piv, wm, tire_mat, Vector3.ZERO, Vector3(0.0, 0.0, 90.0))

		var rim := CylinderMesh.new(); rim.top_radius = rad * 0.60; rim.bottom_radius = rad * 0.60; rim.height = wid + 0.015; rim.radial_segments = 16
		_add_f1_part(spin_piv, rim, carbon, Vector3.ZERO, Vector3(0.0, 0.0, 90.0))

		# 5 metallic spokes + centerlock hub nut + glowing colored F1 sidewall stripe ring!
		var spoke_m := BoxMesh.new(); spoke_m.size = Vector3(wid + 0.025, 0.038, rad * 1.06)
		for sp_i: int in range(3):
			_add_f1_part(spin_piv, spoke_m, rim_mat, Vector3.ZERO, Vector3(float(sp_i) * 60.0, 0.0, 0.0))

		var lock_m := CylinderMesh.new(); lock_m.top_radius = 0.075; lock_m.bottom_radius = 0.09; lock_m.height = wid + 0.05
		_add_f1_part(spin_piv, lock_m, caliper_mat, Vector3.ZERO, Vector3(0.0, 0.0, 90.0))

		var stripe_ring := TorusMesh.new(); stripe_ring.inner_radius = rad * 0.68; stripe_ring.outer_radius = rad * 0.74
		_add_f1_part(spin_piv, stripe_ring, compound_ring, Vector3(side * (wid * 0.505), 0.0, 0.0), Vector3(0.0, 0.0, 90.0))

		wheel_pivots.append(wpiv)
		wheel_spins.append(spin_piv)

	root.set_meta("body_pivot", body_pivot)
	root.set_meta("wheel_pivots", wheel_pivots)
	root.set_meta("wheels", wheel_spins)
	return root


func _spawn_ai_rivals() -> void:
	var specs := [
		{"name": "Червоний", "col": Color(0.92, 0.16, 0.14), "s_ratio": 0.14, "lat": -2.6, "spd": 48.8},
		{"name": "Бірюзовий", "col": Color(0.14, 0.86, 0.74), "s_ratio": 0.36, "lat": 2.6, "spd": 50.4},
		{"name": "Золотий", "col": Color(0.96, 0.78, 0.16), "s_ratio": 0.58, "lat": -2.6, "spd": 47.6},
		{"name": "Смарагдовий", "col": Color(0.16, 0.82, 0.34), "s_ratio": 0.80, "lat": 2.6, "spd": 49.4}
	]
	for i: int in range(specs.size()):
		var car := build_sports_car_mesh(specs[i]["col"], false)
		car.name = "AIRivalCar_%d" % i
		add_child(car)
		rivals.append({
			"name": specs[i]["name"],
			"node": car,
			"s": float(specs[i]["s_ratio"]) * total_length,
			"progress_dist": float(specs[i]["s_ratio"]) * total_length,
			"lat": float(specs[i]["lat"]),
			"base_lat": float(specs[i]["lat"]),
			"cur_spd": float(specs[i]["spd"]),
			"top_spd": float(specs[i]["spd"]),
			"lap": 1,
			"finished": false,
			"finish_time": 0.0,
			"weave_phase": float(i) * 1.57
		})


func prepare_race_start() -> void:
	if frames.is_empty():
		return
	var grid_back := [9.0, 9.0, 14.5, 14.5]
	var grid_lanes := [-2.7, 2.7, -2.7, 2.7]
	_race_mode = "countdown"
	player_progress_dist = -6.0
	_race_elapsed = 0.0
	for i: int in range(rivals.size()):
		var r: Dictionary = rivals[i]
		var back := float(grid_back[i % grid_back.size()])
		var lane := float(grid_lanes[i % grid_lanes.size()])
		r["s"] = fposmod(total_length - back, total_length)
		r["progress_dist"] = -back
		r["lat"] = lane
		r["base_lat"] = lane
		r["cur_spd"] = 0.0
		r["lap"] = 1
		r["finished"] = false
		r["finish_time"] = 0.0
		_sync_rival_transform(r, 0.0)


func set_race_mode(mode: String) -> void:
	_race_mode = mode
	if mode == "idle":
		for i: int in range(rivals.size()):
			var r: Dictionary = rivals[i]
			r["cur_spd"] = float(r["top_spd"])
			r["finished"] = false
			r["lap"] = 1


func _sync_rival_transform(r: Dictionary, delta: float) -> void:
	var sp := sample_at_s(float(r["s"]))
	if sp.is_empty():
		return
	var pos := (sp["pos"] as Vector3) + (sp["right"] as Vector3) * float(r["lat"])
	var car: Node3D = r["node"]
	var fwd: Vector3 = sp["fwd"]
	var right: Vector3 = sp["right"]
	var up: Vector3 = sp["up"]
	car.global_transform = Transform3D(Basis(right, up, -fwd), pos)
	if delta > 0.0:
		var wheels: Array = car.get_meta("wheels", [])
		var spd := float(r["cur_spd"])
		for w: Node3D in wheels:
			w.rotate_x(-spd * delta * 1.9)


func set_player_driving(active: bool) -> void:
	if pit_parked_car:
		pit_parked_car.visible = not active
	if not active:
		set_race_mode("idle")
		set_traffic_light("off")


func _apply_shadow_settings() -> void:
	var shadow_tier := int(ConfigManager.graphics.get("shadows", 3))
	var mode := GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadow_tier >= 1 else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if is_instance_valid(_road_mesh_inst):
		_road_mesh_inst.cast_shadow = mode
	if is_instance_valid(_rail_mesh_inst):
		_rail_mesh_inst.cast_shadow = mode
	if is_instance_valid(_pillar_mm):
		_pillar_mm.cast_shadow = mode
	if is_instance_valid(_gantry_light):
		_gantry_light.shadow_enabled = shadow_tier >= 2
	for r in rivals:
		var c: Node3D = r.get("node")
		if is_instance_valid(c):
			for child in c.find_children("*", "MeshInstance3D", true, false):
				(child as MeshInstance3D).cast_shadow = mode


func sample_at_s(s_dist: float) -> Dictionary:
	if frames.is_empty() or total_length <= 0.1:
		return {}
	var ws := fposmod(s_dist, total_length)
	var lo := 0
	var hi := frames.size() - 1
	while lo < hi:
		var mid := (lo + hi + 1) >> 1
		if float(frames[mid]["s"]) <= ws:
			lo = mid
		else:
			hi = mid - 1
	var next_i := (lo + 1) % frames.size()
	var f0: Dictionary = frames[lo]
	var f1: Dictionary = frames[next_i]
	var s0 := float(f0["s"])
	var s1 := float(f1["s"]) if next_i > 0 else total_length
	var t := clampf((ws - s0) / maxf(s1 - s0, 0.01), 0.0, 1.0)
	var p := (f0["pos"] as Vector3).lerp(f1["pos"] as Vector3, t)
	var fwd := (f0["fwd"] as Vector3).lerp(f1["fwd"] as Vector3, t).normalized()
	var up := (f0["up"] as Vector3).lerp(f1["up"] as Vector3, t).normalized()
	var right := fwd.cross(up).normalized()
	up = right.cross(fwd).normalized()
	return {
		"idx": lo,
		"s": ws,
		"pos": p,
		"fwd": fwd,
		"right": right,
		"up": up,
		"bank_deg": lerpf(float(f0["bank_deg"]), float(f1["bank_deg"]), t),
		"width": lerpf(float(f0["width"]), float(f1["width"]), t),
		"is_gap": bool(f0["is_gap"]),
		"is_boost": bool(f0["is_boost"]),
		"is_crest_boost": bool(f0["is_crest_boost"]),
		"is_loop": bool(f0["is_loop"]),
		"loop_u": lerpf(float(f0["loop_u"]), float(f1["loop_u"]), t)
	}


func find_closest_frame(world_pos: Vector3, hint_idx: int = -1) -> Dictionary:
	var best_i := 0
	var best_d2 := 1e12
	var n := frames.size()
	if hint_idx >= 0 and hint_idx < n:
		for off: int in range(-12, 16):
			var idx := posmod(hint_idx + off, n)
			var d2 := world_pos.distance_squared_to(frames[idx]["pos"] as Vector3)
			if d2 < best_d2:
				best_d2 = d2; best_i = idx
		if best_d2 < 180.0:
			var f_h: Dictionary = frames[best_i].duplicate()
			f_h["idx"] = best_i
			return f_h
	for i: int in range(n):
		var d2 := world_pos.distance_squared_to(frames[i]["pos"] as Vector3)
		if d2 < best_d2:
			best_d2 = d2; best_i = i
	var res: Dictionary = frames[best_i].duplicate()
	res["idx"] = best_i
	return res


func get_pit_start_s() -> float:
	var f := find_closest_frame(PIT_POS)
	return float(f.get("s", 0.0))


func _process(delta: float) -> void:
	if frames.is_empty():
		return
	if _race_mode == "countdown":
		for r in rivals:
			_sync_rival_transform(r, 0.0)
		return

	if _race_mode == "racing":
		_race_elapsed += delta

	for i: int in range(rivals.size()):
		var r: Dictionary = rivals[i]
		var sp_now := sample_at_s(float(r["s"]))
		var target_spd := float(r["top_spd"])
		if not sp_now.is_empty():
			if bool(sp_now["is_boost"]) or bool(sp_now["is_crest_boost"]):
				target_spd *= 1.24
			elif bool(sp_now["is_loop"]):
				target_spd = maxf(target_spd, 48.0)

		if _race_mode == "racing":
			if bool(r["finished"]):
				target_spd *= 0.65
			else:
				# Dynamic neck-and-neck slipstream catch-up + periodic DRS overtake surges
				var gap := player_progress_dist - float(r["progress_dist"])
				if gap > 5.0:
					target_spd += clampf((gap - 5.0) * 0.45, 0.0, 16.5)
				elif gap < -16.0:
					target_spd += clampf((gap + 16.0) * 0.34, -8.5, 0.0)
				var surge := sin(_race_elapsed * (0.48 + float(i) * 0.11) + float(i) * 1.7)
				if surge > 0.50 and absf(gap) < 35.0:
					target_spd += 5.5 + 3.5 * clampf((surge - 0.50) * 2.0, 0.0, 1.0)
				target_spd = clampf(target_spd, 34.0, 68.0)

		var cur_spd := move_toward(float(r["cur_spd"]), target_spd, delta * 44.0)
		r["cur_spd"] = cur_spd

		var ds := cur_spd * delta
		r["s"] = fposmod(float(r["s"]) + ds, total_length)
		if _race_mode == "racing":
			var prog := float(r["progress_dist"]) + ds
			r["progress_dist"] = prog
			r["lap"] = mini(LAPS_TOTAL, maxi(1, int(floor(maxf(prog, 0.0) / total_length)) + 1))
			if not bool(r["finished"]) and prog >= float(LAPS_TOTAL) * total_length:
				r["finished"] = true

		# Subtle smooth racing line & overtaking weave on banked turns
		r["weave_phase"] = float(r["weave_phase"]) + delta * 0.45
		var target_lat := float(r["base_lat"]) + sin(float(r["weave_phase"])) * 0.9
		r["lat"] = lerpf(float(r["lat"]), clampf(target_lat, -3.4, 3.4), clampf(delta * 2.5, 0.0, 1.0))

		_sync_rival_transform(r, delta)


func get_save_state() -> Dictionary:
	var r_list: Array = []
	for r in rivals:
		r_list.append({
			"s": float(r["s"]),
			"progress_dist": float(r["progress_dist"]),
			"lat": float(r["lat"]),
			"base_lat": float(r["base_lat"]),
			"cur_spd": float(r["cur_spd"]),
			"lap": int(r["lap"]),
			"finished": bool(r["finished"]),
			"finish_time": float(r["finish_time"]),
			"weave_phase": float(r["weave_phase"])
		})
	return {
		"race_mode": _race_mode,
		"player_progress_dist": player_progress_dist,
		"race_elapsed": _race_elapsed,
		"rivals": r_list
	}


func apply_save_state(st: Dictionary) -> void:
	_race_mode = str(st.get("race_mode", "idle"))
	player_progress_dist = float(st.get("player_progress_dist", 0.0))
	_race_elapsed = float(st.get("race_elapsed", 0.0))
	var r_list: Array = st.get("rivals", []) as Array
	for i: int in range(mini(rivals.size(), r_list.size())):
		var r: Dictionary = rivals[i]
		var sv: Dictionary = r_list[i] as Dictionary
		r["s"] = float(sv.get("s", r["s"]))
		r["progress_dist"] = float(sv.get("progress_dist", r["progress_dist"]))
		r["lat"] = float(sv.get("lat", r["lat"]))
		r["base_lat"] = float(sv.get("base_lat", r["base_lat"]))
		r["cur_spd"] = float(sv.get("cur_spd", r["cur_spd"]))
		r["lap"] = int(sv.get("lap", r["lap"]))
		r["finished"] = bool(sv.get("finished", false))
		r["finish_time"] = float(sv.get("finish_time", 0.0))
		r["weave_phase"] = float(sv.get("weave_phase", r["weave_phase"]))
		_sync_rival_transform(r, 0.0)
		var r_node: Node3D = r.get("node") as Node3D
		if is_instance_valid(r_node):
			r_node.reset_physics_interpolation()
