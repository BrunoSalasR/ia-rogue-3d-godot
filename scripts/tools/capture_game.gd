extends SceneTree

const OUT_DIR := "res://debug-captures"

func _init() -> void:
	var dir := DirAccess.open("res://")
	if dir and not dir.dir_exists("debug-captures"):
		dir.make_dir("debug-captures")

	var main_scene := load("res://scenes/main/main.tscn") as PackedScene
	if not main_scene:
		push_error("[CAPTURE] Failed to load main scene")
		quit(1)
		return

	var main := main_scene.instantiate()
	root.add_child(main)

	await process_frame
	await process_frame
	await process_frame
	await create_timer(0.4).timeout

	_capture_viewport(main, "frame_main")

	# Simulate some input so we can validate movement look.
	Input.action_press("move_right")
	await create_timer(0.25).timeout
	Input.action_release("move_right")
	_capture_viewport(main, "frame_move")

	Input.action_press("dash")
	await create_timer(0.12).timeout
	Input.action_release("dash")
	_capture_viewport(main, "frame_dash")

	quit(0)

func _capture_viewport(main: Node, name: String) -> void:
	var subvp := main.get_node_or_null("SVContainer/SubViewport") as SubViewport
	if not subvp:
		push_warning("[CAPTURE] SubViewport not found")
		return
	var img := subvp.get_texture().get_image()
	if not img:
		push_warning("[CAPTURE] Could not capture image")
		return
	var out_path := "%s/%s.png" % [OUT_DIR, name]
	var err := img.save_png(out_path)
	if err != OK:
		push_warning("[CAPTURE] save_png failed for %s" % out_path)
