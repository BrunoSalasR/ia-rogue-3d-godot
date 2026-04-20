extends Node3D
## PixelCameraRig — Follows the player with pixel-snapped isometric camera.
## Pixel snapping locks the camera to the world-space pixel grid, eliminating
## sub-pixel shimmer. pixel_size MUST equal ortho_size / viewport_height.

@export var follow_speed: float = 9.0

@export_group("Isometric Setup")
@export var ortho_size:   float = 6.5   # Camera3D.size (world units visible vertically)
@export var angle_x_deg:  float = -45.0  # pitch of the camera arm
@export var arm_distance: float = 14.0   # distance from target to camera
@export var intro_test_view: bool = true
@export var view_offset_xz: Vector2 = Vector2(0.0, -0.8)
@export var vertical_follow_damp: float = 0.25

var follow_target: Node3D = null
var _pixel_size:   float  = 0.0   # computed from SubViewport height at runtime
var _smooth_follow_pos: Vector3 = Vector3.ZERO
var _has_follow_seed: bool = false
var _angle_presets: Array[float] = [-40.0, -45.0, -50.0]
var _angle_idx: int = 1
var _p_was_down: bool = false
var _upscale_material: ShaderMaterial = null
var _intro_preset_applied: bool = false
var _smoothed_y: float = 0.0

@onready var camera: Camera3D = $Camera3D

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_apply_intro_test_preset()
	_angle_idx = _nearest_angle_idx(angle_x_deg)
	_configure_camera()
	_compute_pixel_size()
	_bind_upscale_material()

func _apply_intro_test_preset() -> void:
	if _intro_preset_applied or not intro_test_view:
		return
	# Framing inspired by "intro test" style: slightly steeper and wider to keep
	# character + immediate combat lanes legible.
	angle_x_deg = -38.0
	arm_distance = 12.0
	# Keep constant world-units-per-pixel when internal resolution changes (Holland-style 320×180, etc.).
	var h := 256.0
	var vp := get_viewport()
	if vp:
		h = float(max(vp.size.y, 1))
	ortho_size = 3.6 * (h / 256.0)
	_intro_preset_applied = true

func _configure_camera() -> void:
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size       = ortho_size
	camera.near       = 0.1
	camera.far        = 800.0
	camera.current    = true
	var rad := deg_to_rad(-angle_x_deg)
	camera.position   = Vector3(0.0, arm_distance * sin(rad), arm_distance * cos(rad))
	camera.rotation_degrees.x = angle_x_deg

func _compute_pixel_size() -> void:
	# Pixel size = world units covered by one rendered pixel (vertically).
	# This must match the SubViewport height for perfect grid-lock.
	var vp := get_viewport()
	if vp:
		var h := float(vp.size.y)
		_pixel_size = ortho_size / h if h > 0 else 0.0556
	else:
		_pixel_size = 0.0556   # fallback for 320×180 / size=10

func _process(delta: float) -> void:
	_handle_debug_input()
	camera.current = true

	if not follow_target:
		follow_target = get_tree().get_first_node_in_group("player")
		if not follow_target:
			return

	var desired := follow_target.global_position
	desired.y = 0.0  # mostly track XZ, keep slight vertical damp for stability
	desired.x += view_offset_xz.x
	desired.z += view_offset_xz.y

	if not _has_follow_seed:
		_smooth_follow_pos = desired
		_has_follow_seed = true
	else:
		var t := clampf(delta * follow_speed, 0.0, 1.0)
		_smooth_follow_pos = _smooth_follow_pos.lerp(desired, t)

	# Keep snapped camera for stable pixels.
	var snapped := _smooth_follow_pos
	if _pixel_size > 0.0:
		snapped.x = snappedf(snapped.x, _pixel_size)
		snapped.z = snappedf(snapped.z, _pixel_size)
	if not _has_follow_seed:
		_smoothed_y = snapped.y
	_smoothed_y = lerpf(_smoothed_y, snapped.y, clampf(delta * vertical_follow_damp, 0.0, 1.0))
	snapped.y = _smoothed_y
	global_position = snapped

	# Subpixel compensation to recover smooth movement without pixel crawl.
	var err := _smooth_follow_pos - snapped
	var texel_offset := Vector2.ZERO
	if _pixel_size > 0.0:
		texel_offset.x = err.x / _pixel_size
		texel_offset.y = -err.z / _pixel_size
	texel_offset = texel_offset.clamp(Vector2(-0.5, -0.5), Vector2(0.5, 0.5))
	_apply_texel_offset(texel_offset)

func _handle_debug_input() -> void:
	var p_down := Input.is_key_pressed(KEY_P)
	if p_down and not _p_was_down:
		_cycle_angle_preset()
	_p_was_down = p_down

func _cycle_angle_preset() -> void:
	_angle_idx = (_angle_idx + 1) % _angle_presets.size()
	angle_x_deg = _angle_presets[_angle_idx]
	_configure_camera()

func _nearest_angle_idx(value: float) -> int:
	var best_idx := 0
	var best_dist := INF
	for i in _angle_presets.size():
		var dist := absf(_angle_presets[i] - value)
		if dist < best_dist:
			best_dist = dist
			best_idx = i
	return best_idx

func _pixel_snap() -> void:
	if _pixel_size <= 0.0:
		return
	global_position.x = snappedf(global_position.x, _pixel_size)
	global_position.z = snappedf(global_position.z, _pixel_size)

func set_target(node: Node3D) -> void:
	follow_target = node

func force_snap_to_target() -> void:
	if follow_target:
		var desired := follow_target.global_position
		desired.y = 0.0
		_smooth_follow_pos = desired
		_has_follow_seed = true
		global_position = desired
		_pixel_snap()
		_apply_texel_offset(Vector2.ZERO)

func attach_to_target(node: Node3D) -> void:
	if not node:
		return
	follow_target = node
	if get_parent() != node:
		reparent(node)
	position = Vector3.ZERO
	force_snap_to_target()

func _bind_upscale_material() -> void:
	var scene := get_tree().current_scene
	if not scene:
		return
	var sv_container := scene.get_node_or_null("SVContainer") as SubViewportContainer
	if not sv_container:
		return
	if sv_container.material is ShaderMaterial:
		_upscale_material = sv_container.material as ShaderMaterial

func _apply_texel_offset(offset: Vector2) -> void:
	if _upscale_material:
		_upscale_material.set_shader_parameter("texel_offset", offset)
