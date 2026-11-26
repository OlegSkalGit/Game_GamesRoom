shader_type spatial;
render_mode specular_schlick_ggx;

uniform sampler2D canvas_tex : source_color, filter_linear_mipmap;
uniform float color_mix : hint_range(0.0, 1.0) = 0.0;
uniform float blur_amount : hint_range(0.0, 4.0) = 2.2;
uniform float emission_strength : hint_range(0.0, 2.0) = 0.48;

void fragment() {
	vec2 tex_px = 1.0 / vec2(textureSize(canvas_tex, 0));
	vec2 off = tex_px * blur_amount * 1.45;

	vec3 c = texture(canvas_tex, UV).rgb * 0.28;
	c += texture(canvas_tex, UV + vec2(off.x, 0.0)).rgb * 0.12;
	c += texture(canvas_tex, UV - vec2(off.x, 0.0)).rgb * 0.12;
	c += texture(canvas_tex, UV + vec2(0.0, off.y)).rgb * 0.12;
	c += texture(canvas_tex, UV - vec2(0.0, off.y)).rgb * 0.12;
	c += texture(canvas_tex, UV + vec2(off.x, off.y)).rgb * 0.06;
	c += texture(canvas_tex, UV + vec2(-off.x, off.y)).rgb * 0.06;
	c += texture(canvas_tex, UV + vec2(off.x, -off.y)).rgb * 0.06;
	c += texture(canvas_tex, UV + vec2(-off.x, -off.y)).rgb * 0.06;

	float luma = dot(c, vec3(0.299, 0.587, 0.114));
	vec3 grey = vec3(luma * 0.94, luma * 0.94, luma * 0.96);
	vec3 final_col = mix(grey, c, clamp(color_mix, 0.0, 1.0));

	ALBEDO = final_col;
	ROUGHNESS = 0.55;
	EMISSION = final_col * emission_strength;
}
