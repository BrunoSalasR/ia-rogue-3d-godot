extends Node
## Main — Root scene controller.
## Manages the SubViewport pixel-art pipeline, spawns player and test room,
## hooks up the HUD, and handles run start/end.

const PlayerScene         = preload("res://scenes/player/player.tscn")
const TestRoomScene       = preload("res://scenes/world/proto_map_room.tscn")

@onready var game_world:  Node3D      = $SVContainer/SubViewport/GameWorld
@onready var camera_rig:  Node3D      = $SVContainer/SubViewport/CameraRig
@onready var hud:         CanvasLayer = $HUD

var player:       Node3D = null
var current_room: Node3D = null
var _skip_intro: bool = false
@export var show_intro_narrative: bool = false

# ── Startup ───────────────────────────────────────────────────────────────────

func _ready() -> void:
	_skip_intro = OS.get_cmdline_user_args().has("--skip-intro")
	_spawn_room()
	_spawn_player()
	GameManager.start_run()
	if show_intro_narrative and not _skip_intro:
		_show_run_intro()

func _show_run_intro() -> void:
	await get_tree().process_frame  # let HUD finish layout
	var reflection := GameManager.get_run_reflection()
	if reflection != "":
		hud.show_narrative([{"speaker": "MC", "text": reflection}])
		await hud.narrative_complete
	# Show biome entry monologue
	var mono := GameManager.get_biome_entry_monologue(0)
	if mono != "":
		hud.show_narrative([{"speaker": "MC", "text": mono}])

# ── Spawning ──────────────────────────────────────────────────────────────────

func _spawn_room() -> void:
	current_room = TestRoomScene.instantiate()
	game_world.add_child(current_room)
	if current_room.has_signal("enemy_spawned"):
		current_room.enemy_spawned.connect(_on_enemy_spawned)
	if current_room.has_method("activate"):
		current_room.activate()

func _spawn_player() -> void:
	player = PlayerScene.instantiate()
	game_world.add_child(player)
	player.global_position = Vector3(0.0, 0.0, 0.0)
	# Initial facing: Vector3.BACK (+Z) so idle shows the face toward camera
	# (camera is placed at +Y +Z looking at origin, and the Adventurer model is
	# flipped 180° in player.gd so its face is at +Z).
	if "facing" in player:
		player.facing = Vector3(0.0, 0.0, 1.0)

	# Camera follows player
	if camera_rig.has_method("attach_to_target"):
		camera_rig.attach_to_target(player)
	if camera_rig.has_method("set_target"):
		camera_rig.set_target(player)
	if camera_rig.has_method("force_snap_to_target"):
		camera_rig.force_snap_to_target()

	# HUD binds to player signals
	hud.connect_player(player)

	# Death handler
	player.died.connect(_on_player_died)

func _process(_delta: float) -> void:
	# Camera binding is handled on spawn; avoid re-binding every frame because it
	# kills smooth subpixel compensation and introduces motion jitter.
	pass

func _on_enemy_spawned(enemy: Node3D) -> void:
	# Route hackeo narrative to HUD
	if enemy.has_signal("hackeo_sequence_ready"):
		enemy.hackeo_sequence_ready.connect(hud.show_narrative)
	# Collect fragments when enemy dies
	if enemy.has_signal("died"):
		enemy.died.connect(_on_enemy_died)

# ── Run lifecycle ─────────────────────────────────────────────────────────────

func _on_enemy_died(_position: Vector3, fragment_amount: int) -> void:
	GameManager.add_fragments(fragment_amount)

func _on_player_died() -> void:
	await get_tree().create_timer(1.4).timeout
	GameManager.end_run(GameManager.current_biome)
	get_tree().reload_current_scene()
