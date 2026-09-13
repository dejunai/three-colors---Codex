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
	assert(g.estate.routes["route_business"][0] == "business", "Stable business destination must remain intact")
	assert(g.estate.points["route_business"].pos.z >= 48, "Business transition must sit above the new approach")
	assert(g.movement_bounds.end.y >= 50, "Pickman movement bounds must include the uphill seam")
	for point in [Vector3(14, 0, 17), Vector3(14, 0, 22), Vector3(11, 0, 22), Vector3(11, 0, 25), Vector3(8, 0, 31), Vector3(8, 0, 39), Vector3(8, 0, 47.5)]:
		await g._walk_to(point)
	assert(g.focused == "route_business", "The uphill approach must be walkable to its existing route")
	print("CONTIGUOUS TOWN PHASE 1 / STEP 1 PASS: Pickman-to-business climb, upper silhouette, stable route")
	quit(0)
