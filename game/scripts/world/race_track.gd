class_name MountainRaceTrack
extends Node3D

# Closed mountain-perimeter race circuit circling the entire valley:
# - Pit Stop Station at (-16.0, 6.2, 72.0) connected via winding cobblestone path
# - Steep banked corners (+/-32 deg roll)
# - Speed-boosted Canyon Ravine Jump Gap (~22m) across North Gorge
# - 360-degree Vertical Loop-the-Loop ("Мертва петля", R=14.5m) with neon arch rings
# - 3 Live AI Rivals racing continuously even when the player isn't driving!

const TRACK_WIDTH := 9.2
const PIT_POS := Vector3(-16.0, 6.2, 72.0)

var frames: Array[Dictionary] = []
var total_length: float = 0.0
var rivals: Array[Dictionary] = []
var pit_parked_car: Node3D
var _is_player_driving: bool = false


func _ready() -> void:
	_build_track_geometry_and_collision()
	_build_pit_stop_station()
	_spawn_ai_rivals()


func _build_track_frames() -> void:
	frames.clear()
	# Part 1: Entry after Loop (-28, 18.5, -162) -> West Mirror Ridge -> Pit Stop (-16, 6.2, 72) -> North-East Ridge -> Jump TakeOff (68, 22.8, -144)
	# Part 2: 22m Canyon Gap + Landing Ramp -> Approach into Loop (-8, 18.5, -152)
	# Part 3: Vertical 360 Loop-the-Loop at (-18, 18.5, -152), helix Z=-152 -> -162
	var ctrl_a := [
		{"p": Vector3(-30.0, 18.5, -162.0), "b": 0.0},
		{"p": Vector3(-86.0, 20.5, -152.0), "b": 26.0},
		{"p": Vector3(-138.0, 23.0, -112.0), "b": 34.0},
		{"p": Vector3(-158.0, 21.0, -42.0), "b": 24.0},
		{"p": Vector3(-148.0, 16.5, 34.0), "b": -22.0},
		{"p": Vector3(-112.0, 12.0, 86.0), "b": 28.0},
		{"p": Vector3(-62.0, 7.6, 82.0), "b": 10.0},
		{"p": Vector3(-16.0, 6.2, 72.0), "b": 0.0},   # Pit Stop Station!
		{"p": Vector3(38.0, 7.2, 92.0), "b": 12.0},
		{"p": Vector3(98.0, 12.8, 96.0), "b": 24.0},
		{"p": Vector3(146.0, 19.2, 54.0), "b": 32.0},
		{"p": Vector3(154.0, 21.5, -20.0), "b": 12.0},
		{"p": Vector3(134.0, 22.5, -90.0), "b": 34.0},
		{"p": Vector3(96.0, 21.0, -134.0), "b": 14.0},
		{"p": Vector3(68.0, 23.6, -144.0), "b": 0.0}    # Take-off lip!
	]

	var curve_a := Curve3D.new()
	for i: int in range(ctrl_a.size()):
		var pt: Vector3 = ctrl_a[i]["p"]
		var prev_p: Vector3 = ctrl_a[maxi(i - 1, 0)]["p"]
		var next_p: Vector3 = ctrl_a[mini(i + 1, ctrl_a.size() - 1)]["p"]
		var tan_v := (next_p - prev_p).normalized() * 14.0
		if i == 0:
			tan_v = Vector3(-16.0, 0.0, 0.0)
		elif i == ctrl_a.size() - 1:
			tan_v = Vector3(-14.0, 3.6, -1.5) # Upward ramp lip tangent!
		curve_a.add_point(pt, -tan_v, tan_v)

	var len_a := curve_a.get_baked_length()
	var steps_a := maxi(int(round(len_a / 2.6)), 60)
	for s: int in range(steps_a):
		var u := float(s) / float(steps_a)
		var dist_s := u * len_a
		var p := curve_a.sample_baked(dist_s)
		var p2 := curve_a.sample_baked(minf(dist_s + 1.0, len_a))
		var fwd := (p2 - p).normalized()
		if fwd.length_squared() < 0.01:
			fwd = Vector3(-1, 0, 0)
		var bank := _interp_bank(ctrl_a, u)
		var boost := (len_a - dist_s) < 20.0
		_append_banked_frame(p, fwd, deg_to_rad(bank), false, boost, false, (dist_s > 240.0 and dist_s < 285.0))

	# Part 2: Canyon Ravine Jump Gap (~22m from takeoff (68, 23.6, -144) to landing (44, 18.8, -148))
	var p_take := Vector3(68.0, 23.6, -144.0)
	var p_land := Vector3(44.0, 18.8, -148.0)
	var gap_steps := 9
	for gi: int in range(1, gap_steps):
		var gt := float(gi) / float(gap_steps)
		var gp := p_take.lerp(p_land, gt)
		gp.y += sin(gt * PI) * 4.2 # Parabolic sky arc hint for AI cars & visualization
		var gp_next := p_take.lerp(p_land, minf(gt + 0.1, 1.0))
		gp_next.y += sin(minf(gt + 0.1, 1.0) * PI) * 4.2
		_append_banked_frame(gp, (gp_next - gp).normalized(), 0.0, true, false, false, false)

	# Landing Apron -> Loop Entry (-18, 18.5, -152)
	var ctrl_b := [
		{"p": Vector3(44.0, 18.8, -148.0), "b": 0.0},
		{"p": Vector3(24.0, 18.5, -151.0), "b": 0.0},
		{"p": Vector3(-8.0, 18.5, -152.0), "b": 0.0},
		{"p": Vector3(-18.0, 18.5, -152.0), "b": 0.0}
	]
	var curve_b := Curve3D.new()
	for i: int in range(ctrl_b.size()):
		var pt: Vector3 = ctrl_b[i]["p"]
		var tan_v := Vector3(-8.0, 0.0, 0.0)
		curve_b.add_point(pt, -tan_v, tan_v)
	var len_b := curve_b.get_baked_length()
	var steps_b := maxi(int(round(len_b / 2.6)), 12)
	for s: int in range(steps_b):
		var u := float(s) / float(steps_b)
		var dist_s := u * len_b
		var p := curve_b.sample_baked(dist_s)
		var p2 := curve_b.sample_baked(minf(dist_s + 1.0, len_b))
		var fwd := (p2 - p).normalized()
		var boost_loop := (len_b - dist_s) < 16.0
		_append_banked_frame(p, fwd, 0.0, false, boost_loop, false, false)

	# Part 3: Vertical 360-degree Loop-the-Loop ("Мертва петля", R=14.5m) around (-18, 18.5, -152 -> -162)
	var loop_c := Vector3(-18.0, 18.5 + 14.5, -152.0)
	var R := 14.5
	var loop_steps := 42
	for li: int in range(loop_steps):
		var theta := (float(li) / float(loop_steps)) * TAU
		var z_off := -(float(li) / float(loop_steps)) * 10.0
		var lp := Vector3(loop_c.x - R * sin(theta), loop_c.y - R * cos(theta), loop_c.z + z_off)
		var fwd := Vector3(-R * cos(theta), R * sin(theta), -10.0 / TAU).normalized()
		var inward_up := (Vector3(loop_c.x, loop_c.y, lp.z) - lp).normalized()
		var right := fwd.cross(inward_up).normalized()
		var ortho_up := right.cross(fwd).normalized()
		frames.append({
			"pos": lp,
			"fwd": fwd,
			"right": right,
			"up": ortho_up,
			"width": TRACK_WIDTH,
			"is_gap": false,
			"is_boost": (li < 4),
			"is_loop": true,
			"is_pit": false,
			"s": 0.0
		})

	# Compute cumulative arc length
	total_length = 0.0
	for i: int in range(frames.size()):
		frames[i]["s"] = total_length
		var next_p: Vector3 = frames[(i + 1) % frames.size()]["pos"]
		total_length += (frames[i]["pos"] as Vector3).distance_to(next_p)


func _interp_bank(pts: Array, u: float) -> float:
	var f_idx := clampf(u * float(pts.size() - 1), 0.0, float(pts.size() - 1) - 0.001)
	var i0 := int(floor(f_idx))
	var frac := f_idx - float(i0)
	var t := frac * frac * (3.0 - 2.0 * frac)
	return lerpf(float(pts[i0]["b"]), float(pts[mini(i0 + 1, pts.size() - 1)]["b"]), t)


func _append_banked_frame(p: Vector3, fwd: Vector3, bank_rad: float, is_gap: bool, is_boost: bool, is_loop: bool, is_pit: bool) -> void:
	var raw_right := fwd.cross(Vector3.UP).normalized()
	if raw_right.length_squared() < 0.01:
		raw_right = Vector3.RIGHT
	var raw_up := raw_right.cross(fwd).normalized()
	var rot_basis := Basis(fwd, bank_rad)
	var right := (rot_basis * raw_right).normalized()
	var up := (rot_basis * raw_up).normalized()
	frames.append({
		"pos": p,
		"fwd": fwd,
		"right": right,
		"up": up,
		"width": TRACK_WIDTH + (2.5 if is_pit else 0.0),
		"is_gap": is_gap,
		"is_boost": is_boost,
		"is_loop": is_loop,
		"is_pit": is_pit,
		"s": 0.0
	})


func _build_track_geometry_and_collision() -> void:
	_build_track_frames()

	var road_mat := StandardMaterial3D.new()
	road_mat.albedo_color = Color(0.14, 0.15, 0.17)
	road_mat.roughness = 0.82
	road_mat.vertex_color_use_as_albedo = true

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var col_body := StaticBody3D.new()
	col_body.name = "RaceTrackCollider"
	add_child(col_body)

	var pillar_tfs: Array[Transform3D] = []
	var rail_tfs: Array[Transform3D] = []

	var n := frames.size()
	for i: int in range(n):
		var a: Dictionary = frames[i]
		var b: Dictionary = frames[(i + 1) % n]
		if bool(a["is_gap"]) or bool(b["is_gap"]):
			continue

		var pa: Vector3 = a["pos"]
		var pb: Vector3 = b["pos"]
		var ra: Vector3 = a["right"] * (float(a["width"]) * 0.5)
		var rb: Vector3 = b["right"] * (float(b["width"]) * 0.5)
		var ua: Vector3 = a["up"]
		var ub: Vector3 = b["up"]

		# Top Asphalt surface + Curb Accent + Boost Strip!
		var c_road := Color(0.20, 0.21, 0.24)
		if bool(a["is_boost"]):
			c_road = Color(0.95, 0.52, 0.12)
		elif bool(a["is_pit"]):
			c_road = Color(0.26, 0.27, 0.30)
		var c_curb := Color(0.90, 0.18, 0.16) if (i % 2 == 0) else Color(0.94, 0.94, 0.92)
		if bool(a["is_loop"]):
			c_curb = Color(0.16, 0.82, 0.96) if (i % 2 == 0) else Color(0.96, 0.78, 0.24)

		# Inner wide road quad
		var ra_in: Vector3 = ra * 0.84
		var rb_in: Vector3 = rb * 0.84
		_add_quad(st, pa - ra_in, pa + ra_in, pb + rb_in, pb - rb_in, ua, ub, c_road)
		# Left & Right red-white curbs
		_add_quad(st, pa - ra, pa - ra_in, pb - rb_in, pb - rb, ua, ub, c_curb)
		_add_quad(st, pa + ra_in, pa + ra, pb + rb, pb + rb_in, ua, ub, c_curb)
		# Underside dark slate deck thickness (so bridges/loops look solid from below!)
		var thick_a: Vector3 = -ua * 0.45
		var thick_b: Vector3 = -ub * 0.45
		_add_quad(st, pb - rb + thick_b, pb + rb + thick_b, pa + ra + thick_a, pa - ra + thick_a, -ub, -ua, Color(0.12, 0.12, 0.14))
		_add_quad(st, pa - ra + thick_a, pa - ra, pb - rb, pb - rb + thick_b, -ra.normalized(), -rb.normalized(), Color(0.24, 0.24, 0.27))
		_add_quad(st, pa + ra, pa + ra + thick_a, pb + rb + thick_b, pb + rb, ra.normalized(), rb.normalized(), Color(0.24, 0.24, 0.27))

		# Physics road slab collider
		var seg_mid := (pa + pb) * 0.5 - ((ua + ub) * 0.5) * 0.24
		var seg_len := pa.distance_to(pb) + 0.18
		var seg_fwd := (pb - pa).normalized()
		var seg_up := (ua + ub).normalized()
		var seg_right := seg_fwd.cross(seg_up).normalized()
		seg_up = seg_right.cross(seg_fwd).normalized()
		var cs := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(float(a["width"]), 0.48, seg_len)
		cs.shape = box
		cs.transform = Transform3D(Basis(seg_right, seg_up, -seg_fwd), seg_mid)
		col_body.add_child(cs)

		# Steel support pylons every 6th segment on non-loop bridges
		if not bool(a["is_loop"]) and i % 6 == 0:
			var dist_xz := Vector2(pa.x, pa.z).length()
			var rim_m := clampf((dist_xz - 120.0) / 110.0, 0.0, 1.0)
			var ground_h := 1.5 + rim_m * rim_m * 26.0
			if pa.y > ground_h + 1.2:
				var p_h := maxf(pa.y - ground_h + 2.5, 2.0)
				pillar_tfs.append(Transform3D(Basis.IDENTITY.scaled(Vector3(1.0, p_h, 1.0)), Vector3(pa.x, pa.y - 0.4 - p_h * 0.5, pa.z)))

		# Side safety guard posts on outer mountain turns (not inside boost lip or loop)
		if not bool(a["is_boost"]) and not bool(a["is_loop"]) and not bool(a["is_pit"]) and i % 3 == 0:
			rail_tfs.append(Transform3D(Basis(seg_right, seg_up, -seg_fwd), pa + ra * 0.96 + ua * 0.42))
			rail_tfs.append(Transform3D(Basis(seg_right, seg_up, -seg_fwd), pa - ra * 0.96 + ua * 0.42))

	var mi := MeshInstance3D.new()
	mi.name = "RaceTrackRoadMesh"
	mi.mesh = st.commit()
	mi.material_override = road_mat
	add_child(mi)

	# Support Pillars MultiMesh
	if pillar_tfs.size() > 0:
		var pm := CylinderMesh.new(); pm.top_radius = 0.55; pm.bottom_radius = 0.72; pm.height = 1.0
		var p_mat := StandardMaterial3D.new(); p_mat.albedo_color = Color(0.28, 0.29, 0.32); p_mat.roughness = 0.85
		_add_mm(pm, p_mat, pillar_tfs)

	if rail_tfs.size() > 0:
		var rm := BoxMesh.new(); rm.size = Vector3(0.24, 0.72, 2.4)
		var r_mat := StandardMaterial3D.new(); r_mat.albedo_color = Color(0.75, 0.78, 0.82); r_mat.metallic = 0.6; r_mat.roughness = 0.35
		_add_mm(rm, r_mat, rail_tfs)

	# Glowing Jump Gate Pylons & Checkered Start/Finish Arch + Loop Neon Rings
	_build_loop_neon_rings()
	_build_jump_beacons()


func _add_mm(mesh: Mesh, mat: Material, tfs: Array[Transform3D]) -> void:
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


func _add_quad(st: SurfaceTool, v0: Vector3, v1: Vector3, v2: Vector3, v3: Vector3, n0: Vector3, n1: Vector3, col: Color) -> void:
	st.set_color(col); st.set_normal(n0); st.add_vertex(v0)
	st.set_color(col); st.set_normal(n0); st.add_vertex(v1)
	st.set_color(col); st.set_normal(n1); st.add_vertex(v2)
	st.set_color(col); st.set_normal(n0); st.add_vertex(v0)
	st.set_color(col); st.set_normal(n1); st.add_vertex(v2)
	st.set_color(col); st.set_normal(n1); st.add_vertex(v3)


func _build_loop_neon_rings() -> void:
	var neon := StandardMaterial3D.new()
	neon.albedo_color = Color(0.18, 0.88, 1.0)
	neon.emission_enabled = true
	neon.emission = Color(0.18, 0.88, 1.0)
	neon.emission_energy_multiplier = 2.4
	for f in frames:
		if bool(f["is_loop"]) and int(f["s"]) % 14 == 0:
			var arch := TorusMesh.new(); arch.inner_radius = 5.4; arch.outer_radius = 5.75
			var mi := MeshInstance3D.new(); mi.mesh = arch; mi.material_override = neon
			var fw: Vector3 = f["fwd"]; var rt: Vector3 = f["right"]; var up: Vector3 = f["up"]
			# Rotate torus cleanly perpendicular to track forward!
			mi.transform = Transform3D(Basis(rt, fw, up), (f["pos"] as Vector3) + up * 2.5)
			add_child(mi)


func _build_jump_beacons() -> void:
	var b_mat := StandardMaterial3D.new()
	b_mat.albedo_color = Color(1.0, 0.45, 0.10)
	b_mat.emission_enabled = true; b_mat.emission = Color(1.0, 0.45, 0.10); b_mat.emission_energy_multiplier = 2.6
	for pt: Vector3 in [Vector3(68.0, 23.6, -144.0), Vector3(44.0, 18.8, -148.0)]:
		for side: float in [-4.8, 4.8]:
			var pm := CylinderMesh.new(); pm.top_radius = 0.24; pm.bottom_radius = 0.34; pm.height = 5.5
			var mi := MeshInstance3D.new(); mi.mesh = pm; mi.material_override = b_mat
			mi.position = pt + Vector3(0.0, 2.75, side)
			add_child(mi)


func _build_pit_stop_station() -> void:
	# Pit Stop Station & Starting Grid right near (-16.0, 6.2, 72.0)
	var pit := Node3D.new()
	pit.name = "RacePitStop"
	pit.position = Vector3(-16.0, 6.2, 72.0)
	add_child(pit)

	var concrete := StandardMaterial3D.new(); concrete.albedo_color = Color(0.55, 0.56, 0.58); concrete.roughness = 0.85
	var red_mat := StandardMaterial3D.new(); red_mat.albedo_color = Color(0.84, 0.16, 0.14); red_mat.roughness = 0.35; red_mat.metallic = 0.25
	var glow_mat := StandardMaterial3D.new(); glow_mat.albedo_color = Color(1.0, 0.86, 0.32); glow_mat.emission_enabled = true; glow_mat.emission = Color(1.0, 0.78, 0.24); glow_mat.emission_energy_multiplier = 2.0

	# Pit Canopy Shelter on North Side of Grid (Z=-6.8 relative to Pit center)
	var pad := BoxMesh.new(); pad.size = Vector3(14.0, 0.4, 7.2)
	var pmi := MeshInstance3D.new(); pmi.mesh = pad; pmi.material_override = concrete; pmi.position = Vector3(0.0, -0.05, -7.2)
	pit.add_child(pmi)
	var sb_pad := StaticBody3D.new(); sb_pad.position = Vector3(0.0, -0.05, -7.2)
	var cs_pad := CollisionShape3D.new(); var bs_pad := BoxShape3D.new(); bs_pad.size = Vector3(14.0, 0.4, 7.2)
	cs_pad.shape = bs_pad; sb_pad.add_child(cs_pad); pit.add_child(sb_pad)

	for px: float in [-5.8, 5.8]:
		var col := BoxMesh.new(); col.size = Vector3(0.45, 4.2, 0.45)
		var cmi := MeshInstance3D.new(); cmi.mesh = col; cmi.material_override = red_mat; cmi.position = Vector3(px, 2.1, -9.2)
		pit.add_child(cmi)
		var cmi2 := MeshInstance3D.new(); cmi2.mesh = col; cmi2.material_override = red_mat; cmi2.position = Vector3(px, 2.1, -5.2)
		pit.add_child(cmi2)

	var roof := BoxMesh.new(); roof.size = Vector3(13.6, 0.35, 6.2)
	var rmi := MeshInstance3D.new(); rmi.mesh = roof; rmi.material_override = red_mat; rmi.position = Vector3(0.0, 4.35, -7.2)
	pit.add_child(rmi)

	var sign_lbl := Label3D.new()
	sign_lbl.text = "🏁 ЗУПИНКА • ГІРСЬКІ ПЕРЕГОНИ 🏁"
	sign_lbl.position = Vector3(0.0, 4.95, -4.0)
	sign_lbl.pixel_size = 0.0085
	sign_lbl.font_size = 48
	sign_lbl.modulate = Color(1.0, 0.90, 0.36)
	pit.add_child(sign_lbl)

	var pit_l := OmniLight3D.new()
	pit_l.position = Vector3(0.0, 3.8, -5.0); pit_l.light_color = Color(1.0, 0.90, 0.72)
	pit_l.light_energy = 2.6; pit_l.omni_range = 16.0; pit_l.shadow_enabled = false
	pit.add_child(pit_l)

	# Checkered Start/Finish Arch across the Track!
	for sx: float in [-5.0, 5.0]:
		var ap := BoxMesh.new(); ap.size = Vector3(0.45, 5.2, 0.45)
		var ami := MeshInstance3D.new(); ami.mesh = ap; ami.material_override = concrete; ami.position = Vector3(0.0, 2.6, sx)
		pit.add_child(ami)
	var top_bar := BoxMesh.new(); top_bar.size = Vector3(0.9, 0.8, 10.6)
	var tmi := MeshInstance3D.new(); tmi.mesh = top_bar; tmi.material_override = glow_mat; tmi.position = Vector3(0.0, 5.2, 0.0)
	pit.add_child(tmi)

	# Parked Player Sports Car waiting right on the Pit Stop apron!
	pit_parked_car = build_sports_car_mesh(Color(0.14, 0.48, 0.96))
	pit_parked_car.position = Vector3(0.0, 0.25, -5.8)
	pit_parked_car.rotation.y = PI * 0.5
	pit.add_child(pit_parked_car)

	var inter := StaticBody3D.new()
	inter.name = "RaceStartInteract"
	inter.collision_layer = 2
	inter.collision_mask = 0
	inter.position = Vector3(0.0, 1.1, -5.8)
	var ics := CollisionShape3D.new()
	var ibox := BoxShape3D.new(); ibox.size = Vector3(5.6, 2.2, 3.2)
	ics.shape = ibox
	inter.add_child(ics)
	inter.set_meta("interact_id", "race_start")
	inter.set_meta("interact_title", "Сісти в гоночний болід (Гірська траса)")
	pit.add_child(inter)


static func build_sports_car_mesh(body_col: Color) -> Node3D:
	var root := Node3D.new()
	var paint := StandardMaterial3D.new()
	paint.albedo_color = body_col; paint.roughness = 0.22; paint.metallic = 0.65
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.14, 0.22, 0.30, 0.85); glass.roughness = 0.08; glass.metallic = 0.4
	var tire_mat := StandardMaterial3D.new()
	tire_mat.albedo_color = Color(0.10, 0.10, 0.12); tire_mat.roughness = 0.85
	var rim_mat := StandardMaterial3D.new()
	rim_mat.albedo_color = Color(0.84, 0.86, 0.90); rim_mat.metallic = 0.85; rim_mat.roughness = 0.22
	var head_glow := StandardMaterial3D.new()
	head_glow.albedo_color = Color(1.0, 0.96, 0.82); head_glow.emission_enabled = true; head_glow.emission = Color(1.0, 0.94, 0.72); head_glow.emission_energy_multiplier = 2.5
	var tail_glow := StandardMaterial3D.new()
	tail_glow.albedo_color = Color(1.0, 0.18, 0.14); tail_glow.emission_enabled = true; tail_glow.emission = Color(1.0, 0.16, 0.12); tail_glow.emission_energy_multiplier = 2.2

	# Sleek aerodynamic chassis aligned with Forward = -Z
	var body := BoxMesh.new(); body.size = Vector3(1.92, 0.56, 4.35)
	var bmi := MeshInstance3D.new(); bmi.mesh = body; bmi.material_override = paint; bmi.position = Vector3(0, 0.52, 0)
	root.add_child(bmi)

	var cabin := BoxMesh.new(); cabin.size = Vector3(1.48, 0.48, 1.95)
	var cmi := MeshInstance3D.new(); cmi.mesh = cabin; cmi.material_override = glass; cmi.position = Vector3(0, 0.98, 0.15)
	root.add_child(cmi)

	var spoiler := BoxMesh.new(); spoiler.size = Vector3(1.88, 0.09, 0.36)
	var smi := MeshInstance3D.new(); smi.mesh = spoiler; smi.material_override = paint; smi.position = Vector3(0, 1.05, 1.95)
	root.add_child(smi)

	for lx: float in [-0.70, 0.70]:
		var hl := BoxMesh.new(); hl.size = Vector3(0.32, 0.14, 0.12)
		var hmi := MeshInstance3D.new(); hmi.mesh = hl; hmi.material_override = head_glow; hmi.position = Vector3(lx, 0.56, -2.18)
		root.add_child(hmi)
		var tl := BoxMesh.new(); tl.size = Vector3(0.38, 0.14, 0.12)
		var tmi := MeshInstance3D.new(); tmi.mesh = tl; tmi.material_override = tail_glow; tmi.position = Vector3(lx, 0.60, 2.18)
		root.add_child(tmi)

	var wheels: Array[MeshInstance3D] = []
	for wp: Vector3 in [Vector3(-0.96, 0.36, -1.35), Vector3(0.96, 0.36, -1.35), Vector3(-0.96, 0.36, 1.35), Vector3(0.96, 0.36, 1.35)]:
		var wm := CylinderMesh.new(); wm.top_radius = 0.36; wm.bottom_radius = 0.36; wm.height = 0.28
		var wmi := MeshInstance3D.new(); wmi.mesh = wm; wmi.material_override = tire_mat
		wmi.position = wp; wmi.rotation.z = PI * 0.5
		var rim := CylinderMesh.new(); rim.top_radius = 0.21; rim.bottom_radius = 0.21; rim.height = 0.30
		var rmi := MeshInstance3D.new(); rmi.mesh = rim; rmi.material_override = rim_mat
		wmi.add_child(rmi)
		root.add_child(wmi)
		wheels.append(wmi)
	root.set_meta("wheels", wheels)
	return root


func _spawn_ai_rivals() -> void:
	var specs := [
		{"col": Color(0.92, 0.18, 0.16), "s_ratio": 0.12, "lat": -2.0, "spd": 31.5},
		{"col": Color(0.14, 0.84, 0.72), "s_ratio": 0.45, "lat": 2.0, "spd": 33.8},
		{"col": Color(0.96, 0.76, 0.18), "s_ratio": 0.78, "lat": 0.0, "spd": 29.8}
	]
	for i: int in range(specs.size()):
		var car := build_sports_car_mesh(specs[i]["col"])
		car.name = "AIRivalCar_%d" % i
		add_child(car)
		rivals.append({
			"node": car,
			"s": float(specs[i]["s_ratio"]) * total_length,
			"lat": float(specs[i]["lat"]),
			"spd": float(specs[i]["spd"]),
			"lap": 1
		})


func set_player_driving(active: bool) -> void:
	_is_player_driving = active
	if pit_parked_car:
		pit_parked_car.visible = not active


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
		"width": lerpf(float(f0["width"]), float(f1["width"]), t),
		"is_gap": bool(f0["is_gap"]),
		"is_boost": bool(f0["is_boost"]),
		"is_loop": bool(f0["is_loop"])
	}


func find_closest_frame(world_pos: Vector3, hint_idx: int = -1) -> Dictionary:
	var best_i := 0
	var best_d2 := 1e12
	var n := frames.size()
	if hint_idx >= 0 and hint_idx < n:
		for off: int in range(-10, 14):
			var idx := posmod(hint_idx + off, n)
			var d2 := world_pos.distance_squared_to(frames[idx]["pos"] as Vector3)
			if d2 < best_d2:
				best_d2 = d2; best_i = idx
		if best_d2 < 140.0:
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
	for r in rivals:
		var spd := float(r["spd"])
		var s := float(r["s"])
		var prev_s := s
		s += spd * delta
		if s >= total_length:
			s -= total_length
			r["lap"] = int(r["lap"]) + 1
		r["s"] = s
		var sp := sample_at_s(s)
		if sp.is_empty():
			continue
		var boost_mult := 1.28 if bool(sp["is_boost"]) or bool(sp["is_loop"]) else 1.0
		if boost_mult > 1.0:
			r["s"] = fposmod(prev_s + spd * boost_mult * delta, total_length)
		var pos := (sp["pos"] as Vector3) + (sp["right"] as Vector3) * float(r["lat"])
		var car: Node3D = r["node"]
		var fwd: Vector3 = sp["fwd"]
		var right: Vector3 = sp["right"]
		var up: Vector3 = sp["up"]
		car.global_transform = Transform3D(Basis(right, up, -fwd), pos)
		var wheels: Array = car.get_meta("wheels", [])
		for w: MeshInstance3D in wheels:
			w.rotate_x(-spd * delta * 1.8)
