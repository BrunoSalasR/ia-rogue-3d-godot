extends RefCounted
class_name PixelShaderStyler

const CEL_SHADER := preload("res://assets/shaders/spatial/cel_shader.gdshader")

static func make_cel_material(
	light_color: Color,
	dark_color: Color,
	specular_strength: float = 0.0,
	steepness: float = 1.0,
	light_wrap: float = 0.3,
	specular_shininess: float = 32.0
) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = CEL_SHADER
	mat.set_shader_parameter("cel_ramp", _make_ramp(light_color, dark_color))
	mat.set_shader_parameter("cel_specular_ramp", _make_specular_ramp())
	mat.set_shader_parameter("light_wrap", light_wrap)
	mat.set_shader_parameter("steepness", steepness)
	mat.set_shader_parameter("shadow_strength", 1.0)
	mat.set_shader_parameter("point_light_attenuation_curve", 1.0)
	mat.set_shader_parameter("specular_shininess", specular_shininess)
	mat.set_shader_parameter("specular_strength", specular_strength)
	mat.set_shader_parameter("use_dither", true)
	mat.set_shader_parameter("dither_strength", 0.22)
	mat.set_shader_parameter("dither_directional", true)
	return mat

static func apply_to_node_recursive(root: Node, material: Material) -> void:
	if root is MeshInstance3D:
		(root as MeshInstance3D).material_override = material
	for child in root.get_children():
		apply_to_node_recursive(child, material)

static func _make_ramp(light_color: Color, dark_color: Color) -> GradientTexture1D:
	var gradient := Gradient.new()
	gradient.add_point(0.0, dark_color)
	gradient.add_point(0.45, dark_color.lerp(light_color, 0.45))
	gradient.add_point(0.8, light_color)
	gradient.add_point(1.0, light_color.lightened(0.08))
	var texture := GradientTexture1D.new()
	texture.width = 64
	texture.gradient = gradient
	return texture

static func _make_specular_ramp() -> GradientTexture1D:
	var gradient := Gradient.new()
	gradient.add_point(0.0, Color(0.0, 0.0, 0.0, 1.0))
	gradient.add_point(0.75, Color(0.1, 0.1, 0.1, 1.0))
	gradient.add_point(1.0, Color(1.0, 1.0, 1.0, 1.0))
	var texture := GradientTexture1D.new()
	texture.width = 64
	texture.gradient = gradient
	return texture
