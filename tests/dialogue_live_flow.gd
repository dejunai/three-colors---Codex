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
	g._travel("estate", Vector3(0,0.1,35), 0, false)
	# Save halfway through the opening, restore the next unread line, then the fork.
	g._interact("odell")
	g._next_card()
	assert(not g.state.evidence.has("eight"))
	assert(g._save_game())
	g._load_game()
	assert(g.page == "dialogue" and g.dialogue.cards[0][1].begins_with("There are eight bodies"))
	assert(g.state.dialogue_state.visit_count("odell") == 1)
	cards(g)
	assert(g.page == "witness" and g.state.evidence.has("eight"))
	assert(g.state.clock_minutes == 360 and not g.state.dialogue_state.topic_done("odell","default"))
	assert(g._save_game())
	g._load_game()
	assert(g.page == "witness" and g.state.dialogue_state.visit_count("odell") == 1)
	var buttons = g.content.find_children("*","Button",true,false)
	assert(buttons.size() == 2)
	buttons[1].pressed.emit()
	assert(g.state.clock_minutes == 368 and g.state.statements.size() == 1)
	assert(g.state.statements[0].begins_with("Walter wrote EIGHT"))
	assert(g.state.dialogue_state.topic_done("odell","default"))
	g._save_game()
	g._load_game()
	g._interact("odell")
	assert(g.page == "witness" and g.content.find_children("*","Button",true,false).size() == 1)
	# Typed evidence is mirrored into existing case IDs, not duplicate prose notes.
	g._close()
	g._interact("assistant")
	cards(g)
	assert(g.state.evidence.has("testimony") and g.state.evidence.has("eight"))
	assert(not g.state.evidence.has("gas"), "Assistant must preserve shipped reward behavior")
	g._interact("gardener")
	cards(g)
	g.state.estate_complete = true
	g.state.coat = "Plain wool coat"
	g._interact("gardener")
	cards(g)
	assert(g.state.dialogue_state.facts.has("gardener.eight_sheets") and g.state.dialogue_state.facts.has("gardener.service_door"))
	# Current authored files are parseable, have valid case IDs and no demo topics.
	for actor in g.scripted_dialogue.FILES:
		var def = g.scripted_dialogue.definition(actor)
		assert(def.errors.is_empty(), str(def.errors))
		for topic in def.topics:
			assert(topic.id != "bullets" and topic.id != "club_five")
	# Almy unlocks the service entrance and her topic unlocks the actual ledger.
	g._travel("boardinghouse",Vector3(0,0.1,6),0,false)
	g._interact("almy")
	cards(g)
	assert(g.state.visited.has("almy"))
	g.scripted_dialogue.play_topic(g,"almy","lay_lead")
	assert(g.page == "witness" and not g.state.evidence.has("lay_lead"))
	g.scripted_dialogue.play_topic(g,"almy","identify")
	cards(g)
	assert(g.state.evidence.has("naomi"))
	g.scripted_dialogue.play_topic(g,"almy","lay_lead")
	cards(g)
	assert(g.state.evidence.has("lay_lead"))
	g.scripted_dialogue.play_topic(g,"almy","almy_trust")
	cards(g)
	g._save_game()
	g._load_game()
	assert(g.state.inquiry_topics.has("almy_trust"))
	# First visit, montage second, plain-coat third: retries cannot farm visits.
	g._travel("lounge",Vector3(0,0.1,6),0,false)
	for i in 3:
		g._interact("barman")
		cards(g)
	assert(g.state.steward_visits == 1 and g.state.dialogue_state.visit_count("steward") == 1)
	g.state.intake_done = true
	g._travel("room",Vector3(0,0.1,6),0,false)
	g._interact("sleep")
	while g.page == "montage": g.content.find_children("*","Button",true,false)[0].pressed.emit()
	assert(g.state.day == 3 and g.state.dialogue_state.visit_count("steward") == 2)
	g._travel("lounge",Vector3(0,0.1,6),0,false)
	g.state.coat = "Police coat"
	g._interact("barman")
	cards(g)
	assert(g.state.steward_visits == 2 and g.page == "play")
	g.state.coat = "Plain wool coat"
	g._interact("barman")
	cards(g)
	assert(g.state.steward_visits == 3 and g.page == "witness")
	g.scripted_dialogue.play_topic(g,"barman","pantry_lead")
	assert(not g.state.evidence.has("pantry_lead") and g.page == "witness")
	for id in ["club_talk","club_devotion","pantry_lead"]:
		g.scripted_dialogue.play_topic(g,"barman",id)
		cards(g)
		assert(g.state.evidence.has(id))
	assert(g.state.timed_conversations.has("pantry_lead"))
	# Old saves seed spent intros/locked responses without inventing evidence.
	var old = g.state.pack().duplicate(true)
	old.version = 7
	old.erase("dialogue_state")
	var migrated = g.CaseState.new()
	assert(migrated.restore(old))
	assert(migrated.dialogue_state.topic_done("odell","default"))
	assert(migrated.dialogue_state.topic_done("steward","steward_open"))
	assert(migrated.evidence == g.state.evidence)
	old.version=8
	old.dialogue_state=g.CaseState.new().dialogue_state.pack()
	assert(migrated.restore(old))
	assert(migrated.dialogue_state.topic_done("odell","default"), "Shipped v8 empty dialogue store must migrate the legacy answer")
	print("DIALOGUE LIVE PASS: actual UI, mid-line and fork saves, silent branch, evidence, both gardener clues, gated menus, three steward visits, montage, clock, legacy migration")
	quit()
