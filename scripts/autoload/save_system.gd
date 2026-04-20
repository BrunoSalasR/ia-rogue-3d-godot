extends Node
## SaveSystem — Autoload singleton.
## Handles 3 save slots in JSON format stored in user://.

const SAVE_DIR  = "user://saves/"
const SAVE_FILE = "slot_%d.json"

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)

# ── Save ─────────────────────────────────────────────────────────────────────

func save_slot(slot: int) -> void:
	var data := {
		"run_count":          GameManager.run_count,
		"total_fragments":    GameManager.total_fragments,
		"biome_reached":      GameManager.biome_reached,
		"upgrades_purchased": GameManager.upgrades_purchased,
		"timestamp":          Time.get_datetime_string_from_system(),
	}
	var path := SAVE_DIR + SAVE_FILE % slot
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()

# ── Load ─────────────────────────────────────────────────────────────────────

func load_slot(slot: int) -> bool:
	var path := SAVE_DIR + SAVE_FILE % slot
	if not FileAccess.file_exists(path):
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return false
	var text := file.get_as_text()
	file.close()

	var json := JSON.new()
	if json.parse(text) != OK:
		push_error("SaveSystem: failed to parse slot %d" % slot)
		return false

	var data: Dictionary = json.get_data()
	GameManager.run_count          = data.get("run_count", 0)
	GameManager.total_fragments    = data.get("total_fragments", 0)
	GameManager.biome_reached      = data.get("biome_reached", 0)
	GameManager.upgrades_purchased = data.get("upgrades_purchased", [])
	GameManager.current_slot       = slot
	return true

# ── Query ────────────────────────────────────────────────────────────────────

func slot_exists(slot: int) -> bool:
	return FileAccess.file_exists(SAVE_DIR + SAVE_FILE % slot)

func get_slot_preview(slot: int) -> Dictionary:
	if not slot_exists(slot):
		return {}
	var file := FileAccess.open(SAVE_DIR + SAVE_FILE % slot, FileAccess.READ)
	if not file:
		return {}
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return {}
	file.close()
	return json.get_data()

func delete_slot(slot: int) -> void:
	var path := SAVE_DIR + SAVE_FILE % slot
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
