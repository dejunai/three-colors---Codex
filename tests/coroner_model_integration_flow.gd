extends SceneTree

const CoronerModel = preload("res://scripts/shared/coroner_model.gd")

func _initialize() -> void:
	call_deferred("run")

func current_clip(model: Node3D) -> String:
	var player := CoronerModel.animation_player(model)
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
	var estate_assistant: Node3D = g.estate.assistant_actor
	assert(is_instance_valid(estate_assistant) and estate_assistant.has_node("RenderedCoroner"), "Opening assistant must use the rendered model")
	assert(current_clip(estate_assistant) == "Idle", "Opening assistant must begin in Idle")
	
	g._interact("assistant")
	assert(current_clip(estate_assistant) == "Confer", "Opening assistant must animate Confer during conversation")
	g._close()
	assert(current_clip(estate_assistant) == "Idle", "Opening assistant must return to Idle after conversation")

	print("CORONER MODEL INTEGRATION PASS: estate assistant instantiates rendered model and animates during dialogue")
	quit(0)
