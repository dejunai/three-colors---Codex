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
	assert(g.movement_bounds.end.y >= 112, "Shared movement bounds must include the upper approach")
	for point in [Vector3(14, 0, 17), Vector3(14, 0, 22), Vector3(11, 0, 22), Vector3(11, 0, 25), Vector3(8, 0, 31), Vector3(8, 0, 39), Vector3(8, 0, 49), Vector3(8, 0, 57), Vector3(8, 0, 67)]:
		await g._walk_to(point)
	assert(g.state.world == "town", "Walking into business must retain the shared exterior")
	assert(g.player.position.y > 5.0, "Business street must occupy the raised plateau")
	# Use the deliberate alley between the museum and stationer rather than
	# attempting to walk through the northern storefront row.
	for point in [Vector3(-9, 0, 76), Vector3(-9, 0, 97), Vector3(-24, 0, 97), Vector3(-24, 0, 100), Vector3(-24, 0, 108), Vector3(-24, 0, 116.5)]:
		await g._walk_to(point)
	assert(g.player.position.y > 11.5, "Upper approach must reach the established upper elevation")
	assert(g.estate.has_node("ContiguousTownPhaseOne/UpperDistrictExterior"), "Upper district geometry must share the Pickman exterior")
	assert(not g.estate.routes.has("route_upper") and not g.estate.routes.has("route_pickman"), "Upper exterior must not retain a loading boundary")
	assert(g.estate.routes.has("route_upper_house_1"), "Separate upper interiors must retain stable routes")
	for point in [Vector3(-24, 0, 121), Vector3(-9, 0, 121), Vector3(-9, 0, 134)]:
		await g._walk_to(point)
	assert(g.state.world == "town" and g.player.position.y > 12.0, "Upper street must remain inside the raised shared exterior")
	for point in [Vector3(9, 0, 134), Vector3(9, 0, 117), Vector3(9, 0, 108), Vector3(9, 0, 99), Vector3(9, 0, 76), Vector3(-9, 0, 76), Vector3(-9, 0, 50), Vector3(-9, 0, 37), Vector3(-9, 0, 24)]:
		await g._walk_to(point)
	assert(g.state.world == "town" and g.player.position.y < 1.0, "Alternate return must reach Pickman without an exterior reload")
	print("CONTIGUOUS TOWN PHASE 1 / STEP 5 PASS: complete Pickman-business-upper walking loop")
	quit(0)
