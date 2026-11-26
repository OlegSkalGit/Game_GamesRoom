shader_type spatial;
render_mode blend_add, depth_draw_never, cull_disabled, unshaded;

uniform vec4 beam_color : source_color = vec4(1.0, 0.92, 0.68, 1.0);
uniform float intensity : hint_range(0.0, 2.0) = 0.36;

void fragment() {
	float along = clamp(1.0 - UV.y, 0.0, 1.0);
	float len_fade = pow(along, 1.65) * smoothstep(0.0, 0.08, UV.y);
	float edge = pow(clamp(abs(dot(normalize(NORMAL), normalize(VIEW))), 0.0, 1.0), 1.65);
	float shimmer = 0.92 + 0.08 * sin(UV.y * 18.0 - TIME * 1.5);
	float alpha = len_fade * edge * intensity * shimmer;
	ALBEDO = beam_color.rgb;
	ALPHA = clamp(alpha, 0.0, 0.65);
}
