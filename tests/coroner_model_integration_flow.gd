extends SceneTree

const CoronersAssistantModel = preload("res://scripts/shared/coroners_assistant_model.gd")

func _initialize() -> void:
	call_deferred("run")

func current_clip(model: Node3D) -> String:
	var player := CoronersAssistantModel.animation_player(model)
	return String(player.current_animation) if player != null else ""

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
	assert(is_instance_valid(estate_assistant) and estate_assistant.has_node("RenderedCoronersAssistant"), "Opening assistant must use the female rendered model")
	var clips := CoronersAssistantModel.animation_map(CoronersAssistantModel.animation_player(estate_assistant))
	assert(current_clip(estate_assistant) == clips["Idle"], "Opening assistant must begin in the mapped idle")
	
	g._interact("assistant")
	assert(current_clip(estate_assistant) == clips["Confer"], "Opening assistant must animate the mapped conversation clip")
	g._close()
	assert(current_clip(estate_assistant) == clips["Idle"], "Opening assistant must return to the mapped idle after conversation")

	# The separately scheduled morgue identity reuses the same woman and adapter
	# without sharing dialogue completion state with the opening assistant.
	g.state.day = 2
	g.state.clock_minutes = 540.0
	g.state.estate_complete = true
	g._travel("morgue", Vector3(0,0.1,4), 0, false)
	var morgue_assistant := g.scripted_dialogue.figures.get("coroners_assistant_morgue") as Node3D
	assert(is_instance_valid(morgue_assistant) and morgue_assistant.has_node("RenderedCoronersAssistant"), "Returning morgue assistant must reuse the female rendered model")
	var morgue_clips := CoronersAssistantModel.animation_map(CoronersAssistantModel.animation_player(morgue_assistant))
	g._interact("coroners_assistant_morgue")
	assert(current_clip(morgue_assistant) == morgue_clips["Confer"], "Returning assistant must animate during morgue dialogue")
	g._close()
	assert(current_clip(morgue_assistant) == morgue_clips["Idle"], "Returning assistant must return to idle after morgue dialogue")

	print("CORONER MODEL INTEGRATION PASS: estate and returning morgue assistants share the female model and animate independently")
	quit(0)
