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
	g._travel("town", Vector3(100, -2.2, -8), 0, false)
	await physics_frame
	assert(g.estate.has_node("ContiguousTownPhaseTwo/WaterfrontExterior/OffshoreWhalingStation"), "Detailed offshore whaling station must remain visible and unreachable")
	assert(not g.estate.routes.has("route_waterfront") and not g.estate.routes.has("route_pickman"), "Waterfront exterior must not retain a loading boundary")
	for point in [Vector3(100, 0, -15), Vector3(100, 0, -18), Vector3(100, 0, -24), Vector3(100, 0, -30.5)]:
		await g._walk_to(point)
	assert(g.player.position.y < -4.0, "Waterfront approach must read as downhill from lower town")
	for point in [Vector3(100.5, 0, -34), Vector3(100.5, 0, -50), Vector3(100.5, 0, -60)]:
		await g._walk_to(point)
	assert(g.state.world == "town" and g.player.position.y < -4.5, "Quay must remain inside the shared exterior")
	assert(g.estate.points.has("chandlers_boy") and g.estate.points.chandlers_boy.pos.x > 60, "Waterfront schedules must use shared coordinates")
	print("CONTIGUOUS TOWN PHASE 2 / STEP 3 PASS: continuous lower waterfront, quay schedules, unreachable island")
	quit(0)
