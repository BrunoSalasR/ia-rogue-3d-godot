extends CharacterBody3D
class_name Player
## Player — Hyper Light Drifter-inspired movement and combat.
##
## Controls:
##   WASD / Arrows   — 8-directional movement
##   Space           — Dash (3 charges, recharges independently, invincible)
##   Left Click      — Melee attack (arc in facing direction, lunge)
##   E               — Hackeo (costs Ciclos, targets nearest hackeable enemy)
##   F               — Interact
##
## HLD feel notes:
##   • Dash is instant, covers a fixed distance, and chains smoothly.
##   • Each dash charge recharges on its own timer — not a shared pool reset.
##   • Melee has a tight forward arc + slight forward lunge.
##   • Invincibility frames during dash only (no iframe on melee).

const PixelShaderStyler = preload("res://scripts/render/pixel_shader_styler.gd")
const CHARACTER_PIXEL_SHADER = preload("res://assets/shaders/spatial/character_pixel_toon.gdshader")

# ── Exports ───────────────────────────────────────────────────────────────────

@export_group("Movement")
@export var speed:        float = 9.0
@export var acceleration: float = 32.0
@export var friction:     float = 24.0

@export_group("Dash")
@export var dash_speed:        float = 34.0
@export var dash_duration:     float = 0.10   # seconds in dash state
@export var dash_min_interval: float = 0.06   # min gap between consecutive dashes
@export var max_dash_charges:  int   = 3
@export var dash_recharge_time: float = 0.70  # per-charge recharge

@export_group("Combat")
@export var max_hp:         int   = 100
@export var melee_damage:   int   = 30
@export var melee_range:    float = 2.2
@export var melee_arc_deg:  float = 130.0
@export var attack_duration: float = 0.16
@export var attack_cooldown: float = 0.20
@export var hit_iframes:    float = 0.55    # invincibility after taking damage
@export var knockback_force: float = 6.0

@export_group("Ciclos")
@export var max_ciclos:   int   = 100
@export var hackeo_cost:  int   = 40
@export var hackeo_range: float = 4.0

@export_group("Visual Form")
@export var start_form: String = "cube" # "cube" or "android"
@export var cube_model_scene: PackedScene
@export var android_model_scene: PackedScene

# ── Runtime state ─────────────────────────────────────────────────────────────

var hp:      int
var ciclos:  int
var facing:  Vector3 = Vector3.BACK   # world-space facing direction

var _move_input:   Vector2 = Vector2.ZERO

# Dash
var _dash_charges:     int   = 0
var _dash_timer:       float = 0.0    # counts down while dashing
var _dash_cd_timer:    float = 0.0    # minimum interval between dashes
var _recharge_timers:  Array = []     # one float per missing charge

# Attack
var _attack_timer:  float = 0.0
var _attack_cd:     float = 0.0

# Damage
var _iframe_timer: float = 0.0

enum State { IDLE, MOVE, DASH, ATTACK, DEAD }
var state: State = State.IDLE

# ── Signals ───────────────────────────────────────────────────────────────────

signal hp_changed(current: int, max_val: int)
signal ciclos_changed(current: int, max_val: int)
signal dash_charges_changed(charges: int, max_charges: int)
signal fragments_changed(total: int)
signal died
signal attack_landed(target: Node3D)
signal hackeo_triggered(target: Node3D)

# ── Node refs ─────────────────────────────────────────────────────────────────

@onready var mesh_pivot:   Node3D           = $MeshPivot
@onready var body_shape:   CollisionShape3D = $CollisionShape3D
@onready var attack_area:  Area3D           = $AttackArea
@onready var hackeo_area:  Area3D           = $HackeoArea
@onready var dash_particles: GPUParticles3D = $DashParticles
@onready var visual_model_anchor: Node3D    = $MeshPivot/VisualModelAnchor

var _active_visual_model: Node3D = null
var _android_augments_root: Node3D = null
var _android_augment_material: StandardMaterial3D = null
var _current_form: String = "cube"
var _visual_animation_player: AnimationPlayer = null
var _anim_idle: StringName = &""
var _anim_move: StringName = &""
var _anim_attack: StringName = &""
var _anim_dash: StringName = &""
var _last_anim_key: String = ""
var _procedural_anim_time: float = 0.0
var _demo_mode: bool = false
var _demo_t: float = 0.0

# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	hp      = max_hp
	ciclos  = max_ciclos
	_dash_charges = max_dash_charges
	_apply_visual_form(start_form)
	_apply_shader_style()
	_demo_mode = OS.get_cmdline_user_args().has("--auto-demo")
	hp_changed.emit(hp, max_hp)
	ciclos_changed.emit(ciclos, max_ciclos)
	dash_charges_changed.emit(_dash_charges, max_dash_charges)
	# Apply permanent upgrades from save
	_apply_upgrades()

func _apply_upgrades() -> void:
	if GameManager.has_upgrade("max_hp_up"):
		max_hp  += 25
		hp      = max_hp
	if GameManager.has_upgrade("max_ciclos_up"):
		max_ciclos += 20
		ciclos     = max_ciclos
	if GameManager.has_upgrade("hackeo_range"):
		hackeo_range *= 1.3
	if GameManager.has_upgrade("hackeo_cost_down"):
		hackeo_cost = max(8, hackeo_cost - 8)
	if GameManager.has_upgrade("dash_recharge"):
		dash_recharge_time *= 0.85

# ── Per-frame ─────────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	_tick_timers(delta)
	_orient_mesh()
	_update_visual_animation(delta)
	_tick_android_pulse()

func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
	_read_input()
	_update_state()
	_apply_physics(delta)
	move_and_slide()

# ── Input ─────────────────────────────────────────────────────────────────────

func _read_input() -> void:
	if _demo_mode:
		_demo_t += get_process_delta_time()
		_move_input = Vector2(cos(_demo_t * 0.7), sin(_demo_t * 0.7)).normalized()
		if int(_demo_t * 2.0) % 6 == 0 and _can_dash():
			_enter_dash()
	else:
		_move_input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if _move_input.length() > 0.1:
		facing = Vector3(_move_input.x, 0.0, _move_input.y).normalized()

func _update_state() -> void:
	match state:
		State.IDLE, State.MOVE:
			if Input.is_action_just_pressed("dash") and _can_dash():
				_enter_dash()
			elif Input.is_action_just_pressed("attack") and _attack_cd <= 0.0:
				_enter_attack()
			elif Input.is_action_just_pressed("hackeo") and ciclos >= hackeo_cost:
				_try_hackeo()
		State.DASH:
			# Allow chaining: press dash again once dash_cd clears
			if Input.is_action_just_pressed("dash") and _can_dash():
				_enter_dash()   # re-enter dash immediately
		State.ATTACK:
			# Can dash-cancel an attack if charges available
			if Input.is_action_just_pressed("dash") and _can_dash():
				_enter_dash()

func _can_dash() -> bool:
	return _dash_charges > 0 and _dash_cd_timer <= 0.0

# ── Movement & physics ────────────────────────────────────────────────────────

func _apply_physics(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 20.0 * delta

	match state:
		State.IDLE, State.MOVE:
			var target_xz := Vector3(_move_input.x, 0.0, _move_input.y) * speed
			if _move_input.length() > 0.1:
				velocity.x = move_toward(velocity.x, target_xz.x, acceleration * delta)
				velocity.z = move_toward(velocity.z, target_xz.z, acceleration * delta)
				state = State.MOVE
			else:
				velocity.x = move_toward(velocity.x, 0.0, friction * delta)
				velocity.z = move_toward(velocity.z, 0.0, friction * delta)
				state = State.IDLE

		State.DASH:
			velocity.x = facing.x * dash_speed
			velocity.z = facing.z * dash_speed

		State.ATTACK:
			# Short forward lunge gives melee snappiness
			var lunge := facing * speed * 0.5
			velocity.x = move_toward(velocity.x, lunge.x, acceleration * delta)
			velocity.z = move_toward(velocity.z, lunge.z, acceleration * delta)

# ── Dash ──────────────────────────────────────────────────────────────────────

func _enter_dash() -> void:
	state = State.DASH
	_dash_charges    -= 1
	_dash_timer       = dash_duration
	_dash_cd_timer    = dash_min_interval
	_recharge_timers.append(0.0)   # start tracking this charge's recharge
	dash_charges_changed.emit(_dash_charges, max_dash_charges)
	if dash_particles:
		dash_particles.restart()
		dash_particles.emitting = true
		_stop_dash_particles_after_duration()

func _stop_dash_particles_after_duration() -> void:
	await get_tree().create_timer(dash_duration).timeout
	if dash_particles:
		dash_particles.emitting = false

# ── Melee ─────────────────────────────────────────────────────────────────────

func _enter_attack() -> void:
	state          = State.ATTACK
	_attack_timer  = attack_duration
	_attack_cd     = attack_cooldown
	_do_melee()

func _do_melee() -> void:
	var space  := get_world_3d().direct_space_state
	var query  := PhysicsShapeQueryParameters3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius   = melee_range
	query.shape     = sphere
	query.transform = global_transform
	query.collision_mask = 0b100  # layer 3 = enemies
	var hit_any := false

	for result in space.intersect_shape(query):
		var body: Node3D = result["collider"]
		if body == self:
			continue
		# Angle check — only hit things inside the arc
		var to_target := (body.global_position - global_position)
		to_target.y = 0.0
		if to_target.length_squared() < 0.001:
			continue
		var angle_deg := rad_to_deg(facing.angle_to(to_target.normalized()))
		if angle_deg > melee_arc_deg * 0.5:
			continue
		if body.has_method("take_damage"):
			body.take_damage(melee_damage, global_position)
			attack_landed.emit(body)
			hit_any = true
	if hit_any:
		HitFreeze.trigger(0.04)

# ── Hackeo ────────────────────────────────────────────────────────────────────

func _try_hackeo() -> void:
	if ciclos < hackeo_cost:
		return
	# Find nearest hackeable enemy within range
	var best_target: Node3D = null
	var best_dist:   float  = hackeo_range
	for body in hackeo_area.get_overlapping_bodies():
		if body == self:
			continue
		if body.has_method("can_be_hacked") and body.can_be_hacked():
			var dist := global_position.distance_to(body.global_position)
			if dist < best_dist:
				best_dist   = dist
				best_target = body
	if best_target:
		ciclos -= hackeo_cost
		ciclos_changed.emit(ciclos, max_ciclos)
		best_target.begin_hackeo()
		hackeo_triggered.emit(best_target)

# ── Taking damage ─────────────────────────────────────────────────────────────

func take_damage(amount: int, source_pos: Vector3 = Vector3.ZERO) -> void:
	if state == State.DASH:
		return   # invincible during dash
	if _iframe_timer > 0.0:
		return
	if state == State.DEAD:
		return

	hp = max(0, hp - amount)
	_iframe_timer = hit_iframes

	# Knockback
	if source_pos != Vector3.ZERO:
		var kb_dir := (global_position - source_pos).normalized()
		kb_dir.y = 0.0
		velocity += kb_dir * knockback_force

	hp_changed.emit(hp, max_hp)
	HitFreeze.trigger(0.03)
	if hp <= 0:
		_die()

func _die() -> void:
	state    = State.DEAD
	velocity = Vector3.ZERO
	died.emit()

# ── Timers ────────────────────────────────────────────────────────────────────

func _tick_timers(delta: float) -> void:
	# Dash active
	if state == State.DASH:
		_dash_timer -= delta
		if _dash_timer <= 0.0:
			state = State.IDLE

	# Between-dash cooldown
	if _dash_cd_timer > 0.0:
		_dash_cd_timer -= delta

	# Per-charge recharge
	var i := 0
	while i < _recharge_timers.size():
		_recharge_timers[i] += delta
		if _recharge_timers[i] >= dash_recharge_time:
			_recharge_timers.remove_at(i)
			_dash_charges = min(_dash_charges + 1, max_dash_charges)
			dash_charges_changed.emit(_dash_charges, max_dash_charges)
		else:
			i += 1

	# Attack
	if state == State.ATTACK:
		_attack_timer -= delta
		if _attack_timer <= 0.0:
			state = State.IDLE
	if _attack_cd > 0.0:
		_attack_cd -= delta

	# Invincibility
	if _iframe_timer > 0.0:
		_iframe_timer -= delta

# ── Visuals ───────────────────────────────────────────────────────────────────

func _orient_mesh() -> void:
	if not mesh_pivot or facing.length() < 0.1:
		return
	# glTF models (Adventurer) face -Z by default. Add PI so that facing +Z (idle,
	# default Vector3.BACK) shows the face toward camera, and moving forward
	# (-Z direction) shows the back to camera. For the cube form we skip the offset.
	var offset := 0.0
	var target_y := atan2(facing.x, facing.z) + offset
	mesh_pivot.rotation.y = lerp_angle(mesh_pivot.rotation.y, target_y, 0.2)

func set_visual_form(form: String) -> void:
	_apply_visual_form(form)

func _apply_visual_form(form: String) -> void:
	_current_form = form
	_clear_active_visual_model()
	_set_primitive_mesh_visible(true)
	if not visual_model_anchor:
		return

	var target_scene: PackedScene = null
	if form == "android":
		target_scene = android_model_scene
	else:
		target_scene = cube_model_scene

	if target_scene:
		var inst := target_scene.instantiate()
		if inst is Node3D:
			_active_visual_model = inst
			if form == "android":
				_active_visual_model.scale = Vector3.ONE * 0.85
			visual_model_anchor.add_child(_active_visual_model)
			_disable_instanced_cameras(_active_visual_model)
			_cache_visual_animation_player(_active_visual_model)
			_force_nearest_texture_filter(_active_visual_model)
			_set_primitive_mesh_visible(false)
			if form == "android":
				_add_blob_shadow()
	_attach_android_augments(form)
	_apply_shader_style()
	_apply_hitbox_for_form(form)

func _clear_active_visual_model() -> void:
	if _active_visual_model:
		_active_visual_model.queue_free()
		_active_visual_model = null
	if _android_augments_root:
		_android_augments_root.queue_free()
		_android_augments_root = null
	_android_augment_material = null
	_visual_animation_player = null
	_anim_idle = &""
	_anim_move = &""
	_anim_attack = &""
	_anim_dash = &""
	_last_anim_key = ""

func _set_primitive_mesh_visible(visible_state: bool) -> void:
	for child in mesh_pivot.get_children():
		if child == visual_model_anchor:
			continue
		if child is MeshInstance3D:
			child.visible = visible_state

func _apply_hitbox_for_form(form: String) -> void:
	if not body_shape:
		return
	var capsule := body_shape.shape as CapsuleShape3D
	if not capsule:
		return
	if form == "android":
		capsule.radius = 0.28
		capsule.height = 0.85
		body_shape.position.y = 0.43
	else:
		# Cubo digital humanoide: hitbox vertical que encaja con torso+cabeza.
		capsule.radius = 0.30
		capsule.height = 1.25
		body_shape.position.y = 0.72

func _disable_instanced_cameras(root: Node) -> void:
	for child in root.get_children():
		if child is Camera3D:
			var cam := child as Camera3D
			cam.current = false
			cam.enabled = false
		_disable_instanced_cameras(child)

func _apply_shader_style() -> void:
	if _active_visual_model and _current_form == "android":
		# The Adventurer gltf already has pixel-art baked textures (Kay Lousberg
		# color palette atlas). We preserve them and only ensure nearest filtering
		# so they read as real pixel-art. Cel banding comes from the outline shader
		# + directional light + the upscale/contrast post.
		return
	var light := Color(0.78, 0.52, 1.0, 1.0)
	var dark := Color(0.11, 0.04, 0.22, 1.0)
	var wrap := 0.2
	var steep := 6.0
	var specular := 0.6
	var shininess := 64.0
	if _current_form == "cube":
		light = Color(0.46, 0.85, 1.0, 1.0)
		dark = Color(0.05, 0.12, 0.22, 1.0)
		wrap = 0.24
		steep = 5.5
		specular = 0.45
		shininess = 48.0
	var mat := PixelShaderStyler.make_cel_material(light, dark, specular, steep, wrap, shininess)
	PixelShaderStyler.apply_to_node_recursive(mesh_pivot, mat)

func _add_blob_shadow() -> void:
	# Add the blob shadow as a direct child of the player (not MeshPivot or the
	# model anchor) so it stays flat on the floor even when the model rotates.
	var existing := get_node_or_null("BlobShadow")
	if existing:
		existing.queue_free()
	var mesh := MeshInstance3D.new()
	mesh.name = "BlobShadow"
	var plane := PlaneMesh.new()
	plane.size = Vector2(1.8, 0.9)
	mesh.mesh = plane
	mesh.position = Vector3(0.45, 0.02, 0.25)
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
	mat.albedo_color = Color(0.05, 0.05, 0.07, 0.55)
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mesh.material_override = mat
	add_child(mesh)

func _force_nearest_texture_filter(root: Node) -> void:
	# Walk the entire model tree and: (1) force NEAREST filtering, (2) switch
	# lighting to TOON so Kay's pixel textures get hard cel bands, (3) ensure
	# all meshes cast shadow on the floor.
	if root is MeshInstance3D:
		var mi := root as MeshInstance3D
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		var mesh_ref := mi.mesh
		if mesh_ref:
			for i in range(mesh_ref.get_surface_count()):
				var src_mat = mesh_ref.surface_get_material(i)
				if src_mat is StandardMaterial3D:
					var dup := (src_mat as StandardMaterial3D).duplicate() as StandardMaterial3D
					dup.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
					dup.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
					dup.specular_mode = BaseMaterial3D.SPECULAR_TOON
					dup.metallic_specular = 0.0
					dup.roughness = 0.92
					# Null / clinical MC: subtle cool-violet multiply on Kay's baked albedo.
					dup.albedo_color = dup.albedo_color * Color(1.045, 0.97, 1.08)
					dup.rim_enabled = true
					dup.rim = 0.045
					dup.rim_tint = 0.35
					mi.set_surface_override_material(i, dup)
	for child in root.get_children():
		_force_nearest_texture_filter(child)

func _convert_hero_materials_to_pixel_toon(root: Node) -> void:
	if root is MeshInstance3D:
		var mi := root as MeshInstance3D
		var existing := mi.get_surface_override_material(0)
		var base_col := Color(0.72, 0.58, 0.42)
		if existing is StandardMaterial3D:
			base_col = (existing as StandardMaterial3D).albedo_color
		elif existing is ShaderMaterial:
			var v = (existing as ShaderMaterial).get_shader_parameter("base_color")
			if v is Color:
				base_col = v
		if mi.material_override is ShaderMaterial and (mi.material_override as ShaderMaterial).shader == CHARACTER_PIXEL_SHADER:
			return
		# Skip toon conversion on very dark details (eyes, mouth) and tiny
		# semi-transparent elements (blob shadow) — preserve their flat source material.
		var luma := base_col.r * 0.299 + base_col.g * 0.587 + base_col.b * 0.114
		if luma < 0.18:
			return
		if existing is StandardMaterial3D and (existing as StandardMaterial3D).transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
			return
		var mat := ShaderMaterial.new()
		mat.shader = CHARACTER_PIXEL_SHADER
		mat.set_shader_parameter("base_color", base_col)
		mat.set_shader_parameter("shade_color", base_col.darkened(0.58))
		mat.set_shader_parameter("highlight_color", base_col.lightened(0.22))
		mat.set_shader_parameter("sun_dir", Vector3(-0.7, 0.7, 0.5))
		mat.set_shader_parameter("shade_threshold", 0.48)
		mat.set_shader_parameter("highlight_threshold", 0.72)
		mi.material_override = mat
	for child in root.get_children():
		_convert_hero_materials_to_pixel_toon(child)

func _attach_android_augments(form: String) -> void:
	# Disabled: augments clash with full humanoid model silhouette.
	# The Adventurer already reads as a character; leaving augments off keeps the
	# reference-style clean look.
	return
	if not visual_model_anchor:
		return
	if form != "android":
		return
	_android_augments_root = Node3D.new()
	_android_augments_root.name = "AndroidAugments"
	visual_model_anchor.add_child(_android_augments_root)

	var chest_core := MeshInstance3D.new()
	var core_mesh := SphereMesh.new()
	core_mesh.radius = 0.12
	core_mesh.height = 0.24
	chest_core.mesh = core_mesh
	chest_core.position = Vector3(0.0, 0.95, 0.07)
	_android_augments_root.add_child(chest_core)

	var visor := MeshInstance3D.new()
	var visor_mesh := BoxMesh.new()
	visor_mesh.size = Vector3(0.24, 0.05, 0.04)
	visor.mesh = visor_mesh
	visor.position = Vector3(0.0, 1.42, 0.14)
	_android_augments_root.add_child(visor)

	var spine := MeshInstance3D.new()
	var spine_mesh := BoxMesh.new()
	spine_mesh.size = Vector3(0.07, 0.36, 0.07)
	spine.mesh = spine_mesh
	spine.position = Vector3(0.0, 0.88, -0.09)
	_android_augments_root.add_child(spine)

	var shoulder_l := MeshInstance3D.new()
	var shoulder_r := MeshInstance3D.new()
	var shoulder_mesh := BoxMesh.new()
	shoulder_mesh.size = Vector3(0.11, 0.11, 0.18)
	shoulder_l.mesh = shoulder_mesh
	shoulder_r.mesh = shoulder_mesh
	shoulder_l.position = Vector3(-0.26, 1.15, 0.03)
	shoulder_r.position = Vector3(0.26, 1.15, 0.03)
	_android_augments_root.add_child(shoulder_l)
	_android_augments_root.add_child(shoulder_r)

	var back_fin := MeshInstance3D.new()
	var fin_mesh := BoxMesh.new()
	fin_mesh.size = Vector3(0.06, 0.40, 0.24)
	back_fin.mesh = fin_mesh
	back_fin.position = Vector3(0.0, 1.20, -0.14)
	_android_augments_root.add_child(back_fin)

	var shoulder_fin_l := MeshInstance3D.new()
	var shoulder_fin_r := MeshInstance3D.new()
	var shoulder_fin_mesh := BoxMesh.new()
	shoulder_fin_mesh.size = Vector3(0.06, 0.24, 0.22)
	shoulder_fin_l.mesh = shoulder_fin_mesh
	shoulder_fin_r.mesh = shoulder_fin_mesh
	shoulder_fin_l.position = Vector3(-0.30, 1.20, -0.06)
	shoulder_fin_r.position = Vector3(0.30, 1.20, -0.06)
	shoulder_fin_l.rotation_degrees = Vector3(0.0, 18.0, -16.0)
	shoulder_fin_r.rotation_degrees = Vector3(0.0, -18.0, 16.0)
	_android_augments_root.add_child(shoulder_fin_l)
	_android_augments_root.add_child(shoulder_fin_r)

	var waist_ring := MeshInstance3D.new()
	var waist_mesh := CylinderMesh.new()
	waist_mesh.top_radius = 0.24
	waist_mesh.bottom_radius = 0.28
	waist_mesh.height = 0.10
	waist_ring.mesh = waist_mesh
	waist_ring.position = Vector3(0.0, 0.76, 0.0)
	_android_augments_root.add_child(waist_ring)

	var forearm_l := MeshInstance3D.new()
	var forearm_r := MeshInstance3D.new()
	var forearm_mesh := BoxMesh.new()
	forearm_mesh.size = Vector3(0.07, 0.28, 0.14)
	forearm_l.mesh = forearm_mesh
	forearm_r.mesh = forearm_mesh
	forearm_l.position = Vector3(-0.34, 0.92, 0.04)
	forearm_r.position = Vector3(0.34, 0.92, 0.04)
	_android_augments_root.add_child(forearm_l)
	_android_augments_root.add_child(forearm_r)

	var shin_l := MeshInstance3D.new()
	var shin_r := MeshInstance3D.new()
	var shin_mesh := BoxMesh.new()
	shin_mesh.size = Vector3(0.10, 0.22, 0.11)
	shin_l.mesh = shin_mesh
	shin_r.mesh = shin_mesh
	shin_l.position = Vector3(-0.12, 0.34, 0.10)
	shin_r.position = Vector3(0.12, 0.34, 0.10)
	_android_augments_root.add_child(shin_l)
	_android_augments_root.add_child(shin_r)

	var heel_l := MeshInstance3D.new()
	var heel_r := MeshInstance3D.new()
	var heel_mesh := BoxMesh.new()
	heel_mesh.size = Vector3(0.08, 0.06, 0.14)
	heel_l.mesh = heel_mesh
	heel_r.mesh = heel_mesh
	heel_l.position = Vector3(-0.12, 0.16, -0.06)
	heel_r.position = Vector3(0.12, 0.16, -0.06)
	_android_augments_root.add_child(heel_l)
	_android_augments_root.add_child(heel_r)

	var antenna_l := MeshInstance3D.new()
	var antenna_r := MeshInstance3D.new()
	var antenna_mesh := CylinderMesh.new()
	antenna_mesh.top_radius = 0.015
	antenna_mesh.bottom_radius = 0.02
	antenna_mesh.height = 0.26
	antenna_l.mesh = antenna_mesh
	antenna_r.mesh = antenna_mesh
	antenna_l.position = Vector3(-0.09, 1.56, -0.02)
	antenna_r.position = Vector3(0.09, 1.56, -0.02)
	_android_augments_root.add_child(antenna_l)
	_android_augments_root.add_child(antenna_r)
	_apply_android_augment_material()

func _apply_android_augment_material() -> void:
	if not _android_augments_root:
		return
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.24, 0.13, 0.48, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.88, 0.34, 1.0, 1.0)
	mat.emission_energy_multiplier = 0.35
	mat.roughness = 0.26
	mat.metallic = 0.92
	mat.rim_enabled = true
	mat.rim = 0.45
	mat.rim_tint = 0.7
	_android_augment_material = mat
	for child in _android_augments_root.get_children():
		if child is MeshInstance3D:
			(child as MeshInstance3D).material_override = mat

func _tick_android_pulse() -> void:
	if not _android_augment_material:
		return
	var pulse := 0.30 + 0.08 * sin(Time.get_ticks_msec() * 0.004)
	_android_augment_material.emission_energy_multiplier = pulse

func _cache_visual_animation_player(root: Node) -> void:
	_visual_animation_player = _find_animation_player(root)
	if not _visual_animation_player:
		return
	_anim_idle = _pick_animation_name(["idle", "stand", "rest"])
	_anim_move = _pick_animation_name(["run", "walk", "move", "jog"])
	_anim_attack = _pick_animation_name(["attack", "melee", "slash", "hit"])
	_anim_dash = _pick_animation_name(["dash", "roll", "dodge"])

func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found := _find_animation_player(child)
		if found:
			return found
	return null

func _pick_animation_name(candidates: Array[String]) -> StringName:
	if not _visual_animation_player or _visual_animation_player.get_animation_list().is_empty():
		return &""
	for candidate in candidates:
		for anim in _visual_animation_player.get_animation_list():
			var key := String(anim).to_lower()
			if key.find(candidate) != -1:
				return anim
	return _visual_animation_player.get_animation_list()[0]

func _update_visual_animation(delta: float) -> void:
	if not _visual_animation_player:
		_update_procedural_visual_animation(delta)
		return
	var desired_key := "idle"
	var desired_anim := _anim_idle
	if state == State.DASH and _anim_dash != &"":
		desired_key = "dash"
		desired_anim = _anim_dash
	elif state == State.ATTACK and _anim_attack != &"":
		desired_key = "attack"
		desired_anim = _anim_attack
	elif _move_input.length() > 0.1 and _anim_move != &"":
		desired_key = "move"
		desired_anim = _anim_move
	if desired_anim == &"":
		return
	if _last_anim_key != desired_key:
		_visual_animation_player.play(desired_anim, 0.2)
		_last_anim_key = desired_key

func _update_procedural_visual_animation(delta: float) -> void:
	if not mesh_pivot:
		return
	_procedural_anim_time += delta
	var t := _procedural_anim_time
	var bob := 0.0
	var tilt_x := 0.0
	var tilt_z := 0.0
	var scale_mul := 1.0
	match state:
		State.DASH:
			bob = 0.07
			tilt_x = -18.0
			scale_mul = 0.96
		State.ATTACK:
			bob = 0.03 + sin(t * 40.0) * 0.01
			tilt_x = -10.0
			tilt_z = sin(t * 20.0) * 3.0
			scale_mul = 1.04
		State.MOVE:
			bob = sin(t * 12.0) * 0.06
			tilt_z = sin(t * 8.0) * 5.0
		_:
			bob = sin(t * 3.5) * 0.015
	mesh_pivot.position.y = move_toward(mesh_pivot.position.y, bob, delta * 2.8)
	mesh_pivot.rotation.x = lerp_angle(mesh_pivot.rotation.x, deg_to_rad(tilt_x), delta * 8.5)
	mesh_pivot.rotation.z = lerp_angle(mesh_pivot.rotation.z, deg_to_rad(tilt_z), delta * 7.2)
	var target_scale := Vector3.ONE * scale_mul
	mesh_pivot.scale = mesh_pivot.scale.lerp(target_scale, min(delta * 8.0, 1.0))
