extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var g = scene.chapter
	g.test_mode = true
	g.state = g.CaseState.new()
	g.state.started = true
	g._travel("precinct", Vector3(0,0.1,6), 0, false)
	var clerk := g.scripted_dialogue.figures.get("intake_clerk") as Node3D
	assert(is_instance_valid(clerk) and clerk.get_meta("archetype") == "UPPER_MAN", "Intake clerk must use the rendered clerk archetype")
	assert(clerk.position.is_equal_approx(Vector3(0.4,0,-4.0)), "Intake clerk must stand behind the intake desk")
	assert(g.estate.points.intake_clerk.pos.is_equal_approx(Vector3(0.4,0,-2.5)), "Clerk interaction stays on the accessible side of the desk")
	g._travel("morgue", Vector3(0,0.1,6), 0, false)
	var coroner := g.scripted_dialogue.figures.get("morgue_coroner") as Node3D
	assert(is_instance_valid(coroner) and coroner.has_node("RenderedCoroner"), "Morgue coroner must use the dedicated rendered model")
	g._travel("estate", Vector3(0,0.1,35), 0, false)
	assert(g.estate.groundskeeper_actor.get_meta("archetype") == "OBSERVER_MAN", "Abel Tavares must use the rendered Observer archetype")
	assert(g.estate.groundskeeper_actor.has_node("Accent"), "Abel's rendered model must retain the color tell")
	print("STAFF MODEL INTEGRATION PASS: rendered intake clerk, morgue coroner, and groundskeeper retain accessible placement and Observer tell")
	quit(0)
