#[compute]
#version 450

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(set = 0, binding = 0) uniform sampler2D src_tex;
layout(rgba16f, set = 0, binding = 1) uniform image2D dst_image;
layout(set = 0, binding = 2) uniform sampler2D depth_tex;

layout(push_constant, std430) uniform Params {
	vec2 raster_size;
	vec2 sun_uv;
	vec4 ray_color; // rgb = tint, a = strength
	vec4 cfg;       // x = density, y = decay, z = weight, w = pass_mode (0 gather, 1 blend)
} params;

const int NUM_SAMPLES = 22;

float ign(vec2 p) {
	return fract(52.9829189 * fract(dot(p, vec2(0.06711056, 0.00583715))));
}

void main() {
	ivec2 gid = ivec2(gl_GlobalInvocationID.xy);
	ivec2 isize = ivec2(params.raster_size);
	if (gid.x >= isize.x || gid.y >= isize.y) {
		return;
	}

	vec2 texel = 1.0 / params.raster_size;
	vec2 uv = (vec2(gid) + 0.5) * texel;

	if (params.cfg.w < 0.5) {
		float aspect = params.raster_size.x * texel.y;
		float sun_dist = length((uv - params.sun_uv) * vec2(aspect, 1.0));
		float dist_mask = smoothstep(1.18, 0.02, sun_dist);
		if (dist_mask <= 0.0001) {
			imageStore(dst_image, gid, vec4(0.0));
			return;
		}

		vec2 delta = (uv - params.sun_uv) * (params.cfg.x / float(NUM_SAMPLES));
		vec2 cur_uv = uv - delta * ign(vec2(gid));
		float illum = 1.0;
		vec3 accum = vec3(0.0);

		for (int i = 0; i < NUM_SAMPLES; i++) {
			cur_uv -= delta;
			if (all(greaterThanEqual(cur_uv, vec2(0.0))) && all(lessThanEqual(cur_uv, vec2(1.0)))) {
				vec2 suv = clamp(cur_uv, texel, 1.0 - texel);
				float d = textureLod(depth_tex, suv, 0.0).r;
				float sky_mask = 1.0 - smoothstep(0.00001, 0.00014, d);
				vec3 c = textureLod(src_tex, suv, 0.0).rgb;
				float luma = dot(c, vec3(0.2126, 0.7152, 0.0722));
				vec3 shaft = min(c, vec3(2.4)) * smoothstep(0.18, 1.15, luma) * sky_mask;
				accum += shaft * illum * params.cfg.z;
			}
			illum *= params.cfg.y;
		}

		vec3 tinted = accum * params.ray_color.rgb * params.ray_color.a * dist_mask;
		tinted = tinted / (1.0 + tinted * 0.42);
		imageStore(dst_image, gid, vec4(tinted, 1.0));
	} else {
		vec3 ray = textureLod(src_tex, uv, 0.0).rgb * 0.36;
		ray += textureLod(src_tex, uv + vec2(texel.x * 1.5, 0.0), 0.0).rgb * 0.16;
		ray += textureLod(src_tex, uv - vec2(texel.x * 1.5, 0.0), 0.0).rgb * 0.16;
		ray += textureLod(src_tex, uv + vec2(0.0, texel.y * 1.5), 0.0).rgb * 0.16;
		ray += textureLod(src_tex, uv - vec2(0.0, texel.y * 1.5), 0.0).rgb * 0.16;

		vec4 base_col = imageLoad(dst_image, gid);
		imageStore(dst_image, gid, vec4(base_col.rgb + ray, base_col.a));
	}
}
