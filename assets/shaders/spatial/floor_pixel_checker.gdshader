shader_type spatial;
render_mode ambient_light_disabled, blend_mix, depth_draw_opaque, cull_back;

// 0 = legacy rotated diamond, 1 = world-axis square tiles (better shadow read + pixel grid).
uniform int pattern_mode = 1;
uniform vec3 color_a : source_color = vec3(0.30, 0.32, 0.37);
uniform vec3 color_b : source_color = vec3(0.46, 0.50, 0.56);
uniform vec3 line_color : source_color = vec3(0.14, 0.16, 0.20);
uniform vec3 shade_tint : source_color = vec3(0.93, 0.96, 1.04);
uniform float cell_size : hint_range(0.25, 6.0, 0.01) = 1.95;
uniform float line_width : hint_range(0.0, 0.2, 0.001) = 0.026;
uniform float grout_weight : hint_range(0.0, 1.0, 0.01) = 0.62;
uniform float contrast : hint_range(0.8, 1.5, 0.01) = 1.06;
uniform float checker_strength : hint_range(0.0, 1.0, 0.01) = 1.0;
uniform float micro_dither : hint_range(0.0, 0.1, 0.001) = 0.006;
uniform float pattern_rotation : hint_range(-3.14, 3.14, 0.0001) = 0.7853981633;
uniform float shadow_darkness : hint_range(0.0, 1.0, 0.01) = 0.36;
uniform float shadow_cool : hint_range(0.0, 0.35, 0.001) = 0.12;
uniform float light_bands : hint_range(3.0, 8.0, 1.0) = 5.0;
uniform float pixel_grid_size : hint_range(0.02, 0.5, 0.001) = 0.12;
uniform float albedo_cap : hint_range(0.75, 1.0, 0.001) = 0.91;

varying vec3 world_pos;

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 19.19);
	return fract((p3.x + p3.y) * p3.z);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 base = vec3(0.5);
	vec2 wp = world_pos.xz / cell_size;

	if (pattern_mode == 1) {
		// Axis-aligned tiles: shadows read clearly across flat squares (pixel-game floor).
		vec2 cell = floor(wp);
		float check = mod(cell.x + cell.y, 2.0);
		base = mix(color_a, color_b, check * checker_strength);

		vec2 fr = fract(wp);
		float edge_dist = min(min(fr.x, 1.0 - fr.x), min(fr.y, 1.0 - fr.y));
		float line_mask = 1.0 - smoothstep(line_width, line_width + 0.01, edge_dist);
		base = mix(base, line_color, line_mask * grout_weight);
	} else {
		float cs = cos(pattern_rotation);
		float sn = sin(pattern_rotation);
		vec2 rp = vec2(wp.x * cs - wp.y * sn, wp.x * sn + wp.y * cs);
		vec2 grid = floor(rp);
		float check = mod(grid.x + grid.y, 2.0);
		base = mix(color_a, color_b, check * checker_strength);
		vec2 frac_uv = fract(rp);
		float edge = min(min(frac_uv.x, frac_uv.y), min(1.0 - frac_uv.x, 1.0 - frac_uv.y));
		float line_mask = 1.0 - smoothstep(line_width, line_width + 0.012, edge);
		base = mix(base, line_color, line_mask * grout_weight);
	}

	// Snapped grain (very light) — avoids “salt” on near-white tiles.
	vec2 pixel_grid = floor(world_pos.xz / pixel_grid_size);
	float n = hash12(pixel_grid + vec2(11.0, 7.0));
	float grain = (n - 0.5) * micro_dither;
	// Less grain on brighter albedo to reduce posterized speckle after upscale.
	float g_attn = mix(1.0, 0.35, smoothstep(0.35, 0.75, max(max(base.r, base.g), base.b)));
	grain *= g_attn;

	base = (base - 0.5) * contrast + 0.5;
	base *= shade_tint;
	base += vec3(grain);
	base = clamp(base, vec3(0.0), vec3(albedo_cap));
	ALBEDO = base;
}

void light() {
	if (LIGHT_IS_DIRECTIONAL) {
		float ndotl = max(0.0, dot(NORMAL, LIGHT));
		float lit_raw = ndotl * ATTENUATION;
		float nband = max(light_bands, 3.0);
		float q = floor(lit_raw * nband + 0.5) / nband;
		float lit_factor = mix(shadow_darkness, 1.0, q);
		vec3 sun = LIGHT_COLOR * lit_factor;
		// Cooler shadow tint so contact shadows pixel bands read against grout.
		vec3 cool = mix(vec3(1.0), vec3(0.78, 0.86, 1.05), shadow_cool);
		DIFFUSE_LIGHT += sun * cool;
	}
}
