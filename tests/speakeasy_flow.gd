extends SceneTree

func _initialize() -> void: call_deferred("run")
func cards(g:Node) -> void:
	while g.page=="dialogue": g._next_card()

func run() -> void:
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var g = scene.chapter
	g.test_mode = true
	g.state = g.CaseState.new()
	g.state.started = true
	g.state.coat = "Police coat"
	g.state.clock_minutes = 360 # Morning

	# 1. Travel to lower district
	g._travel("lower", Vector3(0, 0.1, 8), 0, false)
	g._close()
	await physics_frame
	assert(g.state.world == "lower", "Failed to travel to lower residential")

	# 2. Verify morning Lower District NPCs are present
	assert(g.estate.points.has("drayman"), "Missing drayman in lower")
	assert(g.estate.points.has("fish_smoker"), "Missing fish_smoker in lower")

	# 3. Test speakeasy entrance blocked in morning
	assert(g.estate.routes.has("route_speakeasy"), "Missing route_speakeasy in lower")
	g._interact("route_speakeasy")
	assert(g.page == "dialogue", "Interacting with route_speakeasy in morning should show card")
	assert(g.dialogue.cards[0][0] == "CELLAR BULKHEAD", "Should show cellar bulkhead locked card")
	cards(g)
	g._close()
	assert(g.state.world == "lower", "Should remain in lower")

	# 4. Advance time to evening (1020m) with Police coat -> blocked by bouncer
	g.state.clock_minutes = 1020
	g._interact("route_speakeasy")
	assert(g.page == "dialogue", "Interacting with route_speakeasy with police coat should show rejection card")
	assert(g.dialogue.cards[0][0] == "THE VIEWING SLIT", "Should show viewing slit rejection card")
	cards(g)
	g._close()
	assert(g.state.world == "lower", "Should remain in lower with police coat")

	# 5. Switch to Plain wool coat -> Allowed entry!
	g.state.coat = "Plain wool coat"
	g._interact("route_speakeasy")
	await physics_frame
	assert(g.state.world == "speakeasy", "Should enter speakeasy with plain coat at evening")

	# 6. Verify Speakeasy NPCs and bar stool are present
	assert(g.estate.points.has("speakeasy_bartender"), "Missing bartender")
	assert(g.estate.points.has("night_owl_one"), "Missing night_owl_one")
	assert(g.estate.points.has("night_owl_two"), "Missing night_owl_two")
	assert(g.estate.points.has("speakeasy_bar"), "Missing speakeasy_bar target")

	# 7. Test eavesdropping at the bar
	g._interact("speakeasy_bar")
	assert(g.page == "dialogue", "Interacting with speakeasy_bar should start eavesdrop cards")
	assert(g.dialogue.cards.size() == 6, "Eavesdrop scene should have 6 cards")
	assert(g.dialogue.cards[1][0] == "CALEB", "Card 1 should be Caleb speaking")
	assert(g.dialogue.cards[2][0] == "SILAS", "Card 2 should be Silas speaking")
	cards(g)
	assert(g.state.evidence.has("speakeasy_murders_overheard"), "Should record speakeasy_murders_overheard evidence")
	assert(g.state.statements.has("Overheard at the speakeasy: Otto Kessler was among the six dead; the estate cellar was freezing cold."))

	# 8. Test return route from speakeasy back to lower
	assert(g.estate.routes.has("route_return"), "Missing route_return in speakeasy")
	g._interact("route_return")
	await physics_frame
	assert(g.state.world == "lower", "Should return to lower district")

	print("SPEAKEASY PASS: lower district NPCs, daytime lockout, police coat rejection, evening plain coat entry, bar eavesdropping, notebook recording, and safe return")
	quit()
