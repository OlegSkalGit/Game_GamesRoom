shader_type canvas_item;

uniform float reveal : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec2 px = TEXTURE_PIXEL_SIZE * (1.0 - reveal) * 2.2;
	vec4 col = texture(TEXTURE, UV) * 0.40;
	col += texture(TEXTURE, UV + vec2(px.x, 0.0)) * 0.15;
	col += texture(TEXTURE, UV - vec2(px.x, 0.0)) * 0.15;
	col += texture(TEXTURE, UV + vec2(0.0, px.y)) * 0.15;
	col += texture(TEXTURE, UV - vec2(0.0, px.y)) * 0.15;

	float luma = dot(col.rgb, vec3(0.299, 0.587, 0.114));
	vec3 final_rgb = mix(vec3(luma), col.rgb, clamp(reveal, 0.0, 1.0));
	COLOR = vec4(final_rgb, col.a);
}
