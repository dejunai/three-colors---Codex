extends RefCounted

func finish_cards(g:Node) -> void:
	while g.page=="dialogue": g._next_card()

func settle(g:Node) -> void:
	await g.get_tree().physics_frame
	await g.get_tree().physics_frame

func run(g:Node) -> void:
	await settle(g)
	g.state = g.CaseState.new()
	g.state.started = true
	g.state.finished = true
	g.state.estate_complete = true
	g.state.flask = 3
	g.state.ammo = 6
	g.state.evidence.assign(["eight", "naomi", "wounds", "gas"])
	g.state.discover("knife")

	# 1. Test Forced Spill on Descent
	g._travel("tunnel", Vector3(0, 0.1, 7), 0, false)
	await settle(g)
	assert(g.state.flask == 3, "Flask is intact on entry")
	assert(not g.state.flask_spilled, "Flask is not yet spilled")
	
	# Interact with tunnel_descent
	g._interact("tunnel_descent")
	finish_cards(g)
	assert(g.state.flask_spilled, "Descent past foundation must trigger forced spill")
	assert(g.state.flask == 0, "Spilled flask must be empty")
	assert(g.state.flask_spill_amount == 3, "Exact amount hoarded (3 pours) must be recorded")
	assert(g.state.evidence.has("flask_spill"), "Flask spill must be recorded in evidence")

	# 2. Test Personal Effects & Flask Inspection
	g._case_file()
	assert(g.page == "case")
	g._flask()
	# Check that inspectable flask explains why and how much was lost
	var found_spill_label = false
	for child in g.content.find_children("*", "Label", true, false):
		if child.text.contains("All three short pours were lost"):
			found_spill_label = true
			break
	assert(found_spill_label, "Flask inspection must diegetically explain exact amount lost and spur cause")
	g._close()

	# 3. Test Cultist Stagger (Cannot be killed)
	assert(g.state.ammo == 6, "Revolver starts with 6 rounds")
	g._interact("cultist_encounter")
	assert(g.page == "combat")
	# Fire revolver at cultist
	for button in g.content.find_children("*", "Button", true, false):
		if button.text.begins_with("Fire service revolver"):
			button.pressed.emit()
			break
	assert(g.state.ammo == 5, "Firing revolver spends exactly one round")
	assert(g.estate.cultist_stagger > 0, "Shot staggers cultist center mass")
	g._close()

	# Melee strike with knife against cultist
	g._interact("cultist_encounter")
	for button in g.content.find_children("*", "Button", true, false):
		if button.text.begins_with("Drive Kessler's boning knife"):
			button.pressed.emit()
			break
	# Strength is 2, stagger duration is 1.5 + 2 * 1.0 = 3.5s
	assert(g.estate.cultist_stagger >= 3.4, "Strength stat scales melee stagger duration")
	g._close()

	# 4. Test Drowned Sailor (Mortal with brutal finishing blow)
	assert(not g.state.drowned_dead, "Drowned sailor is active")
	assert(g.estate.points.has("drowned_remains"), "Drowned remains target exists")
	g._interact("drowned_remains")
	assert(g.page == "combat")
	# Strike with knife
	for button in g.content.find_children("*", "Button", true, false):
		if button.text.begins_with("Strike with Kessler's boning knife"):
			button.pressed.emit()
			break
	assert(g.estate.drowned_stagger >= 4.9, "Strength 2 scales knife stagger to 5.0 seconds")
	# Now deliver finishing blow
	var finished_blow = false
	for button in g.content.find_children("*", "Button", true, false):
		if button.text.begins_with("Deliver desperate finishing blow"):
			button.pressed.emit()
			finished_blow = true
			break
	assert(finished_blow, "Finishing blow available when sailor is staggered")
	finish_cards(g)
	assert(g.state.drowned_dead, "Drowned sailor must be permanently dead after finishing blow")
	assert(g.state.evidence.has("drowned_remains"), "Defeat of drowned sailor is discovered")
	assert(not g.estate.points.has("drowned_remains"), "Defeated sailor target is removed from active points")
	print("COMBAT PASS: ammo tracking, knife melee scaling with Strength, immortal cultist vs mortal drowned finishing blow")

	# 5. Test Causal Spine Completion on Corkboard & Link Acceleration
	# With 8 observations (7 existing + lodging) and 0 links, perception is 2 + 2 + 0 = 4 (Spine Forming)
	g.state.discover("lodging")
	assert(g.state.evidence.size() == 8, "Evidence size should be 8")
	assert(g.state.perception() == 4, "Perception without links should be 4 (Spine Forming)")
	g._travel("room", Vector3(0, 0.1, 4))
	await settle(g)
	g._board()
	assert(g.page == "board")
	var found_spine_forming = false
	for child in g.content.find_children("*", "Label", true, false):
		if child.text.contains("CAUSE UNRESOLVED"):
			found_spine_forming = true
			break
	assert(found_spine_forming, "Evidence count must not establish the cause")

	# Walter connects NAOMI FREEMAN and A LOCAL ADDRESS -> confirms naomi_address link
	var link = g.archive._try_link(g, "lodging", "naomi")
	assert(not link.is_empty(), "Valid link between lodging and naomi must succeed")
	assert(g.state.has_link("naomi_address"), "Confirmed link must be recorded in state")
	assert(g.state.perception() >= 5, "Drawing a connection must accelerate Perception to >= 5")

	# Refresh board
	g._board()
	var found_spine_complete = false
	for child in g.content.find_children("*", "Label", true, false):
		if child.text.contains("CAUSE UNRESOLVED"):
			found_spine_complete = true
			break
	assert(found_spine_complete, "A valid link increases Perception without inventing an explanation")
	g._close()

	print("PHASE 2 PASS: forced spill, inspectable loss, combat stagger, ammo spending, Strength scaling, drowned defeat, corkboard causal spine")
	g.get_tree().quit(0)
