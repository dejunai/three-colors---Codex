extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var g = scene.chapter
	g.test_mode = true
	var catalog = g.scripted_dialogue.catalog
	catalog.scan()
	
	# Real phase boundaries from DayClock:
	# MORNING: 360 (6:00 AM)
	# NOON: 720 (12:00 PM)
	# EVENING: 1020 (5:00 PM)
	# NIGHT: 1200 (8:00 PM)
	var phases = ["morning", "noon", "evening", "night"]
	var phase_minutes = {"morning": 360, "noon": 720, "evening": 1020, "night": 1200}
	
	# Check for all extra_actors (the living town population)
	var living_actors = g.scripted_dialogue.extra_actors
	print("Auditing ", living_actors.size(), " living NPCs across phases...")
	var total_collisions = 0

	for p in phases:
		g.state.clock_minutes = phase_minutes[p]
		g.state.day = 3
		g.state.estate_complete = true
		
		# 1. Check raw catalog slot
		var raw_placements: Dictionary = {}
		for actor in living_actors:
			var spot: Array = catalog.slot(actor, g.state)
			if spot.is_empty(): continue
			var key = str(spot[0]) + ":" + str(spot[1])
			if not raw_placements.has(key): raw_placements[key] = []
			raw_placements[key].append(actor)
		
		# 2. Check world-transformed slot (_slot)
		var world_placements: Dictionary = {}
		for actor in living_actors:
			var spot: Array = g.scripted_dialogue._slot(g, actor)
			if spot.is_empty(): continue
			var key = str(spot[0]) + ":" + str(spot[1])
			if not world_placements.has(key): world_placements[key] = []
			world_placements[key].append(actor)
			
		print("\n=== PHASE: ", p, " (minutes=", phase_minutes[p], ") ===")
		print("Placed count: ", world_placements.size())
		var col_count = 0
		for key in world_placements:
			if world_placements[key].size() > 1:
				print("  COLLISION at ", key, ": ", world_placements[key])
				col_count += 1
		var raw_col_count = 0
		for key in raw_placements:
			if raw_placements[key].size() > 1:
				raw_col_count += 1
		print("Collisions (world-space): ", col_count, "  (raw catalog slot): ", raw_col_count)
		total_collisions += col_count

	print("\nTotal coordinate collisions across all phases: ", total_collisions)
	assert(total_collisions == 0, "Found %d NPC coordinate collision(s) — see per-phase output above" % total_collisions)
	print("PLACEMENT AUDIT PASS: %d living NPCs, 0 coordinate collisions across all phases" % living_actors.size())
	quit()