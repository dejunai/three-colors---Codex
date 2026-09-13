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
	var began = Time.get_ticks_usec()
	g._travel("town", Vector3(8, 0.1, 17), 0, false)
	await process_frame
	await physics_frame
	var build_ms = float(Time.get_ticks_usec() - began) / 1000.0
	var counts = {"nodes":0, "meshes":0, "bodies":0, "collisions":0}
	_count(g.estate, counts)
	var actor_count = 0
	for id in g.scripted_dialogue.figures:
		if is_instance_valid(g.scripted_dialogue.figures[id]): actor_count += 1
	var static_mb = float(Performance.get_monitor(Performance.MEMORY_STATIC)) / 1048576.0
	print("CONTIGUOUS TOWN PROFILE")
	print("build_ms=%.2f nodes=%d meshes=%d bodies=%d collisions=%d targets=%d scheduled_actors=%d static_mb=%.2f" % [build_ms, counts.nodes, counts.meshes, counts.bodies, counts.collisions, g.estate.points.size(), actor_count, static_mb])
	quit(0)

func _count(node: Node, counts: Dictionary) -> void:
	counts.nodes += 1
	if node is MeshInstance3D: counts.meshes += 1
	if node is CollisionObject3D: counts.bodies += 1
	if node is CollisionShape3D: counts.collisions += 1
	for child in node.get_children(): _count(child, counts)
