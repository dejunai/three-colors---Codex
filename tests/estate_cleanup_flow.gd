extends SceneTree

func _initialize() -> void: call_deferred("run")

func cards(g: Node) -> void:
	var guard = 0
	while g.page == "dialogue":
		g._next_card()
		guard += 1
		assert(guard < 100)

func run() -> void:
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var g = scene.chapter
	g.test_mode = true
	g.state = g.CaseState.new()
	g.state.started = true
	g._close()
	g._travel("estate", Vector3(0,0.1,35), 0, false)

	# 1. Opening estate: service entrance activator exists and is locked before dawn
	assert(g.estate.points.has("service_entrance"), "Service entrance must have activator on opening visit")
	assert(g.estate.points["service_entrance"].title == "Try the service entrance", "Opening title must reflect locked state")
	g._interact("service_entrance")
	assert(g.page == "dialogue", "Interacting with service entrance before dawn must show locked door cards")
	assert(g.dialogue.cards[0][0] == "THE SERVICE ENTRANCE", "Must display service entrance card")
	cards(g)
	assert(g.page == "play" and g.state.world == "estate", "Player must remain on estate grounds")

	# 2. Opening estate: preliminary report paper and activator are present
	assert(g.estate.points.has("report"), "Preliminary report activator must exist on opening visit")
	assert(is_instance_valid(g.estate.opening_report) and g.estate.opening_report.visible, "Preliminary report paper mesh must be visible")

	# 3. Complete estate (file report and exit through gate)
	g.state.report = "Observations filed"
	g.state.estate_complete = true
	g.estate.sync_staging(g.state)

	# 4. Estate complete cleanup: report activator and paper mesh must be removed
	assert(not g.estate.points.has("report"), "Preliminary report activator must be erased when estate is complete")
	assert(not g.estate.opening_report.visible, "Preliminary report paper mesh must be hidden when estate is complete")
	g._interact("report")
	assert(g.page == "play", "Interacting with dismissed report must be a no-op")

	# 5. After Almy: service entrance becomes lounge entryway
	g.state.visited.append("almy")
	g.estate.sync_staging(g.state)
	assert(g.estate.points.has("service_entrance"))
	assert(g.estate.points["service_entrance"].title == "Enter the smoking lounge through the service entrance")
	g._interact("service_entrance")
	assert(g.state.world == "lounge", "Interacting after Almy must enter the smoking lounge")

	print("ESTATE CLEANUP & SERVICE ENTRANCE PASS: opening locked activator, report mesh & target dismissal on departure, lounge entry after Almy")
	quit(0)
