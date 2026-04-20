shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_opaque, cull_back;

uniform vec3 base_color : source_color = vec3(0.72, 0.58, 0.42);
uniform vec3 shade_color : source_color = vec3(0.20, 0.14, 0.12);
uniform vec3 highlight_color : source_color = vec3(0.98, 0.90, 0.78);
uniform vec3 sun_dir = vec3(-0.7, 0.7, 0.5);

varying vec3 world_normal;

void vertex() {
	world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}

void fragment() {
	vec3 L = normalize(sun_dir);
	float ndotl = dot(world_normal, L);
	float lit = ndotl * 0.5 + 0.5;

	// 4 bands for richer pixel-art shading on curved meshes.
	vec3 final;
	if (lit < 0.35) {
		final = shade_color;
	} else if (lit < 0.55) {
		final = mix(shade_color, base_color, 0.55);
	} else if (lit < 0.78) {
		final = base_color;
	} else {
		final = highlight_color;
	}
	ALBEDO = final;
}
