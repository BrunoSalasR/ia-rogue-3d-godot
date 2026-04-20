extends Node3D
class_name Room
## Room — base class for all combat rooms.
## Locks doors when activated, tracks enemies, opens doors when cleared.

signal room_cleared
signal all_enemies_dead
signal enemy_spawned(enemy: Node3D)

@export var is_boss_room: bool = false
@export var fragment_bonus: int = 0  # extra fragments on clear

var enemies_alive:  int  = 0
var room_cleared_flag: bool = false
var is_active:      bool = false

# Doors and spawns are found by group tags set in the scene
@onready var spawn_points: Array[Node] = []
@onready var doors:        Array[Node] = []

func _ready() -> void:
	spawn_points = _get_children_in_group("spawn_point")
	doors        = _get_children_in_group("door")
	_set_doors_locked(true)

func activate() -> void:
	if is_active:
		return
	is_active = true
	_spawn_enemies()
	if enemies_alive == 0:
		_on_room_cleared()

# ── Enemy lifecycle ───────────────────────────────────────────────────────────

func _spawn_enemies() -> void:
	for sp in spawn_points:
		if sp.has_method("spawn"):
			var enemy = sp.spawn()
			if enemy:
				enemies_alive += 1
				enemy_spawned.emit(enemy)
				if enemy.has_signal("died"):
					enemy.died.connect(_on_enemy_died)

func _on_enemy_died(_pos: Vector3, _frags: int) -> void:
	enemies_alive = max(0, enemies_alive - 1)
	if enemies_alive == 0:
		all_enemies_dead.emit()
		_on_room_cleared()

func _on_room_cleared() -> void:
	if room_cleared_flag:
		return
	room_cleared_flag = true
	_set_doors_locked(false)
	if fragment_bonus > 0:
		GameManager.add_fragments(fragment_bonus)
	room_cleared.emit()

# ── Doors ────────────────────────────────────────────────────────────────────

func _set_doors_locked(locked: bool) -> void:
	for door in doors:
		if locked and door.has_method("lock"):
			door.lock()
		elif not locked and door.has_method("unlock"):
			door.unlock()

# ── Helpers ──────────────────────────────────────────────────────────────────

func _get_children_in_group(group_name: String) -> Array[Node]:
	var result: Array[Node] = []
	for child in get_children():
		if child.is_in_group(group_name):
			result.append(child)
		for sub in child.get_children():
			if sub.is_in_group(group_name):
				result.append(sub)
	return result
