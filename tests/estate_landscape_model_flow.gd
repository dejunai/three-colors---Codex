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
	g._travel("estate", Vector3(0, 0.1, 32), 0, false)
	await physics_frame
	var rendered: Node = g.estate.get_node_or_null("RenderedEstateLandscaping")
	var legacy: Node = g.estate.get_node_or_null("LegacyEstateLandscapeCollisionVisuals")
	assert(rendered != null, "Rendered estate entrance landscaping missing")
	for landmark in ["EntranceTreeWest", "EntranceTreeEast"]:
		assert(rendered.has_node(landmark), "Estate landscape model missing: " + landmark)
		assert(rendered.get_node(landmark).find_children("*", "MeshInstance3D", true, false).size() > 0, "Estate landscape has no render mesh: " + landmark)
	assert(legacy != null and not legacy.visible, "Estate landscape proxy visuals must remain hidden")
	var collision_count := 0
	for node in legacy.find_children("*", "CollisionShape3D", true, false):
		if node.shape != null:
			collision_count += 1
	assert(collision_count == 2, "Estate entrance clusters need two simple collision proxies")
	assert(g.estate.points.has("exit") and g.estate.points["exit"]["pos"] == Vector3(0, 0, 37), "Functional estate exit must remain centered and unchanged")
	assert(g.estate.departure_leaves.size() == 2, "Authored iron gate leaves must remain authoritative")
	print("ESTATE LANDSCAPE MODEL PASS: two perimeter clusters, hidden proxies, and unchanged functional gate")
	scene.queue_free()
	await process_frame
	quit(0)
