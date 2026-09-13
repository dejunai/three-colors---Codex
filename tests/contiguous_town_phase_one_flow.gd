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
	g._travel("town", Vector3(8, 0.1, 17), 0, false)
	await physics_frame
	assert(g.estate.has_node("ContiguousTownPhaseOne"), "Pickman edge seam must be present")
	assert(g.estate.has_node("ContiguousTownPhaseOne/BusinessDistrictExterior"), "Business geometry must share Pickman exterior")
	assert(not g.estate.routes.has("route_business") and not g.estate.routes.has("route_pickman"), "Exterior seam must not retain a loading boundary")
	assert(g.estate.routes.has("route_schoolhouse") and g.estate.routes["route_schoolhouse"][0] == "schoolhouse", "Separate business interiors must retain stable routes")
	assert(g.movement_bounds.end.y >= 50, "Pickman movement bounds must include the uphill seam")
	for point in [Vector3(14, 0, 17), Vector3(14, 0, 22), Vector3(11, 0, 22), Vector3(11, 0, 25), Vector3(8, 0, 31), Vector3(8, 0, 39), Vector3(8, 0, 49), Vector3(8, 0, 57), Vector3(8, 0, 67)]:
		await g._walk_to(point)
	assert(g.state.world == "town", "Walking into business must retain the shared exterior")
	assert(g.player.position.y > 5.0, "Business street must occupy the raised plateau")
	print("CONTIGUOUS TOWN PHASE 1 / STEP 2 PASS: Pickman-to-business continuous exterior, raised street, separate interiors")
	quit(0)
