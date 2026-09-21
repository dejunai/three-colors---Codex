extends SceneTree

const CaptainOdellModel = preload("res://scripts/shared/captain_odell_model.gd")

func _initialize() -> void:
	call_deferred("run")

func current_clip(model: Node3D) -> String:
	var player := CaptainOdellModel.animation_player(model)
	return String(player.current_animation).get_file() if player != null else ""

func run() -> void:
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var g = scene.chapter
	g.test_mode = true
	g.state = g.CaseState.new()
	g.state.started = true
	g._travel("estate", Vector3(0,0.1,35), 0, false)
	var estate_odell: Node3D = g.estate.odell_actor
	assert(is_instance_valid(estate_odell) and estate_odell.has_node("RenderedOdell"), "Opening Odell must use the rendered model")
	g._interact("odell")
	assert(current_clip(estate_odell) == "Confer", "Opening Odell must animate during his conversation")
	g._close()
	assert(current_clip(estate_odell) == "Idle", "Opening Odell must return to idle after conversation")

	g.state.day = 2
	g.state.clock_minutes = 540.0
	g.state.estate_complete = true
	g._travel("precinct", Vector3(0,0.1,6), 0, false)
	assert(g.scripted_dialogue.figures.has("odell_precinct"), "Scheduled precinct Odell must be populated on Day 2")
	var precinct_odell: Node3D = g.scripted_dialogue.figures.odell_precinct
	assert(precinct_odell.has_node("RenderedOdell"), "Precinct Odell must reuse the rendered model")
	g._interact("odell_precinct")
	assert(current_clip(precinct_odell) == "Confer", "Precinct Odell must animate during his conversation")
	g._close()
	assert(current_clip(precinct_odell) == "Idle", "Precinct Odell must return to idle after conversation")
	print("ODELL MODEL INTEGRATION PASS: estate and scheduled precinct identities share the rendered model and dialogue animation")
	quit(0)
