shader_type spatial;
render_mode cull_disabled, depth_draw_opaque, specular_schlick_ggx;

global uniform vec3 sgt_player_position;

uniform vec4 color_base : source_color = vec4(0.14, 0.28, 0.08, 1.0);
uniform vec4 color_tip : source_color = vec4(0.32, 0.48, 0.16, 1.0);
uniform vec4 color_flower : source_color = vec4(0.92, 0.86, 0.35, 1.0);
uniform float wind_speed = 1.8;
uniform float wind_strength = 0.22;
uniform float bend_radius = 2.0;
uniform float bend_strength = 0.62;
uniform float sss_strength = 0.45;
uniform bool is_grass_blade = true;
uniform bool is_cattail_reed = false;

varying float v_height;
varying float v_tint;

void vertex() {
	v_height = clamp(1.0 - UV.y, 0.0, 1.0);
	vec3 inst_pos = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	v_tint = fract(sin(dot(inst_pos.xz, vec2(12.9898, 78.233))) * 43758.5453);

	float flex = is_grass_blade ? pow(v_height, 1.5) : 0.45 * v_height + 0.15;
	float gust = sin(TIME * wind_speed + inst_pos.x * 0.28 + inst_pos.z * 0.21)
		+ 0.45 * cos(TIME * wind_speed * 1.7 + inst_pos.x * 0.65 - inst_pos.z * 0.52);
	vec3 world_disp = vec3(gust, 0.0, gust * 0.55) * (flex * wind_strength);

	vec3 world_v = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec2 to_v = world_v.xz - sgt_player_position.xz;
	float dist_xz = length(to_v);
	if (dist_xz < bend_radius && abs(inst_pos.y - sgt_player_position.y) < 3.0) {
		float k = 1.0 - clamp(dist_xz / max(bend_radius, 0.1), 0.0, 1.0);
		float push = k * k * flex * bend_strength;
		vec2 dir_xz = dist_xz > 0.02 ? (to_v / dist_xz) : vec2(0.7, 0.7);
		world_disp.xz += dir_xz * push;
		world_disp.y -= push * 0.30;
	}
	VERTEX += (inverse(MODEL_MATRIX) * vec4(world_disp, 0.0)).xyz;
}

void fragment() {
	vec3 col = mix(color_base.rgb, color_tip.rgb, v_height);
	col = mix(col, col * vec3(0.84, 0.98, 0.78), v_tint * 0.45);
	if (is_cattail_reed && v_tint > 0.35 && v_height > 0.76 && v_height < 0.93) {
		col = vec3(0.24, 0.13, 0.07);
	} else if (is_grass_blade && v_tint > 0.91 && v_height > 0.72) {
		col = mix(col, color_flower.rgb, 0.85);
	}
	ALBEDO = col;
	ROUGHNESS = 0.72;
	SPECULAR = 0.18;
	BACKLIGHT = col * sss_strength;
}
