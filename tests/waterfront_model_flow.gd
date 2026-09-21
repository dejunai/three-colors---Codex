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
	g._travel("town", Vector3(100, -4.9, -52), 0, false)
	await physics_frame
	var exterior = g.estate.get_node("ContiguousTownPhaseTwo/WaterfrontExterior")
	var rendered = exterior.get_node("RenderedWaterfront")
	var legacy = exterior.get_node("LegacyWaterfrontCollisionVisuals")
	assert(rendered != null and rendered.visible, "Rendered waterfront must own presentation")
	assert(rendered.find_child("QuayAndSeawall", true, false) != null, "Rendered quay hierarchy missing")
	assert(rendered.find_child("WaterSurface", true, false) != null, "Rendered water surface missing")
	assert(rendered.find_child("WorkingFrontage", true, false) != null, "Rendered frontage hierarchy missing")
	assert(rendered.find_child("FishingBoat", true, false) != null, "Rendered fishing boat missing")
	assert(rendered.find_child("WorkingProps", true, false) != null, "Rendered working props missing")
	var hero_props = exterior.get_node_or_null("HeroQuayProps")
	assert(hero_props != null, "Detailed quay prop hierarchy missing")
	for prop_name in ["FishingBoatDetailed", "BoatFrameDetailed", "CargoClusterDetailed", "DockCraneDetailed", "DockShedDetailed"]:
		assert(hero_props.has_node(prop_name), "Detailed quay prop missing: " + prop_name)
	for collision_name in ["BoatFrameCollision", "CargoClusterCollision", "DockCraneCollision", "DockShedBackCollision", "DockShedWestCollision", "DockShedEastCollision"]:
		assert(exterior.has_node(collision_name), "Quay prop collision proxy missing: " + collision_name)
	assert(legacy != null and not legacy.visible, "Legacy waterfront visuals must be hidden")
	var collision_count := 0
	for node in legacy.find_children("*", "CollisionShape3D", true, false):
		if node.shape != null:
			collision_count += 1
	assert(collision_count >= 6, "Hidden legacy geometry must retain collision authority")
	assert(exterior.has_node("OffshoreWhalingStation"), "Provisional island silhouette must remain separate")
	assert(not g.estate.routes.has("route_waterfront") and not g.estate.routes.has("route_pickman"), "Rendered slice must not restore district loading boundaries")
	assert(g.estate.points.has("chandlers_boy"), "Waterfront schedule anchors must remain intact")
	print("WATERFRONT MODEL PASS: rendered quay/frontage/boat/props, legacy collision, island separation, and schedule anchors")
	quit(0)
