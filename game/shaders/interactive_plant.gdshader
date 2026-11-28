shader_type spatial;
render_mode cull_disabled, depth_draw_opaque, specular_schlick_ggx;

global uniform vec3 sgt_player_position;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap;
uniform bool use_albedo_tex = false;
uniform bool use_normal_tex = false;
uniform vec4 albedo_tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float alpha_cutoff : hint_range(0.0, 1.0) = 0.42;
uniform float roughness_val : hint_range(0.0, 1.0) = 0.72;
uniform float wind_speed = 1.6;
uniform float wind_strength = 0.14;
uniform float bend_radius = 2.1;
uniform float bend_strength = 0.65;
uniform float mesh_height = 0.65;
uniform float sss_strength = 0.42;

varying float v_tint;
varying float v_height_k;

void vertex() {
	vec3 inst_pos = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	v_tint = fract(sin(dot(inst_pos.xz, vec2(12.9898, 78.233))) * 43758.5453);
	float hk = clamp(VERTEX.y / max(mesh_height, 0.15), 0.0, 1.0);
	v_height_k = hk;
	float flex = pow(hk, 1.45);

	float gust = sin(TIME * wind_speed + inst_pos.x * 0.32 + inst_pos.z * 0.24)
		+ 0.40 * cos(TIME * wind_speed * 1.6 + inst_pos.x * 0.75 - inst_pos.z * 0.58);
	vec3 world_disp = vec3(gust, 0.0, gust * 0.55) * (wind_strength * flex);

	vec3 world_v = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec2 to_v = world_v.xz - sgt_player_position.xz;
	float dist_xz = length(to_v);
	float dy = abs(inst_pos.y - sgt_player_position.y);
	if (dist_xz < bend_radius && dy < 3.0) {
		float k = 1.0 - clamp(dist_xz / max(bend_radius, 0.1), 0.0, 1.0);
		float push = k * k * flex * bend_strength;
		vec2 dir_xz = dist_xz > 0.02 ? (to_v / dist_xz) : vec2(0.7, 0.7);
		float tremble = sin(TIME * 22.0 + inst_pos.x * 4.0) * 0.03 * k;
		world_disp.xz += dir_xz * (push + tremble);
		world_disp.y -= push * 0.35;
	}

	vec3 rx = MODEL_MATRIX[0].xyz;
	vec3 ry = MODEL_MATRIX[1].xyz;
	vec3 rz = MODEL_MATRIX[2].xyz;
	VERTEX += vec3(
		dot(world_disp, rx) / max(dot(rx, rx), 0.0001),
		dot(world_disp, ry) / max(dot(ry, ry), 0.0001),
		dot(world_disp, rz) / max(dot(rz, rz), 0.0001)
	);
}

void fragment() {
	vec4 base = albedo_tint;
	if (use_albedo_tex) {
		base *= texture(albedo_tex, UV);
	}
	if (alpha_cutoff > 0.01 && base.a < alpha_cutoff) {
		discard;
	}
	vec3 col = mix(base.rgb, base.rgb * vec3(0.86, 1.04, 0.84), v_tint * 0.28);
	ALBEDO = col;
	ROUGHNESS = roughness_val;
	SPECULAR = 0.16;
	if (use_normal_tex) {
		NORMAL_MAP = texture(normal_tex, UV).rgb;
		NORMAL_MAP_DEPTH = 0.75;
	}
	BACKLIGHT = col * sss_strength;
}
