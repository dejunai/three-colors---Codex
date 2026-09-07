extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var state := root.get_node_or_null("GameState")
	if state == null:
		state = load("res://scripts/game_state.gd").new()
		state.name = "GameState"
		root.add_child(state)
	var packed_scene: PackedScene = load("res://scenes/chapter_one_demo.tscn")
	assert(packed_scene != null, "Main scene must load")
	var demo := packed_scene.instantiate()
	root.add_child(demo)
	await process_frame
	assert(demo.player != null, "Player must be constructed")
	assert(demo.camera != null and demo.camera.projection == Camera3D.PROJECTION_ORTHOGONAL, "2.5D camera must be orthographic")
	assert(demo.environment_root.get_child_count() > 10, "Rose garden must contain blockout geometry")

	state.reset_demo()
	assert(state.discover_evidence("impossible_wound"), "Evidence discovery must persist")
	assert(state.discover_evidence("clean_knife"), "Second evidence discovery must persist")
	var valid_link: Dictionary = state.try_link("impossible_wound", "clean_knife")
	assert(valid_link.get("ok", false), "Known evidence pair must link")
	assert(state.has_link("staged_ritual"), "Link state must be queryable")
	var invalid_link: Dictionary = state.try_link("impossible_wound", "clean_knife")
	assert(not invalid_link.get("ok", true), "Duplicate link must be rejected")

	demo._build_slice(1)
	await process_frame
	assert(state.current_slice == 1, "Investigation slice must activate")
	assert(demo.environment_root.get_child_count() > 8, "Investigation room must contain blockout geometry")

	demo._build_slice(2)
	await process_frame
	assert(state.current_slice == 2, "Tunnel slice must activate")
	assert(demo.hazard != null, "Tunnel hazard must be constructed")
	assert(demo.reveal_nodes.size() >= 4, "Perception-revealed tunnel details must exist")

	print("SMOKE TEST PASS: scene construction, orthographic framing, evidence linking, persistence, and tunnel systems")
	quit(0)
