extends Room
class_name ProtoMapRoom

const ENEMY_SCENE := preload("res://scenes/enemies/regulated_enemy.tscn")
const PixelShaderStyler = preload("res://scripts/render/pixel_shader_styler.gd")
const FLOOR_PIXEL_SHADER := preload("res://assets/shaders/spatial/floor_pixel_checker.gdshader")
const CHARACTER_PIXEL_SHADER := preload("res://assets/shaders/spatial/character_pixel_toon.gdshader")

enum DemoLook {
	REF_VIDEO_DEVLOG, ## Suelo damero oscuro + vacío (captura de referencia / devlog Godot)
	VIDEO_INTRO_GRASS, ## Pasto pixel + cielo (benchmark outdoor)
	CLINICAL_CHECKER, ## Laboratorio gris (enemigos “clínicos”)
}

@export var clean_test_mode: bool = true
@export var demo_look: DemoLook = DemoLook.REF_VIDEO_DEVLOG

func _ready() -> void:
	if clean_test_mode:
		_build_clean_stage()
		_build_clean_spawn_points()
		_build_clean_lighting()
	else:
		_build_legacy_stage()
	super._ready()
	_apply_demo_atmosphere()

# ── CLEAN REFERENCE STAGE ────────────────────────────────────────────────────
# Minimal test area with a large world-axis checker floor (shadow-friendly),
# a single hero prop near the player and subtle lighting.

func _build_clean_stage() -> void:
	var geo := Node3D.new()
	geo.name = "CleanStage"
	add_child(geo)

	var ground := StaticBody3D.new()
	ground.collision_layer = 1
	geo.add_child(ground)

	var ground_mesh := MeshInstance3D.new()
	var plane := BoxMesh.new()
	plane.size = Vector3(180.0, 0.5, 180.0)
	ground_mesh.mesh = plane
	ground_mesh.material_override = _make_floor_mat_for_demo()
	ground_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ground_mesh.extra_cull_margin = 8192.0
	ground.add_child(ground_mesh)

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(180.0, 0.5, 180.0)
	col.shape = shape
	ground.add_child(col)

	ground.position = Vector3(0.0, -0.25, 0.0)

	# Invisible walls so arena is bounded without visual clutter.
	_add_invisible_wall(geo, Vector3(180.0, 6.0, 1.0), Vector3(0.0, 3.0, -90.0))
	_add_invisible_wall(geo, Vector3(180.0, 6.0, 1.0), Vector3(0.0, 3.0, 90.0))
	_add_invisible_wall(geo, Vector3(1.0, 6.0, 180.0), Vector3(-90.0, 3.0, 0.0))
	_add_invisible_wall(geo, Vector3(1.0, 6.0, 180.0), Vector3(90.0, 3.0, 0.0))

	# Hero rock next to the player (mirrors reference image composition).
	_add_hero_rock(geo, Vector3(-1.3, 0.0, 0.3))

	# Few distant pillars just to break the floor horizon.
	_add_soft_pillar(geo, Vector3(-14.0, 0.0, -12.0), Vector3(1.1, 1.6, 1.1))
	_add_soft_pillar(geo, Vector3(14.0, 0.0, 12.0), Vector3(1.1, 1.6, 1.1))

func _build_clean_spawn_points() -> void:
	var spawn_root := Node3D.new()
	spawn_root.name = "SpawnPoints"
	add_child(spawn_root)
	# Fewer and farther spawn points to keep the framing clean like the reference.
	var points := [
		Vector3(-16.0, 0.6, -4.0),
		Vector3(16.0, 0.6, 4.0)
	]
	for i in points.size():
		var sp := EnemySpawnPoint.new()
		sp.name = "Spawn_%d" % i
		sp.enemy_scene = ENEMY_SCENE
		sp.position = points[i]
		sp.add_to_group("spawn_point")
		spawn_root.add_child(sp)

func _build_clean_lighting() -> void:
	var key := OmniLight3D.new()
	key.position = Vector3(-2.4, 3.2, 2.2)
	key.light_color = Color(1.0, 0.97, 0.92, 1.0)
	key.light_energy = 0.42 if demo_look != DemoLook.REF_VIDEO_DEVLOG else 0.30
	key.omni_range = 10.0
	key.shadow_enabled = false
	add_child(key)

	var rim := OmniLight3D.new()
	rim.position = Vector3(3.2, 2.4, -2.4)
	rim.light_color = Color(0.58, 0.78, 1.0, 1.0)
	rim.light_energy = 0.30 if demo_look != DemoLook.REF_VIDEO_DEVLOG else 0.18
	rim.omni_range = 9.0
	rim.shadow_enabled = false
	add_child(rim)

# ── Utilities ────────────────────────────────────────────────────────────────

func _make_floor_mat_for_demo() -> ShaderMaterial:
	match demo_look:
		DemoLook.CLINICAL_CHECKER:
			return _make_clinical_checker_floor_mat()
		DemoLook.VIDEO_INTRO_GRASS:
			return _make_video_intro_grass_floor_mat()
		_:
			return _make_ref_video_devlog_floor_mat()


func _make_ref_video_devlog_floor_mat() -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = FLOOR_PIXEL_SHADER
	# pattern_mode 0 = rombos (45°), como en la captura de referencia.
	mat.set_shader_parameter("pattern_mode", 0)
	mat.set_shader_parameter("color_a", Color(0.11, 0.11, 0.13))
	mat.set_shader_parameter("color_b", Color(0.20, 0.21, 0.24))
	mat.set_shader_parameter("line_color", Color(0.06, 0.06, 0.08))
	mat.set_shader_parameter("shade_tint", Color(0.96, 0.97, 1.0))
	mat.set_shader_parameter("cell_size", 2.15)
	mat.set_shader_parameter("line_width", 0.024)
	mat.set_shader_parameter("grout_weight", 0.62)
	mat.set_shader_parameter("contrast", 1.08)
	mat.set_shader_parameter("checker_strength", 1.0)
	mat.set_shader_parameter("micro_dither", 0.003)
	mat.set_shader_parameter("pattern_rotation", 0.7853981633)
	mat.set_shader_parameter("shadow_darkness", 0.30)
	mat.set_shader_parameter("shadow_cool", 0.1)
	mat.set_shader_parameter("light_bands", 5.0)
	mat.set_shader_parameter("pixel_grid_size", 0.13)
	mat.set_shader_parameter("albedo_cap", 0.86)
	return mat


func _make_clinical_checker_floor_mat() -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = FLOOR_PIXEL_SHADER
	mat.set_shader_parameter("pattern_mode", 1)
	mat.set_shader_parameter("color_a", Color(0.38, 0.42, 0.48))
	mat.set_shader_parameter("color_b", Color(0.52, 0.55, 0.60))
	mat.set_shader_parameter("line_color", Color(0.22, 0.24, 0.30))
	mat.set_shader_parameter("shade_tint", Color(0.94, 0.96, 1.02))
	mat.set_shader_parameter("cell_size", 2.05)
	mat.set_shader_parameter("line_width", 0.022)
	mat.set_shader_parameter("grout_weight", 0.58)
	mat.set_shader_parameter("contrast", 1.04)
	mat.set_shader_parameter("checker_strength", 1.0)
	mat.set_shader_parameter("micro_dither", 0.004)
	mat.set_shader_parameter("pattern_rotation", 0.7853981633)
	mat.set_shader_parameter("shadow_darkness", 0.34)
	mat.set_shader_parameter("shadow_cool", 0.11)
	mat.set_shader_parameter("light_bands", 5.0)
	mat.set_shader_parameter("pixel_grid_size", 0.14)
	mat.set_shader_parameter("albedo_cap", 0.90)
	return mat


func _make_video_intro_grass_floor_mat() -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = FLOOR_PIXEL_SHADER
	# Mismo shader: rejilla mundo + bandas de luz; colores “pasto” discretos (no textura HD).
	mat.set_shader_parameter("pattern_mode", 1)
	mat.set_shader_parameter("color_a", Color(0.20, 0.38, 0.22))
	mat.set_shader_parameter("color_b", Color(0.30, 0.52, 0.28))
	mat.set_shader_parameter("line_color", Color(0.12, 0.26, 0.14))
	mat.set_shader_parameter("shade_tint", Color(0.90, 1.02, 0.88))
	mat.set_shader_parameter("cell_size", 1.85)
	mat.set_shader_parameter("line_width", 0.02)
	mat.set_shader_parameter("grout_weight", 0.52)
	mat.set_shader_parameter("contrast", 1.1)
	mat.set_shader_parameter("checker_strength", 1.0)
	mat.set_shader_parameter("micro_dither", 0.008)
	mat.set_shader_parameter("pattern_rotation", 0.7853981633)
	mat.set_shader_parameter("shadow_darkness", 0.32)
	mat.set_shader_parameter("shadow_cool", 0.14)
	mat.set_shader_parameter("light_bands", 5.0)
	mat.set_shader_parameter("pixel_grid_size", 0.12)
	mat.set_shader_parameter("albedo_cap", 0.88)
	return mat


func _apply_demo_atmosphere() -> void:
	var wenv := get_node_or_null("../../WorldEnvironment") as WorldEnvironment
	if not wenv or not wenv.environment:
		return
	var env := wenv.environment
	env.background_mode = Environment.BG_COLOR
	match demo_look:
		DemoLook.VIDEO_INTRO_GRASS:
			env.background_color = Color(0.42, 0.62, 0.78)
			env.ambient_light_color = Color(0.40, 0.50, 0.46)
			env.ambient_light_energy = 0.62
		DemoLook.REF_VIDEO_DEVLOG:
			env.background_color = Color(0.02, 0.02, 0.03)
			env.ambient_light_color = Color(0.18, 0.19, 0.22)
			env.ambient_light_energy = 0.36
		_:
			env.background_color = Color(0.05, 0.06, 0.09)
			env.ambient_light_color = Color(0.24, 0.28, 0.34)
			env.ambient_light_energy = 0.55
	var sun := get_node_or_null("../../DirectionalLight3D") as DirectionalLight3D
	if sun:
		match demo_look:
			DemoLook.VIDEO_INTRO_GRASS:
				sun.light_color = Color(1.0, 0.96, 0.88)
				sun.light_energy = 1.45
			DemoLook.REF_VIDEO_DEVLOG:
				sun.light_color = Color(1.0, 0.95, 0.88)
				sun.light_energy = 1.42
			_:
				sun.light_color = Color(1.0, 0.94, 0.86)
				sun.light_energy = 1.5

func _make_floor_ramp_texture(light_color: Color, dark_color: Color) -> GradientTexture1D:
	var gradient := Gradient.new()
	gradient.add_point(0.0, dark_color)
	gradient.add_point(0.55, dark_color.lerp(light_color, 0.55))
	gradient.add_point(1.0, light_color)
	var texture := GradientTexture1D.new()
	texture.width = 64
	texture.gradient = gradient
	return texture

func _make_specular_ramp_texture() -> GradientTexture1D:
	var gradient := Gradient.new()
	gradient.add_point(0.0, Color(0.0, 0.0, 0.0, 1.0))
	gradient.add_point(0.8, Color(0.08, 0.08, 0.1, 1.0))
	gradient.add_point(1.0, Color(1.0, 1.0, 1.0, 1.0))
	var texture := GradientTexture1D.new()
	texture.width = 64
	texture.gradient = gradient
	return texture

func _add_invisible_wall(parent: Node3D, size: Vector3, pos: Vector3) -> void:
	var wall := StaticBody3D.new()
	wall.collision_layer = 1
	parent.add_child(wall)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	wall.add_child(col)
	wall.position = pos

func _add_hero_rock(parent: Node3D, pos: Vector3) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	parent.add_child(body)
	body.position = pos

	# Organic crystal-like rock: multiple angled boxes with tonal variation.
	var shapes := [
		{"size": Vector3(0.80, 0.68, 0.80), "offset": Vector3(0.0, 0.34, 0.0), "rot": Vector3(12.0, 22.0, -8.0), "tone": Color(0.76, 0.80, 0.86)},
		{"size": Vector3(0.52, 0.46, 0.52), "offset": Vector3(0.30, 0.24, -0.16), "rot": Vector3(-6.0, -14.0, 18.0), "tone": Color(0.58, 0.62, 0.70)},
		{"size": Vector3(0.44, 0.40, 0.44), "offset": Vector3(-0.26, 0.22, 0.22), "rot": Vector3(8.0, 30.0, -4.0), "tone": Color(0.48, 0.52, 0.60)},
		{"size": Vector3(0.34, 0.28, 0.34), "offset": Vector3(0.06, 0.58, -0.10), "rot": Vector3(-12.0, 48.0, 10.0), "tone": Color(0.66, 0.72, 0.80)},
		{"size": Vector3(0.28, 0.22, 0.28), "offset": Vector3(-0.08, 0.66, 0.12), "rot": Vector3(18.0, 24.0, -14.0), "tone": Color(0.72, 0.76, 0.82)},
		{"size": Vector3(0.36, 0.22, 0.36), "offset": Vector3(0.22, 0.10, 0.12), "rot": Vector3(0.0, 18.0, 24.0), "tone": Color(0.40, 0.44, 0.50)}
	]
	for s in shapes:
		var mesh := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = s["size"]
		mesh.mesh = box
		mesh.position = s["offset"]
		mesh.rotation_degrees = s["rot"]
		var rock_mat := ShaderMaterial.new()
		rock_mat.shader = CHARACTER_PIXEL_SHADER
		var rock_tone := s["tone"] as Color
		rock_mat.set_shader_parameter("base_color", rock_tone)
		rock_mat.set_shader_parameter("shade_color", rock_tone.darkened(0.55))
		rock_mat.set_shader_parameter("highlight_color", rock_tone.lightened(0.15))
		rock_mat.set_shader_parameter("sun_dir", Vector3(-0.7, 0.7, 0.5))
		rock_mat.set_shader_parameter("shade_threshold", 0.48)
		rock_mat.set_shader_parameter("highlight_threshold", 0.72)
		mesh.material_override = rock_mat
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mesh.extra_cull_margin = 8192.0
		body.add_child(mesh)

	var col := CollisionShape3D.new()
	var col_shape := BoxShape3D.new()
	col_shape.size = Vector3(1.0, 0.8, 1.0)
	col.shape = col_shape
	col.position = Vector3(0.0, 0.4, 0.0)
	body.add_child(col)

func _add_soft_pillar(parent: Node3D, pos: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	parent.add_child(body)
	body.position = pos

	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.position = Vector3(0.0, size.y * 0.5, 0.0)
	mesh.material_override = PixelShaderStyler.make_cel_material(
		Color(0.38, 0.42, 0.50),
		Color(0.10, 0.12, 0.16),
		0.08,
		4.5,
		0.30,
		44.0
	)
	mesh.extra_cull_margin = 8192.0
	body.add_child(mesh)

	var col := CollisionShape3D.new()
	var col_shape := BoxShape3D.new()
	col_shape.size = size
	col.shape = col_shape
	col.position = Vector3(0.0, size.y * 0.5, 0.0)
	body.add_child(col)

# ── LEGACY STAGE (kept for fallback, not used while clean mode is on) ────────

func _build_legacy_stage() -> void:
	var geo := Node3D.new()
	geo.name = "LegacyStage"
	add_child(geo)
	var floor := StaticBody3D.new()
	floor.collision_layer = 1
	geo.add_child(floor)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(120.0, 0.5, 120.0)
	mesh.mesh = box
	mesh.material_override = _make_reference_floor_mat()
	floor.add_child(mesh)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(120.0, 0.5, 120.0)
	col.shape = shape
	floor.add_child(col)
	floor.position = Vector3(0.0, -0.25, 0.0)
