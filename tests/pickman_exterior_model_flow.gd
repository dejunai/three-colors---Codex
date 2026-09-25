extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var town = load("res://town.gd").new()
	town.location = "town"
	root.add_child(town)
	await process_frame
	var rendered: Node = town.get_node_or_null("RenderedPickmanFrontage")
	var legacy: Node = town.get_node_or_null("LegacyPickmanCollisionVisuals")
	assert(rendered != null and rendered.visible, "Rendered Pickman frontage must own presentation")
	for model_name in ["PolicePrecinctExterior", "AlmyBoardinghouseExterior", "RoomsAboveExterior"]:
		assert(rendered.has_node(model_name), "Pickman exterior missing: " + model_name)
		assert(rendered.get_node(model_name).find_children("*", "MeshInstance3D", true, false).size() > 0, "Pickman exterior has no render mesh: " + model_name)
	assert(legacy != null and not legacy.visible, "Legacy Pickman shells must be hidden")
	var collision_count := 0
	for node in legacy.find_children("*", "CollisionShape3D", true, false):
		if node.shape != null:
			collision_count += 1
	assert(collision_count >= 3, "Hidden Pickman shells must retain collision authority")
	for point_id in ["street_precinct", "street_almy", "street_room"]:
		assert(town.points.has(point_id), "Pickman interaction point moved or disappeared: " + point_id)
	print("PICKMAN EXTERIOR MODEL PASS: rendered landmarks, hidden compatibility shells, retained collision and stable entrances")
	quit(0)
