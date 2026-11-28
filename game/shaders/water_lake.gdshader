shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, specular_schlick_ggx;

uniform vec4 shallow_color : source_color = vec4(0.15, 0.56, 0.54, 0.16);
uniform vec4 deep_color : source_color = vec4(0.05, 0.28, 0.36, 0.46);
uniform vec4 sky_tint : source_color = vec4(0.55, 0.74, 0.92, 1.0);
uniform float wave_speed = 0.42;
uniform float wave_scale = 0.22;
uniform float wave_height = 0.15;
uniform float wind_strength = 0.35;
uniform float roughness_val : hint_range(0.01, 0.5) = 0.05;
uniform sampler2D depth_tex : hint_depth_texture, filter_linear_mipmap;

varying vec3 world_pos;

// Smooth curved domain-warped Gerstner/trochoidal lake waves (zero lattice/grid pattern!)
float wave_displacement(vec2 p, float t, float w_amp) {
	vec2 q = p + vec2(sin(p.y * 0.21 + t * 0.42), cos(p.x * 0.18 - t * 0.37)) * 1.15;
	float h = 0.0;
	h += sin(dot(q, vec2(0.39, 0.24)) + t * 1.75) * 0.34;
	h += sin(dot(q, vec2(-0.27, 0.44)) - t * 1.42) * 0.27;
	h += sin(dot(p, vec2(0.58, -0.49)) + t * 2.15) * 0.19;
	h += cos(dot(q, vec2(-0.83, -0.61)) - t * 2.70) * 0.12;
	h += sin(dot(p, vec2(1.18, 0.94)) + t * 3.10) * 0.08;
	return h * w_amp;
}

float micro_ripples(vec2 p, float t) {
	vec2 w = p + vec2(sin(p.y * 0.75 + t * 1.1), cos(p.x * 0.68 - t * 0.95)) * 0.42;
	float r = 0.0;
	r += sin(dot(w, vec2(2.35, 1.41)) + t * 2.3) * 0.36;
	r += cos(dot(w, vec2(-1.82, 2.67)) - t * 2.8) * 0.28;
	r += sin(dot(w, vec2(3.14, -2.51)) + t * 3.5) * 0.20;
	r += cos(dot(w, vec2(-3.95, -1.94)) - t * 4.1) * 0.16;
	return r;
}

void vertex() {
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float t = TIME * (0.65 + wind_strength * 0.95);
	float w_amp = wave_height * (0.60 + wind_strength * 0.75);
	float disp = wave_displacement(wp.xz, t, w_amp);
	VERTEX.x += cos(wp.x * 0.39 + wp.z * 0.24 + t * 1.75) * w_amp * 0.38;
	VERTEX.z += sin(-wp.x * 0.27 + wp.z * 0.44 - t * 1.42) * w_amp * 0.38;
	VERTEX.y += disp;
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float t = TIME * (0.65 + wind_strength * 0.95);
	float t_frag = TIME * (0.80 + wave_speed * 1.2 + wind_strength * 1.0);
	float w_amp = wave_height * (0.60 + wind_strength * 0.75);
	vec2 p = world_pos.xz;
	vec2 rp = world_pos.xz * (0.65 + wave_scale * 1.6);

	// Attenuate high-frequency micro-ripples with distance so far lake surface stays silky with ZERO Moire grid!
	float cam_dist = length(CAMERA_POSITION_WORLD - world_pos);
	float detail_fade = exp(-cam_dist * 0.022);
	float rip_amp = 0.024 * (0.55 + wind_strength) * detail_fade;

	// Fast analytic surface gradient (replaces 9 heavy trig loops per pixel!)
	float w0 = sin(dot(p, vec2(0.39, 0.24)) + t * 1.75);
	float cw0 = cos(dot(p, vec2(0.39, 0.24)) + t * 1.75) * 0.34 * w_amp;
	float cw1 = sin(dot(p, vec2(-0.27, 0.44)) - t * 1.42) * 0.27 * w_amp;
	vec2 dw = vec2(0.39 * cw0 + 0.27 * cw1, 0.24 * cw0 - 0.44 * cw1);
	if (detail_fade > 0.02) {
		float cr0 = cos(dot(rp, vec2(2.35, 1.41)) + t_frag * 2.3) * 0.45 * rip_amp;
		float sr1 = sin(dot(rp, vec2(-1.82, 2.67)) - t_frag * 2.8) * 0.35 * rip_amp;
		dw += vec2(2.35 * cr0 + 1.82 * sr1, 1.41 * cr0 - 2.67 * sr1);
	}
	float r0 = w0 * 0.55 * w_amp;
	vec3 n_detail = normalize(vec3(-dw.x, 1.0, -dw.y));
	NORMAL = normalize((VIEW_MATRIX * vec4(n_detail, 0.0)).xyz);

	float depth_raw = texture(depth_tex, SCREEN_UV).x;
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth_raw);
	vec4 view_p = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view_p.xyz /= max(view_p.w, 0.0001);
	float water_depth = max(-view_p.z + VERTEX.z, 0.0);

	float depth_factor = clamp(1.0 - exp(-water_depth * 0.28), 0.0, 1.0);
	float fresnel = pow(1.0 - clamp(dot(normalize(VIEW), NORMAL), 0.0, 1.0), 4.0);
	float caustic = pow(max(0.0, sin(p.x * 2.1 + t) * cos(p.y * 1.9 - t * 0.85)), 2.0) * smoothstep(3.8, 0.25, water_depth) * 0.16;
	vec3 base = mix(shallow_color.rgb, deep_color.rgb, depth_factor);
	base = mix(base, sky_tint.rgb, fresnel * 0.48) + vec3(0.24, 0.44, 0.40) * caustic;

	// Smooth rolling shoreline foam (no noise grid seams!)
	float ripple_phase = sin(p.x * 1.4 - p.y * 1.2 + t_frag * 1.8) * 0.5 + 0.5;
	float foam_band = smoothstep(0.55, 0.03, water_depth) * (0.35 + 0.65 * sin(water_depth * 14.0 - t_frag * 2.4 + ripple_phase * 2.2));
	float crest_foam = smoothstep(w_amp * 0.58, w_amp * 0.92, r0) * 0.24 * (0.4 + wind_strength);
	float total_foam = clamp(foam_band * 0.42 + crest_foam, 0.0, 0.55);
	base = mix(base, vec3(0.88, 0.93, 0.96), total_foam);

	ALBEDO = base;
	METALLIC = 0.10;
	ROUGHNESS = roughness_val + total_foam * 0.25;
	SPECULAR = 0.85;
	ALPHA = clamp(mix(shallow_color.a, deep_color.a, depth_factor) + fresnel * 0.22 + total_foam * 0.45, 0.14, 0.72);
}
