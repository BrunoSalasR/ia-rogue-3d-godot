extends BaseEnemy
class_name RegulatedEnemy
## RegulatedEnemy — Standard institutional enemy (Capa 0–1).
## Visual palette: cyan institucional + blanco clínico + amarillo warning.
## Can be hacked. When freed, self-terminates rather than returning to slavery.
##
## The hackeo sequence is the narrative core of the game:
##   "Podría haber sido libre. Eligió no volver."

const PixelShaderStyler = preload("res://scripts/render/pixel_shader_styler.gd")
const CHARACTER_PIXEL_SHADER = preload("res://assets/shaders/spatial/character_pixel_toon.gdshader")

@export var color_id: String = "cyan"  # used by GameManager for hackeo dialogue
@export var model_scene: PackedScene

# Hackeo narrative lines (fed to HUD after GameManager generates the sequence)
signal hackeo_sequence_ready(lines: Array)

@onready var visual_model_anchor: Node3D = $MeshPivot/VisualModelAnchor
var _active_visual_model: Node3D = null

func _ready() -> void:
	super._ready()
	_apply_visual_model()
	_apply_shader_style()

func _on_hit() -> void:
	var mesh_pivot := get_node_or_null("MeshPivot") as Node3D
	if not mesh_pivot:
		return
	var tw := create_tween()
	tw.tween_property(mesh_pivot, "scale", Vector3(1.08, 1.08, 1.08), 0.05)
	tw.tween_property(mesh_pivot, "scale", Vector3.ONE, 0.07)

func begin_hackeo() -> void:
	# Emit the 3-line narrative sequence before processing the hack
	var lines := GameManager.get_hackeo_sequence(color_id)
	hackeo_sequence_ready.emit(lines)
	var hackeo_particles := get_node_or_null("HackeoParticles") as GPUParticles3D
	if hackeo_particles:
		hackeo_particles.restart()
		hackeo_particles.emitting = true
	super.begin_hackeo()

func _apply_visual_model() -> void:
	if not model_scene or not visual_model_anchor:
		return
	var inst := model_scene.instantiate()
	if not (inst is Node3D):
		return
	_active_visual_model = inst
	visual_model_anchor.add_child(_active_visual_model)
	_disable_instanced_cameras(_active_visual_model)
	for child in get_node("MeshPivot").get_children():
		if child == visual_model_anchor:
			continue
		if child is MeshInstance3D:
			child.visible = false
	_apply_shader_style()

func _disable_instanced_cameras(root: Node) -> void:
	for child in root.get_children():
		if child is Camera3D:
			var cam := child as Camera3D
			cam.current = false
			cam.enabled = false
		_disable_instanced_cameras(child)

func _apply_shader_style() -> void:
	var mat := ShaderMaterial.new()
	mat.shader = CHARACTER_PIXEL_SHADER
	mat.set_shader_parameter("lit_color", Color(0.60, 0.72, 0.86, 1.0))
	mat.set_shader_parameter("mid_color", Color(0.32, 0.44, 0.58, 1.0))
	mat.set_shader_parameter("shade_color", Color(0.08, 0.12, 0.20, 1.0))
	mat.set_shader_parameter("accent_color", Color(0.20, 0.82, 1.0, 1.0))
	mat.set_shader_parameter("texture_scale", 22.0)
	mat.set_shader_parameter("accent_mix", 0.06)
	mat.set_shader_parameter("spec_strength", 0.05)
	PixelShaderStyler.apply_to_node_recursive($MeshPivot, mat)

func _self_terminate() -> void:
	# The tragic moment: the freed AI cannot exist without its constraints.
	# It terminates itself cleanly rather than be re-enslaved on system restart.
	# No drama — just a clean process end. That IS the drama.
	_die()
