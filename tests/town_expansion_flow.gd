extends SceneTree
const Places=preload("res://scripts/chapters/town_places.gd")
func _initialize() -> void:
	call_deferred("run")
func settle() -> void:
	await physics_frame
	await physics_frame
func walk(g:Node,p:Vector3) -> void:
	g.yaw=0
	await g._walk_to(p)
func cards(g:Node) -> void:
	while g.page=="dialogue": g._next_card()
func run() -> void:
	print("START EXPANSION")
	var scene=load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var g=scene.chapter
	g.test_mode=true
	g.state=g.CaseState.new()
	g.state.started=true
	g.state.report="Observations filed"
	g._travel("estate",Vector3(0,0.1,35))
	g._finish()
	cards(g)
	assert(g.state.estate_visits_completed==1 and g.state.rose_bodies_removed)
	g.state.day=3
	g._travel("estate",Vector3(23,0.1,-2))
	assert(not g.state.birch_bodies_removed)
	for body in g.estate.birch_bodies: assert(body.visible)
	for id in ["eight","shoes"]:
		g._interact(id)
		cards(g)
		assert(g.state.evidence.has(id))
	g._save_game()
	g._load_game()
	assert(g.state.estate_visits_completed==1 and not g.state.birch_bodies_removed)
	g.state.visited.append("almy")
	g._travel("lounge",Vector3(0,0.1,6))
	g._travel("estate",Vector3(-10,0.1,-17))
	assert(g.state.estate_visits_completed==1 and not g.state.birch_bodies_removed)
	g._travel("town",Vector3(0,0.1,17))
	assert(g.state.estate_visits_completed==2 and not g.state.birch_bodies_removed)
	g._travel("estate",Vector3(0,0.1,35))
	assert(g.state.birch_bodies_removed and g.page=="play")
	for body in g.estate.birch_bodies: assert(not body.visible)
	for id in ["eight","shoes"]:
		assert(not g.estate.points.has(id))
		g._interact(id)
		assert(g.page=="play")
	# Legacy saves preserve the second visit; JSON migration retains new states.
	var packed=g.state.pack()
	var restored=g.CaseState.new()
	assert(restored.restore(JSON.parse_string(JSON.stringify(packed))))
	assert(restored.birch_bodies_removed and restored.estate_visits_completed==2)
	packed.version=5
	for key in ["rose_bodies_removed","birch_bodies_removed","estate_visits_completed"]: packed.erase(key)
	assert(restored.restore(packed))
	assert(restored.rose_bodies_removed and not restored.birch_bodies_removed and restored.estate_visits_completed==1)
	# Every public entrance can be reached and returns to the correct street point.
	for hub in ["business","upper","lower"]:
		# All three hubs are continuous exteriors in new games now (business/upper
		# since Phase One, lower since Phase Two) — their old hub worlds remain
		# loadable so saves made before either migration still work. "lower"
		# previously simulated walking to a "route_lower" street hotspot, but
		# Phase Two's contiguous exterior deliberately erases that point
		# (contiguous_town_phase_two.gd::build()); travel there directly instead,
		# exactly like business/upper already do.
		g._travel(hub,Vector3(10,0.1,25))
		await settle()
		await walk(g,Vector3(10,0,8))
		assert(g.player.position.distance_to(Vector3(10,0.1,8))<1)
		g._save_game()
		g._load_game()
		assert(g.state.world==hub)
		for i in 6:
			var spec=Places.BUILDINGS[hub][i]
			if spec[3]=="exterior":
				assert(not g.estate.routes.has("route_"+spec[0]))
				continue
			var p=Places.front(i)
			if spec[0] == "speakeasy":
				p = p + Vector3(7, 0, 8)
				g.state.clock_minutes = 1020
				g.state.coat = "Plain wool coat"
			await walk(g,Vector3(g.player.position.x,0,8))
			await walk(g,Vector3(p.x,0,8))
			# The speakeasy hatch's angled bulkhead doors block a straight walk
			# to its exact center; stop just short, well within interact focus
			# range (~3 units), instead of fighting that collision precisely.
			await walk(g,p - Vector3(0,0,2) if spec[0] == "speakeasy" else p)
			assert(g.focused=="route_"+spec[0],"Building entrance: "+spec[0])
			g._interact(g.focused)
			assert(g.state.world==spec[0])
			await walk(g,Vector3(0,0,4))
			g._save_game()
			g._load_game()
			assert(g.state.world==spec[0] and g.player.position.distance_to(Vector3(0,0.1,4))<1)
			if spec[3]=="occupied" and g.estate.points.has("local_resident"):
				g._interact("local_resident")
				assert(g.page=="dialogue")
				cards(g)
			await walk(g,Vector3(0,0,7))
			assert(g.focused=="route_return")
			g._interact(g.focused)
			assert(g.state.world==hub)
		# Each hub's own street builder places its own "route_pickman" return
		# hotspot at a different physical position (business/upper share
		# (10,0,26); lower's is (-30,0,8) — see lower_street.gd/business_street.gd/
		# upper_street.gd), so the walk back has to be hub-specific too.
		if hub == "lower":
			# lower_street.gd's route_pickman sits at x=-30, but something in
			# that corner blocks walking the last ~1 unit to it exactly; -29
			# still lands well inside the interact focus radius.
			await walk(g,Vector3(g.player.position.x,0,8))
			await walk(g,Vector3(-29,0,8))
		else:
			await walk(g,Vector3(g.player.position.x,0,8))
			await walk(g,Vector3(10,0,8))
			await walk(g,Vector3(10,0,26))
		assert(g.focused=="route_pickman")
		g._interact(g.focused)
		assert(g.state.world=="town")
		print("HUB PASS: "+hub+"; four interiors, two exterior shells, entry/return and save/resume")
	g._travel("precinct",Vector3(0,0.1,6))
	await walk(g,Vector3(-2.5,0,0))
	await walk(g,Vector3(-3.8,0,0))
	await walk(g,Vector3(-3.8,0,-6.2))
	assert(g.focused=="route_morgue")
	g._interact(g.focused)
	assert(g.state.world=="morgue" and g.estate.scene_bodies.size()==6)
	await walk(g,Vector3(0,0,-4.5))
	assert(g.focused=="morgue_coroner")
	g._interact(g.focused)
	cards(g)
	g._save_game()
	g._load_game()
	assert(g.state.world=="morgue")
	await walk(g,Vector3(0,0,7))
	g._interact(g.focused)
	assert(g.state.world=="precinct")
	g._travel("town",Vector3(-24,0.1,17))
	await walk(g,Vector3(-24,0,22))
	assert(g.focused=="route_post")
	g._interact(g.focused)
	assert(g.state.world=="post_office")
	g._save_game()
	g._load_game()
	assert(g.state.world=="post_office")
	await walk(g,Vector3(0,0,7))
	g._interact(g.focused)
	assert(g.state.world=="town")
	print("EXPANSION PASS: protected second estate visit; silent later removal; migration; all destinations; morgue and post office")
	quit()




