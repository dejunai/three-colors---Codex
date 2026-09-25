extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func verify_business(root_node: Node, routes: Dictionary, context: String) -> void:
	var rendered: Node = root_node.get_node_or_null("RenderedBusinessLandmarks")
	var legacy: Node = root_node.get_node_or_null("LegacySchoolhouseCollisionVisuals")
	assert(rendered != null and rendered.has_node("SchoolhouseExterior"), context + " rendered schoolhouse missing")
	assert(rendered.get_node("SchoolhouseExterior").find_children("*", "MeshInstance3D", true, false).size() > 0, context + " schoolhouse has no render mesh")
	assert(legacy != null and not legacy.visible, context + " primitive schoolhouse visuals must be hidden")
	var collision_count := 0
	for node in legacy.find_children("*", "CollisionShape3D", true, false):
		if node.shape != null:
			collision_count += 1
	assert(collision_count >= 2, context + " hidden schoolhouse shell must retain collision authority")
	assert(routes.has("route_schoolhouse"), context + " schoolhouse interior route must remain stable")

func run() -> void:
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var g = scene.chapter
	g.test_mode = true
	g.state = g.CaseState.new()
	g.state.started = true
	g._travel("town", Vector3(0, 5.6, 75), 0, false)
	await physics_frame
	var business: Node = g.estate.get_node("ContiguousTownPhaseOne/BusinessDistrictExterior")
	verify_business(business, g.estate.routes, "Contiguous business district")
	var legacy_hub = load("res://town_expansion.gd").new()
	legacy_hub.location = "business"
	root.add_child(legacy_hub)
	await process_frame
	verify_business(legacy_hub, legacy_hub.routes, "Old-save business hub")
	print("BUSINESS EXTERIOR MODEL PASS: shared and old-save schoolhouse landmark, hidden compatibility shell, stable interior route")
	legacy_hub.queue_free()
	scene.queue_free()
	await process_frame
	quit(0)
