extends SceneTree

const MODELS := [
	"res://assets/characters/placeholder/mc_android/Soldier.gltf",
	"res://assets/characters/placeholder/mc_android/SciFi.gltf",
	"res://assets/characters/placeholder/MAYBE/Mech_FinnTheFrog.gltf",
	"res://assets/characters/source/SciFi.gltf"
]

func _init() -> void:
	print("[ANIM_PROBE] Begin")
	for path in MODELS:
		var packed := load(path) as PackedScene
		if not packed:
			print("[ANIM_PROBE] FAIL load: ", path)
			continue
		var inst := packed.instantiate()
		var player := _find_animation_player(inst)
		if not player:
			print("[ANIM_PROBE] ", path, " -> no AnimationPlayer")
			continue
		var names: Array[String] = []
		for name in player.get_animation_list():
			names.append(String(name))
		print("[ANIM_PROBE] ", path, " -> ", names)
	print("[ANIM_PROBE] End")
	quit(0)

func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found := _find_animation_player(child)
		if found:
			return found
	return null
