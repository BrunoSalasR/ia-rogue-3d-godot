extends Marker3D
class_name EnemySpawnPoint
## EnemySpawnPoint — Marker that knows which enemy to instantiate.
## Add to group "spawn_point" in the editor so Room can find it.

@export var enemy_scene: PackedScene
@export var auto_spawn_on_ready: bool = false

func _ready() -> void:
	add_to_group("spawn_point")
	if auto_spawn_on_ready:
		spawn()

func spawn() -> Node3D:
	if not enemy_scene:
		push_warning("EnemySpawnPoint: no enemy_scene assigned at %s" % name)
		return null

	var enemy: Node3D = enemy_scene.instantiate()
	# Add to the parent (the Room) so it's part of the scene tree properly
	get_parent().add_child(enemy)
	enemy.global_position = global_position
	return enemy
