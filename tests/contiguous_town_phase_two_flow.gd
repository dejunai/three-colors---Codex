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
	g._travel("town", Vector3(25, 0.1, 8), 0, false)
	await physics_frame
	assert(g.estate.has_node("ContiguousTownPhaseTwo/LowerDistrictExterior"), "Lower geometry must share the town exterior")
	assert(not g.estate.routes.has("route_lower"), "Lower exterior must not retain its loading boundary")
	assert(g.estate.routes.has("route_lower_house_1") and g.estate.routes.has("route_speakeasy"), "Lower interiors must retain stable routes")
	for point in [Vector3(38, 0, 8), Vector3(48, 0, 8), Vector3(50.5, 0, 8), Vector3(54, 0, 8), Vector3(58, 0, 8), Vector3(72, 0, 8), Vector3(91, 0, 8)]:
		await g._walk_to(point)
	assert(g.state.world == "town" and g.player.position.y < -1.5, "Lower street must remain in the shared exterior at its lower elevation")
	assert(g.estate.points.has("drayman") and g.estate.points.drayman.pos.x > 40, "Scheduled lower actors must use shared coordinates")
	print("CONTIGUOUS TOWN PHASE 2 / STEP 1 PASS: Pickman-to-lower descent, stable interiors, scheduled actors")
	quit(0)
