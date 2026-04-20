extends CharacterBody3D
class_name BaseEnemy
## BaseEnemy — Shared logic for all enemies.
## Direct-vector pathfinding (no NavMesh needed for beta).
## Override _on_state_update() in subclasses for unique behaviour.

@export_group("Stats")
@export var max_hp:          int   = 60
@export var move_speed:      float = 3.8
@export var acceleration:    float = 14.0
@export var damage:          int   = 20
@export var attack_range:    float = 1.4
@export var attack_cooldown: float = 1.3
@export var detection_range: float = 14.0
@export var fragment_drop:   int   = 5

@export_group("Hackeo")
@export var hackeable:       bool  = true
@export var hackeo_time:     float = 1.8   # duration of hackeo sequence before self-terminate

# ── Runtime ───────────────────────────────────────────────────────────────────

var hp:           int
var target:       Node3D = null
var _attack_cd:   float = 0.0
var _hackeo_timer: float = 0.0
var _is_dead:     bool = false
var _is_hacked:   bool = false

enum State { IDLE, CHASE, ATTACK, HACKED, DEAD }
var state: State = State.IDLE

# ── Signals ───────────────────────────────────────────────────────────────────

signal died(position: Vector3, fragment_amount: int)
signal hacked

# ─────────────────────────────────────────────────────────────────────────────

func _ready() -> void:
	hp = max_hp
	add_to_group("enemy")
	await get_tree().process_frame
	target = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	if _is_dead:
		return
	_tick_timers(delta)
	_update_ai(delta)
	_apply_movement(delta)
	move_and_slide()

# ── AI update ─────────────────────────────────────────────────────────────────

func _update_ai(_delta: float) -> void:
	match state:
		State.IDLE:
			if target and _dist() < detection_range:
				state = State.CHASE

		State.CHASE:
			if not target:
				state = State.IDLE
				return
			if _dist() <= attack_range:
				state = State.ATTACK
			elif _dist() > detection_range * 1.6:
				state = State.IDLE

		State.ATTACK:
			if not target:
				state = State.CHASE
				return
			if _dist() > attack_range * 1.3:
				state = State.CHASE
			elif _attack_cd <= 0.0:
				_do_attack()

		State.HACKED:
			pass   # timer handled in _tick_timers

func _apply_movement(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 20.0 * delta

	match state:
		State.CHASE:
			if target:
				var dir := (target.global_position - global_position)
				dir.y = 0.0
				dir = dir.normalized()
				velocity.x = move_toward(velocity.x, dir.x * move_speed, acceleration * delta)
				velocity.z = move_toward(velocity.z, dir.z * move_speed, acceleration * delta)
		State.ATTACK, State.HACKED:
			velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
			velocity.z = move_toward(velocity.z, 0.0, acceleration * delta)
		State.IDLE:
			velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
			velocity.z = move_toward(velocity.z, 0.0, acceleration * delta)

func _do_attack() -> void:
	_attack_cd = attack_cooldown
	if target and target.has_method("take_damage"):
		target.take_damage(damage, global_position)

# ── Damage ────────────────────────────────────────────────────────────────────

func take_damage(amount: int, _source_pos: Vector3 = Vector3.ZERO) -> void:
	if _is_dead or _is_hacked:
		return
	hp = max(0, hp - amount)
	HitFreeze.trigger(0.03)
	_on_hit()
	if hp <= 0:
		_die()

func _on_hit() -> void:
	pass  # subclasses: flash, particles, etc.

# ── Hackeo ────────────────────────────────────────────────────────────────────

func can_be_hacked() -> bool:
	return hackeable and not _is_hacked and not _is_dead

func begin_hackeo() -> void:
	_is_hacked   = true
	state        = State.HACKED
	_hackeo_timer = hackeo_time
	hacked.emit()

func _self_terminate() -> void:
	_die()   # Subclasses play dialogue before calling super

# ── Death ─────────────────────────────────────────────────────────────────────

func _die() -> void:
	_is_dead = true
	state    = State.DEAD
	velocity = Vector3.ZERO
	died.emit(global_position, fragment_drop)
	# Small delay so any death effects can play
	await get_tree().create_timer(0.1).timeout
	queue_free()

# ── Helpers ───────────────────────────────────────────────────────────────────

func _dist() -> float:
	if not target:
		return INF
	return global_position.distance_to(target.global_position)

func _tick_timers(delta: float) -> void:
	if _attack_cd > 0.0:
		_attack_cd -= delta
	if state == State.HACKED:
		_hackeo_timer -= delta
		if _hackeo_timer <= 0.0:
			_self_terminate()
