extends SceneTree

const StewardModel = preload("res://scripts/shared/steward_model.gd")

func _initialize() -> void:
	call_deferred("run")

func current_clip(model: Node3D) -> String:
	var player := StewardModel.animation_player(model)
	return String(player.current_animation).get_file() if player != null else ""

func run() -> void:
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var g = scene.chapter
	g.test_mode = true
	g.state = g.CaseState.new()
	g.state.started = true
	g.state.visited.append("almy")
	g._travel("lounge", Vector3(0, 0.1, 6), 0, false)
	
	var steward: Node3D = g.estate.steward_actor
	assert(is_instance_valid(steward) and steward.has_node("RenderedSteward"), "Lounge steward must use the rendered model")
	assert(current_clip(steward) == "Clean_Glass", "Lounge steward must begin in Clean_Glass idle")
	
	g._interact("barman")
	assert(current_clip(steward) == "Confer", "Lounge steward must animate Confer during conversation")
	g._close()
	assert(current_clip(steward) == "Clean_Glass", "Lounge steward must return to Clean_Glass idle after conversation")

	print("STEWARD MODEL INTEGRATION PASS: lounge steward instantiates rendered model, cleans glass idle, and animates Confer during dialogue")
	quit(0)
