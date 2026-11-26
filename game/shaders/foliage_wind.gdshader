shader_type spatial;
render_mode cull_disabled, depth_draw_opaque, specular_schlick_ggx;

uniform vec4 color_base : source_color = vec4(0.14, 0.28, 0.08, 1.0);
uniform vec4 color_tip : source_color = vec4(0.32, 0.48, 0.16, 1.0);
uniform vec4 color_flower : source_color = vec4(0.92, 0.86, 0.35, 1.0);
uniform float wind_speed = 1.8;
uniform float wind_strength = 0.22;
uniform float sss_strength = 0.45;
uniform bool is_grass_blade = true;

varying float v_height;
varying float v_tint;

void vertex() {
	v_height = clamp(1.0 - UV.y, 0.0, 1.0);
	vec3 inst_pos = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	v_tint = fract(sin(dot(inst_pos.xz, vec2(12.9898, 78.233))) * 43758.5453);

	float gust = sin(TIME * wind_speed + inst_pos.x * 0.28 + inst_pos.z * 0.21)
		+ 0.45 * cos(TIME * wind_speed * 1.7 + inst_pos.x * 0.65 - inst_pos.z * 0.52);
	float bend = (is_grass_blade ? pow(v_height, 1.5) : 0.45) * wind_strength * gust;
	VERTEX.x += bend;
	VERTEX.z += bend * 0.55;
}

void fragment() {
	vec3 col = mix(color_base.rgb, color_tip.rgb, v_height);
	col = mix(col, col * vec3(0.84, 0.98, 0.78), v_tint * 0.45);
	if (is_grass_blade && v_tint > 0.91 && v_height > 0.72) {
		col = mix(col, color_flower.rgb, 0.85);
	}
	ALBEDO = col;
	ROUGHNESS = 0.72;
	SPECULAR = 0.18;
	BACKLIGHT = col * sss_strength;
}
