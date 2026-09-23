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
	print("DEBRIEF PASS: both Skip choices, completion, one event, and no repeat panel")
	quit(0)

func _button(g:Node,text:String) -> Button:
	for button in g.content.find_children("*","Button",true,false):
		if button.text == text: return button
	return null
