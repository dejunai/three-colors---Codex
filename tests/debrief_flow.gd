extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var g = scene.chapter
	g.test_mode = true
	g.playthrough_log.endpoint_url = ""
	g.state = g.CaseState.new()
	g.state.day = 3
	g.state.steward_visits = 3
	g.state.intake_done = true
	g.state.visited.append("almy")
	g.state.discover("naomi")
	g.playthrough_log.begin(g.state,g.scripted_dialogue.FILES.keys())

	# Leaving before the ending offers an optional debrief without completing the story.
	g.state.day = 1
	g._save_and_return_to_title()
	assert(g.page == "case")
	var early_skip := _button(g,"Skip debrief and return to title")
	assert(early_skip != null, "Early exit must offer one clear Skip action")
	early_skip.pressed.emit()
	assert(g.page == "title" and not g.state.finished)
	assert(g.state.dialogue_state.flag("exit_debrief_completed"))
	var early_debriefs = g.playthrough_log.buffer.filter(func(item): return item.event == "debrief")
	assert(early_debriefs.size() == 1 and early_debriefs[0].town_feel == "skipped" and early_debriefs[0].time_natural == "skipped")
	assert(g.playthrough_log.buffer.filter(func(item): return item.event == "session_end" and item.ended_via == "closed").size() == 1)

	# A later playthrough still receives the story-ending debrief independently.
	g.state = g.CaseState.new()
	g.state.day = 3
	g.state.steward_visits = 3
	g.state.intake_done = true
	g.state.visited.append("almy")
	g.state.discover("naomi")
	g.playthrough_log.begin(g.state,g.scripted_dialogue.FILES.keys())
	# The debrief now follows the glass (chapter_one_break.gd); a save that already
	# carries the break still reaches it through the bed.
	g.state.dialogue_state.set_flag("glass_broken",true)

	g.staging.sleep(g)
	assert(g.playthrough_log.buffer.filter(func(item): return item.event == "day3_bed_reached").size() == 1)
	while g.page == "dialogue": g._next_card()
	assert(_button(g,"Skip") != null, "The town-feel question must offer Skip")
	_button(g,"Skip").pressed.emit()
	assert(_button(g,"Skip") != null, "The time question must offer Skip")
	_button(g,"Skip").pressed.emit()

	var debriefs = g.playthrough_log.buffer.filter(func(item): return item.event == "debrief")
	assert(debriefs.size() == 1)
	assert(debriefs[0].town_feel == "skipped" and debriefs[0].time_natural == "skipped")
	assert(g.state.finished and g.page == "ending", "Skipping both questions must still reach the ending")
	assert(g.state.dialogue_state.flag("debrief_completed"))
	assert(g.playthrough_log.buffer.filter(func(item): return item.event == "session_end").size() == 1)

	# Completed playthroughs return directly to the ending instead of reopening the questions.
	g._close()
	g.staging.sleep(g)
	assert(g.page == "ending")
	assert(g.playthrough_log.buffer.filter(func(item): return item.event == "debrief").size() == 1)
	print("DEBRIEF PASS: optional early-exit Skip, closed telemetry, story completion, and no repeat panel")
	quit(0)

func _button(g:Node,text:String) -> Button:
	for button in g.content.find_children("*","Button",true,false):
		if button.text == text: return button
	return null
