extends SceneTree

const LANDMARKS = ["RidgeResidenceExterior", "RidgeResidenceSideGate", "RidgeHedgeWest", "RidgeHedgeEast", "RidgeTreeWest", "RidgeTreeEast"]

func _initialize() -> void:
	call_deferred("run")

func verify_upper(root_node: Node, routes: Dictionary, context: String) -> void:
	var rendered: Node = root_node.get_node_or_null("RenderedUpperLandmarks")
	var legacy: Node = root_node.get_node_or_null("LegacyUpperResidenceCollisionVisuals")
	assert(rendered != null, context + " rendered upper landmarks missing")
	for landmark in LANDMARKS:
		assert(rendered.has_node(landmark), context + " landmark missing: " + landmark)
		assert(rendered.get_node(landmark).find_children("*", "MeshInstance3D", true, false).size() > 0, context + " landmark has no render mesh: " + landmark)
	assert(legacy != null and not legacy.visible, context + " primitive ridge-residence visuals must be hidden")
	var collision_count := 0
	for node in legacy.find_children("*", "CollisionShape3D", true, false):
		if node.shape != null:
			collision_count += 1
	assert(collision_count >= 5, context + " hidden house and hedge proxies must retain collision authority")
	assert(routes.has("route_upper_house_4"), context + " ridge-residence interior route must remain stable")

func run() -> void:
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var g = scene.chapter
	g.test_mode = true
	g.state = g.CaseState.new()
	g.state.started = true
	g._travel("town", Vector3(-19, 12.6, 148), PI, false)
	await physics_frame
	var upper: Node = g.estate.get_node("ContiguousTownPhaseOne/UpperDistrictExterior")
	verify_upper(upper, g.estate.routes, "Contiguous upper district")
	var legacy_hub = load("res://town_expansion.gd").new()
	legacy_hub.location = "upper"
	root.add_child(legacy_hub)
	await process_frame
	verify_upper(legacy_hub, legacy_hub.routes, "Old-save upper hub")
	print("UPPER EXTERIOR MODEL PASS: ridge residence, restrained landscaping, hidden collision shell, and stable interior route")
	legacy_hub.queue_free()
	scene.queue_free()
	await process_frame
	quit(0)
