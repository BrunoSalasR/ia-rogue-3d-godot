extends CanvasLayer
## HUD — Terminal-style heads-up display.
## Narrative box freezes the game and requires player input to advance.
## All text is styled to feel like system output, not UI decoration.

signal narrative_complete

@onready var hp_bar:         ProgressBar    = $Root/BottomLeft/HPBar
@onready var ciclos_bar:     ProgressBar    = $Root/BottomLeft/CiclosBar
@onready var fragments_lbl:  Label          = $Root/BottomRight/FragmentsLabel
@onready var dash_container: HBoxContainer  = $Root/BottomRight/DashCharges
@onready var narrative_box:  PanelContainer = $Root/NarrativeBox
@onready var speaker_lbl:    Label          = $Root/NarrativeBox/VBox/Speaker
@onready var text_lbl:       Label          = $Root/NarrativeBox/VBox/Text

var _narrative_queue: Array = []
var _is_showing:      bool  = false
var _line_full:       bool  = false   # true once the full line is visible

# ── Connection ────────────────────────────────────────────────────────────────

func connect_player(player: Node) -> void:
	player.hp_changed.connect(_on_hp_changed)
	player.ciclos_changed.connect(_on_ciclos_changed)
	player.dash_charges_changed.connect(_on_dash_changed)
	GameManager.fragments_changed.connect(_on_fragments_changed)
	# Update immediately with current values
	_on_hp_changed(player.hp, player.max_hp)
	_on_ciclos_changed(player.ciclos, player.max_ciclos)
	_on_dash_changed(player.max_dash_charges, player.max_dash_charges)
	_on_fragments_changed(GameManager.total_fragments)

# ── HUD updates ───────────────────────────────────────────────────────────────

func _on_hp_changed(current: int, max_val: int) -> void:
	hp_bar.max_value = max_val
	hp_bar.value     = current

func _on_ciclos_changed(current: int, max_val: int) -> void:
	ciclos_bar.max_value = max_val
	ciclos_bar.value     = current

func _on_fragments_changed(total: int) -> void:
	fragments_lbl.text = "// FRAG :: %05d" % total

func _on_dash_changed(charges: int, _max_charges: int) -> void:
	var lit_count := 0
	for child in dash_container.get_children():
		if child is ColorRect:
			child.color = Color(0.0, 0.82, 1.0) if lit_count < charges else Color(0.08, 0.08, 0.12)
			lit_count += 1

# ── Narrative system ──────────────────────────────────────────────────────────
## Lines format: Array of { "speaker": String, "text": String }
## Game is paused while narrative is shown.
## First input: reveal full line (if typewriter active).
## Second input: advance to next line.

func show_narrative(lines: Array) -> void:
	_narrative_queue = lines.duplicate()
	_is_showing      = true
	get_tree().paused = true
	_next_line()

func _next_line() -> void:
	if _narrative_queue.is_empty():
		_close_narrative()
		return
	var data: Dictionary = _narrative_queue.pop_front()
	speaker_lbl.text = ("// " + data.get("speaker", "MC") + " ::").to_upper()
	text_lbl.text    = data.get("text", "")
	narrative_box.show()
	_line_full = true   # instant reveal for now; swap for typewriter if desired

func _input(event: InputEvent) -> void:
	if not _is_showing:
		return
	var advance := event.is_action_pressed("ui_accept") or event.is_action_pressed("attack")
	if not advance:
		return
	get_viewport().set_input_as_handled()
	if not _line_full:
		_line_full = true
		# TODO: skip typewriter to full line
	else:
		_next_line()

func _close_narrative() -> void:
	narrative_box.hide()
	_is_showing       = false
	get_tree().paused = false
	narrative_complete.emit()

# ── Biome transition overlay ──────────────────────────────────────────────────

func show_biome_transition(biome_name: String, on_done: Callable) -> void:
	# TODO: fade to black, show biome_name label, then call on_done
	# For now, immediately emit the monologue
	var monologue := GameManager.get_biome_entry_monologue(GameManager.current_biome)
	if monologue != "":
		show_narrative([{"speaker": "MC", "text": monologue}])
		await narrative_complete
	on_done.call()
