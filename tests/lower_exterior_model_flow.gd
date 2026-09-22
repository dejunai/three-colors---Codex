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
	g._travel("town", Vector3(91, -2.2, 8), 0, false)
	await physics_frame
	var lower: Node = g.estate.get_node("ContiguousTownPhaseTwo/LowerDistrictExterior")
	var rendered: Node = lower.get_node_or_null("RenderedLowerLandmarks")
	var legacy: Node = lower.get_node_or_null("LegacyLowerDwellingCollisionVisuals")
	assert(rendered != null and rendered.has_node("DwellingTwoExterior"), "Rendered lower-district landmark missing")
	assert(rendered.get_node("DwellingTwoExterior").find_children("*", "MeshInstance3D", true, false).size() > 0, "Dwelling No. 2 exterior has no render mesh")
	assert(legacy != null and not legacy.visible, "Legacy Dwelling No. 2 visuals must be hidden")
	var collision_count := 0
	for node in legacy.find_children("*", "CollisionShape3D", true, false):
		if node.shape != null:
			collision_count += 1
	assert(collision_count >= 2, "Hidden dwelling shell must retain collision authority")
	assert(g.estate.routes.has("route_lower_house_2"), "Dwelling No. 2 interior route must remain stable")
	assert(g.estate.routes.has("route_speakeasy"), "Dwelling No. 5 speakeasy route must remain untouched")
	var legacy_hub = load("res://town_expansion.gd").new()
	legacy_hub.location = "lower"
	root.add_child(legacy_hub)
	await process_frame
	assert(legacy_hub.has_node("RenderedLowerLandmarks/DwellingTwoExterior"), "Old-save lower hub must instantiate the same rendered landmark")
	assert(not legacy_hub.get_node("LegacyLowerDwellingCollisionVisuals").visible, "Old-save lower hub must hide the compatibility shell")
	assert(legacy_hub.routes.has("route_lower_house_2") and legacy_hub.routes.has("route_speakeasy"), "Old-save lower routes must remain stable")
	print("LOWER EXTERIOR MODEL PASS: shared and old-save Dwelling No. 2 landmark, hidden compatibility shells, stable dwelling and speakeasy routes")
	legacy_hub.queue_free()
	scene.queue_free()
	await process_frame
	quit(0)
