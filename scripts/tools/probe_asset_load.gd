extends SceneTree

const PATHS := [
	"res://assets/world/scifi_megakit/Props/Prop_Computer.gltf",
	"res://assets/world/scifi_megakit/Platforms/Platform_Simple.gltf",
	"res://assets/world/scifi_megakit/Walls/WallAstra_Straight.gltf"
]

func _init() -> void:
	for p in PATHS:
		var r := load(p)
		print("[ASSET_PROBE] ", p, " => ", typeof(r), " class=", r.get_class() if r else "null")
	quit(0)
