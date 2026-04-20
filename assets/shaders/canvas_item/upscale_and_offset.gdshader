shader_type canvas_item;
render_mode unshaded;

uniform vec2 texel_offset = vec2(0.0);
uniform float contrast_boost : hint_range(0.8, 1.6, 0.01) = 1.14;
uniform float vignette_strength : hint_range(0.0, 1.0, 0.01) = 0.22;
uniform float palette_steps : hint_range(6.0, 96.0, 1.0) = 32.0;
// Blend raw vs posterized color — <1.0 softens harsh whites and floor speckle.
uniform float posterize_mix : hint_range(0.0, 1.0, 0.01) = 0.78;
uniform float highlight_ceil : hint_range(0.85, 1.0, 0.001) = 0.96;
uniform float saturation_boost : hint_range(0.8, 1.5, 0.01) = 1.06;
uniform vec3 shadow_tint : source_color = vec3(0.90, 0.95, 1.08);
uniform vec3 highlight_tint : source_color = vec3(1.07, 0.99, 0.94);

vec3 quantize_palette(vec3 c, float steps) {
	return floor(c * steps + 0.5) / steps;
}

void fragment() {
	vec2 shifted = UV - texel_offset * TEXTURE_PIXEL_SIZE;
	vec2 snapped_uv = (floor(shifted / TEXTURE_PIXEL_SIZE) + 0.5) * TEXTURE_PIXEL_SIZE;
	vec3 col = textureLod(TEXTURE, snapped_uv, 0.0).rgb;

	// Boost contrast first to expand the dynamic range before quantization.
	col = (col - 0.5) * contrast_boost + 0.5;

	// Saturation boost so palette reads "artistic" not washed-out.
	float luma = dot(col, vec3(0.2126, 0.7152, 0.0722));
	col = mix(vec3(luma), col, saturation_boost);

	// Soften only very bright samples before posterize (avoids salt on light gray floors).
	col = clamp(col, vec3(0.0), vec3(1.0));
	float hl = max(max(col.r, col.g), col.b);
	float hi_roll = smoothstep(0.82, 0.995, hl);
	float scale_hi = min(highlight_ceil / max(hl, 1e-5), 1.0);
	col *= mix(1.0, scale_hi, hi_roll);

	vec3 poster = quantize_palette(col, palette_steps);
	col = mix(col, poster, posterize_mix);

	// Subtle warm-cool grading on shadow/highlight luma.
	float l = dot(col, vec3(0.2126, 0.7152, 0.0722));
	col *= mix(shadow_tint, highlight_tint, smoothstep(0.15, 0.85, l));

	// Vignette.
	vec2 from_center = UV * 2.0 - 1.0;
	float vig = smoothstep(0.5, 1.2, dot(from_center, from_center));
	col *= 1.0 - vig * vignette_strength;

	COLOR = vec4(clamp(col, vec3(0.0), vec3(1.0)), 1.0);
}
