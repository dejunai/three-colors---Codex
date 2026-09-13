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
	assert(g.estate.has_node("ContiguousTownPhaseTwo/DistantWhalingStation"), "Whaling-station sightline must exist before the waterfront loads")
	assert(g.estate.routes.has("route_waterfront"), "Waterfront compatibility handoff must remain at the descent")
	for point in [Vector3(100, 0, -15), Vector3(100, 0, -18), Vector3(100, 0, -24), Vector3(100, 0, -30.5)]:
		await g._walk_to(point)
	assert(g.focused == "route_waterfront", "Waterfront handoff must sit at the bottom of the physical descent")
	assert(g.player.position.y < -4.0, "Waterfront approach must read as downhill from lower town")
	print("CONTIGUOUS TOWN PHASE 2 / STEP 2 PASS: lower-to-waterfront descent and visible island")
	quit(0)
